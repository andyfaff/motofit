import argparse
import asyncio
import configparser
import sys
from pathlib import Path

import aiofiles
import aiohttp
import numpy as np
import pandas as pd
import zmq.asyncio
from refnx.reduce import event


async def get_webpage(session, das_url, auth):
    try:
        async with session.get(
            das_url,
            headers=auth,
        ) as response:
            response.raise_for_status()
            return await response.text()
    except aiohttp.ClientError as e:
        print(f"Network or HTTP error occurred: {e}")
    except Exception as e:  # noqa
        print(f"An unexpected error occurred: {e}")
    return None


def parse_textstatus(data):
    dct = {}
    for line in data.strip().split("\n"):
        if ":" in line:
            k, v = line.split(":", 1)
            dct[k.strip()] = v.strip()

    return dct


def status_dct(
    DAQ,
    hipadaba_folder="C:/Documents and Settings/platypus/Documents/WaveMetrics/Igor Pro 10 User Files/Python Scripts",
    dataset_num=0
):
    N = dataset_num
    pth = Path(hipadaba_folder)
    with open(pth / DAQ / f"DATASET_{N}" / "status.txt", "r") as f:
        status = "".join(f.readlines())
        status = parse_textstatus(status)
    return status


def process_hipadaba_scan(
    node,
    DAQ,
    frame_agg,
    event_folder="z:/cycle/current/data/histserv",
    hipadaba_folder="C:/Documents and Settings/platypus/Documents/WaveMetrics/Igor Pro 10 User Files/Python Scripts",
    xbins=None,
    ybins=None,
    tbins=None,
    dataset_num=0,
    frequency=24,
    start_end_frame=None,
):
    PERIOD = 1 / frequency
    N = dataset_num

    pth = Path(event_folder)

    _events = event.events(pth / DAQ / f"DATASET_{N}" / "EOS.bin")[0]
    if tbins is None:
        tbins = np.min(_events[1]) - 0.5, np.max(_events[1]) + 0.5
    if ybins is None:
        ybins = np.min(_events[2]) - 0.5, np.max(_events[2]) + 0.5
    if xbins is None:
        xbins = np.min(_events[-1]) - 0.5, np.max(_events[-1]) + 0.5

    # epoch time of 1st frame
    status = status_dct(DAQ, dataset_num=dataset_num, hipadaba_folder=hipadaba_folder)

    # epoch times for start of first and last frame
    NUM_FRAMES = _events[0][-1] + 1
    et_F0 = float(status["dataset_start_time_t"])
    et_FN = np.arange(NUM_FRAMES, dtype=np.float64) * PERIOD + et_F0
    np.testing.assert_equal(et_F0, et_FN[0])

    pth = Path(hipadaba_folder)
    df = pd.read_csv(pth / "instrument_log.dat", names=["node", "ET", "pos"])
    _idx = df["node"] == node
    filtered_df = df[_idx]
    hipa_epoch_times = filtered_df["ET"][_idx].to_numpy()
    positions = filtered_df["pos"][_idx].to_numpy()
    if not len(hipa_epoch_times):
        raise RuntimeError("No hipadaba values recorded for that node")

    # find overlap between hipadaba values and events
    if et_F0 > hipa_epoch_times[-1] or et_FN[-1] < hipa_epoch_times[0]:
        raise RuntimeError(
            "There is no overlap between the hipadaba recorded positions and the event mode data"
        )

    # override the first/last frames.
    if start_end_frame is not None:
        first_frame, last_frame = start_end_frame
    else:  # the default situation
        # work out first neutron frame we want.
        if et_F0 > hipa_epoch_times[0]:
            # the first neutron frame is encompassed by hipa information
            first_frame = 0
        else:
            # the first neutron frame comes before the first hipa information
            first_frame = np.searchsorted(et_FN, hipa_epoch_times[0])

        if et_FN[-1] < hipa_epoch_times[-1]:
            last_frame = _events[0][-1]
        else:
            last_frame = np.searchsorted(et_FN, hipa_epoch_times[-1])
    
    # generate frame bins
    _FBINS = np.arange(first_frame, last_frame, frame_agg)
    FBINS = []
    for i in range(len(_FBINS) - 1):
        FBINS.append(np.arange(_FBINS[i], _FBINS[i + 1]))

    det, _ = event.process_event_stream(_events, FBINS, tbins, ybins, xbins)

    # find corresponding average position for the FRM_AGG range
    pos_node = []
    for _fbin in FBINS:
        # get the epoch time of the frame bins
        ts = et_FN[_fbin[0]]
        tf = et_FN[_fbin[-1] + 1]
        pos_start_end = np.interp([ts, tf], hipa_epoch_times, positions)
        pos_node.append(np.mean(pos_start_end))
    pos_node = np.array(pos_node)

    return pos_node, det


async def zmq_logger(ics_url, das_url, args, auth):
    ctx = zmq.asyncio.Context()
    zmq_socket = ctx.socket(zmq.SUB)
    zmq_socket.connect(ics_url)
    zmq_socket.subscribe("")

    print(f"[*] Subscribed to ZMQ at {ics_url}")
    print(f"[*] Watching tags: {args.tags}")

    # a file that signals a shutdown
    STOP_FILE = Path("stop.txt")
    session_timeout = aiohttp.ClientTimeout(total=30)

    try:
        async with (
            aiofiles.open(args.path / args.outfile, mode="a") as f,
            aiohttp.ClientSession(timeout=session_timeout) as session,
        ):
            while True:
                try:
                    # Wait up to 1 second for a ZMQ message; if nothing arrives, it times out
                    msg = await asyncio.wait_for(zmq_socket.recv_json(), timeout=0.5)
                except asyncio.TimeoutError:
                    # No message arrived in the last second.
                    # Check the stop file, then smoothly resume waiting.
                    if STOP_FILE.exists():
                        break
                    continue

                name = msg.get("name")

                if name == "STARTED" and msg["value"] == "HistogramMemory":
                    html = await get_webpage(session, das_url, auth)
                    dct = parse_textstatus(html)
                    pth = (
                        args.path
                        / dct["DAQ_dirname"]
                        / f"DATASET_{dct['DATASET_number']}"
                    )
                    pth.mkdir(parents=True, exist_ok=True)
                    async with aiofiles.open(pth / "status.txt", "w") as file:
                        await file.write(html)
                        await file.flush()

                # Filter logic: Check against interesting_tags or /control/ prefix
                if name in args.tags:  # or name.startswith("/control/"):
                    # print(msg)
                    await f.write(f"{name}, {msg['ts']}, {msg['value']}\n")
                    await f.flush()  # Ensure it's written to disk

                if STOP_FILE.exists():
                    break

    except asyncio.CancelledError:
        print("\n[!] Shutting down bridge...")
    except Exception as e:  # noqa
        print(f"\n[!] Error: {e}")
    finally:
        zmq_socket.close()
        ctx.term()


def main():
    # Define a clean loop factory to bypass ProactorEventLoop on Windows
    if sys.platform == "win32":
        # Force the Selector loop
        loop_factory = asyncio.SelectorEventLoop
    else:
        # Use the default behavior for macOS / Linux
        loop_factory = None

    # Safely delete the file (ignores error if missing in Python 3.8+)
    Path("stop.txt").unlink(missing_ok=True)

    parser = argparse.ArgumentParser(description="ZMQ Logger")

    # File and Filter Args
    parser.add_argument(
        "--outfile",
        default="instrument_log.dat",
        help="File to save full records",
    )
    parser.add_argument(
        "--path",
        default=".",
        help="Path to where you'd like to store data",
    )
    parser.add_argument(
        "--tags",
        nargs="+",
        required=False,
        help="List of interesting tags to filter (space separated)",
    )

    args = parser.parse_args()
    args.tags = args.tags or []

    config = configparser.ConfigParser()
    config.read("config.ini")
    das_url = config.get("url", "das")
    ics_url = config.get("url", "ics")
    ics_url = f"tcp://{ics_url}"

    username = config["credentials"]["username"]
    password = config["credentials"]["password"]
    auth_header = {"Authorization": aiohttp.encode_basic_auth(username, password)}

    pth = Path(args.path)
    if pth.is_dir():
        args.path = pth
    else:
        raise ValueError(f"Desired output directory, {pth}, does not exist")

    try:
        asyncio.run(
            zmq_logger(ics_url, das_url, args, auth_header), loop_factory=loop_factory
        )
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()

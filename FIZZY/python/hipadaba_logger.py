import argparse
import asyncio
import configparser
import sys
from pathlib import Path

import aiofiles
import aiohttp
import zmq.asyncio


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

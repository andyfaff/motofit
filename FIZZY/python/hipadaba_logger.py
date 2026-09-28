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

    session_timeout = aiohttp.ClientTimeout(total=30)
    try:
        async with (
            aiofiles.open(args.outfile, mode="a") as f,
            aiohttp.ClientSession(timeout=session_timeout) as session,
        ):
            while True:
                msg = await zmq_socket.recv_json()
                name = msg.get("name")

                if name == "STARTED" and msg["value"] == "HistogramMemory":
                    # acquisition started, save the epoch time for dataset_start_time_t
                    html = await get_webpage(session, das_url, auth)
                    dct = parse_textstatus(html)
                    pth = Path(
                        ".", dct["DAQ_dirname"], f"DATASET_{dct['DATASET_number']}"
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

    parser = argparse.ArgumentParser(description="ZMQ Logger")

    # File and Filter Args
    parser.add_argument(
        "--outfile",
        default="instrument_log.dat",
        help="File to save full records",
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

    try:
        asyncio.run(
            zmq_logger(ics_url, das_url, args, auth_header), loop_factory=loop_factory
        )
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()

import sys
from pathlib import Path
import numpy as np
from refnx.reduce import PlatypusReduce, ReductionOptions


def wott(r0, d0, start_end_time=None):
    pth = Path("Z:/cycle/current/data/sics")
    pth_ev = Path("Z:/cycle/current/data/histserv")
    if r0 == "scratch.nx.hdf":
        pass
    else:
        r0 = f"PLP{r0:07d}.nx.hdf"

    d0 = f"PLP{d0:07d}.nx.hdf"
   
    rdo = ReductionOptions()
    if start_end_time is not None:
        start_time, end_time = start_end_time
        rdo = ReductionOptions(event_folder=pth_ev, eventmode=[start_time, end_time])
 
    # pth = Path("W:", "cycle", "171", "data", "sics")
    # 70021 70023, ~0.8 degrees
    d0 = PlatypusReduce(pth / d0)
    output = d0.reduce(pth / r0, save=False, **rdo)

    actual = d0.omega_corrected[0][0]
    nominal = d0.reflected_beam.cat.cat["omega"][0]
    return actual, nominal


if __name__ == "__main__":
    
    try:
        r0 = int(sys.argv[1])
    except ValueError:
        r0 = "scratch.nx.hdf"

    d0 = int(sys.argv[2])
    
    if len(sys.argv) > 3:
        start_time = float(sys.argv[3])
        end_time = float(sys.argv[4])
        actual, nominal = wott(r0, d0, (start_time, end_time))
    else:
        actual, nominal = wott(r0, d0)

import sys
from pathlib import Path
import numpy as np
from refnx.reduce import PlatypusReduce


def wott(r0: int, d0: int):
    pth = Path("Z:/cycle/current/data/sics")
    r0 = f"PLP{r0:07d}.nx.hdf"
    d0 = f"PLP{d0:07d}.nx.hdf"

    # pth = Path("W:", "cycle", "171", "data", "sics")
    # 70021 70023, ~0.8 degrees
    d0 = PlatypusReduce(pth / d0)
    output = d0.reduce(pth / r0, save=False)

    actual = d0.omega_corrected[0][0]
    nominal = d0.reflected_beam.cat.cat["omega"][0]
    return actual, nominal


if __name__ == "__main__":

    r0 = int(sys.argv[1])
    d0 = int(sys.argv[2])
    actual, nominal = wott(r0, d0)

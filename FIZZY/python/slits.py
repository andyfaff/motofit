from refnx.util import slit_optimiser


def slits(footprint, resolution, angle):
    sl = list(slit_optimiser(footprint, resolution, angle, verbose=False))
    return sl


if __name__ == '__main__':
    footprint = float(sys.argv[1])  # convert the argument from a string to a float
    resolution = float(sys.argv[2])  # convert the argument from a string to a float
    angle = float(sys.argv[3])
    result = slits(footprint, resolution, angle)

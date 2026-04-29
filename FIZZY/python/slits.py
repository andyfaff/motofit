from refnx.util import slit_optimiser, height_of_beam_after_dx


def slits(angle, footprint, resolution, L12, L2S, LS3, LpreS1):
    s23 = slit_optimiser(
        footprint, resolution, angle, verbose=False, L12=L12, L2S=L2S, LS3=LS3
    )
    s1 = height_of_beam_after_dx(s23[0], s23[1], L12, -LpreS1)
    s4 = height_of_beam_after_dx(s23[0], s23[1], L12, L2S + LS3)
    return [s1[1], s23[0], s23[1], s4[1]]


if __name__ == "__main__":
    angle = float(sys.argv[1])
    footprint = float(sys.argv[2])
    resolution = float(sys.argv[3])
    L12 = float(sys.argv[4])
    L2S = float(sys.argv[5])
    LS3 = float(sys.argv[6])
    LpreS1 = float(sys.argv[7])
    result = slits(angle, footprint, resolution, L12, L2S, LS3, LpreS1)

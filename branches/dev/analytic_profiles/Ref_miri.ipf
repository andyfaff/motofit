#pragma rtGlobals=1		// Use modern global access method.

//this function will do an exponential decay underneath a single slab
Function Ref_miri(w, yy, xx): fitfunc
Wave w, yy, xx

variable ii, layer_thickness
//w[0] = Scalefactor
//w[1] = SLD superphase
//w[2] = SLD subphase
//w[3] = bkg
//w[4] = subrough
//w[5] = thickness layer1
//w[6] = SLD layer 1
//w[7] = roughness layer 1
//w[8] = NUM_LAYERS - should fix
//w[9] = exp_decay length

//make the wave to pass into the reflectivity calculation
make/d/free/n=((w[8] + 1) * 4 + 6) W_forRef
W_forRef[0] = w[8] + 1
W_forRef[1] = w[0]
W_forRef[2] = w[1]
W_forRef[3] = w[2]
W_forRef[4] = w[3]
W_forRef[5] = w[4]
W_forRef[6] = w[5]
W_forRef[7] = w[6]
W_forRef[8] = 0
W_forRef[9] = w[7]

//work out the thickness of each of the layers
//lets assume that we won't see anything when the exp decay is only 1% different to the bulk
// I = I_0 * exp(-x/L)
// I/I_0  = = exp(-x/L)
// ln(I/I_0) = -x / L
// -L * ln(I/I_0) = x
layer_thickness = ln(0.01) * w[9] * -1 / round(w[8])

for(ii = 0 ; ii < round(w[8]) ; ii+=1)
	W_forRef[4 * (ii + 1) + 6] = layer_thickness
	W_forRef[4 * (ii + 1) + 7] = w[2] + (w[6]-w[2]) * exp(-(layer_thickness * (ii + 0.5)) / w[9])
	W_forRef[4 * (ii + 1) + 8] = 0
	W_forRef[4 * (ii + 1) + 9] = 0
endfor

AbelesAll(W_forRef, yy, xx)
yy = log(yy)
End

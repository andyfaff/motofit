#pragma rtGlobals=1		// Use modern global access method.
Function bin_mixt(w, yy , xx):fitfunc
Wave w, yy, xx

//w[0] = scalefactor
//w[1] = SLD of solvent
//w[2] = background
//w[3] = roughness subphase/layer
//w[4] = thickness
//w[5] = roughness layer/air
//
//w[6] = Area per molecule1
//w[7] = Molecular Volume 1
//w[8] = SLD 1
//
//w[9] = Area per mol2
//w[10] = Molecular Volume 2
//w[11] = SLD 2

make/o/d/n=10 W_forRef

W_forRef[0] = 1
W_forRef[1] = w[0]
W_forRef[2] = 0
W_forRef[3] = w[1]
W_forRef[4] = w[2]
W_forRef[5] = w[3]

//set up the parameters for the layer
W_forRef[6] = w[4]

variable vol_occupied_by1, vol_occupied_by2, total_volume
variable volfrac1, volfrac2, volfracwater
vol_occupied_by1 = w[6] * w[4]
vol_occupied_by2 = w[9] * w[4]
total_volume =  vol_occupied_by2 + vol_occupied_by1
volfrac1 = w[7] / total_volume
volfrac2 = w[10] / total_volume
 
 W_forRef[7] = volfrac1 * w[8] + volfrac2 * w[11] + (1 - volfrac1 - volfrac2) * w[1]
W_forRef[8] = 0
W_forRef[9] = w[5]


//now calculate the reflectivity of such a model
Abelesall(W_forRef, yy, xx)
yy = log(yy)
End
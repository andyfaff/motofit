#pragma rtGlobals=1		// Use modern global access method.
#include "Motofit_all_at_once"

CONSTANT SLICETHICKNESS = 1

Function parabola(w, yy, xx):fitfunc
Wave w, yy, xx

//w[0] = reflectivity SCALE factor
//w[1] = SLD fronting
//w[2] = SLD backing
//w[3] = background
//w[4] = thickness SiO2
//w[5] = SLD SiO2
//w[6] = roughness SiO2/Si
//w[7] = roughness polymer/SiO2

//w[8] = phi_0
//w[9] = h
//w[10] = alpha
//w[11] = SLD polymer
//w[12] = solvent/polymer gaussian roughness

variable numslices = ceil(w[9] / SLICETHICKNESS)
variable realslicethickness = w[9] / numslices

variable ii, volfrac, prefactor, hsquared
make/d/o/n=(4 * (numslices + 1) + 6) W_forreflectivity

W_forreflectivity[0] = numslices + 1
W_forreflectivity[1] = w[0]
W_forreflectivity[2] = w[1]
W_forreflectivity[3] = w[2]
W_forreflectivity[4] = w[3]
W_forreflectivity[5] = w[12]

W_forreflectivity[6] = w[4]
W_forreflectivity[7] = w[5]
W_forreflectivity[8] = 0
W_forreflectivity[9] = w[6]

prefactor = w[8] / (w[9] ^ (2 * w[10]))
hsquared = w[9] ^ 2

for(ii = 0 ; ii < numslices ; ii += 1)
	W_forreflectivity[4 * ii + 10] = realslicethickness
	W_forreflectivity[4 * ii + 11] = w[11]
	
	volfrac = prefactor  * (hsquared - ((ii + 0.5) * realslicethickness) ^ 2) ^ w[10]
	
	W_forreflectivity[4 * ii + 12] = 100 - 100 * volfrac
	if(!ii)
		W_forreflectivity[4 * ii + 13] = w[7]
	else
		W_forreflectivity[4 * ii + 13] = 0
	endif
endfor

motofit(W_forreflectivity, yy, xx)
End

Function gaussianterminatedparabola(w, yy, xx):fitfunc
Wave w, yy, xx

//w[0] = reflectivity SCALE factor
//w[1] = SLD fronting
//w[2] = SLD backing
//w[3] = background
//w[4] = thickness SiO2
//w[5] = SLD SiO2
//w[6] = roughness SiO2/Si
//w[7] = roughness polymer/SiO2

//w[8] = phi_0
//w[9] = h
//w[10] = alpha
//w[11] = z1
//w[12] = beta
//w[13] = SLD polymer
//w[14] = solvent/polymer gaussian roughness

variable numslices1 = ceil(w[11] / SLICETHICKNESS)
variable numslices2 = ceil ((10 * w[12]) / SLICETHICKNESS)
variable realslicethickness1 = w[11] / numslices1
variable realslicethickness2 = (10 * w[12]) / numslices2

variable ii, volfrac, prefactor, hsquared, phi_1
make/d/o/n=(4 * (numslices1 + numslices2 + 1) + 6) W_forreflectivity
make/o/n=(numslices1+numslices2)/d volfracp

W_forreflectivity[0] = numslices1 + numslices2 + 1
W_forreflectivity[1] = w[0]
W_forreflectivity[2] = w[1]
W_forreflectivity[3] = w[2]
W_forreflectivity[4] = w[3]
W_forreflectivity[5] = w[14]

W_forreflectivity[6] = w[4]
W_forreflectivity[7] = w[5]
W_forreflectivity[8] = 0
W_forreflectivity[9] = w[6]

prefactor = w[8] / (w[9] ^ (2 * w[10]))
hsquared = w[9] ^ 2

for(ii = 0 ; ii < numslices1 ; ii += 1)
	W_forreflectivity[4 * (ii + 1) + 6] = realslicethickness1
	W_forreflectivity[4 * (ii + 1) + 7] = w[13]
	
	volfrac = prefactor  * (hsquared - ((ii + 0.5) * realslicethickness1) ^ 2) ^ w[10]
	volfracp[ii] = volfrac
	W_forreflectivity[4 * (ii + 1) + 8] = 100 - 100 * volfrac
	if(!ii)
		W_forreflectivity[4 * (ii + 1) + 9] = w[7]
	else
		W_forreflectivity[4 * (ii + 1) + 9] = 0
	endif
endfor

phi_1 = prefactor * (hsquared - w[11]^2)^w[10]

for(ii = 0 ; ii < numslices2 ; ii += 1)
	W_forreflectivity[4 * (ii + 1 + numslices1) + 6] = realslicethickness2
	W_forreflectivity[4 * (ii + 1 + numslices1) + 7] = w[13]
	
	volfrac = phi_1 * exp(-1 / w[12] * ((ii + 0.5) * realslicethickness2)^1.5)
	volfracp[ii + numslices1] = volfrac
	W_forreflectivity[4 * (ii + 1 + numslices1) + 8] = 100 - 100 * volfrac
	W_forreflectivity[4 * (ii + 1 + numslices1) + 9] = 0
endfor

motofit(W_forreflectivity, yy, xx)
End

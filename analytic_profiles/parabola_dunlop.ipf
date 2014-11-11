#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtGlobals=1		// Use modern global access method.
#include "Motofit_all_at_once"

//change the number of slices at will.  The greater the number of slices the finer the profile, but you may need to use different
//I_sigma and sigma_b
	CONSTANT NUMSLICES=10

Function parabola(w, yy, xx):fitfunc
	Wave w, yy, xx

	//Structure and Collapse of a Surface-Grown Strong Polyelectrolyte Brush on Sapphire
	//Iain E. Dunlop, Robert K. Thomas, Simon Titmus, Victoria Osborne, Steve Edmondson, Wilhelm T.S. Huck, and Jacob Klein
	//dx.doi.org/10.1021/la204655h | Langmuir 2012, 28, 3187?3193

	//THERE ARE 18 parameters in total.

	//w[0] = reflectivity SCALE factor
	//w[1] = SLD fronting (e.g. Si)
	//w[2] = SLD backing (e.g. D2O)
	//w[3] = background
	//w[4] = thickness SiO2
	//w[5] = SLD SiO2
	//w[6] = roughness SiO2/Si

	//w[7] = polymer SLD
	//w[8] = d1
	//w[9] = phi1 [0, 1]
	//w[10] = roughness surface1/SiO2

	//w[11] = d2
	//w[12] = phi2 [0, 1]
	//w[13] = roughness surface2/surface1

	//see equations 1, 2.

	//w[14] = \Gamma, adsorbed amount
	//w[15] = h
	//w[16] = \sigma_{b}
	//w[17] = I_{\sigma} [0, 1]

	variable nlayers = NUMSLICES + 3 //NUMSLICES, SiO2, surface1, surface2
	variable phi, prefactor, h, sigma_n, sigma_b, I_sigma, ii, distance

	//we need 4N + 6 parameters for an Nlayered reflectivity calculation
	make/d/o/n=(4 * nlayers + 6) W_forreflectivity

	//fill out the base set of parameters
	W_forreflectivity[0] = nlayers
	W_forreflectivity[1] = w[0]
	W_forreflectivity[2] = w[1]
	W_forreflectivity[3] = w[2]
	W_forreflectivity[4] = w[3]
	//W_forreflectivity[5] filled out in the loop below

	//SiO2 native oxide layer
	W_forreflectivity[6] = w[4]
	W_forreflectivity[7] = w[5]
	W_forreflectivity[8] = 0
	W_forreflectivity[9] = w[6]

	//surface layer 1
	W_forreflectivity[10] = w[8]
	W_forreflectivity[11] = w[7] 
	W_forreflectivity[12] = 100 - 100 * w[9]
	W_forreflectivity[13] = w[10]

	//surface layer2
	W_forreflectivity[14] = w[11]
	W_forreflectivity[15] = w[7]
	W_forreflectivity[16] = 100 - 100 * w[12]
	W_forreflectivity[17] = w[13]

	h = w[15]
	I_sigma = w[17]
	sigma_b = w[16]
	prefactor = 3 * w[14] / 2 / (h^3)

	for(ii = 0 ; ii < NUMSLICES ; ii += 1)
		//equations 1+2
		distance = (ii + 0.5) * h / NUMSLICES
		phi = prefactor * (h^2 - distance^2)
		sigma_n = (1 + ii * I_sigma) * sigma_b
	
		W_forreflectivity[4 * (ii + 3) + 6] = h / NUMSLICES
		W_forreflectivity[4 * (ii + 3) + 7] = w[7]
		W_forreflectivity[4 * (ii + 3) + 8] = 100 - 100 * phi
		if(ii < NUMSLICES - 1)
			W_forreflectivity[4 * (ii + 3) + 9] = sigma_n
		else
			W_forreflectivity[5] = sigma_n
		endif
	endfor

	//now ask the reflectivity calculation to be carried out.
	motofit(W_forreflectivity, yy, xx)
End

//an easy calculator for the sld profile
//assumes that the W_forreflectivity wave from above is already in the current datafolder
Function calculateSLDprofile()
	make/n=500/d/o SLD
	Wave W_forreflectivity
	Moto_SLDplot(W_forreflectivity, SLD)
	display/K=1 SLD
End
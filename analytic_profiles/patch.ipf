#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "MOTOFIT_all_at_once"

// INSTRUCTIONS:
// 0) Start Motofit.
// 1) Create individual coefficient waves for each patch.  These coefficient waves must be 4N+6
//     parameters long, where N is the number of layers.
//
//	0 - nlayers
//	1 - scale
//	2 - SLDfronting
//	3 - SLDbacking
//	4 - bkg
//	5 - roughness layer_(N) / backing medium
//	6 - thickness layer 1
//	7 - SLD layer 1
//	8 - solvent penetration layer 1
//	9 - roughness layer1 / fronting medium
//
// 2) Combine all the parameters into a combined set using combine_patches()
// 3) Remember to hold all the parameters that need to be.  For example, the SLD of the backing medium
//	   may be the same for all patches.  If you want to fit that parameter then you will need to use a global fitter.
//	   e.g. Motofit->MotoGlobalFit->MotoGlobal Fit
// 4) If you want to change the dq/q resolution do it in the main Motofit panel.
// 5) only the first patch has a linear background.  The other background parameters are ignored.

Function combine_patches(list_of_coefs)
	string list_of_coefs
	// concatenates individual coefficient waves (each 4N + 6 long)
	// into a combined patch wave
	variable ii, offset

	make/n=0/d/o W_patches

	for(ii = 0 ; ii < itemsinlist(list_of_coefs) ; ii += 1)
		Wave patch = $(stringfromlist(ii, list_of_coefs))
		if(4 * patch[0] + 6 != numpnts(patch))
			abort "Individual coefficient wave must be 4N + 6 long"
		endif
		offset = numpnts(W_patches)
		redimension/n=(numpnts(W_patches) + numpnts(patch)) W_patches
		W_patches[offset, numpnts(W_patches) - 1] = patch[p - offset]
	endfor
End

Function patch(w, yy, xx): fitfunc
	Wave w, yy, xx

	// Each parameter set is 4N + 6 parameters long. The parameters are laid out as follows.
	// <parameters patch0>, <parameters patch1>,...
	// The coverage of each patch is specified by the scale factor for each set of parameters.
	// At the moment no normalisation is done for the coverage... E.g. below the critical edge
	// for all patches the reflectivity should equal 1.  Thus, the sum total of the scale factors for
	// all the patches should equal 1.
	// The background is taken from patch 0, all other backgrounds are ignored.

	variable offset = 0, total_params, ii, nlayers, bkg
	
	//we want the motofit() function to be calculating on a lin scale.
	string plotyp_bak
	plotyp_bak = Motofit#getMotofitOption("plotyp")
	Motofit#setMotofitOption("plotyp", "2")
	
	total_params = numpnts(w)
	make/n=0/d/free temp_coefs
	make/d/free/n=(numpnts(yy), 0) tempyy
	duplicate/free yy, tempyycalc

	for(ii = 0 ; offset < total_params ; ii += 1)
		redimension/n=(-1, ii + 1) tempyy

		nlayers = w[offset]
		redimension/n=(4 * nlayers + 6) temp_coefs
		temp_coefs[] = w[offset + p]
		if(ii)
			temp_coefs[4] = 0
		endif	
		//calculate the reflectivity, uses constant dq/q smearing.
		Motofit(temp_coefs, tempyycalc, xx)
		tempyy[][ii] = tempyycalc[p] + bkg * temp_coefs[1]
		offset = offset + (4 * nlayers + 6)
	endfor

	// now sum all contributions
	matrixop/o yy = sumrows(tempyy)

	//convert from a lin scale to a scale you would like.
	Motofit#setMotofitOption("plotyp", plotyp_bak)
	moto_lindata_to_plotyp(str2num(plotyp_bak), xx, yy)
End

//Function patch_smeared(w, yy, xx, dx): fitfunc
//	Wave w, yy, xx, dx
//
//	// each parameter set is 4N + 6 parameters long. The parameters are laid out as follows.
//	// scale, <parameters patch0>, <parameters patch1>,...
//	// scale is used to scale the overall reflectivity.
//	// the coverage of each patch is specified by the scale factor for each set of parameters.
//
//	// NOTE
//	// 1)  the coverages are normalised.  For example, the scale factor for patch0 could be 0.8
//	// the scale factor for patch1 could be 0.7.  The overall sum is 0.8 + 0.7 = 1.5.  Thus, the
//	// coverage of patch 0 is 0.8 / 1.5 = 0.53333, the coverage of patch 1 is 0.7 / 1.5 = 0.4667.
//	// 2) The overall background is taken from patch0 parameters
//
//	variable plotyp = str2num(Motofit#getMotofitOption("plotyp"))
//	variable respoints = str2num(Motofit#getMotofitOption("respoints"))
//	if(numtype(respoints))
//		respoints = 21
//	endif
//	variable/g V_gausspoints = respoints
//
//	make/free/d/n=(numpnts(xx), 2) xtemp
//	xtemp[][0] = xx[p]
//	xtemp[][1] = dx[p]
//	
//	variable total_params, ii, nlayers, offset = 1, total_coverage
//	total_params = numpnts(w)
//	make/n=0/d/free coverage, temp_coefs
//	make/d/free/n=(numpnts(yy), 0) tempyy
//	duplicate/free yy, tempyycalc
//
//	for(ii = 0 ; offset < total_params ; ii += 1)
//		redimension/n=(ii + 1) coverage
//		redimension/n=(-1, ii + 1) tempyy
//
//		nlayers = w[offset]
//		coverage[ii] = w[offset + 1]
//		redimension/n=(4 * nlayers + 6) temp_coefs
//		temp_coefs[] = w[offset + p]
//		// scale is 1
//		temp_coefs[1] = 1
//		// background is 0
//		temp_coefs[4] = 0
//		AbelesAll(temp_coefs, tempyycalc, xtemp)
//		tempyy[][ii] = tempyycalc[p]
//		offset = offset + (4 * nlayers + 6)
//	endfor
//	// normalise coverages
//	total_coverage = sum(coverage)
//	coverage /= total_coverage
//	// calculate contribution of each patch
//	tempyy[][] *= coverage[q]
//	// now sum all contributions
//	matrixop/o yy = sumrows(tempyy)
//	
//	// reflectivity needs to be normalised by overall scale factor
//	yy *= w[0]
//	// add in a background.  THe background is taken from the FIRST
//	yy += w[5]
//	
//	// how are you fitting the data?
//	moto_lindata_to_plotyp(plotyp, xx, yy)
//End
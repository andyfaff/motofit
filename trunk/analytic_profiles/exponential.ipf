#pragma rtGlobals=3		// Use modern global access method.

Static Constant NumSlabs = 500
FUnction expo(w, yy, xx):fitfunc
	Wave w, yy, xx
	//w[0] = scale
	//w[1] = SLD fronting
	//w[2] = SLD backing
	//w[3] = bkg

	//w[4] = thick layer 1 
	//w[5] = volfrac layer1
	//w[6] = decay length adjoining layer
	//w[7] = SLD layer 1

	//w[8] = roughness

	variable maxextent, removepoint, ii, layers, layerthickness

	//make volumefraction profiles
	maxextent = 5* w[6] + 4 * w[8] + w[4]
	make/n=(NUMSLABS * 2 + 1)/o/d volfracprofile, gaussian, vpfronting, vpbacking
	setscale/I x -(maxextent), maxextent, volfracprofile, gaussian, vpfronting, vpbacking
	gaussian = gauss(x, 0, w[8])
	volfracprofile = 0
	volfracprofile = (x < w[4] && x >= 0) ? w[5] : volfracprofile
	volfracprofile = (x > w[4]) ? w[5] * exp(-(x - w[4]) / w[6]) : volfracprofile
	vpfronting = (x < 0) ? 1 : 0
	vpbacking = 1 - vpfronting - volfracprofile	
	
	//convolution and work out the SLD's
	convolve/A gaussian, volfracprofile, vpfronting, vpbacking
	layerthickness = dimdelta(volfracprofile, 0)
	duplicate/free volfracprofile, SLD
	multithread SLD = layerthickness * (vpfronting * w[1] + vpbacking * w[2] + volfracprofile * w[7])
	
	//remove everything that we don't need
	removepoint = x2pnt(volfracprofile, maxextent - 3 * w[8])
	deletepoints removepoint, dimsize(volfracprofile, 0), volfracprofile, vpfronting, vpbacking, SLD
	removepoint = x2pnt(volfracprofile, -3.5 * w[8])
	deletepoints 0, removepoint + 1, volfracprofile, vpfronting, vpbacking, SLD
	
	//now create a layer represention that we can calculate the reflectivity from.
	layers = dimsize(SLD, 0)
	make/n=(4 * layers + 6)/d/free W_forreflectivity = 0
	W_forreflectivity[0] = layers
	W_forreflectivity[1] = w[0]
	W_forreflectivity[2] = w[1]
	W_forreflectivity[3] = w[2]
	W_forreflectivity[4] = w[3]
	W_forreflectivity[5] = 0

	for(ii = 0 ; ii < layers ; ii+=1)
		W_forreflectivity[4 * ii + 6] = layerthickness
		W_forreflectivity[4 * ii + 7] = SLD[ii]
		W_forreflectivity[4 * ii + 8] = 0
		W_forreflectivity[4 * ii + 9] = 0
	endfor
	
//	motofit(W_forreflectivity, yy, xx)
End
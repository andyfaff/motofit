#pragma rtGlobals=1		// Use modern global access method.

constant NUMSTEPS = 30
constant DELRHO = 0.03
constant lambda = .0

Function Chebyshevapproximator(w, yy, xx): fitfunc
	Wave w, yy, xx
	//w[0] = number of slabs
	//w[1] = scale
	//w[2] = fronting SLD
	//w[3] = backing SLD
	//w[4] = bkg
	//w[5] =
	Wave coef_forReflectivity = createCoefs_ForReflectivity(w)
	motofit(coef_forReflectivity, yy, xx)
//	yy = log(yy)
	
End

Function/wave createCoefs_ForReflectivity(w)
	wave w
	
	variable ii, xmod
	variable lastz, lastSLD, numlayers = 0, thicknessoflastlayer=0, MAX_LENGTH
	variable chebdegree = dimsize(w, 0) - (w[0] * 3 + 7)
	MAX_LENGTH = w[w[0] * 3 + 6]
	
	make/d/free/n=(NUMSTEPS) chebSLD
	setscale/I x, 0, MAX_LENGTH, chebSLD

	for(ii = 0 ; ii < chebdegree ; ii+=1)
		multithread		chebSLD += calcCheb(w[(w[0] * 3 + 7) + ii], MAX_LENGTH, ii,  x)
	endfor
	
	make/d/o/n=6 coef_forReflectivity = w
	lastz = -MAX_LENGTH/(NUMSTEPS - 1)
	numlayers = 0
	
	//add in the number of layers that already exist
	redimension/d/n=(dimsize(coef_forreflectivity,0) + 4 * w[0]) coef_forreflectivity
	for(ii = 0 ; ii < w[0] ; ii+=1)
		coef_forreflectivity[4 * ii + 6] = w[3 * ii + 6]
		coef_forreflectivity[4 * ii + 7] = w[3 * ii + 7]
		coef_forreflectivity[4 * ii + 8] = 0
		coef_forreflectivity[4 * ii + 9] = w[3 * ii + 8]
		numlayers += 1
		coef_forreflectivity[0] = numlayers
	endfor
	
	if(numlayers == 0)
		lastSLD = w[2]
	else
		lastSLD = w[3* (w[0]-1) + 7]
	endif
	//now add in the chebyshev
	for(ii = 0 ; ii < dimsize(chebSLD, 0) ; ii+=1)
		if(abs(chebSLD[ii] - lastSLD) > delrho)
			redimension/n=(dimsize(coef_forReflectivity, 0) + 4) coef_forReflectivity
			coef_forReflectivity[4 * numlayers + 6] = MAX_LENGTH/(NUMSTEPS - 1)
			coef_forReflectivity[4 * numlayers + 7] = (chebSLD[ii])
			coef_forReflectivity[4 * numlayers + 8] = 0
			coef_forReflectivity[4 * numlayers + 9] = 0
			
			lastSLD = chebSLD[ii]
			numlayers += 1
			coef_forReflectivity[0] = numlayers
			thicknessoflastlayer = 0
		elseif(numlayers>0)
			coef_forReflectivity[4 * (numlayers - 1) + 6] += MAX_LENGTH/(NUMSTEPS - 1)
		endif
		lastz = pnt2x(chebsld, ii)
	endfor

	return coef_forReflectivity
End

Function chebby(w, yy, xx):fitfunc
	wave w, yy, xx

	variable ii, xmod
	variable lastz, lastSLD, numlayers = 0, thicknessoflastlayer=0, MAX_LENGTH
	variable chebdegree = dimsize(w, 0) - (w[0] * 3 + 7)
	MAX_LENGTH = w[w[0] * 3 + 6]
	yy=0
	for(ii = 0 ; ii < chebdegree ; ii+=1)
		multithread		yy += calcCheb(w[(w[0] * 3 + 7) + ii], MAX_LENGTH, ii,  xx)
	endfor


End

Threadsafe Function calcCheb(coef, MAX_LENGTH, degree, x)
	variable coef, MAX_LENGTH, degree, x
	variable xmod
	xmod = 2 * (x/MAX_LENGTH) - 1
	return coef * chebyshev(degree, xmod) 
End

Function smoother(coefs, y_obs, y_calc, s_obs)
	Wave coefs, y_obs, y_calc, s_obs

	variable retval, betas = 0, ii
	
	make/n=(numpnts(y_obs))/free/d diff
	multithread diff = ((y_obs-y_calc)/s_obs)^2
	retval = sum(diff)
	
	Wave coef_forreflectivity = createCoefs_ForReflectivity(coefs)
	for(ii = 0 ; ii < coef_forreflectivity[0] + 1 ; ii+=1)
		if(ii == 0)
			betas += (coef_forreflectivity[2] - coef_forreflectivity[7])^2
		elseif(ii == coef_forreflectivity[0])
			betas += (coef_forreflectivity[3] - coef_forreflectivity[(4 * (ii - 1)) + 7])^2
			if(abs(coef_forreflectivity[3] - coef_forreflectivity[(4 * (ii - 1)) + 7]) > 0.5)
				retval *= 10
			endif
		else
			betas += (coef_forreflectivity[4 * (ii-1) + 7] - coef_forreflectivity[4 * ii  + 7])^2
		endif
		if(coef_forreflectivity[4 * (ii-1) + 7] < -0.1) 
			retval*=10
		endif
	endfor	

	return retval + lambda * betas
end
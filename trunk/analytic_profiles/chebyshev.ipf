#pragma rtGlobals=1		// Use modern global access method.

constant NUMSTEPS = 40
constant DELRHO = 0.05
constant lambda = 10

Function Chebyshevapproximator(w, yy, xx): fitfunc
	Wave w, yy, xx

	createCoefs_ForReflectivity(w)
	Wave coef_forReflectivity
	Abelesall(coef_forReflectivity, yy, xx)
	multithread yy = log(yy)
	
End

Function createCoefs_ForReflectivity(w)
	wave w
	
	variable ii, jj, xmod, multiplier
	variable lastz, lastSLD, numlayers = 0, MAX_LENGTH
	variable chebcoefs = dimsize(w, 0) - (w[0] * 3 + 7)
	MAX_LENGTH = w[w[0] * 3 + 6]

	//make the wave to calculate the reflectivity
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
		
	//now add in the chebyshev
	//work out the interpolation points, this is the same as the number of chebyshev coefs.
	//a_n are the chebyshev coefficients.
	//chebNodes are the Chebyshev abscissa.
	//it may be better to fit the SLD at those nodes rather than chebyshev coefs.
	make/d/n=(chebcoefs )/free chebNodes, a_n	
	chebnodes = -cos(p *Pi/(chebcoefs-1))
	
	for(ii = 0 ; ii < chebcoefs ; ii+=1)
		for(jj = 0 ; jj < chebcoefs ; jj+=1)
			if(!jj  || jj == chebcoefs -1 )
				multiplier = 0.5
			else
				multiplier = 1
			endif
			variable data = w[(w[0] * 3 + 7) + jj]
			a_n[ii] += multiplier * w[(w[0] * 3 + 7) + jj] * Chebyshev(ii, chebnodes[jj])
		endfor
	endfor
	a_n *= 2/(chebcoefs - 1)
	
	make/d/n=(NUMSTEPS)/free chebSLD
	setscale/I x, 0, MAX_LENGTH, chebSLD
	
	//this is an interpolated SLD profile thro' the cheb nodes
	multithread chebSLD = calcCheb(a_n, 2 * (x / MAX_LENGTH) - 1)
	
	
	if(numlayers == 0)
		lastSLD = w[2]
	else
		lastSLD = w[3* (w[0]-1) + 7]
	endif
	for(ii = 0 ; ii < dimsize(chebSLD, 0) ; ii+=1)
		if(abs(chebSLD[ii] - lastSLD) > delrho)
			redimension/n=(dimsize(coef_forReflectivity, 0) + 4) coef_forReflectivity
			coef_forReflectivity[4 * numlayers + 6] = MAX_LENGTH/(NUMSTEPS - 1)
			coef_forReflectivity[4 * numlayers + 7] = (chebSLD[ii])
			coef_forReflectivity[4 * numlayers + 8] = 0
			coef_forReflectivity[4 * numlayers + 9] = 0.0
			
			lastSLD = chebSLD[ii]
			numlayers += 1
			coef_forReflectivity[0] = numlayers
		elseif(numlayers > 0)
			coef_forReflectivity[4 * (numlayers - 1) + 6] += MAX_LENGTH/(NUMSTEPS - 1)
		endif
		lastz = pnt2x(chebsld, ii)
	endfor

End

Threadsafe Function calcCheb(a_n, x)
wave a_n
variable x

variable ii, summ = 0, multiplier = 1
for(ii = 0 ; ii < numpnts(a_n) ; ii+=1)
	if(ii == 0 || ii == numpnts(a_n)-1)
		multiplier = 0.5
	else
		multiplier = 1
	endif
	summ += multiplier * a_n[ii] * Chebyshev(ii, x)
endfor
return summ
End

//Function smoother(coefs, y_obs, y_calc, s_obs)
//	Wave coefs, y_obs, y_calc, s_obs
//
//	variable retval, betas = 0, ii
//	
//	make/n=(numpnts(y_obs))/free/d diff
//	multithread diff = ((y_obs-y_calc)/s_obs)^2
//	retval = sum(diff)
//	
//	Wave coef_forreflectivity = createCoefs_ForReflectivity(coefs)
//	for(ii = 0 ; ii < coef_forreflectivity[0] + 1 ; ii+=1)
//		if(ii == 0)
//			betas += (coef_forreflectivity[2] - coef_forreflectivity[7])^2
//		elseif(ii == coef_forreflectivity[0])
//			betas += (coef_forreflectivity[3] - coef_forreflectivity[(4 * (ii - 1)) + 7])^2
//			if(abs(coef_forreflectivity[3] - coef_forreflectivity[(4 * (ii - 1)) + 7]) > 0.5)
//				retval *= 10
//			endif
//		else
//			betas += (coef_forreflectivity[4 * (ii-1) + 7] - coef_forreflectivity[4 * ii  + 7])^2
//		endif
//		if(coef_forreflectivity[4 * (ii-1) + 7] < -0.1) 
//			retval*=10
//		endif
//	endfor	
//
//	return retval + lambda * betas
//end

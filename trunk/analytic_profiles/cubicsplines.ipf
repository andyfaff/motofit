#pragma rtGlobals=3		// Use modern global access method.
#pragma ModuleName=cubicspline

Constant NUMSTEPS = 100
Constant WSMOOTH = 0.0
Constant WSMOOTH1 = 0.0

Function lagrangeSmoother(coefs, yobs, ycalc, sobs)
	wave coefs, yobs, ycalc, sobs
	
	variable numknots, Nc, A1, A2, ii, knotoffset, knotmean
	numknots = numpnts(coefs) - 6 - 3 * coefs[0]
	knotoffset = 3 * coefs[0] + 6
	
	duplicate/free/r=[knotoffset, knotoffset + numknots] coefs, knots	
	knotmean = mean(knots)
	
	A1 = 0
	A2 = 0
	for(ii = 0 ; ii < numknots - 1 ; ii+=1)
		A1 +=  (knots[ii + 1] - knots[ii])^2 + WSMOOTH1 * knots[0]^2
		A2 += (knots[ii] - knotmean)^2
	endfor
	
	Nc = ((1-WSMOOTH) * A1 * (numknots + 2) + WSMOOTH * 150 * A2 / (numknots + 2)) * numpnts(yobs)

	duplicate/free yobs, chi2
	multithread chi2 = ((chi2 - ycalc)/ sobs)^2
	NVAR LAMBDA
	return sum(chi2) + LAMBDA * Nc
End

Function cubicSplineRefFitter(w, yy, xx):fitfunc
	wave w, yy, xx
	//w[0] = number of layers that already exist (assumed to be at top)
	//w[1] = scale
	//w[2] = SLD fronting
	//w[3] = SLD backing
	//w[4] = bkg
	//w[5] = thickness 1st prexisting layer
	//w[6] = SLD 1st preexisting layer
	//w[7] = roughness 1st preexisting layer
	//........
	//w[5 + 3*w[0]] = max thickness of cubic spline region
	//w[5 + 3*w[0] + 1 + 1] = aj of first knot
	//w[5 + 3*w[0] + n + 1] = aj of nth knot
	Wave coef_forReflectivity = cubicspline#createCoefs_ForReflectivity(w)
	motofit(coef_forReflectivity, yy, xx)
End

Static Function/Wave createCoefs_forReflectivity(w)
	Wave w
	
	variable ii, xmod
	variable lastz, lastSLD, numlayers = 0, thicknessoflastlayer=0, zmax
	variable stepsize
	
	zmax = w[w[0] * 3 + 5]
	
	make/d/free/n=(NUMSTEPS + 1) cubicSLD, zed
	zed = p * zmax / (NUMSTEPS)
	stepsize = zed[1] - zed[0]

//	make/free/n=(numpnts(w) - 4 - 3 * w[0])/d cubicAJ
//	cubicAJ[1, numpnts(cubicAJ) - 2] = w[p + 6 + 3 * w[0]]
	duplicate/free/r=[5 + 3*w[0] + 1, numpnts(w) - 1] w, cubicAJ
//	insertpoints 0, 1, cubicAJ
//	if(w[0] == 0)
//		cubicAJ[0] = w[2]
//	else
//		cubicAJ[0] = w[3 * (w[0] - 1) + 6]
//	endif
//	redimension/n=(numpnts(cubicAJ) + 1) cubicAJ
//	cubicAJ[numpnts(cubicAJ) - 1] = w[3]
//	
	cubicSplineCurve(cubicAJ, cubicSLD, zed)
	
	//add in the number of layers that already exist
	make/d/o/n=(4 * w[0] + 6)/free coef_forReflectivity = w	
	coef_forReflectivity[5] = 0
	
	for(ii = 0 ; ii < w[0] ; ii+=1)
		coef_forreflectivity[4 * ii + 6] = w[3 * ii + 5]
		coef_forreflectivity[4 * ii + 7] = w[3 * ii + 6]
		coef_forreflectivity[4 * ii + 8] = 0
		coef_forreflectivity[4 * ii + 9] = w[3 * ii + 7]
	endfor
	numlayers = w[0]
	
	//now add in the cubic splines
	for(ii = 0 ; ii < NUMSTEPS ; ii+=1)
			redimension/n=(dimsize(coef_forReflectivity, 0) + 4) coef_forReflectivity
			coef_forReflectivity[4 * ii + 4 * w[0] + 6] = stepsize
			coef_forReflectivity[4 * ii + 4 * w[0]  + 7] = cubicSLD[ii + 0.5]
			coef_forReflectivity[4 * ii + 4 * w[0]  + 8] = 0
			coef_forReflectivity[4 * ii + 4 * w[0]  + 9] = 0
			
			coef_forReflectivity[0] += 1
	endfor

	return coef_forReflectivity
End


Function cubicSplineCurve(aj, rho, z):fitfunc
	wave aj, rho, z
	//implements the splines in Pederson, J.Appl.Cryst. (1992), 25, 129-145
	//with the addition that a spline at the start and end are added.

	//w[0] and w[numpnts(w) - 1] are the start and end points. They should be tied to any value at the start
	//and end.

	//z is the domain of the independent variable.  If z is large and the spline requires sharp features, then the number
	//of knot points, controlled by length of w, should be increased.
	
	//rho is filled out. It should have same length as z. Please note that if aj=1, then the value returned by this function is 1.
	
	variable zmax, Nb, ii

	zmax = z[numpnts(z) - 1] - z[0]
	Nb = dimsize(aj, 0) + 2
	duplicate/free z, xx
	multithread xx[] = ((z[p] - z[0])  * (Nb - 1)/zmax) + 1

	multithread rho = 0

	for(ii = 2 ; ii < Nb ; ii+=1)
		multithread rho[] += aj[ii - 2] * cubicBN(xx[p], ii, Nb)
	endfor
	multithread rho /= 6
End 

threadsafe Function cubicBN(x, n, Nb)
	variable x, n, Nb
	//implements the splines in Pederson, J.Appl.Cryst. (1992), 25, 129-145

	variable delx, val

	delx = x - n
	
	if(delx < -2 || delx >= 2)
		return 0
	endif

	if(n==2)
		if(-2 <= delx && delx < -1)
			return 6
		elseif(-1 <= delx && delx < 0)
			return -delx^3 - 3 * delx^2 - 3*delx + 5
		elseif(0 <= delx && delx < 1)
			return 2 * delx^3 - 3 * delx^2 - 3*delx + 5
		elseif(1 <= delx && delx < 2)
			return (2 - delx)^3
		else
			return 0		
		endif
	elseif(n==Nb - 1)
		if(-2 <= delx && delx < -1)
			return (2 + delx)^3
		elseif(-1 <= delx && delx < 0)
			return -2 * delx^3 - 3 * delx^2 + 3 * delx + 5
		elseif(0 <= delx && delx < 1)
			return delx^3 - 3 * delx^2 + 3 * delx + 5
		elseif(1 <= delx && delx < 2)
			return 6
		else
			return 0		
		endif
	else
		if(-2 <= delx && delx < -1)
			return  (2 + delx)^3
		elseif(-1 <= delx && delx < 0)
			return  	 (2 + delx)^3 - 4 * (1 + delx)^3
		elseif(0 <= delx && delx < 1)
			return	 (2 - delx)^3 - 4 * (1 - delx)^3	
		elseif(1 <= delx && delx < 2)
			return (2 - delx)^3
		else
			return 0		
		endif
	endif

End




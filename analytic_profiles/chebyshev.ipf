#pragma rtGlobals=1		// Use modern global access method.

constant NUMSTEPS = 100
constant DELRHO = 0.04

Function Chebyshevapproximator(w, yy, xx): fitfunc
Wave w, yy, xx

variable ii, xmod
variable chebdegree = dimsize(w, 0) - 7
variable lastz, lastSLD, numlayers = 0, thicknessoflastlayer=0, MAX_LENGTH

MAX_LENGTH = w[6]

make/d/free/n=(NUMSTEPS) chebSLD
setscale/I x, 0, MAX_LENGTH, chebSLD

	for(ii = 0 ; ii < chebdegree ; ii+=1)
		multithread		chebSLD += calcCheb(w[ii + 7], MAX_LENGTH, ii,  x)
	endfor

	make/d/o/n=6 coef_forReflectivity = w
	lastz = -MAX_LENGTH/(NUMSTEPS - 1)
	lastSLD = w[2]
	numlayers = 0
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
//	print numlayers
	AbelesAll(coef_forReflectivity, yy, xx)
//	yy = yy * x^4
	yy = log(yy)
End


Threadsafe Function calcCheb(coef, MAX_LENGTH, degree, x)
variable coef, MAX_LENGTH, degree, x
variable xmod
	xmod = 2 * (x/MAX_LENGTH) - 1
	return coef * chebyshev(degree, xmod) 
End


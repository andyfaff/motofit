#pragma rtGlobals=1		// Use modern global access method.
#include "MOTOFIT_all_at_once"
Function smearingtest(w, RR, qq, dq) :Fitfunc
	Wave w, RR, qq, dq
	variable bkg
	//don't want to convolve the reflectivity if the background has been added		
	variable mode = mod(numpnts(w) - 6, 4)
	
	variable ii, jj	
	variable respoints = 1001
	
	make/free/d/n=(numpnts(qq)) restemp
	make/free/d/n=(respoints) gau, qvals, rvals
	restemp = dq / ((2*sqrt(2*ln(2))))
		
	if(!mode)
		bkg = abs(w[4])
		w[4] = 0
	endif
	variable LIMITer = 4
	for(ii = 0 ; ii < numpnts(RR) ; ii+=1)
		setscale/I x, qq[ii] - limiter * restemp[ii], qq[ii] + limiter * restemp[ii], gau, rvals
		gau = gauss(x, qq[ii], restemp[ii])
		qvals = pnt2x(gau, p)
		abelesall(w, rvals, qvals)
		
		rvals *= gau// * deltax(gau)
		RR[ii] = area(rvals)
	endfor
	//add in the linear background again
	if(!mode)
		w[4] = bkg
	else
		w[6] = bkg
	endif
		
	fastop RR = (bkg) + RR

	//how are you fitting the data?
	RR = log(RR)
//	RR*=qq^4
End

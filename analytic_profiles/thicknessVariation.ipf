#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "MOTOFIT_all_at_once"

Function thicknessvariation(w, yy, xx):fitfunc
wave w, yy, xx

variable SD = w[0], THICK = w[7]
duplicate/free w, origcoef
deletepoints 0, 1, origcoef

variable weight, ii, inX, INTERVALS = 21

duplicate/free yy, temp
origcoef[4] = 0
yy = 0

for(ii = 0 ; ii < INTERVALS ; ii += 1)
	inX = THICK - 3 * SD + 6 * SD * ii/ (INTERVALS - 1)
	weight = 1/SD/sqrt(2*Pi) * exp(-0.5 * ((inX - THICK)/sd)^2)
	origcoef[6] = inX
	motofit(origcoef, temp, xx)
	moto_plotyp_to_lindata(1, xx, temp)
	
	yy += weight * temp
endfor
	yy *= 6 * SD / INTERVALS
	yy += w[5]
	moto_lindata_to_plotyp(1, xx, yy)
	
End
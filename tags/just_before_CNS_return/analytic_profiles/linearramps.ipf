#pragma rtGlobals=3		// Use modern global access method.
Constant SLDincrement = 0.05
Constant MINthickness = 1

Function Rampy(w, yy, xx):fitfunc
Wave w, yy, xx
//w[0] = number of ramps
//w[1] = scale
//w[2] = SLD fronting
//w[3] = SLD backing
//w[4] = bkd
//w[5] = thick ramp0
//w[6] = ENDSLD ramp0
//w[2 * n + 5] = thick rampn
//w[2 * n + 6] = ENDSLD rampn

variable ii, jj, lastSLD, SLDlastramp, numslabs, slabthick, m, c

make/n=6/o/d coef_forreflectivity = 0
coef_forreflectivity[1] = w[1]
coef_forreflectivity[2] = w[2]
coef_forreflectivity[3] = w[3]
coef_forreflectivity[4] = w[4]
coef_forreflectivity[5] = 0

w[2 * (w[0] - 1) + 6] = w[3]

lastSLD = w[2]
SLDlastramp = w[2]
for(ii = 0 ; ii < round(w[0]) ; ii += 1)
	if(w[2 * ii + 5] == 0)
		continue
	endif
	m = (w[2 * ii + 6] - SLDlastramp) / w[2 * ii + 5]
	c = SLDlastramp
	
	numslabs = round(abs((w[2 * ii + 6] - SLDlastramp)/ SLDincrement))
	if(numslabs == 0)
		numslabs = 1
	endif
	
	slabthick = w[2 * ii + 5] / numslabs
	
	if(slabthick < MINthickness)
		numslabs = round(w[2 * ii + 5] / minthickness) 
		if(!numslabs)
			numslabs = 1
		endif
		slabthick = w[2 * ii + 5] / numslabs
	endif
	for(jj = 0 ; jj < numslabs; jj += 1)
		redimension/n=(dimsize(coef_forreflectivity, 0) + 4) coef_forreflectivity
		coef_forreflectivity[4 * coef_forreflectivity[0] + 6] = slabthick
		coef_forreflectivity[4 * coef_forreflectivity[0] + 7] = (jj + 0.5) * m * slabthick + c
		coef_forreflectivity[4 * coef_forreflectivity[0] + 8] = 0
		coef_forreflectivity[4 * coef_forreflectivity[0] + 9] = 0
		coef_forreflectivity[0] += 1
	endfor
	SLDlastramp = w[2 * ii + 6]
endfor

Motofit(coef_forreflectivity, yy, xx)
End
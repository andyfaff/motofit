#pragma rtGlobals=1		// Use modern global access method.
Function adaptiveSlicer(yy, xx, change)
Wave yy, xx
variable change

variable ii, lastxx, lastyy, gradient, areas
make/o/d/n=(1, 2) W_adapt
W_adapt[0][0] = xx[0]
W_adapt[0][1] = yy[0]

lastxx = xx[0]
lastyy = yy[0]

differentiate yy/x=xx/d=dif_XX
dif_XX = abs(dif_XX)
areas = areaxy(xx, dif_XX)
killwaves dif_XX
for(ii = 0 ; ii < numpnts(xx) ; ii += 1)
	if(abs((yy[ii] - lastyy)*(xx[ii] - lastxx)) >  areas/60 || ii == numpnts(xx) - 1)
		redimension/n=(dimsize(W_adapt, 0) + 1, -1) W_adapt
		W_adapt[dimsize(W_adapt, 0) - 1][0] = xx[ii]
		W_adapt[dimsize(W_adapt, 0) - 1][1] = yy[ii]
		lastyy = yy[ii]
		lastxx = xx[ii]
	endif
endfor
duplicate/o W_adapt, W_layers
redimension/n=(dimsize(W_adapt, 0) - 1, -1) W_layers
W_layers[][0] = W_adapt[p+1][0] - W_adapt[p][0]
W_layers[][1] = 0.5 * (W_adapt[p][1] + W_adapt[p+1][1])
//W_layers[][1] =W_adapt[p][1]

End

Function insertintocoefs()
Wave coefs,W_layers
variable ii
for(ii = 0 ; ii < dimsize(W_layers, 0) ; ii+=1)
	coefs[4 * ii + 6] = W_layers[ii][0]
	coefs[4 * ii + 7] = W_layers[ii][1]
	coefs[4 * ii + 8] = 0
	coefs[4 * ii + 9] = 1/2 * W_layers[ii][0]
endfor
End
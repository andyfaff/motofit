#pragma rtGlobals=1		// Use modern global access method.


//This version intended for MOTOFIT_IMAG version of Motofit

constant NUMSLICES = 71

Function SLDcalc(w,xx)
Wave w
variable xx
//w[0] = D1
//w[1] = D2
//w[2] = t
//w[3] = SLD1
//w[4] = SLD2
//w[5] = k
//w[6] = C0

//w[0] = scalefactor
//w[1] = SLDsuperphase(air)
//w[2] = SLDsubphase(Si)
//w[3] = background
//w[4] = roughness of Si-SiO2 interface
//w[5] = thickness of SiO2 layer
//w[6] = SLD of SiO2 layer
//w[7] = roughness of SiO2-layer2 interface
//w[8] = thickness of layer1
//w[9] = roughness of layer1-air interface
//w[10] = thickness of layer 2
//w[11] = D1
//w[12] = D2
//w[13] = t
//w[14] = SLD1
//w[15] = SLD2
//w[16] = k
//w[17] = C0
variable val = NaN

if(xx <= 0)
	val =  (w[16]*w[17]/(1+w[16]*sqrt(w[12]/w[11]))) 
	val *= erfc(abs(xx)/(2*sqrt(w[12]*w[13])))
	val *= (w[15]-w[14])
	val += w[14]
elseif (xx > 0)
	val =  (w[17]/(1+w[16]*sqrt(w[12]/w[11]))) 
	val *= 1+w[16]*sqrt(w[12]/w[11])* erf(xx/(2*sqrt(w[11]*w[13])))
	val *= (w[15]-w[14])
	val += w[14]
else
endif

	return val
End

Function bilayer_diff(w,RR,qq):fitfunc
Wave w, RR, qq
//w[0] = scalefactor
//w[1] = SLDsuperphase(air)
//w[2] = SLDsubphase(Si)
//w[3] = background
//w[4] = roughness of Si-SiO2 interface
//w[5] = thickness of SiO2 layer
//w[6] = SLD of SiO2 layer
//w[7] = roughness of SiO2-layer2 interface
//w[8] = thickness of layer1
//w[9] = roughness of layer1-air interface
//w[10] = thickness of layer 2
//w[11] = D1
//w[12] = D2
//w[13] = t
//w[14] = SLD1
//w[15] = SLD2
//w[16] = k
//w[17] = C0

//4 (parameters each layer) * NUMBER OF SLICES * 2 (number of polymer layers) + 8 (required even for a no-layer model) + 4 (SiO2 layer)
make/o/d/n=(4 * NUMSLICES * 2 +8 + 4) funcoefs		
variable ii, sublayerthickness1, sublayerthickness2

funcoefs[0] =2*NUMSLICES+1
funcoefs[1] = w[0]
funcoefs[2] = w[1]
funcoefs[3] = 0
funcoefs[4] = w[2]
funcoefs[5] = 0
funcoefs[6] = w[3]
funcoefs[7] = w[4]

//parameters 6 to 9 is the surface that is closest to air for layer 1.  We assume that it has the same SLD as virgin layer 1.  
//Note that if the diffusion is extensive this assumption will not be correct.
//the overall thickness of layer 1 is reduced by the width of the erf function on this side.
sublayerthickness1 = w[8]/NUMSLICES
for(ii = 0 ; ii< NUMSLICES ; ii+=1)
	funcoefs[4*ii+8] = sublayerthickness1
	funcoefs[4*ii+9] = SLDcalc(w, (-NUMSLICES+ii+0.5)*sublayerthickness1)
	funcoefs[4*ii+10] = 0
	funcoefs[4*ii+11] = 0
	if(ii == 0)
		funcoefs[4*ii+11] = w[9]
	endif
endfor

sublayerthickness2 = w[10]/NUMSLICES
for(ii = 0 ; ii< NUMSLICES ; ii+=1)
	funcoefs[4*(ii+NUMSLICES) + 8] = sublayerthickness2
	funcoefs[4*(ii+NUMSLICES) + 9] = SLDcalc(w, (ii+0.5)*sublayerthickness2)
	funcoefs[4*(ii+NUMSLICES) + 10] = 0
	funcoefs[4*(ii+NUMSLICES) + 11] = 0
endfor

funcoefs[4*2*NUMSLICES + 8] = w[5]
funcoefs[4*2*NUMSLICES + 9] = w[6]
funcoefs[4*2*NUMSLICES + 10] = 0
funcoefs[4*2*NUMSLICES + 11] = w[7]

Motofit(funcoefs,RR,qq)
//RR= log(RR)

End
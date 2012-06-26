#pragma rtGlobals=1		// Use modern global access method.
Function lipid(coefs,rr,qq):fitfunc
	wave coefs,qq,rr

	lipidtoRef(coefs)
	Wave W_forReflectivity

	Abelesall(W_forreflectivity,RR,qq)
	RR=log(RR)
End

Function lipidtoRef(coefs)
	Wave coefs
	//coefs[0]=scalefactor
	//coefs[1]=SLDsuperphase (silicon?) 						FIX
	//coefs[2]=SLDsolvent (d2o mix?) 
	//coefs[3]=background
	//coefs[5]=oxide thickness
	//coefs[6]=SLDoxide
	//coefs[7]=roughness of si/sio2
	//coefs[8]=roughness of inner lipid head/sio2
	//coefs[9]=Vh, headvolume 								FIX
	//coefs[10]= bh, sum of scattering lengths of headgroup 	FIX
	//coefs[11]= Vt, molecular volume of tailgroup 				FIX
	//coefs[12]= bt, sum of scattering lengths of tailgroup		FIX
	//coefs[13]=Area per molecule (inner)
	//coefs[14]=thickness of inner leaflet head
	//coefs[15]=thickness of inner leaflet chain 
	//coefs[16]=Area per molecule (outer)
	//coefs[17]=thickness of outer leaflet chain
	//coefs[18]=thickness of outer leaflet head
	//coefs[19]=roughness of lipid layers

	make/o/d/n=(5*4+6) W_forReflectivity

	W_forReflectivity[0] = 5
	W_forreflectivity[1] = coefs[0]
	W_forreflectivity[2] = coefs[1]
	W_forreflectivity[3] = coefs[2]
	W_forreflectivity[4] = coefs[3]
	W_forreflectivity[5] = coefs[19]

	//SiO2 layer
	W_forreflectivity[6] = coefs[5]
	W_forreflectivity[7] = coefs[6]
	W_forreflectivity[8] = 0
	W_forreflectivity[9] = coefs[7]

	//inner head
	W_forreflectivity[10] = coefs[14]
	W_forreflectivity[11] = coefs[10] / coefs[9]
	W_forreflectivity[12] =  100 - 100 * (coefs[9] / (coefs[13] * coefs[14]))
	W_forreflectivity[13] = coefs[8]

	//inner chain
	W_forreflectivity[14] = coefs[15]
	W_forreflectivity[15] = coefs[12] / coefs[11]
	W_forreflectivity[16] = 100 - 100 * (coefs[11] / (coefs[13] * coefs[15]))
	W_forreflectivity[17] = coefs[19]
	
	//outer tail
	W_forreflectivity[18] = coefs[17]
	W_forreflectivity[19] = coefs[12] / coefs[11]
	W_forreflectivity[20] = 100 - 100 * (coefs[11] / (coefs[16] * coefs[17]))
	W_forreflectivity[21] = coefs[19]
	
	//outer head
	W_forreflectivity[22] = coefs[18]
	W_forreflectivity[23] =  coefs[10] / coefs[9]
	W_forreflectivity[24] =  100 - 100 * (coefs[9] / (coefs[16] * coefs[18]))
	W_forreflectivity[25] = coefs[19]
End
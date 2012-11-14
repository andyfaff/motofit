#pragma rtGlobals=1		// Use modern global access method.
Function monolayer(coefs,rr,qq):fitfunc
	wave coefs,qq,rr
	
	//coefs[0]=scalefactor
	//coefs[1]=SLDsuperphase (air)
	//coefs[2]=SLDsolvent (h2o/d2o)
	//coefs[3]=background
	//coefs[4]= Area per molecule
	//coefs[5] = thickness tails
	//coefs[6] = roughness tails/air
	//coefs[7] = thickness head
	//coefs[8] = roughness head/tails
	//coefs[9] = roughness solvent/head
	//coefs[10] = b tails
	//coefs[11] = V tails
	//coefs[12] = b head
	//coefs[13] = V head	
		
	monolayertoRef(coefs)
	Wave W_forReflectivity

	Abelesall(W_forreflectivity,RR,qq)
	RR=log(RR)
End

Function monolayertoRef(coefs)
	Wave coefs
	
	variable ii
	//coefs[0]=scalefactor
	//coefs[1]=SLDsuperphase (air)
	//coefs[2]=SLDsolvent (h2o/d2o)
	//coefs[3]=background
	//coefs[4]= Area per molecule
	//coefs[5] = thickness tails
	//coefs[6] = roughness tails/air
	//coefs[7] = thickness head
	//coefs[8] = roughness head/tails
	//coefs[9] = roughness solvent/head
	//coefs[10] = b tails
	//coefs[11] = V tails
	//coefs[12] = b head
	//coefs[13] = V head

	make/o/d/n=(2 * 4 + 6) W_forReflectivity

	W_forReflectivity[0] = 2
	W_forreflectivity[1] = coefs[0]
	W_forreflectivity[2] = coefs[1]
	W_forreflectivity[3] = coefs[2]
	W_forreflectivity[4] = coefs[3]
	W_forreflectivity[5] = coefs[9]

	W_forreflectivity[6] = coefs[5]
	W_forreflectivity[7] = coefs[10] / coefs[11]
	W_forreflectivity[8] = 100 * (1 - (coefs[11] / coefs[4] / coefs[5]))
	W_forreflectivity[9] = coefs[6]

	W_forreflectivity[10] = coefs[7]
	W_forreflectivity[11] = coefs[12] / coefs[13]
	W_forreflectivity[12] = 100 * (1 - (coefs[13] / coefs[4] / coefs[7]))
	W_forreflectivity[13] = coefs[8]


End
#pragma rtGlobals=1		// Use modern global access method.
Function jarek_monolayer(coefs,rr,qq):fitfunc
	wave coefs,qq,rr
	
	//coefs[0]=scalefactor
	//coefs[1]=SLDsuperphase (air)
	//coefs[2]=SLDsolvent (h2o)
	//coefs[3]=background
	//coefs[4]=roughness of h2o/monolayer
	//coefs[5]= number of layers
	//coefs[6]= Area per molecule
	
	//for each layer need to have SLD
	// parameterise thickness, num electrons,  volume of scattering entity, roughness
	// i.e. 
	// coefs[4*p + 7] =  thickness of layer p (layer 0 is closest to incident beam)
	//coefs[4*p + 8] =  number of electrons of layer p material
	//coefs[4*p + 9] =  molecular volume of layer p material, this is needed to account for space filling/water ingress.
	//coefs[4*p+10] = roughness of layer (p-1)/p
	
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
	//coefs[2]=SLDsolvent (h2o)
	//coefs[3]=background
	//coefs[4]=roughness of h2o/monolayer
	//coefs[5]= number of layers
	//coefs[6]= Area per molecule
	
	//for each layer need to have SLD
	// parameterise thickness, num electrons,  volume of scattering entity, roughness
	// i.e. 
	// coefs[4*p + 7] =  thickness of layer p (layer 0 is closest to incident beam)
	//coefs[4*p + 8] =  number of electrons of layer p material
	//coefs[4*p + 9] =  molecular volume of layer p material, this is needed to account for space filling/water ingress.
	//coefs[4*p+10] = roughness of layer (p-1)/p

	make/o/d/n=(coefs[5]*4+6) W_forReflectivity

	W_forReflectivity[0] = coefs[5]
	W_forreflectivity[1] = coefs[0]
	W_forreflectivity[2] = coefs[1]
	W_forreflectivity[3] = coefs[2]
	W_forreflectivity[4] = coefs[3]
	W_forreflectivity[5] = coefs[4]

	for(ii=0 ; ii<coefs[5] ; ii+=1)
		//the thickness of the layer
		W_forReflectivity[4*ii + 6] = coefs[4*ii + 7]

		//now work out the SLD of each layer.
		//the volume fraction of material in the layer
		variable phiMaterial = coefs[4*ii+9] /(coefs[6]  * coefs[4*ii+6]) // phi = (molecular volume of material in layer p)/(Area * thickness of layer)
		variable SLDofMaterial = coefs[4*p + 8] *28.179/ coefs[4*ii+9]	// SLD = Z * r_e / molvolume, where r_e is the Compton radius		

		W_forReflectivity[4*ii + 7] = (phiMaterial * SLDofMaterial) + (1-phiMaterial) * coefs[2]
		
		//water ingress is accounted for in the SLD.
		W_forReflectivity[4*ii + 8] = 0
		
		//the roughness of the layer
		W_forReflectivity[4*ii + 9] = coefs[4*ii + 10]
	endfor

End
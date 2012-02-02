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
	//coefs[1]=SLDsuperphase (silicon?)
	//coefs[2]=SLDsolvent (d2o mix?)
	//coefs[3]=background
	//coefs[4]=roughness of silicon
	//coefs[5]=oxide thickness
	//coefs[6]=SLDoxide
	//coefs[7]=roughness of oxide
	//coefs[8]=Area per molecule
	//coefs[9]=Vh, headvolume
	//coefs[10]=rhoh, SLD of headgroup
	//coefs[11]=Vch, chainvolume
	//coefs[12]=rhoch, SLD of chain
	//coefs[13]=thickness of inner leaflet head
	//coefs[14]=thickness of inner leaflet chain 
	//coefs[15]=thickness of outer leaflet chain
	//coefs[16]=thickness of outer leaflet head
	//coefs[17]=roughness of lipid layers

	make/o/d/n=(5*4+6) W_forReflectivity

	W_forReflectivity[0] = 5
	W_forreflectivity[1] = coefs[0]
	W_forreflectivity[2] = coefs[1]
	W_forreflectivity[3] = coefs[2]
	W_forreflectivity[4] = coefs[3]
	W_forreflectivity[5] = coefs[17]

	//SiO2 layer
	W_forreflectivity[6] = coefs[5]
	W_forreflectivity[7] = coefs[6]
	W_forreflectivity[8] = 0
	W_forreflectivity[9] = coefs[4]

	variable phiInnerH = coefs[9]/(coefs[8]*coefs[13])   	//   PhiInner=Vh/(Area*thicknessofinnerHead)
	variable phiOuterH = coefs[9]/(coefs[8]*coefs[16])		//	PhiOuter =Vh/(Area*thicknessofouterHead)
	variable phiInnerC = phiInnerH * coefs[14]*coefs[11]/(coefs[9]*coefs[13])
	variable phiOuterC =  phiOuterH * coefs[15]*coefs[11]/(coefs[9]*coefs[16])

	//inner head
	W_forreflectivity[10] = coefs[13]
	W_forreflectivity[11] = (phiInnerH * coefs[10]) + ((1-phiInnerH)*coefs[2])
	W_forreflectivity[12] = 0
	W_forreflectivity[13] = coefs[7]

	//inner chain
	W_forreflectivity[14] = coefs[14]
	W_forreflectivity[15] = (phiInnerC * coefs[12]) + ((1-phiInnerC)*coefs[2])
	W_forreflectivity[16] = 0
	W_forreflectivity[17] = coefs[17]
	//outer tail
	W_forreflectivity[18] = coefs[15]
	W_forreflectivity[19] = (phiInnerC * coefs[12]) + ((1-phiOuterC)*coefs[2])
	W_forreflectivity[20] = 0
	W_forreflectivity[21] = coefs[17]
	
	//outer head
	W_forreflectivity[22] = coefs[16]
	W_forreflectivity[23] =  (phiOuterH * coefs[10]) + ((1-phiOuterH)*coefs[2])
	W_forreflectivity[24] =  0
	W_forreflectivity[25] = coefs[17]
End
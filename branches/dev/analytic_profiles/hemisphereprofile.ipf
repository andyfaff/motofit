#pragma rtGlobals=1		// Use modern global access method.
Function Moto_hemiSphereProfile(params,yy,qq): fitfunc
	Wave params,yy,qq
	//params contains the fit parameters
	//yy returns the reflectivity curve for this model
	//qq contains all the q values for the fit
	
	//params[0] = Numotherlayers
	//params[1] = SLDupper
	//params[2] = SLDlower
	//params[3] = Background
	//params[4] = Rc
	//params[5] = Rs
	//params[6] = Gamma
	//params[7] = interface roughness of micelle/solid
	//params[4n+8] = thicknessn otherlayer
	//params[4n+9] = SLDn otherlayer
	//params[4n+10] = solventN otherlayer
	//params[4n+11] = roughnessN otherlayer
	
	//parameters 0 to 7 are required.
	
	CalculateHemiProfile(params)
	Wave coef_RefHemiProfile

	//Calculate the reflectivity
	AbelesAll(coef_RefHemiProfile,yy,qq)
	yy = log(yy)

End

Function CalculateHemiProfile(params)
	Wave params
	//params[0] = Numotherlayers
	//params[1] = SLDupper
	//params[2] = SLDlower
	//params[3] = Background
	//params[4] = Rc
	//params[5] = Rs
	//params[6] = Gamma
	//params[7] = interface roughness of micelle/solid
	//params[4n+8] = thicknessn otherlayer
	//params[4n+9] = SLDn otherlayer
	//params[4n+10] = solventN otherlayer
	//params[4n+11] = roughnessN otherlayer
	
	variable Rc = params[4]
	variable Rs = params[5]
	variable Ads_Gamma = params[6]

	//DEFINE some initial setup parameters
	//number of layers that we'll use
	//Numlayers is the number of layers we'll use for your surface structure
	//otherlayers is for layers containing SiO2, etc.
	variable numlayers = 30
	variable otherlayers = params[0]
	//the thickness of each of those layers (in Angstrom), and roughness if required
	variable layerRoughness = 0
	//NOTE that numlayers*layerthickness must be large enough to encompass your surface structure
	//you may get some Fourier oscillations if layer thickness is too large, make it smaller in that case
	//other parameters for hemispherical model
	variable rho_core = 0.62	//sld core
	variable rho_shell = 0.8	//sld shell
	variable vol_core = 1.0
	variable density_core = 1.16
	variable density_shell = 1.16
	variable  nDEA = 24
	variable MwDEA = 185.3
	variable nDMA = 93
	variable MwDMA = 157.2
	//ENDDEFINE
	
	variable Vtot_DEA = (2/3)*Pi * Rc^3
	variable VblockDEA = nDEA*MwDEA/density_core/0.6022
	variable VtotDMA = (2/3)*Pi * (Rs^3 - Rc^3)
	variable VblockDMA = nDMA*MwDMA/density_shell/0.6022
	
	variable Nagg = vol_core * Vtot_DEA/VblockDEA
	variable vol_shell = Nagg/(VtotDMA/VblockDMA)
	variable Atot = Pi*(Rc^3*vol_core*density_core + (Rs^3-Rc^3)*vol_shell*density_shell)/15/Ads_gamma
	
	//how thin we slice the model.
	variable layerthickness = Rs/numlayers
	
	//now make the coefficientwave to send to the reflectivity calculation
	variable numparams = 4*(numlayers+otherlayers)+6
	make/n=(numparams)/o/d coef_RefHemiProfile

	//need to setup what we know so far into the coefficient wave
	variable ii=0

	coef_RefHemiProfile[0] = numlayers+otherlayers
	coef_RefHemiProfile[1] = 1
	coef_RefHemiProfile[2] = params[1]
	coef_RefHemiProfile[3] = params[2]
	coef_RefHemiProfile[4] = params[3]
	coef_RefHemiProfile[5] = 0

	for(ii = 0 ; ii < otherlayers; ii += 1)
		coef_RefHemiProfile[4*ii+6] = params[4*ii+8]
		coef_RefHemiProfile[4*ii+7] = params[4*ii+9]
		coef_RefHemiProfile[4*ii+8] = params[4*ii+10]
		coef_RefHemiProfile[4*ii+9] = params[4*ii+11]
	endfor
	for(ii = otherlayers ; ii < numlayers+otherlayers; ii += 1)
		coef_RefHemiProfile[4*ii+6] = layerThickness
		coef_RefHemiProfile[4*ii+8] = 0
		coef_RefHemiProfile[4*ii+9] = layerRoughness
		if(ii==otherlayers)
			coef_RefHemiProfile[4*ii+9] = params[7]
		endif
	endfor

	//now need to setup the SLD profile
	variable phi_cz,phi_sz,phi_totz,phi_solv, rho_totz,distz
	for(ii = 0 ; ii < numlayers ; ii+=1)
		distz = layerthickness*(ii+0.5)
		
		if(distz <= Rc)
			phi_cz = Pi*vol_core*(Rc^2 - distz^2)/Atot
			phi_sz = Pi*vol_shell*(Rs^2 - Rc^2)/Atot
		else
			phi_cz = 0
			if(distz < Rs)
				phi_sz = Pi*vol_shell*(Rs^2 - distz^2)/Atot
			else
				phi_sz = 0
			endif
		endif
		
		phi_totz = phi_cz + phi_sz
		phi_solv = 1 - phi_totz
		rho_totz = (phi_cz * rho_core) + (phi_sz * rho_shell) + (phi_solv * params[2])
		coef_RefHemiProfile[4*(ii+otherlayers)+7] = rho_totz
	endfor
End

Function PlotHemisphereSLDprofile(params)
	Wave params
	CalculateHemiProfile(params)
	Wave coef_RefHemiProfile
	string str =  Moto_Dummymotofitstring()
	newdatafolder/o root:motofit
	newdatafolder/o root:motofit:reflectivity
	string/g root:motofit:reflectivity:motofitcontrol = str
	
	make/o/n=(numberbykey("sldpts",str))/d zed,sld	
	sld = Moto_SLDplot(coef_RefHemiProfile,zed)
End
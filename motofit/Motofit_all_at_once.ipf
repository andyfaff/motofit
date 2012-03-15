#pragma rtGlobals=3		// Use modern global access method.
#pragma ModuleName = Motofit
#pragma Igormode=6.22
#pragma version = 400

// SVN date:    $Date: 2011-07-18 10:33:32 +1000 (Mon, 18 Jul 2011) $
// SVN author:  $Author: andrew_nelson $
// SVN rev.:    $Revision: 455 $
// SVN URL:     $HeadURL: https://motofit.svn.sourceforge.net/svnroot/motofit/branches/dev/motofit/Motofit/MOTOFIT_all_at_once.ipf $
// SVN ID:      $Id: MOTOFIT_all_at_once.ipf 455 2011-07-18 00:33:32Z andrew_nelson $
	
#include "GeneticOptimisation"
#include "MOTOFIT_globalreflectometry"
#include "MOTOFIT_SLDcalc"
#include "MOTOFIT_batch"
#include "MOTOFIT_Global fit 2"

Menu "Motofit"
	//this function sets up the user menus at the top of the main IGOR window.
	"Fit Reflectivity data",plotCalcref()
	"Load experimental data",Moto_Plotreflectivity()()
	"Co-refine Reflectometry Data", Motofit_GR#init_fitting()
	"SLD calculator", Moto_SLDdatabase()
	"create local chi2map for requested parameter",motofit#Moto_localchi2()
	Submenu "Fit batch data"
		"Load batch data", LoadAndGraphAll ("")
		"Fit batch data", FitRefToListOfWaves()
		//	                        "Extract trends", Trends()
	End
	"About", Motofit#Moto_AboutPanel()
	"Manual", browseURL "dav1-platypus.nbi.ansto.gov.au/Motofitmanual.pdf"
	"-"
	"Transfer data from old version to new version", motofit#moto_transfer_data()
	"-"
End

Function plotcalcref()	
	string cDF = getdatafolder(1)
	String temp=Winlist("reflectivitypanel","","")
	if(strlen(temp)>0)
		return 0
	endif
	
	Variable num=500,qmin=0.005,qmax=0.5,res=5,SLDplotnum=500,plotyp=1, mode = 0
	Prompt num, "Enter number of data points for model: "
	Prompt qmin, "Enter minimum q-value (A^-1) for model: "
	Prompt qmax, "Enter maximum q-value (A^-1) for model: "
	Prompt res, "Enter %resolution (dq/q): "
	Prompt SLDplotnum, "How many points do you want in the SLD plot"
	Prompt plotyp,"Which plot mode?",popup,"logR vs Q;R vs Q;RQ4 vs Q"
	Prompt mode, "Which mode?", popup, "solventpenetration;complex SLD"
	Doprompt "enter plot parameters",num,qmin,qmax,res,SLDplotnum,plotyp, mode

	//if the user doesn't want to continue with the plotting then abort
	if(V_flag==1)
		abort
	endif
	mode -=1
	
	setupdatafolders()
	setupvariables(mode, res, plotyp, SLDplotnum)
	
	//create theoretical model waves
	setdatafolder root:data:theoretical
	make/o/d/n=(num) theoretical_q,theoretical_R
	theoretical_q = qmin+(x)*((qmax-qmin)/num)

	make/o/d/n=(num, 2) originaldata
	originaldata[][0] = theoretical_q[p]
	originaldata[][1] = theoretical_R[p]

	setscale/P x, qmin, ((qmax - qmin) / num), theoretical_R
	make/o/d/n=(SLDplotnum) sld_theoretical_R
	
	if(!mode)
		make/o/d/n=10 coef_theoretical_R={1,1,0,2.07,1e-7,4,25,3.47,0,4}
	else
		make/o/d/n=10 coef_theoretical_R={1,1,0,0,2.07,0,1e-7,4,25,3.47,0,4}
	endif
	
	note/K coef_theoretical_R
	note coef_theoretical_R, getMotofitOptionString()
	
	//start up the SLD database and populate it with a specific database in igorpro/motofit
	//motofit#Moto_SLDdatabase()	
	Moto_Reflectivitypanel()
	
	Moto_reflectivitygraphs()
	
	moto_usecoefWave(coef_theoretical_R)
	
	Autopositionwindow/E/R=ReflectivityGraph/M=1 SLDgraph
	Autopositionwindow/E/R=ReflectivityGraph/M=0 Reflectivitypanel
	
	moto_update_theoretical()
	setdatafolder $cDF
End

static Function Moto_LayerTableToCref(coefficients)
	//this function the layer tables for the model into the correct coefficient wave
	Wave coefficients
	DFREF saveDFR = GetDataFolderDFR()	// Save
	variable ii
	Setdatafolder root:packages:motofit:reflectivity

	Wave/T layerparams,baselayerparams
	variable layers=dimsize(layerparams, 0) - 2
	variable mode = str2num(getmotofitoption("mode"))
	//this is a bodgy way of doing this, but it's difficult to update things.
	//you are changing the number of layers, so you need to change the length of the coefficient wave
	//however the coefficient wave has the numbers for the multilayers on the end.
	//therefore, get rid of the points that represent the layers, then insert points in
	// which will then have the numbers recopied to them.
	if(mode)
		mode = 2
	endif
	if(!mode)
		redimension/n=(4 * layers + 6)/d coefficients
		coefficients[2] = str2num(layerparams[0][3])
		coefficients[3] = str2num(layerparams[dimsize(layerparams, 0) - 1][3])
		coefficients[4] = str2num(baselayerparams[2][1])
		coefficients[5] = str2num(layerparams[dimsize(layerparams, 0) - 1][7])
	else
		redimension/n=(4 * layers + 8)/d coefficients
		coefficients[2] = str2num(layerparams[0][3])
		coefficients[3] = str2num(layerparams[0][5])
		coefficients[4] = str2num(layerparams[dimsize(layerparams, 0) - 1][3])
		coefficients[5] = str2num(layerparams[dimsize(layerparams, 0) - 1][5])
		coefficients[6] =str2num(baselayerparams[2][1])
		coefficients[7] = str2num(layerparams[dimsize(layerparams, 0) - 1][7])
	endif
	coefficients[0] = layers
	coefficients[1] = str2num(baselayerparams[1][1])
	
	for(ii = 0 ; ii < layers ; ii+=1)
		coefficients[4 * ii + 6 + mode] = str2num(layerparams[ii + 1][1])
		coefficients[4 * ii + 7 + mode] = str2num(layerparams[ii + 1][3])
		coefficients[4 * ii + 8 + mode] = str2num(layerparams[ii + 1][5])
		coefficients[4 * ii + 9 + mode] = str2num(layerparams[ii + 1][7])
	endfor
	SetDataFolder saveDFR			// and restore
End



Function moto_usecoefWave(coefficientwave, [shortcut])
	Wave/z coefficientwave
	//shortcut just means that you are changing the values in the coefficient wave, you're not changing the size.
	variable shortcut
	
	variable mode, ii, newplotyp
	string coefnote = "", item = "", key = "", val = "", holdstring

	if(!waveexists(coefficientwave))
		return 1
	endif
	Wave coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	redimension/n=(dimsize(coefficientwave, 0)) coef_theoretical_R
	coef_theoretical_R = coefficientwave

	if(!shortcut)
		coefnote = note(coefficientwave)
		if(coefficientwave[0] * 4 + 6 == numpnts(coefficientwave))
			coefnote = replacenumberbykey("mode", coefnote, 0)
			coefnote = replacenumberbykey("multilayer", coefnote, 0)
		elseif(coefficientwave[0] * 4 + 8 == numpnts(coefficientwave))
			coefnote = replacenumberbykey("mode", coefnote, 1)
			coefnote = replacenumberbykey("multilayer", coefnote, 0)
		elseif(!mod(numpnts(coefficientwave) - coefficientwave[0] * 4 + 6, 4))
			coefnote = replacenumberbykey("mode", coefnote, 0)
			coefnote = replacenumberbykey("multilayer", coefnote, 1)
			coefnote = replacenumberbykey("Vmullayers", coefnote, (numpnts(coefficientwave) - coefficientwave[0] * 4 + 6)/4)
		elseif(!mod(numpnts(coefficientwave) - coefficientwave[0] * 4 + 8, 4))
			coefnote = replacenumberbykey("mode", coefnote, 1)
			coefnote = replacenumberbykey("multilayer", coefnote, 1)
			coefnote = replacenumberbykey("Vmullayers", coefnote, (numpnts(coefficientwave) - coefficientwave[0] * 4 + 8)/4)				
		endif
		
		//copy control string to motofitoptionstring
		for(ii = 0 ; ii < itemsinlist(coefnote) ; ii+=1)
			item = stringfromlist(ii, coefnote)
			key = stringfromlist(0, item, ":")
			val = stringbykey(key, item)
			setmotofitoption(key, val)
		endfor
		//copy over to coef_theoretical_R
		note/k coef_theoretical_R
		note coef_theoretical_R, getmotofitoptionstring()
	
		//update resolution
		SetVariable res_tab0, win=reflectivitypanel, value =_NUM:str2num(getmotofitoption("res"))
		
		//fitting with constraints?
		checkbox useconstraint_tab0, win=reflectivitypanel, value = str2num(getmotofitoption("useconstraint"))

		//fitting between cursors?
		checkbox fitcursors_tab0, win=reflectivitypanel, value = str2num(getmotofitoption("fitcursors"))

		//use dqwave?
		checkbox usedqwave_tab0, win=reflectivitypanel, value = str2num(getmotofitoption("usedqwave"))

		//use error wave?
		checkbox useerrors_tab0, win=reflectivitypanel, value = str2num(getmotofitoption("useerrors"))

		//plotyp?
		//did plotyp change
		controlinfo/W=reflectivitypanel plotype_tab0
		if(V_Value != numberbykey("plotyp", coefnote))
			//the data is currently in the form of the popup value
			//but you want it in the form of whats in the coefnote.
			setmotofitoption("plotyp", num2istr(V_Value))
			newplotyp = numberbykey("plotyp", coefnote)
			if(numtype(newplotyp))
				newplotyp = V_Value
			endif
			moto_change_plotyp(newplotyp)
		endif
			
		//change layer params in reflectivity panel
		moto_changelayerwave(coef_theoretical_R[0])
	endif
	
	//copy the parameters over, and the holdstring
	mode = str2num(getmotofitoption("mode"))
	holdstring = getmotofitoption("holdstring")
	
	Wave/t layerparams = root:packages:motofit:reflectivity:layerparams
	Wave/t baselayerparams = root:packages:motofit:reflectivity:baselayerparams
	Wave layerparams_selwave = root:packages:motofit:reflectivity:layerparams_selwave
	Wave baselayerparams_selwave = root:packages:motofit:reflectivity:baselayerparams_selwave
	
	baselayerparams[0][1] = num2istr(coef_theoretical_R[0])
	baselayerparams_selwave[0][2] = 	baselayerparams_selwave[0][2] | selectnumber(str2num(holdstring[0]), 0, 16)
	
	baselayerparams[1][1] = num2str(coef_theoretical_R[1])
	baselayerparams_selwave[1][2] = baselayerparams_selwave[1][2] | selectnumber(str2num(holdstring[1]), 0, 16)
	
	layerparams[0][3] = num2str(coef_theoretical_R[2])
	layerparams_selwave[0][4] = layerparams_selwave[0][4] | selectnumber(str2num(holdstring[2]), 0, 16)

	if(!mode)
		baselayerparams[2][1] = num2str(coef_theoretical_R[4])
		baselayerparams_selwave[2][2]  = 	baselayerparams_selwave[2][2]  | selectnumber(str2num(holdstring[4]), 0, 16)
		
		layerparams[dimsize(layerparams, 0) - 1][3] = num2str(coef_theoretical_R[3])
		layerparams_selwave[dimsize(layerparams, 0) - 1][4] = layerparams_selwave[dimsize(layerparams, 0) - 1][4] | selectnumber(str2num(holdstring[3]), 0, 16)

		layerparams[dimsize(layerparams, 0) - 1][7] = num2str(coef_theoretical_R[5])		
		layerparams_selwave[dimsize(layerparams, 0) - 1][8] = layerparams_selwave[dimsize(layerparams, 0) - 1][8] | selectnumber(str2num(holdstring[5]), 0, 16)
	else
		baselayerparams[2][1] = num2str(coef_theoretical_R[6])
		baselayerparams_selwave[2][2] = baselayerparams_selwave[2][2] | selectnumber(str2num(holdstring[6]), 0, 16)

		layerparams[0][5] = num2str(coef_theoretical_R[3])
		layerparams_selwave[0][6] = layerparams_selwave[0][6]  | selectnumber(str2num(holdstring[3]), 0, 16)

		layerparams[dimsize(layerparams, 0) - 1][3] = num2str(coef_theoretical_R[4])
		layerparams_selwave[dimsize(layerparams, 0) - 1][4] = layerparams_selwave[dimsize(layerparams, 0) - 1][4] | selectnumber(str2num(holdstring[4]), 0, 16)

		layerparams[dimsize(layerparams, 0) - 1][5] = num2str(coef_theoretical_R[5])
		layerparams_selwave[dimsize(layerparams, 0) - 1][6] = layerparams_selwave[dimsize(layerparams, 0) - 1][6] | selectnumber(str2num(holdstring[5]), 0, 16)

		layerparams[dimsize(layerparams, 0) - 1][7] = num2str(coef_theoretical_R[7])
		layerparams_selwave[dimsize(layerparams, 0) - 1][8] = layerparams_selwave[dimsize(layerparams, 0) - 1][8] | selectnumber(str2num(holdstring[7]), 0, 16)
	endif
	if(mode)
		mode = 2
	endif
	for(ii = 0 ; ii < coef_theoretical_R[0] ; ii+=1)
		layerparams[ii + 1][1] = num2str(coef_theoretical_R[4 * (ii+1) + 2 + mode])
		layerparams_selwave[ii + 1][2] = layerparams_selwave[ii + 1][2] | selectnumber(str2num(holdstring[4 * ii + 6 + mode]), 0, 16)
		
		layerparams[ii + 1][3] = num2str(coef_theoretical_R[4 * (ii +1) + 3 + mode])
		layerparams_selwave[ii + 1][4] = layerparams_selwave[ii + 1][4] | selectnumber(str2num(holdstring[4 * ii + 7 + mode]), 0, 16)
		
		layerparams[ii + 1][5] = num2str(coef_theoretical_R[4 * (ii+1) + 4 + mode])
		layerparams_selwave[ii + 1][6] = layerparams_selwave[ii + 1][6] | selectnumber(str2num(holdstring[4 * ii + 8 + mode]), 0, 16)
		
		layerparams[ii + 1][7] = num2str(coef_theoretical_R[4 * (ii+1) + 5 + mode])
		layerparams_selwave[ii + 1][8] = layerparams_selwave[ii + 1][8] | selectnumber(str2num(holdstring[4 * ii + 9 + mode]), 0, 16)
	endfor
End

static Function Moto_localchi2()
	Wave/z coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	variable dimension, par0 = 1, par1 = 2, extent0 = 100, extent1 = 100, ii, jj, chi2

	duplicate/free coef_theoretical_R, local_copy_coefs
	prompt dimension, "1D or 2D calculation?", popup, "1D;2D"
	doprompt "Chi2 map for how many dimensions?", dimension
	if(V_flag)
		return 0
	endif
	switch(dimension)
		case 1:
				prompt par0, "first parameter number 1 <= x <= " + num2istr(numpnts(local_copy_coefs) - 1)
				prompt extent0, "Percentage range either side"
				Doprompt "Please select the parameter number and extent for chi2map", par0, extent0
				if(V_flag)
					return 0
				endif
				if(par0 > numpnts(local_copy_coefs) || par0 < 1)
					abort "enter a reasonable parameter number"
					return 0
				endif
				make/o/d/n=501 chi2map = 0
				setscale/I x, local_copy_coefs[par0] * (1 - extent0/100), local_copy_coefs[par0] * (1 + extent0/100), chi2map
				display/K=1 chi2map as "Chi2map for parameter " + num2istr(par0)
				for(ii = 0 ; ii < dimsize(chi2map, 0) ; ii += 1)
					coef_theoretical_R[par0] = pnt2x(chi2map, ii)
					chi2 = Moto_calcchi2()
					if(numtype(chi2))
						coef_theoretical_R = local_copy_coefs
						abort "chi2 calculation was NaN for a value, please check setup"					
					endif
					chi2map[ii] = chi2
				endfor
				
			break
		case 2:
				prompt par0, "first parameter number 1 <= x <= " + num2istr(numpnts(local_copy_coefs))
				prompt extent0, "Percentage range either side"
				prompt par1, "second parameter number 1 <= x <= " + num2istr(numpnts(local_copy_coefs))
				prompt extent1, "Percentage range either side"

				Doprompt "Please select the parameter number and extent for chi2map", par0, extent0, par1, extent1
				if(V_flag)
					return 0
				endif
				if(par0 > numpnts(local_copy_coefs) || par0 < 1 || par1 < 1 || par1 > numpnts(local_copy_coefs))
					abort "enter a reasonable parameter number"
					return 0
				endif
				make/o/d/n=(201, 201) chi2map = 0
				setscale/I x, local_copy_coefs[par0] * (1 - extent0/100), local_copy_coefs[par0] * (1 + extent0/100), chi2map
				setscale/I y, local_copy_coefs[par1] * (1 - extent1/100), local_copy_coefs[par1] * (1 + extent1/100), chi2map
				newimage/K=1 chi2map

				for(ii = 0 ; ii < dimsize(chi2map, 0) ; ii += 1)
					for(jj = 0 ; jj < dimsize(chi2map, 1) ; jj += 1)
						coef_theoretical_R[par0] = DimOffset(chi2map, 0) + ii *DimDelta(chi2map, 0)
						coef_theoretical_R[par1] = DimOffset(chi2map, 1) + jj *DimDelta(chi2map, 1)
						chi2 = Moto_calcchi2()
						if(numtype(chi2))
							coef_theoretical_R = local_copy_coefs
							abort "chi2 calculation was NaN for a value, please check setup"					
						endif
						chi2map[ii][jj] = chi2
					endfor
				endfor
			break
	endswitch
	coef_theoretical_R = local_copy_coefs
End


static Function Moto_calcchi2()
	//this function calculates chi2 when you change the model in the reflectivity panel
	Wave coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	string datasetname
	variable usedqwave, useerrors, usecursors, chi2, leftval, rightval, temp
	
	//which dataset
	controlinfo/w=reflectivitypanel dataset_tab0
	datasetname = S_value

	//use dq wave?
	controlinfo/w=reflectivitypanel usedqwave_tab0
	usedqwave = V_Value
	
	//use error weighting?
	controlinfo/w=reflectivitypanel useerrors_tab0
	useerrors = V_Value
		
	Wave/z RR = $("root:data:"+datasetname + ":" + datasetname + "_R")
	Wave/z qq = $("root:data:"+datasetname + ":" + datasetname + "_q")
	Wave/z dR = $("root:data:"+datasetname + ":" + datasetname + "_E")
	Wave/z dq= $("root:data:"+datasetname + ":" + datasetname + "_dq")
	
	if(!waveexists(RR) || !waveexists(qq))
		return NaN
	endif
	//fit between cursors?
	controlinfo/w=reflectivitypanel fitcursors_tab0
	usecursors = V_Value
	leftval = 0
	rightval = dimsize(RR, 0) - 1
	if(usecursors)
		leftval = numberbykey("POINT", csrinfo(A, "reflectivitygraph"))
		rightval = numberbykey("POINT", csrinfo(B, "reflectivitygraph"))
		if(numtype(leftval))
			leftval = 0
		endif
		if(numtype(rightval))
			rightval = dimsize(RR, 0) - 1
		endif
		if(leftval>rightval)
			temp = leftval
			leftval = rightval
			rightval = temp
		endif
	endif


	make/d/free/n=(dimsize(RR, 0)) rrcalc, diff
	make/d/o/n=(dimsize(RR, 0)) root:data:theoretical:res_theoretical_R
	Wave res_theoretical_R = root:data:theoretical:res_theoretical_R
	
	if(usedqwave && waveexists(dq))
		Motofit_smeared(coef_theoretical_R, RRcalc, qq, dq)
	else
		Motofit(coef_theoretical_R, RRcalc, qq)
	endif
	
	res_theoretical_R =  rr - RRcalc
	
	diff = (RRcalc - rr)^2
	
	if(useerrors && waveexists(dR))
		diff /= dR^2
	//	res_theoretical_R /= dR
	endif
	Wavestats/q/z/m=1/R=[leftval, rightval] diff
	chi2 = V_avg
//   chi2 = sum(diff, leftval, rightval)/ numpnts(diff)
	valdisplay Chisquare_tab0, win=reflectivitypanel, value = _NUM:chi2
	
	return chi2
End

static Function Moto_reflectivitygraphs()
	Wave theoretical_R = root:data:theoretical:theoretical_R
	Wave theoretical_q = root:data:theoretical:theoretical_q
	Wave SLD_theoretical_R = root:data:theoretical:SLD_theoretical_R
	variable plotyp = str2num(motofit#getmotofitoption("plotyp"))
	
	dowindow/k reflectivitygraph
	Display/K=1/N=reflectivitygraph/w=(10,44,560,342) theoretical_R vs theoretical_q as "Reflectivity"
	modifygraph/W=reflectivitygraph lsize(theoretical_R)=2, rgb(theoretical_R) = (0,0,0), axthick=1, fsize=12, standoff(left) = 0
	controlbar/T/W=reflectivitygraph 50
	PopupMenu plotype_tab0,pos={90,7},size={220,24}, proc=motofit#moto_GUI_PopMenu, title="Plot type"
	PopupMenu plotype_tab0,mode=plotyp, bodyWidth= 100, value= #"\"logR vs Q;R vs Q;RQ^4 vs Q;RQ^2 vs Q\""
	Button Autoscale title="Autoscale",size={73,24},pos={9,5},proc=motofit#moto_GUI_button, fsize=10
	Button ChangeQrange title="Q range",proc=motofit#moto_GUI_button,size={73,24}, pos = {87, 5},fsize=10
	Button Snapshot title="snapshot",proc=motofit#moto_GUI_button,size={73,24},pos={320,5},fsize=10
	Button restore title="restore",proc=motofit#moto_GUI_button,size={73,24},pos={395,5},fsize=10
	Button refreshdata title="refresh",size={73,24},proc=motofit#moto_GUI_button, pos ={472, 5}, fsize=10
	CheckBox appendresiduals,pos={10,32},size={100,14},title="Append residuals",fSize=10, value = 0, proc = motofit#moto_GUI_check
	
	if(moto_iswindows())
		Label bottom, "Q (" + num2char(197) + "\\S-1\\M)"
	else 
		Label bottom, "Q (" + num2char(129) + "\\S-1\\M)"
	endif
	Label left, "R"
	ModifyGraph log(bottom)=0,mode=0
	if(plotyp ==0)
		ModifyGraph log(left) = 1
	endif
	
	dowindow/k sldgraph
	Display/K=1/N=SLDgraph/w=(10,364,560,590), SLD_theoretical_R
	Modifygraph/w = SLDgraph lsize(SLD_theoretical_R) = 2, axthick=1, fsize=12, rgb(SLD_theoretical_R) = (0,0,0)
	DoWindow/T SLDgraph,"Scattering length density"
	Label bottom "distance from interface ()"
	if(moto_iswindows())
		Label left, "SLD (10\\S-6\\M "+num2char(197) + "\\S-2\\M)"
		Label bottom "distance from interface (" + num2char(197) + ")"
	else 
		Label left, "SLD (10\\S-6\\M "+num2char(129) + "\\S-2\\M)"
		Label bottom "distance from interface (" + num2char(129) + ")"
	endif
End

Function moto_iswindows()
	String platform= UpperStr(igorinfo(2))
	Variable pos= strsearch(platform,"WINDOWS",0)
	return pos >= 0
End

static Function Moto_Reflectivitypanel() : Panel
	//this function builds the reflectivity panel and associated controls
	Dowindow/k reflectivitypanel
	NewPanel /K=1/W=(560,44,1151,628) as "Reflectivity Panel"
	ModifyPanel cbRGB=(43520,43520,43520)
	Dowindow/C reflectivitypanel
	
	Moto_changelayerwave(1)	
	
	SetDrawLayer UserBack
	Wave/t layerparams = root:packages:motofit:reflectivity:layerparams
					
	ListBox baseparams_tab0,pos={22,266},size={205,72},proc=motofit#moto_GUI_listbox
	ListBox baseparams_tab0,fSize=12
	ListBox baseparams_tab0,listWave=root:packages:motofit:reflectivity:baselayerparams
	ListBox baseparams_tab0,selWave=root:packages:motofit:reflectivity:baselayerparams_selwave
	ListBox baseparams_tab0,mode= 6,editStyle= 2,widths={80,80,20}
	ListBox layerparams_tab0,pos={22,341},size={544,197},proc=motofit#moto_GUI_listbox
	ListBox layerparams_tab0,fSize=12
	ListBox layerparams_tab0,listWave=root:packages:motofit:reflectivity:layerparams
	ListBox layerparams_tab0,selWave=root:packages:motofit:reflectivity:layerparams_selwave
	ListBox layerparams_tab0,mode= 5,editStyle= 2
	ListBox layerparams_tab0,widths={60,60,21,60,21,60,21,60,21}
	CheckBox usemultilayer_tab0,pos={407,308},size={96,14},proc=motofit#moto_GUI_check,title="make multilayer?"
	CheckBox usemultilayer_tab0,value= 0, fsize=12
	
	PopupMenu coefwave_tab0,pos={236,270},size={176,20},bodyWidth=139,proc=motofit#moto_GUI_PopMenu,title="Model"
	PopupMenu coefwave_tab0,fSize=12
	PopupMenu coefwave_tab0,mode=1,value= motofit#moto_useable_coefs()
	ValDisplay Chisquare_tab0,pos={252,304},size={132,20},title="\\F'Symbol'c\\M\\S2"
	ValDisplay Chisquare_tab0,fSize=14,fStyle=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay Chisquare_tab0,value= _NUM:1
	Button Savecoefwave_tab0,pos={421,265},size={68,31},proc=motofit#moto_GUI_button, title="Save"
	Button Savecoefwave_tab0,fSize=12
	Button loadcoefwave_tab0,pos={495,265},size={62,30},proc=motofit#moto_GUI_button,title="Load"
	Button loadcoefwave_tab0,fSize=12
	
	GroupBox group0_tab0,pos={14,28},size={555,74},title="Dataset",frame=1
	GroupBox group1_tab0,pos={14,107},size={554,48},title="Plotting",frame=1
	GroupBox group2_tab0,pos={16,160},size={554,80},title="Fitting",frame=1
	GroupBox group3_tab0,pos={16,245},size={554,297},title="Model",frame=1
	
	Slider slider0_tab0,pos={8,544},size={564,50},fSize=12,fColor=(43690,43690,43690)
	Slider slider0_tab0,valueColor=(43690,43690,43690), help={"adjust a parameter by moving the slider"}
	Slider slider0_tab0,limits={0.5,1.5,0.1},variable= V_Flag,side=1, value = 1,vert= 0, proc = motofit#moto_GUI_slider, ticks=0
	slider slider0_tab0, userdata(whichparam) = "listwave-root:packages:motofit:reflectivity:baselayerparams;row-1;col-1"

	
	//datasets
	Button loaddatas_tab0,pos={32,50},size={108,43},proc=motofit#moto_GUI_button,title="Load data"
	Button loaddatas_tab0,fColor=(65280,32512,16384)

	PopupMenu dataset_tab0,pos={163,62},size={192,20},bodyWidth=145,proc=motofit#moto_GUI_PopMenu,title="dataset"
	PopupMenu dataset_tab0,fSize=12
	PopupMenu dataset_tab0,mode=2,popvalue="_none_",value= motofit#Moto_fittable_datasets()
	
	Button Savefitwave_tab0,pos={382,56},size={167,31},proc=motofit#moto_GUI_button, title="Save fits"
	Button Savefitwave_tab0,fSize=12
	
	//plotting
	PopupMenu plotype_tab0,pos={24,129},size={133,20},bodyWidth=104,proc=motofit#moto_GUI_PopMenu,title="type"
	PopupMenu plotype_tab0,help={"you can change the plot type to whatever you want."}
	PopupMenu plotype_tab0,fSize=12
	PopupMenu plotype_tab0,mode=1,popvalue="logR vs Q",value= #"\"logR vs Q;R vs Q;RQ^4 vs Q;RQ^2 vs Q\""
	SetVariable res_tab0,pos={199,129},size={160,19},proc=motofit#moto_GUI_setvariable,title="resolution dq/q %"
	SetVariable res_tab0,help={"Enter the resolution, dq/q in terms of a percentage. Use dq/q=0 to start with"}
	SetVariable res_tab0,fSize=12,limits={0,10,0.5},value= _NUM:5,live=1
	Button Addcursor_tab0,pos={430,123},size={79,29},proc=motofit#moto_GUI_button,title="Add cursor"
	Button Addcursor_tab0,fSize=12
	
	//fitting
	Button Dofit_tab0,pos={30,182},size={111,48},proc=motofit#moto_GUI_button,title="Do fit"
	Button Dofit_tab0,help={"Performs the fit"},fColor=(65280,32512,16384)
	PopupMenu Typeoffit_tab0,pos={137,195},size={160,20},bodyWidth=150
	PopupMenu Typeoffit_tab0,mode=1,popvalue="Genetic",value= #"\"Genetic;Levenberg-Marquardt;Genetic + LM;Genetic+MC_Analysis\""
	
	CheckBox usedQwave_tab0,pos={307,187},size={99,16},proc=motofit#moto_GUI_check,title="use dQ wave?"
	CheckBox usedQwave_tab0,fSize=12,value= 0
	
	CheckBox useerrors_tab0,pos={307,205},size={111,16},proc=motofit#moto_GUI_check,title="use error wave?"
	CheckBox useerrors_tab0,fSize=12,value= 0

	CheckBox fitcursors_tab0,pos={423,205},size={140,16},proc=motofit#moto_GUI_check,title="Fit between cursors?"
	CheckBox fitcursors_tab0,help={"To get the cursors on the graph press Ctrl-I.  This enables you to fit over a selected x-range"}
	CheckBox fitcursors_tab0,fSize=12,value= 0
	
	CheckBox useconstraint_tab0,pos={423,188},size={137,16},proc=motofit#moto_GUI_check,title="Fit with constraints?"
	CheckBox useconstraint_tab0,fSize=12,value= 0
	
	
	//thickness estimation
	SetVariable FT_lowQ_tab2,pos={73,53},size={142,19},bodyWidth=60,proc=motofit#moto_GUI_setvariable,title="low Q for FFT"
	SetVariable FT_lowQ_tab2,fSize=12,limits={0.005,1,0.01},value= _NUM:0.005
	SetVariable FT_hiQ_tab2,pos={68,77},size={147,19},bodyWidth=60,proc=motofit#moto_GUI_setvariable,title="high Q for FFT"
	SetVariable FT_hiQ_tab2,fSize=12,limits={0.005,1,0.01},value= _NUM:0.5
	SetVariable fringe_tab2,pos={255,77},size={213,19},title="layer thickness spacing"
	SetVariable fringe_tab2,fSize=12,limits={0,0,0},value= _NUM:0
	SetVariable numfringe_tab2,pos={281,53},size={193,19},proc=motofit#moto_GUI_setvariable,title="number of fringes"
	SetVariable numfringe_tab2,fSize=12
	SetVariable numfringe_tab2,limits={0,100,1},value= _NUM:0
	
	make/n=1/o/d root:packages:motofit:reflectivity:ft:fftoutput
	Wave/z FFToutput = root:packages:motofit:reflectivity:ft:FFToutput
	Display /HOST=reflectivitypanel/N=FFToutput/W=(0.1,0.3,0.9,0.9) FFToutput
	Setwindow reflectivitypanel#FFToutput hide= 1

	//constraints tab
	Button Addconstraint_tab1,pos={36,52},size={119,29},disable=1,proc=motofit#moto_GUI_button,title="Add constraint",fsize=10
	Button removeconstraint_tab1,pos={36,95},size={119,30},disable=1,proc=motofit#moto_GUI_button,title="Remove constraint",fsize=10

	ModifyControlList ControlNameList("Reflectivitypanel", ";", "!*_tab0"), disable = 1
	ModifyControlList ControlNameList("Reflectivitypanel", ";", "*_tab0"), disable = 0
	TabControl refpanel,pos={3,1},size={575,571},proc=motofit#moto_GUI_tab
	TabControl refpanel,tabLabel(0)="Fit",tabLabel(1)="Constraints"
	TabControl refpanel,tabLabel(2)="thickness estimation", value = 0
End

static Function moto_appendresiduals()
	string traces = tracenamelist("reflectivitygraph", ";", 5)
	string datasets = "", dataset, fittable, tracecolour
	variable ii, changeaxis = 0
	fittable = moto_fittable_datasets()
	
	for(ii = 0 ; ii < itemsinlist(traces) ; ii+=1)
		if(whichlistitem( removeending(stringfromlist(ii, traces), "_R"), fittable) > -1)
			datasets +=  removeending(stringfromlist(ii, traces), "_R") + ";"
		endif
	endfor
	
	if(!itemsinlist(datasets))
		return 0
	endif
	
	datasets += "theoretical"
	for(ii = 0 ; ii < itemsinlist(datasets) ; ii+=1)
		dataset = stringfromlist(ii, datasets)
		tracecolour = moto_gettracecolour("reflectivitygraph", dataset + "_R")
		Wave/z res = $("root:data:" + dataset + ":res_" + dataset + "_R")
		Wave/z fitqq = $("root:data:" + dataset + ":fit_" + dataset + "_q")
		if(waveexists(res) && waveexists(fitqq))
			checkdisplayed/W=reflectivitygraph res
			if(!V_flag)
				AppendToGraph/W=reflectivitygraph/L=res res vs fitqq
				execute/z "modifygraph/W=reflectivitygraph rgb(" + nameofwave(RES) + ")="  + tracecolour + ",lsize("+nameofwave(RES) + ")=2"
				changeaxis = 1
			endif
		endif
		Waveclear res
	endfor
	
	if(changeaxis)
		ModifyGraph/W=reflectivitygraph standoff(left)=0, standoff(res)=0, axisEnab(left)={0.15,1};
		ModifyGraph/W=reflectivitygraph axisEnab(res)={0,0.12},freePos(res)={0,bottom}
	endif
End

static Function moto_unappendresiduals()
	string traces = tracenamelist("reflectivitygraph", ";", 5)
	string ti
	variable ii, changeaxis = 0
	
	for(ii = 0 ; ii < itemsinlist(traces) ; ii+=1)
		ti = traceinfo("reflectivitygraph", stringfromlist(ii, traces), 0)
		if(stringmatch(stringbykey("YAXIS", ti), "res"))
			removefromgraph/W=reflectivitygraph/z $(stringfromlist(ii, traces))
			changeaxis = 1
		endif
	endfor
	
	if(changeaxis)
		ModifyGraph/W=reflectivitygraph standoff(left)=0, axisEnab(left)={0,1};
	endif
End

static Function Moto_changeQrangeprompt()
	Wave localref_R = root:data:theoretical:theoretical_R
	Wave localref_Q=root:data:theoretical:theoretical_Q
	Variable num=numpnts(localref_R),qmin=localref_q[0],qmax=localref_q[numpnts(localref_q)-1]
	Prompt num, "Enter number of data points for model: "
	Prompt qmin, "Enter minimum q-value (A^-1) for model: "
	Prompt qmax, "Enter maximum q-value (A^-1) for model: "
	Doprompt "enter new plot parameters",num,qmin,qmax
	//if the user doesn't want to continue with changes then abort
	if(V_flag==1)
		Abort
	endif
	Moto_ChangetheoreticalQrange(num,qmin,qmax)
End


//all the fitting is done here:
static Function Moto_do_a_fit()	
	string typeoffit, datasetname, df = "", holdstring = "", fitfunc = "", traces = "", lci = "", rci = "", tracecolour
	variable useerrors, usedqwave, usecursors, leftP, rightP, useconstraint, mode, ii, jj, iters
	dfref savDF = getdatafolderDFR()

	controlinfo/W=reflectivitypanel typeoffit_tab0
	typeoffit = S_value

	controlinfo/W=reflectivitypanel dataset_tab0
	datasetname = S_Value
	if(stringmatch(datasetname, "_none_"))
		Doalert 0, "Please select a valid dataset"
		return 0
	endif

	df = "root:data:" + datasetname
	setdatafolder df

	Wave/z RR = $(datasetname + "_R")
	Wave/z qq = $(datasetname + "_q")
	Wave/z dR = $(datasetname + "_E")
	Wave/z dq = $(datasetname + "_dq")
	Wave coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	Wave SLD_theoretical_R = root:data:theoretical:SLD_theoretical_R

	moto_updateholdstring()
	holdstring = getmotofitoption("holdstring")
	useerrors = str2num(getmotofitoption("useerrors"))
	usedqwave = str2num(getmotofitoption("usedqwave"))
	usecursors = str2num(getmotofitoption("fitcursors"))
	useconstraint =  str2num(getmotofitoption("useconstraint"))
	try
		Moto_backupModel()
		if(!waveexists(RR) || !waveexists(qq))
			abort
		endif
		if(!waveexists(dR) && useerrors)
			abort "An error wave does not exist and you specified that you wanted to fit with errors"
		endif
		if(!useerrors)
			Waveclear dR
			make/n=(dimsize(RR, 0))/d/free inputdR = 1
			Wave dR = inputdR
		endif
		if(usecursors)
			lci = csrinfo(A, "reflectivitygraph")
			rci = csrinfo(B, "reflectivitygraph")
			if(!strlen(lci) || !strlen(rci) || !stringmatch(stringbykey("TNAME", lci), stringbykey("TNAME", rci)))
				abort "if you want to restrict the Qrange (use cursors) they must be both on the same dataset you are trying to fit."
			endif
			leftP = numberbykey("POINT", csrinfo(A, "reflectivitygraph"))
			rightP = numberbykey("POINT", csrinfo(B, "reflectivitygraph"))
			if(leftP > rightP)
				variable temp = rightP
				rightP = leftP
				leftP = temp
			endif
		else
			leftP = 0
			rightP = dimsize(RR, 0) - 1
		endif
	
		//make a q wave to fit and choose the fitfunction
		fitfunc = "motofit"
		make/n=(dimsize(qq, 0))/d/free inputQQ
		inputQQ[] = qq[p]
		if(waveexists(dq) && usedqwave)
			fitfunc = "motofit_smeared"
			redimension/n=(-1, 2) inputQQ
			inputQQ[][1] = dq[p]		
		endif
	
		//make the coefficients to fit
		make/d/o/n=(dimsize(coef_theoretical_R, 0)) $("coef_" + datasetname + "_R")
		Wave coef = $("coef_" + datasetname + "_R")
		coef = coef_theoretical_R
		note/k coef
		note coef, getmotofitoptionstring()
		
		//make the destination waves
		make/o/d/n=(dimsize(RR, 0)) $("fit_" + datasetname + "_R")
		make/o/d/n=(dimsize(RR, 0)) $("fit_" + datasetname + "_q")
		Wave outputRR = $("fit_" + datasetname + "_R")
		Wave outputQQ = $("fit_" + datasetname + "_q")
		outputQQ = QQ
		outputRR = NaN
	
		//see if the fit has already been appended to the reflectivity graph
		traces = tracenamelist("Reflectivitygraph", ";", 1)
		tracecolour = moto_gettracecolour("reflectivitygraph", nameofwave(RR))
		
		if(whichlistitem(nameofwave(outputRR), traces) == -1)
			appendtograph/W=reflectivitygraph/q outputRR vs outputQQ
			execute/z "modifygraph/W=reflectivitygraph rgb(" + nameofwave(outputRR) + ")="  + tracecolour 
		endif
		variable/g V_fiterror = 0
		NVAR V_fiterror
		
		mode = str2num(getmotofitoption("mode"))
		strswitch(typeoffit)
			case "Genetic":
				if(GEN_setlimitsforGENcurvefit(coef, holdstring, paramdescription = moto_paramdescription(coef[0], mode)))
					abort
				endif
				NVAR popsize = root:packages:motofit:old_genoptimise:popsize
				NVAR recomb = root:packages:motofit:old_genoptimise:recomb
				NVAR iterations = root:packages:motofit:old_genoptimise:iterations
				NVAR k_m = root:packages:motofit:old_genoptimise:k_m
				NVAR fittol = root:packages:motofit:old_genoptimise:fittol
				Wave limits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
				Gencurvefit/D=outputRR/I=1/Q/MAT=1/R/W=dR/X=inputQQ/K={iterations, popsize, k_m, recomb}/TOL=(fittol) $fitfunc, RR[leftP, rightP], coef, holdstring, limits
				break
			case "Levenberg-Marquardt":
				if(useconstraint)
					Wave/t constraints = root:packages:motofit:reflectivity:constraintslist
				else
					make/n=0/t/free constraints							
				endif
				FuncFit/H=holdstring/M=2/Q/NTHR=0 $fitfunc coef  RR[leftP, rightP] /X=inputQQ /W=dR /I=1 /D=outputRR /R /A=0 /C=constraints
				break
			case "Genetic + LM":
				if(GEN_setlimitsforGENcurvefit(coef, holdstring, paramdescription =  moto_paramdescription(coef[0], mode)))
					abort
				endif
				NVAR popsize = root:packages:motofit:old_genoptimise:popsize
				NVAR recomb = root:packages:motofit:old_genoptimise:recomb
				NVAR iterations = root:packages:motofit:old_genoptimise:iterations
				NVAR k_m = root:packages:motofit:old_genoptimise:k_m
				NVAR fittol = root:packages:motofit:old_genoptimise:fittol
				Wave limits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
			
				Gencurvefit/D=outputRR/I=1/Q/MAT=1/R/W=dR/X=inputQQ/K={iterations, popsize, k_m, recomb}/TOL=(fittol) $fitfunc, RR[leftP, rightP], coef, holdstring, limits
				if(useconstraint)
					Wave/t constraints = root:packages:motofit:reflectivity:constraintslist
				else
					make/n=0/t/free constraints							
				endif
				FuncFit/Q=1/H=holdstring/M=2/Q/NTHR=0 $fitfunc coef  RR[leftP, rightP] /X=inputQQ /W=dR /I=1 /D=outputRR /R /A=0 /C=constraints
				break
			case "Genetic+MC_Analysis":
				if(!useerrors)
					//you still need errors to resample the data, even if you aren't weighting the fit.
					Waveclear dR
					Wave/z dR = $(datasetname + "_E")
					if(!waveexists(dR))
						abort "You still need to have an error wave to resample the data, even if you aren't weighting the fit"
					endif
				endif
				
				iters = 200
				prompt iters, "iterations:"
				doprompt "Enter the number of Montercarlo iterations", iters
				if(V_Flag)
					abort
				endif
				if(iters<0)
					iters = 1
				else
					iters = ceil(iters)
				endif
				
				if(Moto_montecarlo(fitfunc, coef, RR, inputQQ, dR, holdstring, iters,cursA=leftP, cursB=rightP, fakeweight = !useerrors))
					abort
				endif
				//declare the output of the montecarlo
				Wave M_correlation, M_montecarlo
				make/d/o/n=(dimsize(coef, 0)) W_sigma = 0
				
				Wave M_montecarlostats = M_montecarloStatistics(M_monteCarlo)
				coef = M_montecarlostats[p][0]
				W_sigma = M_montecarlostats[p][1]
				
				//create a graph of all the montecarloSLDcurves
				Moto_montecarlo_SLDcurves(M_montecarlo, 0.02, 250)
				break
		endswitch
		if(!V_fiterror)
			//update the theoretical fit
			coef_theoretical_R = coef
			moto_usecoefWave(coef_theoretical_R, shortcut = 1)
			moto_update_theoretical()
			note/k coef
			note coef, getmotofitoptionstring()
			//keep a history of the fits
			if(!waveexists($("root:data:" + datasetname + ":fit_history")))
				make/o/d/n=(dimsize(coef, 0), 1) $("root:data:" + datasetname + ":fit_history") = coef
				Wave fit_history = $("root:data:" + datasetname + ":fit_history")
				Note/NOCR fit_history, num2str(V_chisq) + ";"
			else
				Wave fit_history = $("root:data:" + datasetname + ":fit_history")
				duplicate/free fit_history, old_history
				if(numpnts(coef) > dimsize(fit_history, 0))
					redimension/n=(numpnts(coef), dimsize(fit_history, 1) + 1) fit_history
				else
					redimension/n=(-1, dimsize(fit_history, 1) + 1) fit_history
				endif
				fit_history = NaN
				fit_history[][] = (p < dimsize(old_history, 0) && q < dimsize(old_history, 1)) ? old_history[p][q] : NaN
				fit_history[][dimsize(fit_history, 1) - 1] = p < dimsize(coef, 0) ? coef[p] : NaN
				Note/NOCR fit_history, num2str(V_chisq) + ";"
			endif
			//divide the residuals wave by the errors
			Wave/z residual = $("root:data:" + datasetname + ":res_" + datasetname + "_R")
			if(waveexists(residual))
				residual /= dR
			endif 
			
			//normalised correlation matrix as well
			Wave/z M_covar
			if(waveexists(M_covar))
				gen_gcm(M_covar)
			endif
			
			//create some SLD waves and append them to the SLD graph
			make/n=(dimsize(SLD_theoretical_R, 0))/d/o $("SLD_" + datasetname + "_R") = SLD_theoretical_R
			Wave SLD = $("SLD_" + datasetname + "_R")
			copyscales SLD_theoretical_R, SLD
			traces = tracenamelist("SLDgraph", ";", 1)
			if(whichlistitem(nameofwave(SLD), traces) == -1)
				appendtograph/W=SLDgraph/q SLD
				execute/z "modifygraph/W=SLDgraph rgb(" + nameofwave(SLD) + ")="  + tracecolour + ",lsize("+nameofwave(SLD) + ")=2"
			endif
			
			//do you want to append residuals
			controlinfo/W=reflectivitygraph appendresiduals
			if(V_Value)
				moto_appendresiduals()
			endif
			
			//print the results to the history line
			Wave W_sigma
			print "_________________________________________________________________"
			print "Fitting to", fitfunc, "using", typeoffit
			print nameofwave(RR), " vs ", nameofwave(qq)
			print "Chi2 = ", V_Chisq / V_npnts
			for(ii = 0 ; ii < numpnts(coef) ; ii+=1)
				printf "\tw[%d] = %f\t+/-\t%g\r", ii, coef[ii], W_sigma[ii]
			endfor
			print "_________________________________________________________________"

		endif
	catch

	endtry
	setdatafolder savDF
End

Function moto_changemode()
//this function toggles the mode between 0 (solvent penetration) and 1 (imaginarySLD)
Wave cth = root:data:theoretical:coef_theoretical_R
variable mode = str2num(getmotofitoption("mode")), ii

if(!mode)
	//imagfronting
	insertpoints 4, 1, cth
	insertpoints 3, 1, cth
	for(ii = 0 ; ii < cth[0] ; ii+=1)
		cth[4 * ii + 9] = (cth[4] * 0.01 * cth[4* ii + 10]) + (cth[4*ii + 9] * (1 - 0.01 * cth[4* ii + 10]))
		cth[4* ii + 10] = 0	
	endfor	
	setmotofitoption("mode", "1")
else
	deletepoints 5, 1, cth
	deletepoints 3, 1, cth
	for(ii = 0 ; ii < cth[0] ; ii+=1)
		cth[4* ii + 8] = 0	
	endfor	
	setmotofitoption("mode", "0")
endif
	moto_usecoefwave(cth)
	moto_update_theoretical()

End


Function/s moto_gettracecolour(graphnamestr, ywavestr)
	string graphnamestr, ywavestr
	string ti = traceinfo(graphnamestr, ywavestr, 0)
	string colour = greplist(ti, "^rgb(x)*")
	return stringbykey("rgb(x)", colour, "=")
End

Function/wave moto_paramdescription(nlayers, mode, [Vmullayers])
	//gives a description for each parameter for the fit.  This is useful for novice users.
	variable nlayers, mode, Vmullayers
	variable ii
	if(!mode)
		make/t/n=(4 * nlayers + 6)/free paramdescription
		paramdescription[3] = "backing-SLD"
		paramdescription[4] = "bkg"
		paramdescription[5] = "backing-rough"
		for(ii = 0 ; ii < nlayers ; ii+=1)
			paramdescription[4 * ii + 6] =  num2istr(ii + 1) + "-thick" 
			paramdescription[4 * ii + 7] =  num2istr(ii + 1) + "-SLD"
			paramdescription[4 * ii + 8] =  num2istr(ii + 1) + "-solv"
			paramdescription[4 * ii + 9] =  num2istr(ii + 1) + "-rough"
		endfor
	else
		make/t/n=(4 * nlayers + 8)/free paramdescription
		paramdescription[3] = "fronting-iSLD"
		paramdescription[4] = "backing-SLD"
		paramdescription[5] = "backing-iSLD"
		paramdescription[6] = "bkg"
		paramdescription[7] = "backing-rough"
		for(ii = 0 ; ii < nlayers ; ii+=1)
			paramdescription[4 * ii + 8] =  num2istr(ii + 1) + "-thick" 
			paramdescription[4 * ii + 9] =  num2istr(ii + 1) + "-SLD"
			paramdescription[4 * ii + 10] =  num2istr(ii + 1) + "-iSLD"
			paramdescription[4 * ii + 11] =  num2istr(ii + 1) + "-rough"
		endfor
	endif
	paramdescription[0] = "numlayers"
	paramdescription[1] = "scale"
	paramdescription[2] = "fronting-SLD"
	
	return paramdescription
End

static Function/t moto_loadcoefs([filestr])
	string fileStr
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	if(!paramisdefault(fileStr) && strlen(fileStr))
		Loadwave/q/O/T fileStr
	else
		Loadwave/q/O/T	
	endif
	if(V_flag==0)
		abort
	endif
	String coefwaveStr= stringfromlist(0, S_Wavenames)
	Wave coefwave = $(coefwavestr)
	string coefnote = note(coefwave)
	
	coefnote = replacestring("\r", coefnote, "")
	if(coefwave[0] * 4 + 6 == numpnts(coefwave))
		coefnote = replacenumberbykey("mode", coefnote, 0)
		coefnote = replacenumberbykey("multilayer", coefnote, 0)
	elseif(coefwave[0] * 4 + 8 == numpnts(coefwave))
		coefnote = replacenumberbykey("mode", coefnote, 1)
		coefnote = replacenumberbykey("multilayer", coefnote, 0)
	elseif(!mod(numpnts(coefwave) - coefwave[0] * 4 + 6, 4))
		coefnote = replacenumberbykey("mode", coefnote, 0)
		coefnote = replacenumberbykey("multilayer", coefnote, 1)
		coefnote = replacenumberbykey("Vmullayers", coefnote, (numpnts(coefwave) - coefwave[0] * 4 + 6)/4)
	elseif(!mod(numpnts(coefwave) - coefwave[0] * 4 + 8, 4))
		coefnote = replacenumberbykey("mode", coefnote, 1)
		coefnote = replacenumberbykey("multilayer", coefnote, 1)
		coefnote = replacenumberbykey("Vmullayers", coefnote, (numpnts(coefwave) - coefwave[0] * 4 + 8)/4)				
	endif
	note/k coefwave
	note coefwave, coefnote

	string datasetname =  replacestring("coef_", coefwavestr, "")
	datasetname = replacestring("_R", datasetname, "")
	newdatafolder/o $("root:data:" + datasetname)
	duplicate/o coefwave, $("root:data:" + datasetname + ":" + "coef_" + datasetname + "_R")
	killwaves/z coefwave
	return datasetname
End

static Function Moto_snapshot(ywave, xwave, sldwave, df)
	string &ywave, &xwave, &sldwave, &df
	
	string snapStr = "snapshot"
	prompt snapStr, "Name: "
	string coefwave
	
	doprompt "Enter a unique name for the snapshot", snapstr
	if(V_flag)
		return 1
	endif
	ywave = cleanupname(snapstr+"_R", 0)
	xwave = cleanupname(snapstr+"_q", 0)
	sldwave = cleanupname("SLD_"+snapstr + "_R", 0)
	coefwave = cleanupname("coef_"+snapstr + "_R", 0)
		
	newdatafolder/o $("root:data:" + snapstr)
	
	df = "root:data:" + snapstr + ":"
	Duplicate/o root:data:theoretical:originaldata, $("root:data:" + snapstr + ":originaldata")
	Duplicate/o root:data:theoretical:coef_theoretical_R, $("root:data:" + snapstr + ":" + coefwave)
	Duplicate/o root:data:theoretical:theoretical_R, $("root:data:" + snapstr + ":" + ywave)
	Duplicate/o root:data:theoretical:theoretical_q, $("root:data:" + snapstr + ":" + xwave)
	Duplicate/o root:data:theoretical:sld_theoretical_R, $("root:data:" + snapstr + ":" + sldwave)
	return 0
End

static Function Moto_refreshData()
	//this function refreshes the loaded data in the reflectivitygraph
	//(assumes data is in root:data:)
	string reflectivitygraph_exists = WinList("reflectivitygraph", ";", "WIN:1")
	string plottedgraphs = ""
	variable ii
	if(strlen(reflectivitygraph_exists))
		plottedgraphs = GetUserData("reflectivitygraph", "", "refFiles")
		for(ii = 0 ; ii < itemsinlist(plottedgraphs, "\r") ; ii += 1)
			Moto_loadReffile(stringfromlist(ii, plottedgraphs, "\r"))
		endfor
	endif
End

static Function moto_change_plotyp(plotyp)
	variable plotyp
	variable ii, oldplotyp
	string datasets = "", dataset = ""

	oldplotyp = str2num(getmotofitoption("plotyp"))
	
	//first get a list of all the datasets.
	datasets = moto_fittable_datasets(justfolders = 1)
	
	for(ii = 0 ; ii < itemsinlist(datasets) ; ii+=1)
		dataset = stringfromlist(ii, datasets)
		//do the experimental data, if it exists.
		Wave/z originaldata = $("root:data:" + dataset + ":originaldata")
		if(waveexists(originaldata))
			make/o/d/n=(dimsize(originaldata, 0)) $("root:data:" + dataset + ":" + dataset + "_R")
			make/o/d/n=(dimsize(originaldata, 0)) $("root:data:" + dataset + ":" + dataset + "_q")
			Wave RR = $("root:data:" + dataset + ":" + dataset + "_R")
			Wave qq = $("root:data:" + dataset + ":" + dataset + "_q")
			RR = originaldata[p][1]
			qq = originaldata[p][0]
			if(dimsize(originaldata, 1) > 2)
				make/o/d/n=(dimsize(originaldata, 0)) $("root:data:" + dataset + ":" + dataset + "_E")
				Wave dR = $("root:data:" + dataset + ":" + dataset + "_E")
				dR = originaldata[p][2]
			else
				Waveclear dR
			endif
			if(dimsize(originaldata, 1) > 3)
				make/o/d/n=(dimsize(originaldata, 0)) $("root:data:" + dataset + ":" + dataset + "_dq")
				Wave dq = $("root:data:" + dataset + ":" + dataset + "_dq")
				dq = originaldata[p][3]
			else
				Waveclear dq
			endif
			moto_lindata_to_plotyp(plotyp, qq, RR, dr = dR, removeNonFinite = 1)
		endif
		//now do the fits, if they exist.
		Wave/z fitRR =  $("root:data:" + dataset + ":fit_" + dataset + "_R")
		Wave /z fitQQ = $("root:data:" + dataset + ":fit_" + dataset + "_q")
		if(waveexists(fitQQ) && waveexists(fitRR))
			moto_plotyp_to_lindata(oldplotyp, fitQQ, fitRR)
			moto_lindata_to_plotyp(plotyp, fitQQ, fitRR, removeNonFinite = 1)
		endif
	endfor
	
	popupmenu plotype_tab0, win=reflectivitypanel, mode = plotyp
	popupmenu plotype_tab0, win=reflectivitygraph, mode = plotyp
	
	setmotofitoption("plotyp", num2istr(plotyp))
	setaxis/a/W=reflectivitygraph left
	moto_update_theoretical()
	switch(plotyp)
		default:
			ModifyGraph/z/w=reflectivitygraph log(left)=0
		break
		case 3:
		case 4:
		case 2:
			ModifyGraph/z/w=reflectivitygraph log(left)=1
		break
	endswitch
End

Static Function setupvariables(mode, res, plotyp, SLDpts)
	variable mode, res, plotyp, SLDpts
	DFREF savDF = getdatafolderDFR()
	
	setdatafolder root:packages:motofit:reflectivity
	string/g  root:packages:motofit:reflectivity:motofitcontrol
	setMotofitOption("mode", num2istr(mode))
	setMotofitOption("res", num2str(res))
	setMotofitOption("plotyp", num2str(plotyp))
	setMotofitOption("SLDpts", num2str(SLDpts))
	setMotofitOption("mulrep", num2str(0))
	setMotofitOption("Vmullayers", num2str(0))
	setMotofitOption("mulappend", num2str(0))
	setMotofitOption("holdstring", "")
	setmotofitoption("usedqwave",num2str(0))
	setmotofitoption("useconstraint",num2str(0))
	setmotofitoption("fitcursors",num2str(0))
	setmotofitoption("useerrors",num2str(0))
	setmotofitoption("multilayer",num2str(0))
	
	ColorTab2wave rainbow
	setdatafolder savDF
End

Static Function setupdatafolders()
	//set up datafolders
	newdatafolder/o root:data
	newdatafolder/o root:data:theoretical
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o root:packages:motofit:reflectivity:ft
End

Static function/s getMotofitOption(option)
	string option
	SVAR/z motofitcontrol = root:packages:motofit:reflectivity:motofitcontrol
	if(SVAR_Exists(motofitcontrol))
		return stringbykey(option, motofitcontrol)
	else
		return ""
	Endif
End

Static function setMotofitOption(option, val)
	string option, val
	SVAR/z motofitcontrol = root:packages:motofit:reflectivity:motofitcontrol
	if(!SVAR_exists(motofitcontrol))
		newdatafolder/o root:packages
		newdatafolder/o root:packages:motofit
		newdatafolder/o root:packages:motofit:reflectivity
		string/g  root:packages:motofit:reflectivity:motofitcontrol
		SVAR motofitcontrol = root:packages:motofit:reflectivity:motofitcontrol
	endif
	motofitcontrol = replacestringbykey(option, motofitcontrol, val)
End

Static function/s getMotofitOptionString()
	SVAR/z motofitcontrol = root:packages:motofit:reflectivity:motofitcontrol
	if(SVAR_exists(motofitcontrol))
		return motofitcontrol
	else
		return ""
	endif
End

Static function setMotofitOptionString(valstr)
	string valstr
	SVAR/z motofitcontrol = root:packages:motofit:reflectivity:motofitcontrol
	motofitcontrol  = valstr
End

Static Function moto_updateholdstring()
	Wave layerparams_selwave = root:packages:motofit:reflectivity:layerparams_selwave
	Wave baselayerparams_selwave = root:packages:motofit:reflectivity:baselayerparams_selwave
	Wave coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	
	variable mode = str2num(getmotofitoption("mode")), numlayers, ii	
	string holdstring = "1"
	
	holdstring += selectstring(baselayerparams_selwave[1][2] & 0x10, "0", "1")
	holdstring += selectstring(layerparams_selwave[0][4] & 0x10, "0", "1")

	numlayers = coef_theoretical_R[0]

	if(!mode)
		holdstring += selectstring(layerparams_selwave[dimsize(layerparams_selwave, 0) - 1][4] & 0x10, "0", "1")
		holdstring += selectstring(baselayerparams_selwave[2][2] & 0x10, "0", "1")
		holdstring += selectstring(layerparams_selwave[dimsize(layerparams_selwave, 0) - 1][8] & 0x10, "0", "1")
		for(ii = 0 ; ii < numlayers ; ii+=1)
			holdstring += selectstring(layerparams_selwave[ii + 1][2] & 0x10, "0", "1")
			holdstring += selectstring(layerparams_selwave[ii + 1][4] & 0x10, "0", "1")
			holdstring += selectstring(layerparams_selwave[ii + 1][6] & 0x10, "0", "1")
			holdstring += selectstring(layerparams_selwave[ii + 1][8] & 0x10, "0", "1")
		endfor
	else
		holdstring += selectstring(layerparams_selwave[0][6] & 0x10, "0", "1")
		holdstring += selectstring(layerparams_selwave[dimsize(layerparams_selwave, 0) - 1][4] & 0x10, "0", "1")
		holdstring += selectstring(layerparams_selwave[dimsize(layerparams_selwave, 0) - 1][6] & 0x10, "0", "1")
		holdstring += selectstring(baselayerparams_selwave[2][2] & 0x10, "0", "1")
		holdstring += selectstring(layerparams_selwave[dimsize(layerparams_selwave, 0) - 1][8] & 0x10, "0", "1")
		for(ii = 0 ; ii < numlayers ; ii+=1)
			holdstring += selectstring(layerparams_selwave[ii + 1][2] & 0x10, "0", "1")
			holdstring += selectstring(layerparams_selwave[ii + 1][4] & 0x10, "0", "1")
			holdstring += selectstring(layerparams_selwave[ii + 1][6] & 0x10, "0", "1")
			holdstring += selectstring(layerparams_selwave[ii + 1][8] & 0x10, "0", "1")
		endfor
	endif
	setmotofitoption("holdstring", holdstring)
End

static Function Moto_FTreflectivity()
	//this function estimates layer thicknesses from the FFT of the reflectivity curve.
	//It uses the cursors to determine the correct zone for transforming.
	//DONT transform the critical edge!
	//if you have two layers producing fringes, then you will get a peak for each of 
	//the layers plus a third peak, which is equal to the sum of the two

	variable plotyp=Str2num(getmotofitoption("plotyp")), FThiQ, FTlowQ
	string datasetname = ""
	dfref dfSav = GetDataFolderDFR()
	
	//get datasets name
	controlinfo/W=reflectivitypanel dataset_tab0
	datasetname = S_Value
	
	if(stringmatch(S_Value,"_none_") )
		datasetname ="theoretical"
	endif
	
	Wave/z RR = $("root:data:" + datasetname + ":" + datasetname + "_R")
	Wave/z qq = $("root:data:" + datasetname + ":" + datasetname + "_q")
	Wave/z originaldata = $("root:data:" + datasetname + ":originaldata")
	if(!waveexists(RR) || !waveexists(qq) || !waveexists(originaldata))
		setdatafolder dfSav
		return 0
	endif
	
	//if the data waves aren't the same length don't do the FT.
	if(numpnts(RR) != numpnts(QQ))
		setdatafolder dfsav
		return 0
	endif
	newdatafolder/o/s root:packages:motofit:reflectivity:ft
	Setdatafolder root:packages:motofit:reflectivity:ft
	
	make/free/d/n=(dimsize(originaldata, 0)) tempy, tempx	
	tempx[] = originaldata[p][0]
	tempy[] = originaldata[p][1]

	sort tempx,tempx,tempy
	
	controlinfo/W=reflectivitypanel FT_lowQ_tab2
	FTlowQ = V_Value
	
	controlinfo/W=reflectivitypanel FT_hiQ_tab2
	FThiQ = V_Value

	variable level,start,finish

	start = binarysearch(tempx,FTlowQ)
	finish = binarysearch(tempx,FThiQ)
			
	if (finish<start)
		variable temp
		temp=start
		start=finish
		finish=temp
	endif
	Deletepoints 0,start, tempy,tempx
	Deletepoints (finish-start+1),(numpnts(tempy) - finish - 1),tempy,tempx
	
	Variable FFTlength=numpnts(tempy)
	if(mod(FFTlength,2)>0)
		FFTlength+=1					//the FFT only works on waves with even numbers
	endif
	Make/free/d/n=(FFTlength) FFTwave
	
	if(FFTlength<8)
		setdatafolder DFsav
		return 0
	endif

	moto_lindata_to_plotyp(3, tempx, tempy, removeNonFinite = 1)	
	
	Interpolate2/T=2/N=(FFTlength)/E=2/Y=FFTWave tempx,tempy 
		
	FFT/z/pad={8*numpnts(FFTwave)}/dest=W_FFT/winf=cos1 FFTwave
	make/o/d/n=(numpnts(W_FFT)) FFToutput
	FFToutput=cabs(W_FFT)
	Variable x2=pnt2x(W_FFT,2)
	Deletepoints 0,2,FFToutput
	Setscale/P x,2*Pi*x2,deltax(W_FFT)*2*Pi,FFToutput

	setdatafolder DFsav
	return 0
End

static Function moto_update_theoretical()
	wave/z coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	wave/z theoretical_R = root:data:theoretical:theoretical_R
	wave/z theoretical_q = root:data:theoretical:theoretical_q
	wave/z SLD_theoretical_R = root:data:theoretical:SLD_theoretical_R
	Wave/z originaldata = root:data:theoretical:originaldata
	variable plotyp
	
	variable chi2 = 0;
	Motofit(coef_theoretical_R, theoretical_R, theoretical_Q)
	Moto_SLDplot(coef_theoretical_R, sld_theoretical_R)
	chi2 = Moto_calcchi2()
	setmotofitoption("V_chisq", num2str(chi2))
	
	plotyp = str2num(getmotofitoption("plotyp"))
	duplicate/free theoretical_R, temp_R
	moto_plotyp_to_lindata(plotyp, theoretical_q, temp_R)
	originaldata[][1] = temp_R[p]

	note/k coef_theoretical_R
	note coef_theoretical_R, getMotofitOptionString()
End

//adding in functionality to change the way the layers are displayed.
static Function Moto_changelayerwave(layers)
	variable layers
	String savedDataFolder = GetDataFolder(1)		// save
	variable mode = str2num(getmotofitoption("mode"))
	if(numtype(mode))
		mode = 0
	endif
	newdatafolder /o/s root:packages
	Newdatafolder/o/S root:packages:Motofit
	Newdatafolder/o/s root:packages:motofit:reflectivity
	Wave/t/z baselayerparams = root:packages:motofit:reflectivity:baselayerparams
	Wave/t/z layerparams = root:packages:motofit:reflectivity:layerparams
	
	if(Waveexists(baselayerparams) == 0)
		make/t/n=(3, 3) baselayerparams = ""
		make/n=(3, 3) baselayerparams_selwave = 0
	else
		Wave/T baselayerparams
		Wave baselayerparams_selwave
		redimension/n=(3, 3) baselayerparams, baselayerparams_selwave
		baselayerparams = ""
		baselayerparams_selwave = 0
	endif

	if(Waveexists(layerparams) == 0)
		Make/o/t/n=(layers + 2, 4*2+1) layerparams = ""
		Make/o/n=(layers + 2, 4*2+1) layerparams_selwave = 0
	else
		Wave/T layerparams
		Wave layerparams_selwave
		redimension/n=(layers + 2, 4 * 2+ 1) layerparams, layerparams_selwave 
		layerparams = ""
		layerparams_selwave = 0
	endif
	
	setdimlabel 1, 0, layer, layerparams
	setdimlabel 1, 1, thickness, layerparams
	setdimlabel 1, 2, $(""), layerparams
	setdimlabel 1, 3, SLD, layerparams
	if(!mode)
		setdimlabel 1, 5, solvent, layerparams	
	else
		setdimlabel 1, 5, iSLD, layerparams	
	endif
	setdimlabel 1, 7, roughness, layerparams	
	setdimlabel 1, 8, $(""), layerparams
	
	variable ii, jj
	//setup selection waves and parameter numbers	
	for(ii = 0 ; ii < layers + 2; ii+=1)
		layerparams_selwave[ii][0]=0
		for(jj = 0 ; jj < 4; jj += 1)
			layerparams_selwave[ii][2*jj+1]=2
			layerparams_selwave[ii][2*jj+2]=32
		endfor
	endfor
	layerparams[][0] = num2str(p)
	layerparams[0][0] = "fronting"
	layerparams[0][1] = "INF"
	
	layerparams_selwave[0][1]=0
	layerparams_selwave[0][2]=0
	layerparams_selwave[0][7]=0
	layerparams_selwave[0][8]=0

	layerparams[dimsize(layerparams, 0) - 1][0] = "backing"
	layerparams[dimsize(layerparams, 0) - 1][1] = "INF"
	layerparams_selwave[dimsize(layerparams, 0) - 1][1]=0
	layerparams_selwave[dimsize(layerparams, 0) - 1][2]=0
	
	baselayerparams[0][0]="numlayers"	
	baselayerparams[1][0]="scale"	
	if(!mode)
		baselayerparams[2][0]="bkg"
		layerparams_selwave[0][5]=0
		layerparams_selwave[0][6]=0
		layerparams_selwave[dimsize(layerparams, 0) -1][6]=0
		layerparams_selwave[dimsize(layerparams, 0) -1][5]=0				
	else
		layerparams_selwave[0][5]=2
		layerparams_selwave[0][6]=32
		baselayerparams[2][0]="bkg"	
	endif	
	baselayerparams_selwave[][0]=0
	baselayerparams_selwave[][1]=2
	baselayerparams_selwave[][2]=32
	baselayerparams_selwave[0][2]=0
	
	SetDataFolder savedDataFolder	
End


Function Motofit_smeared(w, RR, qq, dq) :Fitfunc
	Wave w, RR, qq, dq
	variable bkg
	//don't want to convolve the reflectivity if the background has been added		
	variable mode = mod(numpnts(w) - 6, 4)
	
	variable plotyp = str2num(getMotofitOption("plotyp"))
		
	make/free/d/n=(numpnts(qq), 2) xtemp
	xtemp[][0] = qq[p]
	xtemp[][1] = dq[p]
	
	if(!mode)
		bkg = abs(w[4])
		w[4] = 0
		Abelesall(w, RR, xtemp)
	else
		bkg = abs(w[6])
		w[6] = 0
		Abeles_imagALl(w, RR, xtemp)
	endif

	//add in the linear background again
	if(!mode)
		w[4] = bkg
	else
		w[6] = bkg
	endif
		
	fastop RR = (bkg) + RR

	//how are you fitting the data?
	moto_lindata_to_plotyp(plotyp, qq, RR)
End

Function Motofit(w, RR, qq) :Fitfunc
	Wave w, RR, qq
	variable bkg
		
	string motofitoptions = getMotofitOptionString()
	variable mode
	variable resolution 
	variable plotyp 
	
//	markperftesttime 0
	if(strlen(motofitoptions))
		resolution = numberbykey("res", motofitoptions)
		plotyp = numberbykey("plotyp", motofitoptions)
	else
		resolution = 0
		plotyp = 1
	endif
	
	//are you imaginary (mode != 0) or real (mode == 0)
	mode = mod((numpnts(w) - 6), 4)
		
	if(numtype(resolution) || resolution < 0.5)
		resolution = 0
	endif
		
	if(!mode)
		bkg = abs(w[4])
		w[4] = 0
	else
		bkg = abs(w[6])
		w[6] = 0
	endif
//	markperftesttime 1			
	if(resolution > 0.5)
		//make it an odd number
		resolution/=100
		Variable gaussnum=13

		Make/free/d/n=(gaussnum) gausswave
		Setscale/I x, -resolution, resolution, gausswave
		Gausswave=gauss(x, 0, resolution/(2 * sqrt(2 * ln(2))))
		Variable middle = gausswave[x2pnt(gausswave, 0)]
		 Gausswave /= middle
		Variable gaussgpoint = (gaussnum-1)/2
				
		//find out what the lowest and highest qvalue are
		variable lowQ = wavemin(qq)
		variable highQ = wavemax(qq)
		
		if(lowQ == 0)
			lowQ =1e-6
		endif
		
		Variable start=log(lowQ) - 6 * resolution / 2.35482
		Variable finish=log(highQ * (1 + 6 * resolution / 2.35482))
		Variable interpnum=round(abs(1 * (abs(start - finish)) / (resolution / 2.35482 / gaussgpoint)))
		variable val = (abs(start - finish)) / (interpnum)
		make/free/d/n=(interpnum) ytemp, xtemp
		multithread xtemp=(start) + p * val

		matrixop/o xtemp = powR(10, xtemp)

//		markperftesttime 2

		if(!mode)
			Abelesall(w, ytemp, xtemp)
		else
			Abeles_imagALl(w, ytemp, xtemp)
		endif
//		markperftesttime 3
		//do the resolution convolution
		setscale/I x, start, log(xtemp[numpnts(xtemp) - 1]), ytemp
		convolve/A gausswave, ytemp

		//delete start and finish nodes.
		variable number2d = round(6 * (resolution / 2.35482) / ((abs(start - finish)) / (interpnum))) - 1 
		variable left = leftx(ytemp), space = deltax(ytemp)
		deletepoints 0, number2d, ytemp
		setscale/P x, left + (number2d * space), space, ytemp
		
		variable gaussum = 1/(sum(gausswave))
		fastop ytemp = (gaussum) * ytemp

//		markperftesttime 4
		matrixop/free xrtemp = log(qq)
		duplicate/free rr, ytemp2
		//interpolate to get the theoretical points at the same spacing of the real dataset
//		markperftesttime 5
		Interpolate2/T=2/E=2/I=3/Y=ytemp2/X=xrtemp ytemp
		multithread RR = ytemp2
//		markperftesttime 6

	else 
		if(!mode)
			Abelesall(w, RR, qq)
		else
			Abeles_imagALl(w, RR, qq)
		endif
	endif

	//add in the linear background again
	if(!mode)
		w[4] = bkg
	else
		w[6] = bkg
	endif
	fastop RR = (bkg) + RR
		
	//how are you fitting the data?
//	markperftesttime 7
	moto_lindata_to_plotyp(plotyp, qq, RR)
//	markperftesttime 8
End

/// offspecular/diffuse conversions
Function/C Moto_angletoQ(omega,twotheta,lambda)
	//function converts omega and twotheta to Qz,Qx. Returns Q as a complex variable (so you can get both parts in)  
	Variable omega,twotheta,lambda
	variable/C Q
	omega = Pi*omega/180
	twotheta = Pi*twotheta/180
	Q=cmplx((2*Pi/lambda)*(sin(twotheta-omega)+sin(omega)),(2*Pi/lambda)*(cos(twotheta-omega)-cos(omega)))
	
	return Q
End

Function moto_lindata_to_plotyp(plotyp, qq, RR[, dr, removeNonFinite])
	variable plotyp
	Wave/z qq, RR, dr
	variable removeNonFinite
	
	variable ii
	
	switch(plotyp)
		case 1:	//logR
			if(waveexists(dr))
				variable ln10 = ln(10)
				multithread dr = abs(dR / (RR * ln10))
			endif
//			multithread RR = log(RR)
			matrixop/o RR = log(RR)
			break
		case 2: //linR, do nothing
			break
		case 3: //RQ4
			if(waveexists(dR))
				multithread dR *= qq^4
			endif
			multithread RR *= qq^4
			break
		case 4: //RQ2
			if(waveexists(dR))
				multithread  dR *= qq^2
			endif
			multithread RR *= qq^2
			break
		default:
			break
	endswitch
	if(removeNonFinite)
		if(!waveexists(dR))
			duplicate/free RR, dR
		endif
		for(ii = numpnts(RR) - 1 ; ii >= 0 ; ii -= 1)
			if(numtype(RR[ii]) || numtype(dR[ii]))
				deletepoints/M=0 ii, 1, qq, RR, dR
			endif
		endfor
	endif
End

Function moto_plotyp_to_lindata(plotyp, qq, RR[, dr])
	variable plotyp
	Wave/z qq, RR, dr
	switch(plotyp)
		case 1:	//logR
			if(waveexists(dr))
				dr = abs(dR  * ln(10) * alog(RR))
			endif
			RR = alog(RR)
			return 0
			break
		case 2: //linR, do nothing
			return 0
			break
		case 3: //RQ4
			if(waveexists(dR))
				dR /= qq^4
			endif
			RR /= qq^4
			break
		case 4: //RQ2
			if(waveexists(dR))
				dR /= qq^2
			endif
			RR /= qq^2
			break
		default:
			break
	endswitch
End


static Function Moto_changeTheoreticalQrange(num, qmin, qmax)
	variable num, qmin, qmax
	if(qmin==0)
		qmin=1e-5
	endif
	
	make/o/d/n=(num) root:data:theoretical:theoretical_q,root:data:theoretical:theoretical_R
	Wave theoretical_Q = root:data:theoretical:theoretical_q
	Wave theoretical_R = root:data:theoretical:theoretical_R
	theoretical_q = qmin+(x)*((qmax-qmin)/num)

	make/o/d/n=(num, 2) root:data:theoretical:originaldata
	Wave originaldata = root:data:theoretical:originaldata
	originaldata[][0] = theoretical_q[p]
	originaldata[][1] = theoretical_R[p]	
End

static Function/s Moto_loadReffile(filename)
	//this function loads a reflectivity file in and adjusts it to the current plot type.
	//it does not plot anything.
	string filename
	variable fileID,numcols, ii,  plotyp
	String dataname

	DFREF saveDFR 
	saveDFR = GetDataFolderDFR( )
	
	//get nice name for file.
	dataname = cleanupname(ParseFilePath(3, filename, ":", 0, 0), 0)
	dataname = dataname[0, 31 - 7]
	
	plotyp = str2num(getmotofitoption("plotyp"))
	if(numtype(plotyp))
		plotyp = 1
		setmotofitoption("plotyp", "1")
	endif
	
	newdatafolder/o/s $("root:data:" + dataname)
	
	try
		if(stringmatch(filename,"*.xml"))	//loading XML type reduced file from Platypus
			fileID = xmlopenfile(filename)
			if(fileID==-1)
				print "ERROR opening xml file (Moto_loadReffile)"
				abort
			endif
			make/o/d/n=(0,0) originaldata
			string nodesToLoad = "Qz;R;dR;dQz"
			
			for(ii = 0 ; ii < itemsinlist(nodesToLoad) ; ii+=1)
				if(!xmlwavefmXPATH(fileID, "//REFdata[1]/" + stringfromlist(ii, nodesToLoad), "", ""))
					Wave/t M_xmlcontent
					redimension/n=(dimsize(M_xmlcontent, 0), dimsize(originaldata, 1) + 1) originaldata
					originaldata[][ii] = str2num(M_xmlcontent[p][0])
				else
					abort "the file does not seem to be of the right type"
				endif			
			endfor
		else	
			LoadWave/Q/M/G/D/N=originaldata fileName
			//if you're not loading 2,3 or 4 column data then there may be something wrong.
			Wave/z originaldata0
			duplicate/o originaldata0, originaldata
			killwaves/z originaldata0
			if(dimsize(originaldata, 1) < 2 || dimsize(originaldata, 1) > 4)
				abort "loaded data has the wrong number of columns"
			endif

		endif
		
		//now we should have a wave called originaldata, partition it into x,y, dy, dx waves.
		make/n=(dimsize(originaldata, 0))/o/d $(dataname + "_q") = originaldata[p][0]
		make/n=(dimsize(originaldata, 0))/o/d $(dataname + "_R") = originaldata[p][1]
		if(dimsize(originaldata, 1) > 2)
			make/n=(dimsize(originaldata, 0))/o/d $(dataname + "_E") = originaldata[p][2]
		endif
		if(dimsize(originaldata, 1) > 3)
			make/n=(dimsize(originaldata, 0))/o/d $(dataname + "_dq") = originaldata[p][3]
		endif
		Wave/z qq = $(dataname + "_q")
		Wave/z RR = $(dataname + "_R")
		Wave/z dq = $(dataname + "_dq")
		Wave/z dE = $(dataname + "_E")
		
		motofit#moto_removeNaN(qq, RR, dE, dQ)
		//how are you fitting the data?
		moto_lindata_to_plotyp(plotyp, qq, RR, dR = dE, removeNonFinite = 1)
	
		setdatafolder saveDFR
		return dataName	
	catch
		//there was an error, remove the datafolder
		killdatafolder $("root:data:" + dataname)
		setdatafolder saveDFR
		return ""
	endtry
End

static Function Moto_Plotreflectivity()
	//this function loads experimental data from a file, then puts it into a nice graph.  The data is from 2 to 4 columns wide:  Q,R,dR,dQ and can contain as
	//many datapoints as you want.
	variable fileID,numcols, ii
	string fileName ="", filenames = "" , topGraphStr = "", dataName = "", refname = ""
	Variable rr,gg,bb, plotyp, logg, numfiles, index
	Wave/z M_colors = root:packages:motofit:reflectivity:M_colors
	
	open/r/d/MULT=1/T="????" fileID
	filenames = S_filename
	
	plotyp = str2num(getmotofitoption("plotyp"))
	if(numtype(plotyp) || plotyp == 2)
		logg = 1
	endif
	//if the user presses cancel then we should abort the load
	if(!itemsinlist(filenames))
		return 0
	endif
	
	for(ii = 0 ; ii < itemsinlist(filenames, "\r") ; ii += 1)
		filename = stringfromlist(ii, filenames, "\r")
		
		//load the file
		dataName = Moto_loadReffile(filename)
  	
		//find out the name of the wave
		Wave qq = $("root:data:" + dataname + ":" + dataname + "_q")
		Wave Ref = $("root:data:" + dataname + ":" + dataname + "_R")
		Wave/z dref = $("root:data:" + dataname + ":" + dataname + "_E")
		refname = nameofwave(ref)

		// assign colors randomly		
		if(Waveexists(M_colors))
			numfiles = itemsinlist(getuserdata("reflectivitygraph", "", "refFiles"), "\r")
			index = mod(numfiles * 37, dimsize(M_colors, 0))
			rr = M_colors[index][0]
			gg = M_colors[index][1]
			bb = M_colors[index][2]
		else	
			rr = abs(trunc(enoise(65535)))
			gg = abs(trunc(enoise(65535)))
			bb = abs(trunc(enoise(65535)))
		endif
		
		if(WinType("") == 1)
			if(findlistitem(tracenamelist("", ";", 1), nameofwave(Ref)) != -1)
				//Moto_autoscale()
				return 0
			endif
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph Ref vs qq
				ModifyGraph mode($refname)=3,rgb($refname)=(rr,gg,bb), grid=0, mirror=0, tickUnit=1, marker=8
				ModifyGraph log(left)=(logg),mirror=0
				if(waveexists(dRef))
					ErrorBars/T=0 $refname Y,wave=(dRef,dRef)
				endif
			else
				//new graph
				Display/K=1 Ref vs qq
				ModifyGraph log(bottom)=0,mode=3,rgb=(rr,gg,bb),grid=0,mirror=0,tickUnit=1, marker=8
				ModifyGraph log(left)=(logg)
				if(waveexists(dRef))
					ErrorBars/T=0 $refname Y,wave=(dRef,dRef)
				endif
				Label bottom "Qz/A\\S-1"
				Label left "Reflectivity"
			endif
		else
			// graph window was not target, make new one
			Display/K=1 Ref vs qq
			ModifyGraph log(bottom)=0,mode($refname)=3,rgb=(rr,gg,bb),grid=0,mirror=0,tickUnit=1, marker=8
			ModifyGraph log(left)=(logg)
			if(waveexists(dRef))
				ErrorBars/T=0 $refname Y,wave=(dRef, dRef)
			endif
			Label bottom "Qz/A\\S-1"
			Label left "Reflectivity"
		endif
		
		//keep a note of which waves are displayed in the graph
		topGraphStr = WinName(0,1)
		setwindow $topGraphStr userdata(refFiles) += fileName + "\r"
	endfor
End

static Function Moto_removeNAN(q,R,dR,dQ)
	Wave/z q,R,dR,dQ
	Variable ii
	for(ii = 0 ; ii < numpnts(q) ; ii += 1)
		if(numtype(q[ii]) != 0 || numtype(R[ii]) != 0)
			if(Waveexists(dq) && Waveexists(dR))
				deletepoints ii, 1, q, R, dR, dQ
			elseif(Waveexists(dR))
				deletepoints ii, 1, q, R, dR
			else
				deletepoints ii, 1, q, R
			endif
			ii-=1
		endif
	endfor
End

static Function/s Moto_useable_coefs()
	//returns a string containing all the coefficient waves that have been created.
	//these reside in root:data:<datasetname>, and are called coef_<datasetname>_R
	DFREF saveDFR = GetDataFolderDFR()	// Save	
	dfref data = root:data
	string possibledatasets, currentchoice
	variable ii
	possibledatasets = moto_fittable_datasets(justfolders = 1)
	string validcoefs = ""
	
	for(ii = 0 ; ii < itemsinlist(possibledatasets) ; ii += 1)
		currentchoice = stringfromlist(ii, possibledatasets)
		cd $("root:data:" + currentchoice)
		Wave/z thecoefs = $("coef_" + currentchoice + "_R")
		if(waveexists(thecoefs))
			validcoefs += "coef_" + currentchoice + "_R" + ";"
		endif
		waveclear thecoefs
		cd root:data
	endfor

	SetDataFolder saveDFR			// and restore
	return validcoefs
End

static Function/s Moto_fittable_datasets([justfolders])
	variable justfolders
	//returns a string containing the fittable datasets.
	//if just folders is specified, then the function returns the datafolders in 
	//root:data.  These folders are created when data is loaded, fits are done on the data
	//or when a coefficient file is loaded.
	//The waves in those folders should be called dataset_R, dataset_q, fit_dataset_R, fit_dataset_q
	
	string validdatasets = ""

	DFREF saveDFR = GetDataFolderDFR()	// Save	
	dfref data = root:data
	string possibledatasets = stringbykey("FOLDERS", datafolderdir(1, data)), currentchoice
	variable ii
	possibledatasets = replacestring(",", possibledatasets, ";")
	if(justfolders)
		return possibledatasets
	endif
	possibledatasets = removefromlist("theoretical", possibledatasets)
	
	for(ii = 0 ; ii < itemsinlist(possibledatasets) ; ii += 1)
		currentchoice = stringfromlist(ii, possibledatasets)
		cd $("root:data:" + currentchoice)
		Wave/z originaldata
		if(waveexists(originaldata))
			validdatasets += currentchoice + ";"
		endif
		waveclear originaldata
		cd root:data
	endfor

	SetDataFolder saveDFR			// and restore
	return validdatasets
End

Function Moto_SLDplot(w, sld)
	Wave w, sld
	//
	//This function calculates the SLD profile.
	//	
	variable nlayers,zstart,zend,ii, jj, temp,zinc, ismultilayer, npoints, layerInsert
	variable mode =  mod(numpnts(w) - 6, 4)
	
	make/d/n=0/free SLDmodelcoefwav
		
	if(mode == 0)
		mode = 0
		redimension/n=(4 * w[0] + 6) SLDmodelcoefwav
		Wave SLD_calcwav = SLDmodelcoefwav
		SLD_calcwav = w
	elseif(mode == 2)
		mode = 1
		redimension/n=(4 * w[0] + 8) SLDmodelcoefwav
		Wave SLD_calcwav = SLDmodelcoefwav
		SLD_calcwav = w
	endif

	nlayers=w[0]
	
	if(4 * w[0] + 6 + 2 * mode != numpnts(w))
		ismultilayer = 1
		NVAR/z Vmulrep, Vmullayers, Vappendlayer
		if(!NVAR_exists(Vmulrep) || !NVAR_exists(Vmullayers) || !NVAR_exists(Vappendlayer))
			print "error, you are trying to produce an SLD plot for a multilayer but the multilayer variables don't exist"
			return 1
		endif
		Wave SLD_calcwav = moto_expandMultiToNormalModel(w, mode, Vmullayers, Vappendlayer, Vmulrep)
		nlayers = SLD_calcwav[0]
	endif

	//setup the start and finish points of the SLD profile
	if(!mode)
		if (nlayers == 0)
			zstart= -5-4 * abs(SLD_calcwav[5])
		else
			zstart= -5-4 * abs(SLD_calcwav[9])
		endif
		
		temp = 0
		if (nlayers == 0)
			zend = 5+4*abs(SLD_calcwav[5])
		else	
			for(ii = 1 ; ii < nlayers + 1 ; ii+=1)
				temp += abs(SLD_calcwav[4*ii+2])
			endfor 	
			zend = 5 + temp + 4 * abs(SLD_calcwav[5])
		endif
	else
		if (nlayers == 0)
			zstart= -5-4 * abs(SLD_calcwav[7])
		else
			zstart= -5-4 * abs(SLD_calcwav[11])
		endif
		
		temp = 0
		if (nlayers == 0)
			zend = 5+4*abs(SLD_calcwav[7])
		else	
			for(ii = 1 ; ii < nlayers + 1 ; ii += 1)
				temp += abs(SLD_calcwav[4 * ii + 4])
			endfor 	
			zend = 5 + temp + 4 * abs(SLD_calcwav[7])
		endif
	
	endif

	setscale/I x, zstart, zend, sld

	sld = Moto_SLD_at_depth(SLD_calcwav, x)
End

Function/Wave moto_expandMultiToNormalModel(w, mode, Vmullayers, Vappendlayer, Vmulrep)
	Wave W
	variable mode, Vmullayers, Vappendlayer, Vmulrep
	//this function takes a multilayer coefficientwave and expands it to look like a normal coefficient wave
	variable layer, jj, kk, layerinsert, muloffset, multilayeroffset

	switch(mode)
		case 0:
			make/n=(4 * (w[0] + (Vmullayers * Vmulrep)) + 6)/d/free expandedSLDmodelwave
			expandedSLDmodelwave[0,5] = w
			expandedSLDmodelwave[0] = w[0] + (Vmullayers  * Vmulrep)
			muloffset = 4 * w[0] + 6
			multilayeroffset = 0
		break
		case 1:
			make/n=(4 * (w[0] + Vmullayers) + 8)/d/free expandedSLDmodelwave
			expandedSLDmodelwave[0, 7] = w
			expandedSLDmodelwave[0] = w[0] + (Vmullayers  * Vmulrep)
			muloffset = 4 * w[0] + 8
			multilayeroffset = 2
			break
	endswitch
	
	for(layerinsert = 0, layer = 0 ; layerinsert < expandedSLDmodelwave[0] ; )
				if(layerinsert == Vappendlayer)
					for(jj = 0 ; jj < Vmulrep ; jj += 1)
						for(kk = 0 ; kk < Vmullayers ; kk += 1)
							expandedSLDmodelwave[4 * layerinsert + 6 + multilayeroffset] = w[muloffset + (4 * kk) ]
							expandedSLDmodelwave[4 * layerinsert + 7 + multilayeroffset] = w[muloffset + (4 * kk) + 1]
							expandedSLDmodelwave[4 * layerinsert + 8 + multilayeroffset] = w[muloffset + (4 * kk) + 2]
							expandedSLDmodelwave[4 * layerinsert + 9 + multilayeroffset] = w[muloffset + (4 * kk) + 3]			
							layerinsert += 1
						endfor
					endfor				
				else
					expandedSLDmodelwave[4 * layerinsert + 6 + multilayeroffset] = w[4 * layer + 6 + multilayeroffset]
					expandedSLDmodelwave[4 * layerinsert + 7 + multilayeroffset] = w[4 * layer + 7 + multilayeroffset]
					expandedSLDmodelwave[4 * layerinsert + 8 + multilayeroffset] = w[4 * layer + 8 + multilayeroffset]
					expandedSLDmodelwave[4 * layerinsert + 9 + multilayeroffset] = w[4 * layer + 9 + multilayeroffset]
					layer += 1
					layerinsert += 1		
				endif
			endfor

	return expandedSLDmodelwave
End


static Function Moto_backupModel()
	duplicate/o root:data:theoretical:coef_theoretical_R, root:packages:motofit:reflectivity:coef_theoretical_R_BAK
End

Function Moto_SLD_at_depth(w, zed)
	Wave w
	variable zed
	variable nlayers,SLD1,SLD2,ii,summ
	Variable deltarho,sigma,thick,dist,rhosolv
	variable mode =  mod(numpnts(w) - 6, 4)
	if(mode == 0)
		mode = 0
	elseif(mode == 2)
		mode = 1
	endif
		 
	if(!mode)
		nlayers=w[0]
		rhosolv=w[3]
		dist=0
		summ=w[2]
		for( ii = 0 ; ii < nlayers + 1 ; ii += 1) 
			if(ii == 0)
				if(nlayers)
					SLD1=(w[7]/100)*(100-w[8])+(w[8]*rhosolv/100)
					deltarho=-w[2]+SLD1
					thick=0
					sigma=abs(w[9])
				else
					sigma=abs(w[5])
					deltarho=-w[2]+w[3]
				endif		
			elseif(ii==nlayers)
				SLD1=(w[4*ii+3]/100)*(100-w[4*ii+4])+(w[4*ii+4]*rhosolv/100)
				deltarho=-SLD1+rhosolv
				thick=abs(w[4*ii+2])
				sigma=abs(w[5])
			else
				SLD1=(w[4*ii+3]/100)*(100-w[4*ii+4])+(w[4*ii+4]*rhosolv/100)
				SLD2=(w[4*(ii+1)+3]/100)*(100-w[4*(ii+1)+4])+(w[4*(ii+1)+4]*rhosolv/100)
				deltarho=-SLD1+SLD2
				thick=abs(w[4*(ii)+2])
				sigma=abs(w[4*(ii+1)+5])
			endif
			dist += thick
		
			//if sigma=0 then the computer goes haywire (division by zero), so say it's vanishingly small
			if(sigma == 0)
				sigma += 1e-3
			endif
		
			summ += (deltarho/2)*(1+erf((zed-dist)/(sigma*sqrt(2))))		
		endfor
	else
		nlayers=w[0]
	
		dist=0
		summ=w[2]
		for( ii = 0 ; ii < nlayers + 1 ; ii += 1) 
			if(ii == 0)
				if(nlayers)
					SLD1=w[9]
					deltarho=-w[2] + SLD1
					thick=0
					sigma=abs(w[11])
				else
					sigma=abs(w[7])
					deltarho=-w[2]+w[4]
				endif
			elseif(ii == nlayers)
				SLD1 = w[4*ii+5]
				deltarho = -SLD1+w[4]
				thick = abs(w[4*ii+4])
				sigma = abs(w[7])
			else
				SLD1 = w[4*ii+5]
				SLD2 = w[4*(ii+1)+5]
				deltarho =- SLD1+SLD2
				thick = abs(w[4*(ii)+4])
				sigma = abs(w[4*(ii+1)+7])
			endif
			dist += thick
		
			//if sigma=0 then the computer goes haywire (division by zero), so say it's vanishingly small
			if(sigma == 0)
				sigma += 1e-3
			endif
		
			summ += (deltarho/2)*(1+erf((zed-dist)/(sigma*sqrt(2))))		
		endfor
	endif
		
	return summ
End

static Function Moto_initialiseReportNotebook()
	NewNotebook/v=0/F=1/N=ReflectivityFittingReport as "Reflectivity fitting report"
End


///////////////////////////
///////////////////////////
//           GUI ACTION PROCEDURES
///////////////////////////
///////////////////////////
static Function moto_GUI_button(B_Struct): buttoncontrol
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode!=2)
		return 0
	endif
	string datasetname = "", datasetnames = ""
	variable ii, refnum
	strswitch(B_Struct.ctrlname)
		case "addconstraint_tab1":
			if(waveexists(root:packages:motofit:reflectivity:ConstraintsList)==0)
				Make/T/n=1 root:packages:motofit:reflectivity:constraintsList
				Make/n=1 root:packages:motofit:reflectivity:constraintsSel = 2
				Wave/t constraintsList = root:packages:motofit:reflectivity:constraintsList
				Wave constraintsSel = root:packages:motofit:reflectivity:constraintsSel
				Listbox/z constraints_tab1, win=reflectivitypanel, listwave = constraintslist, selwave = constraintssel, pos={171,54}, size={400,370}, fsize=12
			else
				Wave/t constraintsList = root:packages:motofit:reflectivity:constraintsList
				Wave constraintsSel = root:packages:motofit:reflectivity:constraintsSel
				redimension/n=(dimsize(constraintslist, 0) + 1) constraintslist, constraintsSel
				constraintssel=2
			endif		
			break
		case "removeconstraint_tab1":
			if(waveexists(root:packages:motofit:reflectivity:ConstraintsList)==0)
				ABORT "there is no constraints wave"
			else
				Wave/t constraintsList = root:packages:motofit:reflectivity:constraintsList
				Wave constraintsSel = root:packages:motofit:reflectivity:constraintsSel
				redimension/n=(dimsize(constraintslist, 0) - 1) constraintslist, constraintsSel
			endif
			break
		case "ChangeQrange":
			Moto_changeQrangeprompt()
			moto_update_theoretical()
			break
		case "restore":
			Wave/z backup = root:packages:motofit:reflectivity:coef_theoretical_R_BAK
			if(waveexists(backup))
				moto_usecoefWave(backup)
				moto_update_theoretical()
			endif
			break
		case "snapshot":
			string ywave ="", xwave="", sldwave="", df = ""
			if(!Moto_snapshot(ywave, xwave, sldwave, df))
				if(Findlistitem(ywave, tracenamelist("reflectivitygraph", ";", 1)) == -1)
					Wave ysnap = $(df + ywave)
					Wave xsnap = $(df + xwave)
					Wave/z M_colors = 	root:packages:motofit:reflectivity:M_colors	
					variable rr, gg, bb, index
					if(Waveexists(M_colors))
						variable numfiles = itemsinlist(moto_fittable_datasets())
						index = mod(37 * numfiles, dimsize(M_colors, 0))
						rr = M_colors[index][0]
						gg = M_colors[index][1]
						bb = M_colors[index][2]
					endif
					appendtograph/w=reflectivitygraph ysnap vs xsnap
					modifygraph/W=reflectivitygraph rgb($ywave)=(rr,gg,bb),lsize($ywave)=2
					Legend/C/N=text0/A=MC
				endif
				if(Findlistitem(sldwave,tracenamelist("sldgraph", ";", 1)) == -1)
					Wave sldsnap = $(df + sldwave)
					appendtograph/w=SLDgraph sldsnap
					modifygraph/W=SLDgraph rgb($SLDwave)=(rr,gg,bb),lsize($SLDwave)=2
					Legend/C/N=text0/A=MC
				endif
			endif
			break
		case "refreshData":
			Moto_refreshData()
			break
		case "croppanel":
			//			moto_croppanel()
			break
		case "Autoscale":
			Setaxis/A/W=reflectivitygraph
			break
		case "loaddatas_tab0":
			Dowindow/F reflectivitygraph
			//this function loads the data into IGOR.
			//the plot will try to append the loaded data to the first graph.
			Moto_Plotreflectivity()
			string loadeddatasets = Moto_fittable_datasets()
			if(itemsinlist(loadeddatasets) == 1)
				popupmenu dataset_tab0, win=reflectivitypanel, mode=1, value= motofit#Moto_fittable_datasets()
				setmotofitoption("dataset", stringfromlist(0, loadeddatasets))
				moto_update_theoretical()	
			endif
			
			break
		case "dofit_tab0":
			//start a report notebook for the fitting
			string notebooklist = Winlist("Reflectivityfittingreport",";","Win:16")
			if(itemsinlist(notebooklist)==0)
				Moto_initialiseReportNotebook()
			endif
			
			Moto_do_a_fit()	
					
			break
		case "loadcoefwave_tab0":
			datasetname = moto_loadcoefs()
			if(stringmatch(datasetname, "theoretical"))
				moto_usecoefWave(root:data:theoretical:coef_theoretical_R)
			endif
			break
		case "savefitwave_tab0":
			datasetnames = moto_fittable_datasets(justfolders = 1)
			string listoffits = "", datasettosave
			listoffits += "theoretical;"
			for(ii = 0 ; ii < itemsinlist(datasetnames) ; ii+=1)
				datasetname = stringfromlist(ii, datasetnames)
				Wave/z fitQQ = $("root:data:" + datasetname + ":fit_" + datasetname + "_q")
				Wave/z fitRR = $("root:data:" + datasetname + ":fit_" + datasetname + "_R")
				if(waveexists(fitRR) && waveexists(fitQQ))
					listoffits += datasetname + ";"
				endif
				Waveclear fitQQ, fitRR
			endfor	

			prompt datasettosave, "dataset", popup, listoffits
			Doprompt "Please select the fitted dataset that you would like to save the fit for.", datasettosave
			if(V_flag)
				return 0
			endif
			if(stringmatch(datasettosave, "theoretical"))
				Wave/z fitRR = root:data:theoretical:theoretical_R
				Wave/z fitQQ =  root:data:theoretical:theoretical_q
			else
				Wave/z fitRR =  $("root:data:" + datasettosave + ":fit_" + datasettosave + "_R")
				Wave/z fitQQ =  $("root:data:" + datasettosave + ":fit_" + datasettosave + "_q")
			endif	
			moto_plotyp_to_lindata(str2num(getmotofitoption("plotyp")), fitqq, fitRR)
			
			open/d refnum as "fit_" + datasettosave
			if(strlen(S_filename))
				open refnum as S_filename
				wfprintf refnum, "%g\t%g\r", fitQQ, fitRR
				close refnum
			endif
		
			moto_lindata_to_plotyp(str2num(getmotofitoption("plotyp")), fitqq, fitRR, removeNonFinite = 1)	
			break
		case "savecoefwave_tab0":
			string coefwaves, coefwave
			//this function saves the fit coefficients (parameters) to file
			//the idea is that you can print to a wave, even if you don't have the full version of IGOR
			//choose from all the coefficient waves on offer
			coefwaves = moto_useable_coefs()
			variable savechoice=0
			
			prompt savechoice,"which coefficient wave do you want to save?",popup, coefwaves
			Doprompt "which coefficient wave do you want to save?", savechoice
			if(V_flag==1)
				abort
			endif
			coefwave = Stringfromlist(savechoice-1, coefwaves)
			datasetname = replacestring("coef_", coefwave, "")
			datasetname = replacestring("_R", datasetname, "")
			Wave thecoefs = $("root:data:" + datasetname + ":" + coefwave)
			open/d refnum as coefwave
			if(!strlen(S_filename))
				ABORT
			endif
		
			//open the file for writing
			open refnum as S_filename
		
			//we want to save the wave as an IGOR wave, which means that you can double click it and it automatically loads the parameters up
			//into the reflectivity panel
			fprintf refnum, "IGOR\rX plotcalcref()\rWAVES/D %s\rBEGIN\r", coefwave
			wfprintf refnum, "\t%g\r", thecoefs		//this prints the coefwave to file.
			fprintf refnum,"%s\r","END"
			String coefnote=note(thecoefs)
		
			//if you do a global fit then it's entirely likely that the coefficient wave won't be updated properly
			if(strlen(coefnote)<10)
				coefnote = getMotofitoptionstring()
				if(thecoefs[0] * 4 + 6 == numpnts(thecoefs))
					coefnote = replacenumberbykey("mode", coefnote, 0)
				elseif(thecoefs[0] * 4 + 8 == numpnts(thecoefs))
					coefnote = replacenumberbykey("mode", coefnote, 1)
				elseif(!mod(numpnts(thecoefs) - thecoefs[0] * 4 + 6, 4))
					coefnote = replacenumberbykey("mode", coefnote, 0)
					coefnote = replacenumberbykey("multilayer", coefnote, 1)
					coefnote = replacenumberbykey("Vmullayers", coefnote, (numpnts(thecoefs) - thecoefs[0] * 4 + 6)/4)
				elseif(!mod(numpnts(thecoefs) - thecoefs[0] * 4 + 8, 4))
					coefnote = replacenumberbykey("mode", coefnote, 1)
					coefnote = replacenumberbykey("multilayer", coefnote, 1)
					coefnote = replacenumberbykey("Vmullayers", coefnote, (numpnts(thecoefs) - thecoefs[0] * 4 + 8)/4)				
				endif
			endif
		
			//this following sections writes the wavenote to file so that it can be used to reconstruct the coefficient wave
			fprintf refnum, "X Note %s, \"%s\"\r", coefwave, coefnote
					
			close refnum
			break
		case "addcursor_tab0":
			controlinfo/W=reflectivitypanel dataset_tab0
			datasetname = S_value
			if(stringmatch("_none_", datasetname))
				return 0
			endif
			
			wave dataset = $("root:data:" + datasetname + ":" + datasetname + "_R" )
			string traces = tracenamelist("reflectivitygraph",";",5)

			if(whichlistitem(datasetname + "_R", traces)>-1)
				cursor/A=1/W=reflectivitygraph A, $(datasetname + "_R"), 0
				cursor/A=1/W=reflectivitygraph B, $(datasetname + "_R"), numpnts(dataset)-1
				showinfo/W=reflectivitygraph
			endif
			break
	endswitch
	
	return 0
End

static Function  moto_GUI_check(s) : CheckBoxControl
	STRUCT WMCheckboxAction &s
	if(s.eventcode == -1)
		return 0
	endif
	strswitch(s.ctrlname)
		case "usemultilayer_tab0":
			Doalert 0, "Coming soon, not yet implemented in the GUI"
			return 0
			break
		case "usedqwave_tab0":
			setmotofitoption("usedqwave", num2istr(s.checked))
			break
		case "useerrors_tab0":
			setmotofitoption("useerrors", num2istr(s.checked))
			break
		case "useconstraint_tab0":
			setmotofitoption("useconstraint", num2istr(s.checked))
			break
		case "fitcursors_tab0":
			setmotofitoption("fitcursors", num2istr(s.checked))
			break
		case "appendresiduals":
			if(s.checked)
				moto_appendresiduals()
			else
				moto_unappendresiduals()
			endif
			break
	endswitch
	moto_update_theoretical()
End

static Function moto_GUI_PopMenu(s) : PopupMenuControl
	STRUCT WMPopupAction &s
	variable ii
	string datasets = "", dataset = ""
	
	if(s.eventcode == -1)
		return 0
	endif
	strswitch(s.ctrlname)
		case "dataset_tab0":
			moto_update_theoretical()
			setmotofitoption("dataset", s.popstr)
			Moto_FTreflectivity()
			break
		case "plotype_tab0":
			moto_change_plotyp(s.popnum)
			break
		case "coefwave_tab0":
			string thecoefs = s.popstr
			string datasetname = replacestring("coef_", thecoefs, "")
			datasetname = replacestring("_R", datasetname, "")
			Wave/z coefs = $("root:data:" + datasetname + ":" + thecoefs)
			moto_usecoefwave(coefs)
			moto_update_theoretical()
			break
	endswitch
End

static Function moto_GUI_listbox(LBS) : ListboxControl
	STRUCT WMListboxAction &LBS
	//this function updates the model + updates things
	string whichList =  nameofwave(LBS.listwave)
	Wave selwave = LBS.selwave
	Wave/T listwave = LBS.listwave
	variable row = LBS.row, col = LBS.col	, eventcode = LBS.eventcode
	
	Wave/t layerparams = root:packages:motofit:reflectivity:layerparams
	Wave layerparams_selwave = root:packages:motofit:reflectivity:layerparams_selwave
	
	switch(eventcode)
		case -1:
			return 0
			break
		case 13:
			moto_updateholdstring()
			return 0
			break
		case 4:
			slider slider0_tab0, win=reflectivitypanel, userdata(whichparam) = "listwave-"+GetWavesDataFolder(listwave, 2)+";row-"+num2istr(row)+";col-"+num2istr(col)
			break
		case 7:
			slider slider0_tab0, win=reflectivitypanel, userdata(whichparam) = "listwave-"+GetWavesDataFolder(listwave, 2)+";row-"+num2istr(row)+";col-"+num2istr(col)
			if(numtype(str2num(listwave[row][col])))
				Doalert 0, "please enter a number"
				return 0
			endif
			if(stringmatch(whichlist, "baselayerparams") && row == 0 && col == 1)
				listwave[0][1]=num2istr(abs(str2num(listwave[0][1])))
				variable newlayers = str2num(listwave[0][1])
				variable oldlayers = dimsize(layerparams, 0) - 2
				variable howmany = abs(oldlayers - newlayers)
				variable  ii=0, jj=0
		
				if(oldlayers > newlayers)
					//this line of code enables the user to remove the layer from where he would like
					Variable from = oldlayers
					prompt from, "remove which layer?"
					Doprompt "remove which layer?", from
					if(V_FLag==1)
						listwave[0][1]=num2istr(oldlayers)
						return 0
					endif
					if(from < 1 || from - 1  > oldlayers - howmany)
						listwave[0][1] = num2istr(oldlayers)
						Doalert 0, "you can't remove from that place"
						return 0
					endif
					deletepoints (from),(howmany),layerparams,layerparams_selwave
				elseif(newlayers > oldlayers)
					Variable to=oldlayers
					prompt to, "insert after which layer?"
					Doprompt "insert after which layer?", to
	
					if(V_FLag == 1)
						listwave[0][1]=num2istr(oldlayers)
						return 0
					endif
					if(to<0 || to > newlayers)
						listwave[0][1]=num2istr(oldlayers)
						return 0
					endif
			
					insertpoints (to + 1), (howmany), layerparams,layerparams_selwave
					for(ii = 0 ; ii < howmany ; ii+=1)
						layerparams[ii + to + 1][1] = "0"
						layerparams[ii + to + 1][3] = "0"
						layerparams[ii + to + 1][5] = "0"
						layerparams[ii + to + 1][7] = "0"
						layerparams_selwave[ii + to + 1][0]=0
						layerparams_selwave[ii + to + 1][1]=2
						layerparams_selwave[ii + to + 1][2]=32
						layerparams_selwave[ii + to + 1][3]=2
						layerparams_selwave[ii + to + 1][4]=32
						layerparams_selwave[ii + to + 1][5]=2
						layerparams_selwave[ii + to + 1][6]=32
						layerparams_selwave[ii + to + 1][7]=2
						layerparams_selwave[ii + to + 1][8]=32
					endfor	
				endif
				for(ii = 1 ; ii < dimsize(layerparams, 0)-1 ; ii+=1)
					layerparams[ii][0] = num2istr(ii)
				endfor
			endif
			
			//send the values to the coefficient wave
			Moto_LayerTableToCref(root:data:theoretical:coef_theoretical_R) 
			//calculate the theoretical reflectivity
			Wave/z coef_theoretical_R = root:data:theoretical:coef_theoretical_R
			Wave/z theoretical_R = root:data:theoretical:theoretical_R
			Wave/z theoretical_q = root:data:theoretical:theoretical_q
		
			moto_update_theoretical()
			//set user data in the control to indicate which control was altered (for the slider control)
			slider slider0_tab0, win=reflectivitypanel, userdata(whichparam) = "listwave-"+GetWavesDataFolder(listwave, 2)+";row-"+num2istr(row)+";col-"+num2istr(col)
			doupdate
	
	endswitch
	
	
	return 0
End

static Function moto_GUI_tab(TC_Struct)
	STRUCT WMTabControlAction &TC_Struct
	Variable tab=TC_Struct.tab
	//	ModifyControlList ControlNameList("Reflectivitypanel", ";", "*_tab0"), disable = 0
	if(TC_struct.eventcode == -1)
		return 0
	endif
	String controlsInATab= ControlNameList("Reflectivitypanel", ";", "*_tab*")
	String curTabMatch= "*_tab"+num2istr(tab)
	String controlsInCurTab= ListMatch(controlsInATab, curTabMatch)
	String controlsInOtherTabs= ListMatch(controlsInATab, "!"+curTabMatch)

	ModifyControlList controlsInOtherTabs disable=1, win = reflectivitypanel	// hide
	ModifyControlList controlsInCurTab disable=0, win = reflectivitypanel		// show
	Setwindow reflectivitypanel#FFToutput hide= (tab!= 2)
End

static Function moto_GUI_slider(s) : SliderControl
	STRUCT WMSliderAction &s
	string userdata = getuserdata("reflectivitypanel", "slider0_tab0", "whichparam")
	if(!strlen(userdata))
		return 0
	endif
	if(s.eventcode == -1)
		return 0
	endif
	Wave/t/z listwave = $(stringbykey("listwave", userdata, "-"))
	variable row = numberbykey("row", userdata, "-")
	variable col = numberbykey("col", userdata, "-")
	wave/z coef_theoretical_R = root:data:theoretical:coef_theoretical_R
	wave/z theoretical_R = root:data:theoretical:theoretical_R
	wave/z theoretical_q = root:data:theoretical:theoretical_q
	if(stringmatch(stringbykey("listwave", userdata, "-"), "root:packages:motofit:reflectivity:baselayerparams"))
		if(row==0 || col != 1)
			return 0
		endif
	endif
	if(s.eventcode & 2^1)
		if(row < dimsize(listwave, 0) && col < dimsize(listwave, 1))
			slider slider0_tab0, limits = {0.5 * str2num(listwave[row][col]), 1.5 * str2num(listwave[row][col]), str2num(listwave[row][col])/500}, value=str2num(listwave[row][col])
		endif
	endif
	if(s.eventcode & 2^3)
		if(row < dimsize(listwave, 0) && col < dimsize(listwave, 1))
			listwave[row][col] = num2str(s.curval)
			Moto_LayerTableToCref(root:data:theoretical:coef_theoretical_R)
			moto_update_theoretical()
		endif
	endif
	if(s.eventcode & 2^2)
		slider slider0_tab0, value = 0, limits = {-1, 1, 0.2}
	endif
End

static Function moto_GUI_setvariable(s) : SetVariableControl
	STRUCT WMSetVariableAction &s
 	
	switch(s.eventcode)
		case -1:
			return 0
		break
		default:
			strswitch(s.ctrlname)
				case "res_tab0":
					setmotofitoption("res", s.sval)
					moto_update_theoretical()
					valdisplay chisquare_tab0, value = _NUM:str2num(getmotofitoption("V_chisq")), win=reflectivitypanel
					break
				case "FT_lowQ_tab2":
				case "FT_hiQ_tab2":
					Moto_FTreflectivity()
				break
				case "numfringe_tab2":
					variable numfringes = s.dval, leftP, rightP
					string lci, rci
					lci = csrinfo(A, "reflectivitygraph")
					rci = csrinfo(B, "reflectivitygraph")
					if(!strlen(lci) || !strlen(rci) || !stringmatch(stringbykey("TNAME", lci), stringbykey("TNAME", rci)))
						Doalert 0, "the cursors must be on the same trace in the reflectivitygraph"
						return 0
					endif
					Wave xwave = xwavereffromtrace("reflectivitygraph", stringbykey("TNAME", lci))
					
					leftP = numberbykey("POINT", csrinfo(A, "reflectivitygraph"))
					rightP = numberbykey("POINT", csrinfo(B, "reflectivitygraph"))
					if(leftP > rightP)
						variable temp = rightP
						rightP = leftP
						leftP = temp
					endif
					setvariable fringe_tab2, win=reflectivitypanel, value = _NUM:numfringes * 2*Pi/(xwave[rightP] - xwave[leftP])
				break	
			endswitch
			break
	endswitch		
End


static Function Moto_AboutPanel()
	DoWindow About_Motofit
	if(V_Flag)
		DoWindow/K About_Motofit
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1 /W=(173.25,101.75,550,370) as "About_Motofit"
	DoWindow/C About_Motofit
	SetDrawLayer UserBack
	SetDrawEnv fsize= 20,fstyle= 1,textrgb= (16384,28160,65280)
	DrawText 140,37,"Motofit"
	SetDrawEnv fsize= 16,textrgb= (16384,28160,65280)
	DrawText 70,64,"@ Andrew Nelson, 2005-2009"
	SetDrawEnv fsize= 14,textrgb= (16384,28160,65280)
	DrawText 10,84,"Australian Nuclear Science and Technology Organisation"
	DrawText 11,136,"For further help please contact:" 
	DrawText 11,160,"Andrew_Nelson@users.sourceforge.net"
	DrawText 11,180,"http://motofit.sourceforge.net"

	DrawText 11,216,"Analysis of multiple contrast X-ray and"
	DrawText 11,236,"Neutron Reflectometry data."
	
	DrawText 11,256,"Motofit mode: " + " $Rev: 409 $"
	DrawPict 270,110,1,1,Procglobal#motofit#moto
	
end


// JPEG: width= 100, height= 172
static Picture moto
ASCII85Begin
s4IA0!"_al8O`[\!<E1.!+5d,s5<qn7<iNY!!#_f!%IsK!!iQ)zs4[N@!!NH-"9\f1"9\i2"U,)8$j
[(C#6tbI$OI4R%h]Ke%hTBe(*",('H.\u&JuZ.)BBh?+!2.4+s\?R,TIjI*rjsp6NI>o"U>5:%L<=M
*Y]2#*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zk?s!"fJ:X8l
c5!?qLF&HMtG!WU(<)uos?!WrH(zz!!!3."9ec-#Qb&,_uMt4!!30'!WrT1"9el/#64`(!<N?+"VC_
X"qiWq'1#K('I#;PJWW9mZ,%/";UOG=1L_X!#W,IiP-XWX_uL_W!!<3'!<E0#zz"9eu2!s\f,s24mo
&HDh6!X&T/#Qb&0z!!*'$!sB2>&g8tC5u@h1@=b*d13&G]_9qa=i<LS`;Xse@!"8r1!!3`7&HG#q'=
U6W<7!>@H'huP_c#r[,p+5ubcCg,8^MtW)Mc+K9ilDFX!T&nZCq![f2eDfXToJX[6_k4ERQ!err<u#
:pdZ)V!]8q.__V."3]u236HM].D:^%17++!%3[^FNTp4t'o0g9@JA6ZnM<s>,7em,+i]iHUsKu=Y1X
gN)'kXe:l$kuaM>f_coaf@B]so'</nM.idpo#ENQ[]?#>#:`D6lNH2ptj$?>C\7GKuADc'@k\O/2YT
'E!$QLjn\l(K10dKjQ#RL!(FYY$Vic*kfXqJ.S)C-$F$\s*$RZ\jIb!op,?qN%oQ<*DjHe>_krn>HL
jO+q_iU>7m[P(:I:2i;plfiamn?G9O]HKj`+%RE_r;F;!nnIAM@?m"q=!.LC%Cio0i#`b/WW<BFCji
=O$g"LbBfn>\4/.jMP+t#!Kq;$*\mt>VF^.G=Q=M^Ve4i3g81aI@jOtd2%,j/HgEM\]06OL[3R.ADB
E.)s$o[9A=?I-Qp]lbDB<?DN99F(7Fa89TM(#"Dd7!"8!Ks&>a)ocas>B#?1gj!9UX1#=0ZXuC5)(X
m2>o)pXHe*E8X,Qtn2T.nAi:S[_RF:g!7o=2HUoB?KOY`4Ha3X$.0%!nH8M*-bZaZ#7Wliopp@IFEl
AUa^^tf#?Th/)rH9GEm4l`&F^j'WO+_SHi*>!b^i017nepmpi;6d39D73,Ub-"TAhrnMgk+;lrRqR_
f\@\C*rDjCDkb'"KK:u&dbVW2OCOuQ+,m8e]1dTl%_BZp@fbR8o2=\CC[1d0L93U2J-^&)`EkM9I3`
II\b.0V,e8>i'<8RDqQM2A-l0[cR,kP]hhe_P,=*L(uk2hqo3V1_cYZ_),RAZWJJ)5B]D"sToQBu)[
3eEI92`c?+W4H#d*Nq%l*A7\&N9OO8QCYkTaS]7\Ngc1051NAK&=NZ+P^bBGjGeoJ-o3/+%_S=a)e6
%O/d=<['bM')DN19D>hPC+9']#B[L&-dc@L;FVh,0dUu^\&at_+*nC87iZub@eDF*8Q-Nh^)C#W?^"
eNg56[u*idRQ6=(lW&u?Q$Wap$&L/*mJZ^lYZLM?VrX;2'(/ATG@b8S]>'(kVZ"'fug!^.c'O]jnM6
[,S#;)cL2bfQDLCC=R%ubaJTk`nT\^=e.*guK!(A>2Cq]0EO\7-kGr9kME2s0&fJOR`nLU+`hHAL-&
P+k^31k@#==gd,qg0=XCS&]LGbnNHW[LP9WMG%#f`8dbh*'$k;ih*qA=!rWbM:;3;60*dl^]GL9:an
_Uqg376NAbF1%8_k\>"?dni03/EKG+!5%XM>uS$gP:C&sao#,@+\LCF?e%QIUhD5]35I(**G1;t(9+
A%rVOJG2`V-#?+i2JC6@n$@q<?/mYgIa4.K>4)0pdm@TMU1%Q.PG7HLR%Ck/`iF>tYhk^p7l`Di'qU
A%@/U>RP#!O2(J90:!rVcdDrC3ReTJ4?@`K-cjD,CA\T!/[79@3(.c.2#4ri9,N2#@hs=(cXRDU[s<
$)%(Nl)uA`&Qeks\)2]c\gGY";4Q>,7VJ.KNJa+iJ(R5b&3=egT%\)jf=RHT;)IXRZXEq"YF_"??7+
\\L?VeX?'?qdPiEQJDojBn:[FO'2W[O<>HH8*F-,&^EFgfE0S3:]H.UFO86IbHT,#FfKQi]A\W'4Ad
DCj^Lb*aZ[Md$ndqhY`dNS+%<:S+BI]+[%P"K^2/J>ape$p%O31m.=6?u[OtdrpZ&7A;4!ESG'%B6b
lg)kS:ihoPc'05.[r/GACR%Tk2eZAsX18SV@8<(bnl^[W0,l?-$8iS2>";T2X94ELl+_;6k>%[\/C:
tqY?@#-ugKR%?^3SJX7PYo4V!.9n^_]YVOFPKRX2]r-o^L!a*WjfB(!t;-+dhpRokis<i).d68p$&2
RZD^V6,^%FfX/[LK\NA2iic3J=6H<!u$S3.X4QqO'1rRkMl?O,rQ.-8haD7?LWB>QDFJOonR$pHU;m
pl$8mR!NN7"51LsNc]&_)e]B5I#Kj4S"A,PdFUC`I]cTQVf#<#1U86=5\g=\Kmn724M?GWdL-eQp`T
ZgXnC@@s-t8qA\s"^DS(ZX$)T%j7W<EAqk_r(lEr:E2r#9l6,F$P7E2\isl^qIJiUg/eqlU/Oc*^N^
`n#4Q'+d,tG`+hH7J>?;SK:P5.14t"r#Lngh,CbC*l[+/De!msBPipB01;+0dZ1$!IseDP3L>om9r%
+r'>[41C9B`oI;hoe$#UR:(k%9_F7.A5aN79m+ZnF=N%lD56&j^M2&ffQ/VIrm*Z?^G%'-8>6@()d:
\<@`u&W[DL#F8S[^/@77R2-@!-XG'd;OFRq>*t;HYZ?lEFm4:*]%4T<Z8JJ?^ch-:h=5<%X.pF=*(o
E^/DH/.rl(<(^Kl5gQATb"-;fIfu_jWD($!`'Cj!=E[_cAWsKFl-KER=*t1W-.=XF=9+aQ'Q9.&X]H
eMM<r\$jbYN`B]5+EThVVDHcBTC)4-@-9RRE6f%um?&6&n>pN[*T0-Oq4//="HbB.S@h3t^Jh9uMW+
(u4/RnoUu'8h:t^g@41kV?Rc"VBLcur*4),4!_,css%RAngDZd#]V,TRU"0jrbgFf8Hd[86hJfEuNp
<reb34t5-=Yc8%ZB'=7M.rfK?-9b;E]aS*Y%Zk:Wp]dr<7J1pm]OA18Q"NGY8,i!3]9ZQ%tkQX4GK!
r8:/W+XI^jD9cB]mS8XD-h`BtlQ_`P"c5YFcm2UCcRL`@QPdO1?-=c]!BsZKXMMgN5Y?+_*$:r\XZ,
V)!Au_J/Q,U1/9r32j_*MA&e,)#ZY*l(@1fZp[DPV)uI58<Id+$R0niANo%s8^r&X#/8je+fc;(c*h
=Tphc!.(IA,LcalD8)EAUZ$?MOX#nl?s$o#I>3i,R\PQU)E`Jl(o.Sbj8H)(ePQ3Smo6_0J^ZfO]p>
'NLQY`OQTV@.r<VrJ;50JAXX%MD@3kE<plIQ9R["#m\hLhQ?0_$&IM(2PD]MG.Tr&AQA(;&[iY"u4X
HprgM*&j^@$D;Zh<2F*d,Q1Z%J:fuBI`E?92FEilT:L8Fo4[h:Cj)D75Y.3.g*_@Rr2g?@![7/Zb2;
P]SL*[0H9ra5<n\5A#OBc%fP7V[n"lt8PJXKc)eV-:K&8h/#&+#.-mi?4R[mNW:EahqU7TKiC'].UD
<lMPKF-le+;*YD+p2e%1u(G4!(pR@p#+%j']G&%uN:X"g.hb/(LYt+i>RW9`(gigJR5W-m4_gQ/e#)
%d+qBTi'F99!8d^3U.,PYI2odjbq-P&+p@9f>bftX9OO%#QnTN`3g+/1f38Q1WiLKRJes%ek9Q'(K4
GA[8<b6,HBfLQQ'f*FB`oZg5VL:TdOoqrgKppejVol)H.K=3gtN[=d\Q7bVI)s!7aOS>0!uqGju9?O
m_Ft%9[b]]0RC\''G_d,<i]`??(AsZ5_l0_c[tp!L?T6T+S0R_3*IMPTE=FCJ>m8*RHp0bZU[)Otn^
PrgIh)=40B/=\1I&Q8afcc[t*Dq0lgG"I=/?;RJ&m1t'i&WWDVjS:g'c1:U4-Q@rR[d.arRKrE#L&e
t!/)[pI[[1q`J'#38TI!>P[9:\lri4sL5WO5_]e<PnDn^E\f2K?l9NUT`+)VYp].fGkuqoOle"GOlm
I`LoZoG38_!/=JQ!%5K8<!1uuCdpIX1"R>m4ZSlb0g,!*+HaB05!D,P2kE""h)?F;[=VX?>GROBK-M
l,k:!5Fnis"c]U[W:)jPA;`uf^qNbK\"]S8e8]=3=1Fgi$:c@ano*p29@[Gl"?1gUYE$gUd@Pqrc#+
^:0DfaMqlI[]e*:aDfJN^CQnpIQD2`-N%&qWbN`.XNflV[<aU#j]8#)YX@l1/YnjP)kh44-I4)qJf#
!pV^VMK<if9i_3qW"SsQEeb<Rd;]KU7OjrYRcEOY[=(0=rW3-O]b9VZp]+>0<3e^ih\L(P_2HAW^6j
URYWlZ#^7a"3*pN5jK.!Ld6mF,nYhJ_B'lqg(*[-Nn3-Z5P>Zt4HH,-]Nl91mZ6qnb`?oAl&g5(I<n
L\N@\=2Y=3`>$-u,J<_n4G.(H5MJqPf!i=;JCF6].?-nH$*ZjGcLBn42*f'7D^:L)Nhk_KgZp`E1c<
fV9Sl8MTVd90&R/^7T!LnTo7-Q6<5>1Z(3G'@&)#Ji;VUJPb,\:%9,(q3(1[<MIDQ@+2IrVbLlV#DW
r58JJV3U8kG<+r*[6bLmklt$aRo#<KiGM9r6,3<!nr!#;aKc?n04"M7j^@($3&Y0m7g&Rf>LDV*a/]
&^`WQqM]\sY/IHh\4AL0)GpEaOB0IR/pX&<N]r%FT+n"#h:G814C>rDW,-7er(O3bbHn/SE4(nQnYh
$'Em,iI2dNk7&p$&8+aOnbmDMFI$&XBK'#Lf-?VM1ds!6^N`A+KX"(tQ:PZP+I<<L9$pkLXY0<jR[(
A4LVYNRSW%\eF*SJm#33e[ag^Ko@bO`,%X#5=;;IT[_1(#,M2u;\q23,:W_[9"UUV9qG<9\!hsG*,9
%Zcr/>h+]-$?Gu+(=Du8gObu:'-o!$>g1oIN,q0q&9GIU^96l`Ho`-H-n<m`g_(<(4>qrk"D`fuLT[
VDeTer+g;r@;W?frGq&BE3'l(j+''mL:mEDL"f)q>@WY=]Ugkmi4@W6+6WuYh7h":j_:X7`8\Bi9iD
s';\PmkoXMqY,to,$o*q*@%^WaRW^t2aCJ:K:m)+=)I[T5JkP3-Niq1!)r]m<a-khXgJN3rLSCN?L6
0jXkns[TL^k\+!On*AeSk;^Lb88?Zr`'^#ZANI0U2Z.GtB5mo_W@I6u?KpA8E(JIoX^'I:Zu&E_srN
I"9i[MC?(0?!c(0)gu6$+";4;T-;f2(uOMXd/BlLj>;DDjdiEn,d_Uq;SEtiQd]*=Tr+>Lcs=a&4rj
Wc_FB,qWTnqH,M:$L:tRBXe<`aR\lsnl"9/A2LFPL"kiS5>8?$t2,Z)i_l^'3l.YH)o@n;R@UlkZWY
2>h.X#PPDij`^]-?.J^aYNkr6fSTiEV\p"fGt]<=YgGPO!0j^mmT/qF'9gnem0//ii=*WLop3o<_"X
_7LXus%V(LrLa/dRWg\g*j%2s.6n2s)i_[mO?#XaGG5V!)\%pSO*I'-W*-2;05;#.Wk=_s/]&#'0@o
4M:F^<L>*:T!XJ>WAP)sg)qjD$"Ob-MY[0iQ2+1_HnRU%S%b=]*u#,AhSOf:",GQq>R/PQkCg&:]*Q
qcBe\m)qn;@j4gohQRHrRut1O5BEe<pWNN[.;@qJRV%76&Q`cY\N&kr7;0),cjsfk@]qN&EkM_MN;`
]sI6J9_#72k$*@L@Zl?noO&1XIkBui4tKFMYhVP&qrNT"6_>]0PTR_GMZ$97VZ*q5+PFf13O'R%RO5
l#Oe%L5dket14PCUfPl'[Y9r;!5EKIP4WjJ-0k`5N:"GShl)'\jdQ?6\Nm,+r["hbata,ATqRgf3[o
B6V@Ke]7R]Yh:VN$rn8[#]AJe3<Dt\P'nnt'ViR*+ckLM]&YeT5U;bgHdDoaqQDP"DB".t,fiB)g.G
Hi:dlJ);X(Hl]<5Q^3H(l,uNV`L8JZ;=W8Ef;FSG/O*j(*oZ`FQo%R3Pqk@FXkZOa=1E8S[?uN3GRk
)$q;$GiM'@WlhI]iVK$Td2'-j'[%7r+9t(jh]V>DdAse3W@_n+WJ0Jb"p133$P5+[-g0Tf29a=bY>K
bI@8BP/FQg>i7G)8?Uic2F`LX6jlk%0MC1VLG3EgShHCmAnW@I)67@e^5:]c=QaD3Y!;/<6GT4Y5hh
hK'b28&Gc\0tL"G`0ZK6m$?!>,ns-JN9TjWDsbYPGcBka[ot1CM$#([T"Cin*mdHH8.H^p/t#9nI8K
68'[>a3fa@daC!O`9fMMl.38gCF"+"^nne*03QV#40qmppH'!dI"h`/7Op3muRP37l!&*g)UItd5Sq
=5uMJ4;gF1dDK.]^9T4TG^KT.L+E>qOS4+M#B5,"!VF1PTeZ'AtgsY@tRQ-(f_Opg,<lU?`qnXQP$u
n>Z5SoV9%Cb>AK@mQW:76\dE0A/gf:GadZWU7NCbRVGKSPg9bW6TtX#^'&NqlbB'`N[SVFGIgtWW#g
,BShf69!Rm_73^d%2EeXf%2VMp>0u`liCF\`C8^@LVPer!'#gRi_[_5Ol7l:-VCOOZ:3jFc&LR2=>a
0SMT[rI5)\R)+t)C\3*=93q8HuaAWSV_;kTdaN<3`M+D,aBV5M--c*e>Zn>IGHK@f-N:<.I#cg=]l/
mbDp/[0dMggFB?H3f,(hnIgiOS3dF5=Pk=Fec]*i;lfHaql,<fLRUEpI!+)b*p3KWpDYG)W_u'<T*n
E<&P3Gq*En_dq>%n4jamcVI&!6a3]=H*r[o8g$N\$,C)(1cSlhP:#(8eQE^li8CjiT:>h`DMM^7&/I
YJd0+BIt!ET&ULs3NJGXbS!rnclX5-#)&tSp5&kq)@MUeM>JK*Jgsmt;E3HiRr\#-U9W^,.C3;nQ7+
4(P+DrL7\pT"Oguj::4p&G\cqHHfp5W@]>ka?\HM_CT!%4@e-7d]TOLPN:8Do\2-Id%P#A3+0M'5=+
Ilq.)K+NEjpDjuIV,/hZYXLJ(AsmA*oc,QCGh>3:s0dlW0F$e<PSiVAr\EejJJE%a@4"9o*aFU`%<m
i-&kF&f$!GYP!0&i\Y"s'hbgGqXrc>'<EWT`(o1XmcGsmVF2+:H+'f9)>YRZ47]+COnYq@EFN7('^J
.dLe]7GjT@ac`qO5VbLd)#PVLEr8,W+W-)>>K@pV8-dP1Sn4B,KK+n\d0;RS9'0numWffi3AW!ok\p
G_kUVgI&5>`8mHZN/`/Wg4EBXS/dMEaeb)en%-$4(kD$1SMiPSiG,rki2EMq;GTb%SD\t&@@sun*&o
7Uh.`i6N0r<bbX1K/n#jImU,uqML[-poiiCn`-RCTrGR_q\aWP7Xao.eTmV(lT3_9<b\rV9=T%R4^P
ue)%4A&V+"pf:A<]KF;n]%U[.kWPTXZZR8Q6:HV2*UJra$<FO!<"`efaXf".DAl':%F8n.EQTQ/'Zt
^*X[B(K7W@ZcpnemM0,kkh+I0@l%>@(GlkZ?/kPeu;<*7W7mp:r+H)'D>GcY#$D*nUe#e?%$6HtPbS
"ls<C4`(Q&ZoO1mJF=SmQc`b<LD-HSqfIQ9`Y#AgcHm-W#'2Lm$r>F4IC7Q#IELX"_OOl&BuTmA#h#
)Ra0S=KXJ?Mh]*0_PX5oW&a;'2=KX;I_qPRNc??p3!slLF1-aH6IeG'_C7?206g."/Y?;^78j>.9V0
cIYZ:og&9UFpnqZ1Gk&bE$iEL,:Y;G(33gpD"<\_A-KCoUFn9(fPTTMOt!^\c5,$L=mGo[PCVVW69A
XrEtNY+_[!(QmJV3,14W[9t[WBl[<pk\G<!7?Gm@7,@<NkXeaqeYI;6EWg-47[s`3dih>,s4NY_mZ5
JV4+\IO[nF3WSd!]:ZAoO\KDBLesWCSmf`^p9m+@*k75p%3i(_]6<n6)-?/RX79kIq62oR@CJ,OuE(
f%#5Qd?oVakY]8c0$k/kQGsN1DW37PNF"js>YTN`$D)8a8H.[m;gB*b)M$"'Zp^$'j09MG#7dk,=.T
mM!>X"EX<%nK@W)\)5Y/Rtn6;pCBu<\3V+beIKr(_Y_@p2Cqq,7R$[Cm!?W=pGaU(bfD%?P5.5mc@7
E`YbH,=CQu8sa>;4qrrC1M5j2GFdeR/4k7$I_qZQMs<'doJ9(Sig?QNh:*B]NaZ/Goop1n$Rf,+GeW
3&teU%jM(KMh$T-fou`7dZ+ojL?(DPRP]h6g[[.(*NN8nJN3*l/'n0ZJM`bl>gC2V2Z^O0Qob'#2WN
QG$/@`hDe85Xu&u)88;\Y3WaX(l.`436."@\5:M#%%:%cCI9oLS5Vrk@`0,1X`u8R`5t7\#.iEEP_+
2uS!8S`%p]lL!=UDK(KgEOA=7k#jAC/>d0&]b3m8=Afj)$6a.n!@Up?95!oRt]uP,I+%[d&O7;\2E+
8LSOLp!TkX<9Zdc*LFBI0H1spVd2u3luaHM'OhT5\ZU4SNap0U0)c)Xi"[GDk;XZjf1?q6"1Ht3*(b
=GSE=NUaQkYk/#pouRr)c91-s;5FsBm\^/t?f
ASCII85End
End


static Function Moto_analyseMCdat([file])
	string file
	variable fileID

	if(paramisdefault(file))
		open/r/d fileID
		file = S_filename
	endif
	LoadWave/J/M/D/A=M_montecarlo/K=0/V={" "," $",0,0} file
	
	Moto_montecarlo_SLDcurves($(stringfromlist(0, S_wavenames)), 0.02, 2000)
end

static Function Moto_montecarlo_SLDcurves(M_montecarlo, SLDbin, SLDpts)
	Wave M_montecarlo
	variable SLDbin, SLDpts
	//calculates the envelope of SLDplots for a montecarlo reflectivity analysis.
	//M_montecarlo contains the fit coefficients for all the fit coefs, rows = montecarlo iteration, cols = coefs.
	variable nlayers, MCiters, ii, jj, minz = 0, maxz = 0, SLDmax, SLDmin
	
	//how many layers are there? 
	nlayers=M_montecarlo[0][0]
	
	//how many Monte Carlo iterations there were
	MCiters = dimsize(M_montecarlo, 0)
	
	//a wave to put a temporary SLD plot
	make/n=(SLDpts)/d/free anSLDplot
	make/free/n=(dimsize(M_montecarlo, 1)) tempcoefs
	
	for(ii = 0 ; ii < MCiters ; ii += 1)
		tempcoefs[] = M_montecarlo[ii][p]
		Moto_SLDplot(tempcoefs, anSLDplot)
		if(leftx(anSLDplot) < minz)
			minz = leftx(anSLDplot)
		endif
		if(pnt2x(anSLDplot, numpnts(anSLDplot)-1) > maxz)
			maxz = pnt2x(anSLDplot, numpnts(anSLDplot)-1)
		endif
	endfor
	
	//you have the minimum and maximum ends of all the fits, now create all the SLDprofiles.
	setscale/I x, minz, maxz, anSLDplot
	make/n=(MCiters, SLDpts)/d/free SLDmatrix = NaN
	for(ii = 0 ; ii < MCiters ; ii += 1)
		tempcoefs[] = M_montecarlo[ii][p]
		Moto_SLDplot(tempcoefs, anSLDplot)
		SLDmatrix[ii][] = anSLDplot[q]
	endfor
		
	//now we have a matrix that has uniform scaling and we need to bin it.
	imagestats/M=1 SLDmatrix
	SLDmax = V_max
	SLDmin = V_min

	make/n=( (SLDmax - SLDmin ) / SLDbin)/d/free SLDsliceHIST
	make/n=(MCiters)/d/free SLDslices
		
	setscale/I x,  SLDmin, SLDmax, SLDsliceHIST
	make/n=(SLDpts, numpnts(SLDsliceHIST))/o/d SLDimage
	setscale/I x, minz, maxz,  SLDimage	
	setscale/I y, SLDmin, SLDmax,  SLDimage
	
	for(ii = 0 ; ii < SLDpts ; ii+=1)
		SLDslices[] = SLDmatrix[p][ii]
		Histogram/B=2 SLDslices, SLDsliceHIST
		SLDimage[ii][] = SLDSliceHIST[q]
	endfor
	
	Display /W=(403,44,1188,866)/K=1 
	AppendImage/T SLDimage
	ModifyImage SLDimage ctab= {0.4,*,Rainbow,0}
	ModifyImage SLDimage minRGB=(0,0,0)
	ModifyGraph margin(left)=35,margin(bottom)=14,margin(top)=36,margin(right)=14,gfSize=14
	ModifyGraph wbRGB=(0,0,0),gbRGB=(0,0,0)
	ModifyGraph mirror=2
	ModifyGraph nticks(left)=10,nticks(top)=4
	ModifyGraph minor=1
	ModifyGraph fSize=14
	ModifyGraph standoff=0
	ModifyGraph axRGB=(65535,65535,65535)
	ModifyGraph tlblRGB=(65535,65535,65535)
	ModifyGraph alblRGB=(65535,65535,65535)
	ModifyGraph tkLblRot(left)=90
	ModifyGraph btLen=3
	ModifyGraph tlOffset=-2
	Label left "SLD"
	Label top "distance from interface"
	
End


static Function moto_transfer_data()
	//this function moves the data into the correct data directories from 
	//previous versions of motofit
	DFREF savDF = getdatafolderDFR()
	setdatafolder root:
	
	newdatafolder/o root:data
	
	SVAR/z mcs = root:packages:motofit:reflectivity:motofitcontrol
	variable ii, plotyp = 1, index = 0, red, green, blue, newplotyp
	
	if(SVAR_exists(mcs))
		plotyp = numberbykey("plotyp", mcs)
	endif
	Doalert 1, "Trying to transfer data from an old motofit version to version 4.  This will involve moving a lot of data files from root: to root:data. Make sure you have a backup of the experiment.\rDo you want to continue?"
	if(V_flag == 2)
		return 0
	endif
	
	string dataset, completedatasets, fittabledatasets
	string allWaves_R = wavelist("*_R", ";", "DIMS:1")
	string allWaves_q = wavelist("*_q", ";", "DIMS:1")
	string allWaves_E = wavelist("*_E", ";", "DIMS:1")
	string allWaves_dQ = wavelist("*_dq", ";", "DIMS:1")
				
	Dowindow/k reflectivitypanel
	Dowindow/k reflectivitygraph
	plotcalcref()
	Wave M_colors = root:packages:motofit:reflectivity:M_colors
	
	newplotyp = str2num(getmotofitoption("plotyp"))
	
	for(ii = 0 ; ii < itemsinlist(allwaves_R) ; ii += 1)
		setdatafolder root:
		dataset = removeending(stringfromlist(ii, allwaves_R), "_R")
		if(stringmatch("theoretical", dataset) || grepstring(dataset, "^fit_"))
			killwaves/z theoretical_R, theoretical_q, coef_cref, parameters_cref, resolution, sld, zed
			continue
		endif
		
		Wave/z RRold = $(dataset + "_R")
		Wave/z qqold = $(dataset + "_q")
		Wave/z eeold = $(dataset + "_E")
		Wave/z dqold = $(dataset + "_dq")
		Wave/z coefold = $("coef_" + dataset + "_R")
		
		if(waveexists(RRold) && waveexists(qqold) && numpnts(qqold) == numpnts(rrold))
			completedatasets += dataset + ";"
			newdatafolder/o/s $("root:data:" + dataset)
			make/n=(numpnts(RRold), 2)/o/d originaldata
			make/o/d/n = (numpnts(RRold)) $(dataset + "_R")/Wave=RR
			make/o/d/n = (numpnts(RRold)) $(dataset + "_q")/Wave=qq
			
			moto_plotyp_to_lindata(plotyp, qqold, RRold, dr = eeold)
			originaldata[][0] = qqold[p]
			originaldata[][1] = RRold[p]
			RR = RRold
			qq = qqold
			
			DFREF ndf = $("root:data:" + dataset)
			if(waveexists(eeold))
				make/o/d/n = (numpnts(RRold)) $(dataset + "_E")/Wave=ee
				ee = eeold
				redimension/n=(-1, 3) originaldata
				originaldata[][2] = eeold[p]
			endif 
			if(waveexists(dqold))
				make/o/d/n = (numpnts(RRold)) $(dataset + "_dq")/Wave=dq
				dq = dqold
				redimension/n=(-1, 4) originaldata
				originaldata[][3] = dqold[p]
			endif 
			if(waveexists(coefold))
				make/o/d/n=(dimsize(coefold, 0)) $("coef_" + dataset + "_R") /Wave=coef
				coef = coefold
				note/k coef
				note coef, note(coefold)
			endif 

			moto_lindata_to_plotyp(newplotyp, qq, RR, dr = ee, removeNonFinite = 1)
					
			index += 1
		endif
		waveclear ee, dq, rr, qq
		killwaves/z coefold, RRold, qqold, eeold, dqold
	endfor

	fittabledatasets = motofit#Moto_fittable_datasets()
	for(ii = 0 ; ii < itemsinlist(fittabledatasets); ii+=1)
		Waveclear qq, RR, ee
		dataset = stringfromlist(ii, fittabledatasets)
		if(stringmatch(dataset, "theoretical"))
			continue
		endif
		Wave RR = $("root:data:" + dataset + ":" + dataset + "_R")
		Wave qq = $("root:data:" + dataset + ":" + dataset + "_q")
		Wave/z ee = $("root:data:" + dataset + ":" + dataset + "_E")
		appendtograph/W=reflectivitygraph RR vs qq
		red = M_colors[mod(index * 37, dimsize(M_colors, 0))][0]
		green =  M_colors[mod(index * 37, dimsize(M_colors, 0))][1]
		blue = M_colors[mod(index * 37, dimsize(M_colors, 0))][2]
		if(waveexists(ee))
			Errorbars/W=reflectivitygraph $(nameofwave(RR)) Y, wave=(ee, ee)
		endif
		ModifyGraph/W=reflectivitygraph mode($(nameofwave(RR)))=3,rgb($(nameofwave(RR)))=(red,green, blue), marker=8
		index += 1
	endfor

	setdatafolder savDF
End

Function Moto_reversemodel(coefs)
	Wave coefs

	variable ii, isImag
	isImag = mod(numpnts(coefs) - 6, 4)
	duplicate/free/d coefs, coefs_copy
	
	switch(isImag)
		case 0:
			coefs[2] = coefs_copy[3]
			coefs[3] = coefs_copy[2]

			for(ii = 0 ; ii < coefs_copy[0] ; ii+=1)
				coefs[4 * ii + 6] = coefs_copy[4 * (coefs_copy[0] - ii - 1) + 6]
				coefs[4 * ii + 7] = coefs_copy[4 * (coefs_copy[0] - ii - 1) + 7]
				coefs[4 * ii + 8] = coefs_copy[4 * (coefs_copy[0] - ii - 1) + 8]
			endfor

			coefs[9] = coefs_copy[5]
			coefs[5] = coefs_copy[9]

			for(ii = 1; ii < coefs_copy[0] ; ii+=1)
				coefs[4  * ii + 9] = coefs_copy[ 4  * (coefs_copy[0] - ii ) + 9]
			endfor
			break
		default:
			coefs[2] = coefs_copy[4]
			coefs[3] = coefs_copy[5]
			coefs[4] = coefs_copy[2]
			coefs[5] = coefs_copy[3]

			for(ii = 0 ; ii < coefs_copy[0] ; ii+=1)
				coefs[4 * ii + 8] = coefs_copy[4 * (coefs_copy[0] - ii - 1) + 8]
				coefs[4 * ii + 9] = coefs_copy[4 * (coefs_copy[0] - ii - 1) + 9]
				coefs[4 * ii + 10] = coefs_copy[4 * (coefs_copy[0] - ii - 1) + 10]
			endfor

			coefs[11] = coefs_copy[7]
			coefs[7] = coefs_copy[11]

			for(ii = 1; ii < coefs_copy[0] ; ii+=1)
				coefs[4  * ii + 11] = coefs_copy[ 4  * (coefs_copy[0] - ii ) + 11]
			endfor
			break
	endswitch

End
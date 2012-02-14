#pragma rtGlobals=3		// Use modern global access method.
#pragma ModuleName = Motofit_GR
#pragma Igormode=6.22

#include <WaveSelectorWidget>

static Function buildpanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1 /W=(649,44,1205,700) as "Global Reflectometry Analysis"
	Dowindow/C globalreflectometrypanel
	TabControl globalpaneltab,pos={5,7},size={544,573},proc=Motofit_GR#globalpanel_GUI_tab
	TabControl globalpaneltab,tabLabel(0)="Datasets",tabLabel(1)="Coefficients"
	TabControl globalpaneltab,value= 0
	Button adddataset_tab0,pos={20,35},size={72,31},proc=Motofit_GR#globalpanel_GUI_button,title="Add\rdataset"
	Button adddataset_tab0,fSize=11
	Button removedataset_tab0,pos={97,35},size={72,31},proc=Motofit_GR#globalpanel_GUI_button,title="Remove\rdataset"
	Button removedataset_tab0,fSize=11
	Button changelayers_tab0,pos={174,35},size={72,31},proc=Motofit_GR#globalpanel_GUI_button,title="change\rlayers"
	Button changelayers_tab0,fSize=11
	
	Button linkparameter_tab0,pos={326,37},size={100,30},disable=1,proc=Motofit_GR#globalpanel_GUI_button,title="link selection"
	Button linkparameter_tab0,fSize=11
	Button unlinkparameter_tab0,pos={434,37},size={100,30},disable=1,proc=Motofit_GR#globalpanel_GUI_button,title="unlink selection"
	Button unlinkparameter_tab0,fSize=11
	ListBox datasetparams_tab0,pos={17,72},size={526,499},disable=1,proc=Motofit_GR#globalpanel_GUI_listbox
	ListBox datasetparams_tab0,listWave=root:Packages:motofit:reflectivity:globalfitting:datasets_listwave
	ListBox datasetparams_tab0,selWave=root:Packages:motofit:reflectivity:globalfitting:datasets_selwave, fsize = 12
	ListBox datasetparams_tab0,mode= 10,colorwave = root:Packages:motofit:reflectivity:globalfitting:M_colors
	listbox datasetparams_tab0 win=globalreflectometrypanel, widths = {160}, userColumnResize=1, frame=3
	ListBox coefficients_tab1,pos={17,72},size={526,499},proc=Motofit_GR#globalpanel_GUI_listbox
	ListBox coefficients_tab1,listWave=root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	ListBox coefficients_tab1,selWave=root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	ListBox coefficients_tab1,clickEventModifiers= 4, fsize = 11,mode=6, widths={60}, usercolumnresize=1
	Button do_global_fit,pos={184,600},size={80,40},proc=Motofit_GR#globalpanel_GUI_button,title="Fit"
	Button do_global_fit,fSize=12
	Button simulate,pos={276,600},size={80,40},proc=Motofit_GR#globalpanel_GUI_button,title="Simulate"
	Button simulate,fSize=12
	Button savesetup_tab0,pos={451,600},size={70,20},title="Save setup",fSize=10, proc = Motofit_GR#globalpanel_GUI_button
	Button loadsetup_tab0,pos={451,622},size={70,20},title="Load setup",fSize=10, proc= Motofit_GR#globalpanel_GUI_button
	Slider slider0_tab1,pos={22,589},size={517,16}, proc = Motofit_GR#globalpanel_GUI_slider
	Slider slider0_tab1,limits={0,2,0},value= 0,vert= 0,ticks= 0
	ValDisplay Chi2_tab1,pos={223,42},size={100,25},title="\\F'Symbol'c\\M\\S2",fSize=12
	ValDisplay Chi2_tab1,limits={0,0,0},barmisc={0,1000},value= _NUM:0
	
	String controlsInATab= ControlNameList("globalreflectometrypanel", ";", "*_tab*")
	String curTabMatch= "*_tab"+num2istr(0)
	String controlsInCurTab= ListMatch(controlsInATab, curTabMatch)
	String controlsInOtherTabs= ListMatch(controlsInATab, "!"+curTabMatch)

	ModifyControlList controlsInOtherTabs disable=1	// hide
	ModifyControlList controlsInCurTab disable=0		// show
End

static Function/t CoefficientWaveSelector(whichdataset, xx, yy, numcoefs)
	variable whichdataset, xx, yy, numcoefs
	String panelName = "Selectyourwave"
	string listoptions = ""

	string/g root:packages:motofit:reflectivity:globalfitting:tempstr = ""
	SVAR tempstr = root:packages:motofit:reflectivity:globalfitting:tempstr
	Wave/t datasets = root:packages:motofit:reflectivity:globalfitting:datasets
	string retStr = tempstr
	
	// doesn't exist, make it
	NewPanel/K=1/N=$panelName/W=(xx, yy,xx + 300,yy + 290) as "Select your coefficientwave"
	Button ok,pos={20,261},size={69,21},title="Continue", proc = Motofit_GR#Coefficientwaveselector_BUTTON
	Button cancel,pos={98,261},size={56,22},title="Cancel", proc = Motofit_GR#Coefficientwaveselector_BUTTON

	// list box control doesn't have any attributes set on it
	ListBox coefficientWaveSelectorList,pos={9,13},size={273,241}
	// This static Function does all the work of making the listbox control into a
	// Wave Selector widget. Note the optional parameter that says what type of objects to
	// display in the list. 
	sprintf listoptions, "DIMS:1,MAXROWS:%d,MINROWS:%d", numcoefs, numcoefs
	MakeListIntoWaveSelector(panelName, "coefficientWaveSelectorList", content = WMWS_Waves, selectionmode = WMWS_SelectionSingle, listoptions=listoptions)
	WS_OpenAFolderFully(panelname, "coefficientWaveSelectorList", "root:data:" + datasets[whichdataset])
	// This is an extra bonus- you can create your own static Function to be notified of certain events,
	// such as a change in the selection in the list.
	WS_SetNotificationProc(panelName, "coefficientWaveSelectorList", "Motofit_GR#selectedCoefWave_notification", isExtendedProc=1)

	Pauseforuser $panelname
	retstr = tempstr
	killstrings  root:packages:motofit:reflectivity:globalfitting:tempstr
	return retstr
End

static Function Coefficientwaveselector_BUTTON(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR/z tempstr = root:packages:motofit:reflectivity:globalfitting:tempstr

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlname)
				case "OK":
					break
				case "Cancel":
					tempStr = ""
					break
			endswitch
			WS_FindAndKillWaveSelector(ba.win, "coefficientWaveSelectorList")
			dowindow/k $(ba.win)
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

static Function selectedCoefWave_notification(SelectedItem, EventCode, WindowName, listboxName)
	String SelectedItem
	Variable EventCode
	String WindowName
	String listboxName
	
	SVAR tempstr =root:packages:motofit:reflectivity:globalfitting:tempstr
	tempstr = selectedItem
end

static Function init_fitting([restart, isImagOrSolvent])
	variable restart, isImagOrSolvent
	variable haveRefPanel = itemsinlist(winlist("reflectivitypanel", "", ""))
	variable haveRefGraph = itemsinlist(winlist("reflectivitygraph", "", ""))
	variable haveSLDgraph =  itemsinlist(winlist("SLDgraph", "", ""))
	
	if(haveRefPanel + haveRefGraph + haveSLDgraph !=3)
		Doalert 0, "You need to have the reflectivity panel, reflectivity graph and SLD graph opened, try starting motofit again"
		abort
	endif
	if(restart)
		Dowindow/k globalreflectometrypanel
	endif
	if(itemsinlist(winlist("globalreflectometrypanel", ";", "")))
		Doalert 0, "global reflectivity panel already exists"
		return 0
	endif
	if(!paramisdefault(isImagOrSolvent))
		make_folders_waves(isImagOrSolvent = isImagOrSolvent)
	else
		make_folders_waves()
	endif
	
	buildpanel()
End

static Function make_folders_waves([isImagOrSolvent])
	variable isImagOrSolvent
	dfref savDF = getdatafolderDFR()
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o/s root:packages:motofit:reflectivity:globalfitting	
	
	//this variable is 0 if solvent penetration or 1 if imaginary (can't have mixed).
	variable/g isImag = 0
	if(!paramisdefault(isImagOrSolvent))
		isimag = isImagOrSolvent
	else
		variable temp
		prompt temp, "Did you want to have model with solvent penetrations or complex SLDS?", popup, "solventpenetration;imaginarySLD"
		Doprompt/Help="You can either model with solvent penetrations, or complex SLD's for a given layer" "", temp
		if(V_Flag)
			abort
		endif
		isImag = temp - 1
	endif
	make/n=0/I/u/o numcoefs
	make/n=(0,0)/I/o linkages
	make/n=(0,1)/I/u/o coefficients_selwave
	make/n=(0,1)/I/u/o coefficients_selwave
	make/n=(0,1)/T/o coefficients_listwave
	make/n=(0,1)/t/o datasets_listwave
	make/n=(0,1, 3)/b/u/o datasets_selwave
	SetDimLabel 2,1,backColors,datasets_selwave				// define plane 1 as background colors
	SetDimLabel 2,2,foreColors,datasets_selwave

	make/n=0/T/o datasets
	ColorTab2wave rainbow
	setdatafolder savDF
End

static Function globalpanel_GUI_listbox(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	string thewave = ""
	variable ii, thedataset, chi2 = NaN
	thedataset = 0.5*(col-1)
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			if(lba.eventmod & 2^4)
				Getwindow/z globalreflectometrypanel wsize
				thewave = CoefficientWaveSelector(thedataset, lba.mouseloc.h + V_left, lba.mouseloc.v + V_top,numcoefs[thedataset])
				Wave/z coefs = $theWave
				if(waveexists(coefs))
					for(ii = 0 ; ii < numcoefs[theDataset] ; ii+=1)
						set_param(coefs[ii], ii, theDataset, lba.listwave)
					endfor
				endif
			endif
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			strswitch(lba.ctrlname)
				case "coefficients_tab1":
					if(numtype(str2num(lba.listwave[row][col])))
						Doalert 0, "Please enter a number"
						lba.listwave[row][col] = ""
						return 0
					endif
					set_param(str2num(lba.listwave[row][col]), row, thedataset, lba.listwave)
					chi2 = evaluateGlobalFunction(fitcursors = str2num(motofit#getmotofitoption("fitcursors")))
					slider slider0_tab1, win=globalreflectometrypanel, userdata(whichparam) = "row-"+num2istr(row)+";col-"+num2istr(col)
					valdisplay chi2_tab1, win=globalreflectometrypanel, value=_NUM:chi2
					break
			endswitch
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

static Function set_param(val,row, whichdataset, listwave)
	variable val
	variable row, whichdataset
	Wave/t listwave
	//sets values in the listboxes, and propagates changes based on the linkage matrix	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	wave uniqueparameter = isuniqueparam(following=1)
	variable otherrow, othercol
	listwave[row][2 * whichdataset + 1] = num2str(val)
	
	if(uniqueparameter[row][whichdataset] == 2)
		findvalue/i=(linkages[row][whichdataset])/S=(row + (dimsize(linkages, 0) * whichdataset) + 1)/z linkages
		for(;V_Value != -1; )
			othercol=floor(V_value/dimsize(linkages, 0))
			otherrow=V_value - othercol * dimsize(linkages, 0)
			listwave[otherrow][2 * othercol + 1] = num2str(val)
			findvalue/i=(linkages[row][whichdataset])/S=(V_Value + 1)/z linkages
		endfor
	endif
End

static Function globalpanel_GUI_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	Wave/t datasets_listwave = root:Packages:motofit:reflectivity:globalfitting:datasets_listwave
	Wave datasets_selwave = root:Packages:motofit:reflectivity:globalfitting:datasets_selwave
	Wave/t coefficients_listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	Wave coefficients_selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave M_colors = root:Packages:motofit:reflectivity:globalfitting:M_colors
	NVAR isImag = root:Packages:motofit:reflectivity:globalfitting:isImag

	string listofdatasets = "", dataset, temp = "", temp2 = "", info
	variable ii, numitems, numdatasets, numparams, maxparams=0, whichitem, numlayers, numlinkages, row, col, loQ, hiQ, chi2
	
	numdatasets = dimsize(datasets, 0)

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlname)
				case "adddataset_tab0":
					listofdatasets = motofit#Moto_fittable_datasets()
					numitems = itemsinlist(listofdatasets)
					for(ii = 0 ; ii <  numitems ; ii+=1)
						findvalue/TEXT=stringfromlist(ii, listofdatasets)/TXOP=6 datasets
						if(V_Value == -1)
							temp += stringfromlist(ii, listofdatasets) + ";"
						endif
					endfor
					listofdatasets = temp
					numlayers = 1
					prompt dataset, "which dataset", popup, listofdatasets
					prompt numlayers, "how many layers?"
					Doprompt "Dataset selection", dataset, numlayers
					if(V_flag || add_a_dataset(dataset, numlayers))
						return 0
					endif
					break
				case "changelayers_tab0":
					numitems = dimsize(datasets, 0)
					for(ii = 0 ; ii <  numitems ; ii+=1)
						listofdatasets += datasets[ii] + ";"
					endfor
					numlayers = 1
					prompt dataset, "dataset", popup, listofdatasets
					prompt numlayers, "how many layers?"
					Doprompt "Which dataset did you want to change the number of layers?", dataset, numlayers
					if(V_flag || numlayers < 0)
						return 0
					endif
					change_layers_for_dataset(dataset, numlayers)
					break
				case "removedataset_tab0":
					sockitwavetostring/TXT=";" datasets, listofdatasets
					prompt dataset, "which dataset", popup, listofdatasets
					Doprompt "Please select the dataset to remove", dataset
					if(V_Flag || stringmatch(dataset, "_none_"))
						return 0
					endif
					whichitem = whichlistitem(dataset, listofdatasets)
					remove_dataset_from_linkage(whichitem)
					deletepoints/m=1 whichitem + 1, 1, datasets_listwave, datasets_selwave
					deletepoints/m=1 2 * whichitem + 1, 2, coefficients_selwave, coefficients_listwave
					deletepoints/m=0 whichitem, 1, datasets
					maxparams = wavemax(numcoefs)
					if(!numtype(maxparams))
						redimension/n=(maxparams, -1, -1) datasets_listwave, datasets_selwave, coefficients_selwave, coefficients_listwave
					endif
					regenerateLinkageListBoxes()
					break
			endswitch
			if(!numdatasets)
				return 0
			endif

			strswitch(ba.ctrlname)
				case "linkparameter_tab0":
					temp = which_cells_sel(datasets_selwave)
					linkParameterList(temp)
					regenerateLinkageListBoxes()
					break
				case "unlinkparameter_tab0":
					temp = which_cells_sel(datasets_selwave)
					unlinkParameterList(temp)
					regenerateLinkageListBoxes()
					break
				case "simulate":
					Dowindow/F SLDgraph
					Dowindow/F reflectivitygraph
					chi2 = plotCombinedFitAndEvaluate(fitcursors = str2num(motofit#getmotofitoption("fitcursors")), usedqwave = str2num(motofit#getmotofitoption("usedqwave")))
					ValDisplay Chi2_tab1,value= _NUM:chi2,win=globalreflectometrypanel

					break
				case "do_global_fit":
					Do_a_global_fit()
					break	
				case "savesetup_tab0":
					setup_motoMPI()
					break			
				case "loadsetup_tab0":
					ingest_motoMPI_input()
					break			
			endswitch
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

static function add_a_dataset(datasetname, numlayers)
	//adds a dataset globalfit setup.
	string datasetname
	variable numlayers

	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t coefficients_listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	Wave coefficients_selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	Wave/t datasets_listwave = root:Packages:motofit:reflectivity:globalfitting:datasets_listwave
	Wave datasets_selwave = root:Packages:motofit:reflectivity:globalfitting:datasets_selwave

	NVAR isImag = root:Packages:motofit:reflectivity:globalfitting:isImag

	string listofdatasets = ""
	variable numparams = 0, maxparams, numdatasets, ii, maxlayers
	
	listofdatasets = motofit#Moto_fittable_datasets()
	
	if(whichlistitem(datasetname, listofdatasets) == -1)
		Doalert 0, Datasetname + " is not one of the loaded datasets"
		return 1
	endif
	
	if(stringmatch(datasetname, "_none_") || numlayers < 0)
		return 1
	endif
		
	findvalue/TEXT=datasetname/TXOP=6 datasets
	if(V_Value > -1)
		Doalert 0, "dataset already in use"
		return 1
	endif		

	//add in the new dataset
	if(!isImag)
		numparams = 4 * numlayers + 6
	else
		numparams = 4 * numlayers + 8
	endif				
	numdatasets = dimsize(datasets, 0)
	maxparams = wavemax(numcoefs)
	if(numparams > maxparams || numtype(maxparams))
		maxparams = numparams
	else
//		numparams = maxparams
	endif
		
	redimension/n=(maxparams, 2 * (numdatasets + 1) + 1) coefficients_selwave, coefficients_listwave
	coefficients_selwave[][dimsize(coefficients_selwave, 1) - 1] = 32
	coefficients_selwave[][dimsize(coefficients_selwave, 1) - 2] = 2
	redimension/n=(maxparams, numdatasets + 2, 3) datasets_listwave, datasets_selwave
	redimension/n=(numdatasets + 1) datasets
	setdimlabel 1, 0, param_description, datasets_listwave
	setdimlabel 1, numpnts(datasets), $datasetname, datasets_listwave
	SetDimLabel 2,1,backColors,datasets_selwave				// define plane 1 as background colors
	SetDimLabel 2,2,foreColors,datasets_selwave
	
	datasets[numpnts(datasets) - 1] = datasetname
	add_dataset_to_linkage(numparams)
	
	for(ii = 0 ; ii < numpnts(datasets) ; ii+=1)
		setdimlabel 1, 2 * ii+1, $(datasets[ii]), coefficients_listwave
	endfor
	regenerateLinkageListBoxes()
	
	if(!isimag)
		maxlayers = (dimsize(coefficients_listwave, 0) - 6) / 4
	else
		maxlayers = (dimsize(coefficients_listwave, 0) - 8) / 4
	endif
	
	Wave/t pardes =  moto_paramdescription(maxlayers, isImag)
	datasets_listwave[][0] = pardes[p]
	coefficients_listwave[][0] = pardes[p]
End

Function change_layers_for_dataset(datasetname, numlayers)
	//changes the number of layers for a particular dataset.
	string datasetname
	variable numlayers
	
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t coefficients_listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	Wave coefficients_selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	Wave/t datasets_listwave = root:Packages:motofit:reflectivity:globalfitting:datasets_listwave
	Wave datasets_selwave = root:Packages:motofit:reflectivity:globalfitting:datasets_selwave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages

	NVAR isImag = root:Packages:motofit:reflectivity:globalfitting:isImag

	string listofdatasets = "", unlinklist = ""
	variable numparams = 0, maxparams, numdatasets, ii, datasetnumber, maxlayers
	
	findvalue/TEXT=datasetname/TXOP=6 datasets
	if(V_Value == -1)
		//dataset is not part of setup.
		return 0
	endif	
	datasetnumber = V_Value
	
	//calculate the number of params required.
	if(!isImag)
		numparams = 4 * numlayers + 6
	else
		numparams = 4 * numlayers + 8
	endif
	
	//change the linkage matrix
	change_numparameters_in_linkage(datasetnumber, numparams)
	
	//may need to reduce the number of parameters.
	redimension/n=(dimsize(linkages, 0), -1) coefficients_listwave, coefficients_selwave
	redimension/n=(dimsize(linkages, 0), -1, -1) datasets_selwave, datasets_listwave
	
	regenerateLinkageListBoxes()
	
	//setup the parameter descriptions.
	maxparams = wavemax(numcoefs)
	if(mod(maxparams - 6, 4))
		maxlayers = (maxparams - 8) / 4
	else
		maxlayers = (maxparams - 6) / 4
	endif
	
	Wave/t pardes =  moto_paramdescription(maxlayers, isImag)
	datasets_listwave[][0] = pardes[p]
	coefficients_listwave[][0] = pardes[p]
End

static Function globalpanel_GUI_slider(sa) : SliderControl
	STRUCT WMSliderAction &sa
	
	string userdata = getuserdata("globalreflectometrypanel", "slider0_tab1", "whichparam")
	if(!strlen(userdata))
		return 0
	endif
	variable row = numberbykey("row", userdata, "-")
	variable col = numberbykey("col", userdata, "-")
	variable theDataset = (col - 1)/2
	variable Chi2 = NaN
	Wave/t listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	
	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set			
				Variable curval = sa.curval
			endif
			if(sa.eventcode & 2^1)
				slider slider0_tab1, limits = {0.5 * str2num(listwave[row][col]), 1.5 * str2num(listwave[row][col]), str2num(listwave[row][col])/500}, value=str2num(listwave[row][col])
			endif
			if(sa.eventcode & 2^3)
				listwave[row][col] = num2str(sa.curval)
				set_param(sa.curval, row, thedataset, listwave)
				chi2 = evaluateGlobalFunction(fitcursors = str2num(motofit#getmotofitoption("fitcursors")))
				ValDisplay Chi2_tab1,value= _NUM:chi2,win=globalreflectometrypanel
			endif
			if(sa.eventcode & 2^2)
				slider slider0_tab1, value = 0, limits = {-1, 1, 0.2}
			endif
			break
	endswitch

	return 0
End


static Function/s which_cells_sel(selwave)
	Wave selwave
	
	string retstr = ""
	variable col, row, rowsInWave
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	
	rowsInWave = dimsize(selwave, 0)
	
	duplicate/free selwave, maskwave
	redimension/n=(-1, -1, 0) maskwave
	maskwave = selwave & 2^0
	maskwave += selwave & 2^3
	maskwave = maskwave > 0 ? 1: 0
	
	findvalue/I=1/S=0 maskwave
	for(;V_Value > - 1;)
		col=floor(V_value/rowsInWave)
		row=V_value-col*rowsInWave
		if(col > 0 && row < numcoefs[col - 1])
			retStr += num2istr(col - 1) + ":" + num2istr(row) + ";"
		endif	
		findvalue/z/I=1/S=(V_Value + 1) maskwave
	endfor
	return retstr
End

static Function globalpanel_GUI_tab(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			String controlsInATab= ControlNameList("", ";", "*_tab*")

			String curTabMatch= "*_tab"+num2istr(tab)
			String controlsInCurTab= ListMatch(controlsInATab, curTabMatch)
			String controlsInOtherTabs= ListMatch(controlsInATab, "!"+curTabMatch)

			ModifyControlList controlsInOtherTabs disable=1	// hide
			ModifyControlList controlsInCurTab disable=0		// show
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

static Function/wave isUniqueParam([following, linkagematrix])
	variable following
	Wave/z linkagematrix
	//creates a mask wave the same size as the linkage matrix to tell if a parameter is unique or not.
	//mask = 0 if a parameter is NOT unique
	//mask = -1 if no parameter exists for that dataset/coef combo
	//mask = 1 if a parameter is unique (it does not link to a parameter PRECEDING IT)
	//IFF following = 1
	//then mask = 2 if a FOLLOWING parameter links to it
	
	if(paramisdefault(linkagematrix))
		Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	else
		Wave linkages = linkagematrix	
	endif
	variable ii, jj
	
	if(paramisdefault(following))
		following = 0
	endif
	duplicate/free linkages, isUniqueMask

	for(ii = dimsize(linkages, 1) - 1 ; ii >= 0 ; ii-= 1)
		for(jj = dimsize(linkages, 0) - 1 ; jj >= 0  ; jj -= 1)
			findvalue/i=(linkages[jj][ii])/S=0  linkages 
			if(V_Value < ii * dimsize(linkages, 0) + jj)
				isUniqueMask[jj][ii] = 0
			else
				isUniqueMask[jj][ii] = 1
			endif
		endfor
	endfor
	isUniqueMask = (linkages[p][q] == -1) ? -1 : isUniqueMask[p][q]
	
	if(following)
		for(ii = 0 ; ii < dimsize(linkages, 1) ; ii+= 1)
			for(jj = 0 ; jj < dimsize(linkages, 0)  ; jj += 1)
				if(isUniqueMask[jj][ii] == 1 && (ii * dimsize(linkages, 0) + jj) + 1 < numpnts(linkages))
					findvalue/i=(linkages[jj][ii])/S=(ii * dimsize(linkages, 0) + jj + 1)  linkages 
					if(V_Value > -1)
						isUniqueMask[jj][ii] = 2
					endif
				endif
			endfor
		endfor	
	endif
	
	return isUniquemask
End

static Function assertLinkageCorrupted()
	//returns the truth that the linkage matrix is corrupted.
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	variable ii, jj, uniqueparam = -1
	
	for(ii = 0 ; ii < dimsize(linkages, 1)  ; ii+= 1)
		for(jj =  0; jj <  dimsize(linkages, 0)   ; jj += 1)
			if(linkages[jj][ii] > uniqueparam+1)
				return 1
			endif
			if(linkages[jj][ii] < -1)
				return 1
			endif
			if(linkages[jj][ii] == uniqueparam + 1)
				uniqueparam += 1
			endif
		endfor
	endfor
	return 0
End

static Function/wave generateAUniqueParameterMask()
	//generates a mask containing the unique parameter numbers, if all datasets were totally unlinked
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	variable ii, jj, uniqueparameternumber
	
	duplicate/free linkages, uniqueParameterMask
	uniqueParameterMask = -1
	for(ii = 0 ; ii < numpnts(numcoefs) ; ii += 1)
		for(jj = 0 ; jj < numcoefs[ii] ; jj+=1)
			uniqueParameterMask[jj][ii] = uniqueparameternumber 
			uniqueParameterNumber += 1
		endfor
	endfor
	return uniqueParameterMask
End

static Function lastUniqueParameter(row, col)
	variable row, col
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	variable jj, kk, startP
	
	Wave isunique = isUniqueParam()
	//it's not unique, find the last unique parameter number
	for(jj = col ; jj >=0 ; jj -=1)
		if(jj == col)
			startP = row
		else
			startP = dimsize(linkages, 0) - 1
		endif
		for(kk = startP ; kk >= 0 ; kk -=1)
			if(isunique[kk][jj] == 1)
				return linkages[kk][jj]
			endif
		endfor
	endfor
	return 0		
end

static Function unlinkParameterList(listofParameters[, removeFollowing])
	//this unlinks nonunique (parameters linking to preceding) parameters in the linkage matrices.
	//if removefollowing is specified != 0 then ALL following parameters that link to a specified parameter are also removed.
	//if removefollowing == 0 then following parameters are not unlinked.
	//the default is removefollowing = 1
	
	string listofparameters  //like "0:6;0:7"   (i.e. dataset:parameter pairs)
	variable removefollowing
	
	if(paramisdefault(removefollowing))
		removefollowing = 1
	endif
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	variable ii, jj, kk, lastuniqueparam, startp, col, row, endp
	string pair, recursive = ""
	
	if(assertLinkageCorrupted())
		abort "Linkage matrix corrupted"
	endif
	
	make/i/free/n=(itemsinlist(listofparameters)) whichdataset, whichparameter
	whichdataset = -1
	whichparameter = -1
	
	//need to sort the list
	listofparameters = uniquelist(sortlist(listofparameters, ";", 16))
	if(!itemsinlist(listofparameters))
		return 0
	endif	
	for(ii = 0 ; ii < itemsinlist(listofParameters) ; ii+=1)
		pair = stringfromlist(ii, listofparameters)
		whichdataset[ii] = str2num(stringfromlist(0, pair, ":"))
		whichparameter[ii]  =  str2num(stringfromlist(1, pair, ":"))
	endfor

	
	for(ii = 0 ; ii < numpnts(whichdataset) ; ii+=1)
		Wave isunique = isUniqueParam(following = removefollowing)
		if(isunique[whichparameter[ii]][whichdataset[ii]] == 0)
			lastuniqueparam = lastUniqueParameter(whichparameter[ii], whichdataset[ii])
			//now reset all the  numbers that follow		
			startP = whichparameter[ii] + whichdataset[ii] * dimsize(linkages, 0)
			linkages = p + q * dimsize(linkages, 0) > startP && (isunique[p][q]==1 || linkages[p][q] > lastuniqueparam) ? linkages[p][q] + 1 : linkages[p][q]

			linkages[whichparameter[ii]][whichdataset[ii]] = lastuniqueparam + 1
			lastuniqueparam += 1 				
		elseif(removefollowing && isunique[whichparameter[ii]][whichdataset[ii]] == 2)
			findvalue/I=(linkages[whichparameter[ii]][whichdataset[ii]])/S=(whichdataset[ii] * dimsize(linkages, 0) + whichparameter[ii] + 1) linkages
			for( ; V_Value > -1; )		
				col=floor(V_value/dimsize(linkages, 0))
				row=V_value-col * (dimsize(linkages, 0))
				recursive +=  num2istr(col) + ":" + num2istr(row) + ";"
				findvalue/z/I=(linkages[whichparameter[ii]][whichdataset[ii]])/S=(V_Value + 1) linkages
			endfor
			unlinkParameterList(recursive)
		endif
	endfor
End

static Function/s uniqueList(listStr)
	string listStr
	string retStr = ""
	variable ii
	for(ii = 0; ii < itemsinlist(listStr) ; ii+=1)
		if(whichlistitem(stringfromlist(ii, listStr), retStr) < 0)
			retStr += stringfromlist(ii, listStr) + ";"
		endif
	endfor
	return retStr
End

static Function linkParameterList(listofParameters)
	//this links nonunique parameters in the linkage matrices.
	string listofparameters  //like "0:6;0:7"   (i.e. dataset:parameter pairs)
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	variable ii, jj, kk, lastuniqueparam, startp, col, row, endp
	string pair
	
	if(assertLinkageCorrupted())
		abort "Linkage matrix corrupted"
	endif

	make/i/free/n=(itemsinlist(listofparameters)) whichdataset, whichparameter
	whichdataset = -1
	whichparameter = -1
	
	//need to sort the list
	listofparameters = uniquelist(sortlist(listofparameters, ";", 16))
	if(!itemsinlist(listofparameters))
		return 0
	endif
	
	for(ii = 0 ; ii < itemsinlist(listofParameters) ; ii+=1)
		pair = stringfromlist(ii, listofparameters)
		whichdataset[ii] = str2num(stringfromlist(0, pair, ":"))
		whichparameter[ii]  =  str2num(stringfromlist(1, pair, ":"))
	endfor
	
	//if they are already linked you need to unlink them
	for(ii = 0 ; ii < numpnts(whichdataset) ; ii+=1)
		Wave isunique = isUniqueParam(following = 1)
		if(isunique[whichparameter[ii]][whichdataset[ii]] == 0 || (isunique[whichparameter[ii]][whichdataset[ii]] == 2 && ii != 0))
			unlinkparameterlist(num2istr(whichdataset[ii]) + ":" + num2istr(whichparameter[ii]))
		endif
	endfor
	
	//now link them all up
	//the first item will be the master, subsequent values will link to that.
	//how to renumber the linkage matrix?
	for(ii = numpnts(whichdataset) - 1 ; ii > 0 ; ii -= 1)
		Wave isunique = isuniqueparam()
		variable origvalue = linkages[whichparameter[ii]][whichdataset[ii]]
		
		if(linkages[whichparameter[ii]][whichdataset[ii]] > -1)
			linkages[whichparameter[ii]][whichdataset[ii]] = linkages[whichparameter[0]][whichdataset[0]]
		else
			continue
		endif
		//have to reset all the  numbers that follow, but only if it's unique
		if(isunique[whichparameter[ii]][whichdataset[ii]])
			startP = whichparameter[ii] + whichdataset[ii] * dimsize(linkages, 0)
			linkages = p + q * dimsize(linkages, 0) > startP && (isunique[p][q]==1 || linkages[p][q] > origvalue) ? linkages[p][q] - 1 : linkages[p][q]
			
	//		linkages = p + q * dimsize(linkages, 0) > startP && (isunique[p][q]==1 || (linkages[p][q] > linkages[whichparameter[ii]][whichdataset[ii]])) ? linkages[p][q] - 1 : linkages[p][q]
		endif
	endfor
End

static Function regenerateLinkageListBoxes()
	//puts the text into the datasets and coefficients listwave boxes.
	Wave/t datasets_listwave = root:Packages:motofit:reflectivity:globalfitting:datasets_listwave
	Wave datasets_selwave = root:Packages:motofit:reflectivity:globalfitting:datasets_selwave
	Wave/t coefficients_listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	Wave coefficients_selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave M_colors = root:Packages:motofit:reflectivity:globalfitting:M_colors

	Wave uniqueparam = isUniqueParam()
	variable ii, jj, col, row, uniquelinkages
	string uniquelinkage = ""
	
	datasets_selwave[][][1] = 0
	
	for(ii = 0 ; ii < dimsize(linkages, 1) ; ii += 1)
		for(jj = 0 ; jj <dimsize(linkages, 0) ; jj+=1)
			if(uniqueparam[jj][ii] > 0)
				datasets_listwave[jj][ii + 1] =   datasets[ii] + ":K" + num2istr(jj)
				coefficients_selwave[jj][2 * ii + 1] = 2
				coefficients_selwave[jj][2 * ii + 2] = 32
			elseif(uniqueparam[jj][ii] == 0)
				findvalue/i=(linkages[jj][ii])/S=0/z linkages
				if(V_Value > -1)
					col=floor(V_value/dimsize(linkages, 0))
					row=V_value-col*dimsize(linkages, 0)
					//deal with colouring of linkages
					if(whichlistitem(num2istr(col) + ":" + num2istr(row), uniquelinkage) < 0)
						uniquelinkage += num2istr(col) + ":" + num2istr(row) + ";"
						uniquelinkages += 1
						datasets_selwave[row][col + 1][1] = mod(uniquelinkages * 37, dimsize(M_colors, 0))
						datasets_selwave[jj][ii + 1][1] = mod(uniquelinkages * 37, dimsize(M_colors, 0))
					else
						datasets_selwave[jj][ii + 1][1] = datasets_selwave[row][col + 1][1]					
					endif
					
					datasets_listwave[jj][ii + 1] = 	"LINK:" + datasets[col] + ":K" + num2istr(row)
					coefficients_selwave[jj][2 * ii + 1] = 0
					coefficients_selwave[jj][2 * ii + 2] = 0
					coefficients_listwave[jj][2 * ii + 1] = coefficients_listwave[row][col * 2 + 1]
				endif
			else
				datasets_listwave[jj][ii + 1] = ""
				coefficients_selwave[jj][2 * ii + 1] = 0
				coefficients_listwave[jj][2 * ii + 1] = ""
				coefficients_selwave[jj][2 * ii + 2] = 0
			endif
		endfor
	endfor
End

static Function add_dataset_to_linkage(numcoefsfordataset)
	variable numcoefsfordataset
	//add a dataset to the linkage matrix.
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	variable ii, jj, maxcoefs, lastunique
	
	maxcoefs = wavemax(numcoefs)
	if(numtype(maxcoefs) || maxcoefs < numcoefsfordataset)
		maxcoefs = numcoefsfordataset
	endif
	
	if(dimsize(numcoefs, 0) == 0)
		lastunique = -1
	else
		lastunique = lastuniqueparameter(numcoefs[dimsize(numcoefs, 0) - 1] - 1, dimsize(linkages, 1) - 1)
	endif
	
	redimension/n=(maxcoefs,  dimsize(linkages, 1) + 1) linkages
	redimension/n=(dimsize(numcoefs, 0) + 1) numcoefs
	numcoefs[dimsize(numcoefs, 0) - 1] = numcoefsfordataset
	
	linkages[][dimsize(linkages, 1) - 1] = p + lastunique + 1
	
	for(ii = 0 ; ii < dimsize(numcoefs, 0) ; ii+=1)
		for(jj = numcoefs[ii] ; jj < dimsize(linkages, 0) ; jj+=1)
			linkages[jj][ii] = -1
		endfor
	endfor
End

static Function remove_dataset_from_linkage(num)
	//removes a dataset from the linkage matrix
	variable num
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	
	string listofParameters = ""
	variable ii, jj, row, col, newmaxcoefs = 0
	
	for(ii = 0 ; ii < dimsize(numcoefs, 0) ; ii+=1)
		if(numcoefs[ii] > newmaxcoefs && ii != num)
			newmaxcoefs = numcoefs[ii]
		endif
	endfor
	
	for(ii = 0 ; ii < numcoefs[num] ; ii+=1)
		listofParameters += num2istr(num) + ":" + num2istr(ii) +";"
	endfor
	unlinkParameterList(listofParameters, removeFollowing = 1)
	Wave uniqueparametermask = isuniqueparam()

	//now all unique parameters following the dataset have to be decremented by numcoefs[num]	
	for(ii = num + 1 ; ii < dimsize(linkages, 1) ; ii+=1)
		for(jj = 0 ; jj < dimsize(uniqueparametermask, 0) ; jj += 1)
			if(uniqueparametermask[jj][ii] > 0)
				linkages[jj][ii] -= numcoefs[num]
			elseif(uniqueparametermask[jj][ii] == 0)
				findvalue/S=0/i=(linkages[jj][ii]) linkages
				col = floor(V_value/dimsize(linkages, 0))
				if(col > num)
					linkages[jj][ii] -=numcoefs[num]
				endif 
			endif
		endfor
	endfor
	if(newmaxcoefs < numcoefs[num])
		deletepoints/M=0 newmaxcoefs, dimsize(linkages, 0), linkages
	endif
	deletepoints/M=1 num,  1, linkages
	deletepoints/M=0 num, 1, numcoefs
End

static Function change_numparameters_in_linkage(datasetnum, params)
	//changes the number of parameters for a given dataset in the linkage matrix
	variable datasetnum, params
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs

	string unlinklist = ""
	variable ii, jj, row, col, diff_params, oldnumberofparams, lastuniqueparam
	
	if(params < 1 || numtype(datasetnum) || numtype(params) || datasetnum < 0 || datasetnum > numpnts(numcoefs) - 1)
		return 1
	endif

	oldnumberofparams = numcoefs[datasetnum]
	
	for(ii = 0 ; ii < numcoefs[datasetnum] ; ii+=1)
		unlinklist += num2istr(datasetnum) + ":" + num2istr(ii) +";"
	endfor
	unlinkParameterList(unlinklist, removeFollowing = 1)
	
	//all the unique parameters following this dataset have to be incremented/decremented by the difference in param number
	diff_params = params - oldnumberofparams 
	
	Wave uniqueparametermask = isuniqueparam()
	
	//now all unique parameters following the dataset have to be incremented/decremented by diff_params	
	for(ii = datasetnum + 1 ; ii < dimsize(linkages, 1) ; ii+=1)
		for(jj = 0 ; jj < dimsize(uniqueparametermask, 0) ; jj += 1)
			if(uniqueparametermask[jj][ii] > 0)
				linkages[jj][ii] += diff_params
			elseif(uniqueparametermask[jj][ii] == 0)
				findvalue/S=0/i=(linkages[jj][ii]) linkages
				col = floor(V_value/dimsize(linkages, 0))
				if(col > datasetnum)
					linkages[jj][ii] += oldnumberofparams
				endif 
			endif
		endfor
	endfor
	
	numcoefs[datasetnum] = params
	redimension/n=(wavemax(numcoefs), -1) linkages
	lastuniqueparam = lastUniqueParameter(0, datasetnum)

	for(ii = 0 ; ii < params ; ii  += 1)
		linkages[ii][datasetnum] = lastuniqueparam + ii
	endfor	
	
	for(ii = 0 ; ii < dimsize(linkages, 1) ; ii += 1)
		for(jj = numcoefs[ii] ; jj < dimsize(linkages, 0) ; jj += 1)
			linkages[jj][ii] = -1
		endfor
	endfor
End

Function save_linkage()
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	
End
static Function build_combined_dataset([fitcursors])
	variable fitcursors
	variable loQ, hiQ
	string info
	loQ = 0
	hiQ = Inf
	
	if(fitcursors)
		if(str2num(motofit#getmotofitoption("fitcursors")))
			Info = csrinfo(A, "reflectivitygraph")
			if(strlen(info))
				loQ = csrxwaveref(A, "reflectivitygraph")[numberbykey("POINT", info)]
			endif
			info = csrinfo(B, "reflectivitygraph")
			if(strlen(info))
				hiQ = csrxwaveref(B, "reflectivitygraph")[numberbykey("POINT", info)]
			endif
		endif
	endif
	
	DFREF savDF = getdatafolderDFR()
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave/t listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	Wave selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	variable ii, jj, kk, numuniqueparams, numdatasets, entry
	setdatafolder root:Packages:motofit:reflectivity:globalfitting
	
	numdatasets = dimsize(linkages, 1)
	Wave uniqueparams = isuniqueparam()
	numuniqueparams = lastUniqueParameter(numcoefs[numdatasets - 1] - 1, numdatasets - 1) + 1
	make/n=(numuniqueparams)/o/d coefs = 0
	make/n=(numuniqueparams)/o/u/i holdwave = 0
	
	make/n=(0)/d/o xx, yy, dy, dx
	make/n=(numdatasets)/u/i/o pnts_each_dataset = 0

	for(ii = 0 ; ii < numdatasets ; ii+=1)
		Wave sepxx = $("root:data:" + datasets[ii] + ":" + datasets[ii] + "_q")
		Wave sepyy = $("root:data:" + datasets[ii] + ":" + datasets[ii] + "_R")
		Wave/z sepee = $("root:data:" + datasets[ii] + ":" + datasets[ii] + "_E")
		Wave/z  sepdx= $("root:data:" + datasets[ii] + ":" + datasets[ii] + "_dq")
		for(jj = 0 ; jj < numpnts(sepxx) ; jj += 1)
			if(sepxx[jj] > loQ && sepxx[jj] < hiQ)
				entry = dimsize(xx, 0) 
				redimension/n=(entry + 1) xx, yy, dy, dx
				xx[entry] = sepxx[jj]
				yy[entry] = sepyy[jj]
				if(waveexists(sepee))
					dy[entry] = sepee[jj]
				endif
				if(waveexists(sepdx))
					dx[entry] = sepdx[jj]
				else
					dx[entry] = NaN
				endif
				pnts_each_dataset[ii] += 1
			endif
		endfor
		
		Waveclear sepxx, sepyy, sepee, sepdx
	endfor
	
	kk = 0
	for(ii = 0 ; ii < numpnts(datasets) ; ii+=1)
		for(jj = 0 ; jj < numcoefs[ii] ; jj += 1)
			if(uniqueparams[jj][ii] > 0)
				coefs[kk] = str2num(listwave[jj][2 * ii + 1])
				holdwave[kk] = (selwave[jj][2 * ii + 2] & 2^4)
				//the number of layers is discrete.
				if(jj == 0)
					holdwave[kk] = 1
					selwave[jj][2 * ii + 2] = selwave[jj][2 * ii + 2] | 2^4
				endif
				kk += 1
			endif
		endfor
	endfor
	holdwave = holdwave[p] ? 1 : 0
	setdatafolder savDF
End

static Function extract_combined_into_list(coefs)
	Wave coefs
	//takes a combined list of coefficients and expands it into the listwave of the panel
	//using the linkages matrix
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave

	duplicate/free linkages, mask
	variable ii, jj, kk
	for(ii = 0 ; ii < numpnts(coefs) ; ii+=1)
		mask = linkages[p][q] == ii ? 1 : 0
		for(jj = 0 ; jj < dimsize(mask, 1) ; jj +=1)
			for(kk = 0 ; kk < dimsize(mask, 0) ; kk +=1)
				if(mask[kk][jj] == 1)
					listwave[kk][2 * jj + 1] = num2str(coefs[ii])
				endif
			endfor
		endfor
	endfor
End

static Function/wave decompose_into_individual_coefs(coefs)
	Wave coefs
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	variable ii
	string name
	make/n=(dimsize(numcoefs, 0))/free/wave individualcoefs
	for(ii = 0 ; ii < numpnts(numcoefs) ; ii += 1)
		individualcoefs[ii] = newfreewave(0x04, numcoefs[ii])
		Wave indy = individualcoefs[ii]
		indy = coefs[linkages[p][ii]]
		waveclear indy
	endfor
	
	return individualcoefs
End

Function motofit_globally(w, RR, qq):fitfunc
	Wave w, RR, qq
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave pnts_each_dataset = root:Packages:motofit:reflectivity:globalfitting:pnts_each_dataset
	variable ii, offset = 0
	make/n=(pnts_each_dataset[0])/d/free ytemp, xtemp
	
	Wave/wave individual_coefs = decompose_into_individual_coefs(w)
	for(ii = 0 ; ii < numpnts(numcoefs) ; ii+=1)
		redimension/n=(pnts_each_dataset[ii]) xtemp, ytemp
		xtemp = qq[offset + p]
		Wave indy = individual_coefs[ii]
		motofit(individual_coefs[ii], ytemp, xtemp)
		RR[offset, offset + pnts_each_dataset[ii] - 1] = ytemp[p - offset]
		offset += pnts_each_dataset[ii]
	endfor
End

Function motofit_smeared_globally(w, RR, qq, dq):fitfunc
	Wave w, RR, qq, dq
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave pnts_each_dataset = root:Packages:motofit:reflectivity:globalfitting:pnts_each_dataset
	variable ii, offset = 0
	make/n=(pnts_each_dataset[0])/d/free ytemp, xtemp, dxtemp
	
	Wave/wave individual_coefs = decompose_into_individual_coefs(w)
	for(ii = 0 ; ii < numpnts(numcoefs) ; ii+=1)
		redimension/n=(pnts_each_dataset[ii]) xtemp, ytemp, dxtemp
		xtemp = qq[offset + p]
		dxtemp = dq[offset + p]
		Wave indy = individual_coefs[ii]
		motofit_smeared(individual_coefs[ii], ytemp, xtemp, dxtemp)
		RR[offset, offset + pnts_each_dataset[ii] - 1] = ytemp[p - offset]
		offset += pnts_each_dataset[ii]
	endfor
End


static Function evaluateGlobalFunction([fitCursors, usedqwave])
	variable fitCursors, usedqwave
	
	build_combined_dataset(fitcursors = fitcursors)
	
	Wave yy = root:Packages:motofit:reflectivity:globalfitting:yy
	Wave xx = root:Packages:motofit:reflectivity:globalfitting:xx
	Wave/z dy = root:Packages:motofit:reflectivity:globalfitting:dy
	Wave/z dx = root:Packages:motofit:reflectivity:globalfitting:dx
	Wave coefs = root:Packages:motofit:reflectivity:globalfitting:coefs
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave pnts_each_dataset = root:Packages:motofit:reflectivity:globalfitting:pnts_each_dataset
	Wave SLD_theoretical_R = root:data:theoretical:SLD_theoretical_R
	Wave/wave outputcoefs = decompose_into_individual_coefs(coefs)
	
	string datasetname, alert
	variable ii, offset = 0, resolution
	
	//now do the function evaluation
	make/o/d/n=(dimsize(yy, 0)) root:Packages:motofit:reflectivity:globalfitting:fityy /Wave=fityy
	make/o/d/n=(dimsize(yy, 0)) root:Packages:motofit:reflectivity:globalfitting:fitxx /Wave=fitxx
	make/o/d/n=(dimsize(yy, 0)) root:Packages:motofit:reflectivity:globalfitting:res_fityy /Wave=res_fityy
	
	duplicate/free yy, chi2
	fitxx = xx
	fityy = NaN
	res_fityy = NaN

	Wavestats/q/z coefs
	if(V_numNaNs || V_numInfs)
		return NaN
	endif
	
	if(!usedqwave)
		motofit_globally(coefs, fityy, fitxx)
	else
		wavestats/q/z dx
		if(V_numnans)
			alert = "You selected to use point by point resolution smearing (\"use dq wave\"), but not all the datasets possessed dq information."
			alert += "Do you want to assume that the missing resolution information is constant dq/q?"
			Doalert 1, alert
			if(V_Flag == 2)
				abort
			endif
			resolution = str2num(motofit#getmotofitoption("res")) / 100
			dx = numtype(dx[p]) ? xx[p] * resolution : dx[p]
		endif
		redimension/n=(-1, 2) fitxx
		fitxx[][1] = dx[p]
		motofit_smeared_globally(coefs, fityy, fitxx, dx)
	endif
	
	chi2 = yy - fityy
	if(waveexists(dy) && str2num(motofit#getmotofitoption("useerrors")))
		chi2 /= dy
	endif
	chi2 = chi2^2
	res_fityy = yy - fityy
	
	//evaluate the fit waves for the model
	for(ii = 0 ; ii < numpnts(datasets) ; ii+=1)
		datasetname = datasets[ii]
		//remake the fit waves and sld graphs
		make/o/d/n=(pnts_each_dataset[ii]) $("root:data:" + datasetname + ":fit_" + datasetname + "_R")/Wave=fitR
		fitR = fityy[offset + p]

		make/o/d/n=(pnts_each_dataset[ii]) $("root:data:" + datasetname + ":fit_" + datasetname + "_q")/Wave=fitq
		fitq = fitxx[offset + p]

		//make the residuals
		make/o/d/n=(pnts_each_dataset[ii]) $("root:data:" + datasetname + ":res_" + datasetname + "_R")/Wave=resR
		resR = res_fityy[offset + p]
		
		//make SLD waves
		make/n=(dimsize(SLD_theoretical_R, 0))/d/o $("root:data:" + datasetname + ":SLD_" + datasetname + "_R")/Wave =SLDr
		Moto_SLDplot(outputcoefs[ii], sldr)

		offset += pnts_each_dataset[ii]
		Waveclear fitR, fitq, resR, sldr
	endfor
	Wavestats/q/z/M=1 chi2
	return V_avg
//	return sum(chi2)/numpnts(chi2)
End

static Function plotCombinedFitAndEvaluate([fitcursors, usedqwave])
	variable fitcursors, usedqwave
	
	DFREF savDF = getdatafolderDFR()
	variable retval = NaN
	
	setdatafolder root:Packages:motofit:reflectivity:globalfitting
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave SLD_theoretical_R = root:data:theoretical:SLD_theoretical_R

	variable ii, offset = 0, colornum
	string datasetname, traces, tracecolour
	
	retval = evaluateGlobalFunction(fitcursors = fitcursors, usedqwave = usedqwave)	
		
	for(ii = 0 ; ii < dimsize(linkages, 1) ; ii += 1)
		datasetname = datasets[ii]

		//append fit wave to the reflectivitygraph as well
		Wave fitR = $("root:data:" + datasetname + ":fit_" + datasetname + "_R")
		Wave fitQ = $("root:data:" + datasetname + ":fit_" + datasetname + "_q")
		Wave resR = $("root:data:" + datasetname + ":res_" + datasetname + "_R")
		Wave SLDr = 	$("root:data:" + datasetname + ":SLD_" + datasetname + "_R")
		traces = tracenamelist("Reflectivitygraph", ";", 1)
		tracecolour = moto_gettracecolour("reflectivitygraph", datasetname + "_R")
		
		if(whichlistitem(nameofwave(fitR), traces) == -1)
			appendtograph/W=reflectivitygraph/q fitR vs fitQ
			execute/z "modifygraph/W=reflectivitygraph rgb(" + nameofwave(fitR) + ")="  + tracecolour 
		endif
		
		traces = tracenamelist("SLDgraph", ";", 1)
		if(whichlistitem(nameofwave(SLDr), traces) == -1)
			appendtograph/W=SLDgraph/q SLDr
			execute/z "modifygraph/W=SLDgraph rgb(" + nameofwave(SLDr) + ")="  + tracecolour + ",lsize("+nameofwave(SLDr) + ")=2"
		endif
		Waveclear fitR, fitq, SLDr, resR		
	endfor

	setdatafolder savDF
	return retVal
End

Function Do_a_global_fit()
	string info
	variable retval
	string holdstring = "", datasetname, motofitstring, traces, tracecolour, tracename = "", tracename2, fitfunction = "", alert
	DFREF cDF = getdatafolderDFR()
	variable numdatasets, ii, jj, offset, colornum, iters, resolution
	
	retval = plotCombinedFitAndEvaluate(fitcursors = str2num(motofit#getmotofitoption("fitcursors")), usedqwave = str2num(motofit#getmotofitoption("usedqwave")))

	if(numtype(retval))
		print "ERROR evaluating function, perhaps there is a NaN/Inf parameter"
		return 1
	endif
	
	//the following waves are evaluated in the above function.
	Wave yy = root:Packages:motofit:reflectivity:globalfitting:yy
	Wave xx = root:Packages:motofit:reflectivity:globalfitting:xx
	Wave/z dy = root:Packages:motofit:reflectivity:globalfitting:dy
	Wave/z dx = root:Packages:motofit:reflectivity:globalfitting:dx
	Wave holdwave = root:Packages:motofit:reflectivity:globalfitting:holdwave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave fityy = root:Packages:motofit:reflectivity:globalfitting:fityy
	Wave fitxx = root:Packages:motofit:reflectivity:globalfitting:fitxx
	Wave res_fityy = root:Packages:motofit:reflectivity:globalfitting:res_fityy
	Wave coefs = root:Packages:motofit:reflectivity:globalfitting:coefs
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave pnts_each_dataset = root:Packages:motofit:reflectivity:globalfitting:pnts_each_dataset
	Wave M_colors = root:Packages:motofit:reflectivity:globalfitting:M_colors
	Wave SLD_theoretical_R = root:data:theoretical:SLD_theoretical_R
	
	sockitwavetostring/TXT="" holdwave, holdstring	
	controlinfo/W=reflectivitypanel Typeoffit_tab0
	numdatasets = (dimsize(numcoefs, 0))
	
	//what weighting do you want to use?
	if(!waveexists(dy) || !str2num(motofit#getmotofitoption("useerrors")))
		duplicate/free yy, dytemp
		dytemp = 1.
	else
		duplicate/free dy, dytemp
	endif
	
	//do you want to do point by point resolution smearing?
	if(str2num(motofit#getmotofitoption("usedqwave")))
		Wavestats/q/z dx
		if(V_numnans)
			alert = "You selected to use point by point resolution smearing (\"use dq wave\"), but not all the datasets possessed dq information."
			alert += "Do you want to assume that the missing resolution information is constant dq/q?"
			Doalert 1, alert
			if(V_Flag == 2)
				abort
			endif
			resolution = str2num(motofit#getmotofitoption("res")) / 100
			dx = numtype(dx[p]) ? xx[p] * resolution : dx[p]
		endif		
		fitfunction = "motofit_smeared_globally"
	else
		fitfunction = "motofit_globally"
	endif
	//make a graph for showing the latest data
	if(!itemsinlist(winlist("globalreflectometrygraph", ";","")))
		Display/K=1/N=globalreflectometrygraph/W=(0,0,600, 400)
	else
		//remove all traces
		tracename2 = TraceNameList("globalreflectometrygraph",";", 1)
		tracename2 = sortlist(tracename2, ";", 17)
		for(ii = 0 ; ii < itemsinlist(tracename2) ; ii+=1)
			removefromgraph/z/w=globalreflectometrygraph $(stringfromlist(ii, tracename2))
		endfor
	endif
	for(ii = 0 ; ii < numdatasets ; ii += 1)
		if(ii == 0)
			tracename = "yy"
		else
			tracename = "yy#" + num2istr(ii)
		endif
		colornum = mod(ii * 37, dimsize(M_colors, 0))
		
		appendtograph/W=globalreflectometrygraph yy[offset, pnts_each_dataset[ii] -1 + offset] vs xx[offset, pnts_each_dataset[ii] - 1 + offset]
		if(waveexists(dy))
			ErrorBars/W=globalreflectometrygraph $tracename Y, wave=(dy[offset, pnts_each_dataset[ii] - 1 + offset], dy[offset, pnts_each_dataset[ii] - 1 + offset])
		endif
		modifygraph/W=globalreflectometrygraph rgb($tracename) = (M_colors[colornum][0], M_colors[colornum][1],M_colors[colornum][2])
		modifygraph/W=globalreflectometrygraph mode = 3, log(bottom) = 1, marker = 8
		offset += pnts_each_dataset[ii]
	endfor
	
	offset = 0
	for(ii = 0 ; ii < dimsize(linkages, 1) ; ii += 1)
		datasetname = datasets[ii]
		if(ii == 0)
			tracename = "fityy"
			tracename2 = "res_fityy"
		else
			tracename = "fityy#" + num2istr(ii)
			tracename2 = "res_fityy#" + num2istr(ii)
		endif
		colornum = mod(ii * 37, dimsize(M_colors, 0))
		appendtograph/W=globalreflectometrygraph fityy[offset, pnts_each_dataset[ii] - 1 + offset] vs fitxx[offset, pnts_each_dataset[ii] - 1 + offset]
		appendtograph/W=globalreflectometrygraph/L=res res_fityy[offset, pnts_each_dataset[ii] - 1 + offset] vs fitxx[offset, pnts_each_dataset[ii] - 1 + offset]
		modifygraph/W=globalreflectometrygraph rgb($tracename) = (M_colors[colornum][0], M_colors[colornum][1],M_colors[colornum][2])
		modifygraph/W=globalreflectometrygraph rgb($tracename2) = (M_colors[colornum][0], M_colors[colornum][1],M_colors[colornum][2])
		
		offset += pnts_each_dataset[ii]
	endfor
	
	ModifyGraph/Z/W=globalreflectometrygraph wbRGB=(0,0,0),gbRGB=(0,0,0)
	ModifyGraph/W=globalreflectometrygraph/Z rgb[1]=(18724,65535,0)
	ModifyGraph/W=globalreflectometrygraph zero(res)=1,axisEnab(left)={0.15,1},axisEnab(res)={0,0.1}
	ModifyGraph/W=globalreflectometrygraph freePos(res)={0,bottom},axRGB=(65535,65535,65535)
	ModifyGraph/W=globalreflectometrygraph tlblRGB=(65535,65535,65535),alblRGB=(65535,65535,65535)
	//now do the fits
	variable/g V_fiterror = 0	
	try
		strswitch(S_value)
			case "Genetic":
				GEN_setlimitsforGENcurvefit(coefs, holdstring)
				Wave limitswave = root:packages:motofit:old_genoptimise:GENcurvefitlimits
				NVAR  iterations = root:packages:motofit:old_genoptimise:iterations
				NVAR  popsize = root:packages:motofit:old_genoptimise:popsize
				NVAR  k_m = root:packages:motofit:old_genoptimise:k_m
				NVAR  recomb = root:packages:motofit:old_genoptimise:recomb
				NVAR fittol = root:packages:motofit:old_genoptimise:fittol
				GenCurvefit/q/TOL=(fittol)/K={iterations, popsize, k_m, recomb}/D=fityy/HOLD=holdwave/I=1/W=dytemp/MAT/R=res_fityy/X=fitxx $fitfunction, yy, coefs, "", limitswave
				break
			case "Levenberg-Marquardt":
				FuncFit/H=holdstring/M=2/Q/NTHR=0 $fitfunction coefs yy /X=fitxx /W=dytemp /I=1 /D=fityy /R /A=0
				break
			case "Genetic + LM":
				GEN_setlimitsforGENcurvefit(coefs, holdstring)
				Wave limitswave = root:packages:motofit:old_genoptimise:GENcurvefitlimits
				NVAR  iterations = root:packages:motofit:old_genoptimise:iterations
				NVAR  popsize = root:packages:motofit:old_genoptimise:popsize
				NVAR  k_m = root:packages:motofit:old_genoptimise:k_m
				NVAR  recomb = root:packages:motofit:old_genoptimise:recomb
				NVAR fittol = root:packages:motofit:old_genoptimise:fittol
				GenCurvefit/q/TOL=(fittol)/K={iterations, popsize, k_m, recomb}/D=fityy/HOLD=holdwave/I=1/W=dytemp/MAT/R=res_fityy/X=fitxx $fitfunction, yy, coefs, "", limitswave
				FuncFit/H=holdstring/M=2/Q/NTHR=0 $fitfunction coefs yy /X=fitxx /W=dytemp /I=1 /D=fityy /R /A=0
				break
			case "Genetic+MC_Analysis":
				if(!str2num(motofit#getmotofitoption("useerrors")))
					Doalert 0, "you need to select the use errors checkbox for the Monte Carlo fitting"
					return 1
				endif
				iters = 200
				prompt iters, "how many iterations?"
				Doprompt "Enter the number of MC iterations", iters
				if(V_Flag)
					return 1
				endif
				
				Moto_montecarlo(fitfunction, coefs, yy, fitxx, dy, holdstring, Iters)
				Wave M_montecarlo //also outputs W_sigma
				//overwrite the original coefficients
				matrixop/free/o summ = sumcols(M_montecarlo)
				coefs = summ[0][p] / dimsize(M_montecarlo, 0)
				extract_combined_into_list(coefs)
			
				processGlobalMonteCarlo(M_montecarlo)	
				break
		endswitch
	catch
		V_fiterror = 1
		setdatafolder cDF
	endtry
	setdatafolder cDF
	
	if(!V_fiterror)
		//put the coefficients back into the list
		extract_combined_into_list(coefs)
		
		//create fitted coefficient waves
		Wave/wave outputcoefs = decompose_into_individual_coefs(coefs)
		Wave W_sigma
		Wave/wave outputsigma = decompose_into_individual_coefs(W_sigma)
		motofitstring = motofit#getmotofitoptionstring()
		motofitstring = replacestringbykey("holdstring", motofitstring, "")
		offset = 0
		for(ii = 0 ; ii < numdatasets ; ii+=1)
			datasetname = datasets[ii]
			
			//make the coefficients
			Wave indy = outputcoefs[ii]
			Wave sig = outputsigma[ii]
			
			make/o/d/n=(numcoefs[ii]) $("root:data:" + datasetname + ":coef_" + datasetname + "_R")/Wave=indy2
			make/o/d/n=(numcoefs[ii]) $("root:data:" + datasetname + ":W_sigma")/Wave=indy4
			indy2 = indy
			indy4[] = sig[p]
			note/k indy2
			note indy2, motofitstring
			
			print "_________________________________________________________________"
			print "Global Fitting"
			print datasetname + "_R", " vs ", datasetname + "_q"
			for(jj = 0 ; jj < numpnts(indy2) ; jj+=1)
				printf "\tw[%d] = %f\t+/-\t%g\r", jj, indy[jj], sig[jj]
			endfor
			print "_________________________________________________________________"

			Waveclear indy, indy2, indy4, sig
		endfor
	endif
	
	//get the best fit waves AFTER THE FIT
	variable chi2 = evaluateGlobalFunction(fitcursors = str2num(motofit#getmotofitoption("fitcursors")), usedqwave = str2num(motofit#getmotofitoption("usedqwave")))
	
	//do you want to append residuals
	controlinfo/W=reflectivitygraph appendresiduals
	if(V_Value)
		motofit#moto_appendresiduals()
	endif
	ValDisplay Chi2_tab1, win=globalreflectometrypanel, value = _NUM:(chi2)
	dowindow/k globalreflectometrygraph
End

Function processGlobalMonteCarlo(M_montecarlo)
	//processes monte carlo results for the global fitting
	//should take the form of a 2D wave.  rows=iterations
	//columns = parameters.
	Wave M_montecarlo

	DFREF cDF = getdatafolderDFR()
	variable numdatasets, ii, jj
	Wave holdwave = root:Packages:motofit:reflectivity:globalfitting:holdwave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave coefs = root:Packages:motofit:reflectivity:globalfitting:coefs
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave pnts_each_dataset = root:Packages:motofit:reflectivity:globalfitting:pnts_each_dataset
	
	numdatasets = dimsize(datasets, 0)
	
	//overwrite the coefficient wave (this is repeated in do_a_fit, but isn't present when you ingest motoMPI
	matrixop/free summ = sumcols(M_montecarlo)
	coefs = summ[0][p] / dimsize(M_montecarlo, 0)
	
	//now got to split M_Montecarlo into individual waves, in the root:data folder
	make/wave/n=(numdatasets)/free montecarlowaves
	duplicate/free coefs, tempcoefs
	//make an individual M_montecarlo
	for(ii = 0 ; ii < numdatasets ; ii+=1)
		make/o/d/n=(dimsize(M_montecarlo, 0), numcoefs[ii]) $("root:data:" + datasets[ii] + ":M_montecarlo")/Wave=indy
		montecarlowaves[ii] = indy
		Waveclear indy
	endfor
	//fill in the individual M_montecarlo
	for(ii = 0 ; ii < dimsize(M_montecarlo, 0) ; ii += 1)
		tempcoefs = M_montecarlo[ii][p]
		Wave/wave outputcoefs = decompose_into_individual_coefs(tempcoefs)
		for(jj = 0 ; jj < numdatasets ; jj += 1)
			Wave indy = outputcoefs[jj]
			Wave indy3 = montecarlowaves[jj]
			indy3[ii][] = indy[q]
		endfor
	endfor

	//make an individual output coefficient
	for(ii = 0 ; ii < numdatasets ; ii += 1)
		Wave indy = montecarlowaves[ii]
		make/o/d/n=(dimsize(indy, 1)) $("root:data:" + datasets[ii] + ":coef_" + datasets[ii] + "_R")/Wave=indy2
		make/o/d/n=(dimsize(indy, 1)) $("root:data:" + datasets[ii] + ":W_sigma")/Wave=indy4
		
		for(jj = 0 ; jj < dimsize(indy, 1) ; jj+=1)
			make/n=(dimsize(indy, 0))/d/free temp
			temp[] = indy[p][jj]
			indy2[jj] = mean(temp)
			indy4[jj] = variance(temp)
		endfor
		indy4 = sqrt(indy4)
	endfor

	plotCombinedFitAndEvaluate(fitcursors = str2num(motofit#getmotofitoption("fitcursors")))
	
	//and make the SLD plots
	for(ii = 0 ; ii < numdatasets ; ii+=1)
		setdatafolder $("root:data:" + datasets[ii])
		motofit#moto_montecarlo_SLDcurves(montecarlowaves[ii], 0.02, 500)
		setdatafolder cDF
	endfor	
End

Function setup_motoMPI()
	//sets up input for the motoMPI program, for parallelized monte carlo fitting on a cluster.
		
	string holdstring = "", datasetname, txt = "", pilots = "", datas = "", info = ""
	variable numdatasets, ii, fileID, pilotID, jj, loQ, hiQ, pnt, reso
		
	build_combined_dataset()
	Wave holdwave = root:Packages:motofit:reflectivity:globalfitting:holdwave
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave coefs = root:Packages:motofit:reflectivity:globalfitting:coefs
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave/t datasets = root:Packages:motofit:reflectivity:globalfitting:datasets
	Wave/t listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
	Wave selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
	
	loQ = 0
	hiQ = Inf
	reso = str2num(motofit#getmotofitoption("res"))
	
	if(str2num(motofit#getmotofitoption("fitcursors")))
		Info = csrinfo(A, "reflectivitygraph")
		if(strlen(info))
			loQ = csrxwaveref(A, "reflectivitygraph")[numberbykey("POINT", info)]
		endif
		info = csrinfo(B, "reflectivitygraph")
		if(strlen(info))
			hiQ = csrxwaveref(B, "reflectivitygraph")[numberbykey("POINT", info)]
		endif
	endif
	
	sockitwavetostring/TXT="" holdwave, holdstring	
	controlinfo/W=reflectivitypanel Typeoffit_tab0
	numdatasets = (dimsize(numcoefs, 0))

	newpath/M="Select/create a folder to put the motoMPI input"/o/q/z/c motoMPI
	pathinfo motoMPI
	if(!V_Flag)
		return 1
	endif

	//setup limits
	GEN_setlimitsforGENcurvefit(coefs, holdstring)		
	Wave limitswave = root:packages:motofit:old_genoptimise:GENcurvefitlimits
			
	//make the datasets
	for(ii = 0 ; ii < numdatasets ; ii += 1)
		datasetname = datasets[ii]
		open/P=motoMPI fileID as datasetname + ".txt"
		datas += datasetname + ".txt" + ";"
		open/P=motoMPI pilotID as datasetname + "_pilot.txt"
		pilots += datasetname + "_pilot.txt" + ";"
		
		//write a datafile
		Wave originaldata = $("root:data:" + datasetname + ":originaldata")
		txt = ""
		make/n=(dimsize(originaldata, 0), dimsize(originaldata, 1))/t/free datatext		
		datatext = num2str(originaldata)
		redimension/n=(-1, 4) datatext
		if(dimsize(originaldata, 1) < 4)
			Doalert 0, "no resolution data for dataset " + datasetname + " assuming constant dq/q"
			datatext[][3] = num2str(originaldata[p][0] * reso / 100)
		endif

		//but only for a restricted Q range dictated by the cursors.
		make/free/d/n=(dimsize(originaldata, 0)) tempqq
		tempqq[] = originaldata[p][0]
		
		findlevel/P/Q tempqq, hiQ
		if(!numtype(V_levelX))
			deletepoints/M=0 V_levelX, dimsize(datatext, 0) , datatext
		endif
		findlevel/P/Q tempqq, loQ
		if(!numtype(V_levelX))
			deletepoints/M=0 0, V_levelX , datatext
		endif
		
		insertpoints/M=1 4, 1, datatext
		insertpoints/M=1 3, 1, datatext
		insertpoints/M=1 2, 1, datatext
		insertpoints/M=1 1, 1, datatext
		datatext[][1] = "\t"
		datatext[][3] = "\t"
		datatext[][5] = "\t"
		datatext[][7] = "\n"
		datatext[dimsize(datatext, 0) - 1][7] = ""
		matrixtranspose datatext
		sockitwavetostring datatext, txt
		
		fbinwrite fileID, txt
		close fileID
		
		//now write a pilot file
		txt = "stuff\nvalue hold lowlim hilim\n"
		fbinwrite pilotID, txt
		
		for(jj = 0 ; jj < numcoefs[ii] ; jj += 1)
			txt = ""
			txt += listwave[jj][2 * ii + 1] + " "
			txt += selectstring(selwave[jj][2 * ii + 2] & 2^4, "0","1") + " "
			
			txt += num2str(limitswave[linkages[jj][ii]][0]) + " "
			txt += num2str(limitswave[linkages[jj][ii]][1])
			
			if(jj < numcoefs[ii] - 1)
				txt += "\n"
			endif

			fbinwrite pilotID, txt
		endfor		
		close pilotID
	endfor
	
	open/P=motoMPI pilotID as "global_pilot"
	datas = replacestring(";", datas, " ")
	datas = removeending(datas, " ") + "\n"
	fbinwrite pilotID, datas
	
	pilots = replacestring(";", pilots, " ")
	pilots = removeending(pilots, " ") + "\n"
	fbinwrite pilotID, pilots
	
	for(ii = 0 ; ii < dimsize(linkages, 0) ; ii += 1)
		txt = ""
		for(jj = 0 ; jj < numdatasets ; jj += 1)
			txt += num2istr(linkages[ii][jj]) + " "
		endfor
		txt = removeending(txt, " ")
		if(ii < dimsize(linkages, 0) - 1)
			txt += "\n"
		endif
		fbinwrite pilotID, txt
	endfor
	close pilotID
	
	//TODO Write a PBS script.
End

Function parse_motoMPI([fileStr])
	string fileStr
	//parses output from the motoMPI program.
	//each line is the fit result from a single fit.
	//the first value on each line is a chi2 value.
	
	if(!paramisdefault(fileStr))
		LoadWave/J/M/D/A=wave/K=0/V={"\t, "," $",0,0} fileStr
	else
		Loadwave/J/M/D/A=wave/K=0/V={"\t, "," $",0,0}
	endif
	if(!V_flag)
		return 1
	endif
	Wave theMonteCarlo = $(stringfromlist(0, S_wavenames))
	deletepoints/M=1 0, 1, theMontecarlo
	
	//process the output
	processGlobalMonteCarlo(themontecarlo)
	
	duplicate/o theMontecarlo, M_montecarlo
	killwaves/z theMonteCarlo
End

Function ingest_motoMPI_input([folderStr])
	string folderStr
	//ingests the input to a motoMPI program.
	//i.e. the inputs are the files created by setup_motoMPI()
	
	variable global_pilotID, ii, jj, pilotID, numdatasets,  isImagOrSolvent, hold, row, col
	string input, datafiles, pilotfiles, pathStr, holdstr, linkparams = ""

	try
		if(paramisdefault(folderStr))
			newpath/M="Select the folder containing the setup"/o/q/z motoMPI
		else
			newpath/o/q/z motoMPI, folderStr
		endif
		if(V_Flag)
			abort
		endif
		open/R/P=motoMPI/z global_pilotID as "global_pilot"
		if(V_flag)
			abort
		endif
		pathInfo motoMPI
		pathStr = S_path
	
		freadline global_pilotID, datafiles
		numdatasets = itemsinlist(datafiles, " ")
		make/free/t/n=(numdatasets, 2) datanames
		make/free/n=(numdatasets)/wave coefs
		
		datafiles = removeending(datafiles, "\r")
		for(ii = 0 ; ii < numdatasets ; ii += 1)
			datanames[ii][0] = Motofit#Moto_loadReffile(pathStr + stringfromlist(ii, datafiles, " "))
		endfor

		freadline global_pilotID, pilotfiles
		pilotfiles = removeending(pilotfiles, "\r")
		//read the individual pilot files.
		for(ii = 0 ; ii < numdatasets ; ii += 1)
			open/r/z/P=motoMPI pilotID as stringfromlist(ii, pilotfiles, " ")
			if(V_flag)
				abort
			endif
			//two redundant lines at top
			freadline pilotID, input
			freadline pilotID, input
			//now we get to the interesting part
			make/free/n=(0)/d/o params
			do
				freadline pilotID, input
				if(!strlen(input))
					break
				endif
				redimension/n=(numpnts(params) + 1) params
				params[numpnts(params) - 1] = str2num(stringfromlist(0, input, " "))
				datanames[ii][1] += stringfromlist(1, input, " ")
			while(1)
			duplicate/o params, $("root:data:" + datanames[ii][0] + ":coef_" + datanames[ii][0] + "_R")
			Wave indy = $("root:data:" + datanames[ii][0] + ":coef_" + datanames[ii][0] + "_R")
			coefs[ii] = indy
			close pilotID
			pilotID = 0
		endfor
		//now we've loaded the pilot files and data, try and set the global fitting up.
		isImagOrSolvent = mod((dimsize(params, 0) - 6), 4)
		if(isImagOrSolvent)
			isImagOrSolvent = 1
		endif
		init_fitting(restart = 1, isImagOrSolvent = isImagOrSolvent)
		Wave/t coefficients_listwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_listwave
		Wave coefficients_selwave = root:Packages:motofit:reflectivity:globalfitting:coefficients_selwave
		
		for(ii = 0 ; ii < numdatasets ; ii += 1)
			Wave indy = coefs[ii]
			add_a_dataset(datanames[ii][0], indy[0])
			holdstr = datanames[ii][1]
			for(jj = 0 ; jj < numpnts(indy) ; jj+=1)
				set_param(indy[jj], jj, ii, coefficients_listwave)
				coefficients_selwave[jj][2*ii+2] = str2num(holdstr[jj]) ? coefficients_selwave[jj][2 * ii + 2] | 2^4 :coefficients_selwave[jj][2 * ii + 2] &~( 2^4)	
			endfor
		endfor
		
		//now we have to link parameters, read in linkage matrix
		make/n=(0, numdatasets)/i/free templinkage
		do
			freadline global_pilotID, input
			if(!strlen(input))
				break
			endif
			input = removeending(input, "\r")
			redimension/n=(dimsize(templinkage, 0) + 1, -1) templinkage
			templinkage[dimsize(templinkage, 0) - 1][] = str2num(stringfromlist(q, input, " "))
		while(1)
		
		//linkage matrix read in, link all the parameters
		Wave uniquemask = isuniqueparam(linkagematrix = templinkage)
		for(ii = 0 ; ii < numdatasets ; ii += 1)
			for(jj = 0 ; jj < dimsize(templinkage, 0) ; jj += 1)
				if(uniquemask[jj][ii] == 0)	//parameter is not unique, have to link to one preceeding.
					findvalue/i=(templinkage[jj][ii])/z templinkage
					col=floor(V_value / dimsize(templinkage, 0))
					row=V_value - col * dimsize(templinkage, 0)
					linkparameterlist(num2istr(col) + ":" + num2istr(row) + ";" + num2istr(ii) + ":" + num2istr(jj))
				endif
			endfor
		endfor
		regenerateLinkageListBoxes()
	catch
	
	endtry
	if(global_pilotID)
		close global_pilotID
	endif
	if(pilotID)
		close pilotID
	endif
End
#pragma rtGlobals=2		// Use modern global access method.
#pragma version = 1.10
#pragma IgorVersion = 5.02
#pragma ModuleName= MOTO_WM_NewGlobalFit1

#include <BringDestToFront>
#include <SaveRestoreWindowCoords>

//**************************************
// Changes in Global Fit procedures
// 
//	1.00	first release of Global Fit 2. Adds multi-function capability and ability to link fit coefficients
//			in arbitrary groups. Thus, a coefficient that is not linked to any other coefficient is a "local"
//			coefficient. A coefficient that has all instances linked together is global. This is what the original
//			Global Fit package allowed. In addition, Global Fit 2 allows you to link coefficients into groups that
//			span different fitting functions, or include just a subset of instances of a coefficient.
//
//	1.01	Fixed bugs in contextual menu that pops up from the Initial Guess title cell in the coefficient list
//				on the Coefficient Control tab.
//			Now handles NaN's in data sets, mask waves and weight waves
//
//	1.02	Now uses global string variable for hold string to avoid making the command too long.
//
//	1.03	Cleaned up contextual menus a bit. Click in Data Sets and Functions list requires Control key to present menu.
//			Coefficient list on Coefficient Control tab has items that read "... Selection to(from) wave..." when a selection is present.
//
//	1.04 	Fixed bug: On Windows, if the Global Fit panel was minimized, it gave an error when the window resize code tried to
//			arrange the controls in a too-small window.
//
//	1.05	Fixed bugs:
//				Mask wave panel didn't get full paths for Y waves, so it didn't work correctly when Y waves were
//				not in root:
//
//				Coefficient Control list didn't update when Y waves were replaced using the Set Y Wave menu.
//
//  1.06	If the Global Fit control panel was re-sized very large to see lots of coefficients, the coefficient control
//				tab could be seen at the right edge.
//
//			Waves named "fit_<data set name>" were created but not used. They are no longer made.
//
//	1.07	Fixed a bug in MOTO_NewGF_SetCoefsFromWaveProc that caused problems with the Set from Wave menu.
//	1.08	Fixed a bug in NewGF_CoefRowForLink() that caused problems connected linked cells on the Coefficient
//				Control tab.
//	1.09	Added option for log-spaced X axis for destination waves.
//	1.10	Fixed the bug caused by the fix at 1.08. Had to create a new function: NewGF_CoefListRowForLink(); 
//			NewGF_CoefRowForLink() was being used for two different but related purposes.
//**************************************

//	ARJN VERSION ----- FORKED FROM Wavemetrics version on 4/5/2006
//	I had to hack the file to differentiate it from the version supplied by Wavemetrics.
//	1) Replaced all non static functions with prefix MOTO_, unless the function name became too long, in which case
//		I eliminated the original start.
//	2) Replaced all non-static constants with MOTO_ prefix.
//	3) Replaced the module name

//**************************************
// Things to add in the future:
// 
// 		Want something? Tell support@wavemetrics.com about it!
//**************************************

//ARJN 4/2007
Menu "Motofit"
	Submenu "MotoGlobalfit"
		"MotoGlobal Fit", MOTO_WM_NewGlobalFit1#InitNewGlobalFitPanel()
		"Unload MotoGlobal Fit", MOTO_WM_NewGlobalFit1#UnloadNewGlobalFit()
	End
end

// This is the prototype function for the user's fit function
// If you create your fitting function using the New Fit Function button in the Curve Fitting dialog,
// it will have the FitFunc keyword, and that will make it show up in the menu in the Global Fit control panel.
//ARJN 4/2007
Function MOTO_GFFitFuncTemplate(w, xx)
	Wave w
	Variable xx
	
	DoAlert 0, "Global Fit is running the template fitting function for some reason."
	return nan
end
//ARJN 4/2007
Function MOTO_GFFitAllAtOnceTemplate(pw, yw, xw)
	Wave pw, yw, xw
	
	DoAlert 0, "Global Fit is running the template fitting function for some reason."
	yw = nan
	return nan
end

static constant FuncPointerCol = 0
static constant FirstPointCol = 1
static constant LastPointCol = 2
static constant NumFuncCoefsCol = 3
static constant FirstCoefCol = 4

Function MOTO_NewGlblFitFunc(inpw, inyw, inxw)
	Wave inpw, inyw, inxw

	//ARJN 4/2007
	Wave Xw = root:packages:MotofitGF:NewGlobalFit:XCumData
	//ARJN 4/2007
	Wave DataSetPointer = root:packages:MotofitGF:NewGlobalFit:DataSetPointer
	//ARJN 4/2007
	Wave CoefDataSetLinkage = root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	//ARJN 4/2007
	Wave/T FitFuncList = root:packages:MotofitGF:NewGlobalFit:FitFuncList
	//ARJN 4/2007
	Wave SC=root:packages:MotofitGF:NewGlobalFit:ScratchCoefs
	
	Variable numSets = DimSize(CoefDataSetLinkage, 0)
	Variable CoefDataSetLinkageIndex, i	
	
	for (i = 0; i < NumSets; i += 1)
		Variable firstP = CoefDataSetLinkage[i][FirstPointCol]
		Variable lastP = CoefDataSetLinkage[i][LastPointCol]

		CoefDataSetLinkageIndex = DataSetPointer[firstP]
		//ARJN 4/2007
		FUNCREF MOTO_GFFitFuncTemplate theFitFunc = $(FitFuncList[CoefDataSetLinkage[CoefDataSetLinkageIndex][FuncPointerCol]])

		SC = inpw[CoefDataSetLinkage[CoefDataSetLinkageIndex][FirstCoefCol+p]]
		inyw[firstP, lastP] = theFitFunc(SC, Xw[p])
	endfor
end

//ARJN 4/2007
Function MOTO_NewGlblFitFuncAllAtOnce(inpw, inyw, inxw)
	Wave inpw, inyw, inxw
	//ARJN 4/2007
	Wave DataSetPointer = root:packages:MotofitGF:NewGlobalFit:DataSetPointer
	//ARJN
	Wave CoefDataSetLinkage = root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	//ARJN
	Wave/T FitFuncList = root:packages:MotofitGF:NewGlobalFit:FitFuncList
	//ARJN
	Wave SC=root:packages:MotofitGF:NewGlobalFit:ScratchCoefs
	
	Variable CoefDataSetLinkageIndex, i
	
	Variable numSets = DimSize(CoefDataSetLinkage, 0)
	for (i = 0; i < NumSets; i += 1)
		Variable firstP = CoefDataSetLinkage[i][FirstPointCol]
		Variable lastP = CoefDataSetLinkage[i][LastPointCol]

		CoefDataSetLinkageIndex = DataSetPointer[firstP]
		//ARJN
		FUNCREF MOTO_GFFitAllAtOnceTemplate theFitFunc = $(FitFuncList[CoefDataSetLinkage[CoefDataSetLinkageIndex][FuncPointerCol]])

		SC = inpw[CoefDataSetLinkage[CoefDataSetLinkageIndex][FirstCoefCol+p]]
	
		Duplicate/O/R=[firstP,lastP] inxw, TempXW, TempYW
		TempXW = inxw[p+firstP]
		SC = inpw[CoefDataSetLinkage[i][p+FirstCoefCol]]
		theFitFunc(SC, TempYW, TempXW)
		inyw[firstP, lastP] = TempYW[p-firstP]
	endfor
end

//---------------------------------------------
//  Function that actually does a global fit, independent of the GUI
//---------------------------------------------	

//ARJN
constant MOTO_GlobalFitNO_DATASETS = -1
constant MOTO_GlobalFitBAD_FITFUNC = -2
constant MOTO_GlobalFitBAD_YWAVE = -3
constant MOTO_GlobalFitBAD_XWAVE = -4
constant MOTO_GlobalFitBAD_COEFINFO = -5
constant MOTO_GlobalFitNOWTWAVE = -6
constant MOTO_GlobalFitWTWAVEBADPOINTS = -7
constant MOTO_GlobalFitNOMSKWAVE = -8
constant MOTO_GlobalFitMSKWAVEBADPOINTS = -9
constant MOTO_GlobalFitXWaveBADPOINTS = -10

//ARJN
static Function/S GF_DataSetErrorMessage(code, errorname)
	Variable code
	string errorname
	
	switch (code)
		case MOTO_GlobalFitNO_DATASETS:
			return "There are no data sets in the list of data sets."
			break
		case MOTO_GlobalFitBAD_YWAVE:
			return "The Y wave \""+errorname+"\" does not exist"
			break
		case MOTO_GlobalFitBAD_XWAVE:
			return "The X wave \""+errorname+"\" does not exist"
			break
		case MOTO_GlobalFitNOWTWAVE:
			return "The weight wave \""+errorname+"\" does not exist."
			break
		case MOTO_GlobalFitWTWAVEBADPOINTS:
			return "The weight wave \""+errorname+"\" has a different number of points than the corresponding data set wave."
			break
		case MOTO_GlobalFitNOMSKWAVE:
			return "The mask wave \""+errorname+"\" does not exist."
			break
		case MOTO_GlobalFitMSKWAVEBADPOINTS:
			return "The mask wave \""+errorname+"\" has a different number of points than the corresponding data set wave."
			break
		case MOTO_GlobalFitXWaveBADPOINTS:
			return "The X wave \""+errorname+"\" has a different number of points than the corresponding Y wave."
			break
		default:
			return "Unknown problem with data sets. Error name: "+errorname
	endswitch
end

//ARJN
constant MOTO_NewGFOptionAPPEND_RESULTS = 1
constant MOTO_NewGFOptionCALC_RESIDS = 2
constant MOTO_NewGFOptionCOV_MATRIX = 4
constant MOTO_NewGFOptionFIT_GRAPH = 8
constant MOTO_NewGFOptionQUIET = 16
constant MOTO_NewGFOptionWTISSTD = 32
constant MOTO_NewGFOptionMAKE_FIT_WAVES = 64
constant MOTO_NewGFOptionCOR_MATRIX = 128
constant MOTO_NewGFOptionLOG_DEST_WAVE = 256

//ARJN
Function MOTO_DoNewGlobalFit(FitFuncNames, DataSets, CoefDataSetLinkage, CoefWave, CoefNames, ConstraintWave, Options, FitCurvePoints, DoAlertsOnError, [errorName])
	Wave/T FitFuncNames		// a text wave containing a list of the fit functions to be used in this fit.

	Wave/T DataSets			// Wave containing a list of data sets.
	// Column 0 contains Y data sets.
	// Column 1 contains X data sets. Enter _calculated_ in a row if appropriate.
	// A column with label "Weights", if it exists, contains names of weighting waves for each dataset.
	// A column with label "Masks", if it exists, contains names of mask waves for each data set.

	Wave CoefDataSetLinkage	// a matrix wave with a row for each data set and N+2 columns, where N is the maximum number of coefficients
	// used by any of the fit functions. It looks like this for a hypothetical case of two functions and four
	// data sets:
								
	//		|	f()	first	last	N	c0	c1	c2	c3	c4	c5
	//	---|-----------------------------
	//	ds1	|	0	0		100		5	0	1	2	3	4	-1
	//	ds2	|	0	101		150		5	5	6	2	7	4	-1
	//	ds3	|	1	151		220		6	8	9	2	10	11	12
	//	ds4	|	1	221		300		6	13	14	2	15	16	12

	// In this matrix, I imagine fitting to two functions, one of which takes 5 coefficients, the other 6. 
	// Coefficients 0, 1, and 3 for function f1 are local- they have distinct coefficient array indices 
	// everywhere. Coefficient 2 is global- the same coefficient array index is used for every data set. 
	// Coefficient 4 is "shared local" (group global?)- it is global for ds1 and ds2. The corresponding 
	// coefficient for ds3 and ds4 is local- it probably refers to something entirely different. Function 
	// f1 has no coefficient 5- hence the -1. For f2, coefficient 5 is shared between the data sets (ds3 
	// and ds4) which use f2. The column labelled N is the number of coefficients needed by the fit function.
	// The column labelled f() has an index into the FitFuncNames wave.
	// These columns are set up by the function in its private copy. You can set them to zero:
	// The column labelled first contains the point number where that data set starts in the cumulative waves.
	// The column labelled last contains the point number where the last point of that data set resides in the cumulative waves
								
	Wave CoefWave				// Wave containing initial guesses. The entries in the second and greater columns of the CoefDataSetLinkage
	// wave are indices into this wave.
								
	// There is no particular order- make sure the order here and the indices in CoefDataSetLinkage are consistent.
								
	// Column 0 contains initial guesses
	// A column with label "Hold", if it exists, specifies held coefficients
	// A column with label "Epsilon", if it exists, holds epsilon values for the coefficients
								
	Wave/T/Z CoefNames		// optional text wave with same number of rows as CoefWave. Gives a name for referring to a particular
	// coefficient in coefWave. This is used only in reports to make them more readable. If you don't want to
	// use this wave, use $"" instead of wave name.

	Wave/T/Z ConstraintWave	// This constraint wave will be used straight as it comes, so K0, K1, etc. refer to the order of 
	// coefficients as laid out in CoefWave.
	// If no constraints, use $"".

	Variable Options			// 1: Append Results to Top Graph (implies option 64).
	// 2: Calculate Residuals
	// 4: Covariance Matrix
	// 8: Do Fit Graph (a graph showing the actual fit in progress)
	// 16: Quiet- No printing in History
	// 32: Weight waves contain Standard Deviation (0 means 1/SD)
	// 64: Make fit curve waves (even if option 1 is not turned on)
	// 128: Correlation matrix (implies option 4)
	// 256: Result waves should have log spacing. Generates an GFitX_ wave to go with the GFit_ destination waves.

	Variable FitCurvePoints	// number of points for auto-destination waves

	Variable DoAlertsOnError	// if 1, this function puts up alert boxes with messages about errors. These alert boxes
	// may give more information than the error code returned from the function.

	String &errorName			// Wave name that was found to be in error. Only applies to certain errors.
	

	Variable i,j
	
	String saveDF = GetDataFolder(1)
	SetDataFolder root:
	//ARJN
	NewDataFolder/O/S root:packages
	NewDataFolder/O/S root:packages:motofitgf
	NewDataFolder/O/S root:packages:motofitgf:NewGlobalFit
	
	SetDataFolder $saveDF
	
	//added by ARJN
	Variable PisLevORgen
	Variable/g  root:packages:MotofitGF:NewGlobalFit:isLevORgen		//Levenberg==0,Genetic==1
	NVAR/Z isLevORgen=root:packages:MotofitGF:NewGlobalFit:isLevORgen
	Prompt PisLevORgen,"choose Levenberg Marquardt or Genetic Optimisation",popup,"Levenberg;Genetic"
	Doprompt "choice of fitting method",PisLevORgen
	isLevORgen=PisLevORgen-1
	if(V_flag==1)
		SetDataFolder $saveDF
		abort
	endif
	
	Variable err
	Variable errorWaveRow, errorWaveColumn
	String errorWaveName
	Variable IsAllAtOnce
	
	IsAllAtOnce = GF_FunctionType(FitFuncNames[0])
	for (i = 0; i < DimSize(FitFuncNames, 0); i += 1)
		Variable functype = GF_FunctionType(FitFuncNames[i])
		if (functype == GF_FuncType_BadFunc)
			if (DoAlertsOnError)
				DoAlert 0, "The function "+FitFuncNames[i]+" is not of the proper format."
				return -1
			endif
		elseif (functype == GF_FuncType_NoFunc)
			if (DoAlertsOnError)
				DoAlert 0, "The function "+FitFuncNames[i]+" does not exist."
				return -1
			endif
		endif
		if (functype != IsAllAtOnce)
			if (DoAlertsOnError)
				DoAlert 0, "All your fit functions must be either regular fit functions or all-at-once functions. They cannot be mixed."
				return -1
			endif
		endif
	endfor
	
	//ARJN
	Duplicate/O CoefDataSetLinkage, root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Wave privateLinkage = root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Duplicate/O/T FitFuncNames, root:packages:MotofitGF:NewGlobalFit:FitFuncList
	
	Variable DoResid=0
	Variable doWeighting=0
	Variable doMasking=0
	
	DoUpdate
	err = NewGF_CheckDSets_BuildCumWaves(DataSets, privateLinkage, doWeighting, doMasking, errorWaveName, errorWaveRow, errorWaveColumn)
	DoUpdate
	if (err < 0)
		//ARJN
		if (err == MOTO_GlobalFitNO_DATASETS)
			DoAlert 0, "There are no data sets in the list of data sets."
		elseif (DoAlertsOnError)
			DoAlert 0, GF_DataSetErrorMessage(err, errorWaveName)
		endif
		if (!ParamIsDefault(errorName))
			errorName = errorWaveName
		endif
		return err
	endif
	//ARJN
	Wave Xw = root:packages:MotofitGF:NewGlobalFit:XCumData
	Wave Yw = root:packages:MotofitGF:NewGlobalFit:YCumData
	Duplicate/O YW, root:packages:MotofitGF:NewGlobalFit:FitY
	Wave FitY = root:packages:MotofitGF:NewGlobalFit:FitY
	FitY = NaN
	
	Variable MaxFuncCoefs = 0
	for (i = 0; i < DimSize(DataSets, 0); i += 1)
		MaxFuncCoefs = max(MaxFuncCoefs, privateLinkage[i][NumFuncCoefsCol])
	endfor
	//arjn
	Make/O/D/N=(MaxFuncCoefs) root:packages:MotofitGF:NewGlobalFit:ScratchCoefs
	//arjn
	Make/D/O/N=(DimSize(CoefWave, 0)) root:packages:MotofitGF:NewGlobalFit:MasterCoefs	
	//arjn
	Wave MasterCoefs = root:packages:MotofitGF:NewGlobalFit:MasterCoefs
	MasterCoefs = CoefWave[p][0]
	
	//arjn
	if (!WaveExists(CoefNames))
		Make/T/O/N=(DimSize(CoefWave, 0)) root:packages:MotofitGF:NewGlobalFit:CoefNames
		Wave/T CoefNames = root:packages:MotofitGF:NewGlobalFit:CoefNames
		// go through the matrix backwards so that the name we end up with refers to it's first use in the matrix
		for (i = DimSize(privateLinkage, 0)-1; i >= 0 ; i -= 1)
			String fname = FitFuncNames[privateLinkage[i][FuncPointerCol]]
			for (j = DimSize(privateLinkage, 1)-1; j >= FirstCoefCol; j -= 1)
				if (privateLinkage[i][j] < 0)
					continue
				endif
				CoefNames[privateLinkage[i][j]] = fname+":C"+num2istr(j-FirstCoefCol)
			endfor
		endfor
	endif
	
	String ResidString=""
	String Command=""
	
	if (Options & MOTO_NewGFOptionCALC_RESIDS)
		DoResid = 1
		ResidString="/R"
	endif
	
	//arjn
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif
	if (WinType("evolve") != 0)
		DoWindow/K evolve
	endif
	
	//arjn
	if(isLevORGen==0 ||itemsinlist(Operationlist("GENcurvefit",";","external")))			//added by ARJN
		if (options & MOTO_NewGFOptionFIT_GRAPH)	
			if (WinType("GlobalFitGraph") != 0)
				DoWindow/K GlobalFitGraph
			endif
			String SavedWindowCoords = WC_WindowCoordinatesGetStr("GlobalFitGraph", 0)
			if (strlen(SavedWindowCoords) > 0)
				Execute "Display/W=("+SavedWindowCoords+") as \"Motofit Global Analysis Progress\""
			else
				Display as "Motofit Global Analysis Progress"
			endif
			DoWindow/C GlobalFitGraph
			ColorTab2Wave Rainbow
			Wave M_colors
			Duplicate/O M_colors, root:packages:MotofitGF:NewGlobalFit:NewGF_TraceColors
			Wave colors = root:packages:MotofitGF:NewGlobalFit:NewGF_TraceColors
			Variable index = 0, size = DimSize(M_colors, 0)
			for (i = 0; i < size; i += 1)
				colors[i][] = M_colors[index][q]
				index += 37
				if (index >= size)
					index -= size
				endif
			endfor
			KillWaves/Z M_colors
			Variable nTraces = DimSize(privateLinkage, 0)
			for (i = 0; i < nTraces; i += 1)
				Variable start = privateLinkage[i][FirstPointCol]
				Variable theEnd = privateLinkage[i][LastPointCol]
				AppendToGraph Yw[start, theEnd] vs Xw[start, theEnd]
				AppendToGraph FitY[start, theEnd] vs Xw[start, theEnd]
			endfor
			DoUpdate
			for (i = 0; i < nTraces; i += 1)
				ModifyGraph mode[2*i]=2
				ModifyGraph marker[2*i]=8
				ModifyGraph lSize[2*i]=2
				ModifyGraph rgb[2*i]=(colors[i][0],colors[i][1],colors[i][2])
				ModifyGraph rgb[2*i+1]=(colors[i][0],colors[i][1],colors[i][2])
			endfor		
			ModifyGraph gbRGB=(17476,17476,17476)
			SetWindow GlobalFitGraph, hook = WC_WindowCoordinatesHook
			
			Duplicate/O Yw, root:packages:MotofitGF:NewGlobalFit:NewGF_ResidY
			ResidString = "/R=NewGF_ResidY "
			Wave rw = root:packages:MotofitGF:NewGlobalFit:NewGF_ResidY
			for (i = 0; i < nTraces; i += 1)
				start = privateLinkage[i][FirstPointCol]
				theEnd = privateLinkage[i][LastPointCol]
				AppendToGraph/L=ResidLeftAxis rw[start, theEnd] vs Xw[start, theEnd]
			endfor
			DoUpdate
			for (i = 0; i < nTraces; i += 1)
				ModifyGraph mode[2*nTraces+i]=2
				ModifyGraph rgb[2*nTraces+i]=(colors[i][0],colors[i][1],colors[i][2])
				ModifyGraph lSize[2*nTraces+i]=2
			endfor
			ModifyGraph lblPos(ResidLeftAxis)=51
			ModifyGraph zero(ResidLeftAxis)=1
			ModifyGraph freePos(ResidLeftAxis)={0,kwFraction}
			ModifyGraph axisEnab(left)={0,0.78}
			ModifyGraph axisEnab(ResidLeftAxis)={0.82,1}
		endif
	endif

	//arjn
	Duplicate/D/O MasterCoefs, root:packages:MotofitGF:NewGlobalFit:EpsilonWave
	Wave EP = root:packages:MotofitGF:NewGlobalFit:EpsilonWave
	if (FindDimLabel(CoefWave, 1, "Epsilon") == -2)
		EP = 1e-4
	else
		EP = CoefWave[p][%Epsilon]
	endif

	//arjn
	Variable quiet = ((Options & MOTO_NewGFOptionQUIET) != 0)
	if (!quiet)
		Print "*** Doing Global fit ***"
	endif
	
	//arjn
	if (Options & MOTO_NewGFOptionCOR_MATRIX)
		Options = Options | MOTO_NewGFOptionCOV_MATRIX
	endif
	
	//arjn
	String CovarianceString = ""
	if (Options & MOTO_NewGFOptionCOV_MATRIX)
		CovarianceString="/M=2"
	endif
	
	DoUpdate
	//arjn
	string funcName
	if (isAllAtOnce)
		funcName = " MOTO_NewGlblFitFuncAllAtOnce"
	else
		funcName = " MOTO_NewGlblFitFunc"
	endif
	
	Command =  "FuncFit"+CovarianceString+" "
	if (quiet)
		Command += "/Q"
	endif
	//arjn
	String/G root:packages:MotofitGF:NewGlobalFit:newGF_HoldString
	SVAR newGF_HoldString = root:packages:MotofitGF:NewGlobalFit:newGF_HoldString
	newGF_HoldString = MakeHoldString(CoefWave, quiet, 1)		// MakeHoldString() returns "" if there are no holds
	if (strlen(newGF_HoldString) > 0)
		Command += "/H=root:packages:MotofitGF:NewGlobalFit:newGF_HoldString "
	endif
	Command += funcName+", "		// MakeHoldString() returns "" if there are no holds
	Command += "MasterCoefs, "
	Command += "YCumData "
	if (isAllAtOnce)
		Command += "/X=XCumData "
	endif
	Command += "/D=FitY "
	Command += "/E=EpsilonWave"+ResidString
	if (WaveExists(ConstraintWave))
		Command += "/C="+GetWavesDataFolder(ConstraintWave, 2)
	endif
	if (doWeighting)
		Command += "/W=GFWeightWave"
		//arjn
		if (Options & MOTO_NewGFOptionWTISSTD)
			Command += "/I=1"
		endif
	endif
	SaveDF = GetDataFolder(1)
	
	//arjn
	SetDataFolder root:packages:motofitgf:NewGlobalFit
	Variable/G V_FitQuitReason, V_FitError=0
	Variable/G V_FitNumIters
	DoUpdate
	//added in by ARJN
	if(isLevORGen==0)
		//do nothing, this is Levenberg
	elseif(isLevORgen==1)    //genetic 
		funcname=funcname[1,strlen(funcname)]
		if(itemsinlist(Operationlist("GENcurvefit",";","external"))==1)
			if(strlen(newGF_HoldString)==0)
				variable ii
				for(ii=0;ii<numpnts(root:packages:MotofitGF:NewGlobalFit:MasterCoefs);ii+=1)
					newGF_HoldString+="0"
				endfor
			endif
			//get limits wave, also sets default parameters.
			GEN_setlimitsforGENcurvefit(root:packages:MotofitGF:NewGlobalFit:MasterCoefs, newGF_HoldString, getdatafolder(1))
			NVAR  iterations = root:packages:motofit:old_genoptimise:iterations
			NVAR  popsize = root:packages:motofit:old_genoptimise:popsize
			NVAR recomb =  root:packages:motofit:old_genoptimise:recomb
			NVAR k_m =  root:packages:motofit:old_genoptimise:k_m
			NVAR fittol = root:packages:motofit:old_genoptimise:fittol

			Command =  "GENcurvefit "
			if (quiet)
				Command += "/Q"
			endif
			Command += "/K={"+num2str(iterations)+","+num2str(popsize)+","+num2str(k_m)+","+num2str(recomb)+"}"
			Command += "/X=XCumData"
			Command += "/D=FitY "
			Command += residstring
			if (doWeighting)
				Command += "/W=GFWeightWave "
				if (Options & MOTO_NewGFOptionWTISSTD)
					Command += "/I=1 "
				endif
			endif

			Command += funcName+", "		// MakeHoldString() returns "" if there are no holds
			Command += "YCumData,"
			Command += "MasterCoefs,"
			Command += "root:packages:MotofitGF:NewGlobalFit:newGF_HoldString,"
			Command += "root:packages:motofit:old_genoptimise:GENcurvefitlimits"
		else
			doalert 0, "please install the gencurvefitXOP first"
			return 0
		endif
		make/o/n=(numpnts(mastercoefs)) W_Sigma = 0
	endif
	print command
	Execute Command
		
	NVAR/Z V_chisq
	NVAR/Z fit_npnts = V_npnts
	NVAR/Z fit_numNaNs = V_numNaNs
	NVAR/Z fit_numINFs = V_numINFs
	SetDataFolder $SaveDF
	
	if (V_FitError)
		if (!quiet)
			if (V_FitError & 2)
				DoAlert 0, "Global fit stopped due to a singular matrix error."
			elseif (V_FitError & 4)
				DoAlert 0, "Global fit stopped due to a out of memory error."
			elseif (V_FitError & 8)
				DoAlert 0, "Global fit stopped because one of your fitting functions returned NaN or INF."
			endif
		endif
		return V_FitError
	endif
	
	if (!quiet)
		switch(V_FitQuitReason)
			case 0:
				print "Global Fit converged normally."
				break;
			case 1:
				print "Global Fit stopped because the limit of iterations was reached."
				break;
			case 2:
				print "Global Fit stopped because the limit of iterations with no decrease in chi-square was reached."
				break;
			case 3:
				print "Hmm... Global Fit stopped for an unknown reason."
		endswitch
	endif
	
	if (isLevORgen==0)		////extra bit added ARJN
		if (Options & MOTO_NewGFOptionCOV_MATRIX)		
			//		Wave M_Covar
			Wave M_Covar = root:packages:MotofitGF:NewGlobalFit:M_covar
			if (Options & MOTO_NewGFOptionCOR_MATRIX)
				Duplicate/O M_Covar, M_Correlation
				M_Correlation = M_Covar[p][q]/sqrt(M_Covar[p][p]*M_Covar[q][q])
			endif
		endif
	endif
	
	CoefWave[][0] = MasterCoefs[p]
	Duplicate/O MasterCoefs, GlobalFitCoefficients
	

	if (!quiet)
		Print "\rGlobal fit results"
		if(V_FitError)
			print "\tFit stopped due to an error:"
			if (V_FitError & 2)
				print "\t\tSingular matrix error"
			endif
			if (V_FitError & 4)
				print "\t\tOut of memory"
			endif
			if (V_FitError & 8)
				print "\t\tFit function returned NaN or Inf"
			endif
		else
			switch (V_FitQuitReason)
				case 0:
					print "\tFit converged normally"
					break;
				case 1:
					print "\tFit exceeded limit of iterations"
					break;
				case 2:
					print "\tFit stopped because the user cancelled the fit"
					break;
				case 3:
					print "\tFit stopped due to limit of iterations with no decrease in chi-square"
					break;
			endswitch
		endif
		print "V_chisq =",V_chisq,"V_npnts=",fit_npnts, "V_numNaNs=", fit_numNaNs, "V_numINFs=",fit_numINFs
		print "Number of iterations:",V_FitNumIters 
		// and print the coefficients by data set into the history
		Variable numRows = DimSize(privateLinkage, 0)
		Variable numCols = DimSize(privateLinkage, 1)
		Variable firstUserow, firstUsecol, linkIndex
		Wave W_sigma = root:packages:MotofitGF:NewGlobalFit:W_sigma
		for (i = 0; i < numRows; i += 1)
			print "Data Set: ",DataSets[i][0]," vs ",DataSets[i][1],"; Function: ",FitFuncNames[privateLinkage[i][FuncPointerCol]]
			for (j = FirstCoefCol; j < (privateLinkage[i][NumFuncCoefsCol] + FirstCoefCol); j += 1)
				linkIndex = privateLinkage[i][j]
				
				FirstUseOfIndexInLinkMatrix(linkIndex, privateLinkage, firstUserow, firstUsecol)
				printf "\t%d\t%s\t%g +- %g", j-FirstCoefCol, CoefNames[privateLinkage[i][j]], MasterCoefs[privateLinkage[i][j]], W_sigma[privateLinkage[i][j]]
				if (CoefWave[privateLinkage[i][j]][%Hold])
					printf " *HELD* "
				endif
				if ( (firstUserow != i) || (firstUseCol != j) )
					printf " ** LINKED to data set %s coefficient %d: %s", DataSets[firstUserow][0], firstUseCol-FirstCoefCol, CoefNames[privateLinkage[i][j]]
				endif
				print "\r"
			endfor
		endfor
	endif

	if (FitCurvePoints == 0)
		FitCurvePoints = 200
	endif
	//arjn
	if (options & MOTO_NewGFOptionAPPEND_RESULTS)
		options = options | MOTO_NewGFOptionMAKE_FIT_WAVES
	endif
	
	//arjn
	if (options & MOTO_NewGFOptionCALC_RESIDS)
		options = options | MOTO_NewGFOptionMAKE_FIT_WAVES
	endif
	
	//arjn
	if ( (options & MOTO_NewGFOptionMAKE_FIT_WAVES) || (options & MOTO_NewGFOptionCALC_RESIDS) )
		Wave/Z fitxW = root:packages:MotofitGF:NewGlobalFit:fitXCumData
		if (WaveExists(fitxW))
			KillWaves fitxW
		endif
		Rename xW, fitXCumData
		//arjn
		Wave/Z fitxW = root:packages:MotofitGF:NewGlobalFit:fitXCumData
		Duplicate/O Yw, fitYCumData	
		String ListOfFitCurveWaves = ""
	
		for (i = 0; i < DimSize(DataSets, 0); i += 1)
			String YFitSet = DataSets[i][0]
			
			// copy coefficients for each data set into a separate wave
			Wave YFit = $YFitSet
			saveDF = GetDatafolder(1)
			SetDatafolder $GetWavesDatafolder(YFit, 1)
			String YWaveName = NameOfWave(YFit)
			if (CmpStr(YWaveName[0], "'") == 0)
				YWaveName = YWaveName[1, strlen(YWaveName)-2]
			endif
			// this is a good thing, but doesn't belong here. Individual coefficient waves should be made above
			String coefname = CleanupName("Coef_"+YWaveName, 0)
			Make/D/O/N=(privateLinkage[i][NumFuncCoefsCol]) $coefname
			Wave w = $coefname
			w = MasterCoefs[privateLinkage[i][p+FirstCoefCol]]
			
			//arjn
			if (options & MOTO_NewGFOptionMAKE_FIT_WAVES)
				String fitCurveName = CleanupName("GFit_"+YWaveName, 0)
				Make/D/O/N=(FitCurvePoints) $fitCurveName
				Wave fitCurveW = $fitCurveName
				Variable minX, maxX
				WaveStats/Q/R=[privateLinkage[i][FirstPointCol], privateLinkage[i][LastPointCol]] fitxW
				minX = V_min
				maxX = V_max
				//arjn
				if (options & MOTO_NewGFOptionLOG_DEST_WAVE)
					String fitCurveXName = CleanupName("GFitX_"+YWaveName, 0)
					Duplicate/O fitCurveW, $fitCurveXName
					Wave  fitCurveXW = $fitCurveXName
					
					Variable logXMin = ln(minX)
					Variable logXMax = ln(maxX)
					Variable logXInc = (logXMax - logXMin)/(FitCurvePoints-1)
					
					// if there's something wrong with the X range, there will be inf or nan in one of these numbers
					if ( (numtype(logXMin) != 0) || (numtype(logXMax) != 0) || (numtype(logXInc) != 0) )
						// something wrong- cancel the log spacing option
						options = options & ~MOTO_NewGFOptionLOG_DEST_WAVE
					else
						// it's OK- go ahead with log spacing
						fitCurveXW = exp(logXMin+p*logXInc)
					
						// make auxiliary waves required by the fit function
						// so that we can use the fit function in an assignment
						//arjn
						Duplicate/O fitCurveXW, root:packages:MotofitGF:NewGlobalFit:XCumData
						Wave xw = root:packages:MotofitGF:NewGlobalFit:XCumData
					endif
				endif
				// check this again in case the it was set but cancelled due to bad numbers
				//arjn
				if (!(options & MOTO_NewGFOptionLOG_DEST_WAVE))
					SetScale/I x minX, maxX, fitCurveW
				
					// make auxiliary waves required by the fit function
					// so that we can use the fit function in an assignment
					//arjn
					Duplicate/O fitCurveW, root:packages:MotofitGF:NewGlobalFit:XCumData
					Wave xw = root:packages:MotofitGF:NewGlobalFit:XCumData
					xw = x
				endif
				
				//arjn
				Duplicate/O fitCurveW, root:packages:MotofitGF:NewGlobalFit:DataSetPointer
				Wave dspw = root:packages:MotofitGF:NewGlobalFit:DataSetPointer
				dspw = i
				
				Duplicate/O privateLinkage, copyOfLinkage
				//arjn
				Make/O/D/N=(1,DimSize(copyOfLinkage, 1)) root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				Wave tempLinkage = root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				tempLinkage = copyOfLinkage[i][q]
				tempLinkage[0][FirstPointCol] = 0
				tempLinkage[0][LastPointCol] = FitCurvePoints-1
				//arjn
				if (IsAllAtOnce)
					MOTO_NewGlblFitFuncAllAtOnce(MasterCoefs, fitCurveW, xw)
				else
					MOTO_NewGlblFitFunc(MasterCoefs, fitCurveW, xw)
				endif
				//arjn
				Duplicate/O copyOfLinkage, root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				
				//arjn
				if (options & MOTO_NewGFOptionAPPEND_RESULTS)
					String graphName = FindGraphWithWave(YFit)
					if (strlen(graphName) > 0)
						CheckDisplayed/W=$graphName fitCurveW
						if (V_flag == 0)
							String axisflags = StringByKey("AXISFLAGS", TraceInfo(graphName, YFitSet, 0))
							//arjn
							if (options & MOTO_NewGFOptionLOG_DEST_WAVE)
								String AppendCmd = "AppendToGraph/W="+graphName+axisFlags+" "+fitCurveName+" vs "+fitCurveXName
							else
								AppendCmd = "AppendToGraph/W="+graphName+axisFlags+" "+fitCurveName
							endif
							Execute AppendCmd
						endif
					endif
				endif
			endif
			
			if (options & MOTO_NewGFOptionCALC_RESIDS)
				String resCurveName = CleanupName("GRes_"+YWaveName, 0)
				Make/D/O/N=(numpnts(YFit)) $resCurveName
				Wave resCurveW = $resCurveName
				Wave/Z XFit = $(DataSets[i][1])
				
				// make auxiliary waves required by the fit function
				// so that we can use the fit function in an assignment
				//arjn
				Duplicate/O resCurveW, root:packages:MotofitGF:NewGlobalFit:XCumData
				Wave xw = root:packages:MotofitGF:NewGlobalFit:XCumData
				if (WaveExists(XFit))
					xw = XFit
				else
					xw = pnt2x(YFit, p)
				endif
				
				//arjn
				Duplicate/O resCurveW, root:packages:MotofitGF:NewGlobalFit:DataSetPointer
				Wave dspw = root:packages:MotofitGF:NewGlobalFit:DataSetPointer
				dspw = i
				
				//if (IsAllAtOnce)
				Duplicate/O privateLinkage, copyOfLinkage
				//arjn
				Make/O/D/N=(1,DimSize(copyOfLinkage, 1)) root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				Wave tempLinkage = root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				tempLinkage = copyOfLinkage[i][q]
				tempLinkage[0][FirstPointCol] = 0
				tempLinkage[0][LastPointCol] = FitCurvePoints-1
				//arjn
				if (IsAllAtOnce)
					MOTO_NewGlblFitFuncAllAtOnce(MasterCoefs, resCurveW, xw)
				else
					MOTO_NewGlblFitFunc(MasterCoefs, resCurveW, xw)
				endif
				resCurveW = YFit[p] - resCurveW[p]
				//arjn
				Duplicate/O copyOfLinkage, root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				//else
				//	resCurveW = YFit[p] - NewGlblFitFunc(MasterCoefs, p)
				//endif
			endif
			
			SetDataFolder $saveDF	
		endfor
	endif
	
	return 0
end

static constant GF_FuncType_Regular = 0
static constant GF_FuncType_AllAtOnce = 1
static constant GF_FuncType_BadFunc = -1
static constant GF_FuncType_NoFunc = -2

static Function GF_FunctionType(functionName)
	String functionName
	
	Variable FuncType = GF_FuncType_BadFunc
	
	string FitFuncs = FunctionList("*", ";", "NPARAMS:2;VALTYPE:1")
	if (FindListItem(functionName, FitFuncs) >= 0)
		FuncType = GF_FuncType_Regular
	else
		FitFuncs = FunctionList("*", ";", "NPARAMS:3;VALTYPE:1")
		if (FindListItem(functionName, FitFuncs) >= 0)
			FuncType = GF_FuncType_AllAtOnce
		endif
	endif
	
	if (FuncType == GF_FuncType_BadFunc)
		Variable funcExists = Exists(functionName)
		if ((funcExists != 6) && (funcExists != 3) )
			FuncType = GF_FuncType_NoFunc
		endif
	endif
	return FuncType
end

static Function FirstUseOfIndexInLinkMatrix(index, linkMatrix, row, col)
	Variable index
	Wave linkMatrix
	Variable &row
	Variable &col
	
	Variable i, j
	Variable numRows = DimSize(linkMatrix, 0)
	Variable numCols = DimSize(linkMatrix, 1)
	for (i = 0; i < numRows; i += 1)
		for (j = FirstCoefCol; j < numCols; j += 1)
			if (linkMatrix[i][j] == index)
				row = i
				col = j
				return 0
			endif
		endfor
	endfor
	
	row = -1
	col = -1
	return -1
end

// Checks list of data sets for consistency, etc.
// Makes the cumulative data set waves.
static Function NewGF_CheckDSets_BuildCumWaves(DataSets, linkageMatrix, doWeighting, doMasking, errorWaveName, errorWaveRow, errorWaveColumn)
	Wave/T DataSets
	Wave linkageMatrix
	Variable &doWeighting
	Variable &doMasking
	String &errorWaveName
	Variable &errorWaveRow
	Variable &errorWaveColumn
	
	errorWaveName = ""

	Variable i, j
	String XSet, YSet
	Variable numSets = DimSize(DataSets, 0)
	Variable wavePoints
	Variable npnts
	
	if (numSets == 0)
		return 0
	endif
	
	Variable totalPoints = 0
	
	Variable MaskCol = FindDimLabel(DataSets, 1, "Masks")
	doMasking = 0
	if (MaskCol >= 0)
		//		Make/D/N=(totalPoints)/O root:packages:MotofitGF:NewGlobalFit:GFMaskWave
		doMasking = 1
	endif

	doWeighting = 0
	Variable WeightCol = FindDimLabel(DataSets, 1, "Weights")
	if (WeightCol >= 0)
		//		Make/D/N=(totalPoints)/O root:packages:MotofitGF:NewGlobalFit:GFWeightWave
		doWeighting = 1
	endif
	
	// pre-scan to find the total number of points. This is done so that the concatenated wave
	// can be made at the final size all at one time, avoiding problems with virtual memory
	// that can be caused by re-sizing a memory block many times.
	
	// JW 040818 Failing to check for NaN's in the data waves causes a failure of synchronization between
	// the data structures and the data passed to the fit function by FuncFit. I will have to check for NaN's
	// and not include them.
	// I am removing the check for masked points in this loop. If there are masked points or NaN's, the wave
	// will be too big and will be reduced at the end. However, I will do a check here for bad wave names or bad numbers of
	// points so that I don't have to clutter up the second loop with checks.
	for (i = 0; i < numSets; i += 1)
		// check the Y wave
		YSet = DataSets[i][0]
		XSet = DataSets[i][1]
		Wave/Z Ysetw = $YSet
		Wave/Z Xsetw = $XSet
		if (!WaveExists(YSetw))
			errorWaveName = YSet
			errorWaveRow = i
			errorWaveColumn = 0
			//arjn
			return MOTO_GlobalFitBAD_YWAVE
		endif
		wavePoints = numpnts(Ysetw)
		
		// check the X wave
		if (cmpstr(XSet, "_Calculated_") != 0)
			if (!WaveExists(Xsetw)) 
				errorWaveName = XSet
				errorWaveRow = i
				errorWaveColumn = 1
				//arjn
				return MOTO_GlobalFitBAD_XWAVE
			endif
			if (wavePoints != numpnts(Xsetw))
				errorWaveRow = i
				errorWaveColumn = 1
				//arjn
				return MOTO_GlobalFitXWaveBADPOINTS
			endif
		endif		
		
		// check mask wave if necessary
		if (doMasking)
			Wave/Z mw = $(DataSets[i][MaskCol])
			if (!WaveExists(mw))
				errorWaveRow = i
				errorWaveColumn = MaskCol
				//arjn
				return MOTO_GlobalFitNOMSKWAVE
			endif
			if (wavePoints != numpnts(mw))
				errorWaveRow = i
				errorWaveColumn = MaskCol
				//arjn
				return MOTO_GlobalFitMSKWAVEBADPOINTS
			endif
		endif
		
		// check weighting wave if necessary
		if (doWeighting)
			Wave/Z ww = $(DataSets[i][WeightCol])
			if (!WaveExists(ww))
				errorWaveRow = i
				errorWaveColumn = WeightCol
				//arjn
				return MOTO_GlobalFitNOWTWAVE
			endif
			if (wavePoints != numpnts(ww))
				errorWaveRow = i
				errorWaveColumn = WeightCol
				//arjn
				return MOTO_GlobalFitWTWAVEBADPOINTS
			endif
		endif

		totalPoints += numpnts(Ysetw)
	endfor
	
	if (doWeighting)
		//arjn
		Make/D/N=(totalPoints)/O root:packages:MotofitGF:NewGlobalFit:GFWeightWave
	endif

	// make the waves that will contain the concatenated data sets and the wave that points
	// to the appropriate row in the data set linkage matrix
	//arjn
	Make/D/N=(totalPoints)/O root:packages:MotofitGF:NewGlobalFit:XCumData, root:packages:MotofitGF:NewGlobalFit:YCumData
	Make/U/W/N=(totalPoints)/O root:packages:MotofitGF:NewGlobalFit:DataSetPointer
	
	Wave Xw = root:packages:MotofitGF:NewGlobalFit:XCumData
	Wave Yw = root:packages:MotofitGF:NewGlobalFit:YCumData
	Wave DataSetPointer = root:packages:MotofitGF:NewGlobalFit:DataSetPointer
	Wave/Z Weightw = root:packages:MotofitGF:NewGlobalFit:GFWeightWave
	//	Wave/Z Maskw = root:packages:MotofitGF:NewGlobalFit:GFMaskWave
	
	Variable realTotalPoints = 0
	Variable wavePoint = 0

	// second pass through the list, this time copying the data into the concatenated sets, and
	// setting index numbers in the index wave
	for (i = 0; i < numSets; i += 1)
		YSet = DataSets[i][0]
		XSet = DataSets[i][1]
		Wave/Z Ysetw = $YSet
		Wave/Z Xsetw = $XSet
		Wave/Z mw = $(DataSets[i][MaskCol])
		Wave/Z ww = $(DataSets[i][WeightCol])

		wavePoints = numpnts(Ysetw)
		for (j = 0; j < wavePoints; j += 1)
			if (numtype(Ysetw[j]) != 0)
				continue
			endif
			
			if (doMasking)
				if ( (numtype(mw[j]) != 0) || (mw[j] == 0) )
					continue
				endif
			endif
			
			if (doWeighting)
				if ( (numtype(ww[j]) != 0) || (ww[j] == 0) )
					continue
				endif
			endif
			
			DataSetPointer[wavePoint] = i
			
			Yw[wavePoint] = Ysetw[j]

			if (cmpstr(XSet, "_Calculated_") == 0)
				Xw[wavePoint] = pnt2x(Ysetw, j)
			else
				if (numtype(Xsetw[j]) != 0)
					continue
				endif
				Xw[wavePoint] = Xsetw[j]
			endif
			
			if (doWeighting)
				Weightw[wavePoint] = ww[j]
			endif
			
			wavePoint += 1
		endfor
		
		linkageMatrix[i][FirstPointCol] = realTotalPoints
		linkageMatrix[i][LastPointCol] = wavePoint-1
		realTotalPoints = wavePoint
	endfor
	
	if (totalPoints > realTotalPoints)
		Redimension/N=(realTotalPoints) Yw, Xw
		if (doWeighting)
			Redimension/N=(realTotalPoints) Weightw
		endif			
	endif
	
	return numSets
end

//********************
//	The GUI part
//********************

static Function InitNewGlobalFitGlobals()
	
	String saveFolder = GetDataFolder(1)
	
	NewDataFolder/O/S root:packages
	NewDataFolder/O/S root:packages:motofitgf
	NewDataFolder/O/S root:packages:motofitgf:NewGlobalFit
	
	Make/O/T/N=(1,4,2) NewGF_DataSetListWave = ""
	SetDimLabel 1, 0, 'Y Waves', NewGF_DataSetListWave
	SetDimLabel 1, 1, 'X Waves', NewGF_DataSetListWave
	SetDimLabel 1, 2, Function, NewGF_DataSetListWave
	SetDimLabel 1, 3, '# Coefs', NewGF_DataSetListWave
	
	Make/O/T/N=(1,1,2) NewGF_MainCoefListWave = ""
	SetDimLabel 1, 0, 'Coefs- K0', NewGF_MainCoefListWave

	Make/O/N=(1,4,2) NewGF_DataSetListSelWave = 0	

	Make/O/N=(1,1,2) NewGF_MainCoefListSelWave = 0
	SetDimLabel 2, 1, backColors, NewGF_MainCoefListSelWave
	ColorTab2Wave Pastels
	Wave M_colors
	Duplicate/O M_colors, NewGF_LinkColors
	Variable i, index = 0, size = DimSize(M_colors, 0)
	for (i = 0; i < size; i += 1)
		NewGF_LinkColors[i][] = M_colors[index][q]
		index += 149
		if (index >= size)
			index -= size
		endif
	endfor
	KillWaves/Z M_colors
	
	Make/O/T/N=(1,5) NewGF_CoefControlListWave = ""
	Make/O/N=(1,5) NewGF_CoefControlListSelWave
	SetDimLabel 1, 0, 'Data Set', NewGF_CoefControlListWave
	SetDimLabel 1, 1, Name, NewGF_CoefControlListWave
	SetDimLabel 1, 2, 'Initial Guess', NewGF_CoefControlListWave
	SetDimLabel 1, 3, 'Hold?', NewGF_CoefControlListWave
	SetDimLabel 1, 4, Epsilon, NewGF_CoefControlListWave
	NewGF_CoefControlListSelWave[][3] = 0x20
	
	Variable/G NewGF_RebuildCoefListNow = 1
	
	Variable points = NumVarOrDefault("FitCurvePoints", 200)
	Variable/G FitCurvePoints = points
	
	String setupName = StrVarOrDefault("NewGF_NewSetupName", "NewGlobalFitSetup")
	String/G NewGF_NewSetupName = setupName

	SetDataFolder $saveFolder
end

static Function InitNewGlobalFitPanel()
	//arjn
	if (wintype("MotoGlobalFitPanel") == 0)
		InitNewGlobalFitGlobals()
		fNewGlobalFitPanel()
	else
		DoWindow/F MotoGlobalFitPanel
	endif
end
//arjn
static Function UnloadNewGlobalFit()
	if (WinType("MotoGlobalFitPanel") == 7)
		DoWindow/K MotoGlobalFitPanel
	endif
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif
	if (WinType("NewGF_GlobalFitConstraintPanel"))
		DoWindow/K NewGF_GlobalFitConstraintPanel
	endif
	if (WinType("NewGF_WeightingPanel"))
		DoWindow/K NewGF_WeightingPanel
	endif
	if (WinType("NewGF_GlobalFitMaskingPanel"))
		DoWindow/K NewGF_GlobalFitMaskingPanel
	endif
	Execute/P "COMPILEPROCEDURES "
	//arjn
	KillDataFolder root:packages:MotofitGF:NewGlobalFit
end

static constant NewGF_DSList_YWaveCol = 0
static constant NewGF_DSList_XWaveCol = 1
static constant NewGF_DSList_FuncCol = 2
static constant NewGF_DSList_NCoefCol = 3

// moved to separate wave
//static constant NewGF_DSList_FirstCoefCol = 4
static constant NewGF_DSList_FirstCoefCol = 0

static Function fNewGlobalFitPanel()

	Variable defLeft = 50
	Variable defTop = 70
	Variable defRight = 719
	Variable defBottom = 447
	//arjn
	String fmt="NewPanel/K=1/W=(%s) as \"Motofit Global Analysis\""
	//arjn	
	String cmd = WC_WindowCoordinatesSprintf("MotoGlobalFitPanel", fmt, defLeft, defTop, defRight, defBottom, 0)
	Execute cmd
	//arjn
	//	NewPanel/K=1/W=(156,70,829,443) as "Motofit Global Analysis"
	DoWindow/C MotoGlobalFitPanel

	DefineGuide Tab0AreaLeft={FL,13}			// this is changed to FR, 25 when tab 0 is hidden
	DefineGuide Tab0AreaRight={FR,-10}
	DefineGuide TabAreaTop={FT,28}
	DefineGuide TabAreaBottom={FB,-118}
	DefineGuide Tab1AreaLeft={FR,25}			// this is changed to FL and appropriate offset when tab 1 is shown
	DefineGuide Tab1AreaRight={FR,800}
	DefineGuide GlobalControlAreaTop={FB,-109}
	//arjn
	TabControl NewGF_TabControl,pos={10,7},size={654,255},proc=MOTO_WM_NewGlobalFit1#NewGF_TabControlProc
	TabControl NewGF_TabControl,tabLabel(0)="Data Sets and Functions"
	TabControl NewGF_TabControl,tabLabel(1)="Coefficient Control",value= 0
	
	NewPanel/FG=(Tab0AreaLeft, TabAreaTop, Tab0AreaRight, TabAreaBottom) /HOST=#
	RenameWindow #,Tab0ContentPanel
	ModifyPanel frameStyle=0, frameInset=0
	
	//		ListBox NewGF_DataSetsList,pos={3,133},size={443,196}, listWave=root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	//		ListBox NewGF_DataSetsList,selWave=root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave,proc=MOTO_WM_NewGlobalFit1#NewGF_DataSetListBoxProc
	//		ListBox NewGF_DataSetsList,widths={100,100,100,50,90}, mode=10,editStyle=1,frame=4, colorWave = root:packages:MotofitGF:NewGlobalFit:NewGF_LinkColors
		
	GroupBox NewGF_DataSetsGroup,pos={2,3},size={640,36}
	
	TitleBox NewGF_DataSetsGroupTitle,pos={23,14},size={57,12},title="Data Sets:",fSize=10,frame=0
	TitleBox NewGF_DataSetsGroupTitle,fStyle=1
	//arjn
	PopupMenu NewGF_AddDataSetMenu,pos={88,11},size={120,20},proc=MOTO_WM_NewGlobalFit1#MOTO_NewGF_AddYWaveMenuProc,title="Add Data Sets"
	PopupMenu NewGF_AddDataSetMenu,mode=0,bodyWidth= 120,value= #"MOTO_NewGF_YWaveList(1)"

	PopupMenu NewGF_SetDataSetMenu,pos={370,11},size={120,20},proc=MOTO_WM_NewGlobalFit1#NewGF_SetDataSetMenuProc,title="Set Y Wave"
	PopupMenu NewGF_SetDataSetMenu,mode=0,bodyWidth= 120,value= #"MOTO_NewGF_YWaveList(0)"

	PopupMenu NewGF_SetXDataSetMenu,pos={229,11},size={120,20},proc=MOTO_WM_NewGlobalFit1#NewGF_SetXWaveMenuProc,title="Set X Wave"
	PopupMenu NewGF_SetXDataSetMenu,mode=0,bodyWidth= 120,value= #"MOTO_NewGF_XWaveList()"

	PopupMenu NewGF_RemoveDataSetMenu1,pos={512,11},size={120,20},proc=MOTO_WM_NewGlobalFit1#NewGF_RemoveDataSetsProc,title="Remove"
	PopupMenu NewGF_RemoveDataSetMenu1,mode=0,bodyWidth= 120,value= #"MOTO_NewGF_RemoveMenuList()"

	PopupMenu NewGF_SetFunctionMenu,pos={7,51},size={120,20},proc=MOTO_NewGF_SetFuncMenuProc,title="Choose Fit Func"
	PopupMenu NewGF_SetFunctionMenu,mode=0,bodyWidth= 120,value= #"MOTO_NewGF_FitFuncList()"

	GroupBox NewGF_CoefficientsGroup,pos={134,43},size={508,36}

	TitleBox NewGF_Tab0CoefficientsTitle,pos={145,54},size={73,12},title="Coefficients:"
	TitleBox NewGF_Tab0CoefficientsTitle,fSize=10,frame=0,fStyle=1

	//arjn
	Button NewGF_LinkCoefsButton,pos={224,51},size={70,20},proc=Moto_NEWGF_LinkCoefsButtonProc,title="Link"
	//arjn
	Button NewGF_UnLinkCoefsButton,pos={301,51},size={70,20},proc=MOTO_UnLinkCoefsButtonProc,title="Unlink"
	//arjn
	PopupMenu NewGF_SelectAllCoefMenu,pos={378,51},size={124,20},proc=MOTO_WM_NewGlobalFit1#NewGF_SelectAllCoefMenuProc,title="Select"
	PopupMenu NewGF_SelectAllCoefMenu,mode=0,bodyWidth= 124,value= #"MOTO_WM_NewGlobalFit1#NewGF_ListFunctionsAndCoefs()"
	//arjn
	PopupMenu NewGF_SelectAlsoCoefMenu,pos={509,51},size={124,20},proc=MOTO_WM_NewGlobalFit1#NewGF_SelectAllCoefMenuProc,title="Add To Selection"
	PopupMenu NewGF_SelectAlsoCoefMenu,mode=0,bodyWidth= 124,value= #"MOTO_WM_NewGlobalFit1#NewGF_ListFunctionsAndCoefs()"

	GroupBox NewGF_Tab0ListGroup,pos={2,86},size={641,143}

	ListBox NewGF_DataSetsList,pos={4,88},size={300,139},proc=MOTO_WM_NewGlobalFit1#NewGF_DataSetListBoxProc
	ListBox NewGF_DataSetsList,listWave=root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	ListBox NewGF_DataSetsList,selWave=root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	ListBox NewGF_DataSetsList,mode= 10,editStyle= 1,widths= {81,81,81,42},frame=1,userColumnResize=1
	
	ListBox NewGF_Tab0CoefList,pos={305,88},size={336,139},proc=MOTO_WM_NewGlobalFit1#NewGF_DataSetListBoxProc
	ListBox NewGF_Tab0CoefList,listWave=root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	ListBox NewGF_Tab0CoefList,selWave=root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	ListBox NewGF_Tab0CoefList,colorWave=root:packages:MotofitGF:NewGlobalFit:NewGF_LinkColors
	ListBox NewGF_Tab0CoefList,mode= 10,editStyle= 1,widths= {100},frame=1,userColumnResize=1

	SetActiveSubwindow ##
	
	NewPanel/W=(119,117,359,351)/FG=(Tab1AreaLeft,TabAreaTop,Tab1AreaRight,TabAreaBottom)/HOST=# 
	RenameWindow #, Tab1ContentPanel
	ModifyPanel frameStyle=0, frameInset=0
		
	ListBox NewGF_CoefControlList,pos={4,34},size={440,291},proc = moto_WM_NewGlobalFit1#NewGF_CoefListBoxProc,frame=4
	ListBox NewGF_CoefControlList,listWave=root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	ListBox NewGF_CoefControlList,selWave=root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	ListBox NewGF_CoefControlList,mode= 10,editStyle= 1,widths= {15,15,7,4,5},userColumnResize=1
		
	TitleBox NewGF_CoefControlIGTitle,pos={135,9},size={75,15},title="Initial guess:"
	TitleBox NewGF_CoefControlIGTitle,fSize=12,frame=0,anchor= RC

	PopupMenu NewGF_SetCoefsFromWaveMenu,pos={219,7},size={100,20},title="Set from Wave",mode=0,value=MOTO_ListInitGuessWaves(0, 0)
	PopupMenu NewGF_SetCoefsFromWaveMenu,proc=MOTO_NewGF_SetCoefsFromWaveProc

	PopupMenu NewGF_SaveCoefstoWaveMenu,pos={343,7},size={100,20},title="Save to Wave",mode=0,value="New Wave...;-;"+MOTO_ListInitGuessWaves(0, 0)
	PopupMenu NewGF_SaveCoefstoWaveMenu,proc=MOTO_NewGF_SaveCoefsToWaveProc

	SetActiveSubwindow ##
	
	DefineGuide GlobalControlAreaLeft={FR,-200}

	NewPanel/W=(495,313,643,351)/FG=(FL,GlobalControlAreaTop,FR,FB)/HOST=# 
	ModifyPanel frameStyle=0, frameInset=0
	RenameWindow #,NewGF_GlobalControlArea
	
	GroupBox NewGF_GlobalGroup,pos={5,3},size={478,101}

	CheckBox NewGF_ConstraintsCheckBox,pos={330,49},size={79,14},proc=MOTO_WM_NewGlobalFit1#ConstraintsCheckProc,title="Constraints..."
	CheckBox NewGF_ConstraintsCheckBox,value= 0
	
	CheckBox NewGF_WeightingCheckBox,pos={330,11},size={70,14},proc=MOTO_WM_NewGlobalFit1#NewGF_WeightingCheckProc,title="Weighting..."
	CheckBox NewGF_WeightingCheckBox,value= 0
	
	CheckBox NewGF_MaskingCheckBox,pos={330,30},size={63,14},proc=MOTO_WM_NewGlobalFit1#NewGF_MaskingCheckProc,title="Masking..."
	CheckBox NewGF_MaskingCheckBox,value= 0
	
	CheckBox NewGF_DoCovarMatrix,pos={190,49},size={102,14},proc=MOTO_WM_NewGlobalFit1#NewGF_CovMatrixCheckProc,title="Covariance Matrix"
	CheckBox NewGF_DoCovarMatrix,value= 1
	
	CheckBox NewGF_CorrelationMatrixCheckBox,pos={212,69},size={103,14},proc=MOTO_WM_NewGlobalFit1#NewGF_CorMatrixCheckProc,title="Correlation Matrix"
	CheckBox NewGF_CorrelationMatrixCheckBox,value= 1
	
	CheckBox NewGF_MakeFitCurvesCheck,pos={12,11},size={118,14},proc=MOTO_WM_NewGlobalFit1#NewGF_FitCurvesCheckProc,title="Make Fit Curve Waves"
	CheckBox NewGF_MakeFitCurvesCheck,value= 1
	
	CheckBox NewGF_AppendResultsCheckbox,pos={34,30},size={143,14},proc=MOTO_WM_NewGlobalFit1#NewGF_AppendResultsCheckProc,title="And Append Them to Graphs"
	CheckBox NewGF_AppendResultsCheckbox,value= 1
	
	CheckBox NewGF_DoResidualCheck,pos={34,69},size={104,14},proc=MOTO_WM_NewGlobalFit1#NewGF_CalcResidualsCheckProc,title="Calculate Residuals"
	CheckBox NewGF_DoResidualCheck,value= 1
	
	CheckBox NewGF_DoDestLogSpacingCheck,pos={34,86},size={108,14},title="Logarithmic Spacing"
	CheckBox NewGF_DoDestLogSpacingCheck,value=0

	SetVariable NewGF_SetFitCurveLength,pos={37,49},size={131,15},title="Fit Curve Points:"
	SetVariable NewGF_SetFitCurveLength,limits={2,inf,1},value= root:packages:MotofitGF:NewGlobalFit:FitCurvePoints,bodyWidth= 50
	
	CheckBox NewGF_Quiet,pos={190,30},size={98,14},title="No History Output"
	CheckBox NewGF_Quiet,value=0
	
	CheckBox NewGF_FitProgressGraphCheckBox,pos={190,11},size={103,14},title="Fit Progress Graph"
	CheckBox NewGF_FitProgressGraphCheckBox,value= 1
	
	Button DoFitButton,pos={421,10},size={50,20},proc=MOTO_WM_NewGlobalFit1#NewGF_DoTheFitButtonProc,title="Fit!"
	Button DoSimButton,pos={421,40},size={50,20},proc=MOTO_WM_NewGlobalFit1#NewGF_DoTheFitButtonProc,title="Simulate"

	GroupBox NewGF_SaveSetupGroup,pos={487,3},size={178,101},title="Setup"

	SetVariable NewGF_SaveSetSetName,pos={496,20},size={162,15},title="Name:"
	SetVariable NewGF_SaveSetSetName,value= root:packages:MotofitGF:NewGlobalFit:NewGF_NewSetupName,bodyWidth= 130
	
	CheckBox NewGF_StoredSetupOverwriteOKChk,pos={508,39},size={80,14},title="Overwrite OK"
	CheckBox NewGF_StoredSetupOverwriteOKChk,value= 0
	
	Button NewGF_SaveSetupButton,pos={605,36},size={50,20},proc=MOTO_WM_NewGlobalFit1#NewGF_SaveSetupButtonProc,title="Save"
	
	PopupMenu NewGF_RestoreSetupMenu,pos={522,78},size={107,20},proc=MOTO_WM_NewGlobalFit1#NewGF_RestoreSetupMenuProc,title="Restore Setup"
	PopupMenu NewGF_RestoreSetupMenu,mode=0,value= #"MOTO_WM_NewGlobalFit1#NewGF_ListStoredSetups()"

	SetActiveSubwindow ##
	
	SetWindow MotoGlobalFitPanel, hook = WC_WindowCoordinatesHook
	SetWindow MotoGlobalFitPanel, hook(NewGF_Resize) = MOTO_NewGF_PanelResizeHook

	NewGF_MoveControls()
end

Function MOTO_IsMinimized(windowName)
	String windowName
	
	if (strsearch(WinRecreation(windowName, 0), "MoveWindow 0, 0, 0, 0", 0, 2) > 0)
		return 1
	endif
	
	return 0
end

Function MOTO_NewGF_PanelResizeHook(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	
	Variable statusCode = 0

	if (H_Struct.eventCode == 4)
		return 0
	endif
	//print "event code: ", H_Struct.eventCode, "; Window: ", H_Struct.winName
	
	switch (H_Struct.eventCode)
		case 2:			// kill
			if (WinType("NewGF_GlobalFitConstraintPanel"))
				DoWindow/K NewGF_GlobalFitConstraintPanel
			endif
			if (WinType("NewGF_WeightingPanel"))
				DoWindow/K NewGF_WeightingPanel
			endif
			if (WinType("NewGF_GlobalFitMaskingPanel"))
				DoWindow/K NewGF_GlobalFitMaskingPanel
			endif
			break
		case 6:			// resize
			if (MOTO_IsMinimized(H_Struct.winName))
				break;
			endif
			NewGF_MainPanelMinWindowSize()
			NewGF_MoveControls()
			break
	endswitch
	
	return statusCode		// 0 if nothing done, else 1
End

static constant NewGF_MainPanelMinWidth = 669
static constant NewGF_MainPanelMinHeight = 377

static constant NewGF_TabWidthMargin = 15
static constant NewGF_TabHeightMargin = 122

static constant NewGF_Tab0ListGroupWidthMargin  = 5
static constant NewGF_Tab0ListGroupHeightMargin = 88

static constant NewGF_DataSetListGrpWidthMargin = 341
static constant NewGF_DataSetListGrpHghtMargin = 4

static constant NewGF_Tab0CoefListTopMargin = 88
static constant NewGF_Tab0CoefListLeftMargin = 1
static constant NewGF_Tab0CoefListRightMargin = 2

static constant NewGF_CoefListWidthMargin = 10
static constant NewGF_CoefListHeightMargin = 40

// all dimensions are in points
static Function NewGF_MainPanelMinWindowSize()

	GetWindow MotoGlobalFitPanel, wsize
	Variable minimized= (V_right == V_left) && (V_bottom==V_top)
	if( minimized )
		return 0
	endif
	Variable width= (V_right - V_left)
	Variable height= (V_bottom - V_top)
	width= max(width, NewGF_MainPanelMinWidth*72/ScreenResolution)
	height= max(height, NewGF_MainPanelMinHeight*72/ScreenResolution)
	MoveWindow/W=MotoGlobalFitPanel V_left, V_top, V_left+width, V_top+height
End

static Function NewGF_MoveControls()

	GetWindow MotoGlobalFitPanel wsizeDC
	Variable Width = (V_right - V_left)
	Variable Height = (V_bottom - V_top)
	TabControl NewGF_TabControl, win=MotoGlobalFitPanel,size={width-NewGF_TabWidthMargin, height-NewGF_TabHeightMargin}

	ControlInfo/W=MotoGlobalFitPanel NewGF_TabControl
	switch(V_value)
		case 0:
			GetWindow MotoGlobalFitPanel#Tab0ContentPanel wsizeDC
			Width = (V_right - V_left) - NewGF_Tab0ListGroupWidthMargin
			Height = (V_bottom - V_top) - NewGF_Tab0ListGroupHeightMargin
			GroupBox NewGF_Tab0ListGroup, win=MotoGlobalFitPanel#Tab0ContentPanel, size={width, height}
			ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_DataSetsList
			Variable listwidth = V_width		// constant width
			height -= NewGF_DataSetListGrpHghtMargin
			ListBox NewGF_DataSetsList, win=MotoGlobalFitPanel#Tab0ContentPanel, size={listwidth, height}
			ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_DataSetsList
			Variable top = V_top
			Variable left = V_Left + V_width + 1
			ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_Tab0ListGroup
			listwidth = V_left + V_width - 2 - left
			ListBox NewGF_Tab0CoefList, win=MotoGlobalFitPanel#Tab0ContentPanel, pos={left, top}, size={listwidth, height}
			break;
		case 1:
			GetWindow MotoGlobalFitPanel#Tab1ContentPanel wsizeDC
			Width = (V_right - V_left)
			Height = (V_bottom - V_top)
			ListBox NewGF_CoefControlList, win=MotoGlobalFitPanel#Tab1ContentPanel,size={width-NewGF_CoefListWidthMargin, height-NewGF_CoefListHeightMargin}
			break;
	endswitch
end

static Function/S NewGF_ListStoredSetups()

	String SaveDF = GetDataFolder(1)
	SetDataFolder root:packages:motofitgf:
	
	if (!DataFolderExists("NewGlobalFit_StoredSetups"))
		SetDataFolder $saveDF
		return "\\M1(No Stored Setups"
	endif
	
	SetDataFolder NewGlobalFit_StoredSetups
	
	Variable numDFs = CountObjects(":", 4)
	if (numDFs == 0)
		SetDataFolder $saveDF
		return "\\M1(No Stored Setups"
	endif
	
	Variable i
	String theList = ""
	for (i = 0; i < numDFs; i += 1)
		theList += (GetIndexedObjName(":", 4, i)+";")
	endfor
	
	SetDataFolder $saveDF
	return theList
end


static Function NewGF_SaveSetupButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR NewGF_NewSetupName = root:packages:MotofitGF:NewGlobalFit:NewGF_NewSetupName
	String SaveDF = GetDataFolder(1)
	SetDataFolder root:packages:motofitgf:
	NewDataFolder/O/S NewGlobalFit_StoredSetups

	if (CheckName(NewGF_NewSetupName, 11))
		if (DataFolderExists(NewGF_NewSetupName))
			ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_StoredSetupOverwriteOKChk
			if (V_value)
				KillDataFolder $NewGF_NewSetupName
			else
				DoAlert 1, "The setup name "+NewGF_NewSetupName+" already exists. Make a unique name and continue?"
				if (V_flag == 1)
					NewGF_NewSetupName = UniqueName(NewGF_NewSetupName, 11, 0)
				else
					SetDataFolder $saveDF
					return 0							// ******* EXIT *********
				endif
			endif
		else
			DoAlert 1, "The setup name is not a legal name. Fix it up and continue?"
			if (V_flag == 1)
				NewGF_NewSetupName = CleanupName(NewGF_NewSetupName, 1)
				NewGF_NewSetupName = UniqueName(NewGF_NewSetupName, 11, 0)
			endif
		endif
	endif
	DuplicateDataFolder ::NewGlobalFit, $NewGF_NewSetupName
	SetDataFolder $NewGF_NewSetupName
	
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_ConstraintsCheckBox
	Variable/G DoConstraints = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_WeightingCheckBox
	Variable/G DoWeighting = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_MaskingCheckBox
	Variable/G DoMasking = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_DoCovarMatrix
	Variable/G DoCovarMatrix = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_CorrelationMatrixCheckBox
	Variable/G DoCorelMatrix = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_MakeFitCurvesCheck
	Variable/G MakeFitCurves = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_AppendResultsCheckbox
	Variable/G AppendResults = V_value 
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_DoResidualCheck
	Variable/G DoResiduals = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_DoDestLogSpacingCheck
	Variable/G DoLogSpacing = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_Quiet
	Variable/G DoQuiet = V_value
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_FitProgressGraphCheckBox
	Variable/G DoFitProgressGraph = V_value
	
	KillWaves/Z YCumData, FitY, NewGF_FitFuncNames, NewGF_LinkageMatrix, NewGF_DataSetsList, NewGF_CoefWave
	KillWaves/Z NewGF_CoefficientNames, CoefDataSetLinkage, FitFuncList, DataSetPointer, ScratchCoefs, MasterCoefs, EpsilonWave
	KillWaves/Z GFWeightWave, GFMaskWave, GFUI_GlobalFitConstraintWave, Res_YCumData, M_Covar, W_sigma, W_ParamConfidenceInterval 
	KillWaves/Z M_Correlation, fitXCumData, XCumData
	
	KillVariables/Z V_Flag, V_FitQuitReason, V_FitError, V_FitNumIters, V_numNaNs, V_numINFs, V_npnts, V_nterms, V_nheld
	KillVariables/Z V_startRow, V_endRow, V_startCol, V_endCol, V_chisq
	
	SetDataFolder $saveDF
End

static Function NewGF_RestoreSetupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
		String saveDF = GetDataFolder(1)
		
		SetDataFolder root:packages:motofitgf:NewGlobalFit_StoredSetups:$(PU_Struct.popStr)
		Variable i = 0
		do
			Wave/Z w = WaveRefIndexed("", i, 4)
			if (!WaveExists(w))
				break
			endif
			
			Duplicate/O w, root:packages:MotofitGF:NewGlobalFit:$(NameOfWave(w))
			i += 1
		while (1)
		
		String vars = VariableList("*", ";", 4)
		Variable nv = ItemsInList(vars)
		for (i = 0; i < nv; i += 1)
			String varname = StringFromList(i, vars)
			NVAR vv = $varname
			Variable/G root:packages:MotofitGF:NewGlobalFit:$varname = vv
		endfor
		
		String strs = StringList("*", ";")
		Variable nstr = ItemsInList(strs)
		for (i = 0; i < nstr; i += 1)
			String strname = StringFromList(i, strs)
			SVAR ss = $strname
			String/G root:packages:MotofitGF:NewGlobalFit:$strname = ss
		endfor
		
		SetDataFolder root:packages:motofitgf:NewGlobalFit
		NVAR DoConstraints
		CheckBox NewGF_ConstraintsCheckBox,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoConstraints
		NVAR DoWeighting
		CheckBox NewGF_WeightingCheckBox,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoWeighting
		NVAR DoMasking
		CheckBox NewGF_MaskingCheckBox,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoMasking
		NVAR DoCovarMatrix
		CheckBox NewGF_DoCovarMatrix,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoCovarMatrix
		NVAR DoCorelMatrix
		CheckBox NewGF_CorrelationMatrixCheckBox,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoCorelMatrix
		NVAR MakeFitCurves
		CheckBox NewGF_MakeFitCurvesCheck,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=MakeFitCurves
		NVAR AppendResults
		CheckBox NewGF_AppendResultsCheckbox,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=AppendResults
		NVAR DoResiduals
		CheckBox NewGF_DoResidualCheck,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoResiduals
		Variable/G DoLogSpacing = NumVarOrDefault("DoLogSpacing", 0)
		CheckBox NewGF_DoDestLogSpacingCheck,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoLogSpacing
		NVAR DoQuiet
		CheckBox NewGF_Quiet,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoQuiet
		NVAR DoFitProgressGraph
		CheckBox NewGF_FitProgressGraphCheckBox,win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=DoFitProgressGraph
		KillVariables/Z DoConstraints, DoWeighting, DoMasking, DoCovarMatrix, DoCorelMatrix, MakeFitCurves, AppendResults, DoResiduals, DoQuiet, DoFitProgressGraph
		
		SetDataFolder $saveDF
	endif
End

Function MOTO_NewGF_SetTabControlContent(whichTab)
	Variable whichTab
	
	switch(whichTab)
		case 0:
			DefineGuide/W=MotoGlobalFitPanel Tab1AreaLeft={FR,25},Tab1AreaRight={FR,800}
			DefineGuide/W=MotoGlobalFitPanel Tab0AreaLeft={FL,13},Tab0AreaRight={FR,-10}
			break;
		case 1:
			NVAR/Z NewGF_RebuildCoefListNow = root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
			if (!NVAR_Exists(NewGF_RebuildCoefListNow) || NewGF_RebuildCoefListNow)
				NewGF_RebuildCoefListWave()
			endif
			DefineGuide/W=MotoGlobalFitPanel Tab0AreaLeft={FR,25},Tab0AreaRight={FR,800}
			DefineGuide/W=MotoGlobalFitPanel Tab1AreaLeft={FL,13},Tab1AreaRight={FR, -10}
			break;
	endswitch
	NewGF_MoveControls()
end

static Function NewGF_TabControlProc(TC_Struct)
	STRUCT WMTabControlAction &TC_Struct

	if (TC_Struct.eventCode == 2)
		MOTO_NewGF_SetTabControlContent(TC_Struct.tab)
	endif
End

static Function isControlOrRightClick(eventMod)
	Variable eventMod
	
	if (CmpStr(IgorInfo(2), "Macintosh") == 0)
		if ( (eventMod & 24) == 16)
			return 1
		endif
	else
		if ( (eventMod & 16) == 16)
			return 1
		endif
	endif
	
	return 0
end

//static Function NewGF_DataSetListBoxProc(ctrlName,row,col,event)
//	String ctrlName     // name of this control
//	Variable row        // row if click in interior, -1 if click in title
//	Variable col        // column number
//	Variable event      // event code
	
static Function NewGF_DataSetListBoxProc(LB_Struct)
	STRUCT WMListboxAction &LB_Struct
	
	Variable numcoefs
	String funcName
	
	if (LB_Struct.eventCode == 7)		// finish edit
		if (CmpStr(LB_Struct.ctrlName, "NewGF_Tab0CoefList") == 0)
			return 0
		endif
			
		if (LB_Struct.col == NewGF_DSList_NCoefCol)
			Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
			Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
			Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
			Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
			Variable i,j
			Variable numrows = DimSize(ListWave, 0)
			Variable numcols = DimSize(Listwave, 1)
		
			numcoefs = str2num(ListWave[LB_Struct.row][LB_Struct.col][0])
			funcName = ListWave[LB_Struct.row][NewGF_DSList_FuncCol][0]
			Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
			
			if (NumCoefs > DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
				Redimension/N=(-1,NumCoefs+NewGF_DSList_FirstCoefCol, -1) CoefListWave, CoefSelWave
				for (i = 1; i < NumCoefs; i += 1)
					SetDimLabel 1, i+NewGF_DSList_FirstCoefCol,$("K"+num2str(i)), CoefListWave
				endfor
			endif
			for (i = 0; i < numrows; i += 1)
				if (CmpStr(funcName, ListWave[i][NewGF_DSList_FuncCol][0]) == 0)
					ListWave[i][NewGF_DSList_NCoefCol][0] = num2str(numCoefs)
					for (j = 0; j < numCoefs; j += 1)
						if (!IsLinkText(CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]))		// don't change a LINK specification
							CoefListWave[i][NewGF_DSList_FirstCoefCol+j] = "r"+num2istr(i)+":K"+num2istr(j)
						endif
					endfor
				endif
			endfor
			
			NewGF_CheckCoefsAndReduceDims()
		endif
	elseif(LB_Struct.eventCode == 1)		// mouse down
		Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
			
		if (LB_Struct.row == -1)
			if (CmpStr(LB_Struct.ctrlName, "NewGF_Tab0CoefList") == 0)
				Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
			else
				Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
			endif
			SelWave[][][0] = SelWave[p][q] & ~1				// de-select everything to make sure we don't leave something selected in another column
			SelWave[][LB_Struct.col][0] = SelWave[p][LB_Struct.col] | 1			// select all rows
		elseif ( (LB_Struct.row >= 0) && (LB_Struct.row < DimSize(SelWave, 0)) )
			if (CmpStr(LB_Struct.ctrlName, "NewGF_Tab0CoefList") == 0)
				return 0
			endif
			
			//			if (GetKeyState(0) == 0)										// no modifier keys
			if (isControlOrRightClick(LB_Struct.eventMod))				// right-click or ctrl-click
				switch(LB_Struct.col)
					case NewGF_DSList_YWaveCol:
						PopupContextualMenu MOTO_NewGF_YWaveList(-1)
						if (V_flag > 0)
							Wave w = $S_selection
							NewGF_SetYWaveForRowInList(w, $"", LB_Struct.row)
							SelWave[LB_Struct.row][LB_Struct.col][0] = 0
						endif
						break
					case NewGF_DSList_XWaveCol:
						Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
						Wave w = $(ListWave[LB_Struct.row][NewGF_DSList_YWaveCol][1])
						if (WaveExists(w))
							String RowsText = num2str(DimSize(w, 0))
							PopupContextualMenu "_calculated_;"+WaveList("*",";","MINROWS:"+RowsText+",MAXROWS:"+RowsText+",DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
							if (V_flag > 0)
								Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
								Wave/Z w = $S_selection
								MOTO_NewGF_SetXWaveInList(w, LB_Struct.row)
								SelWave[LB_Struct.row][LB_Struct.col][0] = 0
							endif
						endif
						break
					case NewGF_DSList_FuncCol:
						PopupContextualMenu MOTO_NewGF_FitFuncList()
						if (V_flag > 0)
							FuncName = S_selection
							
							Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
							Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
							Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
							Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
							
							String CoefList
							NumCoefs = GetNumCoefsAndNamesFromFunction(FuncName, coefList)
							
							if (numType(NumCoefs) == 0)
								if (NumCoefs > DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
									Redimension/N=(-1,NumCoefs+NewGF_DSList_FirstCoefCol, -1) CoefListWave, CoefSelWave
									for (i = 1; i < NumCoefs; i += 1)
										SetDimLabel 1, i+NewGF_DSList_FirstCoefCol,$("K"+num2str(i)), CoefListWave
									endfor
								endif
							endif
							
							Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
							ListWave[LB_Struct.row][NewGF_DSList_FuncCol][0] = FuncName
							if (numType(NumCoefs) == 0)
								ListWave[LB_Struct.row][NewGF_DSList_NCoefCol][0] = num2istr(NumCoefs)
								for (j = 0; j < NumCoefs; j += 1)
									String coeftitle = StringFromList(j, coefList)
									if (strlen(coeftitle) == 0)
										coeftitle = "r"+num2istr(LB_Struct.row)+":K"+num2istr(j)
									else
										coeftitle = "r"+num2istr(LB_Struct.row)+":"+coeftitle
									endif
									CoefListWave[LB_Struct.row][NewGF_DSList_FirstCoefCol+j] = coeftitle
								endfor
								SelWave[LB_Struct.row][NewGF_DSList_NCoefCol][0] = 0
							else
								SelWave[LB_Struct.row][NewGF_DSList_NCoefCol][0] = 2
							endif
							for (j = j+NewGF_DSList_FirstCoefCol;j < DimSize(ListWave, 1); j += 1)
								CoefListWave[LB_Struct.row][j] = ""
							endfor
							
							NewGF_CheckCoefsAndReduceDims()
						endif
						break
				endswitch
			endif
		endif
	elseif ( (LB_Struct.eventCode == 8) || (LB_Struct.eventCode == 10) )		// vertical scroll or programmatically set top row
		String otherCtrl = ""
		if (CmpStr(LB_Struct.ctrlName, "NewGF_DataSetsList") == 0)
			otherCtrl = "NewGF_Tab0CoefList"
		else 
			otherCtrl = "NewGF_DataSetsList"
		endif
		ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel $otherCtrl
		//print LB_Struct.ctrlName, otherCtrl, "event = ", LB_Struct.eventCode, "row = ", LB_Struct.row, "V_startRow = ", V_startRow
		if (V_startRow != LB_Struct.row)
			ListBox $otherCtrl win=MotoGlobalFitPanel#Tab0ContentPanel,row=LB_Struct.row
			DoUpdate
		endif
	endif
End
//xstatic constant NewGF_DSList_YWaveCol = 0
//xstatic constant NewGF_DSList_XWaveCol = 1
//xstatic constant NewGF_DSList_FuncCol = 2
//xstatic constant NewGF_DSList_NCoefCol = 3
//xstatic constant NewGF_DSList_FirstCoefCol = 4

Function MOTO_NewGF_AddYWaveMenuProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	Variable i, nInList
	
	if (PU_Struct.eventCode == 2)			// mouse up
		strswitch (PU_Struct.popStr)
			case "All From Top Graph":
				String tlist = TraceNameList("", ";", 1)
				String tname
				i = 0
				do
					tname = StringFromList(i, tlist)
					if (strlen(tname) == 0)
						break;
					endif
					
					Wave w = TraceNameToWaveRef("", tname)
					Wave/Z xw = XWaveRefFromTrace("", tname)
					if (WaveExists(w) && !NewGF_WaveInListAlready(w))
						NewGF_AddYWaveToList(w, xw)
					endif
					i += 1
				while(1)
				break;
			case "All From Top Table":
				do
					Wave/Z w = WaveRefIndexed(WinName(0, 2), i, 1)
					if (!WaveExists(w))
						break;
					endif
					
					NewGF_AddYWaveToList(w, $"")
					i += 1
				while (1)
				break;
			default:
				Wave/Z w = $(PU_Struct.popStr)
				if (WaveExists(w) && !NewGF_WaveInListAlready(w))
					NewGF_AddYWaveToList(w, $"")
				endif
				break;
		endswitch
	endif
	
	return 0
end

static Function NewGF_WaveInListAlready(w)
	Wave w
	
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Variable i
	Variable nrows = DimSize(ListWave, 0)
	for (i = 0; i < nrows; i += 1)
		Wave/Z rowWave = $(ListWave[i][NewGF_DSList_YWaveCol][1])
		if (WaveExists(rowWave) && (CmpStr(ListWave[i][NewGF_DSList_YWaveCol][1], GetWavesDataFolder(w, 2)) == 0))
			return 1
		endif
	endfor
	
	return 0
end

static Function NewGF_AddYWaveToList(w, xw)
	Wave w
	Wave/Z xw
	
	if (!NewGF_WaveIsSuitable(w))
		return 0
	endif
	
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
	Variable nextRow
	
	if (DimSize(ListWave, 0) == 1)
		if (AllFieldsAreBlank(ListWave, 0))
			nextRow = 0
		else
			nextRow = 1
		endif
	else
		nextRow = DimSize(ListWave, 0)
	endif
	
	Redimension/N=(nextRow+1, -1, -1) ListWave, SelWave, CoefListWave, CoefSelWave
	SelWave[nextRow] = 0
	CoefSelWave[nextRow] = 0
	SelWave[nextRow][NewGF_DSList_NCoefCol][0] = 2
	ListWave[nextRow] = ""
	CoefListWave[nextRow] = ""
	
	NewGF_SetYWaveForRowInList(w, xw, nextRow)
	
	//	ListWave[nextRow][NewGF_DSList_YWaveCol][0] = NameOfWave(w)
	//	ListWave[nextRow][NewGF_DSList_YWaveCol][1] = GetWavesDataFolder(w, 2)
	//	if (WaveExists(xw))
	//		ListWave[nextRow][NewGF_DSList_XWaveCol][0] = NameOfWave(xw)
	//		ListWave[nextRow][NewGF_DSList_XWaveCol][1] = GetWavesDataFolder(xw, 2)
	//	else
	//		ListWave[nextRow][NewGF_DSList_XWaveCol][0] = "_calculated_"
	//		ListWave[nextRow][NewGF_DSList_XWaveCol][1] = "_calculated_"
	//	endif
	
	Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
end

static Function NewGF_SetYWaveForRowInList(w, xw, row)
	Wave/Z w
	Wave/Z xw
	Variable row
	
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	
	if (WaveExists(w))
		ListWave[row][NewGF_DSList_YWaveCol][0] = NameOfWave(w)
		ListWave[row][NewGF_DSList_YWaveCol][1] = GetWavesDataFolder(w, 2)
	else
		ListWave[row][NewGF_DSList_YWaveCol][0] = ""			// this allows us to clear the data set from a row
		ListWave[row][NewGF_DSList_YWaveCol][1] = ""
	endif
	if (WaveExists(xw))
		ListWave[row][NewGF_DSList_XWaveCol][0] = NameOfWave(xw)
		ListWave[row][NewGF_DSList_XWaveCol][1] = GetWavesDataFolder(xw, 2)
	else
		ListWave[row][NewGF_DSList_XWaveCol][0] = "_calculated_"
		ListWave[row][NewGF_DSList_XWaveCol][1] = "_calculated_"
	endif
	
	// Whatever happens above, something in the list has changed, so we need to flag the change  for the next time the tab changes
	NVAR/Z NewGF_RebuildCoefListNow = root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
	if (!NVAR_Exists(NewGF_RebuildCoefListNow))
		Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1
	endif
	NewGF_RebuildCoefListNow = 1
end

static Function NewGF_SetDataSetMenuProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	Variable i, j, nInList
	
	if (PU_Struct.eventCode == 2)			// mouse up
		Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
		Variable numRows = DimSize(SelWave, 0)

		strswitch (PU_Struct.popStr)
			case "From Top Graph":
				String tlist = TraceNameList("", ";", 1)
				String tname
				i = 0; j = 0
				for (j = 0; j < numRows; j += 1)
					if ( (SelWave[j][NewGF_DSList_YWaveCol] & 9) != 0)
						NewGF_SetYWaveForRowInList($"", $"", j)
					endif
				endfor
				for (j = 0; j < numRows; j += 1)
					if ( (SelWave[j][NewGF_DSList_YWaveCol] & 9) != 0)
						tname = StringFromList(i, tlist)
						if (strlen(tname) == 0)
							break;
						endif
						
						Wave w = TraceNameToWaveRef("", tname)
						Wave/Z xw = XWaveRefFromTrace("", tname)
						if (WaveExists(w))
							if  (!NewGF_WaveInListAlready(w))
								NewGF_SetYWaveForRowInList(w, xw, j)
							else
								j -= 1		// we didn't use this row, so counteract the increment for loop (??)
							endif
						endif
						i += 1
					endif
				endfor
				break;
			case "From Top Table":
				i = 0; j = 0
				for (j = 0; j < numRows; j += 1)
					if ( (SelWave[j][NewGF_DSList_YWaveCol] & 9) != 0)
						NewGF_SetYWaveForRowInList($"", $"", j)
					endif
				endfor
				for (j = 0; j < numRows; j += 1)
					if ( (SelWave[j][NewGF_DSList_YWaveCol] & 9) != 0)
						Wave w = WaveRefIndexed(WinName(0, 2), i, 1)
						if (!WaveExists(w))
							break;
						endif
						
						NewGF_SetYWaveForRowInList(w, $"", j)
						i += 1
					endif
				endfor
				break;
			default:
				Wave/Z w = $(PU_Struct.popStr)
				if (WaveExists(w) && !NewGF_WaveInListAlready(w))
					for (j = 0; j < numRows; j += 1)
						if ( (SelWave[j][NewGF_DSList_YWaveCol] & 9) != 0)
							NewGF_SetYWaveForRowInList($"", $"", j)
							NewGF_SetYWaveForRowInList(w, $"", j)
							break				// a data set should appear in the list only once
						endif
					endfor
				endif
				break;
		endswitch
	endif
	
	return 0
End

Function MOTO_NewGF_SetXWaveInList(w, row)
	Wave/Z w
	Variable row
	
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	
	if (WaveExists(w))
		Wave/Z yWave = $(ListWave[row][NewGF_DSList_YWaveCol][1])
		if (WaveExists(yWave))
			if (DimSize(yWave, 0) != DimSize(w, 0))
				DoAlert 0, "The wave "+NameOfWave(yWave)+"in row "+num2istr(row)+" has different number of point from the X wave "+NameOfWave(w)
				return -1
			endif
		endif
		
		ListWave[row][NewGF_DSList_XWaveCol][0] = NameOfWave(w)
		ListWave[row][NewGF_DSList_XWaveCol][1] = GetWavesDataFolder(w, 2)
	else
		ListWave[row][NewGF_DSList_XWaveCol][0] = "_calculated_"
		ListWave[row][NewGF_DSList_XWaveCol][1] = "_calculated_"
	endif
	
	// Whatever happens above, something in the list has changed, so we need to flag the change  for the next time the tab changes
	NVAR/Z NewGF_RebuildCoefListNow = root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
	if (!NVAR_Exists(NewGF_RebuildCoefListNow))
		Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1
	endif
	NewGF_RebuildCoefListNow = 1
end

static Function AllFieldsAreBlank(w, row)
	Wave/T w
	Variable row
	
	Variable i
	Variable lastRow = DimSize(w, 1)
	for (i  = 0; i < lastRow; i += 1)
		if (strlen(w[row][i][0]) != 0)
			return 0
		endif
	endfor
	
	return 1
end

static Function NewGF_WaveIsSuitable(w)
	Wave w
	
	String wname = NameOfWave(w)
	
	if (CmpStr(wname[0,3], "fit_") == 0)
		return 0
	endif
	if (CmpStr(wname[0,3], "res_") == 0)
		return 0
	endif
	if (CmpStr(wname[0,4], "GFit_") == 0)
		return 0
	endif
	if (CmpStr(wname[0,4], "GRes_") == 0)
		return 0
	endif
	
	return 1
end

static Function NewGF_SetXWaveMenuProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	//For a PopupMenu control, the WMPopupAction structure has members as described in the following table:
	//WMPopupAction Structure Members	
	//Member	Description
	//char ctrlName[MAX_OBJ_NAME+1]	Control name.
	//char win[MAX_WIN_PATH+1]	Host (sub)window.
	//STRUCT Rect winRect	Local coordinates of host window.
	//STRUCT Rect ctrlRect	Enclosing rectangle of the control.
	//STRUCT Point mouseLoc	Mouse location.
	//Int32 eventCode	Event that caused the procedure to execute. Main event is mouse up=2.
	//String userdata	Primary (unnamed) user data. If this changes, it is written back automatically.
	//Int32 popNum	Item number currently selected (1-based).
	//char popStr[MAXCMDLEN]	Contents of current popup item.

	Variable i, nInList, waveindex

	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Variable numListrows = DimSize(ListWave, 0)
	
	if (PU_Struct.eventCode == 2)			// mouse up
		strswitch (PU_Struct.popStr)
			case "Top Table to List":
				for (i = 0; i < numListrows; i += 1)
					Wave/Z w = WaveRefIndexed(WinName(0, 2), i, 1)
					if (!WaveExists(w))
						break;
					endif
					
					if (MOTO_NewGF_SetXWaveInList(w, i))
						break
					endif
				endfor
				break;
			case "Top Table to Selection":
				waveindex = 0
				for (i = 0; i < numListrows; i += 1)
					if (SelWave[i][NewGF_DSList_XWaveCol][0] & 9)
						Wave/Z w = WaveRefIndexed(WinName(0, 2), waveindex, 1)
						if (!WaveExists(w))
							break;
						endif
						if (MOTO_NewGF_SetXWaveInList(w, i))
							break
						endif
						waveindex += 1
					endif
				endfor
				break;
			case "Set All to _calculated_":
				for (i = 0; i < numListrows; i += 1)
					ListWave[i][NewGF_DSList_XWaveCol] = "_calculated_"
				endfor
				break;
			case "Set Selection to _calculated_":
				for (i = 0; i < numListrows; i += 1)
					if (SelWave[i][NewGF_DSList_XWaveCol][0] & 9)
						ListWave[i][NewGF_DSList_XWaveCol] = "_calculated_"
					endif
				endfor
				break;
			default:
				Wave/Z w = $PU_Struct.popStr
				if (WaveExists(w))
					for (i = 0; i < numListrows; i += 1)
						if (SelWave[i][NewGF_DSList_XWaveCol][0] & 9)
							MOTO_NewGF_SetXWaveInList(w, i)
							//break
						endif
					endfor
				endif
				break;
		endswitch
	endif
	
	return 0
end

static Function NewGF_RemoveDataSetsProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
	Variable i,j
	Variable ncols = DimSize(ListWave, 1)
	Variable nrows = DimSize(ListWave, 0)
	
	if (PU_Struct.eventCode == 2)			// mouse up
		strswitch (PU_Struct.popStr)
			case "Remove All":
				Redimension/N=(1, 4, -1) ListWave, SelWave
				Redimension/N=(1, 1, -1) CoefListWave, CoefSelWave
				ListWave = ""
				CoefListWave = ""
				SelWave = 0
				CoefSelWave = 0
				Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
				break
			case "Remove Selection":
				for (i = nrows-1; i >= 0; i -= 1)
					for (j = 0; j < ncols; j += 1)
						if (SelWave[i][j][0] & 9)
							DeletePoints i, 1, ListWave, SelWave, CoefListWave, CoefSelWave
							Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
							break
						endif
					endfor
				endfor
				break
			default:
				for (i = 0; i < nrows; i += 1)
					if (CmpStr(PU_Struct.popStr, ListWave[i][NewGF_DSList_YWaveCol][0]) == 0)
						DeletePoints i, 1, ListWave, SelWave, CoefListWave, CoefSelWave
						Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
						break
					endif
				endfor
				break
		endswitch
	endif
end

Function MOTO_FitFuncSetSelecRadioProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	Variable SetSelect = (CmpStr(ctrlName, "NewGF_FitFuncSetSelectionRadio") == 0) ^ checked
	
	CheckBox NewGF_FitFuncSetSelectionRadio, win=MotoGlobalFitPanel#Tab0ContentPanel, value = SetSelect
	
	CheckBox NewGF_FitFuncSetAllRadio, win=MotoGlobalFitPanel#Tab0ContentPanel, value = !SetSelect
End

static Function NewGF_CheckCoefsAndReduceDims()
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave

	Variable i
	Variable numListRows = DimSize(ListWave, 0)
	Variable maxCoefs = 0
	
	// collect the maximum number of coefficients from the # Coefs column
	for (i = 0; i < numListRows; i += 1)
		Variable numCoefs = str2num(ListWave[i][NewGF_DSList_NCoefCol])
		maxCoefs = max(maxCoefs, numCoefs)
	endfor
	
	if (maxCoefs < DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
		Variable needCols = maxCoefs + NewGF_DSList_FirstCoefCol
		DeletePoints/M=1 needCols, DimSize(CoefListWave, 1)-needCols, CoefListWave, CoefSelWave
	endif
end

Function MOTO_NewGF_SetFuncMenuProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
	
		Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
		Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
		Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
		
		Variable numListrows = DimSize(ListWave, 0)
		String CoefList
		Variable NumCoefs = GetNumCoefsAndNamesFromFunction(PU_Struct.popStr, coefList)
		Variable i, j
		
		//		ControlInfo NewGF_FitFuncSetSelectionRadio
		//		Variable SetSelection = V_value
		
		if (numType(NumCoefs) == 0)
			if (NumCoefs > DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
				Redimension/N=(-1,NumCoefs+NewGF_DSList_FirstCoefCol, -1) CoefListWave, CoefSelWave
				for (i = 1; i < NumCoefs; i += 1)
					SetDimLabel 1, i+NewGF_DSList_FirstCoefCol,$("K"+num2str(i)), CoefListWave
				endfor
			endif
		endif
		
		for (i = 0; i < numListRows; i += 1)
			if ((SelWave[i][NewGF_DSList_FuncCol][0] & 9) == 0)
				continue		// skip unselected rows
			endif
			
			Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
			ListWave[i][NewGF_DSList_FuncCol][0] = PU_Struct.popStr
			if (numType(NumCoefs) == 0)
				ListWave[i][NewGF_DSList_NCoefCol][0] = num2istr(NumCoefs)
				for (j = 0; j < NumCoefs; j += 1)
					String coeftitle = StringFromList(j, coefList)
					if (strlen(coeftitle) == 0)
						coeftitle = "r"+num2istr(i)+":K"+num2istr(j)
					else
						coeftitle = "r"+num2istr(i)+":"+coeftitle
					endif
					CoefListWave[i][NewGF_DSList_FirstCoefCol+j] = coeftitle
				endfor
				SelWave[i][NewGF_DSList_NCoefCol][0] = 0
			else
				SelWave[i][NewGF_DSList_NCoefCol][0] = 2
			endif
		endfor
		
		NewGF_CheckCoefsAndReduceDims()
	endif
end

Function Moto_NEWGF_LinkCoefsButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
	Variable listRows = DimSize(CoefListWave, 0)
	Variable listCols = DimSize(CoefListWave, 1)
	Variable i,j
	String linkCellText = ""
	Variable linkrow, linkcol
	Variable lastCol
	Variable colorIndex = 1

	// scan for link color indices in order to set the color index to use this time to the first free color
	do
		Variable startOver = 0
		for (i = 0; i < listRows; i += 1)
			for (j = NewGF_DSList_FirstCoefCol; j < listCols; j += 1)
				if (CoefSelWave[i][j][%backColors] == colorIndex)
					colorIndex += 1
					startOver = 1
					break;
				endif
			endfor
			if (startOver)
				break;
			endif
		endfor
	while (startOver)
	
	// find the first cell in the selection to record the link row and column, and to set the color index if it is already linked.
	for (i = 0; i < listRows; i += 1)
		lastCol = NewGF_DSList_FirstCoefCol + str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
		for (j = NewGF_DSList_FirstCoefCol; j < lastCol; j += 1)
			if (CoefSelWave[i][j][0] & 9)
				linkCellText = CoefListWave[i][j][0]
				linkrow = i
				linkcol = j
				if (CoefSelWave[i][j][%backColors] != 0)
					colorIndex = CoefSelWave[i][j][%backColors]
				endif
				break;
			endif
		endfor
		if (strlen(linkCellText) > 0)
			break;
		endif
	endfor
	// if the first cell in the selection is a link, we want to set the link text to be the original, not derived from the current first selection cell.
	if (IsLinkText(linkCellText))
		linkCellText = linkCellText[5, strlen(linkCellText)-1]
	endif
	CoefSelWave[linkrow][linkcol][0] = 0		// de-select the first selected cell
	
	Wave/T Tab1CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave Tab1CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave

	Variable accumulatedGuess = 0
	Variable numAccumulatedGuesses = 0
	Variable linkGuessListIndex = CoefIndexFromTab0CoefRowAndCol(linkrow, linkcol)
	Variable initGuess = str2num(Tab1CoefListWave[linkGuessListIndex][2])
	if (numtype(initGuess) == 0)
		accumulatedGuess += initGuess
		numAccumulatedGuesses += 1
	endif
	string listOfLinkedRows = num2str(linkGuessListIndex)+";"
	string tab1LinkCellText = Tab1CoefListWave[linkGuessListIndex][1]
	
	// now scan from the cell after the first selected cell looking for selected cells to link to the first one
	j = linkcol+1
	for (i = linkrow; i < listRows; i += 1)
		lastCol = NewGF_DSList_FirstCoefCol + str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
		do
			if (j >= listCols)
				break
			endif
			if (CoefSelWave[i][j][0] & 9)
				Variable nCoefs = str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
				if (j >= nCoefs)
					CoefSelWave[i][j][0] = 0		// un-select this cell
					break			// this column isn't used for in this row because this function has fewer coefficients than the maximum
				endif
			
				CoefListWave[i][j][0] = "LINK:"+linkCellText
				CoefSelWave[i][j][%backColors] = colorIndex
				CoefSelWave[linkRow][linkCol][%backColors] = colorIndex							// don't want to set the color of this cell unless another cell is linked to it
				CoefSelWave[i][j][0] = 0
				linkGuessListIndex = CoefIndexFromTab0CoefRowAndCol(i, j)
				initGuess = str2num(Tab1CoefListWave[linkGuessListIndex][2])
				if (numtype(initGuess) == 0)
					accumulatedGuess += initGuess
					numAccumulatedGuesses += 1
				endif
				Tab1CoefListWave[linkGuessListIndex][1] = "LINK:"+tab1LinkCellText
				Tab1CoefSelWave[linkGuessListIndex][1] = 0
				Tab1CoefSelWave[linkGuessListIndex][2] = 0
				Tab1CoefSelWave[linkGuessListIndex][3] = 0			// no more checkbox for holding
				listOfLinkedRows += num2str(linkGuessListIndex)+";"
				//				Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
			endif
						
			j += 1
		while(1)
		j = NewGF_DSList_FirstCoefCol
	endfor
	
	// finally, install the average initial guess into all the linked rows in the tab1 coefficient control list
	if (numAccumulatedGuesses > 0)
		accumulatedGuess /= numAccumulatedGuesses
		Variable endindex = ItemsInList(listOfLinkedRows)
		for (i = 0; i < endindex; i += 1)
			Tab1CoefListWave[str2num(StringFromList(i, listOfLinkedRows))][2] = num2str(accumulatedGuess)
		endfor
	endif
End

// returns the row in the coefficient guess list (tab 1) for a given row and column in the coefficient list on tab 0
static Function CoefIndexFromTab0CoefRowAndCol(row, col)
	Variable row, col
	
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave

	Variable i, j
	col -= NewGF_DSList_FirstCoefCol
	
	Variable coefListIndex = 0
	for (i = 0; i < row; i += 1)
		coefListIndex += str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
	endfor
	coefListIndex += col
	
	return coefListIndex
end

Function Moto_UnLinkCoefsButtonProc(ctrlName) : ButtonControl
	String ctrlName


	Wave/T DataSetListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	//	Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave

	Wave/T Tab1CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave Tab1CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	
	Variable listRows = DimSize(CoefListWave, 0)
	Variable listCols = DimSize(CoefListWave, 1)
	Variable i,j
	
	for (i = 0; i < listRows; i += 1)
		for (j = NewGF_DSList_FirstCoefCol; j < listCols; j += 1)
			if (CoefSelWave[i][j][0] & 9)
				Variable nCoefs = str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])
				if (j >= nCoefs)
					CoefSelWave[i][j][] = 0		// sets color to white AND un-selects
					continue			// this column isn't used for in this row because this function has fewer coefficients than the maximum
				endif
				CoefListWave[i][j][0] = CoefListWave[i][j][1]
				CoefSelWave[i][j][] = 0		// sets color to white AND un-selects
				Variable linkGuessListIndex = CoefIndexFromTab0CoefRowAndCol(i, j)
				Tab1CoefSelWave[linkGuessListIndex][1] = 2
				Tab1CoefSelWave[linkGuessListIndex][2] = 2
				Tab1CoefSelWave[linkGuessListIndex][3] = 0x20		// checkbox
				String coefName = CoefNameFromListText(CoefListWave[i][NewGF_DSList_FirstCoefCol + j][1])
				Tab1CoefListWave[linkGuessListIndex][1] = coefName+"["+DataSetListWave[i][NewGF_DSList_FuncCol][0]+"]["+DataSetListWave[i][NewGF_DSList_YWaveCol][1]+"]"	// last part is full path to Y wave

				//				Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
			endif
		endfor
	endfor
End

static Function NewGF_SelectAllCoefMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
		Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		//		Wave SelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
		Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
		Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
		Variable i,j
		Variable numRows = DimSize(CoefListWave, 0)
		
		if (CmpStr(PU_Struct.ctrlName, "NewGF_SelectAllCoefMenu") == 0)
			CoefSelWave[][][0] = CoefSelWave[p][q][0] & ~9		// clear selection if we're not adding to the selection
		endif
		
		String FuncName = FuncNameFromFuncAndCoef(PU_Struct.popstr)
		String CoefName = CoefNameFromListText(PU_Struct.popstr)
		for (i = 0; i < numRows; i += 1)
			if (CmpStr(FuncName, ListWave[i][NewGF_DSList_FuncCol][0]) == 0)
				Variable nc = str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
				for (j = 0; j < nc; j += 1)
					if (CmpStr(CoefName, CoefNameFromListText(CoefListWave[i][NewGF_DSList_FirstCoefCol + j][0])) == 0)
						CoefSelWave[i][NewGF_DSList_FirstCoefCol + j][0] = CoefSelWave[i][NewGF_DSList_FirstCoefCol + j][0] | 1
					endif
				endfor
			endif
		endfor
	endif
End


static Function/S CoefNameFromListText(listText)
	String listText
	
	Variable colonPos = strsearch(listText, ":", inf, 1)		// search backwards
	return listText[colonPos+1, strlen(listText)-1]
end

static Function/S FuncNameFromFuncAndCoef(theText)
	String theText
	
	Variable colonpos = strsearch(theText, ":", 0)
	return theText[0, colonPos-1]
end

static Function/S NewGF_ListFunctionsAndCoefs()

	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Variable i, j
	Variable numRows = DimSize(ListWave, 0)
	String theList = ""
	
	for (i = 0; i < numRows; i += 1)
		Variable nCoefs = str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
		String FuncName = ListWave[i][NewGF_DSList_FuncCol][0]
		for (j = 0; j < nCoefs; j += 1)
			Variable coefIndex = j + NewGF_DSList_FirstCoefCol
			String coefText = CoefListWave[i][coefIndex][0]
			if (!IsLinkText(coefText))
				String theItem = FuncName+":"+CoefNameFromListText(coefText)
				if (WhichListItem(theItem, theList) < 0)
					theList += theItem+";"
				endif
			endif
		endfor
	endfor
	
	return theList
end

static Function IsWhiteSpaceChar(thechar)
	Variable thechar
	
	Variable spChar = char2num(" ")
	Variable tabChar = char2num("\t")

	if ( (thechar == spChar) || (thechar == tabChar) )
		return 1
	else
		return 0
	endif
end

static Function IsEndLine(theLine)
	String theLine
	
	Variable i = 0
	Variable linelength = strlen(theLine)
	
	for (i = 0; i < linelength; i += 1)
		Variable thechar = char2num(theLine[i])
		if (!IsWhiteSpaceChar(thechar))
			break
		endif
	endfor
	if (i == linelength)
		return 0
	endif
	return CmpStr(theLine[i, i+2], "end") == 0
end

static Function GetNumCoefsAndNamesFromFunction(funcName, coefList)
	String funcName
	String &coefList
	
	Variable i
	Variable numCoefs
	String funcCode = ProcedureText(funcName )
	
	coefList = ""
	
	if (strlen(funcCode) == 0)		// an XOP function?
		numCoefs = NaN
	else
		i=0
		Variable commentPos
		do
			String aLine = StringFromList(i, funcCode, "\r")
			if (IsEndLine(aLine))
				numCoefs = NaN
				break
			endif
			commentPos = strsearch(aLine, "//CurveFitDialog/ Coefficients", 0 , 2)
			if (commentPos >= 0)		// 2 means ignore case
				sscanf aLine[commentPos, inf], "//CurveFitDialog/ Coefficients %d", numCoefs
				i += 1
				break
			endif
			i += 1
		while (1)
		
		if (numType(numCoefs) == 0)
			do
				aLine = StringFromList(i, funcCode, "\r")
				if (IsEndLine(aLine))
					break
				endif
				commentPos = strsearch(aLine, "//CurveFitDialog/ w[", 0 , 2)
				if (commentPos >= 0)		// 2 means ignore case
					Variable equalPos = strsearch(aLine[commentPos, inf], "=", 0) + commentPos
					if (equalPos > 0)
						equalPos += 1
						Variable spChar = char2num(" ")
						Variable tabChar = char2num("\t")
						do
							Variable char = char2num(aLine[equalPos])
							if ( (char == spChar) || (char == tabChar) )
								equalPos += 1
							else
								string name
								sscanf aLine[equalPos, inf], "%s", name
								coefList += name+";"
								break
							endif
						while(1)
					endif
				endif
				i += 1
			while (1)
		endif
	endif
	
	return numCoefs
end

Function/S MOTO_NewGF_YWaveList(UseAllWord)
	Variable UseAllWord			// 0: "From Top Graph", 1: "All From Top Graph", -1: Don't include top graph and top table options

	if (UseAllWord == 1)
		String theList = "All From Top Graph;All From Top Table;-;"
	elseif (UseAllWord == -1)
		theList = ""
	else
		theList = "From Top Graph;From Top Table;-;"
	endif
	theList += WaveList("*", ";", "DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
	return theList
end

Function/S MOTO_NewGF_XWaveList()

	String theList = "Top Table to List;Top Table to Selection;Set All to _calculated_;Set Selection to _calculated_;-;"
	theList += WaveList("*", ";", "DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
	return theList
end

Function/S MOTO_NewGF_RemoveMenuList()

	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave

	String theList = "Remove All;Remove Selection;-;"
	Variable i
	Variable nrows = DimSize(ListWave, 0)
	for (i = 0; i < nrows; i += 1)
		theList += (ListWave[i][NewGF_DSList_YWaveCol][0])+";"
	endfor
	
	return theList
end

Function/S MOTO_NewGF_FitFuncList()

	string theList="", UserFuncs, XFuncs
	
	string options = "KIND:10"
	//	ControlInfo/W=GlobalFitPanel RequireFitFuncCheckbox
	//	if (V_value)
	options += ",SUBTYPE:FitFunc"
	//	endif
	options += ",NINDVARS:1"
	
	UserFuncs = FunctionList("*", ";",options)
	UserFuncs = RemoveFromList("GFFitFuncTemplate", UserFuncs)
	UserFuncs = RemoveFromList("GFFitAllAtOnceTemplate", UserFuncs)
	UserFuncs = RemoveFromList("NewGlblFitFunc", UserFuncs)
	UserFuncs = RemoveFromList("NewGlblFitFuncAllAtOnce", UserFuncs)
	UserFuncs = RemoveFromList("GlobalFitFunc", UserFuncs)
	UserFuncs = RemoveFromList("GlobalFitAllAtOnce", UserFuncs)

	XFuncs = FunctionList("*", ";", "KIND:12")
	
	if (strlen(UserFuncs) > 0)
		theList +=  "\\M1(   User-defined functions:;"
		theList += UserFuncs
	endif
	if (strlen(XFuncs) > 0)
		theList += "\\M1(   External Functions:;"
		theList += XFuncs
	endif
	
	if (strlen(theList) == 0)
		theList = "\\M1(No Fit Functions"
	endif
	
	return theList
end

static Function NewGF_RebuildCoefListWave()

	Wave/T DataSetListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	
	Variable DSListRows = DimSize(DataSetListWave, 0)
	Variable i, j, k
	Variable numUnlinkedCoefs = 0
	Variable totalCoefs = 0
	Variable nc
	Variable coefColonPos
	Variable colonPos
	Variable linkRow
	
	// count total number of coefficient taking into account linked coefficients
	for (i = 0; i < DSListRows; i += 1)
		totalCoefs += str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])
	endfor
	
	if (numtype(totalCoefs) != 0)
		return 0						// ****** EXIT ******
	endif
	
	Redimension/N=(totalCoefs, -1, -1) CoefListWave, CoefSelWave
	CoefListWave[][2] = ""			// clear out any initial guesses that might be left over from previous incarnations
	CoefSelWave[][3] = 0x20			// make the new rows have checkboxes in the Hold column
	CoefListWave[][3] = ""			// make the checkboxes have no label
	CoefSelWave[][1] = 2			// make the name column editable
	CoefSelWave[][2] = 2			// make the initial guess column editable
	CoefSelWave[][4] = 2			// make the epsilon column editable
	CoefListWave[][4] = "1e-6"		// a reasonable value for epsilon
	
	Variable coefIndex = 0
	for (i = 0; i < DSListRows; i += 1)
		nc = str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])
		for (j = 0; j < nc; j += 1)
			CoefListWave[coefIndex][0] = DataSetListWave[i][NewGF_DSList_YWaveCol][1]			// use the full path here
			String coefName = CoefNameFromListText(Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol + j][1])
			if (IsLinkText(Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]))
				Variable linkIndex = NewGF_CoefRowForLink(Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0])
				CoefListWave[coefIndex][1] = "LINK:"+CoefListWave[linkIndex][1]
				CoefListWave[coefIndex][2] = CoefListWave[linkIndex][2]
				CoefSelWave[coefIndex][1,] = 0		// not editable- this is a coefficient linked to another
			else
				CoefListWave[coefIndex][1] = coefName+"["+DataSetListWave[i][NewGF_DSList_FuncCol][0]+"]["+DataSetListWave[i][NewGF_DSList_YWaveCol][1]+"]"	// last part is full path to Y wave
				//				CoefListWave[coefIndex][1] = DataSetListWave[i][NewGF_DSList_FuncCol][0]+":"+coefText
			endif
			coefIndex += 1
		endfor
	endfor	
	
	Variable/G root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 0
end

static Function NewGF_CoefListBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	Wave/T DataSetListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave

	Variable DSListRows = DimSize(DataSetListWave, 0)
	Variable i,j
	Variable coefIndex = 0
	Variable selectionExists
	String newName
	Variable numRowsNeeded
	
	// if a coefficient name has been changed, we need to track down any linked coefficients and change them, too.
	if ( (event == 7) || (event == 2) )		// finish edit
		if ( (col >= 1)	|| (col <= 4) )		// edited a name, initial guess, hold, or epsilon
			if ( (event == 2) && (col != 3) )
				return 0
			endif
			for (i = 0; i < 	DSListRows; i += 1)
				Variable nc = str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])
				for (j = 0; j < nc; j += 1)
					if (IsLinkText(Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]))
						if (NewGF_CoefListRowForLink(Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]) == row)
							switch (col)
								case 1:
									CoefListWave[coefIndex][1] = "LINK:"+CoefListWave[row][1]
									break;
								case 2:
								case 4:
									CoefListWave[coefIndex][col] = CoefListWave[row][col]
									break;
								case 3:
									if (CoefSelWave[row][3] & 0x10)		// is it checked?
										CoefListWave[coefIndex][3] = " X"
									else
										CoefListWave[coefIndex][3] = ""
									endif
									break;
							endswitch
						endif
					endif
					coefIndex += 1
				endfor
			endfor
		endif
	elseif ( (event == 1) && (row == -1) && (col >= 2) )
		selectionExists = (FindSelectedRows(CoefSelWave) > 0)
		string menuStr = "Select All;De-select All;"
		if (selectionExists)
			menuStr += "Save Selection to Wave...;Load Selection From Wave...;"
		else
			menuStr += "Save to Wave...;Load From Wave...;"
		endif
		if (col == 3)		// hold column
			menuStr += "Clear all holds;"
		endif
		PopupContextualMenu menuStr
		if (V_flag > 0)
			switch (V_flag)
				case 1:
					CoefSelWave[][] = CoefSelWave[p][q] & ~9		// clear all selections
					CoefSelWave[][col] = CoefSelWave[p][col] | 1	// select all in this column
					break;
				case 2:
					CoefSelWave[][] = CoefSelWave[p][q] & ~9
					break;
				case 3:
					PopupContextualMenu "\\M1(  Save to Wave:;New Wave...;"+MOTO_ListInitGuessWaves(selectionExists, selectionExists)

					if (V_flag > 0)
						if (CmpStr(S_selection, "New Wave...") == 0)
							numRowsNeeded = selectionExists ? totalSelRealCoefsFromCoefList(1) : totalRealCoefsFromCoefList(0)
							newName = MOTO_NewGF_GetNewWaveName()
							if (strlen(newName) == 0)
								return 0
							endif
							Make/O/N=(numRowsNeeded)/D $newName
							Wave w = $newName
						else
							Wave w = $(S_selection)
						endif
						
						if (WaveExists(w))
							SaveCoefListToWave(w, col, selectionExists, selectionExists)		// SaveOnlySelectedCells, OKToSaveLinkCells
						endif
					endif
					break;
				case 4:
					selectionExists = (FindSelectedRows(CoefSelWave) > 0)
					PopupContextualMenu "\\M1(  Load From Wave:;"+MOTO_ListInitGuessWaves(selectionExists, selectionExists)
					if (V_flag > 0)
						Wave w = $(S_selection)
						
						if (WaveExists(w))
							SetCoefListFromWave(w, col, selectionExists, selectionExists)
						endif
					endif
					break;
				case 5:
					for (i = 0; i < DimSize(CoefSelWave, 0); i += 1)
						Make/O/N=(DimSize(CoefSelWave, 0)) GFTempHoldWave
						GFTempHoldWave = 0
						SetCoefListFromWave(GFTempHoldWave, 3, 0, 0)
						KillWaves/Z GFTempHoldWave
					endfor
			endswitch
		endif
	endif
	
	return 0
end

// finds the row number in the coefficient guess list (tab 1) corresponding to the cell in the tab0 coefficient list linked to by a linked cell
static Function NewGF_CoefRowForLink(linktext)
	String linktext
	
	Wave/T DataSetListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave

	Variable i,j
	Variable DSListRows = DimSize(DataSetListWave, 0)
	Variable coefIndex = 0;
	
	for (i = 0; i < 	DSListRows; i += 1)
		Variable nc = str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])
		for (j = 0; j < nc; j += 1)
			if (CmpStr((Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]), linktext[5, strlen(linktext)-1]) == 0)
				return coefIndex
			endif
			if (!IsLinkText(Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]))
				coefIndex += 1
			endif
		endfor
	endfor
end

static Function NewGF_CoefListRowForLink(linktext)
	String linktext
	
	Wave/T DataSetListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave

	Variable i,j
	Variable DSListRows = DimSize(DataSetListWave, 0)
	Variable coefIndex = 0;
	
	for (i = 0; i < 	DSListRows; i += 1)
		Variable nc = str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])
		for (j = 0; j < nc; j += 1)
			if (CmpStr((Tab0CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]), linktext[5, strlen(linktext)-1]) == 0)
				return coefIndex
			endif
			coefIndex += 1
		endfor
	endfor
end


//******************************************************
// the function that runs when Fit! button is clicked
//******************************************************

//static constant NewGF_DSList_YWaveCol = 0
//static constant NewGF_DSList_XWaveCol = 1
//static constant NewGF_DSList_FuncCol = 2
//static constant NewGF_DSList_NCoefCol = 3

//static constant NewGF_DSList_FirstCoefCol = 0

//static constant FuncPointerCol = 0
//static constant FirstPointCol = 1
//static constant LastPointCol = 2
//static constant NumFuncCoefsCol = 3
//static constant FirstCoefCol = 4

static Function NewGF_DoTheFitButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T DataSetListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	
	Variable numDataSets = DimSize(DataSetListWave, 0)
	Variable numCoefCols = DimSize(Tab0CoefListWave, 1)
	Variable i, j
	Variable nextFunc = 0

	Variable curveFitOptions = 0

	// build wave listing Fitting Function names. Have to check for repeats...
	Make/O/T/N=(numDataSets) root:packages:MotofitGF:NewGlobalFit:NewGF_FitFuncNames = ""
	Wave/T FitFuncNames = root:packages:MotofitGF:NewGlobalFit:NewGF_FitFuncNames
	
	for (i = 0; i < numDataSets; i += 1)
		if (!ItemListedInWave(DataSetListWave[i][NewGF_DSList_FuncCol][0], FitFuncNames))
			FitFuncNames[nextFunc] = DataSetListWave[i][NewGF_DSList_FuncCol][0]
			nextFunc += 1
		endif
	endfor
	Redimension/N=(nextFunc) FitFuncNames
	
	// build the linkage matrix required by DoNewGlobalFit
	// It is a coincidence that the matrix used by the list in the control panel has the same number of columns as the linkage matrix
	// so here we calculate the number of columns to protect against future changes
	
	Variable MaxNCoefs = numCoefCols - NewGF_DSList_FirstCoefCol
	Variable numLinkageCols = MaxNCoefs + FirstCoefCol
	
	Make/N=(numDataSets, numLinkageCols)/O root:packages:MotofitGF:NewGlobalFit:NewGF_LinkageMatrix
	Wave LinkageMatrix = root:packages:MotofitGF:NewGlobalFit:NewGF_LinkageMatrix
	
	Variable nRealCoefs = 0		// accumulates the number of independent coefficients (that is, non-link coefficients)
	for (i = 0; i < numDataSets; i += 1)
		Variable nc = str2num(DataSetListWave[i][NewGF_DSList_NCoefCol][0])

		LinkageMatrix[i][FuncPointerCol] = ItemNumberInTextWaveList(DataSetListWave[i][NewGF_DSList_FuncCol][0], FitFuncNames)
		LinkageMatrix[i][FirstPointCol] = 0		// this is private info used by DoNewGlobalFit(). It will be filled in by DoNewGlobalFit()
		LinkageMatrix[i][LastPointCol] = 0		// this is private info used by DoNewGlobalFit(). It will be filled in by DoNewGlobalFit()
		LinkageMatrix[i][NumFuncCoefsCol] = nc
		
		for (j = NewGF_DSList_FirstCoefCol; j < numCoefCols; j += 1)
			Variable linkMatrixCol = FirstCoefCol + j - NewGF_DSList_FirstCoefCol
			if (j-NewGF_DSList_FirstCoefCol < nc)
				String cellText = Tab0CoefListWave[i][j][0]
				if (IsLinkText(cellText))
					LinkageMatrix[i][linkMatrixCol] = NewGF_CoefRowForLink(cellText)
				else
					LinkageMatrix[i][linkMatrixCol] = nRealCoefs
					nRealCoefs += 1
				endif
			else
				LinkageMatrix[i][linkMatrixCol] = -1
			endif
		endfor
		DoUpdate
	endfor
	
	// Build the data sets list wave
	Make/O/T/N=(numDataSets, 2) root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetsList
	Wave/T DataSets = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetsList
	DataSets[][0,1] = DataSetListWave[p][q+NewGF_DSList_YWaveCol][1]		// layer 1 contains full paths
	
	// Add weighting, if necessary
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_WeightingCheckBox
	if (V_value)
		GFUI_AddWeightWavesToDataSets(DataSets)
		NVAR/Z GlobalFit_WeightsAreSD = root:packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD
		if (NVAR_Exists(GlobalFit_WeightsAreSD) && GlobalFit_WeightsAreSD)
			curveFitOptions += MOTO_NewGFOptionWTISSTD
		endif
	endif
	
	// Add Mask, if necessary
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_MaskingCheckBox
	if (V_value)
		GFUI_AddMaskWavesToDataSets(DataSets)
	endif

	// Build the Coefficient wave and CoefNames wave
	Make/O/D/N=(nRealCoefs, 3) root:packages:MotofitGF:NewGlobalFit:NewGF_CoefWave
	Wave coefWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefWave
	SetDimLabel 1,1,Hold,coefWave
	SetDimLabel 1,2,Epsilon,coefWave
	Make/O/T/N=(nRealCoefs) root:packages:MotofitGF:NewGlobalFit:NewGF_CoefficientNames
	Wave/T CoefNames = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefficientNames

	Variable coefIndex = 0
	Variable nTotalCoefs = DimSize(CoefListWave, 0)
	for (i = 0; i < nTotalCoefs; i += 1)
		if (!IsLinkText(CoefListWave[i][1]))
			coefWave[coefIndex][0] = str2num(CoefListWave[i][2])
			if (numtype(coefWave[coefIndex][0]) != 0)
				TabControl NewGF_TabControl, win=MotoGlobalFitPanel,value=1
				MOTO_NewGF_SetTabControlContent(1)
				CoefSelWave = (CoefSelWave & ~1)
				CoefSelWave[i][2] = 3
				DoAlert 0, "There is a problem with the initial guess value in row "+num2str(i)+": it is not a number."
				return -1
			endif
			coefWave[coefIndex][%Hold] = ((CoefSelWave[i][3] & 0x10) != 0)
			coefWave[coefIndex][%Epsilon] = str2num(CoefListWave[i][4])
			if (numtype(coefWave[coefIndex][%Epsilon]) != 0)
				TabControl NewGF_TabControl, win=MotoGlobalFitPanel,value=1
				MOTO_NewGF_SetTabControlContent(1)
				CoefSelWave = (CoefSelWave & ~1)
				CoefSelWave[i][4] = 3
				DoAlert 0, "There is a problem with the Epsilon value in row "+num2str(i)+": it is not a number."
				return -1
			endif
			CoefNames[coefIndex] = CoefListWave[i][1]
			coefIndex += 1
		endif
	endfor
	
	// Build constraint wave, if necessary
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_ConstraintsCheckBox
	if (V_value)
		NewGF_MakeConstraintWave()
		Wave/T/Z ConstraintWave = root:packages:MotofitGF:NewGlobalFit:GFUI_GlobalFitConstraintWave
	else
		Wave/T/Z ConstraintWave = $""
	endif
	
	// Set options
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_DoCovarMatrix
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionCOV_MATRIX
	endif

	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_CorrelationMatrixCheckBox
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionCOR_MATRIX
	endif

	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_MakeFitCurvesCheck
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionMAKE_FIT_WAVES
	endif

	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea AppendResultsCheck
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionAPPEND_RESULTS
	endif
	
	NVAR FitCurvePoints = root:packages:MotofitGF:NewGlobalFit:FitCurvePoints
	
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_DoResidualCheck
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionCALC_RESIDS
	endif
	
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_DoDestLogSpacingCheck
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionLOG_DEST_WAVE
	endif
	
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_Quiet
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionQUIET
	endif

	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_FitProgressGraphCheckBox
	if (V_value)
		curveFitOptions += MOTO_NewGFOptionFIT_GRAPH
	endif
	
	if(cmpstr(ctrlname,"DoSimButton")==0)
		MOTO_DoNewGlobalSim(FitFuncNames, DataSets, LinkageMatrix, coefWave, CoefNames, ConstraintWave, curveFitOptions, FitCurvePoints, 1)
	else
		Variable err = MOTO_DoNewGlobalFit(FitFuncNames, DataSets, LinkageMatrix, coefWave, CoefNames, ConstraintWave, curveFitOptions, FitCurvePoints, 1)
		if (!err)
			SetCoefListFromWave(coefWave, 2, 0, 0)
		endif
	endif
end

static Function/S MakeHoldString(CoefWave, quiet, justTheString)
	Wave CoefWave
	Variable quiet
	Variable justTheString
	NVAR/z isLevORgen=root:packages:MotofitGF:NewGlobalFit:isLevORgen
	
	String HS=""

	Variable HoldCol = FindDimLabel(CoefWave, 1, "Hold")
	Variable nHolds = 0
	if (HoldCol > 0)
		if (!justTheString)
			HS="/H=\""
		endif
		Variable nCoefs=DimSize(CoefWave, 0)
		Variable i
		for (i = 0; i < nCoefs; i += 1)
			if (CoefWave[i][HoldCol])
				HS += "1"
				nHolds += 1
			else
				HS += "0"
			endif
		endfor
		if (nHolds == 0)
			return ""			// ******** EXIT ***********
		endif
		// work from the end of the string removing extraneous zeroes
		//added by ARJN
		if(isLevORgen==0)	
			if (nHolds == 0)
				return ""			// ******** EXIT ***********
			endif	
			if (strlen(HS) > 1)
				for (i = strlen(HS)-1; i >= 0; i -= 1)
					if (CmpStr(HS[i], "1") == 0)
						break
					endif
				endfor
				if (i > 0)
					HS = HS[0,i]
				endif
			endif
		endif
		if (!justTheString)
			HS += "\""
		endif
		//		if (!quiet)
		//			print "Hold String=", HS
		//		endif
		return HS				// ******** EXIT ***********
	else
		return ""				// ******** EXIT ***********
	endif
end

//***********************************
//
// Constraints
//
//***********************************

static Function ConstraintsCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Variable NumSets = DimSize(ListWave, 0)
	Variable i

	if (checked)
		if (NumSets == 0)
			CheckBox NewGF_ConstraintsCheckBox, win=GlobalFitPanel, value=0
			DoAlert 0, "You cannot add constraints until you have selected data sets"
			return 0
		else
			NVAR/Z NewGF_RebuildCoefListNow = root:packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
			if (!NVAR_Exists(NewGF_RebuildCoefListNow) || NewGF_RebuildCoefListNow)
				NewGF_RebuildCoefListWave()
			endif
			Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
			Variable totalParams = 0
			Variable CoefSize = DimSize(CoefListWave, 0)
			for (i = 0; i < CoefSize; i += 1)
				if (!IsLinkText(CoefListWave[i][1]))
					totalParams += 1
				endif
			endfor

			String saveDF = GetDatafolder(1)
			SetDatafolder root:packages:motofitgf:NewGlobalFit
			
			Wave/T/Z SimpleConstraintsListWave
			if (!(WaveExists(SimpleConstraintsListWave) && (DimSize(SimpleConstraintsListWave, 0) == TotalParams)))
				Make/O/N=(TotalParams, 5)/T SimpleConstraintsListWave=""
			endif
			Variable CoefIndex = 0
			for (i = 0; i < CoefSize; i += 1)
				if (!IsLinkText(CoefListWave[i][1]))
					SimpleConstraintsListWave[CoefIndex][0] = "K"+num2istr(CoefIndex)
					SimpleConstraintsListWave[CoefIndex][1] = CoefListWave[i][1]
					SimpleConstraintsListWave[CoefIndex][3] = "< K"+num2istr(CoefIndex)+" <"
					CoefIndex += 1
				endif
			endfor
			Make/O/N=(TotalParams,5) SimpleConstraintsSelectionWave
			SimpleConstraintsSelectionWave[][0] = 0		// K labels
			SimpleConstraintsSelectionWave[][1] = 0		// coefficient labels
			SimpleConstraintsSelectionWave[][2] = 2		// editable- greater than constraints
			SimpleConstraintsSelectionWave[][3] = 0		// "< Kn <"
			SimpleConstraintsSelectionWave[][4] = 2		// editable- less than constraints
			SetDimLabel 1, 0, 'Kn', SimpleConstraintsListWave
			SetDimLabel 1, 1, 'Actual Coefficient', SimpleConstraintsListWave
			SetDimLabel 1, 2, 'Min', SimpleConstraintsListWave
			SetDimLabel 1, 3, ' ', SimpleConstraintsListWave
			SetDimLabel 1, 4, 'Max', SimpleConstraintsListWave
			
			Wave/Z/T MoreConstraintsListWave
			if (!WaveExists(MoreConstraintsListWave))
				Make/N=(1,1)/T/O  MoreConstraintsListWave=""
				Make/N=(1,1)/O MoreConstraintsSelectionWave=6
				SetDimLabel 1,0,'Enter Constraint Expressions', MoreConstraintsListWave
			endif
			MoreConstraintsSelectionWave=6
			
			SetDatafolder $saveDF
			
			if (WinType("NewGF_GlobalFitConstraintPanel") > 0)
				DoWindow/F NewGF_GlobalFitConstraintPanel
			else
				fNewGF_GlobalFitConstraintPanel()
			endif
		endif
	endif
End

static Function fNewGF_GlobalFitConstraintPanel()

	NewPanel /W=(45,203,451,568)
	DoWindow/C NewGF_GlobalFitConstraintPanel
	AutoPositionWindow/M=0/E/R=MotoGlobalFitPanel NewGF_GlobalFitConstraintPanel

	GroupBox SimpleConstraintsGroup,pos={5,7},size={394,184},title="Simple Constraints"
	Button SimpleConstraintsClearB,pos={21,24},size={138,20},proc=MOTO_WM_NewGlobalFit1#SimpleConstraintsClearBProc,title="Clear List"
	ListBox constraintsList,pos={12,49},size={380,127},listwave=root:packages:MotofitGF:NewGlobalFit:SimpleConstraintsListWave
	ListBox constraintsList,selWave=root:packages:MotofitGF:NewGlobalFit:SimpleConstraintsSelectionWave, mode=7
	ListBox constraintsList,widths={30,189,50,40,50}, editStyle= 1,frame=2,userColumnResize=1

	GroupBox AdditionalConstraintsGroup,pos={5,192},size={394,138},title="Additional Constraints"
	ListBox moreConstraintsList,pos={12,239},size={380,85}, listwave=root:packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	ListBox moreConstraintsList,selWave=root:packages:MotofitGF:NewGlobalFit:MoreConstraintsSelectionWave, mode=4
	ListBox moreConstraintsList, editStyle= 1,frame=2,userColumnResize=1
	Button NewConstraintLineButton,pos={21,211},size={138,20},title="Add a Line", proc=MOTO_WM_NewGlobalFit1#NewGF_NewCnstrntLineButtonProc
	Button RemoveConstraintLineButton01,pos={185,211},size={138,20},title="Remove Selection", proc=MOTO_WM_NewGlobalFit1#RemoveConstraintLineButtonProc

	Button GlobalFitConstraintsDoneB,pos={6,339},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitConstraintsDoneBProc,title="Done"
EndMacro

static Function SimpleConstraintsClearBProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T SimpleConstraintsListWave = root:packages:MotofitGF:NewGlobalFit:SimpleConstraintsListWave
	SimpleConstraintsListWave[][2] = ""
	SimpleConstraintsListWave[][4] = ""
End

static Function NewGF_NewCnstrntLineButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T MoreConstraintsListWave = root:packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	Wave/Z MoreConstraintsSelectionWave = root:packages:MotofitGF:NewGlobalFit:MoreConstraintsSelectionWave
	Variable nRows = DimSize(MoreConstraintsListWave, 0)
	InsertPoints nRows, 1, MoreConstraintsListWave, MoreConstraintsSelectionWave
	MoreConstraintsListWave[nRows] = ""
	MoreConstraintsSelectionWave[nRows] = 6
	Redimension/N=(nRows+1,1) MoreConstraintsListWave, MoreConstraintsSelectionWave
End

static Function RemoveConstraintLineButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T MoreConstraintsListWave = root:packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	Wave/Z MoreConstraintsSelectionWave = root:packages:MotofitGF:NewGlobalFit:MoreConstraintsSelectionWave
	Variable nRows = DimSize(MoreConstraintsListWave, 0)
	Variable i = 0
	do
		if (MoreConstraintsSelectionWave[i] & 1)
			if (nRows == 1)
				MoreConstraintsListWave[0] = ""
				MoreConstraintsSelectionWave[0] = 6
			else
				DeletePoints i, 1, MoreConstraintsListWave, MoreConstraintsSelectionWave
				nRows -= 1
			endif
		else
			i += 1
		endif
	while (i < nRows)
	Redimension/N=(nRows,1) MoreConstraintsListWave, MoreConstraintsSelectionWave
End


static Function GlobalFitConstraintsDoneBProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K NewGF_GlobalFitConstraintPanel
End

static Function NewGF_MakeConstraintWave()

	Wave/Z/T SimpleConstraintsListWave = root:packages:MotofitGF:NewGlobalFit:SimpleConstraintsListWave
	Wave/Z/T MoreConstraintsListWave = root:packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	
	Make/O/T/N=0 root:packages:MotofitGF:NewGlobalFit:GFUI_GlobalFitConstraintWave
	Wave/T GlobalFitConstraintWave = root:packages:MotofitGF:NewGlobalFit:GFUI_GlobalFitConstraintWave
	Variable nextRow = 0
	String constraintExpression
	Variable i, nPnts=DimSize(SimpleConstraintsListWave, 0)
	for (i=0; i < nPnts; i += 1)
		if (strlen(SimpleConstraintsListWave[i][2]) > 0)
			InsertPoints nextRow, 1, GlobalFitConstraintWave
			sprintf constraintExpression, "K%d > %s", i, SimpleConstraintsListWave[i][2]
			GlobalFitConstraintWave[nextRow] = constraintExpression
			nextRow += 1
		endif
		if (strlen(SimpleConstraintsListWave[i][4]) > 0)
			InsertPoints nextRow, 1, GlobalFitConstraintWave
			sprintf constraintExpression, "K%d < %s", i, SimpleConstraintsListWave[i][4]
			GlobalFitConstraintWave[nextRow] = constraintExpression
			nextRow += 1
		endif
	endfor
	
	nPnts = DimSize(MoreConstraintsListWave, 0)
	for (i = 0; i < nPnts; i += 1)
		if (strlen(MoreConstraintsListWave[i]) > 0)
			InsertPoints nextRow, 1, GlobalFitConstraintWave
			GlobalFitConstraintWave[nextRow] = MoreConstraintsListWave[i]
			nextRow += 1
		endif
	endfor
end

//***********************************
//
// Weighting
//
//***********************************

static Function NewGF_WeightingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	if (checked)
		Wave/T ListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		Variable numSets = DimSize(ListWave, 0)

		if (NumSets == 0)
			CheckBox NewGF_WeightingCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea, value=0
			DoAlert 0, "You cannot choose weighting waves until you have selected data sets."
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:packages:motofitgf:NewGlobalFit
			
			Wave/T/Z WeightingListWave
			if (!(WaveExists(WeightingListWave) && (DimSize(WeightingListWave, 0) == NumSets)))
				Make/O/N=(NumSets, 2)/T WeightingListWave=""
			endif
			WeightingListWave[][0] = ListWave[p][0][1]
			Make/O/N=(NumSets, 2) WeightingSelectionWave
			WeightingSelectionWave[][0] = 0		// Data Sets
			WeightingSelectionWave[][1] = 0		// Weighting Waves; not editable- select from menu
			SetDimLabel 1, 0, 'Data Set', WeightingListWave
			SetDimLabel 1, 1, 'Weight Wave', WeightingListWave
			
			SetDatafolder $saveDF
			
			if (WinType("NewGF_WeightingPanel") > 0)
				DoWindow/F NewGF_WeightingPanel
			else
				fNewGF_WeightingPanel()
			endif
			
			Variable/G root:packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD = NumVarOrDefault("root:packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD", 1)
			NVAR GlobalFit_WeightsAreSD = root:packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD
			if (GlobalFit_WeightsAreSD)
				WeightsSDRadioProc("WeightsSDRadio",1)
			else
				WeightsSDRadioProc("WeightsInvSDRadio",1)
			endif
						
		endif
	endif	
end

static Function fNewGF_WeightingPanel() : Panel

	NewPanel /W=(339,193,745,408)
	DoWindow/C NewGF_WeightingPanel
	AutoPositionWindow/M=0/E/R=MotoGlobalFitPanel NewGF_WeightingPanel
	
	ListBox WeightWaveListBox,pos={9,63},size={387,112}, mode=10, listWave = root:packages:MotofitGF:NewGlobalFit:WeightingListWave,userColumnResize=1
	ListBox WeightWaveListBox, selWave = root:packages:MotofitGF:NewGlobalFit:WeightingSelectionWave, frame=2,proc=MOTO_WM_NewGlobalFit1#NewGF_WeightListProc

	Button GlobalFitWeightDoneButton,pos={24,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitWeightDoneButtonProc,title="Done"
	Button GlobalFitWeightCancelButton,pos={331,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitWeightCancelButtonProc,title="Cancel"

	PopupMenu GlobalFitWeightWaveMenu,pos={9,5},size={152,20},title="Select Weight Wave"
	PopupMenu GlobalFitWeightWaveMenu,mode=0,value= #"WM_NewGlobalFit1#ListPossibleWeightWaves()", proc=MOTO_WM_NewGlobalFit1#WeightWaveSelectionMenu

	//	Button WeightClearSelectionButton,pos={276,5},size={120,20},proc=MOTO_WM_NewGlobalFit1#WeightClearSelectionButtonProc,title="Clear Selection"
	//	Button WeightClearAllButton,pos={276,32},size={120,20},proc=MOTO_WM_NewGlobalFit1#WeightClearSelectionButtonProc,title="Clear All"

	GroupBox WeightStdDevRadioGroup,pos={174,4},size={95,54},title="Weights  are"

	CheckBox WeightsSDRadio,pos={185,22},size={60,14},proc=MOTO_WM_NewGlobalFit1#WeightsSDRadioProc,title="Std. Dev."
	CheckBox WeightsSDRadio,value= 0, mode=1
	CheckBox WeightsInvSDRadio,pos={185,38},size={73,14},proc=MOTO_WM_NewGlobalFit1#WeightsSDRadioProc,title="1/Std. Dev."
	CheckBox WeightsInvSDRadio,value= 0, mode=1
EndMacro

static Function NewGF_WeightListProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if (event == 1)
		Wave/T/Z WeightingListWave=root:packages:MotofitGF:NewGlobalFit:WeightingListWave
		Variable NumSets = DimSize(WeightingListWave, 0)
		if ( (row == -1) && (col == 1) )
			Wave WeightingSelWave = root:packages:MotofitGF:NewGlobalFit:WeightingSelectionWave
			WeightingSelWave[][1] = 1
		elseif ( (col == 1) && (row >= 0) && (row < NumSets) )
			if (GetKeyState(0) == 0)
				Wave/Z w = $(WeightingListWave[row][0])
				if (WaveExists(w))
					String RowsText = num2str(DimSize(w, 0))
					PopupContextualMenu "_calculated_;"+WaveList("*",";","MINROWS:"+RowsText+",MAXROWS:"+RowsText+",DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
					if (V_flag > 0)
						Wave/Z w = $S_selection
						if (WaveExists(w))
							WeightingListWave[row][1] = GetWavesDataFolder(w, 2)
						endif
					endif
				endif
			endif
		endif
	endif 
end

static Function GlobalFitWeightDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z WeightingListWave=root:packages:MotofitGF:NewGlobalFit:WeightingListWave
	Variable NumSets = DimSize(WeightingListWave, 0)
	
	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(WeightingListWave[i][1])
		if (!WaveExists(w))
			ListBox WeightWaveListBox, win=NewGF_WeightingPanel, selRow = i
			DoAlert 0, "The wave \""+WeightingListWave[i][1]+"\" does not exist."
			WeightingListWave[i][1] = ""
			return -1
		endif
	endfor
		
	DoWindow/K NewGF_WeightingPanel
End

static Function GlobalFitWeightCancelButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K NewGF_WeightingPanel
	CheckBox NewGF_WeightingCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea, value=0
End

static Function/S ListPossibleWeightWaves()

	Wave/T/Z WeightingListWave=root:packages:MotofitGF:NewGlobalFit:WeightingListWave
	Wave/Z WeightingSelectionWave=root:packages:MotofitGF:NewGlobalFit:WeightingSelectionWave

	String DataSetName=""
	Variable i
	
	ControlInfo/W=NewGF_WeightingPanel WeightWaveListBox
	DataSetName = WeightingListWave[V_value][0]
	
	if (strlen(DataSetName) == 0)
		return "No Selection;"
	endif
	
	Wave/Z ds = $DataSetName
	if (!WaveExists(ds))
		return "Bad Data Set:"+DataSetName+";"
	endif
	
	Variable numpoints = DimSize(ds, 0)
	String theList = ""
	i=0
	do
		Wave/Z w = WaveRefIndexed("", i, 4)
		if (!WaveExists(w))
			break
		endif
		if ( (DimSize(w, 0) == numpoints) && (WaveType(w) & 6) )		// select floating-point waves with the right number of points
			theList += NameOfWave(w)+";"
		endif
		i += 1
	while (1)
	
	if (i == 0)
		return "None Available;"
	endif
	
	return theList
end

static Function WeightWaveSelectionMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	Wave/Z w = $popStr
	if (WaveExists(w))
		Wave/T WeightingListWave=root:packages:MotofitGF:NewGlobalFit:WeightingListWave
		Wave WeightingSelWave = root:packages:MotofitGF:NewGlobalFit:WeightingSelectionWave
		Variable nrows = DimSize(WeightingListWave, 0)
		Variable i
		for (i = 0; i < nrows; i += 1)
			if ( (WeightingSelWave[i][0] & 1) || (WeightingSelWave[i][1]) )
				WeightingListWave[i][1] = GetWavesDatafolder(w, 2)
			endif
		endfor
	endif
end

//static Function WeightClearSelectionButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	Wave/T/Z WeightingListWave=root:packages:MotofitGF:NewGlobalFit:WeightingListWave
//	StrSwitch (ctrlName)
//		case "WeightClearSelectionButton":
//			Wave WeightingSelWave = root:packages:MotofitGF:NewGlobalFit:WeightingSelectionWave
//			Variable nrows = DimSize(WeightingListWave, 0)
//			Variable i
//			for (i = 0; i < nrows; i += 1)
//				if ( (WeightingSelWave[i][0] & 1) || (WeightingSelWave[i][1]) )
//					WeightingListWave[i][1] = ""
//				endif
//			endfor
//			break;
//		case "WeightClearAllButton":
//			WeightingListWave[][1] = ""
//			break;
//	endswitch
//End

static Function WeightsSDRadioProc(name,value)
	String name
	Variable value
	
	NVAR GlobalFit_WeightsAreSD= root:packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD
	
	strswitch (name)
		case "WeightsSDRadio":
			GlobalFit_WeightsAreSD = 1
			break
		case "WeightsInvSDRadio":
			GlobalFit_WeightsAreSD = 0
			break
	endswitch
	CheckBox WeightsSDRadio, win=NewGF_WeightingPanel, value= GlobalFit_WeightsAreSD==1
	CheckBox WeightsInvSDRadio, win=NewGF_WeightingPanel, value= GlobalFit_WeightsAreSD==0
End

// This function is strictly for the use of the Global Analysis control panel. It assumes that the DataSets
// wave so far has just two columns, the Y and X wave columns
static Function GFUI_AddWeightWavesToDataSets(DataSets)
	Wave/T DataSets
	
	Wave/T/Z WeightingListWave=root:packages:MotofitGF:NewGlobalFit:WeightingListWave
	
	Redimension/N=(-1, 3) DataSets
	SetDimLabel 1, 2, Weights, DataSets
	
	Variable numSets = DimSize(DataSets, 0)
	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(WeightingListWave[i][1])
		if (WaveExists(w))
			wave/Z yw = $(DataSets[i][0])
			if (WaveExists(yw) && (numpnts(w) != numpnts(yw)))
				DoAlert 0,"The weighting wave \""+WeightingListWave[i][1]+"\" has a different number points than Y wave \""+(DataSets[i][0])+"\""
				return -1
			endif
			DataSets[i][2] = WeightingListWave[i][1]
		else
			Redimension/N=(-1,2) DataSets
			DoAlert 0,"The weighting wave \""+WeightingListWave[i][1]+"\" for Y wave \""+(DataSets[i][0])+"\" does not exist."
			return -1
		endif
	endfor
	
	return 0
end

static Function GFUI_AddMaskWavesToDataSets(DataSets)
	Wave/T DataSets
	
	Wave/T/Z MaskingListWave=root:packages:MotofitGF:NewGlobalFit:MaskingListWave
	
	Variable startingNCols = DimSize(DataSets, 1)
	Redimension/N=(-1, startingNCols+1) DataSets
	SetDimLabel 1, startingNCols, Masks, DataSets
	
	Variable numSets = DimSize(DataSets, 0)
	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(MaskingListWave[i][1])
		if (WaveExists(w))
			wave/Z yw = $(DataSets[i][0])
			if (WaveExists(yw) && (numpnts(w) != numpnts(yw)))
				DoAlert 0,"The mask wave \""+MaskingListWave[i][1]+"\" has a different number points than Y wave \""+(DataSets[i][0])+"\""
				return -1
			endif
			DataSets[i][startingNCols] = MaskingListWave[i][1]
		else
			Redimension/N=(-1,startingNCols) DataSets
			DoAlert 0,"The mask wave \""+MaskingListWave[i][1]+"\" for Y wave \""+(DataSets[i][0])+"\" does not exist."
			return -1
		endif
	endfor
	
	return 0
end


static Function NewGF_CovMatrixCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if (!checked)
		Checkbox NewGF_CorrelationMatrixCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=0
	endif
End

static Function NewGF_CorMatrixCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if (checked)
		Checkbox NewGF_DoCovarMatrix, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=1
	endif
End


static Function NewGF_FitCurvesCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if (!checked)
		Checkbox NewGF_AppendResultsCheckbox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=0
		Checkbox NewGF_DoResidualCheck, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=0
	endif
End

static Function NewGF_AppendResultsCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if (checked)
		Checkbox NewGF_MakeFitCurvesCheck, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=1
	endif
End

static Function NewGF_CalcResidualsCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	if (checked)
		Checkbox NewGF_MakeFitCurvesCheck, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,value=1
	endif
End


//***********************************
//
// Data masking
//
//***********************************

static Function NewGF_MaskingCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	if (checked)
		Wave/T DataSetList = root:packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		Variable numSets = DimSize(DataSetList, 0)

		if (NumSets == 0)
			CheckBox NewGF_MaskingCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea, value=0
			DoAlert 0, "You cannot add Masking waves until you have selected data sets."
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:packages:motofitgf:NewGlobalFit
			
			Wave/T/Z MaskingListWave
			if (!(WaveExists(MaskingListWave) && (DimSize(MaskingListWave, 0) == NumSets)))
				Make/O/N=(NumSets, 2)/T MaskingListWave=""
			endif
			MaskingListWave[][0] = DataSetList[p][0][1]
			Make/O/N=(NumSets, 2) MaskingSelectionWave
			MaskingSelectionWave[][0] = 0		// Data Sets
			MaskingSelectionWave[][1] = 0		// Masking Waves; not editable- select from menu
			SetDimLabel 1, 0, 'Data Set', MaskingListWave
			SetDimLabel 1, 1, 'Mask Wave', MaskingListWave
			
			SetDatafolder $saveDF
			
			if (WinType("NewGF_GlobalFitMaskingPanel") > 0)
				DoWindow/F NewGF_GlobalFitMaskingPanel
			else
				fNewGF_GlobalFitMaskingPanel()
			endif
		endif
	endif	
end

static Function fNewGF_GlobalFitMaskingPanel() : Panel

	NewPanel /W=(339,193,745,408)
	DoWindow/C NewGF_GlobalFitMaskingPanel
	AutoPositionWindow/M=0/E/R=MotoGlobalFitPanel NewGF_GlobalFitMaskingPanel
	
	ListBox MaskWaveListBox,pos={9,63},size={387,112}, mode=10, listWave = root:packages:MotofitGF:NewGlobalFit:MaskingListWave,userColumnResize=1
	ListBox MaskWaveListBox, selWave = root:packages:MotofitGF:NewGlobalFit:MaskingSelectionWave, frame=2, proc=MOTO_WM_NewGlobalFit1#NewGF_MaskListProc
	Button GlobalFitMaskDoneButton,pos={24,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitMaskDoneButtonProc,title="Done"
	Button GlobalFitMaskCancelButton,pos={331,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitMaskCancelButtonProc,title="Cancel"
	PopupMenu GlobalFitMaskWaveMenu,pos={9,5},size={152,20},title="Select Mask Wave"
	PopupMenu GlobalFitMaskWaveMenu,mode=0,value= #"WM_NewGlobalFit1#ListPossibleMaskWaves()", proc=MOTO_WM_NewGlobalFit1#MaskWaveSelectionMenu
	Button MaskClearSelectionButton,pos={276,5},size={120,20},proc=MOTO_WM_NewGlobalFit1#MaskClearSelectionButtonProc,title="Clear Selection"
	Button MaskClearAllButton,pos={276,32},size={120,20},proc=MOTO_WM_NewGlobalFit1#MaskClearSelectionButtonProc,title="Clear All"
EndMacro


static Function NewGF_MaskListProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if (event == 1)
		Wave/T/Z MaskingListWave=root:packages:MotofitGF:NewGlobalFit:MaskingListWave
		Variable numSets = DimSize(MaskingListWave, 0)
		if ( (row == -1) && (col == 1) )
			Wave MaskingSelWave = root:packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
			MaskingSelWave[][1] = 1
		elseif ( (col == 1) && (row >= 0) && (row < NumSets) )
			if (GetKeyState(0) == 0)
				Wave/Z w = $(MaskingListWave[row][0])
				if (WaveExists(w))
					String RowsText = num2str(DimSize(w, 0))
					PopupContextualMenu "_calculated_;"+WaveList("*",";","MINROWS:"+RowsText+",MAXROWS:"+RowsText+",DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
					if (V_flag > 0)
						Wave/Z w = $S_selection
						if (WaveExists(w))
							MaskingListWave[row][1] = GetWavesDataFolder(w, 2)
						endif
					endif
				endif
			endif
		endif
	endif 
end

static Function GlobalFitMaskDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z MaskingListWave=root:packages:MotofitGF:NewGlobalFit:MaskingListWave
	Variable numSets = DimSize(MaskingListWave, 0)

	Variable i
	for (i = 0; i < NumSets; i += 1)
		Wave/Z w = $(MaskingListWave[i][1])
		if (!WaveExists(w))
			if (strlen(MaskingListWave[i][1]) != 0)
				ListBox MaskWaveListBox, win=NewGF_GlobalFitMaskingPanel, selRow = i
				DoAlert 0, "The wave \""+MaskingListWave[i][1]+"\" does not exist."
				MaskingListWave[i][1] = ""
				return -1
			endif
		endif
	endfor
		
	DoWindow/K NewGF_GlobalFitMaskingPanel
End

static Function GlobalFitMaskCancelButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K NewGF_GlobalFitMaskingPanel
	CheckBox NewGF_MaskingCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea, value=0
End

static Function/S ListPossibleMaskWaves()

	Wave/T/Z MaskingListWave=root:packages:MotofitGF:NewGlobalFit:MaskingListWave
	Wave/Z MaskingSelectionWave=root:packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
	Variable NumSets= DimSize(MaskingListWave, 0)

	String DataSetName=""
	Variable i
	
	ControlInfo/W=NewGF_GlobalFitMaskingPanel MaskWaveListBox
	DataSetName = MaskingListWave[V_value][0]
	
	if (strlen(DataSetName) == 0)
		return "No Selection;"
	endif
	
	Wave/Z ds = $DataSetName
	if (!WaveExists(ds))
		return "Unknown Data Set;"
	endif
	
	Variable numpoints = DimSize(ds, 0)
	String theList = ""
	i=0
	do
		Wave/Z w = WaveRefIndexed("", i, 4)
		if (!WaveExists(w))
			break
		endif
		if ( (DimSize(w, 0) == numpoints) && (WaveType(w) & 6) )		// select floating-point waves with the right number of points
			theList += NameOfWave(w)+";"
		endif
		i += 1
	while (1)
	
	if (i == 0)
		return "None Available;"
	endif
	
	return theList
end

static Function MaskWaveSelectionMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	Wave/Z w = $popStr
	if (WaveExists(w))
		Wave/T MaskingListWave=root:packages:MotofitGF:NewGlobalFit:MaskingListWave
		Wave MaskingSelWave = root:packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
		Variable nrows = DimSize(MaskingListWave, 0)
		Variable i
		for (i = 0; i < nrows; i += 1)
			if ( (MaskingSelWave[i][0] & 1) || (MaskingSelWave[i][1]) )
				MaskingListWave[i][1] = GetWavesDatafolder(w, 2)
			endif
		endfor
	endif
end

static Function MaskClearSelectionButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T/Z MaskingListWave=root:packages:MotofitGF:NewGlobalFit:MaskingListWave
	StrSwitch (ctrlName)
		case "MaskClearSelectionButton":
			Wave MaskingSelWave = root:packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
			Variable nrows = DimSize(MaskingListWave, 0)
			Variable i
			for (i = 0; i < nrows; i += 1)
				if ( (MaskingSelWave[i][0] & 1) || (MaskingSelWave[i][1]) )
					MaskingListWave[i][1] = ""
				endif
			endfor
			break;
		case "MaskClearAllButton":
			MaskingListWave[][1] = ""
			break;
	endswitch
End



//***********************************
//
// Load/Save initial guesses from/to a wave
//
//***********************************

Function/S MOTO_ListInitGuessWaves(SelectedOnly, LinkRowsOK)
	Variable SelectedOnly
	Variable LinkRowsOK

	Variable numrows
	//	ControlInfo/W=MotoGlobalFitPanel#Tab1ContentPanel NewGF_InitGuessCopySelCheck
	if (SelectedOnly)
		numrows = totalSelRealCoefsFromCoefList(LinkRowsOK)
	else
		numrows = totalRealCoefsFromCoefList(LinkRowsOK)
	endif
	
	String numrowsstr = num2str(numrows)
	return WaveList("*", ";", "DIMS:1,MINROWS:"+numrowsstr+",MAXROWS:"+numrowsstr+",BYTE:0,INTEGER:0,WORD:0,CMPLX:0,TEXT:0")
end

char ctrlName[MAX_OBJ_NAME+1]	Control name.
char win[MAX_WIN_PATH+1]	Host (sub)window.
STRUCT Rect winRect	Local coordinates of host window.
STRUCT Rect ctrlRect	Enclosing rectangle of the control.
STRUCT Point mouseLoc	Mouse location.
Int32 eventCode	Event that caused the procedure to execute. Main event is mouse up=2.
String userdata	Primary (unnamed) user data. If this changes, it is written back automatically.
Int32 popNum	Item number currently selected (1-based).
char popStr[MAXCMDLEN]	Contents of current popup item.

Function MOTO_NewGF_SetCoefsFromWaveProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
		Wave w = $(PU_Struct.popStr)
		if (!WaveExists(w))
			DoAlert 0, "The wave you selected does not exist for some reason."
			return 0
		endif
		
		SetCoefListFromWave(w, 2, 0, 0)
	endif
end

Function MOTO_NewGF_SaveCoefsToWaveProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
		if (CmpStr(PU_Struct.popStr, "New Wave...") == 0)
			Variable numRowsNeeded = totalRealCoefsFromCoefList(0)
			String newName = MOTO_NewGF_GetNewWaveName()
			if (strlen(newName) == 0)
				return 0
			endif
			Make/O/N=(numRowsNeeded)/D $newName
			Wave w = $newName
		else
			Wave w = $(PU_Struct.popStr)
		endif
		
		SaveCoefListToWave(w, 2, 0, 0)
	endif
end

Function/S MOTO_NewGF_GetNewWaveName()

	String newName
	Prompt newName, "Enter a name for the new wave:"
	DoPrompt "Get New Wave Name", newName
	if (V_flag)
		return ""
	endif
	
	return newName
end
	
//***********************************
//
// Utility functions
//
//***********************************

// returns semicolon-separated list of items in a selected column of a 1D or 2D text wave
static Function/S TextWaveToList(twave, column)
	Wave/T twave
	Variable column
	
	String returnValue = ""
	Variable nRows = DimSize(twave, 0)
	Variable i
	
	for (i = 0; i < nRows; i += 1)
		returnValue += (twave[i][column])+";"
	endfor
	
	return returnValue
end

static Function IsLinkText(theText)
	String theText
	
	return (CmpStr(theText[0,4], "LINK:") == 0)
end

static Function ItemListedInWave(Item, theWave)
	String Item
	Wave/T theWave
	
	return ItemNumberInTextWaveList(Item, theWave) >= 0
end

static Function ItemNumberInTextWaveList(Item, theWave)
	String Item
	Wave/T theWave
	
	Variable i
	Variable npnts = DimSize(theWave, 0)
	Variable itemNumber = -1
	
	for (i = 0; i < npnts; i += 1)
		if ( (strlen(theWave[i]) > 0) && (CmpStr(theWave[i], Item) == 0) )
			itemNumber = i
			break
		endif
	endfor
	
	return itemNumber
end

// makes a 1D or 2D text wave with each item from a semicolon-separated list in the wave's rows
// in the selected column. You are free to fill other columns as you wish.
static Function ListToTwave(theList, twaveName, columns, column)
	String theList
	String twaveName
	Variable columns
	Variable column
	
	Variable nRows = ItemsInList(theList)
	Variable i
	
	Make/T/O/N=(nRows, columns) $twaveName
	Wave/T twave = $twaveName
	
	for (i = 0; i < nRows; i += 1)
		twave[i][column] = StringFromList(i, theList)
	endfor
end

static Function totalCoefsFromCoefList()

	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	
	return DimSize(CoefListWave, 0)
end

static Function totalRealCoefsFromCoefList(LinkRowsOK)
	Variable LinkRowsOK

	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave

	Variable i
	Variable totalNonlinkRows = 0
	Variable numrows = DimSize(CoefListWave, 0)
	for (i = 0; i < numrows; i += 1)
		if (LinkRowsOK || !IsLinkText(CoefListWave[i][1]))
			totalNonlinkRows += 1
		endif
	endfor
	
	return totalNonlinkRows
end

static Function totalSelRealCoefsFromCoefList(LinkRowsOK)
	Variable LinkRowsOK

	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave

	Variable i
	Variable totalNonlinkRows = 0
	Variable numrows = DimSize(CoefListWave, 0)
	for (i = 0; i < numrows; i += 1)
		if (LinkRowsOK || !IsLinkText(CoefListWave[i][1]))
			if (IsRowSelected(CoefSelWave, i))
				totalNonlinkRows += 1
			endif
		endif
	endfor
	
	return totalNonlinkRows
end

static Function SetCoefListFromWave(w, col, SetOnlySelectedCells, OKtoSetLinkRows)
	Wave w
	Variable col
	Variable SetOnlySelectedCells
	Variable OKtoSetLinkRows
	
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave

	Variable coefIndex = 0;
	Variable i,j
	Variable nTotalCoefs = DimSize(CoefListWave, 0)
	
	String formatStr = "%.15g"
	if ( (WaveType(w) & 4) == 0)		// it's not a double-precision wave
		formatStr = "%.6g"
	endif
	
	for (i = 0; i < nTotalCoefs; i += 1)		// indent 1
		//		if ( SetOnlySelectedCells && ((CoefSelWave[i][col] & 9) == 0) )
		if ( SetOnlySelectedCells && !IsRowSelected(CoefSelWave, i) )
			continue
		endif
		//		if (!OKtoSetLinkRows && !IsLinkText(CoefListWave[i][1]))
		if (!IsLinkText(CoefListWave[i][1]))		// indent 2
			// first part sets the coefficient list wave text from the appropriate element in the input wave
		
			if (col == 3)
				if (w[coefIndex][0])
					CoefSelWave[i][col] = 0x20 + 0x10
				else
					CoefSelWave[i][col] = 0x20
				endif
			else
				string dumstr
				sprintf dumstr, formatStr, w[coefIndex][0]
				Variable nstr = strlen(dumstr)
				for (j = 0; j < nstr; j += 1)
					if (char2num(dumstr[j]) != char2num(" "))
						break
					endif
				endfor
				if (j > 0)
					dumstr = dumstr[j, strlen(dumstr)-1]
				endif
				CoefListWave[i][col] = dumstr
			endif
		else		// indent 2
			string linktext
			// We've hit a link cell (refers to an earlier row)
			// 
			// If we are setting the entire wave, rather than setting the value in the row, we should instead copy the value
			// from the row containing the master copy (the row to which the link refers). (first IF block)
			//
			// If we are setting selected rows, and one of them is a link to another row, we should set the value of the master row
			// and any other rows that link to it.
			if (!SetOnlySelectedCells) 		// indent 3
				// copy linked text from master row when we encounter a linked cell. The links should always be after the cell they link to.
				linktext = (CoefListWave[i][1])[5,strlen(CoefListWave[i][1])-1]
				for (j = 0; j < nTotalCoefs; j += 1)
					if (CmpStr(linktext, CoefListWave[j][1]) == 0)
						if (col == 3)
							if (CoefSelWave[j][col] & 0x10)
								CoefListWave[i][col] = " X"
							else
								CoefListWave[i][col] = ""
							endif
						else
							CoefListWave[i][col] = CoefListWave[j][col]
						endif
						break
					endif
				endfor
				continue		// skip incrementing coefIndex
			elseif (OKtoSetLinkRows)		// indent 3
				linktext = (CoefListWave[i][1])[5,strlen(CoefListWave[i][1])-1]
				for (j = 0; j < nTotalCoefs; j += 1)		// indent 4
					if ( (CmpStr(linktext, CoefListWave[j][1]) == 0) || (CmpStr(CoefListWave[i][1], CoefListWave[j][1]) == 0) )		// indent 5
						// we have found the master row						or one of the linked rows
						if (col == 3)		// indent 6
							if (w[coefIndex][0])
								CoefSelWave[j][col] = 0x20 + 0x10
							else
								CoefSelWave[j][col] = 0x20
							endif
						else		// indent 6
							sprintf dumstr, formatStr, w[coefIndex][0]
							nstr = strlen(dumstr)
							Variable k
							for (k = 0; k < nstr; k += 1)
								if (char2num(dumstr[k]) != char2num(" "))
									break
								endif
							endfor
							if (k > 0)
								dumstr = dumstr[k, strlen(dumstr)-1]
							endif
							CoefListWave[j][col] = dumstr
						endif		// indent 6
						//						coefIndex += 1
					endif		// indent 5
				endfor		// indent 4
			endif		// indent 3
		endif		// indent 2
		coefIndex += 1
	endfor		// indent 1
end

static Function SaveCoefListToWave(w, col, SaveOnlySelectedCells, OKToSaveLinkCells)
	Wave w
	Variable col
	Variable SaveOnlySelectedCells
	Variable OKToSaveLinkCells
	
	Wave/T CoefListWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	Variable ntotalCoefs = totalCoefsFromCoefList()
	Variable i
	Variable waveIndex = 0
	
	for (i = 0; i < ntotalCoefs; i += 1)
		if (OKToSaveLinkCells || !IsLinkText(CoefListWave[i][1]))
			if ( SaveOnlySelectedCells && !IsRowSelected(CoefSelWave, i) )
				continue
			endif
			if (col == 3)
				w[waveIndex] = ((CoefSelWave[i][col] & 0x10) != 0)
			else
				w[waveIndex] = str2num(CoefListWave[i][col])
			endif
			waveIndex += 1
		endif
	endfor
end

static Function FindSelectedRows(SelectionWave)
	Wave SelectionWave
	
	Variable rows = DimSize(SelectionWave, 0)
	Variable cols = DimSize(SelectionWave, 1)
	Variable i,j
	Variable rowsSelected = 0
	
	for (i = 0; i < rows; i += 1)
		for (j = 0; j < cols; j += 1)
			if (IsRowSelected(SelectionWave, i))
				rowsSelected += 1
				break;
			endif
		endfor
	endfor
	
	return rowsSelected;
end

static Function IsRowSelected(SelectionWave, row)
	Wave SelectionWave
	Variable row
	
	Variable cols = DimSize(SelectionWave, 1)
	Variable j
	
	for (j = 0; j < cols; j += 1)
		if (SelectionWave[row][j] & 9)
			return 1
			break;
		endif
	endfor
	
	return 0;
end

Function MOTO_DoNewGlobalSim(FitFuncNames, DataSets, CoefDataSetLinkage, CoefWave, CoefNames, ConstraintWave, Options, FitCurvePoints, DoAlertsOnError, [errorName])
	Wave/T FitFuncNames		// a text wave containing a list of the fit functions to be used in this fit.

	Wave/T DataSets			// Wave containing a list of data sets.
	// Column 0 contains Y data sets.
	// Column 1 contains X data sets. Enter _calculated_ in a row if appropriate.
	// A column with label "Weights", if it exists, contains names of weighting waves for each dataset.
	// A column with label "Masks", if it exists, contains names of mask waves for each data set.

	Wave CoefDataSetLinkage	// a matrix wave with a row for each data set and N+2 columns, where N is the maximum number of coefficients
	// used by any of the fit functions. It looks like this for a hypothetical case of two functions and four
	// data sets:
								
	//		|	f()	first	last	N	c0	c1	c2	c3	c4	c5
	//	---|-----------------------------
	//	ds1	|	0	0		100		5	0	1	2	3	4	-1
	//	ds2	|	0	101		150		5	5	6	2	7	4	-1
	//	ds3	|	1	151		220		6	8	9	2	10	11	12
	//	ds4	|	1	221		300		6	13	14	2	15	16	12

	// In this matrix, I imagine fitting to two functions, one of which takes 5 coefficients, the other 6. 
	// Coefficients 0, 1, and 3 for function f1 are local- they have distinct coefficient array indices 
	// everywhere. Coefficient 2 is global- the same coefficient array index is used for every data set. 
	// Coefficient 4 is "shared local" (group global?)- it is global for ds1 and ds2. The corresponding 
	// coefficient for ds3 and ds4 is local- it probably refers to something entirely different. Function 
	// f1 has no coefficient 5- hence the -1. For f2, coefficient 5 is shared between the data sets (ds3 
	// and ds4) which use f2. The column labelled N is the number of coefficients needed by the fit function.
	// The column labelled f() has an index into the FitFuncNames wave.
	// These columns are set up by the function in its private copy. You can set them to zero:
	// The column labelled first contains the point number where that data set starts in the cumulative waves.
	// The column labelled last contains the point number where the last point of that data set resides in the cumulative waves
								
	Wave CoefWave				// Wave containing initial guesses. The entries in the second and greater columns of the CoefDataSetLinkage
	// wave are indices into this wave.
								
	// There is no particular order- make sure the order here and the indices in CoefDataSetLinkage are consistent.
								
	// Column 0 contains initial guesses
	// A column with label "Hold", if it exists, specifies held coefficients
	// A column with label "Epsilon", if it exists, holds epsilon values for the coefficients
								
	Wave/T/Z CoefNames		// optional text wave with same number of rows as CoefWave. Gives a name for referring to a particular
	// coefficient in coefWave. This is used only in reports to make them more readable. If you don't want to
	// use this wave, use $"" instead of wave name.

	Wave/T/Z ConstraintWave	// This constraint wave will be used straight as it comes, so K0, K1, etc. refer to the order of 
	// coefficients as laid out in CoefWave.
	// If no constraints, use $"".

	Variable Options			// 1: Append Results to Top Graph (implies option 64).
	// 2: Calculate Residuals
	// 4: Covariance Matrix
	// 8: Do Fit Graph (a graph showing the actual fit in progress)
	// 16: Quiet- No printing in History
	// 32: Weight waves contain Standard Deviation (0 means 1/SD)
	// 64: Make fit curve waves (even if option 1 is not turned on)
	// 128: Correlation matrix (implies option 4)

	Variable FitCurvePoints	// number of points for auto-destination waves

	Variable DoAlertsOnError	// if 1, this function puts up alert boxes with messages about errors. These alert boxes
	// may give more information than the error code returned from the function.

	String &errorName			// Wave name that was found to be in error. Only applies to certain errors.
	

	Variable i,j
	String saveDF = GetDataFolder(1)
	SetDataFolder root:
	NewDataFolder/O/S root:packages
	NewDataFolder/O/S root:packages:motofitgf
	NewDataFolder/O root:packages:motofitgf:NewGlobalFit

	SetDataFolder $saveDF
		
	Variable err
	Variable errorWaveRow, errorWaveColumn
	String errorWaveName
	Variable IsAllAtOnce
	
	IsAllAtOnce = GF_FunctionType(FitFuncNames[0])
	for (i = 0; i < DimSize(FitFuncNames, 0); i += 1)
		Variable functype = GF_FunctionType(FitFuncNames[i])
		if (functype == GF_FuncType_BadFunc)
			if (DoAlertsOnError)
				DoAlert 0, "The function "+FitFuncNames[i]+" is not of the proper format."
				return -1
			endif
		elseif (functype == GF_FuncType_NoFunc)
			if (DoAlertsOnError)
				DoAlert 0, "The function "+FitFuncNames[i]+" does not exist."
				return -1
			endif
		endif
		if (functype != IsAllAtOnce)
			if (DoAlertsOnError)
				DoAlert 0, "All your fit functions must be either regular fit functions or all-at-once functions. They cannot be mixed."
				return -1
			endif
		endif
	endfor
	
	Duplicate/O CoefDataSetLinkage, root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Wave privateLinkage = root:packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Duplicate/O/T FitFuncNames, root:packages:MotofitGF:NewGlobalFit:FitFuncList
	
	Variable DoResid=1
	Variable doWeighting=0
	Variable doMasking=0
	
	err = NewGF_CheckDSets_BuildCumWaves(DataSets, privateLinkage, doWeighting, doMasking, errorWaveName, errorWaveRow, errorWaveColumn)
	if (err < 0)
		if (err == MOTO_GlobalFitNO_DATASETS)
			DoAlert 0, "There are no data sets in the list of data sets."
		elseif (DoAlertsOnError)
			DoAlert 0, GF_DataSetErrorMessage(err, errorWaveName)
		endif
		if (!ParamIsDefault(errorName))
			errorName = errorWaveName
		endif
		return err
	endif
	Wave Xw = root:packages:MotofitGF:NewGlobalFit:XCumData
	Wave Yw = root:packages:MotofitGF:NewGlobalFit:YCumData
	Duplicate/O YW, root:packages:MotofitGF:NewGlobalFit:FitY
	Wave FitY = root:packages:MotofitGF:NewGlobalFit:FitY
	FitY = NaN
	
	Variable MaxFuncCoefs = 0
	for (i = 0; i < DimSize(DataSets, 0); i += 1)
		MaxFuncCoefs = max(MaxFuncCoefs, privateLinkage[i][NumFuncCoefsCol])
	endfor
	Make/O/D/N=(MaxFuncCoefs) root:packages:MotofitGF:NewGlobalFit:ScratchCoefs
	
	Make/D/O/N=(DimSize(CoefWave, 0)) root:packages:MotofitGF:NewGlobalFit:MasterCoefs	
	Wave MasterCoefs = root:packages:MotofitGF:NewGlobalFit:MasterCoefs
	MasterCoefs = CoefWave[p][0]
	
	if (!WaveExists(CoefNames))
		Make/T/O/N=(DimSize(CoefWave, 0)) root:packages:MotofitGF:NewGlobalFit:CoefNames
		Wave/T CoefNames = root:packages:MotofitGF:NewGlobalFit:CoefNames
		// go through the matrix backwards so that the name we end up with refers to it's first use in the matrix
		for (i = DimSize(privateLinkage, 0)-1; i >= 0 ; i -= 1)
			String fname = FitFuncNames[privateLinkage[i][FuncPointerCol]]
			for (j = DimSize(privateLinkage, 1)-1; j >= FirstCoefCol; j -= 1)
				if (privateLinkage[i][j] < 0)
					continue
				endif
				CoefNames[privateLinkage[i][j]] = fname+":C"+num2istr(j-FirstCoefCol)
			endfor
		endfor
	endif
	
	String Command=""
		
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif
	String SavedWindowCoords = WC_WindowCoordinatesGetStr("GlobalFitGraph", 0)
	if (strlen(SavedWindowCoords) > 0)
		Execute "Display/W=("+SavedWindowCoords+") as \"Motofit Global Analysis Progress\""
	else
		Display as "Motofit Global Analysis Progress"
	endif
	DoWindow/C GlobalFitGraph
	ColorTab2Wave Rainbow
	Wave M_colors
	Duplicate/O M_colors, root:packages:MotofitGF:NewGlobalFit:NewGF_TraceColors
	Wave colors = root:packages:MotofitGF:NewGlobalFit:NewGF_TraceColors
	Variable index = 0, size = DimSize(M_colors, 0)
	for (i = 0; i < size; i += 1)
		colors[i][] = M_colors[index][q]
		index += 37
		if (index >= size)
			index -= size
		endif
	endfor
	KillWaves/Z M_colors
	Variable nTraces = DimSize(privateLinkage, 0)
	for (i = 0; i < nTraces; i += 1)
		Variable start = privateLinkage[i][FirstPointCol]
		Variable theEnd = privateLinkage[i][LastPointCol]
		AppendToGraph Yw[start, theEnd] vs Xw[start, theEnd]
		AppendToGraph FitY[start, theEnd] vs Xw[start, theEnd]
	endfor
	DoUpdate
	for (i = 0; i < nTraces; i += 1)
		ModifyGraph mode[2*i]=2
		ModifyGraph marker[2*i]=8
		ModifyGraph lSize[2*i]=2
		ModifyGraph rgb[2*i]=(colors[i][0],colors[i][1],colors[i][2])
		ModifyGraph rgb[2*i+1]=(colors[i][0],colors[i][1],colors[i][2])
	endfor		
	ModifyGraph gbRGB=(17476,17476,17476)
	SetWindow GlobalFitGraph, hook = WC_WindowCoordinatesHook
			
	//residuals
	Duplicate/O Yw, root:packages:MotofitGF:NewGlobalFit:NewGF_ResidY
	Wave rw = root:packages:MotofitGF:NewGlobalFit:NewGF_ResidY
	for (i = 0; i < nTraces; i += 1)
		start = privateLinkage[i][FirstPointCol]
		theEnd = privateLinkage[i][LastPointCol]
		AppendToGraph/L=ResidLeftAxis rw[start, theEnd] vs Xw[start, theEnd]
	endfor
	DoUpdate
	for (i = 0; i < nTraces; i += 1)
		ModifyGraph mode[2*nTraces+i]=2
		ModifyGraph rgb[2*nTraces+i]=(colors[i][0],colors[i][1],colors[i][2])
		ModifyGraph lSize[2*nTraces+i]=2
	endfor
	ModifyGraph lblPos(ResidLeftAxis)=51
	ModifyGraph zero(ResidLeftAxis)=1
	ModifyGraph freePos(ResidLeftAxis)={0,kwFraction}
	ModifyGraph axisEnab(left)={0,0.78}
	ModifyGraph axisEnab(ResidLeftAxis)={0.82,1}
	
	string funcName
	if (isAllAtOnce)
		command = " MOTO_NewGlblFitFuncAllAtOnce("
	else
		command = " MOTO_NewGlblFitFunc("
	endif
	Command += "root:packages:MotofitGF:NewGlobalFit:MasterCoefs, "
	Command += "root:packages:MotofitGF:NewGlobalFit:FitY,"
	Command += "root:packages:MotofitGF:NewGlobalFit:XCumData)"
		
	execute command
	
	rw = YW - FitY
	
	SaveDF = GetDataFolder(1)
	SetDataFolder root:packages:motofitgf:NewGlobalFit
		
	NVAR/Z V_chisq
	NVAR/Z fit_npnts = V_npnts
	NVAR/Z fit_numNaNs = V_numNaNs
	NVAR/Z fit_numINFs = V_numINFs
	SetDataFolder $SaveDF

end
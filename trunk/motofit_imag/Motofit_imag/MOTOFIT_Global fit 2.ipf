#pragma rtGlobals=3	// Use modern global access method.
#pragma version = 1.19
#pragma IgorVersion = 6.20
#pragma ModuleName= MOTO_WM_NewGlobalFit1

#include <BringDestToFront>
#include <SaveRestoreWindowCoords>
#include <WaveSelectorWidget>
#include <PopupWaveSelector>

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
//	1.07	Fixed a bug in NewGF_SetCoefsFromWaveProc that caused problems with the Set from Wave menu.
//	1.08	Fixed a bug in NewGF_CoefRowForLink() that caused problems connected linked cells on the Coefficient
//				Control tab.
//	1.09	Added option for log-spaced X axis for destination waves.
//	1.10	Fixed the bug caused by the fix at 1.08. Had to create a new function: NewGF_CoefListRowForLink(); 
//			NewGF_CoefRowForLink() was being used for two different but related purposes.
//	1.11	Fixed endless feedback between data sets list and linkage list if scrolling in either ocurred very rapidly. It is
//			relatively easy to do with a scroll wheel.
//	1.12	Fixed a bug that could cause problems with the display of coefficient names in the list on the right in the
//			Data Sets and Functions tab.
//	1.13	Uses features new in 6.10 to improve error reporting.
//	1.14	Added control for setting maximum iterations.
//	1.15	Added draggable divider between lists on Data Sets and Functions tab.
//			Added creation of per-dataset sigma waves to go with the per-dataset coefficient waves.
//	1.16	New data set selector
//			fixed minor bug in New Data Folder option for choosing data folder for results: added ":" to the parent data folder choice.
//	1.17	Fixed bug: Null String error ocurred if you didn't have Fit Progress Graph selected.
//	1.18	 Fixed bugs:
//			When re-opening the control panel, call to WC_WindowCoordinatesSprintf had a zero last parameter instead of one, resulting in bad sizing on Windows.
//			When re-opening the control panel after closing it, InitNewGlobalFitGlobals() was called, destroying the last set-up.
//			Fixed several index-out-of-range errors.
//	1.19	Fixed bugs:
//			If you used fit functions with unequal numbers of parameters, NewGlblFitFunc and NewGlblFitFuncAllAtOnce would cause an index out of range error
//				during assignment to SC, due to -1 stored as a dummy in the extra slots in the CoefDataSetLinkage wave.
//			The use of a pre-made scratch wave as the temporary coefficient wave inside NewGlblFitFunc and NewGlblFitFuncAllAtOnce when using fit functions
//				having unequal numbers of parameters caused some fit functions to fail, if they depended on the number of points in the coefficient wave being exactly right.
//			Changed:
//			The temporary coefficent wave SC is now a free wave created inside NewGlblFitFunc and NewGlblFitFuncAllAtOnce instead of ScratchCoefs. That saves looking up
//				the ScratchCoefs wave, and the code required to maintain ScratchCoefs. The ScratchCoefs wave has been eliminated.
//**************************************

//**************************************
// Things to add in the future:
// 
//		Mask, constraint, weight panels should use wave selector widgets
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

//ARJN 4/2007
Function MOTO_NewGlblFitFunc(inpw, inyw, inxw)
	Wave inpw, inyw, inxw

	//ARJN 4/2007
	Wave Xw = root:Packages:MotofitGF:NewGlobalFit:XCumData
	Wave DataSetPointer = root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
	
	Wave CoefDataSetLinkage = root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Wave/T FitFuncList = root:Packages:MotofitGF:NewGlobalFit:FitFuncList
	Make/FREE/N=0/D SC
		
	Variable numSets = DimSize(CoefDataSetLinkage, 0)
	Variable CoefDataSetLinkageIndex, i	
	
	for (i = 0; i < NumSets; i += 1)
		Variable firstP = CoefDataSetLinkage[i][FirstPointCol]
		Variable lastP = CoefDataSetLinkage[i][LastPointCol]

		CoefDataSetLinkageIndex = DataSetPointer[firstP]
		//ARJN 4/2007
		FUNCREF MOTO_GFFitFuncTemplate theFitFunc = $(FitFuncList[CoefDataSetLinkage[CoefDataSetLinkageIndex][FuncPointerCol]])

		Redimension/N=(CoefDataSetLinkage[i][NumFuncCoefsCol]) SC		
		SC = inpw[CoefDataSetLinkage[CoefDataSetLinkageIndex][FirstCoefCol+p]]
		inyw[firstP, lastP] = theFitFunc(SC, Xw[p])
	endfor
end

//ARJN 4/2007
Function MOTO_NewGlblFitFuncAllAtOnce(inpw, inyw, inxw)
	Wave inpw, inyw, inxw
	
	Wave DataSetPointer = root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
	
	Wave CoefDataSetLinkage = root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Wave/T FitFuncList = root:Packages:MotofitGF:NewGlobalFit:FitFuncList
	Make/FREE/N=0/D SC
	
	Variable CoefDataSetLinkageIndex, i
	
	Variable numSets = DimSize(CoefDataSetLinkage, 0)
	for (i = 0; i < NumSets; i += 1)
		Variable firstP = CoefDataSetLinkage[i][FirstPointCol]
		Variable lastP = CoefDataSetLinkage[i][LastPointCol]

		CoefDataSetLinkageIndex = DataSetPointer[firstP]
		//ARJN
		FUNCREF MOTO_GFFitAllAtOnceTemplate theFitFunc = $(FitFuncList[CoefDataSetLinkage[CoefDataSetLinkageIndex][FuncPointerCol]])

		Duplicate/O/R=[firstP,lastP] inxw, TempXW, TempYW
		TempXW = inxw[p+firstP]

		Redimension/N=(CoefDataSetLinkage[i][NumFuncCoefsCol]) SC
		SC = inpw[CoefDataSetLinkage[i][p+FirstCoefCol]]
		theFitFunc(SC, TempYW, TempXW)
		inyw[firstP, lastP] = TempYW[p-firstP]		
	endfor
end

//---------------------------------------------
//  Function that actually does a global fit, independent of the GUI
//---------------------------------------------	

//ARJN
constant MOTO_NewGlobalFitNO_DATASETS = -1
constant MOTO_GlobalFitBAD_FITFUNC = -2
constant MOTO_NewGlobalFitBAD_YWAVE = -3
constant MOTO_NewGlobalFitBAD_XWAVE = -4
constant MOTO_GlobalFitBAD_COEFINFO = -5
constant MOTO_NewGlobalFitNOWTWAVE = -6
constant MOTO_GlobalFitWTWAVEBADPOINTS = -7
constant MOTO_NewGlobalFitNOMSKWAVE = -8
constant MOTO_GlobalFitMSKWAVEBADPOINTS = -9
constant MOTO_GlobalFitXWaveBADPOINTS = -10
constant MOTO_NewGlobalFitBADRESULTDF = -11

//ARJN
static Function/S GF_DataSetErrorMessage(code, errorname)
	Variable code
	string errorname
	
	switch (code)
		case MOTO_NewGlobalFitNO_DATASETS:
			return "There are no data sets in the list of data sets."
			break
		case  MOTO_NewGlobalFitBAD_YWAVE:
			return "The Y wave \""+errorname+"\" does not exist"
			break
		case  MOTO_NewGlobalFitBAD_XWAVE:
			return "The X wave \""+errorname+"\" does not exist"
			break
		case  MOTO_NewGlobalFitNOWTWAVE:
			return "The weight wave \""+errorname+"\" does not exist."
			break
		case  MOTO_GlobalFitWTWAVEBADPOINTS:
			return "The weight wave \""+errorname+"\" has a different number of points than the corresponding data set wave."
			break
		case  MOTO_NewGlobalFitNOMSKWAVE:
			return "The mask wave \""+errorname+"\" does not exist."
			break
		case  MOTO_GlobalFitMSKWAVEBADPOINTS:
			return "The mask wave \""+errorname+"\" has a different number of points than the corresponding data set wave."
			break
		case  MOTO_GlobalFitXWaveBADPOINTS:
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

// As of Igor 6.10, return value is the error code from FuncFit if FuncFit stops due to syntax or running errors.
//ARJN
Function MOTO_DoNewGlobalFit(FitFuncNames, DataSets, CoefDataSetLinkage, CoefWave, CoefNames, ConstraintWave, Options, FitCurvePoints, DoAlertsOnError, [errorName, errorMessage, maxIters, resultWavePrefix, resultDF, PisLevORgen])
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

	Variable FitCurvePoints		// number of points for auto-destination waves

	Variable DoAlertsOnError	// if 1, this function puts up alert boxes with messages about errors. These alert boxes
	// may give more information than the error code returned from the function.

	String &errorName			// Wave name that was found to be in error. Only applies to certain errors.
	
	String &errorMessage		// If FuncFit reports an error, this string (if used) will return the standard Igor error message
	
	Variable maxIters			// optional parameter to set the maximum number of iterations to something other than 40
	
	String resultWavePrefix	// optional parameter to enter a string to use as a prefix when naming result waves, like the per-dataset coefficient waves, model traces, residual waves, etc.
	// Be careful- if it's too long you can get a combined name over 31 characters quite easily. If the result name has more than 31 characters, it will be truncated *from the back end*.

	String resultDF				// optional parameter to specify a data folder to hold all result waves. This overrides the default which is to put a
	// given result wave in the same data folder as the Y data wave it goes with.
	
	Variable PisLevORgen		//whether you want to do LM (0) or DE (1)

	if (ParamIsDefault(resultWavePrefix))
		resultWavePrefix = ""
	endif

	Variable specialResultDF = 1
	if (ParamIsDefault(resultDF))
		resultDF = ""
		specialResultDF = 0
	else
		if (strlen(resultDF) == 0)
			specialResultDF = 0
		else
			Variable lastChar = strlen(resultDF)-1
			if (cmpstr(":", resultDF[lastChar,lastChar]) != 0)
				resultDF = resultDF+":"
			endif
			if (!DataFolderExists(resultDF))
				return MOTO_NewGlobalFitBADRESULTDF
			endif
		endif
	endif

	Variable i,j
	
	String saveDF = GetDataFolder(1)
	
	//ARJN
	SetDataFolder root:
	NewDataFolder/O/S Packages
	NewDataFolder/O/S root:packages:motofitgf
	NewDataFolder/O NewGlobalFit
	SetDataFolder $saveDF
	
	//added by ARJN
	Variable/g  root:packages:MotofitGF:NewGlobalFit:isLevORgen		//Levenberg==0,Genetic==1
	NVAR/Z isLevORgen=root:packages:MotofitGF:NewGlobalFit:isLevORgen
	if(Paramisdefault(PisLevORgen))
		Prompt PisLevORgen,"choose Levenberg Marquardt or Genetic Optimisation",popup,"Levenberg;Genetic"
		Doprompt "choice of fitting method",PisLevORgen
		PisLevORgen -= 1
		if(V_flag==1)
			SetDataFolder $saveDF
			abort
		endif
	endif
	isLevORgen = PisLevORgen
		
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
	
	Duplicate/O CoefDataSetLinkage, root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Wave privateLinkage = root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
	Duplicate/O/T FitFuncNames, root:Packages:MotofitGF:NewGlobalFit:FitFuncList
	
	Variable DoResid=0
	Variable doWeighting=0
	Variable doMasking=0
	
	DoUpdate
	err = NewGF_CheckDSets_BuildCumWaves(DataSets, privateLinkage, doWeighting, doMasking, errorWaveName, errorWaveRow, errorWaveColumn)
	DoUpdate
	if (err < 0)
		//ARJN
		if (err == MOTO_NewGlobalFitNO_DATASETS)
			DoAlert 0, "There are no data sets in the list of data sets."
		elseif (DoAlertsOnError)
			DoAlert 0, GF_DataSetErrorMessage(err, errorWaveName)
		endif
		if (!ParamIsDefault(errorName))
			errorName = errorWaveName
		endif
		return err
	endif
	
	if (ParamIsDefault(maxIters))
		maxIters = 40
	endif
	
	Wave Xw = root:Packages:MotofitGF:NewGlobalFit:XCumData
	Wave Yw = root:Packages:MotofitGF:NewGlobalFit:YCumData
	Duplicate/O YW, root:Packages:MotofitGF:NewGlobalFit:FitY
	Wave FitY = root:Packages:MotofitGF:NewGlobalFit:FitY
	FitY = NaN
	
	Make/D/O/N=(DimSize(CoefWave, 0)) root:Packages:MotofitGF:NewGlobalFit:MasterCoefs	
	Wave MasterCoefs = root:Packages:MotofitGF:NewGlobalFit:MasterCoefs
	MasterCoefs = CoefWave[p][0]
	
	if (!WaveExists(CoefNames))
		Make/T/O/N=(DimSize(CoefWave, 0)) root:Packages:MotofitGF:NewGlobalFit:CoefNames
		Wave/T CoefNames = root:Packages:MotofitGF:NewGlobalFit:CoefNames
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

	//arjn
	if (Options & MOTO_NewGFOptionCALC_RESIDS)
		DoResid = 1
	endif
	String residWave = ""
	
	//arjn
	if (WinType("GlobalFitGraph") != 0)
		DoWindow/K GlobalFitGraph
	endif
	
	//arjn
	if(isLevORGen==0 ||itemsinlist(Operationlist("GENcurvefit",";","external")))			//added by ARJN
		if (options & MOTO_NewGFOptionFIT_GRAPH)	
			if (WinType("GlobalFitGraph") != 0)
				DoWindow/K GlobalFitGraph
			endif
			String SavedWindowCoords = WC_WindowCoordinatesGetStr("GlobalFitGraph", 0)
			if (strlen(SavedWindowCoords) > 0)
				Execute "Display/W=("+SavedWindowCoords+") as \"Global Analysis Progress\""
			else
				Display as "Global Analysis Progress"
			endif
			DoWindow/C GlobalFitGraph
			ColorTab2Wave Rainbow
			Wave M_colors
			Duplicate/O M_colors, root:Packages:MotofitGF:NewGlobalFit:NewGF_TraceColors
			Wave colors = root:Packages:MotofitGF:NewGlobalFit:NewGF_TraceColors
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
			if (options & MOTO_NewGFOptionLOG_DEST_WAVE)
				WaveStats/Q/M=1 xW
				if ( (V_min <= 0) || (V_max <= 0) )
					// bad x range for log- cancel the option
					options = options & ~MOTO_NewGFOptionLOG_DEST_WAVE
				else
					// the progress graph should have log X axis
					ModifyGraph/W=GlobalFitGraph log(bottom)=1
				endif
			endif
			SetWindow GlobalFitGraph, hook = WC_WindowCoordinatesHook
		
			if (DoResid)
				Duplicate/O Yw, root:Packages:MotofitGF:NewGlobalFit:NewGF_ResidY
				Wave rw = root:Packages:MotofitGF:NewGlobalFit:NewGF_ResidY
				residWave = "root:Packages:MotofitGF:NewGlobalFit:NewGF_ResidY"
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
	endif	
	Duplicate/D/O MasterCoefs, root:Packages:MotofitGF:NewGlobalFit:EpsilonWave
	Wave EP = root:Packages:MotofitGF:NewGlobalFit:EpsilonWave
	if (FindDimLabel(CoefWave, 1, "Epsilon") == -2)
		EP = 1e-4
	else
		EP = CoefWave[p][%Epsilon]
	endif

	Variable quiet = ((Options & MOTO_NewGFOptionQUIET) != 0)
	if (!quiet)
		Print "*** Doing Global fit ***"
	endif
	
	if (Options & MOTO_NewGFOptionCOR_MATRIX)
		Options = Options | MOTO_NewGFOptionCOV_MATRIX
	endif
	
	Variable covarianceArg = 0
	if (Options & MOTO_NewGFOptionCOV_MATRIX)
		covarianceArg = 2
	endif
	
	DoUpdate
	string funcName=""
	if (isAllAtOnce)
		funcName = "MOTO_NewGlblFitFuncAllAtOnce"
	else
		funcName = "MOTO_NewGlblFitFunc"
	endif
		
	String/G root:Packages:MotofitGF:NewGlobalFit:newGF_HoldString
	SVAR newGF_HoldString = root:Packages:MotofitGF:NewGlobalFit:newGF_HoldString
	newGF_HoldString = MakeHoldString(CoefWave, quiet, 1)		// MakeHoldString() returns "" if there are no holds
	String xwave = ""
//	if (isAllAtOnce)
	xwave = "XCumData"
//	endif
	
	String cwavename = ""
	if (WaveExists(ConstraintWave))
		cwavename = GetWavesDataFolder(ConstraintWave, 2)
	endif
	
	String weightName = ""
	Variable weightType = 0
	if (doWeighting)
		weightName = "GFWeightWave"
		if (Options & MOTO_NewGFOptionWTISSTD)
			weightType = 1
		endif
	endif
	SaveDF = GetDataFolder(1)
	DoUpdate
	SetDataFolder root:Packages:MotofitGF:NewGlobalFit
	Variable/G V_FitQuitReason
	Variable/G V_FitNumIters
	DoUpdate
	DebuggerOptions
	Variable savedDebugOnError = V_debugOnError
	DebuggerOptions debugOnError=0
	Variable V_FItMaxIters = maxIters
	switch (isLevORgen)
		case 0:
			try
				FuncFit/Q=(quiet)/H=(newGF_HoldString)/M=(covarianceArg) $funcname, MasterCoefs, Yw /X=$xwave/D=FitY/E=EP/R=$residWave/C=$cwavename/W=$weightName/I=(weightType)/NWOK
			catch
				String fitErrorMessage = GetRTErrMessage()
				Variable errorCode = GetRTError(1)
				Variable semiPos = strsearch(fitErrorMessage, ";", 0)
				if (semiPos >= 0)
					fitErrorMessage = fitErrorMessage[semiPos+1, inf]
				endif
				if (!quiet)
					DoAlert 0, fitErrorMessage
				endif
			endtry
					
			break
		case 1:
			if(strlen(newGF_HoldString)==0)
				variable ii
				for(ii=0;ii<numpnts(root:packages:MotofitGF:NewGlobalFit:MasterCoefs);ii+=1)
					newGF_HoldString+="0"
				endfor
			endif
			GEN_setlimitsforGENcurvefit(root:packages:MotofitGF:NewGlobalFit:MasterCoefs, newGF_HoldString)
			Wave GENcurvefitlimits =  root:packages:motofit:old_genoptimise:GENcurvefitlimits
			SVAR newGF_HoldString = root:packages:MotofitGF:NewGlobalFit:newGF_HoldString
			make/o/n=(numpnts(mastercoefs)) W_Sigma = 0
			Gencurvefit/K={200,10,0.7,0.5}/Q=(quiet)/MAT=(covarianceArg)/R=$residWave/X=$xwave/I=(weightType)/W=$weightName/D=fity $funcname, Yw, MasterCoefs, newGF_HoldString, GENcurvefitlimits
			break
	endswitch

	DebuggerOptions debugOnError=savedDebugOnError
		
	Variable fit_npnts = V_npnts
	Variable fit_numNaNs = V_numNaNs
	Variable fit_numINFs = V_numINFs
	SetDataFolder $SaveDF
	
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
			Wave M_Covar = root:Packages:MotofitGF:NewGlobalFit:M_covar
			if (Options & MOTO_NewGFOptionCOR_MATRIX)
				Duplicate/O M_Covar, M_Correlation
				M_Correlation = M_Covar[p][q]/sqrt(M_Covar[p][p]*M_Covar[q][q])
			endif
		endif
	endif
	
	CoefWave[][0] = MasterCoefs[p]
	Duplicate/O MasterCoefs, GlobalFitCoefficients
	
	if (!ParamIsDefault(errorMessage))
		errorMessage = fitErrorMessage
	endif

	if (!quiet)
		Print "\rGlobal fit results"
		if (errorCode)
			print fitErrorMessage
			return errorCode
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
		Wave W_sigma = root:Packages:MotofitGF:NewGlobalFit:W_sigma
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

	if (options & MOTO_NewGFOptionAPPEND_RESULTS)
		options = options | MOTO_NewGFOptionMAKE_FIT_WAVES
	endif
	
	if (options & MOTO_NewGFOptionCALC_RESIDS)
		options = options | MOTO_NewGFOptionMAKE_FIT_WAVES
	endif
	
	if ( (options & MOTO_NewGFOptionMAKE_FIT_WAVES) || (options & MOTO_NewGFOptionCALC_RESIDS) )
		Wave/Z fitxW = root:Packages:MotofitGF:NewGlobalFit:fitXCumData
		if (WaveExists(fitxW))
			KillWaves fitxW
		endif
		Rename xW, fitXCumData
		Wave/Z fitxW = root:Packages:MotofitGF:NewGlobalFit:fitXCumData
		Duplicate/O Yw, fitYCumData	
		String ListOfFitCurveWaves = ""
		Wave W_sigma = root:Packages:MotofitGF:NewGlobalFit:W_sigma
	
		for (i = 0; i < DimSize(DataSets, 0); i += 1)
			String YFitSet = DataSets[i][0]
			
			// copy coefficients for each data set into a separate wave
			Wave YFit = $YFitSet
			saveDF = GetDatafolder(1)
			if (specialResultDF)
				SetDataFolder $resultDF
			else
				SetDatafolder $GetWavesDatafolder(YFit, 1)
			endif
			String YWaveName = NameOfWave(YFit)
			if (CmpStr(YWaveName[0], "'") == 0)
				YWaveName = YWaveName[1, strlen(YWaveName)-2]
			endif
			// this is a good thing, but doesn't belong here. Individual coefficient waves should be made above
			String coefname = CleanupName(resultWavePrefix+"Coef_"+YWaveName, 0)
			String sigmaName = CleanupName(resultWavePrefix+"sig_"+YWaveName, 0)
			Make/D/O/N=(privateLinkage[i][NumFuncCoefsCol]) $coefname
			Make/D/O/N=(privateLinkage[i][NumFuncCoefsCol]) $sigmaName
			Wave w = $coefname
			Wave s = $sigmaName
			w = MasterCoefs[privateLinkage[i][p+FirstCoefCol]]
			s = W_sigma[privateLinkage[i][p+FirstCoefCol]]
			
			if (options & MOTO_NewGFOptionMAKE_FIT_WAVES)
				String fitCurveName = CleanupName(resultWavePrefix+"GFit_"+YWaveName, 0)
				Make/D/O/N=(FitCurvePoints) $fitCurveName
				Wave fitCurveW = $fitCurveName
				Variable minX, maxX
				WaveStats/Q/R=[privateLinkage[i][FirstPointCol], privateLinkage[i][LastPointCol]] fitxW
				minX = V_min
				maxX = V_max
				if (options & MOTO_NewGFOptionLOG_DEST_WAVE)
					String fitCurveXName = CleanupName(resultWavePrefix+"GFitX_"+YWaveName, 0)
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
						Duplicate/O fitCurveXW, root:Packages:MotofitGF:NewGlobalFit:XCumData
						Wave xw = root:Packages:MotofitGF:NewGlobalFit:XCumData
					endif
				endif
				// check this again in case the it was set but cancelled due to bad numbers
				if (!(options & MOTO_NewGFOptionLOG_DEST_WAVE))
					SetScale/I x minX, maxX, fitCurveW
				
					// make auxiliary waves required by the fit function
					// so that we can use the fit function in an assignment
					Duplicate/O fitCurveW, root:Packages:MotofitGF:NewGlobalFit:XCumData
					Wave xw = root:Packages:MotofitGF:NewGlobalFit:XCumData
					xw = x
				endif
				
				Duplicate/O fitCurveW, root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
				Wave dspw = root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
				dspw = 0
				
				Duplicate/O privateLinkage, copyOfLinkage
				Make/O/D/N=(1,DimSize(copyOfLinkage, 1)) root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				Wave tempLinkage = root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				tempLinkage = copyOfLinkage[i][q]
				tempLinkage[0][FirstPointCol] = 0
				tempLinkage[0][LastPointCol] = FitCurvePoints-1
				if (IsAllAtOnce)
					MOTO_NewGlblFitFuncAllAtOnce(MasterCoefs, fitCurveW, xw)
				else
					MOTO_NewGlblFitFunc(MasterCoefs, fitCurveW, xw)
				endif
				Duplicate/O copyOfLinkage, root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				KillWaves/Z copyOfLinkage
				
				if (options & MOTO_NewGFOptionAPPEND_RESULTS)
					String graphName = FindGraphWithWave(YFit)
					if (strlen(graphName) > 0)
						CheckDisplayed/W=$graphName fitCurveW
						if (V_flag == 0)
							String axisflags = StringByKey("AXISFLAGS", TraceInfo(graphName, YFitSet, 0))
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
				String resCurveName = CleanupName(resultWavePrefix+"GRes_"+YWaveName, 0)
				Make/D/O/N=(numpnts(YFit)) $resCurveName
				Wave resCurveW = $resCurveName
				Wave/Z XFit = $(DataSets[i][1])
				
				// make auxiliary waves required by the fit function
				// so that we can use the fit function in an assignment
				Duplicate/O resCurveW, root:Packages:MotofitGF:NewGlobalFit:XCumData
				Wave xw = root:Packages:MotofitGF:NewGlobalFit:XCumData
				if (WaveExists(XFit))
					xw = XFit
				else
					xw = pnt2x(YFit, p)
				endif
				
				Duplicate/O resCurveW, root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
				Wave dspw = root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
				dspw = 0
				
				//if (IsAllAtOnce)
				Duplicate/O privateLinkage, copyOfLinkage
				Make/O/D/N=(1,DimSize(copyOfLinkage, 1)) root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				Wave tempLinkage = root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				tempLinkage = copyOfLinkage[i][q]
				tempLinkage[0][FirstPointCol] = 0
				tempLinkage[0][LastPointCol] = numpnts(resCurveW)-1
				if (IsAllAtOnce)
					MOTO_NewGlblFitFuncAllAtOnce(MasterCoefs, resCurveW, xw)
				else
					MOTO_NewGlblFitFunc(MasterCoefs, resCurveW, xw)
				endif
				resCurveW = YFit[p] - resCurveW[p]
				Duplicate/O copyOfLinkage, root:Packages:MotofitGF:NewGlobalFit:CoefDataSetLinkage
				KillWaves/Z copyOfLinkage
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
		//		Make/D/N=(totalPoints)/O root:Packages:MotofitGF:NewGlobalFit:GFMaskWave
		doMasking = 1
	endif

	doWeighting = 0
	Variable WeightCol = FindDimLabel(DataSets, 1, "Weights")
	if (WeightCol >= 0)
		//		Make/D/N=(totalPoints)/O root:Packages:MotofitGF:NewGlobalFit:GFWeightWave
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
			return MOTO_NewGlobalFitBAD_YWAVE
		endif
		wavePoints = numpnts(Ysetw)
		
		// check the X wave
		if (cmpstr(XSet, "_Calculated_") != 0)
			if (!WaveExists(Xsetw)) 
				errorWaveName = XSet
				errorWaveRow = i
				errorWaveColumn = 1
				return MOTO_NewGlobalFitBAD_XWAVE
			endif
			if (wavePoints != numpnts(Xsetw))
				errorWaveRow = i
				errorWaveColumn = 1
				return MOTO_GlobalFitXWaveBADPOINTS
			endif
		endif		
		
		// check mask wave if necessary
		if (doMasking)
			Wave/Z mw = $(DataSets[i][MaskCol])
			if (!WaveExists(mw))
				errorWaveRow = i
				errorWaveColumn = MaskCol
				return MOTO_NewGlobalFitNOMSKWAVE
			endif
			if (wavePoints != numpnts(mw))
				errorWaveRow = i
				errorWaveColumn = MaskCol
				return MOTO_GlobalFitMSKWAVEBADPOINTS
			endif
		endif
		
		// check weighting wave if necessary
		if (doWeighting)
			Wave/Z ww = $(DataSets[i][WeightCol])
			if (!WaveExists(ww))
				errorWaveRow = i
				errorWaveColumn = WeightCol
				return MOTO_NewGlobalFitNOWTWAVE
			endif
			if (wavePoints != numpnts(ww))
				errorWaveRow = i
				errorWaveColumn = WeightCol
				return MOTO_GlobalFitWTWAVEBADPOINTS
			endif
		endif

		totalPoints += numpnts(Ysetw)
	endfor
	
	if (doWeighting)
		Make/D/N=(totalPoints)/O root:Packages:MotofitGF:NewGlobalFit:GFWeightWave
	endif

	// make the waves that will contain the concatenated data sets and the wave that points
	// to the appropriate row in the data set linkage matrix
	Make/D/N=(totalPoints)/O root:Packages:MotofitGF:NewGlobalFit:XCumData, root:Packages:MotofitGF:NewGlobalFit:YCumData
	Make/U/W/N=(totalPoints)/O root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
	
	Wave Xw = root:Packages:MotofitGF:NewGlobalFit:XCumData
	Wave Yw = root:Packages:MotofitGF:NewGlobalFit:YCumData
	Wave DataSetPointer = root:Packages:MotofitGF:NewGlobalFit:DataSetPointer
	Wave/Z Weightw = root:Packages:MotofitGF:NewGlobalFit:GFWeightWave
	//	Wave/Z Maskw = root:Packages:MotofitGF:NewGlobalFit:GFMaskWave
	
	Variable realTotalPoints = 0
	Variable wavePoint = 0

	// second pass through the list, this time copying the data into the concatenated sets, and
	// setting index numbers in the index wave
	for (i = 0; i < numSets; i += 1)
		YSet = DataSets[i][0]
		XSet = DataSets[i][1]
		Wave/Z Ysetw = $YSet
		Wave/Z Xsetw = $XSet
		if(doMasking)
			Wave/Z mw = $(DataSets[i][MaskCol])
		endif
		if (doWeighting)
			Wave/Z ww = $(DataSets[i][WeightCol])
		endif
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
	
	DFREF GFfolder = root:Packages:motofitgf
	if (DataFolderRefStatus(GFFolder) > 0)
		return 0		// if the folder already exists, just use it so the set-up will be the same as before. This risks using a damaged folder...
	endif
	
	DFREF saveFolder = GetDataFolderDFR()
	
	NewDataFolder/O/S root:Packages
	newdatafolder /o/s root:Packages:motofitgf
	NewDataFolder/O/S NewGlobalFit
	
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
	Variable/G NewGF_MaxIters = 40

	SetDataFolder saveFolder
end

static Function InitNewGlobalFitPanel()

	if (wintype("MotoGlobalFitPanel") == 0)
		InitNewGlobalFitGlobals()
		fMotoGlobalFitPanel()
	else
		DoWindow/F MotoGlobalFitPanel
	endif
end

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
	Execute/P "DELETEINCLUDE  <Global Fit 2>"
	Execute/P "COMPILEPROCEDURES "
	KillDataFolder root:Packages:MotofitGF:NewGlobalFit
end

static constant NewGF_DSList_YWaveCol = 0
static constant NewGF_DSList_XWaveCol = 1
static constant NewGF_DSList_FuncCol = 2
static constant NewGF_DSList_NCoefCol = 3

// moved to separate wave
//static constant NewGF_DSList_FirstCoefCol = 4
static constant NewGF_DSList_FirstCoefCol = 0
static strconstant NewGF_NewDFMenuString = "New Data Folder ..."

static Function fMotoGlobalFitPanel()

	Variable defLeft = 50
	Variable defTop = 70
	Variable defRight = 765
	Variable defBottom = 711
	
	String fmt="NewPanel/K=1/W=(%s) as \"Global Analysis\""
	String cmd = WC_WindowCoordinatesSprintf("MotoGlobalFitPanel", fmt, defLeft, defTop, defRight, defBottom, 1)
	Execute cmd

	//	NewPanel/K=1/W=(156,70,829,443) as "Motofit Global Analysis"
	DoWindow/C MotoGlobalFitPanel

	DefineGuide TabAreaLeft={FL,13}			// this is changed to FR, 25 when tab 0 is hidden
	DefineGuide TabAreaRight={FR,-10}
	DefineGuide TabAreaTop={FT,31}
	DefineGuide TabAreaBottom={FB,-307}
	DefineGuide GlobalControlAreaTop={FB,-297}
	DefineGuide Tab0ListTopGuide={TabAreaTop,130}

	TabControl NewGF_TabControl,pos={10,7},size={730,330},proc=MOTO_WM_NewGlobalFit1#NewGF_TabControlProc
	TabControl NewGF_TabControl,tabLabel(0)="Data Sets and Functions"
	TabControl NewGF_TabControl,tabLabel(1)="Coefficient Control",value= 0
	
	Button NewGF_HelpButton,pos={657,3},size={50,20},proc=MOTO_NewGF_HelpButtonProc,title="Help"

	NewPanel/FG=(TabAreaLeft, TabAreaTop, TabAreaRight, TabAreaBottom) /HOST=#
	RenameWindow #,Tab0ContentPanel
	ModifyPanel frameStyle=0, frameInset=0
	
	GroupBox NewGF_DataSetsGroup,pos={12,5},size={315,113},title="Data Sets"
	GroupBox NewGF_DataSetsGroup,fSize=12,fStyle=1
	
	PopupMenu NewGF_AddDataSetMenu,pos={23,29},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#MOTO_NewGF_AddYWaveMenuProc,title="Add Data Sets"
	PopupMenu NewGF_AddDataSetMenu,mode=0,value= #"MOTO_NewGF_YWaveList(1)"

	Button NewGF_AddRemoveWavesButton,pos={23,61},size={220,20},proc=MOTO_AddRemoveWavesButtonProc,title="Add/Remove Waves..."

	//			PopupMenu NewGF_SetDataSetMenu,pos={23,59},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#NewGF_SetDataSetMenuProc,title="Choose Y Wave"
	//			PopupMenu NewGF_SetDataSetMenu,mode=0,value= #"MOTO_NewGF_YWaveList(0)"
	//
	//			PopupMenu NewGF_SetXDataSetMenu,pos={175,59},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#NewGF_SetXWaveMenuProc,title="Choose X Wave"
	//			PopupMenu NewGF_SetXDataSetMenu,mode=0,value= #"Moto_NewGF_XWaveList()"

	PopupMenu NewGF_RemoveDataSetMenu1,pos={175,29},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#NewGF_RemoveDataSetsProc,title="Remove"
	PopupMenu NewGF_RemoveDataSetMenu1,mode=0,value= #"MOTO_NewGF_RemoveMenuList()"

	PopupMenu NewGF_SetFunctionMenu,pos={23,90},size={160,20},bodyWidth=160,proc=Moto_SetFuncMenuProc,title="Choose Fit Function"
	PopupMenu NewGF_SetFunctionMenu,mode=0,value= #"MOTO_NewGF_FitFuncList()"

	GroupBox NewGF_CoefficientsGroup,pos={358,5},size={331,113},title="Coefficients"
	GroupBox NewGF_CoefficientsGroup,fSize=12,fStyle=1

	Button NewGF_LinkCoefsButton,pos={373,81},size={140,20},proc=Moto_NewGF_LinkCoefsButtonProc,title="Link Selection"

	Button NewGF_UnLinkCoefsButton,pos={531,81},size={140,20},proc=Moto_UnLinkCoefsButtonProc,title="Unlink Selection"

	PopupMenu NewGF_SelectAllCoefMenu,pos={373,39},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#NewGF_SelectAllCoefMenuProc,title="Select Coef Column"
	PopupMenu NewGF_SelectAllCoefMenu,mode=0,value= #"MOTO_WM_NewGlobalFit1#NewGF_ListFunctionsAndCoefs()"

	PopupMenu NewGF_SelectAlsoCoefMenu,pos={532,38},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#NewGF_SelectAllCoefMenuProc,title="Add To Selection"
	PopupMenu NewGF_SelectAlsoCoefMenu,mode=0,value= #"MOTO_WM_NewGlobalFit1#NewGF_ListFunctionsAndCoefs()"

	//		GroupBox NewGF_Tab0ListGroup,pos={2,86},size={641,143},disable=1

	ListBox NewGF_DataSetsList,pos={10,130},size={339,160},proc=MOTO_WM_NewGlobalFit1#NewGF_DataSetListBoxProc,frame=2
	ListBox NewGF_DataSetsList,listWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	ListBox NewGF_DataSetsList,selWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	ListBox NewGF_DataSetsList,mode= 10,editStyle= 1,widths={10,10,10,6},userColumnResize= 1, clickEventModifiers=5

	ListBox NewGF_Tab0CoefList,pos={358,130},size={364,160},proc=MOTO_WM_NewGlobalFit1#NewGF_DataSetListBoxProc,frame=2
	ListBox NewGF_Tab0CoefList,listWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	ListBox NewGF_Tab0CoefList,selWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	ListBox NewGF_Tab0CoefList,colorWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_LinkColors
	ListBox NewGF_Tab0CoefList,mode= 10,editStyle= 1,widths={100},userColumnResize= 1, clickEventModifiers=5
		
	GroupBox NewGF_Tab0ListDragLine,pos={353,130},size={4,160},frame=0

	SetActiveSubwindow ##
	
	NewPanel/W=(119,117,359,351)/FG=(TabAreaLeft,TabAreaTop,TabAreaRight,TabAreaBottom)/HOST=# 
	RenameWindow #, Tab1ContentPanel
	ModifyPanel frameStyle=0, frameInset=0
		
	ListBox NewGF_CoefControlList,pos={4,34},size={440,291},proc = MOTO_WM_NewGlobalFit1#NewGF_CoefListBoxProc,frame=2
	ListBox NewGF_CoefControlList,listWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	ListBox NewGF_CoefControlList,selWave=root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	ListBox NewGF_CoefControlList,mode= 10,editStyle= 1,widths= {15,15,7,4,5},userColumnResize=1
		
	TitleBox NewGF_CoefControlIGTitle,pos={135,9},size={75,15},title="Initial guess:"
	TitleBox NewGF_CoefControlIGTitle,fSize=12,frame=0,anchor= RC

	PopupMenu NewGF_SetCoefsFromWaveMenu,pos={219,7},size={100,20},title="Set from Wave",mode=0,value=MOTO_ListInitGuessWaves(0, 0)
	PopupMenu NewGF_SetCoefsFromWaveMenu,proc=Moto_SetCoefsFromWaveProc

	PopupMenu NewGF_SaveCoefstoWaveMenu,pos={343,7},size={100,20},title="Save to Wave",mode=0,value="New Wave...;-;"+MOTO_ListInitGuessWaves(0, 0)
	PopupMenu NewGF_SaveCoefstoWaveMenu,proc=Moto_SaveCoefsToWaveProc

	SetActiveSubwindow ##
	
	NewPanel/W=(495,313,643,351)/FG=(FL,GlobalControlAreaTop,FR,FB)/HOST=# 
	ModifyPanel frameStyle=0, frameInset=0
	RenameWindow #,NewGF_GlobalControlArea
	
	TitleBox NewGF_ResultWavesTitle,pos={23,6},size={77,16},title="Result Waves"
	TitleBox NewGF_ResultWavesTitle,fSize=12,frame=0,fStyle=1
		
	CheckBox NewGF_MakeFitCurvesCheck,pos={28,34},size={145,16},proc=MOTO_WM_NewGlobalFit1#NewGF_FitCurvesCheckProc,title="Make Fit Curve Waves"
	CheckBox NewGF_MakeFitCurvesCheck,fSize=12,value= 1
		
	CheckBox NewGF_AppendResultsCheckbox,pos={50,56},size={186,16},proc=MOTO_WM_NewGlobalFit1#NewGF_AppendResultsCheckProc,title="And Append Them to Graphs"
	CheckBox NewGF_AppendResultsCheckbox,fSize=12,value= 1
		
	CheckBox NewGF_DoResidualCheck,pos={51,79},size={127,16},proc=MOTO_WM_NewGlobalFit1#NewGF_CalcResidualsCheckProc,title="Calculate Residuals"
	CheckBox NewGF_DoResidualCheck,fSize=12,value= 1
		
	SetVariable NewGF_SetFitCurveLength,pos={27,114},size={149,19},bodyWidth=50,title="Fit Curve Points:"
	SetVariable NewGF_SetFitCurveLength,fSize=12
	SetVariable NewGF_SetFitCurveLength,limits={2,inf,1},value= root:Packages:MotofitGF:NewGlobalFit:FitCurvePoints
		
	CheckBox NewGF_DoDestLogSpacingCheck,pos={51,140},size={135,16},title="Logarithmic Spacing"
	CheckBox NewGF_DoDestLogSpacingCheck,fSize=12,value= 0
		
	SetVariable NewGF_ResultNamePrefix,pos={27,177},size={202,19},bodyWidth=50,title="Result Wave Name Prefix:"
	SetVariable NewGF_ResultNamePrefix,fSize=12,value= _STR:""
		
	TitleBox NewGF_ResultWavesDFTitle,pos={27,212},size={199,16},title="Make Result Waves in Data Folder:"
	TitleBox NewGF_ResultWavesDFTitle,fSize=12,frame=0

	Button NewGF_ResultsDFSelector,pos={50,231},size={206,20},fSize=12
	Button NewGF_ResultsDFSelector, UserData(NewGF_SavedSelection)="Same as Y Wave"
	MakeButtonIntoWSPopupButton("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", "MOTO_ResultsDFSelectorNotify", content = WMWS_DataFolders)
	PopupWS_AddSelectableString("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", "Same as Y Wave")
	PopupWS_AddSelectableString("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", NewGF_NewDFMenuString)
	PopupWS_SetSelectionFullPath("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", "Same as Y Wave")

	GroupBox NewGF_GlobalDivider1,pos={284,7},size={4,242}

	TitleBox NewGF_OptionsTitle,pos={304,5},size={45,16},title="Options",fSize=12
	TitleBox NewGF_OptionsTitle,frame=0,fStyle=1

	CheckBox NewGF_FitProgressGraphCheckBox,pos={318,34},size={124,16},title="Fit Progress Graph"
	CheckBox NewGF_FitProgressGraphCheckBox,fSize=12,value= 1

	CheckBox NewGF_Quiet,pos={318,58},size={318,16},title="No History Output"
	CheckBox NewGF_Quiet,fSize=12,value= 0

	CheckBox NewGF_DoCovarMatrix,pos={318,83},size={120,16},proc=MOTO_WM_NewGlobalFit1#NewGF_CovMatrixCheckProc,title="Covariance Matrix"
	CheckBox NewGF_DoCovarMatrix,fSize=12,value= 1

	CheckBox NewGF_CorrelationMatrixCheckBox,pos={339,102},size={120,16},proc=MOTO_WM_NewGlobalFit1#NewGF_CorMatrixCheckProc,title="Correlation Matrix"
	CheckBox NewGF_CorrelationMatrixCheckBox,fSize=12,value= 1

	SetVariable NewGF_SetMaxIters,pos={318,129},size={135,19},bodyWidth=50,title="Max Iterations",fSize=12
	SetVariable NewGF_SetMaxIters,limits={5,500,1},value= root:Packages:MotofitGF:NewGlobalFit:NewGF_MaxIters
	
	CheckBox NewGF_ConstraintsCheckBox,pos={318,206},size={95,16},proc=MOTO_WM_NewGlobalFit1#ConstraintsCheckProc,title="Constraints..."
	CheckBox NewGF_ConstraintsCheckBox,fSize=12,value= 0

	CheckBox NewGF_WeightingCheckBox,pos={318,156},size={87,16},proc=MOTO_WM_NewGlobalFit1#NewGF_WeightingCheckProc,title="Weighting..."
	CheckBox NewGF_WeightingCheckBox,fSize=12,value= 0

	CheckBox NewGF_MaskingCheckBox,pos={318,181},size={75,16},proc=MOTO_WM_NewGlobalFit1#NewGF_MaskingCheckProc,title="Masking..."
	CheckBox NewGF_MaskingCheckBox,fSize=12,value= 0

	GroupBox NewGF_SaveSetupGroup,pos={489,7},size={4,258}

	TitleBox NewGF_SaveSetupTitle,pos={513,5},size={65,16},title="Save Setup"
	TitleBox NewGF_SaveSetupTitle,fSize=12,frame=0,fStyle=1

	SetVariable NewGF_SaveSetSetName,pos={523,39},size={170,19},bodyWidth=130,title="Name:",fSize=12
	SetVariable NewGF_SaveSetSetName,value= root:Packages:MotofitGF:NewGlobalFit:NewGF_NewSetupName
		
	CheckBox NewGF_StoredSetupOverwriteOKChk,pos={572,70},size={95,16},title="Overwrite OK"
	CheckBox NewGF_StoredSetupOverwriteOKChk,fSize=12,value= 0
		
	Button NewGF_SaveSetupButton,pos={585,101},size={50,20},proc=MOTO_WM_NewGlobalFit1#NewGF_SaveSetupButtonProc,title="Save",fSize=12
		
	PopupMenu NewGF_RestoreSetupMenu,pos={536,177},size={140,20},bodyWidth=140,proc=MOTO_WM_NewGlobalFit1#NewGF_RestoreSetupMenuProc,title="Restore Setup"
	PopupMenu NewGF_RestoreSetupMenu,fSize=12,mode=0,value= #"MOTO_WM_NewGlobalFit1#NewGF_ListStoredSetups()"

	Button DoSimButton,pos={378,266},size={167,20},proc=MOTO_WM_NewGlobalFit1#NewGF_DoTheFitButtonProc,title="Simulate"
	Button DoSimButton,fSize=12,fColor=(16385,49025,65535)
	Button DoFitButton,pos={202,266},size={167,20},proc=MOTO_WM_NewGlobalFit1#NewGF_DoTheFitButtonProc,title="Fit!"
	Button DoFitButton,fSize=12,fColor=(16385,49025,65535)

	SetActiveSubwindow ##
	
	MOTO_NewGF_SetTabControlContent(0)
	
	SetWindow MotoGlobalFitPanel, hook = WC_WindowCoordinatesHook
	SetWindow MotoGlobalFitPanel, hook(NewGF_Resize) = MOTO_NewGF_PanelHook

	DFREF savedSetup = root:Packages:NewGlobalFit_StoredSetups:$MOTO_saveSetupName
	if (DataFolderRefStatus(savedSetup) > 0)
		MOTO_RestoreSetup(MOTO_saveSetupName)
	endif
	
	NewGF_MoveControls()
end

Function MOTO_IsMinimized(windowName)
	String windowName
	
	if (strsearch(WinRecreation(windowName, 0), "MoveWindow 0, 0, 0, 0", 0, 2) > 0)
		return 1
	endif
	
	return 0
end

static Function insideRect(r, p)
	STRUCT Rect &r
	STRUCT Point &p
	
	return (p.v > r.top) && (p.v < r.bottom) && (p.h > r.left) && (p.h < r.right)
end

static Function ControlRect(wName, cName, r)
	String wName, cName
	STRUCT Rect &r
	
	ControlInfo/W=$wName $cName
	r.left = V_left
	r.top = V_top
	r.right = V_left+V_width
	r.bottom = V_top+V_height
end

static Function OffsetRect(r, dx, dy)
	STRUCT Rect &r
	Variable dx, dy
	
	r.top += dy
	r.bottom += dy
	r.left += dx
	r.right += dx
end

static Function getHotRect(r, dx, dy)
	STRUCT Rect &r
	Variable dx, dy
	
	STRUCT Rect leftListRect
	STRUCT Rect rightListRect

	ControlRect("MotoGlobalFitPanel#Tab0ContentPanel", "NewGF_DataSetsList", leftListRect)
	ControlRect("MotoGlobalFitPanel#Tab0ContentPanel", "NewGF_Tab0CoefList", rightListRect)
	r = leftListRect
	r.left = leftListRect.right-3
	r.right = rightListRect.left+3
	OffsetRect(r, dx, dy)
end

static constant charOne=49
static constant charZero=48

static structure ListSizeInfo
Variable DataSetsListWidth
Variable CoefListLeft
Variable CoefListWidth
STRUCT Point mouseDownLoc
endstructure

StrConstant MOTO_saveSetupName = "LastSetupSaved"

Function MOTO_NewGF_PanelHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable statusCode = 0

	STRUCT Rect hotRect
	STRUCT ListSizeInfo lsi
	String listInfoStructString
		
	strswitch (s.eventName)
		case "keyboard":
			if ( (s.keycode == 13) || (s.keyCode == 3) )			// return or enter key
				NewGF_DoTheFitButtonProc("")
				statusCode = 1
			endif
			break;
		case "kill":
			MOTO_SaveSetup(MOTO_saveSetupName)
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
		case "resize":
			if (MOTO_IsMinimized(s.winName))
				break;
			endif
			NewGF_MainPanelMinWindowSize()
			NewGF_MoveControls()
			break
		case "mousedown":
			ControlInfo/W=MotoGlobalFitPanel NewGF_TabControl
			if (V_value > 0)
				break;
			endif

			getHotRect(hotRect, s.winRect.left, s.winRect.top)
			if (insideRect(hotRect, s.mouseLoc))
				
				lsi.mouseDownLoc = s.mouseLoc
				SetWindow $(s.winName) UserData(GlobalFitListDrag) = "1"
				ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_DataSetsList
				lsi.DataSetsListWidth = V_width
				ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_Tab0CoefList
				lsi.CoefListLeft = V_left
				lsi.CoefListWidth = V_width
				StructPut/S lsi, listInfoStructString
				SetWindow $(s.winName) UserData(DragListsInfo)=listInfoStructString
				statusCode = 1
			endif
			break;
		case "mouseup":
			ControlInfo/W=MotoGlobalFitPanel NewGF_TabControl
			if (V_value > 0)
				break;
			endif
 
			if (Char2Num(GetUserData(s.winName, "", "GlobalFitListDrag")) == charOne)
				SetWindow $(s.winName) UserData(GlobalFitListDrag) = "0"
			endif
			break;
		case "mousemoved":
			ControlInfo/W=MotoGlobalFitPanel NewGF_TabControl
			if (V_value > 0)
				break;
			endif

			getHotRect(hotRect, s.winRect.left, s.winRect.top)
			if ( (Char2Num(GetUserData(s.winName, "", "GlobalFitListDrag")) == charOne) && (s.eventMod & 1) )
				listInfoStructString = GetUserData(s.winName, "", "DragListsInfo")
				StructGet/S lsi, listInfoStructString
				Variable dx = s.mouseLoc.h-lsi.mouseDownLoc.h
				ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_DataSetsList
				Variable listWidth = lsi.DataSetsListWidth+dx
				if (listWidth < 40)
					break;
				endif
				ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_DataSetsList
				Variable listRight = V_left+listWidth
				if (lsi.CoefListWidth-dx < 40)
					Break;
				endif
				ListBox NewGF_DataSetsList,win=MotoGlobalFitPanel#Tab0ContentPanel,size={listWidth, V_height}
				
				Groupbox NewGF_Tab0ListDragLine,win=MotoGlobalFitPanel#Tab0ContentPanel, pos={listRight+NewGF_Tab0ListGrout/2, V_top}

				ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_Tab0CoefList
				ListBox NewGF_Tab0CoefList,win=MotoGlobalFitPanel#Tab0ContentPanel,pos={lsi.CoefListLeft+dx, V_top},size={lsi.CoefListWidth-dx, V_height}
				statusCode = 1
			elseif (insideRect(hotRect, s.mouseLoc))
				s.doSetCursor = 1
				s.cursorCode = 5
			endif
			break;
	endswitch
	 
	return statusCode		// 0 if nothing done, else 1
End

static constant NewGF_MainPanelMinWidth = 715
static constant NewGF_MainPanelMinHeight = 550

static constant NewGF_TabWidthMargin = 15
static constant NewGF_TabHeightMargin = 122

static constant NewGF_Tab0ListGroupWidthMargin  = 5
static constant NewGF_Tab0ListGroupBottomMargin  = 5
//static constant NewGF_Tab0ListGroupHeightMargin = 88
static constant NewGF_Tab0ListGroupHeightMargin = 92
static constant NewGF_Tab0ListGrout = 9

static constant NewGF_DataSetListGrpWidthMargin = 341
//static constant NewGF_DataSetListGrpHghtMargin = 4

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

static Function CalcListSizes(listTop, listHeight, dataSetsListWidth, dataSetsListRight, coefsListleft, coefsListWidth)
	Variable &listTop, &listHeight, &dataSetsListWidth, &dataSetsListRight, &coefsListleft, &coefsListWidth
	
	String leftGuideInfo = GuideInfo("MotoGlobalFitPanel", "TabAreaLeft")
	Variable leftGuideX = NumberByKey("POSITION", leftGuideInfo)
	String rightGuideInfo = GuideInfo("MotoGlobalFitPanel", "TabAreaRight")
	Variable rightGuideX = NumberByKey("POSITION", rightGuideInfo)
	String topGuideInfo = GuideInfo("MotoGlobalFitPanel", "TabAreaTop")
	Variable topGuideY = NumberByKey("POSITION", topGuideInfo)
	String bottomGuideInfo = GuideInfo("MotoGlobalFitPanel", "TabAreaBottom")
	Variable bottomGuideY = NumberByKey("POSITION", bottomGuideInfo)
	String listTopGuideInfo = GuideInfo("MotoGlobalFitPanel", "Tab0ListTopGuide")
	listTop = NumberByKey("POSITION", listTopGuideInfo) - topGuideY
	listHeight = bottomGuideY - topGuideY - listTop - NewGF_Tab0ListGroupBottomMargin

	ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel NewGF_DataSetsList
	dataSetsListWidth = V_width		// constant width
	dataSetsListRight = V_left + V_width
	Variable dataSetsListLeft = V_left

	coefsListleft = dataSetsListRight + NewGF_Tab0ListGrout
	coefsListWidth = (rightGuideX - leftGuideX) - coefsListleft - NewGF_Tab0CoefListRightMargin
	
	if (coefsListWidth < 40)
		Variable delta = 40 - coefsListWidth
		coefsListWidth = 40
		dataSetsListWidth -= delta
		dataSetsListRight = dataSetsListLeft + dataSetsListWidth
		coefsListleft = dataSetsListRight + NewGF_Tab0ListGrout
	endif
end

static Function NewGF_MoveControls()

	String tabBottomGuideInfo = GuideInfo("MotoGlobalFitPanel", "TabAreaBottom")
	Variable tabBottom = NumberByKey("POSITION", tabBottomGuideInfo)
	String tabRightGuideInfo = GuideInfo("MotoGlobalFitPanel", "TabAreaRight")
	Variable tabRight = NumberByKey("POSITION", tabRightGuideInfo)
	ControlInfo/W=MotoGlobalFitPanel NewGF_TabControl
	Variable tabTop = V_top
	Variable tabLeft = V_left
	TabControl NewGF_TabControl, win=MotoGlobalFitPanel,size={tabRight-tabLeft+3, tabBottom-tabTop+3}

	//	GetWindow MotoGlobalFitPanel wsizeDC
	//	Variable Width = (V_right - V_left)
	//	Variable Height = (V_bottom - V_top)
	//	TabControl NewGF_TabControl, win=MotoGlobalFitPanel,size={width-NewGF_TabWidthMargin, height-NewGF_TabHeightMargin}

	//	ControlInfo/W=MotoGlobalFitPanel NewGF_TabControl
	//	switch(V_value)
	//		case 0:
	Variable listTop, listHeight, dataSetsListWidth, dataSetsListRight, coefsListleft, coefsListWidth

	CalcListSizes(listTop, listHeight, dataSetsListWidth, dataSetsListRight, coefsListleft, coefsListWidth)
	ListBox NewGF_DataSetsList, win=MotoGlobalFitPanel#Tab0ContentPanel, pos={dataSetsListRight-dataSetsListWidth, listTop}, size={dataSetsListWidth, listHeight}
	ListBox NewGF_Tab0CoefList, win=MotoGlobalFitPanel#Tab0ContentPanel, pos={coefsListleft, listTop}, size={coefsListWidth, listHeight}			
	Groupbox NewGF_Tab0ListDragLine,win=MotoGlobalFitPanel#Tab0ContentPanel, pos={dataSetsListRight+NewGF_Tab0ListGrout/2, listTop},size={1, listHeight}
	//			break;
	//		case 1:
	GetWindow MotoGlobalFitPanel#Tab1ContentPanel wsizeDC
	Variable Width = (V_right - V_left)
	Variable Height = (V_bottom - V_top)
	ListBox NewGF_CoefControlList, win=MotoGlobalFitPanel#Tab1ContentPanel,size={width-NewGF_CoefListWidthMargin, height-NewGF_CoefListHeightMargin}
	//			break;
	//	endswitch
end

static Function/S NewGF_ListStoredSetups()

	String SaveDF = GetDataFolder(1)
	SetDataFolder root:Packages:motofitgf
	
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

// Expects a legal name as input. If the folder already exists, it will be overwritten.
Function MOTO_SaveSetup(saveName)
	String saveName
	
	DFREF SaveDF = GetDataFolderDFR()
	SetDataFolder root:Packages:motofitgf:
	NewDataFolder/O/S NewGlobalFit_StoredSetups

	DFREF targetDF = $saveName
	if (DataFolderRefStatus(targetDF) > 0)
		KillDataFolder targetDF
	endif
	DuplicateDataFolder root:Packages:motofitgf:NewGlobalFit, $saveName
	SetDataFolder $saveName
	
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
	
	Wave/Z YCumData, FitY, NewGF_LinkageMatrix, NewGF_CoefWave
	Wave/T/Z NewGF_FitFuncNames, NewGF_DataSetsList
	KillWaves/Z YCumData, FitY, NewGF_FitFuncNames, NewGF_LinkageMatrix, NewGF_DataSetsList, NewGF_CoefWave
	
	Wave/Z CoefDataSetLinkage, DataSetPointer, MasterCoefs, EpsilonWave
	Wave/Z/T NewGF_CoefficientNames, FitFuncList
	KillWaves/Z NewGF_CoefficientNames, CoefDataSetLinkage, FitFuncList, DataSetPointer, MasterCoefs, EpsilonWave

	Wave/Z GFWeightWave
	Wave/Z GFMaskWave
	Wave/T/Z GFUI_GlobalFitConstraintWave
	KillWaves/Z GFWeightWave, GFMaskWave, GFUI_GlobalFitConstraintWave

	Wave/Z M_Correlation, fitXCumData, XCumData, M_Covar, W_sigma, W_ParamConfidenceInterval
	KillWaves/Z M_Correlation, fitXCumData, XCumData, M_Covar, W_sigma, W_ParamConfidenceInterval 
	
	KillVariables/Z V_Flag, V_FitQuitReason, V_FitError, V_FitNumIters, V_numNaNs, V_numINFs, V_npnts, V_nterms, V_nheld
	KillVariables/Z V_startRow, V_endRow, V_startCol, V_endCol, V_chisq
	
	SetDataFolder saveDF
end

static Function NewGF_SaveSetupButtonProc(ctrlName) : ButtonControl
	String ctrlName

	SVAR NewGF_NewSetupName = root:Packages:motofitgf:NewGlobalFit:NewGF_NewSetupName
	
	DFREF SaveDF = GetDataFolderDFR()
	SetDataFolder root:Packages:motofitgf
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
					SetDataFolder saveDF
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

	SetDataFolder saveDF
	
	MOTO_SaveSetup(NewGF_NewSetupName)
end	

Function MOTO_RestoreSetup(savedSetupName)
	String savedSetupName
	
	DFREF saveDF = GetDataFolderDFR()
	DFREF savedSetupDF = root:Packages:motofitgf:NewGlobalFit_StoredSetups:$(savedSetupName)
	if (DataFolderRefStatus(savedSetupDF) == 0)
		return -1
	endif
	
	SetDataFolder savedSetupDF
	Variable i = 0
	do
		Wave/Z w = WaveRefIndexed("", i, 4)
		if (!WaveExists(w))
			break
		endif
		
		Duplicate/O w, root:Packages:motofitgf:NewGlobalFit:$(NameOfWave(w))
		i += 1
	while (1)
	
	String vars = VariableList("*", ";", 4)
	Variable nv = ItemsInList(vars)
	for (i = 0; i < nv; i += 1)
		String varname = StringFromList(i, vars)
		NVAR vv = $varname
		Variable/G root:Packages:motofitgf:NewGlobalFit:$varname = vv
	endfor
	
	String strs = StringList("*", ";")
	Variable nstr = ItemsInList(strs)
	for (i = 0; i < nstr; i += 1)
		String strname = StringFromList(i, strs)
		SVAR ss = $strname
		String/G root:Packages:motofitgf:NewGlobalFit:$strname = ss
	endfor
	
	SetDataFolder root:Packages:motofitgf:NewGlobalFit:
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
	
	SetDataFolder saveDF	
	return 0
end

static Function NewGF_RestoreSetupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
		if (MOTO_RestoreSetup(PU_Struct.popStr))
			DoAlert 0, "The saved setup was not found."
		endif
	endif
End

Function MOTO_NewGF_SetTabControlContent(whichTab)
	Variable whichTab
	
	switch(whichTab)
		case 0:
			SetWindow MotoGlobalFitPanel#Tab1ContentPanel hide=1
			SetWindow MotoGlobalFitPanel#Tab0ContentPanel hide=0
			break;
		case 1:
			NVAR/Z NewGF_RebuildCoefListNow = root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
			if (!NVAR_Exists(NewGF_RebuildCoefListNow) || NewGF_RebuildCoefListNow)
				NewGF_RebuildCoefListWave()
			endif
			SetWindow MotoGlobalFitPanel#Tab0ContentPanel hide=1
			SetWindow MotoGlobalFitPanel#Tab1ContentPanel hide=0
			break;
	endswitch
	//	NewGF_MoveControls()
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

Function MOTO_NewGF_SetFunctionForRow(funcName, row)
	String funcName
	Variable row
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave

	String CoefList
	Variable NumCoefs = GetNumCoefsAndNamesFromFunction(FuncName, coefList)

	Variable i, j
	
	if (numType(NumCoefs) == 0)
		if (NumCoefs > DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
			Redimension/N=(-1,NumCoefs+NewGF_DSList_FirstCoefCol, -1) CoefListWave, CoefSelWave
			for (i = 1; i < NumCoefs; i += 1)
				SetDimLabel 1, i+NewGF_DSList_FirstCoefCol,$("K"+num2str(i)), CoefListWave
			endfor
		endif
	endif
	
	Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
	ListWave[row][NewGF_DSList_FuncCol][0] = FuncName
	if (numType(NumCoefs) == 0)
		ListWave[row][NewGF_DSList_NCoefCol][0] = num2istr(NumCoefs)
		for (j = 0; j < NumCoefs; j += 1)
			String coeftitle = StringFromList(j, coefList)
			if (strlen(coeftitle) == 0)
				coeftitle = "r"+num2istr(row)+":K"+num2istr(j)
			else
				coeftitle = "r"+num2istr(row)+":"+coeftitle
			endif
			CoefListWave[row][NewGF_DSList_FirstCoefCol+j][] = coeftitle
		endfor
		SelWave[row][NewGF_DSList_NCoefCol][0] = 0
	else
		SelWave[row][NewGF_DSList_NCoefCol][0] = 2
	endif
	for (j = j+NewGF_DSList_FirstCoefCol;j < DimSize(CoefListWave, 1); j += 1)
		CoefListWave[row][j][] = ""
	endfor
end

static Function NewGF_DataSetListBoxProc(s)
	STRUCT WMListboxAction &s
	
	Variable numcoefs
	String funcName
	Variable i,j
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	Variable numrows = DimSize(ListWave, 0)
	Variable numcols = DimSize(Listwave, 1)
	
	switch (s.eventCode)
		case 7:							// finish edit
			if (CmpStr(s.ctrlName, "NewGF_Tab0CoefList") == 0)
				return 0
			endif
				
			if (s.col == NewGF_DSList_NCoefCol)
			
				numcoefs = str2num(ListWave[s.row][s.col][0])
				funcName = ListWave[s.row][NewGF_DSList_FuncCol][0]
				Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
				
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
			break;
		case 1:							// mouse down
			Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
				
			if (s.row == -1 && (s.eventMod == 1))					// left-click in title row
				if (CmpStr(s.ctrlName, "NewGF_Tab0CoefList") == 0)
					Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
				else
					Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
				endif
				SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
				SelWave[][s.col][0] = SelWave[p][s.col] | 1				// select all rows
			elseif ( s.row == -1 && (s.eventMod & 16))				// context-click in title row
				if (CmpStr(s.ctrlName, "NewGF_Tab0CoefList") == 0)
					return 0
				endif
				if (s.col == 0)												// Y Wave list
				elseif (s.col == 1)											// X Wave list
					SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
					SelWave[][s.col][0] = SelWave[p][s.col] | 1				// select all rows
					ControlUpdate/W=$(s.win) $(s.ctrlName)
					PopupContextualMenu "_calculated_;"+WaveList("*",";","DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
					if (V_flag > 0)
						Wave w = $S_selection
						for (i = 0; i < numrows; i += 1)
							Wave/Z w = $S_selection
							MOTO_NewGF_SetXWaveInList(w, i)
							SelWave[s.row][s.col][0] = 0
						endfor
					endif
				elseif (s.col == 2)											// function list
					SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
					SelWave[][s.col][0] = SelWave[p][s.col] | 1				// select all rows
					ControlUpdate/W=$(s.win) $(s.ctrlName)
					PopupContextualMenu MOTO_NewGF_FitFuncList()
					if (V_flag > 0)
						for (i = 0; i < numrows; i += 1)
							MOTO_NewGF_SetFunctionForRow(S_selection, i)
						endfor
						NewGF_CheckCoefsAndReduceDims()
					endif
				endif
			elseif ( (s.row >= 0) && (s.row < DimSize(SelWave, 0)) )
				if (CmpStr(s.ctrlName, "NewGF_Tab0CoefList") == 0)
					return 0
				endif
				
				if (isControlOrRightClick(s.eventMod))				// right-click or ctrl-click
					switch(s.col)
						case NewGF_DSList_YWaveCol:
							PopupContextualMenu MOTO_NewGF_YWaveList(-1)
							if (V_flag > 0)
								Wave w = $S_selection
								NewGF_SetYWaveForRowInList(w, $"", s.row)
								SelWave[s.row][s.col][0] = 0
							endif
							break
						case NewGF_DSList_XWaveCol:
							Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
							Wave w = $(ListWave[s.row][NewGF_DSList_YWaveCol][1])
							if (WaveExists(w))
								if ( (SelWave[s.row][s.col] & 9) == 0 )		// context-click on selected cell? If not, select the clicked cell
									SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
									SelWave[s.row][s.col][0] = SelWave[s.row][s.col] | 1				// select all rows
									ControlUpdate/W=$(s.win) $(s.ctrlName)
								endif
								String RowsText = num2str(DimSize(w, 0))
								PopupContextualMenu "_calculated_;"+WaveList("*",";","MINROWS:"+RowsText+",MAXROWS:"+RowsText+",DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
								if (V_flag > 0)
									Wave/Z w = $S_selection
									for (i = 0; i < numrows; i += 1)
										if (SelWave[i][s.col] & 9)
											MOTO_NewGF_SetXWaveInList(w, i)
										endif
									endfor
								endif
							endif
							break
						case NewGF_DSList_FuncCol:
							if ( (SelWave[s.row][s.col] & 9) == 0 )		// context-click on selected cell? If not, select the clicked cell
								SelWave[][][0] = SelWave[p][q] & ~9						// de-select everything to make sure we don't leave something selected in another column
								SelWave[s.row][s.col][0] = SelWave[s.row][s.col] | 1				// select all rows
								ControlUpdate/W=$(s.win) $(s.ctrlName)
							endif
							PopupContextualMenu MOTO_NewGF_FitFuncList()
							if (V_flag > 0)
								for (i = 0; i < numrows; i += 1)
									if (SelWave[i][s.col] & 9)
										MOTO_NewGF_SetFunctionForRow(S_selection, i)
									endif
								endfor
								NewGF_CheckCoefsAndReduceDims()
							endif
							break
					endswitch
				endif
			endif
			break;
		case 8:		// vertical scroll (responding to 10, programmatically set top row, caused feedback if scrolling ocurred very rapidly, as with a scroll wheel)
			String otherCtrl = ""
			if (CmpStr(s.ctrlName, "NewGF_DataSetsList") == 0)
				otherCtrl = "NewGF_Tab0CoefList"
			else 
				otherCtrl = "NewGF_DataSetsList"
			endif
			ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel $otherCtrl
			//print s.ctrlName, otherCtrl, "event = ", s.eventCode, "row = ", s.row, "V_startRow = ", V_startRow
			if (V_startRow != s.row)
				ListBox $otherCtrl win=MotoGlobalFitPanel#Tab0ContentPanel,row=s.row
				DoUpdate
			endif
			break;
		case 12:
			print "listbox "+s.win+" got key "+num2char(s.row)+" ("+num2str(s.row)+") and modifiers "+num2str(s.eventMod)
			break;
	endswitch
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


Function MOTO_AddRemoveWavesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			MOTO_BuildDataSetSelector()
			break
	endswitch

	return 0
End

static Function NewGF_WaveInListAlready(w)
	Wave w
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
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
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
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
	
	Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
end

static Function NewGF_SetYWaveForRowInList(w, xw, row)
	Wave/Z w
	Wave/Z xw
	Variable row
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	
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
	NVAR/Z NewGF_RebuildCoefListNow = root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
	if (!NVAR_Exists(NewGF_RebuildCoefListNow))
		Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1
	endif
	NewGF_RebuildCoefListNow = 1
end

static Function NewGF_SetDataSetMenuProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	Variable i, j, nInList
	
	if (PU_Struct.eventCode == 2)			// mouse up
		Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
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
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	
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
	NVAR/Z NewGF_RebuildCoefListNow = root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
	if (!NVAR_Exists(NewGF_RebuildCoefListNow))
		Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1
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

	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
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

Function MOTO_NewGF_RemoveAllDataSets()

	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave

	Redimension/N=(1, 4, -1) ListWave, SelWave
	Redimension/N=(1, 1, -1) CoefListWave, CoefSelWave
	ListWave = ""
	CoefListWave = ""
	SelWave = 0
	CoefSelWave = 0
	Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
end

static Function NewGF_RemoveDataSetsProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
	Variable i,j
	Variable ncols = DimSize(ListWave, 1)
	Variable nrows = DimSize(ListWave, 0)
	
	if (PU_Struct.eventCode == 2)			// mouse up
		strswitch (PU_Struct.popStr)
			case "Remove All":
				MOTO_NewGF_RemoveAllDataSets()
				break
			case "Remove Selection":
				for (i = nrows-1; i >= 0; i -= 1)
					for (j = 0; j < ncols; j += 1)
						if (SelWave[i][j][0] & 9)
							DeletePoints i, 1, ListWave, SelWave, CoefListWave, CoefSelWave
							Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
							break
						endif
					endfor
				endfor
				break
			default:
				for (i = 0; i < nrows; i += 1)
					if (CmpStr(PU_Struct.popStr, ListWave[i][NewGF_DSList_YWaveCol][0]) == 0)
						DeletePoints i, 1, ListWave, SelWave, CoefListWave, CoefSelWave
						Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
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
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave

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

Function MOTO_SetFuncMenuProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
	
		Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
		Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
		Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
		
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
			
			Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
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

Function MOTO_NewGF_LinkCoefsButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
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
	
	Wave/T Tab1CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave Tab1CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave

	Variable accumulatedGuess = 0
	Variable numAccumulatedGuesses = 0
	Variable linkGuessListIndex = CoefIndexFromTab0CoefRowAndCol(linkrow, linkcol)
	if (linkGuessListIndex < DimSize(Tab1CoefListWave,0))
		Variable initGuess = str2num(Tab1CoefListWave[linkGuessListIndex][2])
		if (numtype(initGuess) == 0)
			accumulatedGuess += initGuess
			numAccumulatedGuesses += 1
		endif
		string listOfLinkedRows = num2str(linkGuessListIndex)+";"
		string tab1LinkCellText = Tab1CoefListWave[linkGuessListIndex][1]
	endif
	
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
				if (linkGuessListIndex < DimSize(Tab1CoefListWave, 0))
					initGuess = str2num(Tab1CoefListWave[linkGuessListIndex][2])
					if (numtype(initGuess) == 0)
						accumulatedGuess += initGuess
						numAccumulatedGuesses += 1
					endif
					Tab1CoefListWave[linkGuessListIndex][1] = "LINK:"+tab1LinkCellText
					Tab1CoefSelWave[linkGuessListIndex][1] = 0
					Tab1CoefSelWave[linkGuessListIndex][2] = 0
					Tab1CoefSelWave[linkGuessListIndex][3] = 0			// no more checkbox for holding
				endif
				listOfLinkedRows += num2str(linkGuessListIndex)+";"
				//				Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
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
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave

	Variable i, j
	col -= NewGF_DSList_FirstCoefCol
	
	Variable coefListIndex = 0
	for (i = 0; i < row; i += 1)
		coefListIndex += str2num(ListWave[i][NewGF_DSList_NCoefCol][0])
	endfor
	coefListIndex += col
	
	return coefListIndex
end

Function MOTO_UnLinkCoefsButtonProc(ctrlName) : ButtonControl
	String ctrlName


	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	//	Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave

	Wave/T Tab1CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave Tab1CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	
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
				if (linkGuessListIndex < DimSize(Tab1CoefSelWave, 0))
					Tab1CoefSelWave[linkGuessListIndex][1] = 2
					Tab1CoefSelWave[linkGuessListIndex][2] = 2
					Tab1CoefSelWave[linkGuessListIndex][3] = 0x20		// checkbox
					String coefName = CoefNameFromListText(CoefListWave[i][NewGF_DSList_FirstCoefCol + j][1])
					Tab1CoefListWave[linkGuessListIndex][1] = coefName+"["+DataSetListWave[i][NewGF_DSList_FuncCol][0]+"]["+DataSetListWave[i][NewGF_DSList_YWaveCol][1]+"]"	// last part is full path to Y wave
				endif
				//				Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
			endif
		endfor
	endfor
End

static Function NewGF_SelectAllCoefMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct

	if (PU_Struct.eventCode == 2)			// mouse up
		Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		//		Wave SelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListSelWave
		Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
		Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListSelWave
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

	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
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

	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave

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

	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	
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
	
	Variable/G root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow = 0
end

static Function NewGF_CoefListBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave

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
					PopupContextualMenu "\\M1(  Load From Wave:;"+Moto_ListInitGuessWaves(selectionExists, selectionExists)
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
	
	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave

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
	
	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave

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

	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Wave/T Tab0CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
	
	Variable numDataSets = DimSize(DataSetListWave, 0)
	if (numDataSets <= 1)
		if ( (numDataSets == 1) && (strlen(DataSetListWave[0][0][0]) == 0) )
			DoAlert 0, "You have not selected any data to fit."
			return -1
		endif
	endif
	
	Variable numCoefCols = DimSize(Tab0CoefListWave, 1)
	Variable i, j
	Variable nextFunc = 0

	Variable curveFitOptions = 0

	// build wave listing Fitting Function names. Have to check for repeats...
	Make/O/T/N=(numDataSets) root:Packages:MotofitGF:NewGlobalFit:NewGF_FitFuncNames = ""
	Wave/T FitFuncNames = root:Packages:MotofitGF:NewGlobalFit:NewGF_FitFuncNames
	
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
	
	Make/N=(numDataSets, numLinkageCols)/O root:Packages:MotofitGF:NewGlobalFit:NewGF_LinkageMatrix
	Wave LinkageMatrix = root:Packages:MotofitGF:NewGlobalFit:NewGF_LinkageMatrix
	
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
	Make/O/T/N=(numDataSets, 2) root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetsList
	Wave/T DataSets = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetsList
	DataSets[][0,1] = DataSetListWave[p][q+NewGF_DSList_YWaveCol][1]		// layer 1 contains full paths
	
	// Add weighting, if necessary
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_WeightingCheckBox
	if (V_value)
		GFUI_AddWeightWavesToDataSets(DataSets)
		NVAR/Z GlobalFit_WeightsAreSD = root:Packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD
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
	Make/O/D/N=(nRealCoefs, 3) root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefWave
	Wave coefWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefWave
	SetDimLabel 1,1,Hold,coefWave
	SetDimLabel 1,2,Epsilon,coefWave
	Make/O/T/N=(nRealCoefs) root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefficientNames
	Wave/T CoefNames = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefficientNames

	Variable coefIndex = 0
	Variable nTotalCoefs = DimSize(CoefListWave, 0)
	for (i = 0; i < nTotalCoefs; i += 1)
		if (!IsLinkText(CoefListWave[i][1]))
			coefWave[coefIndex][0] = str2num(CoefListWave[i][2])
			if (numtype(coefWave[coefIndex][0]) != 0)
				CoefSelWave = (CoefSelWave & ~9)
				CoefSelWave[i][2] = 3
				DoAlert 0, "There is a problem with the initial guess value in row "+num2str(i)+": it is not a number."
				TabControl NewGF_TabControl, win=MotoGlobalFitPanel,value=1
				MOTO_NewGF_SetTabControlContent(1)
				return -1
			endif
			coefWave[coefIndex][%Hold] = ((CoefSelWave[i][3] & 0x10) != 0)
			coefWave[coefIndex][%Epsilon] = str2num(CoefListWave[i][4])
			if (numtype(coefWave[coefIndex][%Epsilon]) != 0)
				TabControl NewGF_TabControl, win=MotoGlobalFitPanel,value=1
				MOTO_NewGF_SetTabControlContent(1)
				CoefSelWave = (CoefSelWave & ~9)
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
		Wave/T/Z ConstraintWave = root:Packages:MotofitGF:NewGlobalFit:GFUI_GlobalFitConstraintWave
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
	
	NVAR FitCurvePoints = root:Packages:MotofitGF:NewGlobalFit:FitCurvePoints
	
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
	
	NVAR maxIters = root:Packages:MotofitGF:NewGlobalFit:NewGF_MaxIters
	
	ControlInfo/W=MotoGlobalFitPanel#NewGF_GlobalControlArea NewGF_ResultNamePrefix
	String prefix = S_Value
	
	String resultDF = PopupWS_GetSelectionFullPath("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector")
	if (!DataFolderExists(resultDF))
		resultDF = ""
	endif
	
	if(cmpstr(ctrlname,"DoSimButton")==0)
		MOTO_DoNewGlobalSim(FitFuncNames, DataSets, LinkageMatrix, coefWave, CoefNames, ConstraintWave, curveFitOptions, FitCurvePoints, 1)
	else     
		Variable err = MOTO_DoNewGlobalFit(FitFuncNames, DataSets, LinkageMatrix, coefWave, CoefNames, ConstraintWave, curveFitOptions, FitCurvePoints, 1, maxIters=maxIters, resultWavePrefix=prefix, resultDF=resultDF)
		if (!err)
			SetCoefListFromWave(coefWave, 2, 0, 0)
		endif
	endif
	
	if (!err)
		SetCoefListFromWave(coefWave, 2, 0, 0)
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
		// work from the end of the string removing extraneous zeroes
		if(isLevORgen == 0)
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
	
	Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Variable NumSets = DimSize(ListWave, 0)
	Variable i

	if (checked)
		if (NumSets == 0)
			CheckBox NewGF_ConstraintsCheckBox, win=GlobalFitPanel, value=0
			DoAlert 0, "You cannot add constraints until you have selected data sets"
			return 0
		else
			NVAR/Z NewGF_RebuildCoefListNow = root:Packages:MotofitGF:NewGlobalFit:NewGF_RebuildCoefListNow
			if (!NVAR_Exists(NewGF_RebuildCoefListNow) || NewGF_RebuildCoefListNow)
				NewGF_RebuildCoefListWave()
			endif
			Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
			Variable totalParams = 0
			Variable CoefSize = DimSize(CoefListWave, 0)
			for (i = 0; i < CoefSize; i += 1)
				if (!IsLinkText(CoefListWave[i][1]))
					totalParams += 1
				endif
			endfor

			String saveDF = GetDatafolder(1)
			SetDatafolder root:Packages:MotofitGF:NewGlobalFit
			
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
	ListBox constraintsList,pos={12,49},size={380,127},listwave=root:Packages:MotofitGF:NewGlobalFit:SimpleConstraintsListWave
	ListBox constraintsList,selWave=root:Packages:MotofitGF:NewGlobalFit:SimpleConstraintsSelectionWave, mode=7
	ListBox constraintsList,widths={30,189,50,40,50}, editStyle= 1,frame=2,userColumnResize=1

	GroupBox AdditionalConstraintsGroup,pos={5,192},size={394,138},title="Additional Constraints"
	ListBox moreConstraintsList,pos={12,239},size={380,85}, listwave=root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	ListBox moreConstraintsList,selWave=root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsSelectionWave, mode=4
	ListBox moreConstraintsList, editStyle= 1,frame=2,userColumnResize=1
	Button NewConstraintLineButton,pos={21,211},size={138,20},title="Add a Line", proc=MOTO_WM_NewGlobalFit1#NewGF_NewCnstrntLineButtonProc
	Button RemoveConstraintLineButton01,pos={185,211},size={138,20},title="Remove Selection", proc=MOTO_WM_NewGlobalFit1#RemoveConstraintLineButtonProc

	Button GlobalFitConstraintsDoneB,pos={6,339},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitConstraintsDoneBProc,title="Done"
EndMacro

static Function SimpleConstraintsClearBProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T SimpleConstraintsListWave = root:Packages:MotofitGF:NewGlobalFit:SimpleConstraintsListWave
	SimpleConstraintsListWave[][2] = ""
	SimpleConstraintsListWave[][4] = ""
End

static Function NewGF_NewCnstrntLineButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T MoreConstraintsListWave = root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	Wave/Z MoreConstraintsSelectionWave = root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsSelectionWave
	Variable nRows = DimSize(MoreConstraintsListWave, 0)
	InsertPoints nRows, 1, MoreConstraintsListWave, MoreConstraintsSelectionWave
	MoreConstraintsListWave[nRows] = ""
	MoreConstraintsSelectionWave[nRows] = 6
	Redimension/N=(nRows+1,1) MoreConstraintsListWave, MoreConstraintsSelectionWave
End

static Function RemoveConstraintLineButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Wave/Z/T MoreConstraintsListWave = root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	Wave/Z MoreConstraintsSelectionWave = root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsSelectionWave
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

	Wave/Z/T SimpleConstraintsListWave = root:Packages:MotofitGF:NewGlobalFit:SimpleConstraintsListWave
	Wave/Z/T MoreConstraintsListWave = root:Packages:MotofitGF:NewGlobalFit:MoreConstraintsListWave
	
	Make/O/T/N=0 root:Packages:MotofitGF:NewGlobalFit:GFUI_GlobalFitConstraintWave
	Wave/T GlobalFitConstraintWave = root:Packages:MotofitGF:NewGlobalFit:GFUI_GlobalFitConstraintWave
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
		Wave/T ListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		Variable numSets = DimSize(ListWave, 0)

		if (NumSets == 0)
			CheckBox NewGF_WeightingCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea, value=0
			DoAlert 0, "You cannot choose weighting waves until you have selected data sets."
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:Packages:MotofitGF:NewGlobalFit
			
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
			
			Variable/G root:Packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD = NumVarOrDefault("root:Packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD", 1)
			NVAR GlobalFit_WeightsAreSD = root:Packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD
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
	
	ListBox WeightWaveListBox,pos={9,63},size={387,112}, mode=10, listWave = root:Packages:MotofitGF:NewGlobalFit:WeightingListWave,userColumnResize=1
	ListBox WeightWaveListBox, selWave = root:Packages:MotofitGF:NewGlobalFit:WeightingSelectionWave, frame=2,proc=MOTO_WM_NewGlobalFit1#NewGF_WeightListProc

	Button GlobalFitWeightDoneButton,pos={24,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitWeightDoneButtonProc,title="Done"
	Button GlobalFitWeightCancelButton,pos={331,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitWeightCancelButtonProc,title="Cancel"

	PopupMenu GlobalFitWeightWaveMenu,pos={9,5},size={152,20},title="Select Weight Wave"
	PopupMenu GlobalFitWeightWaveMenu,mode=0,value= #"MOTO_WM_NewGlobalFit1#ListPossibleWeightWaves()", proc=MOTO_WM_NewGlobalFit1#WeightWaveSelectionMenu

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
		Wave/T/Z WeightingListWave=root:Packages:MotofitGF:NewGlobalFit:WeightingListWave
		Variable NumSets = DimSize(WeightingListWave, 0)
		if ( (row == -1) && (col == 1) )
			Wave WeightingSelWave = root:Packages:MotofitGF:NewGlobalFit:WeightingSelectionWave
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

	Wave/T/Z WeightingListWave=root:Packages:MotofitGF:NewGlobalFit:WeightingListWave
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

	Wave/T/Z WeightingListWave=root:Packages:MotofitGF:NewGlobalFit:WeightingListWave
	Wave/Z WeightingSelectionWave=root:Packages:MotofitGF:NewGlobalFit:WeightingSelectionWave

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
		Wave/T WeightingListWave=root:Packages:MotofitGF:NewGlobalFit:WeightingListWave
		Wave WeightingSelWave = root:Packages:MotofitGF:NewGlobalFit:WeightingSelectionWave
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
//	Wave/T/Z WeightingListWave=root:Packages:MotofitGF:NewGlobalFit:WeightingListWave
//	StrSwitch (ctrlName)
//		case "WeightClearSelectionButton":
//			Wave WeightingSelWave = root:Packages:MotofitGF:NewGlobalFit:WeightingSelectionWave
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
	
	NVAR GlobalFit_WeightsAreSD= root:Packages:MotofitGF:NewGlobalFit:GlobalFit_WeightsAreSD
	
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
	
	Wave/T/Z WeightingListWave=root:Packages:MotofitGF:NewGlobalFit:WeightingListWave
	
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
	
	Wave/T/Z MaskingListWave=root:Packages:MotofitGF:NewGlobalFit:MaskingListWave
	
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
		Wave/T DataSetList = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
		Variable numSets = DimSize(DataSetList, 0)

		if (NumSets == 0)
			CheckBox NewGF_MaskingCheckBox, win=MotoGlobalFitPanel#NewGF_GlobalControlArea, value=0
			DoAlert 0, "You cannot add Masking waves until you have selected data sets."
			return 0
		else
			String saveDF = GetDatafolder(1)
			SetDatafolder root:Packages:MotofitGF:NewGlobalFit
			
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
	
	ListBox MaskWaveListBox,pos={9,63},size={387,112}, mode=10, listWave = root:Packages:MotofitGF:NewGlobalFit:MaskingListWave,userColumnResize=1
	ListBox MaskWaveListBox, selWave = root:Packages:MotofitGF:NewGlobalFit:MaskingSelectionWave, frame=2, proc=MOTO_WM_NewGlobalFit1#NewGF_MaskListProc
	Button GlobalFitMaskDoneButton,pos={24,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitMaskDoneButtonProc,title="Done"
	Button GlobalFitMaskCancelButton,pos={331,186},size={50,20},proc=MOTO_WM_NewGlobalFit1#GlobalFitMaskCancelButtonProc,title="Cancel"
	PopupMenu GlobalFitMaskWaveMenu,pos={9,5},size={152,20},title="Select Mask Wave"
	PopupMenu GlobalFitMaskWaveMenu,mode=0,value= #"MOTO_WM_NewGlobalFit1#ListPossibleMaskWaves()", proc=MOTO_WM_NewGlobalFit1#MaskWaveSelectionMenu
	Button MaskClearSelectionButton,pos={276,5},size={120,20},proc=MOTO_WM_NewGlobalFit1#MaskClearSelectionButtonProc,title="Clear Selection"
	Button MaskClearAllButton,pos={276,32},size={120,20},proc=MOTO_WM_NewGlobalFit1#MaskClearSelectionButtonProc,title="Clear All"
EndMacro


static Function NewGF_MaskListProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if (event == 1)
		Wave/T/Z MaskingListWave=root:Packages:MotofitGF:NewGlobalFit:MaskingListWave
		Variable numSets = DimSize(MaskingListWave, 0)
		if ( (row == -1) && (col == 1) )
			Wave MaskingSelWave = root:Packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
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

	Wave/T/Z MaskingListWave=root:Packages:MotofitGF:NewGlobalFit:MaskingListWave
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

	Wave/T/Z MaskingListWave=root:Packages:MotofitGF:NewGlobalFit:MaskingListWave
	Wave/Z MaskingSelectionWave=root:Packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
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
		Wave/T MaskingListWave=root:Packages:MotofitGF:NewGlobalFit:MaskingListWave
		Wave MaskingSelWave = root:Packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
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

	Wave/T/Z MaskingListWave=root:Packages:MotofitGF:NewGlobalFit:MaskingListWave
	StrSwitch (ctrlName)
		case "MaskClearSelectionButton":
			Wave MaskingSelWave = root:Packages:MotofitGF:NewGlobalFit:MaskingSelectionWave
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

Function/S Moto_ListInitGuessWaves(SelectedOnly, LinkRowsOK)
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

Function MOTO_SetCoefsFromWaveProc(PU_Struct) : PopupMenuControl
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

Function Moto_SaveCoefsToWaveProc(PU_Struct) : PopupMenuControl
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
// Make new data folder
//
//***********************************

Function MOTO_ResultsDFSelectorNotify(event, selectionStr, windowName, ctrlName)
	Variable event
	String selectionStr
	String windowName
	String ctrlName

	if (CmpStr(selectionStr, NewGF_NewDFMenuString) == 0)
		if (WinType("NewGF_GetNewDFNamePanel") == 7)
			Execute/P/Q "DoWindow/F NewGF_GetNewDFNamePanel"
		else
			Execute/P/Q "MOTO_WM_NewGlobalFit1#MOTO_build_GetNewDFNamePanel()"
		endif
		PopupWS_SetSelectionFullPath("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", GetUserData("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", "NewGF_SavedSelection"))
	else
		Button $ctrlName, win=$windowName,UserData(NewGF_SavedSelection)=selectionStr
	endif
end

Function MOTO_build_GetNewDFNamePanel()

	NewPanel/K=1/W=(373,50,637,358)/N=NewGF_GetNewDFNamePanel as "Get New Data Folder Name"
	
	TitleBox NewGF_CDFTitle,pos={15,6},size={117,16},title="Current Data Folder:"
	TitleBox NewGF_CDFTitle,fSize=12,frame=0

	TitleBox NewGF_NewDFCDFTitle,pos={55,28},size={85,16},title=GetDataFolder(1)
	TitleBox NewGF_NewDFCDFTitle,fSize=12,frame=0
	
	Button NewGF_NewDFSelectParentDF,pos={55,93},size={150,20}
	MakeButtonIntoWSPopupButton("NewGF_GetNewDFNamePanel", "NewGF_NewDFSelectParentDF", "" , initialSelection=RemoveEnding(GetDataFolder(1)), content=WMWS_DataFolders)

	
	TitleBox NewGF_ParentDFTitle,pos={15,72},size={112,16},title="Parent Data Folder:"
	TitleBox NewGF_ParentDFTitle,fSize=12,frame=0
	
	SetVariable NewGF_NewDFSetFolderName,pos={50,171},size={160,19},bodyWidth=160,proc=MOTO_NewDFSetFolderNameProc
	SetVariable NewGF_NewDFSetFolderName,fSize=12,value= _STR:""
	
	TitleBox NewGF_NewDFTitle,pos={15,145},size={136,16},title="New Data Folder Name:"
	TitleBox NewGF_NewDFTitle,fSize=12,frame=0
	
	Button NewGF_NewDFOKButton,pos={55,206},size={150,20},proc=MOTO_NewDFOKButtonProc,title="Make Data Folder"
	
	Button NewGF_NewDFDoneButton,pos={80,262},size={100,20},proc=MOTO_NewDFDoneButtonProc,title="Done"
end

Function MOTO_NewDFOKButtonProc(ctrlName) : ButtonControl
	String ctrlName

	String ParentDFName = PopupWS_GetSelectionFullPath("NewGF_GetNewDFNamePanel", "NewGF_NewDFSelectParentDF") + ":"
	String saveDF = GetDataFolder(1)
	SetDataFolder ParentDFName
	ControlInfo/W=NewGF_GetNewDFNamePanel NewGF_NewDFSetFolderName
	String newDFName = S_value
	NewDataFolder/O $newDFName
	SetDataFolder saveDF
	
	PopupWS_SetSelectionFullPath("MotoGlobalFitPanel#NewGF_GlobalControlArea", "NewGF_ResultsDFSelector", ParentDFName+PossiblyQuoteName(newDFName))
	Button NewGF_ResultsDFSelector, win=MotoGlobalFitPanel#NewGF_GlobalControlArea,UserData(NewGF_SavedSelection)=ParentDFName+PossiblyQuoteName(newDFName)
End

Function MOTO_NewDFDoneButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K NewGF_GetNewDFNamePanel
End

Function MOTO_NewDFSetFolderNameProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			String sval = sva.sval
			if ( (strlen(sval) > 0) && (CmpStr(sval, CleanupName(sval, 1)) == 0) )
				Button NewGF_NewDFOKButton, win=$(sva.win), disable=0
			else
				Button NewGF_NewDFOKButton, win=$(sva.win), disable=2
			endif
			break
	endswitch

	return 0
End

//***********************************
//
// Data Wave Selector
//
//***********************************

Function MOTO_BuildDataSetSelector()

	if (WinType("NewGF_SelectDataSetsPanel") == 7)
		DoWindow/F NewGF_SelectDataSetsPanel
		return 0
	endif

	NewPanel/N=NewGF_SelectDataSetsPanel/K=1/W=(230,330,848,804) as "Add/Remove Data Sets"

	CheckBox DataSets_FromTargetCheck,pos={266,16},size={90,16},proc=MOTO_DataSetsFmTargetCheckProc,title="From Target"
	CheckBox DataSets_FromTargetCheck,fSize=12,value= 0

	TitleBox SelectData_YWavesTitle,pos={93,9},size={104,19},title="Select Y Waves"
	TitleBox SelectData_YWavesTitle,fSize=14,frame=0,fStyle=1

	ListBox NewGF_SelectDataSetsYSelector,pos={28,35},size={235,175}
	MakeListIntoWaveSelector("NewGF_SelectDataSetsPanel", "NewGF_SelectDataSetsYSelector", selectionMode=WMWS_SelectionNonContiguous)

	PopupMenu NewData_YListSortMenu,pos={46,217},size={20,20}, proc=MOTO_DataSets_SelPopupMenuProc
	MakePopupIntoWaveSelectorSort("NewGF_SelectDataSetsPanel", "NewGF_SelectDataSetsYSelector", "NewData_YListSortMenu")

	SetVariable DataSets_YListFilterString,pos={88,218},size={73,19},bodyWidth=40,proc=MOTO_DS_SelFilterSetVarProc,title="Filter"
	SetVariable DataSets_YListFilterString,fSize=12,value= _STR:"*"
	
	PopupMenu DataSets_YListSelectMenu,pos={170,218},size={75,20},bodyWidth=75,proc=MOTO_DataSets_SelPopupMenuProc,title="Select"
	PopupMenu DataSets_YListSelectMenu,mode=0,value= #"\"All;Every Other;Every Other starting with second;Every Third;Every Thirdstarting with second;Every Thirdstarting with third;\""

	TitleBox SelectData_XWavesTitle,pos={424,9},size={104,19},title="Select X Waves"
	TitleBox SelectData_XWavesTitle,fSize=14,frame=0,fStyle=1

	ListBox NewGF_SelectDataSetsXSelector,pos={359,35},size={235,175}
	MakeListIntoWaveSelector("NewGF_SelectDataSetsPanel", "NewGF_SelectDataSetsXSelector", selectionMode=WMWS_SelectionNonContiguous)
	WS_AddSelectableString("NewGF_SelectDataSetsPanel", "NewGF_SelectDataSetsXSelector", "_calculated_")
	

	PopupMenu NewData_XListSortMenu,pos={373,217},size={20,20}
	MakePopupIntoWaveSelectorSort("NewGF_SelectDataSetsPanel", "NewGF_SelectDataSetsXSelector", "NewData_XListSortMenu")

	SetVariable DataSets_XListFilterString,pos={415,218},size={73,19},bodyWidth=40,title="Filter"
	SetVariable DataSets_XListFilterString,fSize=12,value= _STR:"*",proc=MOTO_DS_SelFilterSetVarProc

	PopupMenu DataSets_XListSelectMenu,pos={497,218},size={75,20},bodyWidth=75,title="Select",proc=MOTO_DataSets_SelPopupMenuProc
	PopupMenu DataSets_XListSelectMenu,mode=0,value= #"\"All;Every Other;Every Other starting with second;Every Third;Every Thirdstarting with second;Every Thirdstarting with third;\""

	Button NewGF_SelectDataSetsArrowButt,pos={285,249},size={50,25},proc=MOTO_SelDataSetsArrowButtonProc,title="\\$PICT$name=ProcGlobal#MOTO_YellowDownArrow$/PICT$"
	Button NewGF_SelectDataSetsYArrowBtn,pos={117,249},size={50,25},proc=MOTO_SelDataSetsArrowButtonProc,title="\\$PICT$name=ProcGlobal#MOTO_YellowDownArrow$/PICT$"
	Button NewGF_SelectDataSetsXArrowBtn,pos={443,249},size={50,25},proc=MOTO_SelDataSetsArrowButtonProc,title="\\$PICT$name=ProcGlobal#MOTO_YellowDownArrow$/PICT$"

	Make/O/N=(0,2)/T root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	Make/O/N=(0,2) root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
	Wave/T SelectedDataSetsListWave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	Wave SelectedDataSetsSelWave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
	SetDimLabel 1,0,'Y waves',root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	SetDimLabel 1,1,'X waves',root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	ListBox NewGF_SelectedDataSetsList,pos={28,292},size={566,138},proc=MOTO_SelectedDataListBoxProc
	ListBox NewGF_SelectedDataSetsList,listWave=root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	ListBox NewGF_SelectedDataSetsList,selWave=root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
	ListBox NewGF_SelectedDataSetsList,mode= 10,editStyle= 1
	
	Wave/T DataSetListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_DataSetListWave
	Variable nrows = DimSize(DataSetListWave, 0)
	if ( (nrows == 1) && AllFieldsAreBlank(DataSetListWave, 0))
		nrows = 0
	endif
	if (nrows > 0)
		Redimension/N=(nrows, 2) SelectedDataSetsListWave, SelectedDataSetsSelWave
		SelectedDataSetsListWave[][] = DataSetListWave[p][q][1]		// layer 1 contains full paths
	endif

	GroupBox SelectData_MoverBox,pos={164,435},size={222,33}

	Button SelectData_MoveUpButton,pos={300,440},size={30,22},proc=MOTO_DataSetsMvSelWavesUpOrDown,title="\\F'Symbol'­"

	Button SelectData_MoveDnButton,pos={340,440},size={30,22},proc=MOTO_DataSetsMvSelWavesUpOrDown,title="\\F'Symbol'¯"

	TitleBox SelectData_MoverTitle,pos={184,443},size={87,16},title="Move Selection"
	TitleBox SelectData_MoverTitle,fSize=12,frame=0

	Button DataSets_SelectAll,pos={393,443},size={75,20},proc=MOTO_DataSets_SelAllBtnProc,title="Select All"

	Button DataSets_OKButton,pos={27,443},size={100,20},proc=MOTO_DataSets_OKButtonProc,title="OK"

	Button DataSets_CancelButton,pos={494,443},size={100,20},proc=MOTO_DataSets_CancelButtonProc,title="Cancel"
	
	SetWindow NewGF_SelectDataSetsPanel, hook(DataSetsSelectorHook)=MOTO_SelectDataSets_WindowHook
end

Function MOTO_DataSetsFmTargetCheckProc(s)
	STRUCT WMCheckboxAction &s
	
	if (s.eventCode == 2)		// mouse up
		
	endif
end

Function MOTO_DS_SelFilterSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			string listboxName = "NewGF_SelectDataSetsYSelector"
			if (CmpStr(sva.ctrlName, "DataSets_XListFilterString") == 0)
				listboxName = "NewGF_SelectDataSetsXSelector"
			endif
			if (strlen(sva.sval) == 0)
				sva.sval="*"
				SetVariable $sva.ctrlName,win=$sva.win,value= _STR:"*"
			endif
			WS_SetFilterString(sva.win, listboxName, sva.sval)
			break
	endswitch

	return 0
End

Function MOTO_DataSets_SelPopupMenuProc(s) : PopupMenuControl
	STRUCT WMPopupAction &s

	switch( s.eventCode )
		case 2: // mouse up
			String indexedPath = "", listofPaths = ""
			Variable index=0
			string listboxName = "NewGF_SelectDataSetsYSelector"
			if (CmpStr(s.ctrlName, "DataSets_XListSelectMenu") == 0)
				listboxName = "NewGF_SelectDataSetsXSelector"
				index=1
			endif
			switch (s.popNum)
				case 1:			// select all
					do
						indexedPath = WS_IndexedObjectPath(s.win, listboxName, index)
						if (strlen(indexedPath) == 0)
							break;
						endif
						listofPaths += indexedPath+";"
						index += 1
					while (1)
					break;
				case 2:			// select every other
					do
						indexedPath = WS_IndexedObjectPath(s.win, listboxName, index)
						if (strlen(indexedPath) == 0)
							break;
						endif
						listofPaths += indexedPath+";"
						index += 2
					while (1)
					break;
				case 3:			// select every other starting with second
					index += 1
					do
						indexedPath = WS_IndexedObjectPath(s.win, listboxName, index)
						if (strlen(indexedPath) == 0)
							break;
						endif
						listofPaths += indexedPath+";"
						index += 2
					while (1)
					break;
				case 4:			// select every third
					do
						indexedPath = WS_IndexedObjectPath(s.win, listboxName, index)
						if (strlen(indexedPath) == 0)
							break;
						endif
						listofPaths += indexedPath+";"
						index += 3
					while (1)
					break;
				case 5:			// select every third starting with second
					index += 1
					do
						indexedPath = WS_IndexedObjectPath(s.win, listboxName, index)
						if (strlen(indexedPath) == 0)
							break;
						endif
						listofPaths += indexedPath+";"
						index += 3
					while (1)
					break;
				case 6:			// select every third starting with third
					index += 2
					do
						indexedPath = WS_IndexedObjectPath(s.win, listboxName, index)
						if (strlen(indexedPath) == 0)
							break;
						endif
						listofPaths += indexedPath+";"
						index += 3
					while (1)
					break;
			endswitch
			WS_ClearSelection(s.win, listboxName)
			WS_SelectObjectList(s.win, listboxName, listofPaths)
			break
	endswitch
end

Function MOTO_SelData_CheckForDupYWaves()

	Wave/T listwave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	Wave selwave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
	Variable nrows = DimSize(listwave, 0)
	Variable i,j

	// look for duplicate Y waves, an N^2 operation!
	nrows = DimSize(listwave, 0)
	if (nrows < 2)
		return 0
	endif
	
	for (i = 0; i < nrows-1; i += 1)
		for (j = i+1; j < nrows; j += 1)
			if (CmpStr(listwave[i][0], listwave[j][0]) == 0)		// found a duplicate
				selwave = 0
				selwave[i][0] = selwave[i][0] | 1
				selwave[j][0] = selwave[j][0] | 1
				DoUpdate
				DoAlert 0, "Found duplicate Y waves."
				return 1
				break;
			endif
		endfor
	endfor
	
	return 0
end

Function MOTO_SelDataSetsArrowButtonProc(s) : ButtonControl
	STRUCT WMButtonAction &s

	if (s.eventCode == 2)			// mouse up
		String YWaves = WS_SelectedObjectsList(s.win, "NewGF_SelectDataSetsYSelector")
		String XWaves = WS_SelectedObjectsList(s.win, "NewGF_SelectDataSetsXSelector")
		Variable nwaves = ItemsInList(YWaves)
		Variable nXwaves = ItemsInList(Xwaves)
		
		if (nXwaves == 1)
			String singleXwave = StringFromList(0, XWaves)
		endif
		
		Wave/T listwave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
		Wave selwave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
		Variable nrows = DimSize(listwave, 0)
		Variable i, j, index, startWave=0
		Variable DoingX=0, DoingY=0
		
		if (CmpStr(s.ctrlName, "NewGF_SelectDataSetsYArrowBtn") == 0)
			// first insert selections into cells that are selected
			index = 0
			for (i = 0; i < nrows; i += 1)
				if ( (strlen(listWave[i][0]) == 0) || (selwave[i][0] & 9) )
					listWave[i][0] = StringFromList(index, YWaves)
					index += 1
					if (index >= nwaves)
						break;
					endif
				endif
			endfor
			startWave = index
			// if any are left over, add rows to receive the waves, and leave the X cells blank
			DoingY = 1
		elseif  (CmpStr(s.ctrlName, "NewGF_SelectDataSetsXArrowBtn") == 0)
			if (nXwaves > 1)
				for (i = 0; i < nrows; i += 1)
					if ( (strlen(listWave[i][1]) == 0) || (selwave[i][1] & 9) )
						listWave[i][1] = StringFromList(index, XWaves)
						index += 1
						if (index >= nXwaves)
							break;
						endif
					endif
				endfor
				startWave = index
				DoingX = 1
				nwaves = nXwaves
			else
				for (i = 0; i < nrows; i += 1)
					if ( (strlen(listWave[i][1]) == 0) || (selwave[i][1] & 9) )
						listWave[i][1] = singleXwave
					endif
				endfor
			endif
		else
			if ( (nwaves != nXwaves) && (nXwaves != 1) )
				DoAlert 0, "You have selected "+num2str(nwaves)+" Y waves, but "+num2str(ItemsInList(Xwaves))+" X waves."
				return -1
			endif
			DoingX = 1
			DoingY = 1
		endif

		if (DoingX || DoingY)
			if (startWave < nwaves)
				Variable firstNewRow = nrows
				InsertPoints firstNewRow, nwaves-startWave, listwave, selwave
				for (i = startWave; i < nWaves; i += 1)
					index = firstNewRow+i
					if (DoingY)
						listwave[index][0] = StringFromList(i, YWaves)
					endif
					if (DoingX)
						if (nXwaves == 1)
							listwave[index][1] = singleXwave
						else
							listwave[index][1] = StringFromList(i, XWaves)
						endif
					endif
				endfor
			endif
		endif
		
		MOTO_SelData_CheckForDupYWaves()
	endif
End

Function MOTO_SelectDataSets_WindowHook(s)
	STRUCT WMWinHookStruct &s

	Variable returnValue = 0
	
	strswitch (s.eventName)
		case "keyboard":
			if ( (s.keycode == 8) || (s.keycode == 127) )			// delete or forward delete
				Wave/T listwave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
				Wave selWave=root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
				Variable nrows = DimSize(listwave, 0)
				Variable i
				for (i = nrows-1; i >= 0; i -= 1)
					if ( (selwave[i][0] & 9) || ((selwave[i][1] & 9)) )
						DeletePoints i, 1, listwave, selwave
					endif
				endfor
				if (DimSize(listwave, 0) == 0)
					Redimension/N=(0,2) listwave, selwave
				endif
				MOTO_SelData_CheckForDupYWaves()
				returnValue = 1
			endif
			break;
	endswitch
	
	return returnValue
end

Function MOTO_SelectedDataListBoxProc(s) : ListBoxControl
	STRUCT WMListboxAction &s

	Variable row = s.row
	Variable col = s.col
	WAVE/T/Z listWave = s.listWave
	WAVE/Z selWave = s.selWave

	switch( s.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			if ( (s.row >= 0) && (s.row < DimSize(listWave, 0)) && (s.eventMod & 16) )
				
			endif
			break
		case 2:	// mouse up
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 12:	// key stroke
			if ( (s.row == 8) || (s.row == 127) )			// delete or forward delete
				Variable nrows = DimSize(listwave, 0)
				Variable i
				for (i = nrows-1; i >= 0; i -= 1)
					if ( (selwave[i][0] & 9) || ((selwave[i][1] & 9)) )
						DeletePoints i, 1, listwave, selwave
					endif
				endfor
				if (DimSize(listwave, 0) == 0)
					Redimension/N=(0,2) listwave, selwave
				endif
				MOTO_SelData_CheckForDupYWaves()
			elseif ( ((s.row == char2num("a")) || (s.row == char2num("A"))) && (s.eventMod & 8) )
				selwave = selwave[p][q] | 1
			else
				//print "Listbox char code = ", s.row
			endif
			break;
	endswitch

	return 0
End

Function MOTO_DataSets_SelAllBtnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Wave selWave=root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
			selwave = selwave[p][q] | 1
			break
	endswitch

	return 0
End

Function MOTO_DataSetsMvSelWavesUpOrDown(s) : ButtonControl
	STRUCT WMButtonAction &s
	
	if (s.eventCode != 2)
		return 0
	endif

	Wave/T SelectedWavesListWave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
	Wave SelectedWavesSelWave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
	
	Duplicate/O/T/FREE SelectedWavesListWave, DuplicateSelectedWaveListWave
	Duplicate/O/FREE SelectedWavesSelWave, DuplicateSelectedWavesSelWave
	
	Variable rowsInSelectedList = DimSize(SelectedWavesSelWave, 0)
	Variable firstSelectedRow = rowsInSelectedList
	Variable lastSelectedRow = rowsInSelectedList
	Variable nSelectedRows = 0
	Variable i
	Variable lastRow = rowsInSelectedList-1
	
	Variable moveUp = CmpStr(s.ctrlName, "SelectData_MoveUpButton") == 0
	
	if (moveUp)
		if ( (SelectedWavesSelWave[0][0] & 0x01) || (SelectedWavesSelWave[0][1] & 0x01) )
			return 0		// a cell in the top row is selected; can't move up
		endif
	else
		if ( (SelectedWavesSelWave[lastRow][0] & 0x01) || (SelectedWavesSelWave[lastRow][1] & 0x01) )
			return 0		// a cell in the bottom row is selected; can't move down
		endif
	endif
	
	Variable col
	for (col = 0; col < 2; col += 1)
		nSelectedRows = 0
		
		if (moveUp)
			for (i = 0; i < rowsInSelectedList; i += 1)
				if (SelectedWavesSelWave[i][col] & 0x09)
					SelectedWavesListWave[i-1][col] = DuplicateSelectedWaveListWave[i][col]
					SelectedWavesSelWave[i-1][col] = DuplicateSelectedWavesSelWave[i][col]
					SelectedWavesListWave[i][col] = DuplicateSelectedWaveListWave[i -1][col]
					SelectedWavesSelWave[i][col] = DuplicateSelectedWavesSelWave[i -1][col]
				endif
			endfor
		else
			for (i = rowsInSelectedList-1; i >= 0; i -= 1)
				if (SelectedWavesSelWave[i][col] & 0x09)
					SelectedWavesListWave[i+1][col] = DuplicateSelectedWaveListWave[i][col]
					SelectedWavesSelWave[i+1][col] = DuplicateSelectedWavesSelWave[i][col]
					SelectedWavesListWave[i][col] = DuplicateSelectedWaveListWave[i+1][col]
					SelectedWavesSelWave[i][col] = DuplicateSelectedWavesSelWave[i +1][col]
				endif
			endfor
		endif
	endfor
end

Function MOTO_DataSets_CancelButtonProc(s) : ButtonControl
	STRUCT WMButtonAction &s

	switch( s.eventCode )
		case 2: // mouse up
			DoWindow/K $(s.win)
			break
	endswitch

	return 0
End

Function MOTO_DataSets_OKButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Wave/T SelectedWavesListWave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsListWave
			Wave SelectedWavesSelWave = root:Packages:MotofitGF:NewGlobalFit:SelectedDataSetsSelWave
			Variable nSelected = DimSize(SelectedWavesListWave, 0)
			Variable i
			
			// Some sanity checks
			for (i = 0; i < nSelected; i += 1)
				if (CmpStr(SelectedWavesListWave[i][0], SelectedWavesListWave[i][1]) == 0)
					SelectedWavesSelWave = 0
					SelectedWavesSelWave[i][0] = SelectedWavesSelWave[i][0] | 1
					SelectedWavesSelWave[i][1] = SelectedWavesSelWave[i][1] | 1
					DoUpdate
					DoAlert 0, "You have selected the same wave for both the Y and the X waves."
					return 0
				endif
				Wave/Z w = $(SelectedWavesListWave[i][0])
				if (!WaveExists(w))
					SelectedWavesSelWave = 0
					SelectedWavesSelWave[i][0] = SelectedWavesSelWave[i][0] | 1
					DoUpdate
					DoAlert 0, "One of your Y waves is missing."
					return 0
				endif
				Wave/Z xw = $(SelectedWavesListWave[i][0])
				if (WaveExists(xw) && (numpnts(w) != numpnts(xw)))
					SelectedWavesSelWave = 0
					SelectedWavesSelWave[i][0] = SelectedWavesSelWave[i][0] | 1
					SelectedWavesSelWave[i][1] = SelectedWavesSelWave[i][1] | 1
					DoUpdate
					DoAlert 0, "The number of points in your Y wave does not match the number of points in the X wave."
					return 0
				endif
			endfor
			
			MOTO_NewGF_RemoveAllDataSets()
			
			for (i = 0; i < nSelected; i += 1)
				Wave w = $(SelectedWavesListWave[i][0])
				Wave/Z xw = $(SelectedWavesListWave[i][1])
				
				//	if (WaveExists(w) && !NewGF_WaveInListAlready(w))
				NewGF_AddYWaveToList(w, xw)
				//	endif
			endfor
			DoWindow/K $(ba.win)
			break
	endswitch

	return 0
End

\$PICT$name=ProcGlobal#MOTO_YellowRightArrow$/PICT$
// PNG: width= 13, height= 15
Picture MOTO_YellowRightArrow
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!!.!!!!0#Qau+!3ec;+92BF&SXU":e=#A+Ad)sAnc'm!!%6Ejct6f;ca
gUhg8S]67j<&+"Mut!MU:-TX#%.9DK:A.Ni)mf_4m`8_ZnK<"MHfLbcI'KGd$c5r4H.-E%cPS*3]36
l.19*'-oQ)of[FC`9%U41F%cZ=pQD4ZBq7GMi:fF7+BmT(<#&`YBb%J-1<k9BhXL+p@-JR0*(6huXQ
Ohu[d'<=p[Fb7fuu(%'+;_!"i%rq'IcR1A52Ngm9pL<_P\F56ar%/N'0e"['I0EDM?j]QgWbt8Aad_
(D\.AY([=d?05&<ho=qNN6Ci[2Uio?<0Fe#YA^UQ/r=.M%MMmR8\X&o'#Xo)K2',,[s8_!X__o.!Y!
1`T]ZYL2R\r#DL5?[=A%O.$i$d0^Ihlg\db\I>,_&qL#@Cs;&u!4O`ah4N$5VZ"a9K7saMjTYmWVo'
K8cl,n2e&2LlQNpo'DDKK7BJMa>"L(c**4`!tef2h:J.g?fcl[625ELF/WhC*o@]if_FoWK%=5XP_$
Ut/,N(G]NXgYQhX?Q>Y:7*oZqMrhPgt"IjG`B.em7u=F3nQKrGIlkJd\Y9Li3V4n4li1Jo5!1in@If
3jJuAs+L:P[$b3jF1[*c&O+Sr/q@I5:4Bs)l7i3I@UG'P,?<*Q#0laU+P2r1nPfc`WA\?)nY'8O&8=
;_Zc98"YNEM_=aa!bdEG`h/ZD`ZUD2,(F]?3?1fpc9V^]*t[e04_?ShJ5J_bM,rFIeVFHi#nL2,8YA
@)amEUj$Y@Gk_D"ebc0-RET4<:[U3H@4leT(nr,l.\HsJ_@5Rfj^W/[1bQ\8E$HTg1!E=$N`bOJ>h3
mQ_%C]/=ngQ*F*Gm.i,,a$[VN,Ib(8MR3"MP6>k?hYj;[!hi2N3l'K15.]S@;>>Nih86r^Wt/p:>P*
-?:*7IXJPG_f_*+P]o\,83S$`?`GPj#=`bs1Qm^7oOZ3&a:$u(Y:ZZCD6k=FRBld`l;ZFcGEI/D,]H
Voil/\#HAD\)L()l1LA,*-_'P5'XY1#g5i)#QoVkK)j^pS>ai=*qI+JR_pC&\1jAtE;"i6q=o*C&C$
N#<0?r;ogd)&n+WZI!;`G-qY^+kNC^5,$\&G]Cis\!R`OL]/^M1+$C6DT7p1N:Fe68d(#]6/RLZ\6u
\np-g^9m?s467=@eEn7@1?;K]pMoZn:jS/INtlh`n\'/A9_i9Rm.Z^#c7XQ-i9ZWj^n6o2Q?rfH8fC
&(6e@'*9!ts1;+G,6XMPY-8M$'49Qj]O8/ofYP;SSqX(2j`o>pZ-C4rBuOd@6&['G(P11L.-cGnZtH
Wk/Sl_R=h/]q+CgV[N&:3N7D4*RX4q9"ic4Z=G=>4?V/rC>n;-ABp`c&A&a(9^m]@Q@A#rq5\1:Ybu
*d@"M71Tb)i!*Wh31)^-*XoWq@#f+%g^mPKO8,c,C!+(iiGd0'_f1V3p8cUmJol:eipU,%i?hqDomK
'QA1mBqL:l9"-NZa`>-Ib(BUq2@5:m;;tM?:1`YFonAJY`q*8rs+2XocZF!@.c$:)O,_TL2M;W%Tp@
;a;dXQ@T,%e>NT9&Q*3EJYM;+rr7T4msF;YasfW!(dOrC9D.S_HqIeg6Di4n`Dhk(,`'pL(5i<H@W;
s]Zd``Y=S;al>]?I;qD=d?8Ord9rWFIFh=tSEmh>a%!AI)55u]6I9oqY9_a"W!4\7+lh$k)3;Kh::Z
=_d-H4[6p<Tk#S94l-YU>u<N66V5l8U):DkYu]>rP-,7]!cJ)1gQDYT'%@j7)V(j2F-(`L<+ImGXbM
\#$XO4B!\2"AJkKGU*rP5-uOS_PTYo878B`cg8GrZ,gB#&4RSX\A]6L*lfudO^L&U$>FN)?#uX0`92
ql'/:4i6f.35&VUhG)dXNE2W'4sq]XO/J!CY:@]n5MTJV9Z\2+k7n?1eoo6:_@bCVZ,ErH<_J!M^I0
74%+.m5.$iql]6mH,$qf@Da4#23$L4G`qd$<Co;P^>m,PHS;58j[Grpqn>#IL1+IHs,\i%\D;m;L,U
]Q),](,*7l/_ch#o6g@(nQqG3h?l.QHJBg7;+Q/_!np<Wd>!!#SZ:.26O@"J
ASCII85End
End
// PNG: width= 16, height= 12
Picture MOTO_YellowDownArrow
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!!1!!!!-#Qau+!9Aj6ec5[R&SXU":e=#A+Ad)sAnc'm!!%6Ejct6f;ca
gUhg8S]67j<&+"Mut!MU:-TX#%.9DK:A.Ni)mf_4m`8_ZnK<"MHfLbcI'KGd$c5r4H.-E%cPS*3]36
l.19*'-oQ)of[FC`9%U41F%cZ=pQD4ZBq7GMi:fF7+BmT(<#&`YBb%J-1<k9BhXL+p@-JR0*(6huXQ
Ohu[d'<=p[Fb7fuu(%'+;_!"i%rq'IcR1A52Ngm9pL<_P\F56ar%/N'0e"['I0EDM?j]QgWbt8Aad_
(D\.AY([=d?05&<ho=qNN6Ci[2Uio?<0Fe#YA^UQ/r=.M%MMmR8\X&o'#Xo)K2',,[s8_!X__o.!Y!
1`T]ZYL2R\r#DL5?[=A%O.$i$d0^Ihlg\db\I>,_&qL#@Cs;&u!4O`ah4N$5VZ"a9K7saMjTYmWVo'
K8cl,n2e&2LlQNpo'DDKK7BJMa>"L(c**4`!tef2h:J.g?fcl[625ELF/WhC*o@]if_FoWK%=5XP_$
Ut/,N(G]NXgYQhX?Q>Y:7*oZqMrhPgt"IjG`B.em7u=F3nQKrGIlkJd\Y9Li3V4n4li1Jo5!1in@If
3jJuAs+L:P[$b3jF1[*c&O+Sr/q@I5:4Bs)l7i3I@UG'P,?<*Q#0laU+P2r1nPfc`WA\?)nY'8O&8=
;_Zc98"YNEM_=aa!bdEG`h/ZD`ZUD2,(F]?3?1fpc9V^]*t[e04_?ShJ5J_bM,rFIeVFHi#nL2,8YA
@)amEUj$Y@Gk_D"ebc0-RET4<:[U3H@4leT(nr,l.\HsJ_@5Rfj^W/[1bQ\8E$HTg1!E=$N`bOJ>h3
mQ_%C]/=ngQ*F*Gm.i,,a$[VN,Ib(8MR3"MP6>k?hYj;[!hi2N3l'K15.]S@;>>Nih86r^Wt/p:>P*
-?:*7IXJPG_f_*+P]o\,83S$`?`GPj#=`bs1Qm^7oOZ3&a:$u(Y:ZZCD6k=FRBld`l;ZFcGEI/D,]H
Voil/\#HAD\)L()l1LA,*-_'P5'XY1#g5i)#QoVkK)j^pS>ai=*qI+JR_pC&\1jAtE;"i6q=o*C&C$
N#<0?r;ogd)&n+WZI!;`G-qY^+kNC^5,$\&G]Cis\!R`OL]/^M1+$C6DT7p1N:Fe68d(#]6/RLZ\6u
\np-g^9m?s467=@eEn7@1?;K]pMoZn:jS/INtlh`n\'/A9_i9Rm.Z^#c7XQ-i9ZWj^n6o2Q?rfH8fC
&(6e@'*9!ts1;+G,6XMPY-8M$'49Qj]O8/ofYP;SSqX(2j`o>pZ-C4rBuOd@6&['G(P11L.-cGnZtH
Wk/Sl_R=h/]q+CgV[N&:3N7D4*RX4q9"ic4Z=G=>4?V/rC>n;-ABp`c&A&a(9^m]@Q@A#rq5\1:Ybu
*d@"M71Tb)i!*Wh31)^-*XoWq@#f+%g^mPKO8,c,C!+(iiGd0'_f1V3p8cUmJol:eipU,%i?hqDomK
'QA1mBqL:l9"-NZa`>-Ib(BUq2@5:m;;tM?:1`YFonAJY`q*8rs+2XocZF!@.c$:)O,_TL2M;W%Tp@
;a;dXQ@T,%e>NT9&Q*3EJYM;+rr7T4msF;YasfW!(dOrC9D.S_HqIeg6Di4n`Dhk(,`'pL(5i<H@W;
s]Zd``Y=S;al>]?I;qD=d?8Ord9rWFIFh=tSEmh>a%!CB@G5u]6I<Kb$j!`9M_k:Xr=,Z_q5b"&sG;
G[rt.URa>d`8".,_X;o-JD:!g2%lE_<cpGj#;o@9X6$%B?lo,H[!AD2QKe,8Wn`<%Yk.rhsWuZ:"/K
Q$fbM`o$(bKT@Ra7=P=lK4oF_f1K0euP/;"a^"sdZJ#I%F-o)We?sqQ'\$PVTC)%<e31V8'Lb)IHNr
b62^fD87ZU1:cDuo:0G)DdQFDfB7J#Q&!qPhp1hLa)F\\0&%%)_$:e\s_P,!>Do\E(hRl.9LUM%gqh
^0(,R\>b<5.cE[-0pERbH(NXRFg%LmmHa#3BiSZ%EhDU^C;oKo&M2*<V&_m)Q6bM\GLf9&lE%1-lSU
8[3D)sY(5kVVdI>j;+`Fck^r`C&+e]:,(I_beB!^aZfR#4p5D:&d;gs]Jcnh/CqI55pz8OZBBY!QNJ
ASCII85End
End

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

	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	
	return DimSize(CoefListWave, 0)
end

static Function totalRealCoefsFromCoefList(LinkRowsOK)
	Variable LinkRowsOK

	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave

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

	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave

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
	
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave

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
	
	Wave/T CoefListWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListWave
	Wave CoefSelWave = root:Packages:MotofitGF:NewGlobalFit:NewGF_CoefControlListSelWave
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

Function MOTO_NewGF_HelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DisplayHelpTopic "Global Curve Fitting"
			break
	endswitch

	return 0
End

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
		if (err == MOTO_NewGlobalFitNO_DATASETS)
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
	
	if (options & MOTO_NewGFOptionLOG_DEST_WAVE)
		WaveStats/Q/M=1 xW
		if ( (V_min <= 0) || (V_max <= 0) )
			// bad x range for log- cancel the option
			options = options & ~MOTO_NewGFOptionLOG_DEST_WAVE
		else
			// the progress graph should have log X axis
			ModifyGraph/W=GlobalFitGraph log(bottom)=1
		endif
	endif
		
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
#pragma rtGlobals=3		// Use modern global access method.
#pragma IgorVersion = 6.2

//This procedure contains the reduction procedure copied mainly from the existing SLIM code. The additional polarization correction of the recorded spectra is contained in the procedure "Polcorr-thomas" 
//FUNCTIONS IN THIS FILE:
//Function testPolReductionProcedure(cases)
//Function PolarizedReduction(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, runfilenames, lowLambda, highLambda, rebin, [water, background, expected_peak, manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose])
//Function/t reducepol(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, runfilenames, lowLambda, highLambda, rebin,  [water, background, expected_peak, manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose])
//Function writeSpecRefXML1DPolCorr(outputPathStr, fname, qq, RR, dR, RRpolCorr, DRpolCorr, dQ, exptitle, user, samplename, runnumbers, rednnote)
//Function spliceFilesPolCorr(outputPathStr, fname, filesToSplice, [factors, rebin])
//Function/t Pla_GetWeightScOPolCorr(wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr)
//Function Pla_rebin_afterwardsPolCorr(qq,rr, dr,rrpolcorr, drpolcorr, dq, rebin, lowerQ,upperQ)
//Function SLIM_plot_reducedPolCorr(inputPathStr, filenames)
//Function SLIM_plotPolCorr(inputpathStr, outputPathStr, fileNames,lowlambda,highLambda, background, [expected_peak, rebinning, manual, normalise, saveSpectrum])
//Function button_SLIM_PLOTPolCorr(ba) : ButtonControl

//GENERAL COMMENTS
// NSF means non-spin-flip
// SF means spin-flip
// I00, I01, I10, I11 are the measured reflected intensities, i.e. reflected spectra or reflectivities
// DB00, DB01, DB10, DB11 are the direct beams
// The order of FUNCTION INPUT has to be 00,01,10,11 - as above, otherwise, the channels can be mixed up, which will lead to wrong results.
// See the below test function for a typical FUNCTION INPUT structure

//Handling COMMENTS 
// The code relies on accurate input parameters (00,01,10,11) in order to figure out which mode the reflected spectra and direct beam spectra are measured in. 
// The input of the filenumbers has to be in full, i.e. PLP6640 without the leading 0's is not allowed.
// The runfilenames input to function PolarizedReduction contains multiples of 8 entries, each for a different angle measured.
// You cannot process more than 1 measurement at the time, i.e. you cannot give the same anlges.  
// The runfilneames input to function reducepol has to contain 8 entries, specifying the four reflected polarization channels and the four direct beam channels of each polarization. 
// In case a particular channel has not been recorded, the filenumber is to be replaced with "00" (if the measurement involved both, polarizer and analyzer) or "0" (measurement without the analyzer)
//	A) REFLECTIVITY MODES: 
//	1) All four reflectivity channels have been recorded. 
// 	2) ONLY NSF channels have been recorded with Polarizer and Analyzer being used. ("00" for missing entries)
//	3) ONLY ONE of the SF channels has been recorded, you can decide which one in the testPolRed below. ("00" for missing entries)
//	4) No Analyzer in the beam, ONLY I0 and I1 are recorded ("0" for missing entries)
//	5) No Reflectivity is calculated, only reduced and polarization corrected spectra are given out ("00" for missing entries, or you can leave the DB blank)

//     B) DIRECT BEAMS: 
//     1) The spin flipper, either ON or OFF, do NOT change the shape of the spectrum, therefore it is up to the user to provide only DB00 or DB11 or both.	
//	 2) If all four DB channels are provided, a full polarization correction of DB is performed -- I00 and I01 will be divided by DB00 -- I11 and I10 will be divided by DB11 ("00" for missing entries)
//	 3) If three DB channels (i.e. the two NSF and one SF) are provided, the reduced form of polarization correction is performed -- I00 and I01 will be divided by DB00 -- I11 and I10 will be divided by DB11 ("00" for missing entries)
// 	 4) If only one DB has been recorded, the polarization correction will only be a scaling with the efficiency function ("00" for missing entries)
//	 5) If you do not want to make a polarization correction on the direct beams (for whatever reason), give the same entry for DB00 and DB11 (here only one DB file is possible) ("00" for missing entries)

 
Function testPolRed(cases)
	//This function performs an example redution of polarized data on the example of the polarized reflectivity from Cr(20Å)/Ni80Fe20(300Å)/Si. NOTE: The measurement has been recorded using all four elements. The old flipper settings etc.!!!  
	//The options are: cases = "Full" ; "NSF" ; "R01" ; "R10" ; "R0R1" ; "Spectra"
	//The files you need are:"PLP0006737;PLP0006743;PLP0006740;PLP0006734;PLP0006640;PLP0006726;PLP0006717;PLP0006675:PLP0006738;PLP0006744;PLP0006741;PLP0006735;PLP0006641;PLP0006727;PLP0006718;PLP0006676:PLP0006739;PLP0006745;PLP0006742;PLP0006736;PLP0006642;PLP0006728;PLP0006719;PLP0006677"
	//AND the waterrun:  PLP0006319
	string cases
	//Additional variables needed for function execution
	//testfiles contains the string of filenames that are to be reduced.
	string testfiles = "", inputPathStr = "", outputPathStr = "", waterrun = ""
	variable scalefactor
	
	inputPathStr = "D:INSTRUMENTS:PLATYPUS:ALL:" //where can I find the data 
	outputPathStr =  "J:ANSTO:PLATYPUS:DATA-Reduction-implementation:Reduced-data:" //where do you want me to write the data
	waterrun = "PLP0006319" //what is the datafile of the waterrun (this should be in the input folder found under inputPathStr)
	scalefactor = 1 //I would recommend setting the scalefactor to 0.79278 in order to have a critical edge corresponding to 1 
				   // The scalefactor for the individual measured reflected spectra do not have to be the same.
	
	if(stringmatch(cases, "Full"))
		//Case 1: Full polarization correction of 4 reflected spectra and 4 direct beam spectra --- "Full"
		testfiles = "PLP0006737;PLP0006743;PLP0006740;PLP0006734;PLP0006640;PLP0006726;PLP0006717;PLP0006675:PLP0006738;PLP0006744;PLP0006741;PLP0006735;PLP0006641;PLP0006727;PLP0006718;PLP0006676:PLP0006739;PLP0006745;PLP0006742;PLP0006736;PLP0006642;PLP0006728;PLP0006719;PLP0006677"
	elseif(stringmatch(cases, "NSF"))
		//Case 2: Only the NSF (non-spin-flip) channels have been recorded. --- "NSF" 
		testfiles = "PLP0006737;00;00;PLP0006734;PLP0006640;00;00;PLP0006675:PLP0006738;00;00;PLP0006735;PLP0006641;00;00;PLP0006676:PLP0006739;00;00;PLP0006736;PLP0006642;00;00;PLP0006677"
	elseif(stringmatch(cases, "R01"))
		//Case 3: The two NSF and the SF I01 have been recorded -- "R01"
		testfiles = "PLP0006737;PLP0006743;00;PLP0006734;PLP0006640;PLP0006726;00;PLP0006675:PLP0006738;PLP0006744;00;PLP0006735;PLP0006641;PLP0006727;00;PLP0006676:PLP0006739;PLP0006745;00;PLP0006736;PLP0006642;PLP0006728;00;PLP0006677"
	elseif(stringmatch(cases, "R10"))	
		//Case 4: The two NSF and the SF I10 have been recorded -- "R10"
		testfiles = "PLP0006737;00;PLP0006740;PLP0006734;PLP0006640;00;PLP0006717;PLP0006675:PLP0006738;00;PLP0006741;PLP0006735;PLP0006641;00;PLP0006718;PLP0006676:PLP0006739;00;PLP0006742;PLP0006736;PLP0006642;00;PLP0006719;PLP0006677"
	elseif(stringmatch(cases, "R0R1"))
		//Case 5: Only NSF channels have been recorded WITHOUT the analyzer in the beam
		testfiles = "PLP0006737;0;0;PLP0006734;PLP0006640;0;0;PLP0006675:PLP0006738;0;0;PLP0006735;PLP0006641;0;0;PLP0006676:PLP0006739;0;0;PLP0006736;PLP0006642;0;0;PLP0006677"
	elseif(stringmatch(cases, "Spectra"))
		//Case 6: No Reflectivity is calculated, only reduced and polarization corrected spectra are given out
		testfiles = "PLP0006737;PLP0006743;PLP0006740;PLP0006734;00;00;00;00:PLP0006738;PLP0006744;PLP0006741;PLP0006735;00;00;00;00:PLP0006739;PLP0006745;PLP0006742;PLP0006736;00;00;00;00"
	endif

	PolarizedReduction( inputPathStr, outputPathStr, scalefactor,scalefactor,scalefactor,scalefactor,testfiles, 2.5, 12.5, 3, water=waterrun, background=1, expected_peak=cmplx(143,nan), manual=1, dontoverwrite=0, normalise=1, saveSpectrum=1, saveoffspec=1, verbose=1)


end



Function PolarizedReduction(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, runfilenames, lowLambda, highLambda, rebin, [water, background, expected_peak, manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose])
	// This Function should be called from the Graphical user interface
	// it takes the functionality of the original function "reduce" in unpolarized reduction
	// FIRST "reducepol" is called for each set of angles
	// The output of reducepol is a list of the polarization corrected and reduced filenames, these are also written to the outputpathstring
	// SECOND: spliceFilesPolCorr is called to stitch all the angles given in runfilenames together.
	string inputPathStr, outputPathStr //specify where the input files can be found or the output shall be written e.g. "C:platypus:My Documents:Desktop:data", "C:platypus:My Documents:Desktop:data:output"
	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11 //data is divided by this variable
	//Each input reflected spectra has to be given its own scaling. The reason being that in if the scaling of the R00 and R11, i.e. the two NSF channels, from the measurement is different (for example at the critical edge), this would give a wrong polarization correction. 
	// For ease of data manipulation, the two SF channels can also be individually scaled. In general, the R01 channel should have the scaling of R00. R10 should have the scaling of R11.  
	string runfilenames //runfilenames contains blocks of 8, the first four entries are full filenames of the reflected spectra, the next four are the full filenames of the direct beams
	//different polarization channels are separated by ";" different angles of incidence are separated by ":" 
	// firstI00;firstI01;firstI10;firstI11;firstDB00;firstDB01;firstDB10;firstDB11:secondI00;secondI01;secondI10;secondI11;secondDB00;secondDB01;secondDB10;secondDB11
	variable lowLambda,highLambda, rebin //variables specifying the low wavelength cutoff, the high wavelength cutoff and the rebin persentage, e.g. 3 for 3% dq/q rebinning
	//OPTIONAL:	
	string water // string containing the water runfile for detector normalisation
	variable background //variable specifying whether you want to subtract background (1=true, 0 = false), 1 is default.
	variable/c expected_peak // complex variable specifying where you expect to see the specular ridge, in detector pixels, e.g. expected_peak=cmplx(143,nan)
	variable manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose
	//	manual - variable specifying  whether you would like to manually choose beam centres/FWHM, otherwise it is done automatically
	//	dontoverwrite = variable specifying if you want to create unique names everytime you reduce the file. (default == 1)
	//	normalise - variable specifying whether you want to normalise by beam monitor counts (default == 1)
	//	saveSpectrum - variable specifying whether you want to normalise by beam monitor counts (default == 0)
	//	saveoffspec - variable specifying whether you want to save the offspecular reflectivity map (default == 0), this is only non-polarization corrected data
	//	verbose - variable specifying if you want verbose output (default == 1)
	
	string cDF, toSplice=""
	string  fname, cmd = "", thePair, ifname, newfnameI00, newfnameI01, newfnameI10, newfnameI11, Tfname, PolChannelsfname="" 
	variable ii, spliceFactor, numpairs
	cDF = getdatafolder(1)	
	try
		numpairs = itemsinlist(runfilenames, ":")
		print "(PolarizedReduction) This is the number of Angles that will be processed: numpairs = ", numpairs //This is the number of Angles that will be processed
		for(ii = 0 ; ii < numpairs ; ii += 1)
			thePair = stringfromlist(ii, runfilenames, ":") 
			print "(PolarizedReduction) this is the input to reducepol, being executed hereafter: thepair = ", thePair
			ifname = reducepol(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, thePair, lowLambda, highLambda, rebin, water = water, background=background, expected_peak=expected_peak, manual=manual, dontoverwrite=dontoverwrite, normalise=normalise, saveSpectrum=saveSpectrum, saveoffspec=saveoffspec, verbose=verbose)
			if(strlen(ifname) == 0)
				print "ERROR whilst calling reducepol (PolarizedReduction)"
				abort
			else
			//The output of reducepol is gathered in tosplice with a structure similar to runfilenames, i.e. datasets are separated by ";" and angles separated by ":"
				toSplice += ifname + ":"
			
			endif
		endfor
		toSplice = RemoveEnding(toSplice, ":")
		print "(Polarized Reduction) This is what comes out of reducepol (toSplice = )", toSplice
		
		if(dontoverwrite)
			
			Tfname = stringfromlist(0, toSplice, ":") //Takes the first angle of the files that comes out of reducepol for loop
			newfnameI00 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(0, Tfname, ";"), ".xml")
			newfnameI01 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(1, Tfname, ";"), ".xml")
			newfnameI10 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(2, Tfname, ";"), ".xml")
			newfnameI11 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(3, Tfname, ";"), ".xml")
			
		else
			Tfname = stringfromlist(0, toSplice, ":")
			newfnameI00 =  "c_" +stringfromlist(0, Tfname, ";")
			newfnameI01 =  "c_" +stringfromlist(1, Tfname, ";")
			newfnameI10 =  "c_" +stringfromlist(2, Tfname, ";")
			newfnameI11 =  "c_" +stringfromlist(3, Tfname, ";")
			
		endif
		//PolChannelsfname contains the new names of the datasets which is passed to spliceFilesPolCorr
		PolChannelsfname = 	newfnameI00 + ";" + newfnameI01 + ";" + newfnameI10 + ";" + newfnameI11
		
		if(itemsinlist(toSplice, ":") > 1)
			sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, PolChannelsfname, toSplice, rebin
			print cmd
		
			if(spliceFilesPolCorr(outputPathStr, PolChannelsfname, toSplice, rebin = rebin))
				print "ERROR while splicing (reduce)";abort
			endif
		endif		
	catch
		
		Print "ERROR: an abort was encountered in (reduce)"
		setdatafolder $cDF
		return 1
	endtry

	setdatafolder $cDF
	return 0

End

Function/t reducepol(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, runfilenames, lowLambda, highLambda, rebin,  [water, background, expected_peak, manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose])
	//This function is similar to the reduceASingleFile function. 
	//However, instead of a single dataset, four polarization channels are needed including the corresponding direct beams.
	//First, ProcessNexusFile is called for each file in the list runfilenames
	//Second, PolCorr is called (the mode depends on the input, see example)
	//Third, direct beam divisions are performed within the flow of the function 
	//Forth, the reduced files are written to the disc as ACII.dat (polarization corrected), 1D.xml (Polarization corrected), 2D.xml (NOT polarization corrected)
	//The function RETURNS a LIST of polarization corrected reduced reflected spectra filenames --outputname
	string inputPathStr, outputPathStr
	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11
	string runfilenames //runfilenames contains 8 entries separated by ";" First 4 reflected intensities (I00, I01, I10, I11) and then 4 direct beams (DB00, DB01, DB10, DB11)
	variable lowLambda,highLambda, rebin
	string water
	variable background
	variable/c expected_peak
	variable manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose
	//ADDITIONAL parameter
	string cDF, runnumberDF, runnumber, reductionCmd
	variable isDirect
	string fname, cmd="", theFile, ifname  //theFile = thePair
	variable ii, iii, jj, aa, splicefactor, numpairs, numspectra, D_S2, D_S3, D_SAMPLE, domega, fileID, scalefactors
	string processedruns, I00, I01, I10, I11, D00, D01, D10, D11,  DBSpectra, thedirectDF, theangleDF, RefSpectra, theAngle = "", theDB = "", ofname, outputname=""
	processedruns = ""
	
	cDF = getdatafolder(1) //returns the string containing the full path to the datafolder
	//This try - catch -endtry environment contains the 	
	try
			//setup the datafolders
			Newdatafolder/o root:packages
			Newdatafolder /o root:packages:platypus
			Newdatafolder /o root:packages:platypus:data
			//directory for the reduction package
			Newdatafolder /o root:packages:platypus:data:Reducer
			setdatafolder "root:packages:platypus:data:Reducer"
			//set up the default parameters
			if(paramisdefault(water))
				water = ""
			endif
			if(paramisdefault(background))
				background = 1
			endif
			if(paramisdefault(expected_peak))
				expected_peak = cmplx(ROUGH_BEAM_POSITION, NaN)
			endif
			if(paramisdefault(manual))
				manual = 0
			endif
			if(paramisdefault(dontoverwrite))
				dontoverwrite = 1
			endif
			if(paramisdefault(normalise))
				normalise = 1
			endif
			if(paramisdefault(saveSpectrum))
				saveSpectrum = 0
			endif
			if(paramisdefault(saveoffspec))
				saveoffspec = 0
			endif
			if(paramisdefault(verbose))
				verbose = 1
			endif
			if(numtype(scalefactorI00) || scalefactorI00==0 || numtype(scalefactorI01) || scalefactorI01==0 || numtype(scalefactorI10) || scalefactorI10==0 || numtype(scalefactorI11) || scalefactorI11==0)
				print "ERROR a non sensible scale factor was entered (reducePol) - setting ALL scalefactor to 1";	
				scalefactorI00 = 1; scalefactorI01 = 1; scalefactorI10 = 1; scalefactorI11 = 1;  
			endif
			//create the reduction string for this particular operation.  This is going to be saved in the datafile.
			cmd = "reducepol(\"%s\",\"%s\",%g,%g,%g,%g,\"%s\",%g,%g,%g,water =\"%s\",background = %g, expected_peak=cmplx(%g,%g), manual = %g, dontoverwrite = %g, normalise = %g, saveSpectrum = %g, saveoffspec=%g)"
			sprintf reductionCmd, cmd, inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, runfilenames, lowLambda, highLambda, rebin, water, background, real(expected_peak), imag(expected_peak), manual, dontoverwrite, normalise, saveSpectrum,saveoffspec
			if(verbose)
				print reductionCmd
			endif
			
				
		
				//set the data to load
				GetFileFolderInfo/q/z inputPathStr
				if(V_flag)//path doesn't exist
					print "ERROR please give valid input path (reducePol)";abort
				endif		
				GetFileFolderInfo/q/z outputPathStr
				if(V_flag)//path doesn't exist
					print "ERROR please give valid output path (reducePol)";abort
				endif
				//check that low lambda, high lambda + rebin are reasonable
				if(lowlambda < 0 || lowlambda>highlambda || lowlambda >20 || numtype(lowlambda))
					print "ERROR set a reasonable value for low lambda cutoff";	abort
				endif
				if(highlambda < 0 || highlambda >30|| numtype(highlambda))
					print "ERROR set a reasonable value for high lambda cutoff";	abort
				endif
				if(rebin <0 || rebin >15 || numtype(rebin))
					print "ERROR rebin should be 0<rebin<15 (reduce)"; 
					print "defaulting to 1%"
					rebin = 1
				endif
				//try to load the waterrun file 'water', if it exists
				if(!paramisdefault(water) && strlen(water)>0)
					if(loadNexusFile(inputPathStr, water, outputPathStr = outputpathStr))
						print "Error loading water run (reducePol)"
						abort
					endif
				endif
				//make the rebin wave, to rebin both direct and reflected data
				if(rebin)
					Wave W_rebinboundaries = Pla_gen_binboundaries(lowlambda, highlambda, rebin)
				endif
			//Figure out how many items are given in the list of datafiles to be reduced
			//This has to be either 8 (which includes direct beams) or 4, in which case no reflectivity is produced, but the spectra given are only polarization corrected (i.e. no direct beam division)
			//If specific channels have not been recorded and are missing, the runfilenames for these have to be set to "00" or "0"
			//Here "00" is reserved for a general measurement with both polarizer and analyzer
			// "0" is reserved for a measurement using only the polarizer
			numpairs = itemsinlist(runfilenames, ";")	
			print "(reducepol) number of items in list runfilenames:", numpairs
			if(numpairs != 4 && numpairs != 8)
				printf "ERROR: Encountered unexpected number of files, you have to give either 8 or 4 filenames in the form PLP0006737; 00; 00; PLP0006734;PLP6640;00;00;00\r"
			endif
			isDirect = 0	
		for(ii = 0 ; ii < numpairs ; ii += 1)
			//extract the filename from the runfilenames list
			theFile = stringfromlist(ii, runfilenames, ";")
			//Execute ProcessNexusfile for each item in the list
			//check if the filename is either "00" or "0", these are then not reduced, but the order of the files is kept
			if(stringmatch(theFile, "00")||stringmatch(theFile, "0"))
				//After the loop, processedruns contains the updated list of filenames
				iii = ii+1 
				processedruns += theFile+";"
				printf "item %g not processed in ProcessNexusFile since no runnumber given (ReducePol)\r", iii
			else
				runnumber = theFile	
				if(strlen(runnumber)==0 ) //|| strlen(direct)==0   it currently doesnt matter if the beam is direct or not
					print "ERROR parsing the runfilenamestring (reducePol)"; abort
				endif
				if(ii>3)
					print "(reducepol) NOW PROCESSING A DIRECT BEAM in ProcessNexusFile with runfilename: " + theFile
					isDirect = 0 //THIS SHOULD BE isDirect = 1, but the SF channels screw up!!!
				else
					print "(reducepol)  the reflected runfilename currently processed in ProcessNexusFile is: "+runnumber
				endif
				if(rebin)
					if(processNeXUSfile(inputPathStr, outputPathStr, runnumber, background, lowLambda, highLambda, water = water, isDirect = isDirect, expected_peak = expected_peak, rebinning = W_rebinboundaries, manual = manual, normalise=normalise, saveSpectrum = saveSpectrum))
						print "ERROR while processing a direct beam run (ReducePol[processNexusfile])" ; abort
					else
					 	fname = cutfilename(runnumber)
						print "(ProcessNexusfile) finished successfully for file"+ fname
						ifname = fname
					endif
				else
					if(processNeXUSfile(inputPathStr, outputPathStr, runnumber, background, lowLambda, highLambda, water = water, isDirect = isDirect, expected_peak = expected_peak, manual = manual, normalise = normalise, saveSpectrum = saveSpectrum))
						print "ERROR could not find a W_rebinboundaries (ReducePol[processNexusfile])" 
						print "ERROR while processing a direct beam run (ReducePol[processNexusfile])" ; abort
					else 
						fname = cutfilename(runnumber)
						print "(processNexusfile) finished successfully for file"+ fname + "(ReducePol)"
						ifname = fname
					endif				
				endif

				//from here the processNexusFile has been called and a single processed spectrum M_Spec exists.
				if(strlen(ifname) == 0)
					print "ERROR whilst calling ProcessNexusFile ", thefile, " (reducepol)"
					abort
				else
					processedruns += ifname+";"
				endif			
			endif	
		endfor
		runfilenames = RemoveEnding(processedruns, ";")
		print "(ReducePol) List of files after ProcessNexusFile: " + runfilenames
	catch
		Print "ERROR: an abort was encountered in (reducePol after ProcessNexusfile)"
		setdatafolder $cDF
		return ""
	
	endtry
	//From here I start a new try - catch - endtry environment to separate the different sections of the workflow
	//Here the polarization correction of the above reduced files takes place 
	try
	//REFLECTED SPECTRA
		//First the reflected channels (Note: it does not matter if these are reflectivities or direct beams if no entries on the direct beam positions in "runfilenames" has been given)
		//The files need to be in order 
		I00 = stringfromlist(0, runfilenames, ";") //I00 means OFF OFF = R--
		I01 = stringfromlist(1, runfilenames, ";") //I01 means OFF ON = R-+
		I10 = stringfromlist(2, runfilenames, ";") //I10 means ON OFF = R+-
		I11 = stringfromlist(3, runfilenames, ";") //I11 means ON ON = R++
	print "RUNNING POLARIZATION CORRECTION ON REFLECTED SPECTRA" + I00 + ";" + I01 + ";" + I10 + ";" + I11
	//Figure out how many input files there are and which ones are to be processed with which polarization correction 
	if(stringmatch(I00, "00") || stringmatch(I11, "00"))
		//This would mean a mistake has been made, you need at least the I00 and I11 files for a polarization correction to make sense		
		printf "No I00 or I11 found, cannot run PolCorr (ReducePol)\r"
	elseif(stringmatch(I01, "00") && stringmatch(I10, "00")) //Note the "00" condition in comparison to the next one
		printf "Only I00 and I11 given (polcorr_NSF), a correction without the information of the SF channels is made\r ASSUMING I01 = I10 = 0, ANA = F2 = 1 (ReducePol)\r"
		if(!polcorr_NSF(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11))
			print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " NSF PolCorr successfull (ReducePol)" 
		endif
	elseif(stringmatch(I01, "0") && stringmatch(I10, "0")) //Note the "0" condition
		printf "Only I0 and I1 given (polcorr_R0R1), ONLY polarizer used in measurement???!!!\r ASSUMING I01=I10=0, ANA = 1, F2=0, (ReducePol)\r"
		if(!polcorr_R0R1(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11))
			print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " Polarizer ONLY polcorr successfull (ReducePol)" 
		endif	
	elseif(stringmatch(I01, "00") || stringmatch(I10, "00"))
		printf "Only I00 and I11 and ONE SF channel given (polcorr_R01),\r ASSUMING I01 = I10 and vice versa, Efficiencies are taken in full (ReducePol)\r"
		if(!polcorr_R01(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11))
			print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " R01 polcorr successfull (ReducePol)" 
		endif	
	else
		printf "FULL CORRECTION OF FOUR REFLECTIVITY CHANNELS (polcorr_FULL)\r All channels and efficiencies are taken into account\r"
		if(!polcorr_FULL(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11))
			print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " FULL polcorr successfull (ReducePol)" 
		endif	
	endif
	//Polcorr makes a folder "PolCorrected", in which I store the efficiency matrices and the reflectivities. In order for those not to be overwritten by the direct beams below, I rename them
	//Note that the outcome of the polarization correction is stored in the IGOR subfolder containing the runfilename. Items in PolCorrected are not to be further processd and are overwritten with each new angle or different dataset.
	Wave/z   RI00, RI01, RI10, RI11, poleff, anaeff, flipper1, flipper2, finals, vecintensities
	if(WaveExists(vecintensities))			
		  duplicate/O vecintensities, vecintensitiesStored
		  killwaves vecintensities
	endif
	if(WaveExists(RI00))			
		  duplicate/O RI00, Ref00
		  killwaves RI00
	endif	  
	if(WaveExists(RI01)) 
	  	duplicate/O RI01, Ref01
	  	killwaves RI01
	endif
	if(WaveExists(RI10)) 
		duplicate/O RI10, Ref10
		killwaves RI10
	endif
	if(WaveExists(RI11)) 
		  duplicate/O RI11, Ref11
		  killwaves RI11
	endif
	if(WaveExists(poleff)) 
		  duplicate/O poleff, Refpoleff
		  killwaves poleff
	endif
	if(WaveExists(anaeff)) 
		  duplicate/O anaeff, Refanaeff
		  killwaves anaeff
	endif
	if(WaveExists(flipper1)) 
		  duplicate/O flipper1, Refflipper1
		  killwaves flipper1
	endif
	if(WaveExists(flipper2)) 
		  duplicate/O flipper2, Refflipper2
		  killwaves flipper2
	endif
	if(WaveExists(finals)) 
	  	  duplicate/O finals, Reffinals
	  	  killwaves finals
	endif
	//DIRECT BEAMS
	//make the case that someone gave the direct beams on the positions 5-8 in the fileslist.
	//Here I need to consider which DB file might belong to which Reflectivity.
	//In general, the DB polarization correction has the same form as the reflectivity polarization correction above, with the exception that only one file can be processed as well.
	if(numpairs<=4)
		printf "No direct beams given, \r the correction ends here, giving only the corrected spectra (ReducePol)"
		setdatafolder $cDF
	
		Print "(ReducePol) finished successfully without direct beams and direct beam division"
		return ""
		
	elseif(numpairs>4)
		//What if the direct beams for one spin channel are different to the others? One might vary the resolution for an SF measurement... The wavelength resolution should not be varied, as that might affect the plarization correction
		print "The numbers after the first four entries are considered as the direct beams (ReducePol)"
		D00 = stringfromlist(4, runfilenames, ";")
		D01 = stringfromlist(5, runfilenames, ";")
		D10 = stringfromlist(6, runfilenames, ";")
		D11 = stringfromlist(7, runfilenames, ";")
		
		
		if(stringmatch(D00, D11)&& !stringmatch(D00, "00")&& !stringmatch(D00, "0"))	
		//CASE: For some reason someone does not want to make a polarization correction of the direct beams. To invoke this case, give the same filenames for DB00 and DB11.
			print "the files for the DB00 and DB11 are equal (" + D00 +" and "+ D11+ "). A polarization correction of direct beams will not take place (ReducePol)"
			//need to create M_SpecPolCorr and set it equal to M_Spec
			if(!stringmatch(D00, "00")|| !stringmatch(D00, "0"))
				Wave DI00spec = $("root:packages:platypus:data:Reducer:"+D00+":M_Spec") 
				//Wave DI11spec = $("root:packages:platypus:data:Reducer:"+D11+":M_Spec")
				string DB00path = "root:packages:platypus:data:Reducer:"+D00+":M_specPolCorr"
				//string DB11path = "root:packages:platypus:data:Reducer:"+D11+":M_specPolCorr"
				make/o/d/n=(DimSize(DI00spec,0), DimSize(DI00spec,1)) $DB00path
				WAVE DBI00 =  $DB00path
				DBI00 = DI00spec
			endif				
		else
			if(stringmatch(D01, D00)||stringmatch(D10, D00)||stringmatch(D01, D11)||stringmatch(D10, D11))	
			//Case: If one of the SF DirectBeam filenames is equal to a NSF channel, the correction will disregard this and treat it as "not measured" 
				print "the DB given for one of the SF channels is equal to one NSF channel, will set them to 00 (ReducePol)"	
				if(stringmatch(D01,D00)||stringmatch(D01,D11))
					D01 = "00"
				endif
				if(stringmatch(D10,D00)||stringmatch(D10,D11))
					D10 = "00"
				endif
			endif
			if(stringmatch(D00, "00") && stringmatch(D11, "00"))
			// CASE: Both DB00 and DB11 received "00" as input. This means that no direct beam is given and therefore no reflectivity will be produced. 
			// The output is the polarization correted reflected spectrum of the first four entries only.
					printf "No DB00 and DB11 found, cannot process DB (ReducePol)\r"
					setdatafolder $cDF
					Print "(ReducePol) finished successfully without direct beams and direct beam division"
					return ""
			elseif(stringmatch(D00, "0") && stringmatch(D11, "0"))
			// CASE: Both DB00 and DB11 received "0" as input. This means that no direct beam is given and therefore no reflectivity will be produced. 
			// The output is the polarization correted reflected spectrum. 
				printf "No DB00 and DB11 found, cannot process DB (ReducePol)\r"
				setdatafolder $cDF
				Print "(ReducePol) finished successfully without direct beams and direct beam division"
				return ""
			elseif(!stringmatch(D00, "00") && stringmatch(D01, "00") && stringmatch(D10, "00")&& stringmatch(D11, "00"))
				printf "ONLY DB00 direct beam given, the correction is just a scaling (ReducePol)\r"
				if(!polcorr_DB(D00, D01, D10, D11, 1, 1, 1, 1))
					print D00 + " DB polcorr successfull (ReducePol)" 
				endif
			elseif(!stringmatch(D11, "00") && stringmatch(D01, "00") && stringmatch(D10, "00")&&stringmatch(D00, "00") )
				printf  "ONLY DB11 direct beam given, the correction is just a scaling (ReducePol)\r"
				if(!polcorr_DB(D00, D01, D10, D11, 1, 1, 1, 1))
					print D11 + " DB polcorr successfull (ReducePol)" 
				endif
			elseif(stringmatch(D01, "00") && stringmatch(D10, "00")&&!stringmatch(D11, "00")&&!stringmatch(D00, "00"))
				printf "Only DB00 and DB11 given, no full correction (ReducePol)\r"
				if(!polcorr_NSF(D00, D01, D10, D11, 1, 1, 1, 1))
					print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " NSF polcorr successfull (ReducePol)" 
				endif
			elseif(stringmatch(D01, "0") && stringmatch(D10, "0")&&!stringmatch(D11, "00")&&!stringmatch(D00, "00"))
				printf "Only DB0 and DB1 given, no full correction (ReducePol)\r"
				if(!polcorr_R0R1(D00, D01, D10, D11, 1, 1, 1, 1))
						print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " Polarizer ONLY polcorr successfull (ReducePol)" 
				endif	
			elseif(stringmatch(D01, "00") || stringmatch(D10, "00")&&!stringmatch(D11, "00")&&!stringmatch(D00, "00"))
				printf "Only DB00 and DB11 and one SF channel given, no full correction\r"
				if(!polcorr_R01(D00, D01, D10, D11, 1, 1, 1, 1))
						print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " NSF polcorr successfull (ReducePol)" 
				endif	
			else
				printf "FULL CORRECTION OF FOUR DirectBeam CHANNELS (ReducePol)\r"
				if(!polcorr_FULL(D00, D01, D10, D11, 1, 1, 1, 1))
						print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " FULL polcorr successfull (ReducePol)" 
				endif	
		
			endif
			//Same as above, rename the items in PolCorrected in order to not interfere with the reflectivity files from the polarization correction
			Wave/z   RI00, RI01, RI10, RI11, poleff, anaeff, flipper1, flipper2, finals
			if(WaveExists(RI00))			
				  duplicate/O RI00, DB00
				  killwaves RI00
			else
				print "ERROR: I lost the wavename of the direct beams which just came out of PolCorr (ReducePol)"; abort
			endif	  
			if(WaveExists(RI01)) 
	  			duplicate/O RI01, DB01
	  			killwaves RI01
			endif
			if(WaveExists(RI10)) 
				duplicate/O RI10, DB10
				killwaves RI10
			endif
			if(WaveExists(RI11)) 
				duplicate/O RI11, DB11
		 	 	killwaves RI11
			endif
			if(WaveExists(poleff)) 
				  duplicate/O poleff, DBpoleff
				  killwaves poleff
			endif
			if(WaveExists(anaeff)) 
				  duplicate/O anaeff, DBanaeff
				  killwaves anaeff
			endif
			if(WaveExists(flipper1)) 
				  duplicate/O flipper1, DBflipper1
				  killwaves flipper1
			endif
			if(WaveExists(flipper2)) 
				  duplicate/O flipper2, DBflipper2
				  killwaves flipper2
			endif
			if(WaveExists(finals)) 
		  	 	 duplicate/O finals, DBfinals
		  	 	 killwaves finals
			endif
		endif
	endif
	processedruns = I00 + ";" + I01 + ";" + I10 + ";" + I11 + ";" + D00 + ";" + D01 + ";" + D10 + ";" + D11 
	runfilenames = RemoveEnding(processedruns, ";")
	Print "List of polarization corrected spectra (ReducePol[PolCorr]): " + runfilenames
	catch
		Print "ERROR: an abort was encountered in (reducepol[Polcorr])"
		setdatafolder $cDF
		return ""
	endtry
	
	Print "(POLCORR) finished successfully (ReducePol)"
	Print "Now executing direct beam divisions (ReducePol)"
	//NOW DIRECT BEAM DIVISIONS
	//figure out which datasets belong together and process them together
	try
		if(numpairs>4)
			print "The positions 5, 6, 7, 8 in the list runfilenames are considered as direct beams for division (ReducePol)"
			numpairs = 4
		endif					
		//Change the datalist in order to have the correct DB at the correct position
		//might be that D00 or D11 are 00  and D01 and D10 need to be changed anyway
		if(stringmatch(D00, "00")|| stringmatch(D00, "0"))
			D00 = D11
			print "D00 was not given, setting DB to D11 (ReducePol)"
		endif
		if(stringmatch(D11, "00")|| stringmatch(D11, "0"))
			D11 = D00
			print "D11 was not given, setting DB to D00 (ReducePol)"
		endif
		RefSpectra  = I00 + ";" + I01 + ";" + I10 + ";" + I11
		DBSpectra = D00 + ";" + D00 + ";" + D11 + ";" + D11
		//reset processdruns
		processedruns = ""
		//This forloop runs for each combination of the reflected spectra and direct beams above
		for(ii = 0 ; ii < 4 ; ii += 1)
			//extract the filename from the runfilenames list
			theAngle = stringfromlist(ii, RefSpectra, ";")
			theDB = stringfromlist(ii, DBSpectra, ";")
			//Advise which scalefactor is to be used
			if(ii == 0)
				scalefactors = scalefactorI00;
			elseif(ii == 1)
				scalefactors = scalefactorI01;
			elseif(ii == 2)
				scalefactors = scalefactorI10;
			else
				scalefactors = scalefactorI11;	
			endif
			//check if the filename is either "00" or "0", these are then not reduced, but the order of the files is kept
			if(stringmatch(stringfromlist(ii, RefSpectra, ";"), "00") || stringmatch(stringfromlist(ii, RefSpectra, ";"), "0"))
				//After the loop, 'processedruns' contains the updated list of filenames
				iii = ii+1
				processedruns += theAngle+":"+theDB+";"
				printf "Item %g not processed since no runnumber given (ReducePol)\r", iii
				outputname = outputname + stringfromlist(ii, RefSpectra, ";") + ";"
			else
				print "(ReducePol) Advice which files belong together? Reflectivities: ", RefSpectra, "Direct beams: ", DBSpectra
				//recheck that the files have been loaded and the folders exist
				thedirectDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(theDB,".nx.hdf"),0)
				theAngleDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(theAngle,".nx.hdf"),0)
				if(!datafolderexists(thedirectDF))
					Print "ERROR, direct beam not loaded: (ReducePol)"; abort
				endif
				if(!datafolderexists(theAngleDF))
					Print "ERROR, reflected intensity not loaded: (ReducePol)"; abort
				endif
				processedruns += theAngle+":"+theDB+";"
				
				Wave M_specD = $(thedirectDF+":M_spec"); AbortOnRTE
				Wave M_specDPolCorr = $(thedirectDF+":M_specPolCorr"); AbortOnRTE //polarization corrected DB, if at all
				Wave M_specDSD = $(thedirectDF+":M_specSD"); AbortOnRTE
				Wave M_specDPolCorrSD = $(thedirectDF+":M_specPolCorrSD"); AbortOnRTE			
				Wave M_topandtailD = $(thedirectDF+":M_topandtail"); AbortOnRTE			
				Wave W_lambdaD = $(thedirectDF+":M_lambda"); AbortOnRTE
				Wave M_lambdaHISTD = $(thedirectDF+":M_lambdaHIST"); AbortOnRTE
				Wave/z M_uncorrectedGravityCentre = $(thedirectDF+":M_uncorrectedgravityCentre"); AbortOnRTE
				Wave DetectorPosD = $(thedirectDF+":instrument:detector:longitudinal_translation"); AbortOnRTE
				Wave DetectorHeightD = $(thedirectDF+":instrument:detector:vertical_translation")
				Wave M_directbeampos = $(thedirectDF+":M_beampos"); AbortOnRTE
				
				//create a string to hold the reduction string.
				string/g $(theAngleDF+":reductionCmd") = reductionCmd
				
				Wave M_specA0 = $(theAngleDF+":M_spec"); AbortOnRTE
				Wave M_specA0PolCorr = $(theAngleDF+":M_specPolCorr"); AbortOnRTE
				Wave M_specA0SD = $(theAngleDF+":M_specSD"); AbortOnRTE
				Wave M_specA0PolCorrSD = $(theAngleDF+":M_specPolCorrSD"); AbortOnRTE
				Wave M_topandtailA0 = $(theAngleDF+":M_topandtail"); AbortOnRTE
				Wave M_topandtailA0SD = $(theAngleDF+":M_topandtailSD"); AbortOnRTE
				
				numspectra = dimsize(M_specA0, 1)
		
				Wave DetectorPosA0 = $(theAngleDF+":instrument:detector:longitudinal_translation"); AbortOnRTE
				Wave M_beamposA0 = $(theAngleDF+":M_beampos"); AbortOnRTE
				Wave DetectorHeightA0 = $(theAngleDF+":instrument:detector:vertical_translation")
				Wave sth = $(theAngleDF+":sample:sth"); AbortOnRTE
				
				if((DetectorPosA0[0] - DetectorPosD[0])>0.1)
					Print "ERROR, detector dy for direct and reduced data not the same: (ReducePol)"; abort
				endif
				//work out the actual angle of incidence from the peak position on the detector
				//this will depend on the mode
				Wave/t mode = $(theAngleDF+":instrument:parameters:mode")
				//create an omega wave
				Wave M_lambda = $(theAngleDF+":M_lambda"); AbortOnRTE
				Wave M_lambdaHIST = $(theAngleDF+":M_lambdaHIST"); AbortOnRTE
				Wave M_specTOFHIST = $(theAngleDF+":M_specTOFHIST"); AbortOnRTE
				Wave M_specTOF = $(theAngleDF+":M_specTOF"); AbortOnRTE
				duplicate/o M_lambda, $(theAngleDF+":omega")
				Wave omega = $(theAngleDF+":omega")
				//create a twotheta wave, and a qz, qx wave
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_twotheta")
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_omega")
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_qz")	
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_qy")					
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_qzSD")			
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_ref")
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_refPolCorr")
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_refPolCorrSD")
				duplicate/o M_topandtailA0, $(theAngleDF + ":M_refSD")
				duplicate/free M_lambdaHIST, M_qHIST
				
				Wave M_twotheta = $(theAngleDF + ":M_twotheta")
				Wave M_omega = $(theAngleDF + ":M_omega")
				Wave M_qz = $(theAngleDF + ":M_qz")
				Wave M_ref = $(theAngleDF + ":M_ref")
				Wave M_refPolCorr = $(theAngleDF + ":M_refPolCorr")
				Wave M_refPolCorrSD = $(theAngleDF + ":M_refPolCorrSD")
				Wave M_refSD = $(theAngleDF + ":M_refSD")
				Wave M_qy = $(theAngleDF + ":M_qy")
				Wave M_qzSD = $(theAngleDF + ":M_qzSD")
				
				variable loPx, hiPx
				loPx = numberbykey( "loPx", note(M_topandtailA0))
				hiPx = numberbykey("hiPx", note(M_topandtailA0))
				
				strswitch(mode[0])
					case "FOC":
					case "POL":
					case "POLANAL":
					case "MT":
						//					omega = Pi*sth[0]/180
						multithread omega[][] = atan(((M_beamposA0[p][q] + DetectorHeightA0[0]) - (M_directbeampos[p][0] + DetectorHeightD[0]))/DetectorposA0[0])/2
						multithread M_twotheta[][][] = atan((( (q * Y_PIXEL_SPACING) + DetectorHeightA0[0]) - (M_directbeampos[p][0] + DetectorHeightD[0]))/DetectorposA0[0])
						if(omega[0][0] < 0)
							omega = 0 - omega
							M_twotheta = 0 - M_twotheta
						endif
					break
					case "SB":
						//					Wave m1ro =  $(angle0DF+":instrument:collimator:rotation");ABORTonRTE
						//					omega = m1ro[0]
						multithread omega[][] = atan(((M_beamposA0[p][q] + DetectorHeightA0[0]) - (M_directbeampos[p][0] + DetectorHeightD[0]))/(2*DetectorposA0[0]))
						multithread M_twotheta[][][] = omega[p][r] + atan((((q * Y_PIXEL_SPACING) + DetectorHeightA0[0]) - (M_directbeampos[p][0] + DetectorHeightD[0]) - (DetectorposA0[0] * tan(omega[p][r])))/DetectorposA0[0])
					break
					case "DB":		//angle of incidence for DB is always 4.8
						//					omega = 4.8 * Pi/180
						multithread omega[][] = atan(((M_beamposA0[p][q] + DetectorHeightA0[0]) - (M_directbeampos[p][0] + DetectorHeightD[0]))/(2*DetectorposA0[0]))
						multithread M_twotheta[][][] = omega[p][r]+ atan((((q * Y_PIXEL_SPACING) + DetectorHeightA0[0]) - (M_directbeampos[p][0] + DetectorHeightD[0]) - (DetectorposA0[0] * tan(omega[p][r])))/DetectorposA0[0])
					break
				endswitch
				print "corrected angle of incidence for ",theAngle, " is: ~",180*omega[0][0]/pi
				//within the specular band omega changes slightly
				//used for constant Q integration.
				multithread M_omega = M_twotheta/2
				
				//now normalise the counts in the reflected beam by the direct beam spectrum
				//this gives a reflectivity
				//and propagate the errors, leaving the fractional variance (dr/r)^2
				//this step probably produces negative reflectivities, or NaN if M_specD is 0.
				//ALSO, 
				//M_refSD has the potential to be NaN is M_topandtailA0 or M_specD is 0.
				
				//ATTENTION: For the polarization corrected data, no complete error propagation through the polarization correction is performed.
				//Currently the error is simply taken from the intensity in the corrected spectra.
				//A complete error propagation is to be implemented in the future.				
				multithread M_ref[][][] = M_topandtailA0[p][q][r] / M_specD[p][0]
				multithread M_refPolCorr[] = M_specA0PolCorr[p] / M_specDPolCorr[p]
				//M_refSD[][] =   (M_topandtailA0SD[p][q] / M_topandtailA0[p][q])^2 +(W_specDSD[p] / W_specD[p])^2 
				M_refSD = 0
				M_refPolCorrSD = 0	
				
				multithread M_refSD[][][] += numtype((M_topandtailA0SD[p][q][r] / M_topandtailA0[p][q][r])^2) ? 0 : (M_topandtailA0SD[p][q][r] / M_topandtailA0[p][q][r])^2
				multithread M_refSD[][][] += numtype((M_specDSD[p][0] / M_specD[p][0])^2) ? 0 : (M_specDSD[p][0] / M_specD[p][0])^2	
				
				multithread M_refPolCorrSD[] += numtype((M_specA0PolCorrSD[p] / M_specA0PolCorr[p])^2) ? 0 : (M_specA0PolCorrSD[p] / M_specA0PolCorr[p])^2
				multithread M_refPolCorrSD[] += numtype((M_specDPolCorrSD[p] / M_specDPolCorr[p])^2) ? 0 : (M_specDPolCorrSD[p] / M_specDPolCorr[p])^2	
				
				//now calculate the Q values for the detector pixels.  Each pixel has different 2theta and different wavelength, ASSUME that they have the same angle of incidence
				multithread M_qz[][][]  = 2 * Pi * (1 / M_lambda[p][r]) * (sin(M_twotheta[p][q][r] - omega[p][r]) + sin(M_omega[p][q][r]))
				multithread M_qy[][][] = 2 * Pi * (1 / M_lambda[p][r]) * (cos(M_twotheta[p][q][r] - omega[p][r]) - cos(M_omega[p][q][r]))
				
				//work out the uncertainty in Q.
				//the wavelength contribution is already in W_LambdaSD
				//now have to work out the angular part and add in quadrature.
				Wave M_lambdaSD = $(theAngleDF+":M_lambdaSD"); AbortOnRTE
				multithread M_qzSD[][][] = (M_lambdaSD[p][r] / M_lambda[p][r])^2
				
				//angular part of uncertainty
				Wave ss2vg = $(theAngleDF+":instrument:slits:second:vertical:gap")
				Wave ss3vg = $(theAngleDF+":instrument:slits:third:vertical:gap")
				Wave slit2_distance = $(theAngleDF+":instrument:parameters:slit2_distance")
				Wave slit3_distance = $(theAngleDF+":instrument:parameters:slit3_distance")
				D_S2 = slit2_distance[0]
				D_S3 = slit3_distance[0]
				domega = 0.68 * sqrt((ss2vg[0]^2 + ss3vg[0]^2) / ((D_S3 - D_S2)^2))
		
				//now calculate the full uncertainty in Q for each Q pixel
				multithread M_qzSD[][][] += (domega/omega[p][r])^2
				multithread M_qzSD = sqrt(M_qzSD)
				multithread M_qzSD *= M_qz
				
				//correct for the beam monitor one counts.  This assumes that the direct beam was measured with the same
				//slit characteristics as the reflected beam.  This assumption is normally ok for the first angle.  One can only hope that everyone
				//have done this for the following angles.
				//multiply by bmon1_direct/bmon1_angle0
		
				//			//there should exist a global variable by the name of angle0DF + BM1counts, which is the summed BM1 count.
				//			//this normalisation can be done in processNexus file
				//			NVAR/z bmon1_counts_direct = $(directDF) + ":bm1counts"
				//			NVAR/z bmon1_counts_angle0 = $(angle0DF) + ":bm1counts"
				//			
				//			if(nvar_exists(bmon1_counts_direct) && nvar_exists(bmon1_counts_angle0))
				//				if(bmon1_counts_direct != 0 && bmon1_counts_angle0 != 0)
				//					temp =  ((sqrt(bmon1_counts_direct)/bmon1_counts_direct)^2 + (sqrt(bmon1_counts_angle0)/bmon1_counts_angle0)^2) //(dratio/ratio)^2
				//					
				//					multithread M_refSD += temp		//M_refSD is still fractional variance at this point.
				//					multithread M_ref *= bmon1_counts_direct/bmon1_counts_angle0
				//				endif
				//			endif

				//M_refSD is still (dr/r)^2
				multithread M_refPolCorrSD = sqrt(M_refPolCorrSD)
				multithread M_refPolCorrSD *= M_refPolCorr
				
				multithread M_refSD = sqrt(M_refSD)
				multithread M_refSD *= M_ref
						
				//scale reflectivity by scale factor
				// because refSD is stil fractional variance (dr/r)^2 have to divide by scale factor squared.
				multithread M_ref /= scalefactors
				//A division of the polarization corrected spectra by the scalefactor is not performed, since the spectra are scaled before the polarization correction. 
				//This might lead to slight differences in scaling, although I have not yet encountered such a case. 
				//If the scaling is different after the polarization correction, NEW scalefactors have to be provided! Otherwise, here new scalefactors would need to be provided, which complicates the whole reduction considerably.
				//multithread M_refPolCorr /= scalefactors
				multithread M_refSD /= (scalefactors)
				//multithread M_refPolCorrSD /= (scalefactors)
				
				//now cut out the pixels that aren't in the reflected beam
				//			deletepoints/M=1 hiPx+1, dimsize(M_ref,1), M_ref,M_refSD, M_qz, M_qzSD, M_omega, M_twotheta
				//			deletepoints/M=1 0, loPx, M_ref,M_refSD, M_qz, M_qzSD, M_omega, M_twotheta
	
				//get a beam profile for normalisation, not all pixels contribute equally to the reflectivity signal
				//			make/o/d/n=(hiPx-loPx+1)  $(angle0DF + ":beam_profile")
				//			Wave beam_profile = $(angle0DF + ":beam_profile")
				//			for(jj=0 ; jj< numpnts(beam_profile) ; jj+=1)
				//				imagetransform/g=(loPx+jj) sumcol M_topandtailA0
				//				beam_profile[jj] = V_Value
				//			endfor		
				//			Wavestats/q/m=1 beam_profile
				//			beam_profile /= (V_sum)
				//			M_ref[][] *= (beam_profile[q])

				/////////////////////////////
				/////////////////////////////
				//constant wavelength binning, comment out if performing constant Q
				/////////////////////////////
				/////////////////////////////
				make/n=(dimsize(M_qHIST, 0) - 1, numspectra)/free/d W_q = 0, W_qSD = 0, W_ref = 0, W_refSD = 0
		
				Multithread W_q[][] = LambdaToQ(M_lambda[p][q], omega[p][q])			
				Multithread W_qSD[][] = (M_lambdaSD[p][q]/M_lambda[p][q])^2+(domega/omega[p][q])^2
				Multithread W_qSD = sqrt(W_qSD)
				Multithread W_qSD *= W_q
				
				duplicate/free M_ref, M_reftemp
				duplicate/free M_refSD, M_refSDtemp

				deletepoints/M=1 hiPx + 1, dimsize(M_ref, 1), M_reftemp, M_refSDtemp
				deletepoints/M=1 0, loPx, M_reftemp, M_refSDtemp

				for(aa = 0 ; aa < numspectra ; aa += 1)
					imagetransform/P=(aa) sumallrows M_reftemp
					Wave W_sumrows
					W_ref[][aa] = W_sumrows[p]
			
					for(jj = 0 ; jj < dimsize(M_reftemp, 1) ; jj += 1)
						W_refSD[][aa] += M_refSDtemp[p][jj][aa]^2
					endfor
				endfor
				W_refSD = sqrt(W_refSD)
				/////////////////////////////
					/////////////////////////////			
				//Constant Q - doesn't work at the moment
				/////////////////////////////
				/////////////////////////////
				//work out Q bins			
				//			histtopoint(W_qHIST)
				//			Wave W_point
				//			duplicate/o W_point, $(angle0DF + ":W_q")
				//			duplicate/o W_point, $(angle0DF + ":W_qSD")
				//			Wave W_q = $(angle0DF + ":W_q")
				//			Wave W_qSD = $(angle0DF + ":W_qSD")
				//			LambdatoQ(W_qHIST, W_lambdaHIST, omega)
				//			LambdatoQ(W_q, W_lambda, omega)
				//			//assume that W_qSD is the same as the middle row.
				//			W_qSD[] = M_qzSD[p][dimsize(M_qzSD,1)/2]
				//			
				//			Pla_histogram(W_qHIST, M_qz, M_ref, M_refSD)
				//			Wave W_signal, W_signalSD, W_binfiller
				//			duplicate/o W_signal, $(angle0DF + ":W_ref")
				//			duplicate/o W_signalSD, $(angle0DF + ":W_refSD")
				//			killwaves/Z W_signal, W_signalSD
				//			Wave W_ref = $(angle0DF + ":W_ref")
				//			Wave W_refSD = $(angle0DF + ":W_refSD")
				//			//			W_ref/=W_binfiller
				//			//			W_refSD/=W_binfiller
				//			
				//			//now we have to get rid of points at the start and end, because const Qz is diagonal on the detector - some Qz bins
				//			//are filled with a lot fewer points, it's just easiest to delete them.
				//			//Do the low Q end first (highest bin number).
				//			//work out the highest Qz value, this will be at the top left
				//			//need to work out which W_qHIST bin it falls into
				//			variable loQcutoff = binarysearch(W_qHIST, M_qz[inf][inf])
				//			variable hiQcutoff = binarysearch(W_qHIST, M_qz[0][0])
				//			//need to get rid of all Q points higher than this.  First for the point values, then for the histoversions
				//			deletepoints/M=0 loQcutoff+1, dimsize(W_q,0), W_q, W_ref,W_refSD, W_qSD, W_lambda
				//			deletepoints/M=0 loQcutoff+1, dimsize(W_q,0), W_beamposA0, W_specA0, W_specA0SD, W_specTOF, M_topandtailA0
				//			deletepoints/M=0 loQcutoff+1, dimsize(W_q,0), M_topandtailA0SD, W_lambdaSD, omega, M_qz, M_ref, M_refSD, M_qzSD, M_omega, M_twotheta
				//			deletepoints/M=0 loQcutoff+2, dimsize(W_qHIST,0), W_qHIST, W_specTOFHIST, W_lambdaHIST
				//			
				//			deletepoints/M=0 0, hiQcutoff, W_q, W_ref,W_refSD, W_qSD, W_lambda
				//			deletepoints/M=0 0, hiQcutoff, W_beamposA0, W_specA0, W_specA0SD, W_specTOF, M_topandtailA0
				//			deletepoints/M=0 0, hiQcutoff, M_topandtailA0SD, W_lambdaSD, omega, M_qz, M_ref, M_refSD, M_qzSD, M_omega, M_twotheta
				//			deletepoints/M=0 0, hiQcutoff, W_qHIST, W_specTOFHIST, W_lambdaHIST		
			
				//
				//now write the individual wave out to a file.  It is reverse sorted in q, sorted in lambda, and we want to keep that.
				//therefore SORT->WRITE->REVERSE SORT
				//
				make/n=(dimsize(W_q, 0))/d/free qq = 0, RR = 0, dR = 0, dQ = 0, RRpolCorr=0, DRpolCorr=0 
				make/n=(dimsize(M_ref, 0), dimsize(M_ref, 1))/free/d qz2D, qy2D, RR2d, EE2d 
				for(aa = 0 ; aa < numspectra ; aa += 1)
					RR[] = W_ref[p][aa]
					RRpolCorr[] = M_refPolCorr[p][aa]
					DRpolCorr[] = M_refPolCorrSD[p][aa]
					dR[] = W_refSD[p][aa]
					qq[] = W_q[p][aa]
					dQ[] = W_qSD[p][aa]
					Sort qq, qq, RR, dR, dQ, RRpolCorr, DRpolCorr
			
					fname = cutfilename(theAngle)
					if(dontoverwrite)
						fname = uniqueFileName(outputPathStr, fname, ".dat")
					else
						print "NO UNIQUE FILENAME, files overwritten (ASCII.dat) (ReducePol)"
					endif
					
					newpath/o/q/z pla_temppath_write, outputpathStr
					open/P=pla_temppath_write fileID as fname + ".dat"
			
					if(V_flag == 0)
						fprintf fileID, "Q (1/A)\t Ref\t dRef (SD)\t RefPolCorr\t DRefPolCorr\t dq(FWHM, 1/A)\n"
						wfprintf fileID, "%g\t %g\t %g\t %g\t %g\t %g\n" qq, RR, dR, RRpolCorr, DRpolCorr, dQ
						close fileID
					endif
			
					//this only writes XML for a single file
					fname = cutfilename(theAngle)
					if(dontoverwrite)
						fname = uniqueFileName(outputPathStr, fname, ".xml")
					else
						print "NO UNIQUE FILENAME, files overwritten (1D.XML) (ReducePol)"
					endif
					Wave/t user = $(theAngleDF + ":user:name")
					Wave/t samplename = $(theAngleDF + ":sample:name")			
					//The code to write an xml file has been adjusted to incorporate the new polarization corrected channels
					writeSpecRefXML1DPolCorr(outputPathStr, fname, qq, RR, dR, RRPolCorr, dRPolCorr, dQ, "", user[0], samplename[0], theAngle, reductionCmd)
						
					//write a 2D XMLfile for the offspecular data
					if(saveoffspec)
						Multithread qz2D[][] = M_qz[p][q][aa]
						Multithread qy2D[][] = M_qy[p][q][aa]
						Multithread RR2d[][] = M_Ref[p][q][aa]
						Multithread EE2d[][] = M_RefSD[p][q][aa]
							
						ofname = "off_" + cutfilename(theAngle)
						if(dontoverwrite)
							ofname = uniqueFileName(outputPathStr, ofname, ".xml")
						else
							print "NO UNIQUE FILENAME, files overwritten (2D.XML) (ReducePol)"	
						endif
						//Since the 2D data is not polarization corrected, this file stays the same as in unpolarized mode
						write2DXML(outputPathStr, ofname, qz2D, qy2D, RR2d, EE2d, "", user[0], samplename[0], theAngle, reductionCmd)
					endif
				endfor
//				
				killpath/z pla_temppath_write
				outputname = outputname + fname + ";"
			endif
		endfor	
		print "(ReducePol) The runs processed in reducePol are", processedruns

			
	catch
		Print "ERROR: an abort was encountered in (DB division part)"
		setdatafolder $cDF
		return ""
	endtry	
	
	
	setdatafolder $cDF
	outputname = RemoveEnding(outputname, ";")
	Print "(ReducePol) finished successfully", outputname
	return outputname
	
End

Function writeSpecRefXML1DPolCorr(outputPathStr, fname, qq, RR, dR, RRpolCorr, DRpolCorr, dQ, exptitle, user, samplename, runnumbers, rednnote)
	String outputPathStr, fname
	wave qq, RR, dR, RRpolCorr, DRpolCorr, dQ
	String exptitle, user, samplename, runnumbers, rednnote	//a function to write an XML description of the reduced dataset.
	//pathname is a folder path, e.g. faffmatic:Users:andrew:Desktop: 	REQUIRED
	//fname is the filename of the file you want to write					REQUIRED
	//qq, RR, dR, RRpolCorr, DRpolCorr, dQ are the waves you want to write to the file			REQUIRED	
	//exptitle is the experiment title, e.g. "polymer films.				OPTIONAL
	//user is the user name												OPTIONAL
	//samplename is the name of the sample, duh						OPTIONAL
	//runnumbers is a semicolon separated list of the runnumbers making up this file, e.g. PLP0001000;PLP0001001;PLP0001002	OPTIONAL
	//rednnote is the command that was used to do the reduction			OPTIONAL
	
	variable fileID,ii,jj
	string qqStr="",RRstr="",dRStr="",RRPolCorrstr="",dRPolCorrStr="",  dqStr = "", prefix = ""
	
	GetFileFolderInfo/q/z outputPathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (writeSpecRefXML1D)"
		return 1	
	endif
		
	//create the XMLfile
	fileID = XMLcreatefile(outputPathStr + fname + ".xml", "REFroot", "", "")
	if(fileID < 1)
		print "ERROR couldn't create XML file (writeSpecRefXML1D)"
	endif

	xmladdnode(fileID,"//REFroot","","REFentry","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]","","time",Secs2Date(DateTime,0) + " "+Secs2Time(DateTime,3))

	xmladdnode(fileID,"//REFroot/REFentry[1]","","Title","",1)
	
	//username
	xmladdnode(fileID,"//REFroot/REFentry[1]","","User",user,1)

	//sample names
	xmladdnode(fileID,"//REFroot/REFentry[1]","","REFsample","",1)
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFsample","","ID", samplename,1)

	xmladdnode(fileID,"//REFroot/REFentry[1]","","REFdata","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","axes","Qz")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","rank","1")

	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","type","POINT")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","spin","UNPOLARISED")
	
	for(ii=0;ii<itemsinlist(runnumbers);ii+=1)
		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Run","",1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","filename",stringfromlist(ii,runnumbers)+".nx.hdf")
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","preset","")
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","size","")
	endfor
	
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(1)+"]","","reductionnote",rednnote,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(1)+"]/reductionnote[1]","","software","SLIM")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(1)+"]/reductionnote[1]","","version", num2istr(Pla_getVersion()))
	
	//create ASCII representation of data
	sockitWaveToString/TXT qq, qqStr
	sockitWaveToString/TXT RR, RRStr
	sockitWaveToString/TXT dR, dRStr
	sockitWaveToString/TXT RRPolCorr, RRPolCorrStr
	sockitWaveToString/TXT dRPolCorr, dRPolCorrStr
	sockitWaveToString/TXT dQ, dqStr

	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","dim",num2istr(itemsinlist(RRstr," ")))

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","R",RRStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/R","","uncertainty","dR")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","RPolCorr",RRPolCorrStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/RPolCorr","","uncertainty","dRPolCorr")
	
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Qz",qqStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","uncertainty","dQz")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","units","1/A")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dR",dRStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dR","","type","SD")
	
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dRPolCorr",dRPolCorrStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dRPolCorr","","type","SD")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dQz",dqStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dQz","","type","FWHM")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dQz","","units","1/A")

	xmlclosefile(fileID,1)
End


Function spliceFilesPolCorr(outputPathStr, fname, filesToSplice, [factors, rebin])
	//Returns 0 if successfull, 1 if not (err)
	string outputPathStr, fname, filesToSplice, factors 
	//fname contains the output names of the spliced datasets "c_..." as list separated by ";" (4 entries)
	//filesToSplice contains a list of the polarization corrected spectra, 4 individual channels are separated by ";" while angles are separated by ":" (as many angles as measured)
	variable rebin
	//This function splices different reduced files together. It is very similar to the original without polarization corrected data, as are the functions called within.
	//The main difference is that the new polcorr spectra are processed as well. The different pol-channels are processed after each other.
	//Functions called within: Pla_GetWeightScOPolCorr, Pla_rebin_afterwardsPolCorr, writeSpecRefXML1DPolCorr


	string cDF
	cDF = getdatafolder(1)
	string df = "root:packages:platypus:data:Reducer:"
	string qqStr="",RRstr="",dRStr="",RRPolCorrstr="",dRPolCorrStr="",dqStr="",filename,prefix=""
	string user = "", samplename = "", rednnote = ""
	string newfnameI00, newfnameI01, newfnameI10, newfnameI11, Tfname, Ffname, tempfilenameoutput
	
	variable fileID, R00fileID, R01fileID,R10fileID,R11fileID, ii,fileIDcomb, err=0, jj, numfiles
	string compSplicefactors, temporarystring
	variable/c compSplicefactor, compSplicefactorpolcorr
	variable compSplicefactorreal, compSplicefactorimag, compSplicefactorpolcorrreal, compSplicefactorpolcorrimag

	try
		err=0
		newdatafolder/o root:packages
		newdatafolder/o root:packages:platypus
		newdatafolder/o root:packages:platypus:data
		newdatafolder/o root:packages:platypus:data:reducer
		newdatafolder/o/s root:packages:platypus:data:reducer:temp
	 
		GetFileFolderInfo/q/z outputPathStr
		if(V_flag)//path doesn't exist
			print "ERROR please give valid path (spliceFilesPolCorr)"
			return 1	
		endif
					
		//load in each of the files
		//fname (=PolchannelsFname) contains the output filenames C_...
		//filestosplice (=toSplice) contains a list of files in chunks of 4. the channels are separated by ";", while the angles are separated by ":"
		Tfname = stringfromlist(0, fname, ":")		
		newfnameI00 =  stringfromlist(0, Tfname, ";") 
		if(stringmatch(newfnameI00, "c_00") || stringmatch(newfnameI00, "c_0") )
				newfnameI00 = ""
		endif
		newfnameI01 =  stringfromlist(1, Tfname, ";")
		if(stringmatch(newfnameI01, "c_00") || stringmatch(newfnameI01, "c_0"))
				newfnameI01 = ""
		endif
		newfnameI10 =  stringfromlist(2, Tfname, ";") 
		if(stringmatch(newfnameI10, "c_00") || stringmatch(newfnameI10, "c_0"))
				newfnameI10 = ""
		endif
		newfnameI11 =  stringfromlist(3, Tfname, ";") 
		if(stringmatch(newfnameI11, "c_00") || stringmatch(newfnameI11, "c_0"))
				newfnameI11 = ""
		endif
		print "(spliceFilesPolCorr) First angle of files to be spliced: Tfname = ", Tfname
		numfiles = itemsinlist(filesToSplice, ":")
		for(ii = 0 ; ii < itemsinlist(filesToSplice, ":") ; ii += 1)
			print "(spliceFilesPolCorr) This is the first step of the for loop (it will be repeated): All files to be spliced", filesToSplice
			Ffname = stringfromlist(ii, filesToSplice, ":")
			print "(spliceFilesPolCorr) THIS SHOULD GO FORWARD in the steps of the loop): Ffname = ", Ffname
			//////////////////////////
			//NEED TO REPEAT FOR EACH CHANNEL FROM HERE
			//FIRST THE R00 channel
			///////////////////////////////////////////////
			if(stringmatch(stringfromlist(0, Ffname), "00")||stringmatch(stringfromlist(0, Ffname), "0"))
				print "The File for REF I00 was not given in (loop ii, Ffname) pos 0 (spliceFilesPolCorr)", ii, Ffname
			else
				tempfilenameoutput = stringfromlist(0, Ffname)
				print "R00 file to be processed in run ", ii, " of for loop (spliceFilesPolCorr)", tempfilenameoutput
				R00fileID = xmlopenfile(outputPathStr + stringfromlist(0, Ffname) + ".xml")
				if(R00fileID < 1)
					print "ERROR couldn't open individual file (spliceFilesPolCorr)";abort
				endif
			
				xmlwavefmXPATH(R00fileID,"//REFdata[1]/Qz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontQzR00
				xmlfilecontQzR00 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R00fileID,"//REFdata[1]/R","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRR00
				xmlfilecontRR00 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R00fileID,"//REFdata[1]/RPolCorr","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRPolCorrR00
				xmlfilecontRPolCorrR00 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R00fileID,"//REFdata[1]/dR","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRR00
				xmlfilecontdRR00 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R00fileID,"//REFdata[1]/dRPolCorr","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRPolCorrR00
				xmlfilecontdRPolCorrR00 = str2num(M_xmlcontent[p][0])

				xmlwavefmXPATH(R00fileID,"//REFdata[1]/dQz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdQzR00
				xmlfilecontdQzR00 = str2num(M_xmlcontent[p][0])
			
//				sort asdfghjkl0,asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3 
				sort xmlfilecontQzR00, xmlfilecontQzR00, xmlfilecontRR00, xmlfilecontRPolCorrR00, xmlfilecontdRR00, xmlfilecontdRPolCorrR00, xmlfilecontdQzR00
				if(ii == 0)
					make/o/d/n=(numpnts(xmlfilecontQzR00)) tempQQR00, tempRRR00, tempDRR00,tempRRPolCorrR00, tempDRPolCorrR00, tempDQR00
					Wave tempQQR00, tempRRR00, tempDRR00, tempDQR00, tempRRPolCorrR00, tempDRPolCorrR00
					tempQQR00=xmlfilecontQzR00
					tempRRR00=xmlfilecontRR00
					tempRRPolCorrR00=xmlfilecontRPolCorrR00
					tempDRR00=xmlfilecontdRR00
					tempDRPolCorrR00=xmlfilecontdRPolCorrR00
					tempDQR00=xmlfilecontdQzR00
				
					samplename = xmlstrfmXpath(R00fileID, "//REFsample/ID", "", "")
					user = xmlstrfmXpath(R00fileID, "//REFentry[1]/User", "", "")
					rednnote = xmlstrfmXpath(R00fileID,"//REFroot/REFentry[1]/REFdata[1]/Run[1]/reductionnote","","")
					compsplicefactor = cmplx(1., 1.)
					print "(spliceFilesPolCorr) The compSplicefactor is", compSplicefactor, "since loop", ii			 
				else
					//splice with propagated error in the splice factor
					if(paramisdefault(factors))
				
					
						compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR00, tempRRR00, tempDRR00, tempRRPolCorrR00, tempDRPolCorrR00, xmlfilecontQzR00, xmlfilecontRR00, xmlfilecontdRR00, xmlfilecontRPolCorrR00, xmlfilecontdRPolCorrR00) 		
						                               //Pla_GetWeightScOPolCorr(wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr)
						//print compSplicefactors
						temporarystring = stringfromlist(0, compSplicefactors, ";")
						compSplicefactorreal  = str2num(temporarystring)
						temporarystring = stringfromlist(1, compSplicefactors, ";")
						compSplicefactorimag = str2num(temporarystring)
						temporarystring = stringfromlist(2, compSplicefactors, ";")
						compSplicefactorpolcorrreal  = str2num(temporarystring)
					 	temporarystring = stringfromlist(3, compSplicefactors, ";")
						compSplicefactorpolcorrimag = str2num(temporarystring)
					
						compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
						compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
						print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R00 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
					else
						if(itemsinlist(factors) <= ii)
							compSplicefactor = cmplx(str2num(stringfromlist(ii-1, factors)), 0)
						else
							compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR00, tempRRR00, tempDRR00, tempRRPolCorrR00, tempDRPolCorrR00, xmlfilecontQzR00, xmlfilecontRR00, xmlfilecontdRR00, xmlfilecontRPolCorrR00, xmlfilecontdRPolCorrR00)							
							temporarystring = stringfromlist(0, compSplicefactors, ";")
							compSplicefactorreal  = str2num(temporarystring)
							temporarystring = stringfromlist(1, compSplicefactors, ";")
							compSplicefactorimag = str2num(temporarystring)
							temporarystring = stringfromlist(2, compSplicefactors, ";")
							compSplicefactorpolcorrreal  = str2num(temporarystring)
					 		temporarystring = stringfromlist(3, compSplicefactors, ";")
							compSplicefactorpolcorrimag = str2num(temporarystring)
					
							compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
							compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
							print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R00 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
						endif
						
					endif
					if(numtype(REAL(compspliceFactor)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					if(numtype(REAL(compspliceFactorpolcorr)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					//xmlfilecontQzR00, xmlfilecontRR00, xmlfilecontRPolCorrR00, xmlfilecontdRR00, xmlfilecontdRPolCorrR00, xmlfilecontdQzR00
					
					//(Comment from Andy:) think the following is wrong! No need to errors in quadrature if scalefactor does not depend on wavelength
					xmlfilecontdRR00 = (xmlfilecontdRR00/xmlfilecontRR00)^2
					xmlfilecontdRR00 += (imag(compSpliceFactor)/real(compSpliceFactor))^2
					xmlfilecontdRR00 = sqrt(xmlfilecontdRR00)
					xmlfilecontRR00 *= real(compSplicefactor)
					xmlfilecontdRR00 *= xmlfilecontRR00
					
					xmlfilecontdRPolCorrR00 = (xmlfilecontdRPolCorrR00/xmlfilecontRPolCorrR00)^2
					xmlfilecontdRPolCorrR00 += (imag(compspliceFactorpolcorr)/real(compspliceFactorpolcorr))^2
					xmlfilecontdRPolCorrR00 = sqrt(xmlfilecontdRPolCorrR00)
					xmlfilecontRPolCorrR00 *= real(compspliceFactorpolcorr)
					xmlfilecontdRPolCorrR00 *= xmlfilecontRPolCorrR00
				
					concatenate/NP {xmlfilecontRR00},tempRRR00
					concatenate/NP {xmlfilecontRPolCorrR00},tempRRPolCorrR00
					concatenate/NP {xmlfilecontQzR00},tempQQR00
					concatenate/NP {xmlfilecontdQzR00},tempDQR00
					concatenate/NP {xmlfilecontdRR00},tempDRR00
					concatenate/NP {xmlfilecontdRPolCorrR00},tempDRPolCorrR00
				
					sort tempQQR00,tempQQR00,tempRRR00,tempDRR00, tempRRPolCorrR00,tempDRPolCorrR00, tempDQR00 
				endif
				//close the XML file
				xmlsetattr(R00fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scale", num2str(real(compsplicefactor)))
				xmlsetattr(R00fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scalePolCorr", num2str(real(compsplicefactorpolcorr)))
				xmlclosefile(fileID, 1)
				R00fileID=0
			endif
			
			//////////////////////////
			//NOW THE R01 CHANNEL
			///////////////////////////////////////////////
			if(stringmatch(stringfromlist(1, Ffname), "00")||stringmatch(stringfromlist(1, Ffname), "0"))
				print "The File for REF I01 was not given in (loop ii, Ffname) pos 1  (spliceFilesPolCorr)", ii, Ffname
			else
				tempfilenameoutput = stringfromlist(1, Ffname)
				print "R01 file to be processed in run ", ii, " of for loop (splicefilespolcorr)", tempfilenameoutput
				R01fileID = xmlopenfile(outputPathStr + stringfromlist(1, Ffname) + ".xml")
				if(R01fileID < 1)
					print "ERROR couldn't open individual file (spliceFilesPolCorr)";abort
				endif
			
				xmlwavefmXPATH(R01fileID,"//REFdata[1]/Qz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontQzR01
				xmlfilecontQzR01 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R01fileID,"//REFdata[1]/R","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRR01
				xmlfilecontRR01 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R01fileID,"//REFdata[1]/RPolCorr","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRPolCorrR01
				xmlfilecontRPolCorrR01 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R01fileID,"//REFdata[1]/dR","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRR01
				xmlfilecontdRR01 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R01fileID,"//REFdata[1]/dRPolCorr","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRPolCorrR01
				xmlfilecontdRPolCorrR01 = str2num(M_xmlcontent[p][0])

				xmlwavefmXPATH(R01fileID,"//REFdata[1]/dQz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdQzR01
				xmlfilecontdQzR01 = str2num(M_xmlcontent[p][0])
			
//				sort asdfghjkl0,asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3 
				sort xmlfilecontQzR01, xmlfilecontQzR01, xmlfilecontRR01, xmlfilecontRPolCorrR01, xmlfilecontdRR01, xmlfilecontdRPolCorrR01, xmlfilecontdQzR01
				if(ii == 0)
					make/o/d/n=(numpnts(xmlfilecontQzR01)) tempQQR01, tempRRR01, tempDRR01,tempRRPolCorrR01, tempDRPolCorrR01, tempDQR01
					Wave tempQQR01, tempRRR01, tempDRR01, tempDQR01, tempRRPolCorrR01, tempDRPolCorrR01
					tempQQR01=xmlfilecontQzR01
					tempRRR01=xmlfilecontRR01
					tempRRPolCorrR01=xmlfilecontRPolCorrR01
					tempDRR01=xmlfilecontdRR01
					tempDRPolCorrR01=xmlfilecontdRPolCorrR01
					tempDQR01=xmlfilecontdQzR01
				
					samplename = xmlstrfmXpath(R01fileID, "//REFsample/ID", "", "")
					user = xmlstrfmXpath(R01fileID, "//REFentry[1]/User", "", "")
					rednnote = xmlstrfmXpath(R01fileID,"//REFroot/REFentry[1]/REFdata[1]/Run[1]/reductionnote","","")
					compsplicefactor = cmplx(1., 1.)			 
				else
					//splice with propagated error in the splice factor
					if(paramisdefault(factors))
				
					
						compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR01, tempRRR01, tempDRR01, tempRRPolCorrR01, tempDRPolCorrR01, xmlfilecontQzR01, xmlfilecontRR01, xmlfilecontdRR01, xmlfilecontRPolCorrR01, xmlfilecontdRPolCorrR01) 		
						                               //Pla_GetWeightScOPolCorr(wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr)
						//print compSplicefactors
						temporarystring = stringfromlist(0, compSplicefactors, ";")
						compSplicefactorreal  = str2num(temporarystring)
						temporarystring = stringfromlist(1, compSplicefactors, ";")
						compSplicefactorimag = str2num(temporarystring)
						temporarystring = stringfromlist(2, compSplicefactors, ";")
						compSplicefactorpolcorrreal  = str2num(temporarystring)
					 	temporarystring = stringfromlist(3, compSplicefactors, ";")
						compSplicefactorpolcorrimag = str2num(temporarystring)
					
						compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
						compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
						print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R01 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
					else
						if(itemsinlist(factors) <= ii)
							compSplicefactor = cmplx(str2num(stringfromlist(ii-1, factors)), 0)
						else
							compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR01, tempRRR01, tempDRR01, tempRRPolCorrR01, tempDRPolCorrR01, xmlfilecontQzR01, xmlfilecontRR01, xmlfilecontdRR01, xmlfilecontRPolCorrR01, xmlfilecontdRPolCorrR01)							
							temporarystring = stringfromlist(0, compSplicefactors, ";")
							compSplicefactorreal  = str2num(temporarystring)
							temporarystring = stringfromlist(1, compSplicefactors, ";")
							compSplicefactorimag = str2num(temporarystring)
							temporarystring = stringfromlist(2, compSplicefactors, ";")
							compSplicefactorpolcorrreal  = str2num(temporarystring)
					 		temporarystring = stringfromlist(3, compSplicefactors, ";")
							compSplicefactorpolcorrimag = str2num(temporarystring)
					
							compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
							compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
							print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R01 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
						endif
						
					endif
					if(numtype(REAL(compspliceFactor)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					if(numtype(REAL(compspliceFactorpolcorr)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					//xmlfilecontQzR01, xmlfilecontRR01, xmlfilecontRPolCorrR01, xmlfilecontdRR01, xmlfilecontdRPolCorrR01, xmlfilecontdQzR01
					
					//(Comment from Andy:) think the following is wrong! No need to errors in quadrature if scalefactor does not depend on wavelength
					xmlfilecontdRR01 = (xmlfilecontdRR01/xmlfilecontRR01)^2
					xmlfilecontdRR01 += (imag(compSpliceFactor)/real(compSpliceFactor))^2
					xmlfilecontdRR01 = sqrt(xmlfilecontdRR01)
					xmlfilecontRR01 *= real(compSplicefactor)
					xmlfilecontdRR01 *= xmlfilecontRR01
					
					xmlfilecontdRPolCorrR01 = (xmlfilecontdRPolCorrR01/xmlfilecontRPolCorrR01)^2
					xmlfilecontdRPolCorrR01 += (imag(compspliceFactorpolcorr)/real(compspliceFactorpolcorr))^2
					xmlfilecontdRPolCorrR01 = sqrt(xmlfilecontdRPolCorrR01)
					xmlfilecontRPolCorrR01 *= real(compspliceFactorpolcorr)
					xmlfilecontdRPolCorrR01 *= xmlfilecontRPolCorrR01
				
					concatenate/NP {xmlfilecontRR01},tempRRR01
					concatenate/NP {xmlfilecontRPolCorrR01},tempRRPolCorrR01
					concatenate/NP {xmlfilecontQzR01},tempQQR01
					concatenate/NP { xmlfilecontdQzR01},tempDQR01
					concatenate/NP {xmlfilecontdRR01},tempDRR01
					concatenate/NP {xmlfilecontdRPolCorrR01},tempDRPolCorrR01
				
					sort tempQQR01,tempQQR01,tempRRR01,tempDRR01, tempRRPolCorrR01,tempDRPolCorrR01, tempDQR01 
				endif
				//close the XML file
				xmlsetattr(R01fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scale", num2str(real(compsplicefactor)))
				xmlsetattr(R01fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scalePolCorr", num2str(real(compsplicefactorpolcorr)))
				xmlclosefile(fileID, 1)
				R01fileID=0				
			endif
			
			//////////////////////////
			//NOW THE R10 CHANNEL
			///////////////////////////////////////////////
				if(stringmatch(stringfromlist(2, Ffname), "00")||stringmatch(stringfromlist(2, Ffname), "0"))
					print "The File for REF I10 was not given in (loop ii, Ffname) pos 2 (spliceFilesPolCorr)", ii, Ffname
				else
				tempfilenameoutput = stringfromlist(2, Ffname)
				print "R10 file to be processed in run ", ii, " of for loop (spliceFilesPolCorr)", tempfilenameoutput
				R10fileID = xmlopenfile(outputPathStr + stringfromlist(2, Ffname) + ".xml")
				if(R10fileID < 1)
					print "ERROR couldn't open individual file (spliceFilesPolCorr)";abort
				endif
			
				xmlwavefmXPATH(R10fileID,"//REFdata[1]/Qz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontQzR10
				xmlfilecontQzR10 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R10fileID,"//REFdata[1]/R","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRR10
				xmlfilecontRR10 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R10fileID,"//REFdata[1]/RPolCorr","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRPolCorrR10
				xmlfilecontRPolCorrR10 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R10fileID,"//REFdata[1]/dR","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRR10
				xmlfilecontdRR10 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R10fileID,"//REFdata[1]/dRPolCorr","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRPolCorrR10
				xmlfilecontdRPolCorrR10 = str2num(M_xmlcontent[p][0])

				xmlwavefmXPATH(R10fileID,"//REFdata[1]/dQz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdQzR10
				xmlfilecontdQzR10 = str2num(M_xmlcontent[p][0])
			
//				sort asdfghjkl0,asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3 
				sort xmlfilecontQzR10, xmlfilecontQzR10, xmlfilecontRR10, xmlfilecontRPolCorrR10, xmlfilecontdRR10, xmlfilecontdRPolCorrR10, xmlfilecontdQzR10
				if(ii == 0)
					make/o/d/n=(numpnts(xmlfilecontQzR10)) tempQQR10, tempRRR10, tempDRR10,tempRRPolCorrR10, tempDRPolCorrR10, tempDQR10
					Wave tempQQR10, tempRRR10, tempDRR10, tempDQR10, tempRRPolCorrR10, tempDRPolCorrR10
					tempQQR10=xmlfilecontQzR10
					tempRRR10=xmlfilecontRR10
					tempRRPolCorrR10=xmlfilecontRPolCorrR10
					tempDRR10=xmlfilecontdRR10
					tempDRPolCorrR10=xmlfilecontdRPolCorrR10
					tempDQR10=xmlfilecontdQzR10
				
					samplename = xmlstrfmXpath(R10fileID, "//REFsample/ID", "", "")
					user = xmlstrfmXpath(R10fileID, "//REFentry[1]/User", "", "")
					rednnote = xmlstrfmXpath(R10fileID,"//REFroot/REFentry[1]/REFdata[1]/Run[1]/reductionnote","","")
					compsplicefactor = cmplx(1., 1.)			 
				else
					//splice with propagated error in the splice factor
					if(paramisdefault(factors))
				
					
						compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR10, tempRRR10, tempDRR10, tempRRPolCorrR10, tempDRPolCorrR10, xmlfilecontQzR10, xmlfilecontRR10, xmlfilecontdRR10, xmlfilecontRPolCorrR10, xmlfilecontdRPolCorrR10) 		
						                               //Pla_GetWeightScOPolCorr(wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr)
						//print compSplicefactors
						temporarystring = stringfromlist(0, compSplicefactors, ";")
						compSplicefactorreal  = str2num(temporarystring)
						temporarystring = stringfromlist(1, compSplicefactors, ";")
						compSplicefactorimag = str2num(temporarystring)
						temporarystring = stringfromlist(2, compSplicefactors, ";")
						compSplicefactorpolcorrreal  = str2num(temporarystring)
					 	temporarystring = stringfromlist(3, compSplicefactors, ";")
						compSplicefactorpolcorrimag = str2num(temporarystring)
					
						compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
						compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
						print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R10 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
					else
						if(itemsinlist(factors) <= ii)
							compSplicefactor = cmplx(str2num(stringfromlist(ii-1, factors)), 0)
						else
							compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR10, tempRRR10, tempDRR10, tempRRPolCorrR10, tempDRPolCorrR10, xmlfilecontQzR10, xmlfilecontRR10, xmlfilecontdRR10, xmlfilecontRPolCorrR10, xmlfilecontdRPolCorrR10)							
							temporarystring = stringfromlist(0, compSplicefactors, ";")
							compSplicefactorreal  = str2num(temporarystring)
							temporarystring = stringfromlist(1, compSplicefactors, ";")
							compSplicefactorimag = str2num(temporarystring)
							temporarystring = stringfromlist(2, compSplicefactors, ";")
							compSplicefactorpolcorrreal  = str2num(temporarystring)
					 		temporarystring = stringfromlist(3, compSplicefactors, ";")
							compSplicefactorpolcorrimag = str2num(temporarystring)
					
							compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
							compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
							print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R10 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
						endif
						
					endif
					if(numtype(REAL(compspliceFactor)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					if(numtype(REAL(compspliceFactorpolcorr)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					//xmlfilecontQzR10, xmlfilecontRR10, xmlfilecontRPolCorrR10, xmlfilecontdRR10, xmlfilecontdRPolCorrR10, xmlfilecontdQzR10
					
					//(Comment from Andy:) think the following is wrong! No need to errors in quadrature if scalefactor does not depend on wavelength
					xmlfilecontdRR10 = (xmlfilecontdRR10/xmlfilecontRR10)^2
					xmlfilecontdRR10 += (imag(compSpliceFactor)/real(compSpliceFactor))^2
					xmlfilecontdRR10 = sqrt(xmlfilecontdRR10)
					xmlfilecontRR10 *= real(compSplicefactor)
					xmlfilecontdRR10 *= xmlfilecontRR10
					
					xmlfilecontdRPolCorrR10 = (xmlfilecontdRPolCorrR10/xmlfilecontRPolCorrR10)^2
					xmlfilecontdRPolCorrR10 += (imag(compspliceFactorpolcorr)/real(compspliceFactorpolcorr))^2
					xmlfilecontdRPolCorrR10 = sqrt(xmlfilecontdRPolCorrR10)
					xmlfilecontRPolCorrR10 *= real(compspliceFactorpolcorr)
					xmlfilecontdRPolCorrR10 *= xmlfilecontRPolCorrR10
				
					concatenate/NP {xmlfilecontRR10},tempRRR10
					concatenate/NP {xmlfilecontRPolCorrR10},tempRRPolCorrR10
					concatenate/NP {xmlfilecontQzR10},tempQQR10
					concatenate/NP {xmlfilecontdQzR10},tempDQR10
					concatenate/NP {xmlfilecontdRR10},tempDRR10
					concatenate/NP {xmlfilecontdRPolCorrR10},tempDRPolCorrR10
				
					sort tempQQR10,tempQQR10,tempRRR10,tempDRR10, tempRRPolCorrR10,tempDRPolCorrR10, tempDQR10 
				endif
				//close the XML file
				xmlsetattr(R10fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scale", num2str(real(compsplicefactor)))
				xmlsetattr(R10fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scalePolCorr", num2str(real(compsplicefactorpolcorr)))
				xmlclosefile(fileID, 1)
				R10fileID=0
			endif
			
			//////////////////////////
			//NOW THE R11 CHANNEL
			///////////////////////////////////////////////
			if(stringmatch(stringfromlist(3, Ffname), "00")||stringmatch(stringfromlist(3, Ffname), "0"))
				print "The File for REF I11 was not given in (loop ii, Ffname) pos 3 (spliceFilesPolCorr)", ii, Ffname
			else
				tempfilenameoutput = stringfromlist(3, Ffname)
				print "R11 file to be processed in run ", ii, " of for loop (splicefilespolcorr)", tempfilenameoutput
				R11fileID = xmlopenfile(outputPathStr + stringfromlist(3, Ffname) + ".xml")
				if(R11fileID < 1)
					print "ERROR couldn't open individual file (spliceFilesPolCorr)";abort
				endif
			
				xmlwavefmXPATH(R11fileID,"//REFdata[1]/Qz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontQzR11
				xmlfilecontQzR11 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R11fileID,"//REFdata[1]/R","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRR11
				xmlfilecontRR11 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R11fileID,"//REFdata[1]/RPolCorr","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontRPolCorrR11
				xmlfilecontRPolCorrR11 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R11fileID,"//REFdata[1]/dR","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRR11
				xmlfilecontdRR11 = str2num(M_xmlcontent[p][0])
				
				xmlwavefmXPATH(R11fileID,"//REFdata[1]/dRPolCorr","","")
    	 			Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdRPolCorrR11
				xmlfilecontdRPolCorrR11 = str2num(M_xmlcontent[p][0])

				xmlwavefmXPATH(R11fileID,"//REFdata[1]/dQz","","")
				Wave/t M_xmlcontent
				make/o/d/n=(dimsize(M_xmlcontent,0)) xmlfilecontdQzR11
				xmlfilecontdQzR11 = str2num(M_xmlcontent[p][0])
			
//				sort asdfghjkl0,asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3 
				sort xmlfilecontQzR11, xmlfilecontQzR11, xmlfilecontRR11, xmlfilecontRPolCorrR11, xmlfilecontdRR11, xmlfilecontdRPolCorrR11, xmlfilecontdQzR11
				if(ii == 0)
					make/o/d/n=(numpnts(xmlfilecontQzR11)) tempQQR11, tempRRR11, tempDRR11,tempRRPolCorrR11, tempDRPolCorrR11, tempDQR11
					Wave tempQQR11, tempRRR11, tempDRR11, tempDQR11, tempRRPolCorrR11, tempDRPolCorrR11
					tempQQR11=xmlfilecontQzR11
					tempRRR11=xmlfilecontRR11
					tempRRPolCorrR11=xmlfilecontRPolCorrR11
					tempDRR11=xmlfilecontdRR11
					tempDRPolCorrR11=xmlfilecontdRPolCorrR11
					tempDQR11=xmlfilecontdQzR11
				
					samplename = xmlstrfmXpath(R11fileID, "//REFsample/ID", "", "")
					user = xmlstrfmXpath(R11fileID, "//REFentry[1]/User", "", "")
					rednnote = xmlstrfmXpath(R11fileID,"//REFroot/REFentry[1]/REFdata[1]/Run[1]/reductionnote","","")
					compsplicefactor = cmplx(1., 1.)			 
				else
					//splice with propagated error in the splice factor
					if(paramisdefault(factors))
				
					
						compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR11, tempRRR11, tempDRR11, tempRRPolCorrR11, tempDRPolCorrR11, xmlfilecontQzR11, xmlfilecontRR11, xmlfilecontdRR11, xmlfilecontRPolCorrR11, xmlfilecontdRPolCorrR11) 		
						                               //Pla_GetWeightScOPolCorr(wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr)
						//print compSplicefactors
						temporarystring = stringfromlist(0, compSplicefactors, ";")
						compSplicefactorreal  = str2num(temporarystring)
						temporarystring = stringfromlist(1, compSplicefactors, ";")
						compSplicefactorimag = str2num(temporarystring)
						temporarystring = stringfromlist(2, compSplicefactors, ";")
						compSplicefactorpolcorrreal  = str2num(temporarystring)
					 	temporarystring = stringfromlist(3, compSplicefactors, ";")
						compSplicefactorpolcorrimag = str2num(temporarystring)
					
						compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
						compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
						print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R11 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
					else
						if(itemsinlist(factors) <= ii)
							compSplicefactor = cmplx(str2num(stringfromlist(ii-1, factors)), 0)
						else
							compSplicefactors = Pla_GetWeightScOPolCorr(tempQQR11, tempRRR11, tempDRR11, tempRRPolCorrR11, tempDRPolCorrR11, xmlfilecontQzR11, xmlfilecontRR11, xmlfilecontdRR11, xmlfilecontRPolCorrR11, xmlfilecontdRPolCorrR11)							
							temporarystring = stringfromlist(0, compSplicefactors, ";")
							compSplicefactorreal  = str2num(temporarystring)
							temporarystring = stringfromlist(1, compSplicefactors, ";")
							compSplicefactorimag = str2num(temporarystring)
							temporarystring = stringfromlist(2, compSplicefactors, ";")
							compSplicefactorpolcorrreal  = str2num(temporarystring)
					 		temporarystring = stringfromlist(3, compSplicefactors, ";")
							compSplicefactorpolcorrimag = str2num(temporarystring)
					
							compSplicefactor = cmplx(compSplicefactorreal, compSplicefactorimag)
							compSplicefactorPolCorr = cmplx(compSplicefactorpolcorrreal, compSplicefactorpolcorrimag)
							print "These are the SpliceFactors compSplicefactor and compSplicefactorpolcorr for R11 (spliceFilesPolCorr)",compSplicefactor, compSplicefactorpolcorr 
						endif
						
					endif
					if(numtype(REAL(compspliceFactor)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					if(numtype(REAL(compspliceFactorpolcorr)))
						print "ERROR while splicing into combineddataset (spliceFilesPolCorr)";abort
						
					endif
					//xmlfilecontQzR11, xmlfilecontRR11, xmlfilecontRPolCorrR11, xmlfilecontdRR11, xmlfilecontdRPolCorrR11, xmlfilecontdQzR11
					
					//(Comment from Andy:) think the following is wrong! No need to errors in quadrature if scalefactor does not depend on wavelength
					xmlfilecontdRR11 = (xmlfilecontdRR11/xmlfilecontRR11)^2
					xmlfilecontdRR11 += (imag(compSpliceFactor)/real(compSpliceFactor))^2
					xmlfilecontdRR11 = sqrt(xmlfilecontdRR11)
					xmlfilecontRR11 *= real(compSplicefactor)
					xmlfilecontdRR11 *= xmlfilecontRR11
					
					xmlfilecontdRPolCorrR11 = (xmlfilecontdRPolCorrR11/xmlfilecontRPolCorrR11)^2
					xmlfilecontdRPolCorrR11 += (imag(compspliceFactorpolcorr)/real(compspliceFactorpolcorr))^2
					xmlfilecontdRPolCorrR11 = sqrt(xmlfilecontdRPolCorrR11)
					xmlfilecontRPolCorrR11 *= real(compspliceFactorpolcorr)
					xmlfilecontdRPolCorrR11 *= xmlfilecontRPolCorrR11
				
					concatenate/NP {xmlfilecontRR11},tempRRR11
					concatenate/NP {xmlfilecontRPolCorrR11},tempRRPolCorrR11
					concatenate/NP {xmlfilecontQzR11},tempQQR11
					concatenate/NP {xmlfilecontdQzR11},tempDQR11
					concatenate/NP {xmlfilecontdRR11},tempDRR11
					concatenate/NP {xmlfilecontdRPolCorrR11},tempDRPolCorrR11
				
					sort tempQQR11,tempQQR11,tempRRR11,tempDRR11, tempRRPolCorrR11,tempDRPolCorrR11, tempDQR11 
				endif
				//close the XML file
				xmlsetattr(R11fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scale", num2str(real(compsplicefactor)))
				xmlsetattr(R11fileID, "//REFroot/REFentry[1]/REFdata/Run", "", "scalePolCorr", num2str(real(compsplicefactorpolcorr)))
				xmlclosefile(fileID, 1)
				R11fileID=0
			endif
			
		endfor
		
		if(!paramisdefault(rebin) && rebin > 0 && rebin < 15)
			print "(SpliceFilesPolCorr) List of all files after the for loop: filestosplice = ", filesToSplice
			Ffname = stringfromlist(0, filesToSplice, ":")
			print "(SpliceFilesPolCorr) List of first angle filenames: Ffname= ", Ffname
			if(stringmatch(stringfromlist(0, Ffname), "00")||stringmatch(stringfromlist(0, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I00 was not given to rebin_afterwards after the loop", Ffname
			else
				Pla_rebin_afterwardsPolCorr(tempQQR00, tempRRR00, tempDRR00, tempRRPolCorrR00, tempDRPolCorrR00, tempDQR00, rebin, tempQQR00[0] - 0.00005, tempQQR00[numpnts(tempQQR00) - 1]+0.00005)
				Wave W_Q_rebin, W_R_rebin, W_E_rebin, W_R_rebinpolcorr, W_E_rebinpolcorr, W_dq_rebin
				duplicate/o W_Q_rebin, tempQQR00
				duplicate/o W_R_rebin, tempRRR00
				duplicate/o W_E_rebin, tempDRR00
				duplicate/o W_R_rebinpolcorr, tempRRPolCorrR00
				duplicate/o W_E_rebinpolcorr, tempDRPolCorrR00
				duplicate/o W_dq_rebin, tempDQR00
			endif
			if(stringmatch(stringfromlist(1, Ffname), "00")||stringmatch(stringfromlist(1, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I01 was not given to rebin_afterwards after the loop", Ffname
			else
				Pla_rebin_afterwardsPolCorr(tempQQR01, tempRRR01, tempDRR01, tempRRPolCorrR01, tempDRPolCorrR01, tempDQR01, rebin, tempQQR01[0] - 0.00005, tempQQR01[numpnts(tempQQR01) - 1]+0.00005)
				Wave W_Q_rebin, W_R_rebin, W_E_rebin, W_R_rebinpolcorr, W_E_rebinpolcorr, W_dq_rebin
				duplicate/o W_Q_rebin, tempQQR01
				duplicate/o W_R_rebin, tempRRR01
				duplicate/o W_E_rebin, tempDRR01
				duplicate/o W_R_rebinpolcorr, tempRRPolCorrR01
				duplicate/o W_E_rebinpolcorr, tempDRPolCorrR01
				duplicate/o W_dq_rebin, tempDQR01
			endif	
			if(stringmatch(stringfromlist(2, Ffname), "00")||stringmatch(stringfromlist(2, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I10 was not given to rebin_afterwards after the loop", Ffname
			else
				Pla_rebin_afterwardsPolCorr(tempQQR10, tempRRR10, tempDRR10, tempRRPolCorrR10, tempDRPolCorrR10, tempDQR10, rebin, tempQQR10[0] - 0.00005, tempQQR10[numpnts(tempQQR10) - 1]+0.00005)
				Wave W_Q_rebin, W_R_rebin, W_E_rebin, W_R_rebinpolcorr, W_E_rebinpolcorr, W_dq_rebin
				duplicate/o W_Q_rebin, tempQQR10
				duplicate/o W_R_rebin, tempRRR10
				duplicate/o W_E_rebin, tempDRR10
				duplicate/o W_R_rebinpolcorr, tempRRPolCorrR10
				duplicate/o W_E_rebinpolcorr, tempDRPolCorrR10
				duplicate/o W_dq_rebin, tempDQR10
			endif	
			if(stringmatch(stringfromlist(3, Ffname), "00")||stringmatch(stringfromlist(3, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I11 was not given to rebin_afterwards after the loop", Ffname
			else
				Pla_rebin_afterwardsPolCorr(tempQQR11, tempRRR11, tempDRR11, tempRRPolCorrR11, tempDRPolCorrR11, tempDQR11, rebin, tempQQR11[0] - 0.00005, tempQQR11[numpnts(tempQQR11) - 1]+0.00005)
				Wave W_Q_rebin, W_R_rebin, W_E_rebin, W_R_rebinpolcorr, W_E_rebinpolcorr, W_dq_rebin
				duplicate/o W_Q_rebin, tempQQR11
				duplicate/o W_R_rebin, tempRRR11
				duplicate/o W_E_rebin, tempDRR11
				duplicate/o W_R_rebinpolcorr, tempRRPolCorrR11
				duplicate/o W_E_rebinpolcorr, tempDRPolCorrR11
				duplicate/o W_dq_rebin, tempDQR11
			endif	
		endif
		
		//write the Ref00.dat ascii file and xml file
		if(stringmatch(stringfromlist(0, Ffname), "00")||stringmatch(stringfromlist(0, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I00 was not given in", Ffname, "to write a file"
		else
			newpath/z/o/q pla_temppath_write, outputpathStr
			open/P=PLA_temppath_write/z=1 fileIDcomb as  newfnameI00 + ".dat"
			killpath/z pla_temppath_write
		
			if(V_flag)
				print "ERROR writing combined file R00 (splicefilesPolCorr)";	 abort
			endif
		
			fprintf fileIDcomb, "Q (1/A)\t Ref\t dRef (SD)\t RefPolCorr\t dRefPolCorr (SD)\t dq(FWHM, 1/A)\r"
			wfprintf fileIDcomb, "%g\t %g\t %g\t %g\t %g\t %g\r", tempQQR00, tempRRR00, tempDRR00, tempRRPolCorrR00, tempDRPolCorrR00, tempDQR00
			close fileIDcomb
			//now write a spliced XML file
			writeSpecRefXML1DPolCorr(outputPathStr, NewfnameI00, tempQQR00, tempRRR00, tempDRR00, tempRRPolCorrR00, tempDRPolCorrR00, tempDQR00, "", user, samplename, filestosplice, rednnote)
		
		endif
		//write the Ref01.dat ascii file and xml.file
		if(stringmatch(stringfromlist(1, Ffname), "00")||stringmatch(stringfromlist(1, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I01 was not given in", Ffname, "to write a file"
		else
			newpath/z/o/q pla_temppath_write, outputpathStr
			open/P=PLA_temppath_write/z=1 fileIDcomb as  newfnameI01 + ".dat"
			killpath/z pla_temppath_write
		
			if(V_flag)
				print "ERROR writing combined file R01 (splicefilesPolCorr)";	 abort
			endif
		
			fprintf fileIDcomb, "Q (1/A)\t Ref\t dRef (SD)\t RefPolCorr\t dRefPolCorr (SD)\t dq(FWHM, 1/A)\r"
			wfprintf fileIDcomb, "%g\t %g\t %g\t %g\t %g\t %g\r", tempQQR01, tempRRR01, tempDRR01, tempRRPolCorrR01, tempDRPolCorrR01, tempDQR01
			close fileIDcomb
			//now write a spliced XML file
			writeSpecRefXML1DPolCorr(outputPathStr, NewfnameI01, tempQQR01, tempRRR01, tempDRR01, tempRRPolCorrR01, tempDRPolCorrR01, tempDQR01, "", user, samplename, filestosplice, rednnote)
		
		endif
		//write the Ref10.dat ascii file
		if(stringmatch(stringfromlist(2, Ffname), "00")||stringmatch(stringfromlist(2, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I10 was not given in", Ffname, "to write a file"
		else
			newpath/z/o/q pla_temppath_write, outputpathStr
			open/P=PLA_temppath_write/z=1 fileIDcomb as  newfnameI10 + ".dat"
			killpath/z pla_temppath_write
		
			if(V_flag)
				print "ERROR writing combined file R10 (splicefilesPolCorr)";	 abort
			endif
		
			fprintf fileIDcomb, "Q (1/A)\t Ref\t dRef (SD)\t RefPolCorr\t dRefPolCorr (SD)\t dq(FWHM, 1/A)\r"
			wfprintf fileIDcomb, "%g\t %g\t %g\t %g\t %g\t %g\r", tempQQR10, tempRRR10, tempDRR10, tempRRPolCorrR10, tempDRPolCorrR10, tempDQR10
			close fileIDcomb
			//now write a spliced XML file
			writeSpecRefXML1DPolCorr(outputPathStr, NewfnameI10, tempQQR10, tempRRR10, tempDRR10, tempRRPolCorrR10, tempDRPolCorrR10, tempDQR10, "", user, samplename, filestosplice, rednnote)
		
		endif
		//write the Ref11.dat ascii file
		if(stringmatch(stringfromlist(3, Ffname), "00")||stringmatch(stringfromlist(3, Ffname), "0"))
				print "(SpliceFilesPolCorr) The File for REF I11 was not given in", Ffname, "to write a file"
		else
			newpath/z/o/q pla_temppath_write, outputpathStr
			open/P=PLA_temppath_write/z=1 fileIDcomb as  newfnameI11 + ".dat"
			killpath/z pla_temppath_write
		
			if(V_flag)
				print "ERROR writing combined file R11 (splicefilesPolCorr)";	 abort
			endif
		
			fprintf fileIDcomb, "Q (1/A)\t Ref\t dRef (SD)\t RefPolCorr\t dRefPolCorr (SD)\t dq(FWHM, 1/A)\r"
			wfprintf fileIDcomb, "%g\t %g\t %g\t %g\t %g\t %g\r", tempQQR11, tempRRR11, tempDRR11, tempRRPolCorrR11, tempDRPolCorrR11, tempDQR11
			close fileIDcomb
			//now write a spliced XML file
			writeSpecRefXML1DPolCorr(outputPathStr, NewfnameI11, tempQQR11, tempRRR11, tempDRR11, tempRRPolCorrR11, tempDRPolCorrR11, tempDQR11, "", user, samplename, filestosplice, rednnote)
		
		endif

	catch
		if(R00fileID)
			xmlclosefile(R00fileID,0)
		endif
		if(R01fileID)
			xmlclosefile(R01fileID,0)
		endif
		if(R10fileID)
			xmlclosefile(R10fileID,0)
		endif
		if(R11fileID)
			xmlclosefile(R11fileID,0)
		endif
		if(r00fileID)
			close R00fileID
		endif
		if(R01fileID)
			close R01fileID
		endif
		if(R10fileID)
			close R10fileID
		endif
		if(R11fileID)
			close R11fileID
		endif
		err=1
		print "ERROR: something went wrong in (spliceFilesPolCorr)"
	endtry
	print "(SpliceFilesPolCorr) reached the end of the function"
	setdatafolder $cDF
	killdatafolder/z 	root:packages:platypus:data:reducer:temp
	return err
End

Function/t Pla_GetWeightScOPolCorr(wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr)
	Wave wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr, wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr	//1 = first dataset, 2= second dataset

	variable ii, npnts1, npnts2, num2
	string compSplicefactor
	sort wave1q,wave1q,wave1R, wave1dR,wave1RPolCorr, wave1dRPolCorr
	sort wave2q,wave2q,wave2R, wave2dR, wave2RPolCorr, wave2dRPolCorr
	
	npnts1 = dimsize(wave1q, 0)
	npnts2 = dimsize(wave2q, 0)
	
	if(wave2q[0] > wave1q[npnts1 - 1])
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling. (Pla_GetWeightScOPolCorr)"
		compsplicefactor = "NaN; NaN; NaN; NaN"
		return compSplicefactor //cmplx(NaN, NaN)
	endif
	
	make/u/I/free/n=0 overlapPoints

	for(ii = 0 ;  ii < dimsize(wave2q, 0) && wave2q[ii] < wave1q[npnts1 - 1] ; ii+=1)
		if(wave2q[ii] > wave1q[0] && wave2q[ii] < wave1q[npnts1 - 1])
			redimension/n=(numpnts(overlapPoints) + 1) overlapPoints
			overlapPoints[numpnts(overlapPoints) - 1] = ii
		endif
	endfor
	
	num2 = numpnts(overlapPoints)
	if(!num2)
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling. (Pla_GetWeightScOPolCorr)"
		compsplicefactor = "NaN; NaN; NaN; NaN"
		return compSplicefactor //cmplx(NaN, NaN)
	endif	
	////////////////////////////////////
	
	Variable ival1, newi, newdi, ratio, dratio, newpolcorri, newdpolcorri, ratiopolcorr, dratiopolcorr, qval2
	make/n=(num2)/d/free W_scalefactor, W_dScalefactor, W_scalefactorPolCorr, W_dScalefactorPolCorr
		
	for(ii = 0 ; ii < num2 ; ii += 1)
		//get scaling factor at each point of wave 2 in the overlap region
		qval2 = wave2q[overlapPoints[ii]]
		newi = interp(qval2, wave1q, wave1R)	//get the intensity of wave1 at an overlap point
		newpolcorri = interp(qval2, wave1q, wave1RPolCorr)		
		newdi = interp(qval2, wave1q, wave1dR)
		newdpolcorri = interp(qval2, wave1q, wave1dRPolCorr)
		
		if(!numtype(wave2R[ii]) && !numtype(newi) && !numtype(newdi) && !numtype(wave2RPolCorr[ii]) && !numtype(newPolCorri) && !numtype(newdPolCorri)&& wave2R[ii] != 0&& wave2RPolCorr[ii] != 0)
			W_scalefactor[ii] = newi/wave2R[ii]
			W_dScalefactor[ii] = W_scalefactor[ii]* sqrt((newdi/newi)^2 + (wave2dr[ii]/wave2r[ii])^2)
			W_scalefactorPolCorr[ii] = newPolCorri/wave2RPolCorr[ii]
			W_dScalefactorPolCorr[ii] = W_scalefactorPolCorr[ii]* sqrt((newdPolCorri/newPolCorri)^2 + (wave2drPolCorr[ii]/wave2rPolCorr[ii])^2)
		endif
		
	endfor
	
	W_dScalefactor = 1/(W_dScalefactor^2)
	W_dScalefactorPolCorr = 1/(W_dScalefactorPolCorr^2)
	
	variable normal, num = 0, den=0, dnormal, normalpolcorr, numpolcorr = 0, denpolcorr=0, dnormalpolcorr
	for(ii=0 ; ii < num2 ; ii += 1)
		if(!numtype(W_scalefactor[ii]) && !numtype(W_dscalefactor[ii]))
			num += W_scalefactor[ii] * W_dscalefactor[ii] 
			den += W_dscalefactor[ii]
		endif
		if(!numtype(W_scalefactorPolCorr[ii]) && !numtype(W_dscalefactorPolCorr[ii]))
			numpolcorr += W_scalefactorPolCorr[ii] * W_dscalefactorPolCorr[ii] 
			denpolcorr += W_dscalefactorPolCorr[ii]
		endif
	endfor
	
	normal = num/den
	dnormal = sqrt(1/den)
	normalpolcorr = numpolcorr/denpolcorr
	dnormalpolcorr = sqrt(1/denpolcorr)
	
	if(numtype(normal))
		print "ERROR while splicing (Pla_GetWeightScOPolCorr)"
	endif
	if(numtype(normalpolcorr))
		print "ERROR while splicing (Pla_GetWeightScOPolCorr)"
	endif
	sprintf compSplicefactor, "%g; %g; %g; %g;", normal, dnormal, normalpolcorr, dnormalpolcorr
	
	Return compSplicefactor //cmplx(normal, dnormal)
End

Function Pla_rebin_afterwardsPolCorr(qq,rr, dr,rrpolcorr, drpolcorr, dq, rebin, lowerQ,upperQ)
Wave qq,rr,dr, rrpolcorr, drpolcorr, dq
variable rebin, lowerQ, upperQ
//this function rebins a set of R vs Q data given a rebin percentage.
//it is designed to replace rebinning the wavelength spectrum which can result in twice as many points in the overlap region.
//However, the background subtraction is currently done on rebinned data. So if you don't rebin at the start the  subtraction
//isn't as good.
	variable stepsize, numsteps, ii, binnum, weight, weightpolcorr

	rebin =  1 + (rebin/100)
	stepsize = log(rebin)
	numsteps = log(upperQ / lowerQ) / stepsize

	make/n=(numsteps + 1)/o/d W_q_rebin, W_R_rebin, W_E_rebin, W_R_rebinPolCorr, W_E_rebinPolCorr, W_dq_rebin
	W_q_rebin = 0
	W_R_rebin = 0
	W_E_rebin = 0
	W_R_rebinPolCorr = 0
	W_E_rebinPolCorr = 0
	W_dq_rebin = 0

	make/n=(numsteps + 2)/free/d W_q_rebinHIST
	make/n=(numsteps + 1)/d/free Q_sw, I_sw, E_sw, I_swPolCorr, E_swPolCorr

	W_q_rebinHIST[] = alog( log(lowerQ) + (p-0.5) * stepsize)

	for(ii = 0 ; ii < numpnts(qq) ; ii += 1)
		binnum = binarysearch(W_q_rebinHIST, qq[ii])
		if(binnum < 0)
			continue
		endif
		 weight = 1 / (dR[ii]^2)
		 weightpolcorr = 1 / (dRpolcorr[ii]^2)
		 
		W_R_rebin[binnum] += RR[ii] * weight
		W_R_rebinPolCorr[binnum] += RRPolCorr[ii] * weightpolcorr
		W_q_rebin[binnum] += qq[ii] * weightpolcorr
		W_dq_rebin[binnum] += dq[ii] * weightpolcorr
		Q_sw[binnum] += weightpolcorr
		I_sw[binnum] += weight
		I_swpolcorr[binnum] += weightpolcorr
	endfor
	W_R_rebin[] /= I_sw[p]
	W_R_rebinpolcorr[] /= I_swpolcorr[p]
	W_q_rebin[] /= Q_sw[p]
	W_E_rebin[] = sqrt(1/I_sw[p])
	W_E_rebinpolcorr[] = sqrt(1/I_swpolcorr[p])
	W_dq_rebin[] /= Q_sw[p]
	
	for(ii = numpnts(W_q_rebin) - 1 ; ii >= 0 ; ii -= 1)
		if(numtype(W_q_Rebin[ii]))
			deletepoints ii, 1, W_q_rebin, W_R_rebin, W_E_rebin, W_R_rebinPolCorr, W_E_rebinPolCorr, W_dq_rebin
		endif
	endfor
	//In the output this should appear for each additional angle 
	print "(Pla_rebin_afterwardsPolCorr) is finished"
	
End


Function SLIM_plot_reducedPolCorr(inputPathStr, filenames)
	string inputPathStr, filenames
	variable ii,numwaves,jj
	string loadedWavenames, slimplotstring
	string cDF = getdatafolder(1)

	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o root:packages:platypus:data:Reducer
	newdatafolder/o/s root:packages:platypus:data:Reducer:SLIM_plot

	GetFileFolderInfo/q/z inputpathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (SLIM_plot_reducedPolCorr)"
		return 1
	endif
	
	try
		dowindow/k SLIM_PLOTwin
		display/K=1 as "SLIM plot PolCorr (C) Andrew Nelson + ANSTO 2008 + Thomas Saerbeck 2012"
		dowindow/c SLIM_PLOTwin
		controlbar/W=SLIM_PLOTwin 30
		button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOTPolCorr,title="Refresher",size={100,20}, fColor=(0,52224,26368)
	
		sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\", 0, 0, 0)", inputpathStr, inputpathStr, fileNames
		setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
		setwindow SLIM_PLOTwin, userdata(filenames) = filenames
		setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr		

		for(ii = 0 ; ii < itemsinlist(filenames) ; ii += 1)
			string fname = stringfromlist(ii, filenames)

			variable fileID = xmlopenfile(inputPathStr + fname)
			if(fileID < 1)
				print "ERROR opening xml file (SLIM_PLOT_reduced)"
				abort
			endif
			fname = removeending(fname,".xml")
			
			xmlwavefmXPATH(fileID,"//Qz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_q",0)
			Wave qq = $cleanupname(fname+"_q",0)
			qq = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//R","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_R",0)
			Wave RR = $cleanupname(fname+"_R",0)
			RR = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//RPolCorr","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_RPolCorr",0)
			Wave RRPolCorr = $cleanupname(fname+"_RPolCorr",0)
			RRPolCorr = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//dR","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_E",0)
			Wave EE = $cleanupname(fname+"_E",0)
			EE = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//dRPolCorr","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_EPolCorr",0)
			Wave EEPolCorr = $cleanupname(fname+"_EPolCorr",0)
			EEPolCorr = str2num(M_xmlcontent[p][0])
				
			xmlwavefmXPATH(fileID,"//dQz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_dq",0)
			Wave dq = $cleanupname(fname+"_dq",0)
			dq = str2num(M_xmlcontent[p][0])
			
			sort qq,qq,RR,RRPolCorr,EE,EEPolCorr,dQ
			xmlclosefile(fileID,0)
			
			//			LoadWave/J/D/A/W/P=path_to_data/K=0 stringfromlist(ii,filenames)
			//			loadedWavenames = S_wavenames
			//			duplicate/o $(stringfromlist(0,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_q")
			//			duplicate/o $(stringfromlist(1,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_R")
			//			duplicate/o $(stringfromlist(2,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_E")
			//			duplicate/o $(stringfromlist(3,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_dq")
			//			Wave qq = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_q")
			//			Wave RR = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_R")
			//			Wave EE = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_E")
			//			Wave dq = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_dq")
			appendtograph/w=SLIM_PLOTwin RR vs qq
			ErrorBars/T=0 $nameofwave(RR) Y,wave=(EE,EE)
			appendtograph/w=SLIM_PLOTwin RRPolCorr vs qq
			ErrorBars/T=0 $nameofwave(RRPoLCorr) Y,wave=(EEPolCorr,EEPolCorr)
			ModifyGraph log(left)=1 //1
			SetAxis left, 0.0000001, 3 // -0.1, 0.1  //
			Variable n = 72*15/2.54
			Variable m =  72*25/2.54
			ModifyGraph width=m, height = n
			//ModifyGraph expand=2
			killwaves/z M_xmlcontent,W_xmlcontentnodes
			//			for(jj=0 ; jj<itemsinlist(loadedWavenames);jj+=1)
			//				killwaves/z $(stringfromlist(jj,loadedwavenames))
			//			endfor
		endfor
		CommonColors("SLIM_PLOTwin")
		Legend/C/N=text0/A=RT
		cursor/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,tracenamelist("SLIM_PLOTwin",";",1))) 0.5,0.5
		showinfo
		setdatafolder $cDF
		return 0
	catch
		setdatafolder $cDF
		return 0
	endtry
End

Function SLIM_plotPolCorr(inputpathStr, outputPathStr, fileNames,lowlambda,highLambda, background, [expected_peak, rebinning, manual, normalise, saveSpectrum])
	String inputpathStr, outputPathStr, fileNames
	variable lowlambda, highlambda, background, rebinning, manual, normalise, saveSpectrum
	variable/c expected_peak
	inputpathStr = outputPathStr
	string slimplotstring = ""
	if(paramisdefault(expected_peak))
		expected_peak = cmplx(ROUGH_BEAM_POSITION, NaN)
	endif
			
	if(paramisdefault(manual))
		manual = 0
	endif
	if(paramisdefault(normalise))
		normalise = 0
	endif
	if(paramisdefault(saveSpectrum))
		saveSpectrum = 0
	endif

	GetFileFolderInfo/q/z inputPathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid input path (SLIM_plotPolCorr)"
		return 1	
	endif

	variable ii
	string tempDF,tempFileNameStr
	
	for(ii=0 ; ii<itemsinlist(filenames) ; ii += 1)
		tempFileNameStr = stringfromlist(ii, fileNames)
		
		//trying to plot reduced data
		if(stringmatch(".xml",tempfilenamestr[strlen(tempfilenamestr)-4,strlen(tempfilenamestr)-1]))
			if(SLIM_plot_reducedPolCorr(inputPathStr, filenames))
				print "ERROR while trying to plot reduced data (SLIM_plotPolCorr)"
				return 1
			endif
			return 0
		endif
		
		if(stringmatch(".itx",tempfilenamestr[strlen(tempfilenamestr)-4,strlen(tempfilenamestr)-1]))
			if(SLIM_plot_scans(inputPathStr, filenames))
				print "ERROR while trying to plot reduced data (SLIM_plotPolCorr)"
				return 1
			endif
			return 0
		endif

		if(stringmatch(".spectrum", tempfilenamestr[strlen(tempfilenamestr) - 9, strlen(tempfilenamestr) - 1]))	
			if(SLIM_plot_spectrum(inputPathStr, filenames))
				print "ERROR while trying to plot spectrum data (SLIM_plotPolCorr)"
				return 1
			endif
			return 0
		endif
				
		if(stringmatch(".xrdml",tempfilenamestr[strlen(tempfilenamestr)-6,strlen(tempfilenamestr)-1]))	
			if(SLIM_plot_xrdml(inputPathStr, filenames))
				print "ERROR while trying to plot XRDML data (SLIM_plotPolCorr)"
				return 1
			endif
			return 0
		endif
		
		//now try to plot NeXUS data
		if(!stringmatch(".nx.hdf", tempfilenamestr[strlen(tempfilenamestr)-7,strlen(tempfilenamestr)-1]))
			Doalert 0, "ERROR: this isn't a NeXUS file (SLIM_plotPolCorr)"
			return 1
		endif
		tempFileNameStr = removeending(stringfromlist(ii,fileNames),".nx.hdf")
		
		GetFileFolderInfo/q/z outputPathStr
		if(V_flag)//path doesn't exist
			print "ERROR please give valid output path as well (SLIM_plotPolCorr)"
			return 1	
		endif
	
		if(paramisdefault(rebinning) || rebinning <= 0)
			if(processNeXUSfile(inputPathStr, outputPathStr, tempFileNameStr, background, lowLambda, highLambda, expected_peak=expected_peak, manual=manual, normalise = normalise, savespectrum = saveSpectrum))
				print "ERROR: problem with one of the files you are trying to open (SLIM_plotPolCorr)"
				return 1
			endif
		else
			Wave W_rebinboundaries = Pla_gen_binboundaries(lowlambda, highlambda, rebinning)
			if(processNeXUSfile(inputPathStr, outputPathStr, tempFileNameStr, background, lowLambda, highLambda, expected_peak=expected_peak, rebinning=W_rebinboundaries,manual=manual, normalise = normalise, savespectrum = saveSpectrum))
				print "ERROR: problem with one of the files you are trying to open (SLIM_plotPolCorr)"
				return 1
			endif		
		endif
	endfor

	//tempDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(filename,".nx.hdf"),0)
	//this datafolder should have:
	//1) M_topAndTail
	//2) M_topandtailSD
	//3) W_spec
	//4) W_specSD
	//5) W_specTOF
	//6) W_specTOFHIST
	//7) W_lambda
	//8) W_lambdaSD
	//9) W_lambdaHIST
	//and (optionally)
	//10) W_ref
	//11) W_refSD
	//12) W_q
	//13) W_qSD

	killwaves/z W_rebinboundaries
	//make a graph called SLIM_PLOT
	dowindow/k SLIM_PLOTwin
	display/K=1/W=(30,0,600,350) as "SLIM plot (C) Andrew Nelson + ANSTO 2008 + Thomas Saerbeck 2012"
	dowindow/c SLIM_PLOTwin
	setwindow SLIM_PLOTwin, userdata(filenames) = filenames
	setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr
	
	sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\",%g, %g, %d, expected_peak = cmplx(%g, %g), rebinning=%g, manual=%d, normalise=%d, saveSpectrum=%d)", inputpathStr, outputPathStr, fileNames,lowlambda,highLambda, background, real(expected_peak), imag(expected_peak), rebinning, manual, normalise, saveSpectrum
	setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
	
	controlbar/W=SLIM_PLOTwin 30
	popupmenu/z graphtype,win=SLIM_PLOTwin, bodyWidth=160,proc=popup_SLIM_PLOT
	popupmenu/z graphtype,win=SLIM_PLOTwin, value="SPEC vs Lambda;SPEC vs TOF;Detector vs Lambda;Detector vs TOF;Ref vs Q;Ref vs Lambda;Ref vs TOF"
	checkbox/z isLog,win=SLIM_PLOTwin, title="LOG?",pos={169,5},proc=checkBox_SLIM_PLOT
	button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOTPolCorr,title="Refresh",pos = {228,3},size={100,20}, fColor=(0,52224,26368)
	//	button getimagelineprofile,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Line Profile",pos = {340,3},size={100,20} 
	if(SLIM_redisplay(0,0))
		print "ERROR while trying to redisplay (SLIM_plotPolCorr)"
		return 1
	endif
End


Function button_SLIM_PLOTPolCorr(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR lowLambda = root:packages:platypus:data:Reducer:lowLambda
	NVAR highLambda = root:packages:platypus:data:Reducer:highLambda
	Wave/t angledata_list = root:packages:platypus:data:Reducer:angledata_list
	NVAR rebinpercent = root:packages:platypus:data:Reducer:rebinpercent
	SVAR inputPathStr = root:packages:platypus:data:Reducer:inputPathStr
	SVAR outputPathStr = root:packages:platypus:data:Reducer:outputPathStr
	NVAR backgroundsbn =  root:packages:platypus:data:Reducer:backgroundsbn
	NVAR manualbeamfind =  root:packages:platypus:data:Reducer:manualbeamfind
	NVAR normalisebymonitor = root:packages:platypus:data:Reducer:normalisebymonitor
	NVAR saveSpectrum =  root:packages:platypus:data:Reducer:saveSpectrum
	
	variable background,isLOG,type, rebinning
	string fileNames = "", pathStr = "", slimplotstring = ""

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlname)
				case "refresh":
					filenames = GetUserData("SLIM_PLOTwin","","filenames")
					print filenames, "here should be the filenames (button_SLIM_PLOTPolCorr(ba))"
					pathStr = GetUserData("SLIM_PLOTwin","","pathStr")
					slimplotstring = GetUserData("SLIM_PLOTwin","","slimplotstring")
					print slimplotstring
					controlinfo/w=SLIM_PLOTwin isLog
					isLog = V_Value
					controlinfo graphtype
					type = V_Value-1			
					rebinning = rebinpercent

					//	execute/q slimplotstring
					SLIM_plotPolCorr(pathStr, pathStr, fileNames,lowLambda,highLambda, backgroundsbn, rebinning = rebinning, normalise = normalisebymonitor, saveSpectrum = saveSpectrum, manual = manualbeamfind)
					if(!stringmatch(stringfromlist(0,filenames),"*.xml") && !stringmatch(stringfromlist(0,filenames),"*.xrdml") && !stringmatch(stringfromlist(0,filenames),"*.spectrum"))
						SLIM_redisplay(type,isLog)
					endif
					break
				case "getimagelineprofile":
					WMCreateImageLineProfileGraph();
					break
			endswitch
			break
	endswitch
	return 0
End



































 	


#pragma rtGlobals=3		// Use modern global access method.
#pragma IgorVersion = 6.2

//This procedure contains the reduction functions copied mainly from the existing SLIM code for unpolarized reduction. 
//The additional polarization correction of the recorded spectra is contained in the procedure "Pla_reductionPOLCORRECT" 
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
// NSF means non-spin-flip (00 = downdown, 11 =upup)
// SF means spin-flip
// I00, I01, I10, I11 are the measured reflected intensities, i.e. reflected spectra or reflectivities
// DB00, DB01, DB10, DB11 are the direct beams
// I00 means OFF OFF = R--
// I01 means OFF ON = R-+
// I10 means ON OFF = R+-
// I11 means ON ON = R++
// There need to be 8 entries to fully specify a measurement at ONE angle in FOUR polarization channels with four direct beams
// Missing files, polarization channels of relected spectra or direct beams that have not beam measured are replaced with "00" (measurement with analyzer) or "0" (measurment without analyzer)
// The order of FUNCTION INPUT of the runfilenames has to be 00,01,10,11, otherwise, the channels can be mixed up, which will lead to wrong results.
// See the below test function for a typical FUNCTION INPUT structure

// Handling COMMENTS 
// The code relies on accurate input parameters (00,01,10,11) in order to figure out which mode the reflected spectra and direct beam spectra are measured in. 
// The input of the filenumbers has to be in full, i.e. PLP0006640. Omitting of the leading 0's is NOT allowed.
// The runfilenames input to function PolarizedReduction contains MULTIPLES of 8 entries, each for a different angle measured. 
// Structure is OFFOFF;OFFON;ONOFF;ONON;DBOFFOFF;DBOFFON;DBONOFF;DBONON : OFFOFF;OFFON;ONOFF;ONON;DBOFFOFF;DBOFFON;DBONOFF;DBONON : OFFOFF;OFFON;ONOFF;ONON;DBOFFOFF;DBOFFON;DBONOFF;DBONON
// NOTE THE ":" separating the different angles measured 
// You cannot process more than 1 measurement at the time, i.e. you cannot give the same anlges.  
// In case a particular channel has not been recorded, the filenumber is to be replaced with "00" (measurement with analyzer and polarizer) or "0" (measurement without the analyzer)
//	A) REFLECTIVITY MODES: 
//	1) All four reflectivity channels have been recorded. = "FULL"
// 	2) ONLY NSF channels have been recorded with Polarizer and Analyzer being used. ("00" for missing entries) = "NSF"
//	3) ONLY ONE of the SF channels has been recorded, you can decide which one in the testPolRed below. ("00" for missing entries).  = "R01" or "R10"
//	4) No Analyzer in the beam, ONLY I0 and I1 are recorded ("0" for missing entries) = "R0R1"
//	5) No Reflectivity is calculated, only reduced and polarization corrected spectra are given out ("00" for missing entries, or you can leave the DB blank) = "Spectra"

//     B) DIRECT BEAMS: 
//     1) The spin flipper, either ON or OFF, do NOT change the shape of the spectrum, therefore it is up to the user to provide only DB00 or DB11 or both.	
//	 2) If all four DB channels are provided, a full polarization correction of DB is performed -- I00 and I01 will be divided by DB00 -- I11 and I10 will be divided by DB11 
//	 3) As one can see in 2), the convention is taken to divide the spectra by the corresponding direct beam with the same INCIDENT POLARIZATION. 
//	 4) If three DB channels (i.e. the two NSF and one SF) are provided, the reduced form of polarization correction is performed -- I00 and I01 will be divided by DB00 -- I11 and I10 will be divided by DB11 ("00" for missing entries)
// 	 5) If only one DB has been recorded, the polarization correction will only be a scaling with the efficiency function ("00" for missing entries)
//	 6) If you do not want to make a polarization correction on the direct beams (for whatever reason), give the same entry for DB00 and DB11 (here only one DB file is possible) ("00" for missing entries)
//	 7) If you do not want to produce a reflectivity, but are merely interested in the pectra, either provide "00" on all entries of the DB, or leave them ALL blank

 
Function testPolRed(cases)
	//This function performs an example redution of polarized data on the example of the polarized reflectivity from Cr(20Å)/Ni80Fe20(300Å)/Si.
	// NOTE: The measurement has been recorded using all four elements. The old flipper settings etc.!!!  
	//The options are: cases = "Full" ; "NSF" ; "R01" ; "R10" ; "R0R1" ; "Spectra"
	//The data is recorded in three angles: 0.4°, 1.0°, 2.5°
	//The files you need are:
	//"PLP0006737;PLP0006743;PLP0006740;PLP0006734;PLP0006640;PLP0006726;PLP0006717;PLP0006675:PLP0006738;PLP0006744;PLP0006741;PLP0006735;PLP0006641;PLP0006727;PLP0006718;PLP0006676:PLP0006739;PLP0006745;PLP0006742;PLP0006736;PLP0006642;PLP0006728;PLP0006719;PLP0006677"
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

Menu "Platypus"
	Submenu "SLIM"
		"Polarized Reduction", reducerpanelPOL()
	End
End

Function PolarizedReduction(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, runfilenames, lowLambda, highLambda, rebin, [water, background, expected_peak, manual, dontoverwrite, normalise, saveSpectrum, saveoffspec, verbose])
	// This Function should be called from the Graphical user interface
	// It takes the functionality of the original function "reduce" in unpolarized reduction
	// FIRST "reducepol" is called for each set of angles
	// The output of reducepol is a list of the polarization corrected and reduced filenames (i.e. they are now a reflectivity), these are also written to the outputpathstring
	// SECOND: spliceFilesPolCorr is called to stitch all the angles given in runfilenames together.
	string inputPathStr, outputPathStr //specify where the input files can be found or the output shall be written 
	//e.g. "C:platypus:My Documents:Desktop:data:", "C:platypus:My Documents:Desktop:data:output:"
	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11 //Data is divided by this variable
	//Each input reflected spectra has to be given its own scaling. The reason being that in if the scaling of the R00 and R11, i.e. the two NSF channels, is different (for example at the critical edge), this would give a wrong polarization correction. 
	// For ease of data manipulation, the two SF channels can also be individually scaled. In general, the R01 channel should have the scaling of R00. R10 should have the scaling of R11. (Scaled on incident polarization)  
	string runfilenames //runfilenames contains blocks of 8, the first four entries are full filenames of the reflected spectra, the next four are the full filenames of the direct beams
	//different polarization channels are separated by ";" (Semicolon) different angles of incidence are separated by ":" (Colon)
	// firstI00;firstI01;firstI10;firstI11;firstDB00;firstDB01;firstDB10;firstDB11:secondI00;secondI01;secondI10;secondI11;secondDB00;secondDB01;secondDB10;secondDB11
	variable lowLambda,highLambda, rebin //variables specifying the low wavelength cutoff, the high wavelength cutoff and the rebin percentage, e.g. 3 for 3% dq/q rebinning
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
	
	NVAR expectedcentre=root:packages:platypus:data:Reducer:expected_centre
	if(expectedcentre<20)
		expectedcentre = 144
		//root:packages:platypus:data:Reducer:expected_centre = 144
	endif
	if(verbose)
		print "Executing function with extended explanations"
	endif	
	string cDF, toSplice=""
	string  fname, cmd = "", thePair, ifname, newfnameI00, newfnameI01, newfnameI10, newfnameI11, newfnameI00PolCorr, newfnameI01PolCorr, newfnameI10PolCorr, newfnameI11PolCorr, Tfname , Ffname, PolChannelsfname="" 
	variable ii, spliceFactor, numpairs, spectras, numfiles
	spectras = 1
	cDF = getdatafolder(1)	
	try
		numpairs = itemsinlist(runfilenames, ":")
		if(paramisdefault(verbose))
			verbose = 1
		endif
		if(verbose)
			print "(PolarizedReduction) This is the number of Angles that will be processed: numpairs = ", numpairs //This is the number of Angles that will be processed
		endif
		if(numpairs==0)
			print "ERROR: No filenames given, no reduction taking place (PolarizedReduction)!"; abort
		endif
		for(ii = 0 ; ii < numpairs ; ii += 1)
			thePair = stringfromlist(ii, runfilenames, ":") 
			print "(PolarizedReduction) this is the input to reducepol (", thepair ," ) for angle ", ii
			ifname = reducepol(inputPathStr, outputPathStr, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, thePair, lowLambda, highLambda, rebin, water = water, background=background, expected_peak=expected_peak, manual=manual, dontoverwrite=dontoverwrite, normalise=normalise, saveSpectrum=saveSpectrum, saveoffspec=saveoffspec, verbose=verbose)
			if(strlen(ifname) == 0)
				print "ERROR whilst calling reducepol (PolarizedReduction)"
				abort
			elseif(stringmatch(ifname, "spectra"))
				print "NO DIRECT BEAMS WERE ENTERED to reducepol. NO REFLCETIVITY is produced.(PolarizedReduction)"
				spectras  = 0
			else
			//The output of reducepol is gathered in tosplice with a structure similar to runfilenames, i.e. datasets are separated by ";" and angles separated by ":"
				toSplice += ifname + ":"
			
			endif
		endfor
		if(!spectras)
			print "The outputs are the polarization corrected spectra only.(PolarizedReduction)"
			setdatafolder $cDF
			return 0
		endif
		toSplice = RemoveEnding(toSplice, ":")
		if(verbose)
			print "(Polarized Reduction) This is what comes out of reducepol (toSplice = )", toSplice
		endif
		if(dontoverwrite)
			
			Tfname = stringfromlist(0, toSplice, ":") //Takes the first angle of the files that comes out of reducepol for loop
			newfnameI00 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(0, Tfname, ";"), ".xml")
			newfnameI01 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(1, Tfname, ";"), ".xml")
			newfnameI10 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(2, Tfname, ";"), ".xml")
			newfnameI11 =  uniqueFileName(outputPathStr, "c_" + stringfromlist(3, Tfname, ";"), ".xml")
			newfnameI00PolCorr =  uniqueFileName(outputPathStr, "c_" + stringfromlist(0, Tfname, ";")+"PolCorr", ".xml")
			newfnameI01PolCorr =  uniqueFileName(outputPathStr, "c_" + stringfromlist(1, Tfname, ";")+"PolCorr", ".xml")
			newfnameI10PolCorr =  uniqueFileName(outputPathStr, "c_" + stringfromlist(2, Tfname, ";")+"PolCorr", ".xml")
			newfnameI11PolCorr =  uniqueFileName(outputPathStr, "c_" + stringfromlist(3, Tfname, ";")+"PolCorr", ".xml")
		else
			Tfname = stringfromlist(0, toSplice, ":")
			newfnameI00 =  "c_" +stringfromlist(0, Tfname, ";")
			newfnameI01 =  "c_" +stringfromlist(1, Tfname, ";")
			newfnameI10 =  "c_" +stringfromlist(2, Tfname, ";")
			newfnameI11 =  "c_" +stringfromlist(3, Tfname, ";")
			newfnameI00PolCorr =  "c_" +stringfromlist(0, Tfname, ";")+"PolCorr"
			newfnameI01PolCorr =  "c_" +stringfromlist(1, Tfname, ";")+"PolCorr"
			newfnameI10PolCorr =  "c_" +stringfromlist(2, Tfname, ";")+"PolCorr"
			newfnameI11PolCorr =  "c_" +stringfromlist(3, Tfname, ";")+"PolCorr"
		endif
		//PolChannelsfname contains the new names of the datasets which is passed to spliceFilesPolCorr
		//tosplice = filesToSplice contains a list of the polarization corrected spectra, 4 individual channels are separated by ";" while angles are separated by ":" (as many angles as measured)
		PolChannelsfname = 	newfnameI00 + ";" + newfnameI01 + ";" + newfnameI10 + ";" + newfnameI11
		string filenameoutputI00="", filenameoutputI01="", filenameoutputI10="", filenameoutputI11=""
		string filenameoutputI00polcorr="", filenameoutputI01polcorr="", filenameoutputI10polcorr="", filenameoutputI11polcorr=""  
		if(itemsinlist(toSplice, ":") > 1)
			numfiles = itemsinlist(toSplice, ":")
			for(ii = 0 ; ii < itemsinlist(toSplice, ":") ; ii += 1)
				//if(verbose)
				//	print "(PolarizedReduction) This is the first step of the for loop (it will be repeated): All files to be spliced", toSplice
				//endif
				Ffname = stringfromlist(ii, toSplice, ":")
				if(verbose)
					print "(Polarized Reduction) These are the datasets in angle "ii": Ffname = ", Ffname
				endif
				if(stringmatch(stringfromlist(0, Ffname), "00")||stringmatch(stringfromlist(0, Ffname), "0"))
					if(verbose)
						print "The File for REF I00 was not given in (loop ii, Ffname) pos 0 (spliceFilesPolCorr)", ii, Ffname
					endif
				else
					filenameoutputI00 += stringfromlist(0, Ffname) + ";"
					filenameoutputI00polcorr += stringfromlist(0, Ffname) + "PolCorr" + ";"
				endif
				if(stringmatch(stringfromlist(1, Ffname), "00")||stringmatch(stringfromlist(1, Ffname), "0"))
					if(verbose)
						print "The File for REF I01 was not given in (loop ii, Ffname) pos 1 (spliceFilesPolCorr)", ii, Ffname
					endif
				else
					filenameoutputI01 += stringfromlist(1, Ffname) + ";"
					filenameoutputI01polcorr += stringfromlist(1, Ffname) + "PolCorr" + ";"
				endif
				if(stringmatch(stringfromlist(2, Ffname), "00")||stringmatch(stringfromlist(2, Ffname), "0"))
					if(verbose)
						print "The File for REF I10 was not given in (loop ii, Ffname) pos 2 (spliceFilesPolCorr)", ii, Ffname
					endif
				else
					filenameoutputI10 += stringfromlist(2, Ffname) + ";"
					filenameoutputI10polcorr += stringfromlist(2, Ffname) + "PolCorr" + ";"
				endif
				if(stringmatch(stringfromlist(3, Ffname), "00")||stringmatch(stringfromlist(3, Ffname), "0"))
					if(verbose)
						print "The File for REF I11 was not given in (loop ii, Ffname) pos 3 (spliceFilesPolCorr)", ii, Ffname
					endif
				else
					filenameoutputI11 += stringfromlist(3, Ffname) + ";"
					filenameoutputI11polcorr += stringfromlist(3, Ffname) + "PolCorr" + ";"
				endif

			endfor			
			filenameoutputI00 = RemoveEnding(filenameoutputI00, ";")
			filenameoutputI01 = RemoveEnding(filenameoutputI01, ";")
			filenameoutputI10 = RemoveEnding(filenameoutputI10, ";")
			filenameoutputI11 = RemoveEnding(filenameoutputI11, ";")
			if(strlen(filenameoutputI00)>1)
				if(verbose)
					print "Splicing I00 = " + filenameoutputI00
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI00, filenameoutputI00, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI00, filenameoutputI00, rebin = rebin))
					print "ERROR while splicing I00 (polarization uncorrected) (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I00 found for splicing"
				endif
			endif
			if(strlen(filenameoutputI01)>1)
				if(verbose)
					print "Splicing I01 = " + filenameoutputI01
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI01, filenameoutputI01, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI01, filenameoutputI01, rebin = rebin))
					print "ERROR while splicing I01 (polarization uncorrected) (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I01 found for splicing"
				endif
			endif
			if(strlen(filenameoutputI10)>1)
				if(verbose)
					print "Splicing I10 = " + filenameoutputI10
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI10, filenameoutputI10, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI10, filenameoutputI10, rebin = rebin))
					print "ERROR while splicing I10 (polarization uncorrected) (PolarizedReduction)";abort
				endif
			else
				if(verbose)
					print "NO I10 found for splicing"
				endif
			endif
			if(strlen(filenameoutputI11)>1)
				if(verbose)
				print "Splicing I11 = " + filenameoutputI11
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI11, filenameoutputI11, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI11, filenameoutputI11, rebin = rebin))
					print "ERROR while splicing I11 (polarization uncorrected) (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I11 found for splicing"
				endif
			endif
			filenameoutputI00polcorr = RemoveEnding(filenameoutputI00polcorr, ";")
			filenameoutputI01polcorr = RemoveEnding(filenameoutputI01polcorr, ";")
			filenameoutputI10polcorr = RemoveEnding(filenameoutputI10polcorr, ";")
			filenameoutputI11polcorr = RemoveEnding(filenameoutputI11polcorr, ";")
			if(strlen(filenameoutputI00polcorr)>1)
				if(verbose)
				print "Splicing I00polcorr = " + filenameoutputI00polcorr				
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI00PolCorr, filenameoutputI00polcorr, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI00PolCorr, filenameoutputI00polcorr, rebin = rebin))
					print "ERROR while splicing Polarization Corrected I00 (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I00polcorr found for splicing"
				endif
			endif
			if(strlen(filenameoutputI01polcorr)>1)
				if(verbose)
				print "Splicing I01polcorr = " + filenameoutputI01polcorr
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI01PolCorr, filenameoutputI01polcorr, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI01PolCorr, filenameoutputI01polcorr, rebin = rebin))
					print "ERROR while splicing Polarization Corrected I01 (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I01polcorr found for splicing"
				endif
			endif
			if(strlen(filenameoutputI10polcorr)>1)
				if(verbose)
				print "Splicing I10polcorr = " + filenameoutputI10polcorr
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI10PolCorr, filenameoutputI10polcorr, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI10PolCorr, filenameoutputI10polcorr, rebin = rebin))
					print "ERROR while splicing Polarization Corrected I10 (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I10polcorr found for splicing"
				endif
			endif
			if(strlen(filenameoutputI11polcorr)>1)
				if(verbose)
				print "Splicing I11polcorr = " + filenameoutputI11polcorr
				endif
				sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, newfnameI11PolCorr, filenameoutputI11polcorr, rebin
				print cmd
				if(spliceFiles(outputPathStr, newfnameI11PolCorr, filenameoutputI11polcorr, rebin = rebin))
					print "ERROR while splicing Polarization Corrected I11 (PolarizedReduction)";abort
				endif
			else
				if(verbose)
				print "NO I11polcorr found for splicing"
				endif
			endif
			//sprintf cmd, "splicefiles(\"%s\",\"%s\",\"%s\",rebin = %g)", outputPathStr, PolChannelsfname, toSplice, rebin
			//print cmd
			//if(spliceFilesPolCorr(outputPathStr, PolChannelsfname, toSplice, rebin = rebin, verbose = verbose))
			//	print "ERROR while splicing (PolarizedReduction)";abort
			//endif
		endif		
	catch
		
		Print "ERROR: an abort was encountered in (PolarizedReduction)"
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
	//Fourth, the reduced files are written to the disk as ASCII.dat (polarization corrected), 1D.xml (Polarization corrected), 2D.xml (NOT polarization corrected)
	//The function RETURNS a LIST of polarization corrected reduced reflected file filenames --outputname
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
	string fname, fnamepolcorr, cmd="", theFile, ifname  //theFile = thePair
	variable ii, iii, jj, aa, splicefactor, numpairs, numspectra, D_S2, D_S3, D_SAMPLE, domega, fileID, scalefactors
	string processedruns, I00, I01, I10, I11, D00, D01, D10, D11,  DBSpectra, thedirectDF, theangleDF, RefSpectra, theAngle = "", theDB = "", ofname, outputname=""
	string writetempDF, proccmdp, cmdp 
	string temprunfilenames, tempdirectDF  //Delete if Andys issue with rebinboundaries is solved and W_newrebinboundaries needs to be replaced with W_rebinboundaries
	variable omegas, two_thetas, numprocessedfiles
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
				background = 0
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
			if(numtype(scalefactorI00) || numtype(scalefactorI01) || numtype(scalefactorI10) || numtype(scalefactorI11) )
				print "ERROR a non sensible scale factor was entered (reducePol) - setting ALL scalefactor to 1";	
				scalefactorI00 = 1; scalefactorI01 = 1; scalefactorI10 = 1; scalefactorI11 = 1;  
			endif
			//if(scalefactorI00==0||scalefactorI01==0||scalefactorI10==0||scalefactorI11==0)
			//	print "WARNING WARNING: ONE OF THE SCALEFACTORS APPEARS TO BE 0"
			//endif
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
				make/n=(dimsize(W_rebinboundaries, 0))/free/d W_newrebinboundaries //Andys issue  //Delete if Andys issue with rebinboundaries is solved and W_newrebinboundaries needs to be replaced with W_rebinboundaries
				 
			//Figure out how many items are given in the list of datafiles to be reduced
			//This has to be either 8 (which includes direct beams) or 4, in which case no reflectivity is produced, but the spectra given are only polarization corrected (i.e. no direct beam division)
			//If specific channels have not been recorded and are missing, the runfilenames for these have to be set to "00" or "0"
			//Here "00" is reserved for a general measurement with both polarizer and analyzer
			// "0" is reserved for a measurement using only the polarizer
			numpairs = itemsinlist(runfilenames, ";")	
			if(verbose)
				print "(reducepol) number of items in list runfilenames:", numpairs
			endif
			if(numpairs != 4 && numpairs != 8)
				printf "ERROR: Encountered unexpected number of files, you have to give either 8 or 4 filenames in the form PLP0006737; 00; 00; PLP0006734;PLP6640;00;00;00\r"
			endif
			isDirect = 0	
		for(ii = numpairs-1 ; ii >= 0; ii -= 1)//(ii = 0 ; ii < numpairs ; ii += 1)
		//the for loop runs in reverse in order to first process the direct beam runs and create M_lambdaHIST in order to make the same mistake as ANDY does in his reduction in processnexusfile and reduceasinglefile where the angle is rebinned to M_lambdaHIST instead of W_rebinboundaries
			//extract the filename from the runfilenames list
			theFile = stringfromlist(ii, runfilenames, ";")
			//Execute ProcessNexusfile for each item in the list
			//check if the filename is either "00" or "0", these are then not reduced, but the order of the files is kept
			if(stringmatch(theFile, "00")||stringmatch(theFile, "0"))
				//After the loop, processedruns contains the updated list of filenames
				iii = ii+1 
				processedruns += theFile+";"
				if(verbose)
				printf "item %g not processed in ProcessNexusFile since no runnumber given (ReducePol)\r", iii
				endif
				
			else
				runnumber = theFile	
				if(strlen(runnumber)==0 ) //|| strlen(direct)==0   it currently doesnt matter if the beam is direct or not
					print "ERROR parsing the runfilenamestring (reducePol)"; abort
				endif
				if(ii>3)
					if(verbose)
						print "(reducepol) NOW PROCESSING A DIRECT BEAM in ProcessNexusFile with runfilename: " + theFile
					endif
					W_newrebinboundaries = W_rebinboundaries //Delete if Andys issue with rebinboundaries is solved
					isDirect = 0 //THIS SHOULD BE isDirect = 1, but the SF channels screw up!!!
				else
					if(verbose)
						print "(reducepol)  the reflected runfilename currently processed in ProcessNexusFile is: "+runnumber
					endif
					//need to figure out which direct beam has been processed and how I can handle it. //Delete if Andys issue with rebinboundaries is solved
					if(!stringmatch(stringfromlist(4, runfilenames, ";"), "00")&&!stringmatch(stringfromlist(4, runfilenames, ";"), "0")) //Delete if Andys issue with rebinboundaries is solved
						tempdirectDF = "root:packages:platypus:data:Reducer:"+ stringfromlist(4, runfilenames, ";") //Delete if Andys issue with rebinboundaries is solved
						Wave M_lambdaHISTDtemp = $(tempdirectDF+":M_lambdaHIST"); AbortOnRTE //Delete if Andys issue with rebinboundaries is solved
						make/n=(dimsize(M_lambdaHISTDtemp, 0))/free/d/o W_lambdaHISTDtemp //Delete if Andys issue with rebinboundaries is solved
						W_newrebinboundaries[] = M_lambdaHISTDtemp[p][0] //Delete if Andys issue with rebinboundaries is solved
					elseif(!stringmatch(stringfromlist(7, runfilenames, ";"), "00")&&!stringmatch(stringfromlist(7, runfilenames, ";"), "0")) //Delete if Andys issue with rebinboundaries is solved
						tempdirectDF = "root:packages:platypus:data:Reducer:"+ stringfromlist(7, runfilenames, ";") //Delete if Andys issue with rebinboundaries is solved
						print tempdirectDF //Delete if Andys issue with rebinboundaries is solved
						Wave M_lambdaHISTDtemp = $(tempdirectDF+":M_lambdaHIST"); AbortOnRTE //Delete if Andys issue with rebinboundaries is solved
						make/n=(dimsize(M_lambdaHISTDtemp, 0))/free/d/o W_lambdaHISTDtemp //Delete if Andys issue with rebinboundaries is solved
						W_newrebinboundaries[] = M_lambdaHISTDtemp[p][0] //Delete if Andys issue with rebinboundaries is solved
					else //Delete if Andys issue with rebinboundaries is solved
						W_newrebinboundaries[] = W_rebinboundaries //Delete if Andys issue with rebinboundaries is solved
					endif		 //Delete if Andys issue with rebinboundaries is solved
				endif
				if(rebin)
					if(processNeXUSfile(inputPathStr, outputPathStr, runnumber, background, lowLambda, highLambda, water = water, isDirect = isDirect, expected_peak = expected_peak, rebinning = W_newrebinboundaries, manual = manual, normalise=normalise, saveSpectrum = saveSpectrum))
						print "ERROR while processing a spectrum (ReducePol[processNexusfile])" ; abort
					else
					 	fname = cutfilename(runnumber)
						if(verbose)
							print "(ProcessNexusfile) finished successfully for file"+ fname
						endif
						ifname = fname
					endif
				else
					if(processNeXUSfile(inputPathStr, outputPathStr, runnumber, background, lowLambda, highLambda, water = water, isDirect = isDirect, expected_peak = expected_peak, manual = manual, normalise = normalise, saveSpectrum = saveSpectrum))
						print "ERROR could not find a W_rebinboundaries (ReducePol[processNexusfile])" 
						print "ERROR while processing a direct beam run (ReducePol[processNexusfile])" ; abort
					else 
						fname = cutfilename(runnumber)
						if(verbose)
							print "(processNexusfile) finished successfully for file"+ fname + "(ReducePol)"
						endif
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
		//Start insert of correcting the reverse loop
		//Since I did the processnexusfiles in reverse order, I need to reorder the output in runfilenames 
		numprocessedfiles = itemsinlist(runfilenames)
		temprunfilenames = ""
		for(ii=numprocessedfiles-1; ii>=0; ii-=1)
			temprunfilenames += stringfromlist(ii, runfilenames, ";") + ";"
		endfor
		//print runfilenames, temprunfilenames
		runfilenames = RemoveEnding(temprunfilenames, ";")
		//print runfilenames
		//end insert of correcting the reverse loop
		if(verbose)
			print "(ReducePol) List of files after ProcessNexusFile: " + runfilenames
		endif	
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
	if(verbose)
	print "RUNNING POLARIZATION CORRECTION ON REFLECTED SPECTRA: " + I00 + ";" + I01 + ";" + I10 + ";" + I11
	endif
	//Figure out how many input files there are and which ones are to be processed with which polarization correction 
	if(stringmatch(I00, "00") || stringmatch(I11, "00"))
		//This would mean a mistake has been made, you need at least the I00 and I11 files for a polarization correction to make sense		
		printf "ERROR: No I00 or I11 found, cannot run Polarization Correction (ReducePol)\r"; printf "Please reduce in unpolarized mode if you only have measured one polarization channel (ReducePol)\r"; return ""
	elseif(stringmatch(I01, "00") && stringmatch(I10, "00")) //Note the "00" condition in comparison to the next one
		if(verbose)
			printf "Only I00 and I11 given (polcorr_NSF), a correction without the information of the SF channels is made\r ASSUMING I01 = I10 = 0, ANA = F2 = 1 (ReducePol)\r"
		endif
		if(!polcorr_NSF(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, verbose = verbose))
			if(verbose)
				print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " NSF PolCorr successfull (ReducePol)" 
			endif
		endif
	elseif(stringmatch(I01, "0") && stringmatch(I10, "0")) //Note the "0" condition
		if(verbose)
			printf "Only I0 and I1 given (polcorr_R0R1), ONLY polarizer used in measurement???!!!\r ASSUMING I01=I10=0, ANA = 1, F2=0, (ReducePol)\r"
		endif
		if(!polcorr_R0R1(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, verbose = verbose))
			if(verbose)
				print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " Polarizer ONLY polcorr successfull (ReducePol)" 
			endif	
		endif	
	elseif(stringmatch(I01, "00") || stringmatch(I10, "00"))
		if(verbose)
			printf "Only I00 and I11 and ONE SF channel given (polcorr_R01),\r ASSUMING I01 = I10 and vice versa, Efficiencies are taken in full (ReducePol)\r"
		endif
		if(!polcorr_R01(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, verbose = verbose))
			if(verbose)
				print I00 +", "+ I01 +", "+ I10 +", "+ I11+ " R01 polcorr successfull (ReducePol)" 
			endif
		endif	
	else
		if(verbose)
			printf "FULL CORRECTION OF FOUR REFLECTIVITY CHANNELS (polcorr_FULL)\r All channels and efficiencies are taken into account\r"
		endif
		if(!polcorr_FULL(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11,verbose=verbose))
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
		if(verbose)
			printf "No direct beams given, \r the correction ends here, giving only the corrected spectra (ReducePol)"
		endif
		setdatafolder $cDF
		if(verbose)
		Print "(ReducePol) finished successfully without direct beams and direct beam division"
		endif
		return "spectra"
	elseif(numpairs>4)
		//What if the direct beams for one spin channel are different to the others? One might vary the resolution for an SF measurement... The wavelength resolution should not be varied, as that might affect the plarization correction
		if(verbose)
			print "The numbers after the first four entries are considered as the direct beams (ReducePol)"
		endif
		D00 = stringfromlist(4, runfilenames, ";")
		D01 = stringfromlist(5, runfilenames, ";")
		D10 = stringfromlist(6, runfilenames, ";")
		D11 = stringfromlist(7, runfilenames, ";")
		if(stringmatch(D00, D11)&& !stringmatch(D00, "00")&& !stringmatch(D00, "0"))	
		//CASE: For some reason someone does not want to make a polarization correction of the direct beams. To invoke this case, give the same filenames for DB00 and DB11.
			if(verbose)
				print "The files for the DB00 and DB11 are equal (" + D00 +" and "+ D11+ "). A polarization correction of direct beams will not take place (ReducePol)"
			endif
			//need to create M_SpecPolCorr and set it equal to M_Spec
			if(!stringmatch(D00, "00")|| !stringmatch(D00, "0"))
				Wave DI00spec = $("root:packages:platypus:data:Reducer:"+D00+":M_Spec") 
				Wave DI00SDspec = $("root:packages:platypus:data:Reducer:"+D00+":M_SpecSD") 
				string DB00path = "root:packages:platypus:data:Reducer:"+D00+":M_specPolCorr"
				string DB00SDpath = "root:packages:platypus:data:Reducer:"+D00+":M_specPolCorrSD"
				make/o/d/n=(DimSize(DI00spec,0), DimSize(DI00spec,1)) $DB00path
				WAVE DBI00 =  $DB00path
				make/o/d/n=(DimSize(DI00SDspec,0), DimSize(DI00SDspec,1)) $DB00SDpath
				WAVE DBI00SD =  $DB00SDpath
				DBI00 = DI00spec
				DBI00SD = DI00SDspec
			endif				
		else
			if(stringmatch(D01, D00)||stringmatch(D10, D00)||stringmatch(D01, D11)||stringmatch(D10, D11))	
			//Case: If one of the SF DirectBeam filenames is equal to a NSF channel, the correction will disregard this and treat it as "not measured" 
				if(verbose)
					print "The DB given for one of the SF channels is equal to one NSF channel! (ReducePol)"	
				endif
				if(stringmatch(D00,"00")||stringmatch(D11,"00"))
					if(verbose)
						print "The DB given for one of the SF channels is equal to one NSF channel, will set them to 00 (ReducePol)"	
					endif
					if(stringmatch(D01,D00)||stringmatch(D01,D11))
						D01 = "00"
					endif
					if(stringmatch(D10,D00)||stringmatch(D10,D11))
						D10 = "00"
					endif
				elseif(stringmatch(D00,"0")||stringmatch(D11,"0"))
					if(verbose)
						print "The DB given for one of the SF channels is equal to one NSF channel, will set them to 0 (ReducePol)"	
					endif
					if(stringmatch(D01,D00)||stringmatch(D01,D11))
						D01 = "0"
					endif
					if(stringmatch(D10,D00)||stringmatch(D10,D11))
						D10 = "0"
					endif
				endif
			endif
			if(stringmatch(D00, "00") && stringmatch(D11, "00"))
			// CASE: Both DB00 and DB11 received "00" as input. This means that no direct beam is given and therefore no reflectivity will be produced. 
			// The output is the polarization correted reflected spectrum of the first four entries only.
					if(verbose)
						printf "No DB00 and DB11 found, cannot process DB (ReducePol)\r"
					endif
					setdatafolder $cDF
					if(verbose)
					Print "(ReducePol) finished successfully without direct beams and direct beam division"
					endif
					return "spectra"
			elseif(stringmatch(D00, "0") && stringmatch(D11, "0"))
			// CASE: Both DB00 and DB11 received "0" as input. This means that no direct beam is given and therefore no reflectivity will be produced. 
			// The output is the polarization correted reflected spectrum. 
				if(verbose)
					printf "No DB00 and DB11 found, cannot process DB (ReducePol)\r"
				endif
				setdatafolder $cDF
				if(verbose)
				Print "(ReducePol) finished successfully without direct beams and direct beam division"
				endif
				return "spectra"
			elseif(!stringmatch(D00, "00") && stringmatch(D01, "00") && stringmatch(D10, "00")&& stringmatch(D11, "00"))
				if(verbose)
				printf "ONLY DB00 direct beam given, the correction is just a scaling (ReducePol)\r"
				endif
				if(!polcorr_DB(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
					print D00 + " DB polcorr successfull (ReducePol)" 
				endif
			elseif(!stringmatch(D11, "00") && stringmatch(D01, "00") && stringmatch(D10, "00")&&stringmatch(D00, "00") )
				if(verbose)
				printf  "ONLY DB11 direct beam given, the correction is just a scaling (ReducePol)\r"
				endif
				if(!polcorr_DB(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
					if(verbose)
					print D11 + " DB polcorr successfull (ReducePol)"
					endif 
				endif
			elseif(!stringmatch(D00, "0") && stringmatch(D01, "0") && stringmatch(D10, "0")&& stringmatch(D11, "0"))
				if(verbose)
				printf "ONLY DB0 direct beam given, the correction is just a scaling (ReducePol)\r"
				endif
				if(!polcorr_DB(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
					print D00 + " DB polcorr successfull (ReducePol)" 
				endif
			elseif(!stringmatch(D11, "0") && stringmatch(D01, "0") && stringmatch(D10, "0")&&stringmatch(D00, "0") )
				if(verbose)
				printf  "ONLY DB1 direct beam given, the correction is just a scaling (ReducePol)\r"
				endif
				if(!polcorr_DB(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
					if(verbose)
					print D11 + " DB polcorr successfull (ReducePol)"
					endif 
				endif	
			elseif(stringmatch(D01, "00") && stringmatch(D10, "00")&&!stringmatch(D11, "00")&&!stringmatch(D00, "00"))
				if(verbose)
				printf "Only DB00 and DB11 given, no full correction (ReducePol)\r"
				endif
				if(!polcorr_NSF(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
					if(verbose)
					print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " NSF polcorr successfull (ReducePol)" 
					endif
				endif
			elseif(stringmatch(D01, "0") && stringmatch(D10, "0")&&!stringmatch(D11, "0")&&!stringmatch(D00, "0"))
				if(verbose)
				printf "Only DB0 and DB1 given, no full correction (ReducePol)\r"
				endif
				if(!polcorr_R0R1(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
						if(verbose)
						print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " Polarizer ONLY polcorr successfull (ReducePol)" 
						endif
				endif	
			elseif(stringmatch(D01, "00") && stringmatch(D10, "00")&&!stringmatch(D11, "00")&&!stringmatch(D00, "00"))
				if(verbose)
				printf "Only DB00 and DB11 and one SF channel given, no full correction\r"
				endif
				if(!polcorr_R01(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
						if(verbose)
						print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " NSF polcorr successfull (ReducePol)" 
						endif
				endif	
			else
				if(verbose)
				printf "FULL CORRECTION OF FOUR DirectBeam CHANNELS (ReducePol)\r"
				endif
				if(!polcorr_FULL(D00, D01, D10, D11, 1, 1, 1, 1,verbose=verbose))
						if(verbose)
						print D00 +", "+ D01 +", "+ D10 +", "+ D11+ " FULL polcorr successfull (ReducePol)" 
						endif
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
	//you may want to save the spectrum to file
	variable numprocessedruns = itemsinlist(processedruns)
	string polcorrrunfiles
	for(ii=0; ii<numprocessedruns; ii+=1)
		polcorrrunfiles = stringfromlist(ii, processedruns, ";") 
		if(!stringmatch(polcorrrunfiles, "00") && !stringmatch(polcorrrunfiles, "0"))
		if(!paramisdefault(saveSpectrum) && saveSpectrum)
			writetempDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(polcorrrunfiles,".nx.hdf"),0)
			//Wave PolCorr_spectrumsave, PolCorrSD_spectrumsave, M_lambdaPolCorr, M_lambdaPolCorrSD, W_omegas, W_two_thetas
			Wave PolCorr_spectrumsave = $(writetempDF+":M_specPolCorr")
			Wave PolCorrSD_spectrumsave = $(writetempDF+":M_specPolCorrSD")
			Wave M_lambdaPolCorr = $(writetempDF+":M_lambda")
			Wave M_lambdaPolCorrSD = $(writetempDF+":M_lambdaSD")
			Wave W_omegas = $(writetempDF+":instrument:parameters:omega")
			omegas = W_omegas[0]
			Wave W_two_thetas = $(writetempDF+":instrument:parameters:twotheta")
			two_thetas = W_two_thetas[0]
		
			cmdp = "processNeXUSfile(\"%s\", \"%s\", \"%s\", %d, %g, %g, water=\"%s\",isdirect=%d,  expected_peak=cmplx(%g,%g), omega=%g,two_theta=%g,manual=%d, savespectrum=%d, normalise=%d,verbose=%d)"
			sprintf proccmdp, cmdp, inputPathStr, outputPathStr, polcorrrunfiles, background, lowLambda, highLambda, water, isDirect,real(expected_peak), imag(expected_peak), omegas, two_thetas,manual, saveSpectrum, normalise,verbose
					
			if(writeSpectrum(outputPathStr, polcorrrunfiles+"PolCorr", polcorrrunfiles, PolCorr_spectrumsave, PolCorrSD_spectrumsave, M_lambdaPolCorr, M_lambdaPolCorrSD, proccmdp, dontoverwrite=dontoverwrite))
				print "ERROR whilst writing spectrum to file (processNexusfile)"
			else
			 	if(verbose)
			 		print "writing polarization corrected spectrum: " + polcorrrunfiles  
			 	endif
			endif
			
		endif
		endif
	endfor
	runfilenames = RemoveEnding(processedruns, ";")
	if(verbose)
	Print "List of polarization corrected spectra (ReducePol[PolCorr]): " + runfilenames
	endif
	catch
		Print "ERROR: an abort was encountered in (reducepol[Polcorr])"
		setdatafolder $cDF
		return ""
	endtry
	if(verbose)
		Print "(POLCORR) finished successfully (ReducePol)"
		Print "Now executing direct beam divisions (ReducePol)"
	endif
	//NOW DIRECT BEAM DIVISIONS
	//figure out which datasets belong together and process them together
	try
		if(numpairs>4)
			if(verbose)
			print "The positions 5, 6, 7, 8 in the list runfilenames are considered as direct beams for division (ReducePol)"
			endif
			numpairs = 4
		endif					
		//Change the datalist in order to have the correct DB at the correct position
		//might be that D00 or D11 are 00  and D01 and D10 need to be changed anyway
		if(stringmatch(D00, "00")|| stringmatch(D00, "0"))
			D00 = D11
			if(verbose)
			print "D00 was not given, setting DB to D11 (ReducePol)"
			endif
		endif
		if(stringmatch(D11, "00")|| stringmatch(D11, "0"))
			D11 = D00
			if(verbose)
			print "D11 was not given, setting DB to D00 (ReducePol)"
			endif
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
				if(verbose)
				printf "Item %g not processed since no runnumber given (ReducePol)\r", iii
				endif
				outputname = outputname + stringfromlist(ii, RefSpectra, ";") + ";"
			else
				if(verbose)
				print "(ReducePol) Advice which files belong together? Reflectivities: ", RefSpectra, "Direct beams: ", DBSpectra
				endif
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
				//and propagate the errors
				//this step probably produces negative reflectivities, or NaN if M_specD is 0.
				//ALSO, 
				//M_refSD has the potential to be NaN is M_topandtailA0 or M_specD is 0.
				
				//ATTENTION: For the polarization corrected data, no complete error propagation through the polarization correction is performed.
				//Currently the error is simply taken from the intensity in the corrected spectra.
				//A complete error propagation is to be implemented in the future.
				//The simplified error propagation is implemented in this code				
				M_refSD = 0
				M_refPolCorrSD = 0	
				M_ref = 0
				M_refPolCorr = 0
				
				multithread M_refSD[][][] = sqrt(((M_topandtailA0SD[p][q][r] / M_specD[p][0])^2 + (M_topandtailA0[p][q][r]^2 / (M_specD[p][0]^4)) * M_specDSD[p][0]^2))
				multithread M_refPolCorrSD[] = sqrt(((M_specA0PolCorrSD[p] / M_specDPolCorr[p])^2 + (M_specA0PolCorr[p]^2 / (M_specDPolCorr[p]^4)) * M_specDPolCorrSD[p]^2))
				multithread M_ref[][][] = M_topandtailA0[p][q][r] / M_specD[p][0]
				multithread M_refPolCorr[] = M_specA0PolCorr[p] / M_specDPolCorr[p]
				
				//scale reflectivity by scale factor
 	                   // because refSD is stil fractional variance (dr/r)^2 have to divide by scale factor squared.
				multithread M_ref /= scalefactors
				multithread M_refSD /= (scalefactors)
				////A division of the polarization corrected spectra by the scalefactor is not performed, since the spectra are scaled before the polarization correction. 
				////This might lead to slight differences in scaling, although I have not yet encountered such a case. 
				////If the scaling is different after the polarization correction, NEW scalefactors have to be provided! Otherwise, here new scalefactors would need to be provided, which complicates the whole reduction considerably.
				//multithread M_refPolCorr /= scalefactors
				//multithread M_refPolCorrSD /= (scalefactors)
				
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
						if(verbose)
						print "NO UNIQUE FILENAME, files overwritten (ASCII.dat) (ReducePol)"
						endif
					endif
					fnamepolcorr = fname + "PolCorr"
					newpath/o/q/z pla_temppath_write, outputpathStr
//					This writes a .dat for a combined PolCorr and normal file
//					open/P=pla_temppath_write fileID as fname + ".dat"
//			
//					if(V_flag == 0)
//						fprintf fileID, "Q (1/A)\t Ref\t dRef (SD)\t RefPolCorr\t DRefPolCorr\t dq(FWHM, 1/A)\n"
//						wfprintf fileID, "%g\t %g\t %g\t %g\t %g\t %g\n" qq, RR, dR, RRpolCorr, DRpolCorr, dQ
//						close fileID
//					endif
					open/P=pla_temppath_write fileID as fname + ".dat"
			
					if(V_flag == 0)
						fprintf fileID, "Q (1/A)\t Ref\t dRef (SD)\t dq(FWHM, 1/A)\n"
						wfprintf fileID, "%g\t %g\t %g\t %g\n" qq, RR, dR, dQ
						close fileID
					endif
					open/P=pla_temppath_write fileID as fnamepolcorr + ".dat"
			
					if(V_flag == 0)
						fprintf fileID, "Q (1/A)\t RefPolCorr\t DRefPolCorr\t dq(FWHM, 1/A)\n"
						wfprintf fileID, "%g\t %g\t %g\t %g\n" qq, RRpolCorr, DRpolCorr, dQ
						close fileID
					endif
			
					//this only writes XML for a single file
					fname = cutfilename(theAngle)
					if(dontoverwrite)
						fname = uniqueFileName(outputPathStr, fname, ".xml")
					else
						if(verbose)
						print "NO UNIQUE FILENAME, files overwritten (1D.XML) (ReducePol)"
						endif
					endif
					Wave/t user = $(theAngleDF + ":user:name")
					Wave/t samplename = $(theAngleDF + ":sample:name")			
					//The code to write an xml file has been adjusted to incorporate the new polarization corrected channels
					
					
					//writeSpecRefXML1DPolCorr(outputPathStr, fname, qq, RR, dR, RRPolCorr, dRPolCorr, dQ, "", user[0], samplename[0], theAngle, reductionCmd)
					writeSpecRefXML1D(outputPathStr, fname, qq, RR, dR, dQ, "", user[0], samplename[0], theAngle, reductionCmd)
					fnamepolcorr = fname + "PolCorr"
					writeSpecRefXML1D(outputPathStr, fnamepolcorr, qq, RRPolCorr, dRPolCorr, dQ, "", user[0], samplename[0], theAngle, reductionCmd)
						
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
							if(verbose)
							print "NO UNIQUE FILENAME, files overwritten (2D.XML) (ReducePol)"	
							endif
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
		if(verbose)
		print "(ReducePol) The runs processed in reducePol are", processedruns
		endif
	catch
		Print "ERROR: an abort was encountered in (DB division part)"
		setdatafolder $cDF
		return ""
	endtry	
	setdatafolder $cDF
	outputname = RemoveEnding(outputname, ";")
	if(verbose)
	Print "(ReducePol) finished successfully", outputname
	endif
	return outputname
End

Function  reducerpanelPOL() : Panel  //reducerpanel
	PauseUpdate; Silent 1		// building window...
	Dowindow/k POLSLIM
	NewPanel/W=(100,0,1021,230)/N=POLSLIM/k=1 as "POLSLIM - (C) Andrew Nelson 2009 + Thomas Saerbeck 2012"
	///W=(384,163,1085,607)
	
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	//directory for the reduction package
	Newdatafolder /o root:packages:platypus:data:Reducer
	//492
	make/b/u/n=(4,9,2)/o root:packages:platypus:data:Reducer:angledata_selPOL
	make/n=(4,9)/o/t root:packages:platypus:data:Reducer:angledata_listPOL
	make/o/w/u/n=(4,3)/o root:packages:platypus:data:Reducer:angledata_colorPOL
	make/b/u/n=(4,9,2)/o root:packages:platypus:data:Reducer:angledata_sel
	make/n=(4,9)/o/t root:packages:platypus:data:Reducer:angledata_list
	string/g root:packages:platypus:data:Reducer:inputpathStr
	string/g root:packages:platypus:data:Reducer:outputpathStr
	string/g root:packages:platypus:data:Reducer:waterrunfile

	variable/g root:packages:platypus:data:Reducer:lowLambda=2.5
	variable/g root:packages:platypus:data:Reducer:highLambda=12.5
	variable/g root:packages:platypus:data:Reducer:expected_centre=144
	variable/g root:packages:platypus:data:Reducer:rebinpercent=3
	variable/g root:packages:platypus:data:Reducer:backgroundsbn=1
	variable/g root:packages:platypus:data:Reducer:manualbeamfind=1
	variable/g root:packages:platypus:data:Reducer:normalisebymonitor=1
	variable/g root:packages:platypus:data:Reducer:saveSpectrum=0
	variable/g root:packages:platypus:data:Reducer:saveoffspec=0
	variable/g root:packages:platypus:data:Reducer:measwithanalyzer=1
	variable/g root:packages:platypus:data:Reducer:verbosevar=1
	variable/g root:packages:platypus:data:Reducer:donotoverwrite=0
	variable/g root:packages:platypus:data:Reducer:streamedReduction= 0
		
	SVAR inputpathStr = root:packages:platypus:data:Reducer:inputpathStr
	SVAR outputpathStr = root:packages:platypus:data:Reducer:outputpathStr
	SVAR waterrunfile = root:packages:platypus:data:Reducer:waterrunfile
	
	Wave/t angledata_listPOL = root:packages:platypus:data:Reducer:angledata_listPOL
	Wave angledata_selPOL= root:packages:platypus:data:Reducer:angledata_selPOL
	Wave angledata_colorPOL= root:packages:platypus:data:Reducer:angledata_colorPOL
	setdimlabel 1,1,Include,angledata_listPOL
	//setdimlabel 1,2,Dontoverwrite,angledata_listPOL
	setdimlabel 1,2,Scalefactor,angledata_listPOL
	setdimlabel 1,3,Reflectangle1,angledata_listPOL
	setdimlabel 1,4,Reflectangle2,angledata_listPOL
	setdimlabel 1,5,Reflectangle3,angledata_listPOL
	setdimlabel 1,6,Directangle1,angledata_listPOL
	setdimlabel 1,7,Directangle2,angledata_listPOL
	setdimlabel 1,8,Directangle3,angledata_listPOL
	
	setdimlabel 0,0,IntensityI00,angledata_listPOL
	setdimlabel 0,1,IntensityI01,angledata_listPOL
	setdimlabel 0,2,IntensityI10,angledata_listPOL
	setdimlabel 0,3,IntensityI11,angledata_listPOL
	
	//setdimlabel 1,9,waterrun,angledata_list
	angledata_listPOL=""
	angledata_listPOL[0][0] = "I00: OFF/OFF = R--"
	angledata_listPOL[1][0] = "I01: OFF/ON = R-+"
	angledata_listPOL[2][0] = "I10: ON/OFF = R+-"
	angledata_listPOL[3][0] = "I11: ON/ON = R++"
	//angledata_selPOL[][0] = 0x01
	angledata_selPOL[][1] = 0x20//2^5
	angledata_selPOL[][2] = 0x02////2^5
	angledata_selPOL[][3]=0x02
	angledata_selPOL[][4]=0x02
	angledata_selPOL[][5]=0x02
	angledata_selPOL[][6]=0x02
	angledata_selPOL[][7]=0x02
	angledata_selPOL[][8]=0x02
	//65535
	angledata_colorPOL[][0] = 30000
	angledata_colorPOL[][1] = 40000
	angledata_colorPOL[][2] = 65535
	
	angledata_selPOL[][][1]= 1
	SetDimLabel 2,1,backColors,angledata_selPOL				// define plane 1 as background colors
	//SetDimLabel 2,1,foreColors,angledata_selPOL	  			// redefine plane 1 s foreground colors
	//size={677,353}, widths = {12,12,100}
	ListBox whichangles,pos={13,103},size={895,99}, widths = {125, 40,66, 78}
	ListBox whichangles,listWave=root:packages:platypus:data:Reducer:angledata_listPOL
	ListBox whichangles,selWave=root:packages:platypus:data:Reducer:angledata_selPOL,colorwave=root:packages:platypus:data:Reducer:angledata_colorPOL 
	ListBox whichangles userColumnResize=1
	ListBox whichangles,mode= 6, editStyle= 2,fstyle = 1,fsize = 12,frame = 4, proc=POLSLIM_listproc
	ListBox whichangles, help={"Please enter the filenames of the datafiles that you wish to reduce."}
	
	Button reduce_tab0,pos={14,10},size={260,22},proc=SLIMPOL_buttonprocpol,title="Reduce"
	Button reduce_tab0,labelBack=(1,52428,26586),font="Arial",fstyle = 1,fColor=(65535,0,0)//(1,4,52428)
	Button plot_tab0,pos={14,43},size={260,22},proc=SLIMPOL_buttonprocpol,title="Plot"
	Button plot_tab0,labelBack=(1,52428,26586),font="Arial",fstyle = 1,fColor=(0,65535,0)
	
	SetVariable waterrunfile_tab0,pos={13,79},size={155,16},title="Waterrun",fstyle = 1
	SetVariable waterrunfile_tab0,fSize=10
	SetVariable waterrunfile_tab0,value= root:packages:platypus:data:Reducer:waterrunfile,noedit= 0
	
	checkbox measwithanalyzer_tab0,pos={193,79},size={178,14},proc=POLSLIM_analyzercheckbox,title="Measurement with analyzer?",fsize=12,fstyle=1,side=1
	checkbox measwithanalyzer_tab0,variable= root:packages:platypus:data:Reducer:measwithanalyzer
	checkbox verbosevar_tab0,pos={410,79},size={178,14},proc=POLSLIM_verbosecheckbox,title="Run with extended description?",fsize=12,fstyle=1,side=1
	checkbox verbosevar_tab0,variable= root:packages:platypus:data:Reducer:verbosevar
	checkbox donotoverwrite_tab0,pos={540,79},size={178,14},proc=POLSLIM_donotoverwritecheckbox,title="Do not overwrite",fsize=12,fstyle=1,side=1
	checkbox donotoverwrite_tab0,variable= root:packages:platypus:data:Reducer:donotoverwrite	
	
	SetVariable dataSource_tab0,pos={288,10},size={367,16},title="Data directory"
	SetVariable dataSource_tab0,fSize=10
	SetVariable dataSource_tab0,value= root:packages:platypus:data:Reducer:inputpathStr,noedit= 0
	SetVariable dataOut_tab0,pos={288,30},size={367,16},title="Output directory"
	SetVariable dataOut_tab0,fSize=10
	SetVariable dataOut_tab0,value= root:packages:platypus:data:Reducer:outputpathStr,noedit= 0
	
	Button storeangleslist_tab0,pos={734,9},size={152,16},proc=SLIMPOL_buttonprocpol,title="store data list"
	Button storeangleslist_tab0,fSize=9
	
	Button loadangleslist_tab0,pos={734,32},size={152,16},proc=SLIMPOL_buttonprocpol,title="load data list"
	Button loadangleslist_tab0,fSize=9
	
	Button showreducervariables_tab0,pos={348,53},size={152,16},proc=SLIMPOL_buttonprocpol,title="show reducer variables"
	Button showreducervariables_tab0,fSize=9

	Button changedatasource_tab0,pos={671,10},size={44,16},proc=SLIMPOL_buttonprocpol,title="change"
	Button changedatasource_tab0,fSize=9
	
	Button changedataout_tab0,pos={671,30},size={44,16},proc=SLIMPOL_buttonprocpol,title="change"
	Button changedataout_tab0,fSize=9

	Button downloadPlatdata_tab0,pos={518,53},size={152,16},proc=SLIMPOL_buttonprocpol,title="Download Platypus data"
	Button downloadPlatdata_tab0,fSize=9

	Button clear_tab0,pos={772,55},size={86,17},proc=SLIMPOL_buttonprocpol,title="clear"
	string titlestring = "Hold down \"ctrl\" + left click on item for a help printed in the MAIN IGOR CommandWindow. 	 "
	titlebox/z helpfield,pos={13,205},size={520,23}, fixedSize =0,title=titlestring 
	titlebox/z helpfield,fstyle = 1, frame=3, fsize =12
	//Killstrings/z titlestring
End


Function POLSLIM_listproc(lba) : ListBoxControl //behind the : is the subtype, telling igor, that this is called when something happens, e.g. button tick
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col //Selection column
	WAVE/T/Z listWave = lba.listWave //List wave specified by ListBox command
	WAVE/Z selWave = lba.selWave //Selection wave specified by ListBox command
	string filenames = ""
	SVAR inputpathStr = root:packages:platypus:data:Reducer:inputpathStr

	switch( lba.eventCode )
		case -1: // control being killed
			break

		case 4://Cell Selection
			if(lba.eventmod==16 && col > 0)	//eventmod changes whether alt or ctrl are pressed 
			//5 BITS (4 3 2 1 0) which can be filled. x0 = enter, x1 = left click, x2 = shift, x4 = ALT, x8 = ctrl, right = 16  Therefore crtl+left=9, shift+right=18
				GetFileFolderInfo/q/z inputpathStr
				if(V_flag)//path doesn't exist
					Doalert 0, "Please enter a valid filepath for the data source"
					return 0	
				endif
				
				newpath/o/q/z pla_temppath_SLIM_listproc, inputpathStr	
				filenames = indexedfile(pla_temppath_SLIM_listproc, -1, ".hdf")	
				filenames = sortlist(filenames,";",17)
				killpath/z pla_temppath_SLIM_listproc
				popupcontextualmenu "-Filldown-;"+filenames
				switch(V_Flag)
					case 1:
						variable ii
						for(ii=row+1 ; ii<dimsize(listWave,0) && strlen(listWave[ii][col])==0 ; ii+=1)
							listwave[ii][col] = listwave[ii-1][col]
						endfor
						break
					default:
						lba.listwave[row][col]=removeending(S_Selection,".nx.hdf")
						break
				endswitch
			endif
			if(lba.eventmod==9 && col > 0)
				//printf "NOTE: Please note the entry help for the direct beams by \"ctrl+left click\" on the three right most columns.\r\r"
				if(col==1)
					printf "With the Include button, you can specify whether a specific polarization channel has been measured\r"
					printf " and should be included in the reduction and polarization correction." 
					printf "This should be at least the I00=R-- and I11=R++ channels.\r\r" 
				elseif(col==2)
					printf "Please enter the scalefactor of the measured reflectivities.\r"
					printf "You can choose different scalings for each channel, but note that this will affect the polarization correction.\r\r"
				elseif(col>2 && col<6)
					printf "Please insert the number of the reflected-spectrum datafile you want to reduce:\r" 
					printf "You can enter either the full file name, e.g. PLP0001111, or just the number, i.e. without the leading PLP and zeros.\r"
					printf "The first three COLUMNS contain the measured angles, in incremental order.\r"
					printf "RIGHT click to obtain a list of files contained in your input folder.\r"
					printf "If you have not measured all three angles, leave missing fields blank.\r"
					printf "The ROWS contain the different polarization state, as defined by the spin flipper setting used in the experiment.\r"
					printf "In case not all channels have been measured, leave the respective fields blank\r"
					printf "BUT you need to provide AT LEAST one I00=R-- and one I11=R++ channel for the reduction to work.\r\r"
				elseif(col>5 && col<9)
					printf "Please insert the direct beam (DB) filenames to normalize the recorded reflectivity spectra.\r"
					printf "NOTE: You only have to provide a single direct beam for all channels to make a reduction (leave other fields blank).\r"
					printf "Case 0: No direct beam provided. The output of the reduction will only be the polarization corrected and reduced spectra, not the reflectivity.\r"
					printf "Case 1: Only DB for OFF/OFF or ON/ON is provided: All channels are divided by the same DB The polarization correction is just a scaling with the efficiency.\r"
					printf "Case 2: The DB for OFF/OFF and ON/ON are the same: NO polarization correction is performed.\r"
					printf "Case 3: The DB for OFF/OFF and ON/ON are provided and DIFFERENT: The I00 and I01 are divided by DB OFF/OFF; the I11 and I10 are divided by DB ON/ON\r"
					printf "Case 4: In the case you also provide DB for the SF channels ON/OFF and OFF/ON, a more complete polarization correction of the direct beams will be performed.\r"
					printf "The DB division is the same as for Case 3.\r\r"
				endif
			endif
			break		
		case 3: // double click
			break
		//case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
	endswitch

	return 0
End



Function  reducerVariablesPanelPOL() : Panel
	PauseUpdate; Silent 1		// building window...
	Dowindow/k SLIMvarpanel
	NewPanel /K=1 /W=(385,164,588,390)
	Dowindow/c SLIMvarpanel
	
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	//directory for the reduction package
	Newdatafolder /o root:packages:platypus:data:Reducer
	
	NVAR backgroundsbn = root:packages:platypus:data:Reducer:backgroundsbn
	NVAR manualbeamfind =  root:packages:platypus:data:Reducer:manualbeamfind
	NVAR normalisebymonitor = root:packages:platypus:data:Reducer:normalisebymonitor
	NVAR saveSpectrum = root:packages:platypus:data:Reducer:saveSpectrum
	NVAR saveoffspec = root:packages:platypus:data:Reducer:saveoffspec
	NVAR streamedReduction = root:packages:platypus:data:Reducer:streamedReduction
	 
	SetVariable lowLambda_tab0,pos={10,10},size={177,16},title="lowWavelength", win=SLIMvarpanel
	SetVariable lowLambda_tab0,fSize=10, win=SLIMvarpanel
	SetVariable lowLambda_tab0,limits={0.5,30,0.1},value= root:packages:platypus:data:Reducer:lowLambda, win=SLIMvarpanel
	SetVariable highLambda_tab0,pos={10,30},size={178,16},title="highWavelength", win=SLIMvarpanel
	SetVariable highLambda_tab0,fSize=10, win=SLIMvarpanel
	SetVariable highLambda_tab0,limits={0.5,30,0.1},value= root:packages:platypus:data:Reducer:highLambda, win=SLIMvarpanel
	SetVariable rebinpercent_tab0,pos={10,51},size={177,16},title="Rebin %tage ", win=SLIMvarpanel
	SetVariable rebinpercent_tab0,fSize=10, win=SLIMvarpanel
	SetVariable rebinpercent_tab0,limits={-1,11,1},value= root:packages:platypus:data:Reducer:rebinpercent, win=SLIMvarpanel
	SetVariable expected_centre_tab0,pos={8,72},size={178,16},title="expected centre", win=SLIMvarpanel
	SetVariable expected_centre_tab0,fSize=10, win=SLIMvarpanel
	SetVariable expected_centre_tab0,limits={-220,220,1},value= root:packages:platypus:data:Reducer:expected_centre, win=SLIMvarpanel
	CheckBox background_tab0,pos={9,94},size={138,14},title="background subtraction?", win=SLIMvarpanel
	CheckBox background_tab0,fSize=10,variable= root:packages:platypus:data:Reducer:backgroundsbn, win=SLIMvarpanel, value = backgroundsbn
	CheckBox manual_tab0,pos={9,115},size={109,14},title="manual beam find?", win=SLIMvarpanel, value = manualbeamfind
	CheckBox manual_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:manualbeamfind
	CheckBox normalise_tab0,pos={9,136},size={155,14},title="normalise by beam monitor?", win=SLIMvarpanel
	CheckBox normalise_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:normalisebymonitor, value = normalisebymonitor
	CheckBox saveSpectrum_tab0,pos={9,157},size={94,14},title="save spectrum?", win=SLIMvarpanel
	CheckBox saveSpectrum_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:saveSpectrum, value = saveSpectrum
	CheckBox saveoffspec_tab0,pos={9,178},size={94,14},title="save offspecular map?", win=SLIMvarpanel
	CheckBox saveoffspec_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:saveoffspec, value =  saveoffspec
	CheckBox streamedreduction_tab0,pos={9,199},size={94,14},title="do streamed reduction?", win=SLIMvarpanel
	CheckBox streamedreduction_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:streamedReduction, value =  streamedReduction, disable=2
End

Function SLIMPOL_buttonprocpol(ba) : ButtonControl //SLIM_buttonproc
	STRUCT WMButtonAction &ba
	//this button handler deals with all button press events in the SLIM button window
	string cDF = getdatafolder(1)

	switch( ba.eventCode )
		case 2: // mouse up
			
			// click code here
			NVAR lowLambda = root:packages:platypus:data:Reducer:lowLambda
			NVAR highLambda = root:packages:platypus:data:Reducer:highLambda
			Wave/t angledata_listPOL = root:packages:platypus:data:Reducer:angledata_listPOL
			Wave angledata_selPOL= root:packages:platypus:data:Reducer:angledata_selPOL
			Wave angledata_colorPOL= root:packages:platypus:data:Reducer:angledata_colorPOL
			SVAR inputpathStr = root:packages:platypus:data:Reducer:inputpathStr
			SVAR outputpathStr = root:packages:platypus:data:Reducer:outputpathStr
			SVAR waterrunfile = root:packages:platypus:data:Reducer:waterrunfile
			 
			NVAR expected_centre = root:packages:platypus:data:Reducer:expected_centre
			NVAR rebinpercent = root:packages:platypus:data:Reducer:rebinpercent
			NVAR backgroundsbn =  root:packages:platypus:data:Reducer:backgroundsbn
			NVAR manualbeamfind =  root:packages:platypus:data:Reducer:manualbeamfind
			NVAR normalisebymonitor = root:packages:platypus:data:Reducer:normalisebymonitor
			NVAR saveSpectrum =  root:packages:platypus:data:Reducer:saveSpectrum
			NVAR saveoffspec =  root:packages:platypus:data:Reducer:saveoffspec
			NVAR/z streamedReduction = root:packages:platypus:data:Reducer:streamedReduction
			NVAR measwithanalyzer=root:packages:platypus:data:Reducer:measwithanalyzer
			NVAR verbosevar=root:packages:platypus:data:Reducer:verbosevar
			NVAR donotoverwrite=root:packages:platypus:data:Reducer:donotoverwrite
			
			variable rebinning,ii,jj, dontoverwrite = 0, temp, maxtime, mintime
			variable rr, storefilelist
			string tempDF,filenames, water = "", tempangledata_listPOL
			string fileNameList="", righteousFileName = "", fileFilterStr = ""
			string cmd, template
			string storestringlist,storestringlisttemp, loadstringlist, loadstringsel, tempdeststring, thepolpath,polfilenamelists, tempoutputpathStr
			strswitch(ba.ctrlname)
				
				case "reduce_tab0":
					if(ba.eventmod==9)
						printf "Reduce (with polarization correction) datafiles specified in the table below.\r"
						printf "You need to provide at least one OFF/OFF and one ON/ON spectrum in order to perform a reduction.\r\r"
						break
					endif 
					GetFileFolderInfo/q/z inputpathStr
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath for the data source"
						return 0	
					endif
					GetFileFolderInfo/q/z outputpathStr
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath for the output files"
						return 0	
					endif
					//currently, a streamed reduction is not possible.
					streamedReduction = 0
					if(streamedReduction)
//							prompt temp, "time each bin (s)"
//							prompt maxtime, "ending time (s)"
//							prompt mintime, "starting time (s)"
//							maxtime = 3600
//							mintime = 0
//							temp = 60
//							Doprompt "What timescales did you want for the streamed reduction?", mintime, maxtime, temp
//							if(V_flag)
//								abort
//							endif
//							streamedReduction = temp
//							
//							make/n=(ceil((maxtime - mintime) / temp) + 1)/free/d timeslices
//							timeslices = temp * p + mintime
//							if(timeslices[numpnts(timeslices) - 1] > maxtime)
//								timeslices[numpnts(timeslices) - 1] = maxtime
//							endif
//							
//							dontoverwrite = 1
						Doalert 0, "A streamed reduction of polarized data is not possible at this stage!"
						return 0	
					endif
					
					//did you want to rebin?
					rebinning = rebinpercent
					if(strlen(waterrunfile)>0)
						//ask if first three are PLP, otherwise change something...
						string testwaterrunfilestring 
						if(stringmatch(waterrunfile,"PLP*"))
							if(stringmatch(waterrunfile,"PLP"))
								print "ERROR - file name is incomplete (SLIMPOL_buttonprocpol)",  waterrunfile;	return 1
							else
								waterrunfile= replacestring("PLP", waterrunfile, "")
							endif
						endif
						if(numtype(str2num(waterrunfile)) == 2)	
							print "ERROR - file name is incorrect (no PLP + number format) (SLIMPOL_buttonprocpol)",  waterrunfile;	return 1	
						endif
						if(expandStrIntoPossibleFileName(waterrunfile, righteousFileName)) //add in the reflected beam run
							print "ERROR - file name is incorrect (no number format) (SLIMPOL_buttonprocpol)",  waterrunfile;	return 1
						endif
						waterrunfile = righteousfileName
					endif					
					for(ii=0 ; ii < dimsize(angledata_listPOL, 0) ; ii+=1) //go through the table of angledata_list, ii=rows
						if(!(angledata_selPOL[ii][1] & 2^4)) //if the include button of the row is not ticked, continue: 2^4=48=selected button otherwise 32 //strlen(angledata_listPOL[ii][4]) == 0 || 
							continue
						endif
						if(numtype(str2num(angledata_listPOL[ii][2])))
							angledata_listPOL[ii][2] = "1"
							print "Warning setting scale factor to 1 ", angledata_listPOL[ii][2]
						endif
						
						fileNameList = ""
						for(jj = 3 ;  jj <=8  ; jj+=1) //strlen(angledata_listPOL[ii][jj])>0 && ,,jj=cols
							//print ii, jj, angledata_listPOL[ii][jj]
							if(stringmatch(angledata_listPOL[ii][jj],"PLP*"))
								if(stringmatch(angledata_listPOL[ii][jj],"PLP"))
									print "ERROR - file name is incomplete (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][jj];	return 1
								else		
									angledata_listPOL[ii][jj]= replacestring("PLP", angledata_listPOL[ii][jj], "")
								endif
							endif
							if(numtype(str2num(angledata_listPOL[ii][jj])) == 2&&strlen(angledata_listPOL[ii][jj])>0)	
								print "ERROR - file name is incorrect 1 (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][jj];	return 1	
							endif
							if(measwithanalyzer==1)
								if(strlen(angledata_listPOL[ii][jj])<=0)
									angledata_listPOL[ii][jj] = "00"
								elseif(stringmatch(angledata_listPOL[ii][jj],"0"))
									angledata_listPOL[ii][jj] = "00"
								elseif(stringmatch(angledata_listPOL[ii][jj],"00"))
									angledata_listPOL[ii][jj] = "00"
								else
									if(expandStrIntoPossibleFileName(angledata_listPOL[ii][jj], righteousFileName)) //add in the reflected beam run
										print "ERROR - file name is incorrect 2 (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][jj];	return 1
									endif
									angledata_listPOL[ii][jj] = righteousFileName	
								endif
							elseif(measwithanalyzer==0)
								if(strlen(angledata_listPOL[ii][jj])<=0)
									angledata_listPOL[ii][jj] = "0"
								elseif(stringmatch(angledata_listPOL[ii][jj],"00"))
									angledata_listPOL[ii][jj] = "0"
								elseif(stringmatch(angledata_listPOL[ii][jj],"0"))
									angledata_listPOL[ii][jj] = "0"
								elseif(ii==1)
									angledata_listPOL[ii][jj]= "0"
								elseif(ii==2)
									angledata_listPOL[ii][jj]= "0"
								else
									if(expandStrIntoPossibleFileName(angledata_listPOL[ii][jj], righteousFileName)) //add in the reflected beam run
										print "ERROR - file name is incorrect (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][jj];	return 1
									endif
									angledata_listPOL[ii][jj] = righteousFileName	
								endif
							else
								print "Something is wrong with the analyzer included setting (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][jj];	return 1
							endif
						endfor 
					
					endfor
					//Gather the filenames in the list and put the in the right order to be fed into runfilenames
					for(jj = 3;  jj <6  ; jj+=1)
						if(jj>3)
						if(stringmatch(angledata_listPOL[0][jj],"00") || stringmatch(angledata_listPOL[0][jj], "0")) //if reflectangle1 is 0, disregard row 2^4=48=selected button otherwise 32
							continue
						endif
						endif
						for(ii = 0;  ii <4  ; ii+=1)	
						 	if(measwithanalyzer==1)
								if(strlen(angledata_listPOL[ii][jj])<=0|| !(angledata_selPOL[ii][1] & 2^4))
									tempangledata_listPOL = "00"
								else 
									tempangledata_listPOL = 	angledata_listPOL[ii][jj]
								endif
							elseif(measwithanalyzer==0)
								if(strlen(angledata_listPOL[ii][jj])<=0|| !(angledata_selPOL[ii][1] & 2^4))
									tempangledata_listPOL = "0"
								else 
									tempangledata_listPOL = 	angledata_listPOL[ii][jj]
								endif
							else
								print "ERROR - Could not sort out the filename order (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][jj];	return 1
							endif	
							fileNameList += tempangledata_listPOL+";"
						endfor
						for(ii = 0;  ii <4  ; ii+=1)
							rr=jj+3 //in order to cover the direct beams
						 	if(measwithanalyzer==1)
								if(strlen(angledata_listPOL[ii][rr])<=0|| !(angledata_selPOL[ii][1] & 2^4))
									tempangledata_listPOL = "00"
								else 
									tempangledata_listPOL = 	angledata_listPOL[ii][rr]
								endif
							elseif(measwithanalyzer==0)
								if(strlen(angledata_listPOL[ii][rr])<=0|| !(angledata_selPOL[ii][1] & 2^4))
									tempangledata_listPOL = "0"
								else 
									tempangledata_listPOL = 	angledata_listPOL[ii][rr]
								endif
							else
								print "ERROR - Could not sort out the filename order (SLIMPOL_buttonprocpol)",  angledata_listPOL[ii][rr];	return 1
							endif
							
							//we might assume, that if no first direct beam is given, only a spectrum output will be given
							//if the first direct beam but no second direct beam is given, we might replace it with the first.
							if(!stringmatch(angledata_listPOL[ii][6],"00") && !stringmatch(angledata_listPOL[ii][6], "0"))
								if(stringmatch(angledata_listPOL[ii][rr],"00") || stringmatch(angledata_listPOL[ii][rr], "0"))
										tempangledata_listPOL=angledata_listPOL[ii][6]
								endif
							endif
							fileNameList += tempangledata_listPOL+";"
						endfor
						fileNameList = removeending(fileNameList,";")
						fileNameList += ":"		
					endfor
						fileNameList = removeending(fileNameList,":")	
						
						//some of the scalefactors might yet not be given, but we need them...
						variable sc1,sc2,sc3,sc4
						sc1 = str2num(angledata_listPOL[0][2]);sc2=str2num(angledata_listPOL[1][2]);sc3=str2num(angledata_listPOL[2][2]);sc4=str2num(angledata_listPOL[3][2])
						if(numtype(sc1))
								sc1 = 1
							if((angledata_selPOL[0][1] & 2^4))
								print "Warning setting scale factor I00 to 1 "
							endif
						endif
						if(numtype(sc2))
							 sc2 = 1
							if((angledata_selPOL[1][1] & 2^4))
							print "Warning setting scale factor I01 to 1 "
						endif
						endif
						if(numtype(sc3))
							 sc3 = 1
							if((angledata_selPOL[2][1] & 2^4))
							print "Warning setting scale factor I10 to 1 "
						endif
						endif
						if(numtype(sc4))
							 sc4 = 1
							if((angledata_selPOL[3][1] & 2^4))
							print "Warning setting scale factor I11 to 1 "
						endif
						endif
						if(stringmatch(stringfromlist(0,filenamelist),"00")&&stringmatch(stringfromlist(3,filenamelist),"00"))
							print "ERROR, you need to give at least the first angles of I00=R-- (or I0=R-) and I11=R++ (or I1=R+) for this to work!"
							printf "Aborting the reduction\r\r"
							break
						elseif(stringmatch(stringfromlist(0,filenamelist),"0")&&stringmatch(stringfromlist(3,filenamelist),"0"))
							print "ERROR, you need to give at least the first angles of I00=R-- (or I0=R-) and I11=R++ (or I1=R+) for this to work!"
							printf "Aborting the reduction\r\r"
							break
						endif
						
						if(!streamedReduction)
							template =  " Polarized Reduction(\"%s\",\"%s\",scale I00 = %g,scale I01 = %g,scale I10 = %g,scale I11 = %g,\"%s\",%g,%g,%g,background = %g,water=\"%s\", expected_peak=cmplx(%g, NaN), manual = %g, dontoverwrite = %g, normalise = %g, saveSpectrum = %g, saveoffspec=%g, verbose=%g)"
							sprintf cmd, template,inputpathStr,outputPathStr,sc1,sc2,sc3,sc4, fileNameList,lowLambda,highLambda, rebinning,  backgroundsbn,waterrunfile, expected_centre, manualbeamfind, donotoverwrite, normalisebymonitor, saveSpectrum, saveoffspec, verbosevar
							cmdToHistory(cmd)
							if(PolarizedReduction(inputpathStr, outputPathStr, sc1, sc2,sc3,sc4,fileNameList, lowlambda, highlambda, rebinning, water=waterrunfile, background=backgroundsbn, expected_peak= cmplx(expected_centre, NaN), manual=manualbeamfind, dontoverwrite=donotoverwrite, normalise=normalisebymonitor, saveSpectrum=saveSpectrum, saveoffspec=saveoffspec, verbose=verbosevar))
								print "ERROR something went wrong when calling Polarized Reduction reduce (SLIMPOL_buttonprocpol)";  return 1
							endif
						else
							print "streamed reductionshould not happen!"
							//template =  "reduceasinglefile(\"%s\",\"%s\",%s,\"%s\",%g,%g,%g,background = %g,water=\"%s\", expected_peak=cmplx(%g, NaN), manual = %g, dontoverwrite = 1, normalise = %g, saveSpectrum = %g, saveoffspec=%g, timeslices = ??wave??)"
							//sprintf cmd, template, replacestring("\\", inputpathStr, "\\\\"), replacestring("\\", outputpathStr, "\\\\"), angledata_list[ii][2], fileNameList,lowLambda,highLambda, rebinning,  backgroundsbn,water, expected_centre, manualbeamfind, normalisebymonitor, saveSpectrum, saveoffspec
							//cmdToHistory(cmd)								
							//if(!strlen(reduceASingleFile(inputpathStr, outputPathStr, str2num(angledata_list[ii][2]), fileNameList,lowLambda,highLambda, rebinning, background = backgroundsbn, water = water, expected_peak = cmplx(expected_centre, NaN), manual=manualbeamfind, dontoverwrite = 1, normalise = normalisebymonitor, saveSpectrum = saveSpectrum, saveoffspec=saveoffspec)))//, timeslices=timeslices
							//	print "ERROR something went wrong when calling reduce (SLIM_buttonproc)";  return 1
							//endif
						endif
					break
				case "showreducervariables_tab0":
					if(ba.eventmod==9)
						printf "--Click to open a new panel in which the reducer variables are specified.--\r"
						printf "Careful, the values change if you open a panel for unpolarized reduction.\r\r"
						break
					endif 
					reducerVariablesPanelPOL() 
					break
				case "downloadPlatdata_tab0":
					if(ba.eventmod==9)
						printf "--Click to download PLATYPUS data from the server (Internet connection required).--\r\r"
						break
					endif 
					GetFileFolderInfo/q/z inputpathStr
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath to place the downloaded files"
						return 0	
					endif
					downloadplatypusdata(inputPathStr = inputPathStr)
					break
				case "plot_tab0":
					if(ba.eventmod==9)
						printf "--Plot raw and reduced PLATYPUS data.--\r\r"
						break
					endif 
					Doalert 1, "Are the files you want to view in the input directory (YES) or the output directory (NO)?"
					string thePathstring = ""
					if(V_flag == 1)
						thePathstring = inputpathStr
						fileFilterStr = ".hdf;.xml;.itx;.xrdml;.spectrum;"
					elseif(V_flag == 2)
						thePathstring = outputpathStr
						fileFilterStr = ".xml;.itx;.xrdml;.spectrum;.hdf;"
					endif
					
					GetFileFolderInfo/q/z thePathstring
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath for the data source"
						return 0	
					endif
					//did you want to rebin?
					rebinning = rebinpercent
									
					//find the files with the new multiopenfiles XOP
					Newpath/o/q/z pla_temppath_read, thePathstring
					open/MULT=1/r/P=pla_temppath_read/d/M="Select the files you wish to view"/F=fileFilterStr refnum

					killpath/z pla_temppath_read
					if(V_Flag!=0)
						return 0
					endif

					string pathSep
					strswitch(UpperStr(IgorInfo(2)))
						case "MACINTOSH":
							pathSep = ":"
							break
						case "WINDOWS":
							pathSep = "\\"
							break
					endswitch
										
					thePathstring = Parsefilepath(1, Stringfromlist(0, S_filename, "\r"), pathSep, 1, 0)					
					filenames = ""

					for(ii=0 ; ii<itemsinlist(S_filename, "\r") ; ii+=1)
						filenames += ParseFilePath(0, stringfromlist(ii, S_filename, "\r"), pathSep, 1, 0)+";"
					endfor
					
					if(itemsinlist(filenames, "\r")==0)
						return 0
					endif
					
					sprintf cmd, "slim_plot(\"%s\",\"%s\",\"%s\",%g,%g,%g,expected_peak=cmplx(%g, %g), rebinning=%g, manual=%g, normalise=%g, saveSpectrum = %g)",inputPathStr, outputPathStr, filenames, lowLambda,highLambda, backgroundsbn,expected_centre, NaN, rebinpercent, manualbeamfind, normalisebymonitor, saveSpectrum
					cmdToHistory(cmd)
						
					if(slim_plot(thePathstring, outputPathStr, fileNames,lowLambda,highLambda,backgroundsbn, expected_peak = cmplx(expected_centre, NaN), rebinning = rebinpercent, manual = manualbeamfind, normalise = normalisebymonitor, saveSpectrum = saveSpectrum))
						print "ERROR while trying to plot (SLIM_buttonproc)"
						return 0
					endif
					break
				case "clear_tab0":
					if(ba.eventmod==9)
						printf "--Clear all data entered in the datafiles table. The parameters specified in the reducer variables and the waterrun remain.--\r\r"
						break
					endif 
					angledata_listPOL=""
					angledata_listPOL[0][0] = "I00: OFF/OFF = R--"
					angledata_listPOL[1][0] = "I01: OFF/ON = R-+"
					angledata_listPOL[2][0] = "I10: ON/OFF = R+-"
					angledata_listPOL[3][0] = "I11: ON/ON = R++"
					//angledata_selPOL[][0] = 0x01
					angledata_selPOL[][1] = 0x20//2^5
					angledata_selPOL[][2]=0x02
					angledata_selPOL[][3]=0x02
					angledata_selPOL[][4]=0x02
					angledata_selPOL[][5]=0x02
					angledata_selPOL[][6]=0x02
					angledata_selPOL[][7]=0x02
					angledata_selPOL[][8]=0x02
					angledata_selPOL[][][1]= 1
								
				break
				case "storeangleslist_tab0":
					if(ba.eventmod==9)
						printf "--Store the list of angles to IGOR in order to recall the table at a later state. --\r"
						break
					endif 
						string dest, destination, selectfile
						tempoutputpathStr = ""
						Prompt dest, "Please enter a name for the list to be stored (no special characters, no spaces)."
						Prompt destination, "Do you want to store the list to hard drive? Type in a destination file name"
						Prompt selectfile, "Or select file from disk below to overwrite an existing file.", popup, "New file;Select file from disk to overwrite"
						string helper="No special characters or spaces allowed.\r The ending _StoredAnglelist will be added to the string.\r If a name is given in second line, file will be saved to hard drive.\r The path given in the reducer panel will be used."
						DoPrompt/HELP=helper "Enter destination", dest, destination, selectfile
						if(V_Flag)
							break
						elseif(strlen(dest)>0)
						storestringlist = "root:packages:platypus:data:Reducer:" + dest + "_StoredAnglelist"
						make/n=(23,9)/o/t $(storestringlist) //list
						wave/t storelist = $(storestringlist)
						storelist = ""
						storelist[0][] = angledata_listPOL[0][q]						
						storelist[1][] = angledata_listPOL[1][q]
						storelist[2][] = angledata_listPOL[2][q]
						storelist[3][] = angledata_listPOL[3][q]
						storelist[4][] = num2str(angledata_selPOL[0][q])						
						storelist[5][] = num2str(angledata_selPOL[1][q])
						storelist[6][] = num2str(angledata_selPOL[2][q])
						storelist[7][] = num2str(angledata_selPOL[3][q])
						storelist[8][0] = "Input Path"; storelist[8][1] = inputpathStr; 
						storelist[9][0] = "Output Path"; storelist[9][1] = outputpathStr;
						storelist[10][0] = "Waterrun"; storelist[10][1] = waterrunfile;
						storelist[11][0] = "Low Wavelength"; storelist[11][1] = num2str(lowLambda);
						storelist[12][0] = "High Wavelength"; storelist[12][1] = num2str(highLambda);
						storelist[13][0] = "Rebin %tage"; storelist[13][1] = num2str(rebinpercent);
						storelist[14][0] = "expected centre"; storelist[14][1] = num2str(expected_centre);
						storelist[15][0] = "Background Subtraction"; storelist[15][1] = num2str(backgroundsbn);
						storelist[16][0] = "Manual Beam Find"; storelist[16][1] = num2str(manualbeamfind);
						storelist[17][0] = "Normalize By Monitor"; storelist[17][1] = num2str(normalisebymonitor);
						storelist[18][0] = "Save Spectrum"; storelist[18][1] = num2str(saveSpectrum);
						storelist[19][0] = "Save Offspecular Map"; storelist[19][1] = num2str(saveoffspec);
						storelist[20][0] = "Meas with Ana"; storelist[20][1] = num2str(measwithanalyzer);
						storelist[21][0] = "Dont Overwrite"; storelist[21][1] = num2str(donotoverwrite);
						storelist[22][0] = "Verbose"; storelist[22][1] = num2str(verbosevar);
						else
							print "Nothing written to internal IGOR storage."
						endif
						
						
						if(V_Flag)
							break
						elseif(stringmatch(selectfile,"Select file from disk to overwrite"))
							GetFileFolderInfo/q/z outputpathStr
							if(V_flag)//path doesn't exist
								Doalert 0, "Please enter a valid filepath to place the downloaded files"
								return 0	
							endif
						 	thepolPath = outputpathStr
							Newpath/o/q/z pla_temppath_read, thepolPath
							Variable refNum
							String fileFilters = "Data Files (*.dat):.dat;"
							fileFilters += "All Files:.*;"

							Open /D /R /F=fileFilters /P=pla_temppath_read /M="Select a file" refNum
							if(strlen(S_fileName)>0)
								tempoutputpathStr = S_fileName
								storefilelist = itemsinlist(S_fileName, ":")
								S_filename = stringfromlist(storefilelist-1,S_fileName, ":")
								destination =  replacestring("_StoredAnglelist.dat", S_fileName, "")
							else
								destination = ""
								tempoutputpathstr = ""
							endif	
							killpath/z pla_temppath_read
						endif
						if(strlen(destination)>0)
							storestringlisttemp = "root:packages:platypus:data:Reducer:" + destination + "_StoredAnglelist"
						make/n=(23,9)/o/t $(storestringlisttemp) //list
						wave/t storelisttemp = $(storestringlisttemp)
						storelisttemp = ""
						storelisttemp[0][] = angledata_listPOL[0][q]						
						storelisttemp[1][] = angledata_listPOL[1][q]
						storelisttemp[2][] = angledata_listPOL[2][q]
						storelisttemp[3][] = angledata_listPOL[3][q]
						storelisttemp[4][] = num2str(angledata_selPOL[0][q])						
						storelisttemp[5][] = num2str(angledata_selPOL[1][q])
						storelisttemp[6][] = num2str(angledata_selPOL[2][q])
						storelisttemp[7][] = num2str(angledata_selPOL[3][q])
						storelisttemp[8][0] = "Input Path"; storelisttemp[8][1] = inputpathStr; 
						storelisttemp[9][0] = "Output Path"; storelisttemp[9][1] = outputpathStr;
						storelisttemp[10][0] = "Waterrun"; storelisttemp[10][1] = waterrunfile;
						storelisttemp[11][0] = "Low Wavelength"; storelisttemp[11][1] = num2str(lowLambda);
						storelisttemp[12][0] = "High Wavelength"; storelisttemp[12][1] = num2str(highLambda);
						storelisttemp[13][0] = "Rebin %tage"; storelisttemp[13][1] = num2str(rebinpercent);
						storelisttemp[14][0] = "expected centre"; storelisttemp[14][1] = num2str(expected_centre);
						storelisttemp[15][0] = "Background Subtraction"; storelisttemp[15][1] = num2str(backgroundsbn);
						storelisttemp[16][0] = "Manual Beam Find"; storelisttemp[16][1] = num2str(manualbeamfind);
						storelisttemp[17][0] = "Normalize By Monitor"; storelisttemp[17][1] = num2str(normalisebymonitor);
						storelisttemp[18][0] = "Save Spectrum"; storelisttemp[18][1] = num2str(saveSpectrum);
						storelisttemp[19][0] = "Save Offspecular Map"; storelisttemp[19][1] = num2str(saveoffspec);
						storelisttemp[20][0] = "Meas with Ana"; storelisttemp[20][1] = num2str(measwithanalyzer);
						storelisttemp[21][0] = "Dont Overwrite"; storelisttemp[21][1] = num2str(donotoverwrite);
						storelisttemp[22][0] = "Verbose"; storelisttemp[22][1] = num2str(verbosevar);
						if(strlen(tempoutputpathStr)>0)
							tempoutputpathStr = removeending(tempoutputpathStr, destination + "_StoredAnglelist.dat") 
						else 
							tempoutputpathStr = outputpathstr
							print "Output set to the OUTPUTPATH specified!!"
						endif	
							GetFileFolderInfo/q/z tempoutputpathStr
						if(V_flag)//path doesn't exist
							Doalert 0, "Error, Could not open the specified file."
							return 0	
						endif
						if(strlen(tempoutputpathStr)>0)
							thepolPath = tempoutputpathStr
							tempdeststring = destination +  "_StoredAnglelist"+".dat"
						else
							print "ERROR, Could not open the specified file.  (SLIMPOL_buttonprocpol(ba))"
							return 0	
						endif
						Newpath/o/q/z pla_temppath_read, thepolPath
						open/P=pla_temppath_read storefilelist as tempdeststring						
						if(V_flag)
							print "ERROR writing reducer parameters to disk (SLIMPOL_buttonprocpol(ba))";	 abort
						endif
						storestringlisttemp = "root:packages:platypus:data:Reducer:"
						make/n=(23,1)/o/t $(storestringlisttemp+"temp1") //list
						wave/t storelisttemp1 = $(storestringlisttemp+"temp1")
						storelisttemp1[][] = storelisttemp[p][0]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp2") //list
						wave/t storelisttemp2 = $(storestringlisttemp+"temp2")
						storelisttemp2[][] = storelisttemp[p][1]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp3") //list
						wave/t storelisttemp3 = $(storestringlisttemp+"temp3")
						storelisttemp3[][] = storelisttemp[p][2]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp4") //list
						wave/t storelisttemp4 = $(storestringlisttemp+"temp4")
						storelisttemp4[][] = storelisttemp[p][3]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp5") //list
						wave/t storelisttemp5 = $(storestringlisttemp+"temp5")
						storelisttemp5[][] = storelisttemp[p][4]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp6") //list
						wave/t storelisttemp6 = $(storestringlisttemp+"temp6")
						storelisttemp6[][] = storelisttemp[p][5]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp7") //list
						wave/t storelisttemp7 = $(storestringlisttemp+"temp7")
						storelisttemp7[][] = storelisttemp[p][6]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp8") //list
						wave/t storelisttemp8 = $(storestringlisttemp+"temp8")
						storelisttemp8[][] = storelisttemp[p][7]
						make/n=(23,1)/o/t $(storestringlisttemp+"temp9") //list
						wave/t storelisttemp9 = $(storestringlisttemp+"temp9")
						storelisttemp9[][] = storelisttemp[p][8]
						wfprintf storefilelist, "", storelisttemp1, storelisttemp2, storelisttemp3, storelisttemp4, storelisttemp5, storelisttemp6, storelisttemp7, storelisttemp8, storelisttemp9  //storelisttemp[1][q], storelisttemp[2][q], storelisttemp[3][q], storelisttemp[4][q], storelisttemp[5][q], storelisttemp[6][q], storelisttemp[7][q], storelisttemp[7][q], storelisttemp[8][q],  
						close storefilelist
						//Save/O/J/P=pla_temppath_read $(storestringlisttemp) as tempdeststring
						killwaves/z storelisttemp, storelisttemp1 , storelisttemp2, storelisttemp3, storelisttemp4, storelisttemp5, storelisttemp6, storelisttemp7, storelisttemp8, storelisttemp9 
						if(strlen(tempoutputpathStr)>0)
							print "File \"" + destination + "_StoredAnglelist"+ ".dat\" written to disk:" + tempoutputpathStr
						endif
						else 
							print "No name specified, nothing written to hard drive."
						endif
						killpath/z pla_temppath_read
					break	
				case "loadangleslist_tab0":
					if(ba.eventmod==9)
						printf "--Choose from a list of stored angle list to fill the table.\r\r"
						printf "--The list will be empty if there are no stored data lists.\r\r"
						break
					endif 
					string listofwaves
					setdatafolder root:packages:platypus:data:Reducer:
					listofwaves = wavelist("*_StoredAnglelist",";","")
					popupcontextualmenu "-Load from disk-;"+listofwaves
					if(V_Flag<=0)
						V_Flag = 0
					endif
					switch(V_Flag)
					case 0: 
						print "No item selected"
						break
					case 1:
						GetFileFolderInfo/q/z outputpathStr
						tempoutputpathStr = outputpathStr
						if(V_flag)//path doesn't exist
							Doalert 0, "The path given in the output directory is not valid.\r Will open default folder."
							//return 0
							tempoutputpathStr = ""	
						endif
						thepolPath = tempoutputpathStr
						Newpath/o/q/z pla_temppath_read, thepolPath
						LoadWave/A=temploadwave/o/H/k=2/J/p=pla_temppath_read/L={0,0,0,0,0}/m
		
						if(V_Flag>0)					
						wave/t storelist = $("root:packages:platypus:data:Reducer:temploadwave0")
						waterrunfile = storelist[7][1] 
						angledata_listPOL[0][] = storelist[0][q]
						angledata_listPOL[1][] = storelist[1][q]
						angledata_listPOL[2][] = storelist[2][q]
						angledata_listPOL[3][] = storelist[3][q]
						angledata_selPOL[0][][0] = str2num(storelist[4][q])
						angledata_selPOL[1][][0] = str2num(storelist[5][q])
						angledata_selPOL[2][][0] = str2num(storelist[6][q])
						angledata_selPOL[3][][0] = str2num(storelist[7][q])
						angledata_selPOL[][][1] = 1
						inputpathStr = storelist[8][1] 
						outputpathStr= storelist[9][1]
						waterrunfile= storelist[10][1]
						lowLambda= str2num(storelist[11][1])
						highLambda= str2num(storelist[12][1])
						rebinpercent= str2num(storelist[13][1])
						expected_centre= str2num(storelist[14][1])
						backgroundsbn= str2num(storelist[15][1] )
						manualbeamfind= str2num(storelist[16][1])
						normalisebymonitor= str2num(storelist[17][1] )
						saveSpectrum= str2num(storelist[18][1] )
						saveoffspec= str2num(storelist[19][1])
						measwithanalyzer =str2num(storelist[20][1])
						donotoverwrite= str2num(storelist[21][1])
						verbosevar= str2num(storelist[22][1])
						killpath/z pla_temppath_read
						killwaves/z storelist
						print "File Loaded, the wave is not assigned in IGOR."
						print "Store IGOR internally to recall."
						else
						 print "No file specified!"
						endif
						
						break
					default:
						string templist = removeending(S_selection, "_StoredAnglelist")
						loadstringlist = "root:packages:platypus:data:Reducer:" + S_selection
						wave/t storelist = $(loadstringlist)
						waterrunfile = storelist[7][1] 
						angledata_listPOL[0][] = storelist[0][q]
						angledata_listPOL[1][] = storelist[1][q]
						angledata_listPOL[2][] = storelist[2][q]
						angledata_listPOL[3][] = storelist[3][q]
						angledata_selPOL[0][][0] = str2num(storelist[4][q])
						angledata_selPOL[1][][0] = str2num(storelist[5][q])
						angledata_selPOL[2][][0] = str2num(storelist[6][q])
						angledata_selPOL[3][][0] = str2num(storelist[7][q])
						angledata_selPOL[][][1] = 1
						inputpathStr = storelist[8][1] 
						outputpathStr= storelist[9][1]
						waterrunfile= storelist[10][1]
						lowLambda= str2num(storelist[11][1])
						highLambda= str2num(storelist[12][1])
						rebinpercent= str2num(storelist[13][1])
						expected_centre= str2num(storelist[14][1])
						backgroundsbn= str2num(storelist[15][1] )
						manualbeamfind= str2num(storelist[16][1])
						normalisebymonitor= str2num(storelist[17][1] )
						saveSpectrum= str2num(storelist[18][1] )
						saveoffspec= str2num(storelist[19][1])
						measwithanalyzer =str2num(storelist[20][1])
						donotoverwrite= str2num(storelist[21][1])
						verbosevar= str2num(storelist[22][1])
					endswitch
					
	
					setdatafolder $cdf
					break	
				case "changedatasource_tab0":
					if(ba.eventmod==9)
						printf "--Click to insert a path to the folder where the data can be found.\r\r"
						printf "All files you want to reduce need to be in the same folder.--\r\r"
						break
					endif 
					getfilefolderinfo/q/z=2/d ""
					if(V_flag == 0)
						inputpathStr = S_path
					endif
					break
				case "changedataout_tab0":
					if(ba.eventmod==9)
						printf "--Specify a path to a folder where the output of the reduction can be stored.--\r\r"
						break
					endif 
					getfilefolderinfo/q/z=2/d ""
					if(V_flag == 0)
						outputpathStr = S_path
					endif
					break
			endswitch	
			break
			
	endswitch
	setdatafolder $cDF
	return 0
End
Function POLSLIM_analyzercheckbox(bana) : CheckBoxControl
	STRUCT WMCheckboxAction &bana
	NVAR measwithanalyzer= root:packages:platypus:data:Reducer:measwithanalyzer	
	variable ii,jj
	Wave/t angledata_listPOL = root:packages:platypus:data:Reducer:angledata_listPOL
	Wave angledata_selPOL= root:packages:platypus:data:Reducer:angledata_selPOL

	switch(measwithanalyzer)
		case 1://"measwithanalyzer_tab0":
			if(bana.eventmod==9)
				printf "Toggle between a measurement performed with or without analyser to separate the neutron spin state after reflection \r"
				printf "i.e. the neutron spin before and after the sample is distinguished (with analyzer):"
				printf "R--, R-+, R+-, R++\r"
				printf "or not (without analyzer):\r"
				printf "R-, R+\r\r"
				break
			endif
			for(ii=0 ; ii < dimsize(angledata_listPOL, 0) ; ii+=1) 
				if(strlen(angledata_listPOL[ii][3]) == 0 || !(angledata_selPOL[ii][1] & 2^4)) //if reflectangle1 is 0, disregard row 2^4=48=selected button otherwise 32
					continue
				endif
				for(jj = 3; jj <= 8 ; jj+=1)
						if(strlen(angledata_listPOL[ii][jj])<=0)
							angledata_listPOL[ii][jj] = "00"
						endif
						if(stringmatch(angledata_listPOL[ii][jj],"0"))
							angledata_listPOL[ii][jj] = "00"
						endif
				endfor
			endfor
			angledata_listPOL[0][0] = "I00: OFF/OFF = R--"
			angledata_listPOL[1][0] = "I01: OFF/ON = R-+"
			angledata_listPOL[2][0] = "I10: ON/OFF = R+-"
			angledata_listPOL[3][0] = "I11: ON/ON = R++"
		break
		case 0:
			if(bana.eventmod==9)
				printf "Toggle between a measurement performed with or without analyser to separate the neutron spin state after reflection \r"
				printf " i.e. the neutron spin before and after the sample is distinguished (with analyzer):"
				printf "R--, R-+, R+-, R++\r"
				printf " or not (without analyzer):\r"
				printf "R-, R+ (leave other fields blank)\r\r"
				break
			endif
			for(ii=0 ; ii < dimsize(angledata_listPOL, 0) ; ii+=1) 
				if(strlen(angledata_listPOL[ii][3]) == 0 || !(angledata_selPOL[ii][1] & 2^4)) //if reflectangle1 is 0, disregard row 2^4=48=selected button otherwise 32
							continue
				endif
				for(jj = 3; jj <= 8 ; jj+=1)
						if(strlen(angledata_listPOL[ii][jj])<=0)
							angledata_listPOL[ii][jj] = "0"
						endif
						if(stringmatch(angledata_listPOL[ii][jj],"00"))
							angledata_listPOL[ii][jj] = "0"
						endif
				endfor
			endfor
			angledata_listPOL[0][0] = "I0: Flipper OFF = R-"
			angledata_listPOL[1][0] = "Not available: disregarded"
			angledata_listPOL[2][0] = "Not available: disregarded"
			angledata_listPOL[3][0] = "I1: Flipper ON = R+"
			ListBox whichangles userColumnResize=1
			break
		endswitch
End

Function POLSLIM_verbosecheckbox(verb) : CheckBoxControl
	STRUCT WMCheckboxAction &verb
	NVAR donotoverwrite= root:packages:platypus:data:Reducer:verbosevar
	switch(donotoverwrite)
	case 1://"measwithanalyzer_tab0":
		if(verb.eventmod==9)
			printf "Execute the reduction with an extended description of the process printed in the IGOR Command Window.\r"
			printf "This is more to for programmers to understand the code flow.\r\r"
			break
		endif
	break
	case 0:
		if(verb.eventmod==9)
			printf "Execute the reduction with an extended description of the process printed in the IGOR Command Window.\r"
			printf "This is more to for programmers to understand the code flow.\r\r"
			break
		endif
	break
	endswitch
End


Function POLSLIM_donotoverwritecheckbox(donoov) : CheckBoxControl
	STRUCT WMCheckboxAction &donoov
	NVAR donotoverwrite= root:packages:platypus:data:Reducer:donotoverwrite
	switch(donotoverwrite)
		case 1://"measwithanalyzer_tab0":
			if(donoov.eventmod==9)
				printf "If \"Do not overwrite is ticked, previous reductions will not be overwritten.\r"
				printf "The new reduced data will be appended with an incremental _0, _1, ... after the filename.\r"
				printf "If the box is NOT active, old data will be overwritten.\r\r"
				break
			endif
		break
		case 0:
			if(donoov.eventmod==9)
				printf "If \"Do not overwrite is ticked, previous reductions will not be overwritten.\r"
				printf "The new reduced data will be appended with an incremental _0, _1, ... after the filename.\r"
				printf "If the box is NOT active, old data will be overwritten.\r\r"
				break
			endif
		break
		endswitch
End


















 	


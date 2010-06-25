#pragma rtGlobals=1		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

//TODO all distances, chopper frequencies should be read from NeXUS file

//opening of the choppers, in radians
	Constant O_C1 = 1.04719755
	Constant O_C2 = 0.17453293
	Constant O_C3 = 0.43633231
	Constant O_C4 = 1.04719755
	Constant O_C1d = 60
	Constant O_C2d = 10
	Constant O_C3d = 25
	Constant O_C4d = 60

	Constant DISCRADIUS = 350
	
	//default distances.  These should normally be read from the NeXUS file.
	constant C_CHOPPER1_DISTANCE = 0
	constant C_CHOPPER2_DISTANCE = 103
	constant C_CHOPPER3_DISTANCE = 359
	constant C_CHOPPER4_DISTANCE = 808
	constant C_SLIT2_DISTANCE = 1909.9
	constant C_SLIT3_DISTANCE = 4767.9
	constant C_GUIDE1_DISTANCE = NaN
	constant C_GUIDE2_DISTANCE = NaN
	constant C_SAMPLE_DISTANCE = 5045.4

	//Physical Constants
	Constant PLANCK = 6.624e-34
	Constant NEUTRONMASS = 1.6749286e-27
	Constant P_MN = 3.9548e-7
	
	//the constants below may change frequently
	Constant Y_PIXEL_SPACING = 1.177	//in mm
	Constant CHOPFREQ = 23		//Hz
	Constant ROUGH_BEAM_POSITION = 150		//Rough direct beam position
	constant ROUGH_BEAM_WIDTH = 10
	Constant CHOPPER1_PHASE_OFFSET = -0.7903
	Constant CHOPPAIRING = 3
		
	//StrConstant PATH_TO_DATA = "Macintosh HDD:Users:andrew:Documents:Andy:Platypus:TEMP:"


Function reduce(pathName, scalefactor,runfilenames, lowlambda, highlambda, rebin, [water, background, expected_centre, manual, dontoverwrite])
	string pathName
	variable scalefactor
	string runfilenames
	variable lowLambda,highLambda, rebin
	string water
	variable background, expected_centre, manual, dontoverwrite
	
	//produces a reflectivity curve for a given set of angles
	//returns 0 if successful, non zero otherwise
	
	//scalefactor = data is divided by this number to produce a correct critical edge.
	//runfilenames = run names for reflected and direct data in key:value; form.  i.e. "PLP303:PLP302;PLP304:PLP302"	
	//lowLambda = cutoff, wavelengths below this value are discarded.
	//highLambda = cutoff, wavelengths above this value are discarded.
	
	//OPTIONAL
	//water = runfile containing water data
	//background = whether you want to subtract background (1=TRUE, 0 = FALSE)
	//expected_centre = where you expect to see the specular ridge, in detector pixels
	//manual = 1 if you would like to manually choose beam centres/FWHM, otherwise it is done automatically
	//dontoverwrite = 1 if you want to create unique names everytime you reduce the file. (default == 0)
	
	//this function must load the data using loadNexusfile, then call processNexusfile which produces datafolders containing
	//containing the spectrum (W_spec, W_specSD, W_lambda, W_lambdaSD,W_specTOFHIST,W_specTOF,W_LambdaHIST)

	//to create reflectivity one simply divides the reflected spectrum by the direct spectrum.
	//Remembering to propagate the errors in quadrature.
	//A resolution wave is also calculated.  The wavelength contribution is calculated in processNexusfile
	//the angular part is calculated here.
	
	//writes out the file in Q <tab> R <tab> dR <tab> dQ format.
	
	string tempStr,cDF,directDF,angle0DF, alreadyLoaded="", toSplice="", direct = "", angle0="",tempDF, reductionCmd
	variable ii,D_S2, D_S3, D_SAMPLE,domega, spliceFactor, bmon1_counts_Direct, bmon1_counts_angle0,temp, isDirect, aa,bb,cc,dd,jj,kk
	
	cDF = getdatafolder(1)
	
	//setup the datafolders
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	//directory for the reduction package
	Newdatafolder /o root:packages:platypus:data:Reducer
	tempDF = "root:packages:platypus:data:Reducer:"

	//set up the default parameters
	if(paramisdefault(water))
		water = ""
	endif
	if(paramisdefault(background))
		background = 1
	endif
	if(paramisdefault(expected_centre))
		expected_centre = ROUGH_BEAM_POSITION
	endif
	if(paramisdefault(manual))
		manual = 0
	endif
	if(paramisdefault(dontoverwrite))
		dontoverwrite = 0
	endif
	
	//create the reduction string for this particular operation.  THis is going to be saved in the datafile.
	sprintf reductionCmd, "reduce(\"%s\",%g,\"%s\",%g,%g,%g,background = %g,water=\"%s\", expected_centre=%g, manual = %g, dontoverwrite = %g)",pathName, scalefactor, runfilenames,lowLambda,highLambda, rebin,  background,water, expected_centre, manual, dontoverwrite
	
	try
		setdatafolder "root:packages:platypus:data:Reducer"
		//set the data to load
		Newpath/o/q/z PATH_TO_DATA,pathName
		PATHinfo PATH_TO_DATA
		if(!V_flag)
			print "ERROR pathname not valid (loadNexusfile)";abort
		endif

		//check the scalefactor is reasonable
		if(numtype(scalefactor) || scalefactor==0)
			print "ERROR a non sensible scale factor was entered (reduce) - setting scalefactor to 1";	
			scalefactor = 1 
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
	
		//iterate through the runnames and check they're valid
		if(itemsinlist(runfilenames)==0)
			print "ERROR no runs will be reduced if you don't give any (reduce)";abort
		endif
		
		if(!paramisdefault(water) && strlen(water)>0)
			if(!datafolderexists("root:packages:platypus:data:Reducer:"+cleanupname(removeending(water,".nx.hdf"),0)))
				if(loadNexusFile(pathName, water))
					print "Error loading water run (reduce)"
					abort
				endif
			endif
		endif
		

		//make the rebin wave, to rebin both direct and reflected data
		if(rebin)
			make/o/d/n= (round(log(highlambda/lowlambda)/log(1+rebin/100))+1) W_rebinBoundaries
			W_rebinboundaries = lowlambda * (1+rebin/100)^p
		endif
		for(ii=0 ;  ii< itemsinlist(runfilenames) ; ii+=1)
			angle0 = stringfromlist(0, stringfromlist(ii,runfilenames), ":")
			direct = stringbykey(angle0, runfilenames)
			if(strlen(angle0)==0 || strlen(direct)==0)
				print "ERROR parsing the runfilenamesstring (reduce)"; abort
			endif

			//start off by processing the direct beam run
			if(whichlistitem(direct,alreadyLoaded)==-1)	//if you've not loaded the direct beam for that angle do so.
				isDirect = 1
				if(loadNexusfile(S_path, direct))
					print "ERROR couldn't load direct beam run (reduce)";abort
				endif
				if(rebin)
					if(processNeXUSfile(direct, background, lowLambda, highLambda, water = water, isDirect = isDirect, expected_centre = expected_centre, rebinning = W_rebinboundaries,manual=manual))
						print "ERROR while processing a direct beam run (reduce)" ; abort
					endif
				else
					if(processNeXUSfile(direct, background, lowLambda, highLambda, water = water, isDirect = isDirect, expected_centre = expected_centre, manual =manual))
						print "ERROR while processing a direct beam run (reduce)" ; abort
					endif				
				endif

				alreadyLoaded += direct+";"	
			endif
			
			directDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(direct,".nx.hdf"),0)
			if(!datafolderexists(directDF))
				Print "ERROR, direct beam not loaded: (reduce)"; abort
			endif
			
			Wave W_specD = $(directDF+":W_spec"); AbortOnRTE
			Wave W_specDSD = $(directDF+":W_specSD"); AbortOnRTE			
			Wave M_topandtailD = $(directDF+":M_topandtail"); AbortOnRTE			
			Wave W_lambdaD = $(directDF+":W_lambda"); AbortOnRTE
			Wave W_lambdaHISTD = $(directDF+":W_lambdaHIST"); AbortOnRTE
			Wave/z W_uncorrectedGravityCentre = $(directDF+":W_uncorrectedgravityCentre"); AbortOnRTE
			Wave DetectorPosD = $(directDF+":instrument:detector:longitudinal_translation"); AbortOnRTE
			Wave DetectorHeightD = $(directDF+":instrument:detector:vertical_translation")
			Wave W_directbeampos = $(directDF+":W_beampos"); AbortOnRTE

			//
			//load in and process reflected angle
			//
			if(loadNexusfile(S_path, angle0))
				print "ERROR couldn't load a reflected beam run, "+angle0 + " (reduce)";
				abort
			endif

			//when you process the reflected nexus file you have to use the lambda spectrum from the direct beamrun
			if(processNeXUSfile(angle0, background, lowLambda, highLambda, water = water, isDirect = 0, expected_centre = expected_centre, rebinning = W_lambdaHISTD, manual=manual))
				print "ERROR while processing a reflected beam run (reduce)" ; abort
			endif
			
			//to keep track of what we have to splice and save
			toSplice += angle0 + ";"
			
			//check that the angle0 data has been loaded into a folder and processed
			angle0DF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(angle0,".nx.hdf"),0)
			if(!datafolderexists(angle0DF))
				Print "ERROR, data from angle file "+ angle0 + " not loaded: (reduce)"
				abort
			endif
			
			//create a string to hold the reduction string.
			string/g $(angle0DF+":reductionCmd") = reductionCmd
			
			Wave W_specA0 = $(angle0DF+":W_spec"); AbortOnRTE
			Wave W_specA0SD = $(angle0DF+":W_specSD"); AbortOnRTE
			Wave M_topandtailA0 = $(angle0DF+":M_topandtail"); AbortOnRTE
			Wave M_topandtailA0SD = $(angle0DF+":M_topandtailSD"); AbortOnRTE

			Wave DetectorPosA0 = $(angle0DF+":instrument:detector:longitudinal_translation"); AbortOnRTE
			Wave W_beamposA0 = $(angle0DF+":W_beampos"); AbortOnRTE
			Wave DetectorHeightA0 = $(angle0DF+":instrument:detector:vertical_translation")

			Wave sth = $(angle0DF+":sample:sth"); AbortOnRTE
			
			if((DetectorPosA0[0] - DetectorPosD[0])>0.1)
				Print "ERROR, detector dy for direct and reduced data not the same: (reduce)"; abort
			endif
			
			//work out the actual angle of incidence from the peak position on the detector
			//this will depend on the mode
			Wave/t mode = $(angle0DF+":instrument:parameters:mode")
			//create an omega wave
			Wave W_lambda = $(angle0DF+":W_lambda"); AbortOnRTE
			Wave W_lambdaHIST = $(angle0DF+":W_lambdaHIST"); AbortOnRTE
			Wave W_specTOFHIST = $(angle0DF+":W_specTOFHIST"); AbortOnRTE
			Wave W_specTOF = $(angle0DF+":W_specTOF"); AbortOnRTE

			duplicate/o W_lambda, $(angle0DF+":omega")
			Wave omega = $(angle0DF+":omega")
			//create a twotheta wave, and a qz, qx wave
			duplicate/o M_topandtailA0, $(angle0DF + ":M_twotheta")
			duplicate/o M_topandtailA0, $(angle0DF + ":M_omega")
			duplicate/o M_topandtailA0, $(angle0DF + ":M_qz")	
			duplicate/o M_topandtailA0, $(angle0DF + ":M_qy")					
			duplicate/o M_topandtailA0, $(angle0DF + ":M_qzSD")			
			duplicate/o M_topandtailA0, $(angle0DF + ":M_ref")
			duplicate/o M_topandtailA0, $(angle0DF + ":M_refSD")	
			duplicate/o W_lambdaHIST, $(angle0DF + ":W_qHIST")
			Wave M_twotheta = $(angle0DF + ":M_twotheta")
			Wave M_omega = $(angle0DF + ":M_omega")
			Wave M_qz = $(angle0DF + ":M_qz")
			Wave M_qy = $(angle0DF + ":M_qy")
			Wave M_qzSD = $(angle0DF + ":M_qzSD")
			Wave M_ref =  $(angle0DF + ":M_ref")
			Wave M_refSD =  $(angle0DF + ":M_refSD")
			Wave W_qHIST = $(angle0DF + ":W_qHIST")
	
			variable loPx, hiPx
			loPx = numberbykey( "loPx", note(M_topandtailA0))
			hiPx = numberbykey("hiPx", note(M_topandtailA0))
			
			strswitch(mode[0])
				case "FOC":
				case "MT":
					//					omega = Pi*sth[0]/180
					multithread	 omega = atan(((W_beamposA0 + DetectorHeightA0[0]) - (W_directbeampos + DetectorHeightD[0]))/DetectorposA0[0])/2
					multithread M_twotheta[][] = atan((( (q * Y_PIXEL_SPACING) + DetectorHeightA0[0]) - (W_directbeampos[p] + DetectorHeightD[0]))/DetectorposA0[0])
					break
				case "SB":
					//					Wave m1ro =  $(angle0DF+":instrument:collimator:rotation");ABORTonRTE
					//					omega = m1ro[0]
					multithread omega = atan(((W_beamposA0 + DetectorHeightA0[0]) - (W_directbeampos + DetectorHeightD[0]))/(2*DetectorposA0[0]))
					multithread M_twotheta[][] = omega[p] + atan((((q * Y_PIXEL_SPACING) + DetectorHeightA0[0]) - (W_directbeampos[p] + DetectorHeightD[0]) - (DetectorposA0[0] * tan(omega[p])))/DetectorposA0[0])
					break
				case "DB":		//angle of incidence for DB is always 4.8
					//					omega = 4.8 * Pi/180
					multithread omega = atan(((W_beamposA0 + DetectorHeightA0[0]) - (W_directbeampos + DetectorHeightD[0]))/(2*DetectorposA0[0]))
					multithread M_twotheta[][] = omega[p] + atan((((q * Y_PIXEL_SPACING) + DetectorHeightA0[0]) - (W_directbeampos[p] + DetectorHeightD[0]) - (DetectorposA0[0] * tan(omega[p])))/DetectorposA0[0])
					break
			endswitch
			print "corrected angle of incidence for ",angle0, " is: ~",180*omega[0]/pi

			//within the specular band omega changes slightly
			//used for constant Q integration.
			multithread M_omega = M_twotheta/2
			
			//now normalise the counts in the reflected beam by the direct beam spectrum
			//this gives a reflectivity
			//and propagate the errors, leaving the fractional variance (dr/r)^2
			//this step probably produces negative reflectivities, or NaN if W_specD is 0.
			//ALSO, 
			//M_refSD has the potential to be NaN is M_topandtailA0 or W_specD is 0.
			multithread M_ref[][] = M_topandtailA0[p][q] / W_specD[p]
//			M_refSD[][] =   (M_topandtailA0SD[p][q] / M_topandtailA0[p][q])^2 +(W_specDSD[p] / W_specD[p])^2 
			M_refSD = 0	
			multithread M_refSD[][] += numtype((M_topandtailA0SD[p][q] / M_topandtailA0[p][q])^2) ? 0 : (M_topandtailA0SD[p][q] / M_topandtailA0[p][q])^2
			multithread M_refSD[][] += numtype((W_specDSD[p] / W_specD[p])^2) ? 0 : (W_specDSD[p] / W_specD[p])^2						
			
			//now calculate the Q values for the detector pixels.  Each pixel has different 2theta and different wavelength, ASSUME that they have the same angle of incidence
			multithread M_qz[][]  = 2 * Pi * (1 / W_lambda[p]) * (sin(M_twotheta[p][q] - omega[p]) + sin(M_omega[p][q]))
			multithread M_qy[][] = 2 * Pi * (1 / W_lambda[p]) * (cos(M_twotheta[p][q] - omega[p]) - cos(M_omega[p][q]))

			//work out the uncertainty in Q.
			//the wavelength contribution is already in W_LambdaSD
			//now have to work out the angular part and add in quadrature.
			Wave W_lambdaSD = $(angle0DF+":W_lambdaSD"); AbortOnRTE
			multithread M_qzSD[][] = (W_lambdaSD[p] / W_lambda[p])^2
			
			//angular part of uncertainty
			Wave ss2vg = $(angle0DF+":instrument:slits:second:vertical:gap")
			Wave ss3vg = $(angle0DF+":instrument:slits:third:vertical:gap")
			Wave slit2_distance = $(angle0DF+":instrument:parameters:slit2_distance")
			Wave slit3_distance = $(angle0DF+":instrument:parameters:slit3_distance")
			D_S2 = slit2_distance[0]
			D_S3 = slit3_distance[0]
			domega = 0.68 * sqrt((ss2vg[0]^2 + ss3vg[0]^2) / ((D_S3 - D_S2)^2))
			
			//now calculate the full uncertainty in Q for each Q pixel
			multithread M_qzSD += (domega/omega[p])^2
			multithread M_qzSD = sqrt(M_qzSD)
			multithread M_qzSD *= M_qz
			
			//scale reflectivity by scale factor
			// because refSD is stil fractional variance (dr/r)^2 have to divide by scale factor squared.
			multithread M_ref /= scalefactor
			multithread M_refSD /= (scalefactor)^2
			
			//correct for the beam monitor one counts.  This assumes that the direct beam was measured with the same
			//slit characteristics as the reflected beam.  This assumption is normally ok for the first angle.  One can only hope that everyone
			//have done this for the following angles.
			//multiply by bmon1_direct/bmon1_angle0

			if(exists(angle0DF+":monitor:bm1_counts")==1 && exists(directDF+":monitor:bm1_counts")==1)
				Wave/z bmon1_Direct = $(directDF+":monitor:bm1_counts")
				Wave/z bmon1_angle0 = $(angle0DF+":monitor:bm1_counts")
				if(bmon1_Direct[0] != 0 && bmon1_angle0[0] != 0)
					bmon1_counts_direct = bmon1_direct[0]
					bmon1_counts_angle0 = bmon1_angle0[0]
					temp =  ((sqrt(bmon1_counts_direct)/bmon1_counts_direct)^2 + (sqrt(bmon1_counts_angle0)/bmon1_counts_angle0)^2) //(dratio/ratio)^2
					
					multithread M_refSD += temp		//M_refSD is still fractional variance at this point.
					multithread M_ref *= bmon1_counts_direct/bmon1_counts_angle0
				endif
			endif
			//M_refSD is still (dr/r)^2
			multithread M_refSD = sqrt(M_refSD)
			multithread M_refSD *= M_ref
			
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
			histtopoint(W_qHIST)
			Wave W_point
			duplicate/o W_point, $(angle0DF + ":W_q")
			duplicate/o W_point, $(angle0DF + ":W_qSD")
			Wave W_q = $(angle0DF + ":W_q")
			Wave W_qSD = $(angle0DF + ":W_qSD")
//			LambdatoQ(W_qHIST, W_lambdaHIST, omega)
			LambdatoQ(W_q, W_lambda, omega)
			
			W_qSD[] = (W_lambdaSD[p]/W_lambda[p])^2+(domega/omega[p])^2
			W_qSD = sqrt(W_qSD)
			W_qSD *= W_q

			duplicate/o W_q, $(angle0DF+":W_ref")
			duplicate/o M_ref, $(angle0DF+":M_reftemp")
			duplicate/o M_refSD, $(angle0DF+":M_refSDtemp")

			Wave W_ref = $(angle0DF + ":W_ref")
			Wave M_reftemp = $(angle0DF + ":M_reftemp")
			Wave M_refSDtemp = $(angle0DF + ":M_refSDtemp")
			
			deletepoints/M=1 hiPx+1, dimsize(M_ref,1), M_reftemp,M_refSDtemp
			deletepoints/M=1 0, loPx, M_reftemp,M_refSDtemp

			imagetransform sumallrows M_reftemp
			Wave W_sumrows
			W_ref = W_sumrows
			
			duplicate/o W_ref, $(angle0DF+":W_refSD")
			Wave W_refSD = $(angle0DF + ":W_refSD")
			W_refSD = 0
			for(jj=0 ; jj<dimsize(M_reftemp,1) ; jj+=1)
				W_refSD[] += M_refSDtemp[p][jj]^2
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
			Sort W_q,W_q,W_ref,W_refSD,W_qSD

			variable fileID
			string fname = cutfilename(angle0) + ".dat"
			if(dontoverwrite)
				fname = uniqueFileName(S_path, fname, ".dat")
			endif
			open/P=path_to_data/z=1 fileID as fname
			
			if(V_flag==0)
				fprintf fileID, "Q (1/A)\t Ref\t dRef (SD)\t dq(FWHM, 1/A)\n"
				wfprintf fileID, "%g\t %g\t %g\t %g\n" W_q,W_ref,W_refSD,W_qSD
				close fileID
			endif
			pathinfo path_to_data
			//this only writes XML for a single file
			writeXML(S_path,angle0, dontoverwrite)
			
			//write a 2D XMLfile for the offspecular data
//			write2DXML(S_path, angle0, dontoverwrite)
			Sort/R W_q,W_q,W_ref,W_refSD,W_qSD
		endfor
		//at this point, outside the for block, one should have reduced all the individual angles
		//the runnames to splice are in the variable toSplice.
		//splice these, sort them and write to a combined file.

		//THey are spliced from file, rather from memory, this is because one may want to delete individual points using
		//delrefpoints.  If you want to do this then do the reduction, delrefpoints, then call splicefiles again.
		print "splicefiles(\"" + replacestring("\\", pathname, "\\\\") + "\", \"" + toSplice + "\",  dontoverwrite = " + num2istr(dontoverwrite) + "rebin = " + num2str(rebin) + ")"
		if(spliceFiles(pathName, toSplice, dontoverwrite = dontoverwrite, rebin = rebin))
			print "ERROR while splicing (reduce)";abort
		endif		
	catch
		killwaves/z W_q,W_ref,W_qSD,W_refSD, M_reftemp, M_refSDtemp
		
		Print "ERROR: an abort was encountered in (reduce)"
		setdatafolder $cDF
		return 1
	endtry

	killwaves/z W_q,W_ref,W_qSD,W_refSD, M_reftemp, M_refSDtemp
	setdatafolder $cDF
	return 0
End

Function sumWave(wav,p1,p2)
	Wave wav
	variable p1,p2
	variable summ,ii,temp
	if(p2<p1)
		temp = p2
		p2 = p1
		p1 = temp
	endif

	for(ii=0 ; ii<p2; ii+=1)
		summ+=wav[ii]
	endfor
	return summ
end

Function/t cutFileName(filename)
	string filename
	//this function cuts a filename like "PLP00000054" down to "PLP54"
	//returns the shortened name as a string.
	variable ii
	string ret = ""
	
	return filename
	
	variable len = strlen(filename)
	variable isNumber = 0
	for(ii=0 ; ii<len ; ii+=1)
		if(!stringmatch(filename[ii],"0"))
			ret+=filename[ii]
		endif
	endfor
	return ret
End

Function/t uniqueFileName(pathStr, filename, ext)
	string pathStr, filename, ext
		string theFiles, theUniqueName = ""
		variable ii
		Newpath/o/q/z PATH_TO_DATA, pathStr
		PATHinfo PATH_TO_DATA
		if(!V_flag)
			print "ERROR pathname not valid (uniqueFileName)";abort
		endif
		
		theFiles = indexedFile(PATH_TO_DATA, -1, ext)
		theUniqueName = filename
		//the file already exists, increment a number
		for(ii=1; whichListItem(theUniqueName, theFiles) > -1 ; ii+=1)
			theUniqueName = "o" + num2istr(ii) + "_" + filename
		endfor 
		return theUniqueName
End

Function expandStrIntoPossibleFileName(fileStub, righteousFileName)
	//expands a possible fileStub into a correct Nexus filename.
	string fileStub, &righteousFileName

	string tempStr = ""
	variable size

	if(numtype(str2num(fileStub)) == 0)	//fileStub is a number like 302, so expand it to PLP0000203
		size = strlen(fileStub)
		if(str2num(fileStub) < 0 || size > 7)
			return 1
		endif
		sprintf tempstr, "PLP%0.7d.nx.hdf",str2num(fileStub)
	else			//the filestub begins with alphabetical characters, so the user probably supplied the whole thing, apart from the ending
		tempStr = fileStub + ".nx.hdf"
	endif

	righteousFileName = removeending(tempStr,".nx.hdf")
	return 0
End

Function loadNeXUSfile(pathname, filename)
	string pathname, fileName
	//loads a NeXUS file, fileName, from the path contained in the pathName string.
	//returns 0 if successful, non zero otherwise
	string tempDF = "",cDF = "", temp
	variable fileRef, err, number

	cDF = getdatafolder(1)
	
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	Newdatafolder /o root:packages:platypus:data:Reducer
	
	Newpath/o/q/z PATH_TO_DATA, pathName
	pathinfo PATH_TO_DATA
	if(!V_flag)//path doesn't exist
		print "ERROR please set valid path (SLIM_PLOT_scans)"
		return 1	
	endif
	
	//full file path may be given
	filename = removeending(parsefilepath(0, filename, "*", 1, 0), ".nx.hdf")	
	sscanf filename, "PLP%d",number
	
	try
		//open the file and load the data
		tempDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(filename,".nx.hdf"),0)

		for(;;)
			if(doesNexusfileExist("PATH_TO_DATA", filename+".nx.hdf"))
				hdf5openfile/P=PATH_TO_DATA/r/z fileRef as filename+".nx.hdf"
			else
				doalert 1, "Couldn't find beam file: "+filename+". Do you want to try and download it from the server?"
				if(V_flag==2)
					print "ERROR: couldn't open beam file: (loadNexusfile)"; abort
				else
					if(downloadplatypusdata(pathname=pathname, lowFi = number, hiFi = number +1))
						print "ERROR while trying to download platypus data from server (loadNexusfile)";abort
					endif
				endif
			else
				break
			endif
		endfor
		newdatafolder/o $tempDF

		hdf5loadgroup/CONT=1/r/o/z $tempDF,fileRef,"entry1/"	
	catch
		if(fileRef)
			hdf5closefile fileRef
		endif
		setdatafolder $cDF
		killdatafolder/z $tempDF	
		return 1
	endtry
	
	if(fileRef)
		hdf5closefile fileRef
	endif	
	setdatafolder $cDF
	return 0
End

Function doesNexusfileExist(pathName, filename)
	string pathName, fileName

	string files = indexedfile($pathName, -1, ".hdf")
	variable pos = whichlistitem(filename, files)
	if(pos==-1)
		return 0
	else
		return 1
	endif
End

Function processNeXUSfile(filename, background, loLambda, hiLambda[, water, scanpoint,isDirect, expected_centre, expected_width, omega, two_theta, rebinning,manual])
	string fileName
	variable background, loLambda, hiLambda
	string water
	variable scanpoint, isDirect, expected_centre, expected_width, omega, two_theta, manual
	Wave/z rebinning
	//processes a loaded NeXUS file.
	//returns 0 if successful, non zero otherwise

	//water is a filename for a normalisation run, typically a SANS scattering through a water cuvette.
	//freq = chopper frequency, in Hz
	//expected_centre = pixel position for specular beam
	//expected_width = FWHM width in pixels of specular beam
	//pairing = the chopper pairing used (2, 3 or 4)  Default = 3
	//manual = 1 for manual specification of specular ridge
	//rebinning = a wave containing new wavelength bins
	
	//first thing we will do is  average over x, possibly rebin, subtract background on timebin by time bin basis, then integrate over the foreground
	//files will be loaded into root:packages:platypus:data:Reducer:+cleanupname(removeending(fileStr,".nx.hdf"),0)
	
	//OUTPUT
	//W_Spec,W_specSD,W_lambda,W_lambdaSD,W_lambdaHIST,W_specTOF,W_specTOFHIST, W_waternorm, W_beampos
	
	variable ChoD, toffset, nrebinpnts,ii, D_CX, phaseAngle, pairing, freq, poff, calculated_width, temp
	string tempDF,cDF,tempDFwater
	Wave/z hmmWater
	
	//create the data folder structure
	cDF = getdatafolder(1)
	
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	Newdatafolder /o root:packages:platypus:data:Reducer
	
	if(loLambda <= 0)
		loLambda = 0.1
	endif
	if(hiLambda < loLambda)
		hiLambda = loLambda+1
	endif
	
	try
		//check the data is loaded
		tempDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(filename,".nx.hdf"),0)
		if(!datafolderexists(tempDF))
			print "ERROR: you have not loaded ",filename," (processNexusfile)"
			abort
		endif
			
		//pre-average the data over x
		//hmm[scanpoint][t][y][x]
		setdatafolder $tempDF
		Wave hmm = $(tempDF+":data:hmm")
		if(paramisdefault(scanpoint) && dimsize(hmm,0)>1)
			scanpoint = 0
			prompt scanpoint, "Enter an integer scanpoint number 0<= scanpoint<="+num2istr(dimsize(hmm,0)-1)
			doprompt filename,scanpoint
			if(V_Flag)
			print "DIDN'T WANT TO ENTER A scanpoint (processNexusFile)"
				abort
			endif
		endif
		if(wavedims(hmm) != 4)
			print "ERROR: dataset must be saved as HISTOGRAM_XYT to be handled correctly (processNexusfile)"
			abort
		endif
		if(dimsize(hmm,0)-1 < scanpoint)
			print "ERROR: you are trying to access a scanpoint outside a valid limit (processNexusfile)"
			abort
		endif
		make/o/i/u/n=(dimsize(hmm,1),dimsize(hmm,2),dimsize(hmm,3)) detector
		multithread detector[][][] = hmm[scanpoint][p][q][r]
		imagetransform sumplanes, detector
		duplicate/o M_sumplanes, detector
		duplicate/o detector, detectorSD
		multithread detectorSD = sqrt(detectorSD)
		killwaves/z M_sumplanes
		
		//check the waterrun is loaded
		if(!paramisdefault(water) && strlen(water)>0)
			tempDFwater = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(water,".nx.hdf"),0)
			if(!datafolderexists(tempDFwater))
				print "specified water run not already loaded (processNexusfile)"
				abort
			endif
			Wave hmmWater = $(tempDFwater+":data:hmm");AbortonRTE
			if(!waveexists($"root:packages:platypus:data:Reducer:"+cleanupname(removeending(water,".nx.hdf"),0)+":W_waternorm"))
				if(createWaterNormalisationWave(hmmWater, fileName))
					print "ERROR: creating water normalisation array (processNexusfile)"
					abort
				endif
			endif
			Wave W_waternorm = $"root:packages:platypus:data:Reducer:"+cleanupname(removeending(water,".nx.hdf"),0)+":W_waternorm"
			Wave W_waternormSD = $"root:packages:platypus:data:Reducer:"+cleanupname(removeending(water,".nx.hdf"),0)+":W_waternormSD"
			
			if(numpnts(W_Waternorm) != Dimsize(detector,1))
				print "ERROR: water normalisation run doesn't have the same number of y pixels as the data it is trying to normalise (processNexusfile)"
				abort
			endif
			
			for(ii=0; ii<dimsize(detector,0) ; ii += 1)
				multithread detectorSD[ii][] = (detectorSD[ii][q]/detector[ii][q])^2+(W_waternormSD[q]/W_waternorm[q])^2
				multithread detector[ii][] /= W_waternorm[q]
				multithread detectorSD[ii][] = sqrt(detectorSD[ii][q]) * (detector[ii][q])
			endfor
			//this step could've created INFs and NaN, as there are divide by 0 when you divide by detector[ii][q]
			multithread detectorSD = numtype(detectorSD[p][q]) ? 0 : detectorSD[p][q]
		endif

		if(paramisdefault(manual))
			manual = 0
		endif
		
		if(paramisdefault(expected_centre))
			expected_centre = ROUGH_BEAM_POSITION
		endif
		
		//figure out if you are doing a directbeam run
		if(paramisdefault(isDirect))
			Doalert 1,"Is "+ filename + " a direct beamrun?"
			if(V_Flag == 1)
				isDirect = 1
			else
				isDirect = 0
			endif
		endif

		//work out the "supposed" omega and two_theta values
		if(paramisdefault(omega))
			Wave W_omega = $(tempDF+":instrument:parameters:omega")
			omega = W_omega[scanpoint]
		endif
		if(paramisdefault(two_theta))
			Wave W_two_theta = $(tempDF+":instrument:parameters:twotheta")
			two_theta = W_two_theta[scanpoint]
		endif
		
		//work out what the total expected width of the beam is
		//from De Haan1995
		Wave  ss2vg = $(tempDF+":instrument:slits:second:vertical:gap")
		Wave ss3vg = $(tempDF+":instrument:slits:third:vertical:gap")
		Wave sample_distance = $(tempDF+":instrument:parameters:sample_distance")
		Wave slit3_distance = $(tempDF+":instrument:parameters:slit3_distance")
		Wave slit2_distance = $(tempDF+":instrument:parameters:slit2_distance")
		Wave DetectorPos = $(tempDF+":instrument:detector:longitudinal_translation")
		
		if(paramisdefault(expected_width))
			calculated_width = 2 * (ss3vg[scanpoint]/2 + ((ss2vg[scanpoint] + ss3vg[scanpoint])*(detectorpos[scanpoint]+sample_distance[scanpoint]-slit3_distance[scanpoint])/(2*(slit3_distance[scanpoint]-slit2_distance[scanpoint])))) / Y_PIXEL_SPACING
			expected_width = 2.5* calculated_width +2
		endif
		
		//work out what the disc spacing is
		Wave chopper1_distance = $(tempDF+":instrument:parameters:chopper1_distance")
		Wave chopper2_distance = $(tempDF+":instrument:parameters:chopper2_distance")
		Wave chopper3_distance = $(tempDF+":instrument:parameters:chopper3_distance")
		Wave chopper4_distance = $(tempDF+":instrument:parameters:chopper4_distance")
		
		//setup the default parameters, such as distance, chopper frequency, etc.
		//the phase definitions are as follows:
		//
		// When the PHASE ANGLE=0 then the leading edge of the secondary chopper is aligned with the 
		// trailing edge of the master chopper.
		//
		// The PHASE OFFSET accounts for the fact that the choppers aren't perfectly setup and describes the angular offset required
		// to make the PHASE ANGLE 0.
		//
		//	A POSITIVE phase angle would lead to a phase OPENING, i.e. a direct line of sight.
		//   Hence a POSITIVE phase offset would move the choppers towards a phase opening.
		//  
		//	A NEGATIVE phase angle means that one starts to remove lower wavelengths from the beam.
		//
		//   For example: the nominal phase operation of chopper 3 is 42.5 degrees, with a phase offset of 0.33 degrees.
		//   if one wants a phase opening of 2 degrees one would move the phase
		//    of chopper 3 to 42.5-0.33-2. = 40.17
		//  For a phase closing of 2, move to 42.5-0.33+2 = 44.17
		//  If the phase offset was -0.33 then the first case one changes to 42.5+0.33-2 = 40.83, the second at 44.83.
		// 
		// This applies towards choppers 2 and 3.  It is slightly different for chopper 4.  For this the nominal operating
		// phase is -60 degrees.  A phase opening for this chopper is towards 0.  I.e. For a phase opening of 1 degrees operate at
		// -59 and vice versa.
		//  Thus a positive phase offset for chopper 4, such as 0.23 degrees, one would operate the choppers at -59.79 degrees.  
		// If a phase opening of 2 degrees is required then would operate at -60+0.23+2 = -57.79.
		
		
		if(exists(tempDF + ":instrument:disk_chopper:ch1speed")==1)
			Wave frequency = $(tempDF+":instrument:disk_chopper:ch1speed")
			freq  = frequency[scanpoint] / 60
		
			Wave ch2speed = $(tempDF + ":instrument:disk_chopper:ch2speed")
			Wave ch3speed = $(tempDF + ":instrument:disk_chopper:ch3speed")
			Wave ch4speed = $(tempDF + ":instrument:disk_chopper:ch4speed")
			Wave ch2phase = $(tempDF + ":instrument:disk_chopper:ch2phase")
			Wave ch3phase = $(tempDF + ":instrument:disk_chopper:ch3phase")
			Wave ch4phase = $(tempDF + ":instrument:disk_chopper:ch4phase")
			Wave ch2phaseoffset = $(tempDF + ":instrument:parameters:chopper2_phase_offset")
			Wave ch3phaseoffset = $(tempDF + ":instrument:parameters:chopper3_phase_offset")
			Wave ch4phaseoffset = $(tempDF + ":instrument:parameters:chopper4_phase_offset")
			
			if(abs(ch2speed[scanpoint]) > 10)
				pairing = 2
				D_CX = chopper2_distance[scanpoint]
				phaseangle = -ch2phase[scanpoint] - ch2phaseoffset[scanpoint] + 0.5*(O_C2d+O_C1d)
			elseif(abs(ch3speed[scanpoint]) > 10)
				pairing = 3
				D_CX = chopper3_distance[scanpoint]
				phaseangle = -ch3phase[scanpoint] - ch3phaseoffset[scanpoint] +0.5*(O_C3d+O_C1d)
			else
				pairing = 4
				D_CX = chopper4_distance[scanpoint]
				phaseangle = ch4phase[scanpoint] - ch4phaseoffset[scanpoint] + 0.5*(O_C4d+O_C1d)
			endif
		else		
			D_CX = C_Chopper3_distance
			pairing = CHOPPAIRING
			phaseAngle = 0
			freq = CHOPFREQ
		endif

		//work out the total flight length
		chod = ChoDCalculator(fileName, omega, two_theta, pairing = pairing, scanpoint = scanpoint)
		if(numtype(chod))
			print "ERROR, chod is NaN (processNexusdata)"
			abort
		endif		

		//setup time of flight paraphenalia
		Wave TOF = $(tempDF+":data:time_of_flight")
		duplicate/o TOF, $(tempDF+":W_specTOFHIST")
		Wave W_specTOFHIST
				
		//toffset - the time difference between the magnet pickup on the choppers (TTL pulse), which is situated in the middle of the chopper window, and the trailing edge of chopper 1, which 
		//is supposed to be time0.  However, if there is a phase opening this time offset has to be relocated slightly, as time0 is not at the trailing edge.
		if(exists(tempDF + ":instrument:parameters:chopper1_phase_offset") == 1)
			Wave ch1phaseoffset = $(tempDF + ":instrument:parameters:chopper1_phase_offset")
			poff = ch1phaseoffset[scanpoint]
		else
			poff = CHOPPER1_PHASE_OFFSET
		endif
		variable poffset = 1e6 * poff/(2*360*freq)
		toffset = poffset + (1e6*O_C1/2/(2*Pi)/freq) - (1e6*phaseAngle/(360*2*freq))
		W_specTOFHIST -=toffset
		
		//convert TOF to lambda	
		TOFtoLambda(W_specTOFHIST,ChoD)
		Wave W_lambda
		duplicate/o W_lambda, $(tempDF+":W_lambdaHIST")
		Wave W_lambdaHIST
		histtopoint(W_lambdaHIST)
		Wave W_point
		duplicate/o W_point, $(tempDF+":W_lambda")

		//now we need to find out where the beam hits the detector
		variable/c peak_params
		if(manual || findspecridge(detector, 50, 0.01, expected_centre,expected_width,peak_params) || numtype(real(peak_params)) || numtype(imag(peak_params)))
			//use the following procedure to find the specular ridge
			userSpecifiedArea(detector, peak_Params)

			//			imagetransform sumallcols detector
			//			duplicate/o W_sumcols, xx
			//			xx = p
			//			peak_params = cmplx(Pla_peakcentroid(xx,W_sumcols),expected_width)
	
			//			peak_params = cmplx(expected_centre, calculated_width)
			killwaves/z W_sumcols,xx
		endif
								
		//if you are a direct beam do a gravity correction, but have to recalculate centre.
		if(isDirect)
			variable lobin = (real(peak_params)-4 - 1.3*imag(peak_params)/2) , hiBin = (real(peak_params)+4 + 1.3*imag(peak_params)/2)
			correct_for_gravity(detector, detectorSD, W_lambda, 0, loLambda, hiLambda, lobin, hiBin)
			Wave M_gravitycorrected, M_gravitycorrectedSD
			duplicate/o M_gravitycorrected, $(tempDF+":Detector")
			duplicate/o M_gravitycorrectedSD, $(tempDF+":DetectorSD")
			killwaves/z M_gravitycorrected, M_gravitycorrectedSD
			if(findspecridge(detector, 50, 0.01, expected_centre,expected_width, peak_params) || numtype(real(peak_params)) || numtype(imag(peak_params)))
			//use the following procedure to find the specular ridge
				userSpecifiedArea(detector, peak_Params)
			endif	
		endif

		//someone provided a wavelength spectrum BIN EDGES to rebin to.
		variable hiPoint, loPoint
		if(!paramisdefault(rebinning) && waveexists(rebinning))		
			loPoint = binarysearch(rebinning, loLambda)
			hiPoint = binarySearch(rebinning, hiLambda)
			if(0 <= hiPoint)
				deletepoints hiPoint+1, numpnts(rebinning), rebinning		
			endif
			if(0 <= loPoint)
				deletepoints 0, loPoint+1, rebinning
			endif
			//rebin detector image
			if(Pla_2DintRebin(W_lambdaHIST, detector, detectorSD, rebinning))
				print "ERROR while rebinning detector pattern (processNexusfile)"
				abort
			endif
			Wave M_rebin, M_rebinSD
			duplicate/o M_rebin,  $(tempDF+":detector")
			duplicate/o M_rebinSD,  $(tempDF+":detectorSD")
			Wave detector, detectorSD
			
			duplicate/o rebinning, W_lambdaHIST
			LambdatoTOF(W_lambdaHIST, chod)

			Wave W_tof
			duplicate/o W_tof,  $(tempDF+":W_specTOFHIST")
			Wave W_specTOFHIST
			
			killwaves/z W_tof, M_rebin, M_rebinSD
		else		//delete the lolambda and hilambda cutoffs
			loPoint = binarysearch(W_lambdaHIST, loLambda)
			hiPoint = binarySearch(W_lambdaHIST, hiLambda)
			if(0 <= hiPoint)
				//these are histogram bins
				deletepoints hiPoint+1, numpnts(W_lambdaHIST), W_lambdaHIST, W_specTOFHIST		
				//these aren't
				deletepoints hiPoint, numpnts(W_lambdaHIST), detector, detectorSD
			endif
			if(0 <= loPoint)
				deletepoints 0, loPoint+1, W_lambdaHIST, detector, detectorSD, W_specTOFHIST
			endif
		endif
		
		//convert histogrammed TOF and lambda to their point counterparts
		histTOPoint(W_specTOFHIST)
		Wave W_point
		duplicate/o W_point, $(tempDF+":W_specTOF")
		Wave W_specTOF
		
		histToPoint(W_lambdaHIST)
		Wave W_point
		duplicate/o W_point, $(tempDF+":W_lambda")
		Wave W_lambda
		
		//Now work out where the beam hits the detector
		//this is used to work out the correct angle of incidence.
		//it will be contained in a wave called beampos
		//beampos varies as a fn of wavelength due to gravity

		if(isDirect)
			//the spectral ridge for the direct beam has a gravity correction involved with it.
			//the correction coefficients for the beamposition are contaned in W_gravCorrCoefs
			Wave W_gravCorrCoefs = $(tempDF+":W_gravCorrCoefs")
			duplicate/o W_lambda, $(tempDF+":W_beampos")
			Wave W_beampos = $(tempDF+":W_beampos")
			
			W_beampos = deflec(W_gravCorrCoefs, W_lambda)	
			
			//the following correction assumes that the directbeam neutrons are falling from a point position W_gravCorrCoefs[1] before the detector
			//At the sample stage (W_gravcorrcoefs[1] - detectorpos[0]) they have a certain vertical velocity, assuming that the neutrons had an initial vertical velocity of 0
			// Although the motion past the sample stage will be parabolic, assume that the neutrons travel in a straight line after that (i.e. the tangent of the parabolic motion at the sample stage)
			// this should give an idea of the direction of the true incident beam, as experienced by the sample
			//Factor of 2 is out the front to give an estimation of the increase in 2theta of the reflected beam.
		//	W_beampos[] = W_gravCorrCoefs[1] -2 * ((1/Y_PIXEL_SPACING) * 1000 * 9.81 * ((W_gravCorrCoefs[0] - detectorPos[scanpoint])/1000) * (detectorPos[scanpoint]/1000) * W_lambda[p]^2/((P_MN*1e10)^2))
			
			W_beampos = W_beampos*Y_PIXEL_SPACING
		else
			make/o/n=(numpnts(W_lambda)) $(tempDF+":W_beampos")
			Wave W_beampos = $(tempDF+":W_beampos")
			W_beampos = (real(peak_params) * Y_PIXEL_SPACING)
		endif
	
		if(topAndTail(detector, detectorSD, real(peak_params), imag(peak_params), background))
			print "ERROR while topandtailing (processNexusdata)"
			abort
		endif			
		
		//the output from the topAndTail process is the background subtracted spectrum, etc.
		duplicate/o root:packages:platypus:data:Reducer:W_spec , $(tempDF+":W_spec")
		duplicate/o root:packages:platypus:data:Reducer:W_specSD , $(tempDF+":W_specSD")
		duplicate/o root:packages:platypus:data:Reducer:M_topAndTail , $(tempDF+":M_topAndTail")
		duplicate/o root:packages:platypus:data:Reducer:M_topAndTailSD , $(tempDF+":M_topAndTailSD")
		Wave W_spec = $(tempDF+":W_spec")
		Wave M_topAndTail = $(tempDF+":M_topandtail")
		Wave M_topAndTailSD = $(tempDF+":M_topandtailSD")
	
		//now work out dlambda/lambda, the resolution contribution from wavelength.
		//vanWell, Physica B,  357(2005) pp204-207), eqn 4.
		//this is only an approximation for our instrument, as the 2nd and 3rd discs have smaller
		//openings compared to the master chopper.  Therefore the burst time needs to be looked at.
		//W_point should still be the point version of the TOFhistogram.
		duplicate/o W_lambda, $(tempDF+":W_lambdaSD")
		wave W_lambdaSD = $(tempDF+":W_lambdaSD")
		//account for the width of the time bin
		W_LambdaSD = ((W_specTOFHIST[p+1]-W_specTOFHIST[p])/(W_specTOF[p]))^2
		//account for the gross resolution of the chopper, adding in a contribution if you have a phase
		//opening.  (don't forget freq is in Hz, W_point is in us.
		W_LambdaSD += ((D_CX/ChoD)+(phaseAngle/(360*freq*1e-6*W_specTOF[p])))^2
		
		variable tauH = (1e6*ss2vg[scanpoint]/(DISCRADIUS*2*Pi*freq))
		W_LambdaSD += (tauH/(W_specTOF[p]))^2
		W_LambdaSD *= 0.68^2
		W_lambdaSD = sqrt(W_LambdaSD)
		W_lambdaSD *= W_lambda
	
		killwaves/z W_point, detector, detectorSD
		setdatafolder $cDF
		return 0
	catch
		//	killwaves/z W_point, detector, detectorSD
		setdatafolder $cDF
		return 1
	endtry
End


Function writeXML(pathName, runnumbers, dontoverwrite)
	string pathName,runnumbers
	variable dontoverwrite
	 
	//a function to write an XML description of the reduced dataset.
	variable fileID,ii,jj
	string df = "root:packages:platypus:data:Reducer:"
	string qqStr="",RRstr="",dRStr="", dqStr = "",filename, prefix = ""

	if(itemsinlist(runnumbers) == 0)
		print "ERROR, no runs to write (writeXML)"
		return 1
	endif
	for(ii=0 ; ii<itemsinlist(runnumbers) ; ii+=1)
		if(!Datafolderexists(df+stringfromlist(ii,runnumbers)))
			print "ERROR one or more of the runs doesn't exist (writeXML)"
			return 1
		endif
	endfor
	filename = cutfilename(stringfromlist(0, runnumbers)) + ".xml"
	
	pathinfo PATH_TO_DATA
	if(!V_FLAG)
		print "ERROR output path doesn't exist (writexml)"
		return 1
	endif
	
	if(itemsinlist(runnumbers)>1)
		filename = "c_"+filename
	endif
	
	if(dontoverwrite)
		filename = uniqueFileName(S_path, filename, ".xml")
	endif

	fileID = XMLcreatefile(S_Path + filename,"REFroot","","")

	xmladdnode(fileID,"//REFroot","","REFentry","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]","","time",Secs2Date(DateTime,0) + " "+Secs2Time(DateTime,3))

	xmladdnode(fileID,"//REFroot/REFentry[1]","","Title","",1)

	Wave/t user = $(df+stringfromlist(0,runnumbers)+":user:name")
	xmladdnode(fileID,"//REFroot/REFentry[1]","","User",user[0],1)

	xmladdnode(fileID,"//REFroot/REFentry[1]","","REFsample","",1)
	Wave/t samplename = $(df+stringfromlist(0,runnumbers)+":sample:name")
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFsample","","ID",samplename[0],1)

	xmladdnode(fileID,"//REFroot/REFentry[1]","","REFdata","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","axes","Qz")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","rank","1")

	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","type","POINT")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","spin","UNPOLARISED")

	make/n=0/o/d tempRR, tempQQ,tempRRsd,tempQQsd
	
	for(ii=0;ii<itemsinlist(runnumbers);ii+=1)
		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Run","",1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","filename",stringfromlist(ii,runnumbers)+".nx.hdf")
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","preset","")
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","size","")

		Wave qq = $(df+stringfromlist(ii,runnumbers)+":W_q")
		Wave RR = $(df+stringfromlist(ii,runnumbers)+":W_Ref")
		Wave dR = $(df+stringfromlist(ii,runnumbers)+":W_RefSD")
		Wave dq = $(df+stringfromlist(ii,runnumbers)+":W_qSD")

		concatenate/NP {RR}, tempRR
		concatenate/NP { qq}, tempQQ
		concatenate/NP { dq}, tempQQsd
		concatenate/NP { dR}, tempRRsd

		SVAR reductionCmd = $(df+stringfromlist(ii,runnumbers)+":reductionCmd")
		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","reductionnote",reductionCmd,1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]/reductionnote["+num2istr(ii+1)+"]","","software","SLIM")
	endfor
	sort tempQQ, tempQQ,tempRR, tempRRsd, tempQQsd
	
	//create ASCII representation of data
	sockitWaveToString/TXT tempQQ, qqStr
	sockitWaveToString/TXT tempRR, RRStr
	sockitWaveToString/TXT tempRRsd, dRStr
	sockitWaveToString/TXT tempQQsd, dqStr
	killwaves/z tempRR,tempqq,tempQQsd,tempRRsd

	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","dim",num2istr(itemsinlist(RRstr," ")))

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","R",RRStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/R","","uncertainty","dR")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Qz",qqStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","uncertainty","dQz")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","units","1/A")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dR",dRStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dR","","type","SD")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dQz",dqStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dQz","","type","FWHM")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dQz","","units","1/A")

	xmlclosefile(fileID,1)
End

Function write2DXML(pathName,runnumbers, dontoverwrite)
	string pathName,runnumbers
	variable dontoverwrite
	
	//a function to write an XML description of the reduced dataset.
	variable fileID,ii,jj
	string df = "root:packages:platypus:data:Reducer:"
	string qzStr="",RRstr="",dRStr="",qyStr="", filename,prefix=""

	if(itemsinlist(runnumbers)==0)
		print "ERROR, no runs to write (writeXML)"
		return 1
	endif
	
	if(!Datafolderexists(df+stringfromlist(0,runnumbers)))
		print "ERROR one or more of the runs doesn't exist (write2DXML)"
		return 1
	endif
	filename = "off_" + cutfilename(stringfromlist(0, runnumbers)) + ".xml"
	
	pathinfo PATH_TO_DATA
	if(!V_FLAG)
		print "ERROR output path doesn't exist (writexml)"
		return 1
	endif
	
	if(dontoverwrite)
		filename = uniqueFileName(S_path, filename, ".xml")
	endif
		
	fileID = XMLcreatefile(S_Path + filename, "REFroot", "", "")

	xmladdnode(fileID,"//REFroot","","REFentry","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]","","time",Secs2Date(DateTime,0) + " "+Secs2Time(DateTime,3))

	xmladdnode(fileID,"//REFroot/REFentry[1]","","Title","",1)

	Wave/t user = $(df+stringfromlist(0,runnumbers)+":user:name")
	xmladdnode(fileID,"//REFroot/REFentry[1]","","User",user[0],1)

	xmladdnode(fileID,"//REFroot/REFentry[1]","","REFsample","",1)
	Wave/t samplename = $(df+stringfromlist(0,runnumbers)+":sample:name")
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFsample","","ID",samplename[0],1)

	xmladdnode(fileID,"//REFroot/REFentry[1]","","REFdata","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","axes","Qz;Qy")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","rank","2")

	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","type","POINT")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","spin","UNPOLARISED")
	
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Run","",1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run[1]","","filename",stringfromlist(0,runnumbers)+".nx.hdf")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run[1]","","preset","")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run[1]","","size","")

	Wave qy = $(df+stringfromlist(ii,runnumbers)+":M_qy")
	Wave RR = $(df+stringfromlist(ii,runnumbers)+":M_Ref")
	Wave qz = $(df+stringfromlist(ii,runnumbers)+":M_qz")
	Wave dR = $(df+stringfromlist(ii,runnumbers)+":M_refSD")
	Wave M_omega = $(df+stringfromlist(ii,runnumbers)+":M_omega")
	Wave M_twotheta = $(df+stringfromlist(ii,runnumbers)+":M_twotheta")
	
	SVAR reductionCmd = $(df+stringfromlist(ii,runnumbers)+":reductionCmd")
	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata/Run[1]","","reductionnote",reductionCmd,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run[1]/reductionnote[1]","","software","SLIM")
	
	sockitwavetostring/TXT qz, qzStr
	sockitwavetostring/TXT RR, RRStr
	sockitwavetostring/TXT qy, qyStr
	sockitwavetostring/TXT dR, dRStr
	
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","dim",num2istr(dimsize(RR,0))+";"+num2istr(dimsize(RR,1)))

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","R",RRStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/R","","uncertainty","dR")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Qz",qzStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","uncertainty","")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","units","1/A")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Qy",qyStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qy","","uncertainty","")
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qy","","units","1/A")

	xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dR",dRStr,1)
	XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dR","","type","SD")

	xmlclosefile(fileID,1)
End

Function madd(pathname, filenames)
	string pathname, filenames

	variable ii,jj, kk, fileIDadd, fileIDcurrent, err=0
	string nodes = "",temp, addfile, cDF, nodename, attributes

	cDF = getdatafolder(1)
	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o/s $"root:packages:platypus:temp"

	newpath/o/q/z PATH_TO_DATA, pathname
	pathinfo PATH_TO_DATA
	if(!V_Flag)
		print "ERROR while creating path (madd)"; abort
	endif
	//nodes += "/entry1/data/hmm;"
	//nodes += "/entry1/data/time;"
	//nodes += "/entry1/data/total_counts;"
	nodes +=  "/entry1/instrument/detector/hmm;"
	nodes += "/entry1/instrument/detector/total_counts;"
	nodes += "/entry1/instrument/detector/time;"
	nodes += "/entry1/monitor/bm1_time;"
	nodes += "/entry1/monitor/bm1_counts;"
	nodes += "/entry1/monitor/bm2_counts;"
	nodes += "/entry1/monitor/bm2_time;"
	nodes += "/entry1/monitor/time"

	try
		for(ii=0 ; ii<itemsinlist(filenames); ii+=1)
			temp = removeending( stringfromlist(ii,filenames), ".nx.hdf")+".nx.hdf"
			if(!doesnexusfileexist("PATH_TO_DATA", temp))
				print "ERROR one of the filenames doesn't exist (madd)";abort	
			endif
		endfor

		temp = removeending( stringfromlist(0,filenames), ".nx.hdf")+".nx.hdf"
		copyfile/o pathname+temp as pathname+"ADD_"+temp
		if(V_Flag)
			print "ERROR copying file failed (madd)";abort
		endif

		addfile = pathname+"ADD_"+temp

		hdf5openfile/Z fileIDadd as addfile
		if(V_Flag)
			print "ERROR opening add file (madd)";abort
		endif

		for(ii=1 ; ii<itemsinlist(filenames) ; ii+=1)
			temp = removeending( stringfromlist(ii,filenames), ".nx.hdf")+".nx.hdf"
			hdf5openfile/Z fileIDcurrent as pathname+temp
			if(V_Flag)
				print "ERROR opening add file (madd)";abort
			endif
			//now copy the nodes
			for(jj=0 ; jj<itemsinlist(nodes) ; jj+=1)
				attributes = ""
				nodename = stringfromlist(jj, nodes)
				
				hdf5loaddata/q/z fileIDadd,nodename
				if(V_Flag)
					print "ERROR while loading a dataset (madd)";abort
				endif
				Wave numwave1 = $stringfromlist(0, S_Wavenames)
				hdf5loaddata/q/z fileIDcurrent, nodename
				if(V_Flag)
					print "ERROR while loading a dataset (madd)";abort
				endif
				Wave numwave2 = $stringfromlist(0, S_Wavenames)
				numwave1 = numwave1+numwave2

				make/o/d/n=(wavedims(numwave1),4) hyperslab
				hyperslab[][0] = 0
				hyperslab[][1] = 1
				hyperslab[][2] = 1
				hyperslab[][3] = dimsize(numwave1, p)
				///gzip={6,0}/LAYO={2,dimsize(numwave1,0),dimsize(numwave1,1),dimsize(numwave1,2),dimsize(numwave1,3)} 
				
				hdf5savedata/o/z/slab=hyperslab numwave1, fileIDadd, nodename
				if(V_Flag)
					print "ERROR couldn't save added data to ADD file (madd)";abort
				endif

				killwaves/a/z
			endfor
	
			hdf5closefile/Z fileIDcurrent
			if(V_Flag)
				print "ERROR couldn't close current file (madd)";abort
			endif
		endfor

		hdf5closefile/z fileIDadd
		if(V_Flag)
			print "ERROR couldn't close ADD file (madd)";	abort
		endif

	catch
		err = 1
		hdf5closefile/z fileIDadd
		hdf5closefile/z fileIDcurrent
	endtry

	setdatafolder $cDF
	killdatafolder/z $"root:packages:platypus:temp"
	return err
End

Function delReducedPoints()
	variable theFile
	Open/R/D/M="Please select the XML file to remove points from."/T=".xml" theFile
	if(strlen(S_filename) > 0)
		string pathInStr = ParseFilePath(1, S_filename, ":", 1, 0)
		string fileInStr = ParseFilePath(0, S_filename, ":", 1, 0)
		string pointsToDelete = ""
		prompt pointsToDelete, ""
		string help = "Please enter individual points numbers, or ranges.  A typical string is \"0; 20-31\" which would delete point 0 and points 20 to 31"
		Doprompt/help = help "Enter the points to delete", pointsToDelete
		if(!V_flag)
			delrefpoints(pathInStr, fileInStr, pointsToDelete)
		endif
	endif
End

Function delrefpoints(pathname, filename, pointlist)
	string pathname, filename, pointlist

	string data,temp
	variable fileID,ii, numtoremove,lower,upper

	try
		fileID = xmlopenfile(pathname+filename)
		if(fileID < 1)
			print "ERROR couldn't open XML file";abort
		endif
		pointlist = sortlist(pointlist, ";", 3)
		pointlist = lowerstr(pointlist)
		if(grepstring(pointlist, "[a-z]+"))
			print "ERROR list of points should only contain numbers";abort
		endif
		
		xmlwavefmXPATH(fileID, "//REFdata[1]/Qz", "", "")
		Wave/t M_xmlcontent
		make/o/d/n=(dimsize(M_xmlcontent, 0)) asdfghjkl0
		asdfghjkl0 = str2num(M_xmlcontent[p][0])
			
		xmlwavefmXPATH(fileID, "//REFdata[1]/R","","")
		Wave/t M_xmlcontent
		make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl1
		asdfghjkl1 = str2num(M_xmlcontent[p][0])

		xmlwavefmXPATH(fileID, "//REFdata[1]/dR", "", "")
		Wave/t M_xmlcontent
		make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl2
		asdfghjkl2 = str2num(M_xmlcontent[p][0])

		xmlwavefmXPATH(fileID, "//REFdata[1]/dQz", "", "")
		Wave/t M_xmlcontent
		make/o/d/n=(dimsize(M_xmlcontent, 0)) asdfghjkl3
		asdfghjkl3 = str2num(M_xmlcontent[p][0])
			
		sort asdfghjkl0, asdfghjkl0, asdfghjkl1, asdfghjkl2, asdfghjkl3
		
		for(ii = 0 ; ii < itemsinlist(pointlist) ; ii += 1)
			temp=stringfromlist(ii, pointlist)
			numtoremove = str2num(stringfromlist(ii, pointlist ,";"))
			if(!numtype(numtoremove) && strsearch(temp, "-", 0) == -1)
				deletepoints numtoremove, 1, asdfghjkl0, asdfghjkl1, asdfghjkl2, asdfghjkl3
			else	
				sscanf temp, "%d-%d",lower,upper
				if(V_Flag!=2)
					print "ERROR parsing range of values to delete (delrefpoints)";abort
				endif
				if(upper<lower)
					numtoremove = lower
					lower=upper
					upper = numtoremove
				endif
				numtoremove = upper-lower+1
				deletepoints lower, numtoremove, asdfghjkl0, asdfghjkl1, asdfghjkl2, asdfghjkl3
			endif
		endfor
		
		data = ""
		SOCKITwavetoString/TXT asdfghjkl0, data
		xmlsetnodestr(fileID, "//REFdata[1]/Qz", "", data)
	
		data = ""
		SOCKITwavetoString/TXT asdfghjkl1, data
		xmlsetnodestr(fileID, "//REFdata[1]/R", "", data)

		data = ""
		SOCKITwavetoString/TXT asdfghjkl2, data
		xmlsetnodestr(fileID, "//REFdata[1]/dR", "", data)

		data = ""
		SOCKITwavetoString/TXT asdfghjkl3, data
		xmlsetnodestr(fileID, "//REFdata[1]/dQz", "", data)

	catch
		if(fileID>0)
			xmlclosefile(fileID,0)
			fileID=0
		endif
	endtry
	killwaves/z asdfghjkl0, asdfghjkl1, asdfghjkl2, asdfghjkl3, M_xmlcontent, W_xmlcontentnodes
	
	print "NOW please remember to resplice individual angles (delRefpoints)"
	if(fileID>0)
		xmlclosefile(fileID,1)
	endif
End

Function spliceFiles(pathName,runnumbers, [factors, dontoverwrite, rebin])
	string pathName,runnumbers, factors
	variable dontoverwrite, rebin
	//this function splices different reduced files together.
	
	string cDF = getdatafolder(1)
	string fname
	string df = "root:packages:platypus:data:Reducer:"
	string qqStr="",RRstr="",dRStr="",dqStr="",filename,prefix=""
	
	variable fileID,ii,fileIDcomb, err=0, jj
	
	if(paramisdefault(dontoverwrite))
		dontoverwrite = 0
	endif
	
	try
		newdatafolder/o root:packages
		newdatafolder/o root:packages:platypus
		newdatafolder/o root:packages:platypus:data
		newdatafolder/o root:packages:platypus:data:reducer
		newdatafolder/o/s root:packages:platypus:data:reducer:temp
	 
		newpath/o/q/z PATH_TO_DATA, pathname
		pathinfo PATH_TO_DATA
		if(!V_FLAG)
			print "ERROR output path doesn't exist (writexml)"
			return 1
		endif
		
		//load in each of the files
		for(ii = 0 ; ii < itemsinlist(runnumbers) ; ii += 1)
			fileID = xmlopenfile(S_path + stringfromlist(ii, runnumbers) + ".xml")
			if(fileID < 1)
				print "ERROR couldn't open individual file (spliceFiles)";abort
			endif
			
			xmlwavefmXPATH(fileID,"//REFdata[1]/Qz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl0
			asdfghjkl0 = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//REFdata[1]/R","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl1
			asdfghjkl1 = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//REFdata[1]/dR","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl2
			asdfghjkl2 = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//REFdata[1]/dQz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl3
			asdfghjkl3 = str2num(M_xmlcontent[p][0])
			
			xmlclosefile(fileID,0)
			fileID=0
			
			sort asdfghjkl0,asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3 
			
			if(ii==0)
				make/o/d/n=(numpnts(asdfghjkl0)) tempQQ, tempRR, tempDR, tempDQ
				Wave tempQQ, tempRR, tempDR, tempDQ
				tempQQ=asdfghjkl0
				tempRR=asdfghjkl1
				tempDR=asdfghjkl2
				tempDQ=asdfghjkl3
			else
				//splice with propagated error in the splice factor
				variable/c compSplicefactor
				if(paramisdefault(factors))
					compSplicefactor = Pla_GetweightedScalingInoverlap(tempQQ,tempRR, tempDR, asdfghjkl0,asdfghjkl1,asdfghjkl2)		
				else
					if(itemsinlist(factors) <= ii)
						compSplicefactor = cmplx(str2num(stringfromlist(ii-1, factors)), 0)
					else
						compSplicefactor = Pla_GetweightedScalingInoverlap(tempQQ,tempRR, tempDR, asdfghjkl0,asdfghjkl1,asdfghjkl2)								
					endif
				endif
				if(numtype(REAL(compspliceFactor)))
					print "ERROR while splicing into combineddataset (spliceFiles)";abort
				endif

				//think the following is wrong! No need to errors in quadrature if scalefactor does not depend on wavelength
				asdfghjkl2 = (asdfghjkl2/asdfghjkl1)^2
				asdfghjkl2 += (imag(compSpliceFactor)/real(compSpliceFactor))^2
				asdfghjkl2 =sqrt(asdfghjkl2)
				asdfghjkl1 *= real(compSplicefactor)
				asdfghjkl2 *= asdfghjkl1
				
				concatenate/NP {asdfghjkl1},tempRR
				concatenate/NP {asdfghjkl0},tempQQ
				concatenate/NP { asdfghjkl3},tempDQ
				concatenate/NP {asdfghjkl2},tempDR
				
				sort tempQQ,tempQQ,tempRR,tempDR,tempDQ 
			endif
		endfor
		
		if(!paramisdefault(rebin) && rebin > 0 && rebin < 15)
			Pla_rebin_afterwards(tempQQ, tempRR, tempDR, tempDQ, rebin, tempQQ[0] - 0.00005, tempQQ[numpnts(tempQQ) - 1]+0.00005)
			duplicate/o W_Q_rebin, tempQQ
			duplicate/o W_R_rebin, tempRR
			duplicate/o W_E_rebin, tempDR
			duplicate/o W_dq_rebin, tempDQ
		endif
		
		fname = "c_" + cutfilename(stringfromlist(0, runnumbers)) + ".dat"
		if(dontoverwrite)
			fname = uniqueFileName(S_path, fname, ".dat")
		endif
		
		open/P=PATH_TO_DATA/z=1 fileIDcomb as fname
		if(V_flag)
			print "ERROR writing combined file (aplicefiles)";	 abort
		endif
		
		fprintf fileIDcomb, "Q (1/A)\t Ref\t dRef (SD)\t dq(FWHM, 1/A)\r"
		wfprintf fileIDcomb, "%g\t %g\t %g\t %g\r", tempQQ, tempRR, tempDR, tempDQ
		close fileIDcomb
		
		//now write an XML file
		fname = "c_" + cutfilename(stringfromlist(0,runnumbers)) + ".xml"
		if(dontoverwrite)
			fname = uniquefilename(S_path, fname, ".xml")
		endif
		fileID = XMLcreatefile(S_Path + fname, "REFroot", "", "")
		if(fileID < 1)
			print "ERROR while creating XML combined file (spliceFiles)";abort
		endif
		
		xmladdnode(fileID, "//REFroot", "", "REFentry", "", 1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]","","time",Secs2Date(DateTime,0) + " "+Secs2Time(DateTime,3))

		xmladdnode(fileID,"//REFroot/REFentry[1]","","Title","",1)

		Wave/t user = $(df+stringfromlist(0,runnumbers)+":user:name")
		xmladdnode(fileID,"//REFroot/REFentry[1]","","User",user[0],1)

		xmladdnode(fileID,"//REFroot/REFentry[1]","","REFsample","",1)
		Wave/t samplename = $(df+stringfromlist(0,runnumbers)+":sample:name")
		xmladdnode(fileID,"//REFroot/REFentry[1]/REFsample","","ID",samplename[0],1)

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
		
			string reductionNote = xmlstrfmXpath(fileID, "//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]/reductionnote","","")
			xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]","","reductionnote",reductionnote,1)
			XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Run["+num2istr(ii+1)+"]/reductionnote","","software","SLIM")
		endfor
	
		//create ASCII representation of data
		sockitWaveToString/TXT tempQQ, qqStr
		sockitWaveToString/TXT tempRR, RRStr
		sockitWaveToString/TXT tempDR, dRStr
		sockitWaveToString/TXT tempDQ, dqStr

		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata","","dim",num2istr(itemsinlist(RRstr," ")))

		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","R",RRStr,1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/R","","uncertainty","dR")

		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","Qz",qqStr,1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","uncertainty","dQz")
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/Qz","","units","1/A")

		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dR",dRStr,1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dR","","type","SD")

		xmladdnode(fileID,"//REFroot/REFentry[1]/REFdata","","dQz",dqStr,1)
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dQz","","type","FWHM")
		XMLsetattr(fileID,"//REFroot/REFentry[1]/REFdata/dQz","","units","1/A")

		xmlclosefile(fileID,1)
	catch
		if(fileID)
			xmlclosefile(fileID,0)
		endif
		if(fileID)
			close fileID
		endif
		err=1
	endtry
	
	setdatafolder $cDF
	killdatafolder/z 	root:packages:platypus:data:reducer:temp
	return err
End

//Function Pla_splitfile(pathname, filename)
//	//split a single file with several frames into several files with 1 frame.
//	string pathname, filename
//	//splitfile("foobar:Users:anz:Desktop:test:","QKK0006492.nx.hdf")
//	variable ii,jj, kk, fileIDadd, fileIDcurrent, err=0, run_dims
//	string nodes = "",temp, addfile, cDF, nodename, attributes,filebase,filepath
//	
//	Struct HDF5DataInfo di
//	InitHDF5DataInfo(di)	// Initialize structure.
//
//	cDF = getdatafolder(1)
//	newdatafolder/o root:packages
//	newdatafolder/o root:packages:platypus
//	newdatafolder/o/s $"root:packages:platypus:temp"
//
//	newpath/o/q/z PATH_TO_DATA, pathname
//	pathinfo PATH_TO_DATA
//	filepath = S_path
//	if(!V_Flag)
//		print "ERROR while creating path (splitfile)"; abort
//	endif
//	//going to enumerate nodes that appear to grow with multiple frames.
//	//it's not clear from the file which ones do and which ones don't
//	nodes += "/entry1/data/hmm;"
//	nodes += "/entry1/data/run_number;"
//	
//	try
//		if(itemsinlist(filename)>1)
//			print "ERROR - do one file at a time (splitfile)";abort
//		endif
//		
//		filebase = removeending( stringfromlist(0,filename), ".nx.hdf")
//		temp = filebase +".nx.hdf"
//		
//		if(!doesnexusfileexist("PATH_TO_DATA", temp))
//			print "ERROR one of the filenames doesn't exist (splitfile)";abort	
//		endif
//		
//		//open the sourcefile as read-write
//		hdf5openfile/R/Z/P=PATH_TO_DATA fileIDcurrent as filename
//		if(V_Flag)
//			print "ERROR opening add file (splitfile)";abort
//		endif
//		
//		InitHDF5DataInfo(di)	// Initialize structure.
//		HDF5DatasetInfo(fileIDcurrent , "/entry1/data/hmm" , 0 , di ) 
//		run_dims = di.dims[0]
//
//		//now have to iterate through runnodes shrinking everything
//		for(ii = 0 ; ii < run_dims ; ii+=1)
//			print ii
//			//if its the first run copy the original file
//			//if it's subsequent just copy the 1st runnumber
//			if( ii == 0 )
//				copyfile/o filepath+filename as filepath+"temp.nx.hdf"
//				temp =  filepath+"temp.nx.hdf"
//				if(V_Flag)
//					print "ERROR copying file failed (splitfile)";abort
//				endif
//			else
//				copyfile/o filepath+filebase+"_0.nx.hdf" as filepath+filebase+"_"+num2istr(ii)+".nx.hdf"
//				temp =  filepath+filebase+"_"+num2istr(ii)+".nx.hdf"
//				if(V_Flag)
//					print "ERROR copying file failed (splitfile)";abort
//				endif				
//			endif
//			//open the datafile
//			hdf5openfile/Z fileIDadd as temp
//			if(V_Flag)
//				print "ERROR opening add file (splitfile)";abort
//			endif
//			
//			//now shrink the nodes
//			for(jj=0 ; jj<itemsinlist(nodes) ; jj+=1)
//				nodename = stringfromlist(jj, nodes)
////				print jj,nodename
//				if(ii==0)
//					attributes = saveAttributes(fileIDcurrent, nodename)
//				endif
//
//				HDF5DatasetInfo(fileIDcurrent ,  nodename , 0 , di ) 
//
//				//the runnumber is the first slab of the wave
//				make/o/i/n=(di.ndims, 4) hyperslab
//				hyperslab[][0] = 0
//				hyperslab[][1] = 1
//				hyperslab[][2] = 1
//				hyperslab[][3] = di.dims[p]
//				hyperslab[0][3] = 1
//				hyperslab[0][0] = ii
//					
//				hdf5loaddata/q/z/o/slab=hyperslab fileIDcurrent, nodename
//				if(V_Flag)
//					print "ERROR while loading a dataset (splitfile)";abort
//				endif
//				Wave numwave1 = $stringfromlist(0, S_Wavenames)			
//
//				if(ii==0)
//					hdf5savedata/z/o numwave1, fileIDadd, nodename
//					if(V_Flag)
//						print "ERROR couldn't save added data to ADD file (splitfile)";abort
//					endif
//					restoreAttributes(fileIDadd, nodename, attributes)
//				else
//					hyperslab[][0] = 0
//					hyperslab[][1] = 1
//					hyperslab[][2] = 1
//					hyperslab[][3] = dimsize(numwave1,p)
//					hdf5savedata/z/o/slab=hyperslab numwave1, fileIDadd, nodename
//					if(V_Flag)
//						print "ERROR couldn't save added data to ADD file (splitfile)";abort
//					endif
//				endif				
//				killwaves/a/z
//			endfor
//			hdf5closefile/z fileIDadd
//			if(V_Flag)
//				print "ERROR couldn't close split file (splitfile)";abort
//			endif
//			
//			if( ii == 0 )
//				//if you're the first runthrough repack the h5file, otherwise the file is still large
//				String unixCmd, igorCmd
//				unixCmd = "/usr/local/bin/h5repack -v -f GZIP=1 "+HFStoPosix("",filepath+"temp.nx.hdf",1,1)  + " " +HFStoPosix("",filepath,1,1)+filebase+"_"+num2istr(ii)+".nx.hdf"
//				sprintf igorCmd, "do shell script \"%s\"", unixCmd	
//				print igorCmd
//				ExecuteScriptText igorCmd
//			endif
//		endfor
//	
//		hdf5closefile/Z fileIDcurrent
//		if(V_Flag)
//			print "ERROR couldn't close current file (splitfile)";abort
//		endif
//	catch
//		err = 1
//		hdf5closefile/z fileIDadd
//		hdf5closefile/z fileIDcurrent
//	endtry
//
//	setdatafolder $cDF
//	killdatafolder/z $"root:packages:platypus:temp"
//	return err
//End
//
//Function/t saveAttributes(fileID, nodename)
////save the attributes of an HDF node in some waves
//	variable fileID
//	string nodename
//
//	variable ii
//	string wavenames = ""
//	HDF5ListAttributes/Z fileID , nodename
//
//	for(ii=0 ; ii<itemsinlist(S_HDF5ListAttributes) ; ii+=1)
//		HDF5loaddata/A=stringfromlist(ii, S_HDF5ListAttributes)/q/o/z fileID, nodename
//		wavenames +=  S_Wavenames
//	endfor
//
//	return wavenames
//End
//
//Function restoreAttributes(fileID, nodename, wavenames)
////restore the attributes of an HDF node from some waves
//	variable fileID
//	string nodename
//	string wavenames
//	variable ii
//
//	for(ii = 0 ; ii<itemsinlist(wavenames); ii+=1)
//		Wave/t/z textwav = $(stringfromlist(ii,wavenames))
//		if(waveexists(textwav))
//			hdf5savedata/A=nameofwave(textwav)/Z/o textwav, fileID, nodename	
//		endif
//		Wave/t/z wav = $(stringfromlist(ii,wavenames))
//		if(waveexists(wav))
//			hdf5savedata/A=nameofwave(wav)/Z/o wav, fileID, nodename	
//		endif
//	endfor
//End


//A wrapper script to reduce many X-ray files

Function reduceManyXrayFiles()

	variable err, ii, jj
	string cDF = getdatafolder(1)
	string aFile, theFiles, base
	try
		Newdatafolder/o root:packages
		Newdatafolder /o/s root:packages:Xpert
		multiopenfiles/M="Please select all specular Xpert Pro files"/F=".xrdml;"
		if(V_flag)
			return 0
		endif
		theFiles = S_filename
		
		for(ii = 0 ; ii<itemsinlist(theFiles) ; ii+=1)
			aFile = Stringfromlist(ii, theFiles)
			print "reducing: ", aFile
			
			if(cmpstr(igorinfo(2),"Macintosh")==0)
				base = parsefilepath(3, aFile, ":", 0, 0)
			else
				base = parsefilepath(3, aFile, "\\", 0, 0)
			endif	
			base = cleanupname(base, 0)
			
			do
				multiopenfiles/M="Please select up to two background runs for "+base/F=".xrdml;"
				if(V_flag)
					S_filename = ""
				endif
			while(itemsinlist(S_filename)>2)
		
			//if there is no problem reducing it, then try to save it
			if(!reduceXpertPro(afile, bkg1=stringfromlist(0, S_filename), bkg2 = stringfromlist(1, S_filename)))
				SaveXraydata(base)		
			else
				//someone somewhere aborted the whole thing
				print "ERROR aborted in (reduceManyXrayFiles)"
				abort
			endif
		endfor
	catch
		err = 1
	endtry

	setdatafolder $cDF
	return err
End

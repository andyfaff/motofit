#pragma rtGlobals=1		// Use modern global access method.
//background offset is the separation between the specridge and the region taken to be background.
	constant BACKGROUNDOFFSET = 2

	// SVN date:    $Date$
	// SVN author:  $Author$
	// SVN rev.:    $Revision$
	// SVN URL:     $HeadURL$
	// SVN ID:      $Id$
	
Function topAndTail(measurement, measurementSD, peak_Centre,peak_FWHM,background)
	Wave measurement	//the data from the NeXUS file
	Wave measurementSD
	variable peak_Centre, peak_FWHM //expected_width is the FWHM width of the beam
	variable background		//do you want to do a background reduction
	
	//the specular region is integrated over around the specular pixels, after
	//subtracting a linear background.  THe linear background is determined by fitting the intensity in backgroundwidth pixels each side of the
	//foreground area
	
	
	//measurement is taken to be a 2d wave [time][y]
	
	//output:
	//M_topandtail
	//M_topandtailSD
	//W_spec
	//W_specSD

	variable ii,jj,tempVar,foregroundwidth,backgroundwidth
	variable/c retval
	String cDF = getdatafolder(1)

	try
		//Make datafolders first.
		//The datafolders have the same substructure as the Instrument control
		Newdatafolder/o root:packages
		Newdatafolder /o root:packages:platypus
		Newdatafolder /o root:packages:platypus:data
		//directory for the reduction package
		Newdatafolder /o/s root:packages:platypus:data:Reducer

		if(Wavedims(measurement) != 2 || Wavedims(measurementSD) != 2)
			print "ERROR: whilst reducing, dataset should be 2D [time][y] (topAndTail)"
			abort
		endif

		make/o/d/n=(dimsize(measurement,0),dimsize(measurement,1)) root:packages:platypus:data:reducer:M_topAndTail
		Wave M_topAndTail= root:packages:platypus:data:reducer:M_topAndTail
		M_topAndTail[][] = measurement[p][q]
		
		//make an error wave
		duplicate/o measurementSD, M_topAndTailSD
		
		//do the background subtraction
		if(background)
			backgroundWidth = 1.7*peak_FWHM
		else
			backgroundwidth = 0
		endif

		variable loPx, hiPx
		foregroundwidth = peak_FWHM *1.7
		loPx = floor(peak_centre - foregroundwidth/2)
		hiPx = ceil(peak_centre + foregroundwidth/2)
		
		if(backgroundwidth > 0)
			if(Pla_linbkg(M_topAndTail,M_topAndTailSD,loPx, hiPx, backgroundwidth))
				print "ERROR: whilst reducing: (topAndTail)"
				abort
			endif
			wave M_imagebkg, M_imagebkgSD
		else
			duplicate/o M_topandtail,M_imagebkg
			duplicate/o M_topandtailSD,M_imagebkgSD		
		endif

		//now we have M_imagebkg and M_imagebkgSD, copy those back into M_topAndTail
		duplicate/o M_imagebkg,M_topAndTail,temp
		duplicate/o M_imagebkgSD,M_topAndTailSD,tempSD

		//now lets produce the background subtracted, integrated spectrum
		deletepoints/M=1 hiPx+1, dimsize(temp,1), temp,tempSD
		deletepoints/M=1 0, loPx, temp,tempSD
		imagetransform sumallrows temp
		duplicate/o W_sumrows W_spec
	
		//now create the SD of the integrated, background subtracted TOF spectrum
		duplicate/o W_spec,W_specSD
		variable count1,count2
		count1=dimsize(W_specSD, 0)
		count2 = dimsize(tempSD, 1)

		for(ii=0 ; ii < count1 ; ii+=1)
			for(jj=0 ; jj<count2 ; jj+=1)
				W_specSD[ii] += (tempSD[ii][jj]^2)
			endfor
		endfor
		W_specSD = sqrt(W_specSD)
		
		//make a record of the beam position on the detector by storing it in the wave note
		//these values were found above using findspecridge
		//these values are only applicable for reflected beams.  Direct beam centres depend on wavelength.
		//also make a note of the integration region on the detector, these are INCLUSIVE
		note/k W_spec
		note/k M_topandtail
		string tempStr =  "centre:"+num2str(peak_centre)+";FWHM:"+num2str(peak_FWHM)
		tempStr +=";loPx:"+num2str(loPx)
		tempStr +=";hiPx:"+num2str(hiPx)
		note W_spec, tempStr
		note M_topandtail, tempStr
		
		killwaves/z M_sumplanes,xx,W_sumcols,W_sumrows,W_integrate,W_integratex,W_peakinfo,M_imagebkg,M_imagebkgSD,temp,tempSD,M_rebin,M_rebinSD
		Setdatafolder $cDF
		return 0
	catch
		killwaves/z M_sumplanes,xx,W_sumcols,W_sumrows,W_integrate,W_integratex,W_peakinfo,M_imagebkg,M_imagebkgSD,temp,tempSD,M_rebin,M_rebinSD
		Setdatafolder $cDF
		return 1
	endtry
End

Function createWaterNormalisationWave(waterrun, fileName)
	Wave waterrun
	string fileName
	//this function creates a water normalisation array, to normalise over different efficiencies.
	//waterrun is the detector image for the water run (typically measured using the full xy pixelation
	
	//filename is the name of the run for which you are trying to normalise.
	//filename is present because there may be different xy pixelation for the water run and they need to be the same
	
	string cDF = getdatafolder(1)
	variable tempVar, retval=0, lowestX, highestX
	string waterDF = getwavesdatafolder(waterrun,1)
	string tempDF = "root:packages:platypus:data:Reducer:"+filename
	
	waterDF = removelistitem(itemsinlist(waterDF,":")-1,waterDF,":")
	
	try
		if(Wavedims(waterrun) != 4)
			print "ERROR: waterrun is not proper data (ptyx) (createWaterNormalisationWave)"
			abort
		endif
		setdatafolder $waterDF
	
		make/o/i/u/n=(dimsize(waterrun,1),dimsize(waterrun,2),dimsize(waterrun,3)) M_waternorm
		M_waternorm[][][] = waterrun[0][p][q][r]
		
		//delete x points from the normalisation wave that aren't in the data
		Wave watXbin = $(waterDF+"data:x_bin")
		Wave dataXbin = $(tempDF+":data:x_bin")
		highestX = (binarysearch(watXbin, dataXbin[0]))
		lowestX = (binarysearch(watXbin, dataXbin[dimsize(dataXbin,0)]))
		deletepoints/M=2 lowestX+1, dimsize(M_waternorm, 2), M_waternorm
		deletepoints/M=2 0, highestX, M_waternorm
		
		//this averages over x
		imagetransform sumplanes, M_waternorm
		duplicate/o M_sumplanes, M_waternorm
		killwaves/z M_sumplanes

		imagetransform sumallcols M_waternorm 
		duplicate/o W_sumcols,W_waternorm

		duplicate/o W_waternorm, W_waternormSD
		W_waternormSD=sqrt(W_waternorm+1)
		tempVar = mean(W_waternorm)
		W_waternorm /= tempVar
		W_waternormSD /=tempVar
		W_waternormSD = W_waternormSD

	catch
		retval = 1
	endtry
	killwaves/z M_sumplanes,M_waternorm,W_sumcols
	setdatafolder $cDF
	return 0		
End

Function findSpecRidge(ytWave, searchIncrement , tolerance, expected_centre, expected_width, retval)
	Wave ytWave
	variable searchIncrement, tolerance
	variable   expected_centre, expected_width
	variable/c &retval 
	retval =  cmplx(NaN,NaN)

	variable ii,jj

	if(wavedims(ytWave) != 2)
		print "ERROR incorrect size for ytWave, not 2dimensional (findSpecRidge)"
		return 1
	endif
	if(searchIncrement > dimsize(yTwave,0))
		print "ERROR increment is larger than the first dimension (findSpecRidge)"
		return 1
	endif

	try
		make/o/d/n=(dimsize(ytwave,1)) subSection = 0, subSectionX=p
		make/o/d/n=(0) peakCentre,peakFWHM

		for(ii=0 ; ii< floor(dimsize(ytWave,0) / searchIncrement) ; ii+=1)
			redimension/n=(ii+1, -1) peakCentre,peakFWHM
		
			for(jj = ii*searchIncrement ; jj < (ii+1) * searchIncrement ; jj+=1)
				subsection[] += ytWave[dimsize(ytwave,0)-jj-1][p]
			endfor
			Pla_findpeakdetails(subsection, subsectionX,expected_centre = expected_centre, expected_width = expected_width)
			Wave W_peakInfo
			if((2.35482 * W_peakInfo[7]/sqrt(2) < expected_width && abs(W_peakInfo[6] - expected_centre) <  2*expected_width))
				peakCentre[ii] = W_peakInfo[6]
				peakFWHM[ii] = 2.35482 * W_peakInfo[7]/sqrt(2)
			else
				peakCentre[ii] = NaN
				peakFWHM[ii] = NaN
			endif	
			
			if(ii>0 && abs((peakCentre[ii]-peakCentre[ii-1])/peakCentre[ii]) < tolerance && abs((peakFWHM[ii]-peakFWHM[ii-1])/peakFWHM[ii]) < tolerance)
				retval = cmplx(W_peakInfo[6], 2.35482*W_peakInfo[7]/sqrt(2))
				break
			endif	
		endfor
	catch
		print "PROBLEM whilst finding specular ridge (findSpecRidge)"
		killwaves/z subSection, subsectionX,W_peakinfo,peakCentre,peakFWHM
	
		return 1
	endtry

	killwaves/z subSection, subsectionX,W_peakinfo,peakCentre,peakFWHM

	if(imag(retval) >  expected_width || abs(real(retval) - expected_centre) >  expected_width)
		print "PROBLEM, there was no significant specular beam detected: ", Getwavesdatafolder(ytwave,0) , "(findspecularridge)"
		retval = cmplx(NaN,NaN)
		return 1
	endif
	
	return 0
End

Function ChoDCalculator(fileName, omega, two_theta [,pairing, scanpoint])
	string fileName
	variable omega, two_theta
	variable pairing, scanpoint
	
	variable chod = 0, master = -1, slave = -1, ii, jj
	string tempDF  = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(filename,".nx.hdf"),0)

	Wave chopper1_distance = $(tempDF+":instrument:parameters:chopper1_distance")
	Wave chopper2_distance = $(tempDF+":instrument:parameters:chopper2_distance")
	Wave chopper3_distance = $(tempDF+":instrument:parameters:chopper3_distance")
	Wave chopper4_distance = $(tempDF+":instrument:parameters:chopper4_distance")
	//guide 1 is the single deflection mirror (SB)
	//its distance is from chopper 1 to the middle of the mirror (1m long)
	
	//guide 2 is the double deflection mirror (DB)
	//its distance is from chopper 1 to the middle of the second of the compound mirrors! (a bit weird, I know).
	
	Wave guide1_distance = $(tempDF+":instrument:parameters:guide1_distance")
	Wave guide2_distance = $(tempDF+":instrument:parameters:guide2_distance")
	Wave sample_distance = $(tempDF+":instrument:parameters:sample_distance")
	Wave DetectorPos = $(tempDF+":instrument:detector:longitudinal_translation")
	Wave/t mode = $(tempDF+":instrument:parameters:mode")
	
//	if(omega < 0 || two_theta < 0)
//		print "WARNING, OMEGA isn't set, spectrum is approximate, setting omega, 2theta=0 (CHODcalculator)"
//		omega=0
//		two_theta = 0
//	endif
	if(paramisdefault(scanpoint))
		scanpoint = 0
	endif
	
	if(paramisdefault(pairing))
		master = 1
		slave = 3
	endif
	
	//assumes that disk closest to the reactor (out of a given pair) is always master
	for(ii = 1; ii < 5 ; ii+=1)
		if(pairing & 2^ii)
			master = ii
			break
		endif
	endfor
	for(ii = master + 1 ; ii < 5 ; ii+=1)
		if(pairing & 2^ii)
			slave = ii
			break
		endif
	endfor
	
	switch(master)
		case 1: 
			ChoD = 0
			break
		case 2:
			ChoD -= chopper2_distance[scanpoint]
			break
		case 3:
			ChoD -= chopper3_distance[scanpoint]
			break
		default:
			print "ERROR: master chopper must be 1,2,3 (ChoDCalculator)"
			return NaN
			break
	endswitch
		
	switch(slave)
		case 2:
			ChoD -= chopper2_distance[scanpoint]
			break
		case 3:
			ChoD -= chopper3_distance[scanpoint]
			break
		case 4:
			ChoD -= chopper4_distance[scanpoint]
			break
		default:
			print "ERROR: slave must be 2,3 or 4 (ChoDCalculator)"
			return NaN
			break
	endswitch
	//T0 is midway between master and slave, but master may not necessarily be disk 1.
	//However, all instrument lengths are measured from disk1
	ChoD /= 2
	
	strswitch(mode[scanpoint])
		case "FOC":
			//FALL THROUGH INTO MT, the two are the same
		case "POL":
		case "POLANAL":
		case "MT":
			chod += sample_distance[scanpoint]
			chod += DetectorPos[scanpoint] / cos(Pi * two_theta / 180)
			break
		case "SB":			//assumes guide1_distance is in the MIDDLE OF THE MIRROR
			chod += guide1_distance[scanpoint]
			chod += (sample_distance[scanpoint] - guide1_distance[scanpoint]) / cos(Pi * omega / 180)
			if(two_theta > omega)
				chod += detectorpos[scanpoint]/cos( Pi* (two_theta-omega) / 180)
			else
				chod += detectorpos[scanpoint] /cos( Pi * (omega-two_theta) /180)
			endif
			break
		case "DB":			//guide2_distance in in the middle of the 2nd compound mirror
			// guide2_distance - longitudinal length from midpoint1->midpoint2 + direct length from midpoint1->midpoint2
			chod += guide2_distance[scanpoint] + 600* cos (1.2 * Pi/180) * (1 - cos(2.4 * Pi/180)) 
			
			//add on distance from midpoint2 to sample
			chod +=  (sample_distance[scanpoint] - guide2_distance[scanpoint]) / cos(4.8 * Pi/180)
						
			//add on sample -> detector			
			if(two_theta > omega)																			
				chod += detectorpos[scanpoint] / cos( Pi* (two_theta-4.8) / 180)
			else
				chod += detectorpos[scanpoint] /cos( Pi * (4.8 - two_theta) /180)
			endif
			break
		default:
			chod = NaN
			break
		
	endswitch
	return chod
End

Function TOFtoLambda(TOF, distance)
	Wave TOF
	variable distance
	//convert TOF to lambda.
	//time of flight in microseconds, flight distance in mm, time offset in microseconds
	//output in W_lambda, in Angstrom

	//make the wave to put it in
	make/o/d/n=(numpnts(TOF)) W_lambda
	Wave W_lambda

	W_lambda = P_MN*(TOF[p])*1e-3/distance
	W_lambda *=1e10

	return 0
End

Function LambdatoTOF(Lambda, distance)
	Wave Lambda
	variable distance
	//convert  lambda to TOF
	//time of flight in microseconds, flight distance in mm, time offset in microseconds
	//output in W_lambda, in Angstrom

	//make the wave to put it in
	make/o/d/n=(numpnts(lambda)) W_TOF
	
	W_tof = (lambda/P_MN)*distance * 1e-7

	return 0
End

Function LambdaToQ(Qq, lambda,omega)
	Wave qq
	Wave lambda
	Wave omega

	//converts wave containing lambda values, and an incident angle to Q vector.  
	//lambda in Angstrom
	//omega in radians
	qq = 4*Pi*sin(omega)/lambda
End

Function histToPoint(w)
	Wave w
	make/o/d/n=(numpnts(w)-1) W_point
	w_point[] = w[p]+w[p+1]
	W_point /=2
End


Function Pla_linbkg(image,imageSD,loPx, hiPx, backgroundwidth)
	Wave image,imageSD
	variable loPx, hiPx, backgroundwidth
	
	//background offset must NEVER be negative
	variable y0,y1,y2,y3
	string tempStr=""
	variable temp
	
	y0 = round( loPx - backgroundwidth - BACKGROUNDOFFSET -1)
	y1 = round(loPx - BACKGROUNDOFFSET - 1)
	y2 = round(hiPx + BACKGROUNDOFFSET+1)
	y3 = round(hiPx + BACKGROUNDOFFSET +1 + backgroundwidth)
	
	//fits a linear background to an image
	//linear fits are along vertical y direction.
	//results in M_imagebkg, the original image minus the background
	//results are also in M_imagebkgSD.
	//imageSD are going to be used as weighting.
	//y0, y1, etc are defined as pixel numbers that are used to create a mask.
	//points will be used to calculate the background if y0<points<y1 and y2<points<y3
	if(y0<0 || y1<y0 || y2<y1||y3<y2||y3>dimsize(image,1))
		return 1
	endif

	duplicate/o image, M_imagebkg,M_imagebkgSD
	make/o/d/n=(dimsize(image,1)) W_mask

	variable ii,degfree=-2
	for(ii=0 ; ii<dimsize(image,1); ii+=1)
		if((ii>=y0 && ii < y1)||(ii > y2 && ii<=y3))
			W_mask[ii] = 1
			degfree += 1
		else
			W_mask[ii] = 0
		endif
	endfor

	//	variable/g V_FitOptions=4
	//	make/o/d/n=2 W_coef
	//	for(ii=0 ; ii<dimsize(image,0);ii+=1)
	//		imagetransform/g=(ii) getrow image
	//		Wave W_extractedRow
	//		
	//		W_coef[0] = W_extractedRow[y0]
	//		W_coef[1] = (W_extractedRow[y3]-W_extractedRow[y0])/(y3-y0)
	//		duplicate/o W_extractedRow W_templine
	//
	//		imagetransform/g=(ii) getrow imageSD
	//		duplicate/o W_extractedRow W_templineSD
	//	
	//		W_templineSD[] = (W_templineSD[p]==0) ? 1 : W_templineSD[p]
	//		//the best and most correct way to propagate the errors will be by using PLA_cpInterval.
	//		//However, it is quicker to estimate the error from a linear interpolation of the prediction band
	//		//this is entirely permissible for background subtraction within the spec beam area
	//		//but will not be correct outside the background+foreground regions.
	//		//In which case use funcfit and Pla_CPInterval, it'll just be slower.
	//		variable v_fiterror=0
	//		CurveFit/n/q/NTHR=0 line  W_templine /M=W_mask /I=1 /W=W_templineSD /D /F={0.683000, 2}
	//		if(getrterror(0))
	//			tempStr = GetRTErrMessage()
	//			M_imagebkg[ii][] = 0
	//			M_imagebkgSD[ii][] = 0
	//			temp = GetRTError(1)
	//		else
	//			Wave UP_W_templine,LP_W_templine
	//			M_imagebkg[ii][] = W_coef[0] + q*W_coef[1]
	//			M_imagebkgSD[ii][] = 0.5*(UP_W_templine(q)-LP_W_templine(q))		
	//		endif
	//	endfor
	
	Make/o/DF/N=(dimsize(image,0))/free dfw
	Multithread dfw= Pla_linbkgworker(image, imageSD, W_mask, p,  y0, y1, y2, y3)
	DFREF df= dfw[0]		
	Duplicate/O df:W_templine, M_imagebkg
	Duplicate/O df:W_templineSD, M_imagebkgSD
	Variable nmax=dimsize(image,0)
	for(ii=1;ii<nmax;ii+=1)
		df= dfw[ii]
		Concatenate {df:W_templine}, M_imagebkg
		Concatenate {df:W_templineSD}, M_imagebkgSD
	endfor
	KillWaves/z dfw
	matrixtranspose M_imagebkg
	matrixtranspose M_imagebkgSD

	M_imagebkg*=-1
	M_imagebkg+=image
	M_imagebkgSD *= M_imagebkgSD
	M_imagebkgSD += imageSD^2
	M_imagebkgSD = sqrt(M_imagebkgSD)

	killwaves/z W_extractedrow,W_Coef,W_mask,W_sigma,W_templine,W_templineSD,M_Covar,W_paramconfidenceinterval
	killwaves/z UC_W_templine, LC_W_templine, UP_W_templine, LP_W_templine
	return 0 
End

Threadsafe Function/DF Pla_linbkgworker(image, imageSD, W_mask, pp,  y0, y1, y2, y3)
	Wave image, imageSD, W_mask
	variable  pp,  y0, y1, y2, y3
	string tempSTr
	variable temp

	DFREF dfSav= GetDataFolderDFR()
	// Create a free data folder to hold the extracted and filtered plane 
	DFREF dfFree= NewFreeDataFolder()
	SetDataFolder dfFree

	imagetransform/g=(pp) getrow image
	Wave W_extractedRow
		
	make/o/d/n=2 W_coef
	W_coef[0] = W_extractedRow[y0]
	W_coef[1] = (W_extractedRow[y3]-W_extractedRow[y0])/(y3-y0)
	duplicate/o W_extractedRow W_templine
	
	imagetransform/g=(pp) getrow imageSD
	duplicate/o W_extractedRow W_templineSD
	
	W_templineSD[] = (W_templineSD[p]==0) ? 1 : W_templineSD[p]
	//the best and most correct way to propagate the errors will be by using PLA_cpInterval.
	//However, it is quicker to estimate the error from a linear interpolation of the prediction band
	//this is entirely permissible for background subtraction within the spec beam area
	//but will not be correct outside the background+foreground regions.
	//In which case use funcfit and Pla_CPInterval, it'll just be slower.
	variable v_fiterror=0

	CurveFit/n/q line, kwCWave=W_coef,  W_templine /M=W_mask /I=1 /W=W_templineSD /D /F={0.683000, 2}
		
	if(getrterror(0))
		tempStr = GetRTErrMessage()
		W_templine = 0
		W_templineSD = 0
		temp = GetRTError(1)
	else
		Wave UP_W_templine,LP_W_templine
		W_templine = W_coef[0] + p*W_coef[1]
		W_templineSD = (p > leftx(UP_W_templine) && p < rightx(UP_W_templine)) ? 0.5*(UP_W_templine(p)-LP_W_templine(p)) : 0
//		W_templineSD[] = 0.5*(UP_W_templine(p)-LP_W_templine(p))
	endif

	SetDataFolder dfSav
	// Return a reference to the free data folder containing M_ImagePlane
	return dfFree
End

Function Pla_CPInterval(fitfunction,xx, covar, params, conflevel, DegFree)
	//confidence level should be between 0 and 100
	String fitfunction
	Variable xx
	Wave covar
	Wave params
	Variable conflevel
	Variable DegFree
	
	Variable ii
	Variable jj
	Variable temp, Yvar
	Variable tP
	
	if( (dimsize(params,0) != dimsize(covar,0)) || (dimsize(covar,1) != dimsize(params,0)))
		abort "covariance matrix not square with same size as param wave"
	endif
	if(conflevel<0 || conflevel>1)
		ABORT "confidence level should be between 0 and 1"
	endif
		
	Duplicate/O params, dyda
	
	if(cmpstr(fitfunction,"Platypus#myline")==0)
		dyda[0] = 0
		dyda[1] = params[1]
	else
		Duplicate/O params, epsilon
		epsilon = 1e-8
		Pla_calcDerivs(fitfunction,xx, params, dyda, epsilon)
	endif
	 
	YVar = 0
	for(ii=0 ; ii<numpnts(params) ; ii+=1)
		temp = 0
		for(jj=0 ; jj<numpnts(params) ; jj+=1)
			temp += covar[jj][ii]*dyda[jj]
		endfor
		YVar += temp*dyda[ii]
	endfor
	
	tP = StudentT(confLevel, DegFree)	
	
	killwaves/z dyda,epsilon,theP
	
	return tP*sqrt(YVar)
end

Function Pla_calcDerivs(fitfunction,xx, params, dyda, epsilon)
	string fitfunction
	Variable xx
	Wave params
	Wave dyda
	Wave epsilon
	
	variable yhat,ii
	Duplicate/O params, theP
	
	variable whattype=Numberbykey("N_Params",Functioninfo(fitfunction))
	if(whattype==2)			//point by point fit function
		Funcref GEN_fitfunc fan=$fitfunction
		yhat = fan(params,xx)
		for(ii=0 ; ii< numpnts(params) ; ii+=1)
			theP = params
			theP[ii] = params[ii]-epsilon[ii]
			yhat = fan(theP, xx)
			theP[ii] = params[ii]+epsilon[ii]
			dyda[ii] = (yhat - fan(theP, xx))/(2*epsilon[ii])
		endfor
	else
		doalert 0,"Can't calculate derivatives for allatonce fitfunctions at this moment"
		abort
	endif
end

Threadsafe Function myline(w,x):fitfunc
	Wave w;variable x
	return w[0]+w[1]*x
end

Threadsafe Function myGAUSS(w,x):fitfunc
	Wave w;variable x
	return w[0]+w[1]*exp(-((w[2]-x)/w[3])^2)
end

Function correct_for_gravity(data, dataSD, lambda, trajectory, lowLambda, highLambda,loBin,hiBin)
	Wave data, dataSD, lambda
	variable trajectory,  lowLambda,highLambda, loBin, hiBin
	//this function provides a gravity corrected yt plot, given the data, its associated errors, the wavelength corresponding to each of the time
	//bins, and the trajectory of the neutrons.  Low lambda and high Lambda are wavelength cutoffs to igore.
	
	
	//output:
	//corrected data,dataSD
	//W_gravCorrCoefs.  THis is a theoretical prediction where the spectral ridge is for each timebin.  This will be used to calculate the actual angle
	//	of incidence in the reduction process.

	variable ii, totaldeflection, err = 0, travel_distance = 0
	try

		if(numpnts(data) != numpnts(dataSD) || dimsize(data,0) != numpnts(lambda))
			print "ERROR the data dimension aren't consistent (correct_for_gravity)"
			err = 1
			abort
		endif

		make/d/o/n=(dimsize(data, 0), dimsize(data, 1)) M_gravitycorrected, M_gravitycorrectedSD
		make/d/o/n=(dimsize(data,1)) Xsection, XsectionSD
		make/d/o/n=(dimsize(data,1)+1) Xsection_px, Xsection_px_rebin
		Xsection_px = p-0.5				//subtract half a pixel because we need to work on histogrammed data.
		
		//find out the correct travel_distance to do.  This is empirical
		//find out where the specular ridge is, as a fn of wavelength
		//this is only likely to work for reasonable wavelengths
		//will fall over if two beams hit the detector
		centre_wavelength(data, loBin, hiBin)
		Wave W_centrewavelength
		
		duplicate/o lambda, W_mask
		//if the wavelength is ridiculous mask the point
		W_mask = W_mask<lowlambda ? NaN : W_mask[p]
		W_mask = W_mask>highLambda ? NaN : W_mask[p]
		W_mask = W_mask<2 ? NaN : W_mask[p]
		W_mask = W_mask>18 ? NaN : W_mask[p]

		//if the centre isn't within a reasonable range of detector pixels ignore it.
		W_mask[] = W_centrewavelength[p] < 30 ? NaN : W_mask[p]
		W_mask[] = W_centrewavelength[p] > 190 ? NaN : W_mask[p]
		
		make/o/n=3/d W_coef = {3000,ROUGH_BEAM_POSITION,0}
		make/o/t W_constraints = {"W_coef[0]<6000","W_coef[0]>1500","W_coef[1]<190","W_coef[1]>30"}
		variable V_fiterror = 0
		FuncFit/H="001"/NTHR=0/n/q deflec W_coef  W_centrewavelength /X=lambda /M=W_mask /C=W_constraints 
		if(V_Fiterror)
			print "ERROR while finding gravity correction (correct_for_gravity)"
			abort
		endif
		travel_distance = W_coef[0]
		duplicate/o W_coef, W_gravCorrCoefs
		
				
		//now rebin the detector accounting for the gravity correction
		for(ii=0 ; ii<dimsize(lambda,0) ; ii+=1)
			totaldeflection = deflection(lambda[ii], travel_distance, trajectory)/Y_PIXEL_SPACING
			Xsection_px_rebin = Xsection_px + totaldeflection

			//extract a row
			imagetransform/g=(ii) getRow data
			Wave W_extractedRow
			Xsection = W_extractedRow
	
			imagetransform/g=(ii) getRow dataSD
			XsectionSD = W_extractedRow
	
			//now rebin and insert back into M_gravitycorrected
			if(Pla_intRebin(Xsection_px, Xsection, XsectionSD, Xsection_px_rebin))
				print "ERROR encountered while rebinning (correction_for_gravity)"
				err = 1
				abort
			endif
			Wave W_rebin, W_rebinSD
			M_gravitycorrected[ii][] = W_rebin[q]
			M_gravitycorrectedSD[ii][] = W_rebinSD[q]
		endfor
	catch

	endtry

	killwaves/z W_extractedRow, Xsection, XsectionSD, Xsection_px, Xsection_px_rebin, W_rebin, W_rebinSD, W_mask,W_centrewavelength, W_extractedRow
	killwaves/z W_coef, W_constraints
	return err
End

Function deflection(lambda, travel_distance, trajectory)
	variable lambda, travel_distance, trajectory
	//returns the deflection in mm of a ballistic neutron
	//lambda in Angstrom, travel_distance (length of correction, e.g. sample - detector) in mm, trajectory in degrees above the horizontal
	//The deflection correction  is the distance from where you expect the neutron to hit the detector (detector_distance*tan(trajectory))
	//to where is actually hits the detector, i.e. the vertical deflection of the neutron due to gravity.

	variable pp, trajRad

	if(lambda>10)
		variable aa=10
	endif
	trajRad = trajectory*Pi/180
	pp = travel_distance/1000 * tan(trajRad)
	pp -= 9.81*(travel_distance/1000)^2*(lambda/1e10)^2 / (2*cos(trajRad)*cos(trajRad)*(P_MN)^2)
	pp *= 1000

	return pp
End

Function deflec(w, lambda):fitfunc
	//fit function that describes the gravity deflection of a neutron with wavelength lambda.
	//the returned value is expressed in terms of detector pixels.
	Wave w
	variable lambda
	
	return deflection(lambda,w[0],w[2])/Y_PIXEL_SPACING + w[1]
End

Function centre_wavelength(data, lobin, hibin)
	Wave data
	variable lobin, hibin
	//finds out where the spectral ridge is for each time bin in a yt plot.
	make/o/d/n=(dimsize(data,0)) W_centreWavelength = NaN
	variable ii
		
	make/o/n=(dimsize(data,1)) xdata = p
	
//	for(ii=0 ; ii <dimsize(data,0) ; ii+=1)
//		//extract a row
//		variable V_fiterror = 0
//		imagetransform/g=(ii) getRow data
//		Wave W_extractedRow
//		
//		W_centrewavelength[ii] = Pla_peakcentroid(xdata, W_extractedrow, x0= loBin, x1 = hiBin)
//		//		curvefit/n=1/q/NTHR=2 gauss  data[ii][]
//		//		Wave W_coef
//		//		if(!V_fiterror)
//		//			W_centrewavelength[ii] = W_coef[2]
//		//		else
//		//			W_centrewavelength[ii] = NaN
//		//		endif
//	endfor
	
	Make/o/DF/N=(dimsize(data, 0))/free dfw
	 dfw = Pla_centre_wavelengthworker(xdata, data, p, loBin, hiBin)
	DFREF df
	for(ii = 0 ; ii < dimsize(data, 0) ; ii+=1)
		df = dfw[ii]
		Wave theResult = df:theResult
		W_centrewavelength[ii] = theResult[0]
	endfor	
	
	killwaves/z W_coef, xdata, dfw
End

Threadsafe Function/DF Pla_centre_wavelengthworker(xdata, data, pp, loBin, hiBin)
	Wave xdata, data
	variable pp, lobin, hibin
	
	//a parallelised way of doing a wavelength rebin, called by Pla_2
	DFREF dfSav= GetDataFolderDFR()
	// Create a free data folder to hold the extracted and filtered plane 
	DFREF dfFree= NewFreeDataFolder()
	SetDataFolder dfFree
		
	make/n=1/d theResult
	imagetransform/g=(pp) getRow data
	Wave W_extractedRow
		
	theResult[0] = Pla_peakcentroid(xdata, W_extractedrow, x0= loBin, x1 = hiBin)
	
	SetDataFolder dfSav
	// Return a reference to the free data folder containing M_ImagePlane
	return dfFree	
End


Function Pla_beam_width(w, zz, d1, d2): fitfunc
	wave w, zz, d1, d2

	variable L12,  L2D, detcloud, scalefactor, ii

	L12 = 2834.5   //distance between the slits
	L2D = 2785.7	//distance from slits to point of interest

	detCloud = w[0]
	scalefactor = w[1]

	make/n=(dimsize(d1,0))/d/free x1, x2

	make/n=1000/o/d/free detresponse, beamProfile
	setscale/P x -50, 0.1, detresponse, beamprofile

	detresponse = gauss(x, 0, detCloud)

	x1 =  d2/2 + (((d1 - d2)*L2D) / (2 * L12)) 
	x2 = (((d1 + d2)*L2D) / (2 * L12)) + d2/2

	for(ii = 0 ; ii< dimsize(d1, 0) ; ii+=1)
		beamprofile = 0
		beamprofile[] = (abs(pnt2x(beamprofile, p)) <= x1[ii]) ? 1 : 0
		beamprofile[] = (abs(pnt2x(beamprofile, p)) >= x1[ii] && abs(pnt2x(beamprofile, p)) <= x2[ii]) ? (abs(pnt2x(beamprofile, p)) - x2[ii])/(x1[ii] - x2[ii]) : beamprofile[p]
		convolve/a detresponse, beamprofile
		beamprofile *= 0.1
		findlevel/q beamprofile, 0.02
		zz[ii] = scalefactor * abs(2*V_levelX)
	endfor
End

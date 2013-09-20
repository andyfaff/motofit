#pragma rtGlobals=3		// Use modern global access method.
//background offset is the separation between the specridge and the region taken to be background.
	constant BACKGROUNDOFFSET = 2
//the value you multiply the FWHM by to get the foregroundwidth
	constant INTEGRATEFACTOR = 1.7

	// SVN date:    $Date$
	// SVN author:  $Author$
	// SVN rev.:    $Revision$
	// SVN URL:     $HeadURL$
	// SVN ID:      $Id$
	
Function topAndTail(measurement, measurementSD, peak_Centre,peak_FWHM,background [, backgroundMask])
	Wave measurement	//the data from the NeXUS file
	Wave measurementSD
	variable peak_Centre, peak_FWHM //expected_width is the FWHM width of the beam
	variable background		//do you want to do a background reduction
	Wave/z backgroundMask	//this mask is used to specify which points are used as the background region. Set to  zero, or NaN if NOT background.
	
	//the specular region is integrated over around the specular pixels, after
	//subtracting a linear background.  THe linear background is determined by fitting the intensity in backgroundwidth pixels each side of the
	//foreground area
	
	
	//measurement is taken to be a 3d wave [time][y][layers]
	
	//output:
	//M_topandtail
	//M_topandtailSD
	//M_spec
	//M_specSD

	variable ii,jj,kk,tempVar,foregroundwidth,backgroundwidth
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

		if(Wavedims(measurement) != 3 || Wavedims(measurementSD) != 3)
			print "ERROR: whilst reducing, dataset should be 3D [time][y][layers] (topAndTail)"
			abort
		endif

		make/o/d/n=(dimsize(measurement,0),dimsize(measurement,1), dimsize(measurement, 2)) root:packages:platypus:data:reducer:M_topAndTail
		Wave M_topAndTail= root:packages:platypus:data:reducer:M_topAndTail
		M_topAndTail[][][] = measurement[p][q][r]
		
		//make an error wave
		duplicate/o measurementSD, M_topAndTailSD
		
		//do the background subtraction
		if(background)
			backgroundWidth = INTEGRATEFACTOR * peak_FWHM
		else
			backgroundwidth = 0
		endif

		variable loPx, hiPx
		foregroundwidth = peak_FWHM * INTEGRATEFACTOR
		loPx = floor(peak_centre - foregroundwidth / 2)
		hiPx = ceil(peak_centre + foregroundwidth / 2)
		
		if(background && (backgroundwidth > 0 || waveexists(backgroundMask)))
			if(Pla_linbkg(M_topAndTail, M_topAndTailSD,loPx, hiPx, backgroundwidth, backgroundMask = backgroundMask))
				print "ERROR: whilst reducing: (topAndTail)"
				abort
			endif
			wave M_imagebkg, M_imagebkgSD
		else
			duplicate/free M_topandtail,M_imagebkg
			duplicate/free M_topandtailSD,M_imagebkgSD		
		endif

		//now we have M_imagebkg and M_imagebkgSD, copy those back into M_topAndTail
		Multithread M_topandtail = M_imagebkg
		Multithread M_topandtailSD = M_imagebkgSD
	 	
		duplicate/free M_imagebkg, temp
		duplicate/free M_imagebkgSD, tempSD

		//now lets produce the background subtracted, integrated spectrum
		deletepoints/M=1 hiPx+1, dimsize(temp, 1), temp, tempSD
		deletepoints/M=1 0, loPx, temp, tempSD
		make/d/o/n=(dimsize(temp, 0), dimsize(temp, 2)) M_spec = 0, M_specSD = 0
		for(ii = 0 ; ii < dimsize(temp, 2) ; ii += 1)
			imagetransform/p=(ii) sumallrows temp
			Wave W_sumrows
			M_spec[][ii] = W_sumrows[p]
		endfor
	
		//now create the SD of the integrated, background subtracted TOF spectrum
		variable count1,count2
		count1 = dimsize(M_specSD, 0)
		count2 = dimsize(tempSD, 1)
		for(kk = 0 ; kk < dimsize(M_spec, 1) ; kk += 1)
			for(ii = 0 ; ii < count1 ; ii += 1)
				for(jj = 0 ; jj < count2 ; jj += 1)
					M_specSD[ii][kk] += (tempSD[ii][jj][kk]^2)
				endfor
			endfor
		endfor
		M_specSD = sqrt(M_specSD)
		
		//make a record of the beam position on the detector by storing it in the wave note
		//these values were found above using findspecridge
		//these values are only applicable for reflected beams.  Direct beam centres depend on wavelength.
		//also make a note of the integration region on the detector, these are INCLUSIVE
		note/k M_spec
		note/k M_topandtail
		string tempStr =  "centre:"+num2str(peak_centre)+";FWHM:"+num2str(peak_FWHM)
		tempStr +=";loPx:"+num2str(loPx)
		tempStr +=";hiPx:"+num2str(hiPx)
		note M_spec, tempStr
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
	string waterDF = getwavesdatafolder(waterrun, 1)
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
		lowestX = (binarysearch(watXbin, dataXbin[dimsize(dataXbin,0) - 1]))
		deletepoints/M=2 lowestX+1, dimsize(M_waternorm, 2), M_waternorm
		deletepoints/M=2 0, highestX, M_waternorm
		
		//this averages over x
		imagetransform sumplanes, M_waternorm
		Wave M_sumplanes
		duplicate/o M_sumplanes, M_waternorm
		killwaves/z M_sumplanes

		imagetransform sumallcols M_waternorm 
		Wave W_sumcols
		duplicate/o W_sumcols,W_waternorm

		duplicate/o W_waternorm, W_waternormSD
		W_waternormSD=sqrt(W_waternorm+1)
		//disregard 10 points on each edge of the detector from the mean
		tempVar = mean(W_waternorm, 10, 210)
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

Function findSpecRidge(tynWave, searchIncrement , tolerance, expected_peak, binToStartFrom, retval)
	Wave tynWave
	variable searchIncrement, tolerance
	variable/c   expected_peak
	variable binToStartFrom
	variable/c &retval 
	retval =  cmplx(NaN,NaN)

	variable ii,jj

	//detector wave (ytnwave) is expected to be 3 dimensional, i.e. ytwave[t][y][layer]
	//we will do the beam locating on the SUM of all the layers!
	
	if(wavedims(tynWave) != 3)
		print "ERROR incorrect size for ytWave, not 3dimensional (findSpecRidge)"
		return 1
	endif
	if(searchIncrement > dimsize(tynWave,0))
		print "ERROR increment is larger than the first dimension (findSpecRidge)"
		return 1
	endif
	
	//we are going to do the search on the sum of the planes
	imagetransform sumplanes tynWave
	Wave M_sumplanes
	
	try
		make/o/d/n=(dimsize(M_sumplanes, 1))/free subSection = 0, subSectionX=p
		make/o/d/n=(0)/free peakCentre,peakFWHM

		for(ii = bintostartfrom, jj = 0 ; ii >= 0 ; ii -= searchIncrement, jj+=1)
			redimension/n=(jj + 1, -1) peakCentre, peakFWHM
			
			Duplicate/o/free/r=[ii, dimsize(M_sumplanes, 0) - 1][0, dimsize(M_sumplanes, 1) - 1] M_sumplanes, subimage
			imagetransform sumallcols subimage
			Wave W_sumcols
			subsection = W_sumcols

			Pla_findpeakdetails(subsection, subsectionX,expected_centre = real(expected_peak), expected_width = imag(expected_peak))
			Wave W_peakInfo
			if((2.35482 * W_peakInfo[7]/sqrt(2) < imag(expected_peak) && abs(W_peakInfo[6] - real(expected_peak)) <  2 * imag(expected_peak)))
				peakCentre[jj] = W_peakInfo[6]
				peakFWHM[jj] = 2.35482 * W_peakInfo[7]/sqrt(2)
			else
				peakCentre[jj] = NaN
				peakFWHM[jj] = NaN
			endif	
			
			if(jj>0 && abs((peakCentre[jj]-peakCentre[jj -1])/peakCentre[jj]) < tolerance && abs((peakFWHM[jj]-peakFWHM[jj - 1])/peakFWHM[jj]) < tolerance)
				retval = cmplx(W_peakInfo[6], 2.35482*W_peakInfo[7]/sqrt(2))
				break
			endif	
		endfor
	catch
		print "PROBLEM whilst finding specular ridge (findSpecRidge)"
		killwaves/z W_peakinfo, M_sumplanes, W_sumcols
	
		return 1
	endtry

	killwaves/z W_peakinfo, M_sumplanes, W_sumcols

	if(imag(retval) >  imag(expected_peak) || abs(real(retval) - real(expected_peak)) >  2 * imag(expected_peak))
		print "PROBLEM, there was no significant specular beam detected: ", Getwavesdatafolder(tynwave,0) , "(findspecularridge)"
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
	print "CHod is:",chod
	return chod
End

Threadsafe Function TOFtoLambda(TOF, distance)
	variable TOF
	variable distance
	//convert TOF to lambda.
	//time of flight in microseconds, flight distance in mm, time offset in microseconds
	//output in Angstrom
	return 1e7 * P_MN * TOF / distance
End

Threadsafe Function LambdatoTOF(Lambda, distance)
	variable Lambda
	variable distance
	//convert  lambda to TOF
	//time of flight in microseconds, flight distance in mm, time offset in microseconds

	//make the wave to put it in
	
	return  (lambda/P_MN)*distance * 1e-7
End

Threadsafe Function LambdaToQ(lambda, omega)
	variable lambda
	variable omega

	//converts wave containing lambda values, and an incident angle to Q vector.  
	//lambda in Angstrom
	//omega in radians
	return 4 * Pi * sin(omega) / lambda
End

Function histToPoint(w)
	Wave w
	make/o/d/n=(numpnts(w)-1) W_point
	w_point[] = w[p]+w[p+1]
	W_point /=2
End

Function Pla_linbkg(image, imageSD, loPx, hiPx, backgroundwidth, [backgroundMask])
	Wave image,imageSD
	variable loPx, hiPx, backgroundwidth
	Wave/z backgroundMask
	
	//background offset must NEVER be negative
	variable y0,y1,y2,y3
	string tempStr=""
	variable temp
	
	y0 = round( loPx - backgroundwidth - BACKGROUNDOFFSET  - 1)
	y1 = round(loPx - BACKGROUNDOFFSET - 1)
	y2 = round(hiPx + BACKGROUNDOFFSET + 1)
	y3 = round(hiPx + BACKGROUNDOFFSET + 1 + backgroundwidth)
	
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
	make/d/n=(dimsize(image,1))/free W_mask = 0

	variable ii,degfree=-2, jj, numplanes = 0
	for(ii=0 ; ii<dimsize(image,1); ii+=1)
		if((ii>=y0 && ii < y1)||(ii > y2 && ii<=y3))
			W_mask[ii] = 1
			degfree += 1
		endif
	endfor
	
	//you want to specify a background region manually
	if(!paramisdefault(backgroundmask) && waveexists(backgroundMask))
		W_mask = backgroundMask
		degfree = -2
		for(ii = 0 ; ii< dimsize(image, 1) ; ii+=1)
			if(!numtype(backgroundMask[ii]) && backgroundMask[ii])
				degfree += 1
			endif
		endfor
	endif

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
	
	duplicate/o image, M_imagebkg, M_imagebkgSD
	multithread M_imagebkg = 0
	multithread M_imagebkgSD = 0
	
	for(ii = 0 ; ii < dimsize(image, 2) ; ii += 1)
		Make/o/DF/N=(dimsize(image,0))/free dfw
		Multithread dfw= Pla_linbkgworker(image, imageSD, W_mask, p,  y0, y1, y2, y3, ii)
		for(jj = 0 ; jj < dimsize(image, 0) ; jj += 1)
			DFREF df= dfw[jj]
			Wave W_templine = df:W_templine
			Wave W_templineSD = df:W_templineSD
			M_imagebkg[jj][][ii] =  W_templine[q]
			M_imagebkgSD[jj][][ii] =  W_templineSD[q]
		endfor
		killwaves/z dfw 
	endfor
	
	//do the background subtraction.
	EP_sub(image, imageSD, M_imagebkg, M_imagebkgSD, M_imagebkg, M_imagebkgSD)
	
	killwaves/z W_extractedrow,W_Coef,W_mask,W_sigma,W_templine,W_templineSD,M_Covar,W_paramconfidenceinterval
	killwaves/z UC_W_templine, LC_W_templine, UP_W_templine, LP_W_templine
	return 0 
End

Threadsafe Function/DF Pla_linbkgworker(image, imageSD, W_mask, pp,  y0, y1, y2, y3, layer)
	Wave image, imageSD, W_mask
	variable  pp,  y0, y1, y2, y3, layer
	string tempSTr
	variable temp

	DFREF dfSav= GetDataFolderDFR()
	// Create a free data folder to hold the extracted and filtered plane 
	DFREF dfFree= NewFreeDataFolder()
	SetDataFolder dfFree
	
	imagetransform/g=(pp)/p=(layer) getrow image
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
	variable v_fiterror=0, v_fitoptions = 4

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

Function Pla_CPInterval(fitfunction, xx, covar, params, conflevel, DegFree)
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

Function Pla_calcDerivs(fitfunction, xx, params, dyda, epsilon)
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

Threadsafe Function myline(w, x):fitfunc
	Wave w;variable x
	return w[0]+w[1]*x
end

Threadsafe Function myGAUSS(w,x):fitfunc
	Wave w;variable x
	return w[0]+w[1]*exp(-((w[2]-x)/w[3])^2)
end

Function correct_for_gravity(data, dataSD, lambda, trajectory, lowLambda, highLambda, loBin, hiBin)
	Wave data, dataSD, lambda
	variable trajectory,  lowLambda, highLambda, loBin, hiBin
	//this function provides a gravity corrected yt plot, given the data, its associated errors, the wavelength corresponding to each of the time
	//bins, and the trajectory of the neutrons.  Low lambda and high Lambda are wavelength cutoffs to igore.
	
	//output:
	//corrected data, dataSD
	//M_gravCorrCoefs.  THis is a theoretical prediction where the spectral ridge is for each timebin.  This will be used to calculate the actual angle
	//	of incidence in the reduction process.

	variable ii, jj, totaldeflection, err = 0, travel_distance
	try
		if(numpnts(data) != numpnts(dataSD) || dimsize(data, 0) != dimsize(lambda, 0))
			print "ERROR the data dimension aren't consistent (correct_for_gravity)"
			err = 1
			abort
		endif
		if(dimsize(lambda, 1) != dimsize(data, 2))
			print "ERROR the data and wavelength matrix must be 2D (correct_for_gravity)"
			err = 1
			abort
		endif

		make/d/o/n=(dimsize(data, 0), dimsize(data, 1), dimsize(data, 2)) M_gravitycorrected, M_gravitycorrectedSD
		make/d/o/n=(dimsize(data, 1)) Xsection, XsectionSD
		make/d/o/n=(dimsize(data, 1) + 1) Xsection_px, Xsection_px_rebin
		Xsection_px = p-0.5				//subtract half a pixel because we need to work on histogrammed data.
		
		//find out the correct travel_distance to do.  This is empirical
		//find out where the specular ridge is, as a fn of wavelength
		//this is only likely to work for reasonable wavelengths
		//will fall over if two beams hit the detector
		centre_wavelength(data, loBin, hiBin)
		Wave M_centrewavelength
		
		make/n=(dimsize(lambda, 0))/free/d W_mask = lambda[p][0]
		//if the wavelength is ridiculous mask the point
		W_mask = W_mask < lowlambda ? NaN : W_mask[p]
		W_mask = W_mask > highLambda ? NaN : W_mask[p]
		W_mask = W_mask < 2 ? NaN : W_mask[p]
		W_mask = W_mask > 18 ? NaN : W_mask[p]

		//if the centre isn't within a reasonable range of detector pixels ignore it.
		make/n=(3, dimsize(data, 2)) /o/d M_gravCorrCoefs = 0

		make/o/n=3/d W_coef = {3000,ROUGH_BEAM_POSITION,0}
		make/o/t W_constraints = {"W_coef[0]<6000","W_coef[0]>1500","W_coef[1]<190","W_coef[1]>30"}
		
		for(jj = 0 ; jj < dimsize(data, 2) ; jj += 1)
			W_mask[] = M_centrewavelength[p][jj] < 30 ? NaN : W_mask[p]
			W_mask[] = M_centrewavelength[p][jj] > 190 ? NaN : W_mask[p]
				
			variable V_fiterror = 0
			FuncFit/H="001"/NTHR=0/n/q deflec W_coef  M_centrewavelength[][jj] /X=lambda[][jj] /M=W_mask /C=W_constraints 
			if(V_fiterror)
				print "ERROR while finding gravity correction (correct_for_gravity)"
				abort
			endif
			travel_distance = W_coef[0]

			M_gravCorrCoefs[][jj] = W_coef[p]
				
			//now rebin the detector accounting for the gravity correction
			for(ii = 0 ; ii < dimsize(lambda, 0) ; ii += 1)
				totaldeflection = deflection(lambda[ii], travel_distance, trajectory)/Y_PIXEL_SPACING
				Xsection_px_rebin = Xsection_px + totaldeflection

				//extract a row
				imagetransform/g=(ii)/P=(jj) getRow data
				Wave W_extractedRow
				Xsection = W_extractedRow
	
				imagetransform/g=(ii)/P=(jj) getRow dataSD
				XsectionSD = W_extractedRow
	
				//now rebin and insert back into M_gravitycorrected
				if(Pla_intRebin(Xsection_px, Xsection, XsectionSD, Xsection_px_rebin))
					print "ERROR encountered while rebinning (correction_for_gravity)"
					err = 1
					abort
				endif
				Wave W_rebin, W_rebinSD
				M_gravitycorrected[ii][][jj] = W_rebin[q]
				M_gravitycorrectedSD[ii][][jj] = W_rebinSD[q]
			endfor
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
	//finds out where the spectral ridge is for each time bin in a ytn plot.
	make/o/d/n=(dimsize(data,0), dimsize(data, 2)) M_centreWavelength = NaN
	variable ii, jj
		
	make/o/n=(dimsize(data, 1)) xdata = p
	
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
	for(ii = 0 ; ii < dimsize(data, 2) ; ii += 1)
		Make/o/DF/N=(dimsize(data, 0))/free dfw
		Multithread dfw[] = Pla_centre_wavelengthworker(xdata, data, p, loBin, hiBin, ii)
		DFREF df
		for(jj= 0 ; jj < dimsize(data, 0) ; jj += 1)
			df = dfw[jj]
			Wave theResult = df:theResult
			M_centrewavelength[jj][ii] = theResult[0]
		endfor	
	endfor
	killwaves/z W_coef, xdata, dfw
End

Threadsafe Function/DF Pla_centre_wavelengthworker(xdata, data, pp, loBin, hiBin, layer)
	Wave xdata, data
	variable pp, lobin, hibin, layer
	
	//a parallelised way of doing a wavelength rebin, called by Pla_2
	DFREF dfSav= GetDataFolderDFR()
	// Create a free data folder to hold the extracted and filtered plane 
	DFREF dfFree= NewFreeDataFolder()
	SetDataFolder dfFree
		
	make/n=1/d theResult
	imagetransform/g=(pp)/P=(layer) getRow data
	Wave W_extractedRow
		
	theResult[0] = Pla_peakcentroid(xdata, W_extractedrow, x0= loBin, x1 = hiBin)
	
	SetDataFolder dfSav
	// Return a reference to the free data folder containing M_ImagePlane
	return dfFree	
End


Function Pla_beam_width( w, zz, d1, d2): fitfunc
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

Function/wave Pla_gen_binboundaries(lowlambda, highlambda, rebinpercent)
	//generates logarithmically spaced bin boundaries, with low and high wavelength cutoffs.
	//the bins are centred around those cutoffs (meaning you do use data with a slightly lower/higher wavelength 
	//than low/high lambda)
	variable lowlambda, highlambda, rebinpercent
	variable frac = 1. + (rebinpercent/100.)
	
	lowlambda = (2 * lowlambda) / ( 1. + frac)
	highlambda =  frac * (2 * highlambda) / ( 1. + frac)              
	variable numsteps = floor(log(highlambda / lowlambda ) / log(frac)) + 1
	variable stepsize = log(highlambda / lowlambda ) /(numsteps - 1)
	
	make/d/o/n= (numsteps) W_rebinBoundaries = log(lowlambda) + p * stepsize
	W_rebinboundaries = alog(W_rebinboundaries)
	Wave W_rebinboundaries = W_rebinboundaries
	return W_rebinboundaries
End

////////////////////////////////////////////////////////////////
//highly detailed resolution kernel
////////////////////////////////////////////////////////////////

Function thetadist(theta, qwave, d1, d2, L12, nom_q, nom_theta)
	
	Wave theta, qwave
	variable d1, d2, L12, nom_q, nom_theta
	//work out the PDF for the angular component of the resolution function

	variable beeta, alpha, gradient, intercept, areas, nom_lambda, thetarad

	nom_lambda = 4*Pi*sin(nom_theta*Pi/180)/nom_q
	thetarad = nom_theta * Pi / 180
	
	alpha = (d1 + d2) / 2 / L12
	beeta = abs(d1-d2) / 2 / L12
	
	duplicate/free qwave, xtheta
	xtheta = asin(qwave[p] * nom_lambda / 4 / Pi)
	
	theta = (xtheta[p] >= thetarad-beeta && xtheta[p] <= thetarad + beeta) ? 1 : 0
	gradient = 1/(alpha - beeta)
	intercept = alpha * gradient
	theta = (xtheta[p] < thetarad-beeta) ? gradient * (xtheta[p]-thetarad) + alpha * gradient : theta
	theta = (xtheta[p] > thetarad+beeta) ? -gradient * (xtheta[p]-thetarad) + alpha * gradient : theta
	theta = (xtheta[p] < thetarad-alpha || xtheta[p] >= thetarad + alpha) ? 0 : theta

	areas =  area(theta)
	theta /= areas
	
	//now we have distribution as a function of theta
	//transform with the jacobian
	theta *= nom_lambda/4/Pi/cos(xtheta[p])
	
End

Function lambdadist(lambdadist, qwave, nom_lambda, reso, nom_q)
	Wave lambdadist, qwave
	variable nom_lambda, reso, nom_q
	//work out the PDF for the wavelength component of the resolution function. Burst time and rebinning.

	variable areas, dl, K, loLambda, hiLambda, hiQ, loQ, nomtheta, lambda, pnt
	
	K = nom_q * nom_lambda		//4 * Pi * sin(theta)
	dl = nom_lambda * reso/200

	hiQ = K/(nom_lambda - dl)
	loQ = K/(nom_lambda + dl)
	
	lambdadist = 0
	//The rectangular distribution must undergo a Jacobian transformation
	//into Q space
	lambdadist = (qwave[p] >= loQ && qWave[p] <= hiQ) ? K/ 2 / dl / qwave[p]^2 : 0

End

Function crossingtimedist(lambdadist, qwave, nom_lambda, ss2vg, chod, radius, freq, nom_q)
	Wave lambdadist, qwave
	variable  nom_lambda, ss2vg, chod, radius, freq, nom_q
	//work out the PDF for the wavelength component of the resolution function, crossing time component.
	variable areas, tau, totalflight, temp2, temp, K, dl
	
	K = nom_q * nom_lambda		//4 * Pi * sin(theta)

	totalflight = nom_lambda/3956*(chod/1000)
	tau = ss2vg/radius/2/Pi/freq 
	temp = 3956* (totalflight-tau / 2)/(chod/1000)
	temp2 = 3956* (totalflight+tau / 2)/(chod/1000)

	lambdadist = (K/qwave[p] >= temp && K/qwave[p] <= temp2) ? K / (temp2 - temp) / qwave[p]^2 : 0		
End

function/wave actualkernel(nomtheta, d1,d2,L12, nomq, reso, chod, radius, freq, specI, specL, DA)
	Variable nomtheta, d1, d2, L12, nomq, reso, chod, radius, freq
	Wave specI, specL
	variable DA

	variable qq, areas, nomlambda, K
	make/d/n=501/o/free lambda, theta, qwave, lambda2, lambda3
	duplicate/free qwave, xlambda, xtheta, tempkernel,  templambdakernel, spec_IQ
	
	nomlambda = 4 * Pi * sin(nomtheta*Pi/180)/nomq
//	print nomlambda
	
	qq = 4*Pi*sin(nomtheta *Pi/180)/nomlambda
	setscale/I x, qq * (0.9), qq * 1.1, theta, lambda, lambda2, qwave, tempkernel, templambdakernel, lambda3, spec_IQ

	qwave = x
	xlambda[] = 4 * Pi * sin(nomtheta*Pi/180)/qwave[p] - nomlambda
	xtheta[] = asin(qwave[p] /4 / Pi * nomlambda) - (nomtheta*Pi/180)

	//angular component
	thetadist(theta, qwave, d1,d2, L12, nomq, nomtheta); 
	//burst time component
	lambdadist(lambda, qwave, nomlambda, reso, nomq)
	//rebinning component
	lambdadist(lambda3, qwave, nomlambda, DA, nomq)
	//crossing time component
	crossingtimedist(lambda2, qwave, nomlambda, d2, chod, radius, freq, nomq)

	//work out p(Q) for incidence beam spectrum
	//don't forget to multiply with source distribution
	K = nomq * nomlambda
	variable jj
	for(jj = 0 ; jj < numpnts(spec_IQ) ; jj += 1)
		variable wavelength = K/qwave[jj]
		variable point = binarysearchinterp(specL,  wavelength)
		if(numtype(point))
			if(K/qwave[jj] < specL[0])
				spec_IQ[jj] = K * specI[0]/qwave[jj]^2
			else
				spec_IQ[jj] = K * specI[numpnts(specI) - 1]/qwave[jj]^2
			endif
		else
			spec_IQ[jj] = K * specI[point]/qwave[jj]^2
		endif
	
	endfor
	
//	spec_IQ[] = K * specI[binarysearchinterp(specL,  K/qwave[p])]/qwave[p]^2

//have both lambda terms.  Need to convolve both together and multiply with p(Q) of the incident beam spectrum
	templambdakernel = lambda
	
	convolve/A lambda2, templambdakernel
	templambdakernel *= deltax(templambdakernel)
	
	convolve/A lambda3, templambdakernel
	templambdakernel *= deltax(templambdakernel)
	
	templambdakernel *= spec_IQ

	areas = areaXY(qwave, templambdakernel)
	templambdakernel /= areas

//fold in the angular component
	areas =  areaxy(qwave, theta)
	theta /= areas

	tempkernel = theta
	convolve/A templambdakernel, tempkernel
	tempkernel *=deltax(tempkernel)

	make/n=(dimsize(tempkernel, 0), 2)/o/d kernel
	copyscales tempkernel, kernel
	kernel[][0] = qwave[p]	
	kernel[][1] = tempkernel[p]
	return kernel
End

Function assignActualKernel(refDF, directDF, W_q, specnum)
	string refDF, directDF
	Wave W_q
	variable specnum
	//calculates the full resolution kernel for reflectivity spectra
	DFRef cDF = getdatafolderDFR()
	variable ii
	
	setdatafolder refDF
	
	Wave d1 = $(refDF + ":instrument:slits:second:vertical:gap")
	Wave d2 = $(refDF + ":instrument:slits:third:vertical:gap")
	Wave omega = $(refDF + ":omega")
	Wave M_lambdaD = $(directDF + ":M_lambda")
	Wave M_specD = $(directDF + ":M_spec")
	Wave chod = $(refDF + ":chod")
	Wave D_CX = $(refDF + ":D_CX")
	Wave phaseAngle = $(refDF + ":phaseAngle")
	Wave frequency = $(refDF + ":instrument:disk_chopper:ch1speed")
	Wave M_specTOFHIST = $(refDF + ":M_specTOFHIST")
	Wave M_specTOF = $(refDF + ":M_specTOF")
		
	duplicate/r=[0, dimsize(W_q, 0) - 1][specnum, specnum]/free W_q, qq
	duplicate/r=[0, dimsize(omega, 0) - 1][specnum][specnum]/free omega, omegas
	duplicate/r=[0, dimsize(M_lambdaD, 0) - 1][0]/free M_lambdaD, specL
	duplicate/r=[0, dimsize(M_specD, 0) - 1][0]/free M_specD, specI
	
	redimension/n=(-1, 0) specL, specI, qq, omegas
	
	make/n=(dimsize(qq, 0), 501, 2)/d/o resolutionkernel
	
	//reso, the burst time contribution
	variable reso = 100 * D_CX[specnum]/chod[specnum]
	
	//collimation distance
	Wave slit2_distance = $(refDF + ":instrument:parameters:slit2_distance")
	Wave slit3_distance = $(refDF + ":instrument:parameters:slit3_distance")
	variable L12 = slit3_distance[0] - slit2_distance[0]
	
	for(ii = 0 ; ii < numpnts(qq) ; ii+=1)
		variable nomlambda = 4 * Pi * sin(omegas[ii]) / qq[ii]
		//DA, the smearing due to broad timebins and/or rebinning
		variable DA = 100 * (M_specTOFHIST[ii + 1][specnum] - M_specTOFHIST[ii][specnum]) / M_specTOF[ii][specnum]
		
		//reso2, resolution contribution to burst time due to phase opening of choppers
		variable reso2 = 100 * (phaseAngle[specnum] * pi / 180) * 3956 / nomlambda / (chod[specnum] / 1000) / (2 * pi * frequency[0] / 60)

		Wave kernel = actualkernel(omegas[ii] * 180 / pi, d1[specnum], d2[specnum], L12, qq[ii], reso + reso2, chod[specnum], 350, frequency[0]/60, specI, specL, DA)

		resolutionkernel[ii][][0] = kernel[q][0]
		resolutionkernel[ii][][1] = kernel[q][1]
	endfor
	
	reverse/DIM=0 resolutionkernel
	
	setdatafolder cDF
End

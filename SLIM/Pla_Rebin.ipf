#pragma rtGlobals=3		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

Function Pla_PlaneIntRebin(x_init, data, dataSD, x_rebin)
	Wave x_init, data, dataSD, x_rebin

	//Rebins 3D histogrammed data [x][y][slice] into boundaries set by xy_rebin.
	//makes the waves M_rebin and M_RebinSD.
	//each slice is done individually

	//it uses linear interpolation to work out the proportions of which original cells should be placed
	//in the new bin boundaries.

	// Precision will normally be lost.  
	// It does not make sense to rebin to smaller bin boundaries.

	variable ii,jj
	make/o/d/n=(dimsize(x_rebin, 0) - 1, dimsize(data, 1), dimsize(data, 2)) M_rebin,M_rebinSD

	if(checkSorted(x_rebin) || checkSorted(x_init))
		print "The x_rebin and x_init must be monotonically increasing (Pla_2DintRebin)"
		return 1
	endif
	
	if(wavedims(x_init) != 2 || wavedims(data) != 3 || wavedims(dataSD) != 3 || wavedims(x_rebin)!=1 || dimsize(x_init, 1) != dimsize(data, 2))
		print "One of the wave dimensions is wrong (Pla_intrebin)"	
		return 1
	endif
	
	if(dimsize(x_init, 0) - 1 != dimsize(data, 0) || numpnts(data) != numpnts(dataSD))
		print "data and dataSD must have one less point in the y-direction than y_init (Pla_intRebin)"
		return 1
	endif

	//iterate through the columns and rebin each of them
//	for(ii = 0 ; ii<dimsize(data,1) ; ii+=1)
//		imagetransform/g=(ii) getcol data
//		duplicate/o W_extractedcol tempCol
//		imagetransform/g=(ii) getcol dataSD
//		duplicate/o W_extractedcol tempColSD
//		Pla_intRebin(x_init,tempCol,tempColSD,x_rebin)
//		Wave W_rebin,W_rebinSD
//		imagetransform/D=W_rebin/G=(ii) putcol M_rebin
//		imagetransform/D=W_rebinSD/G=(ii) putcol M_rebinSD
//	endfor
	for(jj = 0 ; jj < dimsize(data, 2) ; jj += 1)
		imagetransform/g=(jj) getcol x_init
		Wave W_extractedCol	
		Make/o/DF/N=(dimsize(data, 1))/free dfw
		MultiThread dfw = Pla_2DintRebinWorker(W_extractedCol, data, dataSD, x_rebin, p, jj)
		DFREF df
		for(ii = 0 ; ii < dimsize(data, 1) ; ii+=1)
			df = dfw[ii]
			imagetransform/D=df:W_rebin/G=(ii)/P=(jj) putcol M_rebin
			imagetransform/D=df:W_rebinSD/G=(ii)/P=(jj) putcol M_rebinSD
		endfor	
	endfor
	
	killwaves/z tempcol,W_extractedcol,W_rebin,W_rebinSD, tempcolSD, dfw
end

Threadsafe Function/DF Pla_2DintRebinWorker(x_init, data, dataSD, x_rebin, qq, layer)
	Wave x_init, data, dataSD, x_rebin
	variable qq, layer
	//a parallelised way of doing a wavelength rebin, called by Pla_2
	DFREF dfSav= GetDataFolderDFR()
	// Create a free data folder to hold the extracted and filtered plane 
	DFREF dfFree= NewFreeDataFolder()
	SetDataFolder dfFree
		
	imagetransform/g=(qq)/P=(layer) getcol data
	Wave W_extractedcol
	duplicate/o W_extractedcol, tempCol
	imagetransform/g=(qq)/P=(layer) getcol dataSD
	duplicate/o W_extractedcol tempColSD
	Pla_intRebin(x_init, tempCol, tempColSD, x_rebin)
	Wave W_rebin, W_rebinSD

	SetDataFolder dfSav
	// Return a reference to the free data folder containing M_ImagePlane
	return dfFree	
End

//Function Pla_intRebin2(x_init, y_init, s_init, x_rebin)
//	Wave x_init, y_init, s_init,x_rebin
//	//Rebins histogrammed data into boundaries set by x_rebin.
//	//makes the waves W_rebin and W_RebinSD.
//
//	//it uses linear interpolation to work out the proportions of which original cells should be placed
//	//in the new bin boundaries.
//
//	// Precision will normally be lost.  
//	// It does not make sense to rebin to smaller bin boundaries.
//	
//	//when we calculate the standard deviation on the intensity carry the variance through the calculation
//	//and convert to SD at the end.
//	variable ii = 0, pnts_init, pnts_final	
//	pnts_init = dimsize(x_init, 0) - 1
//	pnts_final = dimsize(x_rebin, 0) - 1
//	make/free/d/n=(pnts_init) var_init = s_init^2, y_temp, var_temp, mask
//
//	make/n=(pnts_final)/d/o W_rebin, W_rebinSD
//	W_rebin = 0
//	W_rebinSD = 0
//	
//	make/free/d/n=(pnts_init, pnts_final) y_temp, var_temp, mask
//	y_temp[][] = y_init[p]
//	var_temp[][] = var_init[p]
//	mask = 0
//	
//	make/n=(pnts_final)/free/d p_lo, p_hi, p_hiI, p_loI
//	p_lo = binarysearchinterp(x_init, x_rebin[p])
//	p_hi = binarysearchinterp(x_init, x_rebin[p + 1])
//	p_loI = binarysearch(x_init, x_rebin[p])
//	p_hiI = binarysearch(x_init, x_rebin[p + 1])
//	
//	
//	for(ii = 0 ; ii < pnts_final; ii += 1)		
//		// new bin out of x_init range
//		if(p_hiI[ii] == -1 || p_loI[ii] == -2)
//			mask[][ii] = 0
//			continue
//		endif
//		// new bin totally covers x_init range
//		if(p_loI[ii] == -1 && p_hiI[ii] == -2)
//			mask[][ii] = 1
//			continue
//		endif
//		// new bin overlaps lower boundary
//		if(p_loI[ii] == -1)
//			p_lo[ii] = 0
//			p_loI[ii] = 0
//		endif
//		// new bin overlaps upper boundary
//		if(p_hiI[ii] == -2 || p_hiI[ii] == pnts_init)
//			p_hi[ii] = pnts_init
//			p_hiI[ii] = p_hi[ii] - 1
//		endif
//		
//		mask[][ii] = (p >= ceil(p_lo[ii]) && p < floor(p_hi[ii])) ? 1 : 0
//		if(p_loI[ii] == p_hiI[ii])
//			mask[p_loI[ii]][ii] = p_hi[ii] - p_lo[ii]
//		else
//			mask[p_loI[ii]][ii] = 1 - (p_lo[ii] - p_loI[ii])
//			mask[p_hiI[ii]][ii] = p_hi[ii] - p_hiI[ii]	
//		endif
//	endfor
//
//	matrixop/free/o/nthr=0 outp = sumcols(y_temp * mask)
//	W_rebin = outp
//	matrixop/free/o/nthr=0 outp = sumcols(var_temp * mask * mask)
//	W_rebinSD = outp
//
//	W_rebinSD = sqrt(W_rebinSD)
//End	

Threadsafe Function Pla_intRebin(x_init, y_init, s_init, x_rebin)
	Wave x_init, y_init, s_init,x_rebin
	//Rebins histogrammed data into boundaries set by x_rebin.
	//makes the waves W_rebin and W_RebinSD.

	//it uses linear interpolation to work out the proportions of which original cells should be placed
	//in the new bin boundaries.

	// Precision will normally be lost.  
	// It does not make sense to rebin to smaller bin boundaries.
	
	//when we calculate the standard deviation on the intensity carry the variance through the calculation
	//and convert to SD at the end.
	variable ii = 0, frac, frac2
	make/free/d/n=(dimsize(x_rebin, 0)) pos, posI
	make/free/d/n=(dimsize(s_init, 0)) var_init = s_init^2
	
	pos = binarysearchinterp(x_init, x_rebin)
	posI = binarysearch(x_init, x_rebin)
	for(ii = 0 ; ii < dimsize(pos, 0); ii+=1)
		if(posI[ii] == -1)
			posI[ii] = 0
			pos[ii] = 0
		endif
	endfor

	for(ii = 0 ; ii < dimsize(pos, 0); ii+=1)
		if(posI[ii] == -2)
			posI[ii] = dimsize(x_init, 0) - 1
			pos[ii] = dimsize(x_init, 0) - 1
		endif
	endfor
	make/d/n=(dimsize(y_init, 0))/free cumsum, cumsumVar
	cumsum = sum(y_init, 0, p)
	cumsumVar = sum(var_init, 0, p)

	insertpoints 0, 1, cumsum, cumsumVar

	make/n=(dimsize(x_rebin, 0) - 1)/d/o W_rebin, W_rebinSD
	W_rebin = 0
	W_rebinSD = 0

	W_rebin[] = cumsum[pos[p + 1]] - cumsum[pos[p]] 

	for (ii = 0 ; ii < dimsize(x_rebin, 0) - 1 ; ii += 1)
		//now add on fractional bits
		//fractional parts in same bin
		if(floor(pos[ii]) == floor(pos[ii + 1]))
			frac = pos[ii + 1] - pos[ii]
			W_rebinSD[ii] += frac^2 * (cumsumVar[ceil(pos[ii + 1])] - cumsumVar[floor(pos[ii])])
		//fractional parts in different bins
		else
			W_rebinSD[ii] += cumsumVar[floor(pos[ii + 1])] - cumsumVar[ceil(pos[ii])]
			frac = ceil(pos[ii]) - pos[ii]
			frac2 = pos[ii + 1] - floor(pos[ii + 1])
			
			W_rebinSD[ii] += frac^2 * (cumsumVar[ceil(pos[ii])] - cumsumVar[floor(pos[ii])])
			W_rebinSD[ii] += frac2^2 * (cumsumVar[ceil(pos[ii + 1])] - cumsumVar[floor(pos[ii + 1])])
		endif
	endfor

	W_rebinSD = sqrt(W_rebinSD)
End	

Function test_Pla_intRebin()
	variable timer = startmstimer
	//basic test
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {-0.2, 0.8, 1.5, 2.5, 3.5, 8}
	make/n=5/d/free result, resultSD
	c = sqrt(b)
	result = {1.6, 1.9, 3.5, 4.5, 11.5}
	resultSD = {1.131370849898, 0.9110433579144, 1.322875655532, 1.5, 3.201562118716}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail0 - test_pla_intRebin"
		abort
	endif
	
	//test that unaltered bins give same result
	duplicate/free/o a, d
	Pla_intrebin(a,b,c,d)
	if(EqualWaves(W_rebin, b, 1) != 1 || EqualWaves(W_rebinSD, c, 1) != 1)
		print  "Fail1 - test_pla_intRebin"
		abort
	endif
	
	// first bin is outside the range
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {-1.0, -0.2, 0.8, 1.5, 2.5, 3.5, 8}
	make/n=(numpnts(d) - 1)/d/free result, resultSD
	c = sqrt(b)
	result = {0, 1.6, 1.9, 3.5, 4.5, 11.5}
	resultSD = {0, 1.131370849898, 0.9110433579144, 1.322875655532, 1.5, 3.201562118716}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail2 - test_pla_intRebin"
		abort
	endif
	
	// last bin is outside the range
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {-0.2, 0.8, 1.5, 2.5, 3.5, 8, 10}
	make/n=(numpnts(d) - 1)/d/free result, resultSD
	c = sqrt(b)
	result = {1.6, 1.9, 3.5, 4.5, 11.5, 0}
	resultSD = {1.131370849898, 0.9110433579144, 1.322875655532, 1.5, 3.201562118716, 0}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail2.1 - test_pla_intRebin"
		abort
	endif
	
	// rebinning encompasses the entire range
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {-1.0, 8}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {23}
	resultSD = {4.79583}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail3 - test_pla_intRebin"
		abort
	endif

	// test4
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {-1.0, 5.1, 8}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {19.25, 3.75}
	resultSD = {4.360690886, 1.875}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail4 - test_pla_intRebin"
		abort
	endif

	// test5
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {0.2, 1.1, 8}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {1.9, 20.7}
	resultSD = {1.144552314, 4.519955752}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail5 - test_pla_intRebin"
		abort
	endif

	// test6
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {0.2, 1.1, 8}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {1.9, 20.7}
	resultSD = {1.144552314, 4.519955752}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail6 - test_pla_intRebin"
		abort
	endif
	
	// test7
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {0.2, 1.1, 6.6}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {1.9, 20.7}
	resultSD = {1.144552314, 4.519955752}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail7 - test_pla_intRebin"
		abort
	endif
	
	// test8
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {0.2, 1.1, 6.5}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {1.9, 20.45}
	resultSD = {1.144552314, 4.466052508}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail8 - test_pla_intRebin"
		abort
	endif
		
	// test9
	make/d/free a = {0,1,2,3,4,5,6.6}
	make/d/free b = {2,3,4,5,5,4}
	make/d/free/n=6 c
	make/d/free d = {6.4, 6.5}
	make/n=(numpnts(d))/d/free result, resultSD
	c = sqrt(b)
	result = {.25}
	resultSD = {0.125}

	Pla_intRebin(a,b,c,d)
	Wave W_rebin, W_rebinSD	
	if(EqualWaves(W_rebin, result, 1) != 1 || EqualWaves(W_rebinSD, resultSD, 1) != 1)
		print "Fail9 - test_pla_intRebin"
		abort
	endif
	print "Pass - test_pla_intRebin", stopmstimer(timer)
End

Function Pla_histogram(W_bins, W_q, W_R, W_Rsd)
	Wave W_bins, W_q, W_R, W_Rsd

	variable ii, whichBin
	make/o/d/n=(numpnts(W_bins)-1) W_signal, W_signalSD, W_binfiller
	W_signal = 0
	W_signalSD = 0
	W_binfiller = 0
	for(ii=0 ; ii<numpnts(W_R) ; ii+=1)
		whichbin = binarysearch(W_bins,W_q[ii])
		if(whichbin<0)
			continue
		endif
		if(numtype(W_R[ii]))
			print "break at ",ii
		endif
		W_binfiller[whichbin]+=1
		
		W_signal[whichbin] += W_R[ii]
		W_signalSD[whichbin] += (W_Rsd[ii])^2
	endfor

	W_signalSD = sqrt(W_signalSD)
End

Function Pla_avghistogrambin(origbin)
	Wave origbin
	make/o/d/n=(numpnts(origbin)-1) W_avg
	W_avg[] = 0.5*(origbin[p]+origbin[p+1])
End

Function Pla_unavghistogrambin(histobin,offset)
	Wave histobin
	variable offset

	variable ii
	make/o/d/n=(numpnts(histobin)+1) W_unavg
	W_unavg[0] = histobin[0] - offset
	for(ii=1 ; ii<numpnts(W_unavg) ; ii+=1)
		W_unavg[ii] = 2*histobin[ii-1] - W_unavg[ii-1]
	endfor

End

Threadsafe Function checkSorted(aWave)
	Wave aWave
	variable ii
	for(ii=dimsize(awave,0)-1 ; ii>= 1 ; ii-=1)
		if(awave[ii] < awave[ii-1])
			return 1
		endif
	endfor
	return 0
End


Function Pla_rebin_afterwards(qq,rr, dr, dq, rebin, lowerQ,upperQ)
Wave qq,rr,dr,dq
variable rebin, lowerQ, upperQ
//this function rebins a set of R vs Q data given a rebin percentage.
//it is designed to replace rebinning the wavelength spectrum which can result in twice as many points in the overlap region.
//However, the background subtraction is currently done on rebinned data. So if you don't rebin at the start the  subtraction
//isn't as good.
	variable stepsize, numsteps, ii, binnum, weight

	rebin =  1 + (rebin/100)
	stepsize = log(rebin)
	numsteps = log(upperQ / lowerQ) / stepsize

	make/n=(numsteps + 1)/o/d W_q_rebin, W_R_rebin, W_E_rebin, W_dq_rebin
	W_q_rebin = 0
	W_R_rebin = 0
	W_E_rebin = 0
	W_dq_rebin = 0

	make/n=(numsteps + 2)/free/d W_q_rebinHIST
	make/n=(numsteps + 1)/d/free Q_sw, I_sw, E_sw

	W_q_rebinHIST[] = alog( log(lowerQ) + (p-0.5) * stepsize)

	for(ii = 0 ; ii < numpnts(qq) ; ii += 1)
		binnum = binarysearch(W_q_rebinHIST, qq[ii])
		if(binnum < 0)
			continue
		endif
		 weight = 1 / (dR[ii]^2)
		 if(numtype(weight))		//it's possible for dR to be 0.  If this is the case then R[binnum] is going to be INF. Let's prevent this from happening.
		 	continue
		 endif
		W_R_rebin[binnum] += RR[ii] * weight
		W_q_rebin[binnum] += qq[ii] * weight
		W_dq_rebin[binnum] += dq[ii] * weight
		Q_sw[binnum] += weight
		I_sw[binnum] += weight
	endfor
	W_R_rebin[] /= I_sw[p]
	W_q_rebin[] /= Q_sw[p]
	W_E_rebin[] = sqrt(1/I_sw[p])
	W_dq_rebin[] /= Q_sw[p]
	
	for(ii = numpnts(W_q_rebin) - 1 ; ii >= 0 ; ii -= 1)

		if(numtype(W_q_Rebin[ii]))

			deletepoints ii, 1, W_q_rebin, W_R_rebin, W_E_rebin, W_dq_rebin

		endif

	endfor



End
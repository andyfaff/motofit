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
	variable ii = 0
	make/free/d/n=(dimsize(x_rebin, 0)) pos
	make/free/d/n=(dimsize(s_init, 0)) var_init = s_init^2
	
	pos = binarysearchinterp(x_init, x_rebin)
	for(ii = 0 ; ii < dimsize(pos, 0) && numtype(pos[ii]); ii+=1)
			pos[ii] = 0
	endfor
	
	for(ii = dimsize(pos, 0) - 1; ii >=0 && numtype(pos[ii]); ii -=1)
			pos[ii] = dimsize(x_init, 0) - 1
	endfor
	
	make/d/n=(dimsize(y_init, 0))/free cumsum, cumsumVar
	cumsum = sum(y_init, 0, p)
	cumsumVar = sum(var_init, 0, p)
	
	insertpoints 0, 1, cumsum, cumsumVar

	make/n=(dimsize(x_rebin, 0) - 1)/d/o W_rebin, W_rebinSD
	W_rebin = 0
	W_rebinSD = 0
	
	W_rebin[] = cumsum[pos[p + 1]] - cumsum[pos[p]] 
	//TODO, get rid of abs....
	W_rebinSD[] = abs((cumsumVar[pos[p+1]] - cumsumVar[pos[p]]))
	
	duplicate/free pos, celloc
	celloc= ceil(pos[p]) - 1 < 0 ? 0 : ceil(pos[p]) - 1

	W_rebinSD[] -=  (ceil(pos[p+1])-pos[p+1]) * s_init[celloc[p+1]]^2 * (1-ceil(pos[p+1])+pos[p+1])
	W_rebinSD[] -=  (ceil(pos[p])-pos[p]) * s_init[celloc[p]]^2 * (1-ceil(pos[p])+pos[p])
	W_rebinSD = sqrt(W_rebinSD)
End	

//Threadsafe Function Pla_rb(x_init, y_init, s_init, x_rebin)
//	Wave x_init, y_init, s_init,x_rebin
//
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
//			
//	
//	if(wavedims(X_init)!=1 || wavedims(y_init)!=1 || wavedims(s_init)!=1 || wavedims(X_rebin)!=1)
//		print "All supplied waves must be 1D (Pla_intrebin)"	
//		return 1
//	endif
//	
//	if(numpnts(X_init)-1!= numpnts(y_init) || numpnts(y_init)!=numpnts(s_init))
//		print "y_init and s_init must have one less point than x_init (Pla_intRebin)"
//		return 1
//	endif
//
//	
//	make/o/d/n =(numpnts(x_rebin)-1) W_rebin=0,W_RebinSD=0
//	
//	variable ii=0, kk = 0
//	variable lowlim,upperlim, lowcelloc, uppercelloc
//	
//	for(ii=0; ii< numpnts(x_rebin)-1 ; ii+=1)
//		//this gives the approximate position of where the new bin would start in the old bin		
//		lowlim = binarysearchinterp(x_init,x_rebin[ii])
//		upperlim = binarysearchinterp(x_init,x_rebin[ii+1])	
//		
//		//if your rebin x boundaries are set outisde those of the initial data then you won't get any counts.
//		if(numtype(lowlim) && numtype(upperlim))
//			W_rebin[ii] = 0
//			W_RebinSD[ii] = 0
//			continue
//		endif
//		
//		//lower limit for your rebinned data may be outside the original histogram boundary
//		//set it to the lowest point in this case
//		if(numtype(lowlim))
//			lowlim = 0
//		endif
//
//		//upperlimit has escaped, so set to the highest from the original data.		
//		if(numtype(upperlim))
//			upperlim = numpnts(x_init) - 1
//		endif
//		
//		lowcelloc = trunc(lowlim)
//		uppercelloc = trunc(upperlim)
//		if(lowcelloc > numpnts(y_init) -1 )
//			lowcelloc = numpnts(y_init) -1
//		endif
//		if(uppercelloc > numpnts(y_init) -1)
//			uppercelloc = numpnts(y_init) -1
//		endif
//		
//		//now need to add the counts together
//		
//		//both upperlimit and lower limit rebin boundaries aren't the same unbinned cell
//		//need to take a proportion of a lower and upper cell 
//		if(lowcelloc != uppercelloc)
//			W_rebin[ii]  =  y_init[lowcelloc]*(ceil(lowlim) - lowlim)
//			W_rebin[ii] += y_init[uppercelloc]*(upperlim - trunc(upperlim))
//			
//			W_RebinSD[ii]  = (s_init[lowcelloc]*(ceil(lowlim) - lowlim))^2
//			W_RebinSD[ii] += (s_init[uppercelloc]*(upperlim - trunc(upperlim)))^2
//		else
//			//the upper and lower limits are in the same binned cell.  Need to work out
//			//what proportion of the original cell is occupied by the difference between the limits
//			W_rebin[ii] =	y_init[lowcelloc] * (upperlim - lowlim)
//			W_RebinSD[ii] =	(s_init[lowcelloc]*(upperlim - lowlim))^2
//		endif
//		
//		//if the upper and lower limits span several of the original data, then you need to add counts 
//		//from each individual cell.
//		if((ceil(lowlim) < trunc(upperlim)) && (trunc(upperlim) - ceil(lowlim) >= 1))
//			for(kk = 0 ; kk < trunc(upperlim) - ceil(lowlim) ;kk += 1)
//				W_rebin[ii] += y_init[ceil(lowlim) + kk]
//				W_RebinSD[ii] += (s_init[ceil(lowlim) + kk])^2
//			endfor
//		endif
//				
//	endfor
//	W_RebinSD = sqrt(W_RebinSD)
//End


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
#pragma rtGlobals=1		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

Function Pla_2DintRebin(x_init,data,dataSD,x_rebin)
	Wave x_init,data,dataSD,x_rebin

	//Rebins 2D histogrammed data into boundaries set by xy_rebin.
	//makes the waves M_rebin and M_RebinSD.

	//it uses linear interpolation to work out the proportions of which original cells should be placed
	//in the new bin boundaries.

	// Precision will normally be lost.  
	// It does not make sense to rebin to smaller bin boundaries.

	variable ii,jj
	make/o/d/n=(numpnts(x_rebin)-1,dimsize(data,1)) M_rebin,M_rebinSD

	if(checkSorted(x_rebin) || checkSorted(x_init))
		print "The x_rebin and x_init must be monotonically increasing (Pla_2DintRebin)"
		return 1
	endif
	
	if(wavedims(x_init)!=1 || wavedims(data)!=2 || wavedims(dataSD)!=2 || wavedims(x_rebin)!=1)
		print "One of the wave dimensions is wrong (Pla_intrebin)"	
		return 1
	endif
	
	if(numpnts(x_init)-1!= dimsize(data,0) || numpnts(data)!=numpnts(dataSD))
		print "data and dataSD must have one less point in the y-direction than y_init (Pla_intRebin)"
		return 1
	endif

	for(ii = 0 ; ii<dimsize(data,1) ; ii+=1)
		imagetransform/g=(ii) getcol data
		duplicate/o W_extractedcol tempCol
		imagetransform/g=(ii) getcol dataSD
		duplicate/o W_extractedcol tempColSD
		Pla_intRebin(x_init,tempCol,tempColSD,x_rebin)
		Wave W_rebin,W_rebinSD
		imagetransform/D=W_rebin/G=(ii) putcol M_rebin
		imagetransform/D=W_rebinSD/G=(ii) putcol M_rebinSD
	endfor
	
	killwaves/z tempcol,W_extractedcol,W_rebin,W_rebinSD, tempcolSD
end

Function Pla_intRebin(x_init, y_init,s_init, x_rebin)
	Wave x_init, y_init, s_init,x_rebin

	//Rebins histogrammed data into boundaries set by x_rebin.
	//makes the waves W_rebin and W_RebinSD.

	//it uses linear interpolation to work out the proportions of which original cells should be placed
	//in the new bin boundaries.

	// Precision will normally be lost.  
	// It does not make sense to rebin to smaller bin boundaries.
	
	if(checkSorted(x_rebin) || checkSorted(x_init))
		print "The x_rebin and x_init must be monotonically increasing (Pla_intRebin)"
		return 1
	endif
	
	if(wavedims(X_init)!=1 || wavedims(y_init)!=1 || wavedims(s_init)!=1 || wavedims(X_rebin)!=1)
		print "All supplied waves must be 1D (Pla_intrebin)"	
		return 1
	endif
	
	if(numpnts(X_init)-1!= numpnts(y_init) || numpnts(y_init)!=numpnts(s_init))
		print "y_init and s_init must have one less point than x_init (Pla_intRebin)"
		return 1
	endif

	
	make/o/d/n =(numpnts(x_rebin)-1) W_rebin=0,W_RebinSD=0
	
	variable ii=0, kk = 0
	variable lowlim,upperlim
	
	for(ii=0; ii< numpnts(x_rebin)-1 ; ii+=1)

		//this gives the approximate position of where the new bin would start in the old bin		
		lowlim = binarysearchinterp(x_init,x_rebin[ii])
		upperlim = binarysearchinterp(x_init,x_rebin[ii+1])	
		
		//if your rebin x boundaries are set outisde those of the initial data then you won't get any counts.
		if(numtype(lowlim) && numtype(upperlim))
			W_rebin[ii] = 0
			W_RebinSD[ii] = 0
			continue
		endif
		
		//lower limit for your rebinned data may be outside the original histogram boundary
		//set it to the lowest point in this case
		if(numtype(lowlim) && numtype(upperlim) == 0)
			lowlim = 0
		endif
		
		//lower limit for rebinned boundary is in the original boundaries
		//but upperlimit has escaped, so set to the highest from the original data.
		if(numtype(lowlim)==0 && numtype(upperlim) )
			upperlim = numpnts(x_init)-1
		endif
		
		//now need to add the counts together
		
		//both upperlimit and lower limit rebin boundaries aren't the same unbinned cell
		//need to take a proportion of a lower and upper cell 
		if(trunc(lowlim) != trunc(upperlim))
			W_rebin[ii]  =  y_init[trunc(lowlim)]*(ceil(lowlim) - lowlim)
			W_rebin[ii] += y_init[trunc(upperlim)]*(upperlim - trunc(upperlim))
			
			W_RebinSD[ii]  = (s_init[trunc(lowlim)]*(ceil(lowlim) - lowlim))^2
			W_RebinSD[ii] += (s_init[trunc(upperlim)]*(upperlim - trunc(upperlim)))^2
			W_RebinSD[ii] = sqrt(W_RebinSD[ii])
		else
			//the upper and lower limits are in the same binned cell.  Need to work out
			//what proportion of the original cell is occupied by the difference between the limits
			W_rebin[ii] =	y_init[trunc(lowlim)]*(upperlim-lowlim)
			W_RebinSD[ii] =	s_init[trunc(lowlim)]*(upperlim-lowlim)
		endif
		
		//if the upper and lower limits span several of the original data, then you need to add counts 
		//from each individual cell.
		if((ceil(lowlim) < trunc(upperlim)) && (trunc(upperlim) - ceil(lowlim) >= 1))
			for(kk = 0 ; kk < trunc(upperlim) - ceil(lowlim) ;kk += 1)
				W_rebin[ii] += y_init[ceil(lowlim) + kk]
				W_RebinSD[ii] += (s_init[ceil(lowlim) + kk])^2
			endfor
			W_RebinSD[ii] = sqrt(W_RebinSD[ii])
		endif
	endfor
	
	return 0
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

Function checkSorted(aWave)
	Wave aWave
	variable ii
	for(ii=dimsize(awave,0)-1 ; ii>= 0 ; ii-=1)
		if(awave[ii] < awave[ii-1])
			return 1
		endif
	endfor
	return 0
End
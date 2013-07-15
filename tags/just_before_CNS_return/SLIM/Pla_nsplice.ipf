#pragma rtGlobals=3		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

Function Pla_GetScalingInOverlap(wave1q,wave1R,wave2q,wave2R)
	Wave wave1q,wave1R,wave2q,wave2R		//1 = first dataset, 2= second dataset
	
	variable num2, ii, npnts1, npnts2
	
	sort wave1q,wave1q,wave1R
	sort wave2q,wave2q,wave2R
	
	npnts1 = dimsize(wave1q, 0)
	npnts2 = dimsize(wave2q, 0)
	
	if(wave2q[0] > wave1q[npnts1 - 1])
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return NaN
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
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return NaN
	endif	
		
	Variable ival1,newi,ratio,numNaN, qval2
	ratio=0
	ii=0
	numNaN=0
	
	for(ii=0 ; ii < num2 ; ii+=1)
		//get scaling factor at each point of wave 2 in the overlap region
		qval2 = wave2q[overlapPoints[ii]]
		newi = interp(qval2, wave1q, wave1R)		//get the intensity of wave1 at an overlap point
	
		if(!numtype(wave2R[ii]) && !numtype(newi) && wave2R[ii] != 0)
			ratio += newi / wave2R[ii]					//get the scale factor
		else
			numNaN += 1
		endif
	endfor
	
	variable normal = ratio/(num2 - numNaN)		// +1 counts for point zero
	if(numtype(normal))
		print "ERROR while splicing (GetScalinginOverlap)"
	endif

	Return normal
End


Function/c Pla_GetWeightedScalingInOverlap(wave1q,wave1R, wave1dR, wave2q, wave2R, wave2dR)
	Wave wave1q,wave1R, wave1dR, wave2q,wave2R, wave2dR	//1 = first dataset, 2= second dataset

	variable ii, npnts1, npnts2, num2
	
	sort wave1q,wave1q,wave1R,wave1dR
	sort wave2q,wave2q,wave2R,wave2dR
	
	duplicate/free wave1q, wave1qtemp
	duplicate/free wave1R, wave1Rtemp
	duplicate/free wave1dR, wave1dRtemp
	duplicate/free wave2q, wave2qtemp
	duplicate/free wave2R, wave2Rtemp
	duplicate/free wave2dR, wave2dRtemp
	
	npnts1 = dimsize(wave1q, 0)
	npnts2 = dimsize(wave2q, 0)
	
	for(ii = npnts1 - 1 ; ii >= 0 ; ii-=1)
		if(wave1Rtemp[ii] == 0 || wave1dRtemp[ii] == 0 || numtype(wave1Rtemp[ii]) || numtype(wave1dRtemp[ii]))
			deletepoints ii, 1, wave1qtemp, wave1Rtemp, wave1dRtemp
		endif
	endfor
	
	for(ii = npnts2 - 1 ; ii >= 0 ; ii-=1)
		if(wave2Rtemp[ii] == 0 || wave2dRtemp[ii] == 0 || numtype(wave2Rtemp[ii]) || numtype(wave2dRtemp[ii]))
			deletepoints ii, 1, wave2qtemp, wave2Rtemp, wave2dRtemp
		endif
	endfor
	
	npnts1 = dimsize(wave1qtemp, 0)
	npnts2 = dimsize(wave2qtemp, 0)
	
	if(wave2qtemp[0] > wave1qtemp[npnts1 - 1])
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return cmplx(NaN, NaN)
	endif
	
	make/u/I/free/n=0 overlapPoints
	
	for(ii = 0 ;  ii < dimsize(wave2qtemp, 0) && wave2qtemp[ii] < wave1qtemp[npnts1 - 1] ; ii+=1)
		if(wave2qtemp[ii] > wave1qtemp[0] && wave2qtemp[ii] < wave1qtemp[npnts1 - 1])
			redimension/n=(numpnts(overlapPoints) + 1) overlapPoints
			overlapPoints[numpnts(overlapPoints) - 1] = ii
		endif
	endfor
	
	num2 = numpnts(overlapPoints)
	if(!num2)
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return cmplx(NaN, NaN)
	endif	
	
	Variable ival1, newi, newdi, ratio, dratio, qval2
	make/n=(num2)/d/free W_scalefactor, W_dScalefactor
		
	for(ii = 0 ; ii < num2 ; ii += 1)
		//get scaling factor at each point of wave 2 in the overlap region
		qval2 = wave2qtemp[overlapPoints[ii]]
		newi = interp(qval2, wave1qtemp, wave1Rtemp)		//get the intensity of wave1 at an overlap point
		newdi = interp(qval2, wave1qtemp, wave1dRtemp)
		
		if(!numtype(wave2Rtemp[ii]) && !numtype(newi) && !numtype(newdi))
			W_scalefactor[ii] = newi/wave2Rtemp[ii]
			W_dScalefactor[ii] = sqrt((newdi/wave2Rtemp[ii])^2 + ((newi * wave2drtemp[ii])^2)/wave2Rtemp[ii]^4)
		endif
	endfor
	
	W_dScalefactor = 1/(W_dScalefactor^2)
	
	variable normal, num = 0, den=0, dnormal
	for(ii=0 ; ii < num2 ; ii += 1)
		if(!numtype(W_scalefactor[ii]) && W_scalefactor[ii] && W_dscalefactor[ii] && !numtype(W_dscalefactor[ii]))
			num += W_scalefactor[ii] * W_dscalefactor[ii] 
			den += W_dscalefactor[ii]
		endif
	endfor
	
//	duplicate/o W_scalefactor, root:W_scalefactor
//	duplicate/o W_dscalefactor, root:W_dscalefactor
	
	normal = num/den
	dnormal = sqrt(1/den)
//	print normal, dnormal
	if(numtype(normal))
		print "ERROR while splicing (GetScalinginOverlap)"
	endif
	Return cmplx(normal, dnormal)
End

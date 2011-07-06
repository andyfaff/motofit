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


Function/c Pla_GetWeightedScalingInOverlap(wave1q,wave1R, wave1dR, wave2q,wave2R, wave2dR)
	Wave wave1q,wave1R, wave1dR, wave2q,wave2R, wave2dR	//1 = first dataset, 2= second dataset

	variable ii, npnts1, npnts2, num2
	
	sort wave1q,wave1q,wave1R,wave1dR
	sort wave2q,wave2q,wave2R,wave2dR
	
	npnts1 = dimsize(wave1q, 0)
	npnts2 = dimsize(wave2q, 0)
	
	if(wave2q[0] > wave1q[npnts1 - 1])
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return cmplx(NaN, NaN)
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
		return cmplx(NaN, NaN)
	endif	
	
	Variable ival1, newi, newdi, ratio, dratio, qval2
	make/n=(num2)/d/free W_scalefactor, W_dScalefactor
		
	for(ii = 0 ; ii < num2 ; ii += 1)
		//get scaling factor at each point of wave 2 in the overlap region
		qval2 = wave2q[overlapPoints[ii]]
		newi = interp(qval2, wave1q, wave1R)		//get the intensity of wave1 at an overlap point
		newdi = interp(qval2, wave1q, wave1dR)
		
		if(!numtype(wave2R[ii]) && !numtype(newi) && !numtype(newdi) && wave2R[ii] != 0)
			W_scalefactor[ii] = newi/wave2R[ii]
			W_dScalefactor[ii] = W_scalefactor[ii]* sqrt((newdi/newi)^2 + (wave2dr[ii]/wave2r[ii])^2)
		endif
	endfor
	
	W_dScalefactor = 1/(W_dScalefactor^2)
	
	variable normal, num = 0, den=0, dnormal
	for(ii=0 ; ii < num2 ; ii += 1)
		if(!numtype(W_scalefactor[ii]) && !numtype(W_dscalefactor[ii]))
			num += W_scalefactor[ii] * W_dscalefactor[ii] 
			den += W_dscalefactor[ii]
		endif
	endfor
	
	normal = num/den
	dnormal = sqrt(1/den)
	
	if(numtype(normal))
		print "ERROR while splicing (GetScalinginOverlap)"
	endif
	Return cmplx(normal, dnormal)
End

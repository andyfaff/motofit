#pragma rtGlobals=1		// Use modern global access method.

Function GetScalingInOverlap(wave1q,wave1R,wave2q,wave2R)
	Wave wave1q,wave1R,wave2q,wave2R		//1 = first dataset, 2= second dataset
	
	sort wave1q,wave1q,wave1R
	sort wave2q,wave2q,wave2R
	
	Variable num2		//largest point number of wave2 in overlap region
	FindLevel/P/Q wave2q,(wave1q[numpnts(wave1q)-1])
	num2 = trunc(V_levelx)
	
	if(numtype(num2) != 0)
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return NaN
	endif	
	
	Variable ii,ival1,newi,ratio,numNaN
	ratio=0
	ii=0
	numNaN=0
	
	for(ii=0 ; ii<num2 ; ii+=1)
		//get scaling factor at each point of wave 2 in the overlap region
		newi = interp(wave2q[ii],wave1q,wave1R)		//get the intensity of wave1 at an overlap point
	
		if(!numtype(wave2R[ii]) && !numtype(newi) && wave2R[ii] != 0)
			ratio += newi/wave2R[ii]					//get the scale factor
		else
			numNaN+=1
		endif
	endfor
	
	variable normal = ratio/(num2 - numNaN)		// +1 counts for point zero
	if(numtype(normal))
		print "ERROR while splicing (GetScalinginOverlap)"
	endif

	Return normal
End


Function/c GetWeightedScalingInOverlap(wave1q,wave1R, wave1dR, wave2q,wave2R, wave2dR)
	Wave wave1q,wave1R, wave1dR, wave2q,wave2R, wave2dR	//1 = first dataset, 2= second dataset
	
	sort wave1q,wave1q,wave1R,wave1dR
	sort wave2q,wave2q,wave2R,wave2dR
	
	Variable num2		//largest point number of wave2 in overlap region
	FindLevel/P/Q wave2q,(wave1q[numpnts(wave1q)-1])
	num2 = trunc(V_levelx)
	
	if(numtype(num2) != 0)
		print  "ERROR there are no data points in the overlap region. Either reduce the number of deleted points or use manual scaling."
		return NaN
	endif	
	
	Variable ii,ival1,newi, newdi, ratio, dratio
	make/n=(num2)/d/o W_scalefactor, W_dScalefactor
		
	for(ii=0 ; ii<num2 ; ii+=1)
		//get scaling factor at each point of wave 2 in the overlap region
		newi = interp(wave2q[ii],wave1q,wave1R)		//get the intensity of wave1 at an overlap point
		newdi = interp(wave2q[ii], wave1q, wave1dR)
		
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
	killwaves/z W_scalefactor, W_dscalefactor
	Return cmplx(normal,dnormal)
End
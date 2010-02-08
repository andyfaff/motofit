#pragma rtGlobals=1		// Use modern global access method.
Function modelWrapper(w,y,x):fitfunc
	Wave w,y,x
	make/n=(4*w[0]+6)/free/d forRef = w
	variable ii

	for(ii=0 ; ii <w[0] ; ii+=1)
		forRef[4*ii+6] = w[6]
		forRef[4*ii+7] = w[ii+9]
		forRef[4*ii+8] = 0
		if(ii)
			forRef[4*ii+9] = w[7]
		else
			forRef[4*ii+9] = w[8]
		endif
	endfor
	
//		for(ii=0 ; ii <w[0]-1 ; ii+=1)
//			forRef[4*ii+6] = w[6]
//			forRef[4*ii+7] = w[ii+12]
//			forRef[4*ii+8] = 0
//			if(ii)
//				forRef[4*ii+9] = w[7]
//			else
//				forRef[4*ii+9] = w[11]
//			endif
//		endfor
//		forRef[4*(w[0]-1)+6] = w[8]
//		forRef[4*(w[0]-1)+7] = w[9]
//		forRef[4*(w[0]-1)+8] = 0
//		forRef[4*(w[0]-1)+9] = w[10]



Abelesall(forRef,y,x)
y = log(y)
End


//gencurvefit /MINF=smoother/X=root:PAF1_q/K={100,20,0.7,0.5}/TOL=0.001/L=200 modelWrapper,root:PAF1_R,root:w,"1010011100000000000000000000000000000000000000000000000000",root:packages:motofit:gencurvefit:gen_limits
Function smoothier(coefs, y_obs, y_calc, s_obs)
	Wave coefs, y_obs, y_calc, s_obs
	make/n=(numpnts(y_obs))/free/d diff
	diff = ((y_obs-y_calc)/s_obs)^2
	
	variable ii, betaD=0
	for(ii=8 ; ii<coefs[0]-1 ; ii+=1)
		betaD += (coefs[ii]-coefs[ii+1])^2
	endfor
	if(coefs[0] > 0)
		betaD += (coefs[2]-coefs[8])^2
	endif
	if(coefs[0] > 1)
		betaD += (coefs[8-1+coefs[0]]-coefs[3])^2
	endif
	
	return sum(diff)* betaD
end
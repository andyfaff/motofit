#pragma rtGlobals=1		// Use modern global access method.
Function modelWrapper(w,y,x):fitfunc
	Wave w,y,x
	make/n=(4*w[0]+6)/o/d coef_forref = w
	variable ii

	for(ii=0 ; ii <w[0] ; ii+=1)
		coef_forref[4*ii+6] = w[6]
		coef_forref[4*ii+7] = w[ii+9]
		coef_forref[4*ii+8] = 0
		if(ii)
			coef_forref[4*ii+9] = w[7]
		else
			coef_forref[4*ii+9] = w[8]
		endif
	endfor
	
//		for(ii=0 ; ii <w[0]-1 ; ii+=1)
//			coef_forref[4*ii+6] = w[6]
//			coef_forref[4*ii+7] = w[ii+12]
//			coef_forref[4*ii+8] = 0
//			if(ii)
//				coef_forref[4*ii+9] = w[7]
//			else
//				coef_forref[4*ii+9] = w[11]
//			endif
//		endfor
//		coef_forref[4*(w[0]-1)+6] = w[8]
//		coef_forref[4*(w[0]-1)+7] = w[9]
//		coef_forref[4*(w[0]-1)+8] = 0
//		coef_forref[4*(w[0]-1)+9] = w[10]

//	for(ii=1 ; ii < w[0] ; ii+=1)
//			coef_forref[4*ii+6] = w[9]
//			coef_forref[4*ii+7] = w[ii - 1+12]
//			coef_forref[4*ii+8] = 0
//			if(ii==1)
//				coef_forref[4*ii+9] = w[10]
//			else
//				coef_forref[4*ii+9] = w[11]
//			endif
//	endfor
//	coef_forref[6] = w[6]
//	coef_forref[7] = w[7]
//	coef_forref[8] = 0
//	coef_forref[9] = w[8]


Motofit(coef_forref,y,x)
//y = log(y)
End


//gencurvefit /MINF=smoother/X=root:PAF1_q/K={100,20,0.7,0.5}/TOL=0.001/L=200 modelWrapper,root:PAF1_R,root:w,"1010011100000000000000000000000000000000000000000000000000",root:packages:motofit:gencurvefit:gen_limits
Function smoothier(coefs, y_obs, y_calc, s_obs)
	Wave/z coefs, y_obs, y_calc, s_obs

	make/n=(numpnts(y_obs))/free/d diff
	diff = ((y_obs-y_calc)/s_obs)^2
	
	variable ii, betaD=1
	for(ii=9 ; ii<9+coefs[0]-1 ; ii+=1)
		betaD +=sqrt(abs((coefs[ii]-coefs[ii+1])/(0.5*coefs[ii]+0.5*coefs[ii+1])))
	endfor
//	if(coefs[0] > 0)
//		betaD += (coefs[2]-coefs[9])^2
//	endif
//	if(coefs[0] > 1)
//		betaD += (coefs[9-1+coefs[0]]-coefs[3])^2
//	endif
	
	return sum(diff)* betaD
end
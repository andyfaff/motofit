#pragma rtGlobals=1		// Use modern global access method.
Function modelWrapper(w,y,x):fitfunc
	Wave w,y,x
	make/n=(4*w[0]+6)/o/d/free coef_forref = w
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

	//Motofit(coef_forref,y,x)

	Abelesall(coef_forref, y , x)
	y = log(y)
End

//gencurvefit /MINF=smoother/X=root:PAF1_q/K={100,20,0.7,0.5}/TOL=0.001/L=200 modelWrapper,root:PAF1_R,root:w,"1010011100000000000000000000000000000000000000000000000000",root:packages:motofit:gencurvefit:gen_limits
Function smoothier(coefs, y_obs, y_calc, s_obs)
	Wave/z coefs, y_obs, y_calc, s_obs

	make/n=(numpnts(y_obs))/free/d diff
	diff = ((y_obs-y_calc)/s_obs)^2
	variable chi2
	variable ii, betaD = 0
	
	for(ii = 9 ; ii < dimsize(coefs, 0) - 2 ; ii += 1)
		if(coefs[0] > 1)
			betaD += (coefs[ii] - coefs[ii+1])^2
		endif
	endfor
	betaD += (coefs[2] - coefs[9])^2
	betaD += (coefs[3] - coefs[dimsize(coefs, 0) - 2])^2
	
	//assumes that the final parameter is the "lambda parameter" that controls the smoothing
	chi2 = sum(diff)
//	print chi2, betaD * coefs[dimsize(coefs, 0) - 1]
	
	return chi2 + betaD * coefs[dimsize(coefs, 0) - 1]
end

Function test(coefs, RR, qq, ee, holdstring)
	wave qq, RR, ee, coefs
	string holdstring

	GEN_setlimitsforGENcurvefit(coefs, holdstring, getdatafolder(1) )
	Wave/z limits =root:packages:motofit:old_genoptimise:GENcurvefitlimits
//	make/n=0/d/o concatenated_results
	variable ii
	for(ii = -9 ; ii < 20 ; ii+=1)
		coefs[dimsize(coefs, 0) -1] = 2 ^ ii
		gencurvefit /MINF=smoothier/X=qq/TEMP=1/STGY=9/K={2000,20,0.7,0.5}/TOL=0.001/L=200/W=EE/I=1 modelWrapper,RR,coefs, holdstring, limits
		concatenate {coefs}, concatenated_results
	endfor

End
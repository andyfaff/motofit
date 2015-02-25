#pragma rtGlobals=1		// Use modern global access method.
//chebyshevapproximator(wave0, fit_c_PLP0008682_R, root:data:c_PLP0008682:c_PLP0008682_q);moto_SLDplot(coef_forreflectivity, root:data:theoretical:SLD_theoretical_R)
//gencurvefit /X=$(dat + "q")/K={100,20,0.7,0.5}/HOLD=wave2/TOL=0.001/D=root:fit_c_PLP0008682_R/W=$(dat + "E")/I=1 Chebyshevapproximator, $(dat + "R"),root:wave0,"",root:wave1

//chebyshevapproximator(root:data:c_PLP0008698:Coef_c_PLP0008698_R, fit_c_PLP0008698_R, root:data:c_PLP0008698:c_PLP0008698_q);moto_SLDplot(coef_forreflectivity, root:data:c_PLP0008698:SLD_c_PLP0008698_R)
//chebyshevapproximator(root:data:c_PLP0008682:Coef_c_PLP0008682_R, fit_c_PLP0008682_R, root:data:c_PLP0008682:c_PLP0008682_q);moto_SLDplot(coef_forreflectivity, root:data:c_PLP0008682:SLD_c_PLP0008682_R)

//gencurvefit /X=:data:e361r:e361r_q/K={5000,10,0.7,0.5}/TOL=0.00001/HOLD=hold/D=root:res/W=:data:e361r:e361r_E/I=1/L=200 Chebyshevapproximator,:data:e361r:e361r_R,root:wave0,"",root:packages:motofit:gencurvefit:gen_limits

static constant NUMSTEPS = 40
constant lambda = 10

Function Chebyshevapproximator(w, yy, xx): fitfunc
	Wave w, yy, xx
	
	//w[0] - how many "initial slabs"
	//w[1] - scale factor
	//w[2] - SLD fronting
	//w[3] - SLD backing
	//w[4] - bkg
	//w[5] - roughness of last initial slab / start of chebyshev period
	//w[3 * (w[0] - 1) + 6] - thickness of initial slab
	//w[3 * (w[0] - 1) + 7] - SLD of initial slab
	//w[3 * (w[0] - 1) + 8] - roughness of initial slab
	//w[3 * w[0]+ 6] - total extent of chebyshev layer
	//w[3 * w[0]+ 6 + N] - SLD of chebyhev nodes
	
	createCoefs_ForReflectivity(w)
	Wave coef_forReflectivity
//	motofit(coef_forreflectivity, yy, xx)
	Abelesall(coef_forReflectivity, yy, xx)
	multithread yy = log(yy)
	
End

Function createCoefs_ForReflectivity(w)
	wave w
	
	variable MAX_LENGTH, ii
	
	//workout how many chebyshev nodes
	duplicate/free/r=[w[0] * 3 + 7, numpnts(w) - 1] w, chebvals
	variable NCHEBNODES = numpnts(chebvals)

	MAX_LENGTH = w[w[0] * 3 + 6]

	//make the wave to calculate the reflectivity
	make/d/o/n=6 coef_forReflectivity = w
	coef_forreflectivity[5] = 2
		
	//add in the number of layers that already exist and those for the chebyshev part
	redimension/d/n=(dimsize(coef_forreflectivity,0) + 4 * (w[0] + NUMSTEPS)) coef_forreflectivity
	for(ii = 0 ; ii < w[0] ; ii+=1)
		coef_forreflectivity[4 * ii + 6] = w[3 * ii + 6]
		coef_forreflectivity[4 * ii + 7] = w[3 * ii + 7]
		coef_forreflectivity[4 * ii + 8] = 0
		coef_forreflectivity[4 * ii + 9] = w[3 * ii + 8]
	endfor
	coef_forreflectivity[0] = w[0] + NUMSTEPS
	
	if(NCHEBNODES < 1)
		return 0
	endif
		
	//now add in the chebyshev
	Wave chebNodes = cheby_interp_nodes(NCHEBNODES)

	if(NCHEBNODES == 1)
		make/n=1/d/o W_coefs = mean(chebvals)
	else
		cheby_guess_params(NCHEBNODES - 1, chebvals, chebnodes)
		Wave W_coefs
	endif
	
	make/d/n=(NUMSTEPS)/free chebSLD, tempxx
	setscale/I x, 0, MAX_LENGTH, chebSLD
	tempxx[] = pnt2x(chebSLD, p)
	cheby_fit(W_coefs, chebSLD, tempxx)	
	
	for(ii = 0 ; ii < dimsize(chebSLD, 0); ii+=1)
		coef_forReflectivity[4 * (w[0] + ii) + 6] = MAX_LENGTH / NUMSTEPS
		coef_forReflectivity[4 * (w[0] + ii) + 7] = chebSLD[ii + 0.5]
		coef_forReflectivity[4 * (w[0] + ii) + 8] = 0
		if (!ii)
			coef_forReflectivity[4 * (w[0] + ii) + 9] = w[5]
		else
			coef_forReflectivity[4 * (w[0] + ii) + 9] = 0.2
		endif
	endfor

End



//Function smoother(coefs, y_obs, y_calc, s_obs)
//	Wave coefs, y_obs, y_calc, s_obs
//
//	variable retval, betas = 0, ii
//	
//	make/n=(numpnts(y_obs))/free/d diff
//	multithread diff = ((y_obs-y_calc)/s_obs)^2
//	retval = sum(diff)
//	
//	Wave coef_forreflectivity = createCoefs_ForReflectivity(coefs)
//	for(ii = 0 ; ii < coef_forreflectivity[0] + 1 ; ii+=1)
//		if(ii == 0)
//			betas += (coef_forreflectivity[2] - coef_forreflectivity[7])^2
//		elseif(ii == coef_forreflectivity[0])
//			betas += (coef_forreflectivity[3] - coef_forreflectivity[(4 * (ii - 1)) + 7])^2
//			if(abs(coef_forreflectivity[3] - coef_forreflectivity[(4 * (ii - 1)) + 7]) > 0.5)
//				retval *= 10
//			endif
//		else
//			betas += (coef_forreflectivity[4 * (ii-1) + 7] - coef_forreflectivity[4 * ii  + 7])^2
//		endif
//		if(coef_forreflectivity[4 * (ii-1) + 7] < -0.1) 
//			retval*=10
//		endif
//	endfor	
//
//	return retval + lambda * betas
//end

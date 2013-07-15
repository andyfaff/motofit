#pragma rtGlobals=3		// Use modern global access method.
Structure fitfuncStruct   
Wave w
wave y
wave x[50]
 
int16 numVarMD
wave ffsWaves[50]
wave ffsTextWaves[10]
variable ffsvar[5]
string ffsstr[5]
nvar ffsnvars[5]
svar ffssvars[5]
funcref allatoncefitfunction ffsfuncrefs[10]
uint32 ffsversion    // Structure version. 
EndStructure 

Function allatoncefitfunction(w,y,x)
	Wave w,y,x
End
 
 
Function kernelSmearedMotofit(s) : FitFunc
	Struct fitfuncStruct &s

	Wave w = s.w
	Wave yy =  s.y
	Wave xx =  s.x[0]
	Wave resolutionKernel = s.ffsWaves[0]
	
	variable qpoints, kernelpoints
	qpoints = dimsize(resolutionKernel, 0)
	kernelpoints = dimsize(resolutionKernel, 1)
	
	duplicate/free/r=[0, qpoints - 1][0, kernelPoints - 1][0, 0] resolutionKernel, ytemp, qtemp
	
	redimension/n=(qpoints * kernelPoints) ytemp, qtemp
	AbelesAll(w, ytemp, qtemp)
	redimension/n=(qpoints , kernelPoints) ytemp
	
	//multiply by the resolution kernel
	multithread ytemp[][] *= resolutionkernel[p][q][1]
	
	//now do simpson integration of the weighted intensities.
	//http://en.wikipedia.org/wiki/Simpson's_rule#Sample_implementation
	multithread yy[] = ytemp[p][0]
	multithread yy[] += ytemp[p][kernelPoints - 1]
	
	multithread ytemp[][] = (mod(q, 2) == 1) ? ytemp[p][q] * 4 : ytemp[p][q] * 2
	multithread ytemp[][0] = 0
	multithread ytemp[][kernelpoints - 1] = 0

	matrixop/NTHR=0/free summ = sumrows(ytemp)
	
	multithread yy[] += summ[p]
	multithread yy[] *= (resolutionKernel[p][1][0] - resolutionKernel[p][0][0]) / 3
//	yy = log(yy)
	yy *=xx^4
End

Function kernelSmearingHarness(w, yy, xx, resolutionKernel)
Wave w, yy, xx, resolutionKernel

Struct fitfuncStruct s

Wave s.w = w
Wave s.y = yy
Wave s.x[0] = xx
Wave s.ffsWaves[0] = resolutionKernel
kernelSmearedMotofit(s)
End

Function main()
	Wave coef_PLP0005568_R, PLP0005568_q, PLP0005568_R, PLP0005568_E, PLP0005568_dq
//	Wave coef_PLP0006029_R, PLP0006029_q, PLP0006029_R, PLP0006029_E, PLP0006029_dq, wave0
//	Wave coef_PLP0003213_R, PLP0003213_q, PLP0003213_R, PLP0003213_E, PLP0003213_dq, wave0
//	Wave coef_PLP0002079_R, PLP0002079_q, PLP0002079_R, PLP0002079_E, PLP0002079_dq, wave0
//	Wave coef_PLP0011714_R, PLP0011714_q, PLP0011714_R, PLP0011714_E, PLP0011714_dq, wave0
//Wave coef_PLP0000708_R, PLP0000708_q, PLP0000708_R, PLP0000708_E, PLP0000708_dq, wave0
		
	Wave Gencurvefitlimits
	Wave reducedKernel = reducedKernel
	// initialise the structure you will use
	struct fitfuncStruct s

	// we must set the version of the structure (currently 1000)
	s.ffsversion = 1000
	
	// numVarMD is the number of dependent variables you are fitting
	// this must be correct, or Gencurvefit won't run.
	s.numVarMD=1		

	Wave s.ffsWaves[0] = reducedkernel
	Wave s.w = coef_PLP0005568_R
	Wave s.y = PLP0005568_R
	Wave s.x[0] = PLP0005568_q
	Wave wave0
	Gencurvefit /W=PLP0005568_E/I=1/strc=s/TOL=0.005/K={2000,20,0.7,0.5}/X=PLP0005568_q kernelSmearedMotofit,PLP0005568_R,coef_PLP0005568_R,"10100000100010",Gencurvefitlimits

End

Function munge(coefs, y_obs, y_calc, s_obs)
	Wave coefs, y_obs, y_calc, s_obs
	make/n=(numpnts(y_obs))/free/d diff
	diff = ((y_obs-y_calc)/s_obs)^2
	return sum(diff)
end

Function reduceResolutionKernel(resolutionkernel, pts)
Wave resolutionkernel
variable pts

variable ii

make/n=(dimsize(resolutionkernel, 1))/free/d kernel, kernelx
make/n=(pts)/free/d interpo

make/n=(dimsize(resolutionkernel, 0), pts, 2)/o/d reducedKernel

for(ii = 0 ; ii < dimsize(resolutionkernel, 0) ; ii+=1)
kernel = resolutionkernel[ii][p][1]
kernelx = resolutionkernel[ii][p][0]
Interpolate2/T=2/N=(pts)/E=2/Y=interpo kernelx, kernel
reducedkernel[ii][][0] = pnt2x(interpo, q)
reducedkernel[ii][][1] = interpo[q]
endfor

End

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
	
	//resolution kernel has dimensions [qpoints][kernelpoints][2]
	//Each row in the first layer contains the 'x' points for the probability distribution.
	//The values in the second layer contains the corresponding probability for the PDF.
	//numpnts(xx) == dimsize(resolutionkernel, 0) == numpnts(yy)
	
	variable qpoints, kernelpoints
	qpoints = dimsize(resolutionKernel, 0)
	kernelpoints = dimsize(resolutionKernel, 1)
	
	duplicate/free/r=[0, qpoints - 1][0, kernelPoints - 1][0, 0] resolutionKernel, ytemp, qtemp
	
	redimension/n=(qpoints * kernelPoints) ytemp, qtemp
	Abeles_imagAll(w, ytemp, qtemp)
	redimension/n=(qpoints , kernelPoints) ytemp
	
	//multiply by the resolution kernel probability
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
//	yy *=xx^4
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

Function main(datasetname, [justsim])
	String datasetname
	variable justsim
	//a function to simplify doing a resolution kernel fit/simulation
	Wave rr = $(datasetname + "_R")
	Wave qq = $(datasetname + "_q")
	Wave dr = $(datasetname + "_E")
	Wave dq = $(datasetname + "_dq")
	Wave coefs = $("coef_" + datasetname + "_R")
			
	//you should already have specified the following waves in the current datafolder.
	Wave resolutionkernel
	
	// initialise the structure you will use
	struct fitfuncStruct s

	// we must set the version of the structure (currently 1000)
	s.ffsversion = 1000
	
	// numVarMD is the number of dependent variables you are fitting
	// this must be correct, or Gencurvefit won't run.
	s.numVarMD=1		

	Wave s.ffsWaves[0] = resolutionkernel
	Wave s.w = coefs
	Wave s.x[0] = qq

	make/d/o/n=(numpnts(rr)) $("fit_" + datasetname + "_R")
	Wave fit_RR = $("fit_" + datasetname + "_R")
	
	if(justsim)
		Wave s.y = fit_RR
		kernelSmearedMotofit(s)
	else
		Wave holdwave
		Wave Gencurvefitlimits
		Gencurvefit /D=fit_rr/L=(numpnts(rr))/W=dr/I=1/hold=holdwave/strc=s/TOL=0.05/K={2000,10,0.7,0.5}/DITH={0.7, 1.5}/X=qq kernelSmearedMotofit, rr, coefs,"",Gencurvefitlimits
	endif
End

Function munge(coefs, y_obs, y_calc, s_obs)
	Wave coefs, y_obs, y_calc, s_obs
	make/n=(numpnts(y_obs))/free/d diff
	diff = ((y_obs-y_calc)/s_obs)^2
	return sum(diff)
end

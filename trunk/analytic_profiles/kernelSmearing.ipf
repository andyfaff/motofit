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
	yy = log(yy)
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
	Wave coef_PLP0001125_R, PLP0001125_q, PLP0001125_R, PLP0001125__E, PLP0001125_dq
	Wave resolutionkernel, Gencurvefitlimits1
	
	// initialise the structure you will use
	struct fitfuncStruct s

	// we must set the version of the structure (currently 1000)
	s.ffsversion = 1000
	
	// numVarMD is the number of dependent variables you are fitting
	// this must be correct, or Gencurvefit won't run.
	s.numVarMD=1		

	Wave s.ffsWaves[0] = resolutionKernel
	Wave s.w = w
	Wave s.y = yy
	Wave s.x[0] = xx

	Gencurvefit /strc=s /X=PLP0001125_q kernelSmearedMotofit,PLP0001125_R,coef_PLP0001125_R,"10100100100000",Gencurvefitlimits1
End

Function reduceResolutionKernel(resolutionkernel, pts)
Wave resolutionkernel
variable pts

variable ii

make/n=(dimsize(resolutionkernel, 1))/free/d kernel, kernelx
make/n=(pts)/free/d interpo

make/n=(dimsize(resolutionkernel, 0), pts, 2)/o reducedKernel

for(ii = 0 ; ii < dimsize(resolutionkernel, 0) ; ii+=1)
kernel = resolutionkernel[ii][p][1]
kernelx = resolutionkernel[ii][p][0]
Interpolate2/T=2/N=(pts)/E=2/Y=interpo kernelx, kernel
reducedkernel[ii][][0] = pnt2x(interpo, q)
reducedkernel[ii][][1] = interpo[q]
endfor

End

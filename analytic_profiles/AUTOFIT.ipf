#pragma rtGlobals=1		// Use modern global access method.
Function autofit(yw, xw, ew, fresnelInfo, maxLength, minSLD, maxSLD, lambdavals)
	Wave yw, xw, ew, fresnelInfo
	variable maxLength, minSLD, maxSLD
	Wave lambdavals

	variable numNodes, maxQ, ii

	Wavestats/q/z xw
	numnodes = ceil( (V_max * maxLength) /Pi) + 5

	make/free/d/n=(5 + numnodes) tempcoefs, holdwave
	make/free/d/n=(5 + numnodes, 2) limits
	make/d/o/n=(dimsize(tempcoefs, 0), dimsize(lambdavals, 0)) coefs
	make/d/o/n=(dimsize(lambdavals, 0)) chi2
	duplicate/o yw, fitted
	
	coefs = 0
	chi2=0

	//set up the limits
	limits = 0
	limits[1, 4][0] = fresnelinfo[p - 1][0]
	limits[1, 4][1] = fresnelinfo[p - 1][1]

	for(ii = 0 ; ii < numNodes ; ii+= 1)
		limits[ii + 6][0] = minSLD
		limits[ii + 6][1] = maxSLD
	endfor

	//set up tempcoefs
	tempcoefs = 0
	tempcoefs[0] = 0
	tempcoefs[5] = maxlength

	//now set up holdwave
	holdwave = 0
	holdwave[0] = 1
	holdwave[5] = 1

	display/k=1 chi2 vs lambdavals
	ModifyGraph log(left)=1
	ModifyGraph log(bottom)=1

	for(ii = 0 ; ii < dimsize(lambdavals, 0) ; ii += 1)
		variable/g lambda
		lambda = lambdavals[ii]
		gencurvefit/MINF=lagrangesmoother/q/X=xw/hold=holdwave/D=fitted/W=ew/I=1/K={20,10,0.7,0.5}/TOL=0.01 cubicSplineRefFitter,yw,tempcoefs,"",limits
//gencurvefit /MINF=lagrangesmoother/X=root:data:e361r:e361r_q/hold=wave2/W=root:data:e361r:e361r_q/I=1/K={200,10,0.7,0.5}/TOL=0.001/L=200 cubicSplineRefFitter,root:data:e361r:e361r_R,root:coefs,"",root:gen_limits
		coefs[][ii] = tempcoefs[p]

		//need to work out proper chi2
		Wave fitted
		fitted -= yw
		fitted /= ew
		fitted *= fitted
		chi2[ii] = sum(fitted)/numpnts(yw)

		print lambdavals[ii], chi2[ii]
		doupdate
	endfor

End

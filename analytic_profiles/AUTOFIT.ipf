#pragma rtGlobals=1		// Use modern global access method.
Function autofit(yw, xw, ew, fresnelInfo, maxLength, numKnots, minSLD, maxSLD, lambdavals)
	Wave yw, xw, ew, fresnelInfo
	variable maxLength, numKnots, minSLD, maxSLD
	Wave lambdavals
	
	//An autofitting routine. Works by using cubic b splines to model an SLD curve. This SLD curve
	//generates a reflectivity curve, which is compared to the data
	//Please see the cubicsplines.ipf procedure file.

	//yw, xw, ew is the data: R, Q, dR
	//
	//fresnelinfo is a wave with dimensions [4 + 3*M][2]. They contain the lower and upper limits (column) for the
	//scale factor- fresnelinfo[0]
	//SLDfronting -fresnelinfo[1]
	//SLDbacking -fresnelinfo[2]
	//background	-fresnelinfo[3]
	//thickness layer M - fresnelinfo[3*M + 4]
	//SLD M - fresnelinfo[3*M + 5]
	//roughness M - fresnelinfo[3*M + 6]
	//these known layers are closest to the fronting medium. The spline region is closest to the backing medium
	
	//if you want to hold one of those parameters you should make the lower and upper limits equal
	//
	//maxlength - what is the total maximum span of the SLD profile.
	//numKnots - how many spline knots do you want to use to describe the SLD profile. This should be at least
	// N = zmax * Qmax / Pi
	//where zmax is the maxlength, and Qmax is the highest Q value in the data. If you choose too few knots you 
	//won't describe the SLD profile properly. Too few knots results in fine features not being described properly.
	//minSLD - the minimum SLD value the knots can have
	//maxSLD - the maximum SLD value the knots can have
	//lambdavals - Wave containing lagrangian multipliers to adjust the flexibility/stiffness of the generated SLD profile.
	//please see cubicsplines.ipf and Pedersen et al, J. Appl. Cryst. (1994), 27, 36-49.  This should span a
	//logarithmic range, e.g. 1e-10, 1e-9......, 1e-2, 1e-1, 1, 10.....
	//
	//The output is a 2D wave, coefs, that are the fitted coefficients. Please see cubicSplineRefFitter in cubicsplines.ipf
	//coefs has dimensions [6 + numKnots + 3M][dimsize(lambdavals, 0)]
	//The other output is a wave, chi2, which contains chi2 values corresponding to the relevant column in coefs, and the
	//relevant lambdaval
	//
	//The whole idea is that at low lambda value, the generated SLD profile is very flexible and will have the lowest chi2.
	//But this flexibility is too much, so try higher lambda values, which stiffen the SLD profile. However, once it gets too 
	//stiff the chi2 value will diverge.  So the best fit will be the coef column that has the highest lambda value, without chi2
	//diverging.
	
	variable maxQ, ii, numKnownLayers

	Wavestats/q/z xw

	numKnownLayers = (dimsize(fresnelInfo, 0) - 4)/3

	make/free/d/n=(5 + numKnots + 3 * numKnownLayers) tempcoefs, holdwave
	make/free/d/n=(5 + numKnots + 3 * numKnownLayers, 2) limits
	make/d/o/n=(dimsize(tempcoefs, 0), dimsize(lambdavals, 0)) coefs
	make/d/o/n=(dimsize(lambdavals, 0)) chi2
	duplicate/o yw, fitted
	
	coefs = 0
	chi2=0

	//set up the limits
	limits = 0
	limits[1, 4 + 3 * numKnownLayers][0] = fresnelinfo[p - 1][0]
	limits[1, 4 + 3 * numKnownLayers][1] = fresnelinfo[p - 1][1]

	for(ii = 0 ; ii < numKnots ; ii+= 1)
		limits[ii + 6 + 3 * numKnownLayers][0] = minSLD
		limits[ii + 6 + 3 * numKnownLayers][1] = maxSLD
	endfor

	//set up tempcoefs
	tempcoefs = 0
	tempcoefs[0] = numKnownLayers
	tempcoefs[5 + 3 * numKnownLayers] = maxlength

	//now set up holdwave
	holdwave = 0
	holdwave[0] = 1
	holdwave[5 + 3 * numKnownLayers] = 1
	
	display/k=1 chi2 vs lambdavals
	ModifyGraph log(bottom)=1

	for(ii = 0 ; ii < dimsize(lambdavals, 0) ; ii += 1)
		variable/g lambda
		lambda = lambdavals[ii]
		gencurvefit/MINF=lagrangesmoother/q/X=xw/hold=holdwave/D=fitted/W=ew/I=1/K={500,10,0.7,0.5}/TOL=0.01 cubicSplineRefFitter,yw,tempcoefs,"",limits
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

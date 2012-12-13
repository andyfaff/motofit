#pragma rtGlobals=1		// Use modern global access method.
#include "MOTOFIT_all_at_once"
#include "Pla_reduction"
Function thetadist(theta, qwave, d1, d2, L12, nom_q, nom_theta)
	Wave theta, qwave
	variable d1, d2, L12, nom_q, nom_theta

	variable beeta, alpha, gradient, intercept, areas, nom_lambda, thetarad

	nom_lambda = 4*Pi*sin(nom_theta)/nom_q
	thetarad = nom_theta
	
	alpha = (d1 + d2) / 2 / L12
	beeta = abs(d1-d2) / 2 / L12
	
	duplicate/free qwave, xtheta
	xtheta = asin(qwave[p] * nom_lambda / 4 / Pi)
	
	theta = (xtheta[p] >= thetarad-beeta && xtheta[p] <= thetarad + beeta) ? 1 : 0
	gradient = 1/(alpha - beeta)
	intercept = alpha * gradient
	theta = (xtheta[p] < thetarad-beeta) ? gradient * (xtheta[p]-thetarad) + alpha * gradient : theta
	theta = (xtheta[p] > thetarad+beeta) ? -gradient * (xtheta[p]-thetarad) + alpha * gradient : theta
	theta = (xtheta[p] < thetarad-alpha || xtheta[p] >= thetarad + alpha) ? 0 : theta

	areas =  area(theta)
	theta /= areas
	
	//now we have distribution as a function of theta
	//transform with the jacobian
	theta *= nom_lambda/4/Pi/cos(xtheta[p])
	
End

Function lambdadist(lambda, qwave, nom_lambda, reso, nom_q)
	Wave lambda, qwave
	variable nom_lambda, reso, nom_q

	variable areas, dl, K, loLambda, hiLambda, hiQ, loQ
	
	K = nom_q * nom_lambda		//4 * Pi * sin(theta)
	dl = nom_lambda * reso/200

	hiQ = K/(nom_lambda - dl)
	loQ = K/(nom_lambda + dl)
	
	lambda = 0
	//The rectangular distribution must undergo a Jacobian transformation
	//into Q space
	lambda = (qwave[p] >= loQ && qWave[p] <= hiQ) ? K/ 2 / dl / qwave[p]^2 : 0
End

Function bursttimedist(lambda, xlambda, nom_lambda, ss2vg, chod, radius, freq)
	Wave lambda, xlambda
	variable  nom_lambda, ss2vg, chod, radius, freq

	variable areas, tau, totalflight, temp2, temp

	totalflight = nom_lambda/3956*(chod/1000)
	tau = ss2vg/radius/2/Pi/freq 
	temp = 3956* (totalflight-tau / 2)/(chod/1000)
	temp2 = 3956* (totalflight+tau / 2)/(chod/1000)

	lambda = (xlambda[p] + nom_lambda >= temp && xlambda[p] + nom_lambda <= temp2) ? 1 : 0
End

function/wave actualkernel(nomtheta, d1,d2,L12, nomq, reso, chod, radius, freq)
	Variable nomtheta, d1, d2, L12, nomq, reso, chod, radius, freq

	variable qq, areas, nomlambda
	make/d/n=501/o lambda, theta,qwave, lambda2
	duplicate/free qwave, xlambda, xtheta, tempkernel
	
	nomlambda = 4 * Pi * sin(nomtheta)/nomq
	
	qq = 4*Pi*sin(nomtheta)/nomlambda
	setscale/I x, qq * (0.9), qq * 1.1, theta, lambda, lambda2, qwave, tempkernel

	qwave = x
	xlambda[] = 4 * Pi * sin(nomtheta)/qwave[p] - nomlambda
	xtheta[] = asin(qwave[p] /4 / Pi * nomlambda) - (nomtheta)

	thetadist(theta, qwave, d1,d2, L12, nomq, nomtheta); 
	lambdadist(lambda, qwave, nomlambda, reso, nomq)
	bursttimedist(lambda2, xlambda, nomlambda, d2, chod, radius, freq)

	areas =  areaxy(qwave, lambda)
	lambda /= areas

	areas =  areaxy(qwave, lambda2)
	lambda2 /= areas
	
	areas =  areaxy(qwave, theta)
	theta /= areas

	tempkernel = theta
	convolve/A lambda, tempkernel
	tempkernel *=deltax(tempkernel)

//if you are rebinning to the resolution you measured at, then you need
//to convolve the lambda contribution twice.	
//	convolve/A lambda, tempkernel
//	tempkernel*= 	deltax(tempkernel)

	convolve/A lambda2, tempkernel
	tempkernel *=deltax(tempkernel)
	
	make/n=(dimsize(tempkernel, 0), 2)/o/d kernel
	copyscales tempkernel, kernel
	kernel[][0] = qwave[p]	
	kernel[][1] = tempkernel[p]
	return kernel
End

Function test()

Wave kernel = actualkernel(3.29*Pi/180, 2.06, 2.06, 2850, 0.19351, 5, 7300, 350,20)
print theoreticalkernel(3.29*Pi/180, 2.06, 2.06, 2850, 0.19351, 5, 7300, 350,20)
End

function theoreticalkernel(nomtheta, d1,d2,L12, nomq, reso, chod, radius, freq)
	Variable nomtheta, d1, d2, L12, nomq, reso, chod, radius, freq
	
	variable lambda, dlambda, dtheta, thetarad, dq, tof
	thetarad = nomtheta
	dtheta = sqrt(0.68^2*(d1^2 + d2^2)/L12^2)
	
	lambda = 4*Pi*sin(thetarad)/nomq
	tof = chod/1000*lambda/3956

	//this is if you are rebinning to the resolution that you measured at
//	dlambda = sqrt(0.68^2 * ((reso/100)^2 + (reso/100)^2))
	
	//this is if you don't rebin to the resolution you measured at.
	print (reso/100)^2,(d1/radius/tof/freq/2/Pi)^2 
	dlambda = sqrt(0.68^2 * ((reso/100)^2 + (d1/radius/tof/freq/2/Pi)^2))
	
	
	dq =  nomq*sqrt((dlambda)^2 + (dtheta/thetarad)^2)
	return dq
End


Function assignActualKernel()
	Wave W_q, omega, d1, d2
	//d1=3.0
	//d2=3.0
	make/n=(dimsize(W_q, 0), 501, 2)/d/o resolutionkernel

	variable ii
	for(ii = 0 ; ii < numpnts(W_q) ; ii+=1)
		Wave kernel = actualkernel(omega[ii], 2.06, 2.06, 2835, W_q[ii], 4.7, 7382, 350, 20)

		resolutionkernel[ii][][0] = kernel[q][0]
		resolutionkernel[ii][][1] = kernel[q][1]
	endfor
End

Function assigntheoreticalKernel()
	Wave theoretical_q
	Wave  thetas = root:actualkernel:thetas
	Wave  d1 =  root:actualkernel:d1
	Wave d2 =  root:actualkernel:d2
	cd root:theoreticalkernel

	make/n=(dimsize(theoretical_q, 0))/d/o resolutionkernel

	variable ii, dq
	for(ii = 0 ; ii < dimsize(theoretical_q,0) ; ii+=1)
		resolutionkernel[ii] = theoreticalkernel(thetas[ii], d1[ii], d2[ii], 2800, theoretical_q[ii], 6.44, 7300, 350, 20)

	endfor
End
#pragma rtGlobals=1		// Use modern global access method.

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

//a fit function for fitting NSF reflectivity (both spin channels)
//assumes that y and x are concatenated datasets. i.e.
//Rplusplus comes first, then Rminusminus. 
//The number of data points in each channel should be put into ffsWaves[0]
Function motofitNSF(s):fitfunc
	Struct fitfuncStruct &s
	variable npointsPlus, npointsminus
	Wave numpoints = s.ffsWaves[0]
	Wave yy = s.y
	Wave xx = s.x[0]
	Wave w = s.w
	npointsplus = numpoints[0]
	npointsminus = numpoints[1]
	
	make/n=(npointsplus)/c/d/free rspin
	make/n=(npointsplus)/d/free qspin
	qspin[] = xx[p]
	
	Abeles_bmagall(w, rspin, qspin)
	yy[] = real(rspin[p])

	redimension/n=(npointsminus)/c/d rspin
	redimension/n=(npointsminus)/d qspin
	qspin[] = xx[p + npointsplus]
	
	Abeles_bmagall(w, rspin, qspin)
	yy[] = imag(rspin[p + npointsplus])
	yy = log(yy)
End

//a fit function for fitting NSF reflectivity (one spin channel)
Function NSFplusplus(w, yy, xx):fitfunc
Wave w, yy, xx
duplicate/free yy, rtemp
redimension/c rtemp
Abeles_bmagall(w, rtemp, xx)
yy = log(real(rtemp))
End

Function NSFminusminus(w, yy, xx):fitfunc
Wave w, yy, xx
duplicate/free yy, rtemp
redimension/c rtemp
Abeles_bmagall(w, rtemp, xx)
yy = log(imag(rtemp))
End

Function main(w, limitwave, holdwave, iterations, Qplusplus, Rplusplus, Eplusplus, Qminusminus, Rminusminus, Eminusminus)
	Wave w, limitwave, holdwave
	variable iterations
	Wave Qplusplus, Rplusplus, Eplusplus, Qminusminus, Rminusminus, Eminusminus

	//w should have size 4 * n + 8.
	//w[0] = nlayers
	//w[1] = scale
	//w[2] = SLDf
	//w[3] = bmagf
	//w[4] = SLDb
	//w[5] = bmagf
	//w[6] = bkg
	//w[7] = backingrough
	//w[4*n + 8] = thickn
	//w[4*n + 9] = SLDn
	//w[4*n + 10] = bmagn
	//w[4*n + 11] = roughn
	
	//limitwave[numpnts(w)][2] - first column is lowerlimit, second column upperlimit
	//holdwave[numpnts(w)] - set to 0 to let param vary, !=0 to fix param.
	//iterations is number of mc iterations.
	
	Struct fitfuncStruct s
	variable ii, totaltime
	totaltime = datetime
	
	make/d/free/n=(numpnts(Rplusplus) + numpnts(Rminusminus)) tempqq, tempRR, tempee
	make/d/n=2/free numpoints
	
	numpoints[0] = numpnts(Rplusplus)
	numpoints[1] = numpnts(Rminusminus)
	
	tempqq[] = qplusplus[p]
	temprr[] = Rplusplus[p]
	tempee[] = eplusplus[p]
	tempqq[] = qminusminus[p + numpoints[0]]
	temprr[] = Rminusminus[p + numpoints[0]]
	tempee[] = eminusminus[p + numpoints[0]]

	s.ffswaves[0] = numpoints

	make/n=(iterations, dimsize(w, 0)) M_montecarlo = 0
	for(ii = 0 ; ii < iterations ; ii += 1)
		if(ii == 0)
			Gencurvefit /strc=s /X=tempqq /hold=holdwave motofitNSF, tempyy, w, "", limitwave
		else
			Gencurvefit /MC/strc=s /X=tempqq /hold=holdwave motofitNSF, tempyy, w, "", limitwave
		endif	
		
		M_montecarlo[ii][] = w[q]
		print "done iteration", ii, "in", datetime - totaltime, "seconds"
	endfor
End

Function pmatrix(qu,qd,dspac)
	variable/c qu,qd
	variable dspac
	make/o/n=(4,4)/c/d M_p
	M_p=cmplx(0,0)	
		M_p[0][0] = exp(-cmplx(0,1)*qu*dspac)
		M_p[1][1] = exp(cmplx(0,1)*qu*dspac)
		M_p[2][2] = exp(-cmplx(0,1)*qd*dspac)
		M_p[3][3] = exp(cmplx(0,1)*qd*dspac)
End

Function dmatrix(qu,qd)
	variable/c qu,qd
	make/d/o/c/n=(4,4) M_d = 0
	
	M_d[0][0] = 1
	M_d[0][1] = 1
	M_d[1][0] = qu
	M_d[1][1] = -qu

	M_d[2][2] = 1
	M_d[2][3] = 1
	M_d[3][2] = qd
	M_d[3][3] = -qd
End

Function/c qcal(qq,nb)
	variable qq,nb
	variable qc2 = 4*Pi*nb
	variable/c qperp
	
	qperp = sqrt(qq^2-qc2)
	
	return qperp
End

Function RRcalc(theta)
variable theta
make/o/d/c/n=(4,4) M_RR = 0
theta/=2
M_RR[0][0] = cos(theta)*cmplx(1,0)
M_RR[1][1] = cos(theta)*cmplx(1,0)

M_RR[0][2] = sin(theta)*cmplx(1,0)
M_RR[1][3] = sin(theta)*cmplx(1,0)

M_RR[2][0] = -sin(theta)*cmplx(1,0)
M_RR[3][1] = -sin(theta)*cmplx(1,0)

M_RR[2][2] = cos(theta)*cmplx(1,0)
M_RR[3][3] = cos(theta)*cmplx(1,0)

End

Function pnr(w,xx)
	Wave w,xx
	//ww parameter wave, xx is the number of x points for calculation
	//w[0] = number of layers
	//w[1] = scale
	//	[2] = sldupper
	//	[3] = Bupper
	//	[4] = thetaupper
	//	[5] = sldlower
	//	[6] = Blower

	//	[ 4n+7] = d n
	//	[ 4n+8] = sld n
	//	[ 4n+9] = b n
	//	[ 4n+10] = theta n

	make/o/d/n=(numpnts(xx),4) M_pnr
	make/o/d/n=(4,4)/c M,MM,RR
	
	variable nb_air=w[2]
	variable nb_sub=w[5]
	variable ii,jj
	for(ii=0;ii<numpnts(xx);iI+=1)
		variable qvac = xx[ii]*0.5
		//   qvac(iq)=(qmin+float(iq)*qstep)*0.5
		variable/c qair_u=qcal(qvac,nb_air+w[3])
		variable/c qair_d=qcal(qvac,nb_air-w[3])

		variable/c qsub_u=qcal(qvac,(nb_sub+w[6]))
		variable/c qsub_d=qcal(qvac,(nb_sub-w[6]))
		MM = 0
		MM[0][0] = cmplx(1,0)
		MM[1][1] = cmplx(1,0)
		MM[2][2] = cmplx(1,0)
		MM[3][3] = cmplx(1,0)
 
		for( jj=0;jj<w[0];jj+=1)
			variable/c qu = qcal(qvac,w[4*jj+8]+w[4*jj+9])
			variable/c qd = qcal(qvac,w[4*jj+8]-w[4*jj+9])
			variable/c thetai
			if(jj==0)
				thetai = (w[4])*Pi/180
			else
				thetai = (w[4*jj+10])*Pi/180
			endif
			
			RRcalc(thetai)
						
			dmatrix(qu,qd)	//create M_d
			pmatrix(qu,qd,w[4*jj+7])
			
			Wave M_d,M_p,M_RR
			MatrixOp/O MM = MM x M_d x M_p x (inv(M_d) x M_RR)
		endfor
		
		RRcalc(Pi/180*w[4])
		
		dmatrix(qair_u,qair_d)
		Wave M_d,M_RR
		
		MatrixOp/o M = (inv(M_d)) x M_RR x MM
		dmatrix(qsub_u,qsub_d)
		MatrixOp/o M = M x M_d

		M_pnr[ii][0] = magsqr((M[1][0]*M[2][2]-M[1][2]*M[2][0])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//uu
		M_pnr[ii][1] = magsqr((M[3][2]*M[0][0]-M[3][0]*M[0][2])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//dd
		M_pnr[ii][2] = magsqr((M[3][0]*M[2][2]-M[3][2]*M[2][0])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//ud
		M_pnr[ii][3] = magsqr((M[1][2]*M[0][0]-M[1][0]*M[0][2])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//du

	endfor

End

#pragma rtGlobals=1		// Use modern global access method.
#include "motofit_all_at_once"

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

Function NSF_globally(w, RR, qq):fitfunc
	Wave w, RR, qq
	
	Wave linkages = root:Packages:motofit:reflectivity:globalfitting:linkages
	Wave numcoefs = root:Packages:motofit:reflectivity:globalfitting:numcoefs
	Wave pnts_each_dataset = root:Packages:motofit:reflectivity:globalfitting:pnts_each_dataset
	variable ii, offset = 0
	make/n=(pnts_each_dataset[0])/d/free ytemp, xtemp
	
	Wave/wave individual_coefs = Motofit_GR#decompose_into_individual_coefs(w)
	for(ii = 0 ; ii < numpnts(numcoefs) ; ii+=1)
		redimension/n=(pnts_each_dataset[ii]) xtemp, ytemp
		xtemp = qq[offset + p]
		Wave indy = individual_coefs[ii]
		if(ii == 0)
			NSFplusplus(individual_coefs[ii], ytemp, xtemp)
		elseif(ii == 1)
			NSFminusminus(individual_coefs[ii], ytemp, xtemp)
		endif
		RR[offset, offset + pnts_each_dataset[ii] - 1] = ytemp[p - offset]
		offset += pnts_each_dataset[ii]
	endfor
End


Function main(dplusplus, dminusminus, wplusplus, wminusminus, holdwave, linkages, iterations)
	string dplusplus, dminusminus
	wave wplusplus, wminusminus, holdwave, linkages
	variable iterations

	DFREF saveDFR = GetDataFolderDFR()

	variable ii, jj, kk, totaltime
	totaltime = datetime
	
	Wave Qplusplus = $("root:data:" + dplusplus + ":" + dplusplus + "_q")
	Wave Rplusplus = $("root:data:" + dplusplus + ":" + dplusplus + "_R")
	Wave Eplusplus = $("root:data:" + dplusplus + ":" + dplusplus + "_E")
	Wave Qminusminus = $("root:data:" + dminusminus + ":" + dminusminus + "_q")
	Wave Rminusminus = $("root:data:" + dminusminus + ":" + dminusminus + "_q")
	Wave Eminusminus = $("root:data:" + dminusminus + ":" + dminusminus + "_q")

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
	
	if(dimsize(holdwave, 1) != 2 || dimsize(linkages, 1) != 2)
		SetDataFolder saveDFR
		abort
	endif
	
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:Packages:motofit:reflectivity:
	newdatafolder/o/s root:Packages:motofit:reflectivity:globalfitting:
	
	make/d/free/n=(numpnts(Rplusplus) + numpnts(Rminusminus)) tempqq, tempRR, tempee
	Duplicate/O linkages, $("root:Packages:motofit:reflectivity:globalfitting:linkages")

	make/n=2/d numcoefs
	numcoefs[0] = dimsize(wplusplus, 0)
	numcoefs[1] = dimsize(wminusminus, 0)
	
	make/d/n=2 pnts_each_dataset
	pnts_each_dataset[0] = numpnts(Rplusplus)
	pnts_each_dataset[1] = numpnts(Rminusminus)
	
	tempqq[] = qplusplus[p]
	temprr[] = Rplusplus[p]
	tempee[] = eplusplus[p]
	tempqq[] = qminusminus[p + pnts_each_dataset[0]]
	temprr[] = Rminusminus[p + pnts_each_dataset[0]]
	tempee[] = eminusminus[p + pnts_each_dataset[0]]
	
	//make combined coefficients
	Wave uniqueparams = Motofit_GR#isUniqueParam()
	duplicate/free wplusplus, w_combined
	duplicate/free holdwave, w_hold
	
	redimension/n=(-1, 2) w_combined
	redimension/n=(numpnts(w_hold), 0) w_hold
	redimension/n=(numpnts(uniqueparams), 0) uniqueparams

	for(ii = dimsize(uniqueparams, 0) - 1; ii > -1 ; ii -= 1)
		if(!uniqueparams[ii])
			deletepoints ii, 1, w_combined, w_hold
		endif
	endfor

	make/n=(iterations, dimsize(w_combined, 0)) root:M_montecarlo = 0
	Wave M_montecarlo = root:M_montecarlo
	for(ii = 0 ; ii < iterations ; ii += 1)
		if(ii == 0)
			Gencurvefit  /X=tempqq /hold=holdwave NSF_globally, tempyy, w_combined, "", limitwave
		else
			Gencurvefit /MC /X=tempqq /hold=holdwave NSF_globally, tempyy, w_combined, "", limitwave
		endif	
		
		M_montecarlo[ii][] = W_combined
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

//Function RRcalc(theta)
//variable theta
//make/o/d/c/n=(4,4) M_RR = 0
//theta/=2
//M_RR[0][0] = cos(theta)*cmplx(1,0)
//M_RR[1][1] = cos(theta)*cmplx(1,0)
//
//M_RR[0][2] = sin(theta)*cmplx(1,0)
//M_RR[1][3] = sin(theta)*cmplx(1,0)
//
//M_RR[2][0] = -sin(theta)*cmplx(1,0)
//M_RR[3][1] = -sin(theta)*cmplx(1,0)
//
//M_RR[2][2] = cos(theta)*cmplx(1,0)
//M_RR[3][3] = cos(theta)*cmplx(1,0)
//
//End

//Function pnr(w,xx)
//	Wave w,xx
//	//ww parameter wave, xx is the number of x points for calculation
//	//w[0] = number of layers
//	//w[1] = scale
//	//	[2] = sldupper
//	//	[3] = Bupper
//	//	[4] = thetaupper
//	//	[5] = sldlower
//	//	[6] = Blower
//
//	//	[ 4n+7] = d n
//	//	[ 4n+8] = sld n
//	//	[ 4n+9] = b n
//	//	[ 4n+10] = theta n
//
//	make/o/d/n=(numpnts(xx),4) M_pnr
//	make/o/d/n=(4,4)/c M,MM,RR
//	
//	variable nb_air=w[2]
//	variable nb_sub=w[5]
//	variable ii,jj
//	for(ii=0;ii<numpnts(xx);iI+=1)
//		variable qvac = xx[ii]*0.5
//		//   qvac(iq)=(qmin+float(iq)*qstep)*0.5
//		variable/c qair_u=qcal(qvac,nb_air+w[3])
//		variable/c qair_d=qcal(qvac,nb_air-w[3])
//
//		variable/c qsub_u=qcal(qvac,(nb_sub+w[6]))
//		variable/c qsub_d=qcal(qvac,(nb_sub-w[6]))
//		MM = 0
//		MM[0][0] = cmplx(1,0)
//		MM[1][1] = cmplx(1,0)
//		MM[2][2] = cmplx(1,0)
//		MM[3][3] = cmplx(1,0)
// 
//		for( jj=0;jj<w[0];jj+=1)
//			variable/c qu = qcal(qvac,w[4*jj+8]+w[4*jj+9])
//			variable/c qd = qcal(qvac,w[4*jj+8]-w[4*jj+9])
//			variable/c thetai
//			if(jj==0)
//				thetai = (w[4])*Pi/180
//			else
//				thetai = (w[4*jj+10])*Pi/180
//			endif
//			
//			RRcalc(thetai)
//						
//			dmatrix(qu,qd)	//create M_d
//			pmatrix(qu,qd,w[4*jj+7])
//			
//			Wave M_d,M_p,M_RR
//			MatrixOp/O MM = MM x M_d x M_p x (inv(M_d) x M_RR)
//		endfor
//		
//		RRcalc(Pi/180*w[4])
//		
//		dmatrix(qair_u,qair_d)
//		Wave M_d,M_RR
//		
//		MatrixOp/o M = (inv(M_d)) x M_RR x MM
//		dmatrix(qsub_u,qsub_d)
//		MatrixOp/o M = M x M_d
//
//		M_pnr[ii][0] = magsqr((M[1][0]*M[2][2]-M[1][2]*M[2][0])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//uu
//		M_pnr[ii][1] = magsqr((M[3][2]*M[0][0]-M[3][0]*M[0][2])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//dd
//		M_pnr[ii][2] = magsqr((M[3][0]*M[2][2]-M[3][2]*M[2][0])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//ud
//		M_pnr[ii][3] = magsqr((M[1][2]*M[0][0]-M[1][0]*M[0][2])/(M[0][0]*M[2][2]-M[0][2]*M[2][0]))//du
//
//	endfor
//
//End

#pragma rtGlobals=1		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

Function Pla_findpeakDetails(ywave,xwave,[expected_centre,expected_width])//distance,profile)//y, x
	Wave ywave,xwave
	variable expected_centre,expected_width
//	Wave mask
	variable ii
	//tries to find a peak around expected centre, with a given width.
	//you need to have a good estimate of the peak width.
	//this function expects equal spacing

	make/o/d/n=8 W_peakinfo
	
	//work out the centroid position
	W_peakinfo[0] = Pla_peakCentroid(xwave,ywave,x0=expected_centre-2*expected_width,x1=expected_centre+2*expected_width)
      
	//now work out where the leading edge and trailing edge of the peak is.  
	//CAUTION, this may be rough
	Wave/z W_integrate,W_integratex
      
	//this should get 99.5% of the integrated counts
	//note that you can only get these positions if profile is an equally spaced wave.
	if(waveexists(W_integrate) && waveexists(W_integratex))
		variable leadingedgeval = binarysearchinterp(W_integrate,0.0025)
		variable leadingedgepos =W_integratex[trunc(leadingedgeval)]+ (leadingedgeval-trunc(leadingedgeval))*(W_integratex[trunc(leadingedgeval)+1]-W_integratex[trunc(leadingedgeval)])
		variable trailingedgeval = binarysearchinterp(W_integrate,0.9975)
		variable trailingedgepos =W_integratex[trunc(trailingedgeval)]+ (trailingedgeval-trunc(trailingedgeval))*(W_integratex[trunc(trailingedgeval)+1]-W_integratex[trunc(trailingedgeval)])
		W_peakinfo[1] = leadingedgepos
		W_peakinfo[2] = trailingedgepos
	endif
	
	W_peakinfo[3] = areaXY(xwave,ywave)
	
	variable V_fiterror
	variable/g V_fitOptions=4
	
	variable low,high
	if(paramisdefault(expected_Centre) || paramisdefault(expected_width))
		low=0
		high = numpnts(xwave)-1
	else
		low = round(binarysearchinterp(xwave,expected_centre-3*expected_width))
		high = round(binarysearchinterp(xwave,expected_centre+3*expected_width))
		if(numtype(low))
			low = 0
		endif
		if(numtype(high))
			high = numpnts(xwave)
		endif
	endif
	
	Curvefit/q/n gauss, ywave[low,high]/X=xwave[low,high]
	Wave W_coef
	W_peakinfo[4] = W_coef[0]
	W_peakinfo[5] = W_coef[1]
	W_peakinfo[6] = W_coef[2]
	W_peakinfo[7] = W_coef[3]
	killwaves/z W_coef
End

Function Pla_findpeak(distance, profile,centre,sd)
	Wave distance,profile
	variable centre,sd
	//finds the most intense peak, returns its position
	//this can fall over if:
	//a) the non-specular peaks are more intense than the specular peak
	//b) there is a strong linear background that can overwhelm the peaks
	//
	//To get around this one should always restrict the area of interest.
	//sets a global variable called Pla_peakloc
	variable/g Pla_peakloc

	variable x0,x1
	x0 = centre - 5*sd
	x1 = centre + 5*sd

	variable peak
	variable pnts = binarysearch(distance,x0)
	if(pnts<0)
		pnts=0
	endif
	variable xx = distance[pnts]
	variable ii = 0,maxpeak,maxpeakloc

	duplicate/o profile,W_temp
	duplicate/o distance,W_tempx

	Deletepoints 0,pnts, W_temp,W_tempx
	xx = binarysearch(W_tempx,x1)
	if(xx<0)
		xx=numpnts(W_tempx)-1
	endif
	Deletepoints xx,numpnts(W_temp), W_temp,W_tempx

	Differentiate W_temp /D=W_temp_dif/X=W_tempx
	Differentiate W_temp_Dif /D=W_temp_dif_dif/X=W_tempx

	//find out how many minima there are.
	FindLevels/Q W_temp_dif, 0
	//perhaps no levels, go to 2nd derivative
	//this is slightly bodgy.  You are going on the hope that the peak you are shooting for has a larger 2nd derivative minimum, which 
	//will happen if the peak is sharper.  This is often the case for specular scattering.  This can also pick up an inflexion point
	if(V_Flag==2)
		Wavestats/M=1/q/z W_temp_dif_dif
		Pla_peakloc = V_minloc
		Killwaves/z W_temp_dif,W_temp_dif_dif,W_temp,W_tempx
	endif
	Wave W_findlevels

	//if you find one place were the differential is 0 then return that.
	if(V_levelsfound == 1)
		Pla_peakloc =  W_tempx[W_findlevels[0]]
		Killwaves/z W_temp_dif,W_temp_dif_dif,W_temp,W_findlevels,W_tempx
	endif
	//if there is more than one maxima, then return the most intense one.
	if(V_levelsfound>1)	
		for(ii=0 ; ii<V_levelsfound ; ii+=1)
			peak =W_temp[W_findlevels[ii]]
			if(peak>maxpeak)
				maxpeak = peak
				maxpeakloc = W_tempx[W_findlevels[ii]]
			endif
		endfor
		Pla_peakloc = maxpeakloc
	endif
	Killwaves/z W_temp_dif,W_temp_dif_dif,W_temp,W_tempx,W_findlevels,W_tempx
End

Threadsafe Function Pla_peakCentroid(xwave,ywave,[x0,x1])
	Wave xwave,ywave
	variable x0,x1
	variable retval
	if(ParamisDefault(x0) || ParamisDefault(x1))
		x0 = 0
		x1 = numpnts(ywave)-1
	endif
	
	//finds the centroid of an xwave,ywave pair.
	//makes W_integrate, an integral under the peak,with W_integratex the corresponding xvalues
	//also returns the centroid, i.e. the mean value.
	
	if(numpnts(xwave)!=numpnts(ywave))
		return Nan
	elseif(x0<0 ||x0>x1||x1>numpnts(ywave)-1)
		return Nan
	else
		duplicate/o ywave, W_tempy
		duplicate/o xwave, W_tempx
		Sort xwave, xwave,ywave
		deletepoints x1+1,numpnts(W_tempy),W_tempy,W_tempx
		deletepoints 0, x0-1,W_tempy,W_tempx
	endif
	
	duplicate/o W_tempx, W_integrate,W_integratex
	W_integrate = 0
	
	variable ii
	for(ii=0 ; ii<numpnts(W_tempx); ii+=1)
			W_integrate[ii] = AreaXY(W_tempx,W_tempy,W_tempx[0],W_tempx[ii])
	endfor
	
	W_integrate /= W_integrate[numpnts(W_tempx)-1]
	variable centroid = binarysearchinterp(W_integrate,0.5)
	if(numtype(centroid))
		retval = NaN
	else
		retval = W_integratex[centroid]
	endif
	
	killwaves/z W_tempy,W_tempx
	return retval
End

Function Pla_halfheight_func(w, yy, xx):fitfunc
	Wave w, yy, xx
	//w[0] = background value
	//w[1] = plateau value (in absence of background)
	//w[2] = location of point of inflection
	//w[3] = sd of decay
	yy = w[1] * 0.5 * erfc((xx - w[2])/w[3]) + w[0]
End

Function/wave Pla_halfheight(yy, xx, ee)
	//fit an error function scan ("halfheight scan")
	//The values are returned in a wave
	//w[0] - the background value
	//w[1] - the plateau value (in absence of background)
	//w[2] = location of point of inflection
	//w[3] = sd of decay
	
	//To get the absolute plateau value calculate w[0] + w[1]
	//To get half height between plateau and background calculate w[0] + 0.5 * w[1]
	Wave yy, xx, ee

	make/n=4/d/free coefs
	make/n=(4, 2)/d/free limits

	Wavestats/q yy
	limits[0][0] = V_min
	limits[0][1] = V_max
	limits[1][0] = V_min
	limits[1][0] = V_max

	Wavestats/q xx
	limits[2][0] = V_min
	limits[2][1] = V_max

	limits[3][0] = 0.0000000000001
	limits[3][1] = V_max

	gencurvefit/I=1/W=ee/Q/N/K={200, 10, 0.7, 0.5}/x=xx/DITH= {0.5, 2}/tol=0.03 Pla_halfheight_func, yy, coefs,"0000",limits
	return coefs
End



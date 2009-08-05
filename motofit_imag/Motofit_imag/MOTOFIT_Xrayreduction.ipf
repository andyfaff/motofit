#pragma rtGlobals=1		// Use modern global access method.
///MOTOFIT is a program that fits neutron and X-ray reflectivity profiles :written by Andrew Nelson
//Copyright (C) 2005 Andrew Nelson and Australian Nuclear Science and Technology Organisation
//anz@ansto.gov.au
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

//MOTOFIT uses the Parratt formalism to calculate the reflectivity.
//MOTOFIT is a powerful tool for Co-refining multiple contrast datasets from the same sample.
//The software should be compatible with Macintosh/PC/NT platforms and requires that IGOR Pro* is installed. 
//You do not have to purchase IGOR Pro - a free demo version of IGOR Pro is available, however some utilities are disabled (such as copying to/from the clipboard)
//IGOR Pro is a commercial software product available to Mac/PC/NT users. 
//A free demo version of IGOR is available from WaveMetrics Inc. These experiments and procedures were created using IGOR Pro 5.04
//The routines have not been tested on earlier versions of IGOR.


Function ReduceXray()
	//this function reduces data from a Pananalytical X-pert Pro system.  It could easily be modified to reduce data
	//from any other machine.
	
	//check we have XMLutils
	if(itemsinlist(functionlist("xmlopenfile",";","")) == 0)
		abort "XMLutils XOP not installed"
	endif
	
	variable fileID

	open/d/a/t="????"/m="Please select an XRDML file" fileID	
	
	//user probably aborted
	if(strlen(S_filename)==0)
		return 0
	endif
	
	String filepath,filename
	filepath = parsefilepath(5,S_fileName,"*",0,1)
	
	//xmlopenfile has to take a UNIX path
	if(cmpstr(igorinfo(2),"Macintosh")==0)
		filename = parsefilepath(3,S_filename,":",0,0)
	else
		filename = parsefilepath(3,filepath,"\\",0,0)
	endif
	
	filename = cleanupname(filename,0)

	//make the names of the datawaves something nicer. 
	String w0,w1,w2, w3
	w0 = CleanupName((fileName + "_q"),0)
	w1 = CleanupName((fileName + "_R"),0)
	w2 = CleanupName((fileName + "_e"),0)
	w3 = CleanupName((fileName + "_dq"),0)
	
	//you don't need to reduce the file if its already been done
	if(exists(w0) !=0)
		DoAlert 0,"This file has already been done"
		KillWaves/z $w0,$w1,$w2, $w3
		ABORT
	endif

	//open the XML file
	fileID = xmlopenfile(filepath)
	if(fileID == -1)
		abort
	endif
		
	//now need to load in the data
	xmlwavefmxpath(fileID,"//xrdml:intensities","xrdml=http://www.xrdml.com/XRDMeasurement/1.0"," \n\r\t")
	
	Wave/t M_xmlcontent
	make/o/d/n=(dimsize(M_xmlcontent,0)) $w0,$w1,$w2, $w3
	Wave qq = $w0, R = $w1, dR = $w2, dq = $w3
	
	R = str2num(M_xmlcontent[p][0])
	
	variable start,stop
	start = str2num(xmlstrfmxpath(fileID,"//xrdml:dataPoints/xrdml:positions[2]/xrdml:startPosition/text()","xrdml=http://www.xrdml.com/XRDMeasurement/1.0"," "))
	stop = str2num(xmlstrfmxpath(fileID,"//xrdml:dataPoints/xrdml:positions[2]/xrdml:endPosition/text()","xrdml=http://www.xrdml.com/XRDMeasurement/1.0"," "))
	
	qq = start + p*(stop-start)/(numpnts(qq)-1)
	
	//the error in reflectivity is the square root of the counts
	dR=sqrt(R)
	
	//you need to know the wavelength
	Variable CuKa=1.541,CuKa1,CuKa2,ratio
	CuKa1 = str2num(xmlstrfmxpath(fileID,"//xrdml:kAlpha1/text()","xrdml=http://www.xrdml.com/XRDMeasurement/1.0"," "))
	CuKa2 = str2num(xmlstrfmxpath(fileID,"//xrdml:kAlpha2/text()","xrdml=http://www.xrdml.com/XRDMeasurement/1.0"," "))
	ratio = str2num(xmlstrfmxpath(fileID,"//xrdml:ratioKAlpha2KAlpha1/text()","xrdml=http://www.xrdml.com/XRDMeasurement/1.0"," "))
	CuKa = (CuKa1+ratio*CuKa2)/(1+ratio)
	
	xmlclosefile(fileID,0)

	variable ii
	doalert 2,"Perform a footprint correction (assumes 1/32 slit + no knife edge)?"
	switch(V_Flag)
		case 1:
			//correction taken from Gibaud et al., Acta Crystallographica, A49, 642-648
			Variable L = 100 //sample length in mm
			variable t_m = 0.108	//value at which the beam falls to zero
			variable T_r = 0.0365		//real thickness of the beam at the sample location

			Prompt L, "sample footprint (mm)"
			Doprompt "sample footprint correction", L
			if(V_Flag == 1)
				abort
			endif
			variable correctionfactor
			make/d/o w_gausscoefs={1, 0, T_r/2}
			for(ii=0 ; ii<numpnts(qq); ii+=1)
				correctionfactor = integrate1D(myga, 0, L*sin(qq[ii]*Pi/180)*0.5)/ integrate1D(myga, 0, t_m)
				R[ii] /= correctionfactor
			endfor
		case 2:
			break
		case 3:
			killwaves/z R,qq,dR,M_xmlcontent,W_xmlcontentnodes,R,qq,dR, dq
			abort
			break
	endswitch
	
	//make the dq wave
	//correction taken from Gibaud et al., Acta Crystallographica, A49, 642-648
	variable w_HWHM_direct_beam = 0.025*(Pi/180)
	dq = 2* (2*Pi/CuKa)* w_HWHM_direct_beam * cos(qq * Pi/180)

	//definition of Q wave vector
	qq = real(Moto_angletoQ(qq,2*qq,CuKa))

	//pull up a graph showiing the data, with the error bars
	Display/K=1 R vs QQ
	Modifygraph log(left)=1,mode=3
	ErrorBars $w1 Y,wave=($w2,$w2)
	Doupdate

	//rename the graph, and put a freely moving cursor on the graph.
	string Rwav=nameofwave(R)
	Cursor /f/h=1 A $Rwav 0.01,1
	DoWindow/C Setcriticaledge
	showinfo
	variable allgood

	//this loop creates a window, with a pause for user command
	//this allows you to adjust the cursors, such that you estimate the correct
	//level for the critical edge.  Once you are happy with that level, you press continue in the Panel,
	//which enables the rest of the function to continue.
	//The data is multiplied by the scale factor, to get the critical edge at R=1.
	do

		variable err
		err = UserCursorAdjust("Setcriticaledge")
		if(err == 1)
			Dowindow/K Setcriticaledge
			killwaves/z R,qq,dR,M_xmlcontent,W_xmlcontentnodes,R,qq,dR, dq
			abort
		endif
		
		Variable scale=vcsr(A)
		Prompt scale, "critical edge scale value"
		Doprompt "critical edge scale value",scale
		if(V_flag==1)
			Dowindow/K Setcriticaledge
			killwaves/z R,qq,dR,M_xmlcontent,W_xmlcontentnodes,R,qq,dR, dq
			abort
		endif 
		R/=scale
		dr/=scale
		Setaxis/A
		Doupdate
		//you can continually adjust the lvel until you are happy with it.
		Doalert 1,"Is it good?"
		if(V_flag==1)
			allgood=1
		endif
		if(V_flag==3)
			Dowindow/K Setcriticaledge
			killwaves/z R, qq, dR, M_xmlcontent, W_xmlcontentnodes, R, qq, dR, dq
			abort
		Endif

	while(allgood==0)

	//now save the data, works with the demo version of IGOR as well.
	SaveXraydata(filename)
	Dowindow/K Setcriticaledge
	killwaves/z R,qq,dR,M_xmlcontent,W_xmlcontentnodes, dq
End

Function myga(xx)
	variable xx
	Wave W_gausscoefs
	return W_gausscoefs[0]*exp(-0.5*((xx-W_gausscoefs[1])/W_gausscoefs[2])^2)

End

Function analyseInstrument(w, x):fitfunc
	Wave w
	variable x
	//w[0] = bkg        a background
	//w[1] = I0	    the peak intensity
	//w[2] = L            length of the sample in mm
	//w[3] = T            height of the beam
	//w[4] = td           height of the detector
	//w[5] = alpha offset

	variable result, ts, numerator, denominator,alpha
	make/n=3/o/d W_gausscoefs={1, 0, w[3]/2}
	
	alpha = x - w[5]
	
	ts = 0.5 * w[2] * abs(sin(alpha * Pi/180))
	numerator = integrate1D(myga, 0, ts)
	denominator = integrate1D(myga, 0, w[4]/2)

	result = w[0] + (w[1]/2) * (1-(numerator/denominator))

	return result
End

Function UserCursorAdjust(grfName)
	String grfName
	variable err = 0
	
	DoWindow/F $grfName		// Bring graph to front
	if (V_Flag == 0)		// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif

	NewPanel/K=2 /W=(139,341,382,432) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor		// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$grfName	// Put panel near the graph
	DrawText 21,20,"Adjust the cursors to set"
	DrawText 21,40,"crit edge level."
	Button button0,pos={5,64},size={92,20},title="Continue"
	Button button0,proc=UserCursorAdjust_ContButtonProc
	Button button1,pos={110,64},size={92,20},title="cancel",proc=UserCursorAdjust_cancButtonProc
	
	//this line allows the user to adjust the cursors until they are happy with the right level.
	//you then press continue to allow the rest of the reduction to occur.
	PauseForUser tmp_PauseforCursor,$grfName
	if(itemsinlist(winlist(grfname, ";", "")) == 0) 	//user pressed cancel
		err = 1
	endif
	
	return err
End

Function UserCursorAdjust_cancButtonProc(B_Struct) :Buttoncontrol 
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode == 2)
		DoWindow/K tmp_PauseforCursor	// Kill self
		Dowindow/K Setcriticaledge
	endif
End

Function UserCursorAdjust_ContButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode == 2)
		DoWindow/K tmp_PauseforCursor		// Kill self
	endif
End

Function SaveXraydata(tempy)
	String tempy
	string fname

	String w0,w1,w2,w3
	w0 = CleanupName((tempy + "_q"),0)
	w1 = CleanupName((tempy + "_R"),0)
	w2 = CleanupName((tempy + "_e"),0)
	w3 = CleanupName((tempy + "_dQ"),0)

	//the idea is that you can print to a wave, even if you don't have the full version of IGOR.
	//this gets the filename for writing. but doesn't actually open it.
	fname=DoSaveFileDialog_Xrayredn(tempy)
	if(strlen(fname)==0)
		ABORT
	endif
	variable refnum
	open refnum as fname

	wave dQ=$w3

	if(waveexists(dQ))
		wfprintf refnum, "%g \t %g \t %g \t %g \r",$w0,$w1,$w2,$w3	 //this prints the wave to file.
	else
		wfprintf refnum, "%g \t %g \t %g \r",$w0,$w1,$w2	//this prints the coefwave to file.
	endif

	close refnum
End

Function/S DoSaveFileDialog_Xrayredn(name)
	String name
	String msg="choose file name"
	Variable refNum
	String message = "Save the file as"
	String outputPath
	
	Open/D/M=msg refNum as name
	outputPath = S_fileName
	if(strlen(S_filename)==0)
		Dowindow/K Setcriticaledge
		ABORT
	endif
	return outputPath
End
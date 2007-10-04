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

	//load the datawaves
	loadwave/j/d/A/L={0,25,0,0,2}
	String filename = S_fileName

	if(V_Flag==0) //user pressed cancel
		ABORT
	endif

	//make the names of the datawaves something nicer. 
	String w0,w1,w2
	w0 = CleanupName((S_fileName + "q"),0)
	w1 = CleanupName((S_fileName + "R"),0)
	w2 = CleanupName((S_fileName + "e"),0)

	//you don't need to reduce the file if its already been done
	if(exists(w0) !=0)
		DoAlert 0,"This file has already been done"
		KillWaves $w0,$w1
		ABORT
	endif

	//rename the datasets in IGOR using the filename of the file you opened
	Rename wave0,$w0
	Rename wave1,$w1
	Duplicate $w1,$w2

	Wave q=$w0,R=$w1,dR=$w2

	//the error in reflectivity is the square root of the counts
	dR=sqrt(dR)

	//you need to know the wavelength
	Variable CuKa=1.541
	Prompt CuKa,"Wavelength"
	Doprompt "X-ray wavelength",CuKa
	if(V_Flag==1)
		abort
	endif

	variable ii
	doalert 2,"Perform a footprint correction (assumes 1/32 slit + no knife edge)?"
	switch(V_Flag)
		case 1:
			Variable footprint = 100
			Prompt footprint, "sample footprint (mm)"
			Doprompt "sample footprint correction",footprint
			if(V_Flag==1)
				abort
			endif
			variable beamarea
			for(ii=0;ii<numpnts(q);ii+=1)
				beamarea = 0.1/sin(Pi*q/180)
				if(beamarea>footprint)
					R*=(beamarea/footprint)
				endif
			endfor
		case 2:
			break
		case 3:
			abort
			break
	endswitch

	//definition of Q wave vector
	q = real(Moto_angletoQ(q,2*q,CuKa))

	//pull up a graph showiing the data, with the error bars
	Display/K=1 R vs Q
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

		UserCursorAdjust("Setcriticaledge")
		Variable scale=vcsr(A)
		Prompt scale, "critical edge scale value"
		Doprompt "critical edge scale value",scale
		if(V_flag==1)
			Dowindow/K Setcriticaledge
			abort
		endif 
		R/=scale
		dr/=scale
		Setaxis/A

		//you can continually adjust the lvel until you are happy with it.
		Doalert 1,"Is it good?"
		if(V_flag==1)
			allgood=1
		endif
		if(V_flag==3)
			Dowindow/K Setcriticaledge
			abort
		Endif

	while(allgood==0)

	//now save the data, works with the demo version of IGOR as well.
	SaveXraydata(filename)
	Dowindow/K Setcriticaledge
End

Function UserCursorAdjust(grfName)
	String grfName

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

	return 0
End

Function UserCursorAdjust_cancButtonProc(ctrlName) :Buttoncontrol 
	String ctrlName
	DoWindow/K tmp_PauseforCursor	// Kill self
	Dowindow/K Setcriticaledge
	ABORT
End

Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K tmp_PauseforCursor		// Kill self
End

Function SaveXraydata(tempy)
	String tempy
	string fname

	String w0,w1,w2,w3
	w0 = CleanupName((tempy + "q"),0)
	w1 = CleanupName((tempy + "R"),0)
	w2 = CleanupName((tempy + "e"),0)
	w3 = CleanupName((tempy + "dQ"),0)

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

Function ReduceNeutrons()
	//load the datawaves
	loadwave/j/d/A/L={0,3,0,0,9}
	String filename = S_fileName
	filename=filename[0,strlen(filename)-5]+"r.txt"

	if(V_Flag==0) //user pressed cancel
		ABORT
	endif

	//you need to know the wavelength
	Variable lambda=2.43,monbkg=0.77,bkg=0
	Prompt lambda,"Wavelength"
	Prompt monbkg,"monitor background,cps"
	Prompt bkg,"detector background, cps"
	Doprompt "instrument details",lambda,monbkg,bkg
	if(V_flag==1)
		abort
	endif

	//make the names of the datawaves something nicer. 
	String w0,w1,w2,w3
	w0 = CleanupName((fileName + "q"),0)
	w1 = CleanupName((fileName + "R"),0)
	w2 = CleanupName((fileName + "e"),0)
	w3 = CleanupName((fileName + "dQ"),0)

	//you don't need to reduce the file if its already been done
	if(exists(w0) !=0)
		DoAlert 0,"This file has already been done"
		KillWaves wave0,wave1,wave2,wave3,wave4,wave5,wave6,wave7,wave8
		ABORT
	endif

	Duplicate wave0,$w0
	Duplicate wave1,$w1
	Duplicate wave1,$w2
	Duplicate wave1,$w3

	Wave q=$w0,R=$w1,dR=$w2,dQ=$w3

	Wave wave0,wave1,wave2,wave3,wave4,wave5,wave6,wave7,wave8
	R=(wave1-(wave4*bkg))/((wave3-(wave4*monbkg)))

	q = real(Moto_angletoQ(wave8,2*wave8,lambda))

	//the error in reflectivity is the square root of the counts
	dR=sqrt(wave1-(wave4*bkg))/((wave3-(wave4*monbkg)))

	//dQ is the FWHM of the gaussian resolution function
	dQ=Q*sqrt((((180*atan((wave5/2+wave6/2)/1271)/Pi)/wave8)^2)+((0.05/lambda)^2))

	//pull up a graph showiing the data, with the error bars
	Display/K=1 R vs Q
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

		UserCursorAdjust("Setcriticaledge")
		Variable scale=vcsr(A)
		Prompt scale, "critical edge scale value"
		Doprompt "critical edge scale value",scale 
		if(V_flag==1)
			Dowindow/K Setcriticaledge
			abort
		endif

		R/=scale

		dR=(1/scale)*sqrt(wave1-(wave4*bkg))/((wave3-(wave4*monbkg)))
		Setaxis/A

		//you can continually adjust the lvel until you are happy with it.
		Doalert 1,"Is it good?"
		if(V_flag==1)
			allgood=1
		endif
		if(V_flag==3)
			Dowindow/K Setcriticaledge
			abort
		Endif
	while(allgood==0)

	//if you also want to add in dQ
	//ActiveCell.Range("n4").Formula = "=k4*SQRT((((180*ATAN((f4/2+g4/2)/1271)/Pi())/i4)^2)+((0.05/o$1)^2))"
	//With ActiveSheet
	//    .Range("n4").Copy
	//    .Paste Destination:=.Range([n5], [m65536].End(3)(1, 2))
	//End With

	killwaves/z wave0,wave1,wave2,wave3,wave4,wave5,wave6,wave7,wave8
	//now save the data, works with the demo version of IGOR as well.
	SaveXraydata(filename)
	Dowindow/K Setcriticaledge
End

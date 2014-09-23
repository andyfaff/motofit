#pragma rtGlobals=3		// Use modern global access method.
#pragma IgorVersion = 6.22
#pragma modulename = Pla_Xrayreduction
// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

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

static constant XRR_BEAMWIDTH_SD = 0.019449 //mm

static Function reduceXpertPro(ref_fname, [bkg1,bkg2, scalefactor, footprint])
	string ref_fname, bkg1, bkg2
	variable scalefactor, footprint

	string base, w0,w1,w2, w3	, directory=""
	string cDF = getdatafolder(1)
	string namespace = "xrdml=http://www.xrdml.com/XRDMeasurement/1.0"
	variable fileID, bkg1_fileID, bkg2_fileID, err = 0, err2 = 0, saveID = 0
	Variable CuKa, CuKa1,CuKa2,ratio, countTime
	variable start,stop, ii,  w_HWHM_direct_beam
	variable t_m = 0.108	//value at which the beam falls to zero
	variable T_r = 0.0365		//real thickness of the beam at the sample location
	
	Newdatafolder/o root:packages
	Newdatafolder /o/s root:packages:Xpert

	try
		base = parsefilepath(3, ref_fname, ":", 0, 0)
		base = cleanupname(base, 0)
		
		directory = ParseFilePath(1, ref_fname, ":", 1, 0)

		//make the names of the datawaves something nicer. 
		w0 = CleanupName((base + "_q"),0)
		w1 = CleanupName((base + "_R"),0)
		w2 = CleanupName((base + "_e"),0)
		w3 = CleanupName((base + "_dq"),0)

		//open the XML file
		fileID = xmlopenfile(ref_fname)
		if(! (fileID  > 0))
			print "The file you tried to open didn't exist: ", ref_fname, " (reduceXpertPro)"
			abort
		endif

		//now need to load in the data for the reflected intensity and the background intensities
		if(xmlwavefmxpath(fileID,"//xrdml:intensities",namespace," \n\r\t"))
			print "ERROR while loading intensities, is this an XRDML file?  (reduceXpertPro)"
			abort
		endif
		Wave/t M_xmlcontent
		make/o/d/n=(dimsize(M_xmlcontent,0)) $w0, $w1, $w2, $w3, bkg_I=0, bkg_SD=0
		Wave qq = $w0, RR = $w1, dR = $w2, dq = $w3
	
		RR = str2num(M_xmlcontent)
		dR = sqrt(RR)
		countTime = str2num(XMLstrFmXpath(fileID,"//xrdml:commonCountingTime",namespace,""))
		RR /= countTime
		dR /=countTime
		
		//load the background files
		if(!paramisdefault(bkg1) && strlen(bkg1))
			bkg1_fileID = xmlopenfile(bkg1)
			if(bkg1_fileID < 1)
				print "ERROR you tried to open a non-existent background file (reduceXpertPro)"
				abort
			endif
			if(xmlwavefmxpath(bkg1_fileID,"//xrdml:intensities",namespace," \n\r\t"))
				print "ERROR while loading intensities, is this an XRDML file?  (reduceXpertPro)"
				abort
			endif
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) bkg1_I, bkg1_SD
			bkg1_I = str2num(M_xmlcontent)
			bkg1_SD = sqrt(bkg1_I)
			if(numpnts(RR) != numpnts(bkg1_I))
				print "ERROR background run and specular run must have the same number of points (reduceXpertPro)"
			endif
			countTime = str2num(XMLstrFmXpath(bkg1_fileID, "//xrdml:commonCountingTime", namespace, ""))
			bkg_I += bkg1_I/ countTime
			bkg_SD += (bkg1_SD / countTime)^2
		endif

		if(!paramisdefault(bkg2) && strlen(bkg2))
			bkg2_fileID = xmlopenfile(bkg2)
			if(bkg2_fileID < 1)
				print "ERROR you tried to open a non-existent background file (reduceXpertPro)"
				abort
			endif
			if(xmlwavefmxpath(bkg2_fileID,"//xrdml:intensities",namespace," \n\r\t"))
				print "ERROR while loading intensities, is this an XRDML file?  (reduceXpertPro)"
				abort
			endif
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) bkg2_I, bkg2_SD
			bkg2_I = str2num(M_xmlcontent)
			bkg2_SD = sqrt(bkg2_I)
			if(numpnts(RR) != numpnts(bkg2_I))
				print "ERROR background run and specular run must have the same number of points (reduceXpertPro)"
			endif
			countTime = str2num(XMLstrFmXpath(bkg2_fileID, "//xrdml:commonCountingTime", namespace, ""))
			bkg_I += bkg2_I/ countTime
			bkg_SD += (bkg2_SD / countTime)^2
		endif				
		//do the background subtraction
		if(bkg2_fileID > 0 || bkg1_fileID > 0)
			if(bkg2_fileID>0 && bkg1_fileID>0)
				bkg_I /=2
				bkg_SD /=2
			endif
			RR -= bkg_I
			dR = sqrt(dR^2 + bkg_SD)
		endif

		start = str2num(xmlstrfmxpath(fileID,"//xrdml:dataPoints/xrdml:positions[2]/xrdml:startPosition/text()",namespace," "))
		stop = str2num(xmlstrfmxpath(fileID,"//xrdml:dataPoints/xrdml:positions[2]/xrdml:endPosition/text()",namespace," "))
		qq = start + p*(stop-start)/(numpnts(qq)-1)	
		CuKa1 = str2num(xmlstrfmxpath(fileID,"//xrdml:kAlpha1/text()",namespace," "))
		CuKa2 = str2num(xmlstrfmxpath(fileID,"//xrdml:kAlpha2/text()",namespace," "))
		ratio = str2num(xmlstrfmxpath(fileID,"//xrdml:ratioKAlpha2KAlpha1/text()",namespace," "))
		CuKa = (CuKa1+ratio*CuKa2)/(1+ratio)

		if(paramisdefault(footprint))
			doalert 2,"Perform a footprint correction (assumes 1/32 slit + no knife edge)?"
			switch(V_Flag)
				case 1:
					footprint = 100
					Prompt footprint, "sample footprint (mm)"
					Doprompt "sample footprint correction", footprint
					if(V_Flag == 1)
						abort
					endif
					break
				case 2:
					footprint = NaN
					break
				case 3:
					killwaves/z M_xmlcontent,W_xmlcontentnodes
					abort
					break
			endswitch
		endif
		
		if(!numtype(footprint))		
			if(footprint <0 || footprint>100)
				print "ERROR footprint value is crazy (reduceXpertPro)"
			endif	
			make/n=(numpnts(qq))/d/free probability
			probability = footprint_correction(qq[p], XRR_BEAMWIDTH_SD, footprint)
			RR[] /= probability[p]
			dR[] /= probability[p]
		endif
		
		//make the dq wave
		//correction taken from Gibaud et al., Acta Crystallographica, A49, 642-648
		w_HWHM_direct_beam = 0.025*(Pi/180)
		dq = 2* (2*Pi/CuKa)* w_HWHM_direct_beam * cos(qq * Pi/180)

		//definition of Q wave vector
		qq = real(Moto_angletoQ(qq, 2*qq, CuKa))
		
		if(paramisdefault(scalefactor))
			//pull up a graph showiing the data, with the error bars
			Display/K=1 RR vs QQ
			Modifygraph log(left)=1,mode=3
			ErrorBars $w1 Y,wave=($w2,$w2)
			Doupdate

			//rename the graph, and put a freely moving cursor on the graph.
			string Rwav=nameofwave(RR)
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
				err2 = UserCursorAdjust("Setcriticaledge")
				if(err2 == 1)
					Dowindow/K Setcriticaledge
					killwaves/z RR,qq,dR,M_xmlcontent,W_xmlcontentnodes,R,qq,dR, dq
					abort
				endif
		
				scalefactor=vcsr(A)
				Prompt scalefactor, "critical edge scale value"
				Doprompt "critical edge scale value",scalefactor
				if(V_flag==1)
					Dowindow/K Setcriticaledge
					abort
				endif 
				RR /= scalefactor
				dR /= scalefactor
				allGood = 1
				//				Setaxis/A
				//				Doupdate
				//				//you can continually adjust the lvel until you are happy with it.
				//				Doalert 1,"Is it good?"
				//				if(V_flag==1)
				//					allgood=1
				//				endif
				//				if(V_flag==3)
				//					Dowindow/K Setcriticaledge
				//					abort
				//				Endif
			while(allgood==0)
			Dowindow/K Setcriticaledge
			print "Scalefactor for ", base, " is ", scalefactor
		else
			RR /= scalefactor
			dR /= scalefactor
		endif
	catch
		err = 1
	endtry
	
	if(fileID>0)
		xmlclosefile(fileID, 0)
	endif
	if(bkg1_fileID>0)
		xmlclosefile(bkg1_fileID, 0)
	endif
	if(bkg2_fileID>0)
		xmlclosefile(bkg2_fileID, 0)
	endif
	
	if(!err)
		open saveID as directory + base + ".dat"
		wfprintf saveID, "%g \t %g \t %g \t %g \n", qq, rr, dr, dq	 //this prints the wave to file.
		close saveID	
		Wave/z dummyres
		writeSpecRefH5_1D(directory, base, qq, RR, dR, dQ, resolutionkernel = dummyres)
	endif

	setdatafolder $cDF
	return err
End

static Function myga(xx)
	variable xx
	Wave W_gausscoefs
	return W_gausscoefs[0]*exp(-0.5*((xx-W_gausscoefs[1])/W_gausscoefs[2])^2)
End

Function footprint_correction(angle, beamwidth_sd, sample_length)
	variable angle, beamwidth_sd, sample_length
	//angle - angle of incidence in degrees
	//beamwidth_sd - sd of a gaussian distributed beam
	//sample_length - length of sample
	//you must use the same units for beamwidth_sd and sample_length

	variable sample_height, probability
	sample_height = sample_length * sin(angle * pi / 180.)
	probability = 2 * (statsnormalcdf(sample_height / 2, 0, beamwidth_sd) - 0.5)
	return probability
End

static Function UserCursorAdjust(grfName)
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
	Button button0,proc=Pla_Xrayreduction#UserCursorAdjust_ContButtonProc
	Button button1,pos={110,64},size={92,20},title="cancel",proc=Pla_Xrayreduction#UserCursorAdjust_cancButtonProc
	
	//this line allows the user to adjust the cursors until they are happy with the right level.
	//you then press continue to allow the rest of the reduction to occur.
	PauseForUser tmp_PauseforCursor,$grfName
	if(itemsinlist(winlist(grfname, ";", "")) == 0) 	//user pressed cancel
		err = 1
	endif
	
	return err
End

static Function UserCursorAdjust_cancButtonProc(B_Struct) :Buttoncontrol 
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode == 2)
		DoWindow/K tmp_PauseforCursor	// Kill self
		Dowindow/K Setcriticaledge
	endif
End

static Function UserCursorAdjust_ContButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode == 2)
		DoWindow/K tmp_PauseforCursor		// Kill self
	endif
End

static Function/S DoSaveFileDialog_Xrayredn(name)
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
`
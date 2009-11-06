#pragma rtGlobals=1
#pragma IGORVersion=5.02
	constant kMotoToImag=0
	
// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

	// Use modern global access method.
	///MOTOFIT is a program that fits neutron and X-ray reflectivity profiles :written by Andrew Nelson
	//Copyright (C) 2005 Andrew Nelson and Australian Nuclear Science and Technology Organisation
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


	//MOTOFIT uses the Abeles or Parratt formalism to calculate the reflectivity.
	//MOTOFIT is a powerful tool for Co-refining multiple contrast datasets from the same sample.
	//The software should be compatible with Macintosh/PC/NT platforms and requires that IGOR Pro* is installed. 
	//You do not have to purchase IGOR Pro - a free demo version of IGOR Pro is available, however some utilities are disabled (such as copying to/from the clipboard)
	//IGOR Pro is a commercial software product available to Mac/PC/NT users. 
	//A free demo version of IGOR is available from WaveMetrics Inc. These experiments and procedures were created using IGOR Pro 5.04
	//The routines have not been tested on earlier versions of IGOR.


Menu "Motofit"
	//this function sets up the user menus at the top of the main IGOR window.
	"-"
	"Fit Reflectivity data",plotCalcref()
	"Load experimental data",Moto_loaddata()
	"Change Q range of theoretical data", Moto_changeQrangeprompt()
	"SLD calculator", Moto_SLDdatabase()
	"create local chi2map for requested parameter",Moto_localchi2()
	Submenu "Fit batch data"
		"Load batch data", LoadAndGraphAll ("")
		"Fit batch data", FitRefToListOfWaves()
		//	                        "Extract trends", Trends()
	End
	"About",Moto_AboutPanel()
	"-"
End

Function/s Moto_Dummymotofitstring()
	SVAR/Z motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	string dummystring
	dummystring="Motofitcontrol:;plotyp:1;SLDpts:500;res:0;usedqwave:0;useconstraint:0;fitcursors:0;holdstring:;"
	dummystring+="dataset:;useerrors:;coefwave:;V_chisq:;"
	dummystring+="SLDtype:neutron;multilayer:0;Vmullayers:0;mulrep:0;mulappend:0;inFIT:0;:4;baselength:6"
	return dummystring
End

Function plotCalcref()
	//this function starts the reflectivity panel, which is the UI for doing the fitting
	String temp=Winlist("reflectivitypanel","","")
	if(strlen(temp)>0)
		return 0
	endif
	setdatafolder root:
	//make the reflectivity datafolders
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o root:packages:motofit:reflectivity:tempwaves
	
	Variable num=500,qmin=0.005,qmax=0.5,res=5,SLDplotnum=500,plotyp=1
	Prompt num, "Enter number of data points for model: "
	Prompt qmin, "Enter minimum q-value (A^-1) for model: "
	Prompt qmax, "Enter maximum q-value (A^-1) for model: "
	Prompt res, "Enter %resolution (dq/q): "
	Prompt SLDplotnum, "How many points do you want in the SLD plot"
	Prompt plotyp,"Which plot mode?",popup,"logR vs Q;R vs Q;RQ4 vs Q"
	Doprompt "enter plot parameters",num,qmin,qmax,res,SLDplotnum,plotyp
	
	//if the user doesn't want to continue with the plotting then abort
	if(V_flag==1)
		abort
	endif
	
	//Motofitcontrol is a global string that we will use to control how the program works.
	String/G root:packages:motofit:reflectivity:Motofitcontrol
	SVAR/z motofitcontrol = root:packages:motofit:reflectivity:Motofitcontrol
	Motofitcontrol = Moto_dummymotofitstring()
	
	Moto_repstr("res",num2str(res))
	Moto_repstr("SLDpts",num2str(SLDplotnum))
	Moto_repstr("plotyp",num2istr(plotyp))
	
	//plotyp=1 means logR vs Q, plotyp=2 means R vs Q, plotyp=3 means RQ4 vs Q
	//res is constant resolution dq/Q
	//usedqwave=0 means that constant dq/q is used. usedqwave=1 means a user defined dQ wave is used.
	//useconstraint=1 means use a constraint wave 
	//fitcursors=1 means fit between the cursors
	//userrors=1 means use the errors while fitting
	//V_chisq is the last Chi squared value 
	
	Variable SLDpts=str2num(Moto_str("SLDpts"))
		
	Variable logg
	switch(plotyp)
		case 1:
			logg=0	
			break
		case 2:
			logg=1
			break
		case 3:
			logg=0
			break
	endswitch

	//this variable is for a running total of the Chisquared value for the dataset that is in focus
	Variable/g root:packages:motofit:reflectivity:chisq	
		
	make/o/d/n=(num) theoretical_q,theoretical_R
	setscale/P x,qmin,((qmax-qmin)/num), theoretical_R
	make/o/d/n=(SLDpts) zed,sld

	//This section pulls up a graph with the reflectivity in it, and a table containing the reflectivity parameters	
	theoretical_q = qmin+(x)*((qmax-qmin)/num)
	make/o/d/n=10 coef_Cref={1,1,0,2.07,1e-7,4,25,3.47,0,4}
	
	note coef_Cref,motofitcontrol
	
	make/o/t/n=10 parameters_Cref={"Numlayers","scale","SLDtop","SLDbase","bkg","sigma_base","thick1","SLD1","solv1","rough1"}
	make/o/n=1 resolution={res}

	//this puts all the parameters in a nice convenient panel
	Moto_Reflectivitypanel()
	
	//this puts sane values in the waves
	Moto_CrefToLayerTable()
	
	//calculate the reflectivity
	Moto_update()

	//this calculates the FT of the theoretical data
	Moto_FTreflectivity()	
	//add in the FFT of the data to the panel
	Display/HOST=#/N=FFTplot /W=(230,450,620,620) root:packages:motofit:reflectivity:tempwaves:FFToutput
	Label/W=reflectivitypanel#FFTplot bottom "size /A"
	Legend/W=reflectivitypanel#FFTplot /C/N=text0/J/F=0/A=MC "\\s(FFToutput) Fourier transform of selected dataset"	
	cursor /F/P/S=2 /H=1/W=reflectivitypanel#FFTplot A FFToutput 0.5,0.5
	Setwindow reflectivitypanel, hook(FTplot)=Moto_FTplothook
	SetWindow reflectivitypanel#fftplot, hook(FTplot)=Moto_FTplothook,hookevents=7
	STRUCT WMWinHookStruct s
	s.eventcode=7
	s.pointnumber=0.5
	Moto_FTplotHook(s)
	setactivesubwindow reflectivitypanel
	
	//make sure the FT graph is displayed first
	STRUCT WMTabControlAction TC_Struct
	TC_Struct.tab = 0
	moto_thicknesstabProc(TC_Struct)
	
	//make a nice graph
	if(!itemsinlist(winlist("reflectivitygraph", ";", "WIN:1")))
		Display/K=1/N=reflectivitygraph/w=(10,10,550,350) theoretical_R vs theoretical_q
		controlbar/T/W=reflectivitygraph 35
		PopupMenu plottype,pos={140,6},size={220,21},proc=Moto_Plottype,title="Plot type"
		PopupMenu plottype,mode=plotyp,bodyWidth= 100,value= #"\"logR vs Q;R vs Q;RQ4 vs Q\""
		Button Autoscale title="Autoscale",size={80,24},pos={12,7},proc=Moto_genericButtonControl,fsize=10
		Button ChangeQrange title="Q range",proc=Moto_genericButtonControl,size={100,24},fsize=10
		Button Snapshot title="snapshot",proc=Moto_genericButtonControl,size={70,24},pos={380,6},fsize=10
		Button restore title="restore",proc=Moto_genericButtonControl,size={70,24},pos={460,6},fsize=10
		
		Label bottom "Q /A\\S-1\\M"
		Label left "R"
		ModifyGraph log(bottom)=0,mode=0
		ModifyGraph log(left)=(logg)
		DoWindow/T reflectivitygraph,"reflectivity graph"
		Display/Host=#/N=SLDplot/W=(0.6,0,1,0.5) sld vs zed

		//This section pulls up a graph of the (real SLD profile). 
		// It automatically updates whenever you change the fit parameters
		
		Label left "\Z08\\f02\\F'Symbol'r\\F'Arial'   \\f00/10\\S-6\\M Å\\S-2 "
		ModifyGraph lblPos(left)=42; 
		Modifygraph fSize(left)=8
		Label bottom "\Z06<<-- TOP          \Z08z /�       \Z06 BOTTOM-->>"
		ModifyGraph lblPos(bottom)=30; 
		Modifygraph fSize(bottom)=8
		Modifygraph rgb(sld)=(0,0,52224)
		Setactivesubwindow Reflectivitygraph
	endif

	//start up the SLD database and populate it with a specific database in igorpro/motofit
	Moto_SLDdatabase()

	//bring the reflectivity graph and panel to the front
	Dowindow/F reflectivitypanel
	Dowindow/F reflectivitygraph
	Autopositionwindow/m=1/R=reflectivitygraph reflectivitypanel
End

Function Moto_genericButtonControl(B_Struct)
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode!=2)
		return 0
	endif
	
	strswitch(B_Struct.ctrlname)
		case "ChangeQrange":
			Moto_changeQrangeprompt()
			break
		case "restore":
			moto_restoremodel()
			break
		case "snapshot":
			string ywave ="",xwave="",sldwave="",zedwave=""
			if(!Moto_snapshot(ywave, xwave, sldwave, zedwave))
				if(Findlistitem(ywave,tracenamelist("reflectivitygraph",";",1))==-1)
					appendtograph/w=reflectivitygraph $("root:"+ywave) vs $("root:"+xwave)
				endif
				if(Findlistitem(sldwave,tracenamelist("reflectivitygraph#SLDplot",";",1))==-1)
					appendtograph/w=reflectivitygraph#sldplot $("root:"+sldwave) vs $("root:"+zedwave)
				endif
				Legend/C/N=text0/A=MC
			endif
			break
		case "croppanel":
			moto_croppanel()
			break
		case "Autoscale":
			Setaxis/A/W=reflectivitygraph
			break
		case "loaddatas":
			SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol

			variable plotyp
			//if the program control string doesn't exist then make logR vs Q the default
			if(SVAR_exists(motofitcontrol)==0)
				plotyp=1
			else
				plotyp=str2num(moto_str("plotyp"))		
			endif

			//this function loads the data into IGOR.
			//the plot will try to append the loaded data to the first graph.
			String graph=StringFromList(0, WinList("*", ";", "WIN:1"))
			if(strlen(graph)>0)
				Dowindow/F $graph
			endif
			Moto_Plotreflectivity()
			break
		case "dofit":
			//start a report notebook for the fitting
			string notebooklist = Winlist("Reflectivityfittingreport",";","Win:16")
			if(itemsinlist(notebooklist)==0)
				Moto_initialiseReportNotebook()
			endif
	
			Controlinfo/W=reflectivitypanel Typeoffit
			strswitch (S_Value)
				case "Genetic":
					Moto_fit_Genetic()
					break
				case "Levenberg-Marquardt":
					Moto_fit_Levenberg()
					break
				case "Genetic + LM":
					Moto_fit_GenLM()
					break
				case "Genetic+MC_Analysis":
					Moto_fit_GenMC()
					break
			endswitch
			break
		case "loadcoefwave":
			SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
			Loadwave/O/T
			if(V_flag==0)
				abort
			endif
			String coefwave=removeending(S_Wavenames)
			String temp=note ($coefwave)
			String coefnote = Moto_dummymotofitstring()
	
			variable ii=0
			//search through motofitstring and add the bits that are missing.
			for(ii=0;ii<itemsinlist(coefnote);ii+=1)
				string item = stringfromlist(ii,coefnote,";")
				item = stringfromlist(0,item,":")
				if(strlen(stringbykey(item,temp,":", ";"))==0) // default isn't present
					temp = replacestringbykey(item,temp,stringbykey(item,motofitcontrol,":",";"))
				endif
			endfor
	
			note/k $coefwave
			note $coefwave,temp
			break
	endswitch
	
	return 0
End

Function Moto_snapshot(ywave,xwave,sldwave,zedwave)
	string &ywave,&xwave,&sldwave,&zedwave
	
	string snapStr = "snapshot"
	prompt snapStr, "Name: "

	do
		doprompt "Enter a unique name for the snapshot", snapstr
		if(V_flag)
			return 1
		endif
		ywave = cleanupname(snapstr+"_R",0)
		xwave = cleanupname(snapstr+"_q",0)
		sldwave = cleanupname("SLD_"+snapstr,0)
		zedwave = cleanupname("zed_"+snapstr,0)
		
		if(checkname(ywave,1) || checkname(xwave,1) || checkname(sldwave,1) || checkname(zedwave,1))
			Doalert 2, "One of the snapshot waves did not have a unique name, did you want to overwrite it?"
			if(V_Flag == 1)
				break
			elseif(V_Flag == 2)
				continue
			elseif(V_Flag == 3)
				return 0
			endif
		else
			break
		endif
	while(1)

	Duplicate/o root:theoretical_R, root:$ywave
	Duplicate/o root:theoretical_q, root:$xwave
	Duplicate/o root:sld, root:$sldwave
	Duplicate/o root:zed, root:$zedwave
	setformula root:$sldwave,""
	
	return 0
End

Function Moto_changeQrangeprompt()
	Wave localref_R=root:theoretical_R,localref_Q=root:theoretical_Q
	Variable num=numpnts(localref_R),qmin=localref_q[0],qmax=localref_q[numpnts(localref_q)-1]
	Prompt num, "Enter number of data points for model: "
	Prompt qmin, "Enter minimum q-value (A^-1) for model: "
	Prompt qmax, "Enter maximum q-value (A^-1) for model: "
	Doprompt "enter new plot parameters",num,qmin,qmax
	//if the user doesn't want to continue with changes then abort
	if(V_flag==1)
		Abort
	endif
	Moto_ChangetheoreticalQrange(num,qmin,qmax)
End

Function Moto_changeTheoreticalQrange(num,qmin,qmax)
	variable num,qmin,qmax
	if(qmin==0)
		qmin=1e-5
	endif
	
	make/o/d/n=(num) root:theoretical_q,root:theoretical_R
	setscale/P x,qmin,((qmax-qmin)/num), theoretical_R
	Wave theoretical_Q=root:theoretical_Q
	theoretical_q = qmin+(x)*((qmax-qmin)/num)
	Moto_update()
End

Function Moto_UpdateR(SV_Struct)
	STRUCT WMSetVariableAction &SV_Struct
	if(SV_Struct.eventcode==-1)
		return 0
	endif
	Moto_update()
End

Function Moto_update()
	//update is a function that makes sure that the theoretical graph of reflectivity
	//and SLD profile is kept up to date.  It should be called if any of the parameters change.
	string saveDF=getdatafolder(1)
	
	Setdatafolder root:
	Wave/z coef_Cref,theoretical_R,theoretical_q,multikernel,multilay,SLD,zed,coef_multiCref
	
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:Motofitcontrol
	//make sure that we're not in a fit
	moto_repstr("inFIT","0")

	Variable multilayer=str2num(Moto_str("multilayer"))
	if (multilayer==0)    //the situation where you're not simulating a multilayer
		NVAR/z Vmullayers = root:packages:motofit:reflectivity:tempwaves:Vmullayers
		
		Vmullayers=0		//you have no multilayers if you're not simulating a multilayer.
		//program will fall over if Vmullayers is not equal to zero.
		
		Motofit(coef_Cref,theoretical_R,theoretical_Q)
		Setformula SLD,"Moto_SLDplot(coef_Cref,zed)"
	else
		Createmultilayer(coef_Cref,multilay)    //the situation when you have a multilayer
		Kerneltransformation(coef_multicref)
		Motofit(coef_multiCref,theoretical_R,theoretical_Q)
		Setformula SLD,"Moto_SLDplot(multikernel,zed)"
	endif
	
	//if you change the model, then you may need to update the FFT of the theoretical curve
	Moto_FTreflectivity()
	
	//update Chisquared value
	//this also has the effect of re-calculating the theoretical curve
	Moto_Chi2_print()
	
	setdatafolder $saveDF
End

Function Motofit(w,y,z) :Fitfunc
	Wave w,y,z
	//NOTE the "Z" wave is really the x data in disguise
	//This fit function calls either Parratt- or Abeles-reflectivity, and integrates over a gaussian beam profile. 
	// Knowledge of dq/q is required.
	
	//Createmotofitwaves() should be called before the fitfunction is used!
	
	//Wouldn't be difficult at all to modify users different resolution function
	//This is where the user should set up their own SLD profile
	String savedDataFolder = GetDataFolder(1)		
	try
		//if this datafolder exists then it is likely that the tempwaves have been made.
		//if it hasn't then make the waves necessary for Motofit to start
		if(!datafolderexists("root:packages:motofit:reflectivity:tempwaves"))
			Moto_createmotofitwaves(w) 
		endif
			
		SVAR/z motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	
		Variable bkg
	
		Variable plotyp=numberbykey("plotyp",motofitcontrol)
		variable inFIT=numberbykey("inFIT",motofitcontrol)
		Variable res=numberbykey("res",motofitcontrol)
		variable usedqwave=numberbykey("usedqwave",motofitcontrol)
		
		string dQwave=cleanupname(removeending(moto_str("dataset"))+"dq",0)
		dQwave = "root:packages:motofit:reflectivity:temp_dq"	
		Wave/z dQ=$dQwave
	
		//if you're not FITTING, then just use constant dQ/Q
		if(inFIT==0)
			usedqwave=0
		endif

		//don't want to convolve the reflectivity if the background has been added
		bkg=abs(w[4])
		w[4]=0

		//you have to set this datafolder because V_mulrep, V_appendlayer, V_numlayers are held in this folder!
		setdatafolder root:packages:motofit:reflectivity:tempwaves
		
		switch(usedqwave)
			case 0:					//case 0 is if usedqwave=0.  This means the user hasn't selected a dQ wave
				res=(res/100)
				if (res<0.005)		//if the resolution is less that 1% don't bother doing the convolution
					Abelesall(w,y,z)
				else				//calculate the resolution with a convolution
					//by varying gaussnum you control the accuracy of the interpolation.  Higher=more accurate but a lot slower.
					//make it an odd number
					Variable gaussnum=13

					Make/o/d/n=(gaussnum) root:packages:motofit:reflectivity:tempwaves:gausswave
					Wave gausswave = root:packages:motofit:reflectivity:tempwaves:gausswave
					Setscale/I x,-res,res,gausswave
					Gausswave=gauss(x,0,res/(2*sqrt(2*ln(2))))
					Variable middle=gausswave[x2pnt(gausswave,0)]
					Gausswave/=middle
				
					Variable gaussgpoint=(gaussnum-1)/2
				
					//find out what the lowest and highest qvalue are
					Wavestats/Q/Z/M=1 z
					variable lowQ = V_min , highQ = V_max
					if(lowQ==0)
						lowQ=1e-6
					endif
					Variable start=log(lowQ)-8*res/2.35482
					Variable finish=log(highQ*(1+8*res/2.35482))
					Variable interpnum=round(abs(1*(abs(start-finish))/(res/2.35482/gaussgpoint)))
					make/o/d/n=(interpnum) root:packages:motofit:reflectivity:tempwaves:logxtemp
					make/o/d/n=(interpnum) root:packages:motofit:reflectivity:tempwaves:ytemp
					make/o/d/n=(interpnum) root:packages:motofit:reflectivity:tempwaves:xtemp
					Wave logxtemp = root:packages:motofit:reflectivity:tempwaves:logxtemp
					Wave xtemp = root:packages:motofit:reflectivity:tempwaves:xtemp
					Wave ytemp = root:packages:motofit:reflectivity:tempwaves:ytemp
				
					logxtemp=(start)+p*(abs(start-finish))/(interpnum)
					xtemp=alog(logxtemp)

					//calculate the theoretical curve with a lot of datapoints	
					AbelesAll(w, ytemp, xtemp)
						
					//do the resolution convolution
					setscale/I x,start,logxtemp[numpnts(logxtemp)-1],ytemp
					convolve/A gausswave ytemp
		
					//delete start and finish nodes.
					variable number2d=round(6*(res/2.35482)/((abs(start-finish))/(interpnum)))-1
					variable left=leftx(ytemp),space=deltax(ytemp)
					deletepoints 0,number2d,ytemp
					setscale/P x,left+(number2d*space),space, ytemp
					//variable right=numpnts(ytemp)
					//deletepoints (right-number2d),right,ytemp
				
					variable gaussum=1/(sum(gausswave))
					fastop ytemp=(gaussum)*ytemp
					duplicate/o z, root:packages:motofit:reflectivity:tempwaves:xrtemp
					duplicate/o z, root:packages:motofit:reflectivity:tempwaves:ytemp2
					Wave ytemp2 = root:packages:motofit:reflectivity:tempwaves:ytemp2, xrtemp =  root:packages:motofit:reflectivity:tempwaves:xrtemp
				
					xrtemp=log(xrtemp)
					//interpolate to get the theoretical points at the same spacing of the real dataset
					Interpolate2/T=2/N=1000/E=2/I=3/Y=ytemp2/X=xrtemp ytemp
					y=ytemp2
				endif
				break
			case 1:			//if usedqwave=1 then this means the user has selected his own resolution wave (requires 4 column data) 
				make/o/n=(13 * dimsize(z, 0)) root:packages:motofit:reflectivity:tempwaves:ytemp, root:packages:motofit:reflectivity:tempwaves:xtemp
				make/o/n=13  root:packages:motofit:reflectivity:tempwaves:x13,  root:packages:motofit:reflectivity:tempwaves:w13
				Wave xtemp = root:packages:motofit:reflectivity:tempwaves:xtemp, ytemp = root:packages:motofit:reflectivity:tempwaves:ytemp
				Wave x13 = root:packages:motofit:reflectivity:tempwaves:x13, w13 = root:packages:motofit:reflectivity:tempwaves:w13				
				y=0
				x13 = {-0.849322,-0.707768,-0.566215,-0.424661,-0.283107,-0.141554,0,0.141554,0.283107,0.424661,0.566215,0.707768,0.849322}
				w13={0.13534,0.24935,0.4111,0.60653,0.80074,0.94596,1,0.94596,0.80074,0.60653,0.4111,0.24935,0.13534}
				
				xtemp[] = x13[mod(p,13)] * dq[floor(p/13)]+z[floor(p/13)]
				Abelesall(w,ytemp,xtemp)
				ytemp *= w13[mod(p,13)]
				y[] = sum(ytemp, 13 * p, 13 * (p+1) -1)
				 
				fastop y = 0.137023*y
				break
		endswitch
		//add in the linear background again
		y=abs(y)
		w[4]=bkg
		fastop y=(bkg) + y
		//how are you fitting the data?
		switch(plotyp)	
			case 1:	
				y=log(y)
				//	MatrixOP/O y=log(abs(y)+bkg)
				break
			case 2:
				//MatrixOP/O y=(abs(y)+bkg)
				break
			case 3:
				y=(y*z^4)
				//MatrixOP/O y=((abs(y)+bkg)*z*z*z*z)
				break
			default:	
		endswitch
	catch
	endtry
	SetDataFolder savedDataFolder
End

Function Moto_createmotofitwaves(w)
	Wave w
	variable nlayers=w[0]
	
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o root:packages:motofit:reflectivity:tempwaves
	
	Variable/g Vmullayers, Vmulrep , Vappendlayer
	
	Make/o/d/C/n=(nlayers+2)root:packages:motofit:reflectivity:tempwaves:pj
	Make/o/d/C/n=(2,2) root:packages:motofit:reflectivity:tempwaves:subtotal,root:packages:motofit:reflectivity:tempwaves:temp2
	Make/o/d/C/n=(2,2) root:packages:motofit:reflectivity:tempwaves:MRtotal,root:packages:motofit:reflectivity:tempwaves:MI		//MRtotal is the resultant matrix MI is the individual matrix for each layer
	NVAR/z Vmullayers=root:packages:motofit:reflectivity:tempwaves:Vmullayers
	
	if(NVAR_exists(Vmullayers)==1)
		make/c/o/d/n=(2,2,Vmullayers) root:packages:motofit:reflectivity:tempwaves:mmatrix	//mmatrix holds the repeat matrix for the multilayer
		make/c/o/d/n=(3,Vmullayers) root:packages:motofit:reflectivity:tempwaves:kznpjbeta //this holds all the wavevectors, fresnel coefficients and beta values for the repeat
	endif
End

Function Moto_Abelesreflectivity(w,y,x) //:fitfunc
	Wave w,y,x
	//this function is calculates the reflectivity with an Abeles characteristic matrix.  It works, so don't alter it.
	//number of layers,SUPERphaseSLD,SUBphaseSLD,Q value
	
	String savedDataFolder = GetDataFolder(1)		// save
	SetDataFolder root:packages:motofit:reflectivity:tempwaves
		
	NVAR/z Vmullayers=root:packages:motofit:reflectivity:tempwaves:Vmullayers
	NVAR/z Vmulrep=root:packages:motofit:reflectivity:tempwaves:Vmulrep
	NVAR/z Vappendlayer = root:packages:motofit:reflectivity:tempwaves:Vappendlayer
	
	Variable reflectivity,ii,jj,kk,nlayers,inter,SLD,qq,scale,bkg,subrough
	Variable/C super,sub,arg,cinter,Beta,Rj,cella,cellb,cellc,celld
	
	//declare all the waves
	//pj are the wavevectors
	//MI is the characteristic matrix for a layer
	Wave/z/c pj,subtotal,temp2,MRtotal,MI,mmatrix,kznpjbeta
	
	//subsequent layers have 4 parameters each: thickness, SLD, solvent penetration and roughness
	//if you increase the number of layers you have to put extra parameters in.
	//you should be able to remember the order in which they go.
	//enter the SLD as SLD*1e6 (it's easier to type).
	
	//Layer 1 is always closest to the SUPERPHASE (e.g. air).  increasing layers go down 
	//towards the subphase.  This may be confusing if you switch between air-solid and solid-liquid
	//I will write some functions to create exotic SLD profiles if required.
	
	nlayers=w[0]
	scale=w[1]
	super=w[2]*1e-6
	sub=1e-6*w[3]
	bkg=abs(w[4])
	subrough=w[5]
	
	//offset is where the coefficients for the multilayer repeat start
	variable offset=4*w[0]+6	
	
	//for definitions of all the parameters see 
	//NEUTRON REFLECTION FROM HYDROGEN/DEUTERIUM CONTAINING MATERIALS
	//Penfold,Webster,Bucknall
	//http://www.isis.rl.ac.uk/largescale/Crisp/documents/neut_refl_HD.htm
	variable nit=numpnts(x)
	for(nit=0;nit<numpnts(x);nit+=1)
		qq=x[nit]
	
		//make the resultant matrix Mr an identity matrix to start with
		MRtotal={{cmplx(1,0),cmplx(0,0)},{cmplx(0,0),cmplx(1,0)}}
		subtotal={{cmplx(1,0),cmplx(0,0)},{cmplx(0,0),cmplx(1,0)}}
		
		//workout the wavevector in the incident medium/superphase
		inter=cabs(sqrt((qq/2)^2))
		pj[0]=cmplx(inter,0)
	
		//workout the wavevector in the subphase
		pj[nlayers+1]=sqrt(pj[0]^2-4*Pi*((w[3]*1e-6)-super))
	
		//workout the wavevector in the rest of the layers
		for(ii=1;ii<nlayers+1;ii+=1)
			SLD=((w[4*(ii)+4]/100)*sub)+((100-w[4*(ii)+4])/100)*w[4*(ii)+3]*1e-6
			pj[ii]=sqrt(cmplx((pj[0]^2-4*Pi*(SLD-super)),0))
		endfor
		
		//workout the wavevector in each of the toplayer of the multilayer (if it exists)
		if(Vmullayers>0)
			SLD=((w[offset+2]/100)*sub)+((100-w[offset+2])/100)*w[offset+1]*1e-6
			kznpjbeta[0][0]=sqrt(cmplx((pj[0]^2-4*Pi*(SLD-super)),0))
		endif
		
		for(ii=0;ii<nlayers+1;ii+=1)
			//work out the fresnel coefficient for the layer
			if(ii==Vappendlayer && Vmulrep>0 && Vmullayers>0)
				rj=((pj[ii]-kznpjbeta[0][0])/(pj[ii]+kznpjbeta[0][0]))*exp(-2*pj[ii]*kznpjbeta[0][0]*w[offset+3]^2) //roughness of the top multilayer
			elseif(ii==(nlayers))
				rj=((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*exp(-2*pj[ii]*pj[ii+1]*subrough^2)	//the roughness of the subphase is sigma_rough
			else
				rj=((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*exp(-2*pj[ii]*pj[ii+1]*w[4*(ii+1)+5]^2)	  //the roughness at the top of each layer
			endif
		
			//work out Beta
			Beta=pj[ii]*cmplx(0,abs(w[4*ii+2]))
			if(ii==0)
				Beta=cmplx(0,0)
			endif
		
			//this is the characteristic matrix of a layer
			MI={{exp(Beta),rj*exp(-Beta)},{rj*exp(Beta),exp(-Beta)}}
		
			//Matrixmultiply MR,MI to get the updated total matrix
			Moto_matrixmult(MRtotal,MI,MRtotal)
	
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			//Multilayer starting
			//if this is the appendlayer then you have to do something about it
			//multiply MR by the multilayer
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			if(ii==Vappendlayer && Vmulrep>0 && Vmullayers>0)
									
				//work out the wavevectors in each of the multilayer subsections
				for(jj=0;jj<Vmullayers;jj+=1)
					SLD=((w[4*jj+offset+2]/100)*sub)+((100-w[4*jj+2+offset])/100)*w[4*jj+1+offset]*1e-6
					kznpjbeta[0][jj]=sqrt(cmplx((pj[0]^2-4*Pi*(SLD-super)),0))
				endfor
			
				//work out the fresnel coefficients
				for(jj=0;jj<Vmullayers;jj+=1)
					if(jj==Vmullayers-1)	//if you're in the last layer then the roughness is the roughness of the top
						kznpjbeta[1][jj]=((kznpjbeta[0][jj]-kznpjbeta[0][0])/(kznpjbeta[0][jj]+kznpjbeta[0][0]))*exp(-2*kznpjbeta[0][jj]*kznpjbeta[0][0]*w[offset+3]^2)
					else					//otherwise it's the roughness of the layer below
						kznpjbeta[1][jj]=((kznpjbeta[0][jj]-kznpjbeta[0][jj+1])/(kznpjbeta[0][jj]+kznpjbeta[0][jj+1]))*exp(-2*kznpjbeta[0][jj]*kznpjbeta[0][jj+1]*w[4*(jj+1)+3+offset]^2)
					endif
				
					//Beta's
					kznpjbeta[2][jj]=kznpjbeta[0][jj]*cmplx(0,abs(w[4*(jj)+offset]))
				
					//fillout the matrix
					mmatrix[][][jj]={{exp(kznpjbeta[2][jj]),kznpjbeta[1][jj]*exp(-kznpjbeta[2][jj])},{kznpjbeta[1][jj]*exp(kznpjbeta[2][jj]),exp(-kznpjbeta[2][jj])}}
				endfor
			
				//work out the subtotal for the matrixrepeats
				//start off the the first layer
				//this will save a lot of time, because you only have to work it out once.
				for(jj=0;jj<Vmullayers;jj+=1)
					temp2[0][0]=mmatrix[0][0][jj]
					temp2[0][1]=mmatrix[0][1][jj]
					temp2[1][0]=mmatrix[1][0][jj]
					temp2[1][1]=mmatrix[1][1][jj]
					
					Moto_matrixmult(subtotal,temp2,subtotal)
				endfor
			
				for(kk=0;kk<Vmulrep;kk+=1)		//multiply of the repeat units to save time
				
					if(kk==Vmulrep-1)			//if you're the last repeat then the fresnel coefficient will have to change using the bottom/Vappend+1 roughness
						if(Vappendlayer==nlayers)
							cellb=((kznpjbeta[0][Vmullayers-1]-pj[nlayers+1])/(kznpjbeta[0][Vmullayers-1]+pj[nlayers+1]))*exp(-2*kznpjbeta[0][Vmullayers-1]*pj[nlayers+1]*subrough^2)
						else
							cellb=((kznpjbeta[0][Vmullayers-1]-pj[Vappendlayer+1])/(kznpjbeta[0][Vmullayers-1]+pj[Vappendlayer+1]))*exp(-2*kznpjbeta[0][Vmullayers-1]*pj[Vappendlayer+1]*w[4*(Vappendlayer+1)+5]^2)
						endif
						mmatrix[][][Vmullayers-1]={{exp(kznpjbeta[2][Vmullayers-1]),cellb*exp(-kznpjbeta[2][Vmullayers-1])},{cellb*exp(kznpjbeta[2][Vmullayers-1]),exp(-kznpjbeta[2][Vmullayers-1])}}
					
						for(jj=0;jj<Vmullayers;jj+=1)
							temp2[0][0]=mmatrix[0][0][jj]
							temp2[0][1]=mmatrix[0][1][jj]
							temp2[1][0]=mmatrix[1][0][jj]
							temp2[1][1]=mmatrix[1][1][jj]
						
							Moto_Matrixmult(MRtotal,temp2,MRtotal)
						endfor
					
					else
						Moto_Matrixmult(MRtotal,subtotal,MRtotal)
					endif					
				endfor
			endif
		endfor
	
		variable den=magsqr(MRtotal[0][0])
		variable num=magsqr(MRtotal[1][0])
		reflectivity=num/den
		reflectivity*=scale
		reflectivity+=bkg
		y[nit] = reflectivity
	endfor
	SetDataFolder savedDataFolder	
End


Function Moto_matrixmult(a,b,c)
	Wave/C a,b,c
	variable/C cella=a[0][0],cellb=a[1][0],cellc=a[0][1],celld=a[1][1],celle=b[0][0],cellf=b[0][1],cellg=b[1][0],cellh=b[1][1]
	c[0][0]=cella*celle+cellc*cellg
	c[1][0]=cellb*celle+celld*cellg
	c[0][1]=cella*cellf+cellc*cellh
	c[1][1]=cellb*cellf+celld*cellh
End


Function Moto_SLDplot(w,z)
	Wave w
	Variable z
	//
	//This function calculates the SLD profile.  It updates whenever the fitparameters update.
	//
	Wave zed = root:zed
	
	Variable SLDpts=str2num(Moto_str("SLDpts"))
	variable nlayers,SLD1,SLD2,zstart,zend,ii,temp,zinc,summ
	Variable deltarho,zi,dindex,sigma,thick,dist,rhosolv
	 
	nlayers=w[0]
	rhosolv=w[3]
	
	//setup the start and finish points of the SLD profile

	if (nlayers==0)
		zstart=-5-4*abs(w[5])
	else
		zstart=-5-4*abs(w[9])
	endif
	
	ii=1
	temp=0
	if (nlayers==0)
		zend=5+4*abs(w[5])
	else	
		do
			temp+=abs(w[4*ii+2])
			ii+=1
		while(ii<nlayers+1)
		
		zend=5+temp+4*abs(w[5])
	endif
	zinc=(zend-zstart)/SLDpts

	//work out the z depth wave
	ii=0
	do
		zed[ii]=zstart+(zinc*ii)
		ii+=1
	while(ii<SLDpts)


	dist=0
	summ=w[2]
	ii=0

	do
		if(ii==0)
			SLD1=(w[7]/100)*(100-w[8])+(w[8]*rhosolv/100)
			deltarho=-w[2]+SLD1
			thick=0
			sigma=abs(w[9])
			
			if(nlayers==0)
				sigma=abs(w[5])
				deltarho=-w[2]+w[3]
			endif
		
		elseif(ii==nlayers)
			SLD1=(w[4*ii+3]/100)*(100-w[4*ii+4])+(w[4*ii+4]*rhosolv/100)
			deltarho=-SLD1+rhosolv
			thick=abs(w[4*ii+2])
			sigma=abs(w[5])
		
		else
			SLD1=(w[4*ii+3]/100)*(100-w[4*ii+4])+(w[4*ii+4]*rhosolv/100)
			SLD2=(w[4*(ii+1)+3]/100)*(100-w[4*(ii+1)+4])+(w[4*(ii+1)+4]*rhosolv/100)
			deltarho=-SLD1+SLD2
			thick=abs(w[4*(ii)+2])
			sigma=abs(w[4*(ii+1)+5])
		endif
		
		dist+=thick
		
		//if sigma=0 then the computer goes haywire (division by zero), so say it's vanishingly small
		if(sigma==0)
			sigma+=1e-3
		endif
		
		summ+=(deltarho/2)*(1+erf((z-dist)/(sigma*sqrt(2))))
		
		ii+=1
	while(ii<nlayers+1)
	
	return summ
End

Function/t Moto_askForListofFiles()
	execute/z "multiopenfiles/F=\".*;.xml;\"/M=\"Please select your data files.\""
	SVAR/z nv = S_filename
	if(SVAR_exists(nv))
		return nv
	else
		return ""
	endif
End

Function Moto_Plotreflectivity()
	//this function loads experimental data from a file, then puts it into a nice graph.  The data is from 2 to 4 columns wide:  Q,R,dR,dQ and can contain as
	//many datapoints as you want.
	variable fileID,numcols, ii
	string fileName ="", filenames = "" 
	if(itemsinlist(OperationList("multiopenfiles", ";", "external" ))>0)
		filenames = Moto_askforlistoffiles()
	else
		open/r/d/T="????" fileID
		filenames = S_filename
	endif
	
	//if the user presses cancel then we should abort the load
	if(itemsinlist(filenames)==0)
		ABORT
	endif
	
	for(ii=0 ; ii<itemsinlist(filenames) ; ii+=1)
		filename = stringfromlist(ii, filenames)
	
		if(stringmatch(filename,"*.xml"))	//loading XML type reduced file from Platypus
			fileID = xmlopenfile(filename)
			if(fileID==-1)
				print "ERROR opening xml file (SLIM_PLOT_reduced)"
				abort
			endif
			
			xmlwavefmXPATH(fileID,"//REFdata[1]/Qz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl0
			asdfghjkl0 = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//REFdata[1]/R","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl1
			asdfghjkl1 = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//REFdata[1]/dR","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl2
			asdfghjkl2 = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//REFdata[1]/dQz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) asdfghjkl3
			asdfghjkl3 = str2num(M_xmlcontent[p][0])
			xmlclosefile(fileID,0)
			numcols=4 
		else	
			LoadWave/Q/G/D/N=asdfghjkl/A fileName
			//if you're not loading 2,3 or 4 column data then there may be something wrong.
			numcols=V_Flag
			Wave/z asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3
			if(numcols<2 || numcols>4)
				Killwaves/z asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3,asdfghjkl4,asdfghjkl5,asdfghjkl6,asdfghjkl7,asdfghjkl8
				ABORT "does your dataset have anything other than 2,3 or 4 columns?"
			endif
		endif

		string pathSep
		strswitch(UpperStr(IgorInfo(2)))
			case "MACINTOSH":
				pathSep = ":"
				break
			case "WINDOWS":
				pathSep = "\\"
				break
		endswitch
		filename = parsefilepath(3,filename,pathSep,0,0)
      	
		SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
  	
		//if the program control string doesn't exist then make logR vs Q the default
		if(SVAR_exists(motofitcontrol))
			variable plotyp=str2num(moto_str("plotyp"))
		else
			plotyp=1
		endif
	
		Variable logg,rr,gg,bb
	
		switch(plotyp)
			case 1:
				logg=0	
				break
			case 2:
				logg=1
				break
			case 3:
				logg=0
				break
		endswitch
	
		//give all the waves their new names, using a filename stub
		String Q,R,dR,dQ

		Q = CleanupName((fileName + "_q"),0)
		R = CleanupName((fileName + "_R"),0)
		dR = CleanupName((fileName + "_E"),0)
		dQ = CleanupName((fileName + "_dq"),0)
	
		//rename all the waves to their correct name
		duplicate/o asdfghjkl0, $Q
		duplicate/o asdfghjkl1, $R
		
		//here's where we see if we've loaded in dR and dQ waves
		switch(numcols)
			case 2:
				Sort $q,$q,$R
				break
			case 3:
				duplicate/o asdfghjkl2,$dR
				Sort $q,$q,$R,$dR
				break
			case 4:
				duplicate/o asdfghjkl2,$dR
				duplicate/o asdfghjkl3,$dQ
				Sort $q,$q,$R,$dR,$dQ
				break
		endswitch
	
		Killwaves/z asdfghjkl0,asdfghjkl1,asdfghjkl2,asdfghjkl3,asdfghjkl4,asdfghjkl5,asdfghjkl6,asdfghjkl7,asdfghjkl8
	
		//remove all the NaN or +/- INFS from loaded wave
		Moto_removeNAN($q,$R,$dR,$dQ)
	
		//do we want to modify the data to suit the plotyp?
		switch(plotyp)
			case 1:
				Moto_toLogLin($Q,$R,$dR,1) //convert data to loglin
				break
			case 2:
				//do nothing, we want the data as linlin
				break
			case 3:
				Moto_toRQ4($Q,$R,$dR,1) //convert data to RQ4
				break
		endswitch
  	
		// assign colors randomly
		rr = abs(trunc(enoise(65535)))
		gg = abs(trunc(enoise(65535)))
		bb = abs(trunc(enoise(65535)))
	
		if(WinType("") == 1)
			if(findlistitem(tracenamelist("",";",1),nameofwave($R))!=-1)
				Moto_autoscale()
				return 0
			endif
			DoAlert 1,"Do you want to append this data to the current graph?"
			if(V_Flag == 1)
				AppendToGraph $R vs $Q
				ModifyGraph mode($R)=3,msize($R)=1,rgb($R)=(rr,gg,bb),grid=0,mirror=0,tickUnit=1//,marker=8
				ModifyGraph log(left)=(logg),mirror=0
				if(waveexists($dR))
					ErrorBars/T=0 $R Y,wave=($dR,$dR)
				endif
				//				Moto_autoscale()
			else
				//new graph
				Display/K=1 $R vs $Q
				ModifyGraph log(bottom)=0,mode=3,msize($R)=1,rgb=(rr,gg,bb),grid=0,mirror=0,tickUnit=1
				ModifyGraph log(left)=(logg)
				if(waveexists($dR))
					ErrorBars/T=0 $R Y,wave=($dR,$dR)
				endif
				Label bottom "Qz/A\\S-1"
				Label left "Reflectivity"
				//				Moto_autoscale()
			endif
		else
			// graph window was not target, make new one
			Display/K=1 $R vs $q
			ModifyGraph log(bottom)=0,mode($R)=3,msize($R)=1,rgb=(rr,gg,bb),grid=0,mirror=0,tickUnit=1
			ModifyGraph log(left)=(logg)
			if(waveexists($dR))
				ErrorBars/T=0 $R Y,wave=($dR,$dR)
			endif
			Label bottom "Qz/A\\S-1"
			Label left "Reflectivity"
			//			Moto_autoscale()
		endif
	endfor
End

Function Moto_autoscale()

	string traces = tracenamelist("reflectivitygraph",";",1)
	string xwavestr
	if(Stringmatch(traces,"*theoretical_R*")==0)
		return 0
	endif
	traces = removefromlist("theoretical_R",traces)

	variable highestvalue=0,lowestvalue=1000,tracenumber,ii=0

	tracenumber = itemsinlist(traces)
	
	if(tracenumber==0)
		return 0
	endif
	
	for(ii=0;ii<tracenumber;ii+=1)
		xwavestr = getwavesdatafolder(xwavereffromtrace("reflectivitygraph",stringfromlist(ii,traces,";")),2)
		Wave xwave = $xwavestr
		Wavestats/Q xwave
		if(highestvalue < V_max)
			highestvalue = V_max
		endif
		if(lowestvalue > V_Min)
			lowestvalue = V_min
		endif
	endfor

	Moto_changeTheoreticalQrange(numpnts(root:theoretical_Q),lowestvalue,highestvalue)
End


Function Moto_Reflectivitypanel() : Panel
	//this function builds the reflectivity panel and associated controls
	NewPanel /W=(124,62,850,700) as "Reflectivity Panel"
	ModifyPanel cbRGB=(43520,43520,43520)
	Dowindow/C reflectivitypanel
	Moto_changelayerwave(6,1,4)
	
	SetDrawLayer UserBack
	ListBox baseparams,pos={92,52},size={146,146},proc=moto_modelchange,frame=0
	ListBox baseparams,listWave=root:packages:motofit:reflectivity:baselayerparams
	ListBox baseparams,selWave=root:packages:motofit:reflectivity:baselayerparams_selwave
	ListBox baseparams,mode= 6,editStyle= 1,widths={19,89,21}
	
	ListBox layerparams,pos={70,289},size={564,133},proc=moto_modelchange
	ListBox layerparams,listWave=root:packages:motofit:reflectivity:layerparams
	ListBox layerparams,selWave=root:packages:motofit:reflectivity:layerparams_selwave
	ListBox layerparams,mode= 5,editStyle= 1
	ListBox layerparams,widths={21,23,86,21,23,86,21,23,86,21,23,86,21}
	ListBox layerparams,userColumnResize= 0
		
	variable/g root:packages:motofit:reflectivity:tempwaves:fringe
	SetVariable FT_lowQ title="low Q for FFT",bodyWidth=60,value=root:packages:motofit:reflectivity:tempwaves:FTlowQ
	Setvariable FT_lowQ,pos={160,476},proc=Moto_FTreflectivityhook,limits={0.005,1,0.01}
	Setvariable FThighQ title = "high Q for FFT",bodyWidth=60,value=root:packages:motofit:reflectivity:tempwaves:FThiQ
	Setvariable FThighQ,pos={160,496},proc=Moto_FTreflectivityhook,limits={0.005,1,0.01}
	Setvariable fringe,pos={148,543},size={166,15},proc=Moto_fringespacing,title="layer thickness spacing"
	Setvariable fringe,limits={0,0,0},barmisc={0,1000},value= root:packages:motofit:reflectivity:tempwaves:fringe
	SetVariable numfringe,pos={174,522},size={137,16},proc=Moto_fringespacing,title="number of fringes"
	SetVariable numfringe,limits={0,100,1},value= K0

	TabControl foo,pos={7,2},size={716,633},proc=Moto_fooProc,tabLabel(0)="Fit"
	TabControl foo,tabLabel(1)="Constraints",tabLabel(2)="Make globals"
	TabControl foo,value= 0
		
	Button Dofit,pos={253,50},size={140,50},proc=Moto_genericButtonControl,title="Do fit"
	Button Dofit,help={"Performs the fit"},fColor=(65280,32512,16384)
	Popupmenu Typeoffit,mode=1,bodywidth=140,pos={345,107},value = "Genetic;Levenberg-Marquardt;Genetic + LM;Genetic+MC_Analysis"

	Button loaddatas,pos={253,137},size={140,50},proc=Moto_genericButtonControl,title="Load data"
	Button loaddatas,fColor=(65280,32512,16384)
	PopupMenu dataset,pos={431,42},size={179,21},proc=Motofit_PopMenuProc,title="dataset"
	PopupMenu dataset,mode=2,bodyWidth= 139,popvalue="_none_",value= #"Listmatch(WaveList(\"*_R\", \";\",\"\"),\"!coef*\")"
	CheckBox useerrors,pos={484,92},size={94,14},proc=Motofit_checkproc,title="use error wave?"
	CheckBox useerrors,value= 0
	CheckBox usedQwave,pos={484,74},size={87,14},proc=Motofit_checkproc,title="use dQ wave?"
	CheckBox usedQwave,value= 0
	PopupMenu coefwave,pos={408,118},size={202,21},proc=Moto_changecoefs,title="Model"
	PopupMenu coefwave,mode=1,bodyWidth= 139,popvalue="coef_Cref",value= #"WaveList(\"coef*\",\";\",\"\")"
	CheckBox fitcursors,pos={483,155},size={116,14},proc=Motofit_checkproc,title="Fit between cursors?"
	CheckBox fitcursors,help={"To get the cursors on the graph press Ctrl-I.  This enables you to fit over a selected x-range"}
	CheckBox fitcursors,value= 0
	SetVariable res,pos={259,197},size={150,16},proc=Motofit_varproc,title="resolution dq/q %"
	SetVariable res,help={"Enter the resolution, dq/q in terms of a percentage. Use dq/q=0 to start with"}
	SetVariable res,limits={0,10,0.1},value= root:resolution[0]
	ValDisplay Chisquare,pos={247,221},size={170,15},title="Chi squared"
	ValDisplay Chisquare,limits={0,0,0},barmisc={0,1000}
	ValDisplay Chisquare,value= #"root:packages:motofit:reflectivity:chisq"
	PopupMenu plottype,pos={29,209},size={186,21},proc=Moto_Plottype,title="Plot type"
	PopupMenu plottype,help={"you can change the plot type to whatever you want."}
	PopupMenu plottype,mode=str2num(moto_str("plotyp")),bodyWidth= 140,value= #"\"logR vs Q;R vs Q;RQ4 vs Q\""
	Button Savecoefwave,pos={622,134},size={95,24},proc=Moto_savecoefficients,title="Save model",fsize=10
	Button loadcoefwave,pos={622,105},size={95,24},proc=Moto_genericButtonControl,title="Load model",fsize=10
	Button Savefitwave,pos={623,31},size={93,42},proc=moto_savefitwave,title="Save reflectivity \rwaves",fsize=10
	Button Addcursor,pos={531,223},size={80,21},proc=Moto_addcursor,title="Add cursor",fsize=10
	Button cursorleftA,pos={467,220},size={29,14},proc=Moto_cursorleft,title="<"
	Button cursorrightA,pos={495,220},size={29,14},proc=Moto_cursorright,title=">"
	Button cursorleftB,pos={467,235},size={29,14},proc=Moto_cursorleft,title="<"
	Button cursorrightB,pos={495,235},size={29,14},proc=Moto_cursorright,title=">"
	//	Button croppanel,pos = {1,1},size={50,20},proc = Moto_genericButtonControl,title="_toggleFFT",fsize=8,pos={402,646}
	
	
	Button Addconstraint,pos={36,52},size={119,29},disable=1,proc=Moto_changeconstraint,title="Add constraint",fsize=10
	Button removeconstraint,pos={36,95},size={119,30},disable=1,proc=Moto_changeconstraint,title="Remove constraint",fsize=10
	CheckBox useconstraint,pos={483,172},size={111,14},proc=Motofit_checkproc,title="Fit with constraints?"
	CheckBox useconstraint,value= 0
	CheckBox usemultilayer,pos={483,189},size={96,14},proc=Setupmultilayer,title="make multilayer?"
	CheckBox usemultilayer,value= 0
	PopupMenu SLDtype,pos={25,236},size={189,21},title="SLD type"
	PopupMenu SLDtype,mode=1,bodyWidth= 140,popvalue="Neutron",value= #"\"Neutron;Xray\""
	TitleBox hold,pos={184,36},size={26,13},title="hold?",frame=0
	TabControl thicknesstab, value=1,tabLabel(1)="Fringe spacing"
	TabControl thicknesstab ,value=0,tabLabel(0)="FFT of data"
	TabControl thicknesstab ,size={564,200},pos={69,426},proc=Moto_thicknesstabproc

		
	//	PopupMenu Calculationtype value="Solvent Penetration;imaginary SLD",pos={366,477},proc=Moto_calculationtype
	
	PopupMenu con1,pos={415,196},size={137,21},disable=1,title="2nd contrast"
	PopupMenu con1,mode=1,popvalue="_none_",value= #"WaveList(\"coef*\",\";\",\"\") +\"_none_\""
	PopupMenu con2,pos={415,223},size={134,21},disable=1,title="3rd contrast"
	PopupMenu con2,mode=27,popvalue="_none_",value= #"WaveList(\"coef*\",\";\",\"\") +\"_none_\""
	PopupMenu con0,pos={415,170},size={133,21},disable=1,title="1st contrast"
	PopupMenu con0,mode=2,popvalue="_none_",value= #"WaveList(\"coef*\",\";\",\"\")+\"_none_\" "
	PopupMenu con3,pos={415,249},size={134,21},disable=1,title="4th contrast"
	PopupMenu con3,mode=4,popvalue="_none_",value= #"WaveList(\"coef*\",\";\",\"\") +\"_none_\""
	PopupMenu con4,pos={415,276},size={134,21},disable=1,title="5th contrast"
	PopupMenu con4,mode=4,popvalue="_none_",value= #"WaveList(\"coef*\",\";\",\"\") +\"_none_\""
	Button makeglobal,pos={342,38},size={162,76},disable=1,proc=Moto_Makeglobals,title="Make global coefficient wave",fsize=10
	CheckBox g1,pos={52,63},size={55,14},disable=1,title="1. scale",value= 0
	CheckBox g0,pos={52,43},size={109,14},disable=1,title="0. Number of layers"
	CheckBox g0,value= 1
	CheckBox g2,pos={52,84},size={69,14},disable=1,title="2. SLD top",value= 0
	CheckBox g3,pos={52,104},size={77,14},disable=1,title="3. SLD base",value= 0
	CheckBox g4,pos={52,124},size={48,14},disable=1,title="4. bkg",value= 0
	CheckBox g5,pos={52,146},size={62,14},disable=1,title="Sig_base",value= 0
	CheckBox g6,pos={51,185},size={59,14},disable=1,title="6. thick1",value= 0
	CheckBox g10,pos={51,206},size={65,14},disable=1,title="10. thick2",value= 0
	CheckBox g14,pos={51,228},size={65,14},disable=1,title="14. thick3",value= 0
	CheckBox g18,pos={51,250},size={65,14},disable=1,title="18. thick4",value= 0
	CheckBox g22,pos={51,272},size={65,14},disable=1,title="22. thick5",value= 0
	CheckBox g26,pos={51,294},size={65,14},disable=1,title="26. thick6",value= 0
	CheckBox g30,pos={51,316},size={65,14},disable=1,title="30. thick7",value= 0
	CheckBox g34,pos={51,338},size={65,14},disable=1,title="34. thick8",value= 0
	CheckBox g38,pos={51,360},size={65,14},disable=1,title="38. thick9",value= 0
	CheckBox g42,pos={51,382},size={71,14},disable=1,title="42. thick10",value= 0
	CheckBox g43,pos={139,382},size={69,14},disable=1,title="43. SLD10",value= 0
	CheckBox g39,pos={139,360},size={63,14},disable=1,title="39. SLD9",value= 0
	CheckBox g35,pos={139,338},size={63,14},disable=1,title="35. SLD8",value= 0
	CheckBox g31,pos={139,316},size={63,14},disable=1,title="31. SLD7",value= 0
	CheckBox g27,pos={139,294},size={63,14},disable=1,title="27. SLD6",value= 0
	CheckBox g23,pos={139,272},size={63,14},disable=1,title="23. SLD5",value= 0
	CheckBox g19,pos={139,251},size={63,14},disable=1,title="19. SLD4",value= 0
	CheckBox g15,pos={139,229},size={63,14},disable=1,title="15. SLD3",value= 0
	CheckBox g11,pos={139,206},size={63,14},disable=1,title="11. SLD2",value= 0
	CheckBox g7,pos={139,185},size={57,14},disable=1,title="7. SLD1",value= 0
	CheckBox g8,pos={224,185},size={57,14},disable=1,title="8. Solv1",value= 0
	CheckBox g12,pos={224,206},size={63,14},disable=1,title="12. Solv2",value= 0
	CheckBox g16,pos={224,229},size={63,14},disable=1,title="16. Solv3",value= 0
	CheckBox g20,pos={224,251},size={63,14},disable=1,title="20. Solv4",value= 0
	CheckBox g24,pos={224,272},size={63,14},disable=1,title="24. Solv5",value= 0
	CheckBox g28,pos={224,294},size={63,14},disable=1,title="28. Solv6",value= 0
	CheckBox g32,pos={224,316},size={63,14},disable=1,title="32. Solv7",value= 0
	CheckBox g36,pos={224,338},size={63,14},disable=1,title="36. Solv8",value= 0
	CheckBox g40,pos={224,360},size={63,14},disable=1,title="40. Solv9",value= 0
	CheckBox g44,pos={224,382},size={69,14},disable=1,title="44. Solv10",value= 0
	CheckBox g45,pos={319,381},size={75,14},disable=1,title="45. rough10",value= 0
	CheckBox g41,pos={319,360},size={69,14},disable=1,title="41. rough9",value= 0
	CheckBox g37,pos={319,338},size={69,14},disable=1,title="37. rough8",value= 0
	CheckBox g33,pos={319,316},size={69,14},disable=1,title="33. rough7",value= 0
	CheckBox g29,pos={319,294},size={69,14},disable=1,title="29. rough6",value= 0
	CheckBox g25,pos={319,271},size={69,14},disable=1,title="25. rough5",value= 0
	CheckBox g21,pos={319,249},size={69,14},disable=1,title="21. rough4",value= 0
	CheckBox g17,pos={319,227},size={69,14},disable=1,title="17. rough3",value= 0
	CheckBox g13,pos={319,205},size={69,14},disable=1,title="13. rough2",value= 0
	CheckBox g9,pos={319,184},size={63,14},disable=1,title="9. rough1",value= 0
	PopupMenu nlayers,pos={170,39},size={125,21},disable=1,title="number of layers"
	PopupMenu nlayers,mode=3,popvalue="0",value= #"\"0;1;2;3;4;5;6;7;8;9;10\""
	PopupMenu numcontrasts,pos={335,128},size={144,21},disable=1,title=" number of contrasts"
	PopupMenu numcontrasts,mode=2,popvalue="1",value= #"\"1;2;3;4;5;6;7;8;9;10\""
	TitleBox compound,pos={498,128},size={50,20}
	TitleBox param2,pos={247,263},size={74,18},title="SLD /10\\S-6\\MA\\S-2",frame=0
	TitleBox param2,fStyle=1
	TitleBox param1,pos={117,267},size={72,13},title="thickness /\\MA",fSize=12
	TitleBox param1,frame=0,fStyle=1
	TitleBox param3,pos={370,259},size={113,26},title="solvent penetration \r          %v/v"
	TitleBox param3,frame=0,fStyle=1
	TitleBox param4,pos={512,266},size={76,13},title="roughness /A",frame=0,fStyle=1
	TitleBox param5,pos={22,312},size={27,13},title="layer",fSize=12,frame=0
	TitleBox param5,fStyle=1
	TitleBox baseparam,pos={27,53},size={33,13},title="layers",fSize=12,frame=0
	TitleBox baseparam,fStyle=1
	TitleBox baseparam1,pos={14,69},size={63,13},title="scalefactor",fSize=12
	TitleBox baseparam1,frame=0,fStyle=1
	TitleBox baseparam2,pos={22,86},size={42,13},title="SLDtop",fSize=12,frame=0
	TitleBox baseparam2,fStyle=1
	TitleBox baseparam3,pos={8,102},size={51,13},title="SLD subphase",fSize=12,frame=0
	TitleBox baseparam3,fStyle=1
	TitleBox baseparam4,pos={31,118},size={21,13},title="bkg",fSize=12,frame=0
	TitleBox baseparam4,fStyle=1
	TitleBox baseparam5,pos={12,133},size={63,13},title="sub rough",fSize=12
	TitleBox baseparam5,frame=0,fStyle=1
	TitleBox baseparam6,pos={80,133},size={50,20}
	TitleBox baseparam0,pos={140,133},size={50,20}
	TitleBox layerparam1,pos={200,133},size={50,20},disable=1
	TitleBox layerparam2,pos={260,133},size={50,20},disable=1
	TitleBox layerparam3,pos={320,133},size={50,20},disable=1
	TitleBox layerparam4,pos={380,133},size={50,20},disable=1
	
	//I'm sorry about this, but I can't seem to be able to perform the follwing command in a function
	string cmd="ValDisplay Chisquare title=\"Chi squared\",pos={252,230},size={170,15},value=root:packages:motofit:reflectivity:chisq"
	Execute/Q/Z cmd
	
End

Function moto_cropPanel()
	//resizes the reflectivity panel so you can't see FTwindow
	Movewindow /w=reflectivitypanel 124,62,700,370
End

Function moto_thicknesstabProc(TC_Struct)
	STRUCT WMTabControlAction &TC_Struct
	if(TC_Struct.eventcode==-1)
		return 0
	endif
	variable tab = TC_Struct.tab
	
	if(tab==0 && Waveexists(root:packages:motofit:reflectivity:tempwaves:FFToutput))
		setwindow reflectivitypanel#FFTplot, hide = 0
	else
		setwindow reflectivitypanel#FFTplot, hide = 1
	endif
	
	setvariable numfringe,disable=(tab!=1)
	setvariable fringe,disable=(tab!=1)
	SetVariable FT_lowQ , disable=(tab!=0)
	Setvariable FThighQ, disable=(tab!=0)
	return 0
End

Function moto_fooProc(TC_Struct)
	STRUCT WMTabControlAction &TC_Struct
	Variable tab=TC_Struct.tab
	//this function controls the visibility of the controls when different tabs are selected in the reflectivity panel.
	//first tab controls
	
	if(TC_Struct.eventcode==-1)
		return 0
	endif
	variable ii
	
	//first tab procedures
	tabcontrol thicknesstab,disable=(tab!=0)
	if(tab==0)
		controlinfo/w=reflectivitypanel thicknesstab
		tabcontrol thicknesstab,value=V_value,win=Reflectivitypanel
		setvariable numfringe,disable=(V_Value==0)
		setvariable fringe,disable=(V_Value==0)
		SetVariable FT_lowQ , disable=(V_Value)
		Setvariable FThighQ, disable=(V_Value)
		setwindow reflectivitypanel#FFTplot, hide=v_value
	else
		setvariable numfringe,disable=(tab!=0)
		setvariable fringe,disable=(tab!=0)
		SetVariable FT_lowQ , disable=(tab!=0)
		Setvariable FThighQ, disable=(tab!=0)
		setwindow reflectivitypanel#FFTplot, hide=1
	endif
	
	PopupMenu SLDtype,disable=(tab!=0)
	titlebox hold,disable=(tab!=0)
	titlebox compound,disable=(tab!=0)
	Button Dofit,disable= (tab!=0)
	Popupmenu Typeoffit,disable= (tab!=0)
		
	if(tab==0 && Waveexists(root:packages:motofit:reflectivity:tempwaves:FFToutput))
		setwindow reflectivitypanel#FFTplot, hide = 0
	else
		setwindow reflectivitypanel#FFTplot, hide = 1
	endif
	
	Checkbox fitcursors,disable= (tab!=0)
	Setvariable res,disable= (tab!=0)
	Valdisplay chisquare,disable= (tab!=0)
	Button loaddatas,disable= (tab!=0)
	//	button croppanel,disable=(tab!=0)
	Popupmenu plottype,disable= (tab!=0)

	Popupmenu coefwave,disable= (tab!=0)
	Popupmenu dataset,disable= (tab!=0)
	Checkbox useerrors,disable= (tab!=0)
	Checkbox usedqwave,disable= (tab!=0)
	
	listbox baseparams,disable=(tab!=0)
	listbox layerparams,disable=(tab!=0)
	
	Button Savecoefwave,disable= (tab!=0)
	Button loadcoefwave,disable= (tab!=0)
	Button Savefitwave,disable= (tab!=0)
	Button Addcursor,disable= (tab!=0)
	Button cursorleftA,disable= (tab!=0)
	Button cursorrightA,disable= (tab!=0)
	Button cursorleftB,disable= (tab!=0)
	Button cursorrightB,disable= (tab!=0)
	Checkbox usemultilayer, disable= (tab!=0)
	Checkbox useconstraint,disable= (tab!=0)
	
	titlebox baseparam1,disable= (tab!=0)
	titlebox baseparam2,disable= (tab!=0)
	titlebox baseparam3,disable= (tab!=0)
	titlebox baseparam4,disable= (tab!=0)
	titlebox baseparam5,disable= (tab!=0)
	titlebox baseparam6,disable= (tab!=0)
	titlebox baseparam7,disable= (tab!=0)
	titlebox baseparam,disable= (tab!=0)
	
	titlebox param1,disable= (tab!=0)
	titlebox param2,disable= (tab!=0)
	titlebox param3,disable= (tab!=0)
	titlebox param4,disable= (tab!=0)
	titlebox param5,disable= (tab!=0)
	
	//second tab controls
	Button addconstraint,disable= (tab!=1)
	Button removeconstraint,disable= (tab!=1)
	ii=0
	string conname

	if(waveexists(root:packages:motofit:reflectivity:constraints))
		do
			conname="constraint"+num2istr(ii)
			Setvariable $conname,disable=(tab!=1)
			ii+=1
		while(ii<numpnts(root:packages:motofit:reflectivity:constraints))
	endif

	//Tab3
	PopupMenu con1,disable= (tab!=2)
	PopupMenu con2,disable= (tab!=2)
	PopupMenu con0,disable= (tab!=2)
	PopupMenu con3,disable= (tab!=2)
	PopupMenu con4,disable= (tab!=2)
	Button makeglobal,disable= (tab!=2)
	CheckBox g1,disable= (tab!=2)
	
	if(tab==2)
		CheckBox g0,disable=2,value=1
	else
		CheckBox g0,disable=1
	endif
	
	for(ii=2;ii<46;ii+=1)
		conname="g"+num2str(ii)
		Checkbox $conname,disable=(tab!=2)
	endfor
	PopupMenu nlayers,disable= (tab!=2)
	PopupMenu nlayers,disable= (tab!=2)
	PopupMenu numcontrasts,disable= (tab!=2)
	PopupMenu numcontrasts,disable= (tab!=2)
	
	return 0
End

Function Moto_Chi2_print()
	String ctrlName

	//what dataset is in focus?
	controlinfo/W=reflectivitypanel dataset
	
	String dataset_y=S_Value
	String dataset_x=cleanupname(removeending(dataset_y)+"q",0)
	String dataset_e=cleanupname(removeending(dataset_y)+"e",0)
	
	//if the waves don't exist don't go anyfurther
	If(Waveexists($dataset_y)==0 ||Waveexists($dataset_x)==0)
		return 0 //don't go anyfurther
	endif
	
	duplicate/o $dataset_y, root:packages:motofit:reflectivity:tempwaves:sim_y
	duplicate/o $dataset_y, root:packages:motofit:reflectivity:tempwaves:enum
	duplicate/o $dataset_x,root:packages:motofit:reflectivity:tempwaves:sim_x
	duplicate/o $dataset_y,root:packages:motofit:reflectivity:tempwaves:sim_e
	
	Wave sim_y = root:packages:motofit:reflectivity:tempwaves:sim_y
	Wave sim_x = root:packages:motofit:reflectivity:tempwaves:sim_x
	Wave sim_e = root:packages:motofit:reflectivity:tempwaves:sim_e
	Wave enum = root:packages:motofit:reflectivity:tempwaves:enum

	//if we are using the error wave, then you want to use the SD of data.  If not, set sim_e=1
	controlinfo/W=reflectivitypanel useerrors 
	variable useerrors=V_Value
	if(waveexists($dataset_e) && useerrors)
		Wave temp=$dataset_e
		sim_e=temp
	else
		sim_e=1
	endif

	//which coefficient wave are you using?
	//first check if are you in multilayer mode?
	variable multilayer=str2num(moto_str("multilayer"))
	String coefwavestr = moto_coefficientfocus()
	Wave coefwave = $coefwavestr
	
	Duplicate/o coefwave,root:packages:motofit:reflectivity:tempwaves:holdwave
	Wave holdwave = root:packages:motofit:reflectivity:tempwaves:holdwave
	holdwave=1
	//update the Chisquared display
	Variable/g root:packages:motofit:reflectivity:chisq=moto_chi2(holdwave,coefwave)/numpnts(sim_y)
End

Function moto_chi2(xx,pp)
	Wave xx,pp //xx is the hold string.  pp is going to be the variables that the user is going to alter.
	//xx has to be the same length as the coefficient wave
	
	NVAR/z progress

	Wave coef_Cref
	variable Chi2=0,multilayer,ii,jj=0,use,npars=coef_Cref[0]

	//are you fitting a multilayer?
	multilayer=str2num(moto_str("multilayer"))

	Wave/z sim_y = root:packages:motofit:reflectivity:tempwaves:sim_y
	Wave/z sim_x = root:packages:motofit:reflectivity:tempwaves:sim_x
	Wave/z	sim_e = root:packages:motofit:reflectivity:tempwaves:sim_e
	Wave/z enum = root:packages:motofit:reflectivity:tempwaves:enum
	Wave/z coef_multicref
	
	for(ii=0;ii<numpnts(xx);ii+=1)	
		use=xx[ii]
		if(use==0)
			switch (multilayer)
				case 0:
					coef_Cref[ii]=pp[jj]
					break
				case 1:
					coef_multiCref[ii]=pp[jj]
			endswitch
			jj+=1
		endif									
	endfor											

	switch (multilayer)
		case 0:
			motofit(coef_Cref,enum,sim_x)
			enum-=sim_y
			enum/=sim_e
			enum=enum*enum
			chi2=sum(enum)
			break
		case 1:
			motofit(coef_multiCref,enum,sim_x)
			enum-=sim_y
			enum/=sim_e
			enum=enum*enum
			chi2=sum(enum)
			break
	endswitch
	
	return Chi2
End

function Moto_ABORTER(str)
	string str
	DoAlert 0, str
End

Function Moto_fit_Genetic()
	//this function is the button control that starts the fit.
	//the fit is done with genetic optimisation which is very very good at finding global minima
	
	string cDF = getdatafolder(1)
	
	Setdatafolder root:
	
	Moto_holdstring("",0)
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	
	Wave/z coef_Cref,coef_multiCref
	Variable ii,nlayers,npars,jj,use
	variable usecursors,useerrors,usedqwave
	String test
	String y,x,e,dx,dataset
	String cmd,cursors,errors,options
	Variable plotyp=str2num(moto_Str("plotyp"))
	Wave/z zed,SLD
	
	//which waves do you want to fit?
	Controlinfo/W=reflectivitypanel dataset
	dataset=S_Value
	dataset=removeending(dataset, "_R")
	y=cleanupname(dataset+"_R",0)
	x=cleanupname(dataset+"_q",0)
	e=cleanupname(dataset+"_E",0)
	dx=cleanupname(dataset+"_dq",0)
	
	Wave/z a=$x
	Wave/z b=$y
	Wave/z c=$e
	Wave/z d=$dx
	
	//the name of the coefficient wave
	String coefwavestr = Moto_coefficientfocus()
	Wave coef = $coefwavestr
	variable multilayer=str2num(moto_str("multilayer"))
	
	//check the x,y waves	
	if(waveexists(b)==0)
		Moto_ABORTER("enter a proper dataset in the dataset popup")
		return 0
	endif
	//if the waves you entered aren't valid then there is no point in doing the fit 
	if(waveexists(a)==0 | waveexists(b)==0)
		Moto_ABORTER("please enter a valid dataset")
		return 0						
	endif
	//we want to fit x and y data that has the same number of data points.
	Variable xlength,ylength,elength
	xlength=Dimsize(a,0)
	ylength=Dimsize(b,0)
	
	if (abs(xlength-ylength)>0)
		Moto_ABORTER("The y data does not have the same number of points as the x data.")
		return 0						
	endif
		
	//set up the holdstring
	String holdstring=moto_str("holdstring")
	
	//do you want to weight with a resolution wave?
	controlinfo/W=reflectivitypanel usedqwave
	if(V_Value==0)
		moto_repstr("usedqwave","0")
	else
		usedqwave=1
		moto_repstr("usedqwave","1")
		if(waveexists(d)==1)		
			if((abs(Dimsize($dx,0)-xlength))>0)
				Moto_Aborter("the resolution wave does not have the same number of points as the xy data")
				return 0
			endif
		else
			Moto_Aborter("dQ wave doesn't exist")
			return 0
		endif
	endif	

	//do you want to fit with errors?
	controlinfo/W=reflectivitypanel useerrors
	if(V_Value == 1)
		if(!waveexists(c))
			Moto_Aborter("relevant error wave doesn't exist")
			return 0
		endif
		if((numpnts(a)-numpnts(c)) != 0)
			Moto_Aborter("error wave needs same number of points as y wave")
			return 0
		endif
		useerrors = 1
	endif
		
	//do we want to fit with the cursors or not
	usecursors=str2num(moto_str("fitcursors"))
	if(usecursors)
		if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
			if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
				abort "The cursors are not on the same wave. Please move them so that they are."
			endif
		else
			abort "The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
		endif
	endif
		
	String fitdestination="fit_"+y,fitx="fit_"+x
	duplicate/o b,$("fit_"+y)
	duplicate/o a,$("fitx_"+y)

	if(usedqwave)
		duplicate/o d, root:packages:motofit:reflectivity:temp_dq
		Wave temp_dq = root:packages:motofit:reflectivity:temp_dq
		if(usecursors)
			Variable start=pcsr(A),finish=pcsr(B),temp
			if(start>finish)
				temp=finish
				finish=start
				start=temp
			endif
			Deletepoints (finish+1),(numpnts(temp_dq)-finish-1),temp_dq
			Deletepoints 0,start, temp_dq
		endif
	endif
	
	//get initialisation parameters for genetic optimisation
	struct GEN_optimisation gen
	gen.GEN_Callfolder = cDF
	GEN_optimise#GEN_Searchparams(gen)
	
	//now set up the command for optimisation
	cmd ="GENcurvefit"
	cmd += 	"/x="+nameofwave(a)
	if(useerrors)
		cmd += "/I=1/w="+nameofwave(c) 
	endif
	cmd += "/D="+fitdestination+" "
		
	options = "/k={"+num2str(gen.GEN_generations)+","+num2str(gen.GEN_popsize)+","+num2str(gen.k_m)+","+num2str(gen.GEN_recombination)+"}"
	options += "/TOL = "+num2str(gen.GEN_V_fittol)
	cmd += options
	cmd += " motofit"
	cmd += ","+nameofwave(b)
	if(usecursors)
		cmd += "[pcsr(A),pcsr(B)]"
	endif
	cmd += ","+coefwavestr
	cmd += ",\""+holdstring+"\""
		
	//get limits wave
	GEN_setlimitsforGENcurvefit($coefwavestr,holdstring,cDF)
	cmd += ",root:packages:motofit:old_genoptimise:GENcurvefitlimits"
	
	//optimise with genetic optimisation
	Moto_repstr("inFIT","1")
	//break the SLD relationship with zed, otherwise it can slow the fit down
	setformula SLD,""	
		
	Moto_backupModel() //make a backup of the model before you start the fit, so that you can roll back.
	
	Dowindow/f reflectivitygraph
	setactivesubwindow reflectivitygraph
	
	try 
		print cmd
		Execute/Q cmd	
	catch
		setdatafolder $cDF
		abort
	endtry
	
	//now we're leaving the fit
	Moto_repstr("inFIT","0")
		 
	//make a coefficient wave related to the data
	//y is the name of the y wave data
	test="coef_"+dataset+"_R"
	Duplicate/O $coefwavestr $test,W_Sigma
	W_Sigma = NaN	
		
	//this sets the wave note of the coefficient wave to be the same as motofitcontrol
	test=cleanupname("coef_"+dataset+"_R", 0)
	if(multilayer==1)
		note/K $test
		moto_repstr("coefwave",test)
		note $test,motofitcontrol
	else
		note/K $test
		moto_repstr("multilayer","0")
		moto_repstr("Vmullayers","0")
		moto_repstr("mulrep","0")
		moto_repstr("mulappend","0")
		moto_repstr("coefwave",test)
		note $test,motofitcontrol
	endif
	
	//update the theoretical graph.
	//first you have to update the coefficient wave
	Wave coef=$test
	if(multilayer==1)
		coef_multicref=coef
		Decompose_multilayer()
	elseif(multilayer==0)
		coef_cref=coef
	endif
		
	//update the layer tables
	Moto_CrefToLayerTable()
		
	Moto_update()
	
	//make the SLD curves and fit curves the same colour as the original wave
	//if the trace isn't on the graph add it.  If it is, don't do anything.
	//produce the fitwaves
	Dowindow/F reflectivitygraph
	Setactivesubwindow reflectivitygraph
	String traceexists=TraceNameList("",";",1)
	if(Strsearch(traceexists,fitdestination,0)!=-1)
		Removefromgraph/w=reflectivitygraph $("fit_"+y)
	endif		
	String temprename="fitx_"+y
	Duplicate/o $temprename,$fitx
	killwaves/z $temprename
	
	traceexists=TraceNameList("",";",1)
	if(Strsearch(traceexists,fitdestination,0)==-1)
		AppendToGraph $fitdestination vs $fitX
	endif
	
	string colour=stringfromlist(25,traceinfo("",y,0))			//position 25 is the RGB colour of the Rwave
	colour=replacestring("x",colour,fitdestination)
	cmd="modifygraph "+colour
	Execute/z cmd
	Modifygraph lsize($fitdestination)=1,mode($fitdestination)=0
	
	//figure out what the SLD and Zed and coef waves should be called.  Use a stub of the
	//data wave.
	//append an SLD wave as well
	Dowindow/F Reflectivitygraph
	Setactivesubwindow reflectivitygraph#SLDplot
	traceexists=TraceNameList("",";",1)
	String SLDdestination="SLD_"+dataset,zeddestination="zed_"+dataset
	Wave sld,zed
	Duplicate/O sld,$SLDdestination
	Duplicate/O zed,$zeddestination
	Setformula $SLDdestination,""
	Setformula $zeddestination,""
	if(Strsearch(traceexists,SLDdestination,0)==-1)
		AppendToGraph/W=# $SLDdestination vs $zeddestination
	endif
	colour=replacestring(fitdestination,colour,slddestination)
	cmd="modifygraph "+colour
	Execute/Z cmd
	Modifygraph lsize($SLDdestination)=1,mode($SLDdestination)=0
	
	//write the fit to the report notebook
	//b is the ywave
	Moto_notebookoutput("Reflectivityfittingreport",b,"Genetic Optimisation")
	
	Setactivesubwindow reflectivitygraph
	setdatafolder $cDF
	return 0
End
//end of genetic optimisation


Function Moto_fit_Levenberg() 
	//this function is the button control that starts the fit.
	//this function takes care of all the procedures involved with performing a Levenberg-Marquardt fit
	Setdatafolder root:
	Wave coef_Cref,zed,SLD
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	
	String test,holdstring,constraint="",errors="",cursors=""
	String y,x,e,dx,dataset
	variable useerrors=0,usedqwave=0,usecursors=0,useconstraint=0
	Variable ii
	Variable plotyp=str2num(Moto_str("plotyp"))


	//setupholdstring, all the hold checkboxes are numbered in order h0,h1,h2, etc.
	Moto_holdstring("",0)
	holdstring=moto_str("holdstring")

	//which waves do you want to fit	
	Controlinfo/W=reflectivitypanel dataset
	dataset=S_Value
	moto_repstr("dataset",dataset)

	if(cmpstr(dataset,"_none_")==0)
		ABORT "Which dataset did you want to fit?"
	endif 

	dataset=removeending(dataset,"_R")
	y=cleanupname(dataset+"_R",0)
	x=cleanupname(dataset+"_q",0)
	e=cleanupname(dataset+"_E",0)
	dx=cleanupname(dataset+"_dq",0)

	Wave/z a=$x
	Wave/z b=$y
	Wave/z c=$e
	Wave/z d=$dx


	if(waveexists(a)==0 | waveexists(b)==0)						//if the waves you entered aren't valid then there is no 
		abort "please enter a valid dataset"		//point in doing the fit.
	endif

	//we want to fit x and y data that has the same number of data points.
	Variable xlength,ylength,elength
	xlength=Dimsize($x,0)
	ylength=Dimsize($y,0)

	if (abs(xlength-ylength)>0)
		abort "The y data does not have the same number of points as the x data."
	endif

	//do you want to fit with errors?
	controlinfo/W=reflectivitypanel useerrors
	if(V_Value == 0)
		
	else
		useerrors=1
		Moto_repStr("useerrors","1")
		if(waveexists(c)==1)
			elength=Dimsize($e,0)
		
			if(abs(xlength-elength)>0)
				abort "the error wave does not have the same number of points as the xy data"
			endif
			errors="/W="+e+" /I=1 "
		else
			abort "error wave doesn't exist"
		endif
	endif

	//do you want to weight with a resolution wave?
	controlinfo/W=reflectivitypanel usedqwave
	if(V_Value==0)
		moto_repstr("usedqwave","0")
	else
		usedqwave=1
		moto_repstr("usedqwave","1")
		if(waveexists(d)==1)		
			if((abs(Dimsize($dx,0)-xlength))>0)
				abort "the resolution wave does not have the same number of points as the xy data"
			endif
		else
			abort "dQ wave doesn't exist"
		endif
	endif	

	//do we want to fit with the cursors or not
	usecursors=str2num(moto_str("fitcursors"))
	if(usecursors==1)
		cursors="[pcsr(A),pcsr(B)] "
		if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
			if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
				abort "The cursors are not on the same wave. Please move them so that they are."
			endif
		else
			abort "The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
		endif
	endif

	//do you want to use constraints?
	useconstraint=str2num(moto_str("useconstraint"))
	if(useconstraint==1)
		if (Waveexists(root:packages:motofit:reflectivity:constraints)==0)
			ABORT "no constraint wave exists"
		else
			Wave/T constraints = root:packages:motofit:reflectivity:constraints
			ii=0
			do
				test=constraints[ii]
				if(strlen(test)==0)
					ABORT "one of the constraint boxes is null"
				endif
				ii+=1
			while(ii<numpnts(constraints))
			//this is the constraint string that goes into the fit command
			constraint="/C=root:packages:motofit:reflectivity:tempconstraints"
			Moto_parse_equalconstraints(constraints)
		endif
	endif

	if(usedqwave)
		duplicate/o d, root:packages:motofit:reflectivity:temp_dq
		Wave temp_dq = root:packages:motofit:reflectivity:temp_dq
		if(usecursors)
			Variable start=pcsr(A),finish=pcsr(B),temp
			if(start>finish)
				temp=finish
				finish=start
				start=temp
			endif
			Deletepoints (finish+1),(numpnts(temp_dq)-finish-1),temp_dq
			Deletepoints 0,start, temp_dq
		endif
	endif
	
	// Set up the fit command
	String fitdestination="fit_"+y,fitx="fit_"+x
	duplicate/o b,$fitdestination
	duplicate/o a,$fitx

	//whats the name of the fitfunction
	//if you are fitting with multilayers then you need to change the holdstring,the fit function
	//and the coefficient wave
	controlinfo/W=reflectivitypanel calculationtype
	string fitfunction =" Motofit "
	string coefwave=moto_coefficientfocus()
	
	variable multilayer=str2num(moto_str("multilayer"))
	
	//break the SLD relationship with zed, otherwise it can slow the fit down
	setformula SLD,""

	//now we're fitting
	Moto_repstr("inFIT","1")
	variable/g V_Fiterror=0
	variable V_abortcode
	
	try
		Moto_backupModel() //make a backup of the model before you start the fit, so that you can roll back.
		string cmd="FuncFit/H=\""+holdstring+"\"/N /M=2"+fitfunction+coefwave+" "+y+cursors+"/X="+x+"/D="+fitdestination + errors+constraint
		print cmd
		Execute/Z cmd
	
		if(GEN_isbitset(V_Fiterror,0))
			print V_fiterror
			string errmsg = "Error while fitting, probably a singular matrix error"
			errmsg += "\n(Make sure that you don't parameters and constrain them at the same time OR that there are no parameters that have no effect on the fit (value=0))"  
			ABORT errmsg
		endif

	catch		//this is what happens if the user aborts the fit
		Moto_repstr("inFit","0")
		Moto_update()
		Moto_CrefToLayerTable()
		if(V_abortcode==-3)
			ABORT
		endif
	endtry
	
	//now we're not
	Moto_repstr("inFit","0")

	//Rename the covariance matrix, then normalise it
	Wave/Z M_Covar
	Duplicate/o M_Covar,M_Covariance
	M_Covariance = M_Covar[p][q]/sqrt(M_Covar[p][p]*M_Covar[q][q])
	killwaves/Z M_Covar
	
	//make a coefficient wave related to the data
	//y is the name of the y wave data
	test="coef_"+dataset+"_R"
	Duplicate/O $coefwave $test

	NVAR/Z V_chisq,V_npnts
	moto_repstr("V_chisq",num2str(V_chisq/V_npnts))
	//set the wave note for the coefficient wave to be the same as motofitcontrol
	if(multilayer==1)
		note/K $test
		moto_repstr("coefwave",test)
		note $test,motofitcontrol
	else
		note/K $test
		moto_repstr("multilayer","0")
		moto_repstr("Vmullayers","0")
		moto_repstr("mulrep","0")
		moto_repstr("mulappend","0")
		moto_repstr("coefwave",test)
		note $test,motofitcontrol
	endif

	//update the theoretical graph.
	if(multilayer==1)
		Kerneltransformation(coef_multicref)
		Decompose_multilayer()
	endif
	
	//update the layer tables
	Moto_CrefToLayerTable()
	
	Moto_update()

	//make the SLD curves and fit curves the same colour as the original wave
	//if the trace isn't on the graph add it.  If it is, don't do anything.
	String traceexists=TraceNameList("",";",1)
	if(Strsearch(traceexists,fitdestination,0)==-1)
		string colour=stringfromlist(25,traceinfo("",y,0))			//position 25 is the RGB colour of the Rwave
		colour=replacestring("x",colour,fitdestination)
		AppendToGraph $fitdestination vs $fitX
		cmd="modifygraph "+colour
		Execute/Z cmd
		Modifygraph lsize($fitdestination)=1,mode($fitdestination)=0
	endif

	//figure out what the SLD and Zed and coef waves should be called.  Use a stub of the
	//data wave.
	//append an SLD wave as well
	Dowindow/F Reflectivitygraph
	Setactivesubwindow reflectivitygraph#SLDplot
	traceexists=TraceNameList("",";",1)
	String SLDdestination="SLD_"+dataset,zeddestination="zed_"+dataset
	Wave sld,zed
	Duplicate/O sld,$SLDdestination
	Duplicate/O zed,$zeddestination
	Setformula $SLDdestination,""
	Setformula $zeddestination,""
	if(Strsearch(traceexists,SLDdestination,0)==-1)
		AppendToGraph/W=# $SLDdestination vs $zeddestination
		colour=replacestring(fitdestination,colour,slddestination)
		cmd="modifygraph "+colour
		Execute/Z cmd
		Modifygraph lsize($SLDdestination)=1,mode($SLDdestination)=0
	endif
	
	//write the fit to the report notebook
	//b is the ywave
	Moto_notebookoutput("Reflectivityfittingreport",b,"Levenberg Marquardt")
	
	Setactivesubwindow reflectivitygraph
End
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
///
Function Moto_fit_GenLM()
	//the fit is done with genetic optimisation then curvefit
	
	string savDF = getdatafolder(1)
	Setdatafolder root:
	Moto_holdstring("",0)
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
		
	Wave coef_Cref,coef_multiCref
	Wave zed,SLD
	
	Variable ii,nlayers,npars,jj,usedqwave,usecursors,useerrors,useconstraint
	Variable plotyp=str2num(moto_Str("plotyp"))
	String coefwave,test,cursors="",errors="",options=""
	
	//which waves do you want to fit?
	String y,x,e,dx,dataset, holdstring, coefwavestr 
	String cmd = ""
	
	Controlinfo/W=reflectivitypanel dataset
	dataset=S_Value
	dataset=removeending(dataset,"_R")
	y=cleanupname(dataset+"_R",0)
	x=cleanupname(dataset+"_q",0)
	e=cleanupname(dataset+"_E",0)
	dx=cleanupname(dataset+"_dq",0)
	
	Wave/z a=$x
	Wave/z b=$y
	Wave/z c=$e
	Wave/z d=$dx
	
	//the name of the coefficient wave
	coefwavestr = Moto_coefficientfocus()
	Wave coef = $coefwavestr
	variable multilayer=str2num(moto_str("multilayer"))
		
	//check the x,y waves	
	if(waveexists(b)==0)
		Moto_ABORTER("enter a proper dataset in the dataset popup")
		return 0
	endif
	//if the waves you entered aren't valid then there is no point in doing the fit 
	if(waveexists(a)==0 | waveexists(b)==0)
		Moto_ABORTER("please enter a valid dataset")
		return 0						
	endif
	//we want to fit x and y data that has the same number of data points.
	Variable xlength,ylength,elength
	xlength=Dimsize(a,0)
	ylength=Dimsize(b,0)
	
	if (abs(xlength-ylength)>0)
		Moto_ABORTER("The y data does not have the same number of points as the x data.")
		return 0						
	endif
		
	//set up the holdstring
	holdstring=moto_str("holdstring")
	
	//do you want to weight with a resolution wave?
	controlinfo/W=reflectivitypanel usedqwave
	if(V_Value==0)
		moto_repstr("usedqwave","0")
	else
		usedqwave=1
		moto_repstr("usedqwave","1")
		if(waveexists(d)==1)		
			if((abs(Dimsize($dx,0)-xlength))>0)
				Moto_Aborter("the resolution wave does not have the same number of points as the xy data")
				return 0
			endif
		else
			Moto_Aborter("dQ wave doesn't exist")
			return 0
		endif
	endif

	//do you want to fit with errors?
	controlinfo/W=reflectivitypanel useerrors
	if(V_Value == 1)
		useerrors = 1
		if(!waveexists(c))
			Moto_Aborter("relevant error wave doesn't exist")
			return 0
		endif
		if((numpnts(a)-numpnts(c)) != 0)
			Moto_Aborter("error wave needs same number of points as y wave")
			return 0
		endif
		errors = "/W="+e+"/I=1"
	endif
	
	//do we want to fit with the cursors or not
	controlinfo/w=reflectivitypanel fitcursors
	if(V_Value)
		usecursors = 1
		cursors="[xcsr(A),xcsr(B)]"
	endif
	
	//output
	String fitdestination="fit_"+y,fitx="fit_"+x
	duplicate/o b,$fitdestination
	duplicate/o a,$("fitx_"+y)
		
	//optimise with genetic optimisation
	Moto_repstr("inFIT","1")
	//break the SLD relationship with zed, otherwise it can slow the fit down
	setformula SLD,""
	
	//get initialisation parameters for genetic optimisation
	struct GEN_optimisation gen
	gen.GEN_Callfolder = savDF
	GEN_optimise#GEN_Searchparams(gen)
	
	cmd ="GENcurvefit"
	cmd += "/q/x="+x
	cmd += "/D="+fitdestination
		
	options = "/k={"+num2str(gen.GEN_generations)+","+num2str(gen.GEN_popsize)+","+num2str(gen.k_m)+","+num2str(gen.GEN_recombination)+"}"
	options += "/TOL = "+num2str(gen.GEN_V_fittol)
	cmd += options
		
	if(useerrors)
		cmd += errors
	endif
	cmd += " motofit"
	cmd += ","+y
	if(usecursors)
		cmd += "[pcsr(A),pcsr(B)]"
	endif
	cmd += ","+coefwavestr
	cmd += ",\""+holdstring+"\""
		
	//get limits wave
	GEN_setlimitsforGENcurvefit($coefwavestr,holdstring,savdf)
	cmd += ",root:packages:motofit:old_genoptimise:GENcurvefitlimits"
	
	Moto_backupModel() //make a backup of the model before you start the fit, so that you can roll back.
	
	if(usedqwave)
		duplicate/o d, root:packages:motofit:reflectivity:temp_dq
		Wave temp_dq = root:packages:motofit:reflectivity:temp_dq
		if(usecursors)
			Variable start=pcsr(A),finish=pcsr(B),temp
			if(start>finish)
				temp=finish
				finish=start
				start=temp
			endif
			Deletepoints (finish+1),(numpnts(temp_dq)-finish-1),temp_dq
			Deletepoints 0,start, temp_dq
		endif
	endif
	
	Dowindow/F reflectivitygraph
	Setactivesubwindow reflectivitygraph
	
	try
		Execute/Q/Z cmd	
	catch
		setdatafolder $savDF
	endtry
	
	//make a coefficient wave related to the data
	//y is the name of the y wave data
	test="coef_"+dataset+"_R"
	Duplicate/O $coefwavestr $test	
	coefwavestr = test
	
	//this sets the wave note of the coefficient wave to be the same as motofitcontrol
	test=cleanupname("coef_"+dataset+"_R", 0)
	if(multilayer==1)
		note/K $test
		moto_repstr("coefwave",test)
		note $test,motofitcontrol
	else
		note/K $test
		moto_repstr("multilayer","0")
		moto_repstr("Vmullayers","0")
		moto_repstr("mulrep","0")
		moto_repstr("mulappend","0")
		moto_repstr("coefwave",test)
		note $test,motofitcontrol
	endif
	
	Dowindow/F reflectivitygraph
	Setactivesubwindow reflectivitygraph
	Removefromgraph/w=reflectivitygraph $("fit_"+y)

	//do you want to use constraints?
	useconstraint=str2num(moto_str("useconstraint"))
	String constraint=""
	if(useconstraint==1)
		if (Waveexists(root:packages:motofit:reflectivity:constraints)==0)
			ABORT "no constraint wave exists"
		else
			Wave/T constraints = root:packages:motofit:reflectivity:constraints
			ii=0
			do
				test=constraints[ii]
				if(strlen(test)==0)
					ABORT "one of the constraint boxes is null"
				endif
				ii+=1
			while(ii<numpnts(constraints))
			//this is the constraint string that goes into the fit command
			constraint="/C=root:packages:motofit:reflectivity:tempconstraints"
			Moto_parse_equalconstraints(constraints)
		endif
	endif
	
	setdatafolder $savDF
	
	//break the SLD relationship with zed, otherwise it can slow the fit down
	setformula SLD,""

	//now we're fitting
	Moto_repstr("inFIT","1")
	variable/g V_Fiterror=0
	
	try
		cmd="FuncFit/H=\""+holdstring+"\"/N /M=2 Motofit "+coefwavestr+" "+y+cursors+" /X="+x+" /D="+fitdestination+errors+constraint
		Execute cmd
	
		if(GEN_isbitset(V_Fiterror,0))
			print V_fiterror
			string errmsg = "Error while fitting, probably a singular matrix error"
			errmsg += "\n(Make sure that you don't hold parameters and constrain them at the same time OR that there are no parameters that have no effect on the fit (value=0))"  
			ABORT errmsg
		endif
	catch		//this is what happens if the user aborts the fit
		Moto_repstr("inFit","0")
		Moto_update()
		if(V_abortcode==-3)
			ABORT
		endif
	endtry
	
	//now we're not
	Moto_repstr("inFit","0")
	
	//Rename the covariance matrix, then normalise it
	Wave/Z M_Covar
	Duplicate/o M_Covar,M_Covariance
	M_Covariance = M_Covar[p][q]/sqrt(M_Covar[p][p]*M_Covar[q][q])
	killwaves/Z M_Covar
	
	NVAR/Z V_chisq,V_npnts
	moto_repstr("V_chisq",num2str(V_chisq/V_npnts))
			
	//this sets the wave note of the coefficient wave to be the same as motofitcontrol
	test=cleanupname("coef_"+dataset+"_R", 0)
	if(multilayer==1)
		note/K $test
		note $test,motofitcontrol
	else
		note/K $test
		note $test,motofitcontrol
	endif
	
	//update the theoretical graph.
	//first you have to update the coefficient wave
	Wave coef=$test
	if(multilayer==1)
		coef_multicref=coef
		Decompose_multilayer()
	elseif(multilayer==0)
		coef_cref=coef
	endif
		
	//update the layer tables
	Moto_CrefToLayerTable()
		
	Moto_update()
	
	Dowindow/F reflectivitygraph
	Setactivesubwindow reflectivitygraph
	String temprename="fitx_"+y
	Duplicate/o $temprename,$fitx
	killwaves/z $temprename

	string traceexists=TraceNameList("",";",1)
	if(Strsearch(traceexists,fitdestination,0)==-1)
		AppendToGraph $fitdestination vs $fitX
	endif
	string colour=stringfromlist(25,traceinfo("",y,0))			//position 25 is the RGB colour of the Rwave
	colour=replacestring("x",colour,fitdestination)
	cmd="modifygraph "+colour
	Execute/Z cmd
	Modifygraph lsize($fitdestination)=1

	//figure out what the SLD and Zed and coef waves should be called.  Use a stub of the
	//data wave.
	//append an SLD wave as well
	Dowindow/F Reflectivitygraph
	Setactivesubwindow reflectivitygraph#SLDplot
	traceexists=TraceNameList("",";",1)
	string SLDdestination="SLD_"+dataset,zeddestination="zed_"+dataset
	Wave sld,zed
	Duplicate/O sld,$SLDdestination
	Duplicate/O zed,$zeddestination
	Setformula $SLDdestination,""
	Setformula $zeddestination,""
	if(Strsearch(traceexists,SLDdestination,0)==-1)
		AppendToGraph/W=# $SLDdestination vs $zeddestination
		colour=replacestring(fitdestination,colour,slddestination)
		cmd="modifygraph "+colour
		Execute/Z cmd
		Modifygraph lsize($SLDdestination)=1
	endif
	
	//write the fit to the report notebook
	//b is the ywave
	Moto_notebookoutput("Reflectivityfittingreport",b,"GEN/LM")
	
	Setactivesubwindow reflectivitygraph
	
	return 0
End


Function Moto_fit_GenMC()
	//this is called by the Dofit button on the reflectivity panel
	string cDF = getdatafolder(1)
	
	try
		Setdatafolder root:
	
		Moto_holdstring("",0)
		SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	
		Wave/z coef_Cref,coef_multiCref
		Variable ii,nlayers,npars,jj,use
		variable usecursors,useerrors,usedqwave, cursA, cursB, iters
		String test
		String y,x,e,dx,dataset
		String cmd,cursors,errors,options
		Variable plotyp=str2num(moto_Str("plotyp"))
		Wave zed,SLD
	
		//which waves do you want to fit?
		Controlinfo/W=reflectivitypanel dataset
		dataset=S_Value
		dataset=removeending(dataset,"_R")
		y=cleanupname(dataset+"_R",0)
		x=cleanupname(dataset+"_q",0)
		e=cleanupname(dataset+"_E",0)
		dx=cleanupname(dataset+"_dq",0)
	
		Wave/z a=$x
		Wave/z b=$y
		Wave/z c=$e
		Wave/z d=$dx
	
		//the name of the coefficient wave
		String coefwavestr = Moto_coefficientfocus()
		Wave coef = $coefwavestr
		variable multilayer=str2num(moto_str("multilayer"))
	
		//check the x,y waves	
		if(waveexists(b)==0)
			Doalert 0, "enter a proper dataset in the dataset popup"
			abort
		endif
		//if the waves you entered aren't valid then there is no point in doing the fit 
		if(waveexists(a)==0 | waveexists(b)==0)
			Doalert 0,"please enter a valid dataset"
			abort
		endif
		//we want to fit x and y data that has the same number of data points.
		Variable xlength,ylength,elength
		xlength=Dimsize(a,0)
		ylength=Dimsize(b,0)
	
		if (abs(xlength-ylength)>0)
			Doalert 0,"The y data does not have the same number of points as the x data."
			abort						
		endif
		
		//set up the holdstring
		String holdstring=moto_str("holdstring")
	
		//do you want to weight with a resolution wave?
		controlinfo/W=reflectivitypanel usedqwave
		if(V_Value==0)
			moto_repstr("usedqwave","0")
		else
			usedqwave=1
			moto_repstr("usedqwave","1")
			if(waveexists(d)==1)		
				if((abs(Dimsize($dx,0)-xlength))>0)
					Doalert 0,"the resolution wave does not have the same number of points as the xy data"
					abort
				endif
			else
				Doalert 0,"dQ wave doesn't exist"
				return 0
			endif
		endif	

		//do you want to fit with errors?
		controlinfo/W=reflectivitypanel useerrors
		if(V_Value == 1)
			if(!waveexists(c))
				Doalert 0,"relevant error wave doesn't exist"
				abort
			endif
			if((numpnts(a)-numpnts(c)) != 0)
				Doalert 0, "error wave needs same number of points as y wave"
				abort
			endif
			useerrors = 1
		else
			DoAlert 0, "The GEN_MC analysis option only works if you fit with an error wave"
			abort
		endif
		
		//do we want to fit with the cursors or not
		usecursors=str2num(moto_str("fitcursors"))
		if(usecursors)
			if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
				if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
					abort "The cursors are not on the same wave. Please move them so that they are."
				endif
			else
				abort "The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
			endif
			cursA = pcsr(A)
			cursB = pcsr(B)
		else
			cursA = 0
			cursB = dimsize(b, 0)
		endif
		
		if(usedqwave)
			duplicate/o d, root:packages:motofit:reflectivity:temp_dq
			Wave temp_dq = root:packages:motofit:reflectivity:temp_dq
			if(usecursors)
				Variable start=pcsr(A),finish=pcsr(B),temp
				if(start>finish)
					temp=finish
					finish=start
					start=temp
				endif
				Deletepoints (finish+1),(numpnts(temp_dq)-finish-1),temp_dq
				Deletepoints 0,start, temp_dq
			endif
		endif
		
		String fitdestination="fit_"+y,fitx="fit_"+x
		duplicate/o b,$("fit_"+y)
		duplicate/o a,$("fitx_"+y)
		Wave wfity=$("fit_"+y)
		Wave wfitx = $("fitx_"+y)
	
		//ask how many montecarlo iters
		iters = 200
		prompt iters, "iterations:"
		doprompt "Enter the number of Montercarlo iterations", iters
		if(V_Flag)
			abort
		endif
		if(iters<0)
			iters = 1
		else
			iters = ceil(iters)
		endif
		
		//optimise with genetic optimisation
		Moto_repstr("inFIT","1")
		//break the SLD relationship with zed, otherwise it can slow the fit down
		setformula SLD,""	

		Moto_backupModel() //make a backup of the model before you start the fit, so that you can roll back.
		
		try 
			if(Moto_montecarlo("motofit", coef, b, a, c, holdstring, iters, cursA = cursA, cursB = cursB))
				abort
			endif
		catch
			setdatafolder $cDF
			abort
		endtry

		//declare the output of the montecarlo
		Wave M_correlation, M_montecarlo, W_sigma954
		
		//make a coefficient wave related to the data
		//y is the name of the y wave data
		test="coef_"+y
		Duplicate/O coef $test,W_Sigma	
		Wave outputcoefs = $test
		outputcoefs = M_montecarlo[0][p]
		coef =  M_montecarlo[0][p]
		W_Sigma = W_sigma954
			
		//fillout the fitwaves, Montecarlo doesn't create them
		Motofit(outputcoefs, wfity, wfitx)
	
		//now we're leaving the fit
		Moto_repstr("inFIT","0")
	
		//this sets the wave note of the coefficient wave to be the same as motofitcontrol
		if(multilayer==1)
			note/K $test
			moto_repstr("coefwave",test)
			note $test,motofitcontrol
		else
			note/K $test
			moto_repstr("multilayer","0")
			moto_repstr("Vmullayers","0")
			moto_repstr("mulrep","0")
			moto_repstr("mulappend","0")
			moto_repstr("coefwave",test)
			note $test,motofitcontrol
		endif
	
		//update the theoretical graph.
		//first you have to update the coefficient wave
		Wave coef=$test
		if(multilayer==1)
			coef_multicref=coef
			Decompose_multilayer()
		elseif(multilayer==0)
			coef_cref=coef
		endif
		
		//update the layer tables
		Moto_CrefToLayerTable()
		
		Moto_update()
		
			
		//make the SLD curves and fit curves the same colour as the original wave
		//if the trace isn't on the graph add it.  If it is, don't do anything.
		//produce the fitwaves
		Dowindow/F reflectivitygraph
		Setactivesubwindow reflectivitygraph
		String traceexists=TraceNameList("",";",1)
		if(Strsearch(traceexists,fitdestination,0)!=-1)
			Removefromgraph/w=reflectivitygraph $("fit_"+y)
		endif		
		String temprename="fitx_"+y
		Duplicate/o $temprename,$fitx
		killwaves/z $temprename
		
		traceexists=TraceNameList("",";",1)
		if(Strsearch(traceexists,fitdestination,0)==-1)
			AppendToGraph $fitdestination vs $fitX
		endif
		
		string colour=stringfromlist(25,traceinfo("",y,0))			//position 25 is the RGB colour of the Rwave
		colour=replacestring("x",colour,fitdestination)
		cmd="modifygraph "+colour
		Execute/z cmd
		Modifygraph lsize($fitdestination)=1,mode($fitdestination)=0
		
		//figure out what the SLD and Zed and coef waves should be called.  Use a stub of the
		//data wave.
		//append an SLD wave as well
		Dowindow/F Reflectivitygraph
		Setactivesubwindow reflectivitygraph#SLDplot
		traceexists=TraceNameList("",";",1)
		String SLDdestination="SLD_"+removeending(dataset,"_"),zeddestination="zed_"+removeending(dataset,"_")
		Wave sld,zed
		Duplicate/O sld,$SLDdestination
		Duplicate/O zed,$zeddestination
		Setformula $SLDdestination,""
		Setformula $zeddestination,""
		if(Strsearch(traceexists,SLDdestination,0)==-1)
			AppendToGraph/W=# $SLDdestination vs $zeddestination
		endif
		colour=replacestring(fitdestination,colour,slddestination)
		cmd="modifygraph "+colour
		Execute/Z cmd
		Modifygraph lsize($SLDdestination)=1,mode($SLDdestination)=0
		
		Setactivesubwindow reflectivitygraph
		
		//create a graph of all the montecarloSLDcurves
		Moto_montecarlo_SLDcurves(M_montecarlo)
		
	catch
	
	endtry
	killwaves/z W_sigma954
	setdatafolder $cDF
	return 0
End

///
///
///
///
///
///
///
///
///End of fit types
///
///
///
///
///
///
///

Function Moto_parse_equalconstraints(constraints)
	Wave/T constraints 

	String callfolder=Getdatafolder(1)
	String constantfolder="root:packages:motofit:reflectivity"
	Setdatafolder constantfolder
	
	duplicate/o/t constraints,tempconstraints
	variable ii=0,alreadydeleted=0
	for(ii=0;ii<numpnts(constraints);ii+=1)
		string foobar=constraints[ii]
		variable isEquals=stringmatch(foobar,"*=*")
		if(isEquals) 		//search for equals
			variable isEqualpos=strsearch(foobar,"=",0)
			string left=foobar[0,isEqualpos-1],right=foobar[isEqualPos+1,strlen(foobar)]
			string ineq0=left+">"+right,ineq1=left+"<"+right
			deletepoints ii-alreadydeleted,1,tempconstraints
			redimension/n=(numpnts(tempconstraints)+2) tempconstraints
			tempconstraints[numpnts(tempconstraints)-2]=ineq0
			tempconstraints[numpnts(tempconstraints)-1]=ineq1
			alreadydeleted+=1
		endif
	endfor
	Setdatafolder callfolder
End

Function Moto_loaddata()
	//need this extra function, because the menu item can't call the generic button control
	STRUCT WMButtonAction B_Struct
	B_Struct.eventcode=2
	B_Struct.ctrlname = "loaddatas"
	Moto_genericButtonControl(B_Struct)
End

Function Moto_toRQ4(Q,R,dR,x)
	Wave/z Q,R,dR
	Variable x
	//if x=0 then you're sending RQ4 to linlin
	//if x=1 then you're sending linlin to RQ4
	switch(x)
		case 0:
			R=R/(Q^4)
			if(waveexists(dR)==1)
				dR/=Q^4
			endif
			break
		case 1:
			if(waveexists(dR)==1)
				dR*=Q^4	
			endif
			R=R*Q^4
			break
	endswitch			
End

Function Moto_toLogLin(Q,R,dR,x)
	Wave/z R,Q,dR
	Variable x
	//if x=0 then you're sending loglin to linlin
	//if x=1 then you're sending linlin to loglin
	switch(x)
		case 0:
			R=alog(R)
			if(waveexists(dR)==1)
				dR=alog(dR)
				dR*=R
				dR-=R
			endif
			break
		case 1:
			if(waveexists(dR)==1)
				dR=log((dR+R)/R)	
			endif
			R=log(R)
			break
	endswitch							
End

Function Moto_Plottype(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	//changes the plotype from logR (case1) to R vs Q (case2) to RQ4 (case3).
	//the plotype is also the data form in which the fit takes place.
	//you are actually altering the data that you load in, when this function is called.
	
	if(PU_Struct.eventcode==-1)
		return 0
	endif
	
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	variable plotyp=str2num(moto_str("plotyp"))
	
	Variable olddatatype,newdatatype,ii,ylength
	olddatatype=plotyp
	newdatatype=PU_Struct.popnum
	plotyp=PU_Struct.popnum
	moto_repstr("plotyp",num2str(newdatatype))
	Dowindow/F Reflectivitygraph
	setactivesubwindow Reflectivitygraph
	String dataR=listmatch(Wavelist("*R",";",""),"!coef*"),temp,ywave,xwave,ewave

	//if there are any global fits they are produced as a 1D wave, without a corresponding q wave
	String anyGFITS=listmatch(dataR,"gfit*"),gtraces=tracenamelist("reflectivitygraph",";",1)
	//but get rid of the global residuals in both strings
	anyGFITS=listmatch(anyGFITS,"!GRES*")
	dataR=listmatch(dataR,"!GRES*")
	gtraces=listmatch(gtraces,"Gfit*")

	for(ii=0;ii<itemsinlist(anyGFITS,";");ii+=1)
		String iterGFIT=stringfromlist(ii,anyGFITS)
		string yfitname=itergfit,xfitname
		xfitname=cleanupname((removeending(yfitname)+"q"),0)
		wave ygfitwave=$yfitname
		duplicate/o ygfitwave,$xfitname
		wave xgfitwave=$xfitname
		xgfitwave=leftx(ygfitwave)+p*deltax(ygfitwave)
		//if there are any global traces in the list are attached then you have to remove and reattach
		//this is because they are displayed as waveform data
		if(whichlistitem(itergfit,gtraces)!=-1)	//this code checks if it's on the list
			RemoveFromGraph $iterGfit
			AppendToGraph/w=reflectivitygraph ygfitwave vs xgfitwave
		endif
	endfor
	
	//convert all to linlin
	ii=0	
	do
		temp=stringfromlist(ii,dataR)
		if(strlen(temp)>0)
			ylength=strlen(temp)
			ywave=temp[0,ylength-2]
			xwave=cleanupname((ywave+"q"),0)
			ewave=cleanupname((ywave+"E"),0)
			ywave=cleanupname((ywave+"R"),0)
			Wave/z R=$ywave
			Wave/z Q=$xwave
			Wave/z dR=$ewave
			
			if(!waveexists(R) || !waveexists(Q))
				ii+=1
				continue
			endif
			
			Switch(olddatatype)
				case 1:
					//convert log-lin to linlin		
					Moto_toLogLin(Q,R,dR,0)
					break
				case 2:
					//do nothing, because you're already lin-lin
					break
				case 3:
					//convert RQ4 to linlin
					Moto_toRQ4(Q,R,dR,0)
					break
			Endswitch
			
			Switch(newdatatype)
				case 1:
					//convert linlin to loglin		
					Moto_toLogLin(Q,R,dR,1)
					break
				case 2:
					//do nothing, because you've already converted them all
					break
				case 3:
					//convert linlin to RQ4
					Moto_toRQ4(Q,R,dR,1)
					break
			Endswitch

		endif
		ii+=1
	while(strlen(temp)>0)

	Moto_update()

	//how do you want the y-axis displayed log(R)=lin, RQ4=log, R=log
	switch (plotyp)
		case 1:
			modifygraph log(left)=0
			Label left "log(R)"
			break
		case 2:
			Modifygraph log(left)=1
			label left "Reflectivity"
			ModifyGraph logTicks(left)=10
			break
		case 3:
			modifygraph log(left)=0
			Label left "RQ\\S4"
			ModifyGraph logLabel(left)=0
			ModifyGraph logTicks(left)=10
			break
		default:
			break
	endswitch
	
	//we have two plottype controls one in the reflectivitypanel, one in the reflectivitygraph
	//we need to make sure they're both updated.
	popupmenu plottype,mode=str2num(moto_str("plotyp")),win=reflectivitypanel
	popupmenu plottype,mode=str2num(moto_str("plotyp")),win=reflectivitygraph

	Setaxis/A
End

Function Moto_Makeglobals(ctrlName) : ButtonControl
	String ctrlName
	//this function sets up IGORS global function fitting panel.
	//you need to have fitted all the individual datasets first. 

	Variable contrasts,nglayers,ii,npars,numfixed,totalpars,count,jj,kk

	//contrasts is the number of contrast datasets from the popup
	controlinfo/W=reflectivitypanel numcontrasts
	contrasts=V_value
	controlinfo/W=reflectivitypanel nlayers
	nglayers=V_value-1						//V_Value starts from 1, but the number of layers goes from 0.

	String test,test1,test2,globalstring

	npars=4*nglayers+6
	globalstring=""
	numfixed=0

	//this section makes sure that the waves are the right length (=npars), and are  proper waves
	for(ii=0;ii<contrasts;ii+=1)	
		test2=""
		test=num2str(ii)
		test1=cleanupname(("con"+test),0)
		controlinfo/W=reflectivitypanel $test1
		test2=S_Value
		if(waveexists($test2)==0)
			abort "one of the waves might not a coefficient wave, please check"
		endif
		
		if(abs(Dimsize($test2,0)-npars)>0)
			abort "one of the coefficient waves is the wrong length for the number of layers"
		endif
	endfor											

	//this part works out which parameters are global.
	for(ii=0;ii<npars;ii+=1)
		test=num2str(ii)
		test1=cleanupname(("g"+test),0)
		controlinfo/W=reflectivitypanel $test1
		numfixed+=V_Value
		globalstring+=num2str(V_Value)
	endfor
	globalstring=globalstring[0,npars-1]

	//how long will the global coefficient wave be? MAKE THE GLOBAL WAVE
	totalpars=numfixed+npars*contrasts-(contrasts*numfixed) 		//remember, you still have to have one parameter for the fixed variable
	Make/o/d/n=(totalpars) globalwave

	//this section fills up all the global coefficients with the relevant parameters from the _1st_ coefficient wave
	ii=0
	jj=0
	controlinfo/W=reflectivitypanel con0
	test=S_value
	Wave w=$test


	//for the new global fit, the wave is filled with coeffs from the first contrast
	globalwave=w

	//now fill up with unfixed parameters from the otherwaves
	//set the fill position for global wave
	jj=numpnts(w)

	//now we need to fill up the remainder of the global wave, starting with the 2nd wave, etc.
	//get the wave names from the popups
	//only put a parameter in the global wave if its not a global

	kk=1
	for(kk=1;kk<contrasts;kk+=1)	
		test2=""
		test=num2istr(kk)
		test1=cleanupname(("con"+test),0)
		controlinfo/W=reflectivitypanel $test1
		test2=S_Value
		Wave w=$test2
		
		ii=0
		do
			count=str2num(globalstring[ii])
			if(count==0)
				globalwave[jj]=w[ii]
				jj+=1
			endif
			ii+=1
		while(ii<strlen(globalstring))				
	endfor									

	/////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////
	//The following code sets up the global fitting panel programatically.
	//this starts up the global fit panel.  However only start it up if it doesn't exist
	Struct globtabs TC_Struct
	test=""
	test=winlist("MotoGlobalFitPanel",";","Win:64")
	if(strlen(test)==0)
		Killdatafolder/Z root:packages:motofitGF:WindowCoordinates
		MOTO_WM_NewGlobalFit1#InitNewGlobalFitPanel()
	endif

	//this gets rid of any previous entries in the boxes
	dowindow/f MotoGlobalFitPanel
	Tabcontrol NewGF_TabControl, win=MotoGlobalFitPanel,value=0
	sorttabs(TC_Struct,0)
	MOTO_NewGF_SetTabControlContent(0)
	removeallglobals()

	test=""
	//this will load ywave and xwaves into the global fit panel
	for(ii=0;ii<contrasts;ii+=1)	
		test="con"+num2istr(ii)
		controlinfo/W=reflectivitypanel $test
		test=S_Value
		test=Removeending(test)
		test=test[5,200]
		test2=test+"Q"
		test+="R"
		dowindow/f MotoGlobalFitPanel
		MOTO_WM_NewGlobalFit1#NewGF_AddYWaveToList($test,$test2)
	endfor									

	Setdatafolder root:packages:MOTOFITGF:Newglobalfit
	Wave/T NewGF_DataSetListWave
	//this sets the fit function.  Only do this for as many datasets as you have
	for(ii=0;ii<contrasts;ii+=1)
		NewGF_DataSetListWave[ii][2][0]="Motofit"
		NewGF_DataSetListWave[ii][3][0]=num2str(npars)
	endfor

	Setdatafolder root:
	//need bit from Wavemetrics to make the whole global window table update
	tool()

	//now link the parameters.
	//you'll have to do a loop, for each of the global parameters, and set them individually.
	Setdatafolder root:packages:motofitgf:Newglobalfit
	Wave NewGF_MainCoefListSelWave
	for(ii=0;ii<npars;ii+=1)	
		test=globalstring[ii]
		if(cmpstr(test,"1")==0)
			for(jj=0;jj<contrasts;jj+=1)
				NewGF_MainCoefListSelWave[jj][ii]=1			
			endfor
			MOTO_WM_NewGlobalFit1#MOTO_NewGF_LinkCoefsButtonProc("NewGF_LinkCoefsButton")
			for(jj=0;jj<contrasts;jj+=1)
				NewGF_MainCoefListSelWave[jj][ii]=0			
			endfor
		endif
	endfor											

	//set the datafolder back to root
	setdatafolder root:

	//this will fill load the coefficients wave into the table.
	dowindow/f MotoGlobalFitPanel
	Tabcontrol NewGF_TabControl, win = MotoGlobalFitPanel,value=1
	sorttabs(TC_Struct,1)
	MOTO_NewGF_SetTabControlContent(1)
	MOTO_WM_NewGlobalFit1#SetCoefListFromWave(globalwave, 2, 0, 0)

End

Function Moto_changecoefs(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	//Function (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName = PU_Struct.ctrlname
	Variable popNum = PU_Struct.popnum
	String popStr = PU_Struct.popStr
	
	if(PU_Struct.eventcode==-1)
		return 0
	endif
	//this function makes coef_Cref equal to to the parameter wave shown in the popup menu
	//when you use this popup you are "importing values" from the coefficient wave selected

	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol
	String plotyp=moto_Str("plotyp")

	//transfer the note in the coefficient wave into motofitcontrol
	//however, if there isn't an associated wave note then you'll have to add in a default version 
	string coefnote=note($popstr)
	if(strlen(coefnote)<10)
		coefnote=Moto_dummymotofitstring()
		coefnote=Replacestringbykey("coefwave",coefnote,popstr)
		coefnote=Replacestringbykey("plotyp",coefnote,moto_str("plotyp"))
		Wave SLD
		coefnote=Replacestringbykey("SLDpts",coefnote,num2istr(numpnts(SLD)))
		Wave temp=$popstr
		variable nlayers=temp[0],num_Vmullayers
		//however, the coefficient wave may be a multilayer, this will estimate the problem
		if(numpnts(temp)>4*nlayers+6)
			coefnote=Replacestringbykey("multilayer",coefnote,"1")
			num_Vmullayers=0.25*(numpnts(temp)-(4*nlayers+6))
			coefnote=Replacestringbykey("Vmullayers",coefnote,num2istr(num_Vmullayers))
		endif
		note/K $Popstr
		note $popstr,coefnote
	endif

	//make the motofitcontrol string equal to the wavenote
	//but first remove any of the carriage returns that may be present in a loaded coefficient wave.
	coefnote=replacestring("\r",coefnote,"")
	note/k $popstr
	note $popstr, coefnote
	motofitcontrol=coefnote
	moto_repstr("coefwave",popstr)

	//this finds out the new coefficient wave
	Variable multilayer=str2num(moto_str("multilayer"))
	String compstr=selectstring(multilayer,"Coef_Cref","Coef_multiCref")
	Wave coef=$moto_Str("coefwave")
	Wave coef_Cref

	//if the popup coefficient wave was a multilayer set up the multilayer panel
	//however if the coefficient wave that was loaded has the name of coef_multicref
	//(a possibility given that one would like to simulate multilayers + save the simulation)
	// then calling setupmultilayer actually overwrites coef_multicref.  Therefore create a temp
	//copy
	if(cmpstr(popStr,"coef_multiCref")==0)
		duplicate/o coef_multicref TEMP_coef_multicref
	endif
	
 
	
	Setupmultilayer("",multilayer)

	if(cmpstr(popStr,"coef_multiCref")==0)
		duplicate/o  TEMP_coef_multicref coef_multicref
		killwaves/z TEMP_coef_multicref
	endif
	
	Wave/z coef_multicref
	checkbox usemultilayer,win=reflectivitypanel,value=multilayer

	//the following command recognises the fact that when you change the coefficient wave you may change 
	//the number of layers, so you have to recalculate the panel.
	//change the number of layers in reflectivitypanel
	//copy the coefficient wave selected in the popup into coef_Cref or coef_multiCref (multilayer case)
	if(cmpstr(popstr,compstr)!=0)
		Duplicate/O coef $compstr
	endif
	
	//need to get those parameters into the layerwaves for the reflectivitypanel			
	variable layers = coef[0]
	variable baselength =6
	variable paramsperlayer = 4
	
	Moto_changelayerwave(baselength,layers,paramsperlayer)
	Moto_CrefToLayerTable()
	Moto_LayerTableToCref(coef_Cref)

	//add the motofitcontrol string to the wave that you've just copied
	note/K coef_Cref
	note coef_cref,motofitcontrol

	if(multilayer==1)
		//if the wave you selected was a multilayer, then you need to update the multilayer panel.  This
		//is done by calling decompose_multilayer()
		Decompose_multilayer()
		//note sure if the following two lines are required, but don't remove them, just in case!	
		Variable/G root:packages:motofit:reflectivity:tempwaves:Vmullayers=numpnts(multilay)/4
		NVAR/z Vmullayers = root:packages:motofit:reflectivity:tempwaves:Vmullayers
		moto_repstr("Vmullayers",num2str(Vmullayers))

		Wave coef_multicref
		note/K coef_multicref
		note coef_multicref,motofitcontrol
	endif

	//this updates the plotype of the coefficients
	//we replaced plotyp in motofitcontrol by the value from the coefficient wave
	//this is newtype below
	variable newtype=str2num(moto_str("plotyp"))
	//however the function plottype requires that the old value of plotyp exist when
	//it's called, so replace plotyp in motofitcontrol by the oldversion 
	//(which was "saved at the top of this function)
	moto_repstr("plotyp",plotyp)
	
	//call plottype with the new version
	PU_Struct.popnum = newtype
	moto_Plottype(PU_Struct)
	
	//you need to change the controls to reflect the values held in the
	//new coefficient wave
	moto_updatecontrols()
	//finally update the theoretical reflectivity
	Moto_update()
End

Function moto_UpdateControls()
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol

	String coefwave=moto_str("coefwave")
	Wave Wcoefwave=$coefwave
	variable nlayers=Wcoefwave[0],ii=0,hold,jj=0,kk=0
	string holdstring=moto_str("holdstring")
	variable baselength = dimsize(root:packages:motofit:reflectivity:baselayerparams,0)
	variable paramsperlayer = 4
	Wave/T baselayerparams = root:packages:motofit:reflectivity:baselayerparams,layerparams = root:packages:motofit:reflectivity:layerparams
	Wave baselayerparams_selwave = root:packages:motofit:reflectivity:baselayerparams_selwave,layerparams_selwave = root:packages:motofit:reflectivity:layerparams_selwave
	
	for(ii=1;ii<baselength;ii+=1)
		hold=str2num(holdstring[ii])
		if(hold==1)
			baselayerparams_selwave[ii][2]=48
		else
			baselayerparams_selwave[ii][2]=32
		endif		
	endfor

	for(ii=baselength;ii<baselength+(paramsperlayer*nlayers);ii+=1)
		hold=str2num(holdstring[ii])
		if(mod(kk,paramsperlayer)==0)
			kk=0
		endif
		
		if(hold==1)
			layerparams_selwave[trunc(jj/paramsperlayer)][3*kk+3]=48
		else
			layerparams_selwave[trunc(jj/paramsperlayer)][3*kk+3]=32
		endif
		kk+=1
		jj+=1
	endfor
		
	Variable multilayer=str2num(moto_str("multilayer"))
	
	string holdref
	if(multilayer==1)
		for(ii=1;ii<4*str2num(moto_str("Vmullayers"));ii+=1)
			holdref="h"+num2istr(ii)
			hold=str2num(holdstring[ii+paramsperlayer*nlayers+baselength-1])
			checkbox $holdref,value=hold,win=multilayerpanel
		endfor
	endif
	checkbox useerrors,value=str2num(moto_str("useerrors")),win=reflectivitypanel
	checkbox usedqwave,value=str2num(moto_str("usedqwave")),win=reflectivitypanel
	moto_repstr("fitcursors","0")
	popupmenu plottype,mode=str2num(moto_str("plotyp")),win=reflectivitypanel
	popupmenu plottype,mode=str2num(moto_str("plotyp")),win=reflectivitygraph
	checkbox usemultilayer,value=str2num(moto_Str("multilayer")),win=reflectivitypanel
	Wave resolution
	resolution[0]=str2num(moto_Str("res"))
	setvariable res,value=resolution[0],win=reflectivitypanel

End

Function Moto_savecoefficients(ctrlName) : ButtonControl
	String ctrlName
	//this function saves the fit coefficients (parameters) to file
	//the idea is that you can print to a wave, even if you don't have the full version of IGOR
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol

	//choose from all the coefficient waves on offer
	string coefwaves=Wavelist("coef*",";","")
	variable savechoice=0
	prompt savechoice,"which coefficient wave do you want to save?",popup,coefwaves
	Doprompt "which coefficient wave do you want to save?",savechoice
	if(V_flag==1)
		abort
	endif

	string tempcoef=Stringfromlist(savechoice-1,coefwaves)
	Wave tempcoefs=$tempcoef
	string tempcoef_txt=tempcoef+".itx"
	string fname=Moto_doSaveFileDialog(tempcoef_txt)

	if(strlen(fname)==0)
		ABORT
	endif
	variable refnum

	//open the file for writing
	open refnum as fname

	//we want to save the wave as an IGOR wave, which means that you can double click it and it automatically loads the parameters up
	//into the reflectivity panel
	String temp,temp2
	temp="IGOR"
	fprintf refnum,"%s\r",temp
	temp="X plotcalcref()"
	fprintf refnum,"%s\r",temp
	temp="WAVES/D "+tempcoef
	fprintf refnum,"%s\r",temp
	fprintf refnum,"%s\r","BEGIN"
	wfprintf refnum, "\t%g\r" tempcoefs		//this prints the coefwave to file.
	fprintf refnum,"%s\r","END"
	String coefnote=note(tempcoefs)

	//if you do a global fit then it's entirely likely that the coefficient wave won't be updated properly
	if(strlen(coefnote)<10)
		coefnote=Moto_dummymotofitstring()
		variable baselength = str2num(stringbykey("baselength",coefnote))
		variable paramsperlayer = 4
		
		coefnote=Replacestringbykey("coefwave",coefnote,tempcoef)
		coefnote=Replacestringbykey("plotyp",coefnote,moto_str("plotyp"))
		Wave SLD
		coefnote=Replacestringbykey("SLDpts",coefnote,num2istr(numpnts(SLD)))
		variable nlayers=tempcoefs[0],num_Vmullayers
		if(numpnts(tempcoefs)>paramsperlayer*nlayers+baselength)
			coefnote=Replacestringbykey("multilayer",coefnote,"1")
			num_Vmullayers=(1/paramsperlayer)*(numpnts(tempcoefs)-(paramsperlayer*nlayers+baselength))
			coefnote=Replacestringbykey("Vmullayers",coefnote,num2istr(num_Vmullayers))
		endif
	endif

	//this following sections writes the wavenote to file so that it can be used to reconstruct the coefficient wave
	String tempmotofitcontrol=coefnote
	String writestring = ""
	variable ii
	do
		writestring = ""
		for(ii=0;ii<4 && itemsinlist(tempmotofitcontrol)>0 ; ii+=1)	
			writestring += stringfromlist(0,tempmotofitcontrol,";")+";"
			tempmotofitcontrol = removelistitem(0,tempmotofitcontrol,";")
		endfor
		
		temp="X Note "+tempcoef+", \""+writestring+"\""
		fprintf refnum, "%s\r", temp
	while (itemsinlist(tempmotofitcontrol)>0)

	close refnum

End


Function/S moto_doSaveFileDialog(name)
	String name
	String msg="choose file name"
	Variable refNum
	//	String message = "Save the file as"
	String outputPath
	
	Open/D/M=msg refNum as name
	outputPath = S_fileName
	return outputPath
End

Function Moto_savefitwave(ctrlName) : ButtonControl
	String ctrlName
	//this function saves a copy of the fit to file.
	//note that the fitwaves that are saved are based on the waves appearing in the ywave popup.

	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:motofitcontrol

	//this section of code converts any GFIT waves (from global fif) into 2 separate waves, otherwise 1D wave 
	// won't save properly into 2D wave
	String dataR=listmatch(Wavelist("*R",";",""),"!coef*"),temp,ywave,xwave,ewave
	String anyGFITS=listmatch(dataR,"gfit*")
	variable ii

	for(ii=0;ii<itemsinlist(anyGFITS,";");ii+=1)
		String iterGFIT=stringfromlist(ii,anyGFITS)
		string yfitname=itergfit,xfitname
		xfitname=cleanupname((removeending(yfitname)+"q"),0)
		wave ygfitwave=$yfitname
		duplicate/o ygfitwave,$xfitname
		wave xgfitwave=$xfitname
		xgfitwave=leftx(ygfitwave)+p*deltax(ygfitwave)
	endfor

	//now select all the different pairs of R+Q waves you can
	string allRwaves=listmatch(dataR,"!GRes*")
	variable savechoice=0
	prompt savechoice,"which set of R+Q waves do you want to save?",popup,allRwaves
	Doprompt "which set of R+Q waves do you want to save?",savechoice
	if(V_flag==1)
		abort
	endif
	string fitywave=Stringfromlist(savechoice-1,allRwaves),fitxwave
	if(cmpstr(fitywave,"theoretical_R")==1)
		fitxwave="theoretical_q"
	else
		fitxwave=cleanupname((removeending(fitywave)+"q"),0)
	endif

	string tempy=fitywave+".txt"
	string fname
	
	//why not convert them back to R vs Q? Then you can load in again
	variable plotyp=str2num(moto_str("plotyp"))
	Wave dummy
	switch (plotyp)
		case 1:
			Moto_toLogLin($fitxwave,$fitywave,dummy,0)
			break
		case 2:
			break
		case 3:
			Moto_toRQ4($fitxwave,$fitywave,dummy,0)
			break
	endswitch
	
	//the idea is that you can print to a wave to save the fit data
	//this gets the filename for writing. but doesn't actually open it.
	fname=Moto_DoSaveFileDialog(tempy)
	if(strlen(fname)==0)
		ABORT
	endif
	variable refnum
	open refnum as fname
	wfprintf refnum, "%g \t %g\r",$fitxwave,$fitywave	//this prints the wave to file.
	close refnum

	//convert back the waves you changed
	Wave dummy
	switch (plotyp)
		case 1:
			Moto_toLogLin($fitxwave,$fitywave,dummy,1)
			break
		case 2:
			break
		case 3:
			Moto_toRQ4($fitxwave,$fitywave,dummy,1)
			break
	endswitch
End

	
Function Moto_fringespacing(ctrlName,nofringes,varStr,varName) : SetVariableControl
	String ctrlName
	Variable nofringes
	String varStr
	String varname
	//this function calculates layer thickness from fringespacing. You need to put the cursors on the graph
	//at a multiple position of the fringe.
	//called by: makefringespace
	NVAR/Z fringe = root:packages:motofit:Reflectivity:tempwaves:fringe
	Variable delq
	if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
		if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
			abort "The cursors are not on the same wave. Please move them so that they are."
		endif
	else
		abort "The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
	endif
	delq=abs(hcsr(B,"")-hcsr(A,""))
	fringe=nofringes*2*Pi/(delq)
End

Function Moto_addcursor(ctrlname) :Buttoncontrol
	string ctrlname
	//adds cursors to the reflectivity graph.

	string cursors=moto_str("dataset")
	string traces = tracenamelist("reflectivitygraph",";",5)

	if(whichlistitem(cursors, traces)>-1)
		cursor/A=1/W=reflectivitygraph A,$cursors,leftx($cursors)
		cursor/A=1/W=reflectivitygraph B,$cursors,numpnts($cursors)-1
	endif
	Doupdate
End

Function Moto_cursorleft(ctrlname) :Buttoncontrol
	string ctrlname
	//this function moves a cursor to the left

	variable a=pcsr(A),b=pcsr(B)
	string cursors=moto_str("dataset")
	if(cmpstr(ctrlname,"cursorleftA")==0)
		cursor/A=1/W=reflectivitygraph A,$cursors,(a-1)
	endif
	if(cmpstr(ctrlname,"cursorleftB")==0)
		cursor/A=1/W=reflectivitygraph B,$cursors,(b-1)
	endif
	Doupdate
End

Function Moto_cursorright(ctrlname) :Buttoncontrol
	string ctrlname
	//this function moves a cursor to the right.
	string cursors=moto_str("dataset")
	variable a=pcsr(A),b=pcsr(B)
	if(cmpstr(ctrlname,"cursorrightA")==0)
		cursor/A=1/W=reflectivitygraph A,$cursors,(a+1)
	endif
	if(cmpstr(ctrlname,"cursorrightB")==0)
		cursor/A=1/W=reflectivitygraph B,$cursors,(b+1)
	endif
	Doupdate
End

Function Moto_FTreflectivityHook(SV_Struct)
	STRUCT WMSetVariableAction &SV_Struct
	Moto_FTreflectivity()
End

Function Moto_FTreflectivity()
	//this function estimates layer thicknesses from the FFT of the reflectivity curve.
	//It uses the cursors to determine the correct zone for transforming.
	//DONT transform the critical edge!
	//if you have two layers producing fringes, then you will get a peak for each of 
	//the layers plus a third peak, which is equal to the sum of the two

	variable plotyp=Str2num(moto_str("plotyp"))
	string xdata,ydata
	String dfSav = GetDataFolder(1)
	
	//get datasets name
	controlinfo/W=reflectivitypanel dataset
	ydata = S_Value
	
	if(cmpstr(S_Value,"_none_")==0 ||cmpstr(S_Value,"theoretical_q")==0 )
		ydata ="theoretical_R"
	endif
	xdata=cleanupname(removeending(ydata)+"q",0)
	
	if(!waveexists($ydata))
		setdatafolder $dfSav
		abort
	endif
	ydata = GetWavesDataFolder($ydata, 2 )
	xdata = GetWavesDataFolder($xdata, 2 )
	
	//if the data waves aren't the same length don't do the FT.
	Variable ylength=numpnts($ydata),xlength=numpnts($xdata)
	if(abs(ylength-xlength)>0)
		return 0
	endif
	
	wave y=$ydata
	wave x=$xdata
	
	if(Waveexists(y)!=1)
		return 0
	endif
	
	Duplicate/o y root:packages:motofit:reflectivity:tempwaves:tempy
	Duplicate/o x root:packages:motofit:reflectivity:tempwaves:tempx
	Setdatafolder root:packages:motofit:reflectivity:tempwaves
	
	Wave/z tempy,tempx,dummy
	sort tempx,tempx,tempy
	
	NVAR/z FThiQ = root:packages:motofit:Reflectivity:tempwaves:FThiQ
	NVAR/z FTlowQ = root:packages:motofit:Reflectivity:tempwaves:FTlowQ
	variable level,start,finish

	if(NVAR_exists(FTlowQ)!=1)
		variable/g root:packages:motofit:Reflectivity:tempwaves:FTlowQ
		NVAR/z FTlowQ = root:packages:motofit:Reflectivity:tempwaves:FTlowQ
		
		if(plotyp==1)
			level = tempy[0]-1
			findlevel/q tempy,level
			start=ceil(v_levelx)
		elseif(plotyp==2)
			level=tempy[0]/10
			findlevel/q tempy,level
			start=ceil(v_levelx)
		elseif(plotyp==3)
			Moto_toRQ4(tempx,tempy,dummy,0)
			level=tempy[0]/10
			start=ceil(v_levelx)
			Moto_toRQ4(tempx,tempy,dummy,1)
		endif
		FTlowQ = tempx[start]
		start = binarysearch(tempx,FTlowQ)
	elseif(NVAR_Exists(FTlowQ))
		start = binarysearch(tempx,FTlowQ)
	endif
	
	if(NVAR_exists(FThiQ)!=1)
		variable /g root:packages:motofit:Reflectivity:tempwaves:FThiQ
		NVAR/z FThiQ = root:packages:motofit:Reflectivity:tempwaves:FThiQ
		FThiQ=tempx[numpnts(tempx)-1]
		finish=binarysearch(tempx,FThiQ)
	elseif(NVAR_Exists(FThiQ))
		finish = binarysearch(tempx,FThiQ)
		if(finish==-2)
			finish = numpnts(tempx)-1
		endif
	endif
			
	if (finish<start)
		variable temp
		temp=start
		start=finish
		finish=temp
	endif
	Deletepoints 0,start, tempy,tempx
	Deletepoints (finish-start+1),(ylength-finish-1),tempy,tempx
	
	Variable FFTlength=numpnts(tempy)
	if(mod(FFTlength,2)>0)
		FFTlength+=1					//the FFT only works on waves with even numbers
	endif
	Make/o/d/n=(FFTlength) FFTwave
	
	if(FFTlength<8)
		setdatafolder $DFsav
		abort
	endif
	
	if(plotyp==2)
		tempy*=tempx^4
	endif
	if(plotyp==1)
		tempy=alog(tempy)
		tempy*=tempx^4
	endif
	
	Interpolate2/T=2/N=(FFTlength)/E=2/Y=FFTWave tempx,tempy 
		
	FFT/z/pad={8*numpnts(FFTwave)}/dest=W_FFT/winf=cos1 FFTwave
	make/o/d/n=(numpnts(W_FFT)) FFToutput
	FFToutput=cabs(W_FFT)
	Variable x2=pnt2x(W_FFT,2)
	Deletepoints 0,2,FFToutput
	Setscale/P x,2*Pi*x2,deltax(W_FFT)*2*Pi,FFToutput

	setdatafolder $DFsav
	return 0
End

Function Moto_FTplotHook(s)
	STRUCT WMWinHookStruct &s
	if(s.eventcode==-1)
		return 0
	endif
	Variable rval= 0
	switch(s.eventCode)
		case 5:
			setactivesubwindow reflectivitypanel
			break;
		case 7:
			getaxis/w=reflectivitypanel#FFTplot /Q bottom
			string pos="layer thickness: "+num2str(s.pointnumber*(V_max-V_min)+V_min)+" A"
			//		Textbox/w=reflectivitypanel#FFTplot/K text0
			TextBox/C/w=reflectivitypanel#FFTplot/N=text0/F=0/A=MC/X=40/y=40 pos
			doupdate
			rval=1
			break
	EndSwitch

	return rval
End

Function Moto_changeconstraint(ctrlname): ButtonControl
	String ctrlname
	//this function either adds or removes a constraint setvariable control in the second tab of the reflectivity panel.
	Variable conlength
	String conname
	if(cmpstr(ctrlname,"addconstraint")==0)
		if(waveexists(root:packages:motofit:reflectivity:Constraints)==0)
			Make/T/n=1 root:packages:motofit:reflectivity:constraints
			SetVariable constraint0,pos={311,61},size={236,16},title="Constraint0",value= root:packages:motofit:reflectivity:constraints[0]
		else
			conlength=numpnts(root:packages:motofit:reflectivity:constraints)
			redimension/n=(conlength+1) root:packages:motofit:reflectivity:constraints
			conname="constraint"+num2istr(conlength)
			Variable conpos=61+(20*conlength)
			SetVariable $conname,pos={311,conpos},size={236,16},title=conname,value= root:packages:motofit:reflectivity:constraints[conlength]
		endif
	endif
	
	if(cmpstr(ctrlname,"removeconstraint")==0)
		if(waveexists(root:packages:motofit:reflectivity:Constraints)==0)
			ABORT "there is no constraints wave"
		endif
		conlength=numpnts(root:packages:motofit:reflectivity:constraints)
		conname="constraint"+num2istr(conlength-1)
		if(conlength==1)
			killwaves/Z root:packages:motofit:reflectivity:constraints
			killcontrol/W=reflectivitypanel $conname
		else
			redimension/n=(conlength-1) root:packages:motofit:reflectivity:constraints
			killcontrol/W=reflectivitypanel $conname
		endif
	endif
End

Function Moto_add_chemical(ctrlName) : ButtonControl
	String ctrlName
	//this functions adds a new chemical to the SLD database
	string saveDF = getdatafolder(1)
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	String/G chemicals
	if (waveexists(chemical)==0)
		make/T/n=0 chemical,chemical_composition
		make/d/n=0 Mass_Density,SLD_X_rays,SLD_neutrons
	endif
	variable numchemical=numpnts(chemical)
	redimension/N=(numchemical+1) chemical,SLD_neutrons,SLD_X_rays,Mass_density, chemical_composition
	String chem,chemcom
	Variable SLDn,SLDx,rho
	Prompt chem, "Name of chemical"
	Prompt SLDn, "neutron SLD"
	Prompt SLDx, "X-ray SLD"
	Prompt rho, "Mass density"
	Prompt chemcom, "Chemical Composition"
	Doprompt "Enter the chemical details" chem,SLDn,SLDx,rho,chemcom
	if(V_flag==1)
		setdatafolder $saveDF
		abort
	endif
	//Wave/T chemical,chemical_composition
	//Wave SLD_neutrons,SLD_X_rays,Mass_density
	chemical[(numchemical+1)]=chem
	SLD_neutrons[numchemical+1]=SLDn
	SLD_X_rays[numchemical+1]=SLDx
	Mass_density[numchemical+1]=rho
	chemical_composition[numchemical+1]=chemcom
	chemicals+=chem+";"
	Setdatafolder root:
End

Function Moto_Loaddatabase(ctrlName) : ButtonControl
	String ctrlName
	//this function loads an SLDdatabase
	SetDatafolder root:packages:motofit:reflectivity:SLDdatabase 
	String/G chemicals=""
	Loadwave/q/o/w/k=0/j/L={0,0,0,0,0}
	if(V_flag==0)
		ABORT
	endif
	Wave/T chemical
	variable ii=0
	do 
		chemicals+=chemical[ii]+";"
		ii+=1
	while(ii<numpnts(chemical))
	Setdatafolder root:
End

Function Moto_Savedatabase(ctrlName) : ButtonControl
	String ctrlName
	//this function saves the SLDdatabase
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	string name=""
	String fname
	fname=Moto_DoSaveFileDialog(name)
	if(strlen(fname)==0)
		ABORT
	endif
	variable refnum
	open refnum as fname
	fprintf refnum, "chemical,chemical_composition,SLD_neutrons,SLD_X_rays,Mass_density\r"
	wfprintf refnum, "%s\t%s\t%g\t%g\t%g\r",chemical,chemical_composition,SLD_neutrons,SLD_X_rays,Mass_Density
	close refnum
	Setdatafolder root:
End


Function Moto_updateSLDdisplay(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	//this function changes the displayed SLD values (in the SLDpanel), depending on what chemical was selected from the chemicals popup. 
	string savedf = getdatafolder(1)
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	Wave/T chemical,chemical_composition
	Wave SLD_neutrons,SLD_X_rays,Mass_density
	Setvariable neutronSLD value=SLD_neutrons[popnum-1]
	Setvariable XraySLD value=SLD_X_rays[popnum-1]
	Setvariable rho value=Mass_density[popnum-1]
	Setvariable chemcom value=chemical_composition[popnum-1]
	Setdatafolder savedf
End

Function Moto_SLDdatabase() : Panel
	//this function creates a panel in which the user can edit the SLD database
	String savedf=getdatafolder(1)
	
	String winexist=WinList("SLDpanel",";","WIN:64")
	if(strlen(winexist)>0)
		Dowindow/F SLDpanel
		setdatafolder savedf
		ABORT
	else
		if(datafolderexists("root:packages:motofit:reflectivity:SLDdatabase")==0)
			newdatafolder/o root:packages
			newdatafolder/o root:packages:motofit
			newdatafolder/o root:packages:motofit:reflectivity
			Newdatafolder/o root:packages:motofit:reflectivity:SLDdatabase
		endif
		PauseUpdate; Silent 1		// building window...
		NewPanel /k=1/W=(0,0,520,320)
		Tabcontrol sldtab size = {511,305},tabLabel(0)="calculator",proc=Moto_SldtabControl,fSize=12
		Tabcontrol sldtab size = {511,305},tabLabel(1)="database",fSize=12
		Tabcontrol sldtab size = {511,305},tabLabel(2)="SLDmixing",fSize=12
		
		Button Addchemical,pos={20,50},size={110,30},proc=Moto_add_chemical,title="Add chemical"
		Button Addchemical,fSize=12
		PopupMenu listchemicals,pos={197,50},size={203,24},proc=Moto_updateSLDdisplay,title="List of chemicals"
		PopupMenu listchemicals,fSize=12
		PopupMenu listchemicals,mode=3,bodyWidth= 100,popvalue="_none_",value= #"root:packages:motofit:reflectivity:SLDdatabase:chemicals"
		Button loaddatabase,pos={20,85},size={110,30},proc=Moto_Loaddatabase,title="load database"
		Button loaddatabase,fSize=12
		SetVariable neutronSLD,pos={220,90},size={180,19},title="Neutron SLD",fSize=12
		SetVariable neutronSLD,value= k0,bodyWidth= 100
		SetVariable XraySLD,pos={236,130},size={164,19},title="X-ray SLD",fSize=12
		SetVariable XraySLD,value= k0,bodyWidth= 100
		SetVariable rho,pos={217,170},size={183,19},title="Mass density",fSize=12
		SetVariable rho,value= k0,bodyWidth= 100
		Button savedatabase,pos={20,120},size={110,30},proc=Moto_Savedatabase,title="Save database"
		Button savedatabase,fSize=12
		SetVariable chemcom,pos={162,210},size={238,19},title="Chemical Composition"
		SetVariable chemcom,fSize=12,value= S_Value,bodyWidth= 100
		SetVariable chemcom,value= S_Value
		DoWindow/C/T SLDpanel,"SLDdatabase"
		
		SetVariable chemical,pos={22,31},size={331,23},title="Chemical Formula",fSize=12
		SetVariable chemical,limits={inf,inf,0},value= root:packages:motofit:reflectivity:SLDdatabase:calcSLD_chemical,bodyWidth= 200,proc = Moto_SLDcalculateSetvariable
		SetVariable calcMASSDENSITY,pos={18,60},size={200,23},title="Mass density",fSize=12,proc=Moto_SLDcalculateSetvariable
		SetVariable calcMASSDENSITY,limits={0,100,0.02},value= root:packages:motofit:reflectivity:SLDdatabase:calcSLD_massdensity
		SetVariable calcMolVol,pos={236,60},size={230,23},title="Molecular volume (A^3)",fSize=12,proc=Moto_SLDcalculateSetvariable
		SetVariable calcMolVol,limits={0,inf,1},value= root:packages:motofit:reflectivity:SLDdatabase:calcSLD_molvol
		
		SetVariable calcNeutronSLD,pos={57,171},size={294,23},title="Neutron SLD",fSize=12
		SetVariable calcNeutronSLD,limits={-inf,inf,0},value= root:packages:motofit:reflectivity:SLDdatabase:calcSLD_neutron,bodyWidth= 197
		SetVariable calcXRAYSLD,pos={82,208},size={269,23},title="Xray SLD",fSize=12
		SetVariable calcXRAYSLD,limits={-inf,inf,0},value= root:packages:motofit:reflectivity:SLDdatabase:calcSLD_Xray,bodyWidth= 197
		Button CALCULATE,pos={194,100},size={100,60},title="Calculate",fSize=12,proc = Moto_SLDcalculateButton
		Button AddToDataBase,pos={194,235},size={100,60},title="Add to \r database",fSize=12,proc = Moto_addchemicalfromcalculator
		
		//make the variables for the mixing
		variable/g root:packages:motofit:reflectivity:SLDdatabase:mixSLD1=6.36,root:packages:motofit:reflectivity:SLDdatabase:mixSLD2=-0.56
		variable/g root:packages:motofit:reflectivity:SLDdatabase:mixOverallSLD=6.36
		variable/g root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac1=1,root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac2=0
		NVAR/z mixOverallSLD = root:packages:motofit:reflectivity:SLDdatabase:mixOverallSLD
				
		SetVariable mixSLD1,pos={29,57},size={200,23},title="SLD 1st component",fSize=12,value =root:packages:motofit:reflectivity:SLDdatabase:mixSLD1
		Setvariable mixSLD1,proc = Moto_mixCalculateSetvariable,limits={-inf,inf,0.01}
		SetVariable mixSLD2,pos={243,57},size={200,23},title="SLD 2nd component",fSize=12,value=root:packages:motofit:reflectivity:SLDdatabase:mixSLD2
		Setvariable mixSLD2, proc = Moto_mixCalculateSetvariable,limits={-inf,inf,0.01}
		SetVariable mixvolfrac1,pos={29,105},size={200,23},title="vol. frac. 1st component",fSize=12,value=root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac1
		Setvariable mixvolfrac1, limits={0,1,0.01},proc= Moto_mixCalculateSetvariable
		SetVariable mixvolfrac2,pos={243,105},size={200,23},title="vol. frac. 2nd component",fSize=12,value=root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac2
		Setvariable mixvolfrac2, limits={0,1,0},proc = Moto_mixCalculateSetvariable
		setvariable mixoverallSLD,pos={164,246},size={160,23},title="Overall SLD",fSize=12,value=mixoverallSLD,limits={-inf,inf,0.01},proc=Moto_mixCalculateSetvarReverse
		
	endif
	
	SetDatafolder root:packages:motofit:reflectivity:SLDdatabase 
	String/G chemicals=""
	//if the SLDdatabase is stored in the MOTOFit directory then you can use a function path
	//to determine where it is.  This is because on Macintoshs the filenames and paths are different 
	String path=FunctionPath("MOTOFIT")
	variable pathlen=itemsinlist(path,":")
	path=Removelistitem(pathlen-1,path,":")
	path+="SLDdatabase.txt"
	Loadwave/q/A/o/w/k=0/j/L={0,0,0,0,0} path
	Wave/T chemical
	variable ii=0
	do 
		chemicals+=chemical[ii]+";"
		ii+=1
	while(ii<numpnts(chemical))
	
	//load the scattering lengths from a textfile
	Moto_SLDLoadScatteringlengths()
	
	//select the calculation tab to start with
	STRUCT WMTabControlAction TC_Struct
	TC_Struct.tab=0
	Moto_SldtabControl(TC_Struct)
	
	Setdatafolder savedf
End

Function Moto_SldtabControl(TC_Struct)
	STRUCT WMTabControlAction &TC_Struct
	Variable tab=TC_Struct.tab
	//this function controls the visibility of the controls when different tabs are selected in the reflectivity panel.
	//first tab controls
	
	if(TC_Struct.eventcode==-1)
		return 0
	endif
	tabcontrol sldtab,value=tab,win=SLDpanel
	
	Button Addchemical,disable = (tab!=1)
	PopupMenu listchemicals,disable = (tab!=1)
	Button loaddatabase,disable = (tab!=1)
	SetVariable neutronSLD,disable = (tab!=1)
	SetVariable XraySLD,disable = (tab!=1)
	SetVariable rho,disable = (tab!=1)
	Button savedatabase,disable = (tab!=1)
	SetVariable chemcom,disable = (tab!=1)

	SetVariable chemical,disable = (tab!=0)
	SetVariable chemical,disable = (tab!=0)
	SetVariable calcMASSDENSITY,disable = (tab!=0)
	SetVariable calcMolVol,disable = (tab!=0)
	
	SetVariable calcNeutronSLD,disable = (tab!=0)
	SetVariable calcXRAYSLD,disable = (tab!=0)
	Button CALCULATE,disable = (tab!=0)
	Button AddToDataBase,disable = (tab!=0)
	
	SetVariable mixSLD1,disable = (tab!=2)
	SetVariable mixSLD2,disable = (tab!=2)
	SetVariable mixvolfrac1,disable = (tab!=2)
	SetVariable mixvolfrac2,disable = (tab!=2)
	SetVariable mixoverallSLD,disable = (tab!=2)
		
End

Function Moto_SLDintocoef_Cref(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	//this function allows the user to select a chemical from the SLD database (either neutron or X-ray)
	//and put the value directly into the SLD position for that particular layer.
	Wave neutronsld=$"root:packages:motofit:reflectivity:SLDdatabase:SLD_neutrons"
	Wave xraysld=$"root:packages:motofit:reflectivity:SLDdatabase:SLD_X_rays"

	controlinfo $ctrlname
	if(cmpstr(S_Value,"_none_")==0 & popnum==9999)
		Setdatafolder root:
		return 0
	endif

	variable entry=V_Value
	variable layer,SLD
	string whichlayer=ctrlname[0,3],layerchem=ctrlname

	String n_or_x=moto_str("SLDtype")

	Strswitch (n_or_x)
		case "neutron":
			SLD=neutronSLD[entry-1]
			break
		case "Xray":
			SLD=xraySLD[entry-1]
			break
	endswitch

	string isNan=num2str(SLD)
	if(cmpstr(isNan,"NaN")==0)
		Doalert 0, "No entered value of this type for this compound\r\r"+layerchem
		return 0
	endif

	Wave c=$"root:coef_Cref"
	Wave w=$"root:multilay"
	strswitch(whichlayer)	
		case "topc":
			c[2]=SLD
			break				
		case "base":
			c[3]=SLD
			break
		case "chem":
			layer=str2num(layerchem[4,1000])
			c[layer*4+3]=SLD
			break
		case "mulc":
			layer=str2num(layerchem[7,1000])
			w[4*layer-3]=SLD
			break
		default:							// optional default expression executed
			// when no case matches
	endswitch
	
	Setdatafolder root:

	//when you update them all only update after the last one
	if(popnum==9999)
	else
		Moto_update()
	endif

End


Function Motofit_Varproc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	moto_repstr(ctrlname,varstr)	
	Moto_update()
End

Function Motofit_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	moto_repstr(ctrlname,popstr)
	if(cmpstr(ctrlname,"dataset")==0)
		Moto_FTreflectivity()
	endif
End

Function Motofit_CheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	moto_repstr(ctrlname,num2str(checked))

End

Function/S Moto_str(key)
	String key
	//motofitcontrol is the global string that controls program behaviour
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:Motofitcontrol
	return Stringbykey(key,motofitcontrol)
End

Function Moto_repstr(key,str)
	String key,str
	SVAR/Z Motofitcontrol=root:packages:motofit:reflectivity:Motofitcontrol
	motofitcontrol=replacestringbykey(key,motofitcontrol,str)
	Wave/z coef_Cref,coef_multicref
	if(Waveexists(coef_Cref)==1)
		note/k coef_Cref
		note coef_Cref,Motofitcontrol
	endif
	if(Waveexists(coef_multicref)==1)
		note/k coef_multicref
		note coef_multicref, motofitcontrol
	endif
End

Function getrid()

	String windows=Winlist("*",";","win:67")
	string choice
	variable ii=0
	for(ii=0;ii<itemsinlist(windows);ii+=1)
		choice=Stringfromlist(ii,windows)
		dowindow/K $choice
	endfor
	killwaves/A/Z
	killdatafolder/Z root:

End

Function Moto_removeNAN(q,R,dR,dQ)
	Wave q,R,dR,dQ
	Variable ii=0
	for(ii=0;ii<numpnts(q);ii+=1)
		if(numtype(q[ii])!=0 || numtype(R[ii])!=0 || R[ii]<=0)
			if(Waveexists(dq) && Waveexists(dR))
				deletepoints ii,1,q,R,dR,dQ
			elseif(Waveexists(dR))
				deletepoints ii,1,q,R,dR
			else
				deletepoints ii,1,q,R
			endif
			
			ii-=1
		endif
	endfor

End

Function Moto_localchi2() //menu call
	Wave coef_Cref = root:coef_Cref ,coef_multiCref=root:coef_multicref
	string callfolder=Getdatafolder(1)
			
	controlinfo/w=reflectivitypanel dataset
	string dataset_y=S_value
	if(cmpstr(S_Value,"_none_")==0)
		setdatafolder $callfolder
		ABORT "Please enter a dataset"
	endif
	
	String dataset_x=cleanupname(removeending(dataset_y)+"q",0)
	String dataset_e=cleanupname(removeending(dataset_y)+"e",0)
	Wave yy=$dataset_y,xx=$dataset_x, ee=$dataset_e

	Setdatafolder root:packages:motofit:reflectivity:tempwaves

	controlinfo/w=reflectivitypanel usemultilayer
	if(V_Value)
		Wave parwave=coef_multicref
	else
		Wave parwave=coef_cref
	endif
	
	duplicate/o parwave, root:packages:motofit:reflectivity:tempwaves:tempparwave
	Wave tempparwave = root:packages:motofit:reflectivity:tempwaves:tempparwave
	
	//do you want to examine a 1D or 2D chi2map
	String dim
	Prompt dim,"Do you want to examine a 1D or 2D chi2map?",popup,"1D;2D"
	Doprompt "Examine chi2map",dim
	if(V_flag==1)
		setdatafolder $callfolder
		abort
	endif
	strswitch (dim)
		case "1D":
			try
				controlinfo/w=reflectivitypanel useerrors
				if(V_Value & waveexists(ee))
					Moto_localchi2graph1D("motofit",tempparwave,yy,xx,ee)	
				else
					duplicate/o yy,temp_e
					temp_e=1
					Moto_localchi2graph1D("motofit",tempparwave,yy,xx,temp_e)
				endif
			catch
			endtry
			break
		case "2D":
			try
				controlinfo/w=reflectivitypanel useerrors
				if(V_Value & waveexists(ee))
					Moto_localchi2graph2D("motofit",tempparwave,yy,xx,ee)	
				else
					duplicate/o yy,temp_e
					temp_e=1
					Moto_localchi2graph2D("motofit",tempparwave,yy,xx,temp_e)
				endif
			catch
			endtry
			break
	endswitch
	killwaves/z enum,tempcoefs,holdwave
	Setdatafolder callfolder
End

Function Moto_localchi2graph1D(funcname,parwave,yy,xx,ee)
	String funcname
	wave parwave,yy,xx,ee
	Struct GEN_optimisation gen
	Wave gen.GEN_yy=yy
	Wave gen.GEN_xx=xx
	Wave gen.GEN_ee=ee
	Wave gen.GEN_parwave=parwave
	
	variable whichParam=1,explorelimit=5
	prompt whichParam,"which variable would you like to inspect?"
	prompt explorelimit,"what percentage either side would you like to explore?"
	Doprompt "lets inspect the Chi2 map for a parameter?",whichParam,explorelimit
	if(V_flag==1)
		abort
	endif
	//if the parameter is valid then abort
	if(whichparam>numpnts(parwave)-1 | whichparam==0)
		abort "parameter chosen is outside the limits"
	endif
	
	gen.GEN_whattype=Numberbykey("N_Params",Functioninfo(funcname))
	if(gen.GEN_whattype==2)
		Funcref GEN_fitfunc gen.fan=$funcname
	elseif(gen.GEN_whattype==3)
		Funcref GEN_allatoncefitfunc gen.fin=$funcname
	endif
	
	make/o/n=1 tempcoefs
	tempcoefs[0]=parwave[whichparam]
	Wave gen.GEN_pvector=tempcoefs
	
	duplicate/o gen.GEN_xx, enum
	
	gen.GEN_holdbits = bin2dec(GEN_holdallstring(numpnts(parwave)))-2^whichparam
	
	variable chi2,ii,value,increm,increment
	Make/o/d/n=201 chi2map
	increm=explorelimit*gen.GEN_parwave[whichparam]/100
	increment=increm/((numpnts(chi2map)-1)/2)
	if(strlen(winlist("chi2map0",";",""))>0)
	else
		display/k=1/n=chi2map chi2map
		label bottom "parameter"
		label left "Chi2"
	endif
	
	variable left=gen.GEN_parwave[whichparam]-increm,right=gen.GEN_parwave[whichparam]+increm
	setscale/P x,left,increment, chi2map
	
	for(ii=0;ii<numpnts(chi2map);ii+=1)
		value=left+increment*ii
		gen.GEN_pvector[whichparam]=value
		chi2map[ii]=GEN_optimise#GEN_chi2(gen)
	endfor
End

Function Moto_localchi2graph2D(funcname,parwave,yy,xx,ee)
	String funcname
	wave parwave,yy,xx,ee
	Struct GEN_optimisation gen
	Wave gen.GEN_yy=yy
	Wave gen.GEN_xx=xx
	Wave gen.GEN_ee=ee
	Wave gen.GEN_parwave=parwave
	
	variable whichParam=1,whichparam2=2,explorelimit=5,explorelimit2=5
	prompt whichParam,"which variable would you like to inspect?"
	prompt whichParam2,"which variable would you like to inspect?"
	prompt explorelimit,"what percentage either side would you like to explore?"
	prompt explorelimit2,"what percentage either side would you like to explore?"
	Doprompt "lets inspect the Chi2 map for a parameter?",whichParam,whichParam2,explorelimit,explorelimit2
	if(V_flag==1)
		abort
	endif
	//if the parameter is valid then abort
	if(whichparam>numpnts(parwave)-1 | whichparam==0)
		abort "parameter chosen is outside the limits"
	endif
	if(whichparam2>numpnts(parwave)-1 | whichparam2==0)
		abort "parameter chosen is outside the limits"
	endif
	
	string callfolder=Getdatafolder(1)
	Setdatafolder root:
	
	gen.GEN_whattype=Numberbykey("N_Params",Functioninfo(funcname))
	if(gen.GEN_whattype==2)
		Funcref GEN_fitfunc gen.fan=$funcname
	elseif(gen.GEN_whattype==3)
		Funcref GEN_allatoncefitfunc gen.fin=$funcname
	endif
	if(whichparam2<whichparam)
		variable temp=whichparam
		whichparam=whichparam2
		whichparam2=temp
	endif
	
	make/o/n=2 tempcoefs
	tempcoefs[0]=parwave[whichparam]
	tempcoefs[1]=parwave[whichparam2]
	Wave gen.GEN_pvector=tempcoefs
	
	duplicate/o gen.GEN_xx, enum
	gen.GEN_holdbits = bin2dec(GEN_holdallstring(numpnts(parwave)))-(2^whichparam)-(2^whichparam2)
	
	variable chi2,ii,value,increm,increment,increm2,increment2,jj
	Make/o/d/n=(51,51) chi2map
	increm=0.01*explorelimit*gen.GEN_parwave[whichparam]
	increm2=0.01*explorelimit2*gen.GEN_parwave[whichparam2]
	increment=increm/((dimsize(chi2map,0)-1)/2)
	increment2=increm2/((dimsize(chi2map,0)-1)/2)
	//	if(strlen(winlist("chi2map0",";",""))>0)
	//	else
	//		display/k=1/n=chi2map chi2map
	//		label bottom "parameter"
	//		label left "Chi2"
	//	endif

	variable left=gen.GEN_parwave[whichparam]-increm,right=gen.GEN_parwave[whichparam]+increm
	variable left2=gen.GEN_parwave[whichparam2]-increm2,right2=gen.GEN_parwave[whichparam2]+increm2
	setscale/p y,left,increment,chi2map
	setscale/p x,left2,increment2,chi2map
	
	for(jj=0;jj<(dimsize(chi2map,0));jj+=1)
		value=left+increment*jj
		gen.GEN_pvector[0]=value
		for(ii=0;ii<(dimsize(chi2map,0));ii+=1)
			value=left2+increment2*ii
			gen.GEN_pvector[1]=value
			chi2map[ii][jj]=GEN_optimise#GEN_chi2(gen)/numpnts(yy)
		endfor
	endfor
	
	String cmd="newgizmo /K=1"
	Execute/q/z cmd
	cmd="AppendToGizmo DefaultSurface=root:chi2map"
	Execute/q/z cmd
	
	Setdatafolder callfolder
End

/// offspecular/diffuse conversions
Function/C Moto_angletoQ(omega,twotheta,lambda)
	//function converts omega and twotheta to Qz,Qx. Returns Q as a complex variable (so you can get both parts in)  
	Variable omega,twotheta,lambda
	variable/C Q
	omega = Pi*omega/180
	twotheta = Pi*twotheta/180
	Q=cmplx((2*Pi/lambda)*(sin(twotheta-omega)+sin(omega)),(2*Pi/lambda)*(cos(twotheta-omega)-cos(omega)))
	
	return Q
End

Function Moto_expandQ(omega,twotheta,lambda,Qz,Qx)
	Wave omega,twotheta,Qz,Qx
	Variable lambda

	Qz=real(Moto_angletoQ(omega,twotheta,lambda))
	Qx=imag(Moto_angletoQ(omega,twotheta,lambda))

End



//adding in functionality to change the way the layers are displayed.
Function Moto_changelayerwave(baselength,layers,paramsperlayer)
	variable baselength,layers, paramsperlayer
	String savedDataFolder = GetDataFolder(1)		// save
	Setdatafolder root:
	newdatafolder /o/s root:packages
	Newdatafolder/o/S root:packages:Motofit
	Newdatafolder/o/s root:packages:motofit:reflectivity
	
	if(Waveexists(baselayerparams)==0)
		make/t/n=(baselength,3) baselayerparams
		make/n=(baselength,3) baselayerparams_selwave
	else
		Wave/T baselayerparams
		Wave baselayerparams_selwave
		redimension/n=(baselength,3) baselayerparams,baselayerparams_selwave
	endif
	
	if(Waveexists(layerparams)==0)
		Make/o/t/n=(layers,paramsperlayer*3+1) layerparams
		Make/o/n=(layers,paramsperlayer*3+1) layerparams_selwave
	else
		Wave/T layerparams
		Wave layerparams_selwave
		redimension/n=(layers,paramsperlayer*3+1) layerparams,layerparams_selwave
	endif
	
	variable ii,jj
	
	//setup selection waves and parameter numbers
	for(ii=0;ii<layers;ii+=1)
		layerparams[ii][0]=num2istr(ii+1)
		layerparams_selwave[ii][0]=0
		for(jj=0;jj<paramsperlayer;jj+=1)
			layerparams[ii][3*jj+1] = num2istr(baselength+paramsperlayer*ii+jj)
			layerparams_selwave[ii][3*jj+1]=0
			layerparams_selwave[ii][3*jj+2]=2
			layerparams_selwave[ii][3*jj+3]=32
		endfor
	endfor
	
	for(ii=0;ii<baselength;ii+=1)
		baselayerparams[ii][0]=num2istr(ii)
		baselayerparams_selwave[ii][0]=0
		baselayerparams_selwave[ii][1]=2
		baselayerparams_selwave[ii][2]=32
		if(ii==0)
			baselayerparams_selwave[0][2]=0
		endif
	endfor

	SetDataFolder savedDataFolder	
End

Function Moto_CrefToLayerTable()
	String coefwavestr = moto_coefficientfocus()
	Wave coefficients = $coefwavestr
	
	String savedDataFolder = GetDataFolder(1)		// save
	Setdatafolder root:packages:motofit:reflectivity
	Wave/T layerparams,baselayerparams
	
	variable layers=dimsize(layerparams,0), paramsperlayer =4
	variable baselength = dimsize(baselayerparams,0)
	variable ii,jj,kk=0
	for(ii=0;ii<baselength;ii+=1)
		baselayerparams[ii][1] = num2str(coefficients[ii])
	endfor
	
	for(ii=0;ii<layers;ii+=1)
		for(jj=0;jj<paramsperlayer;jj+=1)
			layerparams[ii][3*jj+2] = num2str(coefficients[baselength+kk])
			kk+=1
		endfor
	endfor
	
	SetDataFolder savedDataFolder	
End

Function Moto_LayerTableToCref(coefficients)
	//this function pastes the layer tables for the base model into the correct coefficient wave
	Wave coefficients
	String savedDataFolder = GetDataFolder(1)		// saveDF
	Setdatafolder root:packages:motofit:reflectivity
	Wave/T layerparams,baselayerparams
	
	variable layers=dimsize(layerparams,0), paramsperlayer = 4
	variable baselength = dimsize(baselayerparams,0)
	
	//this is a bodgy way of doing this, but it's difficult to update things.
	//you are changing the number of layers, so you need to change the length of the coefficient wave
	//however the coefficient wave has the numbers for the multilayers on the end.
	//therefore, get rid of the points that represent the layers, then insert points in
	// which will then have the numbers recopied to them.
	string waveDF = getwavesdatafolder(coefficients,1)
	setdatafolder $wavedf
	deletepoints 0,(baselength+paramsperlayer*coefficients[0]), coefficients
	insertpoints 0,(baselength+paramsperlayer*layers), coefficients
	setdatafolder root:packages:motofit:reflectivity
	
	variable ii,jj,kk=0
	for(ii=0;ii<baselength;ii+=1)
		coefficients[ii] = str2num(baselayerparams[ii][1])
	endfor
	
	for(ii=0;ii<layers;ii+=1)
		for(jj=0;jj<paramsperlayer;jj+=1)
			coefficients[baselength+kk] = str2num(layerparams[ii][3*jj+2])
			kk+=1
		endfor
	endfor
	
	SetDataFolder savedDataFolder	
End

Function moto_modelchange(LB_Struct) : ListboxControl
	STRUCT WMListboxAction &LB_Struct
	//this function updates the model + updates things
	string whichList =  nameofwave(LB_Struct.listwave)
	Wave selwave = LB_Struct.selwave
	Wave/T listwave = LB_Struct.listwave
	variable row = LB_Struct.row,col = LB_Struct.col	
	
	if(LB_Struct.eventcode==-1)
		return 0
	endif
	
	string coefwave = "root:"+Moto_coefficientfocus() 
	String/G root:packages:motofit:reflectivity:currentfocus  = "listwave:"+whichlist+";row:"+num2str(LB_Struct.row)+";col:"+num2str(LB_Struct.col)
	variable SLDval
	
	if(LB_Struct.eventcode==4)		//enter SLD values into layer params
		if(LB_struct.eventmod & 2^4 && cmpstr(whichlist,"layerparams")==0 && LB_Struct.col==5)
			SLDval = Moto_SLDselection()
			
			listwave[row][col] = num2str(SLDval)
			Moto_LayerTableToCref(root:coef_Cref)
			KillControl /W=reflectivitypanel layerparams
			ListBox layerparams,pos={70,289},size={564,133},proc=moto_modelchange,win=reflectivitypanel
			ListBox layerparams,listWave=root:packages:motofit:reflectivity:layerparams,win=reflectivitypanel
			ListBox layerparams,selWave=root:packages:motofit:reflectivity:layerparams_selwave,win=reflectivitypanel
			ListBox layerparams,mode= 5,editStyle= 1,win=reflectivitypanel
			ListBox layerparams,widths={21,23,86,21,23,86,21,23,86,21,23,86,21},win=reflectivitypanel
			ListBox layerparams,userColumnResize= 0,win=reflectivitypanel
		endif
		if(LB_struct.eventmod & 2^4 && cmpstr(whichlist,"baselayerparams")==0 && LB_Struct.col==1 && (LB_Struct.row==2 || LB_Struct.row==3))
			SLDval = Moto_SLDselection()
			
			listwave[row][col]=num2str(SLDval)
			Moto_LayerTableToCref(root:coef_Cref)
			KillControl /W=reflectivitypanel baseparams
			ListBox baseparams,pos={92,52},size={146,146},proc=moto_modelchange,frame=0
			ListBox baseparams,listWave=root:packages:motofit:reflectivity:baselayerparams
			ListBox baseparams,selWave=root:packages:motofit:reflectivity:baselayerparams_selwave
			ListBox baseparams,mode= 6,editStyle= 1,widths={19,89,21}
		endif
	endif
	
	if(numtype(str2num(LB_struct.listwave[LB_struct.row][LB_Struct.col]))!=0 && LB_struct.eventcode==7)
		Moto_Aborter("please enter a number")
		return 0
	endif
	
	//this is if the number of layers changes
	if(cmpstr(whichlist,"baselayerparams")==0 && LB_Struct.eventcode==7 && LB_Struct.row==0 && LB_Struct.col==1)
		LB_struct.listwave[0][1]=num2istr(abs(str2num(LB_struct.listwave[0][1])))
		variable baselength = dimsize(LB_Struct.listwave,0)
		variable newlayers = str2num(LB_struct.listwave[0][1])
		Wave/T layerparams = root:packages:motofit:reflectivity:layerparams
		Wave layerparams_selwave = root:packages:motofit:reflectivity:layerparams_selwave
		variable oldlayers = dimsize(layerparams,0)
		variable howmany = abs(oldlayers-newlayers)
		variable paramsperlayer = 4,ii=0,jj=0
		
		if(oldlayers>newlayers)
			//this line of code enables the user to remove the layer from where he would like
			Variable from=oldlayers
			prompt from, "remove which layer?"
			Doprompt "remove which layer?", from
			if(V_FLag==1)
				LB_struct.listwave[0][1]=num2istr(oldlayers)
				return 0
			endif
			if(from<1 || from-1 > oldlayers-howmany)
				LB_struct.listwave[0][1]=num2istr(oldlayers)
				Moto_Aborter("you can't remove from that place")
				return 0
			endif
			deletepoints (from-1),(howmany),layerparams,layerparams_selwave
		elseif(newlayers>oldlayers)
			Variable to=oldlayers
			prompt to, "insert after which layer?"
			Doprompt "insert after which layer?", to
	
			if(V_FLag==1)
				LB_struct.listwave[0][1]=num2istr(oldlayers)
				return 0
			endif
			if(to<0 || to > newlayers)
				LB_struct.listwave[0][1]=num2istr(oldlayers)
				return 0
			endif
			
			insertpoints (to),(howmany),layerparams,layerparams_selwave
			redimension/n=(-1,3*paramsperlayer+1) layerparams,layerparams_selwave
			
			for(ii=to;ii<howmany+to;ii+=1)
				Moto_initialiselayerwave(ii)
			endfor
		endif
		
		for(ii=0;ii<newlayers;ii+=1)  //rejig parameter + layer numbers
			layerparams[ii][0]=num2istr(ii+1)
			layerparams_selwave[ii][0]=0
			for(jj=0;jj<paramsperlayer;jj+=1)
				layerparams[ii][3*jj+1] = num2istr(baselength+paramsperlayer*ii+jj)
				layerparams_selwave[ii][3*jj+1]=0
				layerparams_selwave[ii][3*jj+2]=2
			endfor
		endfor
	endif
	
	if(LB_Struct.eventcode==7)
		Moto_LayerTableToCref(root:coef_Cref) //send the values to the coefficient wave
		//note that this only sends them to Coef_Cref, if you're calculating a multilayer then you need to
		//send it to the coef_multicref as well.  However, update has this effect.
		Moto_holdstring("",0)
		Moto_update()		//update the reflectivitycurve
		doupdate
	endif
	return 0
End

Function Moto_SLDselection()
	SVAR chemicals = root:packages:motofit:reflectivity:SLDDatabase:chemicals
	variable chemselection
	Prompt chemselection, "choose chemical", popup,"_none_;"+chemicals
	Doprompt "Enter a chemical",chemselection
	if(V_flag==1 || chemselection==0)
		ABORT
	endif
	controlinfo /W=reflectivitypanel SLDtype
	if(V_value==1) //neutrons
		Wave SLD =  root:packages:motofit:Reflectivity:SLDdatabase:SLD_neutrons
	elseif(V_Value==2)
		Wave SLD = root:packages:motofit:Reflectivity:SLDdatabase:SLD_X_Rays
	endif
	variable SLDval=SLD[chemselection-2]
	if(numtype(SLDval)!=0)
		ABORT "No "+S_Value+" SLD value in the database"
	endif
	return SLDval
End

Function/S Moto_coefficientfocus()
	//this function returns the correct coefficient wave for the type of reflectivity function you're calculating 
	controlinfo/W=reflectivitypanel usemultilayer
	if(V_Value==0)
		return "coef_Cref"
	elseif(V_Value==1)
		return "coef_multiCref"
	endif
End

Function Moto_initialiselayerwave(layer)
	//this function intialises numbers in the reflectivitypanel
	variable layer
	Wave/T layerparams=root:packages:motofit:reflectivity:layerparams
	Wave layerparams_selwave = root:packages:motofit:reflectivity:layerparams_selwave
	variable paramsperlayer = 4
	variable ii=0
	for(ii=0;ii<paramsperlayer;ii+=1)
		layerparams[layer][3*ii+2] = num2str(0)
		layerparams_selwave[layer][3*ii+3]=32
	endfor
End

Function Moto_holdstring(ctrlname,checked) :Checkboxcontrol
	String ctrlname
	variable checked
	//this is a function that updates the holdstring 
	String callfolder=Getdatafolder(1)
	Setdatafolder root:packages:motofit:reflectivity

	Wave layerparams_selwave,baselayerparams_selwave
	variable baselength = dimsize(baselayerparams_selwave,0)
	variable paramsperlayer = round((dimsize(layerparams,1)-1)/3)
	variable layers = dimsize(layerparams_selwave,0)

	String test,test1,holdstring
	holdstring="1"
	Variable ii=0,jj=0
	
	for(ii=1;ii<baselength;ii+=1)
		if(baselayerparams_selwave[ii][2]==49 || baselayerparams_selwave[ii][2]==48)
			holdstring += "1"
		else
			holdstring += "0"
		endif		
	endfor
	
	for(ii=0;ii<layers;ii+=1)
		for(jj=0;jj<paramsperlayer;jj+=1)
			if(layerparams_selwave[ii][3*jj+3]==49 || layerparams_selwave[ii][3*jj+3]==48)
				holdstring += "1"
			else
				holdstring += "0"
			endif
		endfor
	endfor
		
	if(str2num(moto_str("multilayer"))==1)
		NVAR/Z Vmullayers=root:packages:motofit:reflectivity:tempwaves:Vmullayers
		ii=1
		do
			test="h"+num2istr(ii)
			controlinfo/W=multilayerpanel $test
			holdstring+=num2istr(V_Value)
			ii+=1
		while(ii<(Vmullayers*4)+1)
	endif

	Moto_repstr("holdstring",holdstring)
	
	Setdatafolder callfolder
End

Function Moto_AboutPanel()
	DoWindow About_Motofit
	if(V_Flag)
		DoWindow/K About_Motofit
	endif

	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1 /W=(173.25,101.75,550,370) as "About_Motofit"
	DoWindow/C About_Motofit
	SetDrawLayer UserBack
	SetDrawEnv fsize= 20,fstyle= 1,textrgb= (16384,28160,65280)
	DrawText 140,37,"Motofit"
	SetDrawEnv fsize= 16,textrgb= (16384,28160,65280)
	DrawText 70,64,"@ Andrew Nelson, 2005-2009"
	SetDrawEnv fsize= 14,textrgb= (16384,28160,65280)
	DrawText 10,84,"Australian Nuclear Science and Technology Organisation"
	DrawText 11,136,"For further help please contact:" 
	DrawText 11,160,"Andrew_Nelson@users.sourceforge.net"
	DrawText 11,180,"http://motofit.sourceforge.net"

	DrawText 11,216,"Analysis of multiple contrast X-ray and"
	DrawText 11,236,"Neutron Reflectometry data."
	
	DrawText 11,256,"Motofit version: " + " $Rev$"
	DrawPict 270,110,1,1,ProcGlobal#moto
	
end

// JPEG: width= 100, height= 172
Picture moto
ASCII85Begin
s4IA0!"_al8O`[\!<E1.!+5d,s5<qn7<iNY!!#_f!%IsK!!iQ)zs4[N@!!NH-"9\f1"9\i2"U,)8$j
[(C#6tbI$OI4R%h]Ke%hTBe(*",('H.\u&JuZ.)BBh?+!2.4+s\?R,TIjI*rjsp6NI>o"U>5:%L<=M
*Y]2#*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zc@D*Zk?s!"fJ:X8l
c5!?qLF&HMtG!WU(<)uos?!WrH(zz!!!3."9ec-#Qb&,_uMt4!!30'!WrT1"9el/#64`(!<N?+"VC_
X"qiWq'1#K('I#;PJWW9mZ,%/";UOG=1L_X!#W,IiP-XWX_uL_W!!<3'!<E0#zz"9eu2!s\f,s24mo
&HDh6!X&T/#Qb&0z!!*'$!sB2>&g8tC5u@h1@=b*d13&G]_9qa=i<LS`;Xse@!"8r1!!3`7&HG#q'=
U6W<7!>@H'huP_c#r[,p+5ubcCg,8^MtW)Mc+K9ilDFX!T&nZCq![f2eDfXToJX[6_k4ERQ!err<u#
:pdZ)V!]8q.__V."3]u236HM].D:^%17++!%3[^FNTp4t'o0g9@JA6ZnM<s>,7em,+i]iHUsKu=Y1X
gN)'kXe:l$kuaM>f_coaf@B]so'</nM.idpo#ENQ[]?#>#:`D6lNH2ptj$?>C\7GKuADc'@k\O/2YT
'E!$QLjn\l(K10dKjQ#RL!(FYY$Vic*kfXqJ.S)C-$F$\s*$RZ\jIb!op,?qN%oQ<*DjHe>_krn>HL
jO+q_iU>7m[P(:I:2i;plfiamn?G9O]HKj`+%RE_r;F;!nnIAM@?m"q=!.LC%Cio0i#`b/WW<BFCji
=O$g"LbBfn>\4/.jMP+t#!Kq;$*\mt>VF^.G=Q=M^Ve4i3g81aI@jOtd2%,j/HgEM\]06OL[3R.ADB
E.)s$o[9A=?I-Qp]lbDB<?DN99F(7Fa89TM(#"Dd7!"8!Ks&>a)ocas>B#?1gj!9UX1#=0ZXuC5)(X
m2>o)pXHe*E8X,Qtn2T.nAi:S[_RF:g!7o=2HUoB?KOY`4Ha3X$.0%!nH8M*-bZaZ#7Wliopp@IFEl
AUa^^tf#?Th/)rH9GEm4l`&F^j'WO+_SHi*>!b^i017nepmpi;6d39D73,Ub-"TAhrnMgk+;lrRqR_
f\@\C*rDjCDkb'"KK:u&dbVW2OCOuQ+,m8e]1dTl%_BZp@fbR8o2=\CC[1d0L93U2J-^&)`EkM9I3`
II\b.0V,e8>i'<8RDqQM2A-l0[cR,kP]hhe_P,=*L(uk2hqo3V1_cYZ_),RAZWJJ)5B]D"sToQBu)[
3eEI92`c?+W4H#d*Nq%l*A7\&N9OO8QCYkTaS]7\Ngc1051NAK&=NZ+P^bBGjGeoJ-o3/+%_S=a)e6
%O/d=<['bM')DN19D>hPC+9']#B[L&-dc@L;FVh,0dUu^\&at_+*nC87iZub@eDF*8Q-Nh^)C#W?^"
eNg56[u*idRQ6=(lW&u?Q$Wap$&L/*mJZ^lYZLM?VrX;2'(/ATG@b8S]>'(kVZ"'fug!^.c'O]jnM6
[,S#;)cL2bfQDLCC=R%ubaJTk`nT\^=e.*guK!(A>2Cq]0EO\7-kGr9kME2s0&fJOR`nLU+`hHAL-&
P+k^31k@#==gd,qg0=XCS&]LGbnNHW[LP9WMG%#f`8dbh*'$k;ih*qA=!rWbM:;3;60*dl^]GL9:an
_Uqg376NAbF1%8_k\>"?dni03/EKG+!5%XM>uS$gP:C&sao#,@+\LCF?e%QIUhD5]35I(**G1;t(9+
A%rVOJG2`V-#?+i2JC6@n$@q<?/mYgIa4.K>4)0pdm@TMU1%Q.PG7HLR%Ck/`iF>tYhk^p7l`Di'qU
A%@/U>RP#!O2(J90:!rVcdDrC3ReTJ4?@`K-cjD,CA\T!/[79@3(.c.2#4ri9,N2#@hs=(cXRDU[s<
$)%(Nl)uA`&Qeks\)2]c\gGY";4Q>,7VJ.KNJa+iJ(R5b&3=egT%\)jf=RHT;)IXRZXEq"YF_"??7+
\\L?VeX?'?qdPiEQJDojBn:[FO'2W[O<>HH8*F-,&^EFgfE0S3:]H.UFO86IbHT,#FfKQi]A\W'4Ad
DCj^Lb*aZ[Md$ndqhY`dNS+%<:S+BI]+[%P"K^2/J>ape$p%O31m.=6?u[OtdrpZ&7A;4!ESG'%B6b
lg)kS:ihoPc'05.[r/GACR%Tk2eZAsX18SV@8<(bnl^[W0,l?-$8iS2>";T2X94ELl+_;6k>%[\/C:
tqY?@#-ugKR%?^3SJX7PYo4V!.9n^_]YVOFPKRX2]r-o^L!a*WjfB(!t;-+dhpRokis<i).d68p$&2
RZD^V6,^%FfX/[LK\NA2iic3J=6H<!u$S3.X4QqO'1rRkMl?O,rQ.-8haD7?LWB>QDFJOonR$pHU;m
pl$8mR!NN7"51LsNc]&_)e]B5I#Kj4S"A,PdFUC`I]cTQVf#<#1U86=5\g=\Kmn724M?GWdL-eQp`T
ZgXnC@@s-t8qA\s"^DS(ZX$)T%j7W<EAqk_r(lEr:E2r#9l6,F$P7E2\isl^qIJiUg/eqlU/Oc*^N^
`n#4Q'+d,tG`+hH7J>?;SK:P5.14t"r#Lngh,CbC*l[+/De!msBPipB01;+0dZ1$!IseDP3L>om9r%
+r'>[41C9B`oI;hoe$#UR:(k%9_F7.A5aN79m+ZnF=N%lD56&j^M2&ffQ/VIrm*Z?^G%'-8>6@()d:
\<@`u&W[DL#F8S[^/@77R2-@!-XG'd;OFRq>*t;HYZ?lEFm4:*]%4T<Z8JJ?^ch-:h=5<%X.pF=*(o
E^/DH/.rl(<(^Kl5gQATb"-;fIfu_jWD($!`'Cj!=E[_cAWsKFl-KER=*t1W-.=XF=9+aQ'Q9.&X]H
eMM<r\$jbYN`B]5+EThVVDHcBTC)4-@-9RRE6f%um?&6&n>pN[*T0-Oq4//="HbB.S@h3t^Jh9uMW+
(u4/RnoUu'8h:t^g@41kV?Rc"VBLcur*4),4!_,css%RAngDZd#]V,TRU"0jrbgFf8Hd[86hJfEuNp
<reb34t5-=Yc8%ZB'=7M.rfK?-9b;E]aS*Y%Zk:Wp]dr<7J1pm]OA18Q"NGY8,i!3]9ZQ%tkQX4GK!
r8:/W+XI^jD9cB]mS8XD-h`BtlQ_`P"c5YFcm2UCcRL`@QPdO1?-=c]!BsZKXMMgN5Y?+_*$:r\XZ,
V)!Au_J/Q,U1/9r32j_*MA&e,)#ZY*l(@1fZp[DPV)uI58<Id+$R0niANo%s8^r&X#/8je+fc;(c*h
=Tphc!.(IA,LcalD8)EAUZ$?MOX#nl?s$o#I>3i,R\PQU)E`Jl(o.Sbj8H)(ePQ3Smo6_0J^ZfO]p>
'NLQY`OQTV@.r<VrJ;50JAXX%MD@3kE<plIQ9R["#m\hLhQ?0_$&IM(2PD]MG.Tr&AQA(;&[iY"u4X
HprgM*&j^@$D;Zh<2F*d,Q1Z%J:fuBI`E?92FEilT:L8Fo4[h:Cj)D75Y.3.g*_@Rr2g?@![7/Zb2;
P]SL*[0H9ra5<n\5A#OBc%fP7V[n"lt8PJXKc)eV-:K&8h/#&+#.-mi?4R[mNW:EahqU7TKiC'].UD
<lMPKF-le+;*YD+p2e%1u(G4!(pR@p#+%j']G&%uN:X"g.hb/(LYt+i>RW9`(gigJR5W-m4_gQ/e#)
%d+qBTi'F99!8d^3U.,PYI2odjbq-P&+p@9f>bftX9OO%#QnTN`3g+/1f38Q1WiLKRJes%ek9Q'(K4
GA[8<b6,HBfLQQ'f*FB`oZg5VL:TdOoqrgKppejVol)H.K=3gtN[=d\Q7bVI)s!7aOS>0!uqGju9?O
m_Ft%9[b]]0RC\''G_d,<i]`??(AsZ5_l0_c[tp!L?T6T+S0R_3*IMPTE=FCJ>m8*RHp0bZU[)Otn^
PrgIh)=40B/=\1I&Q8afcc[t*Dq0lgG"I=/?;RJ&m1t'i&WWDVjS:g'c1:U4-Q@rR[d.arRKrE#L&e
t!/)[pI[[1q`J'#38TI!>P[9:\lri4sL5WO5_]e<PnDn^E\f2K?l9NUT`+)VYp].fGkuqoOle"GOlm
I`LoZoG38_!/=JQ!%5K8<!1uuCdpIX1"R>m4ZSlb0g,!*+HaB05!D,P2kE""h)?F;[=VX?>GROBK-M
l,k:!5Fnis"c]U[W:)jPA;`uf^qNbK\"]S8e8]=3=1Fgi$:c@ano*p29@[Gl"?1gUYE$gUd@Pqrc#+
^:0DfaMqlI[]e*:aDfJN^CQnpIQD2`-N%&qWbN`.XNflV[<aU#j]8#)YX@l1/YnjP)kh44-I4)qJf#
!pV^VMK<if9i_3qW"SsQEeb<Rd;]KU7OjrYRcEOY[=(0=rW3-O]b9VZp]+>0<3e^ih\L(P_2HAW^6j
URYWlZ#^7a"3*pN5jK.!Ld6mF,nYhJ_B'lqg(*[-Nn3-Z5P>Zt4HH,-]Nl91mZ6qnb`?oAl&g5(I<n
L\N@\=2Y=3`>$-u,J<_n4G.(H5MJqPf!i=;JCF6].?-nH$*ZjGcLBn42*f'7D^:L)Nhk_KgZp`E1c<
fV9Sl8MTVd90&R/^7T!LnTo7-Q6<5>1Z(3G'@&)#Ji;VUJPb,\:%9,(q3(1[<MIDQ@+2IrVbLlV#DW
r58JJV3U8kG<+r*[6bLmklt$aRo#<KiGM9r6,3<!nr!#;aKc?n04"M7j^@($3&Y0m7g&Rf>LDV*a/]
&^`WQqM]\sY/IHh\4AL0)GpEaOB0IR/pX&<N]r%FT+n"#h:G814C>rDW,-7er(O3bbHn/SE4(nQnYh
$'Em,iI2dNk7&p$&8+aOnbmDMFI$&XBK'#Lf-?VM1ds!6^N`A+KX"(tQ:PZP+I<<L9$pkLXY0<jR[(
A4LVYNRSW%\eF*SJm#33e[ag^Ko@bO`,%X#5=;;IT[_1(#,M2u;\q23,:W_[9"UUV9qG<9\!hsG*,9
%Zcr/>h+]-$?Gu+(=Du8gObu:'-o!$>g1oIN,q0q&9GIU^96l`Ho`-H-n<m`g_(<(4>qrk"D`fuLT[
VDeTer+g;r@;W?frGq&BE3'l(j+''mL:mEDL"f)q>@WY=]Ugkmi4@W6+6WuYh7h":j_:X7`8\Bi9iD
s';\PmkoXMqY,to,$o*q*@%^WaRW^t2aCJ:K:m)+=)I[T5JkP3-Niq1!)r]m<a-khXgJN3rLSCN?L6
0jXkns[TL^k\+!On*AeSk;^Lb88?Zr`'^#ZANI0U2Z.GtB5mo_W@I6u?KpA8E(JIoX^'I:Zu&E_srN
I"9i[MC?(0?!c(0)gu6$+";4;T-;f2(uOMXd/BlLj>;DDjdiEn,d_Uq;SEtiQd]*=Tr+>Lcs=a&4rj
Wc_FB,qWTnqH,M:$L:tRBXe<`aR\lsnl"9/A2LFPL"kiS5>8?$t2,Z)i_l^'3l.YH)o@n;R@UlkZWY
2>h.X#PPDij`^]-?.J^aYNkr6fSTiEV\p"fGt]<=YgGPO!0j^mmT/qF'9gnem0//ii=*WLop3o<_"X
_7LXus%V(LrLa/dRWg\g*j%2s.6n2s)i_[mO?#XaGG5V!)\%pSO*I'-W*-2;05;#.Wk=_s/]&#'0@o
4M:F^<L>*:T!XJ>WAP)sg)qjD$"Ob-MY[0iQ2+1_HnRU%S%b=]*u#,AhSOf:",GQq>R/PQkCg&:]*Q
qcBe\m)qn;@j4gohQRHrRut1O5BEe<pWNN[.;@qJRV%76&Q`cY\N&kr7;0),cjsfk@]qN&EkM_MN;`
]sI6J9_#72k$*@L@Zl?noO&1XIkBui4tKFMYhVP&qrNT"6_>]0PTR_GMZ$97VZ*q5+PFf13O'R%RO5
l#Oe%L5dket14PCUfPl'[Y9r;!5EKIP4WjJ-0k`5N:"GShl)'\jdQ?6\Nm,+r["hbata,ATqRgf3[o
B6V@Ke]7R]Yh:VN$rn8[#]AJe3<Dt\P'nnt'ViR*+ckLM]&YeT5U;bgHdDoaqQDP"DB".t,fiB)g.G
Hi:dlJ);X(Hl]<5Q^3H(l,uNV`L8JZ;=W8Ef;FSG/O*j(*oZ`FQo%R3Pqk@FXkZOa=1E8S[?uN3GRk
)$q;$GiM'@WlhI]iVK$Td2'-j'[%7r+9t(jh]V>DdAse3W@_n+WJ0Jb"p133$P5+[-g0Tf29a=bY>K
bI@8BP/FQg>i7G)8?Uic2F`LX6jlk%0MC1VLG3EgShHCmAnW@I)67@e^5:]c=QaD3Y!;/<6GT4Y5hh
hK'b28&Gc\0tL"G`0ZK6m$?!>,ns-JN9TjWDsbYPGcBka[ot1CM$#([T"Cin*mdHH8.H^p/t#9nI8K
68'[>a3fa@daC!O`9fMMl.38gCF"+"^nne*03QV#40qmppH'!dI"h`/7Op3muRP37l!&*g)UItd5Sq
=5uMJ4;gF1dDK.]^9T4TG^KT.L+E>qOS4+M#B5,"!VF1PTeZ'AtgsY@tRQ-(f_Opg,<lU?`qnXQP$u
n>Z5SoV9%Cb>AK@mQW:76\dE0A/gf:GadZWU7NCbRVGKSPg9bW6TtX#^'&NqlbB'`N[SVFGIgtWW#g
,BShf69!Rm_73^d%2EeXf%2VMp>0u`liCF\`C8^@LVPer!'#gRi_[_5Ol7l:-VCOOZ:3jFc&LR2=>a
0SMT[rI5)\R)+t)C\3*=93q8HuaAWSV_;kTdaN<3`M+D,aBV5M--c*e>Zn>IGHK@f-N:<.I#cg=]l/
mbDp/[0dMggFB?H3f,(hnIgiOS3dF5=Pk=Fec]*i;lfHaql,<fLRUEpI!+)b*p3KWpDYG)W_u'<T*n
E<&P3Gq*En_dq>%n4jamcVI&!6a3]=H*r[o8g$N\$,C)(1cSlhP:#(8eQE^li8CjiT:>h`DMM^7&/I
YJd0+BIt!ET&ULs3NJGXbS!rnclX5-#)&tSp5&kq)@MUeM>JK*Jgsmt;E3HiRr\#-U9W^,.C3;nQ7+
4(P+DrL7\pT"Oguj::4p&G\cqHHfp5W@]>ka?\HM_CT!%4@e-7d]TOLPN:8Do\2-Id%P#A3+0M'5=+
Ilq.)K+NEjpDjuIV,/hZYXLJ(AsmA*oc,QCGh>3:s0dlW0F$e<PSiVAr\EejJJE%a@4"9o*aFU`%<m
i-&kF&f$!GYP!0&i\Y"s'hbgGqXrc>'<EWT`(o1XmcGsmVF2+:H+'f9)>YRZ47]+COnYq@EFN7('^J
.dLe]7GjT@ac`qO5VbLd)#PVLEr8,W+W-)>>K@pV8-dP1Sn4B,KK+n\d0;RS9'0numWffi3AW!ok\p
G_kUVgI&5>`8mHZN/`/Wg4EBXS/dMEaeb)en%-$4(kD$1SMiPSiG,rki2EMq;GTb%SD\t&@@sun*&o
7Uh.`i6N0r<bbX1K/n#jImU,uqML[-poiiCn`-RCTrGR_q\aWP7Xao.eTmV(lT3_9<b\rV9=T%R4^P
ue)%4A&V+"pf:A<]KF;n]%U[.kWPTXZZR8Q6:HV2*UJra$<FO!<"`efaXf".DAl':%F8n.EQTQ/'Zt
^*X[B(K7W@ZcpnemM0,kkh+I0@l%>@(GlkZ?/kPeu;<*7W7mp:r+H)'D>GcY#$D*nUe#e?%$6HtPbS
"ls<C4`(Q&ZoO1mJF=SmQc`b<LD-HSqfIQ9`Y#AgcHm-W#'2Lm$r>F4IC7Q#IELX"_OOl&BuTmA#h#
)Ra0S=KXJ?Mh]*0_PX5oW&a;'2=KX;I_qPRNc??p3!slLF1-aH6IeG'_C7?206g."/Y?;^78j>.9V0
cIYZ:og&9UFpnqZ1Gk&bE$iEL,:Y;G(33gpD"<\_A-KCoUFn9(fPTTMOt!^\c5,$L=mGo[PCVVW69A
XrEtNY+_[!(QmJV3,14W[9t[WBl[<pk\G<!7?Gm@7,@<NkXeaqeYI;6EWg-47[s`3dih>,s4NY_mZ5
JV4+\IO[nF3WSd!]:ZAoO\KDBLesWCSmf`^p9m+@*k75p%3i(_]6<n6)-?/RX79kIq62oR@CJ,OuE(
f%#5Qd?oVakY]8c0$k/kQGsN1DW37PNF"js>YTN`$D)8a8H.[m;gB*b)M$"'Zp^$'j09MG#7dk,=.T
mM!>X"EX<%nK@W)\)5Y/Rtn6;pCBu<\3V+beIKr(_Y_@p2Cqq,7R$[Cm!?W=pGaU(bfD%?P5.5mc@7
E`YbH,=CQu8sa>;4qrrC1M5j2GFdeR/4k7$I_qZQMs<'doJ9(Sig?QNh:*B]NaZ/Goop1n$Rf,+GeW
3&teU%jM(KMh$T-fou`7dZ+ojL?(DPRP]h6g[[.(*NN8nJN3*l/'n0ZJM`bl>gC2V2Z^O0Qob'#2WN
QG$/@`hDe85Xu&u)88;\Y3WaX(l.`436."@\5:M#%%:%cCI9oLS5Vrk@`0,1X`u8R`5t7\#.iEEP_+
2uS!8S`%p]lL!=UDK(KgEOA=7k#jAC/>d0&]b3m8=Afj)$6a.n!@Up?95!oRt]uP,I+%[d&O7;\2E+
8LSOLp!TkX<9Zdc*LFBI0H1spVd2u3luaHM'OhT5\ZU4SNap0U0)c)Xi"[GDk;XZjf1?q6"1Ht3*(b
=GSE=NUaQkYk/#pouRr)c91-s;5FsBm\^/t?f
ASCII85End
End

static strconstant NO_ATOM = "Parse error - either the atom or the isotope doesn't exist in the database: "
static strconstant NO_ISOTOPE = "Parse - one of the isotopes isn't in the database"
static strconstant INT_ISOTOPE = "Parse - please enter integers for the isotope"
static strconstant NO_SCATLEN = "No scattering length exists for that isotope: "
static strconstant INCORRECT_DENSITY = "Please enter a mass density > 0"
static strconstant GENERAL = "Parse - please enter chemical as element(isotope)numatoms"


Function Moto_SLDLoadScatteringlengths()
	string saveDF = Getdatafolder(1)
	setdatafolder root:
	newdatafolder/o/s root:packages:motofit
	newdatafolder/o/s root:packages:motofit:reflectivity
	newdatafolder/o/s root:packages:motofit:reflectivity:Slddatabase
	string/g calcSLD_chemical
	variable/g calcSLD_massdensity
	variable/g calcSLD_molvol
	string/g calcSLD_Neutron,calcSLD_Xray
	
	String path=FunctionPath("MOTOFIT")
	variable pathlen=itemsinlist(path,":")
	path=Removelistitem(pathlen-1,path,":")
	path+="SLDscatteringlengths.txt"
	
	LoadWave/q/J/M/n=scatlengths/U={0,0,1,0}/K=2 path
	
	duplicate/o scatlengths0,scatlengths
	killwaves/z scatlengths0
	setdatafolder saveDF
End

Function Moto_SLDcalculateButton(ctrlName) : ButtonControl
	String ctrlName
	SVAR chemical = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_chemical
	SVAR SLD_Neutron = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_neutron
	SVAR SLD_Xray = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_Xray
	NVAR SLD_massdensity = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_massdensity
	Variable/C sld
	sld = Moto_SLDcalculation(chemical,SLD_massdensity,0)
	SLD_Neutron = num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
	sld = Moto_SLDcalculation(chemical,SLD_massdensity,1)
	SLD_xray = num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
End

Function Moto_addchemicalfromcalculator(ctrlName) : ButtonControl
	String ctrlName
	//this function adds a new chemical to the SLD database from the SLDcalculator
	string saveDF=getdatafolder(1)
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	SVAR/z chemicals,calcSLD_Chemical,calcSLD_Neutron,calcSLD_Xray
	NVAR/z calcSLD_Massdensity
	
	if (waveexists(chemical)==0)
		Setdatafolder savedf
		ABORT "Please load the database first"
	endif
	
	variable numchemical=numpnts(chemical)
	redimension/N=(numchemical+1) chemical,SLD_neutrons,SLD_X_rays,Mass_density, chemical_composition
	
	String chemicalname
	Prompt chemicalname, "Name"
	Doprompt "Please provide a name for the chemical" chemicalname
	if(V_flag)
		setdatafolder savedf
		Abort
	Endif
	
	Wave/T chemical,chemical_composition
	Wave SLD_neutrons,SLD_X_rays,Mass_density
	
	chemical[(numchemical+1)]=chemicalname
	
	//parse the real part of the neutron SLD
	variable v1
	sscanf calcSLD_neutron,"%f",v1
	SLD_neutrons[numchemical+1]=v1*1e6
	sscanf calcSLD_Xray,"%f",v1
	SLD_X_rays[numchemical+1]=v1*1e6
	Mass_density[numchemical+1]=calcSLD_massdensity
	chemical_composition[numchemical+1]=calcSLD_chemical
	chemicals+=chemicalname+";"
	Setdatafolder savedf
End

Function Moto_SLDcalculateSetvariable(SV_Struct) : Setvariablecontrol
	STRUCT WMSetVariableAction &SV_Struct
	if(SV_Struct.eventcode!=-1)
		SVAR chemical = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_chemical
		SVAR SLD_Neutron = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_neutron
		SVAR SLD_Xray = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_Xray
		NVAR SLD_massdensity = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_massdensity
		NVAR SLD_molvol = root:packages:motofit:reflectivity:SLDdatabase:calcSLD_molvol
		
		strswitch(SV_Struct.ctrlname)
			case "calcMassDensity":
				SLD_molvol = 1e24  * numberbykey("weight_tot",Moto_SLDparsechemical(chemical,0))/(SLD_massdensity*6.023e23)
				break
			case "calcmolvol":
				SLD_massdensity = 1e24  * numberbykey("weight_tot",Moto_SLDparsechemical(chemical,0))/(SLD_molvol*6.023e23)
				break
		endswitch
		
		Variable/C sld
		sld = Moto_SLDcalculation(chemical,SLD_massdensity,0)
		SLD_Neutron = num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
		
		sld = Moto_SLDcalculation(chemical,SLD_massdensity,1)
		SLD_xray = num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
	endif
	return 0
End

Function/c Moto_SLDcalculation(chemical,massdensity,type)
	String chemical
	variable massdensity
	variable type //(0=neutrons,1=xrays)

	string parsedChemical = Moto_SLDparsechemical(chemical,type)
	variable weight_tot = numberbykey("weight_tot",parsedChemical)
	variable/c scatlen_tot
	scatlen_tot = cmplx(numberbykey("scatlen_tot_re",parsedChemical),numberbykey("scatlen_tot_im",parsedChemical))
	variable/c sld
	
	sld = 1e-29*6.023e23*scatlen_tot*massdensity/weight_tot
	return sld
End

Function/S Moto_SLDparsechemical(chemical,type)
	//parses the entered chemical and adds up the total weight and scattering lengths
	string chemical
	variable type

	wave/t scatlengths = root:packages:motofit:reflectivity:slddatabase:scatlengths

	String element = ""
	variable isotope, numatoms

	variable/c scatlen, scatlen_tot=cmplx(0,0),sld=cmplx(0,0)
	variable weight,weight_tot

	string s1
	variable s1dum,strpos,posintable

	if(strlen(chemical)>0)
		do
			element=""
			//parse for a chemical.  this should be in the general format elementstr(isotopevar)numatomsvar
			sscanf chemical, "%1[A-Z]", s1
			element+=s1
			chemical=chemical[1,strlen(chemical)]
			
			if(strlen(s1)==0)
				Moto_SLDabort(GENERAL)
			endif

			sscanf chemical, "%[a-z]", s1
			element += s1
						
			chemical = chemical[strlen(s1),strlen(chemical)]
			
			//now get the isotope, 0 = natural abundance
			sscanf chemical, "%*[(]%f%*[)]",isotope
			if(V_flag==1)
				strpos= strsearch(chemical,")",0)
				chemical  = chemical[strpos+1,strlen(chemical)]
				isotope = round(isotope)
			else 
				isotope = 0
			endif
			
			//does chemical + isotope exist
			s1 = num2istr(isotope) + element
			Findvalue/text=s1/z scatlengths
			posintable = v_value
			if(posintable==-1)
				Moto_SLDabort(NO_ATOM+element)
			endif
			
			//now find out the number of atoms of that element
			sscanf chemical, "%f",numatoms
			if(V_flag==1)
				sscanf chemical,"%f%s",s1dum,s1
				if(strlen(s1)==0)
					chemical=""
				endif
			
				strpos = strsearch(chemical,s1,0)
				chemical = chemical[strpos,strlen(chemical)]	
			else
				numatoms=1
			endif
		
			//isotope exists, so find scatlen, add to total, add weight to total, depending on the number of atoms.
			if(type==0)
				if(numtype(str2num(scatlengths[posintable][2]))!=0)
					Moto_SLDabort(NO_SCATLEN+ num2istr(isotope)+element)
				endif
				scatlen = numatoms*cmplx(str2num(scatlengths[posintable][2]),str2num(scatlengths[posintable][3]))
			elseif(type==1)
				scatlen =numatoms*cmplx(str2num(scatlengths[posintable][5]),str2num(scatlengths[posintable][6]))
			endif
			
			scatlen_tot += scatlen
			weight_tot += str2num(scatlengths[posintable][1])*numatoms
		
		while(strlen(chemical)!=0)
	endif

	if(type==1)
		scatlen_tot *= 2.8179
	endif
	
	return "weight_tot:" + num2str(weight_tot) + ";scatlen_tot_re:" + num2str(real(scatlen_tot))+";"+"scatlen_tot_im:"+num2str(imag(scatlen_tot))
End

Function Moto_SLDabort(error)
	string error
	ABORT error
End

Function Moto_mixCalculateSetvariable(SV_Struct) : Setvariablecontrol
	//this function works out an overall SLD if you supply volume fractions and individual SLD's
	STRUCT WMSetVariableAction &SV_Struct
	if(SV_Struct.eventcode!=-1)
		NVAR mixOverallSLD = root:packages:motofit:reflectivity:SLDdatabase:mixOverallSLD
		NVAR mixSLD1 = root:packages:motofit:reflectivity:SLDdatabase:mixSLD1
		NVAR mixSLD2 = root:packages:motofit:reflectivity:SLDdatabase:mixSLD2
		NVAR mixvolfrac1 = root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac1
		NVAR mixvolfrac2 = root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac2
			
		mixvolfrac2=1-mixvolfrac1
		mixOverallSLD = mixvolfrac1*mixSLD1 + mixvolfrac2 * mixSLD2

	endif
	return 0
End

Function Moto_mixCalculateSetvarReverse(SV_Struct) : Setvariablecontrol
	//this function takes an overallmixSLD, with SLD's of components, and works out what their volume fractions are.
	Struct WMSetVariableAction &SV_struct
	NVAR/z mixSLD1 = root:packages:motofit:reflectivity:SLDdatabase:mixSLD1
	NVAR/z mixSLD2 = root:packages:motofit:reflectivity:SLDdatabase:mixSLD2
	NVAR/z mixOverallSLD = root:packages:motofit:reflectivity:SLDdatabase:mixOverallSLD
	NVAR/z mixvolfrac1 = root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac1
	NVAR/z mixvolfrac2 = root:packages:motofit:reflectivity:SLDdatabase:mixvolfrac2
	variable volfrac
	if(SV_Struct.eventcode!=-1)
		volfrac = (mixOverallSLD - mixSLD2) / (mixSLD1 - mixSLD2)
		mixvolfrac1 = volfrac
		mixvolfrac2 = 1-volfrac
	endif
	
	return 0
End


Function/S Moto_wave2txtstr(numericwave)
	//this function converts a single column numeric wave to a string.
	Wave numericwave
	if(waveexists(numericwave)==0)
		return ""
	endif
	
	string retStr=""
	variable ii
	for(ii=0;ii<numpnts(numericwave);ii+=1)
		retStr+=num2str(numericwave[ii])+"\r"
	endfor
	return retstr
End

Function/S Moto_layerwave2txtstr(numericwave)
	//this function converts a single column numeric wave to a string.
	Wave numericwave
	if(waveexists(numericwave)==0)
		return ""
	endif
	
	string retStr=""
	Wave baseparams = root:packages:motofit:reflectivity:baselayerparams
	Wave W_Sigma = root:W_Sigma
	variable baseparamssize = dimsize(baseparams,0)
	variable ii,jj=0,kk=1
	
	for(ii=0 ; ii<baseparamssize ; ii+=1)
		retStr+=num2str(numericwave[ii])+"\t+/-\t"+num2str(W_Sigma[ii])+"\r"
	endfor
	
	NVAR/z Vmulrep=root:packages:motofit:Reflectivity:tempwaves:Vmulrep
	NVAR/z Vappendlayer=root:packages:motofit:Reflectivity:tempwaves:Vappendlayer
	NVAR/z Vmullayers=root:packages:motofit:Reflectivity:tempwaves:Vmullayers
	
	for(ii=baseparamssize ; ii<numpnts(numericwave) ; ii+=1)
		if(mod(jj,4)==0 && ((ii-baseparamssize)/4)>=numericwave[0])
			if(kk==1)
				retstr+="Number of multilayers: "+num2istr(Vmullayers)+"\t\tRepeats: "+num2istr(Vmulrep)+"\tAppended to layer: "+num2istr(Vappendlayer)+"\r"
			endif
			retStr+="multilayer "+num2istr(kk)+":\t"
			kk+=1
		elseif(mod(jj,4)==0)
			retStr+="layer "+num2istr(1+(jj/4))+":\t"
		endif	
		retStr += num2str(numericwave[ii])+" +/- "+num2str(W_Sigma[ii])+"\t"
		jj+=1
		if(mod(jj,4)==0)
			retStr+="\r"
		endif	
	endfor
	
	return retstr
End

Function Moto_notebookoutput(notebookname,yWave,additionaloutputstr)
	String notebookname
	Wave ywave
	String additionaloutputStr
	
	String ywaveStr,xwaveStr,coefwaveStr,fit_waveStr,fitx_waveStr
	string texttoadd=""
	variable plotyp=str2num(moto_Str("plotyp"))
	
	yWaveStr=nameofwave(ywave)
	xWaveStr=removeending(yWaveStr)+"q"
	coefwaveStr="coef_"+yWaveStr
	fit_waveStr="fit_"+yWaveStr
	fitX_waveStr="fit_"+xWaveStr
	
	if(Waveexists($fit_waveStr)==0 || Waveexists($fitx_waveStr)==0 || Waveexists($coefwaveStr)==0)
		return 0
	endif
	
	//goto the end of the notebook
	Notebook $notebookname selection={endOfFile, endOfFile}
	
	//add the time
	texttoadd="Fitted at: "+time()+", "+date()+"\r"
	notebook $notebookname, text=texttoadd
	
	//add the waves fitted
	texttoadd="Data: " + ywaveStr + " vs " + xwaveStr + "\r"
	notebook $notebookname, text=texttoadd
	
	//add an additional output string if required
	texttoadd=additionaloutputstr + "\r"
	notebook $notebookname, text=texttoadd
	
	//add in a graph
	if(Waveexists($fit_WaveStr))
		Display/N=Notebookaddgraph $ywaveStr vs $xwaveStr as "NotebookAddgraph"
		Appendtograph/W=notebookaddgraph $fit_waveStr vs $fitx_waveStr
		Label/W=notebookaddgraph left,"R"
		Label/W=notebookaddgraph bottom,"Q /Å\S-1"
		ModifyGraph/W=notebookaddgraph mode($ywaveStr)=3,marker=8,msize=2
		
		if(plotyp==3 || plotyp==2)
			ModifyGraph log(left)=1
		endif
		
		Notebook $notebookname picture={Notebookaddgraph(0,0,0,0),-5, 1}
		Notebook $notebookname,text="\r"
		Dowindow/K Notebookaddgraph
	endif
	
	//add Chi2???
	if(Waveexists($coefwaveStr))
		Moto_Chi2_print()
		NVAR/z chi2sq = root:packages:motofit:reflectivity:chisq
		texttoadd = "Chi2 = "+ num2str(chi2sq)
		Notebook $notebookname,text=texttoadd+"\r"
	endif
	
	//add in the wavedata
	if(Waveexists($coefwaveStr))
		texttoadd = Moto_layerwave2txtstr($coefwavestr)
		Notebook $notebookname,text=texttoadd+"\r"
	endif
	
	texttoadd="__________________________________________________________________________"
	Notebook $notebookname,text=texttoadd+"\r"
End

Function Moto_initialiseReportNotebook()
	NewNotebook/v=0/F=1/N=ReflectivityFittingReport as "Reflectivity fitting report"
End

Function Moto_backupModel()
	string coefwave = moto_coefficientfocus()
	duplicate/o root:$coefwave, root:packages:motofit:reflectivity:tempwaves:coef_Cref_BAK
End

Function Moto_restoreModel()
	string coefwave = moto_coefficientfocus()
	Wave w = $coefwave

	if(!waveexists(w) || !waveexists(root:packages:motofit:reflectivity:tempwaves:coef_Cref_BAK))
		abort "nothing to roll back to"
	endif
	duplicate/o root:packages:motofit:reflectivity:tempwaves:coef_Cref_BAK, root:$coefwave

	strswitch(coefwave)
		case "coef_multicref":
			Decompose_multilayer()
			break
	endswitch

	Moto_creftolayertable()
	Moto_update()
End

Function moto_holdall()
	String holdstring = moto_str("holdstring")
	Wave coef_Cref = root:coef_Cref ,coef_multicref = root:coef_multicref
	variable i,stringlength = numpnts(Coef_Cref)
	
	if(str2num(moto_str("multilayer"))==1)
		stringlength = numpnts(Coef_multicref)
	endif
	
	holdstring=""
	for(i =0 ; i<stringlength; i+=1)
		holdstring[i]="1"
	endfor
	moto_repstr("holdstring",holdstring)
	Moto_updatecontrols()

End

Function moto_offsetQ(Q,theta,lambda)
	Wave q;variable theta,lambda

	q *= (lambda/(4*Pi))
	q = asin(q)
	q *= (180/Pi)

	q += theta

	q *=  (Pi/180)
	q = sin(q) 
	q *= (4*Pi/lambda)

End

Function Moto_montecarlo_SLDcurves(M_montecarlo)
	Wave M_montecarlo
	//calculates the envelope of SLDplots for a montecarlo reflectivity analysis.
	//M_montecarlo contains the fit coefficients for all the fit coefs, rows = montecarlo iteration, cols = coefs.
	variable nlayers,SLD1,SLD2,zstart,zend,ii,temp,zinc,summ,maxsofar,jj,SLDPTS
	Variable deltarho,zi,dindex,sigma,thick,dist,rhosolv
	
	//say how many points you want in the SLD graph
	SLDPTS = 2000
	
	//how many layers are there? 
	nlayers=M_montecarlo[0][0]
	
	//create the SLD matrix
	make/o/d/n=(SLDpts, dimsize(M_montecarlo, 0)) SLDmatrix = 0
	make/d/n=(SLDPTS)/o SLDmatrixtemp
	
	//find out what the start and finish points of the SLD profile are.	
	if (nlayers==0)
		make/o/d/n=(dimsize(M_montecarlo,0)) tempcoefs
		tempcoefs[][] = M_montecarlo[p][5]
		wavestats/q/m=1 tempcoefs

		if(abs(V_max)<abs(V_min))
			temp = V_min
		else
			temp = V_max
		endif
		zstart=-5-4*abs(temp)
	else
		make/o/d/n=(dimsize(M_montecarlo,0)) tempcoefs
		tempcoefs[][] = M_montecarlo[p][9]
		wavestats/q/m=1 tempcoefs

		if(abs(V_max)<abs(V_min))
			temp = V_min
		else
			temp = V_max
		endif
		zstart=-5-4*abs(temp)
	endif
	
	//endpoint of the SLD profile
	maxsofar = 0
	for(jj=0 ; jj<dimsize(M_montecarlo, 0) ; jj+=1)
		ii=1
		temp=0
		if (nlayers==0)
			zend=5+4*abs(M_montecarlo[jj][5])
		else	
			do
				temp+=abs(M_montecarlo[jj][4*ii+2])
				ii+=1
			while(ii<nlayers+1)
		
			zend=5+temp+4*abs(M_montecarlo[jj][5])
		endif
		if(zend>maxsofar)
			maxsofar = zend
		endif
	endfor
	zend = maxsofar
	
	//set the scale for the SLDmatrix
	setscale/I x, zstart, zend, SLDmatrix, SLDmatrixtemp

	for(jj=0 ; jj<dimsize(M_montecarlo, 0) ; jj+=1)
		make/o/d/n=(dimsize(M_montecarlo, 1)) tempcoefs
		tempcoefs[] = M_montecarlo[jj][p]
		
		SLDmatrixtemp = Moto_SLD_at_depth(tempcoefs, x) 		
		SLDmatrix[][jj] = SLDmatrixtemp[p]
	endfor
	
	make/o/d/n=(SLDPTS) W_avgSLD=0
	copyscales/p SLDmatrix, W_avgSLD
	
	display/K=1 
	Wave W_chisq
	wavestats/m=1/q W_chisq
	variable counter=0
	
	for(ii=0 ; ii<dimsize(SLDMatrix, 1) ; ii+=1)
		if(W_chisq[ii] < V_avg +3*V_sdev)
			appendtograph SLDmatrix[][ii]
			W_avgSLD[] += SLDmatrix[p][ii]
			counter+=1
		endif
	endfor
	W_avgSLD/=counter
	appendtograph W_avgSLD
	
	killwaves/z tempcoefs, SLDmatrixtemp
End

Function Moto_SLD_at_depth(w,z)
	//function calculates an SLD point at a distance, z, from the interface.
	//w are the fit coefficients.
	//shares a lot of code with Moto_SLDplot
	wave w
	variable z

	variable nlayers,SLD1,SLD2,zstart,zend,ii,temp,zinc,summ
	Variable deltarho,zi,dindex,sigma,thick,dist,rhosolv
	
	rhosolv=w[3]
	nlayers = w[0]
	//work out the z depth wave
	dist=0
	summ=w[2]
	ii=0

	do
		if(ii==0)
			SLD1=(w[7]/100)*(100-w[8])+(w[8]*rhosolv/100)
			deltarho=-w[2]+SLD1
			thick=0
			sigma=abs(w[9])
			
			if(nlayers==0)
				sigma=abs(w[5])
				deltarho=-w[2]+w[3]
			endif
		
		elseif(ii==nlayers)
			SLD1=(w[4*ii+3]/100)*(100-w[4*ii+4])+(w[4*ii+4]*rhosolv/100)
			deltarho=-SLD1+rhosolv
			thick=abs(w[4*ii+2])
			sigma=abs(w[5])
		
		else
			SLD1=(w[4*ii+3]/100)*(100-w[4*ii+4])+(w[4*ii+4]*rhosolv/100)
			SLD2=(w[4*(ii+1)+3]/100)*(100-w[4*(ii+1)+4])+(w[4*(ii+1)+4]*rhosolv/100)
			deltarho=-SLD1+SLD2
			thick=abs(w[4*(ii)+2])
			sigma=abs(w[4*(ii+1)+5])
		endif
		
		dist+=thick	
		//if sigma=0 then the computer goes haywire (division by zero), so say it's vanishingly small
		if(sigma==0)
			sigma+=1e-3
		endif
		
		summ+=(deltarho/2)*(1+erf((z-dist)/(sigma*sqrt(2))))
		
		ii+=1
	while(ii<nlayers+1)
	
	return summ
End
#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName= GEN_optimise
///GeneticOptimisation is a IGOR PRO procedure that fits data using a Genetic Algorithm method :written by Andrew Nelson
//Copyright (C) 2006 Andrew Nelson and Australian Nuclear Science and Technology Organisation
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

//GeneticOptimisation is a powerful code to fit data, and is an extremely good method of finding global minima in the optimisation map
//The procedure uses the algorithm given in:
//
// Wormington et al, Characterization of structures from X-ray scattering data using genetic algorithms, Phil. Trans. R. Soc. Lond. A (1999) 357, 2827-2848
//
//The software should be compatible with Macintosh/PC/NT platforms and requires that IGOR Pro* is installed. 
//You do not have to purchase IGOR Pro - a free demo version of IGOR Pro is available, however some utilities are disabled (such as copying to/from the clipboard)
//IGOR Pro is a commercial software product available to Mac/PC/NT users. 
//A free demo version of IGOR is available from WaveMetrics Inc. These experiments and procedures were created using IGOR Pro 5.04
//The routines have not been tested on earlier versions of IGOR.

#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName= GEN_optimise
#include <WaveSelectorWidget>
#include <PopupWaveSelector>

Menu "Motofit"
	"Genetic curvefitting /1", Genetic_curvefitting()
End

Function Genetic_Curvefitting()
	string cdf = getdatafolder(1)
	if(itemsinlist(winlist("gencurvefitpanel",";",""))==0)
		if(!datafolderexists("root:packages:motofit:gencurvefit"))
			newdatafolder/o root:packages
			newdatafolder/o root:packages:motofit
			newdatafolder/o/s root:packages:motofit:gencurvefit
			string/g cmd
			if(!exists("lasttab"))
				variable/g lasttab=0
			endif
			if(!exists("saveStatus"))
				string/g saveStatus
			endif
			if(!exists("numcoefs"))
				variable/g numcoefs
			endif
			if(!exists("weighting_radio"))
				variable/g weighting_radio=1
			endif
			if(!exists("destlen"))
				variable/g destlen = 200
			endif
			if(!exists("cursorstart"))
				string/g cursorstart=""
			endif
			if(!exists("cursorfinish"))
				string/g cursorfinish=""
			endif
			if(!exists("ydataWAV"))
				string/g ydataWAV = "_none_"
			endif
			if(!exists("coefWAV"))
				string/g coefWAV = "_new wave_"
			endif
			if(!exists("xdataWAV"))
				string/g xdataWAV = "_calculated_"
			endif
			if(!exists("weightWAV"))
				string/g weightWAV = "_none_"
			endif
			if(!exists("functionstr"))
				string/g functionstr = stringfromlist(1,GEN_Functionlists())
			endif
			if(!exists("nindvars"))
				variable/g nindvars = 1
			endif
			if(!exists("numpoints"))
				variable/g numpoints
			endif
			if(!exists("holdstring"))
				string/g holdstring=""
			endif
			if(!exists("maskWAV"))
				string/g maskWAV = "_none_"
			endif
			if(!exists("limitsWAV"))
				string/g limitsWAV = "_from below_"
			endif
			if(!exists("destWAV"))
				string/g destWAV = "_auto_"
			endif
			if(!exists("resWAV"))
				string/g resWAV = "_none_"
			endif
			if(!exists("tol"))
				variable/g tol = 0.001
			endif
			if(!exists("iterations"))
				variable/g iterations = 100
			endif
			if(!exists("popsize"))
				variable/g popsize = 20
			endif
			if(!exists("recomb"))
				variable/g recomb = 0.5
			endif
			if(!exists("k_m"))
				variable/g k_m =0.7
			endif
	
			if(!waveexists(root:packages:motofit:gencurvefit:GEN_listwave))
				make/o/n=(0,5)/t Gen_listwave
				make/o/n=(0,5) Gen_listselwave
				numcoefs=1
			endif
			Gen_listwave[][0] = num2istr(p)
			Gen_listselwave=0
			Gen_listselwave[][1] = 2
			Gen_listselwave[][2] = 32
			Gen_listselwave[][3] = 2
			Gen_listselwave[][4] = 2
		endif
		Execute "Gen_curvefitpanel_init()"
	else
	endif
	gen_setstatus()
	setdatafolder $cdf
End

 Function Gen_curvefitpanel_init() : Panel
 	svar ydataWav = root:packages:motofit:gencurvefit:ydataWav
	svar xdataWav = root:packages:motofit:gencurvefit:xdataWav
	svar coefWav = root:packages:motofit:gencurvefit:coefWav
	svar weightWav = root:packages:motofit:gencurvefit:weightWav
	svar maskWav = root:packages:motofit:gencurvefit:maskWav
	svar resWav = root:packages:motofit:gencurvefit:resWav
	svar functionstr = root:packages:motofit:gencurvefit:functionstr
	svar holdstring = root:packages:motofit:gencurvefit:holdstring
	svar limitsWav = root:packages:motofit:gencurvefit:limitsWAV
	svar destWav = root:packages:motofit:gencurvefit:destwav
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /k=2/W=(343,159,930,540) as "Curvefitting with Genetic Optimisation"
	Dowindow/C gencurvefitpanel
	TabControl tab0,pos={12,6},size={560,324},proc=gen_tabcontrol
	TabControl tab0,tabLabel(0)="Function and Data",tabLabel(1)="Data Options"
	TabControl tab0,tabLabel(2)="Coefficients",tabLabel(3)="Output Options",value= 0
	Button fit_button,pos={19,343},size={81,24},proc=Gen_doFitButtonProc,title="Do it"
	Button tocmdline_button,pos={114,343},size={103,24},proc=GEN_tocmdline_buttonproc,title="To Cmd Line"
	Button toclip_button,pos={231,343},size={103,24},proc=GEN_toclip_buttonproc,title="To Clip"
	Button cancel_button,pos={463,343},size={103,24},proc=GEN_cancelButtonProc,title="cancel"
	GroupBox Function_group_tab0,pos={41,63},size={174,199},disable=1,title="Function",mode=1
	PopupMenu FunctionStr_popup_tab0,pos={52,86},size={148,20},disable=1,proc=gen_functionstr
	PopupMenu FunctionStr_popup_tab0,mode=2,bodyWidth= 148,value= #"GEN_Functionlists()"
	GroupBox ydata_group_tab0,pos={275,63},size={232,51},disable=1,title="Y Data"
	GroupBox xdata_group_tab0,pos={275,127},size={233,133},disable=1,title="X Data"
	TitleBox xdata_title_tab0,pos={291,144},size={196,12},disable=1,title="If you only have a ywave select _calculated_"
	TitleBox xdata_title_tab0,frame=0
	
	SetVariable ydataWav_setvar_tab0,pos={294,86},size={180,20},title=" ",fsize=12
	SetVariable ydataWav_setvar_tab0,bodyWidth= 180,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "ydataWav_setvar_tab0", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:ydataWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "ydataWav_setvar_tab0", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_ydataWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "ydataWav_setvar_tab0","_none_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "ydataWav_setvar_tab0","_none_")
	
	SetVariable xdataWav_setvar_tab0,pos={294,164},size={180,20},title=" ",fsize=12
	SetVariable xdataWav_setvar_tab0,bodyWidth= 180,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "xdataWav_setvar_tab0", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:xdataWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "xdataWav_setvar_tab0", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_xdataWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "xdataWav_setvar_tab0","_calculated_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "xdataWav_setvar_tab0","_calculated_")
	
	CheckBox fromtarget_tab0 title="From target?",fsize=10,pos={481,52}
	
	GroupBox range_group_tab1,pos={29,51},size={170,127},disable=1,title="Range"
	GroupBox weighting_group_tab1,pos={211,51},size={170,127},disable=1,title="Weighting"
	GroupBox mask_group_tab1,pos={394,51},size={170,127},disable=1,title="Data Mask"

	SetVariable weightWAV_setvar_tab1,pos={217,74},size={140,20},title=" ",fsize=12
	SetVariable weightWAV_setvar_tab1,bodyWidth= 140,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "weightWAV_setvar_tab1", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:weightWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "weightWAV_setvar_tab1", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_dataWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "weightWAV_setvar_tab1","_none_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "weightWav_setvar_tab1","_none_")

	SetVariable range_lower_tab1,pos={41,98},size={55,21},disable=1,title=" "
	SetVariable range_lower_tab1,fSize=14,proc=gen_range_setvarProc
	SetVariable range_lower_tab1,limits={-inf,inf,0},value= root:packages:motofit:gencurvefit:cursorstart,bodyWidth= 50
	SetVariable range_upper_tab1,pos={129,99},size={55,21},disable=1,title=" "
	SetVariable range_upper_tab1,fSize=14,proc=gen_range_setvarProc
	SetVariable range_upper_tab1,limits={-inf,inf,0},value= root:packages:motofit:gencurvefit:cursorfinish,bodyWidth= 50
	Button rangecursors_button_tab1,pos={37,143},size={67,26},disable=1,title="cursors", proc=gen_cursors_buttonproc
	Button range_button_tab1,pos={123,143},size={67,26},disable=1,title="clear",proc=gen_clearcursors_buttonproc
	TitleBox rangelimits_group_tab1,pos={50,74},size={106,15},disable=1,title="start\t\tend"
	TitleBox rangelimits_group_tab1,fSize=12,frame=0
	GroupBox weightingchoice_group_tab1,pos={222,102},size={148,69},disable=1,title="Wave contains"
	CheckBox weighting_check0_tab1,pos={235,125},size={101,14},disable=1,proc=Gen_weightingRadioProc,title="Standard Deviation"
	CheckBox weighting_check0_tab1,value= 1,mode=1
	CheckBox weighting_check1_tab1,pos={235,144},size={112,14},disable=1,proc=Gen_weightingRadioProc,title="1/Standard Deviation"
	CheckBox weighting_check1_tab1,value= 0,mode=1

	SetVariable maskWAV_setvar_tab1,pos={400,74},size={140,20},title=" ",fsize=12
	SetVariable maskWAV_setvar_tab1,bodyWidth= 140,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "maskWAV_setvar_tab1", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:maskWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "maskWAV_setvar_tab1", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_dataWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "maskWAV_setvar_tab1","_none_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "maskWav_setvar_tab1","_none_")
 	
	CheckBox fromtarget_tab1 title="Select waves from target?",fsize=10,pos={113,248}
	

	SetVariable coefWAV_setvar_tab2,pos={23,57},size={227,20},title="Coefficient Wave",fsize=11
	SetVariable coefWAV_setvar_tab2,bodyWidth= 140,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "coefWAV_setvar_tab2", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:coefWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "coefWAV_setvar_tab2", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_coefWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "coefWAV_setvar_tab2","_new wave_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "coefWav_setvar_tab1","_new wave_")

	SetVariable limitsWAV_setvar_tab2,pos={326,94},size={173,20},title="Limits Wave",fsize=11
	SetVariable limitsWAV_setvar_tab2,bodyWidth= 110,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "limitsWAV_setvar_tab2", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:limitsWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "limitsWAV_setvar_tab2", matchStr="*", listoptions="DIMS:2,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1,maxcols:2,mincols:2",namefilterproc = "Gen_filter_limitsWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "limitsWAV_setvar_tab2","_from below_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "limitsWav_setvar_tab2","_from below_")


	Button graphnow_button_tab2,pos={91,94},size={90,20},proc=gen_graphnowbutton,title="Graph now"
	Button graphnow_button_tab2,fSize=11
	ListBox coefficients_listbox_tab2,pos={23,147},size={538,177},disable=1,proc=Gen_ListBoxProc
	ListBox coefficients_listbox_tab2,listWave=root:packages:motofit:gencurvefit:Gen_listwave
	ListBox coefficients_listbox_tab2,selWave=root:packages:motofit:gencurvefit:Gen_listselwave
	ListBox coefficients_listbox_tab2,mode= 5,editStyle= 1,widths={30,80,20,60,60}
	
	SetVariable destWav_setvar_tab3,pos={17,45},size={211,20},title="Destination",fsize=11
	SetVariable destWav_setvar_tab3,bodyWidth= 140,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "destWav_setvar_tab3", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:destWav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "destWav_setvar_tab3", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_destWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "destWav_setvar_tab3","_auto_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "destWav_setvar_tab3","_auto_")

	SetVariable resWav_setvar_tab3,pos={38,75},size={191,20},title="residual",fsize=11
	SetVariable resWav_setvar_tab3,bodyWidth= 140,noedit=1
	MakeSetVarIntoWSPopupButton("gencurvefitpanel", "resWav_setvar_tab3", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:reswav",content = WMWS_Waves)
	PopupWS_MatchOptions("gencurvefitpanel", "resWav_setvar_tab3", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_resWav")
	PopupWS_AddSelectableString("gencurvefitpanel", "resWav_setvar_tab3","_none_;_auto wave_")
	PopupWS_SetSelectionFullPath("gencurvefitpanel", "resWav_setvar_tab3","_none_")


	CheckBox covar_check_tab3,pos={36,224},size={163,15},title="Create covariance matrix"
	CheckBox covar_check_tab3,fSize=12,value= 0
	CheckBox suppress_check_tab3,pos={36,246},size={164,15},title="Suppress screen updates"
	CheckBox suppress_check_tab3,fSize=12,value= 0
	SetVariable destlen_setvar_tab3,pos={280,44},size={112,17},title="Length:  "
	SetVariable destlen_setvar_tab3,fSize=11
	SetVariable destlen_setvar_tab3,limits={0,inf,0},value= root:packages:motofit:gencurvefit:destlen,bodyWidth= 60
	TitleBox tit1_title_tab2,pos={44,127},size={24,14},disable=1,title="coef"
	TitleBox tit1_title_tab2,fSize=11,frame=0
	TitleBox tit2_title_tab2,pos={133,127},size={63,14},disable=1,title="Initial guess"
	TitleBox tit2_title_tab2,fSize=11,frame=0
	TitleBox tit3_title_tab2,pos={253,127},size={29,14},disable=1,title="hold?"
	TitleBox tit3_title_tab2,fSize=11,frame=0
	TitleBox tit4_title_tab2,pos={335,127},size={55,14},disable=1,title="lower limit"
	TitleBox tit4_title_tab2,fSize=11,frame=0
	TitleBox tit5_title_tab2,pos={450,127},size={57,14},disable=1,title="upper limit"
	TitleBox tit5_title_tab2,fSize=11,frame=0
	SetVariable iterations_setvar_tab1,pos={424,206},size={125,17},disable=1,title="iterations"
	SetVariable iterations_setvar_tab1,fSize=11
	SetVariable iterations_setvar_tab1,limits={1,inf,0},value= root:packages:motofit:gencurvefit:iterations,bodyWidth= 70
	SetVariable popsize_setvar_tab1,pos={395,232},size={154,17},disable=1,title="population size"
	SetVariable popsize_setvar_tab1,fSize=11
	SetVariable popsize_setvar_tab1,limits={1,inf,0},value= root:packages:motofit:gencurvefit:popsize,bodyWidth= 70
	SetVariable recom_setvar_tab1,pos={348,259},size={201,17},disable=1,title="recombination constant"
	SetVariable recom_setvar_tab1,fSize=11
	SetVariable recom_setvar_tab1,limits={0,1,0},value= root:packages:motofit:gencurvefit:recomb,bodyWidth= 70
	SetVariable km_setvar_tab1,pos={377,286},size={173,17},disable=1,title="mutation constant"
	SetVariable km_setvar_tab1,fSize=11
	SetVariable km_setvar_tab1,limits={0,1,0},value= root:packages:motofit:gencurvefit:k_m,bodyWidth= 70
	Button default_button_tab2,pos={522,92},size={42,20},proc=gen_defaultlims_buttonproc,title="default"
	Button default_button_tab2,fSize=9
	
End

 Function gen_tabcontrol(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			Modifycontrol PopupWS_Button0,win= gencurvefitpanel, disable=(tab!=0)
			Modifycontrol PopupWS_Button1,win= gencurvefitpanel, disable=(tab!=0)
			Modifycontrol PopupWS_Button2,win= gencurvefitpanel, disable=(tab!=1)
			Modifycontrol PopupWS_Button3,win= gencurvefitpanel, disable=(tab!=1)
			Modifycontrol PopupWS_Button4,win= gencurvefitpanel, disable=(tab!=2)
			Modifycontrol PopupWS_Button5,win= gencurvefitpanel, disable=(tab!=2)
			Modifycontrol PopupWS_Button6,win= gencurvefitpanel, disable=(tab!=3)
			Modifycontrol PopupWS_Button7,win= gencurvefitpanel, disable=(tab!=3)
						
			ModifyControlList ControlNameList("",";","*_tab0") disable=(tab!=0)
			ModifyControlList ControlNameList("",";","*_tab1") disable=(tab!=1)
			ModifyControlList ControlNameList("",";","*_tab2") disable=(tab!=2)
			ModifyControlList ControlNameList("",";","*_tab3") disable=(tab!=3)
			break
	endswitch

	return 0
End

Function gen_functionstr(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			svar/z functionStr = root:packages:motofit:gencurvefit:functionstr
			functionstr = pa.popstr
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			break
	endswitch

	return 0
End
Function Gen_waveselectionNotification(event, wavepath, windowName, ctrlName)
		Variable event
		String wavepath
		String windowName
		String ctrlName
		SVAR coefWav = root:packages:motofit:gencurvefit:coefWav
		NVAR numcoefs = root:packages:motofit:gencurvefit:numcoefs

		switch(event)
			case WMWS_SelectionChanged:				//WMWS_SelectionChanged = 4, the only event code.  Defined in WaveSelectorWidget
				strswitch(ctrlname)
					case "ydataWav_setvar_tab0":
						nvar numpoints = root:packages:motofit:gencurvefit:numpoints
						numpoints = numpnts($wavepath)
						break
					case "limitsWAV_setvar_tab2":
						if(cmpstr(wavepath,"_from below_"))
							wave limits = $(wavepath)
							Gen_insertLimits(limits)
						endif
						break	
					case "coefWAV_setvar_tab2":					
						if(cmpstr(wavepath,"_New Wave_")==0)
							string newwavename
							variable nc
							dowindow/w=popupWSpanel /k popupwspanel
							newpanel/W=(0,0,1,1)
							dowindow/c popupwspanel
							
							Prompt newwavename,"enter the new wave name"
							Prompt nc,"and the number of coefficients (>=1)"
							do
								doprompt "Create a new fit wave",newwavename,nc
								if(V_flag)
									break
								else
									newwavename = possiblyquotename(newwavename)
									if(exists(newwavename))
										Doalert 0, "name already in use"
										continue
									endif
									if(strlen(newwavename)==0 || itemsinlist(wavelist(newwavename,";","")) || strlen(newwavename)>31)
										Doalert 0,"Please enter a valid wavename"
										continue
									endif
									if(nc<1)
										Doalert 0, "number of coefficients must be >0"
										continue
									endif
									make/o/d/n=(nc) $newwavename = 0
									string fullpath = getdatafolder(1)+newwavename
									
									//another BODGE
									//the function that calls this notify procedure doesn't check that you have created anything before if returns.
									//this means if you create a wave, then use popws_setselectionfull path it overwrites whatever you did.
									
									string cmd = "PopupWS_SetSelectionFullPath(\""+windowname+"\",\""+ctrlname+"\",\""+ fullPath+"\")"
									execute/p cmd
//									killcontrol/w = gencurvefitpanel coefWAV_setvar_tab2
//									SetVariable coefWAV_setvar_tab2,win = gencurvefitpanel,pos={23,57},size={227,20},title="Coefficient Wave",fsize=11
//									SetVariable coefWAV_setvar_tab2,win = gencurvefitpanel,bodyWidth= 140,noedit=1
//									MakeSetVarIntoWSPopupButton("gencurvefitpanel", "coefWAV_setvar_tab2", "Gen_waveselectionNotification", "root:Packages:Motofit:gencurvefit:coefWav",content = WMWS_Waves)
//									PopupWS_MatchOptions("gencurvefitpanel", "coefWAV_setvar_tab2", matchStr="*", listoptions="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MINROWS:1",namefilterproc = "Gen_filter_coefWav")
//									PopupWS_AddSelectableString("gencurvefitpanel", "coefWAV_setvar_tab2","_new wave_")
//
//									PopupWS_SetSelectionFullPath(windowname,ctrlname, fullPath)
									coefWav = newwavename
									numcoefs = nc
									break
								endif
							while(1)
							Gen_expandnpars(numcoefs)
							Gen_insertCoefs($fullpath)
						else
							Wave coefs = $(wavepath)
							numcoefs = Dimsize(coefs,0)
							Gen_expandnpars(numcoefs)
							Gen_insertCoefs(coefs)
						endif
						break
				endswitch
				break
		endswitch
		Gen_rebuildPopups(event,wavepath,windowname,ctrlname)
End

Function Gen_expandnpars(numpars)
	variable numpars
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	variable ii
	variable prev = dimsize(Gen_listwave,0)
	
	Redimension/n=(numpars,5) GEN_listselwave,GEN_listwave
	GEN_listselwave[][4] =2
	GEN_listselwave[][3]=2
	GEN_listselwave[][1]=2
	for(ii=prev ; ii< numpars ; ii+=1)
		GEN_listselwave[ii][2]=32
	endfor
	GEN_listwave[][0]=num2istr(p)
	
End

Gen_expandnpars(numpars)
Gen_insertCoefs(coefs)

 Function Gen_insertCoefs(coefs)
	Wave coefs
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	if(numpnts(coefs)!=Dimsize(GEN_listwave,0) || Wavedims(coefs)!=1)
		Abort "error somewhere"
	endif
	Gen_listwave[][1] = num2str(coefs[p])
End

 Function Gen_insertLimits(limits)
	Wave limits
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	if(dimsize(limits,0)!=Dimsize(GEN_listwave,0) || dimsize(limits,1)!=2 || Wavedims(limits)!=2)
		Abort "error somewhere"
	endif
	Gen_listwave[][3] = num2str(limits[p][0])
	Gen_listwave[][4] = num2str(limits[p][1])
End

 Function Gen_extractLimits()
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	make/o/d/n=(dimsize(gen_listwave,0),2) root:packages:motofit:gencurvefit:gen_limits
	Wave gen_limits = root:packages:motofit:gencurvefit:gen_limits
	gen_limits[][0] = str2num(gen_listwave[p][3])
	gen_limits[][1] = str2num(gen_listwave[p][4])
End


 Function Gen_weightingRadioProc(CB_Struct):checkboxcontrol
	STRUCT WMCheckboxAction &CB_Struct
	
	NVAR weighting_Radio = root:packages:motofit:gencurvefit:weighting_Radio
	
	strswitch (CB_Struct.ctrlname)
		case "weighting_check0_tab1":
			weighting_Radio= 1
			break
		case "weighting_check1_tab1":
			weighting_Radio= 2
			break
	endswitch
	CheckBox weighting_check0_tab1,value= weighting_Radio==1,win=gencurvefitpanel
	CheckBox weighting_check1_tab1,value= weighting_Radio==2,win=gencurvefitpanel
End


Function/s GEN_Functionlists()
	string theList="", UserFuncs, XFuncs
	string options = "KIND:10"
	options += ",SUBTYPE:FitFunc"
	options += ",NINDVARS:1"
	UserFuncs = FunctionList("*", ";",options)
	UserFuncs = RemoveFromList("GFFitFuncTemplate", UserFuncs)
	UserFuncs = RemoveFromList("GFFitAllAtOnceTemplate", UserFuncs)
	UserFuncs = RemoveFromList("NewGlblFitFunc", UserFuncs)
	UserFuncs = RemoveFromList("NewGlblFitFuncAllAtOnce", UserFuncs)
	UserFuncs = RemoveFromList("GlobalFitFunc", UserFuncs)
	UserFuncs = RemoveFromList("GlobalFitAllAtOnce", UserFuncs)
	UserFuncs = RemoveFromList("MOTO_GFFitFuncTemplate", UserFuncs)
	UserFuncs = RemoveFromList("MOTO_GFFitAllAtOnceTemplate", UserFuncs)
        
	XFuncs = FunctionList("*", ";", "KIND:12")
	if (strlen(UserFuncs) > 0)
		theList +=  "\\M1(   User-defined functions:;"
		theList += UserFuncs
	endif
	if (strlen(XFuncs) > 0)
		theList += "\\M1(   External Functions:;"
		theList += XFuncs
	endif
	if (strlen(theList) == 0)
		theList = "\\M1(No Fit Functions"
	endif
	return theList
End


 Function GEN_cancelButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			gen_savestatus()
			Killwindow GenCurvefitPanel
			break
	endswitch

	return 0
End

 Function GEN_tocmdline_buttonproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR cmd = root:packages:motofit:gencurvefit:cmd
	switch( ba.eventCode )
		case 2: // mouse up
			if(Gen_parsetoFitCmd())
				return 0
			endif
			Tocommandline cmd
			gen_savestatus()
			killwindow gencurvefitpanel
			break
	endswitch

	return 0
End

 Function GEN_toclip_buttonproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	SVAR cmd = root:packages:motofit:gencurvefit:cmd
	switch( ba.eventCode )
		case 2: // mouse up
			if(Gen_parsetoFitCmd())
				return 0
			endif
			putscraptext cmd
			gen_savestatus()
			killwindow gencurvefitpanel
			break
	endswitch

	return 0
End

 Function Gen_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			if(numtype(str2num(listwave[row][col])))
				DoAlert 0, "Numeric value required"
			endif
			break
	endswitch

	return 0
End

 Function Gen_checkLimits()
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	variable ii
	for(ii=0;ii<dimsize(gen_listwave,0);ii+=1)
		if(numtype(str2num(gen_listwave[ii][3])))
			Doalert 0, "Lower Limit: "+num2istr(ii)+ " is not a number"
			return 1
		endif
		if(numtype(str2num(gen_listwave[ii][4])))
			Doalert 0, "Upper limit: "+num2istr(ii)+ " is not a number"
			return 1
		endif
	endfor
End


 Function Gen_checkParams()
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	variable ii
	for(ii=0;ii<dimsize(gen_listwave,0);ii+=1)
		if(numtype(str2num(gen_listwave[ii][1])))
			Doalert 0, "Parameter: "+num2istr(ii)+ " is not a number"
			return 1
		endif
	endfor
End

 Function Gen_checkLimitBoundaries()
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	variable ii
	variable val,lowlim,upperlim
	for(ii=0;ii<dimsize(gen_listwave,0);ii+=1)
		val = str2num(gen_listwave[ii][1])
		lowlim = str2num(gen_listwave[ii][3])
		upperlim = str2num(gen_listwave[ii][4])
		if( !(gen_listselwave[ii][2]&2^4))
			if(lowlim>upperlim)
				Doalert 0, "lower limit for parameter: "+num2istr(ii)+ " is greater than the upper limit"
			endif
		Endif
	endfor
End

 Function Gen_buildholdstring()
	Wave/T Gen_listwave = root:packages:motofit:gencurvefit:Gen_listwave
	Wave Gen_listselwave = root:packages:motofit:gencurvefit:Gen_listselwave
	SVAR holdstring = root:packages:motofit:gencurvefit:holdstring
	holdstring = ""
	variable ii
	for(ii=0;ii<dimsize(Gen_listwave,0);ii+=1)
		if(gen_listselwave[ii][2]&2^4)
			holdstring +="1"
		else
			holdstring +="0"
		endif
	endfor
End

 Function Gen_parsetoFitCmd()
	variable err
	Gen_buildholdstring()
	if(Gen_checkParams())
		return 1
	endif
	if(Gen_checkLimits())
		return 1
	endif	
	if(gen_checklimitboundaries())
		return 1
	endif
	
	string hostwindow = "gencurvefitpanel"
	string ydataWav = PopupWS_GetSelectionFullPath(hostWindow, "ydataWav_setvar_tab0")
	string xdataWav = PopupWS_GetSelectionFullPath(hostWindow, "xdataWav_setvar_tab0")
	string coefWav = PopupWS_GetSelectionFullPath(hostWindow, "coefWav_setvar_tab2")
	string weightWav = PopupWS_GetSelectionFullPath(hostWindow, "weightWav_setvar_tab1")
	string  maskwav = PopupWS_GetSelectionFullPath(hostWindow, "maskWav_setvar_tab1")
	string resWav = PopupWS_GetSelectionFullPath(hostWindow, "resWav_setvar_tab3")
	svar functionstr = root:packages:motofit:gencurvefit:functionstr
	nvar weighting_radio = root:packages:motofit:gencurvefit:weighting_radio
	nvar destlen = root:packages:motofit:gencurvefit:destlen
	svar cursorstart = root:packages:motofit:gencurvefit:cursorstart
	svar cursorfinish = root:packages:motofit:gencurvefit:cursorfinish
	svar holdstring = root:packages:motofit:gencurvefit:holdstring
	string limitsWav = PopupWS_GetSelectionFullPath(hostWindow, "limitsWav_setvar_tab2")
	string destWav = PopupWS_GetSelectionFullPath(hostWindow, "destWav_setvar_tab3")
	svar cmd = root:packages:motofit:gencurvefit:cmd
	nvar tol = root:packages:motofit:gencurvefit:tol
	nvar iterations = root:packages:motofit:gencurvefit:iterations
	nvar popsize = root:packages:motofit:gencurvefit:popsize
	nvar recomb = root:packages:motofit:gencurvefit:recomb
	nvar k_m = root:packages:motofit:gencurvefit:k_m
	Wave ywave = $ydataWav
	
	cmd = "gencurvefit "
	if(cmpstr(xdataWav,"_calculated_") !=0)
		cmd += "/X="+xdataWav
	endif

	cmd += "/K={"+num2str(iterations)+","+num2str(popsize)+","+num2str(k_m)+","+num2str(recomb)+"}"
	cmd += "/TOL="+num2str(tol)
	
	if(cmpstr(destWav,"_auto_") == 0)
		cmd+="/L="+num2str(destlen)
	else
		cmd += "/D="+destWav
	endif
	
	if(cmpstr(maskWav,"_none_") !=0)
		cmd +="/M="+maskwav
	endif
	
	if(cmpstr(resWav,"_none_")==0)
	elseif(cmpstr(resWav,"_auto wave_")==0)
		cmd += "/R"
	else
		cmd += "/R="+resWav
	endif
	
	if(cmpstr(weightWav,"_none_"))
		cmd+="/W="+weightWav
		if(weighting_radio ==1)
			cmd+="/I=1"
		elseif(weighting_radio==2)
			cmd+="/I=0"
		endif
	endif
	
	controlinfo/w=gencurvefitpanel suppress_check_tab3
	if(V_Value)
		cmd+="/N"
	endif
	
	controlinfo/w=gencurvefitpanel covar_check_tab3
	if(V_Value)
		cmd+="/MAT"
	endif
	
	if(cmpstr(functionstr,"_none_")==0)
		Doalert 0, "You haven't entered a fitfunction"
		return 1
	else
		cmd+= " "+functionstr
	endif
	if(cmpstr(ydataWav,"_none_")==0)
		DoAlert 0, "You haven't entered a ywave"
		return 1
	else
		cmd+= ","+ydataWav
	endif
	
	if(strlen(cursorstart)>0 || strlen (cursorfinish)>0)
		string topgraph = winname(0,1)
		SVAR ydataWavstr = root:packages:motofit:gencurvefit:ydataWav
		variable start,finish
		if(gen_checkcursors(cursorstart) || gen_checkcursors(cursorfinish))
			return 1
		endif
		strswitch(cursorstart)
			case "pcsr(A)":
				err = whichlistitem(ydatawavstr,tracenamelist(topgraph,";",1))
				if(err==-1)
					Doalert 0, "the y wave is not displayed as a trace in the topgraph"
					return 1
				endif
				if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
					if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
						Doalert 0,"The cursors are not on the same wave. Please move them so that they are."
						return 1
					endif
				else
					doalert 0,"The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
					return 1
				endif
				start = pcsr(A)
				break
			case "pcsr(B)":
				err = whichlistitem(ydatawavstr,tracenamelist(topgraph,";",1))
				if(err==-1)
					Doalert 0, "the y wave is not displayed as a trace in the topgraph"
					return 1
				endif
				if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
					if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
						Doalert 0,"The cursors are not on the same wave. Please move them so that they are."
						return 1
					endif
				else
					doalert 0,"The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
					return 1
				endif
				start = pcsr(B)
				break
			default:
				start = str2num(cursorstart)
				break
		endswitch
		strswitch(cursorfinish)
			case "pcsr(A)":
				err = whichlistitem(ydatawavstr,tracenamelist(topgraph,";",1))
				if(err==-1)
					Doalert 0, "the y wave is not displayed as a trace in the topgraph"
					return 1
				endif
				if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
					if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
						Doalert 0,"The cursors are not on the same wave. Please move them so that they are."
						return 1
					endif
				else
					doalert 0,"The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
					return 1
				endif
				finish = pcsr(A)
				break
			case "pcsr(B)":
				err = whichlistitem(ydatawavstr,tracenamelist(topgraph,";",1))
				if(err==-1)
					Doalert 0, "the y wave is not displayed as a trace in the topgraph"
					return 1
				endif
				if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
					if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
						Doalert 0,"The cursors are not on the same wave. Please move them so that they are."
						return 1
					endif
				else
					doalert 0,"The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
					return 1
				endif
				finish = pcsr(B)
				break
			default:
				finish= str2num(cursorfinish)
				break
		endswitch
		if(finish<start || start<0 || finish <0 || finish>numpnts(ywave) || finish-start <1)
			doalert 0, "There is something wrong with the cursor range entered"
			return 1
		endif
		cmd+="["+num2istr(start)+","+num2istr(finish)+"]"
	endif

	
	if(cmpstr(coefWav,"_default_")==0 || cmpstr(coefWav,"_new Wave_")==0)
		Doalert 0, "You need to select a coefficient Wave"
		return 1
	else 
		Wave/t gen_listwave = root:packages:motofit:gencurvefit:gen_listwave
		Wave coefs = $coefWav
		redimension/n=(dimsize(gen_listwave,0)) coefs
		coefs[] = str2num(gen_listwave[p][1])
		cmd+=","+coefWav
	endif
	cmd+=",\""+holdstring+"\""
	
	if(cmpstr(limitswav,"_from below_")==0)
		gen_extractlimits()
		cmd +=",root:packages:motofit:gencurvefit:gen_limits"
	else
		Wave/t gen_listwave = root:packages:motofit:gencurvefit:gen_listwave
		Wave limits = $limitsWav
		limits[][0] = str2num(gen_listwave[p][3])
		limits[][1] = str2num(gen_listwave[p][4])
		cmd+=","+limitsWav
	endif
	return 0
End

 Function gen_graphnowbutton(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	svar ydataWav = root:packages:motofit:gencurvefit:ydataWav
	svar xdataWav = root:packages:motofit:gencurvefit:xdataWav
	svar coefWav = root:packages:motofit:gencurvefit:coefWav
	svar weightWav = root:packages:motofit:gencurvefit:weightWav
	svar maskWav = root:packages:motofit:gencurvefit:maskWav
	svar resWav = root:packages:motofit:gencurvefit:resWav
	svar functionstr = root:packages:motofit:gencurvefit:functionstr
	svar destWav = root:packages:motofit:gencurvefit:destWav
	nvar destlen = root:packages:motofit:gencurvefit:destLen
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(cmpstr(ydataWav,"_none_")==0)
				doalert 0, "Please select a ywave first"
				return 0
			endif
			Wave/z ywave = $PopupWS_GetSelectionFullPath("gencurvefitpanel","ydataWav_setvar_tab0")

			if(!waveexists(ywave))
				DoAlert 0, "the y wave doesn't exist, have you moved it, or did you select a data folder in the ywave popup by mistake?"
				return 0
			endif
			
			variable err = whichlistitem(ydatawav,(tracenamelist(winname(0,1),";",1)));
			if(err==-1)
				DoAlert 0, "It was impossible to plot your fitting function: the fit data is not on the top graph"
				return 0
			endif
			
			if( Gen_checkParams())
				return 0
			endif
			
			if(cmpstr(coefWav,"_new Wave_")==0)
				Doalert 0, "You need to select a coefficient Wave"
				return 0
			else 
				Wave/t gen_listwave = root:packages:motofit:gencurvefit:gen_listwave
				Wave coefs = $(PopupWS_GetSelectionFullPath("gencurvefitpanel","coefWav_setvar_tab2"))
				redimension/n=(dimsize(gen_listwave,0)) coefs
				coefs[] = str2num(gen_listwave[p][1])
			endif
			
			string output
			output = cleanupname("fit_"+ydatawav,1)
			make/o/d/n=(numpnts(ywave)) $output = NaN
			Wave outputWav = $(output)
			setscale/p x,dimoffset(ywave,0),dimdelta(ywave,0), outputWav

			string fulloutputpath = getwavesdatafolder(outputWav,2)
			string fullcoefpath =  getwavesdatafolder(coefs,2)
			string fullxwavepath =  PopupWS_GetSelectionFullPath("gencurvefitpanel","xdataWav_setvar_tab0")
			string cmd
			string funcinfo = functioninfo(functionstr)
			variable nparams = numberbykey("N_Params",funcinfo)
			switch(nparams)
				case 2:
					if(!(numberbykey("PARAM_0_TYPE",funcinfo)&16484) || (numberbykey("PARAM_1_TYPE",funcinfo)!=4))
						DoAlert 0, "Something may be wrong with your fitfunction"
					else
	
						if(cmpstr(xdataWav,"_calculated_")==0)
							cmd = fulloutputpath+"="+functionstr+"("+fullcoefpath+",x)"
						else
							cmd = fulloutputpath +"="+functionstr+"("+fullcoefpath+","+fullxwavepath+")"
						endif
					endif
					break
				case 3:
					if(!(numberbykey("PARAM_0_TYPE",funcinfo)&16484) || !(numberbykey("PARAM_1_TYPE",funcinfo)&16484) || !(numberbykey("PARAM_2_TYPE",funcinfo)&16484) )
						DoAlert 0, "Something may be wrong with your fitfunction"
					else
						if(cmpstr(xdataWav,"_calculated_")==0)
							make/o/d/n=(numpnts(outputWav)) root:packages:motofit:gencurvefit:tempx
							Wave tempx = root:packages:motofit:gencurvefit:tempx
							tempx[] = dimoffset(outputWav,0)+p*dimdelta(outputWav,0)
							cmd = functionstr+"("+fulloutputpath+","+fullcoefpath+",root:packages:motofit:gencurvefit:tempx)"
						else
							cmd = functionstr+"("+fullcoefpath+","+fulloutputpath+","+fullxwavepath+")"
						endif
					endif
					break
				default:
					Doalert 0, "Cannot handle multivariate fits in this dialogue at the moment"
					return 0
					break
			endswitch
			execute/q cmd
			err = whichlistitem(output,(tracenamelist(winname(0,1),";",1)))
			if(err!=-1)
				removefromgraph/w=$(winname(0,1)) $output
			endif
			if(cmpstr(xdataWav,"_calculated_")==0)
				appendtograph/w=$(winname(0,1)) outputWav
			else
				Wave xwave = $(fullxwavepath)
				appendtograph/w=$(winname(0,1)) outputWav vs xwave 
			endif
	endswitch

	return 0
End

Function Gen_doFitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			if(!Gen_parsetoFitCmd())
				svar cmd = root:packages:motofit:gencurvefit:cmd
				
				//if the fitwave is already present it's a good idea to remove it. 	
				svar ydataWav = root:packages:motofit:gencurvefit:ydataWav
				string output = cleanupname("fit_"+ydatawav,1)
				variable err = whichlistitem(output,(tracenamelist(winname(0,1),";",1)))
				if(err!=-1)
					removefromgraph/w=$(winname(0,1)) $output
				endif
				cmdToHistory(cmd)
				execute cmd
				gen_savestatus()
				
				killwindow gencurvefitpanel
			endif
			break
	endswitch

	return 0
End

Function cmdToHistory(cmd)	// returns 0 if Macintosh, 1 if Windows
	string cmd
	String platform= UpperStr(igorinfo(2))
	strswitch(platform)
		case "MACINTOSH":
			print num2char(-91) + cmd
		break
		case "WINDOWS":
			print num2char(-107)+cmd
		break
	endswitch
End

 Function gen_cursors_buttonproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			svar cursorstart = root:packages:motofit:gencurvefit:cursorstart 
			svar cursorfinish= root:packages:motofit:gencurvefit:cursorfinish
			
			string topgraph = winname(0,1)
			svar ydataWav = root:packages:motofit:gencurvefit:ydataWav 
		
			variable err = whichlistitem(ydataWav,tracenamelist(topgraph,";",1))
			if(err==-1)
				Doalert 0, "the y wave is not displayed as a trace in the topgraph"
				cursorstart = ""
				cursorfinish = ""
				return 0
			endif
			if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
				if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
					Doalert 0,"The cursors are not on the same wave. Please move them so that they are."
					cursorstart = ""
					cursorfinish = ""
					return 0
				endif
			else
				doalert 0,"The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
				cursorstart = ""
				cursorfinish = ""
				return 0
			endif
			svar cursorstart = root:packages:motofit:gencurvefit:cursorstart 
			svar cursorfinish= root:packages:motofit:gencurvefit:cursorfinish
			cursorstart = "pcsr(a)"
			cursorfinish = "pcsr(b)"
			break
	endswitch

	return 0
End

 Function gen_clearcursors_buttonproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			svar cursorstart = root:packages:motofit:gencurvefit:cursorstart 
			svar cursorfinish= root:packages:motofit:gencurvefit:cursorfinish
			cursorstart = ""
			cursorfinish = ""
			break
	endswitch

	return 0
End

 Function gen_range_setvarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
		
			gen_checkcursors(sva.sval)
			return 0
			break
	endswitch

	return 0
End

 Function gen_checkcursors(startORend)
	string startORend
	svar cursorstart= root:packages:motofit:gencurvefit:cursorstart
	svar cursorfinish= root:packages:motofit:gencurvefit:cursorfinish
	Wave ydata = $(PopupWS_GetSelectionFullPath("gencurvefitpanel", "ydataWav_setVar_tab0"))
	if(!waveexists(ydata))
		DoAlert 0, "y wave doesn't seem to exist in gen_checkcursors"
		return 1
	endif		
	if(cmpstr(startORend,"pcsr(A)")==0 || cmpstr(startORend,"pcsr(B)")==0)
		return 0
	endif
	if(numtype(str2num(startORend)))
		DoAlert 0, "Numeric value required"
		return 1
	endif
	cursorstart = num2istr(str2num(cursorstart))
	cursorfinish = num2istr(str2num(cursorfinish))
			
	if(str2num(cursorfinish) == str2num(cursorstart) || str2num(cursorstart)>str2num(cursorfinish))
		Doalert 0,"the start cursor must be less than the end cursor"
		return 1
	endif
	if(str2num(cursorfinish)<0 || str2num(cursorstart)<0)
		Doalert 0, "the start and end points must not have negative point numbers"
		return 1
	endif
	if(str2num(cursorstart)>numpnts(ydata)-1 || str2num(cursorstart)>numpnts(ydata)-1)
		Doalert 0," the point number entered is greater than the number of points in the ywave"
		return 1
	endif
End

 Function gen_defaultlims_buttonproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Wave/t  gen_listwave = root:packages:motofit:gencurvefit:gen_listwave
			variable ii
			for(ii=0; ii<dimsize(gen_listwave,0);ii+=1)
				if(str2num(gen_listwave[ii][1])<0)
					gen_listwave[ii][3] = num2str(2*str2num(gen_listwave[ii][1]))
					gen_listwave[ii][4] = "0"
				else				
					gen_listwave[ii][3] = "0"
					gen_listwave[ii][4] =  num2str(2*str2num(gen_listwave[ii][1]))
				endif
			endfor
			break
	endswitch

	return 0
End

Function Gen_isSameWave(wav1,wav2)
	Wave wav1,wav2

	if(!equalwaves(wav1,wav2,-1) || cmpstr(getWavesdatafolder(wav1,2),getwavesdatafolder(wav2,2)))
		return 0
	endif	

	return 1
End

//filters for displaying waves in waveselectors
Function Gen_filter_ydataWav(aName,contents)
	String aName
	variable contents
	
	if(cmpstr(aName,"_none_")==0)
		return 1
	endif
	Wave/z aWav = $aName
	
	controlinfo/w=gencurvefitpanel fromtarget_tab0
	variable fromtarget = v_value
	
	if(Wavedims(aWav)==1 && numpnts(aWav)>0)
		if(fromtarget)
			checkdisplayed $aName
			if(V_flag)
				return 1
			else
				return 0
			endif
		else
			return 1
		endif
	else
		return 0
	endif
End
Function Gen_filter_xdataWav(aName,contents)	//this can be used for x,weight,mask
	String aName
	variable contents

	Wave/z aWav = $aName
	if(cmpstr(aName,"_calculated_")==0)
		return 1
	endif

	controlinfo/w=gencurvefitpanel fromtarget_tab0
	variable fromtarget = v_value

	Wave/z ywav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "ydataWav_setvar_tab0")
	if(waveexists(ywav) && (Wavedims(aWav)!=1 || numpnts(aWav) != numpnts(ywav) || gen_isSamewave(aWav, yWAV)))
		return 0
	else 
		if(fromtarget)
			checkdisplayed $aName
			if(V_flag)
				return 1
			else
				return 0
			endif
		else
			return 1
		endif
	endif
End

Function Gen_filter_dataWav(aName,contents)	//this can be used for weight,mask
	String aName
	variable contents

	Wave/z aWav = $aName
	if(cmpstr(aName,"_none_")==0)
		return 1
	endif

	controlinfo/w=gencurvefitpanel fromtarget_tab1
	variable fromtarget = v_value
	
	Wave/z ywav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "ydataWav_setvar_tab0")
	if(waveexists(ywav) && (Wavedims(aWav)!=1 || numpnts(aWav) != numpnts(ywav) ))
		return 0
	else 
		if(fromtarget)
			checkdisplayed $aName
			if(V_flag)
				return 1
			else
				return 0
			endif
		else
			return 1
		endif
	endif
End

Function Gen_filter_coefWav(aName,contents)
	String aName
	variable contents

	Wave/z aWav = $aName
	if(cmpstr(aName,"_new wave_")==0)
		return 1
	endif

	Wave/z ywav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "ydataWav_setvar_tab0")
	Wave/z xwav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "xdataWav_setvar_tab0")
	Wave/z weightWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "weightWav_setvar_tab1")
	Wave/z maskWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "maskWav_setvar_tab1")
	Wave/z resWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "resWav_setvar_tab3")
	Wave/z destWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "destWav_setvar_tab3")
	
	if(waveexists(ywav) && Gen_isSameWave(yWav,aWAV))
		return 0
	endif
	if(waveexists(xwav) && Gen_isSameWave(xWav,aWav))
		return 0
	endif
	if(waveexists(weightwav) && Gen_isSameWave(weightWav,aWav))
		return 0
	endif
	if(waveexists(maskwav) && Gen_isSameWave(maskWav,aWav))
		return 0
	endif
	if(waveexists(reswav) && Gen_isSameWave(resWav,aWav))
		return 0
	endif
	if(waveexists(destwav) && Gen_isSameWave(destWav,aWav))
		return 0
	endif
	if(wavedims(aWav)!=1 || numpnts(aWav)<1)
		return 0
	endif
	
	return 1
End

Function Gen_filter_resWav(aName,contents)
	String aName
	variable contents

	Wave/z aWav = $aName
	if(cmpstr(aName,"_none_")==0 || cmpstr(aName,"_auto wave_")==0)
		return 1
	endif

	Wave/z ywav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "ydataWav_setvar_tab0")
	Wave/z xwav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "xdataWav_setvar_tab0")
	Wave/z weightWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "weightWav_setvar_tab1")
	Wave/z maskWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "maskWav_setvar_tab1")
	Wave/z resWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "resWav_setvar_tab3")
	Wave/z destWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "destWav_setvar_tab3")
	Wave/z coefWave = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "coefWav_setvar_tab2")

	if(waveexists(coefwav) && Gen_isSameWave(coefWav,aWav))
		return 0
	endif
	if(waveexists(xwav) && Gen_isSameWave(xWav,aWav))
		return 0
	endif
	if(waveexists(weightwav) && Gen_isSameWave(weightWav,aWav))
		return 0
	endif
	if(waveexists(maskwav) && Gen_isSameWave(maskwav,aWav))
		return 0
	endif
	if(waveexists(destwav) && Gen_isSameWave(destwav,aWav))
		return 0
	endif
	if(waveexists(coefwav) && Gen_isSameWave(coefWav,aWav))
		return 0
	endif
	if(waveexists(ywav) && (numpnts(aWav)<1 || Wavedims(aWav)!=1 || numpnts(aWav) != numpnts(ywav) || gen_isSamewave(aWav, yWAV)))
		return 0
	else 
		return 1
	endif
End

Function Gen_filter_destWav(aName,contents)
	String aName
	variable contents

	Wave/z aWav = $aName
	if(cmpstr(aName,"_none_")==0 || cmpstr(aName,"_auto wave_")==0)
		return 1
	endif

	Wave/z ywav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "ydataWav_setvar_tab0")
	Wave/z xwav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "xdataWav_setvar_tab0")
	Wave/z weightWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "weightWav_setvar_tab1")
	Wave/z maskWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "maskWav_setvar_tab1")
	Wave/z resWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "resWav_setvar_tab3")
	WAVE/z coefWav = $PopupWS_GetSelectionFullPath("gencurvefitpanel", "coefWav_setvar_tab2")
	
	if(waveexists(xwav) && Gen_isSameWave(xWav,aWav))
		return 0
	endif
	if(waveexists(weightwav) && Gen_isSameWave(weightWav,aWav))
		return 0
	endif
	if(waveexists(maskwav) && Gen_isSameWave(maskwav,aWav))
		return 0
	endif
	if(waveexists(reswav) && Gen_isSameWave(resWav,aWav))
		return 0
	endif
	if(waveexists(coefwav) && Gen_isSameWave(coefWav,aWav))
		return 0
	endif
	if(waveexists(ywav) && (numpnts(aWav)<1 || Wavedims(aWav)!=1 || numpnts(aWav) != numpnts(ywav) || gen_isSamewave(aWav, yWAV)))
		return 0
	else 
		return 1
	endif
End

Function Gen_filter_limitsWav(aName,contents)
	String aName
	variable contents

	Wave/z aWav = $aName
	if(cmpstr(aName,"_from below_")==0)
		return 1
	endif

	WAVE/t gen_listwave = root:packages:motofit:gencurvefit:gen_listwave
	nvar/z numcoefs = root:packages:motofit:gencurvefit:numcoefs
	
	if(Wavedims(aWav)!=2 || dimsize(aWav,1)!=2 || dimsize(aWav,0)!=numcoefs)
		return 0
	else
		return 1
	endif 
End

Function Gen_rebuildPopups(event,wavepath,windowname,ctrlname)
	Variable event
	String wavepath
	String windowName
	String ctrlName
	
	string ctrllist = "xdataWav_setvar_tab0:_calculated_;weightWav_setvar_tab1:_none_;maskWav_setvar_tab1:_none_;destWav_setvar_tab3:_auto_;resWav_setvar_tab3:_none_;"
	ctrllist += "coefWav_setvar_tab2:_new wave_;limitsWav_setvar_tab2:_from below_"
	
	string filterlist = "xdataWav_setvar_tab0:gen_filter_xdataWav;weightWav_setvar_tab1:gen_filter_dataWav;maskWav_setvar_tab1:gen_filter_dataWav;destWav_setvar_tab3:gen_filter_destWav;"
	filterlist+= "resWav_setvar_tab3:gen_filter_resWav;coefWav_setvar_tab2:gen_filter_coefWav;limitsWav_setvar_tab2:gen_filter_limitsWav"
	
	variable ii
	string ctrl
	string ctrlWavStr,nameFilterProcStr
	
	strswitch(ctrlname)
		default:
			Wave/z ywave = $wavepath
				variable numpoints = numpnts(ywave)
				for(ii=0;ii<itemsinlist(ctrllist,";");ii+=1)
					ctrl = stringfromlist(ii,ctrllist,";")
					ctrl = stringfromlist(0,ctrl,":")
					ctrlWavStr = PopupWS_GetSelectionFullPath("gencurvefitpanel", ctrl)
					
					nameFilterProcStr = stringbykey(ctrl,filterlist)
					FUNCREF namefiltertemplate namefilterproc = $nameFilterProcStr
					if(!namefilterproc(ctrlWavStr,0))
						PopupWS_SetSelectionFullPath("gencurvefitpanel", ctrl, stringbykey(ctrl,ctrllist))
					endif
				endfor
		break
	
	endswitch

End

function gen_savestatus()

	string ctrllist = "ydataWav_setVAR_tab0:_none_;xdataWav_setvar_tab0:_calculated_;weightWav_setvar_tab1:_none_;maskWav_setvar_tab1:_none_;destWav_setvar_tab3:_auto_;resWav_setvar_tab3:_none_;"
	ctrllist += "coefWav_setvar_tab2:_new wave_;limitsWav_setvar_tab2:_from below_"
	svar saveStatus = root:packages:motofit:gencurvefit:saveStatus
	nvar lasttab = root:packages:motofit:gencurvefit:lasttab
	
	variable ii
	string ctrl
	for(ii=0;ii<itemsinlist(ctrllist);ii+=1)
		ctrl = stringfromlist(ii,ctrllist)
		ctrl = stringfromlist(0,ctrl,":")
		ctrllist = replacestringbykey(ctrl,ctrllist,PopupWS_GetSelectionFullPath("gencurvefitpanel", ctrl))
	endfor
	savestatus = ctrllist
	
	controlinfo/w=gencurvefitpanel tab0
	lasttab = V_Value
End

function gen_setstatus()
	
	string ctrllist = "ydataWav_setVAR_tab0:_none_;xdataWav_setvar_tab0:_calculated_;weightWav_setvar_tab1:_none_;maskWav_setvar_tab1:_none_;destWav_setvar_tab3:_auto_;resWav_setvar_tab3:_none_;"
	ctrllist += "coefWav_setvar_tab2:_new wave_;limitsWav_setvar_tab2:_from below_"
	svar saveStatus = root:packages:motofit:gencurvefit:saveStatus
	nvar lasttab = root:packages:motofit:gencurvefit:lasttab

	if(strlen(saveStatus)==0)
		savestatus = ctrllist
	endif
	variable ii
	string ctrl,val
	for(ii=0;ii<itemsinlist(ctrllist);ii+=1)
		ctrl = stringfromlist(ii,ctrllist)
		ctrl = stringfromlist(0,ctrl,":")
		val = stringbykey(ctrl,saveStatus)
		if(waveexists($val))
			PopupWS_SetSelectionFullPath("gencurvefitpanel", ctrl, val)
		endif
		if(cmpstr(ctrl,"coefWav_setvar_tab2")==0 && waveexists($val))
			Gen_expandnpars(numpnts($val))
			Gen_insertCoefs($val)
		endif
	endfor
	
	struct WMTabControlAction tca
	tca.eventcode=2
	tca.tab=lasttab		
	gen_tabcontrol(tca)	
	tabcontrol tab0 win=gencurvefitpanel,value = lasttab
End
	
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
////////
////////	Below this is the old genetic optimisation code.  It may come in useful for those 
////////	who can't use the XOP
////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////


Structure GEN_optimisation
Wave GEN_parwave		//what are the initial parameters?
String GEN_parwavename

String GEN_holdstring		//the holdstring for holding parameters
Variable GEN_holdBits	//an integer representation of holdstring
variable GEN_numvarparams

Wave GEN_limits			//what are the limits on your parameters?
Wave GEN_b			//what is the best fit so far?
Funcref GEN_allatoncefitfunc fin	//what fit function are you going to use?
Funcref GEN_fitfunc fan
Variable GEN_popsize
Variable k_m
Wave GEN_trial
Wave GEN_yy
string GEN_ywavename
Wave GEN_xx
Wave GEN_ee
String GEN_ywaveDF
String GEN_xwaveDF
String GEN_ewaveDF
String GEN_parwaveDF	
Wave GEN_yybestfit
Variable GEN_generations	
Variable GEN_recombination
Wave GEN_chi2matrix
Wave GEN_populationvector
Wave GEN_bprime
Wave GEN_pvector
variable GEN_currentpvector
variable GEN_chi2best
variable GEN_whattype
Variable GEN_V_fittol
Wave GEN_parnumber
String GEN_callfolder
variable GEN_quiet //don't print stuff in history area
Endstructure


Function/S dec2bin(int)
	variable int
	string binary="",bin=""
	variable ii=0,remainder
	do
		binary+=num2istr(mod(int,2))
		int=floor(int/2)
	while(int!=0)
	//now reverse order of binary to get proper number
	for(ii=strlen(binary);ii>-1;ii-=1)
		bin+=binary[ii]
	endfor
	
	return bin
End

Function/S GEN_holdallstring(numvarparams)
	variable numvarparams
	variable ii
	string str=""
	for(ii=0 ; ii<numvarparams ; ii+=1)
		str+="1"
	endfor
	return str
End

Function bin2dec(bin)
	string bin
	variable int=0
	variable ii, binlen = strlen(bin) -1

	for(ii=strlen(bin)-1 ; ii>-1 ; ii-=1)
		if(cmpstr(bin[ii],"1") == 0)
			int+=2^(binlen - ii)
		endif
	endfor
	return int
End

Function GEN_isbitset(value,bit)
	variable value,bit
	
	string binary=dec2bin(value)
	
	//if you want to examine bits higher than the logical size of the holdvalue then they must
	//not be "set"
	//e.g. holdstring is 110
	// Gen_reverseString("110") returns "011"
	// bin2dec("011") returns 3
	// GEN_isbitset(3,2) should return 0.
	
	if(bit>strlen(binary)-1)
		return 0
	endif
	
	variable bool=str2num(binary[strlen(binary)-bit-1])
	
	return bool
End

Function/S GEN_reverseString(str)
	//this function reverses the string order because bits are set from RHS
	string str
	string localcopystr = str
	str = ""
	variable ii
	//now reverse order of binary to get proper number
	for(ii=strlen(localcopystr);ii>-1;ii-=1)
		str +=localcopystr[ii]
	endfor
	return str
End

//HERE'S WHERE YOU START IF YOU WANT TO FIT PROGRAMATICALLY
Function GEN_curvefit(func,parwave,ywave,holdstring,[x,w,c,mask,cursors,popsize,k_m,recomb,iters,tol,q])
	//this is the first insertion to the GENETIC optimisation
	
	//REQUIRED
	//func		:	name of the fitfunction, as a string
	//parwave	:	parameter wave for sending to the fitfunction
	//ywave		:	wave containing the data
	//holdstring	:	string that specifies the parameters you want to vary	
	
	//OPTIONAL
	//x			:	wave containing the x values for the fit. SHould be same length as ywave
	//w			:	weight wave containing the standard deviations of all the points
	//c			:	wave containing the upper and lower limits for each of parwave entries.  If not specified
	//				or is incorrect then program will ask to set limits
	//mask		:	wave to mask individual points in fit.  Should be same length as ywave.  Set mask[] to
	//				0 to ignore that point
	//popsize	:	population size multiplier (start with 10-20?)
	//k_m		:	mutation constant
	//recomb		:	recombination constant
	//iters		:	number of iterations through population
	//tol			:	a fractional decrease in chi2 below this value stops the fit
	//q			:	quiet mode.  Set this to 1 to set to quiet mode, nothing prints in history window
	
	String func
	Wave parwave,ywave
	String holdstring
	Wave x,w,c,mask
	variable cursors,popsize,k_m,recomb,iters,tol,q
	
	//use the GEN_optimisation structure	
	Struct GEN_optimisation gen
	
	//where are you calling the function from?
	//these are so you can retun the output to the right places.
	gen.GEN_callfolder=getdatafolder(1)
	variable/g V_fiterror = 0
	
	try
		//make the datafolders for the fitting
		Newdatafolder/o root:packages
		newdatafolder/o root:packages:motofit
		Newdatafolder/o root:packages:motofit:old_genoptimise
		
		//what type of fit function?
		variable whattype=Numberbykey("N_Params",Functioninfo(func))
		gen.GEN_whattype=whattype
		if(gen.GEN_whattype==2)			//point by point fit function
			Funcref GEN_fitfunc gen.fan=$func
		elseif(gen.GEN_whattype==3)		//all at once fit function 
			Funcref GEN_allatoncefitfunc gen.fin=$func
		endif
	
		//does the user want to operate in quiet mode?
		//check the maskwave and cursors
		if(ParamIsDefault(q))
			gen.GEN_quiet=0
		else
			if(q!=0)
				q=1
			endif
			gen.GEN_quiet=q
		endif

	
		//check the ywave and store its datafolder
		if(!waveexists(ywave))
			setdatafolder $gen.GEN_callfolder
			abort "y wave doesn't exist"
		elseif(dimsize(ywave,1)>0)
			setdatafolder $gen.GEN_callfolder
			abort "can only fit 1D data at this time"
		elseif(dimsize(ywave,0)==0)
			setdatafolder $gen.GEN_callfolder
			abort "y wave has no points to fit"
		else
			gen.GEN_ywaveDF=Getwavesdatafolder(ywave,1)
			duplicate/o ywave,root:packages:motofit:old_genoptimise:GEN_yy
		endif
	
		//check the parwave and store its datafolder
		if(!waveexists(parwave))
			setdatafolder $gen.GEN_callfolder
			abort "parameter wave doesn't exist"
		elseif(dimsize(parwave,1)>0)
			setdatafolder $gen.GEN_callfolder
			abort "can only use a 1D parameter wave at this time"
		elseif(dimsize(parwave,0)==0)
			setdatafolder $gen.GEN_callfolder
			abort "coefficient wave contains no parameters"
		else
			gen.GEN_parwaveDF=Getwavesdatafolder(parwave,2)
			duplicate/o parwave,root:packages:motofit:old_genoptimise:GEN_parwave
		endif
	
		//check the xwave (x) and store it's datafolder
		if(ParamIsDefault(x))		//you're going to be using the ywave scaling
			make/o/d/n = (dimsize(ywave,0)) root:packages:motofit:old_genoptimise:GEN_xx = leftx(ywave)+p*dimdelta(ywave,0)
		elseif(!ParamisDefault(x))	//the user specified an xwave
			if(!waveexists(x))
				setdatafolder $gen.GEN_callfolder
				abort "x wave doesn't exist"
			elseif(dimsize(x,1)>0)
				setdatafolder $gen.GEN_callfolder
				abort "can only use a 1D x wave at this time"
			elseif(dimsize(x,0)!=dimsize(ywave,0))
				setdatafolder $gen.GEN_callfolder
				abort "x wave requires same number of points as y wave" 
			else
				gen.GEN_xwaveDF=Getwavesdatafolder(x,1)
				duplicate/o x,root:packages:motofit:old_genoptimise:GEN_xx
			endif
		endif
	 
		//check the weightwave and store its datafolder
		if(ParamIsDefault(w))		//you're going to be fitting with unit weights
			make/o/d/n=(dimsize(ywave,0)) root:packages:motofit:old_genoptimise:GEN_ee=1
		elseif(!ParamisDefault(w))	//the user specified an weightwave
			if(!waveexists(w))
				setdatafolder $gen.GEN_callfolder
				abort "weight wave doesn't exist"
			elseif(dimsize(w,1)>0)
				setdatafolder $gen.GEN_callfolder
				abort "can only use a 1D weight wave at this time"
			elseif(dimsize(w,0)!=dimsize(ywave,0))
				setdatafolder $gen.GEN_callfolder
				abort "weight wave requires same number of points as y wave" 
			else
				gen.GEN_ewaveDF=Getwavesdatafolder(w,1)
				duplicate/o w,root:packages:motofit:old_genoptimise:GEN_ee
			endif
		endif	
		
		//check the maskwave and cursors
		variable ii=0
		if(ParamIsDefault(mask) == 0)
			if(!waveexists(mask))
				setdatafolder $gen.GEN_callfolder
				abort "specified mask wave doesn't exist"
			elseif(dimsize(mask,1)>0)
				setdatafolder $gen.GEN_callfolder
				abort "can only use a 1D mask wave at this time"
			elseif(dimsize(mask,0)!=dimsize(ywave,0))
				setdatafolder $gen.GEN_callfolder
				abort "mask wave requires same number of points as y wave" 
			else
				duplicate/o mask,root:packages:motofit:old_genoptimise:GEN_mask
			endif
		endif
	
		//check the holdstring
		if(strlen(holdstring)!=dimsize(parwave,0))
			setdatafolder $gen.GEN_callfolder
			abort "holdstring needs to be same length as coefficient wave"
		endif
	
		gen.GEN_holdstring = holdstring
		gen.GEN_numvarparams=0
		
		variable test = strlen(holdstring)
		for(ii=0;ii<strlen(holdstring);ii+=1)
			if(cmpstr(holdstring[ii],"0") == 0)
				gen.GEN_numvarparams += 1
			endif
			if(cmpstr(holdstring[ii],"0") != 0)
				if(cmpstr(holdstring[ii],"1") != 0)
					setdatafolder $gen.GEN_callfolder
					abort "holdstring can only contain 0 (vary) or 1 (hold)"
				endif
			endif
		endfor
		gen.GEN_holdBits = bin2dec(GEN_reverseString(holdstring))
	
		//Setdatafolder to Genetic Optimisation
		setdatafolder root:packages:motofit:old_genoptimise
	
		//setup wave references.
		Wave gen.GEN_yy=GEN_yy,gen.GEN_parwave=GEN_parwave,gen.GEN_ee=GEN_ee,gen.GEN_xx=GEN_xx,GEN_mask
		gen.GEN_parwavename=nameofwave(parwave)
		gen.GEN_ywavename=nameofwave(ywave)

		variable nit
		//search for any cursors, masked points, then NaN's to remove non-relevant points from wave
		if(ParamisDefault(cursors)==0)	//the user wants to use cursors
			if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
				if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
					abort "The cursors are not on the same wave. Please move them so that they are."
				endif
			else
				abort "The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
			endif
			if(cmpstr(CsrWave(A,"",1),nameofwave(ywave)) || cmpstr(CsrWave(B,"",1),nameofwave(ywave)))
				Doalert 1,"One of the cursors is not on the dataset you selected, continue?"
				if(V_flag==2)
					ABORT
				endif
			endif
			Variable start=pcsr(A),finish=pcsr(B),temp
			if(start>finish)
				temp=finish
				finish=start
				start=temp
			endif
			//create temporary copies of the data
			//this is because you're deleting points from the users wave
			//so remember to replace the points when you've finished doing the fit
			if(ParamisDefault(mask) == 0)
				Deletepoints (finish+1),(numpnts(gen.GEN_yy)-finish-1),gen.GEN_yy,gen.GEN_xx,gen.GEN_ee,GEN_mask
				Deletepoints 0,start, gen.GEN_yy,gen.GEN_xx,gen.GEN_ee,GEN_mask
			else
				Deletepoints (finish+1),(numpnts(gen.GEN_yy)-finish-1),gen.GEN_yy,gen.GEN_xx,gen.GEN_ee
				Deletepoints 0,start, gen.GEN_yy,gen.GEN_xx,gen.GEN_ee
			endif
		endif	
		
		if(ParamIsDefault(mask)==0)	
			for(ii=0;ii<numpnts(gen.GEN_yy);ii+=1)
				if(GEN_mask[ii]==0 || numtype(GEN_mask[ii])==2)
					deletepoints ii,1,gen.GEN_yy,gen.GEN_ee,gen.GEN_xx,GEN_mask	
					ii-=1
				endif
			endfor
		endif
	
		for(ii=0;ii<numpnts(gen.GEN_yy);ii+=1)
			if(numtype(gen.GEN_yy[ii])!=0 || numtype(gen.GEN_xx[ii])!=0 || numtype(gen.GEN_ee[ii])!=0)
				deletepoints ii,1,gen.GEN_yy,gen.GEN_ee,gen.GEN_xx	
				ii-=1
			endif
		endfor	
		if(dimsize(GEN_yy,0)==0)
			setdatafolder $gen.GEN_callfolder
			abort "there were no valid points in the dataset (after removing NaN and mask/cursor points)"
		endif
	
		//put the name of the function name in a global string
		String/g root:packages:motofit:old_genoptimise:fitfunctionname = 	func
		String/g root:packages:motofit:old_genoptimise:callfolder = gen.GEN_callfolder
		Variable/g root:packages:motofit:old_genoptimise:GEN_holdbits = gen.GEN_holdbits
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//do all the fitting
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//initialise the model	
		//get the intial setup, e.g. numgenerations, mutation constant, etc.
		if(ParamisDefault(popsize) || ParamisDefault(k_m) || ParamisDefault(recomb) || ParamisDefault(iters) || ParamisDefault(tol))
			GEN_searchparams(gen)
		else
			gen.GEN_generations = iters
			gen.GEN_popsize = popsize
			gen.k_m = k_m
			gen.GEN_recombination = recomb
			gen.GEN_V_fittol = tol
		endif
	
		//this sets up the waves for the genetic optimisation
		GEN_Initialise_Model(gen)
	
		Wave gen_b,gen.GEN_b = gen_b
	
		//make the limits wave
		//GEN_setlimitwave makes a limit wave if required
		//GEN_checkinitiallimits makes sure that the initial guess is between the limits
		variable ok
		if(Paramisdefault(c))
			do
				try	//the user may want to abort the fit at this stage and we need to return to the right DF
					GEN_setlimitwave(GEN_parnumber, gen.GEN_b)
					Wave GEN_limits,gen.GEN_limits=GEN_limits
					ok = GEN_checkinitiallimits(GEN_limits, gen.GEN_b)
				catch
					setdatafolder $gen.GEN_callfolder
					V_fiterror = 1
					ABORT
				endtry
			while(ok==1)
		elseif(Paramisdefault(c)==0)
			//make a limitswave, this may be overwritten in the calling function.		
			if(dimsize(c,1)!=2)
				setdatafolder $gen.GEN_callfolder
				abort "user supplied limit wave should be 2 column"
			endif
			if(dimsize(c,0) != dimsize(parwave,0))
				setdatafolder $gen.GEN_callfolder
				abort "user supplied limit wave should be the same length as the parameter wave"		
			endif

			duplicate/o c, root:packages:motofit:old_genoptimise:GEN_limits
			Wave GEN_limits,gen.GEN_limits=GEN_limits
			variable jj=0
			for(ii=0 ; ii<strlen(gen.GEN_holdstring) ; ii+=1)
				if(GEN_isbitset(gen.GEN_holdbits,ii))
					deletepoints ii-jj,1,root:packages:motofit:old_genoptimise:GEN_limits
					jj+=1
				endif
			endfor
		
			ok=GEN_checkinitiallimits(GEN_limits,GEN_b)

			if(ok==1)
				do
					try	//the user may want to abort the fit at this stage and we need to return to the right DF
						GEN_setlimitwave(GEN_parnumber,GEN_b)
					catch
						setdatafolder $gen.GEN_callfolder
						V_fiterror = 1
						ABORT
					endtry
					ok = GEN_checkinitiallimits(GEN_limits,GEN_b)
				while(ok==1)
			endif
		endif
	
		//make a whole set of guesses based on the parameter limits just created
		GEN_set_GENpopvector(GEN_b,GEN_limits)
	
		//setup the trial vector
		make/o/d/n=(dimsize(GEN_b,0)) GEN_trial
	
		Wave GEN_populationvector,gen.GEN_populationvector=GEN_populationvector 
	
		//initialise the Chi2array
		//enum is a wave that is used to evaluate Chi2, i.e. Rcalc
		duplicate/o GEN_xx,enum
		GEN_chi2array(gen)
	
		Wave GEN_chi2matrix,gen.GEN_chi2matrix=GEN_chi2Matrix
		Wave gen_b,gen.GEN_b=gen_b
		Wave gen.GEN_trial=gen_trial

		// make a table to illustrate the evolution
		duplicate/o GEN_populationvector,GEN_colourtable
		duplicate/o GEN_xx,GEN_yybestfit
		Wave gen.GEN_yybestfit=GEN_yybestfit
		GEN_evaluate(gen.GEN_yybestfit,GEN_b,gen)
	
		if(strlen(Winlist("evolve",";",""))==0)
			NewImage/k=1/n=evolve  root:packages:motofit:old_genoptimise:GEN_colourtable
			Modifygraph/w=evolve width=400,height=400
			ModifyImage GEN_colourtable ctab= {0,256,Rainbow,0}
			ModifyGraph/w=evolve mirror(left)=1,mirror(top)=0,minor(top)=0,axisEnab(left)={0.52,1};DelayUpdate
			Label left "pvector";DelayUpdate
			Label top "parameter"
			AppendToGraph/w=evolve /L=ydata/B=xdata root:packages:motofit:old_genoptimise:GEN_yybestfit vs root:packages:motofit:old_genoptimise:GEN_xx
			AppendToGraph/w=evolve /L=ydata/B=xdata root:packages:motofit:old_genoptimise:GEN_yy vs root:packages:motofit:old_genoptimise:GEN_xx
			ModifyGraph/w=evolve axisEnab(ydata)={0,0.48},freePos(ydata)={0,xdata};DelayUpdate
			ModifyGraph/w=evolve freePos(xdata)={0,ydata}
			ModifyGraph/w=evolve axisEnab(xdata)={0.05,1}
			ModifyGraph/w=evolve mode(GEN_yy)=3,marker(GEN_yy)=19,msize(GEN_yy)=1
			ModifyGraph/w=evolve rgb(GEN_yybestfit)=(0,0,0)
		endif
	
		Doupdate
	
		try				//the user may try to abort the fit, especially if it takes a long time	
			//do the first fill with the lowest chi2 value
			variable exchange1,exchange2
			//replace the bvector by the best perfoming from population vector
			//GEN_sort finds the lowest Chi2 value
			//GEN_Chi2matrix contains an array of all the Chi2 values for each pvector 
			//exchange1 is the position of the lowest chi2  value
			exchange1=GEN_sort(GEN_Chi2matrix)
			exchange2=0
			gen.GEN_chi2best=GEN_chi2matrix[exchange1]
			GEN_Chi2matrix[0]=GEN_Chi2matrix[exchange1]
		
			//GEN_replacepvector sets GEN_pvector from the populationvector
			//it also replaces num in the population vector
			GEN_replacepvector(GEN_populationvector,exchange1,exchange2)
			//GEN_replacebvector replaces the best fitvector so far with a subvector, in this case GEN_pvector
			//which has been updated with the previous command
			GEN_replacebvector(gen,gen.GEN_pvector)		
			gen.GEN_currentpvector=0
		
			//make a wave to follow the trend in Chi2
			make/o/d/n=1 GEN_chi2trend
			GEN_Chi2trend[0]=gen.GEN_chi2best
		
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			//now enter the fitting loops to improve it
			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			GEN_optimiseloop(gen)
			//we now have the bestvector, but have to load it into GEN_parwave
			GEN_insertVaryingParams(gen.GEN_parwave,gen.GEN_b,gen.GEN_holdbits)

			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			//make fit waves for the data and coefficients
			GEN_returnresults(gen)
		catch		//if the user aborts during the fit then send back the best position so far
			GEN_returnresults(gen)
			setdatafolder $gen.GEN_callfolder
			V_fiterror = 1
		endtry
	catch
		setdatafolder $gen.GEN_callfolder
		V_fiterror = 1
	endtry
End

Static Function GEN_searchparams(gen)
	Struct GEN_optimisation &gen
	Variable GEN_popsize=20
	Variable k_m=0.5
	Variable GEN_recombination=0.7
	Variable GEN_generations=100
	Variable GEN_V_fittol=0.0005
	prompt k_m,"mutation constant, e.g.0.5"
	prompt GEN_recombination,"enter the recombination constant"
	prompt GEN_generations,"how many generations do you want to use?"
	prompt GEN_popsize,"enter the population size multiplier e.g. 10"
	prompt GEN_V_fittol,"enter the fractional tolerance to stop fit (e.g. 0.05%=0.0005)"
	Doprompt "Set up genetic optimisation",GEN_generations,k_m,GEN_popsize,GEN_recombination,GEN_V_fittol
	String CDF=gen.GEN_callfolder
	if(V_flag==1)
		setdatafolder CDF
		ABORT
	endif
	gen.GEN_generations=GEN_generations
	gen.GEN_popsize=GEN_popsize
	gen.k_m=k_m
	gen.GEN_recombination=GEN_recombination
	gen.GEN_V_fittol=GEN_V_fittol
End

Static Function GEN_optimiseloop(gen)
	//this does all the looping of the optimisation
	Struct GEN_optimisation &gen
	Wave gen.GEN_populationvector,gen.GEN_Chi2matrix
	Wave GEN_Chi2trend
	
	string tagtext
	variable ii,jj,kk,tagchi2,nit
	
	if(!gen.GEN_quiet)
		print "_________________________________\rStarting Genetic Optimisation"
		print "Initial Chi2: "+num2str(gen.GEN_Chi2best)
	endif
	
	Dowindow/F evolve
	
	nit=dimsize(gen.GEN_populationvector,1)
	
	for(kk=0;kk<gen.GEN_generations;kk+=1)			//loop over the generations
		tagtext="Generation: "+num2istr(kk) + " Chi2: "+ num2str(gen.GEN_Chi2best)
		Tag/c/n=text0/f=0/x=20/y=-100/l=0 GEN_colourtable, 0, tagtext

		for(ii=0;ii<nit;ii+=1)
			gen.GEN_currentpvector=ii

			//now set up the trial vector using a wave from the populationvector and bprime
			//first set the pvector 
			GEN_trialvector(gen)

			//make sure that the trial vector has values within the limits
			GEN_ensureconstraints(gen)

			//calculate Chi2 of trial vector and pvector[][gen.GEN_currentpvector]
			//but first have to make pvector equal to trial vector
			variable chi2pvector=gen.GEN_Chi2matrix[ii]
			
			gen.GEN_pvector=gen.GEN_trial
			variable chi2trial=GEN_chi2(gen)

			if(chi2trial<chi2pvector)				//if the trial vector is better than pvector then replace it.
				gen.GEN_populationvector[][gen.GEN_currentpvector]=gen.GEN_trial[p]
				gen.GEN_Chi2matrix[ii]=chi2trial
						
				GEN_chromosome(ii)
						
				if(chi2trial<gen.GEN_Chi2best)		//if this trial vector is better than the current best then replace it
					GEN_replacebvector(gen,gen.GEN_trial)
					gen.GEN_populationvector[][0]=gen.GEN_b[p]
					gen.GEN_Chi2matrix[0]=chi2trial
							
					//update the groovy convergence image
					GEN_chromosome(0)
					GEN_evaluate(gen.GEN_yybestfit,GEN_b,gen)
					
					//add the value to the Chi2 trend
					redimension/n=(numpnts(Gen_Chi2trend)+1) GEN_chi2trend
					GEN_chi2trend[numpnts(GEN_chi2trend)-1] = chi2trial
										
					if((abs(chi2trial-gen.GEN_chi2best)/gen.GEN_chi2best)<gen.GEN_V_fittol)	//if the fractional decrease is less and 0.5% stop.
						gen.GEN_Chi2best=chi2trial
						if(!gen.GEN_quiet)
							print "tolerance reached"
						endif
						return 1
					endif
					gen.GEN_Chi2best=chi2trial
				endif
			endif
		endfor
		//update the convergence image

		doupdate
		Dowindow/F evolve
	endfor
	
	//after all this looping the best vector should be gen.GEN_b
End

Static Function GEN_sort(GEN_chi2matrix)
	Wave GEN_chi2matrix
	variable lowestpvector
	Wavestats/q/z/M=1 GEN_chi2matrix
	findvalue /V=(V_min) GEN_chi2matrix
	return V_Value
End

Static Function GEN_replacepvector(GEN_populationvector,num1,num2)
	//GEN_replacepvector sets GEN_pvector from the populationvector
	//it also replaces num in the population vector
	Wave GEN_populationvector
	Variable num1,num2
	Wave GEN_pvector
	Wave GEN_Chi2matrix
	
	GEN_pvector[]=GEN_populationvector[p][num1]
	ImageTransform/G=(num2)/D=GEN_pvector putCol GEN_populationvector // AG
End

Static Function GEN_replacebvector(gen,ww)
	Struct GEN_optimisation &gen
	Wave ww
	Wave gen.GEN_b
	gen.GEN_b=ww
End

Static Function GEN_trialvector(gen)
	//this function creates a trial vector from bprime and the current pvector
	//it fills from a random position along the trial length (start), then continues filling
	//from the start.  It always fills the last position from the bprime vector, to maintain
	//diversity.
	Struct GEN_optimisation &gen
	Wave gen.GEN_bprime
	Wave gen.GEN_populationvector
	Wave gen.GEN_trial
	
	variable size=dimsize(gen.GEN_populationvector,0) , popsize = dimsize(gen.GEN_populationvector,1)
	variable random_a,random_b
	variable recomb=gen.gen_recombination
	variable k_m = gen.k_m
	variable fillpos = abs(round(abs(enoise(size))-0.500000000001)),ii
	
	do
		random_a=round(abs(enoise(popsize-0.50000001)))
	while(random_a == gen.GEN_currentpvector)
	
	do
		random_b=round(abs(enoise(popsize-0.50000001)))
	while (random_a == random_b )	
                
	for(ii=0 ; ii<size ; ii+=1)
		gen.GEN_bprime[ii] = gen.GEN_populationvector[ii][0] + k_m*(gen.GEN_populationvector[ii][random_a] - gen.GEN_populationvector[ii][random_b]);
	endfor
	
	for(ii=0 ; ii<size ; ii+=1)
		gen.GEN_trial[ii] = gen.GEN_populationvector[ii][gen.GEN_currentpvector]
	endfor
                
	variable counter = 0
	do
		if ((abs(enoise(1)) < recomb) || (counter == size))
			gen.GEN_trial[fillpos] = gen.GEN_bprime[fillpos]
		endif
		fillpos+=1
		fillpos = mod(fillpos,size)
		counter +=1
	while(counter < size)
End

Static Function GEN_ensureconstraints(gen)
	//this function makes sure that the evolving numbers stay within the set limits.
	Struct GEN_optimisation &gen
	Wave gen.GEN_trial
	Wave gen.GEN_limits
	variable ii=0
	variable size=Dimsize(gen.GEN_trial,0)
	variable lowerbound,upperbound
	for(ii=0;ii<size;ii+=1)
		lowerbound=gen.GEN_limits[ii][0]
		upperbound=gen.GEN_limits[ii][1]
		if(gen.GEN_trial[ii]<lowerbound || gen.GEN_trial[ii]>upperbound)	//are we in the limits?
			gen.GEN_trial[ii]=(lowerbound+upperbound)/2+enoise(1)*(upperbound-lowerbound)/2		//this should ensure that the parameter is in limits!!!
		endif
	endfor
End


Static Function GEN_setlimitwave(GEN_parnumber,GEN_b)
	//this function allows the user to set limits for the optimisation
	Wave GEN_parnumber,GEN_b

	//want to add in a bit to make sure that we don't necessarily have to set up the limit wave
	// each time we do the fit
	variable alreadyexists=0
	Wave/z GEN_limits
	//if it already exists and it's the same size as the parameter wave, then you could be fitting the same dataset
	if(Waveexists(GEN_limits) && dimsize(GEN_limits,0)==numpnts(GEN_b)) 
		Doalert 2,"Motofit has detected that you may have tried to fit a similar dataset, use previous limits?"
		switch(V_flag)
			case 1:
				alreadyexists=1
				break
			case 2:
				alreadyexists=0
				break
			case 3:
				ABORT
				break
		endswitch
	endif
	
	//if it doesn't already exist, or you don't want to use the limits again	
	if(alreadyexists==0)
		duplicate/o GEN_b, GEN_limits
		redimension/n=(-1,2) GEN_limits		//one column for the lower limit and one column for the upper limit
		//in all probability the best values for the lower limits are 0, as a guess set the upper limits to twice the parameter value
		variable ii
		for(ii=0;ii<numpnts(GEN_b);ii+=1)
			if(GEN_b[ii]>0)
				GEN_limits[ii][1]=2*GEN_b[ii]
				GEN_limits[ii][0]=0
			else
				GEN_limits[ii][0]=2*GEN_b[ii]
				GEN_limits[ii][1]=0
			endif
		endfor
	endif	
	
	//you still get a chance to edit them
	edit/k=1/n=boundarywave GEN_parnumber,GEN_b,GEN_limits as "set limits for genetic optimisation"
	
	Modifytable title[1] = "parameter number"
	Modifytable title[2] = "initial guess"
	Modifytable title[3] = "lower limit"
	Modifytable title[4] = "upper limit"
	
	GEN_UsereditAdjust("boundarywave")
	
	Dowindow/K boundarywave
End

Static Function GEN_checkinitiallimits(GEN_limits,GEN_b)
	Wave GEN_limits,GEN_b
	Wave GEN_parnumber = root:packages:motofit:old_genoptimise:GEN_parnumber 
	variable ii,lowlimit,upperlimit,parameter,ok
	
	string warning=""
	for(ii=0;ii<numpnts(GEN_b);ii+=1)
		lowlimit=GEN_limits[ii][0]
		upperlimit=GEN_limits[ii][1]
		parameter=GEN_b[ii]
		if(lowlimit>upperlimit)
			warning = "lower limit " + num2istr(GEN_parnumber[ii]) + " is bigger than your upperlimit" 
			doalert 0, warning
			ok=1
			break
//		elseif(parameter<lowlimit || parameter > upperlimit)
//			warning = "parameter: " + num2istr(GEN_parnumber[ii]) + " is outside one of the limits"
//			doalert 0, warning
//			ok=1
//			break
		else
			ok=0
		endif
	endfor
	return ok
End

Static Function GEN_Initialise_Model(gen)
	//this function sets up the geneticoptimisation
	Struct GEN_optimisation &gen

	//the total size of the population, should be an integer number (~10?)
	variable GEN_popsize=gen.GEN_popsize		

	//subset of parameters to be fitted, it's the bestfit vector
	make/o/d/n=(gen.GEN_numvarparams) GEN_b
	Wave gen.GEN_b=GEN_b

	//makee a list of the parameter numbers you are changing
	make/o/d/n=(gen.GEN_numvarparams) GEN_parnumber
	Wave gen.GEN_parnumber=GEN_parnumber
	
	//ii is a loop counter, jj will be for how many parameters will vary
	Variable ii=0,jj=0			

	//and make a wave with the vectors, this wave is the best fit vector
	GEN_extractVaryingParams(gen.GEN_parwave,gen.GEN_b, gen.GEN_holdbits)
	
	for(ii=0 ; ii < numpnts(gen.GEN_parwave) ; ii+=1)
		if(GEN_isbitset(gen.GEN_holdbits,ii)==0)	//we want to fit that parameter
			GEN_parnumber[jj]=ii
			jj+=1
		endif
	endfor
	
	//now make the total population vector
	make/o/d/n=(gen.GEN_numvarparams,GEN_popsize*gen.GEN_numvarparams) GEN_populationvector
	Wave gen.GEN_populationvector=GEN_populationvector
	//make the difference vector, trial vector and two random vectors
	make/o/d/n=(gen.GEN_numvarparams) GEN_bprime
	Wave gen.GEN_bprime=GEN_bprime,gen.GEN_trial=GEN_trial
	
	//make a pvector
	make/o/d/n=(dimsize(GEN_populationvector,0)) GEN_pvector
	Wave gen.GEN_pvector=GEN_pvector	
End


Static Function GEN_set_GENpopvector(GEN_b,GEN_limits)
	//GEN_b is the best guess, GEN_limits[][0 or 1] are the lower/upper limits for the fit
	//GEN_b should already lie in between the limits!!!!!!!!!!!!!!!!
	Wave GEN_b,GEN_limits
	Wave GEN_populationvector
	//initialise loop counters
	Variable ii=0,jj=0,kk=0,nit,nit1

	//random will be a random number.  Lowerbound and upperbound are the limits on the parameters
	Variable random,lowerbound,upperbound
	//initialise GEN_populationvector, within the limits set by GEN_limits
	//first column is the initial parameters
	GEN_populationvector[][0]=GEN_b[p]
	
	//the rest should be created by random numbers.
	//go through each column one by one
	nit=Dimsize(GEN_populationvector,1)
	nit1=Dimsize(GEN_populationvector,0)
	for(ii=0;ii<nit1;ii+=1)
		lowerbound=GEN_limits[ii][0]
		upperbound=GEN_limits[ii][1]
		for(kk=1;kk<nit;kk+=1)
			//generate a random variable for that parameter
			random=(lowerbound+upperbound)/2+abs(lowerbound-upperbound)*enoise(0.5)
			GEN_populationvector[ii][kk]=random
		endfor
	endfor
End

Static Function GEN_chi2array(gen)
	//this function calculates the Chi_2 matrix for the population vector at the start of the optimisation	
	Struct GEN_optimisation &gen
	
	Wave gen.GEN_pvector
	Wave gen.GEN_populationvector

	make/o/d/n=(dimsize(GEN_populationvector,1)) GEN_chi2matrix
	Wave gen.GEN_chi2matrix=GEN_chi2matrix	
	variable ii=0,np=numpnts(GEN_chi2matrix)
	
	for(ii=0;ii<np;ii+=1)
		gen.GEN_pvector[]=gen.GEN_populationvector[p][ii]
		GEN_chi2matrix[ii]=GEN_chi2(gen)
	endfor
End

Static Function GEN_evaluate(evalwave,partialparamwave,gen)
	//this function evaluates Chi2 for evalwave (the ydata).  The partial parameter wave is here (i.e. the 'pvector')
	//the gen structure supplies the holdwave which fills up the full parameter wave.
	Wave evalwave,partialparamwave
	Struct GEN_optimisation &gen
	Wave GEN_parwave=gen.GEN_parwave

	Wave GEN_xx=gen.GEN_xx
	
	GEN_insertVaryingParams(gen.GEN_parwave,partialparamwave,gen.GEN_holdbits)								

	//now evaluate the wave
	if(gen.GEN_whattype==2)
		Funcref GEN_fitfunc gen.fan=gen.fan
		evalwave=gen.fan(GEN_parwave,gen.GEN_xx)
	elseif(gen.GEN_whattype==3)
		Funcref GEN_allatoncefitfunc gen.fin=gen.fin
		gen.fin(GEN_parwave,evalwave,gen.GEN_xx)
	endif
	
End

Static Function GEN_chi2(gen)
	//calculates chi2
	struct GEN_optimisation &gen
	Wave GEN_pvector=gen.GEN_pvector
	Wave GEN_yy=gen.GEN_yy,GEN_ee=gen.GEN_ee
	
	variable Chi2=0
	Wave enum
	
	//evaluate the enumerator using the current pvector 
	GEN_evaluate(enum,gen.GEN_pvector,gen)
	enum-=gen.GEN_yy
	enum/=gen.GEN_ee
	enum=enum*enum
	Wavestats/q/z/M=1 enum
	chi2=V_sum
	
	return Chi2
End

Function GEN_allatoncefitfunc(coefficients,ydata,xdata)
	//the function template for an all at once fitfunction
	Wave coefficients,ydata,xdata
End

Function GEN_fitfunc(coefficients,xx)
	//the function template for a normal fit function
	Wave coefficients
	variable xx
End

Function GEN_insertVaryingParams(baseCoef,varyCoef,holdbits)
	Wave baseCoef,varyCoef
	variable holdbits
	variable ii=0,jj=0
	for(ii=0 ; ii < numpnts(baseCoef) ; ii+=1)
		if(GEN_isBitSet(holdBits,ii) == 0)
			baseCoef[ii] = varyCoef[jj]
			jj+=1
		endif		
	endfor
End

Function GEN_extractVaryingParams(baseCoef,varyCoef, holdbits)
	Wave baseCoef,varyCoef
	variable holdbits	
	variable ii=0,jj=0
	for(ii=0 ; ii < numpnts(basecoef) ; ii+=1)
		if(GEN_isBitSet(holdBits,ii) ==0)
			varycoef[jj] = baseCoef[ii]
			jj+=1
		endif		
	endfor
End

Static Function GEN_UsereditAdjust(tableName)
	String tablename

	DoWindow/F $tableName		// Bring table to front
	if (V_Flag == 0)		// Verify that table exists
		Abort "where did the table go?"
		return -1
	endif

	NewPanel/K=2 /W=(139,341,382,432) as "Pause for user editing"
	DoWindow/C tmp_Pauseforedit		// Set to an unlikely name
	DrawText 21,20,"Edit the values in the table."
	Drawtext 21,40,"Once you press go then"
	Drawtext 21,60,"genetic optimisation will start."
	
	Button button0,pos={5,64},size={92,20},title="Continue"
	Button button0,proc=GEN_optimise#GEN_UsereditAdjust_Cont
	Button button1,pos={110,64},size={92,20},title="cancel",proc=GEN_optimise#GEN_UserEditAdjust_cancel
	//this line allows the user to adjust the cursors until they are happy with the right level.
	//you then press continue to allow the rest of the reduction to occur.
	PauseForUser tmp_Pauseforedit,$tablename

	return 0
End

static Function GEN_UserEditAdjust_Cont(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K tmp_Pauseforedit		// Kill self
End

Static Function GEN_UserEditAdjust_cancel(ctrlName) :Buttoncontrol 
	String ctrlName
	DoWindow/K tmp_Pauseforedit		// Kill self
	Dowindow/K boundarywave
	Svar callfolder = root:packages:motofit:old_genoptimise:callfolder
	Setdatafolder $callfolder 
	ABORT
End

Static Function GEN_returnresults(gen)
	Struct GEN_optimisation &gen
	//make fit waves for the data and coefficients
	variable ii=0,jj=0,use
	
	Wave GEN_parwave=gen.GEN_parwave
	Wave gen.GEN_yy = gen.GEN_yy
	Wave GEN_b = gen.GEN_b
	
	duplicate/o gen.GEN_xx GEN_fitx,GEN_fit
	GEN_evaluate(GEN_fit,GEN_b,gen)
		
	duplicate/o gen.GEN_parwave GEN_coefs
	//now rename the waves to what they should be called
	string ywave=gen.GEN_ywavename
	string xwave=cleanupname("fitx_"+ywave,0)
	ywave=cleanupname("fit_"+ywave,0)
	
	string writename=gen.GEN_callfolder+xwave
	duplicate/o GEN_fitx, $writename
	writename=gen.GEN_callfolder+ywave
	duplicate/o GEN_fit, $writename
	writename=gen.GEN_parwaveDF
	duplicate/o GEN_coefs, $writename
	//now return to the original datafolder
	Setdatafolder $gen.GEN_callfolder
	variable/g V_Chisq=gen.GEN_chi2best
	if(!gen.GEN_quiet)
		print "The refined Chi2 value was "+num2str(V_Chisq)+"\r_________________________________"
	endif
	killwaves/Z GEN_fit,GEN_fitx,GEN_coefs
	//add to Moto_returnresults
	Setdatafolder $gen.GEN_callfolder
	
End

Static Function GEN_chromosome(n)
	//this function makes groovy colours so that you can see when your fits are converging.
	variable n
	Wave GEN_populationvector,GEN_limits,GEN_colourtable
	GEN_colourtable[][n]=256*abs(GEN_populationvector[p][n]-GEN_limits[p][0])/abs(GEN_limits[p][1]-GEN_limits[p][0])		
End


Function GEN_setlimitsforGENcurvefit(coefs,holdstring,GEN_calldatafolder)
	Wave coefs
	String holdstring,GEN_Calldatafolder
    
	variable ok=1,ii,numvarparam=0,jj
    
	for(ii=0;ii<numpnts(coefs);ii+=1) 
		if(cmpstr(holdstring[ii],"0")==0)
			numvarparam+=1
		endif
	endfor
    
	Newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:old_genoptimise
	    
	String/g root:packages:motofit:old_genoptimise:callfolder = GEN_calldatafolder
	do
		try    //the user may want to abort the fit at this stage and we need to return to the right DF
			GEN_setlimitwaveGENcurvefit(coefs,holdstring,numvarparam) 
			Wave/z GENcurvefitdummylimits = root:packages:motofit:old_genoptimise:GENcurvefitdummylimits
			Wave/z GENcurvefitdummycoefs = root:packages:motofit:old_genoptimise:GENcurvefitdummycoefs
			ok = GEN_checkinitiallimits(GENcurvefitdummylimits, GENcurvefitdummycoefs) 
		catch
			setdatafolder $GEN_calldatafolder
			ABORT
		endtry
	while(ok==1)
    
	make/n=(numpnts(coefs),2)/o root:packages:motofit:old_genoptimise:GENcurvefitlimits
	Wave GENcurvefitlimits = root:packages:motofit:old_genoptimise:GENcurvefitlimits 
	jj=0
	for(ii=0;ii<numpnts(coefs);ii+=1)
		if(cmpstr(holdstring[ii],"0")==0)
			GENcurvefitlimits[ii][0] = GENcurvefitdummylimits[jj][0]
			GENcurvefitlimits[ii][1] = GENcurvefitdummylimits[jj][1] 
			coefs[ii] = GENcurvefitdummycoefs[jj]
			jj+=1
		else
			GENcurvefitlimits[ii][0] = -1
			GENcurvefitlimits[ii][1] = -1
		endif
	endfor
End

Function GEN_setlimitwaveGENcurvefit(coefs,holdstring,numvarparam) 
	//this function allows the user to set limits for the optimisation
	Wave coefs
	string holdstring
	variable numvarparam
	variable ii,jj=0
         
	Wave/z GENcurvefitlimits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
	Wave/z GENcurvefitdummylimits = root:packages:motofit:old_genoptimise:GENcurvefitdummylimits
	Wave/z GENcurvefitdummycoefs = root:packages:motofit:old_genoptimise:GENcurvefitdummycoefs
    
	//want to add in a bit to make sure that we don't necessarily have to set up the limit wave
	// each time we do the fit
	variable alreadyexists=0
	//if it already exists and it's the same size as the parameter wave, then you could be fitting the same dataset 
	if(Waveexists(GENcurvefitdummycoefs) && Waveexists(GENcurvefitdummylimits) && numvarparam == numpnts(GENcurvefitdummycoefs)) 
		Doalert 2,"Motofit has detected that you may have tried to fit a similar dataset, use previous limits?"
		switch(V_flag) 
			case 1:
				alreadyexists=1
				break
			case 2:
				alreadyexists=0				
				break
			case 3:
				ABORT
				break 
		endswitch
	endif
	
	make/o/d/n=(numvarparam,1) root:packages:motofit:old_genoptimise:GENcurvefitdummycoefs, root:packages:motofit:old_genoptimise:Gen_parnumber
	make/o/d/n=(numvarparam,2) root:packages:motofit:old_genoptimise:GENcurvefitdummylimits 
			      
	Wave/z GENcurvefitdummylimits= root:packages:motofit:old_genoptimise:GENcurvefitdummylimits 
	Wave/z GENcurvefitdummycoefs= root:packages:motofit:old_genoptimise:GENcurvefitdummycoefs
	Wave/z Gen_parnumber= root:packages:motofit:old_genoptimise:Gen_parnumber
	jj=0
	for(ii=0;ii<numpnts(coefs);ii+=1)
		if(cmpstr(holdstring[ii],"0")==0)
			Gen_parnumber[jj] = ii 
			GENcurvefitdummycoefs[jj] = coefs[ii]
			if(!alreadyexists)
				if(coefs[ii]>0)
					GENcurvefitdummylimits[jj][1]=2*coefs[ii] 
					GENcurvefitdummylimits[jj][0]=0
				else
					GENcurvefitdummylimits[jj][0]=2*coefs[ii]
					GENcurvefitdummylimits[jj][1]=0
				endif
			endif
			jj+=1
		endif
	endfor


	Wave/z GENcurvefitdummylimits= root:packages:motofit:old_genoptimise:GENcurvefitdummylimits 
	Wave/z GENcurvefitdummycoefs= root:packages:motofit:old_genoptimise:GENcurvefitdummycoefs
	Wave/z Gen_parnumber= root:packages:motofit:old_genoptimise:Gen_parnumber
  
	//you still get a chance to edit them
	edit/k=1/n=boundarywave GEN_parnumber,GENcurvefitdummycoefs,GENcurvefitdummylimits as "set limits for genetic optimisation" 
	Modifytable title[1] = "parameter number"
	Modifytable title[2] = "initial guess"
	Modifytable title[3] = "lower limit"
	Modifytable title[4] = "upper limit" 
    
	GEN_UsereditAdjust("boundarywave")
    
	Dowindow/K boundarywave
End

Function Moto_montecarlo(fn, w, yy, xx, ee, holdstring, Iters,[cursA, cursB])
	String fn
	Wave w, yy, xx, ee
	string holdstring
	variable Iters, cursA, cursB
	//the first fit is always on the pristine data
	
	string cDF = getdatafolder(1)
	variable ii,jj,kk, summ, err = 0

	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:old_genoptimise

	try
		//get initialisation parameters for genetic optimisation
		struct GEN_optimisation gen
		gen.GEN_Callfolder = cDF
		GEN_optimise#GEN_Searchparams(gen)
	
		//get limits
		GEN_setlimitsforGENcurvefit(w, holdstring, cDF)
		Wave limits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
	
		//make the montecarlo waves that you will actually fit
		duplicate/o yy, root:packages:motofit:old_genoptimise:y_montecarlo
		duplicate/o xx, root:packages:motofit:old_genoptimise:x_montecarlo
		duplicate/o ee, root:packages:motofit:old_genoptimise:e_montecarlo
		Wave y_montecarlo = root:packages:motofit:old_genoptimise:y_montecarlo
		Wave x_montecarlo = root:packages:motofit:old_genoptimise:x_montecarlo
		Wave e_montecarlo = root:packages:motofit:old_genoptimise:e_montecarlo
		
		//make a wave to put the montecarlo iterations in
		make/o/d/n=(Iters, dimsize(w, 0)) M_montecarlo
		make/o/d/n=(iters) W_chisq
		
		//take care of cursors
		if(paramisdefault(cursA))
			cursA = 0
		endif
		if(paramisdefault(cursB))
			cursB = dimsize(yy, 0)-1
		endif

		//now lets do the montecarlo fitting
		variable timed = datetime
		for(ii=0 ; ii<Iters ; ii+=1)
			if(ii>0)
				y_montecarlo[] = yy[p]
			else
				y_montecarlo[] = yy[p] + gnoise(ee[p])
			endif	
//			Gencurvefit/q/n/X=x_montecarlo/K={gen.GEN_generations, gen.GEN_popsize,gen.k_m, gen.GEN_recombination}/TOL=(gen.GEN_V_fittol) $fn, y_montecarlo[cursA,cursB], w, holdstring, limits
			Gencurvefit/q/n/X=x_montecarlo/I=1/W=e_montecarlo/K={gen.GEN_generations, gen.GEN_popsize,gen.k_m, gen.GEN_recombination}/TOL=(gen.GEN_V_fittol) $fn, y_montecarlo[cursA,cursB], w, holdstring, limits
			M_montecarlo[ii][] = w[q]
			W_chisq[ii] = V_chisq
			print "montecarlo ", ii, " done - total time = ", datetime-timed
		endfor
		print "overall time took: ", datetime - timed , " seconds"
	
		//now work out correlation matrix and errors.
		//see Heinrich et al., Langmuir, 25(7), 4219-4229
		make/n=(dimsize(w, 0))/o W_sigma954, means, stdevs
		make/n=(dimsize(w,0), dimsize(w, 0))/o M_correlation
		M_correlation = NaN
	
		for(ii = 0 ; ii<dimsize(w, 0) ; ii+=1)
			make/o/d/n=(Iters) goes
			goes = M_montecarlo[p][ii]
			Wavestats/alph=0.045501/M=2/q/w goes
			Wave M_wavestats
			W_sigma954[ii] = M_wavestats[25]- M_wavestats[24]
			means[ii] = M_wavestats[3]
			stdevs[ii] = M_wavestats[4]
			if(stringmatch(holdstring[ii], "1"))
				W_sigma954[ii] = NaN
			endif
		endfor
		for(ii=0 ; ii< dimsize(w, 0) ; ii+=1)
			for(jj= ii ; jj<dimsize(w,0) ; jj+=1)
				if(ii==jj || stringmatch(holdstring[ii], "1") || stringmatch(holdstring[jj], "1"))
					M_correlation[ii][jj]=NaN
				else			
					summ = 0
					for(kk = 0 ; kk < Iters ; kk+=1)
						summ += (M_montecarlo[kk][ii]-means[ii])*(M_montecarlo[kk][jj]-means[jj]) 
					endfor
					M_correlation[ii][jj] = summ / (Iters-1) / (stdevs[ii] * stdevs[jj])
				endif  
				M_correlation[jj][ii] = M_correlation[ii][jj]
			endfor
		endfor
	catch
		err = 1	
	endtry
	killwaves/z M_wavestats, goes, means, stdevs, fit_y_montecarlo
	setdatafolder $cDF
	return err
End
#pragma rtGlobals=1		// Use modern global access method.
#PRAGMA modulename = platypus
#include <Image Line Profile>
#pragma IgorVersion = 6.0

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

//DEPENDENCIES
//1) sockit.xop (www.igorexchange.com)
//2) zip.xop (www.igorexchange.com)
//3) easyHttp.xop (www.igorexchange.com)
//4) HDF5.xop (comes with IGOR)
//5) HFStoPOSIX.xop (comes with IGOR)
//6) Pla_peakfinder.ipf (comes from SLIM - the platypus reduction code)

//#pragma IndependentModule=Platypus
//
//		for sending sics commands that will be displayed
//	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
//		for sending an emergency stop command
//	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
//		for sending commands that won't be displayed, but to also get current axis information as it changes.
//	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
//		for synchronous queries
//	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
//		a string that is send on SOCK_cmd channel for user commands
//	NVAR SOCK_chopper = root:packages:platypus:SICS:SOCK_chopper
//		buffer wave for user sent sics commands
//	Wave/t cmd_buffer = root:packages:platypus:SICS:cmd_buffer
//		buffer wave for hidden commands and also current axis information
//	Wave/t interest_buffer = root:packages:platypus:SICS:interest_buffer
//
//		list of all the hipadaba paths and their values, all display variables will represent this text box.
//	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
//
//		current positions of axes.
//		w[][0] = shortname
//		w[][1] = hipadaba name
//		w[][2] = position
//		w[][3] = hipadaba path to softlowerlim
//		w[][4] = softlowerlim
//		w[][5] = hipadaba path to softupperlim
//		w[][6] = softupperlim
//	Wave/t axeslist = root:packages:platypus:SICS:axeslist
//	Wave selaxeslist = root:packages:platypus:sics:selAxesList
//   Wave cwAxes = root:packages:platypus:sics:cwAxes
//		the axis names of the histogram dataset (e.g. t:y:x)
//	SVAR root:packages:platypus:data:RAW:dataAxes = ""
//    Wave/t statemon =  root:packages:platypus:SICS:statemon
//		information on the statemonitor in SICS.
//		a variable for the hdf dataset reference
//	variable/g root:packages:platypus:data:RAW:HDF_Current
//		total counts in current detector
//	variable/g root:packages:platypus:data:RAW:integratedCounts
//		order of display in 2D graph
//	string/g root:packages:platypus:data:RAW:displayed:order
//		current status of SICS
//	string/g root:packages:platypus:SICS:sicsstatus
//		current status of histoserver
//	string/g histostatusStr = root:packages:platypus:SICS:histostatusStr
//		a textwave containing the batch commands to be executed
//	Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
	
Menu "Platypus"
	Submenu "FIZZY"
	"Platypus Operation",platypus#startSICS()
	"setup new experiment", experimentDetailsWizard()
	End
End

Function Setupdatafolders()
	//this function sets up the data folders for FIZZY to work
	String cDF=getdatafolder(1)

	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus

	//all data is kept in data
	Newdatafolder /o root:packages:platypus:data
	//this is where the RAW detector data goes
	Newdatafolder /o root:packages:platypus:data:RAW
	//this is where the displayed+ RAW detector
	Newdatafolder /o root:packages:platypus:data:RAW:displayed
	//this is where the fpx scan goes
	Newdatafolder /o root:packages:platypus:data:scan
	//batch scan stuff goes in here
	Newdatafolder/o root:packages:platypus:data:batchScan
	
	Newdatafolder /o root:packages:platypus:SICS

	setdatafolder $cDF
End

Function setUpGlobalVariables()
	//this should be preceded by a call to setupdatafolders()
	variable/g root:packages:platypus:SICS:SOCK_cmd=-1
	variable/g root:packages:platypus:SICS:SOCK_interupt=-1
	variable/g root:packages:platypus:SICS:SOCK_interest=-1
	variable/g root:packages:platypus:SICS:SOCK_sync=-1
	
	string/g root:packages:platypus:SICS:secondaryshutter
	string/g root:packages:platypus:SICS:tertiaryshutter
	
	variable/g root:packages:platypus:SICS:range
	variable/g root:packages:platypus:SICS:preset
	variable/g root:packages:platypus:SICS:numpoints=1
	
	string/g root:packages:platypus:SICS:sampleStr=" "
	string/g root:packages:platypus:SICS:sicsstatus=""
	string/g root:packages:platypus:SICS:histostatusStr=""
	
	string/g root:packages:platypus:data:RAW:dataAxes = ""
	variable/g root:packages:platypus:data:RAW:HDF_Current
	variable/g root:packages:platypus:data:RAW:integratedCounts
	string/g root:packages:platypus:data:RAW:displayed:order = ""

	variable/g root:packages:platypus:data:batchScan:currentpoint = -1
	 variable/g root:packages:platypus:data:batchScan:userPaused = 0
End

Function button_SICScmdpanel(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR sock_cmd = root:packages:platypus:SICS:SOCK_cmd
	NVAR sock_interupt= root:packages:platypus:SICS:SOCK_interupt

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlname)
				case "Estop_tab0":
					UserDefinedEstopBehaviour()	//defined in Instrument_specific_setup.
					break
				case "SICSclose_tab0":
					sicsclose()
					break
				case "UpdateHMM_tab2":
					getLatestData()
					if(itemsinlist(winlist("spawngraph0",";","")))	
						spawngraphstatspanel(str2num(getuserdata("spawngraph0","","type")))
					endif	

					break
				case "Go_tab1":
					//see if you're doing a batch scan
					if(batchScanStatus())
						print "you are already doing a batch scan, please stop that first"
						return 0
					endif
					//see if you're doing a batch scan
					if(fpxStatus())
						print "you are already doing an fpx scan, please stop that first"
						return 0
					endif

					NVAR range = root:packages:platypus:SICS:range
					NVAR numpoints = root:packages:platypus:SICS:numpoints
					NVAR preset = root:packages:platypus:SICS:preset
					SVAR sampleStr = root:packages:platypus:SICS:sampleStr
					ControlInfo /w=SICScmdpanel motor_tab1
					string motorStr = S_Value
					ControlInfo /w=SICScmdpanel save_tab1
					variable saveOrNot = V_Value
					Controlinfo/w=SICScmdpanel presettype_tab1
					string method = S_Value
										
					//now run the scan
					if(!fpx(motorStr,range,numpoints,presettype = method,preset = preset,saveOrNot = saveOrNot,samplename = sampleStr))
						Button/z Go_tab1 win=sicscmdpanel,disable=1	//if the scan starts disable the go button
						Button/z stop_tab1 win=sicscmdpanel,disable=0		//if the scan starts enable the stop button
						Button/z pause_tab1 win=sicscmdpanel,disable=0		//if the scan starts enable the pause button
						
						setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=2		//if the scan starts disable the title button
						setvariable/z preset_tab1 win=sicscmdpanel,disable=2
						PopupMenu/z presettype_tab1 win=sicscmdpanel,disable=2	
						PopupMenu/z motor_tab1 win=sicscmdpanel,disable=2	
						setvariable/z numpnts_tab1 win=sicscmdpanel,disable=2
						setvariable/z range_tab1 win=sicscmdpanel,disable=2
						checkbox/z save_tab1 win=sicscmdpanel,disable=2	
					endif
					Dowindow/k fpxScan
					break
				case "Stop_tab1":
					Doalert 1, "are you sure you want to stop the scan?"
					if(V_flag==1)
						fpxStop()
					else
						return 0
				endif
				break
			case "Pause_tab1":
				switch(fpxstatus())
					case 2:
						pausefpx(0)
						Button/z Pause_tab1,win=sicscmdpanel,title="Pause"
						//if the tertiary shutter is closed, it might be a good idea to open it.
						if(stringmatch(gethipaval("/instrument/status/tertiary"), "*Closed*"))
							doalert 1, "WARNING, tertiary Shutter appears to be closed, you may not see any neutrons, do you want to continue?"
							if(V_Flag==2)
								abort
							endif
						endif						
						break
					case 1:
						pausefpx(1)
						Button/z Pause_tab1,win=sicscmdpanel, title="Restart"
						break
				endswitch
				break
			case "runbatch_tab3":
					//see if you're doing a batch scan
					if(batchScanStatus())
						print "you are already doing a batch scan, please stop that first"
						return 0
					endif
					//see if you're doing a batch scan
					if(fpxStatus())
						print "you are already doing an fpx scan, please stop that first"
						return 0
					endif
					Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
					if(!batchScan(batchfile))
						Button/z runbatch_tab3 win=sicscmdpanel,disable=1	//if the scan starts disable the go button
						Button/z stopbatch_tab3 win=sicscmdpanel,disable=0		//if the scan starts enable the stop button
						Button/z pausebatch_tab3 win=sicscmdpanel,disable=0		//if the scan starts enable the pause button
						Button/z loadbatch_tab3 win=sicscmdpanel,disable=1		//if the scan starts disable the load batch button
						
					endif
					break
				case "stopbatch_tab3":
					Doalert 1, "are you sure you want to stop the batchscan?"
					if(V_Flag==1)
						batchScanStop()
						print "Stopping batch"
					else
						return 0					
					endif
					break
				case "pausebatch_tab3":
					switch(batchScanStatus())
						case 1:
							batchScanPause(1)
							Button/z Pausebatch_tab3,win=sicscmdpanel,title="Restart"						
							break
						case 2:
							batchScanPause(0)
							Button/z Pausebatch_tab3,win=sicscmdpanel,title="Pause"
							break
					endswitch
					break
				case "loadbatch_tab3":
					Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
					LoadWave/q/J/K=0/V={"\t"," $",0,0}/N=qwertyfiable/L={0,0,0,0,1}		
					if(V_flag)
						Wave/t qwertyfiable0
						batchfile[][1] = selectstring(p > dimsize(qwertyfiable0,0)-1, qwertyfiable0[p], "")
						batchfile[][3]=""
						batchfile[][4]=""
						killwaves/z qwertyfiable0
					endif
					break
				case "checkbatch_tab3":
					Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
					Pla_batchChecker#Pla_checkBatchFile(batchfile)
					break
				case "savebatch_tab3":
					Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
					duplicate/o/t batchfile,qwertyfied
					deletepoints/m=1 0, 1, qwertyfied
					redimension/n=(-1,0) qwertyfied
					Save/G qwertyfied as "batchbuffer.txt"
					killwaves/z qwertyfied
					break
				case "clearbatch_tab3":
					Doalert 1, "Are you sure you want to clear the batch file?"
					if(V_flag == 1) 
						Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
						Wave sel_batchfile = root:packages:platypus:data:batchScan:sel_batchbuffer
						batchfile[][1] = ""
						batchfile[][3] = ""
						batchfile[][4] = ""
						sel_batchfile[][2] = 2^5
					endif
					break
				case "selectAllBatch_tab3":
					Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
					Wave sel_batchfile = root:packages:platypus:data:batchScan:sel_batchbuffer
					sel_batchfile[][2] = 2^5+2^4
					break
				case "deselectAllBatch_tab3":
					Wave/t batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
					Wave sel_batchfile = root:packages:platypus:data:batchScan:sel_batchbuffer				
					sel_batchfile[][2] = 2^5
					break
				case "positions_tab3":
					positions_panel()
					break
				case "anglers_tab3":
					anglers_panel()
					break
			endswitch		
			break
	endswitch

	return 0
End

Function RebuildBatchListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: //mouse down
			if(lba.eventmod & 2^4)
				popupcontextualmenu "acquire;omega_2theta;run;rel;vslits;samplename;igor;wait;attenuate;sics;setexperimentalmode;positioner;angler;txtme;tempbath"
				listwave[row][col] = createFizzyCommand(S_Selection)
			endif
			break
		case 2:
			variable ii
			listwave[row][2] = ""
			if(selwave[row][2] & 2^4)
				listwave[row][2] = ""
			endif
			break
		case 3: // double click
			break
		case 4: // cell selection
			break
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit

			break
	endswitch

	return 0
End


Function startSICS()
	//see if FIZZY is already running
	NVAR/z SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	if(NVAR_Exists(SOCK_interest) && Sockitisitopen(SOCK_interest))
		doalert 1, "FIZZY is already running, do you want to restart?"
		if(V_Flag == 2)
			return 0
		endif
	endif
	//don't want bounds checking on arrays!
	Execute "SetIgorOption DimensionChecking=0xF"
	
	Newpath/o/q Homepath,Home
	PauseUpdate; Silent 1		// building window...
	
	//close all the open TCP sockets
	sockitcloseconnection(-1)
	
	string cDF = getdatafolder(1)
	
	//set up the datafolders
	Setupdatafolders()
	//and now setup places for the global variables
	setUpGlobalVariables()
	
	variable err=0
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync

	make/o/t/n=(1,2)/o root:packages:platypus:SICS:cmd_buffer
	make/o/t/n=(1,2)/o root:packages:platypus:SICS:interest_buffer
	make/o/t/n=(1,2)/o root:packages:platypus:SICS:sync_buffer
	
	make/o/t/n=(0) root:packages:platypus:SICS:statemon
	
	Wave/t cmd_buffer = root:packages:platypus:SICS:cmd_buffer
	Wave/t interest_buffer = root:packages:platypus:SICS:interest_buffer
	Wave/t sync_buffer = root:packages:platypus:SICS:interest_buffer
	
	string sicsuser="",sicspassword=""
	prompt sicsuser, "SICS user name", popup, "manager;user;spy"
	prompt sicspassword, "password"
	DoPrompt "SICS login", sicsuser,sicspassword
	if(V_flag)
		abort
	endif
	
	//socket for sending vanilla sics commands from user
	string LOGFILE = specialdirpath("Desktop", 1, 1, 0) + "SICSlog.txt"
	sockitopenconnection/TIME=2/Q/TOK="\n" SOCK_cmd,ICSserverIP,ICSserverPort,cmd_buffer
//	sockitopenconnection/TIME=2/Q/TOK="\n"/LOG=LOGFILE SOCK_cmd,ICSserverIP,ICSserverPort,cmd_buffer

	if(V_flag)
		abort "Could'nt open a connection to SICS"
	endif
	sockitsendnrecv/TIME=3/SMAL SOCK_cmd,sicsuser + " "+sicspassword+"\n" 
	sockitregisterprocessor(SOCK_cmd,"Ind_process#cmdProcessor")

	//socket for sending interupt, i.e. stop messages from user
	sockitopenconnection/Q/TIME=2/TOK="\n" SOCK_interupt, ICSserverIP,ICSserverPort, cmd_buffer
	if(V_flag)
		abort "Could'nt open a connection to SICS"
	endif
	sockitsendnrecv/time=3/SMAL SOCK_interupt, sicsuser + " "+sicspassword+"\n"
	
	//socket for receiving status messages and for sending messages you don't want to appear in the command buffer
	sockitopenconnection/Q/TIME=2/TOK="\n" SOCK_interest, ICSserverIP, ICSserverPort, interest_buffer
//	sockitopenconnection/Q/TIME=2/TOK="\n"/LOG=LOGFILE SOCK_interest, ICSserverIP, ICSserverPort, interest_buffer
	if(V_flag)
		abort "Could'nt open a connection to SICS"
	endif
	sockitsendnrecv/time=3/SMAL SOCK_interest, sicsuser + " "+sicspassword+"\n"
	sockitsendnrecv/time=1/SMAL SOCK_interest, "\n"
	
	//socket for synchronous queries
	sockitopenconnection/Q/TIME=2/TOK="\n" SOCK_sync, ICSserverIP, ICSserverPort, sync_buffer
//	sockitopenconnection/Q/TIME=2/TOK="\n"/LOG=LOGFILE SOCK_sync, ICSserverIP, ICSserverPort, sync_buffer
	if(V_flag)
		abort "Could'nt open a connection to SICS"
	endif
	sockitsendnrecv/time=3/SMAL SOCK_sync, sicsuser + " "+sicspassword+"\n"
	sockitsendnrecv/time=2/SMAL SOCK_interest, "\n"
	print V_Flag, S_tcp
	
	if(SOCK_cmd < 0 || SOCK_interupt < 0 || SOCK_interest <0 || SOCK_sync <0)
		sicsclose()
		setdatafolder $cDF
		ABORT "Couldn't open all connections to SICS (SICScmd)"
	endif
	
	Setdatafolder root:packages:platypus:SICS

	sleep/t 40
	DoXOPIDLE
	//get the SICS hipadaba paths as a full list
	string pathToHipaDaba = SpecialDirPath("Temporary", 0, 0, 0)
	print "LOADING HIPADABA PATHS"
	sockitsendnrecv/FILE=pathtoHipaDaba+"hipadaba.xml"/TIME=3 SOCK_interest, "getGumtreeXml / \n"
	if(enumerateHipadabapaths(pathtoHipaDaba+"hipadaba.xml"))
		print "Error while enumerating hipadaba paths (startSICS)"
		sicsclose()
		return 1
	endif
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
	
	DoXOPIdle
	//setup experimental details
	experimentDetailsWizard()

	//ok, now get current list of SICS axis positions, then register the interestProcessor on the socket.
	//this function creates root:packages:platypus:SICS:axeslist
	err = createAxisListAndPopulate(SOCK_interest)
	setdatafolder $cDF
	if(err)
		Abort "Couldn't get full list of current motor positions for some reason (SICScmd)"
	endif


	//register a processor for everything coming back on the interest sockit.  THis sockit is used
	//for collecting information on when anything on the instrument hipadaba paths changes.	
	//The "hnotify" command is instrument specific and is issued from Instrument_specific_setup()
	sockitregisterprocessor(sock_interest,"Ind_process#interestProcessor")
	
	//register an interest in the status
	sockitsendmsg sock_interest,"status interest\n"
	if(V_Flag)
		Abort "Couldn't register status interest on interest channel (SICScmd)"
	endif
	
	//register an interest in the statemon (tells when things have started driving, and when they finish)
	sockitsendmsg sock_interest,"statemon interest\n"
	if(V_Flag)
		Abort "Couldn't register statemon interest on interest channel (SICScmd)"
	endif

	//get the current status
	sockitsendmsg sock_interest,"status\n"

	//this is instrument dependent!!!! Only call this function on your own instrument.
	err = Instrument_Specific_Setup()
	if(err)
		abort "problem with instrument specific setup (SICScmd)"
	endif

	//create a layout graph of all the motors
	Instrumentlayout_panel()
	
	//get all the values in the hipadaba tree
	getCurrentHipaVals()
	getCurrentHipaVals()
	
	//Waves for the current axes positions
	//the set of positions has already been completed.
	//here we make a colour wave and the listbox selection wave
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	make/n=(dimsize(axeslist,0),dimsize(axeslist,1), 2)/o root:packages:platypus:sics:selAxesList = 0
	make/w/u/o root:packages:platypus:sics:cwAxes = {{0,65535}, {0,0}, {0,0}}
	Wave selaxeslist = root:packages:platypus:sics:selAxesList
	Wave cwAxes = root:packages:platypus:sics:cwAxes
	//only make col2 editable
	selaxeslist[][2][0] = 2
	//define plane 1 of the selection wave as background colours
	SetDimLabel 2,1,backColors,selaxeslist
	

	make/n=(600, 5)/t/o root:packages:platypus:data:batchScan:list_batchbuffer = ""	
	make/n=(600, 5)/o root:packages:platypus:data:batchScan:sel_batchbuffer
	Wave sel_batchbuffer = root:packages:platypus:data:batchScan:sel_batchbuffer
	wave/t list_batchbuffer = root:packages:platypus:data:batchScan:list_batchbuffer
	setdimlabel 1, 1, command,list_batchbuffer
	setdimlabel 1, 2, 'run?',list_batchbuffer
	setdimlabel 1, 3, 'status', list_batchbuffer
	setdimlabel 1, 4, 'filename', list_batchbuffer
	
	list_batchbuffer[][0] = num2istr(p)
	sel_batchbuffer[][1] = 0
	sel_batchbuffer[][1] = 2^1
	sel_batchbuffer[][2] = 2^5
	sel_batchbuffer[][3] = 0
	sel_batchbuffer[][4] = 0
	
	//panel for the SICS command window
	if(itemsinlist(winlist("SICScmdpanel",";",""))==0)
		NewPanel /W=(48,46,767,785)/k=1 as "FIZZY instrument control (C) A. Nelson + ANSTO"
		DoWindow/C SICScmdPanel

		DefineGuide UGV0={FL,0.52,FR},UGH0={FT,0.12,FB},UGH1={FT,0.6,FB},UGV1={FL,0.03,FR}
		DefineGuide UGV2={FL,0.97,FR},UGH2={FT,248},UGH3={FT,0.962264,FB}
			
		TabControl sicstab proc=sics_tabcontrol,pos={11,2},size={695,729}
		TabControl sicstab value=0,tabLabel(0)="SICS Console + Axis Positions",tabLabel(1)="Runscan",tabLabel(2)="Current Detector",tabLabel(3)="Batch Scan"

		Button SICSclose_tab0,pos={184,674},size={137,28},proc=button_SICScmdpanel,title="close"
		Button Estop_tab0,pos={39,674},size={137,28},proc=button_SICScmdpanel,title="E-STOP"
		Button Estop_tab0,labelBack=(65535,65535,65535),fColor=(65535,16385,16385)
		
		
		TitleBox SICSterminal_tab0 title="                                     SICS terminal                                               ", pos={33,31}
		TitleBox SICSterminal_tab0 frame=5, labelBack=(65280,48896,55552), pos={33,31}
		NewNotebook /F=1 /N=NB0 /W=(179,55,390,670)/FG=(UGV1,,UGV0,) /HOST=#
		RenameWindow #,NB0_tab0
		SetActiveSubwindow ##
		Notebook SICScmdPanel#NB0_tab0, text="Enter your SICS commands here\r"
		Notebook SICScmdPanel#NB0_tab0, defaultTab=20, statusWidth=0, autoSave=1,showRuler=0, rulerUnits=1
	
		ListBox currentAxisPos_tab0,pos={388,31},size={300,687},proc=moveAxisListBoxProc
		ListBox currentAxisPos_tab0,mode= 2,selRow= 0,editStyle= 1,widths={2,0,2,0,2,0,2}, fsize=14
		ListBox currentAxisPos_tab0 listwave=:packages:platypus:SICS:axeslist
		ListBox currentAxisPos_tab0,userColumnResize= 0,selwave = root:packages:platypus:sics:selAxesList,mode = 2, colorWave=root:packages:platypus:SICS:cwAxes
		//		SetVariable histostatus_tab1,pos={62,146},size={402,16},title="histostatus"
		//		SetVariable histostatus_tab1,fSize=10
		//		SetVariable histostatus_tab1,limits={-inf,inf,0},value= root:packages:platypus:SICS:histostatusStr,bodyWidth= 350
		SetVariable sicsstatus_tab0,pos={40,705},size={286,20},title="SICS status"
		SetVariable sicsstatus_tab0,fSize=14,disable=2
		SetVariable sicsstatus_tab0,limits={-inf,inf,0},value= root:packages:platypus:SICS:sicsstatus,bodyWidth= 237

		PopupMenu motor_tab1,pos={70,40},size={136,21},proc=motor_tab1menuproc,title="Motor Name"
		PopupMenu motor_tab1,fSize=10,mode=1,popvalue="_none_",value= #"motorlist()"
		SetVariable range_tab1,pos={54,80},size={107,16},title="range",fSize=10
		SetVariable range_tab1,limits={0,1000,0.1},value= root:packages:platypus:SICS:range
		SetVariable numpnts_tab1,pos={171,80},size={121,16},title="num points",fSize=10
		SetVariable numpnts_tab1,limits={1,inf,1},value= root:packages:platypus:SICS:numpoints
		CheckBox save_tab1,pos={315,89},size={47,26},title="don/t\rsave?",value= 0
		PopupMenu presettype_tab1,pos={51,103},size={110,21},bodyWidth=85,title="type"
		PopupMenu presettype_tab1,fSize=10
		PopupMenu presettype_tab1,mode=1,popvalue="TIME",value= #"\"time;MONITOR_1;count;unlimited;frame\""
		Button Go_tab1,pos={462,39},size={101,101},proc=button_SICScmdpanel,title=""
		Button Go_tab1,picture= procglobal#go_pict
		Button Stop_tab1,pos={462,39},size={101,101},disable=1,proc=button_SICScmdpanel,title=""
		Button Stop_tab1,picture= procglobal#stop_pict
		Button Pause_tab1,pos={566,39},size={103,103},disable=1,proc=button_SICScmdpanel,title=""
		Button Pause_tab1,picture= procglobal#pause_pict
		PopupMenu counttypeVSpos_tab1,pos={183,216},size={272,21},bodyWidth=200,title="count variable",proc=counttypeVSpos_popupcontrol
		PopupMenu counttypeVSpos_tab1,mode=4,popvalue="DetectorCounts",value= #"\"DetectorCounts;AvgCountRate;Det/BM1;Det/BM2;BM2_counts;BM2_rate;BM1_counts;BM1_rate\""
		SetVariable currentpos_tab1,pos={235,42},size={100,16},disable=2,title=" "
		SetVariable currentpos_tab1,limits={-inf,inf,0},value=root:packages:platypus:SICS:axeslist
		SetVariable preset_tab1,pos={170,106},size={123,16},title="preset",fSize=10
		SetVariable preset_tab1,limits={1,inf,1},value= root:packages:platypus:SICS:preset
		ValDisplay progress_tab1,pos={26,144},size={414,14},bodyWidth=342,title="Scan progress"
		ValDisplay progress_tab1,fSize=10,frame=2,limits={0,1,0},barmisc={0,40}
		ValDisplay progress_tab1,value= #"root:packages:platypus:data:scan:pointProgress"
		SetVariable sampletitle_tab1,pos={40,165},size={400,16},bodyWidth=342,title="Sample title"
		SetVariable sampletitle_tab1,fSize=10
		SetVariable sampletitle_tab1,value= root:packages:platypus:SICS:sampleStr
		
		SetVariable filename_tab1,pos={43,187},size={397,16},bodyWidth=342,title="Run Name"
		SetVariable filename_tab1,fSize=10
		SetVariable filename_tab1,value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/experiment/file_name")][1],noedit= 1
	
		Display/W=(33,254,679,711)/FG=(UGV1,UGH2,UGV2,UGH3)/HOST=# 
		RenameWindow #,G0_tab1
		SetActiveSubwindow ##
	
		Button UpdateHMM_tab2,pos={215,31},size={130,40},proc=button_SICScmdpanel,title="Update Detector"
		PopupMenu displayorder_tab2,title="     displayorder",fSize=10,pos={26,41}
		PopupMenu displayorder_tab2,mode=1,value= #"displayorderlist()",proc = popup_changedisplayorder,bodywidth=120
		SetVariable integratedCounts_tab2 title="Integrated Counts",size={200,20},disable=2,pos = {351,43}
		SetVariable integratedCounts_tab2 value=:packages:platypus:data:RAW:integratedCounts
		SetVariable integratedCounts_tab2 limits={-inf,inf,0},fSize=10,disable=2
		Button popgraph_tab2 pos={566,31}
		Button popgraph_tab2 fSize=12,proc=spawngraph
		Button popgraph_tab2 title="spawn graph",size={100,40}
		Checkbox log2Dgraph_tab2 title="log10",pos={364,72},proc=checkbox_sicscmdpanel
		Checkbox autoupdate_tab2 title="auto update",pos={232,72},proc=checkbox_sicscmdpanel
	
		display/W=(21,85,679,476)/FG=(UGV1,UGH0,UGV2,UGH1)/HOST=# 
		RenameWindow #,G0_tab2
		SetActiveSubwindow ##
		Display/W=(21,495,344,725)/FG=(UGV1,UGH1,UGV0,UGH3)/HOST=# 
		RenameWindow #,G1_tab2
		SetActiveSubwindow ##
		Display/W=(368,497,679,724)/FG=(UGV0,UGH1,UGV2,UGH3)/HOST=#
		RenameWindow #,G2_tab2
		SetActiveSubwindow ##
		
		ListBox buffer_tab3,pos={54,45},size={442,637}
		ListBox buffer_tab3,listWave=root:packages:platypus:data:batchScan:list_batchbuffer
		ListBox buffer_tab3,selWave=root:packages:platypus:data:batchScan:sel_batchbuffer
		ListBox buffer_tab3,row= 1,mode= 7,editStyle= 2,widths={10,90,13,24,34}, fsize=14
		ListBox buffer_tab3,userColumnResize= 0,proc=RebuildBatchListBoxProc
		Button runbatch_tab3,pos={510,53},size={101,101},title=""
		Button runbatch_tab3,picture= ProcGlobal#go_pict, proc=button_SICScmdpanel
		Button stopbatch_tab3,pos={511,53},size={101,101},title="",disable=1
		Button stopbatch_tab3,picture= ProcGlobal#stop_pict, proc=button_SICScmdpanel
		Button pausebatch_tab3,pos={510,156},size={103,103},title="",disable=1
		Button pausebatch_tab3,picture= ProcGlobal#pause_pict, proc=button_SICScmdpanel
		Button loadbatch_tab3,pos={514,344},size={100,30},title="Load Batch File",proc=button_SICScmdpanel
		Button savebatch_tab3,pos={514,375},size={100,30},title="Save Batch File",proc=button_SICScmdpanel
		Button checkbatch_tab3,pos={514,415},size={100,30},title="Check Batch File",proc=button_SICScmdpanel
		Button clearbatch_tab3,pos={514,455},size={100,30},title="Clear Batch File",proc=button_SICScmdpanel
		Button selectAllBatch_tab3,pos={514,495},size={100,30},title="Select all",proc=button_SICScmdpanel
		Button deselectAllBatch_tab3,pos={514,535},size={100,30},title="Deselect all",proc=button_SICScmdpanel
		Button positions_tab3 title="Defined positions",pos={514,577}, size={100,30},proc=button_SICScmdpanel
		Button anglers_tab3 title="Defined angles",pos={514,619}, size={100,30},proc=button_SICScmdpanel
				
		setwindow sicscmdpanel hook(winhook)=sicscmdpanelwinhook 
		//		Modifypanel/W=SICScmdpanel noedit=1
	endif
	struct WMTabControlAction tca
	tca.eventcode=2
	tca.tab=0
	sics_tabcontrol(tca)
	
	//start the regular background task list going
	//lets do it every 3 minutes.
	startRegularTasks(180)
End

Function enumerateHipadabapaths(filepath)
	string filepath
	//this function opens and parses an XML file that contains the hipadaba description of the instrument	
	variable fileID=0, retval
	variable ii, jj
	string currentPath, searchstring,outputString

	try
		fileID = XMLopenfile(filepath)
		if(fileID<1)
			print "ERROR while enumerating hipadaba paths (enumerateHipadabapaths)"
			abort
		endif

		xmllistxpath(fileid,"//component/@id","")
		Wave/t M_listXpath
		M_listXPath[][0] = replacestring("hipadaba:SICS", M_listXPath[p][0],"*")
	 
		make/o/n=(dimsize(M_listxpath,0),2)/t hipadaba_paths
		hipadaba_paths[][0] = xmlstrfmxpath(fileID, M_listXPath[p][0],"","")
	
		M_listXPath[][0] = replacestring("/*", M_listXPath[p][0],"")
		M_listXPath[][0] = replacestring("/@id", M_listXPath[p][0],"")
		hipadaba_paths[][0] = replacestring(" ", hipadaba_paths[p][0],"")
	
		for(ii=0 ; ii<dimsize(hipadaba_paths,0); ii+=1)
			currentPath = M_listXPath[ii][0]
			searchstring = ""
			outputString = ""
			for(jj=1 ; jj<itemsinlist(currentPath, "/") ; jj+=1)
				searchstring += "/" + stringfromlist(jj, currentPath, "/")

				findvalue/TEXT=searchstring/TXOP=4/z M_listxpath
				outputString += "/" + hipadaba_paths[v_value][0]
			endfor
			hipadaba_paths[ii][1] = outputString
		endfor

		hipadaba_paths[][0] = hipadaba_paths[p][1]
		hipadaba_paths[][1] = ""
	catch
		retval=1
	endtry

	//now remove the nodes that aren't leaves.
	removeBranchNodes(hipadaba_paths)

	if(fileID>1)
		xmlclosefile(fileID,0)
	endif
	
	killwaves/z M_listxpath
	return retval
End

Function removeBranchNodes(txtWav)
wave/t txtWav
//this function removes non-leaf nodes from a text wave that contains entries like:
// /a			GETS REMOVED
// /a/b			GETS REMOVED
// a/b/c/		STAYS
variable ii
for(ii=0 ; ii<dimsize(txtWav,0) ; ii+=1)
	grep/e=txtWav[ii]/gcol=0/indx/q txtWav
	Wave W_index
	if(dimsize(W_index,0)>1)
		deletepoints ii, 1, txtWav
		ii-=1
	endif
endfor
killwaves/Z W_index
End

function parseReply(msg,lhs,rhs)
	string msg
	string &lhs,&rhs
	lhs = ""
	rhs = ""
	msg=replacestring(" = ",msg, "=")
      msg = removeending(msg, "\n")
	variable items = itemsinlist(msg,"=")
	if(items==2)
		lhs = stringfromlist(0,msg, "=")
		rhs = stringfromlist(1,msg, "=")
	endif
	return items
end

Function getHipaPos(path)
	string path
	//returns the row number of the hipadaba path in the
	//textwave that contains all the child hipadaba nodes.
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
	
	findvalue/text=path/txop=4/z hipadaba_paths
	return v_value
ENd

Function/t getHipaVal(path)
	string path
	//looks up the value of a specific hipadaba node in the enumerated list.
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths

	findvalue/text=path/txop=4/z hipadaba_paths
	if(V_Value == -1)
		return ""
	else
		return hipadaba_paths[V_Value][1]
	endif
ENd

Function sicsCmdPanelWinHook(s)		//window hook for events happening in the SICScmdpanel
	STRUCT WMWinHookStruct &s
	//shutsdown the connection to sics when FIZZY GUI is closed.
	//has a hook to the notebook window in FIZZY that acts as a SICS terminal
	Variable statusCode = 0
 	
	switch(s.eventCode)
		case 2:		//trying to kill the window
			sicsclose()
			return 1
			break
	endswitch
	
	//hook for the notebook window
	strswitch(s.winname)
		case "SICScmdpanel#NB0_tab0":
			String platform= UpperStr(igorinfo(2))
			string cmdChar, temp
			if(stringmatch(platform,"MACINTOSH"))
				cmdChar = num2char(-91)
			else
				cmdChar = num2char(-107)	
			endif
			
			switch(s.eventCode)
				case 11: // Keyboard
					switch (s.keycode)
						case 30:		//down
							notebook $s.winname, findtext={cmdChar, 2^4+2^0}
							notebook $s.winname, selection={startOfParagraph, endOfParagraph}
							statuscode=1
							break
						case 31:		//up 
							notebook $s.winname, findtext={cmdChar, 2^0}
							notebook $s.winname, selection={startOfParagraph, endOfParagraph}
							statuscode=1
							break
						case 13:		//return
							notebook $s.winname, selection={startOfParagraph, endOfParagraph}
							notebook $s.winname, textRGB=(0, 0,  65535), fstyle=1, fsize=12
							getselection notebook, $s.winname, 3
							string cmdStr = S_Selection
							variable parastart = V_startparagraph, paraend = V_endparagraph
							variable endpos=V_endpos, startpos=V_startpos
							
							//figure out if its the last command in the terminal window
							Notebook SICScmdpanel#NB0_tab0 selection={startOfFile, endOfFile}	
							getselection notebook, $s.winname, 1
							if(V_endparagraph != paraend)	//it's not the last command, so copy the selection into the last line
								//remove trailing carriage return
								cmdStr = removeending(cmdStr, "\r")
								Notebook SICScmdpanel#NB0_tab0 selection={endOfFile, endOfFile}, text = cmdStr
								notebook $s.winname, selection={startOfParagraph, endOfParagraph}
								notebook $s.winname, textRGB=(0, 0,  65535), fstyle=1, fsize=12
								return 1
							endif
							
							Notebook SICScmdpanel#NB0_tab0 selection = {(parastart, startpos), (paraend, endpos)}
							
							if(strlen(S_Selection) > 0 && (!stringmatch(S_Selection, "\r")) )
								temp = ""
								notebook $s.winname, selection={startofparagraph, endofparagraph}
								if(!Stringmatch(S_Selection[0], cmdchar))
									temp = cmdChar
								endif
								temp += S_Selection
								if(!Stringmatch(S_Selection[strlen(S_Selection)-1],"\r"))
									temp +="\r"
								endif
								notebook $s.winname, text = temp
							endif
							//SICS can't cope with the IGOR command character, so remove it.
							cmdStr = replacestring(cmdChar, cmdStr, "")
							//now execute the command on the command channel
							sics_cmd_cmd(cmdStr)
							
							//							if(strlen(S_Selection)>0)
							//								notebookaction/w=$s.winname commands=S_Selection, frame=1,ignoreerrors=1, title=S_Selection 
							//							endif
							notebook $s.winname, selection={endofparagraph,startofnextparagraph}
							notebook $s.winname, textRGB=(0, 0, 0)
							statuscode=1
							break
					endswitch
			endswitch
			break
	endswitch

	return statuscode
End

Function motor_tab1menuproc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa	//this function controls what happens when the motor is changed on tab1

	switch( pa.eventCode )
		case 2: // mouse up
			Wave/t axeslist = root:packages:platypus:SICS:axeslist
			Variable popNum = pa.popNum,col,row
			String popStr = pa.popStr
		
			Findvalue/Text=popstr axeslist
			if(V_Value !=-1)
				col = floor(V_Value/dimsize(axeslist,0))
				row = V_Value-col*dimsize(axeslist,0)
				setvariable/z currentpos_tab1, win=sicscmdpanel, value = axeslist[row][2]
			endif
			break
	endswitch

	return 0
End

Function counttypeVSpos_popupcontrol(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	//for changing the display type in the fpx scan window.
	//options are DetectorCounts;AvgCountRate;Det/BM1;Det/BM2;BM2_counts;BM2_rate;BM1_counts;BM1_rate

	Wave/z position = root:packages:platypus:data:scan:position
	Wave/z counts = root:packages:platypus:data:scan:counts

	if(!waveexists(position) || !waveexists(counts))
		return 0
	endif
	
	//first remove all traces from graph
	removealltraces("SICScmdpanel#g0_tab1",1)
	
	variable waveChoice = NaN, errWave = NaN
	strswitch(PU_Struct.popstr)
		case "DetectorCounts":
			waveChoice = 0
			errWave = 1
		break
		case "AvgCountRate":
			waveChoice = 2
		break
		case "Det/BM1":
			waveChoice = 12
			errWave = 13
		break
		case "Det/BM2":
			waveChoice = 10
			errWave = 11
		break
		case "BM2_counts":
			waveChoice = 4
			errWave = 5
		break
		case "BM2_rate":
			waveChoice = 6
		break
		case "BM1_counts":
			waveChoice = 7
			errWave = 8
		break
		case "BM1_rate":
			waveChoice = 9
		break
	endswitch

	appendtograph/w=SICScmdpanel#G0_tab1 counts[][waveChoice] vs position
	if(!numtype(errWave))
		ErrorBars/w=SICScmdpanel#g0_tab1 counts Y,wave=(counts[*][errWave],counts[*][errWave])
	endif
	ModifyGraph/z/w=SICScmdpanel#g0_tab1 mode(counts)=4
	
	return 0
ENd

Function sics_tabcontrol(tca) : TabControl
	STRUCT WMTabControlAction &tca	//this function runs when the main gui tabs are changed.

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			ModifyControlList ControlNameList("SICScmdPanel",";","*_tab0") disable=(tab!=0)
			ModifyControlList ControlNameList("SICScmdPanel",";","*_tab1") disable=(tab!=1)
			setwindow sicscmdpanel#G0_tab1 hide=(tab!=1)
			ModifyControlList ControlNameList("SICScmdPanel",";","*_tab2") disable=(tab!=2)
			ModifyControlList ControlNameList("SICScmdPanel",";","*_tab3") disable=(tab!=3)
			setwindow sicscmdpanel#NB0_tab0 hide=(tab!=0)
			setwindow sicscmdpanel#G0_tab2 hide=(tab!=2)
			setwindow sicscmdpanel#G1_tab2 hide=(tab!=2)
			setwindow sicscmdpanel#G2_tab2 hide=(tab!=2)
			
			CtrlNamedBackground  scanTask status
			if(tab==0)
				setvariable sicsstatus_tab0,win=sicscmdpanel, disable=2
			endif
			if(tab==1)
				setvariable/z currentpos_tab1, win=sicscmdpanel,disable=2
				if(numberbykey("RUN",S_info))	//if the scan is running we need to have the right buttons
					Button Stop_tab1,win=sicscmdpanel,disable=0
					Button Pause_tab1,win=sicscmdpanel,disable=0
					Button Go_tab1,win=sicscmdpanel,disable=1
					setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=2		//if the scan starts disable the title button
					setvariable/z preset_tab1 win=sicscmdpanel,disable=2
					PopupMenu/z presettype_tab1 win=sicscmdpanel,disable=2	
					PopupMenu/z motor_tab1 win=sicscmdpanel,disable=2
					setvariable/z numpnts_tab1 win=sicscmdpanel,disable=2
					setvariable/z range_tab1 win=sicscmdpanel,disable=2	
					checkbox/z save_tab1 win=sicscmdpanel,disable=2										
				else
					Button Stop_tab1,win=sicscmdpanel,disable=1
					Button Pause_tab1,win=sicscmdpanel,disable=1
					Button Go_tab1,win=sicscmdpanel,disable=0
					setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=0		//if the scan starts disable the title button
					setvariable/z preset_tab1 win=sicscmdpanel,disable=0
					PopupMenu/z presettype_tab1 win=sicscmdpanel,disable=0
					PopupMenu/z motor_tab1 win=sicscmdpanel,disable=0	
					setvariable/z numpnts_tab1 win=sicscmdpanel,disable=0
					setvariable/z range_tab1 win=sicscmdpanel,disable=0
					checkbox/z save_tab1 win=sicscmdpanel,disable=0
				endif
			endif
			if(tab==2)
				setvariable/z	integratedCounts_tab2,disable=2,win=sicscmdpanel
			endif
			Ctrlnamedbackground batchScan, status				
			if(tab==3)
				if(numberbykey("RUN",S_info))	//if the scan is running we need to have the right buttons
					Button runbatch_tab3,disable=1,win=sicscmdpanel
					Button stopbatch_tab3,disable=0,win=sicscmdpanel
					Button pausebatch_tab3,disable=0,win=sicscmdpanel
					Button/z loadbatch_tab3 win=sicscmdpanel,disable=1
					
				else
					Button runbatch_tab3,disable=0,win=sicscmdpanel
					Button stopbatch_tab3,disable=1,win=sicscmdpanel
					Button pausebatch_tab3,disable=1,win=sicscmdpanel
					Button/z loadbatch_tab3 win=sicscmdpanel,disable=0	
				endif
			endif					
			break
	endswitch

	return 0
End

Function SICSclose()
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync

		
	batchScanStop()
	fpxStop()
	stopwait()
	stopregulartasks()
	ctrlnamedbackground autoupdate_detector,stop,kill
	
	sockitsendmsg sock_cmd,"logoff\n"
	sockitsendmsg sock_interupt,"logoff\n"
	sockitsendmsg sock_interest,"logoff\n"
	sockitsendmsg sock_sync,"logoff\n"
	
	sockitcloseconnection(sock_cmd)
	sockitcloseconnection(sock_interupt)
	sockitcloseconnection(sock_interest)
	sockitcloseconnection(sock_sync)
	
	sock_cmd = -1
	sock_interupt=-1
	sock_interest=-1
	sock_sync=-1
		
	dowindow/k currentpositions
	dowindow/k sicscmdpanel
	dowindow/k spawngraphstats
	dowindow/k spawngraph0
	
	//An instrumental defined closedown
	Instrumentdefinedclose()
		
	setdatafolder root:
	//	killdatafolder root:packages:platypus
End

Function sendsicscmd(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			sockitsendmsg SOCK_CMD,"\n"
			sockitsendmsg SOCK_CMD,sval+"\n"
			notebook sicscmdpanel#NB0_tab0, selection = {endoffile,endoffile}, textRGB = (0,0,65280),fstyle=1
			notebook sicscmdpanel#NB0_tab0, text = sval + "\r"
			break
	endswitch

	return 0
End

Function createAxisListAndPopulate(sock)
	variable sock

	variable V_Flag = 0,err
	variable numitems = 0,ii,offset,number
	string output ="",cmd
	string str1,str2

	make/o/t/n=(0,0) axeslist
	
	//get list of motors
	SOCKITsendnrecv/Time=1 sock,"sicslist type motor\n"
	output = replacestring("\n",S_tcp,"")
	output = removeending(output," ")

	if(V_Flag)
		print "error while getting list of motors (createAxisListAndPopulate)"
		return 1
	endif
	//remove the forbidden motors
	for(ii=0;ii<itemsinlist(forbiddenmotors);ii+=1)
		output = removefromlist(stringfromlist(ii,forbiddenmotors),output," ")
	endfor
	
	numitems = itemsinlist(output," ")
	redimension/n=(numitems,-1) axeslist

	for(ii=0;ii<numitems; ii+=1)
		axeslist[ii] = stringfromlist(ii,output," ")
	endfor	
	
	//get list of configureable virtual motors
	SOCKITsendnrecv/Time=1 sock,"sicslist type configurablevirtualmotor\n"
	output = replacestring("\n",S_tcp,"")
	output = removeending(output," ")
	if(V_flag)
		return 1
	endif
	//remove the forbidden motors
	for(ii=0;ii<itemsinlist(forbiddenmotors);ii+=1)
		output = removefromlist(stringfromlist(ii,forbiddenmotors),output," ")
	endfor
		
	numitems = itemsinlist(output," ")
	offset = dimsize(axeslist,0)
	redimension/n=(offset+numitems) axeslist

	for(ii=0;ii<numitems; ii+=1)
		axeslist[ii+offset] = stringfromlist(ii,output," ")
	endfor

	//get hipadaba paths for each of the motors.
	sort/a axeslist,axeslist
	redimension/n=(-1,7) axeslist

	cmd = ""
	for(ii=0;ii<dimsize(axeslist,0);ii+=1)
		cmd+="sicslist "+axeslist[ii][0]+" hdb_path\n"
	endfor
	
	SOCKITsendnrecv/time =2 sock,cmd
	output = S_tcp
	if(V_flag)
		print "err"
		return 1
	endif
	for(ii=0;ii<itemsinlist(output,"\n");ii+=1)
		parseReply(stringfromlist(ii,output,"\n"),str1,str2)
		axeslist[ii][1] = str2
	endfor
		
	//now get posn of slits.
	cmd = ""
	for(ii=0;ii<dimsize(axeslist,0);ii+=1)
		cmd+=axeslist[ii][0]+"\n"
	endfor
	SOCKITsendnrecv/Time=1 sock,cmd
	output=S_tcp
	if(V_Flag)
		return 1
	endif
	for(ii=0;ii<itemsinlist(output,"\n");ii+=1)
		parseReply(stringfromlist(ii,output,"\n"),str1,str2)
		axeslist[ii][2] = num2str(str2num(str2))
		Ind_Process#updatelayout(axeslist[ii][0])
	endfor
			
	//now get softlower and softupper limits
	cmd=""
	for(ii=0;ii<dimsize(axeslist,0);ii+=1)
		cmd += axeslist[ii][0]+" softlowerlim\n"
		axeslist[ii][3] = axeslist[ii][1]+"/softlowerlim"
	endfor
	sockitsendnrecv/time=1 sock,cmd
	output = S_tcp
	if(V_Flag)
		print "err"
		return 1
	endif
	for(ii=0;ii<itemsinlist(output,"\n");ii+=1)
		parseReply(stringfromlist(ii,output,"\n"),str1,str2)
		axeslist[ii][4] = num2str(str2num(str2))
	endfor

	cmd=""
	for(ii=0;ii<dimsize(axeslist,0);ii+=1)
		cmd += axeslist[ii][0]+" softupperlim\n"
		axeslist[ii][5] = axeslist[ii][1]+"/softupperlim"
	endfor
	sockitsendnrecv/time=1 sock,cmd
	output = S_tcp
	if(V_Flag)
		print "err"
		return 1
	endif
	for(ii=0;ii<itemsinlist(output,"\n");ii+=1)
		parseReply(stringfromlist(ii,output,"\n"),str1,str2)
		axeslist[ii][6] = num2str(str2num(str2))
	endfor

	return err
End

Function moveAxisListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	//drive an axis to a specific position
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	//string for command and the socket to send it to.

	variable err = 0
	variable positionDesired,lowlim,upperlim
		
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
			string cmd,msg
			NVAR sock_cmd = root:packages:platypus:SICS:SOCK_cmd
			NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest

			if(col != 2)
				sockitsendmsg sock_interest,listwave[row][0]+"\n"
				return 0
			endif
			if(numtype(str2num(listwave[row][col])))
				doalert 0, "need to enter a number"
				listwave[row][col] = "NaN"
				//spoof to get the position correct
				sockitsendmsg sock_interest,listwave[row][0]+"\n"
				return 0
			endif
			
			positionDesired = str2num(listwave[row][col])
			//Now drive to the position
			run(listwave[row][0],positionDesired)
			
			//if it fails then spoof to get the position correct
			sockitsendmsg sock_interest,listwave[row][0]+"\n"
				
			Ind_process#updatelayout(listwave[row][0])
			break
	endswitch

	return 0
End

Function/t motorlist()
	string motors=""
	//create a list of motors that is suitable for scanning.
	Wave/t axeslist = root:packages:platypus:SICS:axeslist

	if(!waveexists(axeslist))
		return "_none_"
	endif
	variable ii
	
	for(ii=0;ii<dimsize(axeslist,0);ii+=1)
		motors = addlistitem(axeslist[ii][0],motors)
	endfor
	motors = addlistitem("_none_",motors)

	return motors
End


//this function displays the current detector pattern
Function getLatestData()
	NVAR	HDF_Current = root:packages:platypus:data:RAW:HDF_Current
	string req_file = ""
	string cDF = getdatafolder(1)
	
	svar dataAxes = root:packages:platypus:data:RAW:dataAxes
	dataAxes = ""
	
	string waves,choice,data,axes, axis_sizes
	string currentdisplayorder
	variable dim0,dim1,dim2,numdims,totalsize
	try
		setdatafolder	root:packages:platypus:data:RAW
		
		//put the current display order in a string, so if it's still a possibility at the end we don't change the gui
		controlinfo/w=sicscmdpanel displayorder_tab2
		currentdisplayorder = S_Value
	
		if(whichlistitem(currentdisplayorder,displayorderlist(),";")!=-1)
			choice = stringbykey(currentdisplayorder,DETECTOR_CHOICE,"=")
		else
			choice = "TOTAL_HISTOGRAM_XYT"
		endif
		
		//get the latest zipped, binary histogram data and place it into data)
		//axes is filled out with the names of the axes (y_bin;x_bin;time_bin)
		//axis_sizes is filled out with the axis sizes (221;421;1000)
		//this is much faster than getting a nexus file then loading it.
		if(grabdata(data, axes, axis_sizes, axesrequested=choice))
			print "Error loading data from Histogram Server (getlatestdata)"
			abort
		endif
	
		//fill out the SVAR that holds the ordering		
		dataAxes = axes
		//unzip the data (it's in .gz format)
		data = ZIPdecode(data)
		//convert the unzipped binary array into a wave
		//the first argument is the wavetype (see wavetype()), in this case signed INT32.
		//use /e if you expect the data to be big endian.
		sockitstringtowave 32,data
		wave W_stringtowave

		//work out how long the axes are for the loaded data.  This is obtained in the grabdata call above.
		dim0 = str2num(stringfromlist(0,axis_sizes))
		dim1 = str2num(stringfromlist(1,axis_sizes))
		dim2 = str2num(stringfromlist(2,axis_sizes))
		if(numtype(dim0))
			print "ERROR incoming data has no dimensions (getLatestData)"
			return 1
		elseif(numtype(dim1))
			numdims = 1
			totalsize = dim0
		elseif(numtype(dim2))
			numdims = 2
			totalsize = dim0 * dim1
		else
			numdims = 3
			totalsize = dim0 * dim1 *dim2
		endif
		if(totalsize != numpnts(W_stringtowave))
			print "ERROR unzipped wave isn't same size as the reported dimensions (getlatestdata)"
			return 1
		endif
		
		//now have to redimension the wave to get it in the right order
		switch(numdims)
			case 1:
				redimension/n=(dim0) W_stringtowave
				break
			case 2:
				redimension/n=(dim0,dim1) W_stringtowave
				break
			case 3:
				redimension/n=(dim0,dim1,dim2) W_stringtowave
				break
		endswitch

		duplicate/o W_stringtowave, hmm
		
		setdatafolder $cDF
	
		variable isLog=0
		controlinfo/w=SICScmdPanel log2Dgraph_tab2
		if(V_Flag==2 && V_Value==1)
			isLog=1
		endif
	
		string newdisplaypossibilities = displayorderlist()
		if(whichlistitem(currentdisplayorder,newdisplaypossibilities) != -1)//we can still display that kind of data
			reDisplay(currentdisplayorder,isLog)
		else
			reDisplay("",isLog)
		endif
	catch
		setdatafolder $cDF
		return 1
	endtry

	
	setdatafolder $cDF
	return 0
End

Function/t displayorderlist()
	string displayorder,possibleAxes
	svar dataAxes = root:packages:platypus:data:RAW:dataAxes
	
	possibleAxes = DETECTOR_AXES

	variable dims = itemsinlist(possibleAxes)
	string swap0,swap1,swap2,swap3,swap4,swap5

	switch (dims)
		case 1:
			displayorder = replacestring(";",possibleAxes,":")
			break
		case 2:
			displayorder = replacestring(";",possibleAxes,":")
			displayorder += ";"
			displayorder += stringfromlist(1,possibleAxes)
			displayorder += ":"
			displayorder += stringfromlist(0,possibleAxes)
			
			//add in 1d situations
			displayorder += stringfromlist(0,possibleAxes)
			displayorder += ";"
			displayorder += stringfromlist(1,possibleAxes)
			
			break
		case 3:
			swap0 =  stringfromlist(0,possibleAxes)+ ":"  + stringfromlist(1,possibleAxes)
			swap1 = stringfromlist(0,possibleAxes)+":"+ stringfromlist(2,possibleAxes)
			swap2 = stringfromlist(1,possibleAxes)+":"+ stringfromlist(2,possibleAxes)	
			swap3 = stringfromlist(1,possibleAxes)+":"+ stringfromlist(0,possibleAxes)
			swap4 = stringfromlist(2,possibleAxes)+":"+ stringfromlist(1,possibleAxes)
			swap5 = stringfromlist(2,possibleAxes)+":"+ stringfromlist(0,possibleAxes)
			displayorder = swap0+";"+swap1+";"+swap2+";"+swap3+";"+swap4+";"+swap5

			//add in 1d situations
			displayorder += ";"
			displayorder += stringfromlist(0,possibleAxes)
			displayorder += ";"
			displayorder += stringfromlist(1,possibleAxes)
			displayorder += ";"
			displayorder += stringfromlist(2,possibleAxes)

			break
	endswitch

	return displayorder
End

Function popup_changedisplayorder(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	variable dims = itemsinlist(pa.popstr,":")
	svar order = root:packages:platypus:data:RAW:displayed:order

	switch( pa.eventCode )
		case 2: // mouse up
			dowindow/k spawngraph0	//kill the spawned graph first
			dowindow/k spawngraphstats
			
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			order=replacestring(":",popstr,";")
			
			getLatestData()
			
		//	redisplay(popstr)
			break
	endswitch

	return 0
End


Function reDisplay(order,isLog)
	String order
	variable isLog
	//this function implicitly assumes that the data from the histoserver is histogrammed!!!!
	//the order string specifies how the live data is displayed on tab2 of the panel.  e.g.
	//e.g. the original data may be t;x;y
	//the user wants y;t.
	//therefore order="y;t"
	//the original ordering is given in the global string dataAxes.
	
	// 1D data is displayed as a graph
	// 2D data is displayed as an image (user defined order)
	// 3D data is first transposed (user defined order), then the useless dimension summed.

	string cDF = getdatafolder(1)
	setdatafolder  root:packages:platypus:data:RAW:displayed
	order = replacestring(":",order,";")
	
	Wave rawdetector = root:packages:platypus:data:RAW:hmm
	if(!waveexists(rawdetector))
		print "ERROR RAW detector data missing (redisplay)"
		setdatafolder $cDF
		return 1
	endif
	
	svar dataAxes = root:packages:platypus:data:RAW:dataAxes
	if(strlen(dataAxes)==0)
		setdatafolder $cDF
		print "ERROR missing data axis labels (redisplay)"
		return 1
	endif
	
	duplicate/o rawdetector, root:packages:platypus:data:RAW:displayed:hmm
	Wave hmm = root:packages:platypus:data:RAW:displayed:hmm
	
	nvar integratedcounts = root:packages:platypus:data:RAW:integratedCounts

	string temp,tempx,tempy,swap0,swap1,swap2,swap3,swap4,swap5

	variable dims = wavedims(rawdetector)
	variable offset,ii
		
	//as is the case if called from getlatestdata
	if(itemsinlist(order)==0)
		if(dims<3)
			order = dataaxes
		elseif(dims==3)
			order = stringfromlist(0,dataaxes)+";"+stringfromlist(1,dataaxes)
		endif
	endif
	
	switch (dims)
		case 1:
			duplicate/o hmm, root:packages:platypus:data:RAW:displayed:display1Dord
			integratedcounts = sum(display1Dord,-inf,inf)
			break
		case 2:
			if(cmpstr(order,dataaxes) == 0)
				duplicate/o hmm, root:packages:platypus:data:RAW:displayed:displayed2D
			else
				duplicate/o hmm, root:packages:platypus:data:RAW:displayed:displayed2D
				Wave displayed2D = root:packages:platypus:data:RAW:displayed:displayed2D
				matrixtranspose displayed2D
			endif
			 
			imagestats root:packages:platypus:data:RAW:displayed:displayed2D
			integratedcounts = 	V_avg * V_npnts
			
			imagetransform sumallcols  root:packages:platypus:data:RAW:displayed:displayed2D
			imagetransform sumallrows  root:packages:platypus:data:RAW:displayed:displayed2D
			Wave W_sumcols
			Wave W_sumrows

			duplicate/o W_sumcols, root:packages:platypus:data:RAW:displayed:displayed2DordProj
			duplicate/o W_sumrows, root:packages:platypus:data:RAW:displayed:displayed2DabsProj

			Wave displayed2DordProj = root:packages:platypus:data:RAW:displayed:displayed2DordProj
			Wave displayed2DabsProj = root:packages:platypus:data:RAW:displayed:displayed2DabsProj
			
			break
		case 3:
			swap0 =  stringfromlist(0,dataAxes)+ ";"  + stringfromlist(1,dataAxes)
			swap1 = stringfromlist(0,dataAxes)+";"+ stringfromlist(2,dataAxes)
			swap2 = stringfromlist(1,dataAxes)+";"+ stringfromlist(2,dataAxes)
			swap3 = stringfromlist(1,dataAxes)+";"+ stringfromlist(0,dataAxes)
			swap4 = stringfromlist(2,dataAxes)+";"+ stringfromlist(1,dataAxes)
			swap5 = stringfromlist(2,dataAxes)+";"+ stringfromlist(0,dataAxes)
		

			if(!cmpstr(swap0,order))
				duplicate/o hmm, root:packages:platypus:data:RAW:displayed:M_Volumetranspose
				tempx = stringfromlist(0,swap0)
				tempy = stringfromlist(1,swap0)
			endif
			
			if(!cmpstr(swap1,order))
				imagetransform/g=1 transposevol,hmm
				tempx = stringfromlist(0,swap1)
				tempy = stringfromlist(1,swap1)
			endif
			if(!cmpstr(swap2,order))
				imagetransform/g=4 transposevol,hmm
				tempx = stringfromlist(0,swap2)
				tempy = stringfromlist(1,swap2)
			endif
			if(!cmpstr(swap3,order))
				imagetransform/g=5 transposevol,hmm
				tempx = stringfromlist(0,swap3)
				tempy = stringfromlist(1,swap3)
			endif
			if(!cmpstr(swap4,order))
				imagetransform/g=3 transposevol,hmm
				tempx = stringfromlist(0,swap4)
				tempy = stringfromlist(1,swap4)	
			endif
			if(!cmpstr(swap5,order))
				imagetransform/g=2 transposevol,hmm
				tempx = stringfromlist(0,swap5)
				tempy = stringfromlist(1,swap5)
			endif
			Wave M_volumetranspose
			imagetransform sumplanes M_volumetranspose
			Wave M_sumplanes
			duplicate/o M_sumplanes,root:packages:platypus:data:RAW:displayed:displayed2D

			imagestats root:packages:platypus:data:RAW:displayed:displayed2D
			integratedcounts = 	V_avg * V_npnts
			
			imagetransform sumallcols  root:packages:platypus:data:RAW:displayed:displayed2D
			imagetransform sumallrows  root:packages:platypus:data:RAW:displayed:displayed2D
			Wave W_sumcols
			Wave W_sumrows

			duplicate/o W_sumcols, root:packages:platypus:data:RAW:displayed:displayed2DordProj
			duplicate/o W_sumrows, root:packages:platypus:data:RAW:displayed:displayed2DabsProj

			Wave displayed2DordProj = root:packages:platypus:data:RAW:displayed:displayed2DordProj
			Wave displayed2DabsProj = root:packages:platypus:data:RAW:displayed:displayed2DabsProj
						
			break
	endswitch

	killwaves/z M_volumetranspose,M_sumplanes,hmm,w_sumrows,w_sumcols

	dims = wavedims(rawdetector)
			
	if(dims==1)
		//remove all traces from the graphs and redisplay
		removealltraces("SICScmdpanel#g0_tab2",3)
		removealltraces("SICScmdpanel#g1_tab2",1)
		removealltraces("SICScmdpanel#g2_tab2",1)
	
		appendtograph/w=SICScmdpanel#g0_tab2 root:packages:platypus:data:RAW:displayed:display1Dord
		modifygraph/w=SICScmdpanel#g0_tab2 mode=4
	else 
		if(findlistitem("displayed2DordProj",tracenamelist("sicscmdpanel#g1_tab2",";",1)) == -1)
			appendtograph /w=sicscmdpanel#g1_tab2 displayed2DordProj
		endif
		if(findlistitem("displayed2DabsProj",tracenamelist("sicscmdpanel#g2_tab2",";",1)) == -1)
			appendtograph /w=sicscmdpanel#g2_tab2 displayed2DabsProj
		endif

		removealltraces("SICScmdpanel#g0_tab2", 1)
		if(findlistitem("displayed2D",imagenamelist("sicscmdpanel#g0_tab2",";")) == -1)
			appendimage /w=sicscmdpanel#g0_tab2 root:packages:platypus:data:RAW:displayed:displayed2D
		endif
		//SetAxis/R left
		temp =stringfromlist(1,order,";")

		modifygraph/w=SICScmdpanel#g1_tab2 mode=4
		modifygraph/w=SICScmdpanel#g2_tab2 mode=4
		ModifyImage/w=SICScmdpanel#g0_tab2 displayed2D ctab= {1e-10,*,rainbow,1}
		ModifyImage/w=SICScmdpanel#g0_tab2 displayed2D minRGB=(0,0,0),maxRGB=0
		ColorScale/C/N=text0/w=SICScmdpanel#g0_tab2 image=displayed2D
		ColorScale/C/N=text0/w=SICScmdpanel#g0_tab2/A=RC side=1
		ColorScale/C/N=text0/w=SICScmdpanel#g0_tab2/e

		Label/z/w=sicscmdpanel#g0_tab2 left temp
		Label/z/w=sicscmdpanel#g1_tab2 bottom stringfromlist(1,order,";")
		Label/z/w=sicscmdpanel#g2_tab2 bottom stringfromlist(0,order,";")
	endif
	Label/z/w=sicscmdpanel#g0_tab2 bottom stringfromlist(0,order,";")
	Label/z/w=sicscmdpanel#g0_tab2 left ""				
	
	if(dims>1 && isLog)
		Wave displayed2D = root:packages:platypus:data:RAW:displayed:displayed2D
		redimension/d displayed2D
		displayed2D=log(displayed2D)
		displayed2D = displayed2D[p][q]==NaN ? 0 : displayed2D[p][q]
		displayed2D = displayed2D[p][q]==-Inf ? 0 : displayed2D[p][q]
	elseif(dims==1 && isLog)
		ModifyGraph/w=sicscmdpanel#g0_tab2 log(left)=1
	endif
	setdatafolder $cDF
End

Function removealltraces(graphwindow,bit)
	string graphwindow
	variable bit	//set bit 0 to remove traces, set bit 1 to remove images
	
	variable ii
	if(2^0 & bit)
		string traces = tracenamelist(graphwindow,";",3)
		for(ii=0;ii<itemsinlist(traces);ii+=1)
			removefromgraph /z/W=$graphwindow $stringfromlist(ii,traces)
		endfor
	endif
	if(2^1 & bit)
		traces=imagenamelist(graphwindow,";")
		for(ii=0;ii<itemsinlist(traces);ii+=1)
			removeimage /z/W=$graphwindow $stringfromlist(ii,traces)
		endfor
	endif
End

Function spawngraphstatsPanel(type)
	variable type

	dowindow/k spawngraphstats
	svar dataAxes = root:packages:platypus:data:RAW:dataAxes
	svar order = root:packages:platypus:data:RAW:displayed:order			
	string title
	variable centroid
	variable/c CoM
			
	variable/g V_Fiterror = 0
						
	if(strlen(dataAxes)==0)
		return 0
	endif			
			
	variable dims = itemsinlist(dataaxes)
	NewPanel /k=1/W=(150,77,387,220) as "spawn graph stats"
	Dowindow/c spawngraphstats
	autopositionwindow/r=spawngraph0 spawngraphstats
	doupdate

	if(type == 1 && dims==1)
		wave display1Dord = root:packages:platypus:data:RAW:displayed:display1Dord
		duplicate/o display1Dord, root:packages:platypus:data:RAW:displayed:display1Dabs
		wave display1Dabs = root:packages:platypus:data:RAW:displayed:display1Dabs
		display1Dabs = p
		
		centroid = pla_peakcentroid(display1Dabs,display1Dord)
		title = "peak centroid: "+num2str(centroid)
		titlebox title0,win=spawngraphstats,title = title,pos={6,6},frame=0

		curvefit/q/n gauss display1Dord /x=display1Dabs
		Wave w_coef
		if(!V_Fiterror)
			title = "gauss centre: "+num2str(W_Coef[2])
			titlebox title1,win=spawngraphstats,title = title,pos={6,28},frame=0
		endif
				
	elseif(dims>1)
		Wave displayed2D = root:packages:platypus:data:RAW:displayed:displayed2D
		wave displayed2DordProj = root:packages:platypus:data:RAW:displayed:displayed2DordProj
		Wave displayed2DabsProj = root:packages:platypus:data:RAW:displayed:displayed2DabsProj
		
		duplicate/o displayed2DordProj, root:packages:platypus:data:RAW:displayed:display2Dord
		duplicate/o displayed2DabsProj, root:packages:platypus:data:RAW:displayed:display2Dabs
		Wave  display2Dabs =root:packages:platypus:data:RAW:displayed:display2Dabs
		Wave display2Dord = root:packages:platypus:data:RAW:displayed:display2Dord
		display2Dabs = p
		display2Dord = p

		switch(type)
			case 1:
				CoM = centreofmass2D(displayed2D,display2Dabs, display2Dord)
				title = "centre of mass: "+num2str(real(CoM))+ " , "+num2str(imag(CoM))
				titlebox title0,win=spawngraphstats,title = title,pos={6,6},frame=0
						
				imagestats displayed2D
				title = "avg counts: "+num2str(V_avg)
				titlebox title1,win=spawngraphstats,title = title,pos={6,28},frame=0

				title = "max counts: "+num2str(V_max)+ " at: "+num2str(display2Dabs[V_maxrowloc+0.5])+ " , "+num2str(display2Dord[V_maxcolloc+0.5])
				titlebox title2,win=spawngraphstats,title = title,pos={6,50},frame=0

				title = "total counts: "+num2str(V_avg*V_npnts)
				titlebox title3,win=spawngraphstats,title = title,pos={6,72},frame=0						
																		
				break
			case 2:
				centroid = pla_peakcentroid(display2Dord,displayed2Dordproj)
				title = "peak centroid: "+num2str(centroid)
				titlebox title0,win=spawngraphstats,title = title,pos={6,6},frame=0

				curvefit/q/n gauss displayed2Dordproj
				Wave w_coef
				if(!V_Fiterror)
					title = "gauss centre: "+num2str(W_Coef[2])
					titlebox title1,win=spawngraphstats,title = title,pos={6,28},frame=0
					title = "gauss stdev: "+num2str(W_Coef[3]/sqrt(2))
					titlebox title2,win=spawngraphstats,title = title,pos={6,50},frame=0
					title = "gauss peak: "+num2str(W_Coef[1])
					titlebox title3,win=spawngraphstats,title = title,pos={6,72},frame=0
				endif

				break
			case 3:
				centroid = pla_peakcentroid(display2Dabs,displayed2Dabsproj)
				title = "peak centroid: "+num2str(centroid)
				titlebox title0,win=spawngraphstats,title = title,pos={6,6},frame=0
						
				curvefit/q/n gauss displayed2Dabsproj
				Wave w_coef
				if(!V_Fiterror)
					title = "gauss centre: "+num2str(W_Coef[2])
					titlebox title1,win=spawngraphstats,title = title,pos={6,28},frame=0
					title = "gauss stdev: "+num2str(W_Coef[3]/sqrt(2))
					titlebox title2,win=spawngraphstats,title = title,pos={6,50},frame=0
					title = "gauss peak: "+num2str(W_Coef[1])
					titlebox title3,win=spawngraphstats,title = title,pos={6,72},frame=0
				endif
						
				break
		endswitch	
	endif
	killwaves/z W_integrate,W_integratex

	return 0
End

Function checkbox_sicscmdpanel(cba):checkboxcontrol
	STRUCT WMCheckboxAction &cba
	
	switch( cba.eventCode )
		case 2: // mouse up
			strswitch(cba.ctrlname)
				case "log2Dgraph_tab2":
					Variable checked = cba.checked
					getLatestData()
					break
				case "autoupdate_tab2":
					if(cba.checked)
						variable space = 2
						prompt space, "Refresh period (s)"
						Doprompt "", space
						if(V_Flag == 1)
							checkbox/z $cba.ctrlname win=$cba.win,value=0
							return 0
						endif
						if(space < 0 || numtype(space))
							space = 2
						endif
						ctrlnamedbackground autoupdate_detector, proc=autoupdate_detector, period = 60*space, start
					else
						ctrlnamedbackground autoupdate_detector, kill
					endif
				break
			endswitch
			break
	endswitch

	return 0
End

Function spawngraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable type
	svar dataAxes = root:packages:platypus:data:RAW:dataAxes
	svar order = root:packages:platypus:data:RAW:displayed:order

	switch( ba.eventCode )
		case 2: // mouse up
			dowindow/k spawngraph0	//kill the graph first
			dowindow/k spawngraphstats
			string title
			variable centroid
			variable/c CoM
			
			variable/g V_Fiterror = 0
						
			if(strlen(dataAxes)==0)
				return 0
			endif			
			
			variable dims = itemsinlist(dataaxes)
			if(dims>1)
				prompt type,  "which graph?",popup "2D;ordinate projection (bottom left);abscissa projection (bottom right)"
			else
				prompt type,  "which graph?",popup "1D"
			endif
			doprompt "spawning...", type
			if(V_Flag)
				return 0
			endif

			if(type == 1 && dims==1)
				wave display1Dord = root:packages:platypus:data:RAW:displayed:display1Dord
				display/n=spawngraph display1Dord
				label/w=spawngraph0 bottom	 stringfromlist(0,dataAxes)
				setwindow spawngraph0 hook(mytesthook)=spawncursorhook1D,hookevents =7
				controlbar/t/w=spawngraph0 30
				curvefit/q/n gauss display1Dord /D
				Wave w_coef				
			elseif(dims>1)
				Wave displayed2D = root:packages:platypus:data:RAW:displayed:displayed2D
				wave displayed2DordProj = root:packages:platypus:data:RAW:displayed:displayed2DordProj
				Wave displayed2DabsProj = root:packages:platypus:data:RAW:displayed:displayed2DabsProj
		
				duplicate/o displayed2DordProj, root:packages:platypus:data:RAW:displayed:display2Dord
				duplicate/o displayed2DabsProj, root:packages:platypus:data:RAW:displayed:display2Dabs
				Wave  display2Dabs =root:packages:platypus:data:RAW:displayed:display2Dabs
				Wave display2Dord = root:packages:platypus:data:RAW:displayed:display2Dord
				display2Dabs = p
				display2Dord = p
				
				display/n=spawngraph/k=1

				switch(type)
					case 1:
						appendimage displayed2D
						ModifyImage displayed2D ctab= {1e-10,*,Rainbow,1}
						ModifyImage displayed2D minRGB=(0,0,0),maxRGB=0
		
						label left stringfromlist(1,dataAxes)
						Button imaglineprofile_spawn, win=spawngraph0, pos={20,2},size={90,15},title="lineprofile"
						Button imaglineprofile_spawn proc=spawnimagelineprofile
						setwindow spawngraph0 hook(mytesthook)=spawncursorhook2D,hookevents =4
						controlbar/t/w=spawngraph0 45
																	
						break
					case 2:
						appendtograph/w=spawngraph0 displayed2DordProj
						modifygraph /W=spawngraph0 mode=4
						setwindow spawngraph0 hook(mytesthook)=spawncursorhook1D,hookevents =4
						controlbar/t/w=spawngraph0 30

						curvefit/q/n gauss displayed2Dordproj
						Wave w_coef
						if(!V_Fiterror)
							duplicate/o displayed2Dordproj,fit_displayed2Dordproj
							fit_displayed2Dordproj = gauss1D(W_coef,X)
							appendtograph/w=spawngraph0 fit_displayed2Dordproj
							ModifyGraph/w=spawngraph0 rgb(fit_displayed2Dordproj)=(0,0,0)
						endif
						label bottom stringfromlist(1,dataAxes)
						break
					case 3:
						appendtograph/w=spawngraph0 displayed2DabsProj
						modifygraph /W=spawngraph0 mode=4
						setwindow spawngraph0 hook(mytesthook)=spawncursorhook1D,hookevents =4
						controlbar/t/w=spawngraph0 30
						
						curvefit/q/n gauss displayed2Dabsproj
						Wave w_coef
						if(!V_Fiterror)
							duplicate/o displayed2Dabsproj,fit_displayed2Dabsproj
							fit_displayed2Dabsproj = gauss1D(W_coef,X)
							appendtograph/w=spawngraph0 fit_displayed2Dabsproj
							ModifyGraph/w=spawngraph0 rgb(fit_displayed2Dabsproj)=(0,0,0)
						endif
						label bottom stringfromlist(0,dataAxes)						
						break
				endswitch	
				
			
			endif
			spawngraphstatspanel(type)
			setwindow spawngraph0 userdata(type)=num2str(type)
			autopositionwindow/r=spawngraph0 spawngraphstats
			break
			
	endswitch

	return 0
End

Function spawnimagelineprofile(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up		
			WMCreateImageLineProfileGraph();

			// click code here
			break
	endswitch

	return 0
End

Function spawnCursorHook1D(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	
	variable xx,yy

	if(!cmpstr(H_Struct.winname,"spawngraph0"))
		yy = Axisvalfrompixel(H_Struct.winname,"left",H_Struct.mouseloc.v)
		xx = Axisvalfrompixel(H_Struct.winname,"bottom",H_Struct.mouseloc.h)
		TitleBox/z title0 win=$(H_Struct.winname) ,title="x:"+num2str(xx)+" \ty:"+num2str(yy)
	endif

	return 0		// 0 if nothing done, else 1
End

Function spawnCursorHook2D(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	
	variable xx,yy,II
	
	Wave displayed2D = root:packages:platypus:data:RAW:displayed:displayed2D
	Wave  display2Dabs =root:packages:platypus:data:RAW:displayed:display2Dabs
	Wave display2Dord = root:packages:platypus:data:RAW:displayed:display2Dord
				
	if(!waveexists(displayed2D))
		return 0
	endif

	if(!cmpstr(H_Struct.winname,"spawngraph0"))
		yy = Axisvalfrompixel(H_Struct.winname,"left",H_Struct.mouseloc.v)
		xx = Axisvalfrompixel(H_Struct.winname,"bottom",H_Struct.mouseloc.h)
		II = displayed2D(xx)(yy)
		TitleBox/z title0 win=$(H_Struct.winname) ,title="x:"+num2str(xx)+" \ty:"+num2str(yy)+"\rI:"+num2str(II)
	endif

	return 0		// 0 if nothing done, else 1
End

Function/c centreofMass2D(w,xx,yy)
	wave w,xx,yy
	//w is a 2D image wave.
	//xx and yy are abscissa and ordinates of image wave
	//xx and yy should be 1 point larger than w, as we are considering an image wave
	//return C-O-M via a complex value
 
	variable ii,jj,totalmass=0,sumrmx=0,sumrmy=0
 
	for(ii=0;ii<dimsize(w,0);ii+=1)
		for(jj=0;jj<dimsize(w,1);jj+=1)
			totalmass+=w[ii][jj]
			sumrmx += w[ii][jj]*(xx[ii]+xx[ii+1])/2
			sumrmy+=w[ii][jj]*(yy[jj]+yy[jj+1])/2
		endfor
	endfor
	return cmplx(sumrmx/totalmass,sumrmy/totalmass)
 
End

Function listexe()
//is anything still running?
NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
	sockitsendnrecv/time=2/smal sock_sync,"\n"
	sockitsendnrecv/time=2/smal sock_sync,"listexe\n"
	S_tcp = replacestring(" ", S_tcp, "")
	S_tcp = replacestring("\t", S_tcp, "")
	if(strlen(stringfromlist(0, S_tcp, "\n")) > 1)
		return 1
	else
		return 0
	endif
End

Function SICSstatus(msg, [oninterest])
	string &msg
	variable oninterest
	//tests if SICS is willing and able to perform commands.
	//returns 0 if SICS is ok to do something
	//returns 1 if SICS is not OK.
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	
	variable err=0, sockID
	SVAR sicsstatus = root:packages:platypus:SICS:sicsstatus
	msg = sicsstatus
	string left
	
	if(oninterest)
		sockID = SOCK_interest
	else
		sockID = SOCK_sync
	endif
	
	do
	//	DoXOPIdle
	//	sockitsendnrecv/time=2/smal sockID,"\n"
		sockitsendnrecv/time=60/smal sockID,"status\n"

		S_tcp = replacestring("\n",S_tcp,  "")
		parsereply(S_tcp,left,msg)
		if(strlen(msg)==0)
			print "BUSY - still trying to get SICS status (sicsstatus)"
			sleep/t 10
		endif	
	while(strlen(msg) == 0)
	
	if(strlen(msg) > 0)
		sicsstatus = msg
	endif
//	if(cmpstr(sicsstatus,"Eager to execute commands")==0)
	if(stringmatch(msg,"Eager to execute commands"))
		return 0
	else
		return 1
	endif
End

Function statemonstatus(item)
	string item
	//sees if item is still live in SICS statemon statecontrol engine.
	//if it is still live then a number >0 will be returned.  If it has finished, then it will return 0.
	Wave/t statemon = root:packages:platypus:SICS:statemon
	findvalue/TEXT=item/TXOP=4 statemon
	if(V_Value == -1)
		return 0
	else
		return 1
	endif
End

Function showStatemon()
	Wave/t statemon = root:packages:platypus:SICS:statemon
	edit/K=1 statemon
End

// PNG: width= 324, height= 108
Picture go_pict
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!$Q!!!"1#R18/!$#`bAcMf2!HV./63+16*9dG'!!Zn*7mm@W!<3'!TY7
7e!!!!*E(F,Q!!!J[!!!J[!CA3(GQ7^D#BWO370hHK$Oe!a]S,>^!!!;c8OPjDGhVQ?I>em5*QR]rD
g1Yn\`:1%6*-a=.;5HqVeXU[/&kaCH:MZq`hJ;ZgM!U$D+n`)"cZMs0bC)qdFr7YUr9^=51[[%[&MU
]W']#j;8`^^P8nOspTT"Zn$df5m,!=8S7r<TID9gUhp0GaIP^SbREs.Eh/(0qo7&;*$M?_8'T9q.?`
E+S>lESEECmI)>/?!A<)"Cf@H`p(LMYt6F_lhB2so7qfC@\!Y7G-4oSF;S7_!rF^8VP:/shdJkNb*'
dWM,a8\T#o13t/kB$Hbj8Xb%CG:g>KK=ah>5o/N.Q[?8"&+X+G$7ZS0>qV>Q/',kGZ<O9O,IuUS,n#
k^mC:qG_-Q1M"`mgh]Ls;VjpEG2lH@C7R,$IaYi'-a@.)F+q-=ae">b*X\[s5#OB[!Wga_@FDDHDHD
K7[[RG>sFjmLMjQ24OaDseBODTT7nAhnRO1Ga4Y1RVHd1Ga*?S&nn;As-:PBGO5nP=['%.9I!)ZRAa
'\h'4Xd:8,.-&M4=?0=e@j?B*k<S/N_#a2!_Eu.><0tF`KP0Ba>Wl#uPDN[L==HH$S0UKhQ:`Vc&%^
tI+1!"49NPW%i9cK\2)/@=1AS#=2e2#E_(6UGZe$+Vu3kHbN:s=/q>1/-QA^,2V;l=9'.9b:c>0+^B
U:HU`bN*,%"6Po-;$3-/Pfm;eSBKL&!L:l<IB:Up/1G*%"!3BcZU4VHfWQ?3-oT(OF^&co95Mh$A6i
ISj#F_\ccr"b.URsOSttU5aj:Is5*#t&!/)-g&7,?%GQAr"!.aP?!5]*Di<947(B>"Q!'kc0+M7])n
,`U,$NT,h!/)-g&7,>B0*!--!.aP?!5]*Di<947(B>"Q!!k4X+M7])n,bk"!<D'^!/)-g&7,>B0*!-
-!.aP?5^7^;Xo.Zgh=^+9Q"#T`SJ"()s*8Qra-(A.pLi_"&7.^P%?tu/ZO8VMcEjp+btIEn'JM3&HF
J!dZgm/Q5OJIEMhfb++M;l+oqlqTnU23ecD*U$G@)/54q/Ynco\sWbnE=sZte"TfX%Q.*Wb4W"F&J'
Q^6jj"k3+nWlNfikn$JA5<Nf#WdA[P>5cB2F9`)T?21@FPHJ2;Q*,Mu;Q\]bQD5Q3^K@Si]RB_d=0>
o8n-ApHhVO;7!TCEocZM@No+mpoLRru\d3;(J$H0[(j#Z)qmC^[a9?seEjKIMb]S=j5r)gEk5$&R"W
a-Y2hVa2\`U/()oPWp'Gf,F7[rcP5jUc_@K\%jSC[F`BqsO&4s/B5Q=6cPJ;SYmfXkQl@2K.'E7@+G
$Y'PBs[;pV'+_T.$b$Ni<r_idcDcpmA^])t34nJN6RaZ_d^-)5`I<NZ7?h);m\Kn]i?fdH&f=^cKrN
JX`YFXU793-=&GQCh?OlY&\K3W$+5OR=5`U+bUDchJOe:qsM]Ot403QjF"Z,a`IK?j3U=.SnJkPMjg
2m_%Xge@ZkqMcEB\F4ip*;d?<m)9p]cTXiMNrOA&o/@Dn^@dhY_qOO\CHeh`e!JfY%,k!cr^#!LS>f
"[4ApO.J\A#3[s?[tDa(\@ZX_,/gb$ktKGTBI[:bE#J)jd=p:s+CDtCS_8.)l[W4pP9Y$:YC*Ofrop
YnSeK^ci2r8X?_CW;oPfAbu]ej(4J6W1]lgQ17#k4/=-XBI_JoQK?[&]+oCkUZ=?_)&jQ"o"ObD7s0
<OE=`_jbqmF?En\8_Ya5=]g%DR+M9C]alAH/NGZ/'Gsi%2OV/gAs6dsJ-f.^65+%++s,V,u4\YZV?J
dj)qmu^+=/dfV7u*la[6h.$iP:5h+8MI_^!PO^EB?s@@0\0hSt_]dgnmYQ>Nq*2aOW5_2X6B<$Q@#Z
I4lueIg[U9:nr;(Mlo/9#0f8=Q9sN5nu9.Ob%/'kbu=$PIH3gmB7`YQK8&g3:8T,fY3W"3d=*=\dMZ
aZ=:8X<3r8@>`VHB&Rk8/UiaI/Ml[S8c_tW$J6!_00H@>2'@Fq,*HD9Q/hl>/&S?YlYpq!>T[T*7t2
FoHEpE36QjJb8qisNW'NrrDIQg;3)o9F*G:ciT@A4YQM$LV5L1s"cb.`>fJ6,UIkWnTN(J.i`YRWSN
ZVJ+t0$[XA9*k6%.?JE9WCL5TY`S]Bd]kf$n92</o=.aW;7b$o(?g>3%d9!t-KdaJ@Q6([1GtmN1(2
?HALGL[+ba"#;Z]LE>SVB9U#0GYa1+;jtJ,,2.Wuns"pSem:^2`.r/X%hm>$#D&-*k='j%bW'E/\\'
0i(;63/5^LM+h3m]1isa]W^S8PM^Q0`:B,L!9#4q)H#CbCX2d=/jAr+AM`Cl)MF4:caQUDrKtK74rr
o-MM)`NYFV1IAX\)!rc:dNc(f9X3>`.!=1,ED4]pT(Gsb'@^H[8<WjUa*Z+>D\*)/Z+S\:Y]X0$2d=
2Y$Xs/u1Eo3VbYj7@L,?9?r&"O0&;QEE=D"s3/'&$I(#i![f3ZQ?)a*7IVoJahC8Up7&5q4$ttd\0U
mj!g,82Jd1lpl)%D?^U[*+39*(q@lj<3'r[4o4R0+H1lDR'UgAP.i`d*m?r?3+/&kTCC!W<^*P(J#@
567?KVE9r0R1N)utX.!"`H:5^3;P]E!KO!W^(F!9"(]KGOV"?3!68!?f#TJFEU?_@$A&"TX2l!"`H:
#VQ0#]E!KO!W^(F!9"(]KGOV"?2t6a!$JoSJFEV*GQ@g'"TX2l!"`H:#VQ0#]Du?,Eg"r'f(Lh(OW'
4Bo[]2;H6mc,/hau%,e4.O3<da?bGFcF\ScAOa!EC\Cb?6==-/o^6E&*E>V_T-F0EeI\D3mN*L<DA1
9(_])-<t??#DF"\k;Ohd;%LRjX.mqAQA%gZ=FipqO5$])]7AMUttTl%5,P]2C3QC[^A/%197LOmC8-
fQ'JFo4m,DJcBJ8.8+kU!n-f/Tz8OZBBY!QNJ
ASCII85End
End

// PNG: width= 324, height= 108
Picture stop_pict
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!$Q!!!"1#R18/!$#`bAcMf2!HV./63+16*9dG'!!Zn*7mm@W!<3'!TY7
7e!!!!*E(F,Q!!!J[!!!J[!CA3(GQ7^D#BWO370hHK$Odt--D`LT!!!hh8OPjDGhVQ@H#sa#^'F/rX
fCg7"pdb=AfSU3B>e@HQD!ipH0C'&,RO!s%W2R;R<di4^4X)W0aJ):,iF2'M[N)jE#G7+*liONb3gZ
6oB)#ZCb#=Z/Eue)?2*4M8#em'kp0Q*V!71DIF$<&hPsMh\t?^G]':(&GWbGjV5:^7h_6LU(?+-W'h
(t$!(8r9WU"jY&.1utFgk0\.AM,:)>8P9U?VVbIkC^9;Q,[R)Et%_ibYb3g$DV+I6Y$Ja8"s:+7W']
BNC.Pr0qMGi?"'#FU?b.V1j*0!6>Tg2T0I+5+`@DSphR_%ie.8'm/hcf4!7#3Uh8UEEhS=pYH8Xq!g
#/&55D]8-oSG)$CUNJ3cd6!=0hpP70d.0``GO"=,)n,a2V&5XJ",0I`h$"<\unKOdt75Y*=-,U<m(f
Vr-ur_(=Z2C$UbU3b5uFoG7Qohn_?9LpV.'G+M'#m"uo\.A^>64*`:"VX3.+XEGVq^I1`h/*3e$Gj8
qRfjOZ1G4>5"CU*3FicXn*<>*P:+36R'*b+IduHf@T0JClgMb,>55itc.r"4l2rbG;^Q4>4pp=hV(]
`Kls1+Eti+E"@!tZ+'m,IICmUHl7!^a3^a%-4bo5W"P?#g7*1IqNq\`*94?bTQ'-ue<N(T5bNbO"kN
fDN[-k%&SUp.HR>,.S8B`YEG9L#a4IW(PlAND%Qn+uE;?",[YYjK=U&+Xk4pP$EbddXmVeTo'8>i-r
1hh^`pu:D4PUJG6hq@a"]FTt:6+,W-2[N3W6<6!W?j)a<%SDumc*:HlUN]KGt:^80K`%)5lEEYr$]@
+<d*Uh\G36N>^PC"/)?2f[O&AARs'mbRQFh5RDVmWLrl`:5[7EOq/@3,\fLk4d_"AnGY<^f@.0XXii
.5BEp4,N$8^g[E<C$Ochq13Zc"f,d+jb,L^;ms1HgIieEr\IIK.?dnM%a+Nf=iN`Ua0:O[qGW`K7<?
(SG$M*dc>?gFgU2s\$<qTX9J,a4q_A*8Ws/K-9("]$?:-C;JX(1)A]k^^JD>.`_Skm]S=*WL#ej]XU
6scI[!=S^<eZ/0d5B/_h(ErMGs759j97>\<-,9eip4I-K?=";T?>omL<a64:gU;7*@f\C`?F@@lan>
X37li$H7a1h=rN"KbQ?l=K:8]F5GdRoa]6<VD^[5?__:9C,OV%TbHG.VgEVXD#lLH7QpeMppP`-P:p
Xe7up$.\qn#:420Z#>`\-hfuS&"]k"5sRlCeY&J$M*d/!LViL<VMdqp[t(N::MnXk.@>`[F4.o-Os`
bdn]nLlaMih>W[/rW5%^@LVqZP#DQUt^Gio][!H,0GlN2&AS!0$O3=TlXXO"-n)Rn]DfC<OKmV<B?a
\Jo"02kUHGG-H!=-c64nI\ge&H$L^Q4_M38rD&/mPmt&[%I`!3YgVeJPOXgU8CZ@"uEsh-3b)a*6N>
eAld3!+']XEK?D&B5A#r].m,Z0OE?Cm3/2dkSpb0]O^,b7Sb&Vm<_o?TOps:`YRMOOdFZ2/lbUq\/G
Hm='2ZE!j&8r-?4?:!M<7i;0%qciNb4>e$.9f#.$+=%/L2KW$kkqmdPd$C?C1Ne30s3Wf!-*Stpuh*
3_:4!%Z.::C+apJ7#9.?eWPMi_\/%IM*Bu`dlaq@"n"j\8QfKF5B92#r'4H10coLDf5X-W[*<Ld<f7
j^op^=/FDO`nVo-1?;+b:_?!kL)mJ7n]c3<O=S$YM!Ch=aV5C+:A`3u7oSin+Z$lKq",uPpAT,Q9.t
,IQ::KgR]\mtnh?8V7D*>,]^b==>DH4s\Iq2E?:N=$^C2,FH0<YC]^IU)h)?Y/,"McWpLu5pUY5=Ka
MP]3k"g7_B!gf0,YlGOH%bg[.b1.<.s%\*@.UJ6`>^*4u<i7'Fi<ZOTGjpV\J/./.`s".<n1.jHP[*
0/p2ugppZt;X)?XSaRhHrnd(qZ5?[Js@Y67t-iT9`Y;37E2mG#',J87jd_\J3Jl3Mo_F:X<8rN,kgd
VRgGYAD&J]S#/M#Af*B^]s8^o[9f'^A*We9,5+P?8"e/jUk`U!Sb.p7u%,bo`2%q/F?;]oUs7MH[O-
+`r-C&X%b`2,;f1rG?:n.ZY+V4g1lfkY=NWg7<#X?fVf(+SNhV<h3K:-5HCq8koL4;%jVHd<Z[2#0P
Q1E+*_^0q6uuFe=!c!,fM:^;"6/<`EIko73koZ4:P&hfstSt$M*fC"Yd(a=B.dmf@lu)h0.Z(ZUkF(
3+1(d#;#&b+"Jk%n,@h;9/aFtCMQe/T9!hn[o/8;#/FQ&!*EHP?pYC.lH6Cb[7:b[L21mo_I[;#9Rn
!@?[r"))^i+5-GYcJYM.]6N6'2##a\$H/S;eAmG&R8?pYC0WlhVB[7Br&m(A+=.0*F/@*dL0N#OcI\
%f9.d'gCi0W3qG$*KBn=5*]__dh<DS]K.%[0;p'"^,tZBkHaprL09gYB7DHTU&b]HQYen%Xn!+>=Z,
$&7A8P/(.76Uq)PEi+`@%NK.K*]k^^!J;I)&eJ4qFG2ZVeJoHDGp:P7XGg=F5IsgG37g,4>nFHC&.*
0`Tek\K'*`iRHp0n0?nqIZn&MOe(U:PAJReOmPe]tI$\D8!sV0:DWNtJV&HiCD:^kXQU?r"P]kOW+M
?=!`DmPNmCd<b(3^cpSf]32p;84Rf6RG3(5T5(9s"BRt+Cem8Jq2fOpq<-#[PS\J9243<H2$_`:Juc
ch]<;fS\[UJQ!3eMo8mU;kq\2-2>Y/ll8PBqLOYXt,i,=,?I+9\J/4%/RaBNSn"eU2?0u4UFDu`\t3
o1.3icrP(2e&,!7I`"DY*Rp3H_[0^cg#M0-+KDg#/e5d\diWHBqKAfVp7(i.ksoZ@LS1r1Amp')Ci=
4rEKuNK_^I6B@]n2X()/D!$pNgpir@Oa<8"P$s6T'04qka3E.96U<c<H^nWdf,J4X&Y6Ol&L8uf?($
DOXH4NfY9n_G^/]i0EQrFN3oaVH@(#&p0(rNP/6!>-9NC'\]\Ts"hC)^P1ot:Va9&+KY6D\IYr/`X:
$%s+K6D4rs'FKO\GYom6-'O(CKGT>/%=gdQUJN?Q_M^aS,\&n-5TpHl%DtF7kP/C-E*c/41PVqJ6a!
HKED8eZ`fM']H;$/pc,aR=Ro`4pbW5[W0^qje;'RAJ1PVMUL67pZLG]MYc+IA(bL]S":S\M2aAZ)4d
PQ&@U4":=eRuCliX)qT/Zg6Z2/96gGA8$;M,:,$lI24WN)3MJ9X=Lk>#']k)i(ID2L7LQo"kD-pBQ?
GOE4q6\4K\_bnt2k`+MEpUm1)_(uFn0YU8_TA1Oi&"p>KW-IA+7%8UHe+Trhn#'!m?A-'2;<H1$Ldf
;Sn*45eC0STpq#6Q.i+-l*^5lmEZ=[rJ%+=6^eJ`BYfC.5rSNsAtE\UiNL%,qB7l^&J`QhWU1_61/P
\CB[g7DYb1hW-OD%0JB.)E"ZrVHKf<!58W@Rr`fToO\Nn*Y/I/eLAu1!s>"9_r%sf5?8JGjRJnDNV`
Q0&AT)K[.kJ![kSKR@NC6Ur(mYl6Qt6[W`\5'UJoeLAH4+cKs3NN_A/$g+6i#a5&Iq-HjI1M$#\iX6
6IomJ.>tibCtd*(Xg3J!!&=<67<:sOMr(9m-unm^baI&K*T29bq(@J@!")YpGg2=QOAL"QfIV)B<IF
qWf!&re->t7qg@=!e0qt)5le5s/kg8q)SDrnXA_\=KM9DT-]\N2bW9>3Hr'iKBV@V"JjF58*9/mc`G
RWnPlc2QfKQK2_Z0e-^h%Z_J)bQXLn`g\Ph<iu9Ztc`r%]+B+2BA8)m^I!"TXqjId;$Jbj@lZP^(.G
HqnV]ojDWscqAIiXD)pNl+m-`Wm_>n2s*#M$NMp^bW"kK2="f*W6[dDXEWFo?7F/kLZ*C0r01s\1[T
1'?W?b:LLG*="qF7^iMtU>B$s4q<7<O#;=I@)YUP;9]T:_R30bbC\*CjmYWe'41e^nR]c`,2V^`kZ[
Z*?@1#M#*l5^ICD,"A+JHYJHY%(fph=CHf92s^]j*>qd6IDBtr(HX$RptSEI;/Zia`9"=?ZVd!eb*O
09l7".4R6P.k=ReuPON=&k.+_n!.;jJ"p=uE&dVm6Y2`7%EO)-!*WL"pYW#%^_;8kN,4N'Bp2Mq78L
ZCIggU.HP0?>`)j^p@^rMsT80EE`JH.%]3]7fZ::,*2V5*>j?D%+.VMLI.LE.k,YGuijj2"Dpa$(sB
Kb4#G#eXR5$QGlipm%^bN2FQV.@er0H:HR,Z6"36_L3T#aZ!r=J7CoR[h-mer*35VhN]':qi=QR]]n
roQEF`4Ph7>dp'H<#W12jeTVC?VF4f-rNPqjG'fP@lrZNY`W6`dh'iS@ZjTWN%*HJcliofRjfHp_bi
#LK3a5>)Mm;jH?\ZTEekLe__+<uWmkGXl,1g9f\C,uD]7AF:K)aH@%E/UaU?<+uCR[-oCp#`8(DGO'
KG0]W/&.Rp27gSJ/Ff[M1]Ub@CX>VVbS*Sq]L-!FglI2"Q$rp;d1A@\D^PhSr[kIeL'a6r>"`V"K$X
aA*W&+p!iZ'%[NWm"S`GYPd:g_Kb:.gB3b[Zg1).!;.cNs9QFJqU5ml))`WYhb9&aQc/#lL$lUXU=]
"Q<CPc:Ee.)g)L;CeKOU:f9(idZO<"9'd/la!0k3aY\c('cmmW0cS("A,LZ-3fn>_Pl!pnRu\MMi]D
;/8r;@ji+OY6=`2f';]?63TK5piK3'A^\1J9-CTVtgA0!CQ5/u]C13_$HNq-DR[H?N;9_%A2.lbSR5
QEIHZJM\#)D8C:#C`as)G/C_;rWd<NqnN7DA_lPn@5[H:Y9Gl4T&TOVP12fhuh90Y*FaH`\=W^F'Pa
o(n'C@8.@<>;e[*<78]\kD<q:+Fo!3*>6WKU;dVu0h=Sr8-/NnFeD/+;Q'Ad/&AZ!cTA9=?`%TARO2
f06%?UkQ't5,b!1q\_'SSkJYk/#G%#$B<f?oF0]LnO'_G,o>RoL3\8;WI[!;8l!c@sk_HlIDtiH:Tf
lR6SH:5d=WAXR\8IM\igmA`OZcJu`H_'$/nJUr87qC)cS2U=lSBV%mJ;0P4`W&B%?p/_rE:.rKW_&s
MJ6<J+B\4KQESM>LBAc2qMeqr)3dsdOm?Er7E]7WCc(BO[@!VC<-5-nOt<mP*V>Gjo`&=s2^E0I:[W
DbJA`9_qP-d&:&Ws<.eP*Uh3L4OQm.9AD8!J.iBGj`s94J?K^6^Y:lKD)+=j(6-D-H!W36D-e?A2/f
X'Er]g1*o[FVE8;_F'9J?)@#'\*.O#GT>rf@l2s]6UJ<&'R1b9AM3JL><Itj30#an)'QY&qbpq[K\/
<Jd8tf(O)8_:uTb(NE$ACfk;(*+ciK\csd41e#?5+b65i6rd#VQO=66WuiE=2BNg*_JQ!T?J(DiR@[
J@.*O5a<J+#VSg*1Jua1YVs93ksDrqLZ0&Eol3QD0#jINY8RTl&7@61[4t7U_3q<;E,Hm#*(WjqO!M
9KQP4C=8mL\s3'g6Fk;J'-XJTF&gC:/dFDsBT?6q&S8@'pjDIXm,(#drf&]#Sb;3BiBf8)\bc*+J!0
JK)E?r=c5\4sIa]I4(GCm4oH9Uo476^832+Mct@f>4]ar7'N4FgDkakW.]^>6V52UYX6J_mS>J>YJ"
PW$N];?3!g1HoV3CB=J9m^pRS/_YW/:%3I0J%_9j8PqU^VqnNKAVJn[1'3n`2^Wi6,O4I\?j2Dj&g%
+6l3,)7m^h=#,EGup(>H`+>HE%!NB%'&LiM1[A%"M1cX=7CmfRuoJge7LhX!G1f*A7f)dUgTUC%C?]
40))k:(gt%#1jlTi0lfA%\@"6W4C6'oH$1WFN'?rCn8^N:4Um4ojhlXPmj6\5+f8cLYu_E<`2uL"L%
q/XPMggh[$B=KnZW<?LYkkU\13GrnZ-k8JY\r7G#!PfBY?R;I#g!CF653\=A9i!S/tc(,K4S6c]La4
`bMIFXUS,\IU7A!94(!`;l7e8RFYpm[E%](@+f0BF*;jE"t3]CY%k*2W+r.J`VpcpDe4CX^`kZXTrI
S<G<DTbhrBbSEC/1VrM?bFP/ECShd/ApUqn]-O?rDHX&@>c,-3LU)77"U"Ac=IG$Wur-"Z3OWo<q!9
7R?.m7C]%9&m'5[/%;i<93-AS"R9.j2X%L21-@\-a$*DY%Z<c5ks4R5:qq/n!_&(bc?#$G17gA?ELa
o#dkEMbQON/AS,VSP"E$RH#:nQ^(mf@qr;jL3`/KV_UgEirCFE!1,bllad!N="L't2Mpr*J>K*=9`U
q3A7W1W)Sn:@k0/"&/$&u!+Zj==NEs>k9Hq8'\B8[*jiZfb_P!=C&6u2bQNc$kC")?she*"6S,g/,=
"r8,Y3@`STW#B1_j8t;GKdVaS7*6#4QlA_!DLE==&tY(qb:4"86]m;i<93S8kPNP<^;2oKEYH0jEB!
bbeW3a90.IR]lV5am5]FDH+SSiiF'G(lLo5NL9"8)<J)W`(/`OV6+ebaVG3[XJ;(fsiY''B#2$CJ#7
in/k;dH?'X1\d>b4]WXm%dHF>5ZM'ZLL\MO,r4$<SF4Ee$T1CYJFFEJ;S.YM:jFZ?(bKB,@em*<_`d
iEBk1XtJO:mPei_0f=6nWueM01M0kpbhQ?L/4BPs1fTu+D&S:u0"kfaWE8MTe(KA/I;A"+lQ$%o1l$
ssiTf4sQ%9U7&mU)k_^o-"U^:FQU]=dM9t9mTJnmqLaX)FT^%976arYrr)7tD^QGA$i$<LEom]Z='G
6pK..#EkK"k\d%1K+L^PNG[r*3L_hV^;OO(BGJ%,(&g]VsQTZ6\5@TlVPuWg#_O;(ggN7c(+9<0h'(
#9`Ri++_5Y5/M/PK\G+]=Dp7b<_7-#C$eV3\"IKAECNb&0>q`DF2kdaGRX"BmCX3eI.P:p8$qnh)Re
E5$]pk=B+!eZk4X(=M-Vp.nODopH^lAFnT)*iX("#3XUL@Q*@:5\M"n`MG2*Ve\rOfM?fp2NV(RB)V
hh7>e=@\O0"*R0I!-ZM<X1AmJ-"UWos5&+c4`lnho&St<^1ZVS$Y"YH;CAS^O#O4kZ=k+]2M6aD0`s
=Lp?_Y5/\mB-F9m07*%H]\2/2Vl8&/]4=5LiMHOdd_=>Fg=l.pZgn,HqG12>Bn=.?LoW2L#1"V([:3
Oh\J3NnG7ar>[UHgo@A,UH]^?a6=)\ADmW8J>Ft#2&9&F6\6>?s`9E.=ai*.QS<IMaPRjhdd8/j`#7
Vp&0m%5IP5/2.se,?*gc>YQ8,:*<Ol-'<Wei%i(T$J`T,e<VE(i%OD9`h7r\b^L,<:Q74<Nj@Z[jnQ
<lL_Eorr:h3=LI*fOEr?A]i=!lj#r6nPQ]&)q&(DA/j6:k;t=;$!s$37d2+$KrqSD*RS+/f)I)*NH<
p3",Vn18(4ju"<p3\K"F]o'\hDP*uqN`\jd-VZqlZ=QT0f>Soo6O+_W:]9tHWuM@Gp6G)Os6,'t!@A
uSTElGo`W<<Ak0A,!$;+@/_KoVeHORL]TYo^AFPW_,I=WgSFgt=/%"Q"NN]V"9\^5cTeaB2&NbIt^@
hi"/MA!VS4aQbYIBU=BY2.!>hgIEs!4lKbK,7G.\t0)$X?1;k_AXRh.4'U7rE[YD[m^2pXO38sXR8q
`8-oJk0[r<&J..u3I9FWmPA0'Zap()!\JNX6E$Zc>_Kmje4B!_uG#%R<*"\4;DLIn%6f$)"5?NfSq]
Gn?Brs=0`Eg+u&Aif8#]i-q6C9D.@6JfK!5uL?:g.`art#$P9]&`Ah*h;D!!#SZ:.26O@"J
ASCII85End
End

// PNG: width= 330, height= 110
Picture pause_pict
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!$W!!!"3#R18/!+@M19E5%m!HV./63+16*9dG'!!Zn*7mm@W!<3'!TY7
7e!!!!*E(F,Q!!!J[!!!J[!CA3(GQ7^D#BWO370hHK$Nh^aj`XA;!!!<.8OPjDGhVQ@95%:-*lmg.^
%IDS(_`)M)BU[`Lpl=tnH!fFTgT-U%(ZfpNB7rY#eFtbj&/:e-LSaPFlNQM1Gjst$9DoH"$T8bd3p.
T2(#<*KVTZuB&OtLWp61e'sO_9ITCd@\`ZrjDq2&:Xh%N;KOSObRSOfY8m9XkALQsoc!MZWa<dJ)kG
'"cj1hj$llVCj,`P29OXWn#*7's>,*>PGPB/$ahRn-#6D;aEb#05=nTZ5rNUHF3$85_uGYV%1:DII:
qX31OVZR/61rj&[8Q%MfN_`>BKW32I2`<RkqYL&117=@Pfs^j-='+#%k2p95;Zth/gW-):BZ)Pq_-e
tIeC6ldMSS0.+@R\%X&lLUg9k]F6kK][_i?"qPQF*1+k-K'C&gMt!<Aet!/)6j64Eo#2#ncK!.[lJ!
(%+pT`tLM)?:=`!'mI`!20UI:]g\a%0-Yk!$KbkJ5?>5VuZml"os;p!"`lF5c=]+e;?UCfr&pQk'?u
K3i5l^O!>,GC1#l:+$V8:r.C_^[`D&5kInWol<!W&(.F".d)7"jF4=jMf[uQP3]aWjlW-/rps@J,kK
fc%91t2'*BQ_V;)!L)hn]$JAPGm@^C)FPQ"$Nc<*=8oO$%S")r2m^GpQ%NRcp&%d%XqCmi;:/Y\29'
?+FuEP-e`>%c+mL?a[;L`r"Z+GuG_(*K%nt\p*V7WiE(@jN%o?MfN+&3LUpPrP`JaYMtb4o*WH9ZM1
\Bn&BH/q??0Kl1l00Ou+jHTMqa`jYb':_hStfa$9S'q!mBjoB$M$7<sVk,(<IijDQi_:JLc9G`5=E;
p!p]Lu7:W([0r%P;BY<3HI[;B[g_qldr?+cCI%hD&XQ=='&H>`C62Lg>p"(DGMU.Q/`:`YOe8-,nn&
U2)`Ye%M%dDN>j[^a'pdro^iu[EUMVmN8)[M4\L?'VP,p@n#WF`M5ahjpAZH)BkI(D@H-:cMfP?3[C
pP<K#%hTUJ$q+ASg]"mF@t%O!ld+/(C(gJ'QSH14IhtN*LcNB?8OLWHdU[[;2Af5'ZSTJR6'<RC3"Y
eZ0B%jV;OP`;akdVipd[a)LA)2@$Pbo"D8'%1a!8ace)4pV2(LDF*YTab<nJESi(HSgp;Vre>MU*E=
Tb[%KF@ftbCR"pP9Pp:5VKG0]ec[r)qf5>Z["Q?'V65FqBb!q4jk"jV[8ViHK)EI6$5YHL_8',)'!A
JAl3X"6h_;U7J5jYI-RE]^Zcl-nDAS,4K^S^u8f*$:D>W$UQ$"q3ic\Yln#4p-t24::ZOqsV99e7W<
&6uUtsSX"JNOpEqc)4$L@#c0g_D:9-dk<_A(5BhUnkjRudg@jmd1S]59N<,8CW20rU`c9j]C@a1sV@
=!F?hbV#7Q!%\Q*JU+CJ_3A^S]X3QV]1pOA*R7F=uVr9#JQ7O27kuYDi06m0Alkl).sgV2%4AH'o'9
YFr1,>[(ki![SXtdZe1=9mURG1)HgINK"hKbB?Isq"VAHrhH6`'H:V(qO'7S4t3&nf&gNr]WYDj\8S
fPMoEnh_)RkDPA-9)9$Qj^P:Ma=K/(WG+:k>6.jR]C7&$?b-7:/i36Gg/(+[S=^,;P^pnO2)f5.(N!
[SXtQ8PQkkPEb3QBh83BCeX;n?&71>.3CR-K;#Lb?W+q+:uW(IGVV^7f,\"&W2B"=fEidf[9/ic-'@
R,ZRiE)>=So63YUK$jJ.?b%7D]qIBkXD"BCuneDXII_htaX=S%]#F+(;c)rt:nb*#[D-lAA[$mF%UO
Llk1Fjq)N:sHXk1H>#6Hur4"0'jMS!U[IJ#LoJeRdNB?XH$uo)L)@;DS`W*31XFE!9i7(T&ch\Bq0]
[QeMCqT"Uj_[e0pQ'tu/a_)/U%A):Nq;0GOHt6H4I;6TM"^0^r.l7rkOpa-M!SP1UmZHR7lDa12SbF
_!/Dc?2f<Su2>l-'X]!S./-#*2GjV/YF&o*SW^*`RnmpG4V/Y>$Wdu"kj$L1Pm=fI,[pQ]i!'?:>h'
Pb)6rDbm[.%,c5.fh:s<`%&cbls*coD)Y3!(n`jr;Q.j:*%*5AS;$bbd)"pqn=Ro%V3"ch7A48\@&M
F\WVkh;.c_uJNr6+,aW\<5!FTR0N27_?-`2g,cRW:V4dOA)`LZ.PZas\=3.]1k6S.)K2?@*Z'(S0T7
7$*!09$Tg6B"ITqT:[oJUXEm!3uO,XY;3'aS^#g):7)\W2cPcb$IX1:pV)D/Glu5$54-Q'Nt(;U?7G
M1qB4%0%p&.W2Y1h\,ZFk?B.&Is#(-_b>E(]DVZP58pbQpMQ`\G4""KEVoV*l]!Rp!(n`j!l8`ZI>p
%kLFW!9O--EFm;'qV$A?$[RMp&#^4"#pg=f`j<E;U[7par$Oq0EQ!JN%QqYUQP%17g6+7u7GL[6\.>
nF16M2Q7a_9o#JB5BYOk`G?'TP`>c6//hrro-g]?*4)&pJY=]BrFT1<W)X^]eR]fB[6Nnai`Y=IOh?
Wo=I6dBOi78VGP6m*;NaAA]kkVh)i:_?FtB_%N[a"f,1'LSY,ipdHT,XNIO>/aM_H`2pp(/q;"Y:rC
9'OEnLY(J!t@)"+O?_br)>\I0tZ,.`p\kc][_aDUm:fBkV0N-Vg2Q4-8$p=ej0,0<;Fc;f-Agg:(uB
77FbBg:Ngl#]2/08a9OF.1hVG0Gr<=;l9s@UU@L0Xf\]>'Apgo-NF]m!!kF^+OgCA:]g\a%0-Yk!/)
6j&8D21VuZml"os;p!(%+p#W2T)e,Y"q!rtXs!20SsKGjh%C&gMt!<AetJ5?=J64Eo#2#ncK!.[lJ5
c=]KdIU:gig*?;2)6pR+c8NA)Pm_9&o*IL5H\7uB[Jg$q"j"?\=H6giZBp-PtK"7)]KeI;]I@3)Z0$
m6m@cK\T;C?(_!:?bh)UK`J_9iA4[,$C8<+DAQ$r!ALMl*,t04L;0he`)$nB(DpZ>Vz8OZBBY!QNJ
ASCII85End
End

Function autoupdate_detector(s)
STRUCT WMBackgroundStruct &s
string status = ""
	if(currentacquisitionstatus(status)==2)
		getlatestdata()
	endif
	return 0
End

Menu "GraphMarquee"
       "-"
       "Sum in Graph Image ROI", Marquee_sumImageROI()
End

Function Marquee_sumImageROI()
	string axes = axislist("")
       GetMarquee/k $stringfromlist(0, axes), $stringfromlist(1, axes)
       if (V_flag == 0)
               return 0
       endif
       variable ii
       String imageNames = imageNameList(S_marqueeWin,";")
       String traceNames = tracenamelist(S_marqueeWin,";",5)

       for(ii=0 ; ii<itemsinlist(imageNames);ii+=1)
               Wave imageRef = imagenametowaveref(S_marqueewin,stringfromlist(ii,imagenames))
		  variable bottom, top
		  bottom = V_bottom
		  top = V_top
              if(V_bottom > V_top)
            		top = V_bottom
            		bottom = V_top
            	endif
               imagestats/M=1/GS={V_left,V_right,bottom,top} imageRef
               printf "IMAGE:\t%s\tsum in ROI =%g\r",stringfromlist(ii,imagenames),V_avg*V_npnts
       endfor
       for(ii=0 ; ii<itemsinlist(traceNames); ii+=1)
               Wave traceRef = traceNametoWaveref(S_marqueewin,stringfromlist(ii,traceNames))
               printf "TRACE:\t%s\tsum in Left-Right Region =%g\r",stringfromlist(ii,tracenames),sum(traceRef)
       endfor
End

Function sics_cmd_interest(cmd)
string cmd
	//send a sics command to sics
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	cmd += "\n"
	sockitsendmsg SOCK_interest,"\n"
	SOCKITsendmsg SOCK_interest,cmd
	//	SOCKITsendnrecv SOCK_interest,cmd
	//	print s_tcp
	//	print cmd
	if(V_flag)
		print "Error while sending SICScmd (sics)", cmd, time()
		return 1
	endif
	return 0
End

Function sics(cmd)
	string cmd
	//send a sics command to sics
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	cmd += "\n"
	sockitsendmsg SOCK_cmd,"\n"
	SOCKITsendmsg SOCK_cmd,cmd
	//	SOCKITsendnrecv SOCK_interest,cmd
	//	print s_tcp
	//	print cmd
	if(V_flag)
		print "Error while sending SICScmd (sics)"
		return 1
	endif
	return 0
End

Function sics_cmd_cmd(cmd)
	string cmd
	//send a sics command to sics
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	cmd += "\n"
	sockitsendmsg SOCK_cmd,"\n"
	SOCKITsendmsg SOCK_cmd,cmd
	//	SOCKITsendnrecv SOCK_interest,cmd
	//	print s_tcp
	//	print cmd
	if(V_flag)
		print "Error while sending SICScmd (sics)"
		return 1
	endif
	return 0
End

Function/t sics_cmd_sync(cmd,[timer])
	string cmd
	variable timer
	//send a sics command to sics
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
	cmd += "\n"
	if(paramisdefault(timer))
		timer = 2.0
	endif
	SOCKITsendnrecv/SMAL/time=(timer) SOCK_sync, cmd
	if(V_flag)
		print "Error while sending SICScmd (sics)"
		return ""
	endif
	return S_tcp
End

Function startRegularTasks(times)
	variable times
	//this function starts a background task that is called regularly (e.g. every three minutes)
	//the regularTasks procedure is called at this periodic rate
	CtrlNamedBackground regularTasks, period = 60*times, proc  = regularTasks
	CtrlNamedBackground regularTasks, start
End

Function stopRegularTasks()
	//this function stops the regular background task. (see startRegularTasks())
	CtrlNamedBackground regularTasks, stop
End

Function checkDrive(motor,desiredPosition)
	string motor
	variable desiredPosition
	NVAR sock_cmd = root:packages:platypus:SICS:SOCK_cmd
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	Wave/t axeslist = root:packages:platypus:SICS:axeslist

	Findvalue/Text=motor axeslist

	variable col = floor(V_Value/dimsize(axeslist,0))
	variable row = V_Value-col*dimsize(axeslist,0)
	variable lowlim,upperlim
	string cmd,msg
	
	if(V_Value == -1)
		print "motor not found (checkDrive)"
		return 1
	endif
	
	lowlim = str2num(axeslist[row][4])
	upperlim = str2num(axeslist[row][6])
	if(!numtype(lowlim) && (!numtype(upperlim)))
		if((lowlim!=upperlim) && (desiredPosition< lowlim || desiredPosition > upperlim))
			print "requested drive is outside limits (checkdrive)"
			return 1			
		endif
		if(numtype(desiredPosition))
			print "you tried to send NaN/Inf to the motor (checkdrive)"
			return 1				
		endif
		if(desiredPosition > lowlim  && desiredPosition < upperlim)
		else
			print "requested drive is outside limits (checkdrive)"
			return 1
		endif
	endif
	return 0
End

Function run(motor,desiredPosition)
	string motor
	variable desiredPosition
	//run motor to desired position
	//returns 1 if motion not possible
	//returns 0 if motion possible and attempts to drive motor
	string cmd
	NVAR sock_cmd = root:packages:platypus:SICS:SOCK_cmd
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	
	if(checkDrive(motor,desiredPosition))
		print "move not allowed (run)"
		return 1
	endif
	
	cmd = "run "+ motor + " "+ num2str(desiredPosition) + "\n"
	if(sics_cmd_interest(cmd))
		print "Error while driving "+motor + " (run)"
		return 1
	endif	
		
	return 0
End

Function drive(motor,desiredPosition)
	string motor
	variable desiredPosition
	//drive motor to desired position
	//returns 1 if motion not possible
	//returns 0 if motion possible and attempts to drive motor
	string cmd
	NVAR sock_cmd = root:packages:platypus:SICS:SOCK_cmd
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	
	if(checkDrive(motor,desiredPosition))
		print "move not allowed (drive)"
		return 1
	endif
	
	cmd = "drive "+ motor + " "+ num2str(desiredPosition) + "\n"
	if(sics_cmd_cmd(cmd))
		print "Error while driving "+motor + " (run)"
		return 1
	endif	
	return 0
End

function rel(motor, pos)
	string motor
	variable pos
	// a command to do a relative motion of a motor
	variable currentpos, desiredpos
	
	currentpos = getpos(motor)
	if(numtype(currentpos))
		print "ERROR: motor position cannot be determined (rel)"
		return 1
	endif
	
	desiredpos = currentpos + pos
	if(checkDrive(motor, desiredpos))
		print "ERROR: motor position cannot be drived to that value (rel)"
		return 1
	endif
	if(run(motor, desiredpos))
		print "ERROR while moving relatively (rel)"
		return 1
	endif
	return 0
End

Function getPos(motor)
	string motor
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	string lhs,rhs
	Wave/t axeslist = root:packages:platypus:SICS:axeslist

	findvalue/TEXT=motor/TXOP=4/z axeslist
	
	if(V_Value>-1)
		return str2num(axeslist[V_Value][2])
	else
		return NaN
	endif
ENd

Function setpos(motor,newpos, [oldpos])
	string motor
	variable newpos, oldpos
	//setpos changes the offset for an axis
	//if oldpos is not specified then setpos changes the current position for axis "motor" to newpos.
	//if oldpos is specified then setpos will make an offset such that what was oldpos is now newpos
	//
	//e.g. setpos("sphi",2)
	//sets the current position of sphi to 2
	//e.g. setpos("sphi,2,oldpos=1)
	//makes an offset of -1 to sphi, such that 1 is now 2.
	
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	
	Findvalue/Text=motor axeslist
	variable col = floor(v_value/dimsize(axeslist,0))
	variable row = v_value-col*dimsize(axeslist,0)
	string cmd
	
	if(v_value == -1)
		print "motor not found (setpos)"
		return 1
	endif
	if(numtype(newpos))
		print "newpos isn't a proper number (setpos)"
		return 1
	endif
	if(paramisdefault(oldpos))
		cmd = "setpos "+ motor+ " "+ num2str(newpos)+"\n"
	else
		if(numtype(oldpos))
			print "oldpos isn't a proper number (setpos)"
			return 1
		endif
		cmd = "setpos " +motor + " " + num2str(oldpos) + " "+num2str(newpos)+"\n"	
	endif
	
	if(sics_cmd_interest(cmd))
		print "Error while setting position (setpos)"
		return 1
	endif
End

Function samplename(samplename)
	string samplename
	//sets the sample name that is saved in the sics file
	//e.g. samplename("Joe Bloggs")
	string cmd = "samplename "+samplename
	if(sics_cmd_cmd(cmd))
		print "Error while setting samplename (samplename)"
		return 1
	endif
End

Function user(username)
	string username
	//sets the username
	//e.g. user("Joe Bloggs")
	string cmd = "user "+username
	if(sics_cmd_cmd(cmd))
		print "Error while setting username (username)"
		return 1
	endif
End

Function emailupdate(user,password,to,subject,body)
	string user, password, to,subject,body

	String unixCmd, igorCmd, sendPypath
		
	sendpypath = functionpath("emailupdate")
		
	if( stringmatch("Macintosh", igorinfo(2)))
		#if (itemsinlist(functionlist("HFStoPOSIX",";","")))
		sendPyPath = Parsefilepath(1,sendPyPath,":",1,0)
//		sendPyPath = HFSToPosix("",sendPyPath,1,0)+"sendmsg.py"
		
		sprintf unixCmd,"python %s '%s' '%s' %s '%s' '%s'",sendPyPath, user, password, to, subject,body
		sprintf igorCmd, "do shell script \"%s\"", unixCmd
		ExecuteScriptText/z igorCmd
		#else
		print "ERROR: can't send update without HFStoPOSIX xop"
		#endif
	else
		sendPyPath = Parsefilepath(5,sendPyPath,"\\",0,0)
		sendPyPath = Parsefilepath(1,sendPyPath,"\\",1,0) +"sendmsg.py"

		sprintf unixCmd,"python %s '%s' '%s' %s '%s' '%s'",sendPyPath, user, password, to, subject,body
		sprintf igorCmd, "%s", unixCmd
		ExecuteScriptText/b/z igorCmd
	endif
End

Function acquire(presettype,preset, samplename, [points])
	string presettype
	variable preset
	string samplename
	variable points

	//starts the detector running, and will save the data that comes off
	//presettype is either "TIME" or "MONITOR_1"
	//preset is therefore either in seconds or monitor counts
	//samplename changes the samplename for the run
	//points will measure several different spectra, putting each one into the same NeXUS file
	//
	//example:
	//acquire("TIME",1,"mysample",points=2)
	//
	//does two acquisitions, each of 1 second each, with the sample title set as "mysample"
	if(paramisDefault(points))
		points = 1
	endif
	if(fpx("_none_",0,points,presettype=presettype,preset=preset,samplename=samplename, auto = 2))
		print "error while acquiring data (acquire)2"
		return 1
	endif
End

Function pauseAcquire(pauseORrestart)
	variable pauseORrestart
	//pause (pauseORrestart=1)
	//restart the scan (pauseORrestart=0)

	pausefpx(pauseORrestart)	
End

Function acquireStop()
	//stop the fpx scan running
	fpxstop()
End

Function acquireStatus()
	//returns the status of the scan
	//0 = not running
	//1 = running
	//2 = paused
	fpxStatus()
End

Function/t getSoftZeroList()
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	//this functions returns a string with all the softzeroes of all the motors that SICS can control
	//this is good for when one want to back up the alignments that you've done
	//it's format is:
	//   "bz:0.000000;m1ro:0.023456645;..................", i.e. key value pairs are separated by semicolons, keys are separated
	//from value by colons.
	
	variable V_Flag = 0,err
	variable numitems = 0,ii,offset,number
	string output ="",cmd,motors=""
	string str1,str2

	//get list of motors
	SOCKITsendnrecv/Time=0.5 SOCK_interest,"sicslist type motor\n"
	output = replacestring("\n",S_tcp,"")
	output = removeending(output," ")
	output = replacestring(" ",output,";")
	
	//now get posn of slits.
	cmd = ""
	for(ii=0; ii<itemsinlist(output);ii+=1)
		cmd +=stringfromlist(ii,output)+" softzero\n"
	endfor

		sockitsendnrecv/Time=0.5/SMAL SOCK_interest,"\n"
		SOCKITsendnrecv/Time=1 SOCK_interest, cmd, motors
	
	motors = replacestring(".softzero = ",motors,":")
	motors = replacestring("\n",motors,";")
	
	return motors
End

Function setSoftZeroList(softzeropos)
	string softzeropos
	//this function sets SICS up with the softzeros contained in the softzeropos string.  This string is typically obtained from getSoftZeroList().
	//it is good for when you want to restore the alignments to a previously obtained setting.
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest

	variable ii
	string cmd=""
	for(ii=0 ; ii<itemsinlist(softzeropos) ; ii+=1)
		cmd = replacestring(";", softzeropos, "\n")
		cmd = replacestring(":", cmd, " softzero ")
	endfor
	sockitsendmsg SOCK_interest, cmd
End

Function getCurrentHipaVals()
Wave/t  hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
NVAR  SOCK_interest = root:packages:platypus:SICS:SOCK_interest
string cmd=""

variable ii = 0;
for(ii=0; ii<dimsize(hipadaba_paths,0) ; ii+=1)
	cmd = "hget "+hipadaba_paths[ii][0]+"\n"
	sockitsendmsg SOCK_interest, cmd
endfor

End

Function email(to, msg)
       string to, msg
       string mailServer = "smtp.nbi.ansto.gov.au"
       string theEmail = ""
       variable sock           //holds the SOCKIT reference
       make/t/o buf                      //holds the output from the SOCKIT connection

       sockitopenconnection/q sock, mailServer, 25, buf

       theEmail = "HELO smtp.nbi.ansto.gov.au\n"               //say HELO to the server
       theEmail += "MAIL FROM: platypus@nbi.ansto.gov.au\n" //say who you are
       theEmail += "RCPT TO:" + to + "\n" //say who the recipient is
       theEmail +=  "DATA\n"           //start the message
       theEmail +=  "Subject:Platypus Update [SEC=UNCLASSIFIED]\n\n"           //subject line, note double newline is required
       theEmail += msg + "\n"  //the message
       theEmail += ".\n" //finish the message

       sockitsendmsg sock, theEmail

       sockitcloseconnection(sock)     //close the SOCKIT connection
End

Function pla_socket_info()

	sockitlist
	Wave W_sockitlist
	variable ii
	for(ii = 0 ; ii < numpnts(W_sockitlist) ; ii+=1)
		print sockitinfo(W_sockitlist[ii])
	endfor

End

Function/t Pla_getReactorInfo()
	variable sock
	make/t/free buf
	string post = "", soapxml = "", URL = "", cmd = "", result = "", infostring = "", serverService = ""
	variable fileID

	URL = "/WebServices/WebServiceAppServiceSoapHttpPort"
	serverService = "http://au/gov/ansto/bragg/web/model/webService/server/webservice/WebServiceAppServer.wsdl"
	soapxml="<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
	soapxml += "<soap:Body xmlns:ns1=\""+ serverService + "\">"
	soapxml += "<ns1:getReactorSimpleDisplayElement/></soap:Body></soap:Envelope>"

	cmd = "POST " + URL + " HTTP/1.1\r\n"
	cmd += "Host: neutron.ansto.gov.au:80\r\n"
	cmd += "Content-Type: text/xml\r\n"
	cmd += "Content-Length: " + num2istr(strlen(soapxml)) + "\r\n"
	cmd += "SOAPAction: http://au/gov/ansto/bragg/web/model/webService/server/webservice/WebServiceAppServer.wsdl/getReactorPower\r\n\r\n"
	cmd += soapxml + "\r\n"

	sockitopenconnection/q sock, "neutron.ansto.gov.au", 80, buf
	sockitsendnrecv/time=1/smal sock, cmd, result
	sockitcloseconnection(sock)
	if(V_Flag)
		print "Couldn't connect to database (getDatabaseInfo)"
		return ""
	endif
	//strip off http headers to leave the XMLfile
	result = result[strsearch(result, "<?xml", 0), strlen(result)-1]

	//write the file to disc
	open fileID as SpecialDirpath("Temporary", 0, 1, 0) + "reactorStatus.xml"
	if(V_flag)
		print "Couldn't open temporary file"
		return ""
	endif
	fbinwrite fileID, result
	close fileID

	//parse the file as an XML file
	fileID = XMLopenfile(S_filename)
	if(fileID< 2)
		print "couldn't open XML status file", date(), time()
		return ""
	endif
	infostring = xmlstrfmxpath(fileID, "//ns0:getReactorSimpleDisplayResponseElement", "ns0=" + serverService,"")
	infoString = replacestring("; ", infostring, ";")

	xmlclosefile(fileID, 0)
	return infoString
End

Function/t Pla_getExperimentInfo(instrument)
	string instrument
	variable sock
	make/t/free buf
	string post = "", soapxml = "", URL = "", cmd = "", result = "", infostring = "", serverService = "", retStr=""
	variable fileID

	URL = "/WebServices/WebServiceAppServiceSoapHttpPort"
	serverService = "http://au/gov/ansto/bragg/web/model/webService/server/webservice/WebServiceAppServer.wsdl"
	soapxml="<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
	soapxml += "<soap:Body xmlns:ns1=\""+ serverService + "\">"
	soapxml += "<ns1:getInfoDisplayElement/></soap:Body></soap:Envelope>"

	cmd = "POST " + URL + " HTTP/1.1\r\n"
	cmd += "Host: neutron.ansto.gov.au:80\r\n"
	cmd += "Content-Type: text/xml\r\n"
	cmd += "Content-Length: " + num2istr(strlen(soapxml)) + "\r\n"
	cmd += "SOAPAction: http://au/gov/ansto/bragg/web/model/webService/server/webservice/WebServiceAppServer.wsdl/getReactorPower\r\n\r\n"
	cmd += soapxml + "\r\n"

	sockitopenconnection/q sock, "neutron.ansto.gov.au", 80, buf
	sockitsendnrecv/time=0.5 sock, cmd, result
	sockitcloseconnection(sock)
	if(V_Flag)
		print "Couldn't connect to database (Pla_getExperimentInfo)"
		return ""
	endif
	//strip off http headers to leave the XMLfile
	result = result[strsearch(result, "<?xml", 0), strlen(result)-1]

	//write the file to disc
	open fileID as SpecialDirpath("Temporary", 0, 1, 0) + "experimentStatus.xml"
	if(V_flag)
		print "Couldn't open temporary file"
		return ""
	endif
	fbinwrite fileID, result
	close fileID

	//parse the file as an XML file
	fileID = XMLopenfile(S_filename)
	if(fileID< 2)
		print "couldn't open XML status file", date(), time()
		return ""
	endif
	infostring = xmlstrfmxpath(fileID, "//ns1:expArray[ns1:instrName='"+ instrument+"']/ns1:proposalCode", "ns1=http://webservice.server.webService.model.web.bragg.ansto.gov.au/types/","")
	retStr = replaceStringbykey("proposalCode",retStr,infostring)
	infostring = xmlstrfmxpath(fileID, "//ns1:expArray[ns1:instrName='"+ instrument+"']/ns1:principalSci", "ns1=http://webservice.server.webService.model.web.bragg.ansto.gov.au/types/","")
	retStr = replaceStringbykey("principalSci",retStr,infostring)
	infostring = xmlstrfmxpath(fileID, "//ns1:expArray[ns1:instrName='"+ instrument+"']/ns1:localSci", "ns1=http://webservice.server.webService.model.web.bragg.ansto.gov.au/types/","")
	retStr = replaceStringbykey("localSci",retStr,infostring)
	infostring = xmlstrfmxpath(fileID, "//ns1:expArray[ns1:instrName='"+ instrument+"']/ns1:exptTitle", "ns1=http://webservice.server.webService.model.web.bragg.ansto.gov.au/types/","")
	retStr = replaceStringbykey("exptTitle",retStr,infostring)

	xmlclosefile(fileID, 0)
	return retStr
End
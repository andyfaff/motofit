#pragma rtGlobals=1		// Use modern global access presettype.
#PRAGMA modulename = platypus

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

STATIC CONSTANT SAWDEVICE = 0		//only set to one if you have more than one entry in the BAT TABLE
										//typically when operating WHA SAW device.

Function/c findthecentre(position,tempY,tempE)
	Wave position,tempY,tempE
	variable/c centre
	//finds the centroid/gauss centre of a distribution
	variable centroid = Pla_peakCentroid(position,tempY)
	centre = cmplx(centroid,centroid)
	
	variable V_fiterror = 0
	//can easily change to lorentzian
	try
		curvefit/n/q/w=0 gauss tempy /X=position/W=tempE/I=1; ABORTONRTE
	catch
		Variable CFerror = GetRTError(1)	// 1 to clear the error
	endtry
	if(V_fiterror || V_abortcode)
		print "error while fitting gaussian (findthecentre)"	
	else 
		Wave W_coef
		centre = cmplx(W_Coef[2],centroid)
		print "Gauss centre at: "+num2str(W_Coef[2])
	endif
	
	print "Centroid at: "+num2str(centroid)
		
	killwaves/z tempY,W_Coef,tempE
	return centre
End

Function fpxStop()
	//stop the fpx scan running
	CtrlNamedBackground  scanTask status
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	if(numberbykey("RUN",S_info))	//if the scan is running, stop it, and finish
		CtrlNamedBackground  scanTask kill = 1
		sockitsendmsg SOCK_interupt, "INT1712 2\n"
		finishscan(1)
		sics_cmd_interest("statemon stop FPX")
	endif
End

Function pausefpx(pauseORrestart)
	variable pauseORrestart
	//pause (pauseORrestart=1)
	//restart the scan (pauseORrestart=0)
	NVAR userPaused = root:packages:platypus:data:scan:userPaused
	userPaused = pauseOrRestart
	
	string histostatus = Ind_Process#grabHistostatus("DAQ")
	CtrlNamedBackground  scanTask status
	if(numberbykey("RUN",S_info))	//if the scan is running
		pauseDetector(pauseORrestart)
	endif
End

Function fpxStatus()
	//returns the status of the scan
	//0 = not running
	//bitwise return
	//1 = paused
	//2 = bkdtask
	//3 = fpxstatemon
	//4 = runscanstatus - /commands/scan/runscan/feedback/status
	//5 = hmcontrol
	//FPX is a statemon addition, because sometimes it takes a while for the runscan status to change.
	//use this as a guard to say the scan has started, but we're still waiting for the status to change to BUSY
	//once it's done this you can remove it.
	
	NVAR/z userPaused = root:packages:platypus:data:scan:userPaused
	ctrlnamedbackground scanTask,status
	variable running = 0
	
	variable bkdtask = numberbykey("RUN",S_info)
	if(numberbykey("RUN",S_info))
		running = running | 2^2
	endif	
	if(statemonstatus("FPX"))
		running = running | 2^3
	endif	
	if(stringmatch(gethipaval("/commands/scan/runscan/feedback/status"), "BUSY"))
		running = running | 2^4
	endif
	if(statemonstatus("hmcontrol"))
		running = running | 2^5
	endif
	if(running)
		if(userPaused)
			running = running | 2^1
		endif
	endif
	return running
End

Function fpx(motorName,rangeVal, numpoints, [mode ,preset, savetype, samplename, automatic])
	string motorName
	variable rangeVal, numpoints
	string mode
	variable preset, savetype
	string samplename
	variable automatic
	//performs a range scan for the motor specified by motorStr, over rangeVal distance, with points points
	//motorStr		-	self explanatory, but set to "dummy_motor" if you don't want to scan a motor
	//points			-	the number of scan points >=0
	//mode			-	time, unlimited, period, count, frame, MONITOR_1, MONITOR_2
	//preset			-	the number of seconds for the scan >0
	//saveOrNot		-	saves the results in a file if saveOrNot=0 (default), if saveOrNot=1, then don't save
	//sampleTitle		-	if the results are going to be saved, then this will be the sample title
	//automatic		-	automatic=0 - ask for user interaction
	//					automatic=1 - no user interaction, automatically go to the peak
	//					automatic=2 - no user interaction, do not go to the peak
	//
	//e.g. fpx("sphi",0.5,11,presettype="time",preset=5)
	//sics command is:
	//runscan scan_variable start stop numpoints time||unlimited||period||count||frame||MONITOR_1||MONITOR_2 savetype save||nosave force true||false
	
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
	NVAR/z	Grange =  root:packages:platypus:SICS:range
	NVAR/z Gpreset = root:packages:platypus:SICS:preset
	NVAR/z Gnumpoints = root:packages:platypus:SICS:numpoints
	//		for sending sics commands that will be displayed
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	//		for sending an emergency stop command
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	//		for sending commands that won't be displayed, but to also get current axis information as it changes.
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	//		a string that is send on SOCK_cmd channel for user commands
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
	SVAR user = root:packages:platypus:SICS:user
	SVAR Gsicsstatus = root:packages:platypus:SICS:sicsstatus
	Wave/t statemon = root:packages:platypus:SICS:statemon
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	NVAR motoraxisrow = root:packages:platypus:data:scan:motoraxisrow
	Wave position = root:packages:platypus:data:scan:position
	Wave counts = root:packages:platypus:data:scan:counts
	NVAR currentpoint = root:packages:platypus:data:scan:currentpoint
	NVAR initialposition =  root:packages:platypus:data:scan:initialPosition
	NVAR motorprecision = root:packages:platypus:data:scan:motorprecision	
	NVAR pointProgress = root:packages:platypus:data:scan:pointProgress
	NVAR userPaused = root:packages:platypus:data:scan:userPaused
	NVAR auto = root:packages:platypus:data:scan:auto				//says whether you are going to autofit and drive to the centre

	string msg = "", saveStr
	string supportedScanTypes = "time||unlimited||period||count||frame||MONITOR_1||MONITOR_2"
	variable start, stop
	DFref cDF
	variable col, row

	cDF = getdatafolderdfr()
	
	if(!stringmatch(user, "manager"))
		print "you are not logged in as the correct user to start a scan"
	endif
	
	if(paramisDefault(automatic))
		automatic = 0
	endif
	
	if(paramisDefault(mode))
		mode = "time"
	endif
	if(paramisDefault(preset))
		preset = 1
	endif
	if(paramisDefault(savetype))
		savetype = 0
	endif
	if(paramisDefault(samplename))
		samplename = ""
	endif
	if(!saveType)
		saveStr = "save"
	else
		saveStr = "nosave"
	endif
	
	//set the display variable to those sent to the function
	Grange = rangeVal
	Gpreset = preset
	Gnumpoints = numpoints
	
	Dowindow/k fpxScan
	
	if( fpxStatus() || statemonstatus("FPX"))	//if the scan is running we can't continue
		print "scan is already running (fpx)", time()
		return 1
	endif
	if(numpnts(statemon)>0)
		print "The SICS statemon isn't cleared, may need to clear it? (fpx)"
		print statemon
		return 1
	endif
	//check the histogram
	if(currentacquisitionstatus(msg) == 2 || currentacquisitionstatus(msg) == 3 || statemonstatus("hmcontrol"))
		Print "you are currently acquiring data, or the histogram server is doing something (fpx)"
		return 1
	endif
	if(!stringmatch(Gsicsstatus, "Eager to execute commands"))
		Print "ERROR - SICS is: "+Gsicsstatus + " (fpx)", time()
		return 1
	endif
	
	//if the tertiary shutter is closed, it might be a good idea to open it.
	if(!stringmatch(gethipaval("/instrument/status/tertiary"), "*OPEN*"))
		print "WARNING, tertiary Shutter appears to be closed, you may not see any neutrons (fpx)"
		//if auto is set, then its probably an automatic scan, so don't ask if you want to stop
		//if auto is NOT set, then you probably want to open the shutter, so ask if you want to continue.
		if(!automatic)	
			doalert 1, "Warning, the tertiary shutter appears closed, do you want to continue? (Scan will start when you press yes)"
			if(V_Flag==2)
				print "Stopping because the tertiary shutter was closed (fpx)"
				return 1
			endif
		endif
	endif
		
	//first have to check if motor exists
	findvalue/text=motorName/Z axeslist
	if(V_Value == -1)
		Print "Error: The" + motorName + " motor is not in the current motor list. (fpx)"
		return 1
	else 
		col=floor(V_Value / dimsize(axeslist, 0))
		row=V_Value - col*dimsize(axeslist, 0)
		motoraxisrow = row
	endif

	//rangeval has to be greater than or equal to 0
	if(rangeval < 0)
		Print "range must be >= 0 (fpx)"
		return 1
	endif

	//number of points has to be greater than or equal to 1
	numpoints = round (numpoints)
	if(numpoints < 1)
		Print "you must have at least 1 point (fpx)"
		return 1
	endif

	//now check upper and lower limits, but not for virtual motors.
	if(!numtype(str2num(axeslist[row][4])) && !numtype(str2num(axeslist[row][6])) )
		if( (str2num(axeslist[row][2]) - rangeval / 2) < str2num(axeslist[row][4]) || (str2num(axeslist[row][2]) + rangeval / 2) > str2num(axeslist[row][6]))
			Print "scan range will exceed limits of motor (fpx)"
			return 1
		endif
	endif
	start = str2num(axeslist[row][2]) - rangeval / 2
	stop = str2num(axeslist[row][2]) + rangeval / 2
	
	//change the samplename
	if(!paramisDefault(samplename))
		sics_cmd_interest("samplename " + samplename)
	endif
	
	//create the data structures
	//see fillScanStats() for column information
	redimension/n=(0) position
	redimension/n=(0, -1) counts
	counts = NaN
	position = NaN
	doupdate

	currentpoint = 0
	initialPosition = str2num(axeslist[row][2])
	pointprogress = 0
	userPaused = 0
	auto = automatic
	
//	//create the positions for the scan
//	if(numpoints == 1)
//		position[] = initialposition
//	else
//		position[] = rangeVal*(p/(numpoints - 1)) + str2num(axeslist[row][2]) - rangeval/2
//	endif

	//append counts to scan graph
	//this is done by the counttypeVSpos_popupcontrol function
	controlinfo/w=sicscmdpanel counttypeVSpos_tab1
	STRUCT WMPopupAction PU_Struct
	PU_Struct.popstr = S_value
	counttypeVSpos_popupcontrol(PU_Struct)
		
//	if(SAWDEVICE)
//		if(sics_cmd_interest("\nhmm configure read_data_period_number 0\nsave 0\nhmm configure read_data_period_number 1\nsave 1\n"))//+num2str(currentpoint)))
//			print "problem while autosaving (fpx)"
//		endif
//	else
//		if(sics_cmd_interest("save 0"))
//			print "ERROR whilst speaking to SICS (fpx)3"
//			return 1
//		endif
//	endif
	
	print "Beginning scan"
	//start the scan task
	appendstatemon("FPX")
		
	//create the SICS command to start the scan
	//runscan scan_variable start stop numpoints time||unlimited||period||count||frame||MONITOR_1||MONITOR_2 savetype save||nosave force true||false
	string cmdTemplate, cmd
	cmdTemplate = "autosave 30\nrunscan %s %e %e %d %s %f savetype %s force true"
	sprintf cmd, cmdTemplate, motorName, start, stop, numpoints, mode, preset, saveStr
//	print cmd
	//send it to SICS, and tell it to autosave
	sics_cmd_cmd(cmd)
	
	//change the GUI look if you are acquiring
	changeGUIforfpx(mode, motorName, numpoints, preset)
	doupdate

	CtrlNamedBackground  scanTask period=60, proc=scanBkgTask, burst=0, dialogsOK =0
	CtrlNamedBackground  scanTask start
	
	return 0
End

Function changeGUIforfpx(mode, motorName, numpoints, preset)
	//changes the GUI look if you are acquiring
	string mode, motorName
	variable numpoints, preset
	Wave axeslist = root:packages:platypus:SICS:axeslist
	variable status = fpxstatus()
	variable currtab
	
	strswitch(mode)
		case "unlimited":
			ValDisplay/z progress_tab1,win=SICScmdpanel,limits={0, inf, 0}, value= #"root:packages:platypus:data:scan:pointProgress"
		break
		default:
			ValDisplay/z progress_tab1,win=SICScmdpanel,limits={0, numpoints * preset, 0}, value= #"root:packages:platypus:data:scan:pointProgress"
		break
	endswitch
	label/W=SICScmdPanel#G0_tab1/z bottom, motorName
	PopupMenu/z motor_tab1, win=SICScmdpanel, fSize=10, mode=1, popvalue = motorName, value = #"motorlist()"
	findvalue/TEXT=motorName/z/txop=4 root:packages:platypus:SICS:axeslist
	if(V_Value > 0)
		SetVariable currentpos_tab1, win=sicscmdpanel, limits={-inf,inf,0},value=root:packages:platypus:SICS:axeslist[V_Value][2]
	else
		SetVariable currentpos_tab1,win=sicscmdpanel, limits={-inf,inf,0},value=NaN
	endif
	
	//what tab are you on?
	controlinfo/W=sicscmdpanel sicstab
	currtab = V_Value
	if(currtab != 1)
		modifycontrollist Controlnamelist("sicscmdpanel", ";", "_tab1") disable = 1
		return 0
	endif
	
	if(status)
		Button/z Go_tab1 win=sicscmdpanel,disable = 3  	//if the scan starts disable the go button
		Button/z stop_tab1 win=sicscmdpanel,disable = 0		//if the scan starts enable the stop button
		Button/z pause_tab1 win=sicscmdpanel,disable = 0		//if the scan starts enable the pause button
		
		setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=2		//if the scan starts disable the title button
		setvariable/z preset_tab1 win=sicscmdpanel,disable=2
		PopupMenu/z mode_tab1 win=sicscmdpanel,disable=2	
		PopupMenu/z motor_tab1 win=sicscmdpanel,disable=2	
		setvariable/z numpnts_tab1 win=sicscmdpanel,disable=2
		setvariable/z range_tab1 win=sicscmdpanel,disable=2
		checkbox/z save_tab1 win=sicscmdpanel,disable=2	
		if(status & 2^1)
			Button/z Pause_tab1,win=sicscmdpanel, title="Restart"
		else
			Button/z Pause_tab1,win=sicscmdpanel, title="Pause"	
		endif
	else
		Button/z Go_tab1 win = sicscmdpanel, disable = 0		//if the scan starts disable the go button
		Button/z stop_tab1 win=sicscmdpanel, disable = 3		//if the scan starts enable the stop button
		Button/z pause_tab1 win = sicscmdpanel, disable = 3		//if the scan starts enable the pause button
		
		setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=0		//if the scan starts disable the title button
		setvariable/z preset_tab1 win=sicscmdpanel,disable=0
		PopupMenu/z mode_tab1 win=sicscmdpanel,disable=0	
		PopupMenu/z motor_tab1 win=sicscmdpanel,disable=0	
		setvariable/z numpnts_tab1 win=sicscmdpanel,disable=0
		setvariable/z range_tab1 win=sicscmdpanel,disable=0
		checkbox/z save_tab1 win=sicscmdpanel,disable=0
	endif
								
End

Function forceScanBkgTask()
Struct WMBackgroundStruct s
	if(fpxstatus() > 0)
		if(scanBkgTask(s))
			ctrlnamedbackground scantask, kill
		endif
	endif
End

Function scanBkgTask(s)
	STRUCT WMBackgroundStruct &s
	
	NVAR pointProgress = root:packages:platypus:data:scan:pointProgress
	NVAR currentpoint = root:packages:platypus:data:scan:currentpoint
	Wave position = root:packages:platypus:data:scan:position
	Wave counts = root:packages:platypus:data:scan:counts	
	
	variable scanpoint = str2num(getHipaval("/commands/scan/runscan/feedback/scanpoint"))
	variable numpoints = str2num(getHipaval("/commands/scan/runscan/numpoints"))
	variable timer = str2num(getHipaval("/instrument/detector/time"))
	variable preset = str2num(getHipaval("/instrument/detector/preset"))
	pointProgress =  scanpoint * preset

	//bitwise return
	//1 = paused
	//2 = bkdtask
	//3 = fpxstatemon
	//4 = runscanstatus - /commands/scan/runscan/feedback/status
	//5 = hmcontrol
	variable status = fpxstatus()
	
	if(status & 2^4)
		pointProgress += timer
	endif
	if(status & 2^3)
		pointProgress = 0
	endif
	
	
	//if you have moved to a new point then do a whole fill of the scanstats
	if(currentpoint != scanpoint) 
		fillScanStats(position, counts, 1)
		currentpoint = scanpoint
	else 
		fillScanStats(position, counts, 0)
	endif
	
	//if you have started running, and the FPX statemon is set, then you can clear that statemon	
	if((status & 2^4) && (status & 2^3))
		statemonclear("FPX")	
	endif
	
	//see if you've finished?
	if(!(status & 2^4) && !(status & 2^3))
		finishScan(0)
		return 1
	endif
	
	return 0
End

Function finishScan(status)
	//status describes whether runscan finished with errors (status=1)
	variable status
	
	string scanmotor = gethipaval("/commands/scan/runscan/scan_variable")
	NVAR initialPosition = root:packages:platypus:data:scan:initialPosition
	Wave position = root:packages:platypus:data:scan:position
	Wave counts = root:packages:platypus:data:scan:counts
	
	string/g root:fpxstackInfo = getrtstackinfo(3)+time()
	
	//		for sending sics commands that will be displayed
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	//		for sending an emergency stop command
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	//		for sending commands that won't be displayed, but to also get current axis information as it changes.
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	SVAR sicsstatus = root:packages:platypus:SICS:sicsstatus
	//whether you want to do an autopeakfit (=1), or manual (=0)
	NVAR auto = root:packages:platypus:data:scan:auto 
	//	do we want to save the data
	NVAR dontSave = root:packages:platypus:data:scan:dontSave	
	//	scan point that you are on
	NVAR currentpoint = root:packages:platypus:data:scan:currentpoint
	//     FIZscan number
	NVAR/z FIZscanFileNumber = root:packages:platypus:data:scan:FIZscanFileNumber

	NVAR userPaused = root:packages:platypus:data:scan:userPaused	//reset the pause status
	userPaused = 0

	variable err
	string var,whichStat
	variable num, offsetValue

	statemonclear("FPX")
	ctrlnamedbackground scanTask, kill=1
	
	//get the last stats updated
	fillScanStats(position, counts, 2)

	controlinfo/w=sicscmdpanel sicstab
	if(V_Value==1)
		Button/z Go_tab1 win=sicscmdpanel,disable=0	
		Button/z stop_tab1 win=sicscmdpanel,disable=1	
		Button Pause_tab1,win=sicscmdpanel,disable=1
		setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=0
		setvariable/z preset_tab1 win=sicscmdpanel,disable=0
		PopupMenu/z mode_tab1 win=sicscmdpanel,disable=0
		PopupMenu/z motor_tab1 win=sicscmdpanel,disable=0	
		setvariable/z numpnts_tab1 win=sicscmdpanel,disable=0
		setvariable/z range_tab1 win=sicscmdpanel,disable=0
		checkbox/z save_tab1 win=sicscmdpanel,disable=0	
	endif
	
	//tell the histogram server to stop acquiring if it's an abnormal stop
	if(status)
		do
			string reply = sics_cmd_sync("histmem stop", timer = 10)
		while(grepstring(reply, "ERROR: Busy"))
		print "Stopped scan for some reason (finishScan)"
	endif
	
	print "scan finished"

	//if you want to save, then we must save the data.
//	if(SAWDEVICE)
//		if(sics_cmd_interest("\nhmm configure read_data_period_number 0\nsave 0\nhmm configure read_data_period_number 1\nsave 1\n"))//+num2str(currentpoint)))
//			print "problem while autosaving (fpx)"
//		endif
//	endif

	//save the scan itself, not the overall data, just counts vs position
	Note/K position, "data:" + getHipaVal("/experiment/file_name") + ";DAQ:" + Ind_Process#grabhistostatus("DAQ_dirname")+";DATE:"+Secs2Date(DateTime,-1) + ";TIME:"+Secs2Time(DateTime,3)+";"
	string fname =  "FIZscan" + num2str(getFIZscanNumberAndIncrement()) + ".itx"
	save/o/t position, counts as PATH_TO_DATA + "FIZ:" + fname
	print "FPXscan (position vs counts) saved to ", PATH_TO_DATA + "FIZ:" + fname
	print "file saved as: ", gethipaval("/experiment/file_name")
	
	//display the scan in an easy to killgraph
	//here we are going to do the peak on counts, but we could do it on monitor, or any other statistic, by choosing a different column
	make/o/d/n=(numpnts(position)) tempY, tempE
	Wave tempY, tempE
	tempY = counts[p][0]
	tempE = counts[p][1]
		
	//the following waves are to put a vertical line on the fpxscangraph to mark the centroid/gauss centres.
	make/o/d/n=(3),root:packages:platypus:data:scan:tagcentroid,root:packages:platypus:data:scan:taggauss,root:packages:platypus:data:scan:tagyy
	Wave tagcentroid = root:packages:platypus:data:scan:tagcentroid
	Wave taggauss = root:packages:platypus:data:scan:taggauss
	Wave tagyy = root:packages:platypus:data:scan:tagyy				
	tagyy={-inf,inf}
	if(auto != 2)
		Dowindow/k fpxScan
		Display/k=1/N=fpxScan
		appendtograph/w=fpxScan counts[][0] vs position
		ModifyGraph/z/w=fpxScan mode(counts)=4
		ModifyGraph/z/w=fpxScan standoff(left)=0,standoff(bottom)=0
		ErrorBars/w=fpxScan counts Y,wave=(counts[*][1],counts[*][1])
		cursor/H=1/s=0/F/P A  counts 0.5,0.5
		showinfo

		appendtograph/w=fpxscan tagyy vs taggauss
		appendtograph/w=fpxscan tagyy vs tagcentroid
		ModifyGraph/w=fpxscan rgb(tagyy)=(0,0,0)
		ModifyGraph/w=fpxscan rgb(tagyy#1)=(0,0,52224)
	endif
					
	//find the centre
	variable/c centre
	centre = findthecentre(position,tempY,tempE)

	tagcentroid = {imag(centre),imag(centre)}
	taggauss = {real(centre),real(centre)}
	if(auto!=2)
		Tag/C/N=text0/TL=0 bottom, real(centre),"gauss"
		Tag/C/N=text1/TL={lineRGB=(0,0,65280)} bottom, imag(centre),"\\K(0,0,65280)centroid"
	endif
	doupdate
	
	if(numtype(initialposition))
		initialposition = str2num(gethipaval("/commands/scan/runscan/scan_start"))
		initialposition += str2num(gethipaval("/commands/scan/runscan/scan_stop"))
		initialposition *= 0.5
	endif		
	
	if(auto)	//if you are auto aligning
		if(status)	//if there was an error during the auto align
			print "there was an error during the auto align, returning to pre-scan position (finishScan)"
			run(scanmotor, initialPosition)
			return 1
		endif
		if(auto ==1)
			print "fpx alignment scan placing ", scanmotor," at: ", imag(centre)
			offsetvalue = imag(centre)
		elseif(auto==2)
			print "fpx scan of motor done, returning ", scanmotor, " to: ", initialposition
			offsetvalue = initialposition
		endif
		if(run(scanmotor, offsetvalue))
			print "error while driving (finishScan)"
			return 1
		endif
		sleep/q/S 2
	else		//no auto alignment, ask the user
		Prompt var,"which variable",popup,"counts;"
		Prompt whichStat,"which statistic",popup,"gaussian;centroid;graph cursors"
		Doprompt "Do you want to move to the peak centre?", var, whichstat			
		if(V_Flag==1)	//if you don't want to move to peak centre
			print "Scan finishing"
			if(run(scanmotor,initialPosition))
				print "Error while returning to original Pos (finishScan)"
			endif
		else		//if you want to move to peak centre
			strswitch(whichStat)
				case "gaussian":
					num = real(centre)
					break
				case "centroid":
					num = imag(centre)
					break
				case "graph cursors":
					//requires that Motofit is installed.
					UserCursorAdjustForCentre("fpxScan", "Adjust cursor to centre")
					//find out what cursor position is.
					for( ;strlen(csrInfo(A, "fpxScan")) == 0 ;)
						print "the cursor was taken off the graph, please put it back on and try again"
						UserCursorAdjustForCentre("fpxScan", "Adjust cursor to centre")
					endfor
					num = hcsr(A, "fpxScan")
	
					break
			endswitch
			
			offsetValue = num
			string helpStr = "If you do not wish to change the position of the peak press cancel"
			Prompt offsetValue, "new value for peak position"
			Doprompt/HELP=helpStr "Please enter the new value for the peak position (cancel=no change)", offsetValue

			if(!V_Flag)		//if you want to enter an offset
				print "Scan finishing, offset changed and driving to to peak position"
				print "setpos:", scanmotor, num, offsetvalue
				sockitsendmsg sock_cmd,"setpos " + scanmotor + " " + num2str(num)+ " "+ num2str(offsetvalue) +"\n"
				if(V_Flag)
					print "error while setting zero (finishScan)"
					return 1
				endif
				if( run(Scanmotor, offsetvalue) )
					print "error while driving (finishScan)"
					return 1
				endif
			else				//if you don't want to enter an offset
				print "Scan finishing, driving to peak position"
				err= run(scanmotor, num)
				if(err)
					print "Error while returning to new position (finishScan)"
				endif
			endif
		endif	
	endif
	//reset the progress bar
	ValDisplay/z progress_tab1, win=SICScmdpanel, limits={0,0,0}
	ctrlnamedbackground scanTask, kill=1
	return err
End

//grab the file number that you need to save the FIZscan to
Function getFIZscanNumberAndIncrement()
	variable fileID, fizscannumber = 0
	string theLine = ""
	open/z fileID as PATH_TO_DATA + "FIZ:fizscannumber"
	if(V_flag != 0)
		return -1
	endif
	fstatus fileID
	theLine = padString(theLine, V_logEOF, 0x20)
	freadline fileID, theLine

	fizscannumber = str2num(theLine)
	if(fizscannumber > 0)
		fizscannumber += 1
	endif

	fsetpos fileID, 0
	fprintf fileID, "%d", fizscannumber

	close fileID
	return fizscannumber
End

Function fillScanStats(position, w, full)
	wave position
	wave w			//where to put the stats
	variable full		//full is issued at the end, to get the correct numbers

	string histostatus
	variable times, fileID
	
	DFREF saveDFR = GetDataFolderDFR()
	DFref tempDF = newfreedatafolder()
	setdatafolder tempDF
			
	string datafilenameandpath = gethipaval("/experiment/file_name")
	string datafilename = parsefilepath(0, datafilenameandpath, "//", 1, 0)
	datafilenameandpath = PATH_TO_DATA + "current:" + datafilename
	Wave/t/z axeslist = root:packages:platypus:SICS:axeslist

	variable scanpoint = str2num(getHipaval("/commands/scan/runscan/feedback/scanpoint"))		
	redimension/n=(scanpoint + 1, -1) w, position
	
	switch(full)
		case 0:
			position[scanpoint] = str2num(getHipaval("/commands/scan/runscan/feedback/scan_variable_value"))
			//time
			times = str2num(gethipaval("/instrument/detector/time"))
			//counts
			w[scanpoint][0] = str2num(gethipaval("/instrument/detector/total_counts"))
			//max detector count rate
			w[scanpoint][3] =  str2num(gethipaval("/instrument/detector/max_binrate"))
	
			//BM1 monitor counts
			w[scanpoint][7] =  str2num(gethipaval("/monitor/bm1_counts"))
			w[scanpoint][9] =  str2num(gethipaval("/monitor/bm1_event_rate"))
		break
		case 1:
			position[scanpoint] = str2num(getHipaval("/commands/scan/runscan/feedback/scan_variable_value"))
//			string DAQname = PATH_TO_HSDATA + replacestring(" ", gethipaval("/instrument/detector/daq_dirname"), "") + ":DATASET_"+num2istr(scanpoint)+":EOS.bin"
//			neutronunpacker/z DAQname
//			if(V_flag)
//				setdatafolder saveDFR
//				return 0
//			endif
//			wave W_unpackedneutronsT
//			w[scanpoint][0] = numpnts(W_unpackedneutronsT)
//		break
		case 2:
			//at the end of a scan get the numbers from the histoserver, because SICS may not have issued them
	//		histostatus = grabAllHistoStatus()
	//		w[point][0] = numberbykey("num_events_filled_to_histo",histostatus,": ","\r")			
			//try getting the counts from the HDF file.
			CopyFile/D /O/Z datafilenameandpath as specialdirpath("Temporary", 0, 0, 0)
			hdf5openfile/z/R fileID as S_filename			
//			hdf5openfile/z/R fileID as datafilenameandpath
			if(!fileID)
				print "HAD ERROR OPENING HDFFILE"		
				setdatafolder saveDFR
				return 0
			endif
			
			//what is the scan variable?
			string scanvariable = gethipaval("/commands/scan/runscan/scan_variable")
			
			//see if the scan variable is in the axeslist (should be first column)
			FindValue/Z/text=(scanvariable)/txop=4 axeslist
			if(V_Value > -1)
				variable col = floor(V_Value / dimsize(axeslist, 0))
				variable row = V_Value - col * dimsize(axeslist, 0)
				string nodepath = "/entry1" + axeslist[row][1]
				hdf5loaddata/o/z/q fileID, nodepath
				if(!V_flag)
					Wave pos = $(stringfromlist(0, S_wavenames))
					position[0, numpnts(pos) - 1] = pos[p]
				endif				
			endif
			
			//get the total_counts for the scan points
			hdf5loaddata/o/z/q fileID, "/entry1/instrument/detector/total_counts"
			if(!V_flag)
				Wave total_counts = $(stringfromlist(0, S_wavenames))
				w[0, numpnts(total_counts) - 1][0] = total_counts[p]
			endif
			
			hdf5loaddata/o/q/z fileID, "/entry1/instrument/detector/total_maprate"
			if(!V_flag)
				Wave total_maprate = $(stringfromlist(0, S_wavenames))
				w[0, numpnts(total_counts) - 1][3] = total_maprate[p]
			endif
		
			hdf5loaddata/o/q/z fileID, "/entry1/instrument/detector/total_maprate"
			if(!V_flag)
				Wave total_maprate = $(stringfromlist(0, S_wavenames))
				w[0, numpnts(total_maprate) - 1][3] = total_maprate[p]
			endif
			
			hdf5loaddata/o/q/z fileID, "/entry1/monitor/bm1_counts"
			if(!V_flag)
				Wave bm1_counts = $(stringfromlist(0, S_wavenames))
				w[0, numpnts(bm1_counts) - 1][7] = bm1_counts[p]
			endif
		
			hdf5loaddata/o/q/z fileID, "/entry1/monitor/bm1_event_rate"
			if(!V_flag)
				Wave bm1_event_rate = $(stringfromlist(0, S_wavenames))
				w[0, numpnts(bm1_event_rate) - 1][9] = bm1_event_rate[p]
			endif
					
			hdf5closefile/z fileID
		break		
	endswitch

	
	w[][1] = sqrt(w[p][0])
	w[][2] = w[p][0]/times
	w[][5] = sqrt(w[p][4])
	w[][8] = sqrt(w[p][7])
	
	//detector counts/BM2 counts
	w[][10] = w[p][0] / w[p][4]
	w[][11] = w[p][10] * sqrt((w[p][1]/w[p][0])^2 + (w[p][5]/w[p][4])^2)
	
	//detector counts/BM1 counts
	w[][12] = w[p][0] / w[p][7]
	w[][13] = w[p][12] * sqrt((w[p][1]/w[p][0])^2 + (w[p][8]/w[p][7])^2)
	setdatafolder saveDFR
End


Function UserCursorAdjustForCentre(grfName, textStr)
	String grfName, textStr
	variable err
	
	DoWindow/F $grfName		// Bring graph to front

	NewPanel/K=2 /W=(139,341,382,432) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor		// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$grfName	// Put panel near the graph
	DrawText 21,20, textStr
	Button button0,pos={5,64},size={92,20},title="Continue"
	Button button0,proc=Pla_UserCursorAdjust_ContButton
	
	//this line allows the user to adjust the cursors until they are happy with the right level.
	//you then press continue to allow the rest of the reduction to occur.
	PauseForUser tmp_PauseforCursor,$grfName
End

Function Pla_UserCursorAdjust_ContButton(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	if(B_Struct.eventcode == 2)
		DoWindow/K tmp_PauseforCursor		// Kill self
	endif
End
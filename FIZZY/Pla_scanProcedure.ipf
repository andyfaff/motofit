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
	curvefit/n/q/w=0 gauss tempy /X=position/W=tempE/I=1
	if(V_fiterror)
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
	if(numberbykey("RUN",S_info))	//if the scan is running, stop it, and finish
		CtrlNamedBackground  scanTask kill=1
		finishscan(1)
	endif
End

Function pausefpx(pauseORrestart)
	variable pauseORrestart
	//pause (pauseORrestart=1)
	//restart the scan (pauseORrestart=0)
	NVAR userPaused = root:packages:platypus:data:scan:userPaused
	userPaused = pauseOrRestart
	
	string histostatus = grabHistostatus("DAQ")
	CtrlNamedBackground  scanTask status
	if(numberbykey("RUN",S_info))	//if the scan is running
		pauseDetector(pauseORrestart)
	endif
End

Function fpxStatus()
	//returns the status of the scan
	//0 = not running
	//1 = running
	//2 = paused
	NVAR/z userPaused = root:packages:platypus:data:scan:userPaused
	ctrlnamedbackground scanTask,status
	variable running = numberbykey("RUN",S_info)
	if(running)
		if(userPaused)
			return 2
		endif
	endif
	return running
End

Function fpx(motorStr,rangeVal,points,[presettype,preset,saveOrNot,samplename,auto])
	string motorstr
	variable rangeVal,points
	string presettype
	variable preset,saveOrNot
	string samplename
	variable auto
	//performs a range scan for the motor specified by motorStr, over rangeVal distance, with points points
	//motorStr			-	self explanatory, but set to "_none_" if you don't want to scan a motor
	//points			-	the number of scan points >=0
	//presettype		-	TIME or MONITOR
	//preset			-	the number of seconds for the scan >0
	//saveOrNot		-	saves the results in a file if saveOrNot=0 (default), if saveOrNot=1, then don't save
	//sampleTitle		-	if the results are going to be saved, then this will be the sample title
	//auto			-	auto=0 - ask for user interaction
	//					auto=1 - no user interaction, automatically go to the peak
	//					auto=2 - no user interaction, do not go to the peak
	//
	//e.g. fpx("sphi",0.5,11,presettype="TIME",preset=5)
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
	
	if(paramisDefault(auto))
		auto = 0
	endif
	
	if(paramisDefault(presettype))
		presettype = "TIME"
	endif
	if(paramisDefault(preset))
		preset = 1
	endif
	if(paramisDefault(saveOrNot))
		saveOrNot = 0
	endif
	if(paramisDefault(samplename))
		samplename = ""
	endif
	
	//set the display variable to those sent to the function
	Grange = rangeVal
	Gpreset = preset
	Gnumpoints = points
	
	Dowindow/k fpxScan
	
	if( fpxStatus() )	//if the scan is running we can't continue
		print "scan is already running (fpx)"
		return 1
	endif
	
	//if the tertiary shutter is closed, it might be a good idea to open it.
	if(stringmatch(gethipaval("/instrument/status/tertiary"), "*Closed*"))
		print "WARNING, tertiary Shutter appears to be closed, you may not see any neutrons (fpx)"
		//if auto is set, then its probably an automatic scan, so don't ask if you want to stop
		//if auto is NOT set, then you probably want to open the shutter, so ask if you want to continue.
		if(!auto)	
			doalert 1, "Warning, the tertiary shutter appears closed, do you want to continue? (Scan will start when you press yes)"
			if(V_Flag==2)
				print "Stopping because the tertiary shutter was closed (fpx)"
				return 1
			endif
		endif
	endif
			
	//all the positions
	//Wave position = root:packages:platypus:data:scan:position
	//the counts at those positions
	//Wave counts = root:packages:platypus:data:scan:counts
	//current point
	//variable/g currentpoint = root:packages:platypus:data:scan:currentpoint
	//motor name being scanned
	//string/g scanmotor = root:packages:platypus:data:scan:scanmotor

	string cDF,msg,lhs="",rhs=""
	variable col,row
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	variable/g root:packages:platypus:data:scan:motoraxisrow = NaN
	NVAR motoraxisrow = root:packages:platypus:data:scan:motoraxisrow

	cDF = getdatafolder(1)

	//see if you're already doing an fpx scan
	if(fpxStatus())
		print "you are currently doing an fpx scan, please stop that first (fpx)"
		return 1	
	endif

	Wave/t statemon = root:packages:platypus:SICS:statemon
	if(numpnts(statemon)>0)
		print "The SICS statemon isn't cleared, may need to clear it? (fpx)"
		return 1
	endif
	//check the histogram
	if(currentacquisitionstatus(msg) == 2 || currentacquisitionstatus(msg) == 3 || statemonstatus("hmcontrol"))
		Print "you are currently acquiring data, or the histogram server is doing something (fpx)"
		return 1
	endif

	//see if SICS is doing anything
	if(SICSstatus(msg))
		Print "SICS is: "+msg + " (fpx)"
		return 1
	endif
		
	//first have to check if motor exists
	if(stringmatch(motorStr,"_none_"))
		motoraxisrow = NaN
	else
		findvalue/text=motorStr/Z axeslist
		if(V_Value == -1)
			Print "Error: The" + motorStr + " motor is not in the current motor list. (fpx)"
			return 1
		else 
			col=floor(V_Value / dimsize(axeslist, 0))
			row=V_Value-col*dimsize(axeslist, 0)
			motoraxisrow = row
		endif
	endif
	//rangeval has to be greater than or equal to 0
	if(rangeval < 0)
		Print "range must be >=0 (fpx)"
		return 1
	endif

	//number of points has to be greater than or equal to 1
	points = round (points)
	if(points < 1)
		Print "you must have at least 1 point (fpx)"
		return 1
	endif

	//now check upper and lower limits, but not for virtual motors.
	if(!stringmatch(motorStr, "_none_") && !numtype(str2num(axeslist[row][4])) && !numtype(str2num(axeslist[row][6])) )
		if( (str2num(axeslist[row][2]) - rangeval/2) < str2num(axeslist[row][4]) || (str2num(axeslist[row][2])+rangeval/2) > str2num(axeslist[row][6]))
			Print "scan range will exceed limits of motor (fpx)"
			return 1
		endif
	endif
	

	//create the data structures
	//see fillScanStats() for column information
	make/o/d/n=(points) root:packages:platypus:data:scan:position
	make/o/d/n=(points,14) root:packages:platypus:data:scan:counts=0
	
	variable/g root:packages:platypus:data:scan:currentpoint = -1			//initialise to -1
	string/g root:packages:platypus:data:scan:scanmotor = motorStr
	string/g root:packages:platypus:data:scan:presettype = presettype
	variable/g root:packages:platypus:data:scan:preset = preset
	variable/g root:packages:platypus:data:scan:dontSave = saveOrNot
	variable/g root:packages:platypus:data:scan:initialPosition = str2num(axeslist[row][2])
	variable/g root:packages:platypus:data:scan:pointProgress = 0
	variable/g root:packages:platypus:data:scan:auto = auto				//says whether you are going to autofit and drive to the centre
	variable/g root:packages:platypus:data:scan:userPaused = 0		//says whether you are currently in a user paused situation
	variable/g root:packages:platypus:data:scan:autosave = 1			//a global which will workout if its time to autosave (every three minutes)
	variable/g root:packages:platypus:data:scan:timeMoveStarted = 1			
	variable/g root:packages:platypus:data:scan:areYouMoving = 0			
	variable/g root:packages:platypus:data:scan:motorprecision = 0	
	variable/g root:packages:platypus:data:scan:requestedPointStart=0 //acquisition was requested to start
	variable/g root:packages:platypus:data:scan:requestedPointStartTime=0 //time at which the acquisition was requested to start


	Wave position = root:packages:platypus:data:scan:position
	Wave counts = root:packages:platypus:data:scan:counts
	NVAR currentpoint = root:packages:platypus:data:scan:currentpoint
	NVAR initialposition =  root:packages:platypus:data:scan:initialPosition
	NVAR motorprecision = root:packages:platypus:data:scan:motorprecision
	
	//findout what the precision of the motor of interest is
	//it's contained in the hipadaba tree
	if(!numtype(motoraxisrow))	
		motorprecision = str2num(gethipaval(axeslist[motoraxisrow][1] + "/precision"))
	endif

	//the virtual motors don't have precision associated with them, so give a default if the number is NaN/Inf
	if(numtype(motorprecision) != 0)
		motorprecision = 0.008
	endif
	
	//create the positions for the scan
	if(stringmatch(motorstr,"_none_"))
		position = p
	else
		if(points ==1)
			position[] = initialposition
		else
			position[] = rangeVal*(p/(points - 1)) + str2num(axeslist[row][2]) - rangeval/2
		endif
	endif

	//append counts to scan graph
	//this is done by the counttypeVSpos_popupcontrol function
	controlinfo/w=sicscmdpanel counttypeVSpos_tab1
	STRUCT WMPopupAction PU_Struct
	PU_Struct.popstr = S_value
	counttypeVSpos_popupcontrol(PU_Struct)
	
//	//stop the detector to initialise it, then put it into a paused (not the true pause, but the yellow button) state to 
//	//initialise the detector
//	//the detector starts much faster from a suspended state than from a stopped state.
//	if(stopAndPrimeDetector(presettype,preset))
//		print "ERROR while stopping detector (fpx)"
//		return 1
//	endif

	//if you're going to save, then start a new file	
	if(saveOrNot)
		//no save, except we will store it in the scratch file, in case we need it at the end.
		sics_cmd_interest("newfile HISTOGRAM_XYT scratch")
	else	//save
		sics_cmd_interest("newfile HISTOGRAM_XYT")
	endif
	
	if(!paramisDefault(samplename))
		sics_cmd_interest("samplename " + samplename)
	endif
	
	if(SAWDEVICE)
		if(sics_cmd_interest("\nhmm configure read_data_period_number 0\nsave 0\nhmm configure read_data_period_number 1\nsave 1\n"))//+num2str(currentpoint)))
			print "problem while autosaving (fpx)"
		endif
	else
		if(sics_cmd_interest("save 0"))
			print "ERROR whilst speaking to SICS (fpx)3"
			return 1
		endif
	endif
	
	sockitsendmsg/time=1 SOCK_interest,"datafilename\n"
	if(V_Flag)
		print "ERROR whilst speaking to SICS (fpx)3"
		return 1
	endif
	
	if(HISTMEM_preparedetector(presettype,preset))
		print "ERROR while preparing detector (fpx)"
		return 1
	endif
	
	//check that we know what presettype we have, and what the preset is.
	sics_cmd_interest("hget /instrument/detector/mode\nhget /instrument/detector/preset")
	
	strswitch(presettype)
		case "unlimited":
			ValDisplay/z progress_tab1,win=SICScmdpanel,limits={0, inf, 0}
		break
		default:
			ValDisplay/z progress_tab1,win=SICScmdpanel,limits={0, points*preset, 0}
		break
	endswitch
	ValDisplay/z progress_tab1,win=SICScmdpanel,value= #"root:packages:platypus:data:scan:pointProgress"
	label/W=SICScmdPanel#G0_tab1/z bottom, motorstr
	PopupMenu/z motor_tab1, win=SICScmdpanel, fSize=10, mode=1, popvalue = motorStr, value = #"motorlist()"
	findvalue/TEXT=motorStr/z/txop=4 root:packages:platypus:SICS:axeslist
	if(V_Value > 0)
		SetVariable currentpos_tab1, win=sicscmdpanel, limits={-inf,inf,0},value=root:packages:platypus:SICS:axeslist[V_Value][2]
	else
		SetVariable currentpos_tab1,win=sicscmdpanel, limits={-inf,inf,0},value=NaN
	endif
	
	doupdate
//	DoXOPIdle
	print "Beginning scan"
	//start the scan task
	CtrlNamedBackground  scanTask period=600, proc=scanBkgTask, burst=0, dialogsOK =0
	CtrlNamedBackground  scanTask start
	return 0
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
	//this is a named background task that is called by runscan, that will move the instrument point by point and acquire data
	 
	Wave position = root:packages:platypus:data:scan:position
	Wave counts = root:packages:platypus:data:scan:counts
	Wave/t axeslist = root:packages:platypus:SICS:axeslist
	NVAR currentpoint = root:packages:platypus:data:scan:currentpoint			//what scan point you are on.  Subtract one from this value to get the real number
	NVAR pointProgress = root:packages:platypus:data:scan:pointProgress
	NVAR preset = root:packages:platypus:data:scan:preset
	NVAR dontSave = root:packages:platypus:data:scan:dontSave	
	SVAR presettype = root:packages:platypus:data:scan:presettype
	NVAR userPaused = root:packages:platypus:data:scan:userPaused		//says whether you are currently in a user paused situation
	NVAR autosave = root:packages:platypus:data:scan:autosave
	NVAR timeMoveStarted = root:packages:platypus:data:scan:timeMoveStarted			
	NVAR requestedPointStart = root:packages:platypus:data:scan:requestedPointStart //have you requested acquisition to start
	NVAR requestedPointStartTime = root:packages:platypus:data:scan:requestedPointStartTime //have you requested acquisition to start
	NVAR areYouMoving = root:packages:platypus:data:scan:areYouMoving
	SVAR scanmotor = root:packages:platypus:data:scan:scanmotor
	NVAR motoraxisrow = root:packages:platypus:data:scan:motoraxisrow
	NVAR motorprecision = root:packages:platypus:data:scan:motorprecision
	SVAR sicsstatus = root:packages:platypus:SICS:sicsstatus
	Wave/t statemon = root:packages:platypus:SICS:statemon

	//		for sending sics commands that will be displayed
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	//		for sending an emergency stop command
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	//		for sending commands that won't be displayed, but to also get current axis information as it changes.
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest

	string msg,tempstr,lhs,rhs
	variable status,temp, hmstatus=0
	
	//flush the buffered TCP/IP messages, this will update counts, etc.
//	execute/P/Q "DOXOPIdle"
	
	//in the last call to this function we may have asked the histo to start acquiring
	//sometimes it takes a while for SICS to emit the hmcontrol message.
	//we want to wait for a while to make sure that sics has sent the message
	//if it doesn't then we'll do a time out.
	hmstatus = statemonstatus("hmcontrol") | statemonstatus("HistogramMemory")

	if(requestedPointStart)
		if(hmstatus)
			requestedPointStart = 0
		elseif( (ticks - requestedPointStartTime) > 3600)
			print "ERROR whilst trying to start histogram server (scanbkgtask)"
			finishScan(1)
			return 1
		else
			return 0
		endif
	endif
	
	//lets do an autosave every three minutes, useful for long scans, but only if you're acquiring
	//you can also do a test to see if the required stats have been reached.
	if( hmstatus )
		if(mod(round(str2num(gethipaval("/instrument/detector/time"))/60),3)==0 && !autosave)
			//save every 3 minutes
			print "AUTOSAVED ", gethipaval("/experiment/file_name")
			
			if(SAWDEVICE)
				if(sics_cmd_interest("\nhmm configure read_data_period_number 0\nsave 0\nhmm configure read_data_period_number 1\nsave 1\n"))//+num2str(currentpoint)))
					print "problem while autosaving (fpx)"
				endif
			else
				if(sics_cmd_interest("save "+num2str(currentpoint)))
					print "problem while autosaving (fpx)"
				endif
			endif
					
			//see if the scan is ready to be finished
			if(scanReadyToBeStopped(currentPoint))
				sics_cmd_interest("histmem stop")
				autosave = 1
				return 0
			endif
			
			autosave = 1
		elseif(mod(round(str2num(gethipaval("/instrument/detector/time"))/60),3) != 0)
			autosave = 0
		endif
	endif	
	
	if( hmstatus )		//you are still acquiring
		pointprogress = currentpoint*preset
		strswitch(gethipaval("/instrument/detector/mode"))
			case "TIME":
				pointProgress += round(str2num(gethipaval("/instrument/detector/time")))
			break
			case "MONITOR_1":
				pointprogress += str2num(gethipaval("/monitor/bm1_counts"))
			break
			case "unlimited":
				pointprogress = round(str2num(gethipaval("/instrument/detector/time")))
			break
			case "count":
				pointprogress += str2num(gethipaval("/instrument/detector/total_counts"))
			break
			
		endswitch
		fillScanStats(counts, currentpoint, 0)
		return 0

	elseif(statemonstatus(scanmotor))
		return 0	//SICS is doing something 
		
	elseif(areyoumoving == 0)
		//here we're not moving the scanmotor, and we're not acquiring
		//either we've just finished the scan point, or you've just started an fpx scan
		pointProgress = (currentpoint+1)*preset

		if(currentpoint >= 0)	//If currentpoint >=0, then we've already started the scan and completed at least one point
			if( hmstatus )//SICS hasn't finished updating.
				return 0
			endif
			
			if(SAWDEVICE)
				if(sics_cmd_interest("\nhmm configure read_data_period_number 0\nsave 0\nhmm configure read_data_period_number 1\nsave 1\n"))//+num2str(currentpoint)))
					print "problem while autosaving (fpx)"
				endif
			else
				if(sics_cmd_interest("save "+num2str(currentpoint)))
					print "problem while saving (fpx)"
				endif
			endif
		
			fillScanStats(counts, currentpoint, 1)
			print "Position:\t" + num2str(position[currentpoint]) + "\t\tCounts:\t" + num2str(counts[currentpoint][0])			
			
			//if the following test is true, you've finished the fpx scan.
			if(currentPoint == numpnts(position) - 1 )
				finishScan(0)
				return 1
			endif
		endif
		
		//update the point number and move on to the next one, this is also called for the first scan point
		currentpoint += 1

		timeMoveStarted = dateTime	
		areYouMoving = 1
				
		if(stringmatch(scanmotor, "_none_"))
		else
			//drive to the currentpoint and let it get there.
			if(run(scanmotor, position[currentpoint]))
				print "Error while asking to do a move (scanBkgTask)"
				finishScan(1)
				return 1
			endif
			return 0
		endif
	endif
	
	if(areyoumoving == 1) 	//we should only get to this point if we have started a move (move includes the "_none_" motor).
//		status = sicsstatus(msg)
		if(statemonstatus(scanmotor) || ((abs(position[currentpoint] - str2num(axeslist[motoraxisrow][2])) > motorprecision) && !stringmatch(scanmotor,"_none_")) || sicsstatus(msg))	
			if(datetime - timeMoveStarted > MOTIONTIMEOUT)
				print "Motion timed out on scan, Aborting (scanBkgTask)"
				finishScan(1)
				return 1
			endif
			return 0
		else//if(!status)		//we're not moving, so we should be able to start the acquisition.
			areYouMoving = 0
			//we want to plot the actual position, not what we requested
			if(stringmatch(scanmotor,"_none_"))
				position[currentpoint] = currentpoint
			else
				if(abs(position[currentpoint] - str2num(axeslist[motoraxisrow][2])) > motorprecision)
					//check if the motion was within tolerance
					print "The "+scanmotor+" motion wasn't within tolerance (scanbkgtask)"
					finishScan(1)
					return 1					
				endif
				position[currentpoint] = str2num(axeslist[motoraxisrow][2])
			endif		
			//it's time to do an acquisition if you'v e stopped moving
			if(HISTMEM_startDetector())
				print "Couldn't start the detector at point "+num2str(currentpoint) + " (scanBkgTask)"
				finishScan(1)
				return 1
			endif
			requestedPointStart = 1
			requestedPointStartTIme = ticks
			return 0	
		endif
	endif
	
	return 0
End

Function finishScan(status)
	//status describes whether runscan finished with errors (status=1)
	variable status
	
	SVAR scanmotor = root:packages:platypus:data:scan:scanmotor
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
	
	controlinfo/w=sicscmdpanel sicstab
	if(V_Value==1)
		Button/z Go_tab1 win=sicscmdpanel,disable=0	
		Button/z stop_tab1 win=sicscmdpanel,disable=1	
		Button Pause_tab1,win=sicscmdpanel,disable=1
		setvariable/z sampletitle_tab1 win=sicscmdpanel,disable=0
		setvariable/z preset_tab1 win=sicscmdpanel,disable=0
		PopupMenu/z presettype_tab1 win=sicscmdpanel,disable=0
		PopupMenu/z motor_tab1 win=sicscmdpanel,disable=0	
		setvariable/z numpnts_tab1 win=sicscmdpanel,disable=0
		setvariable/z range_tab1 win=sicscmdpanel,disable=0
		checkbox/z save_tab1 win=sicscmdpanel,disable=0	
	endif
	
	
	//tell the histogram server to stop acquiring if it's an abnormal stop
	if(status)
		sics_cmd_interest("histmem stop")
		print "Stopped scan for some reason (finishScan)"
		fillScanStats(counts, currentpoint, 1)
	endif
	
	print "scan finished"
//	DoXOPIdle

	//if you want to save, then we must save the data.
	if(SAWDEVICE)
		if(sics_cmd_interest("\nhmm configure read_data_period_number 0\nsave 0\nhmm configure read_data_period_number 1\nsave 1\n"))//+num2str(currentpoint)))
			print "problem while autosaving (fpx)"
		endif
	else
		if(sics_cmd_interest("save " + num2str(currentpoint)))
			print "ERROR while saving data (finishScan)"
		endif
	endif

	//save the scan itself, not the overall data, just counts vs position
	Newpath/o/q/z PATH_TO_DATA, PATH_TO_DATA+"extras:"
	PATHinfo PATH_TO_DATA
	if(V_flag)
		if(!NVAR_exists(FIZscanFileNumber))
			string files = greplist(IndexedFile(PATH_TO_DATA, -1, ".itx", "IGR0"), "^FIZscan")	// all Igor text files
			string lastfile = ""
			files = sortlist(files, ";", 16)
			lastfile = stringfromlist(itemsinlist(files) - 1, files)
			lastfile = removeending(lastfile, ".itx")
			lastfile = replacestring("FIZscan", lastfile, "")
			Variable/g root:packages:platypus:data:scan:FIZscanFileNumber = str2num(lastfile) + 1
			NVAR/z FIZscanFileNumber = root:packages:platypus:data:scan:FIZscanFileNumber
		else
			FIZscanFileNumber += 1
		endif
		string fname =  "FIZscan" + num2str(FIZscanFileNumber) + ".itx"
		save/o/t/p=PATH_TO_DATA position, counts as fname
		print "FPXscan (position vs counts) saved to ", parsefilepath(5, S_Path+fname, "*", 0, 1)
		print "file saved as: ", gethipaval("/experiment/file_name")
	endif
	
	//display the scan in an easy to killgraph
	Dowindow/k fpxScan
	Display/k=1/N=fpxScan
	appendtograph/w=fpxScan counts[][0] vs position
	ModifyGraph/z/w=fpxScan mode(counts)=4
	ModifyGraph/z/w=fpxScan standoff(left)=0,standoff(bottom)=0
	ErrorBars/w=fpxScan counts Y,wave=(counts[*][1],counts[*][1])
	cursor/H=1/s=0/F/P A  counts 0.5,0.5
	showinfo
		
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
	appendtograph/w=fpxscan tagyy vs taggauss
	appendtograph/w=fpxscan tagyy vs tagcentroid
	ModifyGraph/w=fpxscan rgb(tagyy)=(0,0,0)
	ModifyGraph/w=fpxscan rgb(tagyy#1)=(0,0,52224)

	if(stringmatch(scanmotor,"_none_"))
		print "finished scan"
		return 0
	endif
					
	//find the centre
	variable/c centre
	centre = findthecentre(position,tempY,tempE)

	tagcentroid = {imag(centre),imag(centre)}
	taggauss = {real(centre),real(centre)}
	Tag/C/N=text0/TL=0 bottom, real(centre),"gauss"
	Tag/C/N=text1/TL={lineRGB=(0,0,65280)} bottom, imag(centre),"\\K(0,0,65280)centroid"
	doupdate
		
	if(auto)	//if you are auto aligning
		if(status)	//if there was an error during the auto align
			print "there was an error during the auto align, returning to pre-scan position (finishScan)"
			run(scanmotor,initialPosition)
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
//		DoXOPIdle	
	else		//no auto alignment, ask the user
		Prompt var,"which variable",popup,"counts;"
		Prompt whichStat,"which statistic",popup,"gaussian;centroid;graph cursors"
		Doprompt "Do you want to move to the peak centre?", var, whichstat			

		if(V_Flag==1)	//if you don't want to move to peak centre
			if(!stringmatch(scanmotor,"_none_") )
				print "Scan finishing"
				if(run(scanmotor,initialPosition))
					print "Error while returning to original Pos (finishScan)"
				endif
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
				if(!stringmatch(scanmotor, "_none_") )
					print "Scan finishing, driving to peak position"
					err= run(scanmotor, num)
					if(err)
						print "Error while returning to new position (finishScan)"
					endif
				endif
			endif
		endif	
	endif
	//reset the progress bar
	ValDisplay/z progress_tab1, win=SICScmdpanel, limits={0,0,0}
	ctrlnamedbackground scanTask, kill=1
	return err
End

Function fillScanStats(w,point,full)
	wave w			//where to put the stats
	variable point		//the stats will be put in this row
	variable full		//full is issued at the end, to get the correct numbers		
	
	string histostatus
	variable times
	
	if(full)	//at the end of a scan get the numbers from the histoserver, because SICS may not have issued them
		histostatus = grabAllHistoStatus()
		//time
		times = numberbykey("acq_dataset_active_sec",histostatus,": ","\r")
		//counts
		w[point][0] = numberbykey("num_events_filled_to_histo",histostatus,": ","\r")	
		//max detector count rate
		w[point][3] = numberbykey("ratemap_xy_max_bin",histostatus,": ","\r")
		//BM2 monitor counts
		w[point][4] =  numberbykey("BM2_Counts",histostatus,": ","\r")
		w[point][6] =  w[point][4]/times
		//BM1 monitor counts
		w[point][7] =  numberbykey("BM1_Counts",histostatus,": ","\r")
		w[point][9] =  w[point][7]/times
	else
		//time
		times = str2num(gethipaval("/instrument/detector/time"))
		//counts
		w[point][0] = str2num(gethipaval("/instrument/detector/total_counts"))
		//max detector count rate
		w[point][3] =  str2num(gethipaval("/instrument/detector/max_binrate"))

		//BM2 monitor counts
//		w[point][4] =  str2num(gethipaval("/monitor/bm2_counts"))
//		w[point][6] =  str2num(gethipaval("/monitor/bm2_event_rate"))

		//BM1 monitor counts
		w[point][7] =  str2num(gethipaval("/monitor/bm1_counts"))
		w[point][9] =  str2num(gethipaval("/monitor/bm1_event_rate"))
	endif
	
	
	w[point][1] = sqrt(w[point][0])
	w[point][2] = w[point][0]/times
	w[point][5] = sqrt(w[point][4])
	w[point][8] = sqrt(w[point][7])
	
	//detector counts/BM2 counts
	w[point][10] = w[point][0] / w[point][4]
	w[point][11] = w[point][10] * sqrt((w[point][1]/w[point][0])^2 + (w[point][5]/w[point][4])^2)
	
	//detector counts/BM1 counts
	w[point][12] = w[point][0] / w[point][7]
	w[point][13] = w[point][12] * sqrt((w[point][1]/w[point][0])^2 + (w[point][8]/w[point][7])^2)
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
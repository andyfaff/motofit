// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$


Function batchScan(batchfile)
	Wave/t batchfile
	
	string msg
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
	
	//if the tertiary shutter is closed, it might be a good idea to open it.
	if(stringmatch(gethipaval("/instrument/status/tertiary"), "*Closed*"))
		doalert 1, "WARNING, tertiary Shutter appears to be closed, you may not see any neutrons, do you want to continue?"
		if(V_Flag==2)
			abort
		endif
	endif
	
	//see if attenuator is going
	sockitsendnrecv SOCK_sync, "bat\n", msg
	msg = replacestring(" = ",msg, "=")
      msg = removeending(msg, "\n")
     	if(str2num(stringfromlist(1, msg, "="))  > 1)
		doalert 1, "WARNING, beam attenuator appears to be running, do you want to continue?"
		if(V_Flag==2)
			abort
		endif
	endif
     	if(getpos("bz")  > 10)
		doalert 1, "WARNING, beam shade appears to be in, do you want to continue?"
		if(V_Flag==2)
			abort
		endif
	endif
		
	if(dimsize(batchfile,1)!=4)
		print "Batchbuffer must have 3 columns"
		return 1
	endif
	batchfile[][2] = ""
	
	if(SICSstatus(msg))
		print "Cannot start batch, because SICS is doing something (batchScan)"
		return 1
	endif 
	if(fpxStatus())
		print "Cannot start batch, because you are currently doing an fpx scan (batchScan)"
		return 1
	endif
	if(currentacquisitionStatus(msg) > 1)
		print "Cannot start batch, because the histogram server is doing something (batchScan)"
		return 1
	endif
	if(batchScanStatus())
		print "Cannot start batch, because you are already running a batchscan (batchScan)"
		return 1		
	endif
	
	//make the datafolders
	newdatafolder/o root:packages:platypus:data:batchScan

	//make the global variables
	variable/g root:packages:platypus:data:batchScan:currentpoint = -1		//-1 initialisation, because batchbkgtask adds one to get to the next point
	variable/g root:packages:platypus:data:batchscan:userPaused = 0		//says whether you are currently in a user paused situation
	
	//start the scan task
	CtrlNamedBackground  batchScan period=120, proc=batchbkgtask,  dialogsOK =0
	CtrlNamedBackground  batchScan start
	print "______________________________________________________"
	print "STARTING BATCH MODE"
	return 0
End

Function batchScanStatus()
	//returns the status of the scan
	//0 = not running
	//1 = running
	//2 = paused
	NVAR userPaused = root:packages:platypus:data:batchscan:userPaused

	Ctrlnamedbackground batchScan, status
	variable running = numberbykey("RUN",S_info)
	if(running)
		if(userPaused)
			return 2
		endif
	endif
	return running
End

Function batchScanReadyForNextPoint()
	//this function returns the instrument state.
	//you can probably go onto the next point if
	//1) SICS isn't busy (has stopped moving)
	//2) The histogram server is stopped
	//3) There is no fpx scan running
	string msg
	NVAR userPaused = root:packages:platypus:data:batchscan:userPaused
	Wave/t statemon = root:packages:platypus:SICS:statemon
	
//	DoXOPIdle
	if(userPaused)
		return 2
	elseif(fpxStatus() || statemonstatus("hmcontrol")  || statemonstatus ("HistogramMemory") || waitStatus() || dimsize(statemon,0)>0 || SICSstatus(msg))
//		print "SICSSTATUS "+num2str(SICSstatus(msg))
//		print "FPXSTATUS "+num2str(fpxstatus())
//		print "CURRENTACQSTATUS "+num2str(currentAcquisitionStatus(msg))
		return 1
	else 
		return 0
	endif
End

Function batchScanStop()
	//stops the batch scan running.
	if(fpxStatus())
		fpxstop()
	endif
	if(waitStatus())
		stopwait()
	endif
	string/g root:batchstackInfo = getrtstackinfo(3) + time()
	
	NVAR currentpoint = root:packages:platypus:data:batchScan:currentpoint
	Wave/t list_batchbuffer = root:packages:platypus:data:batchScan:list_batchbuffer
	list_batchbuffer[currentpoint][3] = "Stopped"
	
	Ctrlnamedbackground batchScan, kill=1
	NVAR userPaused = root:packages:platypus:data:batchScan:userPaused	//reset the pause status
	userPaused = 0
	//rejig all the buttons you see on the sicscmdpanel.
	// have /z in case you are running from command line
	controlinfo/w=sicscmdpanel sicstab
	if(V_Value==3)
		Button/z runbatch_tab3 win=sicscmdpanel,disable=0	
		Button/z loadbatch_tab3 win=sicscmdpanel,disable=0
	endif
	Button/z stopbatch_tab3 win=sicscmdpanel,disable=1		
	Button/z pausebatch_tab3 win=sicscmdpanel,disable=1		
	print "FINISHED BATCH MODE at:    ", Secs2Time(DateTime,2)
	print "______________________________________________________"

End

Function batchScanPause(pauseORrestart)
	variable pauseORrestart
	//pause (pauseORrestart=1)
	//restart the scan (pauseORrestart=0)
	NVAR userPaused = root:packages:platypus:data:batchscan:userPaused
	
	userPaused = pauseOrRestart
	if(fpxStatus())
		pausefpx(pauseORrestart)
	endif
End

Function batchbkgtask(s)
	STRUCT WMBackgroundStruct &s
	Wave/t list_batchbuffer = root:packages:platypus:data:batchScan:list_batchbuffer
	Wave sel_batchbuffer = root:packages:platypus:data:batchScan:sel_batchbuffer

	string tempstr=""
	
	//the global variables
	NVAR currentpoint = root:packages:platypus:data:batchScan:currentpoint
	NVAR userPaused = root:packages:platypus:data:batchScan:userPaused		//says whether you are currently in a user paused situation

	//if you are in a user paused state don't do anyupdates.
	if(userPaused)
		return 0
	endif
	//see if we're ready for the next point.  This is defined as SICS not doing something, Histogram server
	//not acquiring, fpx scan not running
	if(batchScanReadyForNextPoint() == 1)
		return 0
	endif
	if(currentpoint >=0 && (sel_batchbuffer[currentpoint][2] & 2^4))
		list_batchbuffer[currentpoint][3] = "DONE"
	endif
	for( ; currentpoint < dimsize(list_batchbuffer,0) ; )
		currentpoint += 1
		if(currentpoint == dimsize(list_batchbuffer, 0))
			batchScanStop()
			return 1
		endif
		if(sel_batchbuffer[currentpoint][2] & 2^4)	
			//see if it's a comment line
			tempstr = replacestring(" ", list_batchbuffer[currentpoint][1], "")
			if(grepstring(tempstr, "^//"))
				continue
			endif
			switch(strlen(list_batchbuffer[currentpoint][1]))
				case 0:
					break
				default:
					executenextbatchpoint(list_batchbuffer, currentpoint)
					return 0
					break
			endswitch
		endif
	endfor
	
	return 0
End

Function executenextbatchpoint(batchbuffer, currentpoint)
	Wave/t batchbuffer
	variable currentpoint

	//contains information as to whether the bufferline will run
	Wave sel_batchbuffer = root:packages:platypus:data:batchScan:sel_batchbuffer
	
	//used as a sockit for the SICS_interest channel
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	//used as a sockit for the SICS cmd channel
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd

	//this function executes a row of the batch buffer.  Will need to do some parsing here!!!!
	print batchbuffer[currentpoint][1]
	if(strlen(batchbuffer[currentpoint][1])>0 && (sel_batchbuffer[currentpoint][2] & 2^4))
		print "STARTED POINT: "+num2str(currentpoint)+" of batch Scan at:    ", Secs2Time(DateTime,2)
		batchbuffer[currentpoint][3] = "Executing"
		execute batchbuffer[currentpoint][1]
	endif
End

Function wait(timeout)
	variable timeout
	//a function that waits for timeout seconds and does nothing.
	variable/g root:packages:platypus:data:batchScan:endtime
	NVAR endtime = root:packages:platypus:data:batchScan:endtime
 
	endtime = datetime+timeout
 
	CtrlNamedBackground waiter,period=60,proc=waittask
	CtrlNamedBackground waiter, start
End
 
Function stopwait()
	ctrlnamedbackground waiter,stop=1
	killvariables/z root:packages:platypus:data:batchScan:endtime
ENd
 
Function waitStatus()
	//returns 0 if you're not waiting for anything
	//returns 1 if you're waiting for something.
	ctrlnamedbackground waiter,status
	return numberbykey("RUN",S_info)
End
 
Function waittask(s)
	STRUCT WMBackgroundStruct &s
	NVAR endtime = root:packages:platypus:data:batchScan:endtime
	if(datetime > endtime)
		stopwait()
		return 1
	endif
	return 0
End

Function labels(labelsStr)
	String labelsStr
End

Function goto(labelsStr, loopNum)
	String labelsStr
	variable loopNum

	NVAR currentpoint = root:packages:platypus:data:batchScan:currentpoint
	Wave/t list_batchbuffer = root:packages:platypus:data:batchScan:list_batchbuffer
	Wave sel_batchbuffer = root:packages:platypus:data:batchScan:sel_batchbuffer

	NVAR/z labeller = $("root:packages:platypus:data:batchScan:"+labelsStr)

	if(!NVAR_exists(labeller))
		variable/g $("root:packages:platypus:data:batchScan:"+labelsStr)
		NVAR/z labeller = $("root:packages:platypus:data:batchScan:"+labelsStr)
		labeller = 0
	endif

	if(labeller < loopNum-1)
		findvalue/S=0/TEXT="labels(\""+labelsStr+"\")" list_batchbuffer
		variable col=floor(V_value/dimsize(list_batchbuffer, 0))
		variable row=V_value-col*dimsize(list_batchbuffer ,0)
		
		if(V_Value>-1)
			labeller += 1
			currentpoint = row
			executenextbatchpoint(list_batchbuffer, currentpoint)
		endif
	else
		labeller=inf
		killvariables/z $("root:packages:platypus:data:batchScan:"+labelsStr)
	endif
End
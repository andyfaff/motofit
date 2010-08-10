#pragma rtGlobals=1		// Use modern global access method.
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Checking the status of the histogram server
//	Controlling the histogram server
//	Getting it's data
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

Function grabData(data,axes,axis_sizes,[axesrequested])
	string &data, &axes, &axis_sizes
	string axesrequested
	
	string cmd, histostatus

	histostatus = graballhistostatus()
	if(strlen(histostatus) == 0)
		Print "Error while grabbing histostatus (grabData)"
		return 1
	endif
	
	if(paramisdefault(axesrequested))
		axesrequested = "TOTAL_HISTOGRAM_XYT"
		axes = "x_bin;y_bin;time_of_flight"
		axis_sizes = stringbykey("OAT_NXC",histostatus,": ","\r")+";"+stringbykey("OAT_NYC",histostatus,": ","\r")+";"+stringbykey("OAT_NTC",histostatus,": ","\r")
	else
		strswitch(axesrequested)
			case "TOTAL_HISTOGRAM_XYT":
				axes = "x_bin;y_bin;time_of_flight"
				axis_sizes = stringbykey("OAT_NXC",histostatus,": ","\r")+";"+stringbykey("OAT_NYC",histostatus,": ","\r")+";"+stringbykey("OAT_NTC",histostatus,": ","\r")
				break
			case "TOTAL_HISTOGRAM_XY":
				axes = "x_bin;y_bin"
				axis_sizes = stringbykey("OAT_NXC",histostatus,": ","\r")+";"+stringbykey("OAT_NYC",histostatus,": ","\r")
				break
			case "TOTAL_HISTOGRAM_XT":
				axes = "x_bin;time_of_flight"
				axis_sizes = stringbykey("OAT_NXC",histostatus,": ","\r")+";"+stringbykey("OAT_NTC",histostatus,": ","\r")
				break
			case "TOTAL_HISTOGRAM_YT":
				axes = "time_of_flight;y_bin"
				axis_sizes = stringbykey("OAT_NTC",histostatus,": ","\r")+";"+stringbykey("OAT_NYC",histostatus,": ","\r")
				break
			case "TOTAL_HISTOGRAM_T":
				axes = "time_of_flight"
				axis_sizes = stringbykey("OAT_NTC",histostatus,": ","\r")
				break
			case "TOTAL_HISTOGRAM_X":
				axes = "x_bin"
				axis_sizes = stringbykey("OAT_NXC",histostatus,": ","\r")
				break
			case "TOTAL_HISTOGRAM_Y":
				axes = "y_bin"
				axis_sizes = stringbykey("OAT_NYC",histostatus,": ","\r")
				break
				
		endswitch
	endif
	
	sprintf cmd,"http://%s:%d/admin/savedataview.egi?data_saveopen_format=ZIPBIN&data_saveopen_action=OPENONLY&type=%s",DASserverIP,DASserverport,axesrequested
	easyHttp/PASS="manager:ansto" cmd,data
	if(V_Flag)
		Print "Error while speaking to Histogram Server (grabData)"
		return 1
	endif

	return V_Flag
ENd

Function currentacquisitionStatus(msg)
	string &msg
	
	variable status = 3
	//find out the current acquisition status
	//return 0 if stopped
	//return 1 if Paused
	//return 2 if acquiring
	//return 3 if starting
	//return 4 if undetermined
	
	//other functions use if(status > 1) to see if the histogram server is doing something
	string statusstr = grabHistoStatus("DAQ")
	msg = statusstr
	strswitch(statusStr)
		case "Stopped":
			status = 0
			break
		case "Paused":
			status = 1
			break
		case "Started":
			status = 2
			break
		case "Starting":
			status = 3
			break
		default:
			status = 4
			break
	endswitch
	
	return status
End


Function/t grabHistoStatus(keyvalue)
	string keyvalue
	//this function returns the status of the Histogram server from it's text status
	string retStr,cmd

	sprintf cmd,"http://%s:%d/admin/textstatus.egi",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd

	if(V_Flag)
		Print "Error while speaking to Histogram Server (grabHistoStatus)"
		return ""
	endif
	retStr = S_getHttp
	retStr = replacestring("\n",retStr,"\r")
	retstr = stringbykey(keyvalue,retStr,":","\r")
	if(!cmpstr(retstr[0]," "))
		retstr = retstr[1,inf]		
	endif
	return retstr
End

Function/t grabAllHistoStatus()
	//this function returns the status of the Histogram server from it's text status
	string retStr,cmd
	
	sprintf cmd,"http://%s:%d/admin/textstatus.egi",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	
	if(V_Flag)
		Print "Error while speaking to Histogram Server (grabAllHistoStatus)"
		return ""
	endif
	retStr = S_getHttp
	retStr = replacestring("\n",retStr,"\r")
	return retstr
End

Function printHistoStatus()
	string keyvalue
	//this function prints the status of the Histogram server from it's text status
	string cmd
	sprintf cmd,"http://%s:%d/admin/textstatus.egi",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd

	if(V_Flag)
		Print "Error while speaking to Histogram Server (printHistoStatus)"
	endif
	S_gethttp = replacestring("\n",S_gethttp,"\r")
	print S_gethttp
End

Function modifyHistoConfig(key,value)
	string key,value
	//this function changes the config of the histogram server.
	//it does not check whether these are allowed values or not.
	//use the XMLschema for the webserver to check for allowed values.
	string msg
	variable status = currentacquisitionStatus(msg)
	string cmd = ""
	if (status!=0)
		print "can't change histo configuration if the server isn't stopped (modifyHistoConfig)" 
		return 1
	endif
	
	sprintf cmd,"http://%s:%d/admin/selectdynamicfatmodifygui.egi?dynamicFATmodifyparamname=%s&dynamicFATmodifyparamvalue=%s",DASserverIP,DASserverport,key,value
	easyHttp/PASS="manager:ansto"  cmd
	
	if(V_Flag)
		Print "Error while speaking to Histogram Server (modifyHistoConfig)"
	endif
	return V_Flag
End

Function grabXMLHistoConfig()
	//downloads the histogram XML config and saves it in the temp directory
	string cmd
	
	sprintf cmd,"http://%s:%d/admin/readconfig.egi?",DASserverIP,DASserverport
	easyHttp/File=home+"histoconfig.xml"/PASS="manager:ansto" cmd

	if(V_Flag)
		Print "Error while speaking to Histogram Server (grabXMLHistoConfig)"
	endif
	return V_Flag
End

Function startDetector()
	string temp = "",cmd
	//this function makes the histogram server acquire. It should have already initialised with the presettype (e.g. TIME or MONITOR, and the preset).
	//using stopAndPrimeDetector(presettype,preset)

	//seize&release the server is toggled.  Therefore if you toggle on, must toggle off otherwise how do you know you've released it?
	//seize control of the server
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (startDetector)"
		return 1
	endif

	if(stringmatch(grabhistostatus("DAQ"),"Started"))
		print "ERROR, detector is already counting (startDetector)"
		return 1
	endif
	
	//start the acquisition
	sprintf cmd,"http://%s:%d/admin/startdaq.egi?viewdata",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (startDetector)"
		return 1
	endif

	//release the control of the server
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (startDetector)"
		return 1
	endif

	return 0
End

Function HISTMEM_preparedetector(presettype,preset)
	string presettype
	variable preset
	//presettype is:
	
	//time
	//MONITOR_1
	//unlimited
	//count
	//frame
	
	//please note, Upper or lower case matters!
	if(stringmatch(grabhistostatus("DAQ"),"Started"))
		print "ERROR, detector is already counting (HISTMEM_preparedetector)"
		return 1
	endif
	strswitch(presettype)
		case "time":
			presettype = "time"
		break
		case "monitor_1":
			presettype = "MONITOR_1"
		break
		case "unlimited":
			presettype = "unlimited"
		break
		case "count":
			presettype = "count"
		break
		case "frame":
			presettype = "frame"
		break		
	endswitch
	
	//set up the preset type. SICS requires that the presettype is "time" not "TIME"
	sics_cmd_sync("histmem mode "+ presettype)
	sics_cmd_sync("histmem preset "+num2str(preset))

//	sics_cmd_sync("histmem pause")
End

Function HISTMEM_startDetector()
	if(stringmatch(grabhistostatus("DAQ"), "Started"))
		print "ERROR, detector is already counting (HISTMEM_startDetector)"
		return 1
	endif

	sics_cmd_interest("histmem start")
	return 0
End

Function stopAndPrimeDetector(presettype,preset)
	string presettype
	variable preset
	//stops the detector acquiring (red button), then configures the detector for a given time and preset.
	//it then primes the detector by pressing the yellow button.
	
	//presettype is
	//	<xsd:enumeration value="TIME"></xsd:enumeration>
	//	<xsd:enumeration value="MONITOR"></xsd:enumeration>
	//	<xsd:enumeration value="UNLIMITED"></xsd:enumeration>
	//	<xsd:enumeration value="PERIOD"></xsd:enumeration>
	//	<xsd:enumeration value="COUNT"></xsd:enumeration>
	//	<xsd:enumeration value="FRAME"></xsd:enumeration>

	//seize control of the server
	string cmd,temp
	
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif

	//stop the detector
	sprintf cmd,"http://%s:%d/admin/stopdaq.egi?viewdata",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif
	
	//change the preset (timer on histoserver is in 1/100s)
	preset *= 100
	sprintf temp,"%10f",preset
	temp = replacestring(" ",temp,"")
	
	if(modifyHistoConfig("COUNT_METHOD",presettype))
		print "couldn't set the COUNT_METHOD (startTimedDetector)"
		return 1
	endif
	if(modifyHistoConfig("COUNT_SIZE",temp))
		print "couldn't set the COUNT_SIZE (startTimedDetector)"
		return 1
	endif
		
	//prime the detector
	sprintf cmd,"http://%s:%d/admin/pausedaq.egi?viewdata",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif

	//release the control of the server
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif
	return 0
End

Function stopDetector()
	//stops the detector acquiring (red button), 

	//seize control of the server
	string cmd,temp
	
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif

	//stop the detector
	sprintf cmd,"http://%s:%d/admin/stopdaq.egi?viewdata",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif
	
	//release the control of the server
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (stopAndPrimeDetector)"
		return 1
	endif
	return 0
End


Function pauseDetector(pauseORrestart)
	variable pauseORrestart
	//this function pauses (pauseORrestart=0) and restarts the detector after a pause(pauseORrestart=1)
	//seize control of the server
	string cmd
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (pauseDetector)"
		return 1
	endif

	//pause/restart the detector
	switch(pauseORrestart)
			//GET /admin/commitsoftvetostates.egi?softveto1=true&softveto2=false&softveto3=false&softveto4=false

		case 1:		//pause acquisition
			sprintf cmd,"http://%s:%d/admin/guienablesoftveto.egi?vetodata",DASserverIP,DASserverport
			easyHttp/PASS="manager:ansto" cmd
			if(V_Flag)
				Print "Error while speaking to Histogram Server (pauseDetector)"
				return 1
			endif
			break
		case 0:		//restart after a pause
			sprintf cmd,"http://%s:%d/admin/guidisablesoftveto.egi?vetodata?",DASserverIP,DASserverport
			easyHttp/PASS="manager:ansto" cmd
			if(V_Flag)
				Print "Error while speaking to Histogram Server (pauseDetector)"
				return 1
			endif
			break
	endswitch
	//release the control of the server
	sprintf cmd,"http://%s:%d/admin/seizereleasecontrolconfig.egi?",DASserverIP,DASserverport
	easyHttp/PASS="manager:ansto" cmd
	if(V_Flag)
		Print "Error while speaking to Histogram Server (pauseDetector)"
		return 1
	endif
	
	return 0
End


Function oat_table(axis,binlim0,binlim1,numchannels,[freq])
	string axis
	variable binlim0,binlim1,numchannels,freq
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	string channel,cmd
	//sets the oat_table by speaking to SICS, not the histogram server
	//AXIS = "X" or "Y" or "T"
	//binlim0 is the lowest histogram bin boundary
	//binlim1 sets the next boundary.
	//all remaining bin boundaries are calculated in a linear fashion from this.
	//i.e. the bins are:
	//
	//binlim0
	//binlim1
	//binlim1+(binlim1-binlim0)
	//binlim1+2*(binlim1-binlim0)
	//...............
	//binlim1+(numchannels-1)(binlim1-binlim0)
		
	strswitch(axis)
		case "X":
			if(binlim0<-210.5 || (binlim0+(binlim1-binlim0)*numchannels) > 210.5)
				print "Error: x bins must lie between -210.5 and 210.5 (OAT_TABLE)"
				return 1
			endif
			channel = "NXC"
			break
		case "Y":
			if(binlim0<-210.5 || (binlim0+(binlim1-binlim0)*numchannels) > 210.5)
				print  "Error: y bins must lie between -210.5 and 210.5 (OAT_TABLE)"
				return 1
			endif
			channel = "NYC"
			break
		case "T":
			if(binlim0<0)
				print  "Error: T bins must lie between 0 and 1/chopper frequency (OAT_TABLE)"
				return 1
			endif
			channel = "NTC"
			break
		default:
			Printf "Error: couldn't setup OAT table, %s is not a valid axis (oat_table)",axis
			return 1
	endswitch
	
	if(numchannels < 1)
		Printf "Error: must have at least one channel for the %s axis table (oat_table)",axis
		return 1
	endif
		
	sprintf cmd, "oat_table -set %s {%g %g} %s %d \n",axis, binlim0, binlim1, channel, numchannels
	sockitsendmsg sock_interest, cmd
	
	sockitsendmsg sock_interest, "histmem loadconf\n"
	//TODO
	if(!ParamIsDefault(freq))
		sprintf cmd,"histmem freq %g\n",freq
		sockitsendmsg sock_interest, cmd
	endif	
	return 0
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//		Histo section over	
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma rtGlobals=1		// Use modern global access method.

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
//
//constants that are specific to each instrument
//
/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

	Strconstant ICSserverIP  = "137.157.202.139"
	Constant 	ICSserverPort = 60003
	Strconstant DASserverIP = "137.157.202.140"
	Constant 	DASserverPort = 8080
	Constant 	DASserverPort_bmon = 30000
	Constant 	DASserverPort_bmon3 = 30002
	Strconstant CHOPPERserverIP = "137.157.202.137"
	Constant 	CHOPPERserverPort = 10000
	Strconstant MOXAserverIP = "137.157.202.145"
	Constant 	MOXA1serverPort = 4001
	Constant 	MOXA2serverPort = 4002
	Constant 	MOXA3serverPort = 4003
	Constant 	MOXA4serverPort = 4004
	StrConstant PATH_TO_DATA = "\\\\Filer\\experiments:platypus:data:"
	
	
	//these motors are removed from the list displayed in the instrument panel.
	Strconstant ForbiddenMotors ="bat;two_theta"
	//where do you want temporary files saved?
	Strconstant Home = "D:temp:"

	//timeout for motors.
	Constant MOTIONTIMEOUT = 600

	//the max count rate you want on the detector
	//the slit will close to zero if you exceed this rate
	Constant FSD = 20000

	//detector axes.
	//these are the different axes that are downloadable from the histogram server
	//these must be changed from instrument to instrument
	StrConstant DETECTOR_AXES = "time_of_flight;y_bin;x_bin"
	StrConstant DETECTOR_CHOICE ="time_of_flight:y_bin=TOTAL_HISTOGRAM_YT;y_bin:time_of_flight=TOTAL_HISTOGRAM_YT;x_bin:y_bin=TOTAL_HISTOGRAM_XY;y_bin:x_bin=TOTAL_HISTOGRAM_XY;time_of_flight:x_bin=TOTAL_HISTOGRAM_XT;x_bin:time_of_flight=TOTAL_HISTOGRAM_XT;time_of_flight=TOTAL_HISTOGRAM_T;y_bin=TOTAL_HISTOGRAM_Y;x_bin=TOTAL_HISTOGRAM_X"

	//constants for creating a webpage with instrument updates.
	//on Platypus this is an apache webserver running on DAV1.
	StrConstant SAVELOC = "C:website:htdocs:"
	StrConstant HTTP_PROXY = "www-proxy.nbi.ansto.gov.au:3128"

Function DefaultHistogram()
	oat_table("X",210.5,209.5,421)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43000,1,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function testHistogram()
	oat_table("X",60.5,59.5,201)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43000,1,freq=23)
	sics_cmd_interest("::chopper::ready?")
End


Function aHistogram()		//suitable for 40mm HG
	oat_table("X",40,-39,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function bHistogram()		//suitable for 40mm HG with FOC
	oat_table("X",56,-52,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function cHistogram()		//suitable for 30mm HG with FOC
	oat_table("X",48,-46,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function dHistogram()	//suitable for 40mm HG with FOC + 50mm St4vt
	oat_table("X",64,-56,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function eHistogram()		//suitable for 25mm HG with FOC
	oat_table("X",21,-19,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function fHistogram()		//suitable for 30mm HG with SB
	oat_table("X",25,-24,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function gHistogram()		//suitable for 7mm HG with FOC
	oat_table("X",10,-10,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End




Function hHistogram()	
//suitable for hslits(44,40,37,44) which gives a 40mm widebeam onto sample with FOC guide.
//this was measured by Zin Tun and Andrew Nelson on 23/12/2009
	oat_table("X",54.5,-54.5,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function iHistogram() //Bills SAW, hslits(10,4,4,20)
	oat_table("X",5.5,-5.5,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function jHistogram()		//suitable for hslits(44,35,35,43) "SB"
	oat_table("X",35,-35,1)
	oat_table("Y",110.5,109.5,221)
	oat_table("T",0,43,999,freq=23)
	sics_cmd_interest("::chopper::ready?")
End

Function hnotify_registration()
	//the purpose of this function is to ask SICS to notify FIZZY when anything changes on the instrument.
	//normally one can use hnotify / , which notifies us of all changes.  However, when the attenuator is oscillating
	//this results in too many incoming messages.  Therefore, we have to notify on everything EXCEPT the
	//attenuator.  The tree structure that one can notify on can be gained by using this hlist / command.

	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	string cmd = ""

	cmd  = "hnotify /monitor 1\n"
	cmd += "hnotify /experiment 2\n"
	cmd += "hnotify /sample 3\n"
	cmd += "hnotify /entry 4\n"
	cmd += "hnotify /data 5\n"
	cmd += "hnotify /commands 7\n"
	cmd += "hnotify /user 8\n"
	
	sockitsendmsg sock_interest,cmd
	if(V_Flag)
		Abort "Couldn't register hnotify on interest channel (hnotify_registration)"
		return 1
	endif
	
	cmd = "hnotify /instrument/run_number 10\n"
	cmd += "hnotify /instrument/detector 11\n"
	cmd += "hnotify /instrument/status 12\n"
	cmd += "hnotify /instrument/slits 13\n"
	cmd += "hnotify /instrument/collimator 14\n"
	cmd += "hnotify /instrument/source/cns_inlet_temp 15\n"
	cmd += "hnotify /instrument/source/power 16\n"
	cmd += "hnotify /instrument/status/secondary 17\n"
	cmd += "hnotify /instrument/status/tertiary 18\n"
	cmd += "hnotify /instrument/parameters/mode 19\n"
	cmd += "hnotify /instrument/parameters/omega 20\n"
	cmd += "hnotify /instrument/parameters/twotheta 21\n"
	cmd += "hnotify /experiment/file_name 22\n"
	cmd += "hnotify /instrument/polarizer 23\n"
		
	sockitsendmsg sock_interest,cmd
	if(V_Flag)
		Abort "Couldn't register hnotify on interest channel (hnotify_registration)"
		return 1
	endif
	
	return 0
end

Function vslits(s1,s2,s3,s4)
	//drives the 4 slits to their respective positions
	variable s1,s2,s3,s4
	variable err = 0
	string cmd=""

	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest

	if(checkDrive("ss1vg",s1) || checkDrive("ss2vg",s2) || checkDrive("ss3vg",s3)	|| checkDrive("ss4vg",s4))
		abort "One of the requested slit positions is not within the limits (slits)" 		
	endif
	cmd = "run ss2u "+num2str(s2/2)+"\n"
	cmd += "run ss2d "+num2str(-s2/2)+"\n"
	cmd += "run ss3u "+num2str(s3/2)+"\n"
	cmd += "run ss3d "+num2str(-s3/2)+"\n"
	cmd += "run ss4u "+num2str(s4/2)+"\n"
	cmd += "run ss4d "+num2str(-s4/2)+"\n"
	cmd += "run ss1u "+num2str(s1/2)+"\n"
	cmd += "run ss1d "+num2str(-s1/2)+"\n"
	
	SOCKITsendmsg sock_interest,cmd
	if(V_flag)
		print "Error while positioning (slits)"
		abort
	endif
	
	return 0
ENd

Function hslits(s1,s2,s3,s4)
	//drives the 4 slits to their respective positions
	variable s1,s2,s3,s4
	variable err = 0
	string cmd=""

	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest

	if(checkDrive("ss1hg",s1) || checkDrive("ss2hg",s2) || checkDrive("ss3hg",s3)	|| checkDrive("ss4hg",s4))
		abort "One of the requested slit positions is not within the limits (slits)" 		
	endif
	
	cmd= "run ss2hg "+num2str(s2)+"\n"
	cmd+= "run ss3hg "+num2str(s3)+"\n"
	cmd+= "run ss4hg "+num2str(s4)+"\n"
	cmd+= "run ss1hg "+num2str(s1)+"\n"
	
	
	SOCKITsendmsg sock_interest,cmd
	if(V_flag)
		print "Error while positioning (slits)"
		abort
	endif
	
	return 0
ENd

Function setExperimentalMode(mode)
	string mode
	variable err=0
	string cmd = "::exp_mode::set_mode "
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	Strswitch (mode)
		case "FOC":
			cmd += "FOC"
			break
		case "MT":
			cmd += "MT"
			break
		case "SB":
			cmd += "SB"
			break
		case "DB":
			cmd +="DB"
			break
		case "POL":
			cmd +="POL"
			break
		default:
			print "ERROR: mode "+mode+" is not allowed.  It should be one of MT,FOC,SB,DB (setExperimentalMode)"
			err=1
			break
	Endswitch
	print "__________________________________________________________"
	print "Changing modes - switching collimation mirror, may take some time"
	print "Be careful, combined omega_2theta motion is now different"
	print "__________________________________________________________"
	
	sockitsendmsg SOCK_cmd, cmd+"\n"
	return err
End

Function omega_2theta(omega,twotheta)
	variable omega,twotheta
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	if(numtype(omega) || numtype(twotheta || omega<0 || twotheta<0))
		print "ERROR: omega and twotheta must be greater than zero and NOT NaN or Inf"
	endif
	sockitsendmsg SOCK_cmd, "::exp_mode::omega_2theta "+num2str(omega)+ " "+num2str(twotheta)+"\n"      	
End

Function attenuate(pos)
	variable pos
	//pos = -1 take the attenuator out
	//pos = 0 park the attenuator in the beam
	//pos = 1 oscillate the attenuator
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	switch(pos)
		case -1:
			sockitsendmsg sock_interest,"bat send oscd=-1\n"
			if(V_Flag)
				return V_Flag
			endif
			break
		case 0:
			sockitsendmsg sock_interest,"bat send oscd=0\n"
			if(V_Flag)
				return V_Flag
			endif
			break
		case 1:
			sockitsendmsg sock_interest,"bat send oscd=1\n"
			if(V_Flag)
				return V_Flag
			endif
			break
		default:
			print "Useage attenuator(-1), attenuator(0),attenuator(1) (attenuate)"
			return 1
			break
	endswitch
	
	return 0
End

Function UserDefinedEstopBehaviour()
	//this function is called if the Estop button is pressed.
	NVAR SOCK_interupt = root:packages:platypus:SICS:SOCK_interupt
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest

	sockitsendmsg sock_interupt,"INT1712 3\n"
	doxopidle
	sleep/t 20
	sockitsendmsg SOCK_interest,"bat send oscd=0\n"
	sockitsendmsg SOCK_interest,"run ss1vg 0\nrun ss2vg 0\nrun ss3vg 0\nrun ss4vg 0\n"
	sockitsendmsg SOCK_interest,"run bz 250\n"
	print "performing Estop - stopping motors, stopping acquisitions, closing slits, putting attenuator in"
	fpxstop()
	batchScanStop()
End

Function Instrumentdefinedclose()
	//called when FIZZY shuts down (SICSclose())
	NVAR SOCK_bmon3 = root:packages:platypus:SICS:SOCK_bmon3
	NVAR SOCK_chopper = root:packages:platypus:SICS:SOCK_chopper
	NVAR SOCK_MOXA1 = root:packages:platypus:SICS:SOCK_MOXA1
	NVAR SOCK_MOXA2 = root:packages:platypus:SICS:SOCK_MOXA2
	NVAR SOCK_MOXA3 = root:packages:platypus:SICS:SOCK_MOXA3
	NVAR SOCK_MOXA4 = root:packages:platypus:SICS:SOCK_MOXA4
	
	NVAR detectorSentinelThreadID = root:packages:platypus:SICS:detectorSentinelThreadID
	
	sockitcloseconnection(SOCK_bmon3)
	sockitcloseconnection(SOCK_chopper)
	sockitcloseconnection(SOCK_MOXA1)
	sockitcloseconnection(SOCK_MOXA2)
	sockitcloseconnection(SOCK_MOXA3)
	sockitcloseconnection(SOCK_MOXA4)
	variable temp = threadgrouprelease(detectorSentinelThreadID)
End

Function Instrument_Specific_Setup()
	variable err = 0
	//this function chains the platypus hipadaba virtual motors to the hipadaba real motor.  This means that when
	//a real motor moves, then the hipadaba virtual motor is updated.  This is because we need to see
	//updated positions for everything.
	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	string cmd = ""
	
	//setup a sockit connection to get the current anode pulse rate from the detector.
	variable/g root:packages:platypus:SICS:SOCK_bmon3
	
	//setup sockit connections for the MOXA box at the sample area
	variable/g root:packages:platypus:SICS:SOCK_MOXA1 = 0
	variable/g root:packages:platypus:SICS:SOCK_MOXA2 = 0
	variable/g root:packages:platypus:SICS:SOCK_MOXA3 = 0
	variable/g root:packages:platypus:SICS:SOCK_MOXA4 = 0
	
	variable/g root:packages:platypus:SICS:bmon3_rate
	variable/g root:packages:platypus:SICS:bmon3_counts  = 0
	variable/g root:packages:platypus:SICS:detectorSentinelThreadID = 0
	variable/g root:packages:platypus:SICS:SOCK_chopper
	
	NVAR SOCK_bmon3 = root:packages:platypus:SICS:SOCK_bmon3
	NVAR bmon3_rate = root:packages:platypus:SICS:bmon3_rate
	NVAR bmon3_counts = root:packages:platypus:SICS:bmon3_counts
	NVAR SOCK_chopper = root:packages:platypus:SICS:SOCK_chopper
	NVAR SOCK_MOXA1 = root:packages:platypus:SICS:SOCK_MOXA1
	NVAR SOCK_MOXA2 = root:packages:platypus:SICS:SOCK_MOXA2
	NVAR SOCK_MOXA3 = root:packages:platypus:SICS:SOCK_MOXA3
	NVAR SOCK_MOXA4 = root:packages:platypus:SICS:SOCK_MOXA4
	NVAR detectorSentinelThreadID = root:packages:platypus:SICS:detectorSentinelThreadID

	//start a thread up to monitor the detector
	detectorSentinelThreadID = threadgroupcreate(1)
	ThreadStart detectorSentinelThreadID, 0, Ind_Process#detectorsentinel()

	//listen to and process the detector rate.
	make/t/o root:packages:platypus:SICS:bmon3_buffer
	Wave/t bmon3_buffer = root:packages:platypus:SICS:bmon3_buffer
	sockitopenconnection/time=2/q SOCK_bmon3, DASserverIP, DASserverPort_bmon3, bmon3_buffer
	if(SOCK_bmon3>0)
		sockitsendmsg SOCK_bmon3,"REPORT ON\n"
		sockitregisterprocessor(SOCK_bmon3,"Ind_process#processbmon3rate")
	endif

	//speak to the MOXA box at the sample area.
	make/t/o root:packages:platypus:SICS:MOXAbuf
	sockitopenconnection/q/time=2 SOCK_MOXA1,MOXAserverIP,MOXA1serverPort,MOXAbuf
	sockitopenconnection/q/time=2 SOCK_MOXA2,MOXAserverIP,MOXA2serverPort,MOXAbuf
	sockitopenconnection/q/time=2 SOCK_MOXA3,MOXAserverIP,MOXA3serverPort,MOXAbuf
	sockitopenconnection/q/time=2 SOCK_MOXA4,MOXAserverIP,MOXA4serverPort,MOXAbuf
			
	//speak to the choppers
	make/t/o root:packages:platypus:SICS:chopperBuf
	Wave chopperBuf = root:packages:platypus:SICS:chopperBuf
	sockitopenconnection/q/time=2 SOCK_chopper,CHOPPERserverIP,CHOPPERserverPort,chopperBuf
	sockitsendnrecv/SMAL/TIME=2 SOCK_chopper,"user:NCS\r"
	sockitsendnrecv/SMAL/TIME=2 SOCK_chopper,"password:NCS013\r"
	
	//set up the notifications you want to receive.  In general, this should be all of the motion axes, etc.
	err = hnotify_registration()
	if(err)
		print "error with hnotify_registation(instrument_specific_setup)"
		return 1
	endif
	
	//get all the values in the hipadaba tree
	getCurrentHipaVals()
	
	//setup the default histogram OAT_Table
	bHistogram()
	//	defaultHistogram()

	return err
End

Function scanReadyToBeStopped(currentPoint)
variable currentpoint

//string filename = gethipaval("/experiment/file_name")
//this function is called by scanbkgtask (fpxScan) and can be used to see if a scan point should be finished, e.g. enough stats, etc.
//return 0 if you want the scan to continue, return 1 if you want the scanpoint to stop.

return 0
End

Function experimentDetailsWizard()
	//sets up default:
	// /experiment/title
	// /user/name
	// /user/email
	// /user/phone
	string experimenttitle="", username="", useremail="", userphone=""

	NVAR SOCK_interest = root:packages:platypus:SICS:SOCK_interest
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd

	string lhs="", reply, cmd

	//sockitsendnrecv/smal/time=1 SOCK_interest, "\n"
	sockitsendnrecv/time=0.75 SOCK_interest, "hget /experiment/title\n", reply
	parsereply(reply, lhs, experimenttitle)
	if(!stringmatch(lhs, "/experiment/title"))
		experimenttitle=""
	endif
	//print lhs, reply,experimenttitle
	prompt experimenttitle, "Experiment title:"

	sockitsendnrecv/time=.75 SOCK_interest, "hget /user/name\n", reply
	parsereply(reply, lhs, username)
	if(!stringmatch(lhs, "/user/name"))
		username=""
	endif
	//print lhs, reply, username
	prompt username, "User Name:"

	sockitsendnrecv/time=0.75 SOCK_interest, "hget /user/email\n", reply
	parsereply(reply, lhs, useremail)
	if(!stringmatch(lhs, "/user/email"))
		useremail=""
	endif
	//print lhs, reply, useremail
	prompt useremail, "User email:"

	sockitsendnrecv/time=0.75 SOCK_interest, "hget /user/phone\n", reply
	parsereply(reply, lhs, userphone)
	if(!stringmatch(lhs, "/user/phone"))
		userphone=""
	endif
	//print lhs, reply, userphone
	prompt userphone, "User phone number:"

	Doprompt "Please enter the details of the experiment.", username, experimenttitle, useremail, userphone

	if(!V_Flag)
		cmd = "hset /experiment/title " + experimenttitle + "\n"
		cmd+="hset /user/name " + username + "\n"
		cmd+="hset /user/email " + useremail + "\n"
		cmd+="hset /user/phone " + userphone + "\n"
		sockitsendmsg sock_cmd, cmd
	endif
End

Function restartBMON3()
	//setup a sockit connection to get the current anode pulse rate from the detector.
	variable/g root:packages:platypus:SICS:SOCK_bmon3
	
	variable/g root:packages:platypus:SICS:bmon3_rate
	variable/g root:packages:platypus:SICS:bmon3_buffer
	NVAR SOCK_bmon3 = root:packages:platypus:SICS:SOCK_bmon3
	NVAR bmon3_rate = root:packages:platypus:SICS:bmon3_rate
	NVAR bmon3_counts = root:packages:platypus:SICS:bmon3_counts

	make/t/o root:packages:platypus:SICS:bmon3_buffer
	Wave/t bmon3_buffer = root:packages:platypus:SICS:bmon3_buffer
	
	sockitcloseconnection(sock_bmon3)
	sockitopenconnection/time=2/q SOCK_bmon3, DASserverIP, DASserverPort_bmon3, bmon3_buffer
	if(sockitisitopen(SOCK_bmon3))
		sockitsendmsg SOCK_bmon3,"REPORT ON\n"
		sockitregisterprocessor(SOCK_bmon3,"Ind_process#processbmon3rate")
	endif	
	CustomControl cc3,pos={400,5},size={300,200},proc=MyCC_MeterFunc,value=root:packages:platypus:SICS:bmon3_rate,win=instrumentlayout
End

Function regularTasks(s)
	//this function gets called ~ every five minutes.  Use this for housekeeping tasks.
	//ADD your own user functions in here.
	STRUCT WMBackgroundStruct &s

	//make sure the detector rate monitor is connected
	NVAR SOCK_bmon3 = root:packages:platypus:SICS:SOCK_bmon3
	if(!SOCKITisitopen(SOCK_bmon3))
		restartbmon3()
	endif
	
	//update the webpage status
	createHTML()
	
	return 0
End

Function/t ChopperStatus()
	NVAR/z SOCK_chopper = root:packages:platypus:SICS:SOCK_chopper
	Wave chopperBuf = root:packages:platypus:SICS:chopperBuf

	string chop1,chop2,chop3,chop4
	variable ch1speed,ch2speed,ch3speed,ch4speed
	variable ch1phase,ch2phase,ch3phase,ch4phase

	sockitsendnrecv/SMAL/TIME=3 SOCK_chopper,"#SOS#STATE 1:\r"
	chop1=S_tcp
	ch1speed = numberbykey("ASPEED",chop1,"= ","#")/60
	ch1phase = numberbykey("APHASE",chop1,"= ","#")

	sockitsendnrecv/SMAL/TIME=3 SOCK_chopper,"#SOS#STATE 2:\r"
	chop2=S_tcp
	ch2speed = numberbykey("ASPEED",chop2,"= ","#")/60
	ch2phase = numberbykey("APHASE",chop2,"= ","#")

	sockitsendnrecv/SMAL/TIME=3 SOCK_chopper,"#SOS#STATE 3:\r"
	chop3=S_tcp
	ch3speed = numberbykey("ASPEED",chop3,"= ","#")/60
	ch3phase = numberbykey("APHASE",chop3,"= ","#")

	sockitsendnrecv/SMAL/TIME=3 SOCK_chopper,"#SOS#STATE 4:\r"
	chop4=S_tcp
	ch4speed = numberbykey("ASPEED",chop4,"= ","#")/60
	ch4phase = numberbykey("APHASE",chop4,"= ","#")

	string retStr = "CH1speed:"+num2str(ch1speed)+";CH1phase:"+num2str(ch1phase)+";"
	retStr += "CH2speed:"+num2str(ch2speed)+";CH2phase:"+num2str(ch2phase)+";"
	retStr += "CH3speed:"+num2str(ch3speed)+";CH3phase:"+num2str(ch3phase)+";"
	retStr += "CH4speed:"+num2str(ch4speed)+";CH4phase:"+num2str(ch4phase)

	return retStr
End


//
//
//
//draw a layout of the instrument
//
//
//
//
// JPEG: width= 961, height= 667
Picture platypuspicture
ASCII85Begin
s4IA0!"_al8O`[\!<E1,!*9.#s8E!<;f?8iG@>N'3Zq.2@rcL/De=)6:M+3Q@qG\p!(-_n#6tM>"pt
VA#R^tH$P"!b%LijW*>K>%(aC+K,U+<S+XS]u0.&,).3Tlh5qt2V4$Ghl,q_SW6Tdmu4[(t-gAjSA$
4@4O%1X?h&0*b[+t,N74$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,Mc4$,M
cs1eUH#QftfX9/JI!!3`5!tbS6_uLbW!<<0'!<E3$zz!!EH,!sSc2#lhgC<Y,63!s/T-"9eu<"9Sl1
":"r-!WrQ;"VMt5'1#J",%5I*14bRm#9uQVTtqHh1Ggse@WHRrdI9'#_VlemnJ4J[;cIn&AA]312e,
j?KTi.*e,R>d)?Bj=!s&E'zz!!!!"!WrQ/#62UA.M2[^!!33'!W`E*!WrH'!!!!"!YGMX&hu[L"<oU
0E>(-ZTom1MnGh;E"99kMg&MN`!<<05!tbMt!;e5i+<i!2+s8'R![8a2+p&r2VX516.Jl7:!S#X7F]
D1X.I!hbRF4&&T-1La?aW8.,,1[,&"a<L.;WUmQlEH9oiqr\L><Rtb$:=**:+I]_eFNBfR3-?]1\UJ
m0sj3hV.lD44sPbR-J[=Ii"8..jnkLm=I#ZT'4#@g0(/jF3GR58n?Wt>9j5i5kA6h1\-BRiAmAANie
G:hge0cSl]nipKW`:kP_(@-"go4F_n]?1@3B'b7Jdl2]$K(E48(I'J^O2&Z!Ho[l3Y<dPM0_!#CcZm
2NO`X/btnm/u35'U3_0aA,S*\@nZ9f2M\L0<nNKg\/('dJarEZ+7D<KFGT(kEVigKh`L"TEsP!`&dk
EHb75r!)g:FWn[mm0tn0HO4eOHX*DHt61Trfl;j5YLbTYdk\TbiP27c7kM@"LKD_i>kugfBiNK%sBY
<h?lmJ4E\/n^V$"Zae0X\fn+0XB"f:F>3+!V27>:n\i*.U,!W\+l:cucZl<msQ;9/@oL<eiEr2\$".
?O+DeXBW#PQf5=tM58BIE\og4/Z$ME#[^TuT53HR.j^&AH8T453Uql:Bkc89g[&(uFI,IQMP,c]#`+
"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL
d1pdq^Nd4+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a
2+p&r2+tcs)rNBfB)lT^,f2jqUS41?ro-9`c-N='XA@CbIh'2cjA(5MW2&IQ6&pf:`.2n"HH].mNj?
:5,0Q;W#nO+2sLA>40ZU[@ZHHt\b.X@h#`U>,G/ier5R)VqMG?:ECj//E-okl*8ASYOh.2O9$!rVn[
d4s/#<__E$%2-i?Z8M5GGB#YS\95#S,/[M8C'^@/WGcm(%=[3>:5TfS&<8[1BO9A+1&FU=:^)BR=I-
)M/5&t+7WT?C`!^D>#U72!\s?O(/Q&3Dl=\#9-LDoLB5_EYC<DGHXJ!L>WhGd,l68/IYAuX]I3<g7Y
)Pr?#"m[RBcu[u+HL28\<!n<?aPpgP7BB+S19=cAF](+lX*$''m./3ft:4XZ^CA"\Xb$$]QF\[=V!\
]OEDVpp,juF_ss1E4s*bGfI`IIfuuT!%\WS3c^$UaC*G.'6pq/G5X\!C6pO.."@PLC6m)HVq^Nd4+s
I(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4
+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+qO_%q^Nd4+sI(4+<i;<dGsltSAJW=3uoQLOsl
g4O!*,bjg#6=g@hH6%23HSjbrVf:T,A=$(jgV3Y#5q-cpb;b:H/?+`rt^\^"]\EH?XlaPm!6hTKH99
i4%JL*8";=cMN_2W?sb`]OJ\\!#,I;V'B[9qNeZ7tIE8YQ,/="kQL/q"=3U^>;[_a\iLR/"IMscS!3
!qLSC+HH%]u#ifT6=tBXh!$kDs(g.P^b[@X[U<:YaER[W#0.aE7o#fu#0.aP7@qAMg$NekebKD$V6I
t:u">!2FBLHrXg1lMX5,6OSC8IboI5oOO@q%P0_VSJ(\Vdg*hZ`gIJ@1X:j=Z#D:J-Q^7dh,oX+&IU
(NRV8.g2!JY@E:(RViC<$Zp,a'9(pQ"Msk]6^nX0hb6c)I_(GX-`F<A=QRTqD>(nQ[K5.,3uF8E8qo
B]Z2-@=%G::L0E/C-U?Yc[=m]W0'ETI$+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+
p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sIQte,(U=+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a
2+p&r2+sI(4+<i!2+s8'R![8a2+q/"EOMps+G[tW)F.D8uco37uA$l$trMJre)?>!n3RH0\Ce$K[p=
&F;Zh[)2jJ/N3#,F/G[!^oM+L.9pk@;hHikB7),DMboZ.>);Ks?Pq,JL>4S%YG'hi;LF1Wo.MWcl9Y
_IO7672D-3)AaH-b`U57]qV;:OQF\kpZhKiG?^ss1fa;k)]B.<F##r?+Ih#E=l4G>>V31P2.q`Y7A.
ZDb:Jb[(/$3[]Wqr^]X#]%A/ag#=kS(3;5gm3>.3+!RR%Je.?X&GXD[GhFgdkf5esd.eDbF9+Gr8&+
ZaXWn\7kGQVcg&hO>WHe5NSXj-@XIljC%1e5XC<fp`pd.;PAjAq2END;jW`b27l\aQV_qRloHo$rPj
*4WSKjckMf*fV;Of'jYl_ciZY9U`Wti.XHB9VL+doCuWju3^5u>FZP[KW^mtZRU0K]ShYS[c)konlr
9<`Q8.DZoM[YmZ$NA*_f4($q$$[`NK92*>YogBG+O:]`_AW?)0O`fCtJ'Y+94QtY"i)fk#bDV4I4Cb
OW8iLCWB=29UV9k[s,PV4SX"qA>AP*SF*0gg,<p1H)7T[Nhr8#^W_/2nI)$tS6nW6SXm.u"B^D1D/m
m"II"K2pW?ei5fQ^^[(`"C)B(*)cd%$ae%_KG78i)=^8Qnn'96LgjZagrXH%Ib=eOHl4WMqL5&,D<6
ps:.6j,nC6pq/G63#I3.O#uZ+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r
2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R&-(2W.b@Np*A
'+U'0@ab0YQW#YQEp&>W9fK0-re(9n^=EkGrae(BqXJl.nKsc2RcP9UiU^\rHk*`8?PaPuY.n^6%>Z
F?(LXe8,HUII6*jGO'#HRK.`5.s[NB*t8I8V0O5DYd,D0%.:H*3QB=V:!TF-lDNSPK>acJ,a000!':
#'fk&\sl!.7D7`Z`h;2[/gZUOQq22_'CQ`.Q'THa&RUj/23U4J;jQ<>jlK,Z,'[T]Pnc$5*mLJ6ZG%
`!OunEJI.OuS*3NlFs'!.mK+2W`DfLHORPQE^3S98@rAdjXo!4MU0eWMoGIQm$I4Tu-8\gkk0@H3FY
ISk>NlZ=IH_?Rpj!fA"fVXniklP0YY3D;r^uhfH.Ge'#fanAS6GGc>$ic4:mb4$^h,r;=:ZZplEU!g
pP+-?l(A2DY9rppkYh*F-J(HW/:TTkeK/]%`l@G:GG60uAgIk*11?CTVke!Gadt)h319UC<T:GkElK
r2^(BOZIo^eRoR._&/%F"u'ipoS#(3YljK<37f<tn$olSY-E*Q0a@:?f]f.2<X#N*eNP\p_a;o^`;(
7"HSG0LC+jrQ:-6+[dAO?lrq0<P@asW>'mtI`C2'Q>XG[X_SAA2C]-V@O8#oFCqT!/oECnk#q@q0G>
X=>Qd?ECMWF=pO%]eZr;E:r,"2ceX2_T<s8>po7Z:;P"oar1fG&4TOXOG^2Q779=77l/`IQl+dO\_J
cR+`ESbNd]%5(!0,g;P6[+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s
8'R![8a2+p&r2+sI(4+TL$i.O#uZ+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2
+p&r208T=_'fc3nB^0?k06Ak/5l`P17`E7<bBAg=&m*Vq>DP?Lm'\'<^uFLp=u&(F_`)bsNahbV08V
SW;aVh5H^Ns&6j\%)j>V7p[-"gVRdEe\\pGk@1ZsQu3=s#=lIOj34m'q\MDdg8,%.`ZgnS1A<+1lD<
gNdg+D$:r(E\2.IB)7EK_\9klG\(V*j8Tpe/9J#&7iFA5YE<jOOfaY_4dUaP@+G$F3D@T].R_/"'Q.
lM<LY_:$>;oho)U`>2s4U\.2eFmOMJi?Vh`n7L5!^qBnr3SN#<j<@qcND+V0B4M&1bR*iCrVtF3S8$
nMXW`'sOA8&W=$f0FrI_=1m9$3Kf@:3p\!/J;^%jU;!%]+%T`W;`dV6PjUEVJ2b][!um285>+Ea-p8
((Ib7*&dD%qasGRLkJelP"5k0Xg938X8GNQd!J`bci=/VTNTrnASD>a=P7Mr`7Srmo.%WZ(+#tCfY/
@,Z`9JS[A32QlkctHpl12"<-<6eJZE6(h)-]I.J>#&X:&'s-cABu%h-\==lsKqhP*4KXH'*m,mtrB,
?$;#^=s)rGscR/dB+%sfi[B!?)1]Xlrh`f19WbI6RIcFn_X!0*CAUbSQIZ6`]6uN/5AgAfdc54DHWV
;^ME%;aH>Mm?Wb,@:PAFr45oiudK+R/nWlXi[-MN!fmJM$XUU9::$EA?a\OV?9,!4g4em.k>^Q+0hU
-`2"8PEXOfbM$+aiVpH<`]OO5=7_q7#.kqC:c87Zog43L_i\2XPQ]pLT&EHVW!$&O7Na![8a2+p&r2
s4@,t+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i
!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sIPir2S>Te)C(?()oggQ<(NiRK+HP!(LsNo
>e';$uTZ][*7M+:-)X)>CRC9I%\_9Ir&jKSWl#<USismgpP$]_**"JjrGsejH.=Hr+UD!+02(.*2At
d`dX1:G.#2^/YWju*APi8LG,u&2.?Oe_dT;4D`X=[s3Sk(LqOO0Y?-O4,Zq6HA;eAlP)h=RcH9a(Zr
kOB+j%IULRQmIXb%omi(+iBqu6Y)5cL&A3^D+YWiC'_>CQ$FGmshWU+LdqWLT:?$qDjcBbkcnCQ;^%
9nio3eAO5GI;ILE(I%0W$76Q_fd??H&D1^*^;\[[rYkZ5puc.UlLXUurRuGd,F,oHI`4nQ7uiP]ZqP
Vu-/UepQCh:TPG%DC_a@TGd9m-.kS=lZR%`sgd_Ap,be)3=U=udT06:74pUE)_(F5IM'K4Q(Y;:.OG
La3.'&Mt_rpeImZ=G/g&=QZgb,FP4=<KY0O`GZhER9Um^P/E?QtRq)FCuhf,7JCIo,DK+4mFXlg5dN
`IgP\ri\^:$bT%%-bZ`iD/p2s%Tpc<9aO<omVCZ^2VQcC/+N%SWO4[F@#L+Z_W_PC12eaB=Yl;`*p7
E)\Za(\S]:=:M0O15_:P-nC27cN5'\%6sNO07O(N+Mj19m:UZ&&TW1J&E0c">5)k&q&oC7iZ_%"G4r
gn3FJDeHar1Kqp]=N9G3NRe)3Cfd7Pq:NmLLMi&1/XskA46A<>aWB%6aPP.C[=a2#cKh(h'8PNOa0"
^F/2n?QSh$Leo9]DE5Op;:9D"GJ!.HT7G@'=%eO.5g==1'WcH!3J1$&(sEIE*IBh).sr68.JAT#fi1
(L)"_*Z%0j#,^t4pk5]'#u4EZeFSJUS-`0<O(h2ZqW,S3K$<gm\a\)Z<!9DAk[K16/F,/9Ws,V!lbI
YA<UVtlg>,WRMt7&=t\e7[\W7*1cUbD+&HUdk,=/)hCa]%O6*<$46,D%Ysu\``K$Bi^p@5,MmPI78`
ci#n_IbP;!CKF^1W2)ALn&1]6#qmOg^TZ>dngG5(GgsWo@Mm;2.rV95AjZ0B6lGhX\?%.oYRG_;]fe
R-G[Mn&W4lCFJ-/#IIiB7bdhVDO.*9`f?FoK3QRX^dh7E?Q;SeE5.XocXIQTB:76ZqBhlE/%!p@#m8
mMf3&O0<'o92Og7IG$XU_i8"0A<lBrV19U++OS0<*dqio;`[$\=8.QH(%T*-9l4tcA^qW\GZd$no(H
rVdTi-p;IanBf;)[#I386mmAeiQV16+1:$WpPh\hZ_R4#e8A!7#6YLLkl=mJ;B!eLk(;;#`+"eL^8f
eLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+-5dJGC;+<i!2+s8'R![8a2+p&r2+sI(4+<
i!2+s8'R![8a2+p&r2+sI(4NJUZ*57=No$kaIl+"1PUc'>*Yrkold`%']Da"](?BcQ?tW1J7)OGao:
.h99Ph.r[;XfdA/JYAaO]?S41?[5h'>#V%E=e?[PDm7!*[l.0hf%t-&^Zr,]bMV\m;KnrbV3:LsFBY
N(/6Ac*?E=`@ArFXn%oISVP!KdWOGeiM\:M>D\d`<BMU9]H\pj7`??Z&PIB'#UT3G?&dN%Kn_hR1%(
Xl0*;Q=!eCakKY**SLug^^5?Xu?$$ei6nXe%2CP70(Kbm@0O;F]i&=KUJflBqrQgH"_Hua.;dRXj3F
&[`/bF=`=Jjl2.`HeonuoctjJR.V1GTW"*usWA;717Y><8m($&gM3,U,S*I4^?]Vm(FuCZ#cs6;L[A
)`G?iok3`#lmiS:D!;gn6XZ?.s)_]"P\,7LBI>>;McUSaM`p=::\6`=`^)<dtb^!4c7\a9tEre^08.
NBst-/\JPtfu<_lTr>m(9sa,Uhp#qD?*(<>9dr/"W-can5fXX[9=sT!g);VQI26g$`<e/,HcO]_\T<
O_h.rYSl9i_bIjeXnh(3j9ned"\qM2[6C`L^qgRqkKk"]5X?OV:Ah@#&tq,Z+\OYFL>#./8Cb<t.^#
LA#o9cu$(O)<c-K,MCuR`UO!R?G?-/?CdI<6VRb>`@e,Dr@D@@PlRiOS?jo;Xpm6h/@pnZrc5a*,tj
ZpODF$q6J<@i0-pX"6>V2B">!Q!SskkYg(PLP+fhZKXK7>PR!:P7"k;Ph>Gj8Wk+Y^'0M[mjU3*%oB
YdIrD58Y_SLD,amg9hIO2\iQ\;oOSp%g+dRlg\C2L,2b_8uKJ8lH`h6E$JfiaY'dmR`:]I_Y(^[t_"
hpWE_8MdY7FA6b=0[/.!$XN%_%^FI1@5T`_k(p6r'<-p38#YrY"@%fk[jGCkhZ!T'G[%&W>/s>E[@<
%(WF$?!H$*=u$SuF+KFi;G>FNNq9U8UY0P)gdRK1ZMdLNtohj1l+ob"p-&#b?i3_8&To67oUh=0q.0
6$8-Sk.O9,D;c8]PI_:7QH%e<S$SkGi+r[ILW3]M6l>acR+:Dd!O>QJpCTHS22nr;E2b[o[@`!\Il8
.L9Z<3)[;3#Yq9#Gq\<_+Uhr1Ha;D&RX[H2ZdDUm)gJc!J52r]7`>so#W`Lqp`u@JBY$nZJL@RP$(2
/nHnnIBX7#Yh<mg&&\rB6&8Z^n\/m*j]al@WA-*V5@`r6e%dDW?T&QZVl\[)7Pp73gl<1V*?g><^n1
ed>AQ`<K`b9TM-7Oe<5i<o^Tb(%f]t[J1LkaF,!>J5%h@$?s-@6#FGVK",=D,BGTaE9bnpn[WAmT._
*"jNHiOBKm5s/#U;JACu$0oL5+RE&uCXqi]i9T,T7d1WB&U>^'iXDX+7aiRkMRN`UeKWK!]D+ht$ql
CNUirnB'EB4[[]+sMP*6m)HWq^Nd4+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r
2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+=]S/<67ed$q<eYh9h&(Dq
02e:U\P,nQ1X8q*_2u4d;*71m_3:*).Yc6-l`gQrMCF^7QT0?J#6p_(n6f26eAT+SZBQSV@O$aX9$i
lh_.*!EVcA*@r`GmM)e<Ko,f&=lI.'#`gp'kKN3m:-IF-9hcqiH4%[XgT:ZFY?!STW>VH$k_&oa030
L5eRYH)N\o-^I0Uf=QJTMeH<g@`oa?htD.RG;[uNQ9CMCucMMjkPl@Us!Y<D$fGYE$Sro]nB-?u><P
+N5C?1fj58+Oj8cA1(q)\.D4Z5Dq$@2qdAHgErNWD0>qQ$)G$Oj#p98?iB=efJIH8bZ,J&2N5UG#?)
RD[niNV=_I<_+ImFiXeArosbf^;XSc!>?6js<f,SNX.k-K4?@@'"H*9-E_ZJNQM"<\M8b8DJrTFU+q
>:&"6bnbIjGt<6si]CYf,4#1LgJV$Q!VS\(f/He$ZCH`/S`G2-PSbI2@28/HcVNe.KrE'i/@G\!BT*
)TL9ii_G+pQRA`753noCK9%i8n2=l;4kf(%T\*A9DD0+W;*6[o&lm3`@/7=eB!`V<@/g4IX6MFkadK
M0!"Cp9%K&Kgb,c'@(V.OUS_isYIB&]U8a4dEpt=idl6]P@Pr4!BmnFAS*T)(/)g`8WZngU5$gq%gb
P7ZZ%7s[WXnMCsporbK$RUWliJ_JlcHU%5rqo`qHnK^2A@sYlgH"tJp8_:E+JoBr(hl('B?ZX<**2r
HbP>9#efCICe.8I(l6S?O7chh8Xmo>+Za0/FVG0cTRr,WWV=?Fk1$"h0q*<\?(04SkH"AC>+_cpsV4
$njWuq..Gn^%lU%kTF?<L>sHuG$W#pOP#Ia8'U02#;eO\#\qWg;F-Ulh2e..QMI.J35P<=kHHf]_J-
=L@]Mdd1\K,X<3u"rSE5o,X<fg?N3b&]DZuRa;;E<RaA_0#u"]*@SE#NFd(]rocQ=Q4o'<B,V\E`,u
X"je,bL?GWC7<d+2F$Ue=)&ZCN!6*>J-cosPG4)K!krr?'l*m<OV@_J;,XJj]O1pQJ`XBOW3mquA,=
2sd#;33\.2T<Ut8F-Z5QTU7fqCeZ<$QR"_!!1I)d8W:ZaCEBVC(Ga=2fl9qS1er\g+9StSmL6)+tSg
"+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s?p8q^Nd4+s
I(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R!oj2YhWXhk:Es_E[>cC1!*8dH/gKIfr$`0HA,Ng:
A*k)]jt)@O:EpgW?t^A6eI'2)5OdrfWsSlP2:KUJm)Nt>ZAr[;*e3/@rr?(97R"c&Y<c7l]t2T"JR7
/BFm[OeFd:OiY<c&B\h$-M>m;#W(hr&mHGF`N?X`CK.f.L9Vkp('cj)bt?o\hYIL9(VcFsQCcMYs.=
uAN]Q$$o^eTEZ)QXoM>j-\V+bc55Dl?A\52Q!i<QTjAo)P0[4[oL-J$pKA945:VAA2^jOaSX(]E7uV
2TP<i!]OqI-pU5TZbb&q56N0*T2#t"kdUZd#^NI,7YB#i\;c.dt<&.ETL)!3a=XAK5HYI3K+GJ&k-1
Zf"]u(i23\.uu6EHgpO@X@p=R"q<ji*?TZYiOVr@`B&B?<*[GOX@E@eJAS(rqH-@=>g/:LPK9e?C#J
*hY,@^9,r9ZW0#ZVIsK`C^TCl1ZOa=P,C+6C!-1pG*q[h>/@&JDlDm!CN.m(b<*$bXC[3m4S]0*T9]
D<NLSPB979;*"d8F1klmenEZ;0i)elM2ULnV3Zq*JuUN<`#J[3R2CY-n)%QU_8Pa+sSK*Wgt^EMaBE
#<)JQdVJF\mZh6G2l;u\VS'QBWuX?)BCK.f3M`rImjrb>$'oJC:3&bahc*DSppVhXLtjabKDNH$nSg
*+csfhgE_K*?R</&APnKRb:FM=R8Z5YKqo0c]E)5QK*s=`Za0/C0XB)+"Hl1rL&!!892;o**^AM=9p
_/=2Edb5NhQr`D[Gq6f>R(0rnRpZY%(3M@:g>,A1n#0Z"W9tbtdFog#7DfG&6Y$EVcgX_Pr]DT8GuN
9OY8R:m4VD#dsZNSl_m@;X-IQ;WVC6RX!]e`QW7KKPUWN[-Fq;TUCJ$i//P\Z,P!5XmA0Z<ZqcF&#u
6OXZ`>UF23BmZN/kOAme,hTkTt%'WWAU8YFtkaaQViHi&]+EfVpUUlk`5PK?=Uh)q^K)CS<jD3FIVg
c2p<FR/X<VF_bl7B^3mkZW$@R-0B5#U<V<iFP@YVl4H'2Mmd/T"-'%j^:@'SHk54P9,h!m/I'(lgVu
b%=;H<dZ=iI%NJLW=96O]D9_h2I2<40BJI(a;aEC*QQWYef/390l8a4C_W`*cVfQYq6_*9o0rS[.M<
$h##dG6rC7/-n3Mi6Z-&(I+!#t6j68[?e<4L)1l1u,2`CJ'HBjm-a'lZ.@4GC+2$XI\IAt.rQ]t>/r
r[[]43mJF-FDWh;p:4hr:FQ*40:qlaj^Sh&%"fIZd&&]&At78\D,3(]3p8W-lAE<:&uKM?%9-=]]4]
(Oi-BA6;5Kb?fH(l9d./e.I7hV/K+Nnk?PMmGBWC>CTq;^4VkJSWL?<8VdKZB"RqO]4k.[8:\sfYEc
!e";Y%t$aVISKFS*%3bq[H=c'[Zm1q^Nd4+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a
2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2/goajr$`0HA,Ng=flCFK0M
*X(=XsJ'VlF9j)sl;phoAe%Cji&SI%sG!_7BVN@Fjf^ri0QOJ)TmF>?+rWOg6j?%$$1Ihd(aS!j!dj
po&*X33[Z0Cq;@7M1Dcq=9?/>BSO<([o`^F"U90DX?fOrU?$hcP@POaDQsE(&[C#9F;dN8CYp@miP?
7c3WMpQm'<XJVLAnYI+(VB3;MG)nZnQ5gtE\"8$+%k1ZSgZT#IjhTs_\&ARmM.id>kFQ?Tp,s448o;
22+`XYL,O"CZkV>cutNM,PiJ0[[cMG%0#1Rp5dG<E!2Q;3s;%P.mhK,@&L,mK\g\kdol!A+k\YeVa$
*%jd=X"Hk[rR*srAXp*CX26nul-9fAUUJM60ofN!H<nB47`ou6+Xr0sCZ-d=(,i[e0SgP)VA9$(;Cn
Dmu2VU9]7bg+=%=<:<IoRgH2E",_kHsZAAL5R.Kro,tm8<E"r'-[cd]Fc<U$cp)BI&e7!E)L0]/;aF
]n/5?L'G&J7169GTZflUO"G7[-@T6m;X]5(k98?<\/U&4+Surlcc\iO0)-pYMME%]D&GY8_4g&NFk1
_P>7%^>BqM'[WoW1VNM@md3&Ebq0"ToaBnVUV/Mm#(D,iR1Em%*//@&S7KKQR2b8CepZqZ\%f,J#2D
A$S?-sl)'#(`n1a?f5oNL""]!#'B0\`T2DKp'X60.`c+A`]5$?<IIJ;<mB`<5EX=8Bog1*i]/7.99b
X7@Oj&C9(\8___t:G%sAbPdl1H^4[Rc+I^(D$i^5+j$0PC;t5K5?=T9WGiTgNrVf@C=t$-tY5,Y`&.
9Ba\=P:\j5?Y]2(`^(&=5:W@uA/k,OS@4\h/OAKZG63pJ+6+3]$d9O8W,.>;Ml5_*L0(DID]oNP7m^
!-6U?CE29S.L:*u>88Z+8@>U*Fr0XB:[DqiU'b.faPi]GejeJ#:I"uaXI7MH`@1e.Vd\)HO)W`gZII
h:)k?bK1s9>RWV)<F1nTY[k80)MAWN\\4s`Y0p<Mdi)9Go)4<WR-n<r*GoBLY(6on%KibunC!UL3@c
jdbjos46jT)Mh\)e*2gl+O3AmRDup[sHW:aUi^jLU=:K#OLlTiAe7hJ5nY2$`GaB^^1n_fcV2`iQp2
WLqQFf;ekT-`j"5O#,]7>0dkHdMT<h_b$K72nL'pZ$h"oq)t<20MM>1in#!!n:31S)XT4LO?_6!G`p
icY>5"Gnbr-^8[naD>?gJSFIh'mbK"b'$.%3`3dRFTQf@p)f3aH<g3c@#@YAV;k(2F23J;B!eLk(;;
#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;5QB@4.O#uZ+p&r2+sI(4+<i!2+s8
'R![8a2+p&r2+sI)em9LqeHRjq?+E7IRdK&+HRGMl9d&k\#k?<-3O9.n1iK"DCn*D2iU,dJGnn[YVU
Ak3+<h)d=PW6Wf%hQF]eLlg%FLVf4gWcMMZX\Z29dRQ>)+hS+808Sq'qUV?=TY?^;TCYr@?KukRKsf
@cE#$%,*i'^RON)p)tZA_Xg'DlkUTac+B?FsU;\*0NGV)BY:%!&\EMN7dqepI/i-cj,S;r)L;$_$S#
*dJ4I!7`G_W53]9B_dgeHM]d/O)7Na.`Q-:^PX"9Ue+Nt$_D6+D,hkZ"!rR8FW.N0;Z2M\(1_Z+?@5
/2csbps![4fUJ*;I6hQ/3j!<QVOF9787_6O<ZZ+&)Xm#Bo-EFXQq2.LdQ<r[%rpl/mT(4]*A)ZT\X_
<j@DAm>5IG=-BQ'S%\cBcbdm-s5,q[$q,Qc)f=WOlt`lHD:>(i'dpf<->Y[iW]]q>a9g')&1?O:r8g
;`HC73/S9)QD?9Bo3i^QWRO($F'2:_ak!7&K-Xb3?q6(G,!0!.nqr;\?/+i*'#3Q^`.k7PN56SG,P?
?S,FhZBZ-Ug5,g^(D9#B$G!#^(L\#`/Wmpmcbsjq/N>&bI9]:=(S-&qFfl:j+ZTb5C"l!"*CH'eUi)
^Q;b;8Ehn5SKBKK-s2BZ^k2%1bT[]'B/I$X&6V-*1XB_8DACMj00,2N4=,i6_)b]'K5M/VI<Y[*R*>
eRukuQ<Gh?CD1(^+HQcn"jaNTl9[R"A?L95ab>;Wlq,dgh.;hsHQ=&-k(btT&:(aQ$S$DVaKFiAGqO
)M,38b([?lC[eJ#)fgL*S#k>FV8f_MNUm$:u2/>QcdZM)CN(g2,qSX)014L4P$.k`H+)_Dd=r*[t))
!-_53?,S+hrLTd@q?DaBe)lZHo&18eATd?h8>$6%\Zid&E?)uQUYfC9A],#`*\i`JQYuN2Pr3A)!#8
PE]806]Qbn4,BRu28/`Pk$V>'BdA*=kXg`_R013bpf99T(X;_?2gAj?u'JL+2!>,kT&I5=2)2V(?@^
NY)4%YSA6\$7LCg2@A>^KF\:m^BN-PM+L_PsdY@sG!j*!Pb6H%Y)c_=7kAq3T2m2XsXEJP,:RbNTT(
l=pEUr9agmp6X604drO1G;^WhKYRQ6q^Nd4+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8
a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+qKiaW8NW.`o=qqBFV.R%fgp]1
q-g:h:&N9\K2umJ5"&>$Vk<kGBLBdX6mU*_-;rnB!.=JSLYOgLFBd@Zl9&.0&LF=I6=58pu`hVbt`*
Ul7M2h$X>0h/_?(S1c?t'aOeuJEW,N9`u)_pO!0b&.p0UA80g53O!eTO25Va?Uu;ha__XIPO1+@[Hi
dE[XDs7kg`.BaW3P5TS)8W0M+WMq2=-%BER$3Vgbh"NI!VbWWei3`U5Ctc_oh,O9[he,4T*a)>T>O$
#X#toC(PBrBdtQ7,ZcUSQWO_fqH6Fd`Gk`FZBO7To!TEFBlm-o[j+c;jm?9g<HT,f1t(QI7m[^D$\_
>N4)X%X\4eNUT@*8@N?FSRV7aC?S6Ick8/[lJHVM'`QeeTE+iE?:Z)*T0]"g<%_=mh8Ic[*Hg6tSZI
X)jdk-_8p[KFP(WL2A!PA]+>>EZCR415?S[&dZ\nP()54+/^KG<9"%qc7hlc!&_9RK.3l.Qeu6RLmq
UC8Dgh`K^:o1CeC^3/2&Y77FUHXK4%SE%u%k*HH3`4&^/oQ(TW%H:'3dDQs@k0@<mOs3]A>(4(f#nN
(uQk/e:sFDeh1Qr64H0m:aWL%#jt"IT@&""U\eNRr&L;eiaNDe%No=Q[,;[0HX2WiaUKI+Js+-jARl
3[_9pmY0N"mPP697F=WZ)I=Ar/['o&T!SO--Ke#CA&VLXk3\n[U[qX&Xks2i;'i#JQj`9nBas1%2/c
KOelK#3>\RV.7`0G_F=6o7o(0_>+Gd:^)WfdEGA>j8N*VD\6+hh;Z1,?hn-[`FiVY^(_dJVXHZ]cVk
L7[s/-)rJ[kQeN#<rB1LK03m@E)pi'-jT(K77Su0!<gjehjf%%V(-BfRn=DV;:@o)S0#&NBt]EEUZu
U(Vk)ia;LIFbdVB#a'TQ2T!B4`D^aPdk(YZGd.=Jc47lf">;Vic[Po^QCg9]i6Z%2Aqj%s,bp7DU(G
G5<pX+W:T-.2#>hr!n=^n^D.h$6[?J-&_2G5])Q9jO$b:=m#CU.)UAW;o[lu=nH0ToVj1;fsWItFGu
r?3Q?+6<k/3(meImWJ-2AN^q9KAV0)TWe;?-eBI%$FqB79k]?_^dLQn6pO.."@POifm<G_Ial_R&dA
Ou@+cOkPVoTIKuE`k?eE*k\@>n8+)oY3/q!$"rrC`@j,!DE%]a^2GpK;#(.$4'=kE2R.iq:QgBt;U7
@QRT&.oKT&J,Nd!>,kT&HNIT&J5$U&.oKT&J,Nd!>,kT&HNIT&J5$U&.oKT&J,Nd!>,lms3gco+s8'
R![8a2+p&r2+sI(4+<i!2+s8'R![8a?Pl.A$7+"sTcsb;7nAsVSaS0IUIpUmqXnc;HlH<H%`D]PY4N
n=n<YdirB/GMXVHj_Y[uR1%[FPRmc):I"Oi_WRO9"c$7c=:H<R^Z*jPmKJOnJKOF`ddPHf@8SJ.@*U
qKm<h]S7;E[I+(@4jg2e>>$FXA!+"&`?S.e345Q?JhOU<B#[D;1K$=>hW9dJVtqJM^6+_ZEuoCHh/[
f,\QYOnpeGR:T<!..q($4EcfM72P:<Nd:gVlnjH%l#>JX:_X5R*acYK<$1-LX=iX[n_*2aaao=3K]_
PI/[2q>Ou:_\8$OZknGB,PW)Xq^d>o)<aWiS3lQ<%W*iU<3ec;^ii0$R4s"Q;*=#&3r@4b8;N;@]Tf
4q$V<7@/c%u.;lu:,rb9Oi294,%aA\5,J@.7fC;$3]*OOYCr![b/E>Y?]%Kf6;MO_>W/7h)Xg<>UqB
8TmTeD$[ooc,[_AtE/:8M];)\d0"AOT.5](']g\Sd;!)4@'F>5%UmGj<FbgfjQ/#7\]Q!,,E_5j7L-
"N)p\!M^t\rrC8-U4nM)nSn4X84-otK8`\M?))`f@pVdI.Ysu=MH7B7*IZ'g//g4bLH0mr0l_3<^Y#
;1eK!&7HQ;4^O)lUU@*b[=d!0S8WCumr_0K>3q2N/'C1K/"e<)$E/Rd.X[CKC[o.%`s@tB>r[_SC$E
dauNE7O26h!G94?P0-b&im.>-C^.[J"kHfl7#h<.gt>GbJ\&@o*X;u7[>s?X?l!PXa3^]=Q^p%F[Lh
(cZ?mFZ52,qp8`LU1,piL*bKX4mqb+<R+@#!24t/7U,al+9I*<#2dR%8gnr#35C3'@oM?mQRN<ZL!b
^dN:NV(dCLm.'k#=BlEHC<"UXbHaJ^?CTlI$!,;ZeA+^p3:NgFcIES_Rtj"Ki[.CrZ8Sd,;h^,++"&
PhY%oiK^lE<6f9ulLN+t(1&Xk"q00=CksfP=_+m>eM<.=ndF=7Q8k<ckI[Be]a_DV=^b$'*F'djM71
]Dh5?uBju+rb`OVKU#jQU1:jZd!=8nALlbCd_95^f!`.(A%p#"s?\YCfP8;O4[6pq/G5X\!C6pP*lq
)"Nh3tk7+,\rqZOu>d^X%m\OI=r\Wpr;@k])&VP)rkf:>>EdofiD?^bQ>f:qa`p4T-pM+DY4SW/VHM
W6pr-se,(U=+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p
&r2+sI(4+<i!2+s8'R![8a2+p&r2/mG\GJ\s4ar@Sm)$HG@fZUDTRU=QZ%p1h1';_Ej@Vk\\]>?+0<
g@rE\,]7ZmKSOU1YZ%gQnKojcFMH%!("JAC(4Wog@Z=mT9\DR,k6'gW\rLf7@$$Bo=qcBfF^"*]2)M
cEeo2c-/TS`*LW&KoqRoDl*X\7iXgmrOO_,T>%TW/oXd"Xu1.uIf<49JD<m:_;+L0KH>nHNErr>KbV
;*!1-5#Eh^gQ?9^Vt)PCH)O:1e^";d+d6'HJ;3B/P^Y:@N'J)YJSG$a3Q2nB??d#2^TT()^P7Gi6:e
Y->;.P@RA.E[(KJIdDd".FhudqbtLRkA&3ia;<?ocSaU5%_]a;hLRoI<]T-Up[n`Jl$0T1@NU-iolE
u7?*I1l.:L6!c1pt3YWos/e?KY=9Ij[?sIE$,]Nk4]<N8nq?Xr$UM'rn,kl"T#'SuNSa^lg>DBr@?g
h*d=o=1uscE8P:J[eKFu>LV(WV3ukckr5O;/dmEFY=f;d;fN-daN+11i3QVG#!DCG9MZdR[j1<F'cO
jee>u&AVl>E=\!B;9K:29<X_-*!U:LU?5^8G4UMfhrkb>egWiJU\"@pADJ"kHUe'Ts:",XFTX.31-?
UuZ+778bN6c3(2`([kXV0h'@n\n'3Q0fs1`oo8A[F`l:Obd4=5s,RGAmfS^Gjoq4[c)Id!TVP`fUb@
f;p=[jVVaf4<0g^il#05Jqn9;eas;,:M7PBVc`4Hi)V0YJTrf76/-:SoM2J06U*EAb`NSr?cU6#Q<:
5)cN+A-J0j\!n]X#';(TYIq=Vn#h'rJ!s._&/N"-f:,dq:N.+S%%2O[Y`X.I!S'Ks3nZ`\_KlUY&j'
@cRaLeh+BoJA7M`gq9q+C73&'*04oRGBJW9Mk(YEM#NU)lbCd_8M!207SAPRDTl8gK_"jV(!Y`!@WM
Ekq?!NbbL9?5/D(?\VJ2!,CI8C])2;u/+4so;0,.R+c30'_6CWm<Cn#6/74O+LJ;J5oOS>Ip?W[%K+
SK]Y`oGO=r/=u3rp7A$njicIh-^<%dp8mLN*5^t?]Em9,/pdBL^8feLkl=mJ;B!eLk(;;#`+"eL^8f
eLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;5QB:2.O#uZ+p&r2+sI(4+<i!2+s8'R![8a2+p
&r2phi+k,fRNYQhcMjVdl@Y9O%;VJ!d/bZQIo[chCBgn'5WsH/Ado_RoE.?f$"CAuYB'pl0=1*8h\<
aOl,S((E(JZWD.A(9mXFbNrG<n/Z;-n'u*^.r/i>,B#C/KCi8oU?+8I92+b)7.#'Lrc,NqCPJqrE(@
HVU4KG$`422rFcH.HhUNOY2TGpW;.fk7&iW<;poW%$aW;1eJn,?M%MguMg9-LVeE"7<;k#Em5/,M6!
<A726MmL89*g\?kF0_\E,DjXQ`#R>.D$XEEas4a&J^OT9nBgu2:JN$e.t4:3Kc,#A]K!QKNRj3FZF6
9a=5tV^/-J%/ptH:F)fForgWCt>VbN*iUom4J;2Af#H;c?5@VW9LhXX\9%IV/1#500P`ZV#fO(.mh/
enAheJ]7(Jc>>OoA6[O31"25p(.<qqZT9jXf+*R"U[t.2l;H1H]C<*EJ-(_G%;W?M>OIp:3D.bYhD$
QqKh7L8!!Wgp+bDG^(lNMM^ulic,up8F@Q.Mn1PWK;#cjBA.O^:IBqI'TuM8d01LZcCR>$e,tq^GM.
/[YaBPi,LGP<3e0)R:ABqGO+A6pWqVgJ8pWB"[Z[24U+trGNb80Jo^Q'meQ'+Zr>oTH_G/sZa"RA'g
4$uQH0].t'h'El#K<O*!Bi!RcD@J%`g1Lj`uS?2m:?K<-Om'6a%HDi8H?.=<8jtiG.*Dr/9\^tXfOO
cqL]TZ`EMIHc5`X(l087/LPI5f/o%R)luY*ZEMY5eS+%fu>'KDEC>UVGZ*We9*fGhN\^8SlksPb4U7
Ji+KT1049fBMmR6cg)aMX`nWkg"P1.U%aXo"l)B/^R2[[.ZFh,kLGB=PoX"+OK5o@!JuDfTr!R'mr(
8OU_43MCOHE=nMK,iG:o3N(FIpW"DYNd5,3Vb'<a9j\HR&d%BCQumC3#Z<7Nf,35.`@Oqf2CV38Ro9
X<DRlm[gJ&Ea)#Vb"StW6cK^$L369fj<>r_CKU*B8TO\6EW9puA-,91fP9u?R<Q]&hGnHY@d/?HKMi
`TaL+dnYDNG0[#[GB9f>5K(K0jMF=qGM77rr>;i9'*<2dZ]*'q?"u"Aa-%,S^-2Ua##j/!1OYF:;0A
9N?FBV`^Ik%jt3e^9C/t-dlom<PJ>!3*l1)k/&$><AqrT)(2&>d-7RV..AS`JBpA#+q\@Bog60>*lb
d.V2U-TRa-D_@\k(t]XGZinX%=hjn]&g;9^M:2LH@Ikn`IMjcY9WK$>LG.B4rORZjg:-loft"5cu^6
=nL9&o4NoSmM+8qa+oF#pg9JJFjl,4MIUt79%1,VA2p/1el<81@W#mtC`Up4j`C+sX65"3(r2M$9:3
(.=BO<,l?;n:Y-se!QOeJL``im<&\&Vf=D@m#H)S8F);ujaFN!)p=R<P7"E;F$/#.negnDM)I;RTP6
H`5]f(q6#[+W\.j4LI108WNa*g]l((m88,LJ.<TQRu3\GLth0<Cd@?`Q-3pp8hi7-Fmm:d^C3$YH*&
5\3I<"KR`;nr/=u4gon*_S44ai71nM>F58(%G/`;3=J!*.fk%'/VL3jK66[saLkpS;L^8feLkn:qf)
$p@+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4
+<i!2+s8'R![8c(=7Dr3R9]*<0$;"ND9*2uE-0tfG]%.P^C@9?/<RdERB%4t>XmeFX>\sI41)aN'KC
.\UV`g<Ag@Bd"'FS.I)j.!q%bAa>u^&<k*BbM9:mH)G%VUn!H(s%#:61_fsP]q/b)H#.l"\+VOhDA'
\-)F2mhf2QP'glN1ge,F';e1p<f_P&8e8(a2kBf<+]Q[p)CMT7u;0Y]&$_8>e/nOg8i;2eBTDV3:#p
8,DK?F"u^TK;s`S?ij+l=Gp@P:4P8Od8kUlCOW-'e>)?K$aOo6-jI6T@DkL+ch:gSs1J'=>aBEVB*c
='3289QoY/`!p(fV!4")$*qBOVnF?0jUs0#n+j06H0<*MTPd)A,C=ZUVs\G<TEh73gnE%'4%S5n4ho
VP#dUL0?W]j=ed%&^UWSYFb3A>&erNk+=#5],?I0i^.I2&WNHoZ*g<t*5dk!4.hegGA4=N>]UjaY/>
/"=ThLgZS$#q4&/9*g9(ATm.Lo-edOSPedFE'/bZ>f]*/$@LiHpankdTdEAfgKfP/Nob3GUYT,mL:Y
Q"U77F)sYeG(J*BncoG$]2AO5-DKQ8m"RlE47*/$l^.$j`R$an<RRao(aiZmQEs,AKE8H3hX&ga;jn
9h1Sq,*JjD<.Q'k+*3H/LRaMCALOD)O*c!r6c",Fe]uHM=7V'ekNZubaZp&q#I=Y"BY")EIAVoB8)$
[N48EJ%O[2QW%j)fDQ!PhsJ_fOdcCJFtf(J\,$m>9+3TTDEYf?X=eiQiKajS/'!_j-U(cV<Cb"\aWF
1M1'[*SOa&^@`AL3)l)!--WK-X_U_4n(&!0[URRZCYS(#]ZZi&L?gWmA+9pS\Ymgrh;&rWp(-H!Zc;
$ja6D,,k1f+))V.;^;?ZNtjb<5WSY1&52/>ud"\UYh,@!CMH%jPTWd#TKC"m\STqHJ\k2%WD1+;4LH
!ukLAn_?-p!0,dDn&Z)GLBjufCe[S-k2<JZ+)p4l45OWT1+`?:c(Zm?!@L3PJ21R!:2u@f?I,^Lq]C
Ff.itf>'QKV+$PS$O)*J$0S_O&i.JW-ZQ.?W"0g(td0@)eUM78Kmb&h(kAAq%`Q[A5MpBcG=R*+\X8
q;$rrE!].fd@3'?>@[D6h=/*8[8s^oN>Vd`WAnM6WI/eA\1d3k;o:QWW@iQ9Mtl6'RTuK09j](.H.:
^J09W4%?"P(j@3i[D.lU?%p$#B;\*u9O`',DL+l1a"RU%md7RNV1C/]olt'jNA7h$Y3`T.6k?W+deb
*tH$!;^?3Q-mZheJM66*dj(lf1&lurtQ+@$auFBJJ5=QSeJSP:W@AYZ5D)-fVj-Zc0%in*[$<7ph;$
uL>N/ouPRN!./jqUaf5WMQ?-=PA3L3)m2n*39=ne%YSESP':S4/@ru.XLA@]F6h]>h395Vi^)$i115
tZ\OjX'rF*ZF]#1*!=fo["<E:W\nno\/7(fg)c&C$gg6GBGBnM1D9Mf+p6uhoSk]BZk[u/",`OD"Hn
WTa9ViCR]NJB^Xtd6O[B=RB)RS^/<^\!L>dbsT;I?U,!'jgfj`)s%P5TD"5dS^?]el\Ihh@`<<nlK,
.,^0'ctUb>'p`1#359e<m;(EZn/Mpk&@PKe<FP<(Uj4\Sic3E(Z?[u5>>ImcEElsXB!fM>Q3\_X+F*
?7\ZQ/dgJV39lp[0(BNn7?,@N4/(N[<Ql?lSP&;^%G@3[QJ[q3U[huUFQH)fonD`=->Q.qhIASI#M(
rpXkOuQ$K&2QAarrClVYbB#c,'.H:=Y299c@%iS6"Z,+%Udpmj/V!?ktDXBZ%<Wcq`MJq`Qf7.7BBp
>\HFc'jI+Gf)kJUt:Eh_:!]o\Sa_VORWMu_rbmZ5&NU8@W(BOUAa!omtp,h]O5li:9_%WF#lEu6)XE
\QJ':(XLi^Cm/o1$N,%X+`4:i5-m>Db]L07sIcXD:?^eP#3-!4i+0FVs3c9uboW\6V6;!iHm-Kc/Se
mJX]kflk+Wh4UmN`LhgkV3kM0cB=`]>eCX1NA%5JVSRZR;Wbo4h(pNn\0=MiJ8@SB_!RiN&6IT_1"b
8GZV<6\dT'@>#a2?/>dTT5gL)iV.(<oS:5'8p;Bd:d+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+
p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!?s3UWm+s8'R![8a2+p&r2+sI(4+=c`-%$MRElEL&
`?V;Zh!OAqk>!W:+2<ACYLcui;?oYW-TDnm*UCO2?Fg[<ha)406DT(h59.O3[->PT##=g`:K=ec4hd
q[*j)e3hfct\-HU.nh<s@;2P6bnD,u+IsB\qnGWL\)LcF5$lq`1gLH1&(Cg`IkaC1`UVb37X6R@2<6
#2fSm6F/M&XD=OJ`IY::Mbeu:F4DYTVo#\FBX)4k9ctQh+D$"j=i57(8;PLJmOU[d*poMFNiPo;AY#
fk;UmO/5C&9"C_tCZCLbrQ(#/YXir,%6Le1r=@BA'<ABs2@ch7Qnq46+p=Vu5;S/rX0"#[FipXd;o%
[)&[FO,au-U"4LDI%=)bO/?QNc2M9bGXS1jCGO(8D_t'ipCe]_&ZSjnsfDT=pcZkYh<ZdNcrq%<((k
b1K#g=f@<:b3Pi=%76dU--1nPK+pB4IX.Di^jn^k;aPD7GBVVM[nB/QAjCrD`Fs)\S\`N@nNBP>,",
#;Khc7PRaK/s0P=#%T(Lu/b*Zs:n[FDW)(ET1LI*gRoM(,PQh8;<3fD7l%(0fD<EUmV]Np"U3b8ZIF
E]dCA4/lQUkp(J0Oj&m[>8/W/W)@fA>;S@$$k@'&>2/kP^.UXB:FgG\QV9F7r%,Stl67h8mhAm'ffS
"@^q%;CTO1!&C/Tl1QH!7^N[*@9L/tC^n_E^-gQ-Zp/F-^Wdm$Q107O#)[,e3[#"dP%hjCk'Du^JmI
l4_kIc:&SI>9CJG':#>"h*N0&%ur]>h,-%58*E(.`+YAa<Y8*!#C]ihV*X@]15J!Y6Dp%i_MFjJ^8%
iN@o2d+FOj1X(6j<%*Z7/,2!iR^EQ_u[>A9NN"=F"i9Li/]s$j.WD0X$Jq%H@g([d\fcY+HPJ_>a.C
K$;[PbmgOcVPb,K#.0/F?$Z(;Sh`dm=h$:F/0[6RdiVGXkdrfuqSkTW^XbTs>)%-cdI0A#Z;JJ3VS(
n92rn,T_Uga0CfIA!)?/4+]Ek!-O5qW1jD[>u;\'Uirj[nrrgDbNrG3^02D5e5?PtFmd[1a7pGKqlA
Eld6g"*2=,02XuT\PpPqVda)U0A0hGRY?,J;:)l'0QZeB8E\W7IJL:r;DBJ"2Q&UXBhA]Kg:`9ht[f
t'e+l"G+d9`F^SE>-ZV7bVp#QSC?DILuJn<$GLI0X8"8(3C&_[s\@OctdPW@7O[3LKV!iM-q9$ca-.
.]6=!bYN`<.2]#o#GT9%&l=u%RI=UO/#[I18EV;SG>D5A$[a\<\D",%nPa-5lAr_-WVK'o%>EBRo94
XiDL3"Y/;/577%!'4'DL-qaHPQ0(:U58KloiTEDlHGS,:Vp0+!%[m"jL!O)Mcf%?C-M))@$PYXIbm8
&8cV$>eq6=WAcsb86C<o4'QkkornYcf2tZ`j_r]M/'9p,HItUEQSI.TDGtPga7N>5LM,M/eDZIOW]8
:<Vdg*GM54Ln&D$^C7t=V!U1hJC<]3FW'>gf+m-AHFI!iRBfQ-<2gid,NEGu-DY0'6rg?[9^8WER(/
:Na&1c]GgA$H$'mPk-f\rH'AJk2KbYjCMAK"<:5"j1;(V.KMloEEfe>b39.`?l_bkDnH2'P=LSRT>0
+0j(Qcg[SLtIod8?6>X['-d(`p]gQjhpHXN?,2e4dTbZFQ(*$W[!,3p!gOg?XL<B:3k,:!'o@dr2f/
G+=^S^#.Dm<[@<Pdd<IeQ'_(Iq%*_ID;aaBHDs#VJ-@ePse"?Q"]g$uU_gCmkf!\EHY@cS`G6;'bgS
bu+W\p[I0`06=<\>*>rQeq\%.Me+KF(\(U=G?X#a(6m;<lXMPaV.C@CIs0EeO0LiiZGa=a,:/p@l2s
L^%US)aD_nTNZ[u>W`19%[SKu^J\@ncu_]u:$QF3jQK5EYS.q9mZ1<RPJ3`aYFAWAZX:q689D5E:DG
-U/jYd3W-3SMWU2J/YRe[2*_qHAZ9kj32-PGgP/FOu]8fhj85+bAW6=1ZBiNI.cSm^X=Zf3\Ne$7WY
?k%gBR)!9FIr@=?;7l!V!i`:*%Vq\G)d:)gn"(@Ea;?5]T4Fm,GFRe#K3@e,!8?jYD^gt]fH*a%V>]
)I(2Kc.,)JOW/?XrGn?#=LlBP57&C55;l3qqV6C`iZW0EL%\2A'naM@q*W![8a2+p&r2+sIQtdJGC;
+<iHY6X!aS!!;5Q83KD"AW?3d>5#N_1C&PO7pE-:UUPJIF\Rl#b>SC!QDQClN,p,6>/tu,\g)*X(5a
Tq>Xjl;\giO$+I$/p7dGg5]b2M5![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R!
[8a2+p&r2+sI(4+<i!2+s;f"@<=K:0rM4ONhR^LQ0l>rnm=Ds^.kjN#<I5B@9H>XI26Hull@#4Ib")
o<lZ_OUff5-3*0[<7?>q'dSml;Qjg-dUfk1Xj:036=a_g,h1WUk4rZ!p'fD<G<(m<Ode4Uh7Ft(fEm
Ee6',^p@<*<:.frQ,*I8lJ6Hr<U<^r^.4^-LDmOWFm``Hs>nRTs]o(`hliSD=+/>Ejs:[Te_cLJ`*+
Sr3=6AV]ZO\BF9]i.!,!7M/sH)=pq\P1T5:f.4YeboEm/nBl=5ZL"LI@jWQk57hnB9#?'#8`08bp+N
;E-&O^XFE5CS(u\rU$\ReHj5nGm]V:haj.8<8Kf/4:E+=GMd.f7q>M?7!c%jO.bT[;:8Kk_(N*Xf%A
9DgG--/S$-")jq%Um+sF^Er92E\<cjRVhI40$OkUs0mCL.9(H66+S?8!d44)lU/)WT?!R!84fFF!,=
24J*L>,E'7qp<IplP]Jkth[DP-P,)nL9fn#H$t*R<S4C36j]oLg<C$:_/+O<(Fk`&@UYr>=3r]1[S/
FSKg38IWTH5+T+$BQ'-@!_uh>%!MU0*Ar.]@tCRPs7T6[]JOp>5HcZZ.=N\iCY"lu5$gq#.5@$oX"U
`i/Bo-S`?<9TEm-`!gL>0!XWO]Pll3LIU1:'a24P3T6u`,"'GZha_$_jQ2Sd/Pb,BmPkt@NCN-g/om
6ie#2!.Qgpi-q*8qT.4tBK@D0@jDJ'S3QUN#KGpSV4Rq-H>monP5,4K[d]M-R%U%O-;eIo/uJjqWX5
iI2=Qms+4\7O%UPicV7.R82HUo8/7H4&41a;&.`d]Jh,)=1\a3,J;X3-cQ<f]qb$)jYZYW\@$(1\-'
@NcsnuK!GQ'InHS:e4!:IRKnU*grD&L3@s%,4:LT[K5c<>p`;rI<LS(;37&]Tg@q$fF)GJs(>/.96M
AH+`l(W(Affq&kZ$tVW9>Y7lFJ*,CS\&0)nZ3jN,pB>eSR)[NQ:ftWZkYOLp<%sBNksS4/[EE?biVM
N35!h-l`AT-R;2?kAt.@mBG`SWn\O51c198$jEgJ1;V:u)r,Pe;s._PG^cc(Qai)flY.[\Zo'V[k_X
@lM>8K24\!a9%hlOJQ'D'O7"Z=lf]aI6*G#n%dGZSbM'm*'V9_$MiVfWp=;cuajoA,U=PiGK]:(TqT
"L;h?AAlkU\+BI,Go7F8?-A>GdbO4>][1%7?to"a3Er>MTe1M<Ck$kdh2g`D?^=Z\*iL/%`7%$G\a.
QTCGsNH@Sd(2E2I7N`PIca]QfD<+5Gu98:r-@uHg$MiS@A]WW9]f:S/1WJn,00s-Fs4"[cupPDtkAJ
MaOKo<Q12/G`@Zr<!)`X-_bVe$5gGm&e2"&,D(JZijZ>i?eMf=n`X[k/o8gFTOH<-jA'i?b#[$Pn?'
U04d/)n*=mfkK.Gd@(\5mdJA?.b:3*$/?F>Olp>IDuE[cgO;doTs;i[%!L]96<&.L(j##CYf"6sVQ'
"rAnWj3hqt\FNPadra`pq2Ulh0;fN<Z!9s0!@h/m[;7b][7Z<:EoN+oumn/a$4@EIA$7^AUu<7Oarg
gUo+(QF0XfA7:A6QK.Ak!"$YlO_A+F+!d4Af8MOU,<G>b4D*@S?^G+Z8e6[Cr'M)oi.;qVjs?M0G-:
,J^H3R0su`2X:=Rujp3?kZ?r+hh.*7#2?BQ8fY&f0ln/q;;meI6@uN72W0P0[[U3+jRkC6aYH:Qfn&
k?S5WAcL?cB3X3]09P;q#.`WMcbC"6+*&_s5pj"7c0X;kNmqrrBs/JrN_or3jqPO5e]E[bG`"i1D>U
()J5R1:heRfLq`GFdV`B(LY^i\TTN6,@b5CX^`8#f!JN[cm(AWI"KI,7H9oh1qCO^XVW7P!#-DC)oF
@]_-^=b##A2ZjI^JgYKG1*WXVX(71E[B0*F>2KMA;hW+e>>TH3^LKBcFde?t=![+,a^@N[l[J]^Nn>
M&'95I<3)O,QOJg.:%cSnOb5Q8T@Fp9E9=HOgb#qEL5PLalnMT$1@u?Imgi`(k0c[^W[5Ta-[j&#_M
5@nW?Mf!J\FC]I=GnQ\9iI#Oi%L3LSqf<pYBJiEIa=3N`pg6q7ECf6sXK37>OaVg)Ko67Z<pJa,$+^
%n#/2`EBd0Q_)Z7&!ojN]EIhQ&6<gLWE8hfqOX#n[aMGio:<\\nIOaX9?e<VZRopi@,J%U\9F+j&II
(-;0:qFPrbaQ])/@ZB1`m=MoZgERX13'FD\%V`ErIX8m^.VN:dVh@*S91g;iml.ekc0;)&("@KYAJG
fQTrG&dCY[c0/+9"c6'g7-Z-1L1MKqC^NHV1S#Bp;.eQ#+Q@O"\*4#bm'*+'f+0km0#R9qWq8iRiW3
;R8Mc_%aJE<B[`9>(Zf1Do_2lhP:@hqkSbjfoC29as);Jb+s%LYc!6Xif5d3MhGZP>od"aEX;/",L@
H[ngu4=s]`g4>rpB'2F.MU]G@doC?5:dRtf:)dQ/Mmh`T;^Y!ZMIcWSsFR4t,_[ZfnMoKBkbbiqGG9
81a%.(TpeqS`W2Lnueo"([h/.3Dum,U?i9a#SQ=c9cmja0S03F0qko@hC#_QiGl)34?Q[)bCT?)-%t
Jj$,^[Ds_*`>:Upp;W.'OjqmCRbEi\$uk13pRS_i2c;_%g3Pl/9,)T-Y+J;EGL8Oo4N7,jG8Ef+M%L
=#&J,Nd!>,kT&HNIT&J5$U&.oKT&J,Nd!>,kT&HNIT&J59Je,(U=+<i!2+s8'R![8a2+p&r2+sI(4+
<i!2+s8'R!oSETfk?i\a!`,C\fE9T(7CTefleV]:Je[b%i3'X`UKmt5$9.fPnB;u`9aXDq1>`'<u\Z
--(;#trWT9\VFkL;:re[U>"_NWZ+8?=ZrYUa'U09\aUD%&=`^#,ZYQcImp2c6@;<"d3V$Q8?BGXNQP
rK.RufMMiMaLcQT[]%N:u8"8if!l@C3kDbro!2X1qI?c2"P@ISL]>pT*rHrr<;ih46R_ceoYTCMHA5
7:rgfNDak.1q7Ild<,/-a^-P^@sp6);*`r4<sOn9!9QCFd/,EJME]3lIYg^AaRc!K:@^U'p^Vj\0/i
B4DV]ar<J#C0$G[bmTqu70,JQ$ghXesTiiFK+Jsi=]boB!<!r%H,hRUqfp9JSXiDEQQdYXcjjc+>bO
d]V=hdZDY-JUtsNK0a2'KCcmZWQI+M2i'ROi[!>p.TG9m\bAQIju-h%@WIqVPpC+9PjDW_XGq?I>7\
,g<5,<,M:_/V!uZ45j$P]"dD#d>.2>-;Fa^pU3?f250#>C];LE11;=5WAIUgN)^Jttli=<Y%X`KQ'@
-PWdu)@nrrA\M&tqe\`!ZitTJe_)D7B04.;Y)+U!5M!>SUH\'NG4T1f#.8*S^SN"Y&&WmZ;3'[fbic
UVTu1V2$V<;4/hObgUR^C^sLuh?rliW&\Ate=j5aQ,+4o+S$`7W:E^)lj,4b[VJ=fmRSg;S.NTpDlh
Ou&`seo@H\mbW9S()=Qo5F:D]'tr/^MLWNf!iH_I%X<&BNQkC\1C*bm!"SD&!d-P"(#bo2?.,K3[+3
0\AmJ-K85Z+>_CqS\qBUOG.t>H#05`T*!FV6mFDmj?7"2s+*kPn'*Hr;9GuRdN(D%tf-L-*69mgd28
c1hZs`7D!,O[Am=sUV,b+E[qtdOb1\(URf<PFJeGD?LK]>>L?M?bGMdY&4_g$od_jfA-e!I&J58Q^0
5ef/N^mk3OrBcdau(`,t$NTA5&j<91Xt7i1#gU(:6r;S\2A;)[&Q,L/Go@XPu_>Tcc%Cg\dOaK*B+r
<Cp=RK"AC&`X+S^-uX&@C^DEF@cQt%1;=R,D$Cd&lA7m0dW2f^8L<0,Y):9+QmFBmWZ4mb2I,AnBit
`$3.mI'Y!!9jGLrS,.sJ#N))\qD#ir)(T+*VpQ/\(SE+<fo)L)1Mm%N![L@UgcehO<3i.IocI1EEO$
o81]>'r)O\?g]7@.(XRn"m/\!4:d2'b3$TaZPfoH:+F:1&#3(%dQ[<S(g^=Wj\HW@<")ZG&A_)OM7H
JQt-GK%oAk2gq*)9=_%E:__<J-44SIdC3U"0)slVW8[5]!L%;_4(nYI+Wj'M&2!.E-Z8oT9\YOY]CJ
M<NX^eNC4"AHEnTVkQA0ph<",'bO`o$#RTlJ_!m7rB.GA6?I$taln\_`AeE&KEH0M_fQ88GEp>e9!:
d8Ikcq;cZp_qS$/>fJB%(3$TL[O3KI%c.E4QG(fpm#$'.iD.2>[+`pl[[MPe=ji,eHXJJKprh_RB"M
E8[qP?B54g[qM]-i1f#$Zh6-W1UDUEgsEMeDYBGS1'qDY2!7e$SuDIq"<%&AB%2I=rqXh7_1bJu\"Z
*!'h[C7ml%N"V4AY=0P/Q<n<&<:r>8/sCEF90&Y^#_Red4ub'Cf/]%o`adeb2I4)]6P">`"hqeP59P
]T*R#bCh>@g]dl)<ilpi4S(VYk(X4/"X>JAb3@9TaWH8ZQV^90^%DR>&pM<=3[9)1EP7bb176r4_;e
D=5>[7&no1XsR8KY;r(Zn$EVF5:pF@8ri4B!#i_5TRE^2Xiu_2Z1tES7+d2H;_TD/dY_QW)5!L-k?t
'a-IOgKsm[Z@!17Wqfc%m'S6bhh3/fQ[*uDMJCa(ApP[Okipqhib7\Qp9Td?p7f"[pM-/.H8lp.9[&
5<me=</EB*suD*9YCH:eB2auNX8I9ahEBbi]Jn))d-QI])G%tXB!F`^=nNO;01i,9cfUQr$Uh.CCE&
i%=^b-u]-^h[*!D6>hH?R/\6?IDcm:CBT"9nJ`?ETB:W2e-XjmEp13KOr/\/"`Y<0tmG<frn*c\I7]
b["6b*rrD/fr7l\-^=VmQUVh`0HGUqHg,<1iFOQXSchftg5L7F9GLo*&1Kr3-bVo@Q_T'cI3uBG1,7
hsscVua4`\*ok@HO\V>+@boj:a57.KKZH(pVPnl[)IbhuD3Z:K7inN.6(ic%uAs(?J=g?VQfNN/AFm
6Xm*K9/m=Eh7u*dU>$[<`J9K4"9m@mmV'o7q/uk6hdm:G-I#I',VYb:T2ml8>^Vc>J_t#2Xt_rOPDY
po41krUUj*=aThrb6m@e'17AtV&GBf-s54sjG8N2)(aM#]oT2L'IS,8;27(!L:1cm9/"R*iHo8f:#f
:Q'mI%##(%p*^*Ab8O^QhT=N5C06*V2C\ogR6J*fZ<Z.*tJN%RTbReP?!C^Bkdp[jC:IgGW:+%>pW1
e9)?[_:C6F,0$=GSf$__$B$A%a:=d;Fkar#gMY=4__dgk(XfSL@]-)gcQ[,-Po2==ag?f[i61Tc]i_
6,dl/S[Xc2p##H#m22AqpJjcWulRKY%g.&gAM$+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2
+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8c_&'>]'lgZJ$bSlWT`FpQ2RA#;Ecb4l^fqV
QkiE4U>202uU^$rCh%7/1mH`_>T\%TTr0)+HLZIFuP<K>%TILbBl`DY+jCtZ?!2_H3^<sMAo7u[.9c
pZT&8LU(">)AagY:r1COitRVK_aN%C?dhsEGQ>n;,'su4@SD,5T(ebF.'/dhEb-!(rT6J:OuuC)\LX
7,BODW"4NA?Ae*Or6E4a5-u0sCN$5THL@40&"R=R-B(4>P@rOk(g(m62?Ck3+7_%c(D7m4oY,ln(]$
>*e;FrL/H4)$q]3GGto="C2?u:)Z5LjJDQ1UkMeTXc)Z'QKORd#/Vfc4A+0Udfdg.HS38X`\BrrC$M
T08OhW4NLh;GbP/l6b##Qrt\uGFUt_H$_GPo&[nTHiF)CO,L`=/);H]0fdsMoM:k8]PUD83-,08M6P
7i]?%/H)#5kdU'=9uT[^hCnC8&Ug,/J0c^sHZWhu("%5'(q2'[[W'=0)*?Unp.J6C&KTpoA`f3[u@f
j)au`Q^JOS[n$\M!?F%&AmI,2_bbHd;.V)CMKTCMFcMt@agm.(-<u65p]L8#iqptF.mUBYZs..#k7i
oALXJp`jV[64](:^_F'].DU[X=nC9d]Bd/CcVDDjAGK-<OXc6kqQHMQSVid#Q1p^6F*:/XH?Z5tpTQ
HBD1pBU#?^-:-I50d0_V0\NXhhCUFCOSLS@NqW&)Ob:;^GrXXD>dOH#Ri4%X%ZeT,XDKd4bQNhcA.7
hiZRh(In+q?Cml8ZN1XL&J5$U&.oKT&J,TK"HGhB#dKZQG:_a!JZ3>FCnWV$oR=_ee):1b`B-m5)d+
IDL6t)LXCrtg2\!>TF^2<hA$K^,<)lYnWKGMSe;aR8[E`p@$uB*PmB;!5JroEIerJ)&KM@@sp,XuK.
:VtD2Tq7Rg=\af,KEg,8K9=06;57j0O/-!ZX24B#?IBIU;HeG3f_LL[.RDFb9*HQ/1cY'Ou?&+OTG<
H[0"t0ri*?kUDrT\,D`mn6L'Lo&!;RI%(9km!S9O.XAiXD<0[#41plpRb>!5]A<\t<Bb&M"C>ie'/[
F%sNt,r8NK[$"!YKEajc,VVJkk5FT*5THdSa%#'S[LK@s(G6BcJoBGE295Tf4&.A_QEAME%R!l7&^d
)BW^MT&O@m"Qfr)?V^j*PRkXFPn<SZ$[ufej9P//*<kja@EiW.WU&`HUm>*d776,rTa*;5Me;/`L4M
UfUPRLHd4'&D!+tF"^fYO5XPiI@XGO9Ln03*0?iob>ei2f=/NFe*.HtJX##dJ+Z+d8)E!<#8ogh7SZ
&3e_d)#buYd1p(cc_m"e"1H')CNF(PdR0m#m3)'=\/bbI*WjLgchSAC?pOnLZbUXNOR>RRb_>o9%UG
9fT(?q<AIulSu^:RRb4F@%VZ.uYOM65Nff)R]iT@I;j$iM0,'6arr<UZAnZ9<DW@VZIO3]a(UI-4i>
?,G:;gBsZ:,TBZsMn_G<PD'XcA<sq)Y^.(Y[J.3&,joHfHZe!QNf[id'8'".sj.mJBKB`\G=5e-=B@
Er*W*7`r-QqW[Y]$amKV3a3"g0\)KEe&X*-JL#@VrJQH0q+8T\>=jXe*@Ke0k:q8rSd`OBQJUY=YHL
.o5\@*pA8SDXjbcuKa9U&!f!)bUrd:n\b1]CdTOF!b7O>PQBato&::Ad0UM-!4U19S`:,qbQIh$YAm
.&IggU3%[#<BhOI@')s-?*II.]$q;4\A6LLVW\1l(ZTVR.`\MV6nT.7lei#an"ufWR6&g8L0;n?*1#
]_t&j+T&J8@?[@W5hrV#D=4BUQRSQF`Kp`&^^V`q/aCr6rQ5DAd<,=6(O=#Oia0(c;g[75)d[lU?D.
?u!I:p/n40GW'l[*nt7=:ABZ3iW`h%SeHVE/$,h?Me]qfPpN:DHQKiGa%T]Plf)9np-5l)A4c=^4&(
!+U9PVXrVF^.PBfOeSDoiXmt"brb'Dg_W&=M"W$8[H!e.!p;NIJUGa$"3j:,QdgZO@mRcU1kl%ieGY
7EPDBD4.8<L@J9XquAA=$m6eC+uQ?Q:D[WaK)lP;c$a?;/"pZREq[Bi9C>\Sh*l8F%Xoicd9ktt^.W
f"el:Ec<AG?eD"@0<@;O*[?3"HifM<bus-"s:(A\7hcq2TEPP1b`7o1ft8&:@tE1.A`U_<5^2bR-i2
(a>MV@+6;NG<et;F<TS"NdP)Z4"2j&maW,@Ua"(9c4*J,=.f!MO_dX.ROg@=/$oKZj[b7h@g!'unKm
e)fUf:6#ltD]V2TfA'=G(X<nCl#R2Bs3/D*:SSXF/EJQ+&$&cn7s)]Q6Xj/*Dp!,AA]kV67;bATrl/
Z3iQ6Ve,-\/Epaef%ZBagl's1(/mBaN4P`\8PJ*D>X!/fQp!Qd[S__5(^+rCa$WPVSWm_2Xgre$$OE
-bM4EdH;(2+7P=DqM[pL8U_*K"[-(<<+aj(e`^^ZE%9'-tcOsUHA';%*l)-T=i^>=88Qee"KCL9[Wi
RR$AIB:>gr.asWl2(RBi`4X%<=Mpu8P9a,OqBC\TU-4-H?9H3@<V(d&PGD%&.oKT&J,Nd!>,kT&HNI
T&J5$U&.oKT&J,Nd!>,kT&HNITJ,e*s.O#uZ+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+K=`l#8
_'c5?3H[@-JPRh/?0NeNWZs)7p4/3IN/KKbu&/J-NE74gG&Pmf*8j6a(`gpI%rbq;RkaQ@bi5R4UlM
LX-9dn[Z3d&0$/V?$5FX/rk_Jk8N^l/PCn#A>@&4`as=$A`:!)UFs?IofB8%i:XM*f2U_9daZ<bZFV
c?p\(Wf"$chd#(R1UhKR"2f6_c^"ECk(8IYY$G;`SJ.ODl?5:GrgWilfseN5.XLUq6^E"Oh?f]fs14
BKk0VsQl.^CdKFP,X^Pl!5!T<Y;`iYmpC1Vma#5!/*FN>l#hPZ'+UN0JkI'^D!(4XjH&EdkRI_WJ4&
H2W?.B_]#n+K7MFhD7Eg/0sfEaQYi*pP]OPGCbBFk,bss6fmM?i#EF7Z/Fa-4R^s;!7_1Ss*StJPi,
,b!!-P$AL477r:u[_A4<W"m)jopVGD5hoXDr!2AX/P1cN4IK9<<!*^u*/l6fJoWa-Q8=%S?[#+8[?a
_?$Nm3!'Lr&:B^dd2;cQY/kn.j4urI8;$MYrr@"c(2JfP\NHsnqHBdc?=K1s,:M%ToXt*"W\PRf%52
nZ_Ufk2YcMU\?R&k4-6["4U2IYl]LIkBo!,WBl:.HB)h"bMr&U\20-e2#P&Gbd]i[/ZC\V)j>8q9ne
nWTt&J7V<6pO.."@PLDP8PX/7he3)aRI!nGI^aP@#T3H['bsbZUsDO^tOV4%>\[YnimjnP`&4P=%+2
D>bjnZY@uUV]4#-jqYN:PeBknq/Z4Q7NC[Q0e7pt+D9Nq.F<\XL,s+M"-:$KrEuYXNk'huHkBaqu63
Y&/@9Z$N1,t5;KG$Zi1GY+"!.-T60,m@]k'"6Z7?1MSgDjaFFL4$'ZaM81VOD/T]#K=2L?70:I+<r^
776iAdT=p)Rni-8,8^NX\HEMoO4kW^g3U9%V0mP-9haq['Of[#ipL],q3s2[RokqTl62$anR87J3Nf
o^5$&Dj+G$tRkiaiIi0@<+EG@,P6I$9@GQHFT74"[B,28)B2nsP4kc<a[Qub<aR-EDlOZSD>2VG4nF
Kd+R>2e+L?KV(uHtP57!0'_[NMcFmH(LR,TSA@3[+0:/Stq:O3!+$q/EM4se0'U'iKD:2kcFDYT;e,
G?:f7C/I-b]lr)Y<6%cSm^jRE)GEVKcU!3,4dr2Kle`1dPN&`-@6N%tVS)4/F7(dTpiO[[5MqW'pcW
8J+%]!ru(MIlncnOkLDGH!:Yt1LCi_6F+iD2IL"(PcH\pu=j2q(]BPaT3@#Dn'JiTE#.&gB9C<jgOC
a,RYF.JS<\)i<&644-W"#qsf`k6KR!q[^M\m6d7\W1kmIqL$9+k@4X"\nIs@1<*nm(693%ToP_4N0Y
=&&+=_GCYmeHpP!)!\p9\2-d=UY\WR=33np%m>fIRM;,n&NPX7i"S3\FF3C)*HGjfu0'$@5RKQ:"sW
b.@?=TJR^o+rE;LW)s3Na,]a,ZI+a\B2"1S/fhG9aJ2#[!T2bA(:%C/n$;H*EuG-\]km!!rImX!`k=
3WLb%jB>ggFY\@TB:i4_G%Yjsg<X*2:3Mkif:HF;ADfrdDn#ELuVGA),k"`o43fc+Y5.sYafQ?HKdo
?fTeQ#\>MJ@tVJX1.I`^[Q9Mg8LWpT$9P*9RQ+ai#E1)[2Ysk#B\-BFOqA/-$Rl#5"jafL3qY!?$a3
/Q==i>@2/,paJP487!/a?SkO.ZNcCYKUWFk;A@Sq&9^)Ro2W-E\q-`)$@tu_G=<[fDRUe9Rr\$eDeg
+OOt\pU#;kdNDAKd_@t:tibip/5Z&QAdm/,=,'_MSHTo&PTD:QJj^2`'9/Otl0B%lCe1/gIq,"lRJS
\3%X\(mSr4fFteWMLjF<_MZC5-,/OF1fTFa.Q;*WH2MWCW.;J^/hUgiVoBnPc'N4]Y5B3-e>5a^9Hh
Ymb0,^e5=],4.PPHrrC8dj3*NOW3<%oY(>AC0H1dTcDR17]^p),7n&q#MpbtJi_e7@]P60G+/[Wc?@
8$<ePf*M>[f_RcJ.,s#A\t6&[o2b>:#[oAd@2.4SMG0"1kI!>mA$^9iB,kH$Bi0`*tml66%u4gR\/#
9?nL@=Ou'F/<N.td`)SE(@^*'Hr_St43K(J1UnA`m)Jk5qC&M4-Hk8-f$k40>NXRagL99Vd-AZq"!/
_`MuXeldIWA'D7LbbXmf1\,6c2cMgcU6TC"bSLhffdf;l"e=%OB09-hgr#<E]D%;=Yd[ecs-.bH3-%
<P=IJ`G@A^%Q`4V/HNM'J+sK,)e@#!lXl*W]ZZ%H&EeRS`&.ifraj1d6jOQ7uFFUe@]OAh,?qklbOH
4<q5;0/>%TkWaf=%)3'X\o#f]kVH3<'MQV%hp4aqh-P=eFkJ+W@Ou+),<@\UX`[gLfnL0kPDId1:1-
*X-LNgL7Glu025::s?3mZa=r8huMVYN=R!"me3#2eSn<l`tYaG>gD6pO.."@PLC6j,nC6pq/G5X\!C
6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6pq/G61N7Ui#!
hQn_.a3Ct[o\Zb?_k,e`s"bpQ3loiEk6LZ6doWU5%+Og$fF^/L^gmc1bE?H86+B5@B):YI?8=C"E;7
9"+VVTg9Eci)h$*EU7cg_7&^/2?+NRiNM0BR=)*M5OiQi/fKIeDI:\%&^/@ri9NI$p(^+^a^N<@jI*
&]:YM>J8_Tff!W2k[ZX[sKO+"+j;)O%G.-3ZX_:oc%ms/24)/MBM^:1kN9;WKF,NN!Hl$5^IG"sr*%
MT'`c0"&9MY4Y4)ZW=>tqa-qpsG30pD&sT'MDho6C98E-rG?WgiT^^N%!lYtL,S5`f=dO:cG@*u1ej
B7_3=Nb7Vfj21a1ks%d3og@`I/@DqC<`CKhC\;:4Rhko,pY`M6.TcdY-*O4lCP(>'"*+mKpUTRQkr6
?6s3Thh2FZ-W&J5$U&/V:Pc!X]r>SqSN%8$+fDPkl0m[G.@JnXog/peW[^0=fI$L2:ZS3!s;_It33C
Fj;M$h*rNqgj33RY8BJJiK:pgITu68audrfA*qg'=*%`DCjt_"J.aGAS^CK>2.p1S"",AC;S_jgNb'
(oWm)ig50I(M'7/*dV-"XG<m%[XoLTWp+!=0o@fA!-U"7`<ltp]J4[)Ql7O[!-MOsf?fIWKXMCm;>o
k/Z7nk!m5n(6)RAVQYDulD7>u`d!L=au)Zpce1ITA>sDTau)DF[uf;JrM@;2,ul\<F:#<dMV0]%6.a
j/<rKg@j1&>?Dppjdo#8*4gG6-*8C?+i>nVJ^[q;q^F>[XF_Tg1h9*mUe)DJE#mrrkBc">*C/.h_l9
GR\aZPdkfCug7`M[@il%!:Bd:i_C'uMOd2?HQd"p[5";:#^.;jetQ;Q/rD*j(TLY#ugF3?q<rT0<_L
NMto?+$ab1^.(ArL]p_@,j"$\Yf9_![AK1)fn2kCotJ^!!!!#^]@gE$9Gpfm*-BKiOWcUi>Wb*m,QG
%L??DB?;TZ>Y%qX4.-b5c^#3kA1^:k#q?*^!G/_;)F<L!e)!n#<!&l$F.S-f.koDW\Ptdu.8E[s/>j
uPs>g]C\[7)j^>ZG7]<_D3V9X-KV9+,IY`3!h/8Wh'Df[sEbULFr,emfBEeO4#@=(Z"pDRbb=#C,k%
IU*_U;bC0Vl5^WYcp'*"mrLMl[[W7Kos;rdG.K.:6OU8KK]dco&Sq&#po%6TDkr5qZ%,i)`r-68%\t
/ZHJ`QTM5GX;>:&Oo-I&HEC?+G;o\"L]$`ZITQkhFN5*GCTkP988p(`iU,ZLS,_i)]S?KYV7_W[lX=
&\)./<c,ij%%N18J2EsQuY:T]l_%`I4@2'e\>-Uf7=m^"$h%]TiT>S@V!lRjc-HR[qiCcTCkTjm2<<
lLFB<8@_8qS5Wc,4>E?Hi%L&9l!o%'>oXA&)Qb_f4oQj(49PudGP$E`DnorLEU$u6V&#-X!.nr^CC1
q($[Jp52?-"*.OZHX6R3m)L34"USXu9q!RHLl6`e0.A)J`si`^fla4U3)l#JFiNSjsA%@gjKL7o'`E
j-I:jiMOak<&2MqW,[PMkTFBGGe9l*)U]n423O7gZ<#&qlM?HJp^aaq\$hU6NgR)T'sP6^kalVa%ZG
Dhk,b>7ON,qJ?t3EI5d2:[1e3_3Skq*(+o.RIa\=:nC"&C-pYTO;)S"ji_Ws]JFEC8=O"RIOauXj'(
Wll!BY.j]/!tY?VTK!TkG_j'0\&SI4YBC4`ObItgTI./:8M.=1j&*/,Ic<HGCU[UN@_@r1F0oe;qkA
[dN<Yi'a?+Z!L(p(2=HT%9Te>d^T48,Zq/B?W_&.1U7o<-V!bZAp`7#XTrg50`,RldU@_PQ];9c@45
'A#@ac%oWalaX-\1W"bD:H7#CgKmLC]B*&kr$q,BXK@ZW__\bC&p%:;\@'[mA9ZTH))nqH$F'KJW+V
#$BmgqF*V%(CeEPd<b.Td2X'0.Ujd8p,k@NE\9KM05<!_Q9,^n@HQ_l8:7PK`C-Q>k'\N!&.3`).Ch
K&__=+]7!PHSD8)`i-IS[!e#7j29:b7ti3J('E6-Ur((FC.fX*.6_+-jg-j>Qln[lIZ]C44JeGC$W.
,h8*KM:7o=>E%:c>CTGLPq^e?I;[L6iJTZ+8LRR8)dUX=FEmr1Bc;e&[iK77eamJ1!C-.)@&*-n[Q0
HT\mQ?n)N>_YpjeP-_KBZcf!RUj`1d5L!g/FbUtdkJF=TKWj_9OBVWC`HC6"/eIkMM,6>9rb<2+-*e
5;5\s]<2G5D%fAs]l)o[1*>kS[SunSqJq#p=Jsl:1W0JEj>4Y,%MMdc7<`eDOTS*\rd4aVps!YG0'V
bXSH$e<Om6<aP0u(Um%sI>YiA&J,Nd!>,kT&HNIT&J5$U&.oKT&J,Nd!>,kT&HNIT&J5$U&.oKZs3^
]n+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI*?4>G@%,SIIF3>u)`Sm\[VJr?u6NPTrsp
W80=\4H=JnKiI-K6dTB$J,jf*E2Vap_BhIW3)o4Woq:!`C4<W35Z@)DWDVYT_V`h0X@#\TT1f$^+#T
Z/o`.>XoiHE)scR_>=4OMr72sjDo$6nWQ=$QT1t:Gc/o9P(=KeL2qe\4V'Po"nQQd.Eu\&nNA#:-!!
esWb#!5LcKNVsrr@14djq;]B9u/XD6\B5J%F0-5l,`LO;C"O^_ZWppF@+-CeY_V,_4H&?-`![Q-iu&
K>oXT[T_W:'gb@/ghAf`a:[gq1Xqum:**I/l,:U8]mu%5f6aTcf;lVYHTb5][[N>b;9H[>SWD"X>i3
5E>G]pPNclcgm.`6"SCLNEITi6X%U6D^]t*L11RHhi$U$NB>1l#VBI3"ZG:^P2MqaW'l!_=QAQ^5".
-@OD'Tbma7[[^oGR'<g)I7KQ-cs(_M7c$c^OmX5cJi!T+5I#oH5"b=(F^"P[E)roPXGuA-UrVX5!t`
F6L9KLc_eYk-&r59,'-7D7>opNr5U%#HL3C-a'd_qBRM`lP,?fQ7,@$s[QK8_lkSg3/F@55)H'skOM
Q9,,Gq-1q=e,3j`,Y6H!Kpf:j0I[ZXMDTi>?AAAP@9l;YC>Ni!298'>9pl:7Ci]deRc7`_"pt7?;4j
e!fYbr<QG>+?!<8P86"jDl]KBVdsd0[E^FMbVJLlJSt2=U9MQ$,alr/_6Pg>B%4c9,B^PBNh]<jfiM
23@(JkVb2Cm%*=7!#YW'r(Sju3nNuJLKWGCF61."?$K0,u+5]X>,O!I>8,T?G$A&*.k<<-u#`t>qDC
DmJPVlRb0L,MI6.YCpU%2q3BfkIY..:dQP&^8p7lF9&*D?/YuHgT#&D&-riL(%Q+MKeQ[qO<8Q=f:E
:oX=#!JdKbM@ZA^!c&I@"4P10"Wp2<[,71+'Z6>p@RmrGcmX;Z\AHs$?$qD#/MOm^j0hC;@G*@+?3]
g"#[m^KNVb/.rZCTN''"9tT!!q<9l7^K"6CD%=M/77qF/OW8F1ln!L88msGn4lBb>W#4O*@=Qe4tKB
;'kUZn"S>`P1</B/ZKjL&4A)#pn-htPq"=JdK"%'bAAD]OMU,3iLiYig*7hj9Vp.Cd[go,Z5^'>8)(
95[mu0P;8PaQloBcl"2Ws+gZY3_a]U?XNIe0EBH$q&(T=O#WO!++aU;6C<,U='o;%iVDFAbbVDbiEa
hb!a;?=PZG9T?7m9*K19._l8Akj3Z]8_X0E-DQ/=3"*6_(B3A'TC1;-!YlV!BXZ>(,d%mDQ:j*R%U[
GrV(-T0'@?'.+>n(RB%WF1adP%F#j4&rPR?^dmtp^Q97.G.#8l784eo+#/d+Jq_)[,l=upCUHXdqA<
LqJH!B2bk(]A$T$R\]"W]NG%t3<k8)@8YiLZ4Zf@("7^!#=/6fl\c^I"j75n#C*4;hbnpZl`@aB_B]
1ZU/+Xa=DZFn.tK^6Ol%<D(&=N++IqVgTk)YQmm`?E5PYV'4-]S[EDm;UTpP;l7.`_!/oj)r&21=2@
MoL<A,i*Fhla^b56@hI>*oWBsmee($fcUi.R1\R?7mrqmN9Xg1O9V/'^ghTiH3i_S>eh,`#l),6_<Q
517?3(FN'`PV>^[C7Xq(3<I))KoDGAM\sqD(`DA^L"A7bnDgLQ1;:e<#4%b$]u)ZCHh39X%^r5;^5F
)ilS^.Llg$DJ#QRJd_;Ro\W%<qcIapE*Rjb1DlU'sROWJlL,Q7W?sJpTV0lBEc&gG\<`2_/1dp*-ah
qW3DMuW,puGq"J>AMiB%97ha6R1F0n&^mk-'_'`rfOC0/+F&Dk"<5%96FUfdj%6L%5PJ[Z+mYO'[>)
W[;W\8WOO`P;Fj'3R)GO0a43Z7bl:\8P]b[E]Q`HbpLc8OBJ?TLHf8("rt_L=Shc3j=rJL(n,<URVk
`g/B*Zd/ncMI$nf<!\9n;G,t5*mNZ2C1";".OH::('mubL<3q&h1oNIs6VMIE;]uKMSm^&J"k'Tt8C
iqsbNj"Sm#AVC`>MciU-&l0uAM^&jR82!jC,)io]?a\g^o[J$Xms7u1H$*t1G9M8>[IkDA1fpq'5o2
M6hq#&EPDZTdh/^cF=!cTMVAp#gD+;?Nh2Cm^-D^4"07EiB]a[XZdUJ'H=H?kOaUC-WZ5&E3(V[Jbh
;Q"O@7N&--_'5g=mS;<`@<iPq8A5BPG?i-TB<io!$dDb(T[RSu*(oj*_RYX67`?a>sp[W7q%*B6F7&
jsHmmSnBsj2\jOSTn%n7lh'$*D;qZODDZU?,:fc>D;g[,K)*JL2blk['`(E[7niGA'.GBO]BUjbG>$
pODf2`P._eZpWG<@l!0X'gLUou=cRf@T&4W=RG?%bse9/8@*e@$]9a`>dC[?LZV5K#2Vf2sl$Wqufd
pF@4e^cYuUh(9(6NhBcO2[uZ`84!CSnhF?k":hicWaK(RTXFdIP4Jq(j(^U%@+MrQI#7H'f%,I8ltj
)>Y^2k.I'J;7!X;f2WtZG$F;%%+!)dCBqgc2*=GR9CDgrbbk7E@Fh#,SHN@^MS3"549+QW_+&Z\U!R
UEZ_f3>";h<+T+HNj/dUDTr5pN==3F*#rTkN&5IqqZd^u%$`+/7^o;R,U8nke<n0mVU$Bc;oqCMDA@
47lN4GA(]+,S[X%UoifU,IdX'D!tiA5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6pq
/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j4A<`+\YO=&dc#1)S^O]8if)%VNR+8rpAcQ
DX%D$rBY\O@]SF87dh5CTVH7Js\N8e+WK?H3pgg2P*NS/d/IR94&gihuU&CK"+0?,cM34S46YG%*e3
j07RVdkjcC5iuOLOnJJqdPi"&l!q"?_+nU0.78$ib.&INQZf?;7GWk2Q[=[_b*^:[f`n\&'Np3<H#F
Hbq;eqHE4HG%k,FuVQj%h0dhH\*aK2#+nk76MYR-?tU#3Pd7'k7"n#L-h$8'l=a+1cY'0uke'(!9<E
g8TS]9mgh:&WKtAoY2\pJ^W+mNtdK]_qAMfb1*u",\#@Q:430!F1!aHa#]r7]8J6+*CdX5?WHH:Dt(
nq-tqmbpaDlaU1uUafKZ`%(:h!/A\=nln].cC?I/<]#J_U%9,Qs*f)Ga0WX`YO>&nMO(J(cfBW<7mY
fOprE4]Gs!Y:D$23kdg+sMRTiNr_!BPHg_rMKSp79^",4#K_hF$kQ-1.]]&3(L5TBS6?6q[>=N;h?-
H34!OcTssbJLkl=oY8G<ZY]iGBR-CWNDBOM+!qJC9YdjkjZ3s+lRbER4qf,t#4KXns(P]VlN>i-]p@
DQ1=/Fp%-PE!*-QOVqG$*HTdDTekTJtqMA]kViCMNnM!M7(7!&DEl17%2Pj(-l_C8n(bXs4qQbQo=N
)`bW-)MPR6OQWZXC+sC(a[Q_4%)LpYm&o>.g,O,s%BOdI/J1E7D)4ja92>]:j#fGZ\aDNmIE3OGH>'
JOJ'=DTnUEMupikrUDlR`l#-J)JiXn&-YqSb;`8$nfrVKQ=G/M(L5Nl#kr?i-*8b$PL#HNW0%"HWtQ
<r<bpuZBGSdA/)9)R)OB3E7*4I#VUfdrj6Z-c;G!1)TY>9/T^L&Pb7[SQ'97'SL\pi82O]a?R0gW$r
W2l/QUA#!F[NJt"FL>Qo*jjcVAO?S+LjIVg2eoMi.)eBL)T;?EkHSk2U#"^0ONYZ1g(V(S7m-'1nGd
.R3CX$]dd;^6dcX>+H2mUm+3i[S1r+^0W$u^9ilZ9PM<PBq3-"u;0$ob\MU<Y"W\p4H?.&2KIO[dnU
Ct=MoeJ#V=$m`q;Sls5aBKS4PpB(o^B9qj`<)UY=l&BeI[,u4*4)F$um,n1`E37Ra6$;MuV!Xm$a^#
'Sie=ZU"^DO#fcqW%VRgjBf^iA/;c,RoC8Y&pe`NfM!I6%>DP#s;l?:8CbD"f?]\Z4Nb7jX+Vq1_rW
-njunKnH?5no<-@45j3HhuP'5WWsUR-V4[/CQbZ7nMo`"7&'Q6e>%f`C:S&+sN2t7D%h3D;>)6(Z3r
R]sV[<R_PDU]!ar[7c$DlqEB<)'^-rJQq]DrW-QpHH@R%&3Ven@W/1WfS<q%,"0NY,QS*Jd"9/?i]p
M`tJM_L%CRfH/XoQK5ENWZD[j<e4USipi/&N2\\JOfTHk[sY<)er']Fj]eDpC?;EWc<>NS98)>0=rC
R;&^,!IRb'm<BOTUS#!N<cM)=<lXPiJgQ6g3K\$&*bXmK!ld`;#$[6p+`j42/imlqYA!l+I_JU8-(?
*A>-CGMJAB7taVtM$SdDfUp3DoU.[iB^-%_Y51e]n;$S<NE['8<=IOe,A/Zc!o9o,UT4u[N&$`/`U*
tc0!^PdjPZ,NjUe!dF@?CG<)l*h8!Y+Glge@Ff]Cr++X*A?d:F+./tXL#_eIMmgWb<DM##&,.U(RK2
Y!7ZL0@kJu`1i04r/UhY3B>*jGQG/r#gn`;QYnfBn:+!NZRdKLngq9_ppH*J4l0DV"gu1rYpU,A(@c
Dc@\$LQ1j]*jO:sA_jM_LV&AdpkOoon_#@tYPUA?Q5CVT`F1aWG]?8hF1]K?WN-C)YQ57K?s_J+'D=
QYDi#CiWO4?UYb2E#K/R)-T:C^!EP;=-4O=\.J2&@*_Q0q3X"o'>:j'DQChUk'#:^cS#U$Pjf?PflV
3=Vc2q[VM[*('/:joLU;$a.GJf3NP07IK%TUWdMj0:`)u5Ef$lRQEMPTs_r8ek4mBq\MVL]_^88F0B
]8JDLY@0V,u$9J?!dsnesL0A$OfnSo5(kn\8?Z=[T:oH_Q_l*=G.;[<pa#l@kNf=I+[WEV.ct8VR=7
(9uLUo)LUFrRXJ\mPoC-lVB4+66Vg8KWb3u#*:oN,>@L76[tg.&;Ymt>U?9D6["A);7^BS6f5FWBB7
gc^G*1$l_jM\*X$T0%kkc_L&$pLsHM:pWYHEm/F#?o3PaFPE;+HF*[1-X-S2d"Z",O1#p(!D9FWI"$
Zh0m$n)nhp[:7c!i<fq'>&(Op19%fq?taTjcD3;nV"G\-3S5"aVl,jsVfTsi?JJ#7A:#rVX+8a/]s"
C(>:5-mJ/Z"2@W\7:FYq/%5ic`?[eZA;CeD$g-Gop/#;D-gJ=Qu^\%tKmE.V"cL;2-5-WUWEAGtYOL
p95f1p^,.rr<-=_oX-ZcigH8FO6/s=l!)<)2qQo6mSV-(oA@t!tZP=&EF#hno]hj4?lE`,\%(]G+Of
NY(gB]VYXQd@P0^)PmuYHfA\Ao*ER8+Y(p%;o=akgIcHl]4)@+tTu@pE,iR'fY8QcASo$OcG#MHC2*
m)cP7\=[6*+1J'1`m##?p1qVlF[V/"/ZKcUSpL,4Sl0iS:Q4NqOK"f'.)gW#[WF1pqGUYR0Q,AC6s<
a'<n8pasRL&J,Nd!>,kT&HNIT&J5$U&.oKT&J,Nd!>,kT&HNIT&J5$U&:a`0q^Nd4+sI(4+<i!2+s8
'R![8a2+p&r2+sI(4+<i!2+s=kkClBol6^ltC#e2C@m3g#8%OE@"Ya;eMU"[(?^GR7>I)HJSqfjaT'
['nZ%;m%dJ5r%3:6a4,>0W>X08[X41:uu37I48F$[Ajjh/-EETjMrETr#],?V=N(-\^K61$uL$I.&*
O25m1-oiM@cSi2Lq3DJ:Poj,f1^QRjAk1<V!=DuZAWK'O(/&Z#tm-Sa.Z*uI:`I!9b=5rcj3s_a0RF
5?O0kf8l%sclZ(N"_NQW7#.l$2S]JiC2&e8W'jf&Z"7p3YE=k]#f</t')r'X:S'd9t&L!*.@2DkuES
8hS'U>,/D\<<B>):Gl(>k:qS9a'l;E[oLm$/1oar"@Q&lLk(;;$]=>S+&@^QR!^b#FbM+&Y%+cJV_h
l@nm/9VqbR2:_uB^hTD@MEI3s;^D6(YF;>A@U@[(@i/9^$mh8pf)j(mQ)!j.KfZf?11S8gR]R>B/E8
@rBB/a*QJ\A#O,YAJR_'ifHjkpe"p<8c2)1Y%d-('ELQ3EtK[WlH*TXg5t!ngPG-9p.GIA%$S]P,"8
l@5F6N[t,^P<CVFPDPfl4JChh=\Q08N+>JVIJekuKRf<@Emr'GKW`JI-@fHFr2s]K&E3&KsdBqe1hh
&)O`Mf9LkMkCn_QUkl7alcaIL&'&oUK8c-cN)"5->q(1&h5?P3Ja*(1_60grO"9e($Bq5&*2DXr[Ep
rr>B?=aNfYrr=i>>:9$-/ORDT!&QoE-hETZ?,l*S05B1V&7WG5&dd0f$u3&!SiO%n+!tU1O>AGI3F(
=&HQQ^j_P*sJX(k";9JX]@>j`VRlM5>1U9(<2E@GCsHha[^qF'Yq:3X+$NKLE(Fb6?4/h1"pQe#:5"
87N(85bi;aO''0YA:Qu2[*rN7`u`^N94p1G*1.M'stb?!D_YURU!$)2@fhafT)DKWYoSddT$_<3#H:
iBL>=sI,2uf7%M^`Cpbm<<8OjW@.#ttG]c("XU_@MVL@5Jl/?VlpcH!<D%>K/H1bBUkiIqp>/Nu>fC
n%DDF<g^;OqO)C6q^C=e=jaf?p>]C&;1a[Td4XN34h62JHQ3UW&lX^$OeHjeA@U&\u99RK_!4l<WCF
26*CYOhAXP9_+1qdOa93bFc0S^SZc`e58:j%';5nA>bgNKHJ`/8)^bVLCds0h),QdD4VUiA0WTrYhS
C_Dg`>A)#BS3WHIQSZ*9>+pQOU:ir"f]r*]M9U@Zg[7J!$P*pI5S#JZU0%RFnu\O9:9?dIuOG#,Yo8
*WhAnpFNErdRZ>Z@0p=5>lF'PN%KZe,FPor#aeW[fcX1&i]Son-V:!7h&I$OhnN&!!B2]]3mK[`NKZ
:98b]J<+t%%b$=XjpKH1Vrk^Nmafc\uE?;]bo"e)`^.U3#-:5KSE<fPVFr/WJ71)TN@&o+)h@300A*
MVRSMP2bSC+gPFXB-VQ@/<\[L.4J8#.*o$Sr:)CMOZ):CM55C'HFO?+K64^1V5\f2Lk@MR)KsXeJH5
@ru\A4d7[eh1^J>F3JlVFkptWb:'YZOjVW<Q54V=G+*\`g/k&%`c.i7<(c,9d\f$@r!u#)]gOP8NU]
Q]#^`1ZQA8Z@gA>`b6Dn$[@jNkM,SX(dQp)j\AnI2%CSr;!\NWX*$o4-/NR`9<Xc=bdV8J*aD*FH'Q
]TTq[_%.U+J=Ruo=_\GFKuAg#H9eW"gXQ@XdP/k<-8p-+.Q@Eg3+#,!,]=\'Tsfnij)-H"Wn6cUcNf
imC%#^N8FOqX@=+9A#a-dU8Do*af9^<'*5UYH#g4-Hr>ub5\Sg(qPH0jZ@>`,QtpsX/JT:<+Y?tel6
_bA1#>D>283,GfVrq6naKc=l8R\Prr@Zj;(/:Pj&8,S>XMh9HTM)NSu\W^1f(3hjJCfqnjML#0Q5_K
?Q6-rk*5Bk3^DNHf(''/l$GE9ErHAe:(AjlX`]BD"(IX%IB1\K3<%N&g#(-jT=XLSEjA]YSc8[#dXL
MsS]]&joABSumZA(c&k<qh\iEmE`cl3K,MZ6_7B3&!8e)QBgDW)c:c^K1g\tuB4V1Rk#!,7EL!7\BL
!81t6VXc.NdfR7*A;8m2]/R)FOP[IX`:nHOQM9bq_eFieWr74X=C15X&p6<$Y@NHPNt0KnkgcpXuK*
TEOQRVk&Q4$+,JuKl7@<Z,HGZE?/&3B*js]B#G]RjleQ^W\Zlt5\dDcm0sWR,'rQ0gc8f)VXUEI-\T
o4,Y&ZH]o^6iZ6ZIDpIW>`!BpjH4>k@DdoWn%ZEZ"LH:?pJ^b9[<ZXX%Cd@dRtiZ+/7LKBO_nN&%tJ
B0!IqZAo4'Qt9RX@E:9pjn9<>F^6%-O4%JnH8D$:2-:YK9\U6?%aH,%j;*Q-J;B!eLk(;;#`+"eL^8
feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feL
kl=mJ;B!hK_[m9T+&]Cg:6'WOmjZ-Nd\f1/rr]\1n/3%h5k.I3MS=O`lQ2<f*d5t63#NM__J_B<m6;
12K>MMEUPaUo,8W9YkYAQ0$3g9#UP'R,*e;76$R3h]sSdHW[fb3:Cf(+/,oST;idU;2KfOQ4$LQaM'
mG3>^nK23W5\_X`H82X`FuJ3*[1e<S>DXkKSZCOZV,NdXkqin#s?pf-b]^"]R?&c@Sa/U@)^u3PW5U
W:m@%<0kN"XsQZM+=QAji;$RM\AKSYM8cAOEQ;O*i[f6'b,S)0)aR+3guA+ECeQa)Q3Y&mHZD[0F'h
A9V1Q,s*CO?'jE\-*#Ee3;>c'O7k>G0q)'GN6-P7%&*VNi<fZ(r/`h\fHC]`'*p<P9IkoKEdiO)YQ-
09k/7d1m!%49#=%1:W$fQZi*r<lnQ=H@'kJrZR=af2.RdDRY,=)%;]KNR]RhTJnVCbL2M)48+!Q=X_
T\ERdSf\6&RU:Zl;o!?4u1d>1lo9CtlJVR2p*./&F`toQ!\:W>g`kWUO*6.9\aNlMW6F8rW`l1@sg0
3O,2WMFH,^XsYBuR=m@[Nrk1iSg-/Jkjk\:#qn]bUKO1c)t)\k#ro_HbMXa?22Wb7(;#$Mep$21WW_
G)IA6Y+NmE.IAo%A)bDaA>"\^MmWF'2Xt*Rra(ZOrrCF-,59n`X8KXQfDbiEar*W`rr>!@ir9"<T.=
n=<alALO5c15NrK*BFia(qmQLuchj_acBE%sO?#roOp9#,D@M#s849uu]OcJlPhKM]d*EGjnZ*u5#(
dD#pb=r6(&:WP8&JS47IRb"L0RklY_P`=_303T^q3m4N\3#pB\O9:9?dIuOG#,Yo8,5/o^/'X[?d]Y
g!4`%/\SJ"2(WuqHb;U1!,6jfQkKnIJbi""Ig.7ZCOuG:Z7gCd"+Q*(DCh@`7$*8idYWti/NpUph[@
D)TVh\:6"EM?4L75EqRYF/[1[+*\^HGS_'r>aNM8,fHa5!E#37Kgl9+1snUTG*_1&23e7c<.X456p<
.E#t5WIgm"W/P;0O\"Ko!)AOZIqL?uQ!FCJ79;lN2/]F@6#!Z2A#7qbl1QM_Xp([\:msG3*2W;p"tB
4(bhb`phNDg*p=Xe7&eNYbQ%X\F;Sp6H'RIbZXJ^M6j2D&N2n?3$a!I`8MYo;uYpOFY5TG%%Iqsfk\
Qqo^A%`\56^[]%i8AO#K?Y=X[=)EnTZ""QpI&M.NJ>Rj=a_jiVN`u@WL]<5)`62^0?i6Uia=[2'Pg-
f&QfPdW\G]'=]LjER5I1iSo0Pp/m%h,F1S(@"eJ63)@$$1=NK^*rr=P:1kX=lftYpBp0+&32!''hFW
9"&CF#!r6GVcT2*)6]i3V#2No)9EQ#)nco@Q1Y^SotRc3]D+iA<C!2%mAL;GZ(^]:;D-!-kO>0ZbJ^
%BOpA$]!a4J99p14Z`Oq8j/UX,X-1gaVHM>0*AAG'BZa@$U)/jJ&n&&8FH@*;&rGEW8>S%S<nRiJLi
+cf^pZNSX7T2_WnAgRBXfO;E!2M(X9\lmqj$raG&@+Gg(E6#!"HITn;_5=?'X?]J\&r7;1[aU(uYu;
%Wg@&4WUlAF^&dQ1WT/rq\,HIs>f"i)D2(jidF%Y@H:)*[+)&/2jhpUgL!lhibE6pA;<b9i**SC[9a
>[&i^piY5Qec0jR1YT/R>jL.(s3g##g1Q,)!4uoCI&Y2"Xf=+Rp^$_[WL.ERG@FYRMa&<QdL$/2ZM=
GG?Lt5&\b^n4$=H'E=K(.8OW#IhQA$2.H-.6t"Xt_4D*F0+q,E%DtW6Ae'\(UWp&coG-lChXWWiVMs
Pq7&_m]_kROuh!X"g7!okeFdZ@!V3NAZE>)$*$DdnB$Do%N--k:@@H9/-0rhc<"Za2.'3-+kap>e^P
/Ob#p^+WM3sn.<^bgNBX%T2@!&1FP8SJZkGr.:E8l:4t0ST`snQe/dg7@cHTj!3*mXM`Mj;0,G]CRQ
*/DBCQ65:"jO6"ouPX!(LIU?eABn3Q'0)UG.om?2#.]>Cd^Yo6pO.."@PLC6j,nC6pq/G5X\!C6pO.
."@PLC6j,nDs4@,t+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+q
![4"/<a>&aU+Z[ohot#'M'%3t2[c>g=Ke>ChPo&GbTlJpfC$BYZi<]T1^*2<AE(WijkO!/3.50DM'K
*duJ2aaL$j4ZUYWHJDVp_6L>"1j)dV_3a$')o'U!CX$FM56C2C*BC7'I/((Un)6gQhEA:NK%=<6`r/
1aQ#R6jFqGZtL#o80!.H@ZKGa@.7f@A7%S$>0CTOFd"RT2Nkj]!7`XOr-l5CU(@pn[5mB2*]CXk/Z@
U-$_)E-,0Yfh5i`u3WfF#g-c@Wgb06tgAlQBkTB/"L9M^,tC6f%/rrp#N`$9B=\9_s1c]%Tuq11nE2
ir3A]s)A7I+/l,\o='/8?L(sq/Hs81F9[VoH%#p<r>L,4]PC44TA#ZK(\)m4-HFMjp[Yh)QO/3Woj1
I%oPI8/bb*bUZZGSfSN%^$K+B-AN>QE,^4LO6r/t3aF-7_A5Z;CQ$`FrLofH*;L4\*pa\CC./$]PjO
`6Ue-S44G\K]RSoS]:EP`qo=1BXhn5\4]DN]J[q\qD_T0_\]o;7JZkr;'3d"\_*,!9j8WR8<Qej5:H
[0EfE(r^=P8@WTpunNHpMdAFYD)f`?=,^"noj2<p.g2morP=8@/,YQ"SiQK[IkAnR+jE4q7AGTMc;?
fgMN^\nX=UfTYLGs@8f!:DA4\tsW5np_PW!8LXGFXa>j+3Yl+^n`CN5F=b6JOiU7;oSPP8,0pubuY7
D1=j@!QOj.t#3TAM2+hjn*QltjdD3W^RgWIX$^+"&3NlrQeQpP.Kb,U%at9:Cc26!+f=$^5o^l"<ad
o5KC?N6hcBl5Pd!_So2YKb_1D#J)k/!3>33]"O6+)QY?Af4Vn=Cq_H7fdDV=HdbfE0Z:2\'uD:^-M>
a`VhMahApVaP-X?9^6V=BX3XI)KXT)l_`]^Ab;KW$_bFOKg$SM'f8;A`nOkHhPI$f5!T&IAnu`Xg3B
<mPgi[^@Id1m)iM"GJ0:&jYQZZer:Yb]c(2>KFM4IL!;.D&rr?T%q3Nmjrca.t!"A>,=!kG(BI;6YL
]7@WID+rHD(EhN6ShA=l[\;8^K%_\daI4n5+MWQM-U5J41AW2!]:qQBuA-n4*o\_AL5%Hgmh9odn:'
$C*AGPLtkHr/Sq)N>!+YL>pL+_559SAC"hMhVJm]][I*(de9b0:YjG#5ei_UR\Q2K+,ViC\Y%bE,i-
L!dnAC#A]Pi9npQd\&+YHB5mmq)d^0I'Ek6j?%#:\j7kc&-1N;#:"SU0Q9kc/]60NUR)eE?Ln$et.C
YOD!bB>GdjJ^WL1CY3H.df/i5p=J5O$^[@QZCT$;#NTBKm8YAWI2n5_:NmF<f^(G9\e"O6BqdH2`\>
H=C<7M'OFUHaNST)>:%q2V1e`.bNt%&Zd#pAtF+=CRQQGR@X'@Q=dF-_+$!^-![j-7PG]`/R_]=*tY
:i&bWTfs2.k01Cn&XO5]^AQQ[#Rd(@AtHfk3gS+[ou%tQ8:*U)15JpP$%p3*C-m>nMXQ2hNFS[]sPJ
ZTpdtsbu'cC2YYE)n#)J\>,B3rME+&L8XMT5Uc^fqZ4WkE[oAI:\iBq1e%N0VYpSW#F1L(EV8[thn_
"/t.e.mELH)<:Jg2A@GMK[O%703Q;YHjeXf-%MpoQX=+PEU1Ut`hG/f'oYP+pCKha\.Z!(_I,e#lWj
O#rKHb!U+R=VKe2NH60=`NFcF(NSShki<NCF@F()rLl1jmA%U8R-J'MFd[4Yp)o>[^6WrcYJ]m858K
+%_s8MF"4kP9e#5>):k/MlmZA(^&J,\#3ZTOgb&CP3;c+Me/mrj_2Ep"=eV_mU:E<D(3C0km_8+^._
b`Y[Dp8MA7ot[Xpp<!q6Ui4>6rFkST4$e<Ec\BTfO[*GFXfWSVl$;Uis:XaSZ^qcJu"mn23(n2X;gR
u3qQUf;,^DKj&@m9'o])%/Wu],^tc7c+)P;$kWLip.[%Q!MIR@hWhPK5W!mGqau>FAhHA1P-Vn\03f
#N3bR^Yf+EM(LP>b%7o#*SN/oKZo[mP%jBZD,^;,D4XIn.Fe)<[o5K;mr7Ea?,>[r_ZX[l^a@\.&#6
f>UZ=@u_sAP*Q(M"'jhN0&4(M/pXUS^*qpY>9#2((u.;j#.D<kS(#2#p3\t"19&gV<@(l')!Znp,FU
Lobm*'?PcMDZrYr`ArrAgPq#[fd6pq/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6
pq/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6pq2Yg7Rl3/,UZbb#PIAm8*LU(&eh
AjX<@ndJD5_8!$TK0`"uBd8LM0_g(6Vb4ZlFXr;mE8s2>7j:P!!m&@pBY3eT)2M$MOm3dr.IqX6p0s
-0&.aj?cQG*AW,j^s]fTr./g@cb1FkGu`fg)ORj-"Ib9_1bYCO/ZJ"He*u#=j,g$70_kHU6<n1EKte
m<'^_[T^7])^B/oQf^.eoikqG.O\O>NCO\!EO0E<b[PSUi,r\#2UIqID]F_%2TZolp,iR;br6+;@L@
\W%a]B;&]!,Pic+`o0[[;8X``<i2g^"0hd&^,A]iG#9i"\2U61IW,]a344@ml(Yga&%++!l"k(be$^
^rqj4P(m=r1DA<<'%JqHZ7]JO.=</1!Qigk)OfR/\3%Yk&&&2W1Fgp>u+:7%&)?YQMQpL/9U#se#Jf
dWZ+f.*D?L:'9XVL],WT;gZf<$o,5BA_s2I``A;3U2Ct8lQt@UKGH;"73ZU]dWo>P5pVWHgJg]_p\B
B42@!B0Oo/G>lPfjT7pO7$.nV@%]Fj5!4<=4V/b?W+D8nB?B&9"$l()uhTjK;pnN_(*-rbberc"YZi
F36t*,<ItST_uY;g^6<uAIal2g*gH@>r92KBUQE[T204Dn"Y"]-a0Ua%SIR)&bV2-D5l#hU*EC7Q.*
f!V.UL+B/ghbUT&Im'fi:SS("$pLWV*Q3!#;U&ZNL[g<.kN_n/Fm*;%_m4k0C"'.]Q7XVWl!gC^.+%
F']98F4sMmMg]m<7EnYecG)$e7g,Hc0*Bjgt8UT=c8!L],Q_&VFT-8`p>U@B4lI9?"\1$XX<ehl_*h
QI5A4cPJXpj%U(iu9&ML"-E]6Be+H3,%]\n.E=m9EQYRb!7oSB.MWonu,@1L(4tbtf615(.4%_kh;5
p'V"7RT4TAL$F_S8.Lrr@dtgqC\s$A$r(HE-e11pYJ!gB3a">hB75Yk-[aVJgYhFj=k<X?kH2.K9Ag
bL5&!1P4:o#QFd.-f2!NI$(%j,:MBGAO\FB$RBf:6RpE0SNt^tM\T`SZaI`UfP.>Trr@/R=`:+d`cr
t.=,a<aqWN@mT+m`aQGhC`@`JS?i\$s$><PJr`&5<05H9GW/@Bj01%&FWHeT=!3p+47lk[,$g%qmEH
$glUU=[7qO@pO`*/!LqCk(8d9+u^We&O256iiS[*G7<::K,]r*_L+;P.eE"A)ij#H-#.0HU-0#*`hF
7o),RH0t?!9X5RT)oZ62IDC#BPgZhbT4[[i=i1uQ6:Df5^APGB<inP$?UA+7t\OVgNm>/rP1cHO>C)
2Va['F[bhiQ_rSQPml0GNWfO!NRFU/k(0nEBC36WP9T'3gmmMSs,^Acq8g5!,k9N-^Ya-;Pe+W?,tR
"+=m#oUH.<2WV-2R!pA('Wr,b;ZPF8>15<C)GYgD"0.,7+#OdTPLi.AAepD/gY?Q_09fho,k^D;lF=
1[b8%JXeAG9\*7'Vg%$B3lj#MJEGBL?ePLFFb57YT'9H,i_Y*u'/)70B#gJA.-[GdOSjuBGmOWaIYh
R/3PS4=bopN\8:3NNDP+fuZL>@it"9-[nSHd.8[gN1g#Ef]E!fWg6".A`pP4D>YjnDVGFo/r'd>-5;
X)KEerf1>^?9Z#`_a=V2IgcHPQPO&WG1Q4hY1f;]4.*F1U>1'InoiMFLk&q"R9bn%h9HdsiW2a`p0!
REe]sDKiEYcC$F&\FTe[6%h01Qs6n3[:NUg_!3j%`m/eS,L0`B!8"In7i*D>s2kX__h_NId)Mer'YL
0YZ2i:plDE7+Xb1)VNir2IU[3BcZMaC:e/UNd.$E;Dq)&1H"P\&_1laZ'.#Q6'rb"h)[-YPH:@B)P7
D!JPP>D_..i,eh0*B^R7C@,/s+.(nW(6%#oe(31Bn1eU-fmWgMg=dnNPP^9XC9#(b%$G5XMR*X)\H]
%UmWK05j1GH/pCmj=#ih9A6bWL?BQ[8dG?VK("l*g$=X)ICJYFjXs%P;Ad)1cf>HY?b*6Dhr;OfK6\
9;IH42ai9oT.]9c;-+A*m5gd<a'mP]a?6b+eP74=KSd.4gksE^c>NW[r'</_m)BR3[J^eg_&D:2b)e
4Ue<L4g@:@:/\\oXk-r]O4C8+LcZ`P_Vp+QD:D`IEZ$rC_;_qJ!_AI,E/uV\VKYMZ3Ye(]'Ha:`mSL
dsO>tk%]:=iS/O&r&'3.!!a&*"_+OE4oQA:rr@\,q#[fhLkpS;L^8feLkl=mJ;B!eLk(;;#`+"eL^8
feLkl=mJ;B!eLkG`Uq^Nd4+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI)gm
8*LU(&ehAjXSe\G,P6eMZ3Y_-h<K7LT3Ig+SA6d748`[!Pg^LXqtdT&4Q"IO!S&t2JP5m2@hoLNd37
?(Gdm'];Ym/Hs/u*3\(n1)OhbFFNpYaA*>D4Ca5QA]^=L'cFMS@9t")["Rni[)2<Cj/8j:I([t7h(+
"[)e?ogjVAbnKc=oQBLRl_dg"4jWAI2Sjdm7+=i2MEo7.<R2p=p4$fl1'&akW+;nk%O19Tc[uH3HUY
*O^oPe/e0?([/J'$snu+H&=$ZFU].84JO0]gATL1"PVkpr7'dL"K94B`\=tA0`'-IkU*o4Z2-SbEO`
M/+2S[h7DQk+ND*__J\e2$o!PqG%5g62(Y`qg'+`,tI2``J8AIT]i(ICn2D&mt09GmoZhVRQ>9nHH9
Wk%YAS#C^.tbq2LB;C6D>gH.c)@A?E-+F(On=i,$XCL5k9ep8oW[4qhtB.mmZP$iVoE^h^1UD%9$2=
gc*=MW`,8@)1tS2l_eU+n"(*#-0!Gk%*'l2?:AhXTfAupp&uq^SdGUnNSCDeQ?5ar2mZ9m96"?Q+l4
3Y&XZj'c9a)OoFO\[C(h7Ga7_rKZ[]ERN(sqg]Xf2BR.Q/H-:uP6-X/];1:T=o-GEYLofF]QIWtk"2
"r9lbPDrU5Ege4sPKNn*W]X)2W,$`IMIJT69Krb\SHHQ>SiZLUT$Vb_paP0u@;IY(_)FF?HqE+dfne
2<(t72SU_(uTIhIIU,ObKsh8FP?F0`cdA8D]_%;=ApCL;4I.79<d&-oUBJ<0UIXq0tP.Ega_+^kVcj
(E1'Me?^Q`Dh?']D7c&Ij[bZDYoc,&mdQ+51ig84YZ::nQ#B>Y*[bVHOEI`f&\$8UWaIa+a65IIl__
S\^^&C9:?3U.Ki413mB%>.ip<i`QNR7/2rUEhB`@N0,C8oR?9YW/-fS>G!,TV0Y&2kMannXbq^5"N_
>i34@dGWf<lIM+K<:.ARR;Rn&k?ap!6H8bT^*4N7'N_>1oG#g>UXeo&Gc(b#HHXL:*95BlbSV&dqIQ
>F<gTr4^-Z.bPdffT^9@2PK+KL`;WGG<=PpocE3l(_G_,[V0G`7cH]l#JF\/o#`FjCdm#O;pBj,[l.
Limn6ZF#8!`K_qN,^ZH%^pX`-9%5*`_XKgg`\<5U"TA]l*N"kOP8EFYptg&gu^U%HdEQ0)-Z1b<n#G
3jZ&P*7G][;lj\$g9)%YS+>"3Cqd^lplW8qqYRs)n]q"rLd-=3J"9&U='Ip,j#RW6H0q4W[?e_12&T
(a>P(EmPc0o`heEDnf#)!ied2[EM=_tHgX2MS+ufXZ-g.,&PQBjL'+F(TsqCWX/c_XEpJpmj]tteR&
1Y:WZ)YF''`W5:jL]25NU@"<,12X88BY`1t0D0f?2b;^HWph4aRR+?c?M<4(Ps7@t>X^Xr^#%R*OB\
W2OLt>;JVeQ.[5*#4:Ml^%YOgi0JXug1=R?G+K%G-.#Nqkqb_39_M(h/H+_m#<+_e]!&tb-4OftBku
jMq6pC/,COj0Ju46dYdq*SB@O_,a@j.+V`1r"gT16.'W8lXD[pBI6[S?]!XRT9mEooVV3?2XBUYfi(
R@]k'*oD\S1ee4r03!]I=5=ui-8[iU%:Ae=OX[5?QFa$`a=B7^C>oP_M-TeNOb"2T2Yp'2q4D/-lB]
6VN6OFEJ;VL&2m#Y?IQ.phoS1"/$Vc@)1o;cKJe^Q2`Pt]]%_g3qIu[aE754+MRI.]V<o@]_YikLJ_
e@Y/*ns!PL;4;^^-]k3RGW18SQks_T)H\%Jcs3;gK7CLkSrI_JEDe,CUZ=6ODlO/[j9\l7NF,g,Wmo
CtOF/RD@TC%AIS,+%VEiRYQ[J7njPlJYfH/:IT6/g/%"DgGcU9Z\kIpaUEBA^9^A:S)\CD\FO-ks3p
='X8pmd4;Xus`U@V_\aOlI`f%CQ2JDV+lk!^.nX>iEBjd6>j_1ZPQ-%V>^hQD?fUlngV&tT"UgCoPG
!7Kpmc!3([d0NdY'c6$VRf5$\._e>hNCTT%<!a<8[Q]YoUh+Pm[BlS\joUd/53Ak1J%!gkEgU6iMqR
q)'1@';U5'n4ECNJD"-or8^2Yo5AGrL`sCuLr6b%<hjg0=+*"1@9DB$<Z%aSm>;U.#c&Q&*g7:lSOM
*i9g$[8*:P<0+fTZoAr*D9O0fe6CF9-Rr<;!c*lFN8"@G9X=f5>PA);X1(a>@))MRpqM1+N-4^5=J3
8)_uRhDVj)b^V";]f":ipo3?BO]LCBh**tgqO2Zd*stpTNHk:b$eY&gU;rX%8rEt2J;B!eLk(;;#`+
"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL
^8feLklD=[6NVD=85?OPcIeag7Rl3/,UZbb"t\OW:C4HeK.!jTL;0is4$nn+t5d5La1Kt6!V2OcI]O
+9,mFm_tu&)Mqn3ZG1U1??Zr_80a_?mV*r_MBC@NXi+oB9gHnnlo`e8n1:i7h-tQo+g3@LS2@f\ZU!
W3a/)spE_)k4X,d#*4F_kMW>-4TfR+%MA0@8=:TNl6GVbr,d,tk9&-C0CgqRU>NYKOT-h0,.?Bm[$f
MnYhG0tLs^_k=">"pae25+t%$FPC#aSI^KQiMNoEd:hdgPnX"R@rjVfpJ.1eL%Z<i=6pD1M0<M7Wd[
#U4Z$'X,luG0*SLP<I8S0Rc^NK9E$!8"<DA!PdCR%YGcm$s`Z*d\ImJ/3D>(Dq[\?C,7R8XQ<,)]m&
1n8#K/r@9:!0nIDq$&\hS6IZWG.7oDOg!iN.tR1#3>T<C!Q"5,Mb)RWLd:^K=nLZOl4Wn7lq)r[U/g
)W$3De+s>u/6iJU2rXIc/[DDZ"5HB"`[W[H(=%E0-^R8kmnoT@^n%!W3rrB2RO1'$JY)WB0O5?_HiU
(ijf,"KGdmX<+CetANq--`g[lr?&X-*!ed)Kq*j^XVu'0Y+)8XEUYin,i)Q#b+X@V/=)mcbO+J\'Ng
iRQHQX$hpM_SII%+."S)i:Xi]\jeFF59t%tG<sF+\)D;5G(rIHbVM#B[LO>)F.GF@<kOd%fkPmanD$
49Wu%FV^c!9(Og3!i%edBcqYBC:Y9AKGUQ6oV7OVK.l><\^aqlq:_Aa^e#"boVCo)"%N$nW*ilCLi6
mE*Xe!d9#*n]WIR0H`/Cdj0D7]TdY[B5`SCEU8#PVp`/=lAk\reao7RS5;u/<o:ZeP`nH4SeW\MZmB
dI$%IZ:&)G8&Ia"UIYi3XT,j/IQD4t^G#JUg:=.n;V0@+6fqeJZ%r07?;Ud\JKbdT_EZIk/m^nl0"4
ucJC=-*.;EC[6a=efn1.Ion>0#IFWir-O92\meJW5E@/SI0Wj*aKrFa],ARu)J44=6Y/EnSAC-VT;f
fMj'l)\j!g2GG5)=$2X?/G1oKP"8ho/hM.RZ!$'CIZ79<[aDijl^HZHk.3O_Xu!pFB?HDR_jsp)jc7
UpdEUfr^=s_RZChmEe4VZ(7Mg[7.O&S8NSo_.2UbE2a\E!0e#M:"?6Kqc1iCo'j2?1eWR$V8>J9<bl
e7f%JkB@r#/7@eNh.sfe]#Hd[JOPYMtglX/Tc5a.]"ms\Aok9(,AbQ]N>BkS;m?)WlC)#NioCrG/&_
N&:p'(pUa#LkWuVa*`cKaQIO=2`6*C6A1S4!,=W;'5(@&$cPqmJX/'2!I!!ohPgDCt\d,d$0lt!4IB
*%J["]u?Wd@!YV^OIQ1hik=+[`!$'X66%1Yh?CFgii<)2Lck%Ao\N4qiiBK_J6NeFMEp=B/57=9fSS
i%,quB+Ful];hAhemW[gP"5@I(e.)Rb9KU2&ik+#[Yj]l/e,YLohk&.9-ka=Y^mJ[eE_Spp/T9EEkB
'7[jb,,._9r(4jJIC1(tlS.r5OGh)kk*.dU3:'p['.X%ot7i[F3=XXDFnEiX1P87BI3;7ZDmQaE*d?
Iitr'JhX]\@$<r6\&qj_e+E]4c*rJ0UKA@iZ_mqNK0BWXO<RpId;=P;(?=5ja14"q;0J/PC&=@35Nr
X\pc%CZX<>8L\4c:Z\^"OYjkoZ[-qIJ<-2D?8@`Ro:Sl"c+QCJpfL+JoC"2Cr<K!DH7o]"P36VhV/<
SY;h7\k*k*"989hU;MjLOj$`j)W^4T31:7]@&$eiGS7f=A(3#iDQr(Ct^YUiUR*qWt.B?U3sAQB$g)
WiKY13\k^[(>'VFq%I1d@]O'h-W=A9+Z,>@<:h_PYDe"Q>1-^ADG,N4o<Gi/^Tt6H!;:6g<DmIq3aj
9cLh%+Q!XUr[SNIY$/Cq5BTkco/72-jE!4T,=m>"H?Z9lsuUS]0mrrDoU>lp\cVlP`*mLK6s/iA*WI
B>X<LnQ":+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2s4-ur+s8'R![8a2+p&r2+sI(
4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2WpNUW;\f9E:ZX(V<VDk?bLqhL38!E-e?T:dTTW&KYT'6u4]
18PBr%i.Xaj&=1F6_^fhSY-e.K2S#>hn/6c;AX6pq/G5X\!Dj-n'jCY0WUlN[DU?EZiW#L@@056B8T
i=0YUIqkFG@,IYkrhq9E#`+"eL^8fhPjK"VWfQp6IkoUdjQQTFhf@&M6oVM1KTH2/G,P)#W*OYI6V-
XM_:n6t?'nbS]3?@nC-ONj[J_aORqmAM3M:LD-S$1qTEe@\^%U&XY)=g1@F_RZ@..TRq/fYYiG<MY)
=bf-Er.nB/@4BLS](>=ktO*Pikse5hMCp=!XkH;MtQUDE1BJu'm-hqn=u-NnDq:!!8f\P?=d\)<0P4
*'B,!7E_PU`q\M'Ap8E4bEKB)'L.=bSQ-FRmjrR#ZViqK6h,7gf:6((?ben[U8K1ebJ.7;Qpo/6P6H
@Q:>PLmS):I9oa\bl),^!42Hq(N,5qIX:3kG%:Tfh_:Q4)ZoFUf/Igh]Nmca^_mH<t!\U^sL8NIl4K
-=GafQJ_'3_*l:WU7SjABVCR=EXU.02J?ObI_5BW'NgV>SP]i4G9Wa+it%kUkA<_o>Oa)$(Df&2;p*
:'QiMPqf^F^)7E3Yg:IE%(I+%!X[<36,MoP2ND9:Bjrr@?gF>Hcm86G(fHeM[HD;7E(p9so\X3<X9_
W-P3/5aPTZejZ/k5:53*^s&Z_WKi%Ns1\J:=n?7%9gV0PL&YhWfh>]6%T+,*TqAPENo:,fWH_O'j+F
13^+/p=q6t&CFY`W+eujo/7N'<*#uf=pP6_0'b.&TnA/NNHtGBK,@(MBDgs()>F0;+&X97OO*dG]Xd
=dqhU.kl&f*>=ZG:<&7@`^KbE;f)AYH^,YoLXFT<Aq]BVLY=0uhBM,CW+O1Y$]o]2@#A/2Ki`3gm89
"N%so[!/*^NOjD7(j0'J=cCTRmg,<0DK_#nWVBd4l?jX5WLb,4qIUT$m2FH<Is5.`C?]7GRb6L3N!6
k+(-SJ[iOS`_ZkO)%6Vmlp;i->aB\fHl?`;>OkIOhP+K:5f4d+u:ord2KD9lR8eJ,ESio3Wn3H^'g"
(LDNqSR)olemrZkYIT*=>Pd8,>R:2>"_ABjuqu435[#'R]$Zgp#8UdWa"T30#B4g$+t)/96[ZOmJHu
aDh]*U76GQZ`\>lGjT@hfW`hBp>D)]aDu^@>VcX%om^HaBeEqZ9.;lFN\6dnjFZ1.I>E&hEJ.GA!YT
%9+TsbP30]1H2Fh=4@/3,;RSQn'g[9Z3G_oW!?3YuZ7o2rsWNX^e6k7[-SJ4kqg#/ed+FOAN.0H=_E
j8T,&"&_6\BIVo$'kr[d['mAnTQ8duSilsSY2_];O-f+7s443G_5;)jME5Br3//cl,=!k(ha1')Z.m
)gNYp]VR?=j5#j(0Od'``A;sHS'a8Z-oO8VZi^I_5uP5bNUA]'k,*6P.iHGAr(rW/Y6(7\lPd/O(L&
,OlB^[O%oJ7nG,V\n0q5J]_d[FH-U^<1c3\,P=So&Eg:K<h)O/cPg\48cV=qTetEH4^`U6ps:.6j,n
C6pq/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6j,nC6p
q/G5X\!C6pO..("KfVFYe><2"K$nrrD3!CHGn!e(o30f,@p_3/%'JRhdXm6%(6A@Gi*te<V1>1qgoO
nT`t3danIb(*MsCLt;'!ffV#a,VdO_jbhh_28Hbhg>eIJ?i)o!-RAq-9as1Fc;VU=OH,=13B?BZDRR
[?gaUT='QgITi8956"NL6*]ppqr7!=ZL\^Fr3D8g$LRnP`=Ver5CrO-do&kc"^#-"h+5uRktVOBN>F
n37*#;k1^&=PN0Lkn:qfD<o>.6tQcL#V`B&:F3Vr<l-g5tt1[DpYk@<#!gb6pO.."C<`XE4rcLo_A(
nZ&fsX$*b9O]Mo5c:7e\tPp:o?d?=?5c]XXLk6GL=XTTFuT=b3S?,Z$=ITlV8oR@sCA]N]9D=,^#<n
C:#^t9b>EsEA7dA[3E*_P`)m5/rn[T;`VdP\U]g=l@\GqN;2N7:"Q[V7K4Si_!u*HW(s!32YY/3ef&
(gPWPUp7$+`9Vgf/j,Hkg_sE^8!:>#PQ!FB1f(O@G#Hf!4t9SD0n),Q;V)3pa`EbT/o0]hQh[UBS3!
7A7_V=s3#gajNebGEoVc9&D,[*</ppnQ9MpFX+';m8[+B1s>A#nNMFJ;FEAJ0CRP*hD9.X[*GI&*!/
cC_FAGT,2P+Jj70mr+ca`h^8pC4lD6tq,cKN(p3D\A2,Z61pa"?#^V>6'!@#/tM88Jr2O6.Ko`*?:Z
WIH(8,ETLb'3n6'F4X<^J@]>3kYA!>s*J6khqP1k'f![cW$$LJ`gi0u>N6OP'qpbCM%r;+HYdW/+,i
n\).rUZ#M\a-pnP^J:pGB2aB'S>bIrVqoWHeDOq!qS>\CXZ?;MaA)0Ic</nA[S7S$,Srk^%q=%Z79D
MHW,CZD>T=idE%"]KlE7NGnN9/n_O"V2au4=t-=gFkZ!5#AI[p=S_BdE;X_*Y;$j64=t_S1YnhBY2s
etn&j@PpCZCAX_%dX^!;Kaad\'03O/=jeo%oZ=&\lDWQqE.%^(c>fX[&i6]2k,!-@nu\?%5nV-jdXA
PGS08Fr<Q)hDqqlaQ5_>ReKIBl*"i(di@'7sC!6Dgn`O0.`<R+,lI4n/MLqG.GImVIc;DUuf>f%CP?
.[l5o9f.Am+)rAd%<HR6'NbW%__'<ue%SMi$E7lqu(ti76CW9E9!MJ([Cc;:c>oX_l1=]r<@&N.,PA
?0lJ'2lANuP!o_^M45eMEY=_cYB-Rjc_]li$%GE9Wo%(q#*,Of)'\aPaXW%hGS5_eG_^"/UArF6%;N
4j[57P0CO1.r`)d;HD&#3O-R]&2R8RqEE0S`B?$lYmB9EXD\!a\a+[p_6W`1G]a-qf+u+ibf_k]'j3
BGO>BBYXYU.JD2-U`m^bt9N[>Rbp9CB59pJ^Z.f!3/6GX@H)p'_1`k^e#apobm=DKuc".I]$e\p.c[
Y-M/JdCB.6H3RiQ<U!\>'VNh5gI_T1'-u`Xu>07@F\+cX$u]errB$>F'blo-!&"]:]CF\RJ/3:aN3&
*mgX25D08DGQPubbVhWZ$dN<87D6UMB>^SNd[hc-8TRJ2JTDk94odF_V,uNUBDuTh4.[cZ.;-,AA$_
IE78W`I6-e:Hs(,tRG;_p;]O-Zg./%qT5ecS3bJ-EsH011L:*$eFo)Sbbt^OTtfKr5dBZp$<CrrB0$
iY<#$G$'&RCgoGm6p_]Qp6XDN1<6nRc#j@nI<-_Po-J+KSb-p/6R/(gq*XRSD;4']G0`q8Z@8r.rrB
R@r4(;RT^8<3nR)72hrVk]eM">.Tb.ta6pq/G5X\!C6pO.."@PLC6j,nC6pq/G5X\!C6pO.."@PLC6
j,nC6pr-sd/,::+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+=bO(%L5\m\ec8
GZ`/=u2F9;4B[O_a;10uqRNS@bPk6>YN'PO/Cb"09_![O:<YMWjj)%@;a-YYZ3N[X$?I7i*_&!8R]*
=l<3NuX2MBSsnQ+o/%jWde>m2D0t<1uC=d6aYI)a*8OBUqq&_0<cnO@N?_ep,qHe6E/7!I?[4`TZ)"
q<e^g(6@a4R\=-HTkOG(.B!N.J^2?LEGHCrpBJ!>8^ILfXgBo%L+MK`/N_mg-bWG?9.W-3LK>KVfPG
[9QAK3a%*]r<M6Lc!>Y4Eue=Q^UKa27knKs)BSGYR@l,0_]3-2X[1`^se2[]9dm-OuknN0q=lE+Pp1
!KT?[jHa@Kn?^,O,eUgi/qGj(eh<<%AtpE/R2QT4<2;LSOqFR=3jX;YH.T/IV4<3Cqn+/aqq,RTBg-
V[C-4sa*UBk+drG*2a;69UfKt<kR<E(Ou8bRR2Yr6nDF=*guTcXlAMA105`APo%A*Gpc&-&Q='E$Gr
LDmAOha+:=1'=4MeMm"aNmB"]I&_NH"#?O(..plR8TO:D-.Vf=+RH-/"V!ph.'Hdkjr\81GVn^s^6\
NtK[mJ[eXR`1a2mH=Tg/Ad^Mk45SgPe.3!Y;AV,XNrh(;BR)]L&"i_LG0(`/kA.u)aL(fXjj052:=d
l^=@9!F^>7r$`&/HN=uk>1[:X#jNK'uiPqX<%b/<**p5]`(<=mD4%EoHt[sfB9kr[V>RHc?#dac64-
/o,lU.8=nbpFk[DLHuOVM^i;96?CBV?._^XeRN"9AX:RZ0"Qh/Tc(H;b$K>dD[pFh=95NNUSuEVsA)
F(<jE/KC\jYg&UXAj2fk[mQYI@`bX]XRaFc+4\CHMpZt$@lB_gNbJqZgC%1^*%#/Jl%52XFY''2MFr
&NlW1^8Q$:sBVLcu"N#7jpX2s[ZT:rP("\27@@i>kM7.o#DYg,j7<]bT>p9c`OX-ZpK(oDM\4QQ<d!
eoOFZF.FrJWh0q,l/qW*8,_27X*d2oO!:liLCV6P.OLNS/<YMlF(f#')r]oI>h^>t8MG,g2uOO%6,2
&PN#8(+(5eS8ZlHDAi]YlBHkpcT?fc(B/Fp[G1d;4^4`3%hA0rY?a'>0*EQ6icTYnN5dGKFDO82,?N
^l-HBY$Pj0J^rigP5-RAL8d!%M_Ia]8n>7a4uK'oLA"PmFTThgO$#fRk!]n=b?":%%Y:&pNhhu^<_,
,YJ_FCK39]l2f(#ce)TG8oMB(iU8/3cWT$(f5*M%X*0a4s(<JX/XMc%t`RRa?9\l1V=2U^&h,76^ZV
9=i^!uIp!!AqHh=&lcWPdhX1FlrfBk[]4gl(d.$G$78;+SiCoOAB,%1@a$^[9QIL2tD4Z+0)m4t[Xb
WL7-G>XaCb7]bEHd)pUn/^GE"gplQ2D>sUNC==HKnGPJU4cKNMQP#uXZ[21G>T5,)$,Psa8THb*NV:
kBkOD\qj#l\.`.u(pi]5\K2A/4NoOq*)';&*+o(J8Hd-ZLADOLa@dI/UsA&Et@1^P.NEqZ^?Er-V)a
ss"Gg%MLb@S_375(DG3\76mX=lb.YSf$_0)^'"TQMkqR9E,!=XDo"P9.Mc;U+MF-2b.e*"*X##eS;+
QHAN#_V3/7f>Qq<KK5p@kcsdR&+cX$S,e;X>a-tnH$`/$7?U9N;7gt?NFH2e/k(TYm[b@'%D<J*i<`
KesZO=`el_st2St1J%@bWe-gt"'kXkueDnm=oRjTRL_%nS#XL<2;8DO*YjSoTI_;/r2L;W:Yu&CS_d
(Xt9sR(t7qod$p/HeVD-U7EOO5QB-tHS$Qj5o(YPKN;!Z\\[WSLQ2j6'&_b?I[`8l2:YO_<-XTHl:K
_W94qZ:Y@[FOdph3J;(tZZT*(cD[-i!fj>&md!#IWL>6"ZM!MZIYF]57(C#u4e-Dcj=@oXI<&gi4WF
X-qr`qbB6d]K?WFi^QdI<HHJif%_C0[NhKZ,OVXGecMp2bT]leQK^c"]Pr&RV:i?riD6l3Nhor<Gf/
g+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p
&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+G#Ht8R"t(l.d4X9dl;D*Nh4Aq6[YQ[I7rJ'K)$)dD]*!
>gX\)A$g:e`M@MskX)RT2&KUu'$3<R3uB$uq'fllj*Qfh+H9Q#;/pVJ"JQO\UN!9unQ;D]g.J7=-$A
Q_OQc<5%Nl":H@%nX"%09GUjrEm\\Z$IdJZm?<%K!\/K`LH-.;_gC#Y!"'e]]uSgtVeF#oB_nL@A[@
fpI]VL05'5G^ogQ9lW2aNm@<>9=t`:_gqSAS7u]QPsoI#,7Cg]%?niBp`+iJCNHAV5L2BOp43H$R(@
W#-j/l!BgcP5I,CtF(`Hb.r#u?epp.^Z-\4<DKO\"j>:-L,(tc.KB>BMJ!o6p!*_,IL%:6slMgi9J!
o6p!*_,IL%:6sf)/>:1X"Ok6sXP`LkF5%R]^C&o.lVa]2#Il`>O!&AA6L(VT-f\feTr%@QUSoW`puE
Q6qp.[a=L%m9Ier:K]4e#8]=d5Lj>3)KtF\E=(mg%"5-aG57-=p[T=g$Heda<&2sk#St`Z.DA[%a'>
;1(EF;<9jZLGE]gbsfH+,XV6Zb+%WcI[Rtih^60kDggp"s4Uro)tkZLJEQtIV>\Y:<S*:9qG_0%J.'
gkWhO?=!?2'-9(Y'15=Q9:+QhWM*YYfcjM"3J/WptG^^e^64`9,id14]r['F&,"X(u_/8>#r21XUP_
$Z/Y/c?Su1B)jqi]*05=BgYKF04$2Gu7p>+uWGRD>=OWVj2uC7Rl0;uN9>lq"nN1Mhft<VUS9X-S9Q
uKQ2m`uFcYINTOB?aE"C%K-arLprdSR3Q`#&kdRR\@uap.ja/rj#V2ClTeX>$opS!!tGBG<)F^*/(s
;c)pZfG>4Wg=@&7/kdse?#=tl=8PXgUG$SM1Rq8>j,_n!5AH;S_*gYN@jAA0=$*=Aq\4=VAXg:F>ml
-ff$*S+Xh=YK['h[.\l*YH:N=mV&m&[)9RS_KhmV2bQ@E'"2B>2*RicF\VMdj+[>nc_Z%S)ih-_:=/
GPGpAVn;(!3Sc+?=EG^.iqFA9Qn%Yl8^A+0"/)@KhgE$3B1KAO"P\edEQWJm2jLd2FWmcE:6>T1?.I
NAWdKtmIAd("5m4&omA`(g-_F5"DR/-W5%,__'<^SM6b?Mn_>t_b!=1!:j;Wj`Gk"\DLF+GZ;eje)=
krE)[_l='5g76H[+f5Ta=;ia9u>7;VO@4]:^(sU6R8QZ3SV&EU(dfDEm8(HrcW1cR00p4IVAud>mV$
<lYN+dPeFJ?lP86HBmSfk0e_C=mi]IIVgJ#Q.74X6gZilkWD*)=T8Ac.>f/Uq@=,9(-gmgF]DBTE1-
!gNYmN>Ohmeu[4@A8QL8OYm8Y,`'2pm@9Z`gV6m7.En!Z0IQiXGD%*n:!os0l2`,QrdSiJLi;m2uZ2
iRb:h-gFC*iE;_J^m>e_^T7TRX"`#>DXlc?R20u39kpjT1JsB?])TUA<P<ghSP]f47=1rnZ-qZ>'et
nYBqK.E-?CQ@?%P4*;'bN)Cud0c`dbu]X4tqfmh@cr[+Q@pSb(3g>*>U<tQ#F&J,Nd!>,kT&HNIT&J
5$U&.oKT&J,Nd!>,kT&HNIT&J5$U&.oKT&J0Hle,(U=+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R
![8a2+p&r2+sI(4+<i!=2,n\JcoMND,G$9#aVkF7WRSG<'Q_(c0cF*W^id0R*4!)9*!bkHWUFk/BSN
#fB=g*\<adheW'>oC&HHl/3bNBPkh]P$6a0j^*JI@!:mgJ)CjEF8pN+Y^*Qc]&74?N=M@q*W![8c_O
3:nmGX'd&r1SM5P5;r:=6=`lf$!ubI%ukt^D$Q>o(MSiX2WYgM.Q(9G_h.]LkF*PTTS4Jb'ZMFfs9G
lF2">879b_M?:QLlDIu*"k&4]CME]G07eXlfd_fqg8$F%LJsJ,C<)C)dfaXH;[YjoO;nA!gNbe2F1e
5G)[>-!QfY"E1r/A/WnA[EHiprE&dF)+F<jAf^6(!X7Z!PaGah\#'BYEu!G(\B$]p;o8(.b21#/iXh
%a1Q@`aleUN3WKV[VuVP*G'uk.FhO/n4Xp^M&kGh/T4Koa)0b-@FVE>P+8a:cf'MDS(Nfcb0GU5.9h
_DN\1g$J66[[DVq2NIgOV!8ITTddf`AJ2!T2JYi<Rnfco"LW[m=JH_Bn>jMm`Di`/EAD,"NB,KXm'>
;Q[;h],A'LFZ05W,lEDFk[2ChRqH6`_V$5;Pp$HIpKqk!3.n_iKK_AM-03312=i-+b"!$PBR[eq5ZU
[o=;T=mnq3=O(;Q47Un0=!lL^MLII,pNU4a]g0;X&m9:04W0W"TL?'C3H/D*mkKj%UGUB8HP"lB%2i
ub6gWo(NO&X^5*:ZL*/5e@@1kBTVNh5n[f#Hi8P"++Ai8tWHL<I_jpq27Q8rX7c;_aEX%Gp[8bbSrn
9oi(_\RSJUjJS*h&4gLYNR=N!RYaPdE6M(SWsGGT$DqX5[*c;3F#q[TjT*pB?:R:iqc=P3WUP^J330
*"X/sh@ACNC3L,A,1i&YXoZb\nE"c%YIc"#C1k_1m8kt>=n"mR:r4WBG>?eKqUD>kl[r:d5m\FW`!Q
i.-GibEthHEKp#s4$oq+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a
2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!?s4-ur+s8'R%N
"5"Ze1j2LJZ*I_8eBnH_cT>3._@PT$--aa"0![.AM!*0\OZs93frmK<kGDW&m;tX:M[hc`Eu%e<+0<
%sC`_kO#kGi;AMRf>=t5q;lj&<SEJLir,<^[4dNI1^lEE7J'%@bhbkVnP]6=nnF!Am;5j?nEN*hnhB
T@qlMp^Y,C&VDI8N]Noa>Ba$C-A'/CCKI'UE<Z,Y5T43.l\lr+&+0Nf7:8r?e]nTL8.]'V0:%12;[0
>;UZZM7L5l!"T#4*['tkBI2&4O:KRQ&TVq2Btd>-"JQq$!LO+4BrH.-fnnmn@+>I%COS7^8'D#P#E&
jWpK)TOH"Yu<stYVH2IR+k*:%2<#%$_X/D*eRCa_QBc]/pQZj6(*0[3Mdm>@CDLiB2D5RsaR"XVLB(
$dl=\hbH)!>;+CeeSD7WTA`2$2VaV$I2V%Y)Cr!%r_A/N:S2`uSkFjJ$32Pg_Y<ROn$Lk)kq\[Cer=
Kef7.)-rOq_BA'CAY*%uJghrtC^htT+/0(TQETaWV[!u^@B>l6e^<@ge!fDW8$p@Wg..^GUg'[\$aB
]Q(s'*.TPM!Y)0)o!NOH7G*7]#Fj)%QE8L*;9F51#EeRQi9CF5,n9EXmc^8u]^>-u(03h,ET`D_uoM
r[92lNi;u4\t2(^Nn_Z=-Z"3QhO,GVt0K;]^Or4fpeEZ#?I*3A*itLkW075@fAWiW)u"B4?rUC^Q9n
FSXg?)#GZ;$X8=RH%DTj2rrAY`@,8klYO'$f2ZEaj;uV-oEaKQm+t>2h+p&r2+sI(4+<i!2+s8'R![
8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+TL$i.O#uZ+p&r2+sI(4+<i!2+s8'R![8a2+p&r2
+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!?#S%Um&:##U+p&r2._Ku3\6iq6"Z@Z#,Rlc$n8c'pW$,
=gR<@_@9=2G\35,tUPMrTd,=FD&DR-KNRn!DXo)"$u*"-"Ti'WrL5o(THe;K^](WlX]g(O5=#GP51?
V#da\Gjk.hVEQ\B,B[bHHBBPe)3,W/rq+@:-7.Gkpkr-e>$ABK'm3_H+2Ps>iF2gH8oqTSD7!$05S:
&5_t4$F6m3d:?U9B>k?cR6q&6#0FuI+qQ]QjC=<1\l>N^F'qZl@(W_ECee&JsC9Ph0rq!mhXQ7ch^7
#eJ.LNg]&>b,9#>HXoRKI@0ne5J-RqfO'9FD0D^lk^2nN*&m0&6@cB\d[%G.F/l/^I,mV9Veqf*[g'
4$>q^YA4ut8B[O_!!=A!SV#N\M:#dP\b&h/<eFjH[DofD\2HC-1gJ!YB5;KjelBsn,]m9bjqf_ZNpF
TApS5I9le^^eWp-O&\iPSadg$/qgp'$U@shd]8D&0'=$G0_>4kpbMY[k/iY>9KHAD`rdFHJ1[E3@e!
"c%o1c6tqC3`r5DV=AqE'DXMX)!,kX8=RH%DTj2rrAY`@,8klYO'$f2ZEaj;uV-oEaKQm+t>2h+qO_
*q^Nd4+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p
&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+qO_#q^Nd4+sI(4+<i!2+s=kkA?i^+
)BQp,3Na/$FBf&br^s,/$e4*H3XPI3KS..'o%V[f$[==tU:*);DW.MUb\%'sE#R\,M,QGA#eMuHGj5
Rj<h7k+^=QbTj8GIJU3J]hB8OE/LUU-Y5:--TLBeCQQFLVjO^\hT]jJhB]Y=?NZV45B=,X%SmX:#4l
.l.PMk59r#`,8kV?-MBhc;ojX]f*7nYs7+mof41dP$J2%\!1G?X`ntXI:kFM<:J*^89i[^S#'fFhX<
&p_D%oPM4/MTpDEb`<8u&7s_7rV8W697FBKU<[qb>*.,2]%V5eoK;EP=f-<`o2n8H[oPd;grr>O)W+
MribjRM\f@7kOTU31M@njBmmpHE&1gQYf5]q1oQKKuVUu`utgj@Hj?/oe/$OjANdPg89CtP:j%nT'M
$;i(.KLM<6Y]-/F_$39?nrP^OSnk@!_',R)Q:W/\c#&nT@)`\9@*j#0p<r&4M@3p=&-C`P2P:!L-0i
sBUd_/npI%jCnJH!%i%_++W/STb+q*efgt3,NnPZB"pUugq;ae#k567X$X_I5t$'(O<V54'<!?)#.X
`1-G5'lgi'Te(L!9kYVc&Pts!rM;&FR\Fg<)h:S['>Hma<C^3C]dUElF!A\4p'g]0Y4_ocp^%3&e\=
iBX#e1>3gE<)gEr?Qi.-GibEthHAP?n;bL=n=m-O-L8E.C[,NsY=jJ\W.;3Ugl0@P5T#n[/p3o"HG^
CMq6^m/,LBB@!6EO!Hf-lHT\;5qHLk(;;#`+"eL^8feLkl=mJ;B!eLk(;;#`+"eL^8feLkl=mJ;B!e
Lk(;;#`+"eL^8fhs3^]n+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8
a2+p&r2+sI(4+<i!2+s8OhG5DDS"kq+T@;CN2+$UVcJ_p'M-[Qqmqtf7M<\Q=cG()PG-F\gsm*Zhf@
lbWV%IL1QnbG:'LpO"uM7HqG:!)(5]r"*Nq\P1>^UYo+kK;*`a^mO?_JA\1`_tdfYGdPFI'(eHo5WC
n&u."RmYEul8(h\s]!.Ws&W2S9i;-E44>sg"8-ZuMl$WjGkZsPN.AF_9WQ-##+[1UaJ9XaPlh66]0)
`#mfL-1*JfrjBJYOg.=`O$37f&$6i2"8hHS"AjVPY35.fEX";WgG3M.C*ho[Fo'2@@J5Tbu#BSu/Mg
b6s4RCZPbr?V<H67;t.sqAZSlLBbY8fc;@Z*)O>nbF,K^2t][1p^K)2g?^/I&9DBN1>1;2al7;NN:L
r=g1iN.f.W;/p6(H-MA$^]%#L<'+f!UNam)Z%,Ef#`3//2ui[km%gBss*gg3$SN*k<$l#X'9F"?Js8
*Pu4L"+dsEJ/rf*6n2_.:Nc=qKE&<q7k$lQWIBc7)8WZ%5'YNDXMk_1i?*><-XsEp%Zf@E;N&>4Lo2
RN7l7)lfE#N(A_6P]""QRU8;k#`RE>H=nNE[]u-\^!!1FH4mGF_R"cc(,CKW]hQm<f43-eHfpd"-f^
9HbH:hp#9-B(r1`XdcRHdR'HE@o!O3bD+NX+*0hcdoKCqo:#DOLs(De0]e$<W\LN-_9l?L(*TFcSHV
>/@;#dn>:11q(OrnQSkHG;.[m@jbHZj8$<.b1hO-FKtLah!DEbd,C6mA<qU1&pm':q+4-=h%jgD,Ro
+&\/-Z2>DZh+lnW"6])q+OcQMKWTn@3u3h74$@mr[XLVq!,@/ue-cZ+<eHF_&VS[[g`C1LDT%BRL.H
r<6N1\LAW^pAef?1bd`L>_2$g*i_J-:8.[*,K;(=OCO'2?5;U<IG./J;B!eLk(;;5QB1/.O#uZ+p&r
2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R![8a2+p&r2+s
I(4+<i!2+s8'R![8a2+p&r2+sI(4+<i!2+s8'R&-(,U.O#uZ+p&r2+sI*9=\0'N'\&BV%uOs74er1!
I+IpUnNPG"Qst:rUoD6b?U2GS?ftNCY$pt9T&mk-^J_4A[/GTmqaD3^n=)pQFVRb4>Q3)n%bmSh/%:
<)Y!$@\>DqDeFg;9aWL8i6'BPMAc"(ZDF,thjX.IW1Fh$mTSUrnu^t(\7AIQdX6Z'$'rm)>R*maOa$
LH:kL4Yq8/SEBP#"S!-?#@54=3pF_oSFYPm,,o279"9WA(:dP2ZVf2&*5pDG&NJWQsWaa_l0fN<msl
C`D$_`A8M<lpn&9I(D_;XSaC+o6rZ^5L^TioBIN(aC-50g7@%*2'[=]VH`YdiqnUikogrEjd9T6P+[
n7/5UIqI=PsXJO$h"m*]mFD/iA62f?5f_Cp:rhpO(GEK;Q8M!RrPNVl[!<Ym7_#PRHt)OG=mFj;ST%
EuU4NlphgSSF%;</uE2ZPSE^j3i=]Bl3@XR2<<PVVlbFk(L9=]7uU>Ei]*Fb<$u0eAM`t5.tBn.oW>
!n\[]/Xb0"J3Vl>tq>>9Xp2B$2_$AfY<M4jHMD0POqAtRXQk\uo&Ubf_fC8tMil0!3FDL`*!NO3@8Z
CZq3["9JM8;N'-Lk(;;#`+"eLd1pm
ASCII85End
End

Function Instrumentlayout_panel()
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
	
	if(itemsinlist(winlist("instrumentlayout",";","")))
		dowindow/k instrumentlayout
	endif
	NewPanel /K=1 /W=(317,56,1040,545) as "Platypus layout"
	dowindow/c instrumentlayout
	SetDrawLayer/w=instrumentlayout UserBack
	drawpict 0,0,0.6,0.6,Procglobal#platypuspicture
	
	TitleBox dz,pos={3,112},size={25,21},title="dz=",labelBack=(65535,65535,65535)
	TitleBox dz,fSize=10
	TitleBox sth,pos={127,177},size={28,21},title="sth="
	TitleBox sth,labelBack=(65535,65535,65535),fSize=10
	TitleBox sz,pos={127,203},size={28,21},title="sz="
	TitleBox sz,labelBack=(65535,65535,65535),fSize=10
	TitleBox sx,pos={127,229},size={28,21},title="sz="
	TitleBox sx,labelBack=(65535,65535,65535),fSize=10
	TitleBox dy,pos={3,139},size={25,21},title="dy=",labelBack=(65535,65535,65535)
	TitleBox dy,fSize=10

	SetVariable CNStemp,pos={552,35},size={130,16},title="CNS temp"
	SetVariable CNStemp,labelBack=(65535,65535,65535),fSize=10
	SetVariable CNStemp,limits={-inf,inf,0},value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/source/cns_inlet_temp")][1],noedit= 1
	
	SetVariable ReactorPower,pos={552,13},size={130,16},title="Reactor power"
	SetVariable ReactorPower,labelBack=(65535,65535,65535),fSize=10
	SetVariable ReactorPower,limits={-inf,inf,0},value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/source/power")][1],noedit= 1
	
	SetVariable secondaryshutter,pos={552,57},size={130,16},title="secondary shutter"
	SetVariable secondaryshutter,labelBack=(65535,65535,65535),fSize=10
	SetVariable secondaryshutter,value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/status/secondary")][1],noedit= 1
	
	SetVariable tertiaryshutter,pos={552,79},size={130,16},title="tertiary shutter"
	SetVariable tertiaryshutter,labelBack=(65535,65535,65535),fSize=10
	SetVariable tertiaryshutter,value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/status/tertiary")][1],noedit= 1
	
	SetVariable mode,pos={552,155},size={130,16},title="mode"
	SetVariable mode,labelBack=(65535,65535,65535),fSize=10
	SetVariable mode,value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/parameters/mode")][1],noedit= 1

	SetVariable omega,pos={552,175},size={130,16},title="omega"
	SetVariable omega,labelBack=(65535,65535,65535),fSize=10
	SetVariable omega,limits={-inf,inf,0},value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/parameters/omega")][1],noedit= 1
	
	SetVariable twotheta,pos={552,195},size={130,16},title="two theta"
	SetVariable twotheta,labelBack=(65535,65535,65535),fSize=10
	SetVariable twotheta,limits={-inf,inf,0},value= root:packages:platypus:SICS:hipadaba_paths[gethipapos("/instrument/parameters/twotheta")][1],noedit= 1
	
	SetVariable sicsstatus,pos={498,216},size={200,16},title="SICS status"
	SetVariable sicsstatus,labelBack=(65535,65535,65535),fSize=8
	SetVariable sicsstatus,limits={-inf,inf,0},value= root:packages:platypus:SICS:sicsstatus,noedit= 1

	DrawRect 219,322,311,357
	DrawRect 180,364,213,439
	DrawRect 316,364,349,439
	DrawRect 219,448,311,483
	SetDrawEnv arrow= 3
	DrawLine 248,359,248,447
	SetDrawEnv arrow= 3
	DrawLine 217,424,313,424
	DrawRect 43,322,135,357
	DrawRect 3,364,36,439
	DrawRect 139,364,172,439
	DrawRect 42,448,134,483
	SetDrawEnv arrow= 3
	DrawLine 61,359,61,447
	SetDrawEnv arrow= 3
	DrawLine 39,424,135,424
	DrawRect 401,322,493,357
	DrawRect 361,364,394,439
	DrawRect 499,364,532,439
	DrawRect 400,448,492,483
	SetDrawEnv arrow= 3
	DrawLine 420,359,420,447
	SetDrawEnv arrow= 3
	DrawLine 398,424,494,424
	DrawRect 587,322,679,357
	DrawRect 547,364,580,439
	DrawRect 683,364,716,439
	DrawRect 586,448,678,483
	SetDrawEnv arrow= 3
	DrawLine 605,359,605,447
	SetDrawEnv arrow= 3
	DrawLine 583,424,679,424
	
	TitleBox ss2vg,pos={252,376},size={34,13},title="ss2vg="
	TitleBox ss2vg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss2hg,pos={261,408},size={34,13},title="ss2hg="
	TitleBox ss2hg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss1vg,pos={63,376},size={34,13},title="ss1vg="
	TitleBox ss1vg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss1hg,pos={72,408},size={34,13},title="ss1hg="
	TitleBox ss1hg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss3vg,pos={422,376},size={34,13},title="ss3vg="
	TitleBox ss3vg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss3hg,pos={431,408},size={34,13},title="ss3hg="
	TitleBox ss3hg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox st3vt,pos={402,303},size={29,13},title="st3vt="
	TitleBox st3vt,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss4vg,pos={607,376},size={34,13},title="ss4vg="
	TitleBox ss4vg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox ss4hg,pos={616,408},size={34,13},title="ss4hg="
	TitleBox ss4hg,labelBack=(65535,65535,65535),fSize=10,frame=0
	TitleBox st4vt,pos={586,303},size={29,13},title="st4vt="
	TitleBox st4vt,labelBack=(65535,65535,65535),fSize=10,frame=0
	
	//a needle meter showing the count rate
	SetDrawLayer UserBack
	
	CustomControl cc3,pos={300,5},size={200,100},proc=MyCC_MeterFunc,value=root:packages:platypus:SICS:bmon3_rate
	CustomControl cc3,userdata= A"5VRScnm%q6!94'K"
	CustomControl cc3,picture= {ProcGlobal#PanelMeterNoScale,1}
	
	//print the chopper status
	Button printchopspeed,pos={569,105},size={100,40},proc=printCHopSpeedBTN,title="Print Chopper\rStatus"
	Button printchopspeed,fSize=10
	doupdate
End

Function printCHopSpeedBTN(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			print ChopperStatus()
			break
	endswitch

	return 0
End

Function drawneedle(v)
	Variable v
	
	if( v<0 )
		v= 0
	elseif( v>FSD )
		v= FSD
	endif
	
	Variable theta= Pi - Pi*v/FSD		// Note: constants are specific to panel meter image
	Variable x0= 127, y0= 121,len= 80
	Variable x= x0 + len*cos(theta)
	Variable y= y0 - len*sin(theta)
	
	SetDrawEnv linefgc= (50000,1000,1000),linethick=3,arrow=1,arrowfat=1
	DrawLine x0,y0,x,y
end


Function drawscale(vmin,vmax,n)
	Variable vmin,vmax,n
	
	variable i
	Variable theta0= Pi			// Note: constants are specific to panel meter image
	Variable dtheta= -Pi/n
	Variable x00= 127, y00= 121,len= 86,ticklen=15,labellen=20
	String s
	
	SetDrawEnv textxjust= 1,textyjust= 1,fsize=9,linethick=2,save
	for(i=0;i<=n;i+=1)
		Variable theta= theta0 + i*dtheta
		Variable x0= x00 + len*cos(theta)
		Variable y0= y00 - len*sin(theta)
		sprintf s,"%.2g",vmin+i*(vmax-vmin)/n
		DrawLine x0,y0,x00 + (len+ticklen)*cos(theta),y00 - (len+ticklen)*sin(theta)
		DrawText x00 + (len+labellen)*cos(theta),y00 - (len+labellen)*sin(theta),s
		if( i!=n )
			DrawLine x0,y0,x00 + len*cos(theta+dtheta),y00 - len*sin(theta+dtheta)
		endif
	endfor
end

Function MyCC_MeterFunc(s)
	STRUCT WMCustomControlAction &s

	NVAR bmon3_rate = root:packages:platypus:SICS:bmon3_rate
	if( s.eventCode==17 )
		drawscale(0,FSD,10)
	elseif( s.eventCode==10 )
		drawneedle(bmon3_rate)
	endif
	
	return 0
End

Picture PanelMeterNoScale
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!#q!!!"Y#R18/!1qAH6i[2e!HV./63+16*9dG'!!Zn*7mm@W!<3'!TY7
7e!!!!*E(F,Q!!!J[!!!J[!CA3(GQ7^D#BWO370hHL#R1kQ7B)UO!!!c38OPjDGhVPUq/]NeQ,c,&8
1ggkBLQSN66Os_#)$.(!!Wj_(h4[`lr;u$a,+TSPuQ"XOJGd>b)44\-b(/.#e"`CEL^RT(bf?ZKg>c
W#RQ/"2XP:(X-_Gon%JMtlkm&G,dljtI&\SCB_?.IhsW_cF7+J>)AGVc"#(r*6DW%H:_^kV=QEco6H
%;_P^=MY&Waa6k].aJ+em@1U'j:%?j$mY)[&I.]-%@k@,3-'$UPOqF?pJ4+@d76/dPqB"[N^c/dR&2
G<ld,_n$5-&-WYOEcaU/**j,/8;QJ]+GeAJ6&5Z;9@[;Z+rf2h,7%.s']T<^EcaSY7-K4FLsQ;k#U,
m7eQi_1)l^CV651PBG<lf+/dR&2G<leWa1=o3(BfTYJfmTP(Bbm4,.\m&&WTt;5nN?7#XTe=GI'^0B
`75h04oH]6&%Y#7s)(*oLRK9NhRqH]j?(M++D!)g+T(ZJ?#>Z)QKg3Bc7fsQqSjN-5.`4)3`019M>l
"Z*@C^Q7m\GR7qX2_`XY$@4Gl]cc>PE0M\O0_1;W5H[?VM*5q)`ic;SK]A;)WXsj(JMd=(MDI(_1\Q
n@0N\rO'UVVK.BZ+R>&K;C9`F9uS4s!@%*!loX9UIMbjHLA,e'gl[:*qD=$/:+>`5T]P,7''dXsf/D
YfNpPD)=u)lh07Z3k9S0.VJ)5l0.>=E*r[Xh2\@H`5KY.@l@hWM'5&+J]*3Eio9"'==dQ*(1L`_0c>
t<9I;T%k>Z"=?:A;]_M+@O-8\FA&.%4cq=&VkGW[%[*Y3.tqZ^]+lT0lZM57#F0ko&]8kM](/1`%m2
3mt3G_uEn`s&a9@3G%qF`j3:H'0t+FgSQa@?-0f2^aB>N!p%?:F84f*G]+.nSrQe=tH&E>B#eJK[F2
C?o2=H(iG/BJO"a_VC"th(Xo6U_eQU9i"e.Dqq!K$`?,BD;\Zm%K#d7j?snNQSfSdg)E@BZa#G%KZE
gd'3GTB@c(3&;`J]S2Mj#eJKWMf\Xq7ktWiG'%]BSYKV7s[8b0!=OT/q\JCo4G@O9_[ZkF7r!0u7J6
(7e/H%+d**BI8n3Cu4itrQC<`rYD.#o819OpZ$8*\TmWgN=??pn[$R:`Qs"QbZV8sGi:u$c(7X):(B
1O%C=_=<rY?CGCuV<*^HUZq^?E]_nj<M(V.oJ9Pno0QS2^cA29::QcJa_e&f_V,r%,o9J*NLWpJEF#
J8g;Q7Z<YM!1W4s*-XI\iMo5GO?HQXf]*=/gb1@0Q6AaMG$R/>ZaO#>+/RknY8[5EVBbs&>6G5NQ-\
W)B0X[m-M[Ro9#Z;cSlqqSEuacXB'+5UYf/?r)gXF6:(`PMMdd!<.ptoFE_rXg=!j[M@**Z<03E7b-
^/;B$Qi68P+b@r,G!'q`*VZ]4l/#k0mh\BP_M'?o4%7RE:U<9?><&-S[>qg`8g;YuiR<kNA&$T?lLC
9B^&-VmWptlDc>VbKD?UcY)drV9GAcMr`r0Z1UDOe"mm?:AB6$)B0Xkg\^HgFT+CJ"U-G[[Z%;h/8R
3`0ekEWAWU\r(3Hg2=nIDHVN@.:O5&cjVmi!KF`k@*@gB!4WGI%S8JWp`84#Xp%%&c@cXhARR.acbE
Of=21c2FPk>'acgKD160aeaL,WRm\^)!SF<FtXU^%D'nZYeI*EH`%&:1;p!&,#Vg*'SHMPL7I\SpH9
*bEak+.7oD@A&AI!`W[e`p@n;[?!U1XZ"(/K[PE@3I--c]P*DJ!W[dgH>4rIkr/fdl?FFb-HJaDTjj
2t1]/eKq8D17X,Zq0"?bW%c(G6sp4.DV)(`?F#Vb(q$0ui8DE4iiRo($gIH@!ZSal0khq]=GDfb0_@
PXHDu=KPWdQ^1N+FXjdV23aAkEVe06k09OEW^e-W4[!(gPiV'&(SB#D;c=A0pWn>0q9gS[$OYOj@0;
p#=d[I-]=9S%q>%^cS=IeJbEk#+k"O(Mf5p<B;6$[t=hfDKo1M`sCah',EcbGj)ZucB%M#dgcQ;e0o
F\XE\STp.Oj'mX//Cn"Is+gl6W38?UQMqUF<5_g&Z/?r:.7STYO0uYS.d:&p=*"T'GQ?j\sJL2`OM&
jom3U<X(1=^DrM`XB&gmj'MY,jCi!oi9MhjnXUG^NoAG63LAYZo"9S4;GI.=EO6Gfki9=mGiR-2V8O
uA`_1+UGN#V#SlY(3Lc^m9>3II1t%mS;/jiapckCQ_ki:m,JXf::;JHHUQPd#H)AkF+h5W7HRR3mdS
pP@SkVW-Z.p?pUda5^UYlI?Ra(5?oP*f9,ZG?5T9%j/f/\$KP_$<F?56Y^A9g`217USkT1QbU665#n
LV;`J=qM\[lg9e+!RFjdCpWhQr1QCOHbT)//iR6#Jj=S^]>F:n@Td*^7W9A?r)fA"KKeZ1,O/f)&9,
&,QW.p"]Npb5'&6i?^,5@N.0g%)q;#lWWLq0^]Bf(.6^09MitcK6LHPWd\CB]XY++%JQkKVM%tnF+[
da(+Gd&K`)Jhim-b?U&c>#7!8nIm8G_hua`G=MX40CI;Q4RrE`>C2;M7B+OT,9A-mn)gQ^Snsr@4IX
Cp;H[0i0DJEs&=hJ8OEuoWU/=+PT*E?*RCMVtW_1O!Z-1U=4I_`=)dj1ZGcu5enX,C%cH%l735$"ai
ajb%RA?U+mTkPF9SXg``EeGUJSJPX\Om+Z67'hjhTmr?NQS7sfgUH55H?jne-8IA5`VP:&lK*+I3-a
p8(Yd[=d0hV3E7(Cnr@UP&?ab?aXf]8.qqkm?)Yq\-:QoIuM.4=A^Yd@grVJTZ?dJ=.r#pt6094$d9
V,RCCJ-Ka<E8D\iucCaaPcS_S*p/`S&3eh',/:;`uZJFD!$`7ruU(E&BiY-,q_AFRVmbJ]r(*V%;4#
Xnk1X`daH">iaUoBCCinQGFW;(Za?]go=t&(T,g%MWiAp=$_i+-Am8IYs7>g)A7fG:5&hcXAS'KiV&
'i%66aCX*^>[-f.PW\]SJr,q;7hE*(rm2Mj>uTR[cO@X%Y)s/c=b_^LgqE#+N)<@Io[Y@^Fb?]mD\*
6URT0#`.Ql-Ve(E_]N".fLUas;P\#CX0:^HTDk)8AS&@;CG/#8TE3Dgod[/Znd5]nnSHpl)4Sl?8kK
HF[V`os[IWILDdp3174hr*cf_(sZd8,Yhp)n;Xe];?ZiQPgBl'rRjNoQ0am$sjW3Ge]U9#30lT-%,*
W50pf?n`39q+*!Y\-*Z3LONPI29TTcb&Y[94)%582b&kDNEE0U&N\!>VEk9e#f`Gpr`>D!9P[:.mNo
iID>_4NV2t,0)"KZ`XN@dn_RXP6;LAfCEIn^UnjfU?=U=pGikE,E4K6?gUE5pJH8VD\;8r+j\/ephD
a<LM:P^*DI^r9]$=2B@HN[sr:B$:\T6q47)ud8ZL40Yn^5(!eCN-REn)YFma/0m.k?Me)`H'ne]!Xq
7rZ"DU7s>\CT#=tE9uB%L6`Tq<V;Aq2."a6j)Qkgs*f.)qC4\$:NH)`(^-a3na>i$4LT,J78p,@Z/T
LT)C[-c@`*p0S3;4bO$EV'g6Q9dDA#2-aX7M`fYP%cRjh=e],KI=WlgXD6+$CDk:aGk8$(@&d3A.9L
'IX(qf^Pm?dJ?^1[aORA[C(6!tRN0eu`.:ET.,acCGV;Kda*t+l)P#bE&f2U#9]1q,b]-qtY5]5=](
+Kd2?_7HB+Cq8G=!VlR.fSSu/,?@G(2QS#hI[8WjJaG^umGlIO%aiMO77>9_Dp3OhBF,'_[mO%fP7K
,<2'SZRsI$k)?^.N6:9r'AQ7=Hu:iH4Y,#9TW6rB.N+h2%\2RPJF]'.6Nh<J@*e-QG?Gen_IOd*XSJ
pKHKs;HdANLO]:ZSK/`5[+Z/G`OLHUccHhJW2lt/n`%N`Unif%+t64]rRe-MaP=1]pm)[4AJC/'<Rs
.#`#Ltb_7b3cGW_.aLBAP;*W5kg%k&kU@9RZU4Dl'G=R5:pg9H9``^UAf_!!-U+B)->hq_#OY$KOV<
Jf'i5+2]X]^sE1`*+]C>dR&5_aG-+7RCT0H,'.aehIg5(P:"V*Z?)3e`G!PkuYX:m<2!Ycjc*r%Q#X
c.QCa@cFS/aYfUtJO^m!C'l-/=H,'4s$0TWqg90<?Z`:=Vi?7U5);]i./JLV[qqDmK`OO*X0(Gjk?g
!o>5>GfkQDc$+6llVA4aWL]*BUKs3>9nX-$h]OVq9,>h7G[I=W-X-prFu*H+dPXmbLN@>TBRJ(._aQ
.3dA#&t58VZu[UO<E3ODf5F1Ii#itcHJ%uD^XCrg,rp9";--i>RCYF[XB[3p,Xi:,JH7O_I[^Wk:LY
:s/$8-=mcqZ6l4h:!*=M23*`56G*#RV/IJ_+/cY%9,Tr92fd,O*U()EX*F#VrI*Y5;)?foRf+*+'S.
;[Ve,Gl:o#R!,9r&B+QIEX>r%Jd?PKmQ1p>3UCn$2QPs+u!HB\6[^^W]WC+9R:7rT,]h@-TnI!O].5
)n*fFaGr\g#9Hd%9E"Rpk/WJV(gDF,)&oAWcqUmtP<X]Gb]Pen:c->3llQW5D='8Bds1eW@B?ukF>b
kg_TO_]arS?r%/1lQq3fq1NlcaO_-u*Y^^d%fA3Vn0Ih_^>ehKt=:ZY.H9`_dk%Da=DpcTR&HRlbMS
NUusJ4ZlF*Siq1SE_j@SI3bCPf/\6B&=TUSDr*U5k0\_,LjSu?g0]4>Iqn7n%5^Zs%b;$snAadtLY[
%;@:+s4(`;2%\)6?<-_A+'LFtt(]$Z=^d3<nNo:9kOcC"_7[Q5BbI.@R[R[V+9#DI:T:=jV<:7`^B#
Z+c2/>GGPd&^7Pf<3*la<PA<j)_6Q"K.G`6UMjM^E9Z2)a<k&=@_u^IQf>6A'pGcGL\E;Lcg&f=nHR
fN2O0&`Z]1TC)SUKHFS:d'Wir=P,"'C%?6@Wh/8)3;/Y@K%mEPA`f1+=dEslijOij1?arAol-j(iFt
.<^XsaW7e^\2(RNr=gU><[j/.AUecetg'j0Ia3W2e)-n)n.k-(UTt@3bEK/&phb:@j/I[(!M#Xgjac
ES_H[KV6uXj6?F>pMl7H]/-E91L)P+F`fN!1k\4q&'n]i+:t3NYn<bI5]1K-M#4so&X]b?feP0[pb]
ILgacH>Y,M__Q;caFN#Qq$3Hsm2ff;&<,UCG:(Tte1"86<LE%G-)F:3!s"=Ws=kU8*^1CQ1gKVd$W3
]lTkl=*@_O[O9L#5i1L%'Elo0/GDoF,I+Vc0Zk?_?J5W4Y&O=0W:tR`aZ3o_^iUK*n=f<201,<V+]3
gqugNBgJ+ZA:iZ8LW'A!7IQ>!:BcK-\QoT6M87MtbeknRVKu)<?n`Jp:f>?i7o:8XZI/5;*]tKT(O!
S(;?1dg_O^Cp-,?hToY3mnk_7<qS>*-ArAh"/,/f2ROb<n=jLR$5/?)RVL:RPHiGg#--"lXOP`'ag]
XMLNp(=_ZgGeO$EVK)7l;$,e)a"AipXsaXLQBa1Crd;!<_Uh8"f)lO;4E"QQ/+>@]G.O-2(`F;"Bq^
;V0lEZ!T=20dg%$WJSHFh1V>hLl5Rm8sCpMYcrnnpl6#JtORV=FVMK(L22.U?4'0hLoKS8i,GlE)Fk
KXO>IJ<OcolrH=nmn[?p(0F,35=?He+rSL'GO)Z$/t;B\B2\IW`;@R1&%?m9Dc\d3#iFMd78i,iS\H
t3sCfqbNK]/$2=)Vf9Y-B8:"VbAqu#qSfSL?B^"^K`oD6+/n^CVpP:II"4s&'6+r$'k9I[DO%YflKr
iY=U)8+Il;cgW&gT[XmMX8aAU)K?Zlg.Gi\ZY%SfTrIgI#tK/Neo1\up,Il;\J!<]QO5(f?mmSNIcc
;,P]C@0$]LKn1aU68;7HO(+X2lXaaCLd[_,f$B$^iD37aG,/&u`fE^?89VO_F`lYb3[I9<$$Np$LYY
^?C9$o\'1PA4.1&dY@F1H6)H;tY^E:A?&G?[j3"n2:pNSeG,pg[]RP6Mc)A@b4Y`M+jEmUtOU?`YCH
5IJ9#e>BP+g2eif<O)tBUX\+C6]A]N#5oF2ZE@@TP]N[nGCVF]5]m&,4q!'I;!R2?.VZ4!ucj?jQS*
Bpp.3PK9ZASpj=?54:F:k+kK4:/;3G535AoE:6sIa;4tnKj-qkSBE^CP0[X^VhU@*1`4!O;r&VEhWj
k25b\"0qie5\ch."3eOb"RLY/)G-fkA=\h2TbL&#K;Pkc^`d!We%2LIk$-OT'49.#5D8s29a['=pK]
R:%`,kj&Va6Pr1?*Bar>i-)Y!kWqh!6G1q'f]VM`l"Imo#=-nG)N?/__tZUc[+16S]&2shG^((+eLE
m-9,jpG['[2nHEXZ[+&B_3kaI7V?pO=0EJIZ"pQ-3&)@58E]-X0V60MT[>p9)IA^JG\c%[:@5'#7"]
&rVCG.U3,p[lF<)EsdSfH<-K';?aX0q!XIE@0OQ6ML@EmRZHd?XD2<!eC=ug#F]DM8(qOodobQP6kM
p6S:k>H1e,)L8nsTN5g2o*/VoVDBI_oURj#SLWO3tf<gXo0GF"Df/*q*;5gFli'MMV?2]`4C1Y55"k
[Y"&YrRGY<n<3288Ll'LfRoo?i+S!3b"4a5b"tEnrQD`l5ncjDtL9_16b#A5#b](P:0HL4>'S97PNP
`Z&:VV>Hs9ro_U7J,ONH_En;E*?k/NHH6IW,pe7FO$609<>AT<>e-ndSsG[3;Gn,@Dps^.G2g#qBL_
hSp\Jr@r>FndlYfp/%g2s@\$tDfG]"@_\uoO$S!c3RhG"5WNo[O+jb3ANYJ7.4Mi2*/Kbn_'Hs^\4d
7pKf$/K:--L0o+p*^9G:7oPoE82l>cSob[%-T%e[J)En0Ug7r!eHI!Rp]&,`QP[Pk!Rb7X"'R8h=\Q
;(^ueVk&IZpTtV#me^_Y.nF0/%n+Z].0/"\'/*j)+fg_a!gt^\ScCH'C8SG3_CFgjZci;7-\+A0TDp
`Qk-`3?WB'.@/bF5hSaiMO/Q!nXJTI>[&LdQtJr-gj8%iuuL0998BB#tLm6gElW3q(1JgMF;p>:"$I
;RR_'!Me$Z&]]Am(C*6^L'^LjJKTcq"[N]n$fRV&AnGYtn^C?e<8F;dT?i;?BTs:dOcNJtUD\>R.(Z
LlC^Lu3#^>]FF[!AZ#U;[&@[nQ/M00U;6%girJd>Wn";/3f#U4@V&B4`,cq&sOSe)$5<*]9LVQ7M*K
?u.kz8OZBBY!QNJ
ASCII85End
End

Function wott(ref_pixel,db_pixel, dy)
	//a simple calculator to work out what the angle of incidence is.
	variable ref_pixel,db_pixel, dy
	variable wott
	wott = 0.5*180*atan(((ref_pixel-db_pixel)*Y_PIXEL_SPACING)/dy)/Pi
	print wott
	return wott

End

Function createHTML()
	//a function that creates a webpage with the instrument status
	//called from Pla_HTMLupdate
	//an empty stub function should always be present in this file, whether it's used or not.
	
	Wave/t hipadaba_paths = root:packages:platypus:SICS:hipadaba_paths
	string cDF = getdatafolder(1)
	
	VARIABLE ii, fileID = 0
	string text = ""
	
	Wave/t/z batchfile = root:packages:platypus:data:batchScan:list_batchbuffer
	Wave/t/z axeslist = root:packages:platypus:SICS:axeslist
	SVAR/z sicsstatus = root:packages:platypus:SICS:sicsstatus
	NVAR/z bmon3_rate = root:packages:platypus:SICS:bmon3_rate
	NVAR/z pointProgress = root:packages:platypus:data:scan:pointProgress
	NVAR/z preset = root:packages:platypus:data:scan:preset
	SVAR/z presettype = root:packages:platypus:data:scan:presettype
	Wave/z position = root:packages:platypus:data:scan:position
	Wave/z counts = root:packages:platypus:data:scan:counts
	
	try
		open/Z=1/T="TEXT" fileID as SAVELOC+"status.html"
		if(V_Flag)
			abort
		endif
		
		//construct the header
		text = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html40/loose.dtd\">\r"
		text += "<HTML>\r"
		text += "<HEAD>\r"
		text += "<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html;charset=UTF-8\">\r"
		text += "<TITLE>Platypus Progress</TITLE>\r"
		text += "<META http-equiv=\"Content-Style-Type\" content=\"text/css\">\r" 
		text += "<STYLE TYPE=\"text/css\">\r" 
		text += "	BODY {\r"
		text += "\t\tpadding-top:0pt; padding-bottom:0pt;\r"
		text += "	}"
		text += "P.HTMLcode {\r"
		text += "\t\tpadding-top:0pt; padding-bottom:0pt;\r"
		text += "	}\r"
		text += "</STYLE>\r"
		text += "</HEAD>\r"
		text += "<BODY STYLE=\"background:rgb(255,255,255)\">\r"
		text += "<META HTTP-EQUIV=\"refresh\" CONTENT=\"120; URL=http://dav1-platypus.nbi.ansto.gov.au/status.html\">\r"

		fbinwrite fileID, text
		
		//write the time of file creation
		text = "<P>"+date() + " " + time() + "</P>\r"
		text += "<P> Copyright 2008, Andrew Nelson + ANSTO</P>\r"
		text += "<P> Instrument Cabin Phone: 9717 7048</P>\r"
		fbinwrite fileID, text

		//now write a table with interesting information
		text ="<TABLE border=\"1\">\r"
		if(SVAR_exists(sicsstatus))
			text +="<TR><TD>SICS status</TD><TD>"+ sicsstatus + "</TD></TR>\r"
		endif
	
		text +="<TR><TD>datafilename</TD><TD>"+ gethipaval("/experiment/file_name") + "</TD></TR>\r"
		text +="<TR><TD>Reactor Power (MW)</TD><TD>"+ gethipaval("/instrument/source/power") + "</TD></TR>\r"	
		text +="<TR><TD>CNS temp (K)</TD><TD>"+ gethipaval("/instrument/source/cns_inlet_temp") +"</TD></TR>\r"
		text +="<TR><TD>Secondary Shutter</TD><TD>"+ UpperStr(gethipaval("/instrument/status/secondary")) + "</TD></TR>\r"
		text +="<TR><TD>Tertiary Shutter</TD><TD>"+ UpperStr(gethipaval("/instrument/status/tertiary")) + "</TD></TR>\r"
	
		if(NVAR_exists(bmon3_rate))
			text +="<TR><TD>Rough Detector Rate (Hz)</TD><TD> "+ num2str(bmon3_rate) + "</TD></TR>\r"
		endif
	
		if(fpxStatus())
			text +="<TR><TD>Acquisition</TD><TD>ACTIVE</TD></TR>\r"
		else
			text +="<TR><TD>Acquisition</TD><TD>IDLE</TD></TR>\r"
		endif
	
		if(batchScanStatus())
			text +="<TR><TD>Batch Scan</TD><TD>ACTIVE</TD></TR>\r"
		else
			text +="<TR><TD>Batch Scan</TD><TD>IDLE</TD></TR>\r"
		endif
		text +="<TR><TD>mode</TD><TD>"+ UpperStr(gethipaval("/instrument/parameters/mode")) + "</TD></TR>\r"
		text +="<TR><TD>omega</TD><TD>"+ UpperStr(gethipaval("/instrument/parameters/omega")) + "</TD></TR>\r"
		text +="<TR><TD>twotheta</TD><TD>"+ UpperStr(gethipaval("/instrument/parameters/twotheta")) + "</TD></TR>\r"
		
		text +="</TABLE>\r"
		fbinwrite fileID, text
		
		//write out if you're currently doing an fpx scan or an acquisition
		text = ""
		if(NVAR_exists(pointprogress) && NVAR_exists(preset) && SVAR_exists(presettype) && waveexists(position) && waveexists(counts))
			if(fpxStatus())
				text += "<P>Time progress in fpx subscan: "+ num2str(pointprogress) + " out of a total of "+num2istr(dimsize(position,0)*preset)+"</P>\r"
				text += "<P> Each preset lasts for: "+ num2str(preset)+"</P>\r"
				text += "<P> with a presettype of : "+ (presettype) + "</P>\r"
				fbinwrite fileID, text
			endif
			
			if(findlistitem("G0_tab1", childwindowlist("sicscmdpanel"))>-0.5)
				doupdate
				savepict/win=sicscmdpanel#g0_tab1/e=-5/o/z as SAVELOC+"statusMedia:Picture0.png"
			endif

			text  = "<table class=\"image\">\r"
			text += "<caption align=\"top\">fpx scan</caption>\r"
		
			text += "<tr><td>\r"
			text += "<P><IMG id=\"Picture0\" src=\"./statusMedia/Picture0.png\" alt=\"Picture0\"></P>\r"
			text += "</TD></TR>\r"
			
			fbinwrite fileID, text
		endif
		
		//the current detector pattern
		text ="<table class=\"image\">\r"
		text +="<caption align=\"top\">Detector Image + TOFspectrum</caption>\r"

		text += "<tr><td>\r"
		text += "<P><IMG id=\"Picture1\" src=\"./statusMedia/Picture1.png\" alt=\"Picture1\"></P>\r"
		text += "</TD></TR>\r"

		text += "<tr><td>\r"
		text += "<P><IMG id=\"Picture2\" src=\"./statusMedia/Picture2.png\" alt=\"Picture2\"></P>\r"
		text += "</TD></TR>\r"

		text += "<tr><td>\r"
		text += "<P><IMG id=\"Picture3\" src=\"./statusMedia/Picture3.png\" alt=\"Picture1\"></P>\r"
		text += "</TD></TR>\r"

		text += "</TABLE>\r"
		fbinwrite fileID, text
		text = ""
			
		if(waveexists(axeslist))
			text ="<TABLE border=\"1\">\r"
			text +="<CAPTION>Axis Positions</CAPTION>\r"	
			text += "<TR>\r<TH>motor name</TH> <TH>position</TH>\r</TR>"
			for(ii=0 ; ii < dimsize(axeslist,0) ; ii+=1)
				text += "<TR><TD>" + axeslist[ii][0] + "</TD><TD>"+ axeslist[ii][2]+"</TD></TR>\r"
			endfor
			text +="</TABLE>\r"
			fbinwrite fileID, text
			text = ""
		endif

		if(waveexists(batchfile))
			text +="<TABLE border=\"1\">\r"
			text +="<CAPTION>Command buffer</CAPTION>\r"
			text += "<TR>\r<TH>#</TH><TH>cmd</TH><TH>status</TH><TH>will run?</TH>\r</TR>\r"
			for(ii=0 ; ii < dimsize(batchfile,0) ; ii+=1)
				text += "<TR><TD>"+num2istr(ii)+"</TD><TD>"+ batchfile[ii][0] + "</TD><TD>"+ batchfile[ii][1] + "</TD><TD> " + batchfile[ii][2]+"</TD></TR>\r"
			endfor
			text +="</TABLE>\r"
			fbinwrite fileID, text
		endif
		
		text = "</BODY>\r"
		text += "</HTML>\r"
		fbinwrite fileID, text
		
		close fileID
		fileID = 0

		string cmd=""

		sprintf cmd,"http://%s:%d/admin//viewdataoptionsgui.egi?&scaling_type=LOG&log_scaling_range=4",DASserverIP,DASserverport
		easyHttp/PASS="manager:ansto" cmd

		sprintf cmd,"http://%s:%d/admin/selectviewdatagui.egi?&type=TOTAL_HISTOGRAM_YT",DASserverIP,DASserverport
		easyHttp/PASS="manager:ansto" cmd

		sprintf cmd,"http://%s:%d/admin/openimageinformatgui.egi?open_format=DISLIN_PNG&open_colour_table=RRAIN&open_plot_zero_pixels=DISABLE&open_annotations=ENABLE", DASserverIP, DASserverport
		easyHttp/FILE=SAVELOC+"statusMedia:Picture1.png" /PASS="manager:ansto" cmd

		sprintf cmd,"http://%s:%d/admin/selectviewdatagui.egi?&type=TOTAL_HISTOGRAM_T",DASserverIP,DASserverport
		easyHttp/PASS="manager:ansto" cmd
	
		sprintf cmd,"http://%s:%d/admin/openimageinformatgui.egi?open_format=DISLIN_PNG&open_colour_table=RRAIN&open_plot_zero_pixels=DISABLE&open_annotations=ENABLE", DASserverIP, DASserverport
		easyHttp/FILE=SAVELOC+"statusMedia:Picture2.png" /PASS="manager:ansto" cmd

		sprintf cmd,"http://%s:%d/admin/selectviewdatagui.egi?&type=TOTAL_HISTOGRAM_Y",DASserverIP,DASserverport
		easyHttp/PASS="manager:ansto" cmd

		sprintf cmd,"http://%s:%d/admin/openimageinformatgui.egi?open_format=DISLIN_PNG&open_colour_table=RRAIN&open_plot_zero_pixels=DISABLE&open_annotations=ENABLE", DASserverIP, DASserverport
		easyHttp/FILE=SAVELOC+"statusMedia:Picture3.png" /PASS="manager:ansto" cmd
		
		sprintf cmd,"http://%s:%d/admin/selectviewdatagui.egi?&type=RATEMAP_YT",DASserverIP,DASserverport
		easyHttp/PASS="manager:ansto" cmd
		
	catch
		if(fileID)
			close fileID
		endif
	endtry
	
	setdatafolder $cDF
End

Function/t createFizzyCommand(type)
	string type
	//run
	//rel
	//acquire
	//omega_2theta
	//samplename
	//igor
	//_none_
	//wait
	//attenuate
	//sics
	string cmd=""

	string motor="",motorlist="", samplename="", sicscmd="",mode
	variable position=0, ii, timer = 0, omega=0.5, twotheta=1, s1=0,s2=0,s3=0,s4=0

	strswitch(type)
		case "":
			break
		case "run":
			Wave/t axeslist = root:packages:platypus:SICS:axeslist
			motorlist = ""
			for(ii=0 ; ii<dimsize(axeslist,0) ; ii+=1)
				motorlist += axeslist[ii][0] + ";"
			endfor
		
			prompt motor, "motor:", popup, motorlist
			prompt position, "position:"
			doprompt "Select motor and desired position", motor, position
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "run(\"%s\",%f)", motor, position
			break
		case "rel":
			Wave/t axeslist = root:packages:platypus:SICS:axeslist
			motorlist = ""
			for(ii=0 ; ii<dimsize(axeslist,0) ; ii+=1)
				motorlist += axeslist[ii][0] + ";"
			endfor

			prompt motor, "motor:", popup, motorlist
			prompt position, "position:"
			doprompt "Select motor and desired relative motion", motor, position
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "rel(\"%s\",%f)", motor, position
			break
			break
		case "acquire":
			string presettypelist="time;MONITOR_1;unlimited;count;frame;"
			string presettype
			prompt samplename,"Sample name: "
			prompt presettype, "Preset type: ", popup, presettypelist
			prompt timer, "preset length: "
			doprompt "Please enter type of acquisition, length and samplename", presettype, timer, samplename
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "acquire(\"%s\",%g, \"%s\")", presettype, timer, samplename
			break
		case "omega_2theta":
			prompt omega, "angle of incidence:"
			prompt twotheta, "total scattering angle (2theta):"
			doprompt "Please enter the acquisition length", omega, twotheta
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "omega_2theta(%g, %g)",omega, twotheta
			break
		case "samplename":
			prompt samplename, "samplename"
			doprompt "Please enter the sample name", samplename
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "samplename(\"%s\")", samplename
			break
		case "igor":
			prompt cmd, "command"
			doprompt "Please enter the IGOR command", cmd
			if(V_Flag)
				return ""
			endif
			break
		case "sics":
			prompt sicscmd, "SICS command:"
			doprompt "Please enter the SICS command", sicscmd
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "sics(\"%s\")", sicscmd
			break
		case "attenuate":
			prompt position, "attenuator mode", popup, "IN;OUT;OSCILLATE"
			doprompt "What do you want the attenuator to do?", position
			if(V_Flag)
				return ""
			endif
			switch(position)
				case 1:
					position = 0
					break
				case 2:
					position = -1
					break
				case 3:
					position = 1
					break
			endswitch
			sprintf cmd, "attenuate(%d)", position
			break
		case "wait":
			prompt timer, "time (s):"
			doprompt "Please enter a delay time", timer
			if(V_Flag)
				return ""
			endif
			sprintf cmd, "wait(%g)", timer
			break
		case "vslits":
			prompt s1, "slit 1 (mm):"
			prompt s2, "slit 2 (mm):"
			prompt s3, "slit 3 (mm):"
			prompt s4, "slit 4 (mm):"
			doprompt "Please enter values for all the slit vertical gaps", s1, s2, s3, s4
			sprintf cmd, "vslits(%g, %g, %g, %g)", s1, s2, s3, s4
			break
		case "setexperimentalmode":
			prompt mode, "Which mode did you want?", popup, "MT;FOC;POL;SB;DB"
			doprompt "Please enter the mode", mode
			sprintf cmd, "setexperimentalmode(\"%s\")", mode
			break
		case "_none_":
		default:
			break

	endswitch

	return cmd
End

Function MOXA(msg, port)
	string msg
	variable port

	NVAR SOCK_MOXA1 = root:packages:platypus:SICS:SOCK_MOXA1
	NVAR SOCK_MOXA2 = root:packages:platypus:SICS:SOCK_MOXA2
	NVAR SOCK_MOXA3 = root:packages:platypus:SICS:SOCK_MOXA3
	NVAR SOCK_MOXA4 = root:packages:platypus:SICS:SOCK_MOXA4

	variable comm

	if(port<1 || port >4)
		print "MOXA port should be 1, 2, 3 or 4"
		return 1
	endif
	port = round(port)

	switch(port)
		case 1:
			comm = SOCK_MOXA1
			break
		case 2:
			comm = SOCK_MOXA2
			break
		case 3:
			comm = SOCK_MOXA3
			break
		case 4:
			comm = SOCK_MOXA4
			break
		default:
			print "MOXA port should be 1, 2, 3 or 4"
			return 1
			break
	endswitch

	if(sockitisitopen(comm))
		sockitsendmsg comm, msg
		if(V_Flag)
			print "MOXA message wasn't sent successfully (MOXA)"
			return 1
		endif
	else
		print "MOXA port isn't open (MOXA)"
		return 1
	endif
	return 0
End

///////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////
//			JULABO water bath for Platypus
///////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function/t julabo_checkStatus()
	//check if julabo is connected
	NVAR SOCK_MOXA1 = root:packages:platypus:SICS:SOCK_MOXA1
	string msg = ""
	//if socket is closed, julabo comms don't work
	if(!sockitisitopen(SOCK_MOXA1))
		print "ERROR: Julabo MOXA TCP/IP socket isn't connected"
		return "JULERR:TCP"
	endif
	
	//if can't get the status julabo must be off
	sockitsendnrecv SOCK_MOXA1, "status\r"
	if(V_Flag || strlen(S_tcp)==0)
		print "ERROR: didn't get a response from Julabo bath"
		return "JULERR:JUL"
	endif
	msg = "JULERR:;STATUS:" + replacestring("\r", S_tcp, "")
	
	//is the temp system on or off
	sockitsendnrecv SOCK_MOXA1, "in_mode_05\r"
	msg += "STARTED:" + replacestring("\r", S_tcp, "") + ";"

	//what is the current temp of the bath
	sockitsendnrecv SOCK_MOXA1, "in_pv_00\r"
	msg += "TEMP:" + replacestring("\r", S_tcp, "") + ";"

	//what is the current settemp
	sockitsendnrecv SOCK_MOXA1, "in_sp_00\r"
	msg += "SETTEMP:" + replacestring("\r", S_tcp, "") + ";"
	
	print msg
	return msg
End

Function julabo_on()
	//assumes julabo is on MOXA port 1
	variable err = MOXA("out_mode_05 1\r", 1)
	return err
End

Function julabo_off()
	//assumes julabo is on MOXA port 1
	variable err = MOXA("out_mode_05 0\r", 1)
	return err
end

Function julabo_gettemp()
	//assumes julabo is on MOXA port 1
	variable err = 0
	variable temperature = NaN
	NVAR SOCK_MOXA1 = root:packages:platypus:SICS:SOCK_MOXA1

	sockitsendnrecv SOCK_MOXA1, "in_pv_00\r"
	if(V_Flag)
		return NaN
	endif
	temperature = str2num(replacestring("\r", S_tcp, ""))
	if(numtype(temperature))
		return NaN
	else
		return temperature
	endif
End

Function julabo_settemp(temperature)
	//assumes julabo is on MOXA port 1
	variable temperature
	variable err
	if(numtype(temperature))
		return 1
	elseif(temperature < 5 || temperature > 60)
		print "Temperature limits hardcoded to 5 < temp <60, check that tubing can handle these temps (julabo_settemp)"
		return 1
	endif
	err = MOXA("out_sp_00 "+num2str(temperature)+"\r", 1)
	return err
end
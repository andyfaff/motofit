#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// https://cms.nbi.ansto.gov.au/instruments/platypus-reflectometer/instrument-manual/echidna-table-of-contents

// if the scan has crap stats try decreasing speed
// dynskan("st4vt", 2.0, 0.05)
// dynskan("sztop", 2.5, 0.05)


// SICS equivalent
// dynskan 100 sztop -1.0 1.0 0.05
// dynskan_data

function dynskan(motor, range, speed [, npnts, automatic])
   string motor
   variable range, speed, npnts, automatic
   
   variable initial_pos, maxspeed, step_size, accel, dist_to_speed
   variable lowerlimit, upperlimit
	string hipadaba_path
	string temp
	string savedDataFolder = GetDataFolder(1)	// Save

	//if the tertiary shutter is closed, it might be a good idea to open it.
	if(stringmatch(gethipaval("/instrument/status/tertiary"), "*Closed*"))
	   speak("The tertiary shutter appears to be closed")
		doalert 1, "WARNING, tertiary Shutter appears to be closed, you may not see any neutrons, do you want to continue?"
		if(V_Flag==2)
			abort
		endif
	endif		
	
	SetDataFolder root:
	newdataFolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o/s root:packages:platypus:data:dynskan

	if(paramisDefault(automatic))
		automatic = 0
	endif
	if(ParamIsDefault(npnts))
		npnts = 4
	endif

	wave/t axeslist = root:packages:platypus:SICS:axeslist
	
	if (dynskan_status() || are_you_already_doing_something(statemon_exceptions="autoalign"))
		return 1
	endif
	
	variable col, row, motoraxisrow
   // first have to check if motor exists
	findvalue/text=motor/Z axeslist
	if(V_Value == -1)
		Print "Error: The" + motor + " motor is not in the current motor list. (start_fly)"
		setdataFolder savedDataFolder
		return 1
	else 
		col = floor(V_Value / dimsize(axeslist, 0))
		row = V_Value - col*dimsize(axeslist, 0)
		motoraxisrow = row
	endif
	
	hipadaba_path = motor_to_hipadaba(motor)
	maxspeed = str2num(getHipaVal(hipadaba_path + "/maxSpeed"))
	accel = str2num(getHipaVal(hipadaba_path + "/accel"))
	dist_to_speed = speed * speed / accel / 2		
	// check lower and upper bounds to see if the move would work
	initial_pos = str2num(axeslist[motoraxisrow][2])
   step_size = range / (npnts - 1)
	variable/g initial_position = initial_pos
	variable/g range_ = range
	variable start_loc = initial_pos - range/2 - dist_to_speed
	variable stop_loc = initial_pos + range/2 + dist_to_speed
	variable/g step_sz = step_size
	variable/g n_pnts = npnts
	variable/g last_ticks = 0
	string/g motorname = motor
	variable/g auto = automatic
	variable/g desired_location = nan
	
	if(speed > maxspeed)
		DoAlert 0, "Warning, scan speed is faster than max speed, clipping to maxspeed"
		speed = maxspeed
	endif

	lowerlimit = str2num(axeslist[motoraxisrow][4])
	upperlimit = str2num(axeslist[motoraxisrow][6])
	if (numtype(lowerlimit) == 0 && numtype(upperlimit) == 0)
		if (start_loc < lowerlimit || stop_loc > upperlimit)
			DoAlert 0, "Error, scan range would exceed limits"
			SetDataFolder savedDataFolder
			return 1
		endif
	else
		DoAlert 1, "Warning, it's unclear if the range would exceed limits, continue?"
		if (V_flag==2)
			SetDataFolder savedDataFolder
			return 1
		endif
	endif
	
	// create the batch for scan
	string cmd = "dynskan 100 %s %g %g %g\n"
	sprintf cmd, cmd, motor, start_loc, stop_loc, speed
	print cmd	
	sics(cmd)
	appendstatemon("DYNSKAN")
		
	make/n=0/d/o dynskan_int_counts, dynskan_int_pos, dynskan_dif_counts, dynskan_frames
	dowindow/k dynskan_progress
	display/n=dynskan_progress/k=1 dynskan_int_counts vs dynskan_int_pos
	AppendToGraph/R/W=dynskan_progress dynskan_dif_counts vs dynskan_int_pos
	ModifyGraph/W=dynskan_progress rgb(dynskan_dif_counts)=(0,0,0)

	Label bottom, motorname
	Label left, "Integrated counts"
	Label right, "counts in peak"


	ctrlnamedbackground dynskan, proc=dynskan_func, start, period=10
	start_hipadaba_logging(motor_to_hipadaba(motor))
	SetDataFolder savedDataFolder
end


function dynskan_status()
	ctrlnamedbackground fly_scan_func, status
	variable running = 0
	
	variable bkdtask = numberbykey("RUN", S_info)
	if(numberbykey("RUN",S_info))
		running = running | 2^2
	endif
	return running
end

function stop_dynskan()
	ctrlnamedbackground dynskan, kill=1
	process_dynskan()
	// process_dynskan typically moves motor to centre or to start location
	wait(2)
	stop_hipadaba_logging()
	statemonclear("DYNSKAN")
end


Function dynskan_func(s)
	STRUCT WMBackgroundStruct &s
	Wave fly_scan = root:packages:platypus:data:dynskan:fly_scan	
	nvar last_ticks = root:packages:platypus:data:dynskan:last_ticks

	if((s.curRunTicks - last_ticks) / 60 > 5)
		last_ticks = s.curRunTicks
		get_dynskan_data()
		process_dynskan_dynamic()
	endif
	if (!statemonstatus("DYNSKAN"))
	    // reached end of fly_scan
	   get_dynskan_data()
	   process_dynskan_dynamic()
		stop_dynskan()
		return 1
	endif
	
	return 0
End

function process_dynskan_dynamic([smooth_len])
	variable smooth_len

   Wave dynskan_int_counts = root:packages:platypus:data:dynskan:dynskan_int_counts
   Wave dynskan_int_pos = root:packages:platypus:data:dynskan:dynskan_int_pos

	if(paramisdefault(smooth_len))
	    smooth_len = 31
	endif
	Duplicate/free dynskan_int_counts,yy_smth;
	Duplicate/free dynskan_int_pos,xx_smth;

	Smooth/E=3/B smooth_len, yy_smth
	SMooth/E=3/B smooth_len, xx_smth
	
	variable npnts = numpnts(dynskan_int_pos)
	make/o/d/n=(npnts) root:packages:platypus:data:dynskan:dynskan_dif_counts
	Wave dynskan_dif_counts = root:packages:platypus:data:dynskan:dynskan_dif_counts
	Differentiate yy_smth/X=xx_smth/D=dynskan_dif_counts
	dynskan_dif_counts[0, 10] = 0
	dynskan_dif_counts[npnts - 10, npnts] = 0
end



function process_dynskan([npnts])
	// npnts - how many points are going to be in the final scan. If npnts
	//         is not specified, it will be the number of points that was
	//         used to run the scan.
   variable npnts
   Wave dynskan_int_counts = root:packages:platypus:data:dynskan:dynskan_int_counts
   Wave dynskan_int_pos = root:packages:platypus:data:dynskan:dynskan_int_pos
		
	nvar n_pnts = root:packages:platypus:data:dynskan:n_pnts 
	nvar step_sz = root:packages:platypus:data:dynskan:step_sz	
	nvar range_ = root:packages:platypus:data:dynskan:range_
	nvar initial_position = root:packages:platypus:data:dynskan:initial_position
	nvar auto = root:packages:platypus:data:dynskan:auto
	svar motorname = root:packages:platypus:data:dynskan:motorname
	variable/g root:packages:platypus:data:dynskan:dynskan_centre
	nvar dynskan_centre = root:packages:platypus:data:dynskan:dynskan_centre
	variable/g root:packages:platypus:data:dynskan:hipadaba_centre = nan
	nvar hipadaba_centre = root:packages:platypus:data:dynskan:hipadaba_centre

	DFREF savedDataFolder = GetDataFolderDFR()

	// try processing with the hipadaba logging approach
	try
		process_hipadaba(motor_to_hipadaba(motorname), trimstring(getHipaVal("/instrument/detector/daq_dirname")), n_pnts)
		wave/z hipadaba_counts = root:packages:platypus:data:dynskan:hipadaba_counts
		wave/z hipadaba_pos = root:packages:platypus:data:dynskan:hipadaba_pos
		if(WaveExists(hipadaba_counts))
			appendtograph/W=dynskan_progress hipadaba_counts vs hipadaba_pos
		endif
		SetDataFolder root:packages:platypus:data:dynskan
		CurveFit/q/M=2/W=2 gauss, hipadaba_counts/X=hipadaba_pos/D
		ModifyGraph/W=dynskan_progress rgb(hipadaba_counts)=(1,4,52428),rgb(fit_hipadaba_counts)=(1,4,52428), lstyle(fit_hipadaba_counts)=3
		Wave W_coef
		hipadaba_centre = W_coef[2]
	catch
	endtry

	SetDataFolder root:packages:platypus:data:dynskan
	Wave dynskan_dif_counts = root:packages:platypus:data:dynskan:dynskan_dif_counts
	Wave dynskan_int_pos = root:packages:platypus:data:dynskan:dynskan_int_pos

	SetDataFolder root:packages:platypus:data:dynskan
	CurveFit/q/M=2/W=2 gauss, dynskan_dif_counts/X=dynskan_int_pos/D
	Wave W_coef
	ModifyGraph/W=dynskan_progress lstyle(fit_dynskan_dif_counts)=3, rgb(fit_dynskan_dif_counts)=(0,0,0)
	dynskan_centre = W_coef[2]
	TextBox/C/N=text0/A=MC "Peak Centre = " + num2str(W_coef[2])
	print "Gauss centre at: " + num2str(W_coef[2])
	print "Hipadaba centre at ", hipadaba_centre
	setdatafolder savedDataFolder
	doupdate/w=dynskan_progress

	apply_any_offset(motorname, dynskan_centre, initial_position, auto)
end


function apply_any_offset(motor, centre, initial_position, auto)
	string motor
	variable centre, initial_position, auto
	
	variable offsetvalue, num, err
	//	socket	for sending sics commands
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd
	nvar desired_location = root:packages:platypus:data:dynskan:desired_location

	if(auto)	//if you are auto aligning
		if(auto == 1)
			print "dynskan placing ", motor," at: ", centre
			desired_location = centre
		elseif(auto == 2)
			print "dynskan of motor done, returning ", motor, " to: ", initial_position
			desired_location = initial_position
		endif
		if(run(motor, desired_location))
			print "error while driving (finishScan)"
			return 1
		endif
		sleep/q/S 2
		doxopIdle
	else		//no auto alignment, ask the user
		DoAlert 1, "Do you want to move to the peak centre?"
		if(V_Flag == 2)	// you don't want to move to peak centre
			run(motor, initial_position)
			print "Scan finishing"
		elseif(V_flag == 1)		// you want to move to peak centre
			num = centre
			offsetValue = centre
			string helpStr = "If you do not wish to change the position of the peak press cancel"
			Prompt offsetValue, "new value for peak position"
			Doprompt/HELP=helpStr "Please enter the new value for the peak position (cancel=no change)", offsetValue

			if(!V_Flag)		// if you want to enter an offset
				print "Scan finishing, offset changed and driving to to peak position"
				print "setpos:", motor, num, offsetvalue
				sockitsendnrecv/smal sock_cmd,"setpos " + motor + " " + num2str(num)+ " "+ num2str(offsetvalue) +"\n"
				if(V_Flag)
					print "error while setting zero (finishScan)"
					return 1
				endif
				if( run(motor, offsetvalue) )
					print "error while driving (finishScan)"
					return 1
				endif
			else				//if you don't want to enter an offset
				print "Scan finishing, driving to peak position"
				err = run(motor, num)
				if(err)
					print "Error while returning to new position (apply_any_offset)"
				endif
			endif
		endif	
	endif
end



Function get_dynskan_data()
	NVAR SOCK_sync = root:packages:platypus:SICS:SOCK_sync
	string data=""
	SOCKITsendnrecv SOCK_sync, "dynskan_data\n", data

   Wave dynskan_int_counts = root:packages:platypus:data:dynskan:dynskan_int_counts
   Wave dynskan_int_pos = root:packages:platypus:data:dynskan:dynskan_int_pos
   Wave dynskan_int_frames = root:packages:platypus:data:dynskan:dynskan_frames
	svar motorname = root:packages:platypus:data:dynskan:motorname
	
	string substr
	variable nitems = itemsinlist(data, "\n")
	if(nitems < 2)
		return 0
	endif
	redimension/n=(nitems - 1)/d dynskan_int_counts, dynskan_int_pos
	variable ii
	string tok
	data = replacestring(" ", data, "")
	
	// first line contains the column headers
	for(ii = 1 ; ii < nitems ; ii += 1)
		substr = stringfromlist(ii, data, "\n")
		
		tok = stringfromlist(1, substr, ",")
		dynskan_int_pos[ii - 1] = str2num(tok)
		
		tok = stringfromlist(4, substr, ",")
		dynskan_int_counts[ii - 1] = str2num(tok)
		
		tok = stringfromlist(3, substr, ",")
		dynskan_int_frames[ii - 1] = str2num(tok)
	endfor
end


function start_hipadaba_logging(nodes)
	// logging of given nodes in the hipadaba tree
	//
	// nodes: semicolon separated list of the hipadaba nodes to track
	//
	// The node logs are currently saved into the IPUF10/Python Scripts directory.
	string nodes
	nodes = replacestring(";", nodes, " ")
	string pth = SpecialDirPath("Igor Pro User Files", 0, 1, 0)
	pth = replacestring("\\", pth, "\\")

	string nodestr = ""
	if(strlen(nodes))
	    nodestr = "--tags " + nodes 
	endif
	
	string cmd = ""
	sprintf cmd, "cmd.exe /c c: && cd \"%sPython Scripts\" && conda activate dev3 && title Hipadaba logger && python hipadaba_logger.py %s", pth, nodestr
	// print cmd
	// the following line is required if one hasn't set up cmd.exe to automatically know conda
   // "call C:\\ProgramData\\miniforge3\\Scripts\\activate && "
	executescripttext/B/W=0.5/z cmd
	//ExecuteDOSCommand_wottpy(cmd, 0.5)
end


function stop_hipadaba_logging()
	// stops the hipadaba logging
	string pth = SpecialDirPath("Igor Pro User Files", 0, 1, 0)
	pth = replacestring("\\", pth, "\\")
	pth += "Python Scripts"
	newpath/C/O/Q stop_hipadaba_logger, pth
	variable fnum
	open/p=stop_hipadaba_logger fnum as "stop.txt"
	close fnum
	killpath/z stop_hipadaba_logger
end


function process_hipadaba(node, daq, frame_agg, [miny, maxy, mint, maxt, start_frame, end_frame])
	// process the dynskan data via the hipadaba logged data and the event mode file
	// node - hipadaba node for what you're scanning
	// daq - DAQ_dirname for the data
	// frame_agg - how many frames you'd like to aggregate together
	// miny - minimum y pixel to include
	// maxy - maximum y pixel to include
	// mint - minimum tof to include (microseconds)
	// maxt - maximum tof to include (microseconds)
	
	// You have to specify both mint/miny and maxt/maxt for them to have an effect
	string node, daq
	variable frame_agg
	variable miny, maxy, mint, maxt, start_frame, end_frame
	string cmd
	variable sz
	string ybins = ""
	string tbins = ""
	string start_end_frame = ""
	if(ParamIsDefault(miny) == 0 && paramisdefault(maxy) == 0)
		 sprintf ybins, ", ybins=(%f, %f)", miny, maxy
	endif
	if(ParamIsDefault(mint) == 0 && paramisdefault(maxt) == 0)
		 sprintf tbins, ", tbins=(%f, %f)", mint, maxt
	endif
	if(ParamIsDefault(start_frame)==0 && paramisdefault(end_frame)==0)
		sprintf start_end_frame, ", start_end_frame=(%d, %d)", start_frame, end_frame
	endif
	
	sprintf cmd, "import numpy as np;import hipadaba_logger; pos, det = hipadaba_logger.process_hipadaba_scan('%s', '%s', %d%s%s%s); output=np.c_[pos, np.squeeze(det)]", node, daq, frame_agg, ybins, tbins, start_end_frame
	print(cmd)
	   
	make/free/o output
	python execute=cmd, array={"output", output}
	sz = dimsize(output, 0)
	make/d/o/n=(sz) root:packages:platypus:data:dynskan:hipadaba_counts = output[p][1] * 100
	make/d/o/n=(sz) root:packages:platypus:data:dynskan:hipadaba_pos = output[p][0]
end
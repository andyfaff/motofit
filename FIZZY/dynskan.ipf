#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// https://cms.nbi.ansto.gov.au/instruments/platypus-reflectometer/instrument-manual/echidna-table-of-contents

// if the scan has crap stats try increasing step size and/or time per point.
// fly("st4vt", 2.0, 0.05, 2)
// fly("sz", 2.5, 0.1, 2)


// SICS equivalent
// dynskan 100 sztop -1.0 1.0 0.05
// show_data

function dynskan(motor, range, speed, npnts, [automatic])
   string motor
   variable range, speed, npnts, automatic
   
   variable initial_pos, maxspeed, step_size
   variable lowerlimit, upperlimit
	string hipadaba_path
	string temp
	string savedDataFolder = GetDataFolder(1)	// Save

	SetDataFolder root:
	newdataFolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o/s root:packages:platypus:data:dynskan

	if(paramisDefault(automatic))
		automatic = 0
	endif

	wave/t axeslist = root:packages:platypus:SICS:axeslist
	
	if (dynskan_status() || are_you_already_doing_something())
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
	
	hipadaba_path = axeslist[motoraxisrow][1]
	maxspeed = str2num(getHipaVal(hipadaba_path + "/maxSpeed"))
	
	// check lower and upper bounds to see if the move would work
	initial_pos = str2num(axeslist[motoraxisrow][2])
   step_size = range / (npnts - 1)
	variable/g initial_position = initial_pos
	variable/g range_ = range
	variable start_loc = initial_pos - range/2 - 2 * step_size
	variable stop_loc = initial_pos + range/2 + 2 * step_size
	variable/g step_sz = step_size
	variable/g n_pnts = npnts
	variable/g last_ticks = 0
	string/g motorname = motor
	variable/g auto = automatic
	
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
	ModifyGraph/W=dynskan_process rgb(dynskan_dif_counts)=(0,0,0)

	Label bottom, motorname
	Label left, "Integrated counts"
	Label right, "counts in peak"


	ctrlnamedbackground dynskan, proc=dynskan_func, start, period=10
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
	statemonclear("DYNSKAN")
	process_dynskan()
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
	    smooth_len = 11
	endif
	Duplicate/free dynskan_int_counts,yy_smth;
	Duplicate/free dynskan_int_pos,xx_smth;

	Smooth/E=3/B smooth_len, yy_smth
	SMooth/E=3/B 5, xx_smth
	
	variable npnts = numpnts(dynskan_int_pos)
	make/o/d/n=(npnts) root:packages:platypus:data:dynskan:dynskan_dif_counts
	Wave dynskan_dif_counts = root:packages:platypus:data:dynskan:dynskan_dif_counts
	Differentiate yy_smth/X=xx_smth/D=dynskan_dif_counts
	dynskan_dif_counts[0, 20] = 0
	dynskan_dif_counts[npnts - 20, npnts] = 0
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
	
	if(paramisdefault(npnts))
	    npnts = n_pnts
	endif
	make/free/d/n=(npnts + 1) edges, loc, interp_cts
	setscale/I x, initial_position - 0.5*(range_ + step_sz), initial_position + 0.5*(range_ + step_sz), edges
	edges = pnt2x(edges, p)
	loc = binarysearchinterp(dynskan_int_pos, edges)
	interp_cts = dynskan_int_counts[loc]
	
	// now histogram
	
	make/d/o/n=(npnts) root:packages:platypus:data:dynskan:dynskan_counts
	make/d/o/n=(npnts) root:packages:platypus:data:dynskan:dynskan_pos
	wave dynskan_counts = root:packages:platypus:data:dynskan:dynskan_counts
   wave dynskan_pos = root:packages:platypus:data:dynskan:dynskan_pos

	dynskan_counts = interp_cts[p + 1] - interp_cts[p]
	dynskan_pos = 0.5 * (edges[p + 1] + edges[p])

	dowindow/k dynskan_plot	
	display/k=1/n=dynskan_plot dynskan_counts vs dynskan_pos
	ModifyGraph rgb(dynskan_counts)=(1,16019,65535), lsize(dynskan_counts)=2
	Label bottom motorname
	
	DFREF savedDataFolder = GetDataFolderDFR()
	SetDataFolder root:packages:platypus:data:dynskan
	CurveFit/q/M=2/W=2 gauss, dynskan_counts/X=dynskan_pos/D
	Wave W_coef
	dynskan_centre = W_coef[2]
	TextBox/C/N=text0/A=MC "Peak Centre = " + num2str(W_coef[2])
	print "Gauss centre at " + num2str(W_coef[2])
	setdatafolder savedDataFolder
	doupdate/w=dynskan_plot

	apply_any_offset(motorname, dynskan_centre, initial_position, auto)
end


function apply_any_offset(motor, centre, initial_position, auto)
	string motor
	variable centre, initial_position, auto
	
	variable offsetvalue, num, err
	//	socket	for sending sics commands
	NVAR SOCK_cmd = root:packages:platypus:SICS:SOCK_cmd

	if(auto)	//if you are auto aligning
		if(auto ==1)
			print "dynskan placing ", motor," at: ", centre
			offsetvalue = centre
		elseif(auto==2)
			print "dynskan of motor done, returning ", motor, " to: ", initial_position
			offsetvalue = initial_position
		endif
		if(run(motor, offsetvalue))
			print "error while driving (finishScan)"
			return 1
		endif
		sleep/q/S 2
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
				sockitsendmsg sock_cmd,"setpos " + motor + " " + num2str(num)+ " "+ num2str(offsetvalue) +"\n"
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
				err= run(motor, num)
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
	SOCKITsendnrecv SOCK_sync, "show_data\n", data

   Wave dynskan_int_counts = root:packages:platypus:data:dynskan:dynskan_int_counts
   Wave dynskan_int_pos = root:packages:platypus:data:dynskan:dynskan_int_pos
   Wave dynskan_int_frames = root:packages:platypus:data:dynskan:dynskan_frames
	svar motorname = root:packages:platypus:data:dynskan:motorname
	
	string substr
	variable nitems = itemsinlist(data, "\n")
	redimension/n=(nitems)/d dynskan_int_counts, dynskan_int_pos
	variable ii
	string tok
	for(ii = 0 ; ii < nitems ; ii += 1)
		substr = stringfromlist(ii, data, "\n")
		substr = replacestring(" ", substr, "")
		
		tok = stringbykey(motorname, substr, "=", ",")
		dynskan_int_pos[ii] = str2num(tok)
		
		tok = stringbykey("hmm.num_events_inside_oat_xyt", substr, "=", ",")
		dynskan_int_counts[ii] = str2num(tok)
		
		tok = stringbykey("hmm.current_frame", substr, "=", ",")
		dynskan_int_frames[ii] = str2num(tok)
	endfor
end

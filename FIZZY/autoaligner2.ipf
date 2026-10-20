#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function autoalign(angle, direct_beam_number, height, [cycles, agg, set_z, set_sth, sztype, zspeed, preset, position, reflect_down])
    variable angle, direct_beam_number, height, cycles, agg, set_z, set_sth
	string sztype
	variable zspeed, preset, position, reflect_down

//	Performs an auto-alignment for an air-solid or solid-liquid sample. Should leave the
//	sample in an aligned state. Requires that reflected beam should already be on the
//	detector, i.e. it doesn't go hunting for a beam that isn't there.
//	Does a dynskan on the height motor, then measures for a while to figure out what the
//  reflected angle is (calling out to refnx to do so. It corrects the height and the angle
//  after each. Two cycles of alignment are done. The positioner table can be automatically
//  filled out if desired.
//  The command can be issued from the command-line or the batch file.
//	
//	Parameters
//	----------
//	
//	angle : int
//	    the entry in the angler table at which you want to do the alignment.
//	direct_beam_number : int
//	    the direct beam run number corresponding to the angle you're aligning at.
//	height : float
//	    the range (mm) over which you'd like to do a height scan.
//
//  cycles : (optional, int)
//      How many cycles of the height/angle alignment do you want to run. Default is 2.
//  agg : (optional, int)
//      the number of adjacent frames to aggregate when measuring the height scan. If
//      the chopper frequency is 24, and agg=6, then each scan point will represent 0.25 of
//      a second.
//	set_z : (optional, int)
//		whether you want to zero out the height for the sztype motor after the scan.
//	set_sth : (optional, int)
//		whether the sth motor is 'setpos' to the sth value from the angler table after
//		the scan.
//	sztype : (optional, {"sztop", "sz"})
//	    the motor to perform the height scan on. "sztop" is the default.
//  zspeed : (optional, float)
//      the speed at which the dynskan on the z-axis is carried out. Default is 0.05. Should be
//      somewhere between 0.01 and 0.2.
//	preset : (optional, float)
//		the number of seconds for the data acquisition that is used to detect the angle
//		of incidence. Default is 15 seconds.
//	position : (optional, int)
//		if this value is set then a `positioner(position)` command is run directly
//		after the `angler(angle)` command at the start of the alignment process. i.e.
//		the existing sxtop/sztop/sth offsets are applied to the sample. After the scan
//		the positioner table is updated with the new offsets. This is useful if the sample
//		has already been roughly aligned, i.e. if you're aligning in a batch script.
//		You should obviously check if the values in the positioner table are sensible before
//		using this option. Performing an sxtop move could move the sample out of the beam.
//	reflect_down : (optional, int)
//		set this value to a non-zero number if you are trying to align the sample in a
//		'reflect down' manner. Most of the samples we measure on Platypus are 'reflect up'.
//  
//  Notes
//  -----
//  - requires that refnx be installed into a dev3 conda environment
//  - if it hasn't been used for a while sometimes the angle calculation, that calls
//    out to refnx, can timeout. If that happens you can call `autoalign_stop()` and
//    try repeating it.

	// what sz motor are you scanning
	if(paramisdefault(sztype))
		sztype = "sztop"
	elseif(strlen(listmatch("sztop;sz", sztype)) == 0)
		Doalert 0, "sztype must be either sztop or sz"
		return 1		
	endif
	if(paramisdefault(preset))
		preset = 15
	elseif(preset < 0)
		preset = 15
	endif
	variable sztype_pos = getpos(sztype)
	if(checkDrive(sztype, sztype_pos - height/2)==1 || checkdrive(sztype, sztype_pos + height/2)==1)
		return 1
		Doalert 0, "Requested height range for " + sztype + " is not accessible" 
	endif
	Wave/t/z angler_listwave = root:packages:platypus:SICS:angler_listwave
	
    if(autoalign_status())
   		print autoalign_status()
		Doalert 0, "Can't currently autoalign"
		return 1
	endif
	if((dimsize(angler_listwave, 0) - 1 < angle) || (angle < 0))
		Doalert 0, "Can't autoalign, angler value is not contained in table"
		return 1
	endif
	print "================================"
	print "Autoaligning ", Secs2Date(DateTime,-2), Secs2Time(DateTime,3)
	print "SOFTZERO at start: sth = ", gethipaVal("/sample/sth/softzero")
	print "SOFTZERO at start: ", sztype, " = ", gethipaVal("/sample/" + sztype + "/softzero")

	appendStatemon("autoalign")
	ctrlnamedBackground autoaligner, proc=autoalign_runner, start, period=20
	newdataFolder/o root:packages:platypus:SICS:autoaligner
	string/g root:packages:platypus:SICS:autoaligner:step /N=step
	string/g root:packages:platypus:SICS:autoaligner:sztype /N=t_sztype
	variable/g root:packages:platypus:SICS:autoaligner:cycle /N=cycle
	variable/g root:packages:platypus:SICS:autoaligner:height /N=t_height
	variable/g root:packages:platypus:SICS:autoaligner:height_state /N=t_height_state
	variable/g root:packages:platypus:SICS:autoaligner:acquire_state /N=t_acquire_state
	variable/g root:packages:platypus:SICS:autoaligner:angle /N=t_angle
	variable/g root:packages:platypus:SICS:autoaligner:omega /N=omega
	variable/g root:packages:platypus:SICS:autoaligner:direct_beam_number /N=tdb
	variable/g root:packages:platypus:SICS:autoaligner:set_z /N=t_set_z
	variable/g root:packages:platypus:SICS:autoaligner:set_sth /N=t_set_sth
	variable/g root:packages:platypus:SICS:autoaligner:preset /N=t_preset
	variable/g root:packages:platypus:SICS:autoaligner:zspeed /N=t_zspeed
	variable/g root:packages:platypus:SICS:autoaligner:position /N=t_position
	variable/g root:packages:platypus:SICS:autoaligner:reflect_down /N=t_reflect_down
	variable/g root:packages:platypus:SICS:autoaligner:original_zpos /N=t_original_zpos
	variable/g root:packages:platypus:SICS:autoaligner:original_zspeed /N=t_original_zspeed
	variable/g root:packages:platypus:SICS:autoaligner:original_sth /N=t_original_sth
	variable/g root:packages:platypus:SICS:autoaligner:epoch_start
	variable/g root:packages:platypus:SICS:autoaligner:epoch_finish
	variable/g root:packages:platypus:SICS:autoaligner:igor_time
	variable/g root:packages:platypus:SICS:autoaligner:dataset_start_time_t
	variable/g root:packages:platypus:SICS:autoaligner:agg /N=t_agg
	variable/g root:packages:platypus:SICS:autoaligner:total_cycles /N=t_total_cycles
	string/g root:packages:platypus:SICS:autoaligner:DAQ_dirname

	omega = str2num(angler_listwave[angle][1])
	t_angle = angle
	t_height = height
	step = ""
	cycle = -3
	tdb = direct_beam_number
	t_set_z = set_z
	t_set_sth = set_sth
	t_sztype = sztype
	t_preset = preset
	if(paramisdefault(position))
		t_position = nan
	else
		t_position = position
	endif
	if(paramisdefault(reflect_down))
		t_reflect_down = 0
	else
		t_reflect_down = reflect_down
	endif
	if(paramisDefault(zspeed))
		t_zspeed = 0.05
	else
		t_zspeed = zspeed
		if(zspeed < 0.01 || zspeed > 0.2)
			print "z speed is too fast or slow, setting to 0.05"
		    t_zspeed = 0.05
		endif
	endif
	if(paramisdefault(agg))
		agg = 6
	endif
	t_agg = round(agg)
	if(paramisdefault(cycles))
		cycles = 2
	endif
	t_total_cycles = round(cycles)
	
	t_original_zpos = getpos(sztype)
	t_original_sth = getpos("sth")

	string hipadaba_path = motor_to_hipadaba(sztype)		
	start_hipadaba_logging(hipadaba_path)
	t_original_zspeed = str2num(getHipaVal(hipadaba_path + "/speed"))

	//	0	at middle
	//	1	at start
	//	2	moving
	//	3	at end
	t_height_state = 0
	
	// 0   stopped
	// 1   started
	t_acquire_state = 0
End


Function autoalign_runner(s)
	STRUCT WMBackgroundStruct &s
	SVAR step = root:packages:platypus:SICS:autoaligner:step
	NVAR cycle = root:packages:platypus:SICS:autoaligner:cycle
	NVAR height = root:packages:platypus:SICS:autoaligner:height
	NVAR height_state = root:packages:platypus:SICS:autoaligner:height_state
	NVAR acquire_state = root:packages:platypus:SICS:autoaligner:acquire_state
	NVAR direct_beam_number = root:packages:platypus:SICS:autoaligner:direct_beam_number
	SVAR sztype = root:packages:platypus:SICS:autoaligner:sztype
	NVAR omega = root:packages:platypus:SICS:autoaligner:omega
	NVAR angle = root:packages:platypus:SICS:autoaligner:angle
	NVAR set_z = root:packages:platypus:SICS:autoaligner:set_z
	NVAR set_sth = root:packages:platypus:SICS:autoaligner:set_sth
	NVAR preset = root:packages:platypus:SICS:autoaligner:preset
	NVAR zspeed = root:packages:platypus:SICS:autoaligner:zspeed
	NVAR original_zspeed = root:packages:platypus:SICS:autoaligner:original_zspeed
	NVAR position = root:packages:platypus:SICS:autoaligner:position
	NVAR reflect_down = root:packages:platypus:SICS:autoaligner:reflect_down
	NVAR epoch_start = root:packages:platypus:SICS:autoaligner:epoch_start
	NVAR epoch_finish = root:packages:platypus:SICS:autoaligner:epoch_finish
	NVAR igor_time = root:packages:platypus:SICS:autoaligner:igor_time
	NVAR agg = root:packages:platypus:SICS:autoaligner:agg
	NVAR total_cycles = root:packages:platypus:SICS:autoaligner:total_cycles

	wave/t axeslist = root:packages:platypus:SICS:axeslist
	SVAR DAQ_dirname = root:packages:platypus:SICS:autoaligner:daq_dirname
	NVAR dataset_start_time_t = root:packages:platypus:SICS:autoaligner:dataset_start_time_t

	variable aas = autoalign_status()
	variable sztype_pos
	string hipadaba_path
	string cmd
	string output
	variable accel
	variable dist_to_speed

	variable actual, offset
	if(cycle == -3 && aas ==2)
		// first time into the background task, need to move
		//appendStatemon("om2th")
		//angler(angle)
		cycle += 1
		return 0
	endif
	if(cycle == -2 && aas == 2)
		// second time into the background task, might need to move samples via positioner
		if(numtype(position))
			// no specified position
			cycle += 1
			return 0			
		else
			// we have a specified position
			positioner(position)
			// wait for a couple of seconds for sample to start moving
			wait(2)
			cycle += 1
			return 0
		endif
	endif

	// ready to start aligning, histogram server is not running
	if(cycle == -1 && aas == 2)
		// start the histogram memory server going
		cycle += 1
		step = "height"
		height_state = 0
		acquire_state = 0
		return sics("histmem mode time\nhistmem preset 1000\nnewfile HISTOGRAM_XYT scratch\nautosave 15\nhistmem start")
	endif


	if(cycle >= 0 && ((aas & 2^2) != 0) && cycle < total_cycles)
		strswitch(step)
			case "height":
				hipadaba_path = motor_to_hipadaba(sztype)
				accel = str2num(getHipaVal(hipadaba_path + "/accel"))
				dist_to_speed = zspeed * zspeed / accel / 2		
				sztype_pos = getpos(sztype)

				switch(height_state)
					case 0:  // supposed to be in middle
						// still moving, don't do anything
						if(statemonstatus(sztype))
							return 0
						endif					
						sztype_pos = getpos(sztype)
						appendStatemon(sztype)
						height_state = 1
						print "Performing height scan"
						return run(sztype, sztype_pos - height/2 - dist_to_speed)
						break
					case 1: // at start of range
						// wait until stationary
						if(statemonstatus(sztype))
							return 0
						endif
						sics("hset " + hipadaba_path + "/speed " + num2str(zspeed))
						sztype_pos = getpos(sztype)
						appendStatemon(sztype)
						height_state = 2
						epoch_start = epoch_time()
						return run(sztype, sztype_pos + height + dist_to_speed)
						break
					case 2: // moving
						// wait until stationary
						if(statemonstatus(sztype))
							return 0
						endif
						height_state = 3
						epoch_finish = epoch_time()
						return 0
						break
					case 3: // at end
						daq_dirname = trimstring(getHipaVal("/instrument/detector/daq_dirname"))
						// TODO check dataset_start_time_t is correct when we have chopper signal back
						sprintf cmd, "import numpy as np;import hipadaba_logger; dct=hipadaba_logger.status_dct('%s');output=dct['dataset_start_time_t']", daq_dirname
						python/z execute=cmd, var={"output", output}
						dataset_start_time_t = str2num(output)
						
						variable freq = str2num(getHipaVal("/instrument/disk_chopper/ch1speed")) / 60
						variable start_frame = ceil((epoch_start - dataset_start_time_t) * freq)
						variable end_frame = ceil((epoch_finish - dataset_start_time_t) * freq)
						process_hipadaba(motor_to_hipadaba(sztype), daq_dirname, agg, start_frame=start_frame, end_frame=end_frame)
						wave hipadaba_counts = root:packages:platypus:data:dynskan:hipadaba_counts
						wave hipadaba_pos = root:packages:platypus:data:dynskan:hipadaba_pos
						
						dowindow/k autoalign_z
						Display/n=autoalign_z hipadaba_counts vs hipadaba_pos
						DoWindow/T autoalign_z,"Autoalign: z component"
						ModifyGraph/w=autoalign_z rgb=(0,0,0)
						label/w=autoalign_z bottom sztype
						CurveFit/q/M=2/W=0 gauss, hipadaba_counts/X=hipadaba_pos/D
						Wave W_coef
						variable hipadaba_centre = W_coef[2]
		
						height_state = 0
						sics("hset " + hipadaba_path + "/speed " + num2str(original_zspeed))
						step = "acquire"
						print "Moving to peak centre"
						appendStatemon(sztype)
						return run(sztype, hipadaba_centre)
						break
				endswitch
				
				return 0
				break
			case "acquire":
				// if there's anything on the statemon (besides histoserver) don't have a period of acquisition
				if(aas & 2^3)
					return 0
				endif
				switch(acquire_state)
					case 0:
						epoch_start = epoch_time()
						igor_time = datetime
						acquire_state = 1
						print "Determining angle"
						return 0
					break
					case 1:
						// compare a datetime because grabbing the epoch time from python makes the GUI flash.
						if(igor_time + preset > datetime)
							return 0
						else
							epoch_finish = epoch_time()
						endif
						step = "height"
						cycle += 1
						print "autoalign: calculating angle"
						print epoch_start-dataset_start_time_t, epoch_finish-dataset_start_time_t
						actual = wottpy(NaN, direct_beam_number, start_time=epoch_start-dataset_start_time_t, end_time=epoch_finish-dataset_start_time_t)
						if(numtype(actual))
							// problem with figuring out angle
							print "Problem with autoaligning"
							appendstatemon("ERROR_AUTOALIGN")
							sics("run ss1u 0 ss1d 0 ss2d 0 ss2u 0 ss3d 0 ss3u 0 ss4u 0 ss4d 0")
							autoalign_stop()
							return 1 
						endif
						if(reflect_down != 0)
							actual *= -1		
						endif
						offset = omega - actual
						acquire_state = 0
						print "APPLYING OFFSET TO STH"
						appendStatemon("sth")
						rel("sth", offset)
						return 0
					break
				endswitch
				break
		endswitch
	endif
	
	// you've done two cycles of aligning and you're no longer moving
	if(cycle==total_cycles && (aas & 2^3)==0)
		variable sth_pos = getpos("sth")
		variable total_offset = sth_pos - omega
		print "TOTAL OFFSETS: ", sztype, " = ", getpos(sztype), "; sth = ", total_offset
		if(set_z != 0)
			print "Adjusting ", sztype, " softzero"
			setpos(sztype, 0)
		endif
		if(set_sth != 0)
			print "Adjusting sth softzero"
			setpos("sth", omega)
		endif
		if(!numtype(position))
			// we are using a specific position, so update offsets
			Wave/t/z position_listwave = root:packages:platypus:SICS:position_listwave
			print("Adjusting values in positioner table")
			position_listwave[position][3] = num2str(getpos(sztype))
			position_listwave[position][5] = num2str(total_offset)
		endif
		autoalign_stop()
		return 1
	endif

	return 0
End


Function autoalign_status()
	// 0 - not currently autoaligning
	// 1 - autoaligner background task running
	// 2 - STARTED = HistogramMemory on statemon
	// 3 - anything else on the statemon
	ctrlnamedbackground autoaligner, status
	variable running = numberByKey("RUN", S_info)

	variable status = 0
	
	// is this autoaligner running?
	if(running)
		status = status | (2^1)
	endif

	// is the histogram server acquiring
	wave/t statemon = root:packages:platypus:SICS:statemon
	string s_statemon
	variable pos
	SOCKITwaveToString/txt=";" statemon, s_statemon
	s_statemon = ReplaceString(" ", s_statemon, "")
	pos = WhichListItem("HistogramMemory", s_statemon)
	if(pos >= 0)
	    status = status | (2^2)
	endif
	
	// is anything else (besides the histogram server) doing anything? (ignore autoalign)
	s_statemon = replacestring("HistogramMemory", s_statemon, "")
	s_statemon = replacestring("autoalign", s_statemon, "")
	// remove empty entries from list
	s_statemon = removefromlist("", s_statemon)
	if(itemsinlist(s_statemon) > 0)
		status = status | (2^3)
	endif

	return status
End


Function autoalign_stop([to_original])
	variable to_original
	if(ParamIsDefault(to_original))
		to_original = 0
	endif
	SVAR sztype = root:packages:platypus:SICS:autoaligner:sztype
	NVAR original_zspeed = root:packages:platypus:SICS:autoaligner:original_zspeed
	string hipadaba_path = motor_to_hipadaba(sztype)
	sics("hset " + hipadaba_path + "/speed " + num2str(original_zspeed))

	if(to_original != 0)
		NVAR original_zpos = root:packages:platypus:SICS:autoaligner:original_zpos
		NVAR original_sth = root:packages:platypus:SICS:autoaligner:original_sth
		run(sztype, original_zpos)
		run("sth", original_sth)
	endif
	stop_hipadaba_logging()
    if(statemonstatus("autoalign"))
	    statemonclear("autoalign")
	endif
	if(statemonstatus("HistogramMemory"))
		sics("histmem stop")
    endif
    print "Finished", Secs2Date(DateTime,-2), Secs2Time(DateTime,3)
   	print "================================"
   	speak("Finished Autoalign")
    ctrlnamedBackground autoaligner, stop=1
End


Function epoch_time()
	variable times
	python execute="import time;timenow=time.time()", var={"timenow", times}
	return times
End
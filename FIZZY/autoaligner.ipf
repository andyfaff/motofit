#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function autoalign(angle, direct_beam_number, height, [set_z, set_sth, sztype, zspeed, preset, position, reflect_down])
    variable angle, direct_beam_number, height, set_z, set_sth
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
	ctrlnamedBackground autoaligner, proc=autoalign_runner, start, period=60
	newdataFolder/o root:packages:platypus:SICS:autoaligner
	string/g root:packages:platypus:SICS:autoaligner:step /N=step
	string/g root:packages:platypus:SICS:autoaligner:next_step /N=next_step
	string/g root:packages:platypus:SICS:autoaligner:sztype /N=t_sztype
	variable/g root:packages:platypus:SICS:autoaligner:cycle /N=cycle
	variable/g root:packages:platypus:SICS:autoaligner:height /N=t_height
	variable/g root:packages:platypus:SICS:autoaligner:angle /N=t_angle
	variable/g root:packages:platypus:SICS:autoaligner:omega /N=omega
	variable/g root:packages:platypus:SICS:autoaligner:direct_beam_number /N=tdb
	variable/g root:packages:platypus:SICS:autoaligner:set_z /N=t_set_z
	variable/g root:packages:platypus:SICS:autoaligner:set_sth /N=t_set_sth
	variable/g root:packages:platypus:SICS:autoaligner:preset /N=t_preset
	variable/g root:packages:platypus:SICS:autoaligner:zspeed /N=t_zspeed
	variable/g root:packages:platypus:SICS:autoaligner:position /N=t_position
	variable/g root:packages:platypus:SICS:autoaligner:reflect_down /N=t_reflect_down
	
	omega = str2num(angler_listwave[angle][1])
	t_angle = angle
	t_height = height
	next_step = "height"
	step = ""
	cycle = -0.5
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
End


Function autoalign_runner(s)
	STRUCT WMBackgroundStruct &s
	SVAR step = root:packages:platypus:SICS:autoaligner:step
	NVAR cycle = root:packages:platypus:SICS:autoaligner:cycle
	NVAR height = root:packages:platypus:SICS:autoaligner:height
	NVAR direct_beam_number = root:packages:platypus:SICS:autoaligner:direct_beam_number
	SVAR next_step = root:packages:platypus:SICS:autoaligner:next_step
	SVAR sztype = root:packages:platypus:SICS:autoaligner:sztype
	NVAR omega = root:packages:platypus:SICS:autoaligner:omega
	NVAR angle = root:packages:platypus:SICS:autoaligner:angle
	NVAR set_z = root:packages:platypus:SICS:autoaligner:set_z
	NVAR set_sth = root:packages:platypus:SICS:autoaligner:set_sth
	NVAR preset = root:packages:platypus:SICS:autoaligner:preset
	NVAR zspeed = root:packages:platypus:SICS:autoaligner:zspeed
	NVAR position = root:packages:platypus:SICS:autoaligner:position
	NVAR reflect_down = root:packages:platypus:SICS:autoaligner:reflect_down
	wave/t axeslist = root:packages:platypus:SICS:axeslist
	
	variable actual, offset, aas
	if(cycle == -0.5 && autoalign_status()==2)
		// first time into the background task, need to move
		angler(angle)
		wait(2)
		cycle += 0.25
		return 0
	endif
	if(cycle == -0.25 && autoalign_status()==2)
		// second time into the background task, might need to move samples via positioner
		if(numtype(position))
			// no specified position
			cycle += 0.25
			return 0			
		else
			// we have a specified position
			positioner(position)
			// wait for a couple of seconds for sample to start moving
			wait(2)
			cycle += 0.25
			return 0
		endif
	endif

	// ready to do height/angle scan
	if(autoalign_status()==2 && cycle < 2 && cmpstr(step, "fpx"))
		strswitch(next_step)
			case "height":
			    print "Cycle ", cycle, ": starting DYNSKAN"
				if(dynskan(sztype, height, zspeed, 31, automatic=1))
					print "Problem with dynskan (autoalign)"
				endif
				cycle += 0.5
				step = "height"
				next_step = "fpx"
				return 0
				break
			case "fpx":
				// desired location for the sztype motor we've just moved
				nvar desired_location = root:packages:platypus:data:dynskan:desired_location
				variable sztype_pos = getpos(sztype)
				variable pos_difference = abs(sztype_pos - desired_location)
				// z precision of motor
				variable zprecision = 0.015
				findvalue/z/text=sztype axeslist
				if(v_value != -1)
					zprecision = str2num(axeslist[v_row][10])	
				endif			

				if(numtype(pos_difference) || pos_difference > zprecision)
				    print "Can't start fpx just yet, ", sztype, " isn't within precision. Might still be moving (autoalign)"
					return 0
				endif
				
			    print "Cycle ", cycle, ": starting fpx"
				if(fpx("dummy_motor", 1, 1, mode="time", preset=preset, savetype=1, automatic=2))
					print "Problem with fpx (autoalign)"
				endif
				cycle += 0.5
				step = "fpx"
				next_step = "height"
				return 0
				break
		endswitch
	endif
	// you've done an fpx scan, so now you need to analyse it.
	if(autoalign_status()==2 && mod(cycle, 1)==0 && !cmpstr(step, "fpx"))
		print "autoalign: calculating angle"
		actual = wottpy(NaN, direct_beam_number)
		if(numtype(actual))
			// problem with figuring out angle
			print "Problem with autoaligning"
			appendstatemon("ERROR_AUTOALIGN")
			vslits(0,0,0,0)
			autoalign_stop()
			return 1 
		endif
		if(reflect_down != 0)
			actual *= -1		
		endif
		offset = omega - actual
		// TODO check if offset is way too high
		print "APPLYING OFFSET TO STH"
		rel("sth", offset)
		wait(2)
		step = ""
	endif
	
	// you've done two cycles of aligning
	if(autoalign_status()==2 && cycle==2)
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
	// 2 - dynskan for height
	// 3 - fpx for angle
	// 4 - sics status is not eager to execute commands, waiting, statemon
	ctrlnamedbackground autoaligner, status
	variable running = numberByKey("RUN", S_info)
	variable status = 0
	if(running)
		status = status | (2^1)
	endif
	if (dynskan_status())
	    status = status | (2^2)
	endif
	if (fpxstatus())
		status = status | (2^3)
	endif
	SVAR sicsstate = root:packages:platypus:SICS:sicsstatus
	if (cmpstr(sicsstate, "Eager to execute commands"))
		status = status | (2^4)
	endif
	if (statemonstatus("DYNSKAN"))
		status = status | (2^4)
	endif
	if (waitstatus())
		status = status | (2^4)
	endif
	if (statemonstatus("om2th"))
		status = status | (2^4)
	endif
	return status
End


Function autoalign_stop()
    statemonclear("autoalign")
    print "Finished", Secs2Date(DateTime,-2), Secs2Time(DateTime,3)
   	print "================================"
    ctrlnamedBackground autoaligner, stop=1
End
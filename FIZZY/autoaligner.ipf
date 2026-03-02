#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function autoalign(angle, direct_beam_number, height, [set_z, set_sth, sztype, preset, position])
    variable angle, direct_beam_number, height, set_z, set_sth
	string sztype
	variable preset, position
	
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
	variable/g root:packages:platypus:SICS:autoaligner:position /N=t_position
		
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
	NVAR position = root:packages:platypus:SICS:autoaligner:position
	
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
				if(dynskan(sztype, height, 0.05, 31, automatic=1))
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
				if(numtype(pos_difference) || pos_difference > 0.015)
				    print "Can't start fpx just yet, ", sztype, " isn't within precision (autoalign)"
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
		offset = omega - actual
		// TODO check if offset is way too high
		print "APPLYING OFFSET TO STH"
		rel("sth", offset)
		wait(2)
		step = ""
	endif
	
	// you've done two cycles of aligning
	if(autoalign_status()==2 && cycle==2)
	
		print "TOTAL OFFSETS: ", sztype, " = ", getpos(sztype), "; sth = ", getpos("sth") - omega
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
			position_listwave[position][5] = num2str(getpos("sth") - omega)
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
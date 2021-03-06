#pragma rtGlobals=3		// Use modern global access method.

Function Pla_openStreamer(folderStr, [dataset])
	string folderStr
	variable dataset
	DFREF cDF = getdatafolderDFR()
	variable numdatasets = 0, fileID, numevents
	string datasetsStr="", theData = "", binaryFileStr = ""
	
	//setup the datafolders
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	Newdatafolder /o root:packages:platypus:data:Reducer
	Newdatafolder /o/s root:packages:platypus:data:Reducer:streamer
	
	if(paramisdefault(dataset))
		dataset = 0
	endif
	
	try
	getfilefolderinfo/q/z folderStr
	if(v_flag)
		print "ERROR streaming datafolder doesn't exist (Pla_openStreamer)"
		setdatafolder cDF
		abort 
	endif
	Newpath/o/q/z Pla_openstreamer, folderStr

	datasetsStr = indexedDir(Pla_openstreamer, -1, 0)
	numdatasets = itemsinlist(datasetsStr)
	
	if(dataset < 0 || dataset > numdatasets - 1)
		print "ERROR dataset number must be 0 < n < ", numdatasets - 1
		setdatafolder cDF
		return 1
	endif	
	
	//load in the entire file
	binaryFileStr = folderStr + ":DATASET_" + num2istr(dataset) + ":EOS.bin"
	//print binaryFileStr
	
	//try opening it first with the neutron unpacker
	#if exists("neutronunpacker")
		print binaryfileStr
		neutronunpacker binaryFileStr
	#else
		setdatafolder cDF
		return 1
	#endif
	if(!V_flag)	// it was PACKEDBIN
		setdatafolder cDF
		return 0
	endif
	
	//if it's not PACKEDBIN, it may be ZIPUNPACKEDBIN, which is the format we first used
	open/r/z fileID as binaryFileStr
	if(fileID < 1)
		print "ERROR, couldn't open file (Pla_openstreamer)"
		setdatafolder CDF
		return 1
	endif
	fstatus fileID
	theData = padstring(theData, V_logEOF, 0)
	fbinread fileID, theData
	
	//now unzip it and put into a 32 bit unsigned integer wave
	theData = zipDecode(theData)
	if(strlen(theData) == 0 || numtype(strlen(thedata)))
		print "ERROR whilst opening stream file (Pla_openstreamer)"
		setdatafolder cDF
		return 1	
	endif
	Sockitstringtowave 64+32, theData
	Wave W_stringtowave
	
	//get rid of the data in the input string (free's memory?)
	theData = ""
	
	//get rid of the 128 byte, 32 integer header header 
	deletepoints 0, 32, W_stringtowave
	
	//now distribute into event histograms
	numevents = numpnts(W_stringtowave) / 4
	make/o/n=(numevents)/Y=(64+32) W_unpackedneutronst, W_unpackedneutronsf
	multithread W_unpackedneutronst = W_stringtowave[4*p + 1] / 1000
	multithread W_unpackedneutronsf = W_stringtowave[4*p + 2]
		
    redimension/E=1/W/N=(numevents * 4 * 2) W_stringtowave;
    make/O/W/N=(numevents) W_unpackedneutronsx, W_unpackedneutronsy
    multithread W_unpackedneutronsx = W_stringtowave[8 * p + 0];
    multithread W_unpackedneutronsy = W_stringtowave[8 * p + 1];
       
       killwaves W_stringtowave
	catch
		 close fileID
	endtry
	
	close fileID
	setdatafolder cDF
	return 0
End

Function/wave Pla_streamedDetectorImage(xbins, ybins, tbins, frameFrequency, slicebins, totaltime)
	//they should be monotonically sorted histogram edges for x, y and t.
	//produces a wave root:packages:platypus:data:Reducer:streamer:Detector[slice][t][y][x]
	Wave xbins, ybins, tbins
	//how many frames per sec
	variable framefrequency
	Wave slicebins
	variable totalTime

	variable numevents, period, ii, totalEvents, numTimeSlices
	variable numxbins, numtbins, numybins, val, cutoff
	string cDF, timeEachSliceStr
	
	cDF = getdatafolder(1)
	//setup the datafolders
	Setdatafolder root:packages:platypus:data:Reducer:streamer
	
	//the frames will be sorted in time, so one can only do the events in the duration period.
	period = 1 / framefrequency

	Wave W_unpackedNeutronsF, W_unpackedNeutronsx, W_unpackedNeutronsy, W_unpackedNeutronst, W_unpackedneutronsV
	
	duplicate/free slicebins, tempSlicebins
	val = binarySearchInterp(tempSlicebins, totalTime)
	if(!numtype(val))
		deletepoints ceil(val) + 1, numpnts(tempslicebins), tempSlicebins
		tempSlicebins[numpnts(tempslicebins) - 1] = totalTime
	endif

	numTimeSlices = dimsize(tempslicebins, 0) - 1
	
	numxbins = dimsize(xbins, 0) - 1
	numybins = dimsize(ybins, 0) - 1
	numtbins = dimsize(tbins, 0) - 1
	//make the detector image
	killwaves/z detector
	make/n=(numTimeSlices * numtbins * numybins * numxbins)/O detector
	make/n=(numtimeslices)/d/free timeEachSlice
	detector = 0
	
	timeEachSlice = (tempslicebins[p+1] - tempslicebins[p]) / totalTime
	
	//lets remove the events after the slicebin finish
	cutoff = binarysearch(W_unpackedneutronsF, slicebins[numpnts(slicebins) - 1] / period)
	if(cutoff >= 0)
		print W_unpackedneutronsF[cutoff]
		deletepoints cutoff - 2,  dimsize(W_unpackedneutronsF, 0), W_unpackedneutronsF, W_unpackedneutronsY, W_unpackedneutronsX, W_unpackedneutronsT, W_unpackedneutronsV
	endif
	
	numevents = dimsize(W_unpackedNeutronsy, 0)
	
	make/n=(numevents)/free/i xpos, ypos, tpos, slicepos, eventpos
	 xpos = binarysearch(xbins, W_unpackedNeutronsX[p])
	multithread ypos = binarysearch(ybins, W_unpackedNeutronsY[p])
	multithread tpos = binarysearch(tbins, W_unpackedNeutronst[p])
	multithread slicepos = binarysearch(tempslicebins, W_unpackedNeutronsF[p] * period)
	
	multithread xpos = xpos[p] == numxbins ? xpos[p] - 1 : xpos[p]
	multithread ypos = ypos[p] == numybins ? ypos[p] - 1 : ypos[p]
	multithread tpos = tpos[p] == numtbins ? tpos[p] - 1 : tpos[p]
	multithread slicepos = slicepos[p] == numtimeslices ? slicepos[p] - 1 : slicepos[p]
	
	variable t0 = (numtimeslices) 
	variable t1 = (numtimeslices * numtbins)
	variable t2 = (numtimeslices * numtbins * numybins)
	
	multithread eventpos = slicepos + tpos * t0 + ypos * t1 + xpos * t2
	histogram/B={0,1, numpnts(detector)} eventpos, detector
	redimension/n=(numTimeSlices, numtbins, numybins, numxbins) detector
	sockitwavetostring/TXT="," timeeachslice, timeeachslicestr
	Note/k detector, "Events:"+num2istr(totalEvents)+";TIME:"+timeeachslicestr
	killwaves/z W_unpackedNeutronsF, W_unpackedNeutronsx, W_unpackedNeutronsy, W_unpackedNeutronst
	setdatafolder $cDF
	return detector
End

Function streamer_test()
	Wave xbins, ybins, tbins
	variable timer = startmstimer
	Pla_openStreamer("faffmatic:Users:andrew:Documents:Andy:Motofit:motofit:tests:SLIM:DAQ_2010-12-17T13-13-30")	
//	Pla_streamedDetectorImage(xbins, ybins, tbins, 20, 10)
	print stopmstimer(timer) /1e6
End
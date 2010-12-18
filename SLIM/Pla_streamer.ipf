#pragma rtGlobals=3		// Use modern global access method.

Function Pla_openStreamer(folderStr, [dataset])
	string folderStr
	variable dataset
	
	variable numdatasets = 0, fileID, numevents
	string cDF, datasetsStr="", theData = "", binaryFileStr = ""
	
	cDF = getdatafolder(1)
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
		abort 
	endif
	Newpath/o/q/z Pla_openstreamer, folderStr

	datasetsStr = indexedDir(Pla_openstreamer, -1, 0)
	numdatasets = itemsinlist(datasetsStr)
	
	if(dataset < 0 || dataset > numdatasets - 1)
		print "ERROR dataset number must be 0 < n < ", numdatasets - 1
		abort
	endif	
	
	//load in the entire file
	binaryFileStr = folderStr + ":Dataset_" + num2istr(dataset) + ":EOS.bin"
	open/r/z fileID as binaryFileStr
	if(fileID < 1)
		print "ERROR, couldn't open file (Pla_openstreamer)"
		abort
	endif
	fstatus fileID
	theData = padstring(theData, V_logEOF, 0)
	fbinread fileID, theData
	
	//now unzip it and put into a 32 bit unsigned integer wave
	theData = zipDecode(theData)
	if(strlen(theData) == 0)
		print "ERROR whilst opening stream file (Pla_openstreamer)"
		abort	
	endif
	Sockitstringtowave 64+32, theData
	Wave W_stringtowave
	
	//get rid of the data in the input string (free's memory?)
	theData = ""
	
	//get rid of the 128 byte, 32 integer header header 
	deletepoints 0, 32, W_stringtowave
	
	//now distribute into event histograms
	numevents = numpnts(W_stringtowave) / 4
	make/o/n=(numevents)/Y=(64+32) tt, ff
	multithread tt = W_stringtowave[4*p + 1]
	multithread ff = W_stringtowave[4*p + 2]
		
       redimension/E=1/W/N=(numevents * 4 * 2) W_stringtowave;
       make/O/W/N=(numevents) xx, yy;
       multithread xx = W_stringtowave[8 * p + 0];
       multithread yy = W_stringtowave[8 * p + 1];
       
       killwaves W_stringtowave
	catch
		 close fileID
	
	endtry
	
	close fileID
	setdatafolder $cDF
End

Function Pla_streamedDetectorImage(xbins, ybins, tbins, frameFrequency, numTimeSlices)
	//they should be monotonically sorted histogram edges for x, y and t.
	Wave xbins, ybins, tbins
	//how many frames per sec
	variable framefrequency, numTimeSlices

	variable numevents, period, ii, xpos, ypos, tpos, slicepos, totalEvents, totalTime, timeSliceDuration
	variable numxbins, numtbins, numybins
	string cDF
	cDF = getdatafolder(1)
	//setup the datafolders
	Setdatafolder root:packages:platypus:data:Reducer:streamer
	
	//the frames will be sorted in time, so one can only do the events in the duration period.
	period = 1 / framefrequency

	Wave xx, yy, tt, ff

	totalTime = (ff[dimsize(ff, 0) - 1] + 1) * period
	numxbins = dimsize(xbins, 0) - 1
	numybins = dimsize(ybins, 0) - 1
	numtbins = dimsize(tbins, 0) - 1
	//make the detector image
	make/n=(numTimeSlices, numtbins, numybins, numxbins)/I/U/O detector
	detector = 0
	
	timeSliceDuration = totalTime / numTimeSlices

	make/o/n=(numTimeSlices + 1)/free slicebins
	slicebins = p * timesliceduration * framefrequency
	
	numevents = dimsize(yy, 0)
	for(ii = 0 ; ii < numevents ; ii += 1)
		xpos = binarysearch(xbins, xx[ii])
		if(xpos >= 0)
			slicepos = binarysearch(slicebins, ff[ii])
			ypos = binarysearch(ybins, yy[ii])
			tpos = binarysearch(tbins, tt[ii])
			if(xpos == numxbins )
				xpos -= 1
			endif
			if(ypos == numybins )
				ypos -= 1
			endif
			if(tpos == numtbins )
				tpos -= 1
			endif
			if(slicepos == numTimeSlices )
				slicepos -= 1
			endif
			
			if(tpos >= 0 && ypos >= 0 && slicepos >= 0)
				detector[slicepos][tpos][ypos][xpos] += 1
				totalEvents += 1
			endif
		endif
	endfor
	Note/k detector, "Events:"+num2istr(totalEvents)
	
	killwaves/z xx, yy, tt, ff
	setdatafolder $cDF
End

Function streamer_test()
	Wave xbins, ybins, tbins
	variable timer = startmstimer
	Pla_openStreamer("faffmatic:Users:andrew:Documents:Andy:Motofit:motofit:tests:SLIM:DAQ_2010-12-17T13-13-30")	
	Pla_streamedDetectorImage(xbins, ybins, tbins, 20, 10)
	print stopmstimer(timer) /1e6
End
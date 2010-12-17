#pragma rtGlobals=1		// Use modern global access method.

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

Structure Pla_timePeriod
variable start_time
variable end_time
Endstructure

Function Pla_streamedDetectorImage(xbins, ybins, tbins, frameFrequency, duration)
	//they should be monotonically sorted histogram edges for x, y and t.
	Wave xbins, ybins, tbins
	//how many frames per sec
	variable framefrequency
	//what time period do you want to select
	Struct Pla_timePeriod &duration

	variable numevents, period, startPoint, endPoint, ii, xpos, ypos, tpos, timeProportion, totalEvents, totalTime
	string cDF
	cDF = getdatafolder(1)
	//setup the datafolders
	Setdatafolder root:packages:platypus:data:Reducer:streamer
	
	Wave xx, yy, tt, ff
	make/n=(1, dimsize(tbins, 0) - 1, dimsize(ybins, 0) - 1, dimsize(xbins, 0) - 1)/I/U/O hmm
	hmm=0
	//the frames will be sorted in time, so one can only do the events in the duration period.
	period = 1/framefrequency
	
	if(!numtype(duration.start_time))
		startPoint = round(binarysearchinterp(ff, duration.start_time * period))
	else
		startPoint = 0
	endif
	
	if(!numtype(duration.end_time))
		endPoint = round(binarysearchinterp(ff, duration.end_time * period))
	else
		endPoint = dimsize(xx, 0)
	endif
	timeProportion = (endPoint-StartPoint) / dimsize(xx, 0)
	totalTime = ff[dimsize(ff, 0) - 1] * period
	
	for(ii = startPoint ; ii < endPoint ; ii += 1)
		xpos = binarysearch(xbins, xx[ii])
		if(xpos > 0)
			ypos = binarysearch(ybins, yy[ii])
			tpos = binarysearch(tbins, tt[ii])
			if(tpos > 0 && ypos > 0 )
				hmm[0][tpos][ypos][xpos] += 1
				totalEvents += 1
			endif
		endif
	endfor
	Note/k hmm, "Events:"+num2istr(totalEvents) + ";timeProportion:" + num2str(timeProportion) + ";time:" + num2str(totalTime)
	
	setdatafolder $cDF
End

Function streamer_test()
	Struct Pla_timePeriod duration
	duration.start_time = inf
	duration.end_time = inf
	Wave xbins, ybins, tbins
	variable timer = startmstimer
	Pla_openStreamer("foobar:Users:anz:Desktop:kinetic_test:DAQ_2010-12-17T13-13-30")	
	Pla_streamedDetectorImage(xbins, ybins, tbins, 20, duration)
	print stopmstimer(timer) /1e6
End
#pragma rtGlobals=3		// Use modern global access method.
#include <Image Line Profile>

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$

Menu "Platypus"
	Submenu "SLIM"
		"Reduction", reducerpanel()
		"Download Platypus Data", downloadPlatypusData()
		"Download DAQ Streamed File", grabStreamFromCatalogue()
		"MADD - Add files together", addFilesTogether()
		"Delete points from reduced files", delReducedPoints()
	End
	"Reduce X'Pert Pro data files", reduceManyXrayFiles()
End

Function addFilesTogether()
	Doalert 1, "Are you aware that all the files need to have been measured under the SAME conditions, otherwise this is rubbish?"
	if(V_Flag==2)
		return 1
	endif
	variable refnum
	open/MULT=1/r/d/M="Please select the files you would like to add together"/F="HDF files:.hdf" refnum

	if(!strlen(S_filename))
		return 1
	endif
	string filenames = ""
	variable ii

	string pathSep, outputPathStr
	strswitch(UpperStr(IgorInfo(2)))
		case "MACINTOSH":
			pathSep = ":"
			break
		case "WINDOWS":
			pathSep = "\\"
			break
	endswitch
										
	outputPathStr = Parsefilepath(1, Stringfromlist(0, S_filename, "\r"), pathSep, 1, 0)
	for(ii=0 ; ii<itemsinlist(S_filename, "\r"); ii+=1)
		filenames += Parsefilepath(0, Stringfromlist(ii, S_filename, "\r"), pathSep, 1, 0)+";"
	endfor
	madd(outputPathStr, filenames)
End

Function grabStreamFromCatalogue()
	Wave/t/z runlist = root:packages:platypus:catalogue:runlist
	if(!waveexists(runlist))
		Doalert 0, "Please catalogue the HDF files first"
		return 1
	endif
	make/n=(dimsize(runlist, 0))/free/t DAQ
	DAQ[] = runlist[p][%DAQ_FILENAME]
	string dirnames = ""
	Sockitwavetostring/TXT=";" DAQ, dirnames
	downloadPlatypusStreamedFile(dirnames)
End

Function downloadPlatypusStreamedFile(DAQfileListStr[, inputPathStr])
	string DAQfileListStr, inputPathStr
	string user="", password="", folder, data = "", datasetFolderStr = "", DAQfileStr = "", URL = ""
	variable ii, fileID, jj, outsideAnsto = 1
	
	if(paramisdefault(inputPathStr))
		newpath/o/c/q/z/M="Where would you like to store your Platypus data?" PLA_temppath_dPD
		if(V_Flag)
			abort
		endif
		pathinfo PLA_temppath_dPD
		inputpathstr = S_path
		killpath/z PLA_temppath_dPD
	else
		getfilefolderinfo/z/q inputpathStr
		if(V_flag)
			Doalert 0, "The path where you wanted to save is not valid (downloadPlatypusData)"
			abort
		endif
	endif
				
	for(;;)
		prompt user, "User name"
		prompt password, "Password"
		prompt outsideAnsto, "Are you on the ANSTO network?", popup, "Yes;No"
		Doprompt "Enter your credentials for scp.nbi.ansto.gov.au", user, password, outsideAnsto
		if(V_Flag)
			return 1
		else
			break
		endif
	endfor
	outsideAnsto -= 1
	if(outsideAnsto)
		URL = "sftp://scp.nbi.ansto.gov.au/experiments/platypus/hsdata/"
	else
		URL = "sftp://custard.nbi.ansto.gov.au/experiments/platypus/hsdata/"
	endif
	
	for(jj = 0 ; jj < itemsinlist(DAQfileListStr) ; jj += 1)
		//create the folder in the input directory
		DAQfilestr = stringfromlist(jj, DAQfileListStr)
		if(!strlen(DAQfileStr))
			continue
		endif
		folder = S_path + DAQfileStr + ":"
		newpath/c/o/q/z PLA_temppath_dPD, folder
		killpath/z PLA_temppath_dPD
	
		print "Starting to download Platypus data."
		easyHttp/PROX=""/PASS=user+":"+password/FILE=folder + "CFG.xml" URL + DAQfileStr + "/CFG.xml"
		if(V_Flag)
			print "Error while downloading Platypus data (downloadPlatypusStreamedFile)"
			return 1
		endif
		//get the datasets
		ii = 0
		do	
			//try getting the file
			easyHttp/PROX=""/PASS=user+":"+password URL + DAQfileStr + "/DATASET_" + num2istr(ii) + "/EOS.bin", data
			if(V_flag)
				break
			endif
			datasetFolderStr = folder + "DATASET_" + num2istr(ii)
			newpath/c/o/q/z PLA_temppath_dPD, datasetFolderStr
			open fileID as datasetfolderStr + ":EOS.bin"
			fbinwrite fileID, data
			close fileID
			ii+=1
		while(!V_Flag)
		killpath/z PLA_temppath_dPD
		print "Got ", DAQfileStr
	endfor
	print "Finished downloading Platypus data."
End

Function builddirectorylist(user, password, lowFi, hiFi,  [outsideANSTO])
	string user, password
	variable lowFi, hiFi, outsideANSTO
	string data = "", direct, files, file, a, b, c, URL="", stopfile
	variable ii, isdirectory, jj, lowf = inf, hif = -inf, startDir
	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:catalogue
	
	sprintf stopfile, "PLP%07d.nx.hdf", lowfi

	if(outsideANSTO)
		URL = "sftp://scp.nbi.ansto.gov.au/experiments/platypus/data/"
	else
		URL = "sftp://custard.nbi.ansto.gov.au/experiments/platypus/data/"
	endif

	make/o/t/n=(0, 2) root:packages:platypus:catalogue:directories/Wave=directories
	easyHttp/TIME=5/PROX=""/PASS=USER + ":"+PASSWORD URL + "cycle/", data
	if(V_Flag)
		return 1
	endif
	data = replacestring("\n", data, "\r")

	for(ii = 2 ; ii < itemsinlist(data, "\r") ; ii += 1)
		direct = parseDirectorylistline(stringfromlist(ii, data, "\r"), isdirectory)
		if(isdirectory)
			redimension/n=(dimsize(directories, 0) + 1, -1) directories
			directories[dimsize(directories, 0) - 1][0] = "cycle/" + direct + "/"
		endif
	endfor
	
	Pla_catalogue#MDsort(directories, 0, reversed=1)
	insertpoints 0, 1, directories
	directories[0][0] = "current/"

	startDir = 0
	for(ii = startDir ; ii < dimsize(directories, 0) ; ii += 1)
		direct = directories[ii][0]
		easyHttp/TIME=5/PROX=""/PASS=USER + ":"+PASSWORD URL + direct, files
		if(V_Flag)
			return 1
		endif
		files = replacestring("\n", files, "\r")
		lowf = inf
		hif = -inf
		for(jj = 2 ; jj < itemsinlist(files, "\r") ; jj += 1)
			file = parseDirectoryListLine(stringfromlist(jj, files, "\r"), isdirectory)
			if(grepstring(file, "PLP[[:digit:]]{7}.nx.hdf"))
				directories[ii][1] += file + ";"
			endif
		endfor
		if(grepstring(directories[ii][1], stopfile))
			return 0
		endif
	endfor
End

Function/s parseDirectoryListLine(directoryline, isdirectory)
	string directoryline
	variable &isdirectory
 
	//directoryline = " dr-xr-xr-x 2 1 1  45056 Jan 6 20:11 q02ee8dddds"
	string a, b, c,d,e,f,g,h,i, j,k,l,m,n,o,p,q
	//perm
	string regex="([dwrx-]+)"
	//u
	regex+="(\\s)+"
	regex+="([[:alnum:][:punct:]]+)"
	//g
	regex+="(\\s)+"
	regex+="([[:alnum:][:punct:]]+)"
	//o
	regex+="(\\s)+"
	regex+="([[:alnum:][:punct:]]+)"
 
	//size
	regex+="(\\s)+"
	regex+="([[:digit:]]+)"
 
	//month
	regex+="(\\s)+"
	regex+="([[:alpha:]]{3})"
 
	//day
	regex+="(\\s)+"
	regex+="([[:digit:]]{1,2})"
 
	//time or year 00:00 or 2010
	regex+="(\\s)+"
	regex+="([[:digit:]:]{4,5})"
 
	//filename/directory
	regex+="(\\s)+"
	regex+="(.+)$"
	splitstring/E=regex directoryline, a, b, c,d,e,f,g,h,i,j,k,l,m,n,o,p,q
 
	a = replacestring(" ", a, "")
	if(stringmatch(a[0], "d"))
		isdirectory = 1
	else
		isdirectory = 0
	endif
	return q
End

Function downloadPlatypusData([inputPathStr, lowFi, hiFi])
	string inputPathStr
	variable lowFi, hiFi
	string user= "", password="", fname, direct, url
	variable ii, col, row, rowsinwave, outsideANSTO
	if(paramisdefault(inputPathStr))
		newpath/o/c/q/z/M="Where would you like to store your Platypus data?" PLA_temppath_dPD
		if(V_Flag)
			abort
		endif
		pathinfo PLA_temppath_dPD
		inputpathstr = S_path
		killpath/z PLA_temppath_dPD
	else
		getfilefolderinfo/z/q inputpathStr
		if(V_flag)
			Doalert 0, "The path where you wanted to save is not valid (downloadPlatypusData)"
			abort
		endif
	endif
					
	for(;;)
		prompt lowFi, "start file"
		prompt hiFI, "end file"
		prompt user, "User name"
		prompt password, "Password"
		prompt outsideANSTO, "Are you inside ANSTO?", popup, "Yes;No"
		Doprompt "Enter your credentials for nbi.ansto.gov.au", user, password, outsideANSTO, lowFi, hiFi
		if(V_Flag)
			return 1
		endif
		if(numtype(lowFi) || Numtype(hiFi) || lowFi <1 || hiFi >9999999 || lowFi>hiFi)
			print "Please enter reasonable numbers for the requested files"
		else
			break
		endif
		
	endfor
	outsideANSTO -= 1
	
	if(outsideANSTO)
		url = "sftp://scp.nbi.ansto.gov.au/experiments/platypus/data/"
	else
		url = "sftp://custard.nbi.ansto.gov.au/experiments/platypus/data/"
	endif
	
	if(builddirectorylist(user, password, lowFi, hiFi, outsideANSTO = outsideANSTO))
		abort "problem building remote directory list"
	endif
	Wave/t directory = root:packages:platypus:catalogue:directories
	//see if the file exists in the directory list.  If it does, download it.
	
	make/free/i/n=(hiFi-lowFi) filenumbers, succeeded
	filenumbers = p + lowFi
	
	multithread succeeded[] = downloader(url, directory, inputpathstr, user + ":" + password, filenumbers[p])
End

Threadsafe Function downloader(url, directory, inputpathstr, userpasscombo, fnumber)
	string url
	wave/t directory
	string inputpathStr, userpasscombo
	variable fnumber

	variable row, col, rowsinwave
	string fname, direct

	sprintf fname, "PLP%07d.nx.hdf", fnumber
	findvalue/TEXT=fname directory
	if(V_Value == -1)
		return 0
	endif
	rowsinwave = dimsize(directory, 0)
	col=floor(V_value / rowsInWave)
	row=V_value-col*rowsInWave
	direct = directory[row][0]
	
	easyHttp/PROX=""/PASS=userpasscombo/File=inputpathStr + fname  url + direct + fname
	print "Got", fname
	return 0
End

Function  reducerpanel() : Panel
	PauseUpdate; Silent 1		// building window...
	Dowindow/k SLIM
	NewPanel /W=(384,163,1085,607)/N=SLIM/k=1 as "SLIM - (C) Andrew Nelson 2009"
	
	
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	//directory for the reduction package
	Newdatafolder /o root:packages:platypus:data:Reducer
	
	make/n=(100,10)/o root:packages:platypus:data:Reducer:angledata_sel
	make/n=(100,10)/o/t root:packages:platypus:data:Reducer:angledata_list
	string/g root:packages:platypus:data:Reducer:inputpathStr
	string/g root:packages:platypus:data:Reducer:outputpathStr
	
	variable/g root:packages:platypus:data:Reducer:lowLambda=2.8
	variable/g root:packages:platypus:data:Reducer:highLambda=18
	variable/g root:packages:platypus:data:Reducer:expected_centre=ROUGH_BEAM_POSITION
	variable/g root:packages:platypus:data:Reducer:rebinpercent=5
	variable/g root:packages:platypus:data:Reducer:backgroundsbn=1
	variable/g root:packages:platypus:data:Reducer:manualbeamfind=0
	variable/g root:packages:platypus:data:Reducer:normalisebymonitor=1
	variable/g root:packages:platypus:data:Reducer:saveSpectrum=0
	variable/g root:packages:platypus:data:Reducer:saveoffspec=0
	variable/g root:packages:platypus:data:Reducer:streamedReduction= 0
		
	SVAR inputpathStr = root:packages:platypus:data:Reducer:inputpathStr
	SVAR outputpathStr = root:packages:platypus:data:Reducer:outputpathStr
	
	Wave/t angledata_list = root:packages:platypus:data:Reducer:angledata_list
	Wave angledata_sel= root:packages:platypus:data:Reducer:angledata_sel
	setdimlabel 1,0,reduce,angledata_list
	setdimlabel 1,1,dontoverwrite,angledata_list
	setdimlabel 1,2,scalefactor,angledata_list
	setdimlabel 1,3,reflectangle1,angledata_list
	setdimlabel 1,4,reflectangle2,angledata_list
	setdimlabel 1,5,reflectangle3,angledata_list
	setdimlabel 1,6,directangle1,angledata_list
	setdimlabel 1,7,directangle2,angledata_list
	setdimlabel 1,8,directangle3,angledata_list
	setdimlabel 1,9,waterrun,angledata_list

	angledata_sel=0x02
	angledata_sel[][0] = 2^5
	angledata_sel[][1] = 2^5
	
	ListBox whichangles,pos={13,77},size={677,353}, widths = {7,11,12}
	ListBox whichangles,listWave=root:packages:platypus:data:Reducer:angledata_list
	ListBox whichangles,selWave=root:packages:platypus:data:Reducer:angledata_sel
	ListBox whichangles,mode= 6,editStyle= 2,proc=SLIM_listproc
	Button reduce_tab0,pos={14,3},size={260,22},proc=SLIM_buttonproc,title="Reduce"
	Button reduce_tab0,labelBack=(1,52428,26586),font="Arial",fColor=(1,4,52428)
	Button plot_tab0,pos={14,30},size={260,22},proc=SLIM_buttonproc,title="Plot"
	Button plot_tab0,labelBack=(1,52428,26586),font="Arial",fColor=(52224,0,0)
	
	SetVariable dataSource_tab0,pos={288,10},size={326,16},title="Data directory"
	SetVariable dataSource_tab0,fSize=10
	SetVariable dataSource_tab0,value= root:packages:platypus:data:Reducer:inputpathStr,noedit= 1
	SetVariable dataOut_tab0,pos={288,30},size={326,16},title="Output directory"
	SetVariable dataOut_tab0,fSize=10
	SetVariable dataOut_tab0,value= root:packages:platypus:data:Reducer:outputpathStr,noedit= 1
	
	//	checkbox rebinning_tab0,pos={574,30},title="rebin?",fsize=10
	Button showreducervariables_tab0,pos={348,52},size={152,16},proc=SLIM_buttonproc,title="show reducer variables"
	Button showreducervariables_tab0,fSize=9

	Button changedatasource_tab0,pos={630,11},size={44,16},proc=SLIM_buttonproc,title="change"
	Button changedatasource_tab0,fSize=9
	
	Button changedataout_tab0,pos={630,31},size={44,16},proc=SLIM_buttonproc,title="change"
	Button changedataout_tab0,fSize=9


	Button downloadPlatdata_tab0,pos={518,53},size={152,16},proc=SLIM_buttonproc,title="Download Platypus data"
	Button downloadPlatdata_tab0,fSize=9
	
	Button clear_tab0,pos={99,55},size={86,17},proc=SLIM_buttonproc,title="clear"
End

Function  reducerVariablesPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	Dowindow/k SLIMvarpanel
	NewPanel /K=1 /W=(385,164,588,390)
	Dowindow/c SLIMvarpanel
	
	Newdatafolder/o root:packages
	Newdatafolder /o root:packages:platypus
	Newdatafolder /o root:packages:platypus:data
	//directory for the reduction package
	Newdatafolder /o root:packages:platypus:data:Reducer
	
	NVAR backgroundsbn = root:packages:platypus:data:Reducer:backgroundsbn
	NVAR manualbeamfind =  root:packages:platypus:data:Reducer:manualbeamfind
	NVAR normalisebymonitor = root:packages:platypus:data:Reducer:normalisebymonitor
	NVAR saveSpectrum = root:packages:platypus:data:Reducer:saveSpectrum
	NVAR saveoffspec = root:packages:platypus:data:Reducer:saveoffspec
	NVAR streamedReduction = root:packages:platypus:data:Reducer:streamedReduction
	 
	SetVariable lowLambda_tab0,pos={10,10},size={177,16},title="lowWavelength", win=SLIMvarpanel
	SetVariable lowLambda_tab0,fSize=10, win=SLIMvarpanel
	SetVariable lowLambda_tab0,limits={0.5,30,0.1},value= root:packages:platypus:data:Reducer:lowLambda, win=SLIMvarpanel
	SetVariable highLambda_tab0,pos={10,30},size={178,16},title="highWavelength", win=SLIMvarpanel
	SetVariable highLambda_tab0,fSize=10, win=SLIMvarpanel
	SetVariable highLambda_tab0,limits={0.5,30,0.1},value= root:packages:platypus:data:Reducer:highLambda, win=SLIMvarpanel
	SetVariable rebinpercent_tab0,pos={10,51},size={177,16},title="Rebin %tage ", win=SLIMvarpanel
	SetVariable rebinpercent_tab0,fSize=10, win=SLIMvarpanel
	SetVariable rebinpercent_tab0,limits={-1,11,1},value= root:packages:platypus:data:Reducer:rebinpercent, win=SLIMvarpanel
	SetVariable expected_centre_tab0,pos={8,72},size={178,16},title="expected centre", win=SLIMvarpanel
	SetVariable expected_centre_tab0,fSize=10, win=SLIMvarpanel
	SetVariable expected_centre_tab0,limits={-220,220,1},value= root:packages:platypus:data:Reducer:expected_centre, win=SLIMvarpanel
	CheckBox background_tab0,pos={9,94},size={138,14},title="background subtraction?", win=SLIMvarpanel
	CheckBox background_tab0,fSize=10,variable= root:packages:platypus:data:Reducer:backgroundsbn, win=SLIMvarpanel, value = backgroundsbn
	CheckBox manual_tab0,pos={9,115},size={109,14},title="manual beam find?", win=SLIMvarpanel, value = manualbeamfind
	CheckBox manual_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:manualbeamfind
	CheckBox normalise_tab0,pos={9,136},size={155,14},title="normalise by beam monitor?", win=SLIMvarpanel
	CheckBox normalise_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:normalisebymonitor, value = normalisebymonitor
	CheckBox saveSpectrum_tab0,pos={9,157},size={94,14},title="save spectrum?", win=SLIMvarpanel
	CheckBox saveSpectrum_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:saveSpectrum, value = saveSpectrum
	CheckBox saveoffspec_tab0,pos={9,178},size={94,14},title="save offspecular map?", win=SLIMvarpanel
	CheckBox saveoffspec_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:saveoffspec, value =  saveoffspec
	CheckBox streamedreduction_tab0,pos={9,199},size={94,14},title="do streamed reduction?", win=SLIMvarpanel
	CheckBox streamedreduction_tab0,fSize=10, win=SLIMvarpanel, variable = root:packages:platypus:data:Reducer:streamedReduction, value =  streamedReduction
End

Function SLIM_listproc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string filenames = ""
	SVAR inputpathStr = root:packages:platypus:data:Reducer:inputpathStr

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 4:
			if(lba.eventmod==17 && col > 0)		
				GetFileFolderInfo/q/z inputpathStr
				if(V_flag)//path doesn't exist
					Doalert 0, "Please enter a valid filepath for the data source"
					return 0	
				endif
				
				newpath/o/q/z pla_temppath_SLIM_listproc, inputpathStr	
				filenames = indexedfile(pla_temppath_SLIM_listproc, -1, ".hdf")	
				filenames = sortlist(filenames,";",17)
				killpath/z pla_temppath_SLIM_listproc
				popupcontextualmenu "-Filldown-;"+filenames
				switch(V_Flag)
					case 1:
						variable ii
						for(ii=row+1 ; ii<dimsize(listWave,0) && strlen(listWave[ii][col])==0 ; ii+=1)
							listwave[ii][col] = listwave[ii-1][col]
						endfor
						break
					default:
						lba.listwave[row][col]=removeending(S_Selection,".nx.hdf")
						break
				endswitch
			endif
			break		
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
	endswitch

	return 0
End


Function SLIM_buttonproc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	//this button handler deals with all button press events in the SLIM button window
	string cDF = getdatafolder(1)

	switch( ba.eventCode )
		case 2: // mouse up
			
			// click code here
			NVAR lowLambda = root:packages:platypus:data:Reducer:lowLambda
			NVAR highLambda = root:packages:platypus:data:Reducer:highLambda
			Wave/t angledata_list = root:packages:platypus:data:Reducer:angledata_list
			Wave angledata_sel= root:packages:platypus:data:Reducer:angledata_sel
			SVAR inputpathStr = root:packages:platypus:data:Reducer:inputpathStr
			SVAR outputpathStr = root:packages:platypus:data:Reducer:outputpathStr
			NVAR expected_centre = root:packages:platypus:data:Reducer:expected_centre
			NVAR rebinpercent = root:packages:platypus:data:Reducer:rebinpercent
			NVAR backgroundsbn =  root:packages:platypus:data:Reducer:backgroundsbn
			NVAR manualbeamfind =  root:packages:platypus:data:Reducer:manualbeamfind
			NVAR normalisebymonitor = root:packages:platypus:data:Reducer:normalisebymonitor
			NVAR saveSpectrum =  root:packages:platypus:data:Reducer:saveSpectrum
			NVAR saveoffspec =  root:packages:platypus:data:Reducer:saveoffspec
			NVAR/z streamedReduction = root:packages:platypus:data:Reducer:streamedReduction

			variable rebinning,ii,jj, dontoverwrite = 0, temp, maxtime, mintime
			string tempDF,filenames, water = ""
			string fileNameList="", righteousFileName = "", fileFilterStr = ""
			string cmd, template

			strswitch(ba.ctrlname)
				case "reduce_tab0":
					GetFileFolderInfo/q/z inputpathStr
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath for the data source"
						return 0	
					endif
					GetFileFolderInfo/q/z outputpathStr
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath for the output files"
						return 0	
					endif
					if(streamedReduction)
							prompt temp, "time each bin (s)"
							prompt maxtime, "ending time (s)"
							prompt mintime, "starting time (s)"
							maxtime = 3600
							mintime = 0
							temp = 60
							Doprompt "What timescales did you want for the streamed reduction?", mintime, maxtime, temp
							if(V_flag)
								abort
							endif
							streamedReduction = temp
							
							make/n=(ceil((maxtime - mintime) / temp) + 1)/free/d timeslices
							timeslices = temp * p + mintime
							if(timeslices[numpnts(timeslices) - 1] > maxtime)
								timeslices[numpnts(timeslices) - 1] = maxtime
							endif
							
							dontoverwrite = 1
					endif
					
					//did you want to rebin?
					rebinning = rebinpercent
										
					for(ii=0 ; ii < dimsize(angledata_list, 0) ; ii+=1)
						if(strlen(angledata_list[ii][3]) == 0 || !(angledata_sel[ii][0] & 2^4))
							continue
						endif
						if(angledata_sel[ii][1] & 2^4)
							dontoverwrite = 1
						else
							dontoverwrite = 0
						endif
						
						fileNameList = ""
						for(jj = 3 ;  strlen(angledata_list[ii][jj])>0 && jj < 6 ; jj+=1)
							if(expandStrIntoPossibleFileName(angledata_list[ii][jj], righteousFileName)) //add in the reflected beam run
								print "ERROR - file name is incorrect (SLIM_buttonproc)",  angledata_list[ii][jj];	return 1
							endif
							angledata_list[ii][jj] = righteousFileName
							fileNameList += righteousfileName+":"

							//check we have at least one direct beam run
							if(jj==3 && strlen(angledata_list[ii][6]) == 0)	
								print "ERROR we need at least one direct beam run (SLIM_buttonproc)";	return 1
							endif						
							//if no direct beam is specified, assume it's the same as the first.
							if(strlen(angledata_list[ii][jj+3]) == 0)			
								angledata_list[ii][jj+3] = angledata_list[ii][6]
							endif
							//add in the direct beam run
							if(expandStrIntoPossibleFileName(angledata_list[ii][jj+3], righteousFileName)) 
								print "ERROR - a direct beam filename is incorrect (SLIM_buttonproc)", angledata_list[ii][jj+3];	return 1
							else
								angledata_list[ii][jj+3] = righteousFileName
								fileNameList += righteousFileName + ";"
							endif
							//don't want to reduce all the angles for a line, if you are doing streamed reduction		
							if(streamedReduction)
								break
							endif	
						endfor
						//is there a water run?
						if(strlen(angledata_list[ii][9]) > 0 )
							if(expandStrIntoPossibleFileName(angledata_list[ii][9], righteousFileName)) 
								print "ERROR - the water beam filename is incorrect (SLIM_buttonproc) ", angledata_list[ii][9];	return 1
							endif
							water = righteousFileName
						endif
						
						if(numtype(str2num(angledata_list[ii][2])))
							angledata_list[ii][2] = "1"
							print "Warning setting scale factor to 1 ", angledata_list[ii][3]
						endif
						
						if(!streamedReduction)
							template =  " reduce(\"%s\",\"%s\",%s,\"%s\",%g,%g,%g,background = %g,water=\"%s\", expected_peak=cmplx(%g, NaN), manual = %g, dontoverwrite = %g, normalise = %g, saveSpectrum = %g, saveoffspec=%g)"
							sprintf cmd, template, replacestring("\\", inputpathStr, "\\\\"), replacestring("\\", outputpathStr, "\\\\"), angledata_list[ii][2], fileNameList,lowLambda,highLambda, rebinning,  backgroundsbn,water, expected_centre, manualbeamfind, dontoverwrite, normalisebymonitor, saveSpectrum, saveoffspec
							cmdToHistory(cmd)
							if(reduce(inputpathStr, outputPathStr, str2num(angledata_list[ii][2]), fileNameList,lowLambda,highLambda, rebinning, background = backgroundsbn, water = water, expected_peak = cmplx(expected_centre, NaN), manual=manualbeamfind, dontoverwrite = dontoverwrite, normalise = normalisebymonitor, saveSpectrum = saveSpectrum, saveoffspec=saveoffspec))
								print "ERROR something went wrong when calling reduce (SLIM_buttonproc)";  return 1
							endif
						else
							template =  "reduceasinglefile(\"%s\",\"%s\",%s,\"%s\",%g,%g,%g,background = %g,water=\"%s\", expected_peak=cmplx(%g, NaN), manual = %g, dontoverwrite = 1, normalise = %g, saveSpectrum = %g, saveoffspec=%g, timeslices = ??wave??)"
							sprintf cmd, template, replacestring("\\", inputpathStr, "\\\\"), replacestring("\\", outputpathStr, "\\\\"), angledata_list[ii][2], fileNameList,lowLambda,highLambda, rebinning,  backgroundsbn,water, expected_centre, manualbeamfind, normalisebymonitor, saveSpectrum, saveoffspec
							cmdToHistory(cmd)								
							if(!strlen(reduceASingleFile(inputpathStr, outputPathStr, str2num(angledata_list[ii][2]), fileNameList,lowLambda,highLambda, rebinning, background = backgroundsbn, water = water, expected_peak = cmplx(expected_centre, NaN), manual=manualbeamfind, dontoverwrite = 1, normalise = normalisebymonitor, saveSpectrum = saveSpectrum, saveoffspec=saveoffspec, timeslices=timeslices)))
								print "ERROR something went wrong when calling reduce (SLIM_buttonproc)";  return 1
							endif
						endif
						
					endfor	
					break
				case "showreducervariables_tab0":
					reducerVariablesPanel() 
					break
				case "downloadPlatdata_tab0":
					GetFileFolderInfo/q/z inputpathStr
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath to place the downloaded files"
						return 0	
					endif
					downloadplatypusdata(inputPathStr = inputPathStr)
					break
				case "plot_tab0":
					Doalert 1, "Are the files you want to view in the input directory (YES) or the output directory (NO)?"
					string thePathstring = ""
					if(V_flag == 1)
						thePathstring = inputpathStr
						fileFilterStr = "HDF files (.hdf):.hdf;XML files (.xml):.xml;ITX files (.itx):.itx;spectrum files (.spectrum):.spectrum;"
					elseif(V_flag == 2)
						thePathstring = outputpathStr
						fileFilterStr = "XML files (.xml):.xml;HDF files (.hdf):.hdf;ITX files (.itx):.itx;spectrum files (.spectrum):.spectrum;"
					endif
					
					GetFileFolderInfo/q/z thePathstring
					if(V_flag)//path doesn't exist
						Doalert 0, "Please enter a valid filepath for the data source"
						return 0	
					endif
					//did you want to rebin?
					rebinning = rebinpercent
									
					//find the files with the new multiopenfiles XOP
					Newpath/o/q/z pla_temppath_read, thePathstring
					open/MULT=1/r/P=pla_temppath_read/d/M="Select the files you wish to view"/F=fileFilterStr refnum

					killpath/z pla_temppath_read
					if(V_Flag!=0)
						return 0
					endif
						
					thePathstring = S_path
					filenames = ""

					for(ii=0 ; ii<itemsinlist(S_filename, "\r") ; ii+=1)
						filenames += ParseFilePath(0, stringfromlist(ii, S_filename, "\r"), ":", 1, 0)+";"
					endfor
					
					if(itemsinlist(filenames, "\r")==0)
						return 0
					endif
					
					sprintf cmd, "slim_plot(\"%s\",\"%s\",\"%s\",%g,%g,%g,expected_peak=cmplx(%g, %g), rebinning=%g, manual=%g, normalise=%g, saveSpectrum = %g)",inputPathStr, outputPathStr, filenames, lowLambda,highLambda, backgroundsbn,expected_centre, NaN, rebinpercent, manualbeamfind, normalisebymonitor, saveSpectrum
					cmdToHistory(cmd)
						
					if(slim_plot(thePathstring, outputPathStr, fileNames,lowLambda,highLambda,backgroundsbn, expected_peak = cmplx(expected_centre, NaN), rebinning = rebinpercent, manual = manualbeamfind, normalise = normalisebymonitor, saveSpectrum = saveSpectrum))
						print "ERROR while trying to plot (SLIM_buttonproc)"
						return 0
					endif
					break
				case "clear_tab0":
					angledata_list=""
					angledata_sel[][0] = 2^5
					angledata_sel[][1] = 2^5				
					break
				case "changedatasource_tab0":
					getfilefolderinfo/q/z=2/d ""
					if(V_flag == 0)
						inputpathStr = S_path
					endif
					break
				case "changedataout_tab0":
					getfilefolderinfo/q/z=2/d ""
					if(V_flag == 0)
						outputpathStr = S_path
					endif
					break
			endswitch	
			break
			
	endswitch
	setdatafolder $cDF
	return 0
End


Function SLIM_plot(inputpathStr, outputPathStr, fileNames,lowlambda,highLambda, background, [expected_peak, rebinning, manual, normalise, saveSpectrum])
	String inputpathStr, outputPathStr, fileNames
	variable lowlambda, highlambda, background, rebinning, manual, normalise, saveSpectrum
	variable/c expected_peak
	
	string slimplotstring = ""
	if(paramisdefault(expected_peak))
		expected_peak = cmplx(ROUGH_BEAM_POSITION, NaN)
	endif
			
	if(paramisdefault(manual))
		manual = 0
	endif
	if(paramisdefault(normalise))
		normalise = 0
	endif
	if(paramisdefault(saveSpectrum))
		saveSpectrum = 0
	endif

	GetFileFolderInfo/q/z inputPathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid input path (SLIM_plot)"
		return 1	
	endif

	variable ii
	string tempDF,tempFileNameStr
	
	for(ii=0 ; ii<itemsinlist(filenames) ; ii += 1)
		tempFileNameStr = stringfromlist(ii, fileNames)
		
		//trying to plot reduced data
		if(stringmatch(".xml",tempfilenamestr[strlen(tempfilenamestr)-4,strlen(tempfilenamestr)-1]))
			if(SLIM_plot_reduced(inputPathStr, filenames))
				print "ERROR while trying to plot reduced data (SLIM_PLOT)"
				return 1
			endif
			return 0
		endif
		
		if(stringmatch(".itx",tempfilenamestr[strlen(tempfilenamestr)-4,strlen(tempfilenamestr)-1]))
			if(SLIM_plot_scans(inputPathStr, filenames))
				print "ERROR while trying to plot reduced data (SLIM_PLOT)"
				return 1
			endif
			return 0
		endif

		if(stringmatch(".spectrum", tempfilenamestr[strlen(tempfilenamestr) - 9, strlen(tempfilenamestr) - 1]))	
			if(SLIM_plot_spectrum(inputPathStr, filenames))
				print "ERROR while trying to plot spectrum data (SLIM_PLOT)"
				return 1
			endif
			return 0
		endif
				
		if(stringmatch(".xrdml",tempfilenamestr[strlen(tempfilenamestr)-6,strlen(tempfilenamestr)-1]))	
			if(SLIM_plot_xrdml(inputPathStr, filenames))
				print "ERROR while trying to plot XRDML data (SLIM_PLOT)"
				return 1
			endif
			return 0
		endif
		
		//now try to plot NeXUS data
		if(!stringmatch(".nx.hdf", tempfilenamestr[strlen(tempfilenamestr)-7,strlen(tempfilenamestr)-1]))
			Doalert 0, "ERROR: this isn't a NeXUS file"
			return 1
		endif
		tempFileNameStr = removeending(stringfromlist(ii,fileNames),".nx.hdf")
		
		GetFileFolderInfo/q/z outputPathStr
		if(V_flag)//path doesn't exist
			print "ERROR please give valid output path as well (SLIM_plot)"
			return 1	
		endif
	
		if(paramisdefault(rebinning) || rebinning <= 0)
			if(processNeXUSfile(inputPathStr, outputPathStr, tempFileNameStr, background, lowLambda, highLambda, expected_peak=expected_peak, manual=manual, normalise = normalise, savespectrum = saveSpectrum))
				print "ERROR: problem with one of the files you are trying to open (SLIM_plot)"
				return 1
			endif
		else
			Wave W_rebinboundaries = Pla_gen_binboundaries(lowlambda, highlambda, rebinning)
			if(processNeXUSfile(inputPathStr, outputPathStr, tempFileNameStr, background, lowLambda, highLambda, expected_peak=expected_peak, rebinning=W_rebinboundaries,manual=manual, normalise = normalise, savespectrum = saveSpectrum))
				print "ERROR: problem with one of the files you are trying to open (SLIM_plot)"
				return 1
			endif		
		endif
	endfor

	//tempDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(filename,".nx.hdf"),0)
	//this datafolder should have:
	//1) M_topAndTail
	//2) M_topandtailSD
	//3) W_spec
	//4) W_specSD
	//5) W_specTOF
	//6) W_specTOFHIST
	//7) W_lambda
	//8) W_lambdaSD
	//9) W_lambdaHIST
	//and (optionally)
	//10) W_ref
	//11) W_refSD
	//12) W_q
	//13) W_qSD

	killwaves/z W_rebinboundaries
	//make a graph called SLIM_PLOT
	dowindow/k SLIM_PLOTwin
	display/K=1/W=(30,0,600,350) as "SLIM plot (C) Andrew Nelson + ANSTO 2008"
	dowindow/c SLIM_PLOTwin
	setwindow SLIM_PLOTwin, userdata(filenames) = filenames
	setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr
	
	sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\",%g, %g, %d, expected_peak = cmplx(%g, %g), rebinning=%g, manual=%d, normalise=%d, saveSpectrum=%d)", inputpathStr, outputPathStr, fileNames,lowlambda,highLambda, background, real(expected_peak), imag(expected_peak), rebinning, manual, normalise, saveSpectrum
	setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
	
	controlbar/W=SLIM_PLOTwin 30
	popupmenu/z graphtype,win=SLIM_PLOTwin, bodyWidth=160,proc=popup_SLIM_PLOT
	popupmenu/z graphtype,win=SLIM_PLOTwin, value="SPEC vs Lambda;SPEC vs TOF;Detector vs Lambda;Detector vs TOF;Ref vs Q;Ref vs Lambda;Ref vs TOF"
	checkbox/z isLog,win=SLIM_PLOTwin, title="LOG?",pos={169,5},proc=checkBox_SLIM_PLOT
	button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Refresh",pos = {228,3},size={100,20}, fColor=(0,52224,26368)
	//	button getimagelineprofile,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Line Profile",pos = {340,3},size={100,20} 
	if(SLIM_redisplay(0,0))
		print "ERROR while trying to redisplay (SLIM_PLOT)"
		return 1
	endif
End

Function SLIM_plot_scans(inputpathStr,filenames)
	String inputpathStr, fileNames
	print "SLIM_plot_scans("+inputpathStr+","+filenames+")"
	variable ii, fnumber
	string cDF, tempStr1,tempStr, slimplotstring
	
	cDF = getdatafolder(1)

	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o root:packages:platypus:data:Reducer
	newdatafolder/o/s root:packages:platypus:data:Reducer:SLIM_plot
	
	GetFileFolderInfo/q/z inputpathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (SLIM_plot_scans)"
		return 1
	endif
	newpath/o/q/z pla_temppath_SLIM_plot_scans, inputpathStr
	
	try
		dowindow/k SLIM_PLOTwin
		display/K=1 as "SLIM plot (C) Andrew Nelson + ANSTO 2008"
		dowindow/c SLIM_PLOTwin
		//		controlbar/W=SLIM_PLOTwin 30
		//		button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Refresh",size={100,20}, fColor=(0,52224,26368)
		
		sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\", 0, 0, 0)", inputpathStr, inputpathStr, fileNames
		setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
		setwindow SLIM_PLOTwin, userdata(filenames) = filenames
		setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr
		
		for(ii=0 ; ii<itemsinlist(filenames) ; ii+=1)
			string fname = stringfromlist(ii,filenames)
			loadWave/o/q/T/P=pla_temppath_SLIM_plot_scans, fname
			sscanf fname, "FIZscan%d%*[.]itx", fnumber
			Wave wav0 = $(stringfromlist(0, S_wavenames))
			Wave wav1 = $(stringfromlist(1, S_wavenames))
			duplicate/o wav0, $(stringfromlist(0, S_wavenames)+ num2istr(fnumber))
			Wave asd0 = $(stringfromlist(0, S_wavenames)+ num2istr(fnumber))
			duplicate/o wav1, $(stringfromlist(1, S_wavenames)+ num2istr(fnumber))
			Wave asd1 = $(stringfromlist(1, S_wavenames)+ num2istr(fnumber))	

			killwaves/z wav0,wav1
			
			appendtograph/w=SLIM_PLOTwin asd1[][0] vs asd0
			modifygraph mode=4
		endfor
		CommonColors("SLIM_PLOTwin")
		Legend/C/N=text0/A=MC
		cursor/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,tracenamelist("SLIM_PLOTwin",";",1))) 0.5,0.5
		showinfo
		setdatafolder $cDF
		killpath/z pla_temppath_SLIM_plot_scans
		return 0
	catch
		killpath/z pla_temppath_SLIM_plot_scans
		setdatafolder $cDF
		return 0
	endtry
End

Function SLIM_plot_reduced(inputPathStr, filenames)
	string inputPathStr, filenames
	variable ii,numwaves,jj
	string loadedWavenames, slimplotstring
	string cDF = getdatafolder(1)

	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o root:packages:platypus:data:Reducer
	newdatafolder/o/s root:packages:platypus:data:Reducer:SLIM_plot

	GetFileFolderInfo/q/z inputpathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (SLIM_plot_reduced)"
		return 1
	endif
	
	try
		dowindow/k SLIM_PLOTwin
		display/K=1 as "SLIM plot (C) Andrew Nelson + ANSTO 2008"
		dowindow/c SLIM_PLOTwin
		controlbar/W=SLIM_PLOTwin 30
		button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Refresh",size={100,20}, fColor=(0,52224,26368)
	
		sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\", 0, 0, 0)", inputpathStr, inputpathStr, fileNames
		setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
		setwindow SLIM_PLOTwin, userdata(filenames) = filenames
		setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr		

		for(ii = 0 ; ii < itemsinlist(filenames) ; ii += 1)
			string fname = stringfromlist(ii, filenames)

			variable fileID = xmlopenfile(inputPathStr + fname)
			if(fileID < 1)
				print "ERROR opening xml file (SLIM_PLOT_reduced)"
				abort
			endif
			fname = removeending(fname,".xml")
			
			xmlwavefmXPATH(fileID,"//Qz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_q",0)
			Wave qq = $cleanupname(fname+"_q",0)
			qq = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//R","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_R",0)
			Wave RR = $cleanupname(fname+"_R",0)
			RR = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//dR","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_E",0)
			Wave EE = $cleanupname(fname+"_E",0)
			EE = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//dQz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_dq",0)
			Wave dq = $cleanupname(fname+"_dq",0)
			dq = str2num(M_xmlcontent[p][0])
			
			sort qq,qq,RR,EE,dQ
			xmlclosefile(fileID,0)
			
			//			LoadWave/J/D/A/W/P=path_to_data/K=0 stringfromlist(ii,filenames)
			//			loadedWavenames = S_wavenames
			//			duplicate/o $(stringfromlist(0,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_q")
			//			duplicate/o $(stringfromlist(1,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_R")
			//			duplicate/o $(stringfromlist(2,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_E")
			//			duplicate/o $(stringfromlist(3,loadedWavenames)),$("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_dq")
			//			Wave qq = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_q")
			//			Wave RR = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_R")
			//			Wave EE = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_E")
			//			Wave dq = $("root:packages:platypus:data:Reducer:SLIM_plot:"+cleanupname(stringfromlist(ii,filenames),0)+"_dq")
			appendtograph/w=SLIM_PLOTwin RR vs qq
			ErrorBars/T=0 $nameofwave(RR) Y,wave=(EE,EE)
			ModifyGraph log(left)=1
			
			killwaves/z M_xmlcontent,W_xmlcontentnodes
			//			for(jj=0 ; jj<itemsinlist(loadedWavenames);jj+=1)
			//				killwaves/z $(stringfromlist(jj,loadedwavenames))
			//			endfor
		endfor
		CommonColors("SLIM_PLOTwin")
		Legend/C/N=text0/A=MC
		cursor/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,tracenamelist("SLIM_PLOTwin",";",1))) 0.5,0.5
		showinfo
		setdatafolder $cDF
		return 0
	catch
		setdatafolder $cDF
		return 0
	endtry
End

Function SLIM_plot_xrdml(inputPathStr, filenames)
	string inputPathStr, filenames
	variable err
	variable ii,numwaves,jj
	string loadedWavenames
	string cDF = getdatafolder(1)
	string theFile, base, slimplotstring
	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o root:packages:platypus:data:Reducer
	newdatafolder/o/s root:packages:platypus:data:Reducer:SLIM_plot

	GetFileFolderInfo/q/z inputpathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (SLIM_plot_xrdml)"
		return 1
	endif
	
	try
		dowindow/k SLIM_PLOTwin
		display/K=1 as "SLIM plot (C) Andrew Nelson + ANSTO 2008"
		dowindow/c SLIM_PLOTwin
		controlbar/W=SLIM_PLOTwin 30
		button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Refresh",size={100,20}, fColor=(0,52224,26368)
		
		sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\", 0, 0, 0)", inputpathStr, inputpathStr, fileNames
		setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
		setwindow SLIM_PLOTwin, userdata(filenames) = filenames
		setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr			

		for(ii=0 ; ii<itemsinlist(filenames) ; ii+=1)
			base = removeending(stringfromlist(ii, filenames), ".xrdml")		
			theFile = inputpathStr + stringfromlist(ii, filenames)
			theFile = parsefilepath(5, theFile, "*", 0, 0)
			
			if(Pla_Xrayreduction#reduceXpertPro(theFile, scalefactor = 1, footprint = NaN))
				abort
			endif
			wave RR = $("root:packages:Xpert:"+ cleanupname(base, 0) + "_R")
			wave qq = $("root:packages:Xpert:" + cleanupname(base, 0) + "_q")
			wave EE = $("root:packages:Xpert:" + cleanupname(base, 0) + "_E")
			//puts files into  root:packages:Xpert
			appendtograph/w=SLIM_PLOTwin RR vs qq
			ErrorBars/T=0 $nameofwave(RR) Y,wave=(EE,EE)
			ModifyGraph log(left)=1
		endfor
		CommonColors("SLIM_PLOTwin")
		Legend/C/N=text0/A=MC
		cursor/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,tracenamelist("SLIM_PLOTwin",";",1))) 0.5,0.5
		showinfo
		setdatafolder $cDF
		return 0
	catch
		err = 1
	endtry
	
	setdatafolder $cDF
	return err
ENd

Function SLIM_plot_spectrum(inputPathStr, filenames)
	string inputPathStr, filenames
	variable err
	variable ii,numwaves,jj, fileID
	string loadedWavenames
	string cDF = getdatafolder(1)
	string theFile, base, slimplotstring
	
	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o root:packages:platypus:data:Reducer
	newdatafolder/o/s root:packages:platypus:data:Reducer:SLIM_plot

	GetFileFolderInfo/q/z inputpathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (SLIM_plot_spectrum)"
		return 1
	endif
	
	try
		dowindow/k SLIM_PLOTwin
		display/K=1 as "SLIM plot (C) Andrew Nelson + ANSTO 2008"
		dowindow/c SLIM_PLOTwin
		controlbar/W=SLIM_PLOTwin 30
		button refresh,win=SLIM_PLOTwin, proc=button_SLIM_PLOT,title="Refresh",size={100,20}, fColor=(0,52224,26368)
		
		sprintf slimplotstring, "SLIM_plot(\"%s\", \"%s\", \"%s\", 0, 0, 0)", inputpathStr, inputpathStr, fileNames
		setwindow SLIM_PLOTwin, userdata(slimplotstring) = slimplotstring
		setwindow SLIM_PLOTwin, userdata(filenames) = filenames
		setwindow SLIM_PLOTwin, userdata(pathStr) = inputpathStr			

		for(ii=0 ; ii<itemsinlist(filenames) ; ii+=1)
			base = removeending(stringfromlist(ii, filenames), ".spectrum")		
			theFile = inputpathStr + stringfromlist(ii, filenames)
			theFile = parsefilepath(5, theFile, "*", 0, 0)

			fileID = xmlopenfile(thefile)
			if(fileID < 1)
				print "ERROR couldn't open spectrum file (SLIM_plot_spectrum)"
				abort
			endif			
			xmlwavefmxpath(fileID, "//R[1]", "","")
			Wave/t M_xmlcontent
			make/n=(dimsize(M_Xmlcontent, 0))/d/o $(base + "_R")
			Wave RR= $(base + "_R")
			RR = str2num(M_xmlcontent[p][0])

			xmlwavefmxpath(fileID, "//lambda[1]", "","")
			Wave/t M_xmlcontent
			make/n=(dimsize(M_Xmlcontent, 0))/d/o $(base + "_lambda")
			Wave lambda = $(base + "_lambda")
			lambda = str2num(M_xmlcontent[p][0])

			xmlwavefmxpath(fileID, "//dR[1]", "","")
			Wave/t M_xmlcontent
			make/n=(dimsize(M_Xmlcontent, 0))/d/o $(base + "_dI")
			Wave dR = $(base + "_dI")
			dR = str2num(M_xmlcontent[p][0])
			
			//puts files into  root:packages:Xpert
			appendtograph/w=SLIM_PLOTwin RR vs lambda
			ErrorBars/T=0 $nameofwave(RR) Y,wave=(dR, dR)
			ModifyGraph log(left)=1
			if(fileID> 0)
				xmlclosefile(fileiD, 0)
			endif

		endfor
		CommonColors("SLIM_PLOTwin")
		Legend/C/N=text0/A=MC
		cursor/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,tracenamelist("SLIM_PLOTwin",";",1))) 0.5,0.5
		showinfo
		setdatafolder $cDF
		return 0
	catch
		err = 1
		if(fileID> 0)
			xmlclosefile(fileiD, 0)
		endif
	endtry
	
	setdatafolder $cDF
	return err
ENd

Function button_SLIM_PLOT(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	NVAR lowLambda = root:packages:platypus:data:Reducer:lowLambda
	NVAR highLambda = root:packages:platypus:data:Reducer:highLambda
	Wave/t angledata_list = root:packages:platypus:data:Reducer:angledata_list
	NVAR rebinpercent = root:packages:platypus:data:Reducer:rebinpercent
	SVAR inputPathStr = root:packages:platypus:data:Reducer:inputPathStr
	SVAR outputPathStr = root:packages:platypus:data:Reducer:outputPathStr
	NVAR backgroundsbn =  root:packages:platypus:data:Reducer:backgroundsbn
	NVAR manualbeamfind =  root:packages:platypus:data:Reducer:manualbeamfind
	NVAR normalisebymonitor = root:packages:platypus:data:Reducer:normalisebymonitor
	NVAR saveSpectrum =  root:packages:platypus:data:Reducer:saveSpectrum
	
	variable background,isLOG,type, rebinning
	string fileNames = "", pathStr = "", slimplotstring = ""

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlname)
				case "refresh":
					filenames = GetUserData("SLIM_PLOTwin","","filenames")
					pathStr = GetUserData("SLIM_PLOTwin","","pathStr")
					slimplotstring = GetUserData("SLIM_PLOTwin","","slimplotstring")
					print slimplotstring
					controlinfo/w=SLIM_PLOTwin isLog
					isLog = V_Value
					controlinfo graphtype
					type = V_Value-1			
					rebinning = rebinpercent

					//	execute/q slimplotstring
					SLIM_plot(pathStr, pathStr, fileNames,lowLambda,highLambda, backgroundsbn, rebinning = rebinning, normalise = normalisebymonitor, saveSpectrum = saveSpectrum, manual = manualbeamfind)
					if(!stringmatch(stringfromlist(0,filenames),"*.xml") && !stringmatch(stringfromlist(0,filenames),"*.xrdml") && !stringmatch(stringfromlist(0,filenames),"*.spectrum"))
						SLIM_redisplay(type,isLog)
					endif
					break
				case "getimagelineprofile":
					WMCreateImageLineProfileGraph();
					break
			endswitch
			break
	endswitch
	return 0
End

Function popup_SLIM_PLOT(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			controlinfo/w=SLIM_PLOTwin isLog
			SLIM_redisplay(popNum-1,V_Value)
			break
	endswitch

	return 0
End

Function checkBox_SLIM_PLOT(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			controlinfo/w=SLIM_PLOTwin graphtype
			SLIM_redisplay(V_Value-1,checked)
			break
	endswitch

	return 0
End

Function SLIM_redisplay(mode,isLog)
	variable mode,isLog
	string fileNames="",tempDF,abscissa,ordinate,existingtraces,annotation,datafolderStr,existingimages, pathStr, slimplotstring
	variable ii,rows,cols,numgraphs,jj,colpos,rowpos,tempVar
	variable/c origin
	//we should offer plots of 
	//0) W_spec vs W_lambda
	//1) W_spec vs W_specTOF
	//2) M_topandtail vs ypixel vs W_lambdaHIST
	//3) M_topandtail vs ypixel vs W_tofHIST
	
	//with options 2 + 3, we don't plot M_topandtail, we duplicate the wave to M_tempSLIMplot, as 
	//we may be plotting log

	//optionally
	//4) W_ref vs W_q
	//5) W_ref vs W_lambda
	//6) W_ref vs W_TOF

	//remove all traces first
	for(;itemsinlist(tracenamelist("SLIM_PLOTwin",";",1))>0;)
		removefromgraph/W=SLIM_PLOTwin $(stringfromlist(0, tracenamelist("SLIM_PLOTwin",";",1)))
	endfor
	for(ii=0;itemsinlist(imagenamelist("SLIM_PLOTwin",";"))>0;ii+=1)
		removeimage/W=SLIM_PLOTwin $(stringfromlist(0, imagenamelist("SLIM_PLOTwin",";")))
		Legend/k/N=$("text"+num2istr(ii))
	endfor

	fileNames = GetUserData("SLIM_PLOTwin","","filenames")
	pathStr = GetUserData("SLIM_PLOTwin","","pathStr")
	slimplotstring = GetUserData("SLIM_PLOTwin","","slimplotstring")
	
	numgraphs = itemsinlist(filenames)
	rows = ceil(numgraphs/4)
	if(numgraphs>3)
		cols = 4
	else
		cols = numgraphs
	endif

	for(ii=0 ; ii<numgraphs ; ii+=1)
		tempDF = "root:packages:platypus:data:Reducer:"+cleanupname(removeending(stringfromlist(ii,filenames),".nx.hdf"),0)
		Wave/z W_ref = $(tempDF+":W_ref")
		Wave/z W_refSD = $(tempDF+":W_refSD")
		Wave/z W_q = $(tempDF+":W_q")
		Wave M_spectof = $(tempDF+":M_spectof")
		Wave M_lambda = $(tempDF+":M_lambda")
		Wave M_spec = $(tempDF+":M_spec")
		Wave M_specSD = $(tempDF+":M_specSD")
		Wave M_topandtail = $(tempDF+":M_topandtail")
		Wave M_specTOFHIST = $(tempDF+":M_specTOFHIST")
		Wave M_lambdaHIST = $(tempDF+":M_lambdaHIST")
		
		switch(mode)
			case 0:
				appendtograph/w=SLIM_PLOTwin M_spec[][0] vs M_lambda[][0]
				ErrorBars/T=0 $("M_Spec#"+num2istr(ii)) Y,wave=(M_specSD[][0], M_specSD[][0])
				ModifyGraph log(left)=isLog
				Label bottom "lambda"
				break
			case 1:
				appendtograph/w=SLIM_PLOTwin M_Spec vs M_spectof[][0]
				ErrorBars/T=0 $("M_Spec#"+num2istr(ii)) Y,wave=(M_specSD, M_specSD)
				ModifyGraph log(left)=isLog
				Label bottom "TOF(us)"
				break
			case 2:
				ordinate = ("L"+num2istr(ii))
				abscissa = ("B"+num2istr(ii))
				colpos = round(mod(ii,cols))
				rowpos = floor(ii/4)
				duplicate/o M_topandtail, $(tempDF+":M_tempSLIMPLOT")
				duplicate/o M_lambdaHIST, $(tempDF + ":M_tempSLIMPLOTlambdaHIST")
				
				Wave M_tempSLIMPLOT = $(tempDF+":"+"M_tempSLIMPLOT")
				Wave M_tempSLIMPLOTlambdaHIST = $(tempDF+":"+"M_tempSLIMPLOTlambdaHIST")
				redimension/n=(-1, 0) M_tempSLIMPLOTlambdaHIST
				
				if(isLOG)
					M_tempSLIMPLOT = log(M_tempSLIMplot)
				endif
				AppendImage/w=SLIM_PLOTwin/L=$ordinate/B=$abscissa M_tempSLIMPLOT vs {M_tempSLIMPLOTlambdaHIST, *}
				ModifyImage/w=SLIM_PLOTwin  $("M_tempSLIMPLOT#"+num2str(ii)) ctab={0,*,Rainbow,0}
				ModifyImage/w=SLIM_PLOTwin $("M_tempSLIMPLOT#"+num2str(ii)) minRGB=(0,0,0),maxRGB=0
				ModifyGraph/w=SLIM_PLOTwin freePos($ordinate)={0,$abscissa},freePos($abscissa)={0,$ordinate}
				ModifyGraph/w=SLIM_PLOTwin fSize($ordinate)=8,fsize($abscissa)=8
				origin = cmplx((1/cols)*colpos+0.04,(rowpos)*(1/rows)+0.04)
				ModifyGraph/w=SLIM_PLOTwin axisEnab($ordinate)={1-(rowpos+1)*(1/rows)+0.04,1-rowpos*(1/rows)-0.04},axisEnab($abscissa)={(1/cols)*colpos+0.04,(colpos+1)*(1/cols)-0.04}
				Label $abscissa "lambda"
				SetAxis $abscissa 0,*
				Label $ordinate "y pixel"
				ModifyGraph lblPosMode($ordinate)=1, lblPosMode($abscissa) = 1
				Legend/C/A=LT/N=$("text"+num2istr(ii))/X=(real(origin)*100)/Y=(imag(origin)*100) Getwavesdatafolder(M_tempSLIMPLOT,0)
				break
			case 3:
				ordinate = ("L"+num2istr(ii))
				abscissa = ("B"+num2istr(ii))
				colpos = round(mod(ii,cols))
				rowpos = floor(ii/4)
				duplicate/o M_topandtail, $(tempDF+":"+"M_tempSLIMPLOT")
				duplicate/o M_specTOFHIST, $(tempDF + ":M_tempSLIMPLOTspectofHIST")
				
				Wave M_tempSLIMPLOT = $(tempDF+":"+"M_tempSLIMPLOT")
				Wave M_tempSLIMPLOTspectofHIST = $(tempDF+":"+"M_tempSLIMPLOTspectofHIST")
				redimension/n=(-1, 0) M_tempSLIMPLOTspectofHIST

				if(isLOG)
					M_tempSLIMPLOT = log(M_tempSLIMplot)
				endif
				AppendImage/w=SLIM_PLOTwin/L=$("L"+num2istr(ii))/B=$("B"+num2istr(ii)) M_tempSLIMPLOT vs {M_tempSLIMPLOTspectofHIST,*}
				ModifyImage/w=SLIM_PLOTwin  $("M_tempSLIMPLOT#"+num2str(ii)) ctab={0,*,Rainbow,0}
				ModifyImage/w=SLIM_PLOTwin $("M_tempSLIMPLOT#"+num2str(ii)) minRGB=(0,0,0),maxRGB=0
				ModifyGraph/w=SLIM_PLOTwin freePos($ordinate)={0,$abscissa},freePos($abscissa)={0,$ordinate}
				ModifyGraph/w=SLIM_PLOTwin fSize($ordinate)=8,fsize($abscissa)=8
				origin = cmplx((1/cols)*colpos+0.04,1-(rowpos)*(1/rows)+0.04)
				ModifyGraph/w=SLIM_PLOTwin axisEnab($ordinate)={1-(rowpos+1)*(1/rows)+0.04,1-rowpos*(1/rows)-0.04},axisEnab($abscissa)={(1/cols)*colpos+0.04,(colpos+1)*(1/cols)-0.04}
				Label $abscissa "TOF(us)"
				SetAxis $abscissa 0,*
				Label $ordinate "y pixel"
				ModifyGraph lblPosMode($ordinate)=1, lblPosMode($abscissa) =1
				Legend/C/A=LT/N=$("text"+num2istr(ii))/J/X=(real(origin)*100)/Y=(imag(origin)*100) Getwavesdatafolder(M_tempSLIMPLOT,0)
				break
			case 4:
				if(waveexists(W_ref) && Waveexists(W_q) && Waveexists(W_refSD))
					appendtograph/w=SLIM_PLOTwin W_ref vs W_q
					tempVar = itemsinlist(greplist(tracenamelist("SLIM_PLOTwin",";",1),"^W_ref"))
					ErrorBars/T=0 $("W_ref#"+num2istr(tempVar-1))  Y,wave=(W_refSD,W_refSD)
					ModifyGraph log(left)=isLog
					Label bottom "q"
				endif
				break
			case 5:
				if(waveexists(W_ref) && Waveexists(W_q) && Waveexists(W_refSD))
					appendtograph/w=SLIM_PLOTwin W_ref vs M_lambda
					tempVar = itemsinlist(greplist(tracenamelist("SLIM_PLOTwin",";",1),"^W_ref"))
					ErrorBars/T=0 $("W_ref#"+num2istr(tempVar-1))  Y,wave=(W_refSD,W_refSD)
					ModifyGraph log(left)=isLog
					Label bottom "lambda"
				endif
				break
			case 6:
				if(waveexists(W_ref) && Waveexists(W_q) && Waveexists(W_refSD))
					appendtograph/w=SLIM_PLOTwin W_ref vs M_spectof
					tempVar = itemsinlist(greplist(tracenamelist("SLIM_PLOTwin",";",1),"^W_ref"))
					ErrorBars/T=0 $("W_ref#"+num2istr(tempVar-1))  Y,wave=(W_refSD,W_refSD)
					ModifyGraph log(left)=isLog
					Label bottom "TOF(us)"
				endif
				break
		endswitch
	endfor

	if(mode == 0 || mode == 1 || mode ==4 || mode == 5 || mode ==6)
		existingtraces = tracenamelist("SLIM_PLOTwin",";",1)
		annotation =""
		if(itemsinlist(existingtraces)==0)
			return 0
		endif
		
		cursor/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,existingtraces)) 0.5,0.5
		
		for(ii=0;ii<itemsinlist(existingtraces);ii+=1)
			Wave temp = tracenametowaveref("SLIM_PLOTwin",stringfromlist(ii,existingtraces))
			datafolderStr = getwavesdatafolder(temp,0)
			annotation+="\\s("+stringfromlist(ii,existingtraces)+") "+datafolderStr+"\r"
		endfor
		annotation = removeending(annotation,"\r")
		Legend/C/N=text0/J/A=MC annotation
		//select a range of different colours
		CommonColors("SLIM_PLOTwin")
	else
		existingimages = imagenamelist("SLIM_PLOTwin",";")
		cursor/I/A=1/W=SLIM_PLOTwin/H=1/F/P A $(stringfromlist(0,existingimages)) 0.5,0.5
	endif
	ShowInfo
	return 0
End

Function CommonColors(graphName)
	String graphName
	If(findlistitem(graphname,winlist(graphname,";","WIN:1"))==-1 || strlen(graphName) == 0)
		return 1
	endif
	
	Variable numTraces = itemsinlist(tracenamelist(graphname,";",1))

	if (numTraces <= 0)
		return 1
	endif

	Variable red, green, blue
	Variable i, index
	for(i=0; i<numTraces; i+=1)
		index = mod(i, 10)				// Wrap after 10 traces.
		switch(index)
			case 0:
				red = 0; green = 0; blue = 0;
				break

			case 1:
				red = 65535; green = 16385; blue = 16385;
				break
				
			case 2:
				red = 2; green = 39321; blue = 1;
				break
				
			case 3:
				red = 0; green = 0; blue = 65535;
				break
				
			case 4:
				red = 39321; green = 1; blue = 31457;
				break
				
			case 5:
				red = 48059; green = 48059; blue = 48059;
				break
				
			case 6:
				red = 65535; green = 32768; blue = 32768;
				break
				
			case 7:
				red = 0; green = 65535; blue = 0;
				break
				
			case 8:
				red = 16385; green = 65535; blue = 65535;
				break
				
			case 9:
				red = 65535; green = 32768; blue = 58981;
				break
		endswitch
		ModifyGraph/W=$graphname rgb[i]=(red, green, blue)
	endfor
	return 0
End

////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
//
// The code below finds the spec ridge if the auto find doesn't work
//
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////

Function userSpecifiedArea(detector, peakParams, bkgloc)
	Wave detector
	variable/C &peakParams, &bkgloc

	try
		NVAR/z TOFpixels = root:packages:platypus:data:reducer:TOFpixels
		if(!NVAR_exists(TOFpixels))
			variable/g root:packages:platypus:data:reducer:TOFpixels = 100
		endif
		NVAR TOFpixels = root:packages:platypus:data:reducer:TOFpixels

		NVAR/z width = root:packages:platypus:data:reducer:width
		if(!NVAR_exists(width)	)
			variable/g root:packages:platypus:data:reducer:width =40
		endif
		NVAR width = root:packages:platypus:data:reducer:width
	
		variable/g root:packages:platypus:data:reducer:expected_centre
		NVAR/z position = root:packages:platypus:data:reducer:expected_centre
	
		variable/g root:packages:platypus:data:reducer:actual_position
		variable/g root:packages:platypus:data:reducer:actual_width
		NVAR/z actual_position = root:packages:platypus:data:reducer:actual_position
		NVAR/z actual_width = root:packages:platypus:data:reducer:actual_width

	
		duplicate/o detector,root:packages:platypus:data:reducer:tempDetector
		Wave tempDetector = root:packages:platypus:data:reducer:tempDetector
		deletepoints/m=0 0, dimsize(tempdetector,0)-tofpixels, tempdetector
		deletepoints/m=1 ceil(position+width/2)+1,  dimsize(tempdetector,1), tempdetector
		deletepoints/m=1 0, floor(position-width/2), tempdetector

		imagetransform sumallcols tempDetector
		Wave W_sumcols
		duplicate/o W_sumcols, root:packages:platypus:data:reducer:ordProj 
		killwaves W_sumcols
		Wave ordProj =  root:packages:platypus:data:reducer:ordProj
		
		setscale/i x,  floor(position-width/2), ceil(position+width/2), ordProj 
		
		make/n=2/o root:packages:platypus:data:reducer:lhs, root:packages:platypus:data:reducer:rhs
		make/n=2/o root:packages:platypus:data:reducer:xrhs, root:packages:platypus:data:reducer:xlhs
		make/n=2/o root:packages:platypus:data:reducer:xrhs_bkg, root:packages:platypus:data:reducer:xlhs_bkg 
		make/n=2/o root:packages:platypus:data:reducer:rhs_bkg, root:packages:platypus:data:reducer:lhs_bkg 
		wave lhs = root:packages:platypus:data:reducer:lhs
		wave rhs = root:packages:platypus:data:reducer:rhs
		wave lhs_bkg = root:packages:platypus:data:reducer:lhs_bkg
		wave rhs_bkg = root:packages:platypus:data:reducer:rhs_bkg
		wave xrhs_bkg = root:packages:platypus:data:reducer:xrhs_bkg
		wave xlhs_bkg = root:packages:platypus:data:reducer:xlhs_bkg
		
		rhs[0] = inf
		rhs[1] = 0
		lhs[0] = inf
		lhs[1] = 0
		lhs_bkg[0] = inf
		lhs_bkg[1] = 0		
		rhs_bkg[0] = inf
		rhs_bkg[1] = 0
		
		createSpecBeamAdjustmentPanel(detector, ordProj)
		pauseforuser specBeamAdjustmentPanel
		bkgloc = cmplx(xlhs_bkg[0], xrhs_bkg[0])
		peakParams = cmplx(actual_position, actual_width)
	catch

	endtry
	killwaves/z W_coef, fit_ordproj, tempdetector

End

Function createSpecBeamAdjustmentPanel(detector, ordProj)
	Wave detector, ordProj
	string filename = getwavesdatafolder(detector, 0)
	NewPanel /W=(150,50,883,506)/n=specBeamAdjustmentPanel as filename
	Button Continue_Button,pos={465,407},size={161,43},proc=killSpecBeamAdjustmentPanel,title="Continue",win=specBeamAdjustmentPanel
	SetVariable pixelsToInclude_setvar,pos={449,275},size={185,19},proc=adjustAOI,title="TOF Pixels to include",win=specBeamAdjustmentPanel
	SetVariable pixelsToInclude_setvar,fSize=12,win=specBeamAdjustmentPanel
	SetVariable pixelsToInclude_setvar,limits={1,9999,1},value= root:packages:platypus:data:reducer:TOFpixels,win=specBeamAdjustmentPanel
	SetVariable width_setvar,pos={464,297},size={170,19},proc=adjustAOI,title="integrate width",win=specBeamAdjustmentPanel
	SetVariable width_setvar,fSize=12,win=specBeamAdjustmentPanel
	SetVariable width_setvar,limits={1,220,1},value= root:packages:platypus:data:reducer:width,win=specBeamAdjustmentPanel
	SetVariable position_setvar,pos={464,321},size={170,19},proc=adjustAOI,title="integrate position",win=specBeamAdjustmentPanel
	SetVariable position_setvar,fSize=12,win=specBeamAdjustmentPanel
	SetVariable position_setvar,limits={1,220,1},value= root:packages:platypus:data:reducer:expected_centre,win=specBeamAdjustmentPanel
	
	SetVariable true_width_setvar,pos={548,368},size={170,19},proc=myAOI,title="true FWHM",win=specBeamAdjustmentPanel
	SetVariable true_width_setvar,fSize=12,win=specBeamAdjustmentPanel
	SetVariable true_width_setvar,limits={1,220,1},value= root:packages:platypus:data:reducer:actual_width,win=specBeamAdjustmentPanel
	SetVariable true_position_setvar,pos={378,368},size={170,19},proc=myAOI,title="true position",win=specBeamAdjustmentPanel
	SetVariable true_position_setvar,fSize=12,win=specBeamAdjustmentPanel
	SetVariable true_position_setvar,limits={1,220,1},value= root:packages:platypus:data:reducer:actual_position,win=specBeamAdjustmentPanel
	TitleBox Instruction,pos={429,231},size={226,20},title="Please adjust regions to find gaussian beamcentre",win=specBeamAdjustmentPanel
	GroupBox group0,pos={440,256},size={203,88},title="auto adjust",win=specBeamAdjustmentPanel
	GroupBox group1,pos={372,349},size={354,49},title="manual adjust",win=specBeamAdjustmentPanel
		
	TitleBox Instruction,pos={429,231},size={226,20},title="Please adjust regions to find gaussian beamcentre",win=specBeamAdjustmentPanel

	DefineGuide/W=specBeamAdjustmentPanel UGV0={FR,0.5,FL},UGH0={FB,0.5,FT}
	Display/W=(104,50,313,153)/FG=(FL,FT,UGV0,FB)/N=detector/HOST=specBeamAdjustmentPanel
	AppendImage/w=specBeamAdjustmentPanel#detector detector
	ModifyImage detector ctab = {*,*,YellowHot,0}
	ModifyGraph mirror=2
	SetDrawLayer UserFront
	Display/W=(361,100,668,204)/FG=(UGV0,FT,FR,UGH0)/N=detectorADD/HOST=specBeamAdjustmentPanel  ordProj
	ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd mode(ordProj)=3,marker(ordProj)=8

	wave lhs = root:packages:platypus:data:reducer:lhs
	wave rhs = root:packages:platypus:data:reducer:rhs
	wave xlhs = root:packages:platypus:data:reducer:xlhs
	wave xrhs = root:packages:platypus:data:reducer:xrhs
	wave xlhs_bkg = root:packages:platypus:data:reducer:xlhs_bkg
	wave xrhs_bkg = root:packages:platypus:data:reducer:xrhs_bkg
	wave lhs_bkg = root:packages:platypus:data:reducer:lhs_bkg
	wave rhs_bkg = root:packages:platypus:data:reducer:rhs_bkg
	
	appendtograph/W=specBeamAdjustmentPanel#Detectoradd lhs vs xlhs
	appendtograph/W=specBeamAdjustmentPanel#Detectoradd rhs vs xrhs
	appendtograph/W=specBeamAdjustmentPanel#Detectoradd rhs_bkg vs xrhs_bkg
	appendtograph/W=specBeamAdjustmentPanel#Detectoradd lhs_bkg vs xlhs_bkg

	newdatafolder/o root:WinGlobals
	newdatafolder/o root:WinGlobals:detectorAdd
	string/g root:WinGlobals:detectorAdd:S_TraceOffsetInfo
	Svar S_TraceOffsetInfo = root:WinGlobals:detectorAdd:S_TraceOffsetInfo
	variable/g root:WinGlobals:detectorAdd:diditmove = 0
	NVAR diditmove = root:WinGlobals:detectorAdd:diditmove
	
	SetFormula diditmove, "userselectedArea(S_TraceOffsetInfo)"

	ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd rgb(rhs_bkg)=(0,0,0),rgb(lhs_bkg)=(0,0,0)
	ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd minor(bottom)=1, log(left)=1,rgb(rhs)=(0,0,65535), rgb(lhs)=(0,0,65535)
	ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd quickdrag(rhs)=1,live(rhs)=1, quickdrag(lhs)=1,live(lhs)=1
	ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd quickdrag(rhs_bkg)=1,live(rhs_bkg)=1, quickdrag(lhs_bkg)=1,live(lhs_bkg)=1
	STRUCT WMSetVariableAction s
	s.eventcode=6
	adjustAOI(s)
End

Function killSpecBeamAdjustmentPanel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			killwindow specbeamadjustmentpanel
			NVAR diditmove = root:WinGlobals:detectorAdd:diditmove
			Setformula diditmove,""
			break
	endswitch

	return 0
End

Function  userselectedArea(tracemoving)
	String tracemoving
	if(!numberbykey("XOFFSET", tracemoving))
		return 0
	endif
	
	wave lhs = root:packages:platypus:data:reducer:lhs
	wave rhs = root:packages:platypus:data:reducer:rhs
	wave xlhs = root:packages:platypus:data:reducer:xlhs
	wave xrhs = root:packages:platypus:data:reducer:xrhs
	wave xlhs_bkg = root:packages:platypus:data:reducer:xlhs_bkg
	wave xrhs_bkg = root:packages:platypus:data:reducer:xrhs_bkg
	wave lhs_bkg = root:packages:platypus:data:reducer:lhs_bkg
	wave rhs_bkg = root:packages:platypus:data:reducer:rhs_bkg
	Wave ordProj =  root:packages:platypus:data:reducer:ordProj 

	
	NVAR/z actual_position = root:packages:platypus:data:reducer:actual_position
	NVAR/z actual_width = root:packages:platypus:data:reducer:actual_width
	string whichtrace = stringbykey("TNAME", tracemoving)
	variable offset = numberbykey("XOFFSET", tracemoving)

	strswitch(whichtrace)
		case "lhs":
			ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(lhs)={0,0}
			if(xlhs[0] + offset > xrhs[0])
				return 0
			endif
			xlhs += offset
			actual_position = 0.5*( xlhs[0] + xrhs[0])
			actual_width = (xrhs[0] - xlhs[0])/INTEGRATEFACTOR	
			xlhs_bkg = xlhs - actual_width*INTEGRATEFACTOR
			xrhs_bkg = xrhs + actual_width*INTEGRATEFACTOR
			break
		case "rhs":
			ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(rhs)={0,0}
			if(xrhs[0] + offset < xlhs[0])
				return 0
			endif
			xrhs += offset
			actual_position = 0.5*( xlhs[0] + xrhs[0])
			actual_width = (xrhs[0] - xlhs[0])/INTEGRATEFACTOR	
			xlhs_bkg = xlhs - actual_width*INTEGRATEFACTOR
			xrhs_bkg = xrhs + actual_width*INTEGRATEFACTOR
		
			break
		case "lhs_bkg":
			ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(lhs_bkg)={0,0}
			if(xlhs_bkg[0] + offset > xlhs[0] - BACKGROUNDOFFSET)
				return 0
			endif
			xlhs_bkg += offset
			break
		case "rhs_bkg":
			ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(rhs_bkg)={0,0}
			if(xrhs_bkg[0] + offset < xrhs[0] + BACKGROUNDOFFSET)
				return 0
			endif
			xrhs_bkg += offset
			break
			
	endswitch
	Tag/W=specBeamAdjustmentPanel#Detectoradd/C/N=centre/S=1/A=MB/TL={lineRGB=(0,0,65535)}/G=(0,0,65535)/TL={len=10,frame=1}   ordProj, actual_position,"\\K(0,0,65535)Centre"
End


Function myAOI(s):setvariablecontrol
	STRUCT WMSetVariableAction &s
	//this function puts a gaussian on the specbeamadjustment plot, with a user specified centre + FWHM.
	//Normally the user relies on a fitted gaussian produced by adjustAOI.  However, there may be some circumstances where they want to manually set the centre + FWHM.

	if(s.eventcode > 0)
		wave imageWave = ImageNameToWaveRef("specBeamAdjustmentPanel#detector", stringfromlist(0,imagenamelist("specBeamAdjustmentPanel#detector",";")) )
		Wave ordProj =  root:packages:platypus:data:reducer:ordProj 
	
		NVAR/z actual_position = root:packages:platypus:data:reducer:actual_position
		NVAR/z actual_width = root:packages:platypus:data:reducer:actual_width

		Wave ordProj =  root:packages:platypus:data:reducer:ordProj 
	
		setactivesubwindow specBeamAdjustmentPanel#detectorADD
	
		make/n=4/d/o root:packages:platypus:data:reducer:W_coef
		Wave W_coef =  root:packages:platypus:data:reducer:W_coef
		W_coef[2] = actual_position
		W_coef[3] = sqrt(2) * actual_width /(2*sqrt(2*ln(2)))
		variable V_fitoptions = 4
		CurveFit/q/W=0/n/H="0011" gauss, kwCWave = W_coef, ordProj

		wave xlhs = root:packages:platypus:data:reducer:xlhs
		wave xrhs = root:packages:platypus:data:reducer:xrhs
		wave xlhs_bkg = root:packages:platypus:data:reducer:xlhs_bkg
		wave xrhs_bkg = root:packages:platypus:data:reducer:xrhs_bkg
	
		xlhs = floor(W_coef[2] - INTEGRATEFACTOR * actual_width/2)
		xrhs = ceil(W_coef[2] +  INTEGRATEFACTOR * actual_width/2)
		xlhs_bkg = xlhs - actual_width*INTEGRATEFACTOR - BACKGROUNDOFFSET
		xrhs_bkg = xrhs + actual_width*INTEGRATEFACTOR + BACKGROUNDOFFSET
		
		ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(lhs)={0,0}, offset(rhs) = {0,0}
		ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(lhs_bkg)={0,0}, offset(rhs_bkg) = {0,0}
		Tag/W=specBeamAdjustmentPanel#Detectoradd/C/N=centre/S=1/A=MB/TL={lineRGB=(0,0,65535)}/G=(0,0,65535)/TL={len=10,frame=1}   ordProj, actual_position,"\\K(0,0,65535)Centre"

		setactivesubwindow specBeamAdjustmentPanel

	endif
End

Function adjustAOI(s):setvariablecontrol
	STRUCT WMSetVariableAction &s

	if(s.eventcode >0)
		wave imageWave = ImageNameToWaveRef("specBeamAdjustmentPanel#detector", stringfromlist(0,imagenamelist("specBeamAdjustmentPanel#detector",";")) )
		Wave ordProj =  root:packages:platypus:data:reducer:ordProj 

		variable tofbins, ypixels
		tofbins = dimsize(imagewave,0)
		ypixels = dimsize(imagewave,1)
		
		nvar tofpixels =  root:packages:platypus:data:reducer:TOFpixels
		nvar width = root:packages:platypus:data:reducer:width
		nvar expected_centre = root:packages:platypus:data:reducer:expected_centre
	
		NVAR/z actual_position = root:packages:platypus:data:reducer:actual_position
		NVAR/z actual_width = root:packages:platypus:data:reducer:actual_width
	
		setdrawlayer/k/w=specBeamAdjustmentPanel#detector progfront
		SetDrawLayer/w=specBeamAdjustmentPanel#detector ProgFront
		SetDrawEnv/w=specBeamAdjustmentPanel#detector linefgc= (65535,65535,0),fillpat= 0,xcoord= bottom,ycoord= left, save
	
		//we are the wrong way around with this rectangle
		drawrect/w=specBeamAdjustmentPanel#detector tofbins-tofpixels,expected_centre - width/2,tofbins, (expected_centre+width/2)
	
		duplicate/o imageWave, root:packages:platypus:data:reducer:tempDetector
		Wave tempDetector = root:packages:platypus:data:reducer:tempDetector
	
		deletepoints/m=0 0, dimsize(tempdetector,0)-tofpixels, tempdetector
		deletepoints/m=1 ceil(expected_centre+width/2)+1,  dimsize(tempdetector,1), tempdetector
		deletepoints/m=1 0, floor(expected_centre-width/2), tempdetector
	
		imagetransform sumallcols tempDetector
		Wave W_sumcols
		duplicate/o W_sumcols, root:packages:platypus:data:reducer:ordProj 
		killwaves W_sumcols
		Wave ordProj =  root:packages:platypus:data:reducer:ordProj 
		setscale/i x,  floor(expected_centre-width/2), ceil(expected_centre+width/2), ordProj 
	
		setactivesubwindow specBeamAdjustmentPanel#detectorADD
		variable v_fitoptions=4
		CurveFit/q/W=0/n gauss, ordProj

		setactivesubwindow specBeamAdjustmentPanel
		Wave W_coef
		actual_position = W_coef[2]
		actual_width = 2*sqrt(2*ln(2))*W_coef[3]/sqrt(2)
	
		wave xlhs = root:packages:platypus:data:reducer:xlhs
		wave xrhs = root:packages:platypus:data:reducer:xrhs
		wave xlhs_bkg = root:packages:platypus:data:reducer:xlhs_bkg
		wave xrhs_bkg = root:packages:platypus:data:reducer:xrhs_bkg
	
		xlhs = floor(W_coef[2] - INTEGRATEFACTOR * actual_width/2)
		xrhs = ceil(W_coef[2] +  INTEGRATEFACTOR * actual_width/2)
		xlhs_bkg = xlhs - actual_width*INTEGRATEFACTOR - BACKGROUNDOFFSET - 1
		xrhs_bkg = xrhs + actual_width*INTEGRATEFACTOR + BACKGROUNDOFFSET + 1

		ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(lhs)={0,0}, offset(rhs) = {0,0}
		ModifyGraph/W=specBeamAdjustmentPanel#Detectoradd offset(lhs_bkg)={0,0}, offset(rhs_bkg) = {0,0}
		Tag/W=specBeamAdjustmentPanel#Detectoradd/C/N=centre/S=1/A=MB/TL={lineRGB=(0,0,65535)}/G=(0,0,65535)/TL={len=10,frame=1}   ordProj, actual_position,"\\K(0,0,65535)Centre"
	endif
End

Function SLIM_plot_offspec(inputPathStr, filenames)
	//plots a map of a 2D offspecular dataset
	string inputPathStr, filenames

	variable ii,numwaves,jj, val
	string loadedWavenames, slimplotstring, axes
	string cDF = getdatafolder(1)

	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o root:packages:platypus:data
	newdatafolder/o root:packages:platypus:data:Reducer
	newdatafolder/o/s root:packages:platypus:data:Reducer:SLIM_plot
	
	GetFileFolderInfo/q/z inputpathStr
	if(V_flag)//path doesn't exist
		print "ERROR please give valid path (SLIM_plot_reduced)"
		return 1
	endif
	
	try		
		for(ii = 0 ; ii < itemsinlist(filenames) ; ii += 1)
			string fname = stringfromlist(ii, filenames)
			variable fileID = xmlopenfile(inputPathStr + fname)
			if(fileID < 1)
				print "ERROR opening xml file (SLIM_PLOT_reduced)"
				abort
			endif
			fname = removeending(fname,".xml")
			axes = xmlstrfmxpath(fileID, "//REFdata/@axes", "", "")
			if(itemsinlist(axes) != 2)
				print "ERROR not an offspecular file"
				abort
			endif
			
			xmlwavefmXPATH(fileID,"//Qz","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_qz",0)
			Wave qz = $cleanupname(fname+"_qz",0)
			qz = str2num(M_xmlcontent[p][0])
			
			xmlwavefmXPATH(fileID,"//R","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_R",0)
			Wave RR = $cleanupname(fname+"_R",0)
			RR = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//dR","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_E",0)
			Wave EE = $cleanupname(fname+"_E",0)
			EE = str2num(M_xmlcontent[p][0])

			xmlwavefmXPATH(fileID,"//Qy","","")
			Wave/t M_xmlcontent
			make/o/d/n=(dimsize(M_xmlcontent,0)) $cleanupname(fname+"_qy",0)
			Wave qy = $cleanupname(fname+"_qy",0)
			qy = str2num(M_xmlcontent[p][0])
			
			xmlclosefile(fileID,0)
			
			sort/R Qz, Qz, Qy,RR,EE
			val = binarysearch(Qz, 0)
			deletepoints val+1, dimsize(Qz, 0), Qz, Qy, RR, EE
			
			sort/R Qy, Qz, Qy,RR,EE
			val = binarysearch(Qy, -1e-3)
			deletepoints val+1, dimsize(Qy, 0), Qz, Qy, RR, EE


			EP_log(RR, EE, RR, EE)
			sort RR, Qz, Qy,RR,EE
			val = binarysearch(RR, -Inf)
			deletepoints val, numpnts(RR) - val, RR, Qz, Qy, EE
			killwaves/z M_xmlcontent,W_xmlcontentnodes
			Display/K=1
			AppendXYZContour RR vs {qy, qz}
		endfor
		setdatafolder $cDF
		return 0
	catch
		setdatafolder $cDF
		return 0
	endtry
End


//#pragma rtGlobals=1		// Use modern global access method.
//Function offspec_XRMLmap()
//variable fileID
//variable wavelength, KA1, KA2, ratio, ii, numscans, startpoint, endpoint
//string namespace = "xrdml=http://www.xrdml.com/XRDMeasurement/1.0"
//
//	Open/R/D/F=".xrdml" fileID
//	fileID = XMLopenfile(S_fileName)
//	if(fileID < 1)
//		abort
//	endif
//
//KA1 = str2num(XMLstrFmXpath(fileID, "//xrdml:kAlpha1",namespace,""))
//KA2 = str2num(XMLstrFmXpath(fileID, "//xrdml:kAlpha2",namespace,""))
//ratio = str2num(XMLstrFmXpath(fileID, "//xrdml:ratioKAlpha2KAlpha1",namespace,""))
//wavelength = (KA1 + ratio * KA2) / (1+ratio)
//
//XMLlistXPATH(fileID, "//xrdml:scan", namespace)
//Wave/t/z M_listXpath
//numscans = dimsize(M_listXPath, 0)
//
//make/n=(0,3)/free/o/d temp
//make/n=(0,3)/o/d offspec_map
//
//for(ii = 0 ; ii < numscans ; ii+=1)
//	XMLlistXpath(fileID, "//xrdml:scan["+num2istr(ii+1)+"]/xrdml:dataPoints/xrdml:intensities", namespace)
//	Wave/t/z M_listXpath
//	XMLwavefmXpath(fileID, M_listXpath[0][0], namespace, " ")
//	Wave/t/z M_xmlcontent
//	redimension/n=(dimsize(M_xmlcontent, 0), -1)temp
//	temp[][2] = str2num(M_XMLcontent[p][0])
//	
//	startpoint = str2num(XMLstrfmXpath(fileID, "//xrdml:scan["+num2istr(ii+1)+"]/xrdml:dataPoints/xrdml:positions[@axis=\"2Theta\"]/xrdml:startPosition", namespace, ""))
//	endpoint = str2num(XMLstrfmXpath(fileID, "//xrdml:scan["+num2istr(ii+1)+"]/xrdml:dataPoints/xrdml:positions[@axis=\"2Theta\"]/xrdml:endPosition", namespace, ""))
//	temp[][0] = startpoint + p * (endpoint - startpoint) / (dimsize(temp, 0) - 1)
//
//	startpoint = str2num(XMLstrfmXpath(fileID, "//xrdml:scan["+num2istr(ii+1)+"]/xrdml:dataPoints/xrdml:positions[@axis=\"Omega\"]/xrdml:startPosition", namespace, ""))
//	endpoint = str2num(XMLstrfmXpath(fileID, "//xrdml:scan["+num2istr(ii+1)+"]/xrdml:dataPoints/xrdml:positions[@axis=\"Omega\"]/xrdml:endPosition", namespace, ""))
//	temp[][1] = startpoint + p * (endpoint - startpoint) / (dimsize(temp, 0) - 1)
//	
//	duplicate/free/o temp, temp2
//	temp2[][1] = imag(Moto_angletoQ(temp[p][1], temp[p][0], wavelength))
//	temp2[][0] = real(Moto_angletoQ(temp[p][1], temp[p][0], wavelength))
//	
//	concatenate/NP=0 {temp2}, offspec_map
//endfor
//
//if(fileID> 0)
//	xmlclosefile(fileID, -1)
//endif
//killwaves/z M_listxpath, M_xmlcontent, W_xmlcontent
//End
#pragma rtGlobals=1		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$
#pragma ModuleName = Pla_catalogue

Menu "Platypus"
	"Catalogue HDF data",catalogueNexusdata()
	"Catalogue FIZ data", catalogueFIZdata()
End

Function catalogueFIZdata()
	newpath/o/z/q/M="Where are the FIZ files?" PATH_TO_DATAFILES
	if(V_flag)
		print "ERROR path to data is incorrect (catalogueFIZdata)"
		return 1
	endif
	pathinfo PATH_TO_DATAFILES
	variable start=1,finish=100000
	prompt start,"start"
	prompt finish,"finish"
	Doprompt "Enter the start and end files",start, finish
	If(V_flag)
		abort
	endif
	catalogueFIZ(S_path,start=start,finish=finish)	
End
	
Function catalogueNexusdata()
	newpath/o/z/q/M="Where are the NeXUS files?" PATH_TO_DATAFILES
	if(V_flag)
		print "ERROR path to data is incorrect (catalogue)"
		return 1
	endif
	pathinfo PATH_TO_DATAFILES
	variable start=1,finish=100000
	prompt start,"start"
	prompt finish,"finish"
	Doprompt "Enter the start and end files",start, finish
	If(V_flag)
		abort
	endif
	catalogueHDF(S_path,start=start,finish=finish)
	print "file:///"+S_path+"catalogue.xml" 
End

Function catalogueHDF(pathName[, start, finish])
	String pathName
	variable start, finish

	string cDF = getdatafolder(1)
	string nexusfiles,tempStr
	variable temp,ii,jj,HDFref,xmlref, firstfile, lastfile, fnum

	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o/s root:packages:platypus:catalogue
	make/o/t/n=(1,9) runlist
	make/o/d/n=(1,4) vgaps
	string/g DAQfiles = ""
	
	if(paramisdefault(start))
		start = 1
	endif

	try
		newpath/o/z/q PATH_TO_DATAFILES, pathname
		if(V_flag)
			print "ERROR path to data is incorrect (catalogue)"
			abort
		endif
	
		nexusfiles = sortlist(indexedfile(PATH_TO_DATAFILES,-1,".hdf"),";",16)
		nexusfiles = replacestring(".nx.hdf", nexusfiles,"")
		nexusfiles = greplist(nexusfiles, "^PLP")
		
		sscanf stringfromlist(0, nexusfiles), "PLP%d", firstfile
		sscanf stringfromlist(itemsinlist(nexusfiles)-1, nexusfiles),"PLP%d",lastfile
		if(paramisdefault(finish))
			finish = lastfile
		endif
		
		pathInfo PATH_TO_DATAFILES
		xmlref = xmlcreatefile(S_path+"catalogue.xml","catalogue","","")
		if(xmlref < 1)
			print "ERROR while creating XML file (catalogue)"
			abort
		endif
		
		jj = 0
		for(ii = 0 ; ii<itemsinlist(nexusfiles) ; ii+=1)
			sscanf stringfromlist(ii, nexusfiles), "PLP%d", fnum
			if(fnum >= firstfile && fnum <= lastfile && fnum >= start && fnum <= finish)
			else
				continue
			endif
			hdf5openfile/p=PATH_TO_DATAFILES/z/r HDFref as stringfromlist(ii,nexusfiles)+".nx.hdf"
			if(V_Flag)
				print "ERROR while opening HDF5 file (catalogue)"
				abort
			endif
		
			appendCataloguedata(HDFref, xmlref, jj, stringfromlist(ii,nexusfiles), runlist, vgaps)
		
			if(HDFref)
				HDF5closefile(HDFref)
			endif
			jj+=1
		endfor
		setdimlabel 1,0,run_number, runlist
		setdimlabel 1, 1, starttime, runlist
		setdimlabel 1,2,sample, runlist
		setdimlabel 1,3,vslits, runlist
		setdimlabel 1,4,omega, runlist
		setdimlabel 1,5,run_time, runlist
		setdimlabel 1,6,total_counts, runlist
		setdimlabel 1,7,mon1_counts, runlist
		setdimlabel 1,8,DAQ_FILENAME, runlist
		dowindow/k Platypus_run_list
		edit/k=1/N=Platypus_run_list runlist.ld as "Platypus Run List"
	catch
		if(HDFref)
			hdf5closefile/z HDFref
		endif
	endtry

	if(xmlref > 0)
		xmlclosefile(xmlref,1)
	endif

	Killpath/z PATH_TO_DATAFILES

	setdatafolder $cDF
End

Function appendCataloguedata(HDFref,xmlref,fileNum,filename, runlist, vgaps)
	variable HDFref,xmlref,fileNum
	string filename
	Wave/t runlist
	Wave vgaps
	SVAR DAQfiles
	print fileNum
	
	string tempStr
	variable row,fnum
	if(HDFref<1 || xmlref<1)
		print "ERROR while cataloging, one or more file references incomplete (appendCataloguedata)"
		abort
	endif
	
	//add another row to the runlist
	redimension/n=(fileNum+1,-1) runlist
	redimension/n=(fileNum+1,-1) vgaps
	row = dimsize(runlist,0)
	
	if(xmladdnode(xmlref,"//catalogue","","nexus","",1))
		abort
	endif
	
	//filename
	if(xmlsetattr(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]","","file",filename))
		abort
	endif
	sscanf filename, "PLP%d",fnum
	runlist[row][0] = num2istr(fnum)
	
	//runnum, sample name, vslits, omega, time, detcounts, mon1counts
 
	hdf5loaddata/z/q/o hdfref,"/entry1/start_time"
	if(!V_flag)
		Wave/t start_time = $(stringfromlist(0, S_wavenames))
		if(xmlsetattr(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]","","date",start_time[0]))
			abort
		endif
	endif
	runlist[row][1] = start_time[0]
 
	//user
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]","","user","",1))
		abort
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/user/name"
	if(!V_flag)
		Wave/t name = $(stringfromlist(0, S_wavenames))
		if(xmlsetattr(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/user","","name",name[0]))
			abort
		endif
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/user/email"
	if(!V_flag)
		Wave/t email = $(stringfromlist(0, S_wavenames))
		if(xmlsetattr(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/user","","email",email[0]))
			abort
		endif
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/user/phone"
	if(!V_flag)
		Wave/t phone = $(stringfromlist(0, S_wavenames))
		if(xmlsetattr(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/user","","phone",phone[0]))
			abort
		endif
	endif
 
	//experiment
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]","","experiment","",1))
		abort
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/experiment/title"
	if(!V_flag)
		Wave/t title = $(stringfromlist(0, S_wavenames))
		if(xmlsetattr(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/experiment","","title",title[0]))
			abort
		endif
	endif
	
	//sample
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]","","sample","",1))
		abort
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/sample/description"
	if(!V_flag)
		Wave/t description = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/sample","","description",description[0],1))
			abort
		endif
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/sample/name"
	if(!V_flag)
		Wave/t name = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/sample","","name",name[0],1))
			abort
		endif
		runlist[row][2] = name[0]
	endif


	hdf5loaddata/z/q/o hdfref,"/entry1/sample/title"
	if(!V_flag)
		Wave/t title = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/sample","","title",title[0],1))
			abort
		endif
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/sample/sth"
	if(!V_flag)
		Wave sth = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/sample","","sth",num2str(sth[0]),1))
			abort
		endif
	endif
	
	//instrument
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]","","instrument","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument","","slits","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits","","first","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/first","","vertical","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/first","","horizontal","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits","","second","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/second","","vertical","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/second","","horizontal","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits","","third","",1))
		abort
	endif
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/third","","vertical","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/third","","horizontal","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits","","fourth","",1))
		abort
	endif
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/fourth","","vertical","",1))
		abort
	endif
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/fourth","","horizontal","",1))
		abort
	endif
 
 	tempstr = ""
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/first/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/first/horizontal","","gap",num2str(gap[0]),1))
			abort
		endif
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/first/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])+", "
		vgaps[row][0] = gap[0]
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/first/vertical","","gap",num2str(gap[0]),1))
			abort
		endif
	endif
	 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/second/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/second/horizontal","","gap",num2str(gap[0]),1))
			abort
		endif
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/second/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])+", "
		vgaps[row][1] = gap[0]
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/second/vertical","","gap",num2str(gap[0]),1))
			abort
		endif
	endif
	 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/third/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/third/horizontal","","gap",num2str(gap[0]),1))
			abort
		endif
	endif
	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/third/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])+", "
		vgaps[row][2] = gap[0]
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/third/vertical","","gap",num2str(gap[0]),1))
			abort
		endif
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/third/vertical/st3vt"
	if(!V_flag)
		Wave st3vt = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/third/vertical","","st3vt",num2str(st3vt[0]),1))
			abort
		endif
	endif  
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/fourth/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/fourth/horizontal","","gap",num2str(gap[0]),1))
			abort
		endif
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/fourth/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])
		vgaps[row][3] = gap[0]
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/fourth/vertical","","gap",num2str(gap[0]),1))
			abort
		endif
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/fourth/vertical/st4vt"
	if(!V_flag)
		Wave st4vt = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/slits/fourth/vertical","","st4vt",num2str(st4vt[0]),1))
			abort
		endif
	endif 
//	sprintf tempstr,"%0.2f, %0.2f, %0.2f, %0.2f",first_vertical_gap[0], second_vertical_gap[0], third_vertical_gap[0], fourth_vertical_gap[0]
//	tempStr = "("+num2str(first_vertical_gap[0])+","
//	tempStr += num2str(second_vertical_gap[0])+","
//	tempStr += num2str(third_vertical_gap[0])+","
//	tempStr += num2str(fourth_vertical_gap[0])+")"
	runlist[row][3]= tempStr
	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/daq_dirname"
	if(!V_flag)
		Wave/t name = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument","","daq_dirname",name[0],1))
			abort
		endif
		runlist[row][8] = name[0]
		daqfiles += name[0] + ";"
	endif
	
	//parameters
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument","","parameters","",1))
		abort
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/parameters/mode"
	if(!V_flag)
		Wave/t mode = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/parameters","","mode",mode[0],1))
			abort
		endif
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/parameters/omega"
	if(!V_flag)
		Wave omega = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/parameters","","omega",num2str(omega[0]),1))
			abort
		endif
		runlist[row][4] = num2str(omega[0])
	endif

	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/parameters/twotheta"
	if(!V_flag)
		Wave twotheta = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/parameters","","twotheta",num2str(twotheta[0]),1))
			abort
		endif
	endif
 
	//detector
	if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument","","detector","",1))
		abort
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/longitudinal_translation"
	if(!V_flag)
		Wave longitudinal_translation = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/detector","","longitudinal_translation",num2str(longitudinal_translation[0]),1))
			abort
		endif
	endif

	hdf5loaddata/z/q/o/n=timer hdfref,"/entry1/instrument/detector/time"
	if(!V_flag)
		Wave timer = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/detector","","time",num2str(timer[0]),1))
			abort
		endif
		runlist[row][5] = num2str(timer[0])
	endif
	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/total_counts"
	if(!V_flag)
		Wave total_counts = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/detector","","total_counts",num2str(total_counts[0]),1))
			abort
		endif
		runlist[row][6] = num2str(total_counts[0])
	endif
	
	hdf5loaddata/z/q/o hdfref,"/entry1/monitor/bm1_counts"
	if(!V_flag)
		Wave bm1_counts = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/detector","","total_counts",num2str(bm1_counts[0]),1))
			abort
		endif
		runlist[row][7] = num2str(bm1_counts[0])
	endif
	 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/vertical_translation"
	if(!V_flag)
		Wave vertical_translation = $(stringfromlist(0, S_wavenames))
		if(xmladdnode(xmlref,"//catalogue/nexus["+num2istr(filenum+1)+"]/instrument/detector","","vertical_translation",num2str(vertical_translation[0]),1))
			abort
		endif 
	endif
End

Function catalogueFIZ(pathName[, start, finish])
	String pathName
	variable start, finish

	string cDF = getdatafolder(1)
	string fizfiles,tempStr
	variable temp,ii,jj,firstfile, lastfile, fnum

	newdatafolder/o root:packages
	newdatafolder/o root:packages:platypus
	newdatafolder/o/s root:packages:platypus:catalogue
	
	if(paramisdefault(start))
		start = 1
	endif

	try
		newpath/o/z/q PATH_TO_DATAFILES, pathname
		if(V_flag)
			print "ERROR path to data is incorrect (catalogueFIZ)"
			abort
		endif
	
		fizfiles = sortlist(indexedfile(PATH_TO_DATAFILES,-1,".itx"),";",16)
		fizfiles = replacestring(".itx", fizfiles,"")
		fizfiles = greplist(fizfiles, "^FIZscan")
		
		sscanf stringfromlist(0, fizfiles), "FIZscan%d%*[.]itx", firstfile
		sscanf stringfromlist(itemsinlist(fizfiles)-1, fizfiles),"FIZscan%d%*[.]itx",lastfile
		if(paramisdefault(finish))
			finish = lastfile
		endif
	
		jj = 0

//Note/K position, "data:" + getHipaVal("/experiment/file_name") + ";DAQ:" + grabhistostatus("DAQ_dirname")+";DATE:"+Secs2Date(DateTime,-1) + ";TIME:"+Secs2Time(DateTime,3)+";"

		make/o/t/N=(0, 6) runlist
		for(ii = 0 ; ii < itemsinlist(fizfiles) ; ii+=1)
			sscanf stringfromlist(ii, fizfiles), "FIZscan%d%*[.]itx", fnum
			if(fnum >= firstfile && fnum <= lastfile && fnum >= start && fnum <= finish)
			else
				continue
			endif
			loadWave/o/q/T/P=PATH_TO_DATAFILES, stringfromlist(ii, fizfiles) + ".itx"

			Wave wav0 = $(stringfromlist(0, S_wavenames))
			Wave wav1 = $(stringfromlist(1, S_wavenames))
			
			string theNote = note(wav0)			
			redimension/n=(dimsize(runlist, 0) + 1, -1) runlist						
			runlist[ii][0] = num2str(fnum)
			runlist[ii][1] = num2istr(dimsize(wave0, 0))
			runlist[ii][2] = stringbykey("data", theNote)
			runlist[ii][3] = stringbykey("DAQ", theNote)
			runlist[ii][4] = stringbykey("DATE", theNote)
			runlist[ii][5] = stringbykey("TIME", theNote)
		endfor
		setdimlabel 1,0,run_number, runlist
		setdimlabel 1,1,num_points, runlist
		setdimlabel 1, 2, datefilename, runlist
		setdimlabel 1,3, DAQfolder, runlist
		setdimlabel 1,4,theDate, runlist
		setdimlabel 1,5,theTime, runlist
		edit/k=1/N=Platypus_run_list runlist.ld as "Platypus Run List"
	catch
	endtry

	Killpath/z PATH_TO_DATAFILES

	setdatafolder $cDF
End

Function parseFIZlog(filename, hipadabapaths)
	string filename, hipadabapaths
	variable ii, jj, theTime, theEntry
	make/free/t/n=0/o W_relevantlines
	make/free/t/n=(0)/o W_output
	for(ii = 0 ; ii < itemsinlist(hipadabapaths) ; ii+=1)
		grep/E=(stringfromlist(ii, hipadabapaths)) filename as W_relevantlines
		if(V_Flag)
			abort
		endif
		if(dimsize(W_relevantlines, 0) > dimsize(W_output, 0))
			redimension/n=(dimsize(W_relevantlines, 0), dimsize(W_output, 1) + 1) W_output
		else
			redimension/n=(-1, dimsize(W_output, 1) + 1) W_output		
		endif
		W_output[][ii] = W_relevantlines[p]
	endfor
	//now find out the times and insert them into a log
	make/n=(0, dimsize(W_output, 1) + 1)/T/o M_logEntries
	for(ii = 0 ; ii < dimsize(W_output, 1) ; ii +=1 )
		for(jj = 0 ; jj < dimsize(W_output, 0) ; jj+=1)
			if(strlen(W_output[jj][ii]))
				redimension/n=(dimsize(M_logEntries, 0) + 1, -1) M_logentries
				M_logentries[dimsize(M_logtime, 0) - 1][0] = stringfromlist(0, W_output[jj][ii], "\t")			
				M_logentries[dimsize(W_logtime, 0) - 1][ii + 1] = stringfromlist(2, W_output[jj][ii], "\t")
			endif
		endfor
	endfor
	MDtextsort(M_logentries, 0)
	make/n=(dimsize(M_logentries, 0))/d/o W_logtime = NaN
	W_logtime[] = str2num(M_logentries[p][0])
	deletepoints/M=1 0, 1, M_logentries
End

static Function MDtextsort(w,keycol, [reverse])
	Wave/t w
	variable keycol, reverse
 
	variable ii
 
	make/t/free/n=(dimsize(w,0)) key
	make/o/free/n=(dimsize(w,0)) valindex
 
	key[] = w[p][keycol]
	valindex=p

 	if(!reverse) 		
		sort/a key,key,valindex
	else
		sort/a/r key,key,valindex
	endif
	
	duplicate/free/t w, M_newtoInsert
 
	for(ii=0;ii<dimsize(w,0);ii+=1)
		M_newtoInsert[ii][] = w[valindex[ii]][q]
	endfor
 
	duplicate/o/t M_newtoInsert,w
End
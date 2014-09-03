#pragma rtGlobals=1		// Use modern global access method.

// SVN date:    $Date$
// SVN author:  $Author$
// SVN rev.:    $Revision$
// SVN URL:     $HeadURL$
// SVN ID:      $Id$
#pragma ModuleName = Pla_catalogue

Menu "Platypus"
	"Catalogue HDF data",catalogueNexusdata()
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
	make/o/d/n=(1,4) vgaps, hgaps
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
		
			appendCataloguedata(HDFref, xmlref, jj, stringfromlist(ii,nexusfiles), runlist, vgaps, hgaps)
		
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

	Killpath/z PATH_TO_DATAFILES

	setdatafolder $cDF
End

Function appendCataloguedata(HDFref,xmlref,fileNum,filename, runlist, vgaps, hgaps)
	variable HDFref,xmlref,fileNum
	string filename
	Wave/t runlist
	Wave vgaps, hgaps
	SVAR DAQfiles
	print fileNum
	
	string tempStr
	variable row,fnum
	if(HDFref<1)
		print "ERROR while cataloging, one or more file references incomplete (appendCataloguedata)"
		abort
	endif
	
	//add another row to the runlist
	redimension/n=(fileNum+1,-1) runlist
	redimension/n=(fileNum+1,-1) vgaps, hgaps
	row = dimsize(runlist,0)
	
	
	//filename
	sscanf filename, "PLP%d",fnum
	runlist[row][0] = num2istr(fnum)
	
	//runnum, sample name, vslits, omega, time, detcounts, mon1counts
 
	hdf5loaddata/z/q/o hdfref,"/entry1/start_time"
	if(!V_flag)
		Wave/t start_time = $(stringfromlist(0, S_wavenames))
	endif
	runlist[row][1] = start_time[0]
 

	hdf5loaddata/z/q/o hdfref,"/entry1/user/name"
	if(!V_flag)
		Wave/t name = $(stringfromlist(0, S_wavenames))
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/user/email"
	if(!V_flag)
		Wave/t email = $(stringfromlist(0, S_wavenames))
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/user/phone"
	if(!V_flag)
		Wave/t phone = $(stringfromlist(0, S_wavenames))
	endif
 
	//experiment
	hdf5loaddata/z/q/o hdfref,"/entry1/experiment/title"
	if(!V_flag)
		Wave/t title = $(stringfromlist(0, S_wavenames))
	endif
	
	//sample
 
	hdf5loaddata/z/q/o hdfref,"/entry1/sample/description"
	if(!V_flag)
		Wave/t description = $(stringfromlist(0, S_wavenames))
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/sample/name"
	if(!V_flag)
		Wave/t name = $(stringfromlist(0, S_wavenames))
		runlist[row][2] = name[0]
	endif


	hdf5loaddata/z/q/o hdfref,"/entry1/sample/title"
	if(!V_flag)
		Wave/t title = $(stringfromlist(0, S_wavenames))
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/sample/sth"
	if(!V_flag)
		Wave sth = $(stringfromlist(0, S_wavenames))
	endif
	
	//instrument
 
 	tempstr = ""
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/first/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		hgaps[row][0] = gap[0]
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/first/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])+", "
		vgaps[row][0] = gap[0]
	endif
	 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/second/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		hgaps[row][1] = gap[0]
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/second/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])+", "
		vgaps[row][1] = gap[0]
	endif
	 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/third/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		hgaps[row][2] = gap[0]
	endif
	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/third/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])+", "
		vgaps[row][2] = gap[0]
	endif
 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/third/vertical/st3vt"
	if(!V_flag)
		Wave st3vt = $(stringfromlist(0, S_wavenames))
	endif  
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/fourth/horizontal/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		hgaps[row][3] = gap[0]
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/fourth/vertical/gap"
	if(!V_flag)
		Wave gap = $(stringfromlist(0, S_wavenames))
		tempStr += num2str(gap[0])
		vgaps[row][3] = gap[0]
	endif

	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/slits/fourth/vertical/st4vt"
	if(!V_flag)
		Wave st4vt = $(stringfromlist(0, S_wavenames))
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
		runlist[row][8] = name[0]
		daqfiles += name[0] + ";"
	endif
	
	//parameters
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/parameters/mode"
	if(!V_flag)
		Wave/t mode = $(stringfromlist(0, S_wavenames))
	endif
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/parameters/omega"
	if(!V_flag)
		Wave omega = $(stringfromlist(0, S_wavenames))
		runlist[row][4] = num2str(omega[0])
	endif

	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/parameters/twotheta"
	if(!V_flag)
		Wave twotheta = $(stringfromlist(0, S_wavenames))
	endif
 
	//detector
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/longitudinal_translation"
	if(!V_flag)
		Wave longitudinal_translation = $(stringfromlist(0, S_wavenames))
	endif

	hdf5loaddata/z/q/o/n=timer hdfref,"/entry1/instrument/detector/time"
	if(!V_flag)
		Wave timer = $(stringfromlist(0, S_wavenames))
		runlist[row][5] = num2str(timer[0])
	endif
	
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/total_counts"
	if(!V_flag)
		Wave total_counts = $(stringfromlist(0, S_wavenames))
		runlist[row][6] = num2str(total_counts[0])
	endif
	
	hdf5loaddata/z/q/o hdfref,"/entry1/monitor/bm1_counts"
	if(!V_flag)
		Wave bm1_counts = $(stringfromlist(0, S_wavenames))
		runlist[row][7] = num2str(bm1_counts[0])
	endif
	 
	hdf5loaddata/z/q/o hdfref,"/entry1/instrument/detector/vertical_translation"
	if(!V_flag)
		Wave vertical_translation = $(stringfromlist(0, S_wavenames))
	endif
End

static Function MDindexsort(w, index)
	Wave w, index 
	variable type
 
	type = Wavetype(w) 
 
	if(type == 0)
		Wave/t indirectSource = w
		duplicate/free indirectSource, M_newtoInsert
		Wave/t output = M_newtoInsert
	 	output[][][] = indirectSource[index[p]][q][r]
	 	indirectSource = output
	else
		Wave indirectSource2 = w
		duplicate/free indirectSource2, M_newtoInsert
	 	multithread M_newtoinsert[][][] = indirectSource2[index[p]][q][r]
		multithread indirectSource2 = M_newtoinsert
 	endif 
End

static Function MDsort(w,keycol, [reversed])
	Wave w
	variable keycol, reversed
 
	variable type
 
	type = Wavetype(w)
 
	make/Y=(type)/free/n=(dimsize(w,0)) key
	make/free/n=(dimsize(w,0)) valindex
 
	if(type == 0)
		Wave/t indirectSource = w
		Wave/t output = key
		output[] = indirectSource[p][keycol]
	else
		Wave indirectSource2 = w
		multithread key[] = indirectSource2[p][keycol]
 	endif
 
	valindex=p
 	if(reversed)
 		sort/a/r key,key,valindex
 	else
		sort/a key,key,valindex
 	endif
 
	if(type == 0)
		duplicate/free indirectSource, M_newtoInsert
		Wave/t output = M_newtoInsert
	 	output[][][] = indirectSource[valindex[p]][q][r]
	 	indirectSource = output
	else
		duplicate/free indirectSource2, M_newtoInsert
	 	multithread M_newtoinsert[][][] = indirectSource2[valindex[p]][q][r]
		multithread indirectSource2 = M_newtoinsert
 	endif 
End
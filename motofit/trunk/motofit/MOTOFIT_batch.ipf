#pragma rtGlobals=1		// Use modern global access method.
Function FitRefToListOfWaves()
	//this fits data in a batch, serial manner to a large number of datasets
	//all the reflectivity waves are called :batchwaveN (Qdata), batchwaveN+1 (Rdata), batchwaveN+2 (Edata)
	//it doesn't do multilayers at the moment.
	string callfolder=Getdatafolder(1)
	
	//the data will be contained in the MOTOFIT_batchfits datafolder
	Setdatafolder root:motofit:MOTOFIT_batchfits
	
	//this command sends all the wave names beginning with wave to the string thelist
	String thelist=Wavelist("batchwave*",";","")		
	
	//setupholdstring, all the hold checkboxes are numbered in order h0,h1,h2, etc.
	//USE THE Motofit box for easy access
	Moto_holdstring("",0)
	String holdstring=moto_str("holdstring")
	variable holdbits =  bin2dec(GEN_reverseString(holdstring))
	
	Variable/g root:Motofit:Motofit_batchfits:V_fitOptions = 4 // suppress progress window
	Variable V_FitError = 0 // prevent abort on error
	
	//offset is the value for offsetting the traces in the graphs
	nvar/z offset
	
	Wave coef_Cref=root:coef_Cref
	duplicate/o coef_Cref, temporaryparameterwave
	make/o/t/n=1 temp_text
	make/o/t/n=0 concat_fname
	make/o/d/n=0 concat_Coef
	make/o/d/n=0 concat_Coef_sigma
	make/o/d/n=0 chi_2
	
	controlinfo/W=reflectivitypanel typeoffit
	//if you're doing genetic optimisation
	if(cmpstr(S_Value,"Genetic Optimisation")==0 || cmpstr(S_Value,"Genetic + LM")==0 )
		make/o/d/n=(strlen(holdstring)) batchlimits
		redimension/n=(-1,2) batchlimits
		
		//subset of parameters to be fitted, it's the bestfit vector
		make/o/d/n=0 GEN_b,GEN_parnumber
		//ii is a loop counter, jj will be for how many parameters will vary
		Variable ii=0,jj=0			
		//parse holdstring to see how many are to be held
		//and make a wave with the vectors, this wave is the best fit vector
		for(ii=0;ii<strlen(holdstring);ii+=1)
			if(GEN_isbitset(holdbits,ii)==0)	//we want to fit that parameter
				redimension/n=(numpnts(GEN_b)+1) GEN_b,GEN_parnumber
				GEN_b[numpnts(GEN_b)-1]=temporaryparameterwave[ii]
				GEN_parnumber[numpnts(GEN_parnumber)-1]=ii
				jj+=1
			endif
		endfor
		//this makes a GEN_limits wave, need to reexpand to a user definable limits wave
		GEN_optimise#GEN_setlimitwave(GEN_parnumber,GEN_b)
		Wave GEN_limits
		//doing the reexpansion
		jj=0
		for(ii=0;ii<strlen(holdstring);ii+=1)
			if(GEN_isbitset(holdbits,ii) == 0)	//we want to fit that parameter
				batchlimits[ii][0] = GEN_limits[jj][0]
				batchlimits[ii][1] = GEN_limits[jj][1]
				jj+=1
			endif
		endfor
		killwaves/z GEN_limits,GEN_b,GEN_parnumber
	endif
	
	//use constraints if the wave exists.
	controlinfo/w=reflectivitypanel useconstraint
	String constraint=""
	ii=0
	string test
	Wave/T constraints=root:motofit:reflectivity:constraints
	if(V_Value)
		if (Waveexists(constraints)==0)
			ABORT "no constraint wave exists"
		else
			do
				test=constraints[ii]
				if(strlen(test)==0)
					ABORT "one of the constraint boxes is null"
				endif
				ii+=1
			while(ii<numpnts(constraints))
			//this is the constraint string that goes into the fit command
			constraint="/C=root:motofit:reflectivity:tempconstraints"
			Moto_parse_equalconstraints(constraints)
		endif
	endif
	
	for(ii=1;ii<itemsinlist(theList);ii+=3)
		String aWaveName_Y = cleanupname("batchwave"+num2istr(ii),0)
		String aWaveName_X = cleanupname("batchwave"+num2istr(ii-1),0)
		String aWaveName_E = cleanupname("batchwave"+num2istr(ii+1),0)
		
		Wave aWave= $aWaveName_Y
			
		// /N suppresses screen updates during fitting
		// /Q suppresses history output during fitting
		
		//make a fitwave
		String fitdestination="fit_"+aWaveName_Y,fitx="fitX_"+aWaveName_Y
		Make/o/d/n=(numpnts($aWaveName_Y)) $fitdestination
		Duplicate/o $aWaveName_X $fitx

		//this is the actual fit part
		Moto_repstr("inFIT","1")
		
//		//spoof in dq wave if required
//		string dataset = moto_str("dataset")
//		moto_repstr("dataset","temp__")
//		duplicate/o $aWaveName_X , root:motofit:reflectivity:tempwaves:temp_dq
//		duplicate/o $aWaveName_X , temp_dq
//		Wave temp_dq=root:motofit:GEN_optimise:temp_dq
//		REQUIRED: make a functional form for dq
				
		controlinfo/w=reflectivitypanel useerrors
		string errors=""
		if(V_Value)
			errors="/W="+aWaveName_E+" /I=1"
		endif
		
		string cmd
		controlinfo/W=reflectivitypanel typeoffit
		Strswitch (S_Value)
		case "Genetic Optimisation":
			controlinfo/w=reflectivitypanel useerrors
			if(V_Value)
				cmd="GEN_Curvefit(\"motofit\",root:motofit:Motofit_batchfits:temporaryparameterwave,"+aWaveName_Y+",\""+holdstring+"\""+",x="+aWaveName_x
				cmd+=",w="+aWavename_E+",popsize=20,k_m=0.7,recomb=0.5,iters=50,tol=0.0001,c=batchlimits,q=1)"
				Execute/Z cmd
			else
				cmd="GEN_Curvefit(\"motofit\",root:motofit:Motofit_batchfits:temporaryparameterwave,"+aWaveName_Y+",\""+holdstring+"\""+",x="+aWaveName_x
				cmd+=",popsize=20,k_m=0.7,recomb=0.5,iters=50,tol=0.0001,c=batchlimits,q=1)"
				Execute/Z cmd
			endif
		break
		case "Levenberg - Marquardt":
			cmd="FuncFit/H=\""+holdstring+"\"/N /Q Motofit root:motofit:Motofit_batchfits:temporaryparameterwave "+aWaveName_Y+"/X="+aWaveName_X+" /D="+fitdestination+constraint+errors
			Execute/Z cmd
		break
		case "Genetic + LM":
			controlinfo/w=reflectivitypanel useerrors
			if(V_Value)
				cmd="GEN_Curvefit(\"motofit\",root:motofit:Motofit_batchfits:temporaryparameterwave,"+aWaveName_Y+",\""+holdstring+"\""+",x="+aWaveName_x
				cmd+=",w="+aWavename_E+",popsize=20,k_m=0.7,recomb=0.5,iters=50,tol=0.0001,c=batchlimits,q=1)"
				Execute/Z cmd
				//followupwith curvefit
				cmd="FuncFit/H=\""+holdstring+"\"/N/q Motofit root:motofit:Motofit_batchfits:temporaryparameterwave "+aWaveName_Y+"/X="+aWaveName_X+" /D="+fitdestination+constraint+errors
				Execute/Z cmd
			else
				cmd="GEN_Curvefit(\"motofit\",root:motofit:Motofit_batchfits:temporaryparameterwave,"+aWaveName_Y+",\""+holdstring+"\""+",x="+aWaveName_x
				cmd+=",popsize=20,k_m=0.7,recomb=0.5,iters=50,tol=0.0001,c=batchlimits,q=1)"
				Execute/Z cmd
				//follow up with curvefit
				cmd="FuncFit/H=\""+holdstring+"\"/N /Q Motofit root:motofit:Motofit_batchfits:temporaryparameterwave "+aWaveName_Y+"/X="+aWaveName_X+" /D="+fitdestination+constraint+errors
				Execute/Z cmd
			endif
		break
		endswitch
	
	//replace the existing dataset, if you are fiddling about with dq.
	//	moto_repstr("dataset",dataset)
		
		Moto_repstr("inFIT","0")
				
		//all the coefficients for all the fits are concatenated into single waves
		String coefnote=note ($aWaveName_Y)
		temp_text[0]=coefnote 
		Wave W_Sigma
		NVAR/Z  V_chisq
		redimension /n=(numpnts(chi_2)+1) chi_2
		chi_2[ii]=V_Chisq
		concatenate {W_Sigma},root:motofit:MOTOFIT_batchfits:concat_coef_sigma
		concatenate {temp_text},root:motofit:MOTOFIT_batchfits:concat_fname
		concatenate {root:motofit:motofit_batchfits:temporaryparameterwave},root:motofit:MOTOFIT_batchfits:concat_coef
		
		Note/K $("fit_"+aWaveName_Y)
		Note $("fit_"+aWaveName_Y),coefnote
		
		string traces = tracenamelist("batchdata",";",1)
		variable traceexists = whichlistitem("fit_"+aWaveName_Y,traces,";")
		if(traceexists==-1)
			Appendtograph/W=batchdata $("fit_"+aWaveName_Y) vs $("fitx_"+aWaveName_Y)
			Modifygraph/W=batchdata mode($("fit_"+aWaveName_Y))=0,offset($("fit_"+aWaveName_Y))={0,offset*(((ii+2)/3)-1)}
			modifygraph/W=batchdata rgb($("fit_"+aWaveName_Y))=(0,0,0)
		endif
		doupdate
		print (ii+2)/3
	endfor

	//this is where you get to when there are no more waves to fit
	dowindow/k concatenatedparameters
	edit/K=1/N=concatenatedparameters concat_fname,concat_coef,chi_2	//display the fit waves
	Matrixtranspose concat_fname;Matrixtranspose concat_coef;Matrixtranspose concat_coef_sigma
	Moto_plotbatchresults(concat_coef,holdstring)
	killwaves/Z temp_text,temporaryparameterwave

	Setdatafolder callfolder
End

Function Moto_plotbatchresults(coefwave,holdstring)
	Wave coefwave 
	String holdstring

	variable coefwave_row = dimsize(coefwave,0)
	variable coefwave_col = dimsize(coefwave,1)
	variable coefwave_depth = dimsize(coefwave,2)
	
	make/o/d/n=(coefwave_row) timeslice=p
	variable numplots=0,ii,offset,offsetstart=0,jj=0
	string axisname,tracename

	dowindow/k concatenatedcoefs
	display/n=concatenatedcoefs
	DoWindow/T concatenatedcoefs,"concatenated fit coefficients"
	modifygraph/w=concatenatedcoefs gbRGB=(0,0,0),wbRGB=(0,0,0 )
	
	for(ii=0;ii<strlen(holdstring);ii+=1)
		if(cmpstr(holdstring[ii],"0")==0)
			numplots+=1
		endif
	endfor

	if(numplots==0)
		abort
	endif

	offset = 0.9/numplots

	for(ii=0;ii<strlen(holdstring);ii+=1)
		if(cmpstr(holdstring[ii],"0")==0)
			axisname="L"+num2istr(ii)
			tracename = "concat_coef#"+num2istr(jj)
			appendtograph/w=concatenatedcoefs/L=$axisname coefwave[][ii] vs timeslice
			Modifygraph axisEnab($axisname)={offsetstart,offsetstart+offset}, axisEnab(bottom)={0.05,1},freePos($axisname)={0,bottom}
			Modifygraph tickRGB($axisName )=(65535,65535,65535),tlblRGB($axisName )=(65535,65535,65535),axRGB($axisName )=(65535,65535,65535) 
			ModifyGraph freePos(L1)={0,bottom},tickRGB(bottom)=(65535,65535,65535),tlblRGB(bottom)=(65535,65535,65535),axRGB(bottom)=(65535,65535,65535) 
			ErrorBars $tracename Y,wave=(root:motofit:MOTOFIT_batchfits:concat_Coef_sigma[][ii],root:motofit:MOTOFIT_batchfits:concat_Coef_sigma[][ii])
			offsetstart+=offset+0.1/numplots
			jj+=1
		endif	
	endfor	
End


Function LoadAndGraphAll (pathname)
	//this function loads all the reflectivity files from a specific folder into IGOR, and adds them to a graph
	//At the moment it can only load 3 column data.
	//For ease of fitting all the loaded waves are labelled as (q data) batchWaveN, (Rdata) batchwaveN+1, (Edata) batchwaveN+2
	//However, the filenames are put into the wavenote. 
 
	String pathName // name of symbolic path or "" to get dialog

	//loads all the data into a specific datafolder!
	string saveDF=Getdatafolder(1)
	Newdatafolder/o/s root:motofit
	NewDataFolder/O/S root:motofit:MOTOFIT_batchfits

	//ask for a path to the data
	String fileName,graphname
	Variable ii=0,graphindex
	if (strlen (pathname)==0) // if no path specified, create one
		NewPath /O temporaryPath
		if(V_flag==-1)
			setdatafolder $saveDF
			abort
		endif
		pathname = "temporaryPath"
	endif

	//ask for file details and graph plot options, etc.
	string extension=".out"
	prompt extension,"Enter extension of batch files to be loaded (including .)"
	variable delpoints=0
	prompt delpoints,"delete any points from the start?"
	variable off = 0.5
	prompt off,"offset the datasets in the dataplot? (only use if logR loading)"
	Doprompt "Customise the load and graphing",extension,delpoints,off

	if(V_flag==1)
		setdatafolder $saveDF
		abort
	endif

	variable/g root:motofit:motofit_batchfits:offset
	NVAR/z offset=root:motofit:motofit_batchfits:offset
	offset=off

	//temporary string references to R,Q , dR and Dq data 
	String theWave_R,theWave_Q,theWave_dR,theWave_dQ
	String All_names="",S_Wavenames

	//what is the current plotype
	//1=logR
	//2=linR
	//3=RQ4
	variable plotyp=str2num(moto_str("plotyp"))

	//loop through each file in folder and add it's name to All_names
	//they are by default .out files, you can change the extension to whatever you want
	All_names = IndexedFile($pathName,-1,extension)

	if(itemsinlist(All_names,";")==0)
		ABORT "no files of type "+extension+" found"
	endif
	
	//sort that list to make it alphabetical.
	All_names=SortList(All_names,";", 0)

	// Create new graph for the data
	if(itemsinlist(winlist("batchdata",";","win:1"))==0)
		Display/K=1/N=batchdata 
	endif

	//loop through each file and load it in.
	for(ii=0;ii<itemsinlist(All_names);ii+=1)
		filename=StringFromList(ii,All_Names,";")
	//	LoadWave /q/a/J/D/O/P=$pathName fileName
		LoadWave/a/J/D/K=0/l={0,120,0,1,3}/V={" "," ",0,0}/P=$pathname filename
		if (V_flag==0)  //No waves loaded. Perhaps user cancelled
			ABORT
		endif
		
		//append the data
		string batchwavename = "batchwave"
		batchwavename="batchwave"+num2istr(3*ii+1)
		duplicate/o $StringFromList (1,S_Wavenames, ";"),$batchwavename
		Killwaves $StringFromList (1,S_Wavenames, ";")
		batchwavename="batchwave"+num2istr(3*ii)
		duplicate/o $StringFromList (0,S_Wavenames, ";"),$batchwavename
		Killwaves $StringFromList (0,S_Wavenames, ";")
		batchwavename="batchwave"+num2istr(3*ii+2)
		duplicate/o $StringFromList (2,S_Wavenames, ";"),$batchwavename
		Killwaves $StringFromList (2,S_Wavenames, ";")
		
		wave R=$cleanupname("batchwave"+num2istr(3*ii+1),0)
		Wave Q=$cleanupname("batchwave"+num2istr(3*ii),0)
		Wave dR=$cleanupname("batchwave"+num2istr(3*ii+2),0)

		deletepoints 0,delpoints,R,Q,dR
	
		Moto_removeNAN(q,R,dR,dR)
		//	Wave dQ=$theWave_dQ
	
		//change the data to the required dataset
		switch(plotyp)
			case 1:
				Moto_tologlin(Q,R,dR,1)
				break
			case 3:
				Moto_toRQ4(Q,R,dR,1)	
				break
		endswitch
	
		//make a concatenated version of the data
		duplicate/o R, temp
		temp[]=ii
		concatenate/NP {R},concat_datay
		concatenate/NP {Q},concat_dataq
		concatenate/NP {temp},concat_dataz
	
		AppendtoGraph R vs Q
		theWave_R=nameofwave(R)
		theWave_dR=nameofwave(dR)
		ErrorBars $theWave_R Y,wave=($theWave_dR,$theWave_dR)
		ModifyGraph offset($thewave_R)={0,ii*offset}
	
		Note R,cleanupname(filename+"R",0)
		Note Q,cleanupname(filename+"Q",0)
		Note dR,cleanupname(filename+"E",0)
	
	endfor
	
	duplicate/o concat_dataq,concat_data
	redimension/n=(-1,3) concat_data
	Wave/z concatdata_y,concat_dataz
	concat_data[][2]=concat_datay[p][0]
	concat_data[][1]=concat_dataz[p][0]
	killwaves/z temp,concat_dataq,concat_datay,concat_dataz
	
	switch (Plotyp)
		case 1:
			ModifyGraph log=0
			break
		case 2:
			ModifyGraph log=1
			break
		case 3:
			ModifyGraph log=1
			break
		
	endswitch
	
	//append the theoretical dataset
	Wave R=root:theoretical_R,Q=root:theoretical_Q
	Appendtograph R vs Q
	theWave_R = nameofwave(R)
	ModifyGraph mode($theWave_R)=0,rgb($theWave_R)=(0,0,0)
	
	Label left "Reflectivity"
	Label bottom "Q/Å\\S-1"
	
	setdatafolder Root:
	
	if (exists ("temporaryPath")) //kill temp path if it exists
		KillPath temporaryPath
	endif
	
	setdatafolder $saveDF
	
End
#pragma rtGlobals=3		// Use modern global access method.

// SVN date:    $Date: 2010-06-08 15:39:49 +1000 (Tue, 08 Jun 2010) $
// SVN author:  $Author: andrew_nelson $
// SVN rev.:    $Revision: 223 $
// SVN URL:     $HeadURL: https://motofit.svn.sourceforge.net/svnroot/motofit/motofit/Motofit/MOTOFIT_batch.ipf $
// SVN ID:      $Id: MOTOFIT_batch.ipf 223 2010-06-08 05:39:49Z andrew_nelson $

Function FitRefToListOfWaves()
	//this fits data in a batch, serial manner to a large number of datasets
	//all the reflectivity waves are called :batchwaveN_q,batchwaveN_R, batchwaveN_E, batchwaveN_dq
	//it doesn't do multilayers at the moment.

	DFREF savDF =GetdatafolderDFR()
	string holdstring = "", fitfunc = "motofit", typeoffit
	variable useconstraint = 0, usedqwave = 0, useerrors = 0, ii = 0
	
	try
		//the data will be contained in the MOTOFIT_batchfits datafolder
		setdatafolder root:packages:motofit:MOTOFIT_batchfits
	
		//this command sends all the wave names beginning with batchwave to the string thelist
		String thelist = Wavelist("batchwave*_R",";","")		
	
		//setupholdstring, all the hold checkboxes are numbered in order h0,h1,h2, etc.
		//USE THE Motofit box for easy access
		holdstring = motofit#getmotofitoption("holdstring")
	
		Variable/g root:packages:motofit:Motofit_batchfits:V_fitOptions = 4 // suppress progress window
		Variable V_FitError = 0 // prevent abort on error
	
		//offset is the value for offsetting the traces in the graphs
		nvar/z offset
	
		Wave coef_theoretical_R = root:data:theoretical:coef_theoretical_R
		duplicate/free coef_theoretical_R, coef
		make/free/t/n=1 temp_text
		make/o/t/n=0 concat_fname
		make/o/d/n=0 concat_Coef
		make/o/d/n=0 concat_Coef_sigma
		make/o/d/n=0 chi_2
	
		controlinfo/W=reflectivitypanel typeoffit_tab0
		typeoffit = S_value
		//if you're doing genetic optimisation
		if(stringmatch(S_Value, "Genetic") || stringmatch(S_Value,"Genetic + LM"))
			GEN_setlimitsforGENcurvefit(coef_theoretical_R, holdstring)
		endif

		controlinfo/w=reflectivitypanel useerrors_tab0	
		useerrors = V_Value
		controlinfo/w=reflectivitypanel usedqwave_tab0	
		usedqwave = V_Value
	
		//use constraints if the wave exists.
		controlinfo/w=reflectivitypanel useconstraint_tab0
		useconstraint = V_Value
		if(useconstraint)
			Wave/t constraints = root:packages:motofit:reflectivity:constraintslist
		else
			make/n=0/t/free constraints							
		endif
		
		variable/g Vmullayers = str2num(motofit#getmotofitoption("Vmullayers"))
		variable/g Vappendlayer =  str2num(motofit#getmotofitoption("Vappendlayer"))
		variable/g Vmulrep = str2num(motofit#getmotofitoption("Vmulrep"))
					
		for(ii = 0; ii < itemsinlist(theList) ; ii += 1)
			Wave RR = $("batchwave" + num2istr(ii) + "_R")
			wave qq = $("batchwave" + num2istr(ii) + "_q")
			wave/z dR = $("batchwave" + num2istr(ii) + "_E")
			wave/z dq = $("batchwave" + num2istr(ii) + "_dq")
		
			//make an outputwave
			make/o/n=(numpnts(RR))/d $("fit_batchwave" + num2istr(ii) + "_R")
			make/o/n=(numpnts(RR))/d $("fit_batchwave" + num2istr(ii) + "_q")
			Wave outputRR = $("fit_batchwave" + num2istr(ii) + "_R")
			Wave outputqq = $("fit_batchwave" + num2istr(ii) + "_q")
			outputqq = qq	
		
			string traces = tracenamelist("batchdata",";",1)
			if(whichlistitem(nameofwave(outputRR), traces, ";") == -1)
				Appendtograph/W=batchdata outputRR vs outputQQ
				modifygraph offset($nameofwave(outputRR))={0, ii * offset}, rgb($nameofwave(outputRR)) = (0,0,0)
			endif

			if(usedqwave && waveexists(dq))
				make/free/d/n=(numpnts(RR), 2) inputQQ
				inputQQ[][0] = qq[p]
				inputQQ[][1] = dq[p]
				fitfunc = "motofit_smeared"
			else		
				make/free/d/n=(numpnts(RR)) inputQQ
				inputQQ[] = qq[p]
				fitfunc = "motofit"
			endif
			
			if(!useerrors || !waveexists(dR))
				Waveclear dR
				make/free/d/n=(numpnts(RR)) tempdR = 1
				Wave dR = tempdR
			endif
		
			Strswitch (typeoffit)
				case "Genetic":
					NVAR popsize = root:packages:motofit:old_genoptimise:popsize
					NVAR recomb = root:packages:motofit:old_genoptimise:recomb
					NVAR iterations = root:packages:motofit:old_genoptimise:iterations
					NVAR k_m = root:packages:motofit:old_genoptimise:k_m
					NVAR fittol = root:packages:motofit:old_genoptimise:fittol
					Wave limits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
		
					Gencurvefit/N/Q/D=outputRR/I=1/MAT/W=dR/X=inputQQ/K={iterations, popsize, k_m, recomb}/TOL=(fittol) $fitfunc, RR, coef, holdstring, limits
					break
				case "Levenberg-Marquardt":
					FuncFit/H=holdstring/N/Q/NTHR=0/M=2 $fitfunc coef  RR /X=inputQQ /W=dR /I=1 /C=constraints /D=outputRR /R /A=0
					break
				case "Genetic + LM":
					NVAR popsize = root:packages:motofit:old_genoptimise:popsize
					NVAR recomb = root:packages:motofit:old_genoptimise:recomb
					NVAR iterations = root:packages:motofit:old_genoptimise:iterations
					NVAR k_m = root:packages:motofit:old_genoptimise:k_m
					NVAR fittol = root:packages:motofit:old_genoptimise:fittol
					Wave limits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
		
					Gencurvefit/D=outputRR/I=1/Q/MAT=1/W=dR/X=inputQQ/K={iterations, popsize, k_m, recomb}/TOL=(fittol) $fitfunc, RR, coef, holdstring, limits
					FuncFit/Q=1/H=holdstring/M=2/Q/NTHR=0 $fitfunc coef  RR /X=inputQQ /W=dR /I=1 /D=outputRR /C=constraints
					break
			endswitch
				
			
			//all the coefficients for all the fits are concatenated into single waves
			String coefnote = note (RR)
			temp_text[0]=coefnote 
			Wave W_Sigma
			redimension /n=(numpnts(chi_2)+1) chi_2
			chi_2[ii]=V_Chisq
			concatenate {W_Sigma}, root:packages:motofit:MOTOFIT_batchfits:concat_coef_sigma
			concatenate {temp_text}, root:packages:motofit:MOTOFIT_batchfits:concat_fname
			concatenate {coef}, root:packages:motofit:MOTOFIT_batchfits:concat_coef
		
			Note/K outputRR
			Note outputRR, coefnote
		
			//		appendtograph/w=reflectivitygraph $("fit_"+aWavename_y) vs $("fitx_"+awavename_y)
			//		modifygraph/w=reflectivitygraph rgb($("fit_"+awavename_y)) = (0,0,0)
			//		SetAxis/w=reflectivitygraph bottom 0.0111023,0.0758042
			//		SetAxis/w=reflectivitygraph left -2.5,2
			//		Wave sld = root:sld , zed = root:zed
			//		sld = moto_sldplot(root:packages:motofit:motofit_batchfits:temporaryparameterwave,zed)
			//		doupdate
			//		dowindow/f reflectivitygraph
			//		addmovieframe
			//		variable kk
			//		string wally = tracenamelist("reflectivitygraph",";",1)
			//		for(kk=0;kk<itemsinlist(wally);kk+=1)
			//			removefromgraph/w=reflectivitygraph $(stringfromlist(kk,wally))
			//		endfor
			//		doupdate
		
			print (ii)
		endfor

		//	closemovie
	
		//this is where you get to when there are no more waves to fit
		dowindow/k concatenatedparameters
		edit/K=1/N=concatenatedparameters concat_fname,concat_coef,chi_2	//display the fit waves
		Matrixtranspose concat_fname
		Matrixtranspose concat_coef
		Matrixtranspose concat_coef_sigma
		Moto_plotbatchresults(concat_coef, holdstring)
	catch
	endtry
	Setdatafolder savDF
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
			ModifyGraph tickRGB(bottom)=(65535,65535,65535),tlblRGB(bottom)=(65535,65535,65535),axRGB(bottom)=(65535,65535,65535) 
			ErrorBars $tracename Y,wave=(root:packages:motofit:MOTOFIT_batchfits:concat_Coef_sigma[][ii],root:packages:motofit:MOTOFIT_batchfits:concat_Coef_sigma[][ii])
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
	dfref saveDF = GetdatafolderDFR()
	newdatafolder /o root:packages
	Newdatafolder/o/s root:packages:motofit
	NewDataFolder/O/S root:packages:motofit:MOTOFIT_batchfits

	try
		//ask for a path to the data
		String fileName,graphname
		Variable ii=0,graphindex, jj
		if (strlen (pathname)==0) // if no path specified, create one
			NewPath /O temporaryPath
			if(V_flag==-1)
				setdatafolder saveDF
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
			setdatafolder saveDF
			abort
		endif

		variable/g root:packages:motofit:motofit_batchfits:offset
		NVAR/z offset=root:packages:motofit:motofit_batchfits:offset
		offset=off

		//temporary string references to R,Q , dR and Dq data 
		String All_names="", S_Wavenames

		//what is the current plotype
		variable plotyp=str2num(motofit#getmotofitoption("plotyp"))

		//loop through each file in folder and add it's name to All_names
		//they are by default .out files, you can change the extension to whatever you want
		All_names = IndexedFile($pathName, -1, extension)

		if(itemsinlist(All_names,";")==0)
			ABORT "no files of type "+extension+" found"
		endif
	
		//sort that list to make it alphanumeric a0, a1, a9, a10, etc.
		All_names=SortList(All_names,";", 16)

		// Create new graph for the data
		if(itemsinlist(winlist("batchdata",";","win:1"))==0)
			Display/K=1/N=batchdata 
		endif

		//loop through each file and load it in.
		for(ii = 0; ii<itemsinlist(All_names) ; ii += 1)
			filename=StringFromList(ii, All_Names, ";")
			LoadWave/Q/G/D/A/P=$pathName fileName
			//		LoadWave/q/a/J/D/K=0/V={"\t, "," $",0,0}/L={0,1,0,0,3}/P=$pathname filename
			//		LoadWave/a/J/D/K=0/l={0,120,0,1,3}/V={" "," ",0,0}/P=$pathname filename
			if (V_flag==0)  //No waves loaded. Perhaps user cancelled
				ABORT
			endif
		
			//append the data
			string batchwavename = "batchwave"
			batchwavename="batchwave" + num2istr(ii)
			duplicate/o $StringFromList (0, S_Wavenames, ";"), $(batchwavename + "_q")
			duplicate/o $StringFromList (1, S_Wavenames, ";"), $(batchwavename + "_R")
			Wave qq = $(batchwavename + "_q")
			Wave RR = $(batchwavename + "_R")
			note/k RR
			note/nocr RR, S_filename
			deletepoints 0, delpoints, RR, qq

			if(itemsinlist(S_wavenames) > 2)
				duplicate/o $StringFromList (2, S_Wavenames, ";"), $(batchwavename + "_E")
				Wave dR = $(batchwavename + "_E")
				deletepoints 0, delpoints, dR
			endif
			if(itemsinlist(S_wavenames) > 3)
				duplicate/o $StringFromList (3,S_Wavenames, ";"), $(batchwavename + "_dq")
				Wave dQ = $(batchwavename + "_dq")
				deletepoints 0, delpoints, dQ
			endif
			for(jj = 0 ; jj < itemsinlist(S_wavenames) ; jj+=1)
				killwaves/z $(stringfromlist(jj, S_wavenames))
			endfor

			motofit#Moto_removeNAN(qq,RR,dR,dq)
	
			moto_lindata_to_plotyp(plotyp, qq, RR, dR = dR, dq = dq, removeNonFinite = 1)
	
			if(whichlistitem(nameofwave(RR), tracenamelist("batchdata", ";", 1)) == -1)
				AppendtoGraph RR vs qq
				ErrorBars $nameofwave(RR) Y,wave=($nameofwave(dR),$nameofwave(dR))
				ModifyGraph offset($nameofwave(RR))={0,ii*offset}	
			endif
			Waveclear RR, qq, dr, dq
		endfor
		
		switch (Plotyp)
			case 1:
				ModifyGraph log=0
				break
			case 2:
			case 3:
			case 4:
				ModifyGraph log=1
				break		
		endswitch
	
		//append the theoretical dataset
		Wave RR=root:data:theoretical:theoretical_R, qq=root:data:theoretical:theoretical_Q
		if(whichlistitem(nameofwave(RR), tracenamelist("batchdata", ";", 1)) == -1)
			Appendtograph RR vs qq
			ModifyGraph mode(theoretical_R)=0,rgb(theoretical_R)=(0,0,0)
		endif
		
		Label left "Reflectivity"
		Label bottom "Q /A\\S-1"
		
		if (exists ("temporaryPath")) //kill temp path if it exists
			KillPath temporaryPath
		endif
	catch
	endtry
	setdatafolder saveDF
End
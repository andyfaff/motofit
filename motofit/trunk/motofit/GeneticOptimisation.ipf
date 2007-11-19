#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName= GEN_optimise
///GeneticOptimisation is a IGOR PRO procedure that fits data using a Genetic Algorithm method :written by Andrew Nelson
//Copyright (C) 2006 Andrew Nelson and Australian Nuclear Science and Technology Organisation
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

//GeneticOptimisation is a powerful code to fit data, and is an extremely good method of finding global minima in the optimisation map
//The procedure uses the algorithm given in:
//
// Wormington et al, Characterization of structures from X-ray scattering data using genetic algorithms, Phil. Trans. R. Soc. Lond. A (1999) 357, 2827-2848
//
//The software should be compatible with Macintosh/PC/NT platforms and requires that IGOR Pro* is installed. 
//You do not have to purchase IGOR Pro - a free demo version of IGOR Pro is available, however some utilities are disabled (such as copying to/from the clipboard)
//IGOR Pro is a commercial software product available to Mac/PC/NT users. 
//A free demo version of IGOR is available from WaveMetrics Inc. These experiments and procedures were created using IGOR Pro 5.04
//The routines have not been tested on earlier versions of IGOR.


//version history
//26/6/06 AG(Wavemetrics) added some speedups.  Search for his name to see what he did.  He made some modifications which should be used as
//	soon as Igor6 comes online.
	
Menu "Motofit"
	"Genetic Optimisation", GEN_optimise#GEN_panelinitialise()
End

Structure GEN_optimisation
Wave GEN_parwave		//what are the initial parameters?
String GEN_parwavename

String GEN_holdstring		//the holdstring for holding parameters
Variable GEN_holdBits	//an integer representation of holdstring
variable GEN_numvarparams

Wave GEN_limits			//what are the limits on your parameters?
Wave GEN_b			//what is the best fit so far?
Funcref GEN_allatoncefitfunc fin	//what fit function are you going to use?
Funcref GEN_fitfunc fan
Variable GEN_popsize
Variable k_m
Wave GEN_trial
Wave GEN_yy
string GEN_ywavename
Wave GEN_xx
Wave GEN_ee
String GEN_ywaveDF
String GEN_xwaveDF
String GEN_ewaveDF
String GEN_parwaveDF	
Wave GEN_yybestfit
Variable GEN_generations	
Variable GEN_recombination
Wave GEN_chi2matrix
Wave GEN_populationvector
Wave GEN_bprime
Wave GEN_pvector
variable GEN_currentpvector
variable GEN_chi2best
variable GEN_whattype
Variable GEN_V_fittol
Wave GEN_parnumber
String GEN_callfolder
variable GEN_quiet //don't print stuff in history area
Endstructure

//GUI bit
Static Function GEN_panelinitialise()
	//this setsup the GUI for performing geneticoptimisation
	Newdatafolder/o root:motofit
	Newdatafolder/o root:motofit:GEN_optimise
	
	if(!waveexists(root:motofit:GEN_optimise:GEN_listselwave) || !waveexists(root:motofit:GEN_optimise:GEN_listwave))
		variable/g root:motofit:GEN_optimise:GEN_numpars=0
		Make/o/n=(0,3) root:motofit:GEN_optimise:GEN_listselwave
		Make/o/n=(0,3)/T root:motofit:GEN_optimise:GEN_listwave
	endif
	
	Wave/T GEN_listwave=root:motofit:GEN_optimise:GEN_listwave
	string alreadyexists=Winlist("geneticoptimisation",";","WIN:64")
	if(strlen(alreadyexists)==0)
		PauseUpdate; Silent 1		// building window...
		NewPanel/k=1 /W=(150,77,558,500)/N=geneticoptimisation
		SetDrawLayer UserBack
		DrawText 32,195,"Parameter"
		DrawText 180,195,"Value"
		DrawText 318,195,"hold?"
		SetVariable GEN_numpars,pos={13,31},size={180,16},proc=GEN_panelexpandpars,title="Number of Parameters"
		SetVariable GEN_numpars,limits={0,inf,1},value= root:motofit:GEN_optimise:GEN_numpars
		PopupMenu GEN_fitfuncselection,pos={13,6},size={207,21},title="Fit function"
		PopupMenu GEN_fitfuncselection,mode=1,bodyWidth= 150,popvalue="_none_",value= #"Functionlist(\"*\",\";\",\"KIND:10,SUBTYPE:Fitfunc\")+Functionlist(\"*\",\";\",\"KIND:12,SUBTYPE:Fitfunc\")"
		PopupMenu GEN_ywave,pos={13,53},size={205,21},proc=GEN_panelfitselection,title="y wave"
		PopupMenu GEN_ywave,mode=1,bodyWidth= 166,popvalue="_none_",value= "_none_;"+GEN_panelretwavewithxpar("GEN_ywave",0,"")
		PopupMenu GEN_xwave,pos={13,77},size={204,21},proc=GEN_panelfitselection,title="x wave"
		PopupMenu GEN_xwave,mode=1,bodyWidth= 165,popvalue="_calculated_",value= "_calculated_;"+GEN_panelretwavewithxpar("GEN_xwave",0,"")
		PopupMenu GEN_ewave,pos={13,100},size={204,21},proc=GEN_panelfitselection,title="e wave"
		PopupMenu GEN_ewave,mode=1,bodyWidth= 164,popvalue="_none_",value= "_none_;"+GEN_panelretwavewithxpar("GEN_ewave",0,"")
		//	PopupMenu GEN_setDF title="Select datafolder",value=GEN_listdatafolders()
		PopupMenu loadfromwave,pos={13,148},size={204,21},proc=GEN_panelsetorsavewave,title="Set from Wave"
		PopupMenu loadfromwave,mode=1,bodyWidth= 128,popvalue="_none_",value=GEN_panelretwavewithxpar("loadfromwave",0,"")
		PopupMenu savewave,pos={13,124},size={205,21},proc=GEN_panelsetorsavewave,title="Save to wave"
		PopupMenu savewave,mode=1,bodyWidth= 134,popvalue="new wave...",value= #"\"new wave...;\"+GEN_panelretwavewithxpar(\"savewave\",0,\"\")"
		Button GEN_dofit,pos={260,19},size={66,28},title="Do fit",proc=GEN_optimise#GEN_panelDofitbutton
		CheckBox usecursors title="Fit between cursors?",pos={230,66}
		Popupmenu usemaskwave title="Use mask wave?",pos={230,87},popvalue="_none_",value="_none_;"+GEN_panelretwavewithxpar("usemaskwave",0,"")
		CheckBox appendfit title="Append fit to top graph?",pos={230,111}
		
		ListBox GEN_par,pos={18,200},size={346,200}
		ListBox GEN_par,listWave=root:motofit:GEN_optimise:GEN_listwave
		ListBox GEN_par,selWave=root:motofit:GEN_optimise:GEN_listselwave,mode= 8,editStyle= 1
		ListBox GEN_par,widths={40,100,10},userColumnResize= 1
	else
		Dowindow/F geneticoptimisation
	endif
End

Static Function/S GEN_listdatafolders()
	String datafolders="root:;"
	String additionalfolders=DataFolderDir(1)
	additionalfolders=additionalfolders[8,strlen(additionalfolders)]
	additionalfolders=replacestring(",",additionalfolders,";")
	additionalfolders=removefromlist("SLDdatabase",additionalfolders)
	additionalfolders=removefromlist("GEN_optimise",additionalfolders)
	return datafolders+additionalfolders
End

Function GEN_panelexpandpars (ctrlname,varNum,varStr,varName) : Setvariablecontrol
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	variable ii
	Wave GEN_listselwave=root:motofit:GEN_optimise:GEN_listselwave
	Wave/T GEN_listwave=root:motofit:GEN_optimise:GEN_listwave
	Redimension/n=(varNum,3) GEN_listselwave,GEN_listwave
	for(ii=0;ii<varNum;ii+=1)
		GEN_listselwave[ii][2]=32
		GEN_listselwave[ii][1]=2
		GEN_listwave[ii][0]=num2istr(ii)
	endfor
End

Function GEN_panelsetorsavewave(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
	string newwavename
	variable ii=0
	Wave/z/t localrefsource=root:motofit:GEN_optimise:GEN_listwave
	
	strswitch(ctrlname)
		case "loadfromwave":
			newwavename=popstr
			Wave/Z localref=$newwavename
			for(ii=0;ii<dimsize(localrefsource,0);ii+=1)
				localrefsource[ii][1]=num2str(localref[ii])
			endfor
			break
		case "savewave":
			strswitch(popstr)
				case "new wave...":
					prompt newwavename,"Enter a new wave name"
					Doprompt "Enter new wave name",newwavename
					if(V_flag==1)
						abort
					else
						make/o/d/n=(dimsize(localrefsource,0)) $newwavename
						Wave localref=$newwavename
						for(ii=0;ii<dimsize(root:motofit:GEN_optimise:GEN_listwave,0);ii+=1)
							localref[ii]=str2num(localrefsource[ii][1])
						endfor
					endif
					break
				default:
					newwavename=popstr
					Wave localref=$newwavename
					for(ii=0;ii<dimsize(root:motofit:GEN_optimise:GEN_listwave,0);ii+=1)
						localref[ii]=str2num(localrefsource[ii][1])
					endfor
					break
			endswitch
			break
	endswitch
End

Function/S GEN_panelfitselection(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
	string otherselection
	strswitch(ctrlname)
		case "GEN_ywave":
			controlinfo/W=geneticoptimisation GEN_xwave
			if(cmpstr("_calculated_",S_Value))
				if(numpnts($S_Value)-numpnts($popstr)!=0)
					Killcontrol/W=geneticoptimisation GEN_xwave
					PopupMenu GEN_xwave,pos={13,77},size={204,21},title="x wave",proc=GEN_panelfitselection
					PopupMenu GEN_xwave,mode=1,bodyWidth= 164,popvalue="choose again",value="_calculated_;"+GEN_panelretwavewithxpar("GEN_xwave",0,"")
				endif
			endif
			controlinfo/W=geneticoptimisation GEN_ewave
			if(cmpstr("_none_",S_Value))
				if(numpnts($S_Value)-numpnts($popstr)!=0)
					Killcontrol/W=geneticoptimisation GEN_ewave
					PopupMenu GEN_ewave,pos={13,100},size={204,21},title="e wave",proc=GEN_panelfitselection
					PopupMenu GEN_ewave,mode=1,bodyWidth= 164,popvalue="choose again",value="_none_;"+GEN_panelretwavewithxpar("GEN_ewave",0,"")
				endif
			endif
			controlinfo/W=geneticoptimisation usemaskwave
			if(cmpstr("_none_",S_Value))
				if(numpnts($S_Value)-numpnts($popstr)!=0)
					Killcontrol/W=geneticoptimisation usemaskwave
					Popupmenu usemaskwave title="Use mask wave?",pos={230,87},popvalue="_none_",value="_none_;"+GEN_panelretwavewithxpar("usemaskwave",0,"")
				endif
			endif
			break
	endswitch
End

Function/S GEN_panelretwavewithxpar(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

	string wavelisting,cmd
	variable ii

	NVAR/Z GEN_numpars=root:motofit:GEN_optimise:GEN_numpars
	strswitch(ctrlname)
		case "loadfromwave":
			cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MAXROWS:"+num2istr(GEN_numpars)+",MINROWS:"+num2istr(GEN_numpars)
			wavelisting=WaveList("*", ";",cmd)
			break
		case "savewave":
			cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MAXROWS:"+num2istr(GEN_numpars)+",MINROWS:"+num2istr(GEN_numpars)
			wavelisting=WaveList("*", ";",cmd)
			break
		case "GEN_ywave":
			cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0"
			wavelisting=WaveList("*", ";",cmd)
			break
		case "GEN_xwave":
			controlinfo/W=GeneticOptimisation GEN_ywave
			if(!cmpstr(S_Value,"_none_"))
				cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0"
				wavelisting=WaveList("*", ";",cmd)
			else
				ii=numpnts($S_Value)
				cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MAXROWS:"+num2istr(ii)+",MINROWS:"+num2istr(ii)
				wavelisting=WaveList("*", ";",cmd)
			endif
			break
		case "GEN_ewave":
			controlinfo/W=GeneticOptimisation GEN_ywave
			if(!cmpstr(S_Value,"_none_"))
				cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0"
				wavelisting=WaveList("*", ";",cmd)
			else
				ii=numpnts($S_Value)
				cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MAXROWS:"+num2istr(ii)+",MINROWS:"+num2istr(ii)
				wavelisting=WaveList("*", ";",cmd)
			endif
			break
		case "usemaskwave":
			controlinfo/W=geneticoptimisation GEN_ywave
			if(!cmpstr(S_Value,"_none_"))
				cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0"
				wavelisting=WaveList("*", ";",cmd)
			else
				ii=numpnts($S_Value)
				cmd="DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0,MAXROWS:"+num2istr(ii)+",MINROWS:"+num2istr(ii)
				wavelisting=WaveList("*", ";",cmd)
			endif
			break
	endswitch

	return wavelisting
End

Static Function GEN_panelDofitbutton(ctrlName) : ButtonControl
	String ctrlName
	String cmd="GEN_curvefit(\""
	
	//add fitfunctioname
	controlinfo/W=geneticoptimisation GEN_fitfuncselection
	if(cmpstr(S_Value,"_none_")==0)
		ABORT "Select a fitfunction"
	endif
	cmd+=S_Value+"\","
	
	//add parwave name
	//but first you have to make it from the panel
	variable ii
	Wave/T localref=root:motofit:GEN_optimise:GEN_listwave
	Wave localrefsel=root:motofit:GEN_optimise:GEN_listselwave
	make/o/d/n=(dimsize(localref,0)) root:motofit:GEN_optimise:GEN_tempparwave
	Wave GEN_tempparwave=root:motofit:GEN_optimise:GEN_tempparwave
	
	for(ii=0;ii<dimsize(root:motofit:GEN_optimise:GEN_listwave,0);ii+=1)
		GEN_tempparwave[ii]=str2num(localref[ii][1])
	endfor
	cmd+="root:motofit:GEN_optimise:GEN_tempparwave,"
	
	string abortmsg="Please enter a valid "
	//now add in the datawaves
	controlinfo/W=geneticoptimisation GEN_ywave
	String y_wavename=S_Value
	if(cmpstr(S_Value,"_none_")==0)
		ABORT abortmsg+"ywave"
	else
		cmd+=possiblyquotename(S_Value)+","
	endif
	
	//add on holdstring
	string holdstring=""
	for(ii=0;ii<dimsize(localrefsel,0);ii+=1)
		holdstring+=num2istr(GEN_isbitset(localrefsel[ii][2],4))
	endfor
	cmd+="\""+holdstring+"\""
	
	//which xwave
	controlinfo/W=geneticoptimisation GEN_xwave
	if(cmpstr(S_Value,"_calculated_") == 0)
	elseif(cmpstr(S_Value,"choose again") == 0)
		ABORT abortmsg+"xwave"
	else
		cmd+=",x="+possiblyquotename(S_Value)
	endif
	
	//which ewave
	controlinfo/W=geneticoptimisation GEN_ewave
	String e_wavename=S_Value
	if(cmpstr(S_Value,"choose again")==0)
		ABORT abortmsg+"ewave"
	elseif(cmpstr(S_Value,"_none_")==0)
	else
		cmd+=",w="+possiblyquotename(S_Value)
	endif
	
	try	//the user might abort halfway through
		controlinfo/W=geneticoptimisation usemaskwave
		variable usemaskwave=cmpstr(S_Value,"_none_")
		string maskwave=S_Value
		Wave maskwaveref=$S_Value
		if(usemaskwave)	//the user wants to use a mask wave, assume that they don't want to use cursors
			//create temporary copies of the data
			//this is because you're deleting points from the users wave
			//so remember to replace the points when you've finished doing the fit
			cmd+=",mask="+S_Value
		endif
		
		//do you want to use cursors
		controlinfo/W=geneticoptimisation usecursors
		variable usecursors=V_Value
		if(usecursors)	//the user wants to use cursors
			cmd+=",cursors=1"
		endif
				
		//need to know the topgraph, so we can append to it later
		string topgraph=WinName(0,1)
		
		//do the genetic optimisation
		cmd+=")"
		print cmd
		Execute/Q/Z cmd
				
		//append the fits
		controlinfo/W=geneticoptimisation appendfit
		if(V_Value)
			string fitname="fit_"+y_wavename,fitxname="fitx_"+y_wavename
			Appendtograph/w=$topgraph $fitname vs $fitxname
		endif 
		
		//update the listbox
		//this wave contains the best fit at the end
		Wave GEN_parwave=root:motofit:GEN_optimise:GEN_parwave
	
		for(ii=0;ii<dimsize(root:motofit:GEN_optimise:GEN_listwave,0);ii+=1)
			localref[ii][1]=num2str(GEN_parwave[ii])
		endfor
		string coefwavestr = "coef_"+y_wavename
		make/o/d/n=(dimsize(localref,0)) $coefwavestr
		Wave coefwave = $coefwavestr
		for(ii=0;ii<dimsize(localref,0);ii+=1)
			coefwave[ii] = str2num(localref[ii][1])
		endfor
	catch
		for(ii=0;ii<dimsize(root:motofit:GEN_optimise:GEN_listwave,0);ii+=1)
			localref[ii][1]=num2str(GEN_parwave[ii])
		endfor
		coefwavestr = "coef_"+y_wavename
		make/o/d/n=(dimsize(localref,0)) $coefwavestr
		Wave coefwave = $coefwavestr
		for(ii=0;ii<dimsize(localref,0);ii+=1)
			coefwave[ii] = str2num(localref[ii][1])
		endfor
	endtry	
End

Function/S dec2bin(int)
	variable int
	string binary="",bin=""
	variable ii=0,remainder
	do
		binary+=num2istr(mod(int,2))
		int=floor(int/2)
	while(int!=0)
	//now reverse order of binary to get proper number
	for(ii=strlen(binary);ii>-1;ii-=1)
		bin+=binary[ii]
	endfor
	
	return bin
End

Function/S GEN_holdallstring(numvarparams)
	variable numvarparams
	variable ii
	string str=""
	for(ii=0 ; ii<numvarparams ; ii+=1)
		str+="1"
	endfor
	return str
End

Function bin2dec(bin)
	string bin
	variable int=0
	variable ii, binlen = strlen(bin) -1

	for(ii=strlen(bin)-1 ; ii>-1 ; ii-=1)
		if(cmpstr(bin[ii],"1") == 0)
			int+=2^(binlen - ii)
		endif
	endfor
	return int
End

Function GEN_isbitset(value,bit)
	variable value,bit
	
	string binary=dec2bin(value)
	
	//if you want to examine bits higher than the logical size of the holdvalue then they must
	//not be "set"
	//e.g. holdstring is 110
	// Gen_reverseString("110") returns "011"
	// bin2dec("011") returns 3
	// GEN_isbitset(3,2) should return 0.
	
	if(bit>strlen(binary)-1)
		return 0
	endif
	
	variable bool=str2num(binary[strlen(binary)-bit-1])
	
	return bool
End

Function/S GEN_reverseString(str)
	//this function reverses the string order because bits are set from RHS
	string str
	string localcopystr = str
	str = ""
	variable ii
	//now reverse order of binary to get proper number
	for(ii=strlen(localcopystr);ii>-1;ii-=1)
		str +=localcopystr[ii]
	endfor
	return str
End

//HERE'S WHERE YOU START IF YOU WANT TO FIT PROGRAMATICALLY
Function GEN_curvefit(func,parwave,ywave,holdstring,[x,w,c,mask,cursors,popsize,k_m,recomb,iters,tol,q])
	//this is the first insertion to the GENETIC optimisation
	//you need the function
	//the initial parameter wave
	//the holdstring
	//and the data you want to fit
	String func
	Wave parwave,ywave
	String holdstring
	Wave x,w,c,mask
	variable cursors,popsize,k_m,recomb,iters,tol,q
	
	//use the GEN_optimisation structure	
	Struct GEN_optimisation gen
	
	//where are you calling the function from?
	//these are so you can retun the output to the right places.
	gen.GEN_callfolder=getdatafolder(1)

	//make the datafolders for the fitting
	Newdatafolder/o root:motofit
	Newdatafolder/o root:motofit:GEN_optimise
		
	//what type of fit function?
	variable whattype=Numberbykey("N_Params",Functioninfo(func))
	gen.GEN_whattype=whattype
	if(gen.GEN_whattype==2)			//point by point fit function
		Funcref GEN_fitfunc gen.fan=$func
	elseif(gen.GEN_whattype==3)		//all at once fit function 
		Funcref GEN_allatoncefitfunc gen.fin=$func
	endif
	
	//does the user want to operate in quiet mode?
	//check the maskwave and cursors
	if(ParamIsDefault(q))
		gen.GEN_quiet=0
	else
		if(q!=0)
			q=1
		endif
		gen.GEN_quiet=q
	endif

	
	//check the ywave and store its datafolder
	if(!waveexists(ywave))
		setdatafolder $gen.GEN_callfolder
		abort "y wave doesn't exist"
	elseif(dimsize(ywave,1)>0)
		setdatafolder $gen.GEN_callfolder
		abort "can only fit 1D data at this time"
	elseif(dimsize(ywave,0)==0)
		setdatafolder $gen.GEN_callfolder
		abort "y wave has no points to fit"
	else
		gen.GEN_ywaveDF=Getwavesdatafolder(ywave,1)
		duplicate/o ywave,root:motofit:GEN_optimise:GEN_yy
	endif
	
	//check the parwave and store its datafolder
	if(!waveexists(parwave))
		setdatafolder $gen.GEN_callfolder
		abort "parameter wave doesn't exist"
	elseif(dimsize(parwave,1)>0)
		setdatafolder $gen.GEN_callfolder
		abort "can only use a 1D parameter wave at this time"
	elseif(dimsize(parwave,0)==0)
		setdatafolder $gen.GEN_callfolder
		abort "coefficient wave contains no parameters"
	else
		gen.GEN_parwaveDF=Getwavesdatafolder(parwave,2)
		duplicate/o parwave,root:motofit:GEN_optimise:GEN_parwave
	endif
	
	//check the xwave (x) and store it's datafolder
	if(ParamIsDefault(x))		//you're going to be using the ywave scaling
		make/o/d/n = (dimsize(ywave,0)) root:motofit:GEN_optimise:GEN_xx = leftx(ywave)+p*dimdelta(ywave,0)
	elseif(!ParamisDefault(x))	//the user specified an xwave
		if(!waveexists(x))
			setdatafolder $gen.GEN_callfolder
			abort "x wave doesn't exist"
		elseif(dimsize(x,1)>0)
			setdatafolder $gen.GEN_callfolder
			abort "can only use a 1D x wave at this time"
		elseif(dimsize(x,0)!=dimsize(ywave,0))
			setdatafolder $gen.GEN_callfolder
			abort "x wave requires same number of points as y wave" 
		else
			gen.GEN_xwaveDF=Getwavesdatafolder(x,1)
			duplicate/o x,root:motofit:GEN_optimise:GEN_xx
		endif
	endif
	 
	//check the weightwave and store its datafolder
	if(ParamIsDefault(w))		//you're going to be fitting with unit weights
		make/o/d/n=(dimsize(ywave,0)) root:motofit:GEN_optimise:GEN_ee=1
	elseif(!ParamisDefault(w))	//the user specified an weightwave
		if(!waveexists(w))
			setdatafolder $gen.GEN_callfolder
			abort "weight wave doesn't exist"
		elseif(dimsize(w,1)>0)
			setdatafolder $gen.GEN_callfolder
			abort "can only use a 1D weight wave at this time"
		elseif(dimsize(w,0)!=dimsize(ywave,0))
			setdatafolder $gen.GEN_callfolder
			abort "weight wave requires same number of points as y wave" 
		else
			gen.GEN_ewaveDF=Getwavesdatafolder(w,1)
			duplicate/o w,root:motofit:GEN_optimise:GEN_ee
		endif
	endif	
		
	//check the maskwave and cursors
	variable ii=0
	if(ParamIsDefault(mask) == 0)
		if(!waveexists(mask))
			setdatafolder $gen.GEN_callfolder
			abort "specified mask wave doesn't exist"
		elseif(dimsize(mask,1)>0)
			setdatafolder $gen.GEN_callfolder
			abort "can only use a 1D mask wave at this time"
		elseif(dimsize(mask,0)!=dimsize(ywave,0))
			setdatafolder $gen.GEN_callfolder
			abort "mask wave requires same number of points as y wave" 
		else
			duplicate/o mask,root:motofit:GEN_optimise:GEN_mask
		endif
	endif
	
	//check the holdstring
	if(strlen(holdstring)!=dimsize(parwave,0))
		setdatafolder $gen.GEN_callfolder
		abort "holdstring needs to be same length as coefficient wave"
	endif
	
	gen.GEN_holdstring = holdstring
	gen.GEN_numvarparams=0
		
	variable test = strlen(holdstring)
	for(ii=0;ii<strlen(holdstring);ii+=1)
		if(cmpstr(holdstring[ii],"0") == 0)
			gen.GEN_numvarparams += 1
		endif
		if(cmpstr(holdstring[ii],"0") != 0)
			if(cmpstr(holdstring[ii],"1") != 0)
				setdatafolder $gen.GEN_callfolder
				abort "holdstring can only contain 0 (vary) or 1 (hold)"
			endif
		endif
	endfor
	gen.GEN_holdBits = bin2dec(GEN_reverseString(holdstring))
	
	//Setdatafolder to Genetic Optimisation
	setdatafolder root:motofit:gen_optimise
	
	//setup wave references.
	Wave gen.GEN_yy=GEN_yy,gen.GEN_parwave=GEN_parwave,gen.GEN_ee=GEN_ee,gen.GEN_xx=GEN_xx,GEN_mask
	gen.GEN_parwavename=nameofwave(parwave)
	gen.GEN_ywavename=nameofwave(ywave)

	variable nit
	//search for any cursors, masked points, then NaN's to remove non-relevant points from wave
	if(ParamisDefault(cursors)==0)	//the user wants to use cursors
		if (WaveExists(CsrWaveRef(A)) %& WaveExists(CsrWaveRef(B)))
			if (CmpStr(CsrWave(A),CsrWave(B)) != 0)
				abort "The cursors are not on the same wave. Please move them so that they are."
			endif
		else
			abort "The cursors must be placed on the top graph.  Select Show Info from the Graph menu for access to the cursors."
		endif
		if(cmpstr(CsrWave(A,"",1),nameofwave(ywave)) || cmpstr(CsrWave(B,"",1),nameofwave(ywave)))
			Doalert 1,"One of the cursors is not on the dataset you selected, continue?"
			if(V_flag==2)
				ABORT
			endif
		endif
		Variable start=pcsr(A),finish=pcsr(B),temp
		if(start>finish)
			temp=finish
			finish=start
			start=temp
		endif
		//create temporary copies of the data
		//this is because you're deleting points from the users wave
		//so remember to replace the points when you've finished doing the fit
		if(ParamisDefault(mask) == 0)
			Deletepoints 0,start, gen.GEN_yy,gen.GEN_xx,gen.GEN_ee,GEN_mask
			Deletepoints (finish-start+1),(numpnts(gen.GEN_yy)-finish-1),gen.GEN_yy,gen.GEN_xx,gen.GEN_ee,GEN_mask
		else
			Deletepoints 0,start, gen.GEN_yy,gen.GEN_xx,gen.GEN_ee
			Deletepoints (finish-start+1),(numpnts(gen.GEN_yy)-finish-1),gen.GEN_yy,gen.GEN_xx,gen.GEN_ee
		endif
	endif	
		
	if(ParamIsDefault(mask)==0)	
		for(ii=0;ii<numpnts(gen.GEN_yy);ii+=1)
			if(GEN_mask[ii]==0 || numtype(GEN_mask[ii])==2)
				deletepoints ii,1,gen.GEN_yy,gen.GEN_ee,gen.GEN_xx,GEN_mask	
				ii-=1
			endif
		endfor
	endif
	
	for(ii=0;ii<numpnts(gen.GEN_yy);ii+=1)
		if(numtype(gen.GEN_yy[ii])!=0 || numtype(gen.GEN_xx[ii])!=0 || numtype(gen.GEN_ee[ii])!=0)
			deletepoints ii,1,gen.GEN_yy,gen.GEN_ee,gen.GEN_xx	
			ii-=1
		endif
	endfor	
	if(dimsize(GEN_yy,0)==0)
		setdatafolder $gen.GEN_callfolder
		abort "there were no valid points in the dataset (after removing NaN and mask/cursor points)"
	endif
	
	//put the name of the function name in a global string
	String/g root:motofit:GEN_optimise:fitfunctionname = 	func
	String/g root:motofit:GEN_optimise:callfolder = gen.GEN_callfolder
	Variable/g root:motofit:GEN_optimise:GEN_holdbits = gen.GEN_holdbits
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//do all the fitting
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//initialise the model	
	//get the intial setup, e.g. numgenerations, mutation constant, etc.
	if(ParamisDefault(popsize) || ParamisDefault(k_m) || ParamisDefault(recomb) || ParamisDefault(iters) || ParamisDefault(tol))
		GEN_searchparams(gen)
	else
		gen.GEN_generations = iters
		gen.GEN_popsize = popsize
		gen.k_m = k_m
		gen.GEN_recombination = recomb
		gen.GEN_V_fittol = tol
	endif
	
	//this sets up the waves for the genetic optimisation
	GEN_Initialise_Model(gen)
	
	Wave gen_b,gen.GEN_b = gen_b
	
	//make the limits wave
	//GEN_setlimitwave makes a limit wave if required
	//GEN_checkinitiallimits makes sure that the initial guess is between the limits
	variable ok
	if(Paramisdefault(c))
		do
			try	//the user may want to abort the fit at this stage and we need to return to the right DF
				GEN_setlimitwave(GEN_parnumber, gen.GEN_b)
				Wave GEN_limits,gen.GEN_limits=GEN_limits
				ok = GEN_checkinitiallimits(GEN_limits, gen.GEN_b)
			catch
				setdatafolder $gen.GEN_callfolder
				ABORT
			endtry
		while(ok==1)
	elseif(Paramisdefault(c)==0)
		//make a limitswave, this may be overwritten in the calling function.		
		if(dimsize(c,1)!=2)
			setdatafolder $gen.GEN_callfolder
			abort "user supplied limit wave should be 2 column"
		endif
		if(dimsize(c,0) != dimsize(parwave,0))
			setdatafolder $gen.GEN_callfolder
			abort "user supplied limit wave should be the same length as the parameter wave"		
		endif

		duplicate/o c, root:motofit:GEN_optimise:GEN_limits
		Wave GEN_limits,gen.GEN_limits=GEN_limits
		variable jj=0
		for(ii=0 ; ii<strlen(gen.GEN_holdstring) ; ii+=1)
			if(GEN_isbitset(gen.GEN_holdbits,ii))
				deletepoints ii-jj,1,root:motofit:GEN_optimise:GEN_limits
				jj+=1
			endif
		endfor
		
		ok=GEN_checkinitiallimits(GEN_limits,GEN_b)

		if(ok==1)
			do
				try	//the user may want to abort the fit at this stage and we need to return to the right DF
					GEN_setlimitwave(GEN_parnumber,GEN_b)
				catch
					setdatafolder $gen.GEN_callfolder
					ABORT
				endtry
				ok = GEN_checkinitiallimits(GEN_limits,GEN_b)
			while(ok==1)
		endif
	endif
	
	//make a whole set of guesses based on the parameter limits just created
	GEN_set_GENpopvector(GEN_b,GEN_limits)
	
	//setup the trial vector
	make/o/d/n=(dimsize(GEN_b,0)) GEN_trial
	
	Wave GEN_populationvector,gen.GEN_populationvector=GEN_populationvector 
	
	//initialise the Chi2array
	//enum is a wave that is used to evaluate Chi2, i.e. Rcalc
	duplicate/o GEN_xx,enum
	GEN_chi2array(gen)
	
	Wave GEN_chi2matrix,gen.GEN_chi2matrix=GEN_chi2Matrix
	Wave gen_b,gen.GEN_b=gen_b
	Wave gen.GEN_trial=gen_trial

	// make a table to illustrate the evolution
	duplicate/o GEN_populationvector,GEN_colourtable
	duplicate/o GEN_xx,GEN_yybestfit
	Wave gen.GEN_yybestfit=GEN_yybestfit
	GEN_evaluate(gen.GEN_yybestfit,GEN_b,gen)
	
	if(strlen(Winlist("evolve",";",""))==0)
		NewImage/k=1/n=evolve  root:motofit:GEN_optimise:GEN_colourtable
		Modifygraph/w=evolve width=400,height=400
		ModifyImage GEN_colourtable ctab= {0,256,Rainbow,0}
		ModifyGraph/w=evolve mirror(left)=1,mirror(top)=0,minor(top)=0,axisEnab(left)={0.52,1};DelayUpdate
		Label left "pvector";DelayUpdate
		Label top "parameter"
		AppendToGraph/w=evolve /L=ydata/B=xdata root:motofit:GEN_optimise:GEN_yybestfit vs root:motofit:GEN_optimise:GEN_xx
		AppendToGraph/w=evolve /L=ydata/B=xdata root:motofit:GEN_optimise:GEN_yy vs root:motofit:GEN_optimise:GEN_xx
		ModifyGraph/w=evolve axisEnab(ydata)={0,0.48},freePos(ydata)={0,xdata};DelayUpdate
		ModifyGraph/w=evolve freePos(xdata)={0,ydata}
		ModifyGraph/w=evolve axisEnab(xdata)={0.05,1}
		ModifyGraph/w=evolve mode(GEN_yy)=3,marker(GEN_yy)=19,msize(GEN_yy)=1
		ModifyGraph/w=evolve rgb(GEN_yybestfit)=(0,0,0)
	endif
	
	Doupdate
	
	try				//the user may try to abort the fit, especially if it takes a long time	
		//do the first fill with the lowest chi2 value
		variable exchange1,exchange2
		//replace the bvector by the best perfoming from population vector
		//GEN_sort finds the lowest Chi2 value
		//GEN_Chi2matrix contains an array of all the Chi2 values for each pvector 
		//exchange1 is the position of the lowest chi2  value
		exchange1=GEN_sort(GEN_Chi2matrix)
		exchange2=0
		gen.GEN_chi2best=GEN_chi2matrix[exchange1]
		GEN_Chi2matrix[0]=GEN_Chi2matrix[exchange1]
		
		//GEN_replacepvector sets GEN_pvector from the populationvector
		//it also replaces num in the population vector
		GEN_replacepvector(GEN_populationvector,exchange1,exchange2)
		//GEN_replacebvector replaces the best fitvector so far with a subvector, in this case GEN_pvector
		//which has been updated with the previous command
		GEN_replacebvector(gen,gen.GEN_pvector)		
		gen.GEN_currentpvector=0
		
		//make a wave to follow the trend in Chi2
		make/o/d/n=1 GEN_chi2trend
		GEN_Chi2trend[0]=gen.GEN_chi2best
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//now enter the fitting loops to improve it
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		GEN_optimiseloop(gen)
		//we now have the bestvector, but have to load it into GEN_parwave
		GEN_insertVaryingParams(gen.GEN_parwave,gen.GEN_b,gen.GEN_holdbits)

		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//make fit waves for the data and coefficients
		GEN_returnresults(gen)
	catch		//if the user aborts during the fit then send back the best position so far
		GEN_returnresults(gen)
	endtry
	
End

Static Function GEN_searchparams(gen)
	Struct GEN_optimisation &gen
	Variable GEN_popsize=20
	Variable k_m=0.7
	Variable GEN_recombination=0.5
	Variable GEN_generations=100
	Variable GEN_V_fittol=0.0005
	prompt k_m,"mutation constant, e.g.0.7"
	prompt GEN_recombination,"enter the recombination constant"
	prompt GEN_generations,"how many generations do you want to use?"
	prompt GEN_popsize,"enter the population size multiplier e.g. 10"
	prompt GEN_V_fittol,"enter the fractional tolerance to stop fit (e.g. 0.05%=0.0005)"
	Doprompt "Set up genetic optimisation",GEN_generations,k_m,GEN_popsize,GEN_recombination,GEN_V_fittol
	String CDF=gen.GEN_callfolder
	if(V_flag==1)
		setdatafolder CDF
		ABORT
	endif
	gen.GEN_generations=GEN_generations
	gen.GEN_popsize=GEN_popsize
	gen.k_m=k_m
	gen.GEN_recombination=GEN_recombination
	gen.GEN_V_fittol=GEN_V_fittol
End

Static Function GEN_optimiseloop(gen)
	//this does all the looping of the optimisation
	Struct GEN_optimisation &gen
	Wave gen.GEN_populationvector,gen.GEN_Chi2matrix
	Wave GEN_Chi2trend
	
	string tagtext
	variable ii,jj,kk,tagchi2,nit
	
	if(!gen.GEN_quiet)
		print "_________________________________\rStarting Genetic Optimisation"
		print "Initial Chi2: "+num2str(gen.GEN_Chi2best)
	endif
	
	Dowindow/F evolve
	
	nit=dimsize(gen.GEN_populationvector,1)
	
	for(kk=0;kk<gen.GEN_generations;kk+=1)			//loop over the generations
		tagtext="Generation: "+num2istr(kk) + " Chi2: "+ num2str(gen.GEN_Chi2best)
		Tag/c/n=text0/f=0/x=20/y=-100/l=0 GEN_colourtable, 0, tagtext

		for(ii=0;ii<nit;ii+=1)
			gen.GEN_currentpvector=ii

			//now set up the trial vector using a wave from the populationvector and bprime
			//first set the pvector 
			GEN_trialvector(gen)

			//make sure that the trial vector has values within the limits
			GEN_ensureconstraints(gen)

			//calculate Chi2 of trial vector and pvector[][gen.GEN_currentpvector]
			//but first have to make pvector equal to trial vector
			variable chi2pvector=gen.GEN_Chi2matrix[ii]
			
			gen.GEN_pvector=gen.GEN_trial
			variable chi2trial=GEN_chi2(gen)

			if(chi2trial<chi2pvector)				//if the trial vector is better than pvector then replace it.
				gen.GEN_populationvector[][gen.GEN_currentpvector]=gen.GEN_trial[p]
				gen.GEN_Chi2matrix[ii]=chi2trial
						
				GEN_chromosome(ii)
						
				if(chi2trial<gen.GEN_Chi2best)		//if this trial vector is better than the current best then replace it
					GEN_replacebvector(gen,gen.GEN_trial)
					gen.GEN_populationvector[][0]=gen.GEN_b[p]
					gen.GEN_Chi2matrix[0]=chi2trial
							
					//update the groovy convergence image
					GEN_chromosome(0)
					GEN_evaluate(gen.GEN_yybestfit,GEN_b,gen)
					
					//add the value to the Chi2 trend
					redimension/n=(numpnts(Gen_Chi2trend)+1) GEN_chi2trend
					GEN_chi2trend[numpnts(GEN_chi2trend)-1] = chi2trial
										
					if((abs(chi2trial-gen.GEN_chi2best)/gen.GEN_chi2best)<gen.GEN_V_fittol)	//if the fractional decrease is less and 0.5% stop.
						gen.GEN_Chi2best=chi2trial
						if(!gen.GEN_quiet)
							print "tolerance reached"
						endif
						return 1
					endif
					gen.GEN_Chi2best=chi2trial
				endif
			endif
		endfor
		//update the convergence image

		doupdate
		Dowindow/F evolve
	endfor
	
	//after all this looping the best vector should be gen.GEN_b
End

Static Function GEN_sort(GEN_chi2matrix)
	Wave GEN_chi2matrix
	variable lowestpvector
	Wavestats/q/z/M=1 GEN_chi2matrix
	findvalue /V=(V_min) GEN_chi2matrix
	return V_Value
End

Static Function GEN_replacepvector(GEN_populationvector,num1,num2)
	//GEN_replacepvector sets GEN_pvector from the populationvector
	//it also replaces num in the population vector
	Wave GEN_populationvector
	Variable num1,num2
	Wave GEN_pvector
	Wave GEN_Chi2matrix
	
	GEN_pvector[]=GEN_populationvector[p][num1]
	ImageTransform/G=(num2)/D=GEN_pvector putCol GEN_populationvector // AG
End

Static Function GEN_replacebvector(gen,ww)
	Struct GEN_optimisation &gen
	Wave ww
	Wave gen.GEN_b
	gen.GEN_b=ww
End

Static Function GEN_trialvector(gen)
	//this function creates a trial vector from bprime and the current pvector
	//it fills from a random position along the trial length (start), then continues filling
	//from the start.  It always fills the last position from the bprime vector, to maintain
	//diversity.
	Struct GEN_optimisation &gen
	Wave gen.GEN_bprime
	Wave gen.GEN_populationvector
	Wave gen.GEN_trial
	
	variable size=dimsize(gen.GEN_populationvector,0) , popsize = dimsize(gen.GEN_populationvector,1)
	variable random_a,random_b
	variable recomb=gen.gen_recombination
	variable k_m = gen.k_m
	variable fillpos = abs(round(abs(enoise(size))-0.500000000001)),ii
	
	do
		random_a=round(abs(enoise(popsize-0.50000001)))
	while(random_a == gen.GEN_currentpvector)
	
	do
		random_b=round(abs(enoise(popsize-0.50000001)))
	while (random_a == random_b )	
                
	for(ii=0 ; ii<size ; ii+=1)
		gen.GEN_bprime[ii] = gen.GEN_populationvector[ii][0] + k_m*(gen.GEN_populationvector[ii][random_a] - gen.GEN_populationvector[ii][random_b]);
	endfor
	
	for(ii=0 ; ii<size ; ii+=1)
		gen.GEN_trial[ii] = gen.GEN_populationvector[ii][gen.GEN_currentpvector]
	endfor
                
	variable counter = 0
	do
		if ((abs(enoise(1)) < recomb) || (counter == size))
			gen.GEN_trial[fillpos] = gen.GEN_bprime[fillpos]
		endif
		fillpos+=1
		fillpos = mod(fillpos,size)
		counter +=1
	while(counter < size)
End

Static Function GEN_ensureconstraints(gen)
	//this function makes sure that the evolving numbers stay within the set limits.
	Struct GEN_optimisation &gen
	Wave gen.GEN_trial
	Wave gen.GEN_limits
	variable ii=0
	variable size=Dimsize(gen.GEN_trial,0)
	variable lowerbound,upperbound
	for(ii=0;ii<size;ii+=1)
		lowerbound=gen.GEN_limits[ii][0]
		upperbound=gen.GEN_limits[ii][1]
		if(gen.GEN_trial[ii]<lowerbound || gen.GEN_trial[ii]>upperbound)	//are we in the limits?
			gen.GEN_trial[ii]=(lowerbound+upperbound)/2+enoise(1)*(upperbound-lowerbound)/2		//this should ensure that the parameter is in limits!!!
		endif
	endfor
End


Static Function GEN_setlimitwave(GEN_parnumber,GEN_b)
	//this function allows the user to set limits for the optimisation
	Wave GEN_parnumber,GEN_b

	//want to add in a bit to make sure that we don't necessarily have to set up the limit wave
	// each time we do the fit
	variable alreadyexists=0
	Wave/z GEN_limits
	//if it already exists and it's the same size as the parameter wave, then you could be fitting the same dataset
	if(Waveexists(GEN_limits) && dimsize(GEN_limits,0)==numpnts(GEN_b)) 
		Doalert 2,"Motofit has detected that you may have tried to fit a similar dataset, use previous limits?"
		switch(V_flag)
			case 1:
				alreadyexists=1
				break
			case 2:
				alreadyexists=0
				break
			case 3:
				ABORT
				break
		endswitch
	endif
	
	//if it doesn't already exist, or you don't want to use the limits again	
	if(alreadyexists==0)
		duplicate/o GEN_b, GEN_limits
		redimension/n=(-1,2) GEN_limits		//one column for the lower limit and one column for the upper limit
		//in all probability the best values for the lower limits are 0, as a guess set the upper limits to twice the parameter value
		variable ii
		for(ii=0;ii<numpnts(GEN_b);ii+=1)
			if(GEN_b[ii]>0)
				GEN_limits[ii][1]=2*GEN_b[ii]
				GEN_limits[ii][0]=0
			else
				GEN_limits[ii][0]=2*GEN_b[ii]
				GEN_limits[ii][1]=0
			endif
		endfor
	endif	
	
	//you still get a chance to edit them
	edit/k=1/n=boundarywave GEN_parnumber,GEN_b,GEN_limits as "set limits for genetic optimisation"
	
	Modifytable title[1] = "parameter number"
	Modifytable title[2] = "initial guess"
	Modifytable title[3] = "lower limit"
	Modifytable title[4] = "upper limit"
	
	GEN_UsereditAdjust("boundarywave")
	
	Dowindow/K boundarywave
End

Static Function GEN_checkinitiallimits(GEN_limits,GEN_b)
	Wave GEN_limits,GEN_b
	variable ii,lowlimit,upperlimit,parameter,ok
	
	for(ii=0;ii<numpnts(GEN_b);ii+=1)
		Wave GEN_limits
		lowlimit=GEN_limits[ii][0]
		upperlimit=GEN_limits[ii][1]
		parameter=GEN_b[ii]
		if(lowlimit>upperlimit)
			doalert 0, "your lower limit is bigger than your upperlimit"
			ok=1
			break
		elseif(parameter<lowlimit || parameter > upperlimit)
			doalert 0, " parameter is outside one of the limits"
			ok=1
			break
		else
			ok=0
		endif
	endfor
	return ok
End

Static Function GEN_Initialise_Model(gen)
	//this function sets up the geneticoptimisation
	Struct GEN_optimisation &gen

	//the total size of the population, should be an integer number (~10?)
	variable GEN_popsize=gen.GEN_popsize		

	//subset of parameters to be fitted, it's the bestfit vector
	make/o/d/n=(gen.GEN_numvarparams) GEN_b
	Wave gen.GEN_b=GEN_b

	//makee a list of the parameter numbers you are changing
	make/o/d/n=(gen.GEN_numvarparams) GEN_parnumber
	Wave gen.GEN_parnumber=GEN_parnumber
	
	//ii is a loop counter, jj will be for how many parameters will vary
	Variable ii=0,jj=0			

	//and make a wave with the vectors, this wave is the best fit vector
	GEN_extractVaryingParams(gen.GEN_parwave,gen.GEN_b, gen.GEN_holdbits)
	
	for(ii=0 ; ii < numpnts(gen.GEN_parwave) ; ii+=1)
		if(GEN_isbitset(gen.GEN_holdbits,ii)==0)	//we want to fit that parameter
			GEN_parnumber[jj]=ii
			jj+=1
		endif
	endfor
	
	//now make the total population vector
	make/o/d/n=(gen.GEN_numvarparams,GEN_popsize*gen.GEN_numvarparams) GEN_populationvector
	Wave gen.GEN_populationvector=GEN_populationvector
	//make the difference vector, trial vector and two random vectors
	make/o/d/n=(gen.GEN_numvarparams) GEN_bprime
	Wave gen.GEN_bprime=GEN_bprime,gen.GEN_trial=GEN_trial
	
	//make a pvector
	make/o/d/n=(dimsize(GEN_populationvector,0)) GEN_pvector
	Wave gen.GEN_pvector=GEN_pvector	
End


Static Function GEN_set_GENpopvector(GEN_b,GEN_limits)
	//GEN_b is the best guess, GEN_limits[][0 or 1] are the lower/upper limits for the fit
	//GEN_b should already lie in between the limits!!!!!!!!!!!!!!!!
	Wave GEN_b,GEN_limits
	Wave GEN_populationvector
	//initialise loop counters
	Variable ii=0,jj=0,kk=0,nit,nit1

	//random will be a random number.  Lowerbound and upperbound are the limits on the parameters
	Variable random,lowerbound,upperbound
	//initialise GEN_populationvector, within the limits set by GEN_limits
	//first column is the initial parameters
	GEN_populationvector[][0]=GEN_b[p]
	
	//the rest should be created by random numbers.
	//go through each column one by one
	nit=Dimsize(GEN_populationvector,1)
	nit1=Dimsize(GEN_populationvector,0)
	for(ii=0;ii<nit1;ii+=1)
		lowerbound=GEN_limits[ii][0]
		upperbound=GEN_limits[ii][1]
		for(kk=1;kk<nit;kk+=1)
			//generate a random variable for that parameter
			random=(lowerbound+upperbound)/2+abs(lowerbound-upperbound)*enoise(0.5)
			GEN_populationvector[ii][kk]=random
		endfor
	endfor
End

Static Function GEN_chi2array(gen)
	//this function calculates the Chi_2 matrix for the population vector at the start of the optimisation	
	Struct GEN_optimisation &gen
	
	Wave gen.GEN_pvector
	Wave gen.GEN_populationvector

	make/o/d/n=(dimsize(GEN_populationvector,1)) GEN_chi2matrix
	Wave gen.GEN_chi2matrix=GEN_chi2matrix	
	variable ii=0,np=numpnts(GEN_chi2matrix)
	
	for(ii=0;ii<np;ii+=1)
		gen.GEN_pvector[]=gen.GEN_populationvector[p][ii]
		GEN_chi2matrix[ii]=GEN_chi2(gen)
	endfor
End

Static Function GEN_evaluate(evalwave,partialparamwave,gen)
	//this function evaluates Chi2 for evalwave (the ydata).  The partial parameter wave is here (i.e. the 'pvector')
	//the gen structure supplies the holdwave which fills up the full parameter wave.
	Wave evalwave,partialparamwave
	Struct GEN_optimisation &gen
	Wave GEN_parwave=gen.GEN_parwave

	Wave GEN_xx=gen.GEN_xx
	
	GEN_insertVaryingParams(gen.GEN_parwave,partialparamwave,gen.GEN_holdbits)								

	//now evaluate the wave
	if(gen.GEN_whattype==2)
		Funcref GEN_fitfunc gen.fan=gen.fan
		evalwave=gen.fan(GEN_parwave,gen.GEN_xx)
	elseif(gen.GEN_whattype==3)
		Funcref GEN_allatoncefitfunc gen.fin=gen.fin
		gen.fin(GEN_parwave,evalwave,gen.GEN_xx)
	endif
	
End

Static Function GEN_chi2(gen)
	//calculates chi2
	struct GEN_optimisation &gen
	Wave GEN_pvector=gen.GEN_pvector
	Wave GEN_yy=gen.GEN_yy,GEN_ee=gen.GEN_ee
	
	variable Chi2=0
	Wave enum
	
	//evaluate the enumerator using the current pvector 
	GEN_evaluate(enum,gen.GEN_pvector,gen)
	enum-=gen.GEN_yy
	enum/=gen.GEN_ee
	enum=enum*enum
	Wavestats/q/z/M=1 enum
	chi2=V_sum
	
	return Chi2
End

Function GEN_allatoncefitfunc(coefficients,ydata,xdata)
	//the function template for an all at once fitfunction
	Wave coefficients,ydata,xdata
End

Function GEN_fitfunc(coefficients,xx)
	//the function template for a normal fit function
	Wave coefficients
	variable xx
End

Function GEN_insertVaryingParams(baseCoef,varyCoef,holdbits)
	Wave baseCoef,varyCoef
	variable holdbits
	variable ii=0,jj=0
	for(ii=0 ; ii < numpnts(baseCoef) ; ii+=1)
		if(GEN_isBitSet(holdBits,ii) == 0)
			baseCoef[ii] = varyCoef[jj]
			jj+=1
		endif		
	endfor
End

Function GEN_extractVaryingParams(baseCoef,varyCoef, holdbits)
	Wave baseCoef,varyCoef
	variable holdbits	
	variable ii=0,jj=0
	for(ii=0 ; ii < numpnts(basecoef) ; ii+=1)
		if(GEN_isBitSet(holdBits,ii) ==0)
			varycoef[jj] = baseCoef[ii]
			jj+=1
		endif		
	endfor
End

Static Function GEN_UsereditAdjust(tableName)
	String tablename

	DoWindow/F $tableName		// Bring table to front
	if (V_Flag == 0)		// Verify that table exists
		Abort "where did the table go?"
		return -1
	endif

	NewPanel/K=2 /W=(139,341,382,432) as "Pause for user editing"
	DoWindow/C tmp_Pauseforedit		// Set to an unlikely name
	DrawText 21,20,"Edit the values in the table."
	Drawtext 21,40,"Once you press go then"
	Drawtext 21,60,"genetic optimisation will start."
	
	Button button0,pos={5,64},size={92,20},title="Continue"
	Button button0,proc=GEN_optimise#GEN_UsereditAdjust_Cont
	Button button1,pos={110,64},size={92,20},title="cancel",proc=GEN_optimise#GEN_UserEditAdjust_cancel
	//this line allows the user to adjust the cursors until they are happy with the right level.
	//you then press continue to allow the rest of the reduction to occur.
	PauseForUser tmp_Pauseforedit,$tablename

	return 0
End

static Function GEN_UserEditAdjust_Cont(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K tmp_Pauseforedit		// Kill self
End

Static Function GEN_UserEditAdjust_cancel(ctrlName) :Buttoncontrol 
	String ctrlName
	DoWindow/K tmp_Pauseforedit		// Kill self
	Dowindow/K boundarywave
	Svar callfolder = root:motofit:GEN_optimise:callfolder
	Setdatafolder $callfolder 
	ABORT
End

Static Function GEN_returnresults(gen)
	Struct GEN_optimisation &gen
	//make fit waves for the data and coefficients
	variable ii=0,jj=0,use
	
	Wave GEN_parwave=gen.GEN_parwave
	Wave gen.GEN_yy = gen.GEN_yy
	Wave GEN_b = gen.GEN_b
	
	duplicate/o gen.GEN_xx GEN_fitx,GEN_fit
	GEN_evaluate(GEN_fit,GEN_b,gen)
		
	duplicate/o gen.GEN_parwave GEN_coefs
	//now rename the waves to what they should be called
	string ywave=gen.GEN_ywavename
	string xwave=cleanupname("fitx_"+ywave,0)
	ywave=cleanupname("fit_"+ywave,0)
	
	string writename=gen.GEN_callfolder+xwave
	duplicate/o GEN_fitx, $writename
	writename=gen.GEN_callfolder+ywave
	duplicate/o GEN_fit, $writename
	writename=gen.GEN_parwaveDF
	duplicate/o GEN_coefs, $writename
	//now return to the original datafolder
	Setdatafolder $gen.GEN_callfolder
	variable/g V_Chisq=gen.GEN_chi2best
	if(!gen.GEN_quiet)
		print "The refined Chi2 value was "+num2str(V_Chisq)+"\r_________________________________"
	endif
	killwaves/Z GEN_fit,GEN_fitx,GEN_coefs
	//add to Moto_returnresults
	try
		GEN_calculateUncertainty(GEN)
	catch
		Setdatafolder $gen.GEN_callfolder
	endtry
	
End

Static Function GEN_chromosome(n)
	//this function makes groovy colours so that you can see when your fits are converging.
	variable n
	Wave GEN_populationvector,GEN_limits,GEN_colourtable
	GEN_colourtable[][n]=256*abs(GEN_populationvector[p][n]-GEN_limits[p][0])/abs(GEN_limits[p][1]-GEN_limits[p][0])		
End

Function GEN_calculateUncertainty(GEN)
	Struct GEN_optimisation &GEN
	//this function aims to estimate the pointwise errors from the genetic optimisation output.
	//these are typically overestimated, but its better than nothing.  The pointwise errors are defined as 
	//the change in parameter requires to increase Chi2 by 2.5%
	
	//we will require DF information, y wave, xwave,ewave,function name, etc.
	string savedf = getdatafolder(1)

	//GEN_parwave contains the fitted data, GEN_holdwave whether you used it or not
	gen.gen_pvector=gen.gen_b
	//make a wave to hold the uncertainty coefficients
	setdatafolder $gen.GEN_callfolder
	make/o/d/n=(numpnts(Gen.GEN_parwave)) W_Sigma 
	setdatafolder root:motofit:GEN_optimise

	//we want to search for a target Chi2 2 percent off the best value
	variable/g GEN_Chi2best = gen.GEN_chi2best

	variable error,originalvalue,frac=0.015
	make/o/n=(strlen(gen.GEN_holdstring)) tempholdwave
	tempholdwave = 1
	Wave tempholdwave
	variable ii=0,jj=0,kk=1

	for(ii=0 ; ii<strlen(gen.GEN_holdstring) ; ii+=1)
		if(GEN_isbitset(gen.GEN_holdbits,ii) == 1)
			W_Sigma[ii]=0
			continue
		endif
		originalvalue = gen.GEN_pvector[jj]
		tempholdwave[ii]=0
		
		do
			if(originalvalue>=0)
				optimize/q/L=(originalvalue-(originalvalue*frac*kk))/H=(originalvalue+(originalvalue*frac*kk)) GEN_findtargeterrors,tempholdwave
			elseif(originalvalue<0)
				optimize/q/L=(originalvalue-abs(originalvalue*frac*kk))/H=(originalvalue+abs(originalvalue*kk*frac)) GEN_findtargeterrors,tempholdwave
			endif
			if(V_min/(GEN_Chi2best*1.02)>0.02)
				kk+=1
			endif
			gen.GEN_pvector[jj] = originalvalue
		while(V_min/(GEN_Chi2best*1.02)>0.02)
		
		tempholdwave[ii]=1
		W_sigma[ii]=abs(V_minloc-originalvalue)
		gen.GEN_pvector[jj] = originalvalue
		jj+=1
	endfor
	setdatafolder savedf
End

Function GEN_findtargeterrors(tempholdwave,param)
	Wave tempholdwave
	variable param

	Struct GEN_optimisation gen

	NVAR/z GEN_chi2best,GEN_holdbits
	SVAR/z fitfunctionname
	
	Wave GEN_pvector, GEN_yy,GEN_xx,GEN_ee,GEN_parwave
	Wave gen.GEN_pvector=GEN_pvector,gen.GEN_yy=GEN_yy,gen.GEN_xx=GEN_xx,gen.GEN_ee=gen_ee,gen.GEN_parwave=GEN_parwave
	
	variable whattype=Numberbykey("N_Params",Functioninfo(fitfunctionname))
	gen.GEN_whattype=whattype
	gen.GEN_holdbits = GEN_holdbits

	if(gen.GEN_whattype==2)
		Funcref GEN_fitfunc gen.fan=$fitfunctionname
	elseif(gen.GEN_whattype==3)
		Funcref GEN_allatoncefitfunc gen.fin=$fitfunctionname
	endif
	
	gen.GEN_chi2best = GEN_chi2best
	variable Chi2target = GEN_chi2best*1.02,ii,jj=0
	
	for(ii=0 ; ii < numpnts(tempholdwave) ; ii+=1)
		if(tempholdwave[ii]==0)
			if(GEN_isbitset(gen.GEN_holdbits,ii) == 0)
				GEN_pvector[jj]=param	
			endif
			jj+=1
		endif
	endfor

	variable chi2guess =  GEN_optimise#GEN_chi2(gen)

	return abs(chi2target-chi2guess)

End
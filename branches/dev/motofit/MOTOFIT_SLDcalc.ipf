#pragma rtGlobals=3		// Use modern global access method.=
#pragma ModuleName = Motofit_SLDcalc
#pragma Igormode=6.22

static strconstant NO_ATOM = "Parse error - either the atom or the isotope doesn't exist in the database: "
static strconstant NO_ISOTOPE = "Parse - one of the isotopes isn't in the database"
static strconstant INT_ISOTOPE = "Parse - please enter integers for the isotope"
static strconstant NO_SCATLEN = "No scattering length exists for that isotope: "
static strconstant INCORRECT_DENSITY = "Please enter a mass density > 0"
static strconstant GENERAL = "Parse - please enter chemical as element(isotope)numatoms"

Function Moto_SLDdatabase() : Panel
	//this function creates a panel in which the user can edit the SLD database
	DFREF savedf=getdatafolderdfr()
	
	String winexist=WinList("SLDpanel",";","WIN:64")
	if(strlen(winexist)>0)
		Dowindow/F SLDpanel
		setdatafolder savedf
		ABORT
	else
		if(datafolderexists("root:packages:motofit:reflectivity:SLDdatabase")==0)
			newdatafolder/o root:packages
			newdatafolder/o root:packages:motofit
			newdatafolder/o root:packages:motofit:reflectivity
			Newdatafolder/o root:packages:motofit:reflectivity:SLDdatabase
		endif
		PauseUpdate; Silent 1		// building window...
		NewPanel /k=1/W=(0,0,520,320)
		Tabcontrol sldtab size = {511,305},tabLabel(0)="calculator",proc=Moto_SldtabControl,fSize=12
		Tabcontrol sldtab size = {511,305},tabLabel(1)="database",fSize=12
		Tabcontrol sldtab size = {511,305},tabLabel(2)="SLDmixing",fSize=12
		
		Button Addchemical_tab1,pos={20,50},size={110,30},proc=Moto_add_chemical,title="Add chemical"
		Button Addchemical_tab1,fSize=12
		PopupMenu listchemicals_tab1,pos={197,50},size={203,24},proc=Moto_updateSLDdisplay,title="List of chemicals"
		PopupMenu listchemicals_tab1,fSize=12
		PopupMenu listchemicals_tab1,mode=3,bodyWidth= 100,popvalue="_none_",value= #"root:packages:motofit:reflectivity:SLDdatabase:chemicals"
		Button loaddatabase_tab1,pos={20,85},size={110,30},proc=Moto_Loaddatabase,title="load database"
		Button loaddatabase_tab1,fSize=12
		SetVariable neutronSLD_tab1,pos={220,90},size={180,19},title="Neutron SLD",fSize=12
		SetVariable neutronSLD_tab1,value= k0,bodyWidth= 100
		SetVariable XraySLD_tab1,pos={236,130},size={164,19},title="X-ray SLD",fSize=12
		SetVariable XraySLD_tab1,value= k0,bodyWidth= 100
		SetVariable rho_tab1,pos={217,170},size={183,19},title="Mass density",fSize=12
		SetVariable rho_tab1,value= k0,bodyWidth= 100
		Button savedatabase_tab1,pos={20,120},size={110,30},proc=Moto_Savedatabase,title="Save database"
		Button savedatabase_tab1,fSize=12
		SetVariable chemcom_tab1,pos={162,210},size={238,19},title="Chemical Composition"
		SetVariable chemcom_tab1,fSize=12,value= S_Value,bodyWidth= 100
		SetVariable chemcom_tab1,value= S_Value
		DoWindow/C/T SLDpanel,"SLDdatabase"
		
		SetVariable chemical_tab0,pos={22,31},size={331,23},title="Chemical Formula",fSize=12
		SetVariable chemical_tab0,limits={inf,inf,0},value= _STR:"",bodyWidth= 200,proc = Moto_SLDcalculateSetvariable
		SetVariable calcMASSDENSITY_tab0,pos={18,60},size={200,23},title="Mass density",fSize=12, proc=Moto_SLDcalculateSetvariable
		SetVariable calcMASSDENSITY_tab0,limits={0,100,0.02},value=_NUM:0
		SetVariable calcMolVol_tab0,pos={236,60},size={230,23},title="Molecular volume (A^3)",fSize=12, proc=Moto_SLDcalculateSetvariable
		SetVariable calcMolVol_tab0,limits={0,inf,1},value= _NUM:0
		
		SetVariable calcNeutronSLD_tab0,pos={57,171},size={294,23},title="Neutron SLD",fSize=12
		SetVariable calcNeutronSLD_tab0,limits={-inf,inf,0},value= _NUM:0,bodyWidth= 197
		SetVariable calcXRAYSLD_tab0,pos={82,208},size={269,23},title="Xray SLD",fSize=12
		SetVariable calcXRAYSLD_tab0,limits={-inf,inf,0},value= _NUM:0,bodyWidth= 197
		Button CALCULATE_tab0,pos={194,100},size={100,60},title="Calculate",fSize=12,proc = Moto_SLDcalculateButton
		Button AddToDataBase_tab0,pos={194,235},size={100,60},title="Add to \r database",fSize=12,proc = Moto_addchemicalfromcalculator
		
		//make the variables for the mixing				
		SetVariable mixSLD1_tab2,pos={29,57},size={200,23},title="SLD 1st component",fSize=12,value =_NUM:6.36
		Setvariable mixSLD1_tab2,proc = Moto_mixCalculateSetvariable,limits={-inf,inf,0.01}
		SetVariable mixSLD2_tab2,pos={243,57},size={200,23},title="SLD 2nd component",fSize=12,value=_NUM:-0.56
		Setvariable mixSLD2_tab2, proc = Moto_mixCalculateSetvariable,limits={-inf,inf,0.01}
		SetVariable mixvolfrac1_tab2,pos={29,105},size={200,23},title="vol. frac. 1st component",fSize=12,value=_NUM:0
		Setvariable mixvolfrac1_tab2, limits={0,1,0.01},proc= Moto_mixCalculateSetvariable
		SetVariable mixvolfrac2_tab2,pos={243,105},size={200,23},title="vol. frac. 2nd component",fSize=12,value=_NUM:0
		Setvariable mixvolfrac2_tab2, limits={0,1,0},proc = Moto_mixCalculateSetvariable
		setvariable mixoverallSLD_tab2,pos={164,246},size={160,23},title="Overall SLD",fSize=12,value=_NUM:0,limits={-inf,inf,0.01},proc=Moto_mixCalculateSetvarReverse
		
	endif
	
	SetDatafolder root:packages:motofit:reflectivity:SLDdatabase 
	String/G chemicals=""
	//if the SLDdatabase is stored in the MOTOFit directory then you can use a function path
	//to determine where it is.  This is because on Macintoshs the filenames and paths are different 
	String path = FunctionPath("MOTOFIT")
	variable pathlen = itemsinlist(path,":")
	path = Removelistitem(pathlen-1, path, ":")
	path+="SLDdatabase.txt"
	Loadwave/q/A/o/w/k=0/j/L={0,0,0,0,0} path
	Wave/T chemical
	variable ii=0
	do 
		chemicals+=chemical[ii]+";"
		ii+=1
	while(ii<numpnts(chemical))
	
	//load the scattering lengths from a textfile
	Moto_SLDLoadScatteringlengths()
	
	STRUCT WMTabControlAction TC_Struct
	TC_Struct.tab=0
	Moto_SldtabControl(TC_Struct)
	
	Setdatafolder savedf
End

Function Moto_updateSLDdisplay(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	//this function changes the displayed SLD values (in the SLDpanel), depending on what chemical was selected from the chemicals popup. 
	DFREF savedf = getdatafolderDFR()
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	Wave/T chemical,chemical_composition
	Wave SLD_neutrons,SLD_X_rays,Mass_density
	Setvariable neutronSLD_tab1 value=SLD_neutrons[popnum-1]
	Setvariable XraySLD_tab1 value=SLD_X_rays[popnum-1]
	Setvariable rho_tab1 value=Mass_density[popnum-1]
	Setvariable chemcom_tab1 value=chemical_composition[popnum-1]
	Setdatafolder savedf
End

Function Moto_SldtabControl(TC_Struct)
	STRUCT WMTabControlAction &TC_Struct
	Variable tab=TC_Struct.tab
	//this function controls the visibility of the controls when different tabs are selected in the reflectivity panel.
	//first tab controls
	
	if(TC_Struct.eventcode==-1)
		return 0
	endif
	String controlsInATab= ControlNameList("SLDpanel", ";", "*_tab*")
	String curTabMatch= "*_tab"+num2istr(tab)
	String controlsInCurTab= ListMatch(controlsInATab, curTabMatch)
	String controlsInOtherTabs= ListMatch(controlsInATab, "!"+curTabMatch)

	ModifyControlList controlsInOtherTabs disable=1	// hide
	ModifyControlList controlsInCurTab disable=0		// show
End

Function Moto_SLDLoadScatteringlengths()
	DFREF saveDF = GetdatafolderDFR()
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o root:packages:motofit:reflectivity:Slddatabase
	
	String path=FunctionPath("MOTOFIT")
	variable pathlen = itemsinlist(path,":")
	path = Removelistitem(pathlen-1,path,":")
	path += "SLDscatteringlengths.txt"
	
	LoadWave/q/J/M/n=scatlengths/U={0,0,1,0}/K=2 path
	Wave/T scatlengths0
	duplicate/o scatlengths0,scatlengths
	killwaves/z scatlengths0
	setdatafolder saveDF
End

Function Moto_SLDcalculateButton(ctrlName) : ButtonControl
	String ctrlName
	Variable/C sld
	
	string chemical = "", SLD_neutron = "", SLD_xray = ""
	variable SLD_massdensity
	controlinfo/W=SLDpanel chemical_tab0
	chemical = S_value
	controlinfo/W=SLDpanel calcMASSDENSITY_tab0
	SLD_massdensity = V_Value
	
	sld = Moto_SLDcalculation(chemical,SLD_massdensity,0)
	SLD_Neutron = num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
	sld = Moto_SLDcalculation(chemical,SLD_massdensity,1)
	SLD_xray = num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
End

Function Moto_Loaddatabase(ctrlName) : ButtonControl
	String ctrlName
	DFREF saveDF = getdatafolderDFR()
	//this function loads an SLDdatabase
	SetDatafolder root:packages:motofit:reflectivity:SLDdatabase 
	String/G chemicals=""
	Loadwave/q/o/w/A/k=0/j/L={0,0,0,0,0}
	if(V_flag==0)
		setdatafolder saveDF
		return 1
	endif
	Wave/T chemical
	variable ii=0
	do 
		chemicals+=chemical[ii]+";"
		ii+=1
	while(ii<numpnts(chemical))

	Setdatafolder saveDF
End


Function Moto_add_chemical(ctrlName) : ButtonControl
	String ctrlName
	//this functions adds a new chemical to the SLD database
	DFREF saveDF = getdatafolderDFR()
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	Wave/T chemical
	String/G chemicals
	

	if (waveexists(chemical)==0)
		make/T/n=0 chemical,chemical_composition
		make/d/n=0 Mass_Density,SLD_X_rays,SLD_neutrons
	else
		Wave/T/z chemical,chemical_composition
		Wave/z SLD_neutrons,SLD_X_rays,Mass_density
	endif
	
	variable numchemical=numpnts(chemical)
	redimension/N=(numchemical+1) chemical,SLD_neutrons,SLD_X_rays,Mass_density, chemical_composition
	String chem, chemcom
	Variable SLDn,SLDx,rho
	Prompt chem, "Name of chemical"
	Prompt SLDn, "neutron SLD"
	Prompt SLDx, "X-ray SLD"
	Prompt rho, "Mass density"
	Prompt chemcom, "Chemical Composition"
	Doprompt "Enter the chemical details" chem, SLDn, SLDx, rho, chemcom
	if(V_flag)
		setdatafolder saveDF
		return 0
	endif
	chemical[numchemical]=chem
	SLD_neutrons[numchemical]=SLDn
	SLD_X_rays[numchemical]=SLDx
	Mass_density[numchemical]=rho
	chemical_composition[numchemical]=chemcom
	chemicals += chem+";"
	Setdatafolder saveDF
End

Function Moto_Savedatabase(ctrlName) : ButtonControl
	String ctrlName
	//this function saves the SLDdatabase
	DFREF saveDF = getdatafolderDFR()
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	string name=""
	String fname
	Wave/t chemical, chemical_composition
	Wave SLD_neutrons, SLD_X_rays, Mass_density
//	fname=Moto_DoSaveFileDialog(name)
	if(strlen(fname)==0)
		ABORT
	endif
	variable refnum
	open/z refnum as fname
	if(V_flag)
		return 0
	endif
	fprintf refnum, "chemical,chemical_composition,SLD_neutrons,SLD_X_rays,Mass_density\r"
	wfprintf refnum, "%s\t%s\t%g\t%g\t%g\r", chemical,chemical_composition,SLD_neutrons,SLD_X_rays,Mass_Density
	close refnum
	Setdatafolder saveDF
End

Function Moto_addchemicalfromcalculator(ctrlName) : ButtonControl
	String ctrlName
	//this function adds a new chemical to the SLD database from the SLDcalculator
	DFREF saveDF=getdatafolderDFR()
	
	Setdatafolder root:packages:motofit:reflectivity:SLDdatabase
	Wave/z/t chemical, chemical_composition
	Wave/z SLD_neutrons, SLD_X_rays, Mass_density
	SVAR chemicals
	if (waveexists(chemical)==0)
		Setdatafolder savedf
		ABORT "Please load the database first"
	endif
	
	variable numchemical=numpnts(chemical)
	redimension/N=(numchemical+1) chemical,SLD_neutrons,SLD_X_rays,Mass_density, chemical_composition
	
	String chemicalname
	Prompt chemicalname, "Name"
	Doprompt "Please provide a name for the chemical" chemicalname
	if(V_flag)
		setdatafolder savedf
		Abort
	Endif
		
	chemical[(numchemical)]=chemicalname
	
	//parse the real part of the neutron SLD
	controlinfo/W=SLDpanel calcNeutronSLD_tab0
	SLD_neutrons[numchemical]=V_Value*1e6

	controlinfo/W=SLDpanel calcXraySLD_tab0	
	SLD_X_rays[numchemical] = V_Value * 1e6
	
	controlinfo/W=SLDpanel calcMASSDENSITY_tab0
	Mass_density[numchemical] = V_Value
	
	controlinfo/W=SLDpanel chemical_tab0 
	chemical_composition[numchemical] = S_value

	chemicals+=chemicalname+";"
	Setdatafolder savedf
End

Function Moto_SLDcalculateSetvariable(SV_Struct) : Setvariablecontrol
	STRUCT WMSetVariableAction &SV_Struct
	if(SV_Struct.eventcode!=-1)
		controlinfo/W=SLDpanel chemical_tab0
		string chemical = S_Value
		
		controlinfo/W=sldpanel calcMASSDENSITY_tab0
		variable SLD_massdensity = V_Value
		
		controlinfo/W=sldpanel calcMolVol_tab0
		variable SLD_molvol = V_Value
		
		strswitch(SV_Struct.ctrlname)
			case "calcMassDensity_tab0":
				SLD_molvol = 1e24  * numberbykey("weight_tot",Moto_SLDparsechemical(chemical, 0))/(SLD_massdensity*6.023e23)
				setvariable calcMolVol_tab0, win=sldpanel, value = _NUM:SLD_molvol
				break
			case "calcmolvol_tab0":
				SLD_massdensity = 1e24  * numberbykey("weight_tot",Moto_SLDparsechemical(chemical,0))/(SLD_molvol*6.023e23)
				setvariable calcMassDensity_tab0, value = _NUM:SLD_massdensity, win=SLDpanel
				break
		endswitch
		
		Variable/C sld
		sld = Moto_SLDcalculation(chemical,SLD_massdensity,0)
		setvariable calcNeutronSLD_tab0, win=sldpanel, value = _STR:num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
		
		sld = Moto_SLDcalculation(chemical,SLD_massdensity,1)
		setvariable calcXraySLD_tab0, win=sldpanel, value = _STR:num2str(real(sld)) + " + " + num2str(imag(sld)) + " i "
	endif
	return 0
End

Function/c Moto_SLDcalculation(chemical,massdensity,type)
	String chemical
	variable massdensity
	variable type //(0=neutrons,1=xrays)

	string parsedChemical = Moto_SLDparsechemical(chemical,type)
	variable weight_tot = numberbykey("weight_tot",parsedChemical)
	variable/c scatlen_tot
	scatlen_tot = cmplx(numberbykey("scatlen_tot_re",parsedChemical),numberbykey("scatlen_tot_im",parsedChemical))
	variable/c sld
	
	sld = 1e-29*6.023e23*scatlen_tot*massdensity/weight_tot
	return sld
End

Function/S Moto_SLDparsechemical(chemical,type)
	//parses the entered chemical and adds up the total weight and scattering lengths
	string chemical
	variable type

	wave/t scatlengths = root:packages:motofit:reflectivity:slddatabase:scatlengths

	String element = ""
	variable isotope, numatoms

	variable/c scatlen, scatlen_tot=cmplx(0,0),sld=cmplx(0,0)
	variable weight,weight_tot

	string s1
	variable s1dum,strpos,posintable

	if(strlen(chemical)>0)
		do
			element=""
			//parse for a chemical.  this should be in the general format elementstr(isotopevar)numatomsvar
			sscanf chemical, "%1[A-Z]", s1
			element+=s1
			chemical=chemical[1,strlen(chemical)]
			
			if(strlen(s1)==0)
				abort "problem while parsing chemical"
			endif

			sscanf chemical, "%[a-z]", s1
			element += s1
						
			chemical = chemical[strlen(s1),strlen(chemical)]
			
			//now get the isotope, 0 = natural abundance
			sscanf chemical, "%*[(]%f%*[)]",isotope
			if(V_flag==1)
				strpos= strsearch(chemical,")",0)
				chemical  = chemical[strpos+1,strlen(chemical)]
				isotope = round(isotope)
			else 
				isotope = 0
			endif
			
			//does chemical + isotope exist
			s1 = num2istr(isotope) + element
			Findvalue/text=s1/txop=3/z scatlengths
			posintable = v_value
			if(posintable==-1)
				abort NO_ATOM
			endif
			
			//now find out the number of atoms of that element
			sscanf chemical, "%f",numatoms
			if(V_flag==1)
				sscanf chemical,"%f%s",s1dum,s1
				if(strlen(s1)==0)
					chemical=""
				endif
			
				strpos = strsearch(chemical,s1,0)
				chemical = chemical[strpos,strlen(chemical)]	
			else
				numatoms=1
			endif
		
			//isotope exists, so find scatlen, add to total, add weight to total, depending on the number of atoms.
			if(type==0)
				if(numtype(str2num(scatlengths[posintable][2]))!=0)
					abort NO_SCATLEN + num2istr(isotope)+element
				endif
				scatlen = numatoms*cmplx(str2num(scatlengths[posintable][2]),str2num(scatlengths[posintable][3]))
			elseif(type==1)
				scatlen =numatoms*cmplx(str2num(scatlengths[posintable][5]),str2num(scatlengths[posintable][6]))
			endif
			
			scatlen_tot += scatlen
			weight_tot += str2num(scatlengths[posintable][1])*numatoms
		
		while(strlen(chemical)!=0)
	endif

	if(type==1)
		scatlen_tot *= 2.8179
	endif
	return "weight_tot:" + num2str(weight_tot) + ";scatlen_tot_re:" + num2str(real(scatlen_tot))+";"+"scatlen_tot_im:"+num2str(imag(scatlen_tot))
End

Function Moto_mixCalculateSetvariable(SV_Struct) : Setvariablecontrol
	//this function works out an overall SLD if you supply volume fractions and individual SLD's
	STRUCT WMSetVariableAction &SV_Struct
	if(SV_Struct.eventcode!=-1)
	
		controlinfo/w=SLDpanel mixSLD1_tab2
		variable mixSLD1 = V_Value
		controlinfo/w=SLDpanel mixSLD2_tab2
		variable mixSLD2 = V_Value
		controlinfo/w=SLDpanel mixvolfrac1_tab2
		variable mixvolfrac1 = V_Value
		controlinfo/w=SLDpanel mixvolfrac2_tab2
		variable mixvolfrac2 = V_Value

		mixvolfrac2=1-mixvolfrac1
		variable mixOverallSLD = mixvolfrac1*mixSLD1 + mixvolfrac2 * mixSLD2
		setvariable mixoverallSLD_tab2 win=sldpanel, value = _NUM:mixoverallSLD
	endif
	return 0
End

Function Moto_mixCalculateSetvarReverse(SV_Struct) : Setvariablecontrol
	//this function takes an overallmixSLD, with SLD's of components, and works out what their volume fractions are.
	Struct WMSetVariableAction &SV_struct
	variable volfrac
	if(SV_Struct.eventcode!=-1)
		controlinfo/W=SLDpanel mixoverallSLD_tab2
		variable mixoverallSLD = V_Value
		
		controlinfo/w=SLDpanel mixSLD1_tab2
		variable mixSLD1 = V_Value
		controlinfo/w=SLDpanel mixSLD2_tab2
		variable mixSLD2 = V_Value
		
		volfrac = (mixOverallSLD - mixSLD2) / (mixSLD1 - mixSLD2)
		variable mixvolfrac1 = volfrac
		variable mixvolfrac2 = 1-volfrac
		setvariable mixvolfrac1_tab2, value = _NUM:mixvolfrac1, win=SLDpanel
		setvariable mixvolfrac2_tab2, value = _NUM:mixvolfrac2,win=SLDpanel
	endif	
	return 0
End

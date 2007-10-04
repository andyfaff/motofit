#pragma rtGlobals=1		// Use modern global access method.
///MOTOFIT is a program that fits neutron and X-ray reflectivity profiles :written by Andrew Nelson
//Copyright (C) 2005 Andrew Nelson and Australian Nuclear Science and Technology Organisation
//anz@ansto.gov.au
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


//MOTOFIT uses the Parratt formalism to calculate the reflectivity.
//MOTOFIT is a powerful tool for Co-refining multiple contrast datasets from the same sample.
//The software should be compatible with Macintosh/PC/NT platforms and requires that IGOR Pro* is installed. 
//You do not have to purchase IGOR Pro - a free demo version of IGOR Pro is available, however some utilities are disabled (such as copying to/from the clipboard)
//IGOR Pro is a commercial software product available to Mac/PC/NT users. 
//A free demo version of IGOR is available from WaveMetrics Inc. These experiments and procedures were created using IGOR Pro 5.04
//The routines have not been tested on earlier versions of IGOR.

Function Setupmultilayer(ctrlname,checked) : CheckboxControl
	String ctrlname
	Variable checked
	NVAR/z Vmullayers,Vmulrep,Vappendlayer
	Wave coef_Cref,theoretical_R,theoretical_q,sld,zed
	
	String saveDF = getdatafolder(1)
	Setdatafolder root:
	
	SVAR/Z Motofitcontrol=root:motofit:reflectivity:Motofitcontrol
	moto_repstr("multilayer",num2str(checked))
	
	switch(checked)	
		case 0:
			note/K coef_Cref
			note coef_Cref,motofitcontrol
			Moto_update()
			Setformula  SLD,"SLDplot(coef_Cref,zed)"
			killvariables/z Vmullayers,Vmulrep,Vappendlayer
			Moto_repstr("Vmullayers","0")
			Moto_repstr("mulrep","0")
			Moto_repstr("mulappend","0")
			Dowindow/K Multilayerpanel
			Killwaves/Z multilay,coef_multiCref,multikernel
			Dowindow/F Reflectivitypanel
			break						
		case 1:		
			Variable/g root:motofit:reflectivity:tempwaves:Vmullayers=str2num(moto_Str("Vmullayers"))
			Variable/g root:motofit:reflectivity:tempwaves:Vmulrep=str2num(moto_Str("mulrep"))
			Variable/g root:motofit:reflectivity:tempwaves:Vappendlayer=str2num(moto_Str("mulappend"))
						
			if(cmpstr(WinList("Multilayerpanel","",""),"multilayerpanel")!=0)
				Make/o/d/n=0 multilay
				duplicate/o coef_Cref coef_multiCref
				execute/Z "Buildmultilayerpanel()"
			endif
			note/K coef_multiCref
			note coef_multiCref,motofitcontrol
			changemultilayers("",Vmullayers,"","")
			Setformula  SLD,"SLDplot(multikernel,zed)"
			Dowindow/F multilayerpanel

			break
		default:							// optional default expression executed
			break						// when no case matches
	endswitch
	setdatafolder $savedf
End


Function changemultilayers(ctrlname,varnum,varstr,varname) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

//this function adds and removes controls for the multilayer panel.
	SVAR/Z Motofitcontrol=root:Motofitcontrol
	if(varnum!=999)
		moto_repstr("Vmullayers",num2str(varnum))
	endif

	Wave multilay
	NVAR/z Vmullayers = root:motofit:reflectivity:tempwaves:Vmullayers
	Variable oldlayers,nlayers
//when you change the number of layers you need to change the number of parameters
//start off by calculating the size of the original wave, so you can kill waves off.
	oldlayers=(dimsize(multilay,0))/4
	if(varnum==999)
		NVAR/Z controlnum
		oldlayers=controlnum
		killvariables/Z controlnum
	endif
//when you get rid of multilay the oldnumber of layers is going to be 0.25*(coef_multiCref-coef_Cref)

	nlayers=Vmullayers
	redimension/n=(4*nlayers) multilay
	pauseupdate

	Variable ii,parindex,jj			//ii is going to be the layer reference 
	String index,controlname
//if there are less layers remove controls
//if there are more layers add controls

	if(oldlayers>nlayers)							//kill the parameters
		dowindow/F multilayerpanel
		ii=oldlayers
		do
			index=num2str(ii)
			controlname="thick"+index
			killcontrol/W=Multilayerpanel $controlname
			controlname="SLD"+index
			killcontrol/W=Multilayerpanel $controlname
			controlname="solv"+index
			killcontrol/W=Multilayerpanel $controlname
			controlname="rough"+index
			killcontrol/W=Multilayerpanel $controlname
			controlname="mulchem"+index
			killcontrol/W=Multilayerpanel $controlname
		
			jj=0
			parindex=4*ii-3
			do											//kill the holdboxes
				index=num2str(parindex)
				controlname="h"+index
				killcontrol/W=Multilayerpanel $controlname
				parindex+=1
				jj+=1
			while(jj<4)
			ii-=1
		while (ii>nlayers)

	elseif(nlayers>oldlayers)						//make the new waves
		dowindow/F multilayerpanel
		
		Variable ypos								//position of the 1st layer
		String partitle,holdname
		ii=oldlayers
	
		do		//ii is the layer number
			parindex=4*ii															//parindex is the parameter number
			ypos=100+24*(ii)														//setup the new layer positions
		
			partitle=num2istr(parindex+1)+". thick"+num2istr(ii+1)						//par title is the name of the title													
			controlname="thick"+num2istr(ii+1)									//controlname is the name of the control					
			SetVariable $controlname,pos={31,ypos},size={110,16},title=partitle
			SetVariable $controlname,value=multilay[parindex],proc=Moto_UpdateR,win=multilayerpanel
			holdname="h"+num2istr(parindex+1)
			CheckBox $holdname,pos={144,ypos},size={16,14},title="",value= 0,proc=Moto_holdstring,win=multilayerpanel
			parindex+=1
		
			partitle=num2istr(parindex+1)+". SLD"+num2istr(ii+1)				
			controlname="SLD"+num2str(ii+1)										
			SetVariable $controlname,pos={172,ypos},size={110,16},title=partitle
			SetVariable $controlname,value=multilay[parindex],proc=Moto_UpdateR,win=multilayerpanel
			SetVariable $controlname,limits={-Inf,Inf,0.05}
			holdname="h"+num2istr(parindex+1)
			CheckBox $holdname,pos={286,ypos},size={16,14},title="",value= 0,proc=Moto_holdstring,win=multilayerpanel
			parindex+=1
		
			partitle=num2istr(parindex+1)+". solv"+num2istr(ii+1)				
			controlname="solv"+num2str(ii+1)										
			SetVariable $controlname,pos={310,ypos},size={110,16},title=partitle
			SetVariable $controlname,value=multilay[parindex],proc=Moto_UpdateR,win=multilayerpanel
			SetVariable $controlname,limits={0,100,5}
			holdname="h"+num2istr(parindex+1)
			CheckBox $holdname,pos={424,ypos},size={16,14},title="",value= 0,proc=Moto_holdstring,win=multilayerpanel
			parindex+=1
	
			partitle=num2istr(parindex+1)+". rough"+num2istr(ii+1)				
			controlname="rough"+num2str(ii+1)										
			SetVariable $controlname,pos={445,ypos},size={110,16},title=partitle
			SetVariable $controlname,value=multilay[parindex],proc=Moto_UpdateR,win=multilayerpanel
			SetVariable $controlname,limits={0,100,0.5}
			holdname="h"+num2istr(parindex+1)
			CheckBox $holdname,pos={559,ypos},size={16,14},title="",value= 0,proc=Moto_holdstring,win=multilayerpanel
			ii+=1
		
			controlname="mulchem"+num2str(ii)										
			Popupmenu $controlname,pos={660,ypos-3},mode=1,fsize=6,popvalue="_none_",value=#"root:motofit:reflectivity:SLDdatabase:chemicals",proc=Moto_SLDintocoef_Cref,win=multilayerpanel
		
		while(ii<nlayers)
	else
		//do nothing
	endif
	Moto_update()
End

Function BuildMultilayerpanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(250,228,1024,612) as "Multilayer Panel"
	ModifyPanel cbRGB=(0,52224,52224)
	SetVariable mullayers,pos={0,1},size={194,16},proc=changemultilayers,title="Number of layers in stack"
	SetVariable mullayers,limits={0,Inf,1},value= root:motofit:reflectivity:tempwaves:Vmullayers
	SetVariable mulrep,pos={2,25},size={194,16},proc=Motofit_Varproc,title="Number of repetitions"
	SetVariable mulrep,limits={0,Inf,1},value= root:motofit:reflectivity:tempwaves:Vmulrep
	SetVariable mulAppend,pos={2,51},size={194,16},proc=Motofit_Varproc,title="Append to stack to layer No."
	SetVariable mulAppend,limits={0,Inf,1},value= root:motofit:reflectivity:tempwaves:Vappendlayer
	Dowindow/C Multilayerpanel
End


Function Createmultilayer(coef_Cref,multilay)
	Wave coef_Cref
	Wave multilay
	//this function makes coef_multiCref from coef_Cref and multilay
	Wave coef_multiCref
	NVAR/z Vmullayers = root:motofit:reflectivity:tempwaves:Vmullayers 
	NVAR/z Vmulrep = root:motofit:reflectivity:tempwaves:Vmulrep
	NVAR/z Vappendlayer = root:motofit:reflectivity:tempwaves:Vappendlayer
		
	if(Vappendlayer>coef_Cref[0])
		ABORT "can't append to this position, append has to be =< number of base layers"
	endif
	concatenate/o/np {coef_cref,multilay},coef_multiCref
	
End

Function Decompose_multilayer()
//this will take coef_multiCref and turn it back into coef_Cref and Multilayer
	Wave coef_Cref,multilay,coef_multiCref
	Variable parbase=coef_Cref[0]*4+6,parmulti=numpnts(coef_multiCref)-parbase
	Variable ii=1
	do
		coef_Cref[ii]=coef_multiCref[ii]
		ii+=1
	while(ii<parbase)

	Variable jj=0
	do
		multilay[jj]=coef_multiCref[ii]
		ii+=1
		jj+=1
	while(jj<parmulti)

End

Function Kerneltransformation(coef_multiCref)
	Wave coef_multiCref
	Wave coef_Cref
//this will transform coef_multiCref into something that the reflectivity kernel can understand
//don't need to do anything with the first 6 points, as they are already setup from coef_Cref
//the first layer is the top layer
	NVAR/z Vmullayers = root:motofit:reflectivity:tempwaves:Vmullayers
	NVAR/z Vmulrep  = root:motofit:reflectivity:tempwaves:Vmulrep
	NVAR/z Vappendlayer = root:motofit:reflectivity:tempwaves:Vappendlayer
	
	Variable baselength=numpnts(coef_Cref)
	Variable ii,jj,kk,mm
	variable totallength=(numpnts(coef_Cref)+(4*Vmullayers*Vmulrep))
	Duplicate/o coef_multiCref,multikernel,repeat
	deletepoints 0,baselength,repeat
	
	if(abs(numpnts(multikernel)-totallength)>=0)
		redimension/n=(numpnts(coef_Cref)+(4*Vmullayers*Vmulrep)) Multikernel
		Multikernel[0]=(numpnts(multikernel)-6)/4
	endif

	for(ii=0;ii<Vappendlayer;ii+=1)	
		Multikernel[4*(ii+1)+2]=coef_multiCref[4*(ii+1)+2]		
		Multikernel[4*(ii+1)+2+1]=coef_multiCref[4*(ii+1)+2+1]
		Multikernel[4*(ii+1)+2+2]=coef_multiCref[4*(ii+1)+2+2]
		Multikernel[4*(ii+1)+2+3]=coef_multiCref[4*(ii+1)+2+3]						
	endfor											

//don't reset ii its counting up the layers
//kk is the multilayer counter, ii is the cumulative multikernel counter,jj is the individual parameter
//within the multilayer

	for(mm=0;mm<Vmulrep;mm+=1)
		if(mm==0)
			redimension/n=(6+(4*ii)) Multikernel
		endif
		concatenate/NP/O {multikernel,repeat},multikernel	
		ii+=numpnts(repeat)/4
	endfor
	
	ii+=1
	redimension/n=(totallength) multikernel
	for(mm=Vappendlayer+1;mm<coef_Cref[0]+1;mm+=1)	
		Multikernel[4*ii+2]=coef_multiCref[4*mm+2]		
		Multikernel[4*ii+2+1]=coef_multiCref[4*mm+2+1]
		Multikernel[4*ii+2+2]=coef_multiCref[4*mm+2+2]
		Multikernel[4*ii+2+3]=coef_multiCref[4*mm+2+3]
		ii+=1								
	endfor
											
	killwaves/Z repeat
End

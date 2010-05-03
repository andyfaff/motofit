#pragma rtGlobals=1		// Use modern global access method.
Function parseCarFile()

	string cDF = getdatafolder(1)
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o/s root:packages:motofit:reflectivity:SLDdatabase

	string buffer, element,otherCrap
	variable fileID,  xx,yy,zz
	variable lineNumber

	make/n=0/t/o  elementType
	make/n=(0,3)/o elementPositions
	make/n=(3)/o/d  cellDimensions

	open/r/M="the car file"/T=".car" fileID
	if(!fileID)
		abort
	endif

	lineNumber = 0
	do
		FReadLine fileID, buffer
		if(!strlen(buffer))
			break
		endif

		if(stringmatch(buffer, "end\r"))
			continue
		endif
		if(lineNumber == 4)
			sscanf buffer, "%s %f %f %f %s", element, xx, yy, zz, otherCrap
			cellDimensions = {xx, yy, zz}
		elseif(lineNumber > 4)
			sscanf buffer, "%s %f %f %f", element, xx, yy, zz
			if(V_flag > 0)
				redimension/n=(dimsize(elementtype, 0) + 1, -1) elementType, elementPositions
				elementType[dimsize(elementtype, 0)- 1] = "0" + element[0,0]
				elementPositions[dimsize(elementPositions, 0)- 1][0] = xx
				elementPositions[dimsize(elementPositions, 0)- 1][1] = yy
				elementPositions[dimsize(elementPositions, 0)- 1][2] = zz		
			endif
		endif
	
		lineNumber +=1
	while(1)


	setdatafolder $cDF

	if(fileID)
		close(fileID)
	endif

	//initialise SLD database
	Moto_SLDdatabase()
End

Function parsePDBFile()

	string cDF = getdatafolder(1)
	newdatafolder/o root:packages
	newdatafolder/o root:packages:motofit
	newdatafolder/o root:packages:motofit:reflectivity
	newdatafolder/o/s root:packages:motofit:reflectivity:SLDdatabase

	string buffer, element,otherCrap, othercrap1, othercrap2, othercrap3, othercrap4
	variable fileID,  xx,yy,zz, otherCrapV, otherCrapV1, otherCrapV2, otherCrapV3
	variable lineNumber

	make/n=0/t/o  elementType
	make/n=(0,3)/o elementPositions
	make/n=(3)/o/d  cellDimensions

	open/r/M="the PDB file"/T=".pdb" fileID
	if(!fileID)
		abort
	endif

	lineNumber = 0
	do
		FReadLine fileID, buffer
		if(!strlen(buffer))
			break
		endif

		if(stringmatch(buffer[0,5], "CRYST1"))
			sscanf buffer, "%s %f %f %f %s", element, xx, yy, zz, otherCrap
			cellDimensions = {xx, yy, zz}		
		endif
		if(stringmatch(buffer[0,3], "ATOM"))
			sscanf buffer, "%s %f %s %s %f  %f %f %f", othercrap, othercrapV1, element, otherCrap, otherCrapV2, xx, yy, zz
			if(V_flag > 0)
				redimension/n=(dimsize(elementtype, 0) + 1, -1) elementType, elementPositions
				elementType[dimsize(elementtype, 0)- 1] = "0" + element[0,0]
				elementPositions[dimsize(elementPositions, 0)- 1][0] = xx
				elementPositions[dimsize(elementPositions, 0)- 1][1] = yy
				elementPositions[dimsize(elementPositions, 0)- 1][2] = zz			
			endif
		endif
	
		lineNumber +=1
	while(1)

	if(fileID)
		close(fileID)
	endif

	//initialise SLD database
	Moto_SLDdatabase()
	setdatafolder $cDF

End

Function SLDprofile(binSize)
	variable binsize
	Wave elementPositions = root:packages:motofit:reflectivity:SLDdatabase:elementPositions
	Wave  cellDimensions = root:packages:motofit:reflectivity:SLDdatabase:cellDimensions
	Wave/t elementType = root:packages:motofit:reflectivity:SLDdatabase:elementType
	variable ii, zposition, nsl, xsl, elem_sel, row, col
	
	variable molecularVolume = cellDimensions[0] * cellDimensions[1] * binsize
	make/n=(round(cellDimensions[2]/binsize), 2)/o/d MD_profile = 0
	setscale/P x, 0, binsize, MD_profile
	
	
	Wave/t scatlengths = root:packages:motofit:reflectivity:SLDdatabase:scatlengths
	for(ii=0 ; ii< dimsize(scatlengths, 0) ; ii+=1)
		scatlengths[ii][0] = replacestring(" ", scatlengths[ii][0], "")
	endfor
	
	for(ii=0 ; ii < dimsize(elementpositions, 0) ; ii+=1)
		zposition = x2pnt(MD_profile, elementpositions[ii][2])
		findvalue/TXOP=4/text=(elementtype[ii]) scatlengths
		col=floor(V_value / dimsize(scatlengths, 0))
		row=V_value-col * dimsize(scatlengths, 0)

		MD_profile[zposition][0] += str2num(scatlengths[row][2])
		MD_profile[zposition][1] += str2num(scatlengths[row][5])
	endfor
	MD_profile *= 2.8179
	MD_profile /= molecularvolume
	MD_profile *=10	
End

Function makeintoMotofitInput(MD_profile, type, doReverse)
	Wave MD_profile
	variable type //0=neutron 1=Xray
	variable doReverse

	variable ii
	variable delta = dimdelta(MD_profile, 0)
	variable nlayers = dimsize(MD_profile, 0)
	make/n=(4*nlayers + 6)/o/d coef_MD

	if(doReverse)
		reverse/dim=0 MD_profile
	endif
	coef_MD[0] = nlayers
	coef_MD[1] = 1
	coef_MD[2] = MD_profile[0][type]
	coef_MD[3] = MD_profile[inf][type]
	coef_MD[4] = 0
	coef_MD[5] = 0

	for(ii = 0 ; ii<nlayers ; ii+=1)
		coef_MD[4 * ii + 6] = abs(delta)
		coef_MD[4 * ii + 7] = MD_profile[ii][type]
		coef_MD[4 * ii + 8] = 0
		coef_MD[4 * ii + 9] = 0
	endfor
End
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

static constant NewGF_DSList_NCoefCol = 3
static constant NewGF_DSList_YWaveCol = 0
static constant NewGF_DSList_XWaveCol = 1
static constant NewGF_DSList_FuncCol = 2
static constant NewGF_DSList_FirstCoefCol = 0

function tool()
Struct tonker LB_Struct
LB_Struct.eventcode=7
LB_Struct.ctrlname="newGF_Datasetslist"
LB_Struct.win="Motoglobalfitpanel#tab0contentpanel"
LB_Struct.col=3
doup(LB_Struct)
ENd

structure globtabs
char ctrlname[100]
char win[100]
STRUCT Rect winRect
STRUCT Rect ctrlrect
int32 eventcode
int32 eventmod
string userdata
int32 tab
STRUCT Point mouseLoc
endstructure

Function sorttabs(TC_Struct,tabb)
	STRUCT globtabs &TC_Struct
	variable tabb			//which tab are you selecting in the global panel?
	TC_Struct.win="Motoglobalfitpanel"
	TC_Struct.eventmod=1
	TC_Struct.ctrlname="NewGF_tabcontrol"
	TC_Struct.winrect.top=0
	TC_Struct.winrect.left=0
	TC_Struct.winrect.bottom=377
	TC_Struct.winrect.right=669
	TC_Struct.ctrlrect.top=7
	TC_Struct.ctrlrect.left=10
	TC_Struct.ctrlrect.bottom=262
	TC_Struct.ctrlrect.right=664
	TC_Struct.eventcode=2
	TC_Struct.tab=tabb
	TC_Struct.mouseLoc.v=16
	TC_Struct.mouseLoc.h=178
	if (TC_Struct.eventCode == 2)
		MOTO_NewGF_SetTabControlContent(TC_Struct.tab)
	endif
End

Structure tonker
char ctrlname[100]
char win[100]
Struct Rect winrect
Struct Rect ctrlrect
int32 eventcode
int32 eventmod
string userdata
int32 eventcode2
int32 row
int32 col
Wave/S listwave
Wave selwave
Wave colorwave
Endstructure

Function	doup(LB_struct)
Struct tonker &LB_struct 
Variable numcoefs
	String funcName
	
	if (LB_Struct.eventCode == 7)		// finish edit
		if (CmpStr(LB_Struct.ctrlName, "NewGF_Tab0CoefList") == 0)
			return 0
		endif
			
		if (LB_Struct.col == NewGF_DSList_NCoefCol)
			Wave/T ListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListWave
			Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListSelWave
			Wave/T CoefListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListWave
			Wave CoefSelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListSelWave
			Variable i,j
			Variable numrows = DimSize(ListWave, 0)
			Variable numcols = DimSize(Listwave, 1)
		
			numcoefs = str2num(ListWave[LB_Struct.row][LB_Struct.col][0])
			funcName = ListWave[LB_Struct.row][NewGF_DSList_FuncCol][0]
			Variable/G root:motofit:MOTOFITGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
			
			if (NumCoefs > DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
				Redimension/N=(-1,NumCoefs+NewGF_DSList_FirstCoefCol, -1) CoefListWave, CoefSelWave
				for (i = 1; i < NumCoefs; i += 1)
					SetDimLabel 1, i+NewGF_DSList_FirstCoefCol,$("K"+num2str(i)), CoefListWave
				endfor
			endif
			for (i = 0; i < numrows; i += 1)
				if (CmpStr(funcName, ListWave[i][NewGF_DSList_FuncCol][0]) == 0)
					ListWave[i][NewGF_DSList_NCoefCol][0] = num2str(numCoefs)
					for (j = 0; j < numCoefs; j += 1)
						if (!MOTO_WM_NewGlobalFit1#IsLinkText(CoefListWave[i][NewGF_DSList_FirstCoefCol+j][0]))		// don't change a LINK specification
							CoefListWave[i][NewGF_DSList_FirstCoefCol+j] = "r"+num2istr(i)+":K"+num2istr(j)
						endif
					endfor
				endif
			endfor
			
			MOTO_WM_NewGlobalFit1#NewGF_CheckCoefsAndReduceDims()
		endif
	elseif(LB_Struct.eventCode == 1)		// mouse down
			Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListSelWave
			
		if (LB_Struct.row == -1)
			if (CmpStr(LB_Struct.ctrlName, "NewGF_Tab0CoefList") == 0)
				Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListSelWave
			else
				Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListSelWave
			endif
			SelWave[][][0] = SelWave[p][q] & ~1				// de-select everything to make sure we don't leave something selected in another column
			SelWave[][LB_Struct.col][0] = SelWave[p][LB_Struct.col] | 1			// select all rows
		elseif ( (LB_Struct.row >= 0) && (LB_Struct.row < DimSize(SelWave, 0)) )
			if (CmpStr(LB_Struct.ctrlName, "NewGF_Tab0CoefList") == 0)
				return 0
			endif
			
//			if (GetKeyState(0) == 0)										// no modifier keys
			if (MOTO_WM_NewGlobalFit1#isControlOrRightClick(LB_Struct.eventMod))				// right-click or ctrl-click
				switch(LB_Struct.col)
					case NewGF_DSList_YWaveCol:
						PopupContextualMenu MOTO_NewGF_YWaveList(-1)
						if (V_flag > 0)
							Wave w = $S_selection
							MOTO_WM_NewGlobalFit1#NewGF_SetYWaveForRowInList(w, $"", LB_Struct.row)
							SelWave[LB_Struct.row][LB_Struct.col][0] = 0
						endif
						break
					case NewGF_DSList_XWaveCol:
						Wave/T ListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListWave
						Wave w = $(ListWave[LB_Struct.row][NewGF_DSList_YWaveCol][1])
						if (WaveExists(w))
							String RowsText = num2str(DimSize(w, 0))
							PopupContextualMenu "_calculated_;"+WaveList("*",";","MINROWS:"+RowsText+",MAXROWS:"+RowsText+",DIMS:1,CMPLX:0,TEXT:0,BYTE:0,WORD:0,INTEGER:0")
							if (V_flag > 0)
								Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListSelWave
								Wave/Z w = $S_selection
								MOTO_NewGF_SetXWaveInList(w, LB_Struct.row)
								SelWave[LB_Struct.row][LB_Struct.col][0] = 0
							endif
						endif
						break
					case NewGF_DSList_FuncCol:
						PopupContextualMenu MOTO_NewGF_FitFuncList()
						if (V_flag > 0)
							FuncName = S_selection
							
							Wave/T ListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListWave
							Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListSelWave
							Wave/T CoefListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListWave
							Wave CoefSelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListSelWave
							
							String CoefList
							NumCoefs = MOTO_WM_NewGlobalFit1#GetNumCoefsAndNamesFromFunction(FuncName, coefList)
							
							if (numType(NumCoefs) == 0)
								if (NumCoefs > DimSize(CoefListWave, 1)-NewGF_DSList_FirstCoefCol)
									Redimension/N=(-1,NumCoefs+NewGF_DSList_FirstCoefCol, -1) CoefListWave, CoefSelWave
									for (i = 1; i < NumCoefs; i += 1)
										SetDimLabel 1, i+NewGF_DSList_FirstCoefCol,$("K"+num2str(i)), CoefListWave
									endfor
								endif
							endif
							
							Variable/G root:motofit:MOTOFITGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
							ListWave[LB_Struct.row][NewGF_DSList_FuncCol][0] = FuncName
							if (numType(NumCoefs) == 0)
								ListWave[LB_Struct.row][NewGF_DSList_NCoefCol][0] = num2istr(NumCoefs)
								for (j = 0; j < NumCoefs; j += 1)
									String coeftitle = StringFromList(j, coefList)
									if (strlen(coeftitle) == 0)
										coeftitle = "r"+num2istr(LB_Struct.row)+":K"+num2istr(j)
									else
										coeftitle = "r"+num2istr(LB_Struct.row)+":"+coeftitle
									endif
									CoefListWave[LB_Struct.row][NewGF_DSList_FirstCoefCol+j] = coeftitle
								endfor
								SelWave[LB_Struct.row][NewGF_DSList_NCoefCol][0] = 0
							else
								SelWave[LB_Struct.row][NewGF_DSList_NCoefCol][0] = 2
							endif
							for (j = j+NewGF_DSList_FirstCoefCol;j < DimSize(ListWave, 1); j += 1)
								CoefListWave[LB_Struct.row][j] = ""
							endfor
							
							MOTO_WM_NewGlobalFit1#NewGF_CheckCoefsAndReduceDims()
						endif
						break
				endswitch
			endif
		endif
	elseif ( (LB_Struct.eventCode == 8) || (LB_Struct.eventCode == 10) )		// vertical scroll or programmatically set top row
		String otherCtrl = ""
		if (CmpStr(LB_Struct.ctrlName, "NewGF_DataSetsList") == 0)
			otherCtrl = "NewGF_Tab0CoefList"
		else 
			otherCtrl = "NewGF_DataSetsList"
		endif
		ControlInfo/W=MotoGlobalFitPanel#Tab0ContentPanel $otherCtrl
//print LB_Struct.ctrlName, otherCtrl, "event = ", LB_Struct.eventCode, "row = ", LB_Struct.row, "V_startRow = ", V_startRow
		if (V_startRow != LB_Struct.row)
			ListBox $otherCtrl win=MotoGlobalFitPanel#Tab0ContentPanel,row=LB_Struct.row
			DoUpdate
		endif
	endif
End


Function Removeallglobals()
	string popstr="Remove All"
	variable eventcode=2
	
	Wave/T ListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListWave
	Wave SelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_DataSetListSelWave
	Wave/T CoefListWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListWave
	Wave CoefSelWave = root:motofit:MOTOFITGF:NewGlobalFit:NewGF_MainCoefListSelWave
	
	Variable i,j
	Variable ncols = DimSize(ListWave, 1)
	Variable nrows = DimSize(ListWave, 0)
	
	if (eventCode == 2)			// mouse up
		strswitch (popStr)
			case "Remove All":
				Redimension/N=(1, 4, -1) ListWave, SelWave
				Redimension/N=(1, 1, -1) CoefListWave, CoefSelWave
				ListWave = ""
				CoefListWave = ""
				SelWave = 0
				CoefSelWave = 0
				Variable/G root:MOTOFITGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
				break
			case "Remove Selection":
				for (i = nrows-1; i >= 0; i -= 1)
					for (j = 0; j < ncols; j += 1)
						if (SelWave[i][j][0] & 9)
							DeletePoints i, 1, ListWave, SelWave, CoefListWave, CoefSelWave
							Variable/G root:MOTOFITGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
							break
						endif
					endfor
				endfor
				break
			default:
				for (i = 0; i < nrows; i += 1)
					if (CmpStr(popStr, ListWave[i][NewGF_DSList_YWaveCol][0]) == 0)
						DeletePoints i, 1, ListWave, SelWave, CoefListWave, CoefSelWave
						Variable/G root:MOTOFITGF:NewGlobalFit:NewGF_RebuildCoefListNow = 1			// this change invalidates the coefficient list on the Coefficient Control tab
						break
					endif
				endfor
				break
		endswitch
	endif
end

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


Function fresnelreflectivity(w,y,z):fitfunc
Wave w,y,z
Duplicate/o z fresneldiv
Duplicate/o z fresnelnum
duplicate/o w callfres
callfres[6]=0 
motofit(callfres,fresnelnum,z)
redimension/n=8 callfres
callfres[0]=0
motofit(callfres,fresneldiv,z)

fastop y=fresnelnum/fresneldiv
killwaves fresneldiv,fresnelnum,callfres

End

Function Calcfresnel(w,y,z)
Wave w,y,z
Duplicate/o y fresneldiv
Duplicate/o w callfres
redimension/n=8 callfres
callfres[0]=0
callfres[6]=0
Motofit(callfres,fresneldiv,z)
y/=fresneldiv
killwaves/Z fresneldiv
End


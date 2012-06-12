#pragma rtGlobals=3		// Use modern global access method.
#pragma IgorVersion = 6.2

//Elements in polarization: Polarizer, Flipper1, Flipper2, Analyzer

//R-- =  (Pol) + (Flipper1 OFF) + (Flipper2 OFF) + (Ana)
//R++ =  (Pol) + (Flipper1 ON) + (Flipper2 ON) + (Ana)

//FUNCTIONS IN THIS FILE:
//Function polcorr_FULL(I00, I01, I10, I11) //FULL polarization analysis INPUT: PLPR--, PLPR-+, PLPR+-, PLP++, 
//Function polcorr_NSF(I00, I01, I10, I11) //ONLY R++ and R-- recorded, physical assuming I01 = I10 = 0,  ANA = F2 = 1; Input I01 == 00, I10 == 00
//Function polcorr_R01(I00, I01, I10, I11) //Only ONE spin-flip channel recorded, physical assuming I01 = I10  and vice versa
//Function polcorr_R0R1(I00, I01, I10, I11) //Only POLARIZER and FLIPPER1 used, physical assuming ANA = 1, F2=0, I01=I10=0 
//Function polcorr_DB(I00, I01, I10, I11) //Direct beam case, scaling only 

//ATTENTION: If the efficiencies of the elements in the polarzation setup change, these have to be entered in each of the functions above!!!
//Some constants defining the efficiency of each element. Here, the polarizer and analyzer efficiency is wavelength dependent: a-b*c^(lambda)
//The waves containing the efficiency to calculate the correction are: poleff, anaeff, flipper1, flipper2
//ATTENTION:
//If you need to change the function describing the wavlength dependence, you need to do so for each wave in each function separately!!! Search for poleff, anaeff, flipper1, flipper2

//poleff = polarizer_efficiency_constant_a - polarizer_efficiency_constant_b * polarizer_efficiency_constant_c ^ ("lambda")
Constant polarizer_efficiency_constant_a = 0.993 
Constant polarizer_efficiency_constant_b = 0.57 
Constant polarizer_efficiency_constant_c = 0.47
//anaeff = analyzer_efficiency_constant_a - analyzer_efficiency_constant_b * analyzer_efficiency_constant_c ^ ("lambda")
Constant analyzer_efficiency_constant_a = 0.993
Constant analyzer_efficiency_constant_b = 0.57
Constant analyzer_efficiency_constant_c = 0.51

Constant flipper1_efficiency_constant_a = 0.997 //flipper1 = flipper1_efficiency_constant_a
Constant flipper2_efficiency_constant_a = 0.997 //flipper2 = flipper2_efficiency_constant_a

Function polcorr_FULL(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, [verbose])
 	//FULL polarization analysis, i.e. all elements have been in the beam and all four poalrization channels have been ,measured.
 	//The Function returns 0 if successfull, 1 if not
 	string I00, I01, I10, I11 //Name the files that should be polarization corrected. The filename has to be given in full.
 	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11 //each channel has an individual scaling factor
 	variable verbose
 	// Additional variables to check the wave dimensions
 	variable nRows, nCols
 	variable nRows00, nCols00, nRowslambda00, nColslambda00
 	variable nRows01, nCols01, nRowslambda01, nColslambda01
 	variable nRows10, nCols10, nRowslambda10, nColslambda10
 	variable nRows11, nCols11, nRowslambda11, nColslambda11
 	// Additional variables containing the efficiencies of the devices 
 	variable a,b,c,L
  	//Run indices
  	variable ii, jj
  	string cDF
  	cDF = getdatafolder(1) //returns the string containing the full path to the datafolder

	try
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I00))
			print "ERROR, I00 folder or wave M_Spec not found (polcorr_FULL)";
			abort
		endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I01))
			print "ERROR, I01 folder or wave M_Spec not found (polcorr_FULL)"; 
			abort
		endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I10))
			print "ERROR, I10 folder or wave M_Spec not found (polcorr_FULL)"; 
			abort
		endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I11))
			print "ERROR, I11 folder or wave M_Spec not found (polcorr_FULL)"; 
			abort
		endif
		Newdatafolder/o root:packages:platypus:data:Reducer:PolCorrected
		string datafolder
		datafolder = "root:packages:platypus:data:Reducer:PolCorrected"
		setdatafolder datafolder 
		
		Wave nI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_Spec") 
		Wave nI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_Spec")
		Wave nI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_Spec")
		Wave nI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_Spec")
		Wave nI00SD = $("root:packages:platypus:data:Reducer:"+I00+":M_SpecSD") 
		Wave nI01SD = $("root:packages:platypus:data:Reducer:"+I01+":M_SpecSD")
		Wave nI10SD = $("root:packages:platypus:data:Reducer:"+I10+":M_SpecSD")
		Wave nI11SD = $("root:packages:platypus:data:Reducer:"+I11+":M_SpecSD")
		Wave LI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_lambda")
		Wave LI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_lambda")
		Wave LI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_lambda")
		Wave LI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_lambda")
		
		//figure out how many rows are in each M_Spec and compare the length. It might be that the wavelength is different for each file, which is bad...
		//but i cannot see how they should be different, but you need to make a test and abort if bad.
	 	//One should also a test if the length of M_lambda and M_Spec is the same...		
		nRows00 =DimSize(nI00,0); nCols00 = DimSize(nI00,1);
		nRowslambda00 = DimSize(LI00,0)
		nRows01 = DimSize(nI01,0); nCols00 = DimSize(nI01,1);
		nRowslambda01 = DimSize(LI01,0)
		nRows10 = DimSize(nI10,0); nCols10 = DimSize(nI10,1);
		nRowslambda10 = DimSize(LI10,0)
		nRows11 = DimSize(nI11,0); nCols11 = DimSize(nI11,1);
		nRowslambda11 = DimSize(LI11,0)
		//Check that M_Spec and M_Lambda have the same length and that the columns of M_spec are smaller than 2
		if(nCols00>1 || nCols11>1 || nCols01>1 || nCols10>1)
			print "ERROR: A streamed reduction of multidimensional data is not possible at this point (polcorr_FULL)"; abort
		endif
		
		if(!equalwaves(nI00, LI00, 512))
			print "ERROR: The row length of M_lambda and M_Spec have different dimension (polcorr_FULL)"+I00
			abort
		endif
		//Check that the datasets have the same length
		//print nRows00, nRows01, nRows10, nRows11
		if(!equalwaves(nI00, nI01, 512) || !equalwaves(nI00, nI10, 512) || !equalwaves(nI00, nI11, 512))
			print "ERROR: The dimensions of the M_Spec is different in the spectra (polcorr_FULL)"
			abort
		endif
		//Check that the wavelength is the same
		if(!equalwaves(LI00, LI01, 1) || !equalwaves(LI00, LI10, 1) || !equalwaves(LI00, LI11, 1))
			print "ERROR: The wavelengths in M_lambda are different to each other in the datafiles (polcorr_FULL)"
			abort
		endif
		//Set a global row length 				
		nRows = nRows00; nCols = nCols00
		//Make the final Reflectivity Waves
		make/o/d/n=(nRows, nCols) RI00; make/o/d/n=(nRows, nCols) RI01; make/o/d/n=(nRows, nCols) RI10; make/o/d/n=(nRows, nCols) RI11 
		//Maken the wave for the polarizer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are defined to describe the efficiency function
		//The values in the comments are the original values until April2012. If the system changes, the new values have to be calculated and inserted here.
		make/o/d/n=(nRows, nCols) poleff
		//print polarizer_efficiency_constant_a //0.993 asymptote
  		//print polarizer_efficiency_constant_b //0.57 response range yaxis
  		//print polarizer_efficiency_constant_c //0.47rate
  		poleff = polarizer_efficiency_constant_a-polarizer_efficiency_constant_b*polarizer_efficiency_constant_c^(LI00)
		 
		make/o/d/n=(nRows, nCols) anaeff
	  	//print analyzer_efficiency_constant_a //a=0.993; 
  		//print analyzer_efficiency_constant_b //b=0.57; 
  		//print analyzer_efficiency_constant_c //c=0.47; 
  		anaeff = analyzer_efficiency_constant_a-analyzer_efficiency_constant_b*analyzer_efficiency_constant_c^(LI00)
		make/o/d/n=(nRows, nCols) flipper1
	  	make/o/d/n=(nRows, nCols) flipper2
	  	//a=0.997 //a=0.997;
	  	//b=0.997 //b=0.997; 
  		
  		flipper1 = flipper1_efficiency_constant_a
  		flipper2 = flipper2_efficiency_constant_a
  		 
  		/////////////////////////////
  		// FOR TESTING PURPOSES ONLY!!!, Here you can manually change the efficiencies to see what happens!
  		// poleff = 1; 
  		// anaeff = 1; 
  		// flipper1 = 1; 
  		// flipper2 = 1;
  		/////////////////////////////
		
		//Make the temporary waves for calculation thorugh the matrices
		make/o/d/n=(nRows, nCols) polefftemp
		make/o/d/n=(nRows, nCols) anaefftemp
		make/o/d/n=(nRows, nCols) flipper1temp
	  	make/o/d/n=(nRows, nCols) flipper2temp
	  	//In order to process the efficiencies in the matrix, we need to convert them into a different form.
		polefftemp =(1-(-1*poleff))/2 
  	    	anaefftemp= (1-(-1*anaeff))/2
  	    	flipper1temp = (1-flipper1)
  	    	flipper2temp = (1-flipper2)
  	    	//The below Matrizes contain the efficiencies of the elements in the polarization setup 
  	    	make/o/d/n=(4,4,nRows) matpol, matana, matflipone, matfliptwo, final
  	    	  	    	
  	    	matpol[0][0][] =1- polefftemp[r];		matpol[0][1][] =0;				 	 matpol[0][2][] =polefftemp[r]; 			matpol[0][3][] =0;
  	    	matpol[1][0][] =0;                    		matpol[1][1][] =1- polefftemp[r];	  	 matpol[1][2][] =0; 					matpol[1][3][] =polefftemp[r];
  	    	matpol[2][0][] =polefftemp[r];    		matpol[2][1][] =0; 	 		 	 matpol[2][2][] =1- polefftemp[r]; 		matpol[2][3][] =0;
  	    	matpol[3][0][] =0;                    		matpol[3][1][] =polefftemp[r];	 	 matpol[3][2][] =0;		 			matpol[3][3][] =1- polefftemp[r];
		
		matana[0][0][] =1- anaefftemp[r];	matana[0][1][] =anaefftemp[r];		 matana[0][2][] =0;		 			matana[0][3][] =0;
  	    	matana[1][0][] =anaefftemp[r];        	matana[1][1][] =1- anaefftemp[r];	 matana[1][2][] =0; 					matana[1][3][] =0;
  	    	matana[2][0][] =0;			   	matana[2][1][] =0; 	 		 	 matana[2][2][] =1- anaefftemp[r]; 		matana[2][3][] =anaefftemp[r];
  	    	matana[3][0][] =0;                    	matana[3][1][] =0;			 	 matana[3][2][] =anaefftemp[r]; 			matana[3][3][] =1- anaefftemp[r];
  	    	
  	    	matflipone[0][0][] =1;				matflipone[0][1][] =0;				 matflipone[0][2][] =0; 					matflipone[0][3][] =0;
  	    	matflipone[1][0][] =0;                    	matflipone[1][1][] =1;	 			 matflipone[1][2][] =0; 					matflipone[1][3][] =0;
  	    	matflipone[2][0][] =flipper1temp[r];   	matflipone[2][1][] =0; 	 			 matflipone[2][2][] =1- flipper1temp[r]; 	matflipone[2][3][] =0;
  	    	matflipone[3][0][] =0;                    	matflipone[3][1][] =flipper1temp[r];	 matflipone[3][2][] =0;		 			matflipone[3][3][] =1- flipper1temp[r];

		matfliptwo[0][0][] =1;				matfliptwo[0][1][] =0;				 matfliptwo[0][2][] =0; 					matfliptwo[0][3][] =0;
  	    	matfliptwo[1][0][] =flipper2temp[r];	matfliptwo[1][1][] =1-flipper2temp[r];	 matfliptwo[1][2][] =0; 					matfliptwo[1][3][] =0;
  	    	matfliptwo[2][0][] =0;   			matfliptwo[2][1][] =0; 	 			 matfliptwo[2][2][] =1; 					matfliptwo[2][3][] =0;
  	    	matfliptwo[3][0][] =0;                    	matfliptwo[3][1][] =0;	 			 matfliptwo[3][2][] =flipper2temp[r];		matfliptwo[3][3][] =1- flipper2temp[r];

		//The Full Matrix equation looks like Int(1x4) = (F1[4x4]) (F2[4x4]) (P[4x4]) (A[4x4]) R(1x4)
		//Therefore, in order to calculate R, we need to multiply the intensity (Int) with the inverse of the efficiency matrices	
		//Calculate the combined efficiency matrix.			
		MatrixOp finals =  matflipone x matfliptwo x matpol x matana
		//Calculate the inverse.
		MatrixOp finaltemp = Inv(finals)
		for(ii=0; ii<nRows; ii+=1)
			final[][][ii] = finaltemp
		endfor	
		killwaves/z finals, finaltemp
		//Make a vector for the intensities and the reflectivities
		make/o/d/n=(4,1,nRows) vecintensities
		vecintensities[0][0][] = nI00[r]/scalefactorI00; vecintensities[1][0][] = nI01[r]/scalefactorI01; vecintensities[2][0][] = nI10[r]/scalefactorI10; vecintensities[3][0][] = nI11[r]/scalefactorI11
		//Calculate the vector of the reflectivities
		MatrixOp vecreftemp = final x vecintensities
		for(ii=0; ii<nRows; ii+=1) 	 
		 	RI11[ii][] = vecreftemp[0][0][ii]
		 	RI10[ii][] = vecreftemp[1][0][ii]
		 	RI01[ii][] = vecreftemp[2][0][ii]
		 	RI00[ii][] = vecreftemp[3][0][ii]
		endfor	
		killwaves/z vecreftemp
		if(verbose)
		print "(polcorr_FULL) polarization correction executed successfully"
		endif
		//Put the corrected spectra back in the original datafolder to have it easier with Andys reduction
		string I00path = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorr"
		string I01path = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorr"
		string I10path = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorr"
		string I11path = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorr"
		//Make the error waves after polcorr
		string I00SDpath = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorrSD"
		string I01SDpath = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorrSD"
		string I10SDpath = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorrSD"
		string I11SDpath = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorrSD"
		
		make/o/d/n=(nRows, nCols) $I00path
		WAVE CI00 =  $I00path
		make/o/d/n=(nRows, nCols) $I01path 
		WAVE CI01 =  $I01path
		make/o/d/n=(nRows, nCols) $I10path 
		WAVE CI10 =  $I10path
		make/o/d/n=(nRows, nCols) $I11path 
		WAVE CI11 =  $I11path
		
		make/o/d/n=(nRows, nCols) $I00SDpath
		WAVE CI00SD =  $I00SDpath
		make/o/d/n=(nRows, nCols) $I01SDpath 
		WAVE CI01SD =  $I01SDpath
		make/o/d/n=(nRows, nCols) $I10SDpath 
		WAVE CI10SD =  $I10SDpath
		make/o/d/n=(nRows, nCols) $I11SDpath 
		WAVE CI11SD =  $I11SDpath
		CI00 = RI00; CI01 = RI01; CI10 = RI10; CI11 = RI11;
		//Still need to scale the error witht the scalefactor, in order not to confuse afterwards.
		CI00SD = nI00SD/scalefactorI00; CI01SD = nI01SD/scalefactorI01; CI10SD = nI10SD/scalefactorI10; CI11SD = nI11SD/scalefactorI11;
		killwaves/z polefftemp, anaefftemp, flipper1temp, flipper2temp, final, matfliptwo, matflipone, matana, matpol
		
		catch
			Print "ERROR: an abort was encountered in (POLCORR_FULL)"
			setdatafolder $cDF
			return 1
		endtry
		
		return 0
End


Function polcorr_NSF(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, [verbose])
 	//ONLY R++ and R-- recorded, the calculation will assume that I01 = I10 = 0,  A = F2 = 1
 	//The I01 and I10 parts are just commented, so you can see what is actually different.
 	//The Function returns 0 if successfull, 1 if not
 	string I00, I01, I10, I11 //Name the files that should be polarization corrected. The filename has to be given in full.
 	//Files that have not been recorded can be input with any gibberish, but one should stick to "00"
 	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11  //each channel has an individual scaling factor
 	variable verbose
 	// Additional varables to check the wave dimensions
 	variable nRows, nCols
 	variable nRows00, nCols00, nRowslambda00, nColslambda00
 	variable nRows01, nCols01, nRowslambda01, nColslambda01
 	variable nRows10, nCols10, nRowslambda10, nColslambda10
 	variable nRows11, nCols11, nRowslambda11, nColslambda11
 	// Additional variables containing the efficiencies of the devices 
 	variable a,b,c,L

  	//Run indices
  	variable ii, jj
  	string cDF
  	cDF = getdatafolder(1) //returns the string containing the full path to the datafolder
	try	
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I00))
			print "ERROR, I00 folder or wave M_Spec not found (polcorr_NSF)";
		      abort
		endif
		//if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I01))
		//	print "ERROR, I01 folder or wave M_Spec not found (polcorr_NSF)"; 
		//	abort
		//endif
		//if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I10))
		//	print "ERROR, I10 folder or wave M_Spec not found (polcorr_NSF)"; 
		//	abort
		//endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I11))
			print "ERROR, I11 folder or wave M_Spec not found (polcorr_NSF)"; 
			abort
		endif
		Newdatafolder/o root:packages:platypus:data:Reducer:PolCorrected
		string datafolder
		datafolder = "root:packages:platypus:data:Reducer:PolCorrected"
		setdatafolder datafolder 
		
		Wave nI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_Spec")
		//Wave nI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_Spec")
		//Wave nI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_Spec")
		Wave nI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_Spec")
		Wave LI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_lambda")
		//Wave LI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_lambda")
		//Wave LI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_lambda")
		Wave LI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_lambda")
		Wave nI00SD = $("root:packages:platypus:data:Reducer:"+I00+":M_SpecSD") 
		//Wave nI01SD = $("root:packages:platypus:data:Reducer:"+I01+":M_SpecSD")
		//Wave nI10SD = $("root:packages:platypus:data:Reducer:"+I10+":M_SpecSd")
		Wave nI11SD = $("root:packages:platypus:data:Reducer:"+I11+":M_SpecSD")
	 
		//I should also a test if the length of M_lambda and M_Spec is the same...		
		nRows00 =DimSize(nI00,0); nCols00 = DimSize(nI00,1);
		nRowslambda00 = DimSize(LI00,0)
		//nRows01 = DimSize(nI01,0); nCols00 = DimSize(nI01,1);
		//nRowslambda01 = DimSize(LI01,0)
		//nRows10 = DimSize(nI10,0); nCols10 = DimSize(nI10,1);
		//nRowslambda10 = DimSize(LI10,0)
		nRows11 = DimSize(nI11,0); nCols11 = DimSize(nI11,1);
		nRowslambda11 = DimSize(LI11,0)
		if(nCols00>1 || nCols11>1)
			print "A streamed reduction of multidimensional data is not possible at this point (polcorr_NSF)"; abort
		endif
		//Check that M_Spec and M_Lambda have the same length
		if(!equalwaves(nI00, LI00, 512))
			print "ERROR: The dimension of M_lambda and M_Spec is different in spectrum "+I00 + "(polcorr_NSF)" 
			abort
		endif
		//Check that the datasets have the same length
		//print nRows00, nRows01, nRows10, nRows11
		if(!equalwaves(nI00, NI11, 512))
			print "ERROR: The dim of the M_Spec is different in the spectra (polcorr_NSF)"
			abort
		endif
		//Check that the wavelength is the same
		if(!equalwaves(LI00, LI11, 1))
			print "ERROR: The wavelengths in M_lambda are different to each other in the datafiles (polcorr_NSF)"
			abort
		endif
		//set a global row length 				
		nRows = nRows00; nCols = nCols00
		//Make the missing I01 and I10 Waves and set them to 0
		make/o/d/n=(nRows, nCols) nI01
		nI01 = 0
		make/o/d/n=(nRows, nCols) nI10
		nI10 = 0
		//Make the final Reflectivity Waves
		make/o/d/n=(nRows, nCols) RI00; make/o/d/n=(nRows, nCols) RI01; make/o/d/n=(nRows, nCols) RI10; make/o/d/n=(nRows, nCols) RI11 
		
		//maken the wave for the polarizer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		//The values in the comments are the original values until April2012. If the system changes, the new values have to be calculated and inserted here.
		make/o/d/n=(nRows, nCols) poleff
		poleff = polarizer_efficiency_constant_a-polarizer_efficiency_constant_b*polarizer_efficiency_constant_c^(LI00)
		 
		//maken the wave for the analyzer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		make/o/d/n=(nRows, nCols) anaeff
		anaeff =1 // a-b*c^(LI00) //The Analyzer has to be assumed to be 100% efficient, since SF is not distinguished. (Well, in principle it is, but we don't know how much there is, because it is not measured. Therefore, this measurement inherently makes a small mistake!!!)
		
		//maken the wave for the flipper1, flipper2 efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		make/o/d/n=(nRows, nCols) flipper1
	  	make/o/d/n=(nRows, nCols) flipper2
	  	
	  	flipper1 = flipper1_efficiency_constant_a
  		flipper2 = 1//the efficiency of flipper 1 has to be 100% in order to make a unity matrix F2 to transfer the intensity and efficiency. Otherwise only SF would exist. 		
 
  		/////////////////////////////
  		//print "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXTESTXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  		//print "FOR TESTING PURPOSES ONLY!!! Here you can manually change the efficiencies to see what happens!"
  		//poleff = 0.1; 
  		//anaeff = 0.1; 
  		//flipper1 = 1; 
  		//flipper2 = 1;
  		/////////////////////////////
		
		//make the temporary waves for calculation thorugh the matrices
		make/o/d/n=(nRows, nCols) polefftemp
		make/o/d/n=(nRows, nCols) anaefftemp
		make/o/d/n=(nRows, nCols) flipper1temp
	  	make/o/d/n=(nRows, nCols) flipper2temp
	  	//In order to process the efficiencies in the matrix, we need to convert them into a different form.
		polefftemp =(1-(-1*poleff))/2
  	    	anaefftemp= (1-(-1*anaeff))/2
  	    	flipper1temp = (1-flipper1)
  	    	flipper2temp = (1-flipper2)
  	    	
  	    	make/o/d/n=(4,4,nRows) matpol, matana, matflipone, matfliptwo, final
  	    	  	    	
  	    	matpol[0][0][] =1- polefftemp[r];		matpol[0][1][] =0;				 	 matpol[0][2][] =polefftemp[r]; 			matpol[0][3][] =0;
  	    	matpol[1][0][] =0;                    		matpol[1][1][] =1- polefftemp[r];	  	 matpol[1][2][] =0; 					matpol[1][3][] =polefftemp[r];
  	    	matpol[2][0][] =polefftemp[r];    		matpol[2][1][] =0; 	 		 	 matpol[2][2][] =1- polefftemp[r]; 		matpol[2][3][] =0;
  	    	matpol[3][0][] =0;                    		matpol[3][1][] =polefftemp[r];	 	 matpol[3][2][] =0;		 			matpol[3][3][] =1- polefftemp[r];
		
		matana[0][0][] =1- anaefftemp[r];	matana[0][1][] =anaefftemp[r];		 matana[0][2][] =0;		 			matana[0][3][] =0;
  	    	matana[1][0][] =anaefftemp[r];        	matana[1][1][] =1- anaefftemp[r];	 matana[1][2][] =0; 					matana[1][3][] =0;
  	    	matana[2][0][] =0;			   	matana[2][1][] =0; 	 		 	 matana[2][2][] =1- anaefftemp[r]; 		matana[2][3][] =anaefftemp[r];
  	    	matana[3][0][] =0;                    	matana[3][1][] =0;			 	 matana[3][2][] =anaefftemp[r]; 			matana[3][3][] =1- anaefftemp[r];
  	    	
  	    	matflipone[0][0][] =1;				matflipone[0][1][] =0;				 matflipone[0][2][] =0; 					matflipone[0][3][] =0;
  	    	matflipone[1][0][] =0;                    	matflipone[1][1][] =1;	 			 matflipone[1][2][] =0; 					matflipone[1][3][] =0;
  	    	matflipone[2][0][] =flipper1temp[r];   	matflipone[2][1][] =0; 	 			 matflipone[2][2][] =1- flipper1temp[r]; 	matflipone[2][3][] =0;
  	    	matflipone[3][0][] =0;                    	matflipone[3][1][] =flipper1temp[r];	 matflipone[3][2][] =0;		 			matflipone[3][3][] =1- flipper1temp[r];

		matfliptwo[0][0][] =1;				matfliptwo[0][1][] =0;				 matfliptwo[0][2][] =0; 					matfliptwo[0][3][] =0;
  	    	matfliptwo[1][0][] =flipper2temp[r];	matfliptwo[1][1][] =1-flipper2temp[r];	 matfliptwo[1][2][] =0; 					matfliptwo[1][3][] =0;
  	    	matfliptwo[2][0][] =0;   			matfliptwo[2][1][] =0; 	 			 matfliptwo[2][2][] =1; 					matfliptwo[2][3][] =0;
  	    	matfliptwo[3][0][] =0;                    	matfliptwo[3][1][] =0;	 			 matfliptwo[3][2][] =flipper2temp[r];		matfliptwo[3][3][] =1- flipper2temp[r];

		//The Full Matrix equation looks like Int(1x4) = (F1[4x4]) (F2[4x4]) (P[4x4]) (A[4x4]) R(1x4)
		//Therefore, in order to calculate R, we need to multiply the intensity (Int) with the inverse of the efficiency matrices	
		//Calculate the combined efficiency matrix.				
		MatrixOp finals =  matflipone x matfliptwo x matpol x matana
		MatrixOp finaltemp = Inv(finals)
		for(ii=0; ii<nRows; ii+=1)
			final[][][ii] = finaltemp
		endfor	
		killwaves/z finals, finaltemp
		//make a vector for the intensities and the reflectivities
		make/o/d/n=(4,1,nRows) vecintensities
		vecintensities[0][0][] = nI00[r]/scalefactorI00; vecintensities[1][0][] = nI01[r]/scalefactorI01; vecintensities[2][0][] = nI10[r]/scalefactorI10; vecintensities[3][0][] = nI11[r]/scalefactorI11
		MatrixOp vecreftemp = final x vecintensities
		for(ii=0; ii<nRows; ii+=1) 	 
		 	RI11[ii] = vecreftemp[0][0][ii]
		 	RI10[ii] = vecreftemp[1][0][ii]
		 	RI01[ii] = vecreftemp[2][0][ii]
		 	RI00[ii] = vecreftemp[3][0][ii]
		endfor	
		killwaves/z vecreftemp
		if(verbose)
		print "(PolCorr_NSF) polarization correction executed successfully"
		endif
		//Put the corrected spectra back in the original datafolder to have it easier with Andys reduction
		string I00path = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorr"
		//string I01path = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorr"
		//string I10path = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorr"
		string I11path = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorr"
		
		make/o/d/n=(nRows, nCols) $I00path 
		WAVE CI00 =  $I00path
		//make/o/d/n=(nRows, nCols) $I01path 
		//WAVE CI01 =  $I01path
		//make/o/d/n=(nRows, nCols) $I10path 
		//WAVE CI10 =  $I10path
		make/o/d/n=(nRows, nCols) $I11path 
		WAVE CI11 =  $I11path
		//Make the error waves after polcorr
		string I00SDpath = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorrSD"
		//string I01SDpath = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorrSD"
		//string I10SDpath = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorrSD"
		string I11SDpath = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorrSD"
		make/o/d/n=(nRows, nCols) $I00SDpath
		WAVE CI00SD =  $I00SDpath
		//make/o/d/n=(nRows, nCols) $I01SDpath 
		//WAVE CI01SD =  $I01SDpath
		//make/o/d/n=(nRows, nCols) $I10SDpath 
		//WAVE CI10SD =  $I10SDpath
		make/o/d/n=(nRows, nCols) $I11SDpath 
		WAVE CI11SD =  $I11SDpath
		CI00 = RI00; CI11 = RI11; 
		//Still need to scale the error witht the scalefactor, in order not to confuse afterwards.
		CI00SD = nI00SD / scalefactorI00; CI11SD = nI11SD / scalefactorI11;
		killwaves/z polefftemp, anaefftemp, flipper1temp, flipper2temp, final, matfliptwo, matflipone, matana, matpol, nI01, nI10
		catch
			Print "ERROR: an abort was encountered in (POLCORR_NSF)"
			setdatafolder $cDF
			return 1
		endtry
		return 0
End


Function polcorr_R01(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, [verbose])
 	//Only ONE spin-flip channel recorded, assuming I01 = I10  and vice versa
 	//The Function returns 0 if successfull, 1 if not
 	string I00, I01, I10, I11 //Name the files that should be polarization corrected. The filename has to be given in full.
 	//Files that have not been recorded can be input with any gibberish, but one should stick to "00"
 	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11  //each channel has an individual scaling factor
 	variable verbose
 	// Additional varables to check the wave dimensions
 	variable nRows, nCols
 	variable nRows00, nCols00, nRowslambda00, nColslambda00
 	variable nRows01, nCols01, nRowslambda01, nColslambda01
 	variable nRows10, nCols10, nRowslambda10, nColslambda10
 	variable nRows11, nCols11, nRowslambda11, nColslambda11
 	// Additional variables containing the efficiencies of the devices
 	variable a,b,c,L, x, y
  	//Run indices
  	variable ii, jj
  	string cDF
  	cDF = getdatafolder(1) //returns the string containing the full path to the datafolder
	try	
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I00))
			print "ERROR, I00 folder or wave M_Spec not found (polcorr_R01)";
			abort
		endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I11))
			print "ERROR, I11 folder or wave M_Spec not found (polcorr_R01)"; 
			abort
		endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I01))
			if(verbose)
			print "I01 folder or wave M_Spec not found (polcorr_R01)"; 
			print "Checking for the I10 instensity...  (polcorr_R01)"; 
			endif
			if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I10))
			 	print "ERROR, I10 folder or wave M_Spec not found (polcorr_R01)";
			 	print "ERROR, I01 folder or wave M_Spec not found (polcorr_R01)"; 
				abort
			endif	
		endif
		Newdatafolder/o root:packages:platypus:data:Reducer:PolCorrected
		string datafolder
		datafolder = "root:packages:platypus:data:Reducer:PolCorrected"
		setdatafolder datafolder 
		Wave nI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_Spec")
		Wave nI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_Spec")
		Wave LI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_lambda")
		Wave LI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_lambda")
		Wave/z nI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_Spec")
		Wave/z LI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_lambda")
		Wave/z nI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_Spec")
		Wave/z LI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_lambda")
		Wave nI00SD = $("root:packages:platypus:data:Reducer:"+I00+":M_SpecSD") 
		Wave/z nI01SD = $("root:packages:platypus:data:Reducer:"+I01+":M_SpecSD")
		Wave/z nI10SD = $("root:packages:platypus:data:Reducer:"+I10+":M_SpecSd")
		Wave nI11SD = $("root:packages:platypus:data:Reducer:"+I11+":M_SpecSD")
	
		nRows00 =DimSize(nI00,0); nCols00 = DimSize(nI00,1);
		nRowslambda00 = DimSize(LI00,0)
		nRows11 = DimSize(nI11,0); nCols11 = DimSize(nI11,1);
		nRowslambda11 = DimSize(LI11,0)		
		//set a global row length 				
		nRows = nRows00; nCols = nCols00
		if( !WaveExists(nI10) )
			//Make the missing I01 and I10 Waves and set them equal to the existing I01 or I10 wave
			make/o/d/n=(nRows, nCols) NnI10
			NnI10 = nI01
			Wave nI10 = NnI10
			make/o/d/n=(nRows, nCols) NnI10SD
			NnI10SD = nI01SD
			Wave nI10SD = NnI10SD
			x = 1 //x=1 means nI10 does not exist 
			y = 2 //y=2 means nI10 does not exist
			if(verbose)
			print "nI10 does not exist"
			endif
		endif
		if( !WaveExists(nI01) )
			//Make the missing I01 and I10 Waves and set them equal to the existing I01 or I10 wave
			make/o/d/n=(nRows, nCols) NnI01
			NnI01 = nI10
			Wave nI01 = NnI01
			make/o/d/n=(nRows, nCols) NnI01SD
			NnI01SD = nI10SD
			Wave nI01SD = NnI01SD
			x = 2 //x=2 means nI01 does not exist
			y = 1 //y=1 means nI01 does not exist
			if(verbose)
			print "nI01 does not exist"
			endif
		endif
		nRows01 = DimSize(nI01,0); nCols00 = DimSize(nI01,1);
		nRowslambda01 = DimSize(LI01,0)
		nRows10 = DimSize(nI10,0); nCols10 = DimSize(nI10,1);
		nRowslambda10 = DimSize(LI10,0)
		if(nCols00>1 || nCols11>1 || nCols01>1 || nCols10>1)
			print "A streamed reduction of multidimensional data is not possible at this point (PolCorr_R01)"; abort
		endif
		//Check that M_Spec and M_Lambda have the same length
		if(!equalwaves(nI00, LI00, 512))
			print "ERROR: The dim of M_lambda and M_Spec is different in spectrum"+I00+ " (PolCorr_R01)"
			abort
		endif
		//Check that the datasets have the same length
		if(!equalwaves(nI00, nI01, 512) || !equalwaves(nI00, nI10, 512) || !equalwaves(nI00, nI11, 512))
			print "ERROR: The dim of the M_Spec is different in the spectra (PolCorr_R01)"
			abort
		endif
		//Check that the wavelength is the same
		if(!equalwaves(LI00, LI11, 1))
			print "ERROR: The wavelengths in M_lambda are different to each other in the datafiles (PolCorr_R01)"
			abort
		endif
		//Make the final Reflectivity Waves
		make/o/d/n=(nRows, nCols) RI00; make/o/d/n=(nRows, nCols) RI01; make/o/d/n=(nRows, nCols) RI10; make/o/d/n=(nRows, nCols) RI11 

		//maken the wave for the polarizer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		//The values in the comments are the original values until April2012. If the system changes, the new values have to be calculated and inserted here.
		make/o/d/n=(nRows, nCols) poleff
		poleff = polarizer_efficiency_constant_a-polarizer_efficiency_constant_b*polarizer_efficiency_constant_c^(LI00)
		 
		//maken the wave for the analyzer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		make/o/d/n=(nRows, nCols) anaeff 
		anaeff = analyzer_efficiency_constant_a-analyzer_efficiency_constant_b*analyzer_efficiency_constant_c^(LI00)
		
		//maken the wave for the flipper1, flipper2 efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		make/o/d/n=(nRows, nCols) flipper1
	  	make/o/d/n=(nRows, nCols) flipper2
		flipper1 = flipper1_efficiency_constant_a
		flipper2 = flipper2_efficiency_constant_a
  		 
  		/////////////////////////////
  		//FOR TESTING PURPOSES ONLY!!! Here you can manually change the efficiencies to see what happens!
  		//poleff = 1; 
  		//anaeff = 1; 
  		//flipper1 = 1; 
  		//flipper2 = 1;
  		/////////////////////////////
		
		//make the temporary waves for calculation thorugh the matrices
		make/o/d/n=(nRows, nCols) polefftemp
		make/o/d/n=(nRows, nCols) anaefftemp
		make/o/d/n=(nRows, nCols) flipper1temp
	  	make/o/d/n=(nRows, nCols) flipper2temp
	  	//In order to process the efficiencies in the matrix, we need to convert them into a different form.
		polefftemp =(1-(-1*poleff))/2
  	    	anaefftemp= (1-(-1*anaeff))/2
  	    	flipper1temp = (1-flipper1)
  	    	flipper2temp = (1-flipper2)
  	    	
  	    	make/o/d/n=(4,4,nRows) matpol, matana, matflipone, matfliptwo, final
  	    	  	    	
  	    	matpol[0][0][] =1- polefftemp[r];		matpol[0][1][] =0;				 	 matpol[0][2][] =polefftemp[r]; 			matpol[0][3][] =0;
  	    	matpol[1][0][] =0;                    		matpol[1][1][] =1- polefftemp[r];	  	 matpol[1][2][] =0; 					matpol[1][3][] =polefftemp[r];
  	    	matpol[2][0][] =polefftemp[r];    		matpol[2][1][] =0; 	 		 	 matpol[2][2][] =1- polefftemp[r]; 		matpol[2][3][] =0;
  	    	matpol[3][0][] =0;                    		matpol[3][1][] =polefftemp[r];	 	 matpol[3][2][] =0;		 			matpol[3][3][] =1- polefftemp[r];
		
		matana[0][0][] =1- anaefftemp[r];	matana[0][1][] =anaefftemp[r];		 matana[0][2][] =0;		 			matana[0][3][] =0;
  	    	matana[1][0][] =anaefftemp[r];        	matana[1][1][] =1- anaefftemp[r];	 matana[1][2][] =0; 					matana[1][3][] =0;
  	    	matana[2][0][] =0;			   	matana[2][1][] =0; 	 		 	 matana[2][2][] =1- anaefftemp[r]; 		matana[2][3][] =anaefftemp[r];
  	    	matana[3][0][] =0;                    	matana[3][1][] =0;			 	 matana[3][2][] =anaefftemp[r]; 			matana[3][3][] =1- anaefftemp[r];
  	    	
  	    	matflipone[0][0][] =1;				matflipone[0][1][] =0;				 matflipone[0][2][] =0; 					matflipone[0][3][] =0;
  	    	matflipone[1][0][] =0;                    	matflipone[1][1][] =1;	 			 matflipone[1][2][] =0; 					matflipone[1][3][] =0;
  	    	matflipone[2][0][] =flipper1temp[r];   	matflipone[2][1][] =0; 	 			 matflipone[2][2][] =1- flipper1temp[r]; 	matflipone[2][3][] =0;
  	    	matflipone[3][0][] =0;                    	matflipone[3][1][] =flipper1temp[r];	 matflipone[3][2][] =0;		 			matflipone[3][3][] =1- flipper1temp[r];

		matfliptwo[0][0][] =1;				matfliptwo[0][1][] =0;				 matfliptwo[0][2][] =0; 					matfliptwo[0][3][] =0;
  	    	matfliptwo[1][0][] =flipper2temp[r];	matfliptwo[1][1][] =1-flipper2temp[r];	 matfliptwo[1][2][] =0; 					matfliptwo[1][3][] =0;
  	    	matfliptwo[2][0][] =0;   			matfliptwo[2][1][] =0; 	 			 matfliptwo[2][2][] =1; 					matfliptwo[2][3][] =0;
  	    	matfliptwo[3][0][] =0;                    	matfliptwo[3][1][] =0;	 			 matfliptwo[3][2][] =flipper2temp[r];		matfliptwo[3][3][] =1- flipper2temp[r];

		//The Full Matrix equation looks like Int(1x4) = (F1[4x4]) (F2[4x4]) (P[4x4]) (A[4x4]) R(1x4)
		//Therefore, in order to calculate R, we need to multiply the intensity (Int) with the inverse of the efficiency matrices	
		//Calculate the combined efficiency matrix.				
		MatrixOp finals =  matflipone x matfliptwo x matpol x matana
		MatrixOp finaltemp = Inv(finals)
		for(ii=0; ii<nRows; ii+=1)
			final[][][ii] = finaltemp
		endfor	
		killwaves/z finals, finaltemp
		//make a vector for the intensities and the reflectivities
		make/o/d/n=(4,1,nRows) vecintensities
		vecintensities[0][0][] = nI00[r]/scalefactorI00; vecintensities[1][0][] = nI01[r]/scalefactorI01; vecintensities[2][0][] = nI10[r]/scalefactorI10; vecintensities[3][0][] = nI11[r]/scalefactorI11
		MatrixOp vecreftemp = final x vecintensities
		for(ii=0; ii<nRows; ii+=1) 	 
		 	RI11[ii] = vecreftemp[0][0][ii]
		 	RI10[ii] = vecreftemp[1][0][ii]
		 	RI01[ii] = vecreftemp[2][0][ii]
		 	RI00[ii] = vecreftemp[3][0][ii]
		endfor	
		killwaves/z vecreftemp
		if(verbose)
		print "(PolCorr_R01) polarization correction executed successfully"
		endif
		//Put the corrected spectra back in the original datafolder to have it easier with Andys reduction
		string I00path = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorr"
		string I01path = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorr"
		string I10path = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorr"
		string I11path = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorr"
		//Make the error waves after polcorr
		string I00SDpath = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorrSD"
		string I01SDpath = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorrSD"
		string I10SDpath = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorrSD"
		string I11SDpath = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorrSD"
		
		make/o/d/n=(nRows, nCols) $I00path 
		WAVE CI00 =  $I00path
		make/o/d/n=(nRows, nCols) $I00SDpath
		WAVE CI00SD =  $I00SDpath
		
		make/o/d/n=(nRows, nCols) $I11path 
		WAVE CI11 =  $I11path
		make/o/d/n=(nRows, nCols) $I11SDpath 
		WAVE CI11SD =  $I11SDpath
		CI00 = RI00;   CI11 = RI11; 
		//Still need to scale the error witht the scalefactor, in order not to confuse afterwards.
		CI00SD = nI00SD / scalefactorI00;
		CI11SD = nI11SD / scalefactorI11;
		if(x==1)
			make/o/d/n=(nRows, nCols) $I01path 
			WAVE CI01 =  $I01path
			CI01 = RI01
			make/o/d/n=(nRows, nCols) $I01SDpath 
			WAVE CI01SD =  $I01SDpath
			CI01SD = nI01SD/scalefactorI01
		else 
			make/o/d/n=(nRows, nCols) $I10path 
			WAVE CI10 =  $I10path
			CI10 = RI10
			make/o/d/n=(nRows, nCols) $I10SDpath 
			WAVE CI10SD =  $I10SDpath
			CI10SD = nI10SD/scalefactorI10
		endif
		killwaves/z polefftemp, anaefftemp, flipper1temp, flipper2temp, final, matfliptwo, matflipone, matana, matpol, vecintensities, NnI10, NnI01
		catch
			Print "ERROR: an abort was encountered in (POLCORR_R01)"
			setdatafolder $cDF
			return 1
		endtry
		return 0
End

Function polcorr_R0R1(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, [verbose])
	//Only POLARIZER and FLIPPER1 used, assuming ANA = 1, F2=0, I01=I10=0 
 	//The Function returns 0 if successfull, 1 if not
 	string I00, I01, I10, I11 //Name the files that should be polarization corrected. The filename has to be given in full.
 	//Files that have not been recorded can be input with any gibberish, but one should stick to "0"
 	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11  //each channel has an individual scaling factor
 	variable verbose
 	// Additional varables to check the wave dimensions
 	variable nRows, nCols
 	variable nRows00, nCols00, nRowslambda00, nColslambda00
 	variable nRows01, nCols01, nRowslambda01, nColslambda01
 	variable nRows10, nCols10, nRowslambda10, nColslambda10
 	variable nRows11, nCols11, nRowslambda11, nColslambda11
 	// Additional variables containing the efficiencies of the devices
 	variable a,b,c,L
  	//Run indices
  	variable ii, jj
  	string cDF
  	cDF = getdatafolder(1) //returns the string containing the full path to the datafolder
	try	
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I00))
			print "ERROR, I00 folder or wave M_Spec not found (polcorr_R0R1)";
			abort
		endif
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I11))
			print "ERROR, I11 folder or wave M_Spec not found (polcorr_R0R1)"; 
			abort
		endif
		Newdatafolder/o root:packages:platypus:data:Reducer:PolCorrected
		string datafolder
		datafolder = "root:packages:platypus:data:Reducer:PolCorrected"
		setdatafolder datafolder 
		
		Wave nI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_Spec")
		Wave nI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_Spec")
		Wave LI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_lambda")
		Wave LI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_lambda")
		
		Wave nI00SD = $("root:packages:platypus:data:Reducer:"+I00+":M_SpecSD") 
		Wave nI11SD = $("root:packages:platypus:data:Reducer:"+I11+":M_SpecSD")
		
		//figure out how many rows are in each M_Spec and compare the length. It might be that the wavelength is different for each file, which is bad...
		//but i cannot see how they should be different, but you need to make a test and abort if bad.
	 
		//I should also a test if the length of M_lambda and M_Spec is the same...		
		nRows00 =DimSize(nI00,0); nCols00 = DimSize(nI00,1);
		nRowslambda00 = DimSize(LI00,0)
		nRows11 = DimSize(nI11,0); nCols11 = DimSize(nI11,1);
		nRowslambda11 = DimSize(LI11,0)
		//Check that M_Spec and M_Lambda have the same length
		if(nCols00>1 || nCols11>1)
			print "A streamed reduction of multidimensional data is not possible at this point (polcorr_R0R1)"; abort
		endif
		if(!equalwaves(nI00, LI00, 512))
			print "ERROR: The row length of M_lambda and M_Spec is different in spectrum"+I00+"(polcorr_R0R1)"
			abort
		endif
		//Check that the datasets have the same length
		if(!equalwaves(nI00, nI11, 512))
			print "ERROR: The row length of the M_Spec is different in the spectra (polcorr_R0R1)"
			abort
		endif
		//Check that the wavelength is the same
		if(!equalwaves(LI00, LI11, 1))
			print "ERROR: The wavelengths in M_lambda are different to each other in the datafiles (polcorr_R0R1)"
			abort
		endif
		//set a global row length 				
		nRows = nRows00; nCols = nCols00
		//Make the missing I01 and I10 Waves and set them to 0
		make/o/d/n=(nRows, nCols) nI01
		nI01 = 0
		make/o/d/n=(nRows, nCols) nI10
		nI10 = 0
		//Make the final Reflectivity Waves
		make/o/d/n=(nRows, nCols) RI00; make/o/d/n=(nRows, nCols) RI01; make/o/d/n=(nRows, nCols) RI10; make/o/d/n=(nRows, nCols) RI11 
		
		//maken the wave for the polarizer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		//The values in the comments are the original values until April2012. If the system changes, the new values have to be calculated and inserted here.
		make/o/d/n=(nRows, nCols) poleff
		poleff = polarizer_efficiency_constant_a-polarizer_efficiency_constant_b*polarizer_efficiency_constant_c^(LI00)
		 
		//maken the wave for the analyzer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		make/o/d/n=(nRows, nCols) anaeff
		anaeff =1 // a-b*c^(LI00)  //The Analyzer has to be assumed to be 100% efficient, since SF is not distinguished. 
		
		//maken the wave for the flipper1, flipper2 efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		make/o/d/n=(nRows, nCols) flipper1
	  	make/o/d/n=(nRows, nCols) flipper2
  		flipper1 = flipper1_efficiency_constant_a
  		flipper2 = 1 //the efficiency of flipper 1 has to be 100% in order to make a unity matrix F2 to transfer the intensity and efficiency. 
  		 
  		/////////////////////////////
  		//FOR TESTING PURPOSES ONLY!!! Here you can manually change the efficiencies to see what happens!
  		//poleff = 1; 
  		//anaeff = 1; 
  		//flipper1 = 1; 
  		//flipper2 = 1;
  		/////////////////////////////
		
		//make the temporary waves for calculation thorugh the matrices
		make/o/d/n=(nRows, nCols) polefftemp
		make/o/d/n=(nRows, nCols) anaefftemp
		make/o/d/n=(nRows, nCols) flipper1temp
	  	make/o/d/n=(nRows, nCols) flipper2temp
	  	//In order to process the efficiencies in the matrix, we need to convert them into a different form.
		polefftemp =(1-(-1*poleff))/2
  	    	anaefftemp= (1-(-1*anaeff))/2
  	    	flipper1temp = (1-flipper1)
  	    	flipper2temp = (1-flipper2)
  	    	
  	    	make/o/d/n=(4,4,nRows) matpol, matana, matflipone, matfliptwo, final
  	    	  	    	
  	    	matpol[0][0][] =1- polefftemp[r];		matpol[0][1][] =0;				 	 matpol[0][2][] =polefftemp[r]; 			matpol[0][3][] =0;
  	    	matpol[1][0][] =0;                    		matpol[1][1][] =1- polefftemp[r];	  	 matpol[1][2][] =0; 					matpol[1][3][] =polefftemp[r];
  	    	matpol[2][0][] =polefftemp[r];    		matpol[2][1][] =0; 	 		 	 matpol[2][2][] =1- polefftemp[r]; 		matpol[2][3][] =0;
  	    	matpol[3][0][] =0;                    		matpol[3][1][] =polefftemp[r];	 	 matpol[3][2][] =0;		 			matpol[3][3][] =1- polefftemp[r];
		
		matana[0][0][] =1- anaefftemp[r];	matana[0][1][] =anaefftemp[r];		 matana[0][2][] =0;		 			matana[0][3][] =0;
  	    	matana[1][0][] =anaefftemp[r];        	matana[1][1][] =1- anaefftemp[r];	 matana[1][2][] =0; 					matana[1][3][] =0;
  	    	matana[2][0][] =0;			   	matana[2][1][] =0; 	 		 	 matana[2][2][] =1- anaefftemp[r]; 		matana[2][3][] =anaefftemp[r];
  	    	matana[3][0][] =0;                    	matana[3][1][] =0;			 	 matana[3][2][] =anaefftemp[r]; 			matana[3][3][] =1- anaefftemp[r];
  	    	
  	    	matflipone[0][0][] =1;				matflipone[0][1][] =0;				 matflipone[0][2][] =0; 					matflipone[0][3][] =0;
  	    	matflipone[1][0][] =0;                    	matflipone[1][1][] =1;	 			 matflipone[1][2][] =0; 					matflipone[1][3][] =0;
  	    	matflipone[2][0][] =flipper1temp[r];   	matflipone[2][1][] =0; 	 			 matflipone[2][2][] =1- flipper1temp[r]; 	matflipone[2][3][] =0;
  	    	matflipone[3][0][] =0;                    	matflipone[3][1][] =flipper1temp[r];	 matflipone[3][2][] =0;		 			matflipone[3][3][] =1- flipper1temp[r];

		matfliptwo[0][0][] =1;				matfliptwo[0][1][] =0;				 matfliptwo[0][2][] =0; 					matfliptwo[0][3][] =0;
  	    	matfliptwo[1][0][] =flipper2temp[r];	matfliptwo[1][1][] =1-flipper2temp[r];	 matfliptwo[1][2][] =0; 					matfliptwo[1][3][] =0;
  	    	matfliptwo[2][0][] =0;   			matfliptwo[2][1][] =0; 	 			 matfliptwo[2][2][] =1; 					matfliptwo[2][3][] =0;
  	    	matfliptwo[3][0][] =0;                    	matfliptwo[3][1][] =0;	 			 matfliptwo[3][2][] =flipper2temp[r];		matfliptwo[3][3][] =1- flipper2temp[r];

		//The Full Matrix equation looks like Int(1x4) = (F1[4x4]) (F2[4x4]) (P[4x4]) (A[4x4]) R(1x4)
		//Therefore, in order to calculate R, we need to multiply the intensity (Int) with the inverse of the efficiency matrices	
		//Calculate the combined efficiency matrix.				
		MatrixOp finals =  matflipone x matfliptwo x matpol x matana
		
		MatrixOp finaltemp = Inv(finals)
		for(ii=0; ii<nRows; ii+=1)
			final[][][ii] = finaltemp
		endfor	
		killwaves/z finals, finaltemp
		//make a vector for the intensities and the reflectivities
		make/o/d/n=(4,1,nRows) vecintensities
			vecintensities[0][0][] = nI00[r]/scalefactorI00; vecintensities[1][0][] = nI01[r]/scalefactorI01; vecintensities[2][0][] = nI10[r]/scalefactorI10; vecintensities[3][0][] = nI11[r]/scalefactorI11
		MatrixOp vecreftemp = final x vecintensities
		for(ii=0; ii<nRows; ii+=1) 	 
		 	RI11[ii] = vecreftemp[0][0][ii]
		 	RI10[ii] = vecreftemp[1][0][ii]
		 	RI01[ii] = vecreftemp[2][0][ii]
		 	RI00[ii] = vecreftemp[3][0][ii]
		endfor	
		killwaves/z vecreftemp
		if(verbose)
		print "(PolCorr_R0R1) polarization correction executed successfully"
		endif
		//Put the corrected spectra back in the original datafolder to have it easier with Andys reduction
		string I00path = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorr"
		string I11path = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorr"
		
		make/o/d/n=(nRows, nCols) $I00path 
		WAVE CI00 =  $I00path
		make/o/d/n=(nRows, nCols) $I11path 
		WAVE CI11 =  $I11path
		
		//Make the error waves after polcorr
		string I00SDpath = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorrSD"
		string I11SDpath = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorrSD"
		make/o/d/n=(nRows, nCols) $I00SDpath
		WAVE CI00SD =  $I00SDpath
		make/o/d/n=(nRows, nCols) $I11SDpath 
		WAVE CI11SD =  $I11SDpath
		//Still need to scale the error witht the scalefactor, in order not to confuse afterwards.
		CI00 = RI00; CI11 = RI11; 
		CI00SD = nI00SD / scalefactorI00; 
		CI11SD = nI11SD / scalefactorI11;
		killwaves/z polefftemp, anaefftemp, flipper1temp, flipper2temp, final, matfliptwo, matflipone, matana, matpol, vecintensities, nI01, nI10
		catch
			Print "ERROR: an abort was encountered in (POLCORR_R0R1)"
			setdatafolder $cDF
			return 1
		endtry
		return 0
End

Function polcorr_DB(I00, I01, I10, I11, scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11, [verbose])
	//This case is only for the direct beam, for the case that only ONE channel has been measured. the correction is essentially just a scaling of the intensity towards the efficiency of the device.
 	//The Function returns 0 if successfull, 1 if not
 	string I00, I01, I10, I11 //Name the files that should be polarization corrected. The filename has to be given in full.
 	//Files that have not been recorded can be input with any gibberish, but one should stick to "00"
 	variable scalefactorI00, scalefactorI01, scalefactorI10, scalefactorI11  //each channel has an individual scaling factor
 	variable verbose
 	// Additional varables to check the wave dimensions
 	variable nRows, nCols
 	variable nRows00, nCols00, nRowslambda00, nColslambda00
 	variable nRows01, nCols01, nRowslambda01, nColslambda01
 	variable nRows10, nCols10, nRowslambda10, nColslambda10
 	variable nRows11, nCols11, nRowslambda11, nColslambda11
 	// Additional variables containing the efficiencies of the devices
 	variable a,b,c,L, w, x, y, z
  	//Run indices
  	variable ii, jj
  	string cDF
  	cDF = getdatafolder(1) //returns the string containing the full path to the datafolder
	try	
		if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I00))
			if(verbose)
			print "ERROR, I00 folder or wave M_Spec not found (PolCorr_DB)";
			print "Checking if I11 exists (PolCorr_DB)";
			endif
			if(!DataFolderExists("root:packages:platypus:data:Reducer:"+I11))
			print "ERROR, I00 AND I11 folder or wave M_Spec not found (PolCorr_DB)"; 
			print "ERROR, You need either I00 or I11 to do this correction (PolCorr_DB)"
			print "If you do not a division of the spectra to be performed, the input should either be 00 or blank (PolCorr_DB)";
			print "If you do not want to correct the DB, give the same entry on I11 and I00 (PolCorr_DB)"
			abort
			endif
		endif	
		Newdatafolder/o root:packages:platypus:data:Reducer:PolCorrected
		string datafolder
		datafolder = "root:packages:platypus:data:Reducer:PolCorrected"
		setdatafolder datafolder 
		
		Wave/z nI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_Spec")
		Wave/z nI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_Spec")
		Wave/z LI00 = $("root:packages:platypus:data:Reducer:"+I00+":M_lambda")
		Wave/z LI11 = $("root:packages:platypus:data:Reducer:"+I11+":M_lambda")
		Wave/z nI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_Spec")
		Wave/z LI10 = $("root:packages:platypus:data:Reducer:"+I10+":M_lambda")
		Wave/z nI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_Spec")
		Wave/z LI01 = $("root:packages:platypus:data:Reducer:"+I01+":M_lambda")
		Wave/z nI00SD = $("root:packages:platypus:data:Reducer:"+I00+":M_SpecSD") 
		Wave/z nI01SD = $("root:packages:platypus:data:Reducer:"+I01+":M_SpecSD")
		Wave/z nI10SD = $("root:packages:platypus:data:Reducer:"+I10+":M_SpecSd")
		Wave/z nI11SD = $("root:packages:platypus:data:Reducer:"+I11+":M_SpecSD")
		
		//figure out how many rows are in each M_Spec and compare the length. It might be that the wavelength is different for each file, which is bad...
		//but i cannot see how they should be different, but you need to make a test and abort if bad.
		//I should also a test if the length of M_lambda and M_Spec is the same...		
		if( WaveExists(nI00) )
			nRows00 =DimSize(nI00,0); nCols00 = DimSize(nI00,1);
			nRowslambda00 = DimSize(LI00,0)
			nRows11 = 0; nCols11 = 0;
			nRowslambda11 = 0
		elseif(WaveExists(nI11))
			nRows00 =0; nCols00 = 0;
			nRowslambda00 = 0
			nRows11 = DimSize(nI11,0); nCols11 = DimSize(nI11,1);
			nRowslambda11 = DimSize(LI11,0)
		else
			print "Could find neither I00 nor I11 (PolCorr_DB)"; abort
		endif
		//Check that M_Spec and M_Lambda have the same length
		if( WaveExists(nI00) )
			if(!equalwaves(nI00, LI00, 512))
				print "ERROR: The dimension of M_lambda and M_Spec is different in spectrum"+I00+"(PolCorr_DB)"
				abort
			endif
		endif	
		if( WaveExists(nI11) )
			if(!equalwaves(nI11, LI11,512))
				print "ERROR: The dimension of M_lambda and M_Spec is different in spectrum"+I11+"(PolCorr_DB)"
				abort	
			endif
		endif	
		//set a global row length 				
		nRows = nRows00; nCols = nCols00
		if( !WaveExists(nI00) )
			//Make the missing Waves and set them to 0
			make/o/d/n=(nRows, nCols) NnI00
			make/o/d/n=(nRows, nCols) NnI00SD
			make/o/d/n=(nRows, nCols) LLI00
			NnI00 = 0
			NnI00SD = 0
			LLI00 = LI11
			Wave nI00 = NnI00
			Wave nI00SD = NnI00SD
			Wave LI00 = LLI11
			w = 1 //x=1 means nI00 does not exist 
			if(verbose)
			print "nI00 does not exist (PolCorr_DB)"
			endif
		else 
			w=2
		endif
		if( !WaveExists(nI11) )
			//Make the missing Waves and set them to 0
			make/o/d/n=(nRows, nCols) NnI11
			make/o/d/n=(nRows, nCols) NnI11SD
			make/o/d/n=(nRows, nCols) LLI11
			NnI11 = 0
			NnI11SD = 0
			LLI11 = LI00
			Wave nI11 = NnI11
			Wave nI11SD = NnI11SD
			Wave LI11 = LLI11
			x = 1 //x=2 means nI11 does not exist 
			if(verbose)
			print "nI11 does not exist (PolCorr_DB)"
			endif
		else 
			x=2
		endif
		if( !WaveExists(nI01) )
			//Make the missing Waves and set them to 0
			make/o/d/n=(nRows, nCols) NnI01
			make/o/d/n=(nRows, nCols) NnI01SD
			NnI01 = 0
			NnI01SD = 0
			Wave nI01 = NnI01
			Wave nI01SD = NnI01SD
			y = 1 //x=3 means nI01 does not exist 
			if(verbose)
			print "nI01 does not exist (PolCorr_DB)"
			endif
		else 
			y=2	
		endif
		if( !WaveExists(nI10) )
			//Make the missing Waves and set them to 0
			make/o/d/n=(nRows, nCols) NnI10
			make/o/d/n=(nRows, nCols) NnI10SD
			NnI10 = 0
			NnI10SD = 0
			Wave nI10 = NnI10
			Wave nI10SD = NnI10SD
			z = 1 //x=4 means nI10 does not exist 
			if(verbose)
			print "nI10 does not exist (PolCorr_DB)"
			endif
		else 
			z=2	
		endif
		nRows00 =DimSize(nI00,0); nCols00 = DimSize(nI00,1);
		nRowslambda00 = DimSize(LI00,0)
		nRows11 = DimSize(nI11,0); nCols11 = DimSize(nI11,1);
		nRowslambda11 = DimSize(LI11,0)	
		nRows01 = DimSize(nI01,0); nCols00 = DimSize(nI01,1);
		nRowslambda01 = DimSize(LI01,0)
		nRows10 = DimSize(nI10,0); nCols10 = DimSize(nI10,1);
		nRowslambda10 = DimSize(LI10,0)
		if(!equalwaves(nI00, nI01, 512)|| !equalwaves(nI00, nI10, 512)|| !equalwaves(nI00, nI11, 512))
			print "ERROR: The row length of the M_Spec is different in the spectra (PolCorr_DB)"
			abort
		endif
		if(nCols00>1 || nCols11>1 || nCols01>1 || nCols10>1)
			print "A streamed reduction of multidimensional data is not possible at this point (PolCorr_DB)"; abort
		endif
		//Make the final Reflectivity Waves
		make/o/d/n=(nRows, nCols) RI00; make/o/d/n=(nRows, nCols) RI01; make/o/d/n=(nRows, nCols) RI10; make/o/d/n=(nRows, nCols) RI11 
		//maken the wave for the polarizer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		//The values in the comments are the original values until April2012. If the system changes, the new values have to be calculated and inserted here.
		make/o/d/n=(nRows, nCols) poleff
		poleff = polarizer_efficiency_constant_a-polarizer_efficiency_constant_b*polarizer_efficiency_constant_c^(LI00)
		 
		//maken the wave for the analyzer efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		//a, b, c are pre-defined to describe the efficiency function
		make/o/d/n=(nRows, nCols) anaeff 
		anaeff =1 // a-b*c^(LI00)
		
		//maken the wave for the flipper1, flipper2 efficiency, give it the right length and then calculate the efficiency as a function of wavelength
		make/o/d/n=(nRows, nCols) flipper1
	  	make/o/d/n=(nRows, nCols) flipper2
  		flipper1 = 1
  		flipper2 = 1
  		/////////////////////////////
  		//FOR TESTING PURPOSES ONLY!!! Here you can manually change the efficiencies to see what happens!
  		//poleff = 1; 
  		//anaeff = 1; 
  		//flipper1 = 1; 
  		//flipper2 = 1;
  		/////////////////////////////
		
		//make the temporary waves for calculation thorugh the matrices
		make/o/d/n=(nRows, nCols) polefftemp
		make/o/d/n=(nRows, nCols) anaefftemp
		make/o/d/n=(nRows, nCols) flipper1temp
	  	make/o/d/n=(nRows, nCols) flipper2temp
	  	//In order to process the efficiencies in the matrix, we need to convert them into a different form.
		polefftemp =(1-(-1*poleff))/2
  	    	anaefftemp= (1-(-1*anaeff))/2
  	    	flipper1temp = (1-flipper1)
  	    	flipper2temp = (1-flipper2)
  	    	
  	    	make/o/d/n=(4,4,nRows) matpol, matana, matflipone, matfliptwo, final
  	    	  	    	
  	    	matpol[0][0][] =1- polefftemp[r];		matpol[0][1][] =0;				 	 matpol[0][2][] =polefftemp[r]; 			matpol[0][3][] =0;
  	    	matpol[1][0][] =0;                    		matpol[1][1][] =1- polefftemp[r];	  	 matpol[1][2][] =0; 					matpol[1][3][] =polefftemp[r];
  	    	matpol[2][0][] =polefftemp[r];    		matpol[2][1][] =0; 	 		 	 matpol[2][2][] =1- polefftemp[r]; 		matpol[2][3][] =0;
  	    	matpol[3][0][] =0;                    		matpol[3][1][] =polefftemp[r];	 	 matpol[3][2][] =0;		 			matpol[3][3][] =1- polefftemp[r];
		
		matana[0][0][] =1- anaefftemp[r];	matana[0][1][] =anaefftemp[r];		 matana[0][2][] =0;		 			matana[0][3][] =0;
  	    	matana[1][0][] =anaefftemp[r];        	matana[1][1][] =1- anaefftemp[r];	 matana[1][2][] =0; 					matana[1][3][] =0;
  	    	matana[2][0][] =0;			   	matana[2][1][] =0; 	 		 	 matana[2][2][] =1- anaefftemp[r]; 		matana[2][3][] =anaefftemp[r];
  	    	matana[3][0][] =0;                    	matana[3][1][] =0;			 	 matana[3][2][] =anaefftemp[r]; 			matana[3][3][] =1- anaefftemp[r];
  	    	
  	    	matflipone[0][0][] =1;				matflipone[0][1][] =0;				 matflipone[0][2][] =0; 					matflipone[0][3][] =0;
  	    	matflipone[1][0][] =0;                    	matflipone[1][1][] =1;	 			 matflipone[1][2][] =0; 					matflipone[1][3][] =0;
  	    	matflipone[2][0][] =flipper1temp[r];   	matflipone[2][1][] =0; 	 			 matflipone[2][2][] =1- flipper1temp[r]; 	matflipone[2][3][] =0;
  	    	matflipone[3][0][] =0;                    	matflipone[3][1][] =flipper1temp[r];	 matflipone[3][2][] =0;		 			matflipone[3][3][] =1- flipper1temp[r];

		matfliptwo[0][0][] =1;				matfliptwo[0][1][] =0;				 matfliptwo[0][2][] =0; 					matfliptwo[0][3][] =0;
  	    	matfliptwo[1][0][] =flipper2temp[r];	matfliptwo[1][1][] =1-flipper2temp[r];	 matfliptwo[1][2][] =0; 					matfliptwo[1][3][] =0;
  	    	matfliptwo[2][0][] =0;   			matfliptwo[2][1][] =0; 	 			 matfliptwo[2][2][] =1; 					matfliptwo[2][3][] =0;
  	    	matfliptwo[3][0][] =0;                    	matfliptwo[3][1][] =0;	 			 matfliptwo[3][2][] =flipper2temp[r];		matfliptwo[3][3][] =1- flipper2temp[r];

		//The Full Matrix equation looks like Int(1x4) = (F1[4x4]) (F2[4x4]) (P[4x4]) (A[4x4]) R(1x4)
		//Therefore, in order to calculate R, we need to multiply the intensity (Int) with the inverse of the efficiency matrices	
		//Calculate the combined efficiency matrix.				
		MatrixOp finals =  matflipone x matfliptwo x matpol x matana
		MatrixOp finaltemp = Inv(finals)
		for(ii=0; ii<nRows; ii+=1)
			final[][][ii] = finaltemp
			
		endfor	
		killwaves/z finals, finaltemp
		//make a vector for the intensities and the reflectivities
		make/o/d/n=(4,1,nRows) vecintensities
			vecintensities[0][0][] = nI00[r]/scalefactorI00; vecintensities[1][0][] = nI01[r]/scalefactorI01; vecintensities[2][0][] = nI10[r]/scalefactorI10; vecintensities[3][0][] = nI11[r]/scalefactorI11
		MatrixOp vecreftemp = final x vecintensities
		for(ii=0; ii<nRows; ii+=1) 	 
		 	RI11[ii] = vecreftemp[0][0][ii]
		 	RI10[ii] = vecreftemp[1][0][ii]
		 	RI01[ii] = vecreftemp[2][0][ii]
		 	RI00[ii] = vecreftemp[3][0][ii]
		endfor	
		killwaves/z vecreftemp
		if(verbose)
		print " (polcorr_DB) polarization correction executed successfully for the direct beams given"
		endif
		//Put the corrected spectra back in the original datafolder to have it easier with Andys reduction
		string I00path = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorr"
		string I01path = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorr"
		string I10path = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorr"
		string I11path = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorr"
		//Make the error waves after polcorr
		string I00SDpath = "root:packages:platypus:data:Reducer:"+I00+":M_specPolCorrSD"
		string I01SDpath = "root:packages:platypus:data:Reducer:"+I01+":M_specPolCorrSD"
		string I10SDpath = "root:packages:platypus:data:Reducer:"+I10+":M_specPolCorrSD"
		string I11SDpath = "root:packages:platypus:data:Reducer:"+I11+":M_specPolCorrSD"
		
		if(w==1 && x==1)
			print "ERROR: Neither 11 nor 00 found (polcorr_DB)"; abort
		elseif(w==2) 
			make/o/d/n=(nRows, nCols) $I00path 
			WAVE CI00 =  $I00path
			CI00 = RI00
			make/o/d/n=(nRows, nCols) $I00SDpath 
			WAVE CI00SD =  $I00SDpath
			CI00SD = nI00SD ;
		elseif(x==2) 
			make/o/d/n=(nRows, nCols) $I11path 
			WAVE CI11 =  $I11path
			CI11 = RI11
			make/o/d/n=(nRows, nCols) $I11SDpath 
			WAVE CI11SD =  $I11SDpath
			CI11SD = nI11SD ;
		endif
		
		if(y==2 || z==2)
			print "THESE WAVES SHOULD NOT EXIST!! (PolCorr_DB)"; 
			print "ERROR: Something went wron in correting a direct beam (PolCorr_DB)"; abort
		else
			if(verbose)
			print "OK, the direct beam was corrected for the inefficiency of the polarizer (PolCorr_DB)"
			endif
		endif
		killwaves/z polefftemp, anaefftemp, flipper1temp, flipper2temp, final, matfliptwo, matflipone, matana, matpol, NnI00, LLI00, NnI11, LLI11, NnI01, NnI10
		catch
			Print "ERROR: an abort was encountered in (polcorr_DB)"
			setdatafolder $cDF
			return 1
		endtry
		return 0
End


























 	


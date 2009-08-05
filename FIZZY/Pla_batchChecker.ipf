#pragma rtGlobals=1		// Use modern global access method.
#pragma IndependentModule=Pla_batchChecker

Function Pla_checkBatchFile(listWave)
	Wave/t listWave

	string pathToBatchProcedure = specialdirpath("Igor Pro User Files", 0, 0, 0)	
	newpath/o/q/z User_PROCEDURES, pathToBatchProcedure
	
	//first part is to write the listWave to a procedure file
	duplicate/o/t listwave, batchFileChecker
	redimension/n=(-1,0)  batchfileChecker
	insertpoints 0,2,batchfilechecker
	batchfileChecker[0] = "#pragma rtGlobals=1    // Use modern global access method."
	batchfileChecker[1] = "Function test()"
	redimension/n=(numpnts(batchfileChecker)+1) batchFileChecker
	batchfileChecker[inf] = "End"

	Save/o/g/P=User_Procedures batchfileChecker as "batchFileChecker.ipf"
	killwaves/z batchFileChecker
	
	//have to stop the HTML updater from working, as this runs in a preemptive thread and recompiling the 
	//procedures kills the thread.
	//now do the checking
	string/g diditcompile = ""

	execute/q/p/z "stopHTMLupdater()"
	execute/p/z "INSERTINCLUDE \"" + pathToBatchProcedure + "batchFileChecker\""
	
	execute/p/z/q "COMPILEPROCEDURES "
	execute/p/z/q "didItcompile = Functionlist(\"\",\";\",\"\")"

	execute/p/q/z "DELETEINCLUDE \"" + pathToBatchProcedure + "batchFileChecker\""
	execute/p/z/q "COMPILEPROCEDURES "
	execute/p/z/q "Deletefile/P=User_Procedures \"batchFileChecker.ipf\""
	execute/p/q/z "Pla_batchChecker#Pla_compResult(didItCompile)"
	execute/p/q/z "startHTMLupdater()"
End

Function Pla_compresult(val)
	string val
	Variable/g V_flag
	
	if(stringmatch(val,"Procedures Not Compiled;"))
		print "There seems to be something wrong with your list of commands"
		V_flag = 1
	else
		print "Your batch list of commands seems to be syntactically correct"
		V_flag=0
	Endif
end
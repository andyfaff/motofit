#pragma rtGlobals=1		// Use modern global access method.

Menu "Platypus"
	"Load SLIM package", loadSLIMPackage()
	"Unload SLIM package", unloadSLIMPackage()
	"-"
End

Function loadSLIMPackage()
	Execute/P/q  "INSERTINCLUDE \"MOTOFIT_all_at_once\""
	Execute/P/q "INSERTINCLUDE \"Pla_reduction\""
	Execute/P/q "COMPILEPROCEDURES "
End

Function unloadSLIMPackage()
	Execute/P/q "DELETEINCLUDE \"Pla_reduction\""
	Execute/P/q "COMPILEPROCEDURES "
End

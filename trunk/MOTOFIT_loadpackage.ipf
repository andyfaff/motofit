#pragma rtGlobals=1		// Use modern global access method.

Menu "Motofit"
	"Load Motofit package", loadMotofitPackage()
	"Unload Motofit package", unloadMotofitPackage()
	"-"
End

Function loadMotofitPackage()
	Execute/P/q  "INSERTINCLUDE \"MOTOFIT_all_at_once\""
	Execute/P/q "COMPILEPROCEDURES "
End

Function unloadMotofitPackage()
	Execute/P/q  "DELETEINCLUDE \"MOTOFIT_all_at_once\""
	Execute/P/q "COMPILEPROCEDURES "
End

Function loadGeneticCurvefitting()
	Execute/P/q  "INSERTINCLUDE \"GeneticOptimisation\""
	Execute/P/q "COMPILEPROCEDURES "
	Execute/p/q "Genetic_curvefitting()"
End
; Script generated with the Venis Install Wizard

; Define your application name
!define APPNAME "motofit"
!define APPNAMEANDVERSION      "motofit  "

; Main Install settings
Name "${APPNAMEANDVERSION}"
InstallDir "$INSTDIR"
OutFile "./motofitImagInstaller.exe"

; Modern interface settings
!include "MUI.nsh"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL

Section "Motofit" Section1

	; Set Section properties
	SetOverwrite on
	
	ReadRegStr $INSTDIR HKEY_LOCAL_MACHINE "SOFTWARE/Microsoft/Windows/CurrentVersion/App Paths/Igor.exe" "Path"
	
	StrLen $0 $INSTDIR
	
	${If} $0 = 0
    Abort "Can't Install because you don't appear to have IGOR installed"
  ${EndIf}
	

	SetOutPath "$INSTDIR/User Procedures/motofit/"
	File "../motofit_imag/Motofit_imag/*.*"
	File "../XOP Toolkit 5/IgorXOPs5/Abeles/VC6/Abeles.xop"
	File "../XOP Toolkit 5/IgorXOPs5/Abeles/VC6/Abeles Help.ihf"

	SetOutPath "$INSTDIR/User Procedures/motofit/platypus"
	File "../../Platypus/FIZZY_SLIM/SLIM/*.*"

	SetOutPath "$INSTDIR/User Procedures/motofit/data"
	File "../motofit_imag/Data/*.*"

	; Set Section Files and Shortcuts
	SetOutPath "$INSTDIR/User Procedures/motofit"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/GeneticOptimisation.ipf"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/MOTOFIT_Global fit 2.ipf"

	SetOutPath "$INSTDIR/User Procedures/motofit/GenCurvefit"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/win/GenCurveFit.xop"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/ExampleExperiment.pxp"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/GenCurveFit Help.ihf"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/ReleaseNotes.txt"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/Structurefitexample.pxp"
	File "../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/license.txt"
	
	SetOutPath "$INSTDIR/User Procedures/motofit/easyHttp"
	File "../XOP Toolkit 5/IgorXOPs5/easyHttp/trunk/win/easyHttp.xop"
	File "../XOP Toolkit 5/IgorXOPs5/easyHttp/trunk/win/easyHttp Help.ihf"
	
	SetOutPath "$INSTDIR/User Procedures/motofit/multiopenfiles"
	File "../XOP Toolkit 5/IgorXOPs5/multiopenfiles/trunk/win/multiopenfiles.xop"
	File "../XOP Toolkit 5/IgorXOPs5/multiopenfiles/trunk/win/multiopenfiles Help.ihf"
		
	SetOutPath "$INSTDIR/User Procedures/motofit/SOCKIT"
	File "../XOP Toolkit 5/IgorXOPs5/SOCKIT/trunk/win/SOCKIT.xop"
	File "../XOP Toolkit 5/IgorXOPs5/SOCKIT/trunk/win/SOCKIT Help.ihf"
	
	SetOutPath "$INSTDIR/User Procedures/motofit/XMLutils"
	File "../XOP Toolkit 5/IgorXOPs5/XMLutils/trunk/win/XMLutils.xop"
	File "../XOP Toolkit 5/IgorXOPs5/XMLutils/trunk/win/XMLutils Help.ihf"
	
	SetOutPath "$INSTDIR/User Procedures/motofit/ZIP"
	File "../XOP Toolkit 5/IgorXOPs5/ZIP/trunk/win/ZIP.xop"
	File "../XOP Toolkit 5/IgorXOPs5/ZIP/trunk/win/ZIP Help.ihf"
	
	
	SetOutPath "$INSTDIR/Igor Extensions"
	CreateShortCut "Shortcut to SOCKIT.lnk" "$INSTDIR/User Procedures/motofit/SOCKIT/SOCKIT.xop"
	CreateShortCut "Shortcut to ZIP.lnk" "$INSTDIR/User Procedures/motofit/ZIP/ZIP.xop"
	CreateShortCut "Shortcut to GenCurvefit.lnk" "$INSTDIR/User Procedures/motofit/GenCurvefit/GenCurvefit.xop"
	CreateShortCut "Shortcut to Abeles.lnk" "$INSTDIR/User Procedures/motofit/Abeles.xop"
	CreateShortCut "Shortcut to easyHttp.lnk" "$INSTDIR/User Procedures/motofit/easyHttp/easyHttp.xop"
	CreateShortCut "Shortcut to multiopenfiles.lnk" "$INSTDIR/User Procedures/motofit/multiopenfiles/multiopenfiles.xop"
  CreateShortCut "Shortcut to HDF5.lnk" "$INSTDIR/More Extensions/File Loaders/HDF5.xop"
	CreateShortCut "Shortcut to XMLutils.lnk" "$INSTDIR/User Procedures/motofit/XMLutils/XMLutils.xop"

	SetOutPath "$INSTDIR/Igor Procedures"
	CreateShortCut "Shortcut to motofit.lnk" "$INSTDIR/User Procedures/motofit"
	CreateShortCut "Shortcut to platypus.lnk" "$INSTDIR/User Procedures/motofit/platypus"

SectionEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Section1} ""
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; eof
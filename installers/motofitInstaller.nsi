; Script generated with the Venis Install Wizard

; Define your application name
!define APPNAME "motofit"
!define APPNAMEANDVERSION      "motofit  "

; Main Install settings
Name "${APPNAMEANDVERSION}"
InstallDir "$INSTDIR"
OutFile "./motofitInstaller.exe"

; Include LogicLibrary
!include "LogicLib.nsh"

; Modern interface settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME

!define MUI_DIRECTORYPAGE_VARIABLE $INSTDIR
!define MUI_DIRECTORYPAGE_TEXT_TOP "Where would you like to install Motofit? I suggest you put it into C:\Program Files\Wavemetrics\Igor Pro Folder\User Procedures\ but it's up to you."
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL


Section "Motofit" Section1

	; Set Section properties
	SetOverwrite on
	
ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
StrLen $0 $1 
${If} $0 = 0
Abort "You don't appear to have IGOR installed"
${EndIf}
	

	SetOutPath "$INSTDIR\motofit\"
	File "../motofit/Motofit/*.*"
	File "../../XOP Toolkit 5/IgorXOPs5/Abeles/trunk/win/Abeles.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/Abeles/trunk/win/Abeles Help.ihf"

	SetOutPath "$INSTDIR\motofit\platypus"
	File "../SLIM/*.*"

	SetOutPath "$INSTDIR\motofit\data"
	File "../motofit/Data/*.*"

	; Set Section Files and Shortcuts
	SetOutPath "$INSTDIR\motofit"
;	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/GeneticOptimisation.ipf"
;	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/MOTOFIT_Global fit 2.ipf"

	SetOutPath "$INSTDIR\motofit\GenCurvefit"
	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/win/GenCurveFit.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/ExampleExperiment.pxp"
	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/GenCurveFit Help.ihf"
	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/ReleaseNotes.txt"
	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/Structurefitexample.pxp"
	File "../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/license.txt"
	
	SetOutPath "$INSTDIR\motofit\easyHttp"
	File "../../XOP Toolkit 5/IgorXOPs5/easyHttp/trunk/win/easyHttp.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/easyHttp/trunk/win/easyHttp Help.ihf"
	
	SetOutPath "$INSTDIR\motofit\multiopenfiles"
	File "../../XOP Toolkit 5/IgorXOPs5/multiopenfiles/trunk/win/multiopenfiles.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/multiopenfiles/trunk/win/multiopenfiles Help.ihf"
		
	SetOutPath "$INSTDIR\motofit\SOCKIT"
	File "../../XOP Toolkit 5/IgorXOPs5/SOCKIT/trunk/win/SOCKIT.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/SOCKIT/trunk/win/SOCKIT Help.ihf"
	
	SetOutPath "$INSTDIR\motofit\XMLutils"
	File "../../XOP Toolkit 5/IgorXOPs5/XMLutils/trunk/win/XMLutils.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/XMLutils/trunk/win/XMLutils Help.ihf"
	
	SetOutPath "$INSTDIR\motofit\ZIP"
	File "../../XOP Toolkit 5/IgorXOPs5/ZIP/trunk/win/ZIP.xop"
	File "../../XOP Toolkit 5/IgorXOPs5/ZIP/trunk/win/ZIP Help.ihf"
	
	ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
	
	SetOutPath $1
	File "../../XOP Toolkit 5/IgorXOPs5/pthreads-w32-2-8-0-release/pthreadVC2.dll"
	File "../../XOP Toolkit 5/IgorXOPs5/pthreads-w32-2-8-0-release/COPYING.txt"
	File "../../XOP Toolkit 5/IgorXOPs5/pthreads-w32-2-8-0-release/COPYING.lib"
	
	SetOutPath "$1\Igor Extensions"
	CreateShortCut "Shortcut to SOCKIT.lnk" "$INSTDIR\motofit\SOCKIT\SOCKIT.xop"
	CreateShortCut "Shortcut to ZIP.lnk" "$INSTDIR\motofit\ZIP\ZIP.xop"
	CreateShortCut "Shortcut to GenCurvefit.lnk" "$INSTDIR\motofit\GenCurvefit\GenCurvefit.xop"
	CreateShortCut "Shortcut to Abeles.lnk" "$INSTDIR\motofit\Abeles.xop"
	CreateShortCut "Shortcut to easyHttp.lnk" "$INSTDIR\motofit\easyHttp\easyHttp.xop"
	CreateShortCut "Shortcut to multiopenfiles.lnk" "$INSTDIR\motofit\multiopenfiles\multiopenfiles.xop"
  CreateShortCut "Shortcut to HDF5.lnk" "$1\More Extensions\File Loaders\HDF5.xop"
	CreateShortCut "Shortcut to XMLutils.lnk" "$INSTDIR\motofit\XMLutils\XMLutils.xop"

	SetOutPath "$1\Igor Procedures"
	CreateShortCut "Shortcut to motofit.lnk" "$INSTDIR\motofit"
	CreateShortCut "Shortcut to platypus.lnk" "$INSTDIR\motofit\platypus"

SectionEnd

Function .onInit
 ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
StrLen $0 $1 
${If} $0 = 0
Abort "You don't appear to have IGOR installed"
${EndIf}
StrCpy $INSTDIR "$1\User Procedures\"
FunctionEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Section1} ""
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; eof
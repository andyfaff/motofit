; Script generated with the Venis Install Wizard
RequestExecutionLevel user

; Define your application name
!define APPNAME "motofit"
!define APPNAMEANDVERSION      "motofit  "

; Main Install settings
Name "${APPNAMEANDVERSION}"
InstallDir "$INSTDIR"
OutFile ".\motofitInstaller_IP7_64.exe"

; Include LogicLibrary
!include "LogicLib.nsh"

; Modern interface settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME

;!define MUI_DIRECTORYPAGE_VARIABLE $INSTDIR
;!define MUI_DIRECTORYPAGE_TEXT_TOP "Where would you like to install Motofit? I suggest you put it into Documents\User Procedures\ but it's up to you."
;!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL


Section "Motofit" Section1

	; Set Section properties
	SetOverwrite on

;ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
;StrLen $0 $1
;${If} $0 = 0
;Abort "You don't appear to have IGOR installed"
;${EndIf}

	StrCpy $INSTDIR "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files\"

	;get rid of previous versions of motofit
;	Delete "$1\User Procedures\motofit\*"
;	RMDir \r "$1\User Procedures\motofit"

	SetOutPath "$INSTDIR\User Procedures\motofit"
	File "..\motofit\*.*"

	SetOutPath "$INSTDIR\User Procedures\motofit\data"
	File "..\motofit\Data\*.*"

	SetOutPath "$INSTDIR\Igor Procedures"
;	Delete "$INSTDIR\Igor Procedures\Shortcut to motofit.lnk"
	File "..\MOTOFIT_loadpackage.ipf"

	;INSTALL ALL THE XOPs
	SetOutPath "$INSTDIR\Igor Extensions (64-bit)"

	File "..\..\XOP Toolkit 6\IgorXOPs6\Abeles\trunk\win\Abeles64.xop"
	File "..\..\XOP Toolkit 6\IgorXOPs6\Abeles\trunk\win\Abeles Help.ihf"

	File "..\..\XOP Toolkit 6\IgorXOPs6\MultiDimensionalGenCurvefit\trunk\win\GenCurveFit64.xop"
	File "..\..\XOP Toolkit 6\IgorXOPs6\MultiDimensionalGenCurvefit\trunk\extra\ExampleExperiment.pxp"
	File "..\..\XOP Toolkit 6\IgorXOPs6\MultiDimensionalGenCurvefit\trunk\extra\GenCurveFit Help.ihf"
	File "..\..\XOP Toolkit 6\IgorXOPs6\MultiDimensionalGenCurvefit\trunk\extra\ReleaseNotes.txt"
	File "..\..\XOP Toolkit 6\IgorXOPs6\MultiDimensionalGenCurvefit\trunk\extra\Structurefitexample.pxp"
	File "..\..\XOP Toolkit 6\IgorXOPs6\MultiDimensionalGenCurvefit\trunk\extra\license.txt"

	File "..\..\XOP Toolkit 6\IgorXOPs6\easyHttp\trunk\win\easyHttp64.xop"
	File "..\..\XOP Toolkit 6\IgorXOPs6\easyHttp\trunk\win\easyHttp Help.ihf"

;	File "..\..\XOP Toolkit 6\IgorXOPs6\multiopenfiles\trunk\win\multiopenfiles64.xop"
;	File "..\..\XOP Toolkit 6\IgorXOPs6\multiopenfiles\trunk\win\multiopenfiles Help.ihf"

	File "..\..\XOP Toolkit 6\IgorXOPs6\SOCKIT\trunk\win\SOCKIT64.xop"
	File "..\..\XOP Toolkit 6\IgorXOPs6\SOCKIT\trunk\win\SOCKIT Help.ihf"

	File "..\..\XOP Toolkit 6\IgorXOPs6\XMLutils\trunk\win\XMLutils64.xop"
	File "..\..\XOP Toolkit 6\IgorXOPs6\XMLutils\trunk\win\XMLutils Help.ihf"

	File "..\..\XOP Toolkit 6\IgorXOPs6\ZIP\trunk\win\ZIP64.xop"
	File "..\..\XOP Toolkit 6\IgorXOPs6\ZIP\trunk\win\ZIP Help.ihf"

        CreateShortCut "Shortcut to HDF5.lnk" "$1\More Extensions\File Loaders\HDF5.xop"

	File "..\..\XOP Toolkit 6\IgorXOPs6\pthreads_win\lib\pthreadVC2_x64.dll"
	File "..\..\XOP Toolkit 6\IgorXOPs6\pthreads_win\lib\COPYING.txt"
	File "..\..\XOP Toolkit 6\IgorXOPs6\pthreads_win\lib\COPYING.lib"

SectionEnd

;Function .onInit
; ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
;StrLen $0 $1
;${If} $0 = 0
;Abort "You don't appear to have IGOR installed"
;${EndIf}
;StrCpy $INSTDIR "$DOCUMENTS\WaveMetrics\Igor Pro 7 User Files\"
;FunctionEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Section1} ""
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; eof
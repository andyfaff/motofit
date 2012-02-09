; Script generated with the Venis Install Wizard

; Define your application name
!define APPNAME "motofit"
!define APPNAMEANDVERSION      "platypus  "

; Main Install settings
Name "${APPNAMEANDVERSION}"
InstallDir "$INSTDIR"
OutFile "./platypusInstaller.exe"

; Include LogicLibrary
!include "LogicLib.nsh"

; Modern interface settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME

;!define MUI_DIRECTORYPAGE_VARIABLE $INSTDIR
;!define MUI_DIRECTORYPAGE_TEXT_TOP "Where would you like to install platypus? I suggest you put it into C:\Program Files\Wavemetrics\Igor Pro Folder\User Procedures\ but it's up to you."
;!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL


Section "platypus" Section1

	; Set Section properties
	SetOverwrite on
	
ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
StrLen $0 $1 
${If} $0 = 0
Abort "You don't appear to have IGOR installed"
${EndIf}
		
	;get rid of previous versions of motofit
	Delete "$1\User Procedures\motofit\*"
	RMDir /r "$1\User Procedures\motofit"
	
	SetOutPath "$INSTDIR\User Procedures\motofit\platypus"
	File "../SLIM/*"

	SetOutPath "$INSTDIR\Igor Procedures"
	File "../Pla_loadpackage.ipf"
	
	;INSTALL ALL THE XOPs
	SetOutPath "$INSTDIR\Igor Extensions"
	
	File "../../../XOP Toolkit 5/IgorXOPs5/Abeles/trunk/win/Abeles.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/Abeles/trunk/win/Abeles Help.ihf"

	File "../../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/win/GenCurveFit.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/ExampleExperiment.pxp"
	File "../../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/GenCurveFit Help.ihf"
	File "../../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/ReleaseNotes.txt"
	File "../../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/Structurefitexample.pxp"
	File "../../../XOP Toolkit 5/IgorXOPs5/MultiDimensionalGenCurvefit/trunk/extra/license.txt"

	File "../../../XOP Toolkit 5/IgorXOPs5/easyHttp/trunk/win/easyHttp.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/easyHttp/trunk/win/easyHttp Help.ihf"
	
	File "../../../XOP Toolkit 5/IgorXOPs5/multiopenfiles/trunk/win/multiopenfiles.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/multiopenfiles/trunk/win/multiopenfiles Help.ihf"
		
	File "../../../XOP Toolkit 5/IgorXOPs5/SOCKIT/trunk/win/SOCKIT.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/SOCKIT/trunk/win/SOCKIT Help.ihf"
	
	File "../../../XOP Toolkit 5/IgorXOPs5/XMLutils/trunk/win/XMLutils.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/XMLutils/trunk/win/XMLutils Help.ihf"
	
	File "../../../XOP Toolkit 5/IgorXOPs5/neutronunpacker/trunk/win/neutronunpacker.xop"
	
	File "../../../XOP Toolkit 5/IgorXOPs5/ZIP/trunk/win/ZIP.xop"
	File "../../../XOP Toolkit 5/IgorXOPs5/ZIP/trunk/win/ZIP Help.ihf"
	
    CreateShortCut "Shortcut to HDF5.lnk" "$1\More Extensions\File Loaders\HDF5.xop"

	ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
	
	SetOutPath $1
	File "../../../XOP Toolkit 5/IgorXOPs5/pthreads-w32-2-8-0-release/pthreadVC2.dll"
	File "../../../XOP Toolkit 5/IgorXOPs5/pthreads-w32-2-8-0-release/COPYING.txt"
	File "../../../XOP Toolkit 5/IgorXOPs5/pthreads-w32-2-8-0-release/COPYING.lib"
	
	
SectionEnd

Function .onInit
 ReadRegStr $1 HKEY_LOCAL_MACHINE "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Igor.exe" "Path"
StrLen $0 $1 
${If} $0 = 0
Abort "You don't appear to have IGOR installed"
${EndIf}
StrCpy $INSTDIR "$DOCUMENTS\Wavemetrics\Igor Pro 6 User Files\"
FunctionEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Section1} ""
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; eof

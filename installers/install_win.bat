@echo off
set batchloc=%~dp0
set instloc="%USERPROFILE%\Documents\WaveMetrics\Igor Pro 7 User Files"

IF EXIST %instloc% (
	echo Files being copied from:
	echo %batchloc%
	echo IPUF directory is:
	echo %instloc%
	echo ""
	xcopy /b/v/s/e/Y %batchloc%"\User Procedures\motofit" %instloc%"\User Procedures\motofit\"
	xcopy /b/v/s/e/Y %batchloc%"\winXOP\Igor Extensions (64-bit)\*" %instloc%"\Igor Extensions (64-bit)\"
	xcopy /b/v/s/e/Y %batchloc%"\Igor Procedures\*" %instloc%"\Igor Procedures\"
) ELSE (
	echo Sorry, the installer can't seem to find the 'Igor Pro 7 User Files' directory
)

cmd /k
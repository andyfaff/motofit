#!/bin/bash

cd $HOME/Documents/Andy/MOTOFIT/motofit/trunk/installers
 
UserProcedures="/Documents/WaveMetrics/Igor Pro 6 User Files/User Procedures"
IgorExtensions="/Documents/WaveMetrics/Igor Pro 6 User Files/Igor Extensions"
IgorProcedures="/Documents/WaveMetrics/Igor Pro 6 User Files/Igor Procedures"

motofit[0]="Motofit_all_at_once.ipf"
motofit[1]="MOTOFIT_Global fit 2.ipf"
motofit[2]="MOTOFIT_batch.ipf"
motofit[3]="SLDscatteringlengths.txt"
motofit[4]="GeneticOptimisation.ipf"
motofit[5]="MOTOFIT_SLDcalc.ipf"
motofit[6]="MOTOFIT_globalreflectometry.ipf"
motofit[7]="SLDdatabase.txt"

xops[0]="Abeles.xop"
xops[1]="GenCurvefit.xop"			
xops[2]="XMLutils.xop"
xops[3]="multiopenfiles.xop"
xops[4]="SOCKIT.xop"
xops[5]="easyHttp.xop"
xops[6]="ZIP.xop"

IgorProceduresfiles="MOTOFIT_loadpackage.ipf"

error=0

echo "*************************************"
echo "*A test script for seeing if the OS X installer works*"
echo ">1) make installer package"
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Motofit_installer.pmdoc/ --out motofitInstaller.mpkg

if  [ -a motofitInstaller.mpkg ]
then
    echo "Installation worked"
else
    echo "couldn't make the installer file"
    exit
fi

echo "*************************************"
echo ">2) try installing"
installer -pkg motofitInstaller.mpkg -target CurrentUserHomeDirectory

rm motofitInstaller.mpkg

#test for all the xops
echo "*************************************"
echo ">3) are all the XOPs installed?"
for file in "${xops[@]}"
do
	thefile=$HOME$IgorExtensions/$file
    if [ -d "$thefile" ]
    then
        rm -rf "$thefile"
    else
        error=1
        echo $thefile "doesn't exist"
    fi
done

#test allprocedures in motofit
echo "*************************************"
echo ">4) are all the procedures installed?"
for file in "${motofit[@]}"
do
	thefile=$HOME$UserProcedures"/motofit/"$file
    if [ -a "$thefile" ]
    then
        rm "$thefile"
    else
        error=1
        echo $thefile "doesn't exist"
    fi
done
rm -rf "$HOME$UserProcedures/motofit"

#test allprocedures in Igor Procedures
for file in "${IgorProceduresfiles[@]}"
do
	thefile=$HOME$IgorProcedures/$file
    if [ -a "$thefile" ]
    then
        rm "$thefile"
    else
        error=1
        echo $thefile "doesn't exist"
    fi
done

echo "Error status is $error"
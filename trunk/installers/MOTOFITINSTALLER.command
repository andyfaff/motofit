#!/bin/bash

#set your proxy server
export ALL_PROXY="http://proxy-dr.ansto.gov.au:3128"

#set your proxypassword.
#this should be of the form "-U username:password"
#for example:
#export PROXYPASS="andrew:mypassword123"
export PROXYPASS=""

SFBASEURL="http://motofit.svn.sourceforge.net/svnroot/motofit/trunk/"
SFMOTOFIT="http://motofit.svn.sourceforge.net/svnroot/motofit/trunk/motofit/"
IGEX="http://www.igorexchange.com/project_download/files/projects/"

IPUF="$HOME/Documents/WaveMetrics/Igor Pro 6 User Files"


echo "*************************************"
echo "A bash script for installing Motofit"
echo "*************************************"

if [ -d "$IPUF" ]
then
    echo "Igor Pro 6 User Files exists"
else
    echo "WARNING: ~/Documents/WaveMetrics/Igor Pro 6 User Files doesn't exist"
    echo "WARNING: trying ~/Documents/WaveMetrics/Igor Pro User Files"
    
    IPUF="$HOME/Documents/WaveMetrics/Igor Pro User Files"
    if [ -d "$IPUF" ]
    then
        echo "~/Documents/WaveMetrics/Igor Pro User Files exists, placing files there"
    else
        echo "~/Documents/WaveMetrics/Igor Pro 6 User Files doesn't exist either"
        error=1
        exit 
    fi
fi
    
cd "$IPUF/User Procedures"
mkdir motofit
cd motofit
rm *

echo "1) Downloading procedure files"
curl -s --output Motofit_all_at_once.ipf $PROXYPASS $SFMOTOFIT"Motofit_all_at_once.ipf"
if [ $? -ne 0 ]
then
    echo "*************************************"
    echo "Downloading of procedure files fails, check proxy in script"
    echo "*************************************"
    exit
fi

curl -s --output MOTOFIT_Global\ fit\ 2.ipf $PROXYPASS $SFMOTOFIT"MOTOFIT_Global%20fit%202.ipf"
curl -s --output MOTOFIT_batch.ipf $PROXYPASS $SFMOTOFIT"MOTOFIT_batch.ipf"
curl -s --output SLDscatteringlengths.txt $PROXYPASS $SFMOTOFIT"SLDscatteringlengths.txt"
curl -s --output GeneticOptimisation.ipf $PROXYPASS $SFMOTOFIT"GeneticOptimisation.ipf"
curl -s --output MOTOFIT_SLDcalc.ipf $PROXYPASS $SFMOTOFIT"MOTOFIT_SLDcalc.ipf"
curl -s --output SLDdatabase.txt $PROXYPASS $SFMOTOFIT"SLDdatabase.txt"
curl -s --output MOTOFIT_globalreflectometry.ipf $PROXYPASS $SFMOTOFIT"MOTOFIT_globalreflectometry.ipf"

cd "$IPUF/Igor Procedures"
curl -s --output MOTOFIT_loadpackage.ipf $SFBASEURL"MOTOFIT_loadpackage.ipf"

echo "2) Downloading extensions"

cd "$IPUF/Igor Extensions"
rm -rf Abeles.xop GenCurvefit.xop XMLutils.xop multiopenfiles.xop SOCKIT.xop easyHttp.xop ZIP.xop
mkdir temp
cd temp

curl -s --output sockit.zip $PROXYPASS "http://www.igorexchange.com/project_download/files/projects/SOCKIT-IGOR.5.00.x-1.x-dev.zip"
echo $?
if [ $? -ne 0 ]
then
    echo "*************************************"
    echo "Downloading of SOCKIT.zip file fails, check proxy in script"
    echo "*************************************"
    exit
fi
unzip -q sockit.zip
if [ $? -ne 0 ]
then
    echo "*************************************"
    echo "Unzipping of SOCKIT.zip file fails, download may have failed check proxy in script"
    echo "*************************************"
    cd ..
    rm -rf temp
    exit
fi

hdiutil attach -quiet sockit/mac/SOCKIT.dmg
cp -rf /Volumes/SOCKIT/SOCKIT.xop ../
hdiutil detach -quiet /Volumes/SOCKIT

curl -s --output abeles.zip -U $PROXYPASS "http://www.igorexchange.com/project_download/files/projects/abeles-IGOR.5.00.x-5.x-dev.zip"
if [ $? -ne 0 ]
then
    echo "Downloading of Abeles.zip file fails, check proxy in script"
    exit
fi
unzip -q abeles.zip
hdiutil attach -quiet abeles/mac/Abeles.dmg
cp -rf /Volumes/Abeles/Abeles.xop ../
hdiutil detach -quiet /Volumes/Abeles

curl -s --output GenCurvefit.zip $PROXYPASS "http://www.igorexchange.com/project_download/files/projects/gencurvefit-IGOR.5.04.x-1.4.x-dev.zip"
if [ $? -ne 0 ]
then
    echo "Downloading of GenCurvefit.zip file fails, check proxy in script"
    exit
fi
unzip -q GenCurvefit.zip
hdiutil attach -quiet gencurvefit/mac/GenCurvefit.dmg
cp -rf /Volumes/GenCurvefit/GenCurvefit.xop ../
hdiutil detach -quiet /Volumes/GenCurvefit

curl -s --output XMLutils.zip $PROXYPASS "http://www.igorexchange.com/project_download/files/projects/XMLutils-IGOR.5.04.x-1.x-dev.zip"
if [ $? -ne 0 ]
then
    echo "Downloading of XMLutils.zip file fails, check proxy in script"
    exit
fi
unzip -q XMLutils.zip
hdiutil attach -quiet XMLutils/mac/XMLutils.dmg
cp -rf /Volumes/XMLutils/XMLutils.xop ../
hdiutil detach -quiet /Volumes/XMLutils

curl -s --output easyHttp.zip $PROXYPASS "http://www.igorexchange.com/project_download/files/projects/easyHttp-IGOR.5.00.x-1.x-dev.zip"
if [ $? -ne 0 ]
then
    echo "Downloading of easyHttp.zip file fails, check proxy in script"
    exit
fi
unzip -q easyHttp.zip
hdiutil attach -quiet easyHttp/mac/easyHttp.dmg
cp -rf /Volumes/easyHttp/easyHttp.xop ../
hdiutil detach -quiet /Volumes/easyHttp

curl -s --output ZIP.zip $PROXYPASS "http://www.igorexchange.com/project_download/files/projects/ZIP-IGOR.5.04.x-1.x-dev.zip"
if [ $? -ne 0 ]
then
    echo "Downloading of ZIP.zip file fails, check proxy in script"
    exit
fi
unzip -q ZIP.zip
hdiutil attach -quiet ZIP/mac/ZIP.dmg
cp -rf /Volumes/ZIP/ZIP.xop ../
hdiutil  detach -quiet /Volumes/ZIP

cd ..
rm -rf temp
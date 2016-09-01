#!/bin/bash
cd ~/Documents/Andy/MOTOFIT/motofit/installers

rm motofitInstaller.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Motofit_installer.pmdoc/ --out motofitInstaller.mpkg

dropdmg motofitInstaller.mpkg
rm -r motofitInstaller.mpkg
mv motofitInstaller.mpkg.dmg motofitInstaller.dmg


rm motofitInstaller_IP7_32.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Motofit_installer_IP7_32.pmdoc/ --out motofitInstaller_IP7_32.mpkg

dropdmg motofitInstaller_IP7_32.mpkg
rm -r motofitInstaller_IP7_32.mpkg
mv motofitInstaller_IP7_32.mpkg.dmg motofitInstaller_IP7_32.dmg


rm platypusInstaller.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc platypus_installer.pmdoc/ --out platypusInstaller.mpkg

dropdmg platypusInstaller.mpkg
rm -r platypusInstaller.mpkg
mv platypusInstaller.mpkg.dmg platypusInstaller.dmg


makeNSIS -V1 motofitInstaller.nsi
makeNSIS -V1 platypusInstaller.nsi

zip motofit_installers4_1.zip *.dmg *.exe
rsync -e ssh motofit_installers4_1.zip andrew_nelson,motofit@frs.sourceforge.net:/home/frs/project/m/mo/motofit/motofit
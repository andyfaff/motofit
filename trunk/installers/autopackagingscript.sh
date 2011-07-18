#!/bin/bash
cd ~/Documents/Andy/MOTOFIT/motofit/installers

rm motofitimagInstaller.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Motofit_imag_installer.pmdoc/ --out motofitimagInstaller.mpkg

dropdmg motofitimagInstaller.mpkg
rm -r motofitimagInstaller.mpkg
mv motofitimagInstaller.mpkg.dmg motofitimagInstaller.dmg

rm motofitInstaller.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Motofit_installer.pmdoc/ --out motofitInstaller.mpkg

dropdmg motofitInstaller.mpkg
rm -r motofitInstaller.mpkg
mv motofitInstaller.mpkg.dmg motofitInstaller.dmg

rm platypusInstaller.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc platypus_installer.pmdoc/ --out platypusInstaller.mpkg

dropdmg platypusInstaller.mpkg
rm -r platypusInstaller.mpkg
mv platypusInstaller.mpkg.dmg platypusInstaller.dmg

makeNSIS -V1 motofitInstaller.nsi
makeNSIS -V1 motofitImagInstaller.nsi
makeNSIS -V1 platypusInstaller.nsi

zip motofit_installers3.2.zip *.dmg *.exe
rsync -e ssh motofit_installers3.2.zip andrew_nelson,motofit@frs.sourceforge.net:/home/frs/project/m/mo/motofit/motofit


#!/bin/bash
cd ~/Documents/Andy/MOTOFIT/installers

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

makeNSIS motofitInstaller.nsi
makeNSIS motofitImagInstaller.nsi
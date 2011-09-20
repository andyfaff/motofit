#!/bin/bash
cd ~/Documents/Andy/MOTOFIT/motofit/branches/dev/installers

rm motofitInstaller.dmg

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker --doc Motofit_installer.pmdoc/ --out motofitInstaller.mpkg

dropdmg motofitInstaller.mpkg
rm -r motofitInstaller.mpkg
mv motofitInstaller.mpkg.dmg motofitInstaller.dmg

makeNSIS -V1 motofitInstaller.nsi
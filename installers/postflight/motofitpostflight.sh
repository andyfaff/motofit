#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Procedures/motofit\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Procedures/motofit\ alias
fi

if [ -d /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit ]
then
	rm -rf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit
fi

if [-d ~/Documents/Wavemetrics/Igor\ Pro\ 6\ User\ Files/Igor\ Procedures/motofit\ alias]
then
    rm ~/Documents/Wavemetrics/Igor\ Pro\ 6\ User\ Files/Igor\ Procedures/motofit\ alias
fi


if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/HDF5.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/HDF5.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/More\ Extensions/File\ Loaders/HDF5.xop ~/Documents/Wavemetrics/Igor\ Pro\ 6\ User\ Files/Igor\ Extensions/HDF5.xop\ alias
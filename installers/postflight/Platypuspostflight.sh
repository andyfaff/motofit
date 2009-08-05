#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Procedures/platypus\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Procedures/platypus\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/platypus /Applications/Igor\ Pro\ Folder/Igor\ Procedures/platypus\ alias

if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/HDF5.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/HDF5.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/More\ Extensions/File\ Loaders/HDF5.xop /Applications/Igor\ Pro\ Folder/Igor\ Extensions/HDF5.xop\ alias

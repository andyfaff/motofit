#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/multiopenfiles.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/multiopenfiles.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/multiopenfiles/multiopenfiles.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/multiopenfiles.xop\ alias
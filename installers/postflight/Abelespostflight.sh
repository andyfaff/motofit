#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/Abeles.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/Abeles.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/Abeles.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/Abeles.xop\ alias
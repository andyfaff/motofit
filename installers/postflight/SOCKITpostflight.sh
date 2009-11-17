#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/SOCKIT.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/SOCKIT.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/SOCKIT/SOCKIT.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/SOCKIT.xop\ alias

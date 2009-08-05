#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/XMLutils.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/XMLutils.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/XMLutils/XMLutils.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/XMLutils.xop\ alias
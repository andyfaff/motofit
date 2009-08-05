#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Procedures/motofit\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Procedures/motofit\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/ /Applications/Igor\ Pro\ Folder/Igor\ Procedures/motofit\ alias
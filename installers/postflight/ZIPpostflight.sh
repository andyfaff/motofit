#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/ZIP.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/ZIP.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/ZIP/ZIP.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/ZIP.xop\ alias
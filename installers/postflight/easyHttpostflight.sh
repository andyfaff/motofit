#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/easyHttp.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/easyHttp.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/easyHttp/easyHttp.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/easyHttp.xop\ alias
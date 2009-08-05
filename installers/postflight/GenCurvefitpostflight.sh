#!/bin/bash
if [ -d /Applications/Igor\ Pro\ Folder/Igor\ Extensions/GenCurvefit.xop\ alias ]
then
	rm /Applications/Igor\ Pro\ Folder/Igor\ Extensions/GenCurvefit.xop\ alias
fi
ln -sf /Applications/Igor\ Pro\ Folder/User\ Procedures/motofit/GenCurvefit/GenCurvefit.xop/ /Applications/Igor\ Pro\ Folder/Igor\ Extensions/GenCurvefit.xop\ alias
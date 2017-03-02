mkdir -p 'dist/winXOP/Igor Extensions (64-bit)'
mkdir -p 'dist/macXOP/Igor Extensions (64-bit)'
mkdir -p 'dist/Igor Procedures'
mkdir -p 'dist/User Procedures'

winXOP='dist/winXOP/Igor Extensions (64-bit)'
macXOP='dist/macXOP/Igor Extensions (64-bit)'
tkt='../../XOP Toolkit 7/IgorXOPs7'
XOPcode='../../XOPcode'

# copy in installers.
cp install_OSX.command dist
cp INSTALL.txt dist

cp -r ../motofit 'dist/User Procedures'
cp ../MOTOFIT_loadpackage.ipf './dist/Igor Procedures'

# package the OSX XOP's
cp -r "$tkt/Abeles/Xcode/Build/Products/Release/Abeles64.xop" "$macXOP"
cp -r "$tkt/easyHttp/Xcode/build/Release/easyhttp64.xop" "$macXOP"
cp -r "$tkt/MultiDimensionalGenCurvefit/Xcode/build/Products/Release/GenCurvefit64.xop" "$macXOP"
cp -r "$tkt/SOCKIT/Xcode/build/Release/SOCKIT64.xop" "$macXOP"
cp -r "$tkt/XMLutils/Xcode/build/Products/Release/XMLutils64.xop" "$macXOP"
cp -r "$tkt/ZIP/Xcode/build/Release/ZIP64.xop" "$macXOP"

cp "$XOPcode/abeles/extra/Abeles Help.ihf" "$macXOP"
cp "$XOPcode/easyhttp/easyHttp Help.ihf" "$macXOP"
cp "$XOPcode/gencurvefit/extra/GenCurveFit Help.ihf" "$macXOP"
cp "$XOPcode/SOCKIT/win/SOCKIT Help.ihf" "$macXOP"
cp "$XOPcode/XMLutils/help/XMLutils Help.ihf" "$macXOP"
cp "$XOPcode/ZIP/ZIP Help.ihf" "$macXOP"

# package the Windows XOP's
cp "$XOPcode/abeles/extra/Abeles Help.ihf" "$winXOP"
cp "$XOPcode/easyhttp/easyHttp Help.ihf" "$winXOP"
cp "$XOPcode/easyhttp/COPYING.txt" "$winXOP/COPYING_EASYHTTP.txt"
cp "$XOPcode/gencurvefit/extra/GenCurveFit Help.ihf" "$winXOP"
cp "$XOPcode/SOCKIT/win/SOCKIT Help.ihf" "$winXOP"
cp "$XOPcode/SOCKIT/win/COPYING.txt" "$winXOP/COPYING_PTHREADS.txt"
cp "$XOPcode/XMLutils/help/XMLutils Help.ihf" "$winXOP"
cp "$XOPcode/ZIP/ZIP Help.ihf" "$winXOP"
cp "$XOPcode/ZIP/zlib_README.txt" "$winXOP/COPYING_ZLIB.txt"


cp "$tkt/Abeles/VC6/Abeles64.xop" "$winXOP"
cp "$tkt/easyHttp/VC8/easyhttp64.xop" "$winXOP"
cp "$tkt/MultiDimensionalGenCurvefit/VC8/GenCurvefit64.xop" "$winXOP"
cp "$tkt/SOCKIT/VC8/SOCKIT64.xop" "$winXOP"
cp "$tkt/XMLutils/VC8/XMLutils64.xop" "$winXOP"
cp "$tkt/ZIP/VC8/ZIP64.xop" "$winXOP"
cp "$tkt/deps/lib/libxml2.dll" "$winXOP"
cp "$tkt/deps/pthreads_win/lib/pthreadVC2_x64.dll" "$winXOP"

zip dist.zip dist


/*
	
GenCurvefit.c -- An XOP for curvefitting via Differential Evolution.
@copyright: Andrew Nelson and the Australian Nuclear Science and Technology Organisation 2007.

*/

/*
	Functions contained in updateXOP<x>.c
*/
void DrawXOPWindow(XOP_WINDOW_REF w);
void DisplayWindowXOP1Message(XOP_WINDOW_REF w, int numcoefs, double* coefs, double chi2,char* fitfunc,long fititers);
XOP_WINDOW_REF CreateXOPWindow(void);
void DestroyXOPWindow(XOP_WINDOW_REF w);

#ifdef _MACINTOSH_			// [
	void XOPWindowClickMac(WindowPtr, EventRecord* );
	int ManuallyCheckButton( WindowPtr );
#endif						// _MACINTOSH_ ]

#ifdef _WINDOWS_			// [
	int CreateXOPWindowClass(void);
#endif	


//in malloc2D.c
void* malloc2d(int ii, int jj, int sz);

/* Prototypes */
HOST_IMPORT void main(IORecHandle ioRecHandle);






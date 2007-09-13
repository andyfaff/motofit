#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

static ControlHandle theControl = NULL;
void DestroyXOPWindow(XOP_WINDOW_REF w);

void ManuallyCheckButton( WindowPtr w ){
	EventRecord	theEvent;
	short		winPart;
	WindowPtr	clickWindow;
	int result = 0;
	Point where;
	int what = 0;

	if(w != NULL ){
		if( WaitNextEvent( mDownMask, &theEvent, 0, nil ) ){
			winPart = FindWindow( theEvent.where, &clickWindow );
			where = theEvent.where;
			GlobalToLocal(&where);
			what = FindControl(where, w , &theControl);
			switch(what) {
				case kControlButtonPart:
					what = TrackControl(theControl, where, NULL);
					switch(what) {
						case kControlButtonPart:
							DestroyXOPWindow(w);
							result = 1;
							break;
					}
					break;
			}
		}
	}
	return result;
}

void DisplayWindowXOP1Message(WindowPtr theWindow,int numcoefs, const double* coefs, double chi2, const char* fitfunc,long fititers)
{
	Rect r;
	int err2;
	char message[255];
	unsigned char temp[255];
	char number[30];
	int offset = 10,vertoffset = 15, vertspace = 20, space = 85, ii, jj;

	GrafPtr thePort, savePort;
	
	GetPort(&savePort);
	thePort = GetWindowPort(theWindow);
	SetPort(thePort);
	TextSize(11);
	GetPortBounds(thePort, &r);
	r.bottom = r.bottom - 35;
	
	EraseRect(&r);
//print out the fitfunction
	MoveTo(offset,vertoffset);
	strcpy(message,"Fitting to: ");
	strcat(message,fitfunc);
	CopyCStringToPascal(message, temp);
	DrawString(temp);
	
//print out the number of iterations and the Chi2 value
	MoveTo(offset, vertoffset+vertspace);
	strcpy(message,"Iterations");
	CopyCStringToPascal(message, temp);
	DrawString(temp);
	strcpy(message,"");
	
	MoveTo(offset+80,vertoffset+vertspace);
	strcpy(message,"Chi Squared");
	CopyCStringToPascal(message, temp);
	DrawString(temp);
	strcpy(message,"");
	
	MoveTo(offset,vertoffset+2*vertspace);
	err2 = sprintf(message,"%d",fititers);
	CopyCStringToPascal(message, temp);
	DrawString(temp);
	strcpy(message,"");
	
	MoveTo(offset+80,vertoffset+2*vertspace);
	err2 = sprintf(message,"%-6.4g",chi2);
	CopyCStringToPascal(message, temp);
	DrawString(temp);
	strcpy(message,"");
	
	MoveTo(offset, vertoffset+10+3*vertspace);
	strcpy(message,"Coefficients");
	CopyCStringToPascal(message, temp);
	DrawString(temp);
	strcpy(message,"");
	
	MoveTo(offset, 15+vertoffset+3*vertspace);
	LineTo(offset+450,15+vertoffset+3*vertspace);
	
	//now print out the first 25 coefficients.  In order to get grid like behaviour there's
	//a lot of moving about.
	for(jj=0 ; (jj<(int)ceil((double)numcoefs/5) && jj<6) ; jj+=1){
		for(ii=0 ; (ii<5 && ii < (numcoefs-(jj*5))) ; ii+=1){
			MoveTo(offset+(ii*space),vertoffset+(5+jj)*vertspace);
			strcpy(number,"");
			err2 = sprintf(number,"%-6.4g",*(coefs+ii+(jj*5)));
			strcat(message,number);
			CopyCStringToPascal(message, temp);
			DrawString(temp);
			strcpy(message,"");
		}

	}
	
	QDFlushPortBuffer(thePort, NULL);
	SetPort(savePort);
}

int XOPWindowClickMac(WindowPtr theWindow, EventRecord* ep) {
	WindowPtr whichWindow;
	Point where;
	int what;
	GrafPtr thePort, savePort;
	int result = 0;
	
	GetPort(&savePort);
	thePort = GetWindowPort(theWindow);
	SetPort(thePort);
	
	what = FindWindow(ep->where, &whichWindow);
	switch(what) {
		case inContent:
			where = ep->where;
			GlobalToLocal(&where);
			what = FindControl(where, theWindow, &theControl);
			switch(what) {
				case kControlButtonPart:
					what = TrackControl(theControl, where, NULL);
					switch(what) {
						case kControlButtonPart:
							DestroyXOPWindow(theWindow);
							result = 1;
							break;
					}
					break;
			}
			break;	
	}
	SetPort(savePort);
	return result;
}

WindowPtr CreateXOPWindow(void){
	WindowPtr theWindow;
		
	theWindow = GetXOPWindow(XOP_WIND, NIL, (WindowPtr)-1L);
	if (theWindow != NULL) {
		Rect bounds;
		SetRect(&bounds, 420, 220, 480, 240);
		theControl = NewControl(theWindow, &bounds, "\pAbort", 1, 0, 0, 1, pushButProc, 0L);
	}
	
	return theWindow;
}

void DestroyXOPWindow(WindowPtr theWindow) {
	KillControls(theWindow);
	DisposeWindow(theWindow);
	theWindow = NULL;
}


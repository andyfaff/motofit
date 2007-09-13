#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h
/*	This is the XOP window class name. It must not conflict with other window
	class names. Therefore, use your XOP's name and make sure that your XOP's
	name is sufficiently descriptive to insure uniqueness.
*/
static char* gXOPWindowClassName = "UpdateGenCurveFit";

/*
	Print a message in the hwnd window
*/
void
DisplayWindowXOP1Message(XOP_WINDOW_REF hwnd, int numcoefs, double* coefs, double chi2,char* fitfunc,long fititers)
{
	HDC hdc;
	HBRUSH hBrush;
	RECT clientRect;
	unsigned long ticks;
	HFONT hFont;
	int err2;
	int nTabPositions = 8;
	int lpnTabStopPositions[8];
	char message[1024];
	char number[30];
	int ii,jj, offset=5,space=80,vertoffset = 20;
	
	lpnTabStopPositions[0] = offset;
	lpnTabStopPositions[1] = offset+space;
	lpnTabStopPositions[2] = offset+2*space;
	lpnTabStopPositions[3] = offset+3*space;
	lpnTabStopPositions[4] = offset+4*space;
	lpnTabStopPositions[5] = offset+5*space;
	lpnTabStopPositions[6] = offset+6*space;
	lpnTabStopPositions[7] = offset+7*space;

	if (GetClientRect(hwnd, &clientRect) == 0)
		return;			// Should never happen.
	
	hdc = GetDC(hwnd);
	if (hdc == NULL)
		return;			// Should never happen.
	
	hBrush = GetStockObject(LTGRAY_BRUSH);
	FillRect(hdc, &clientRect, hBrush);
	hFont = CreateFont(15,0,0,0,300,FALSE,FALSE,FALSE,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,DEFAULT_PITCH,NULL);
	SelectObject(hdc,hFont);
	
	SetBkMode(hdc, TRANSPARENT);

	//DisplayWindowXOP1Message calls code in updateXOP<x>.c
	//this gives a window that gives the user the current chi2 value
	//and the number of iterations.
	strcpy(message,"Fitting to: ");
	strcat(message,fitfunc);
	TabbedTextOut(hdc,3,3,message,strlen(message),nTabPositions,(LPINT) lpnTabStopPositions,0);
	strcpy(message,"");
	
	strcpy(message,"Iterations\tChisq\t");
	TabbedTextOut(hdc,3,3+vertoffset,message,strlen(message),nTabPositions,(LPINT) lpnTabStopPositions,0);
	strcpy(message,"");

	MoveToEx(hdc, 1, 40, (LPPOINT) NULL); 
    LineTo(hdc, 399, 40); 
	
	err2 = sprintf(message,"%d\t%-6.4g\t",fititers,chi2);
	TabbedTextOut(hdc,1,43,message,strlen(message),nTabPositions,(LPINT) lpnTabStopPositions,0);
	strcpy(message,"");

	strcpy(message,"Coefficients");
	TabbedTextOut(hdc,3,75,message,strlen(message),nTabPositions,(LPINT) lpnTabStopPositions,0);
	strcpy(message,"");

	MoveToEx(hdc, 1, 90, (LPPOINT) NULL); 
    LineTo(hdc, 399, 90); 

	for(jj=0 ; (jj<(int)ceil((double)numcoefs/5) && jj<6) ; jj+=1){
		for(ii=0 ; (ii<5 && ii < (numcoefs-(jj*5))) ; ii+=1){
			strcpy(number,"");
			err2 = sprintf(number,"%-6.4g\t",*(coefs+ii+(jj*5)));
			strcat(message,number);
		}
		TabbedTextOut(hdc,1,100+jj*vertoffset,message,strlen(message),nTabPositions,(LPINT) lpnTabStopPositions,0);
		strcpy(message,"");
	}
	DeleteObject(hFont);
	ReleaseDC(hwnd, hdc);
}
/*
	Handle all the window events.
*/
static LRESULT CALLBACK
XOPWindowProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
	int passMessageToDefProc;
	
	if (SendWinMessageToIgor(hwnd, iMsg, wParam, lParam, 0))	// Give Igor a crack at this message.
		return 0;
	
	passMessageToDefProc = 1;		// Determines if we pass message to default window procedure.
	switch(iMsg) {
		case WM_CREATE:
			// Do your custom initialization here.
			
			passMessageToDefProc = 0;
			break;
		
		case WM_MOUSEMOVE:
			passMessageToDefProc = 0;
			break;
			
		case WM_TIMER:
			break;

		case WM_SIZE:
			passMessageToDefProc = 1;		// Windows documentation says to pass this message to the def proc.
			break;

		case WM_MOVE:
			passMessageToDefProc = 1;		// Windows documentation says to pass this message to the def proc.
			break;

		case WM_PAINT:
			{
				HDC hdc;
				PAINTSTRUCT ps;
				int isActive;
				
				isActive = IsXOPWindowActive(hwnd);
				hdc = BeginPaint(hwnd, &ps);
				EndPaint(hwnd, &ps);
			}
			passMessageToDefProc = 0;
			break;

		case WM_ACTIVATE:
		case WM_MDIACTIVATE:
			{
				HDC hdc;
				int isActive;
				
				hdc = GetDC(hwnd);
				if (hdc == NULL)
					break;								// Should never happen.
				isActive = hwnd == (HWND)lParam;		// Are we being activated?
				ReleaseDC(hwnd, hdc);
			}
			
			passMessageToDefProc = 1;		// Windows documentation doesn't say so, but I found it necessary to pass this message to the def proc. Otherwise, the window was not correctly highlighted.
			break;

		case WM_COMMAND:
			passMessageToDefProc = 0;
			break;
		
		case WM_KEYDOWN:
		case WM_CHAR:
			// Do your custom key processing here.
			passMessageToDefProc = 0;
			break;
			
		case WM_LBUTTONDOWN:
			// Do your custom click processing here.
			passMessageToDefProc = 0;
			break;
		
		case WM_RBUTTONDOWN:
			// Do your custom click processing here.
			passMessageToDefProc = 0;
			break;

		case WM_CLOSE:							// Message received when the user clicks the close box.
			HideAndDeactivateXOPWindow(hwnd);
			passMessageToDefProc = 0;
			break;

		case WM_DESTROY:
			passMessageToDefProc = 0;
			break;
	}

	SendWinMessageToIgor(hwnd, iMsg, wParam, lParam, 1);	// Give Igor another crack at it.

	if (passMessageToDefProc == 0)
		return 0;

	// Pass unprocessed message to default window procedure.
	return DefMDIChildProc(hwnd, iMsg, wParam, lParam);
}

/*
	create a window class
*/
int
CreateXOPWindowClass(void)		// Called from main in GenCurvefit.c.
{
	HMODULE hXOPModule;
	WNDCLASSEX  wndclass;
	ATOM atom;
	int err;
	
	err = 0;
	
	hXOPModule = XOPModule();

	wndclass.cbSize			= sizeof(wndclass);
	wndclass.style			= CS_HREDRAW | CS_VREDRAW;
	wndclass.lpfnWndProc	= XOPWindowProc;
	wndclass.cbClsExtra		= 0;
	wndclass.cbWndExtra		= 0;
	wndclass.hInstance		= hXOPModule;
	wndclass.hIcon			= LoadIcon(NULL, IDI_APPLICATION);
	wndclass.hCursor		= NULL;										// we control our cursor
	wndclass.hbrBackground	= GetStockObject(LTGRAY_BRUSH);
	wndclass.lpszMenuName	= NULL;
	wndclass.lpszClassName	= gXOPWindowClassName;
	wndclass.hIconSm		= NULL;
	atom = RegisterClassEx(&wndclass);
	if (atom == 0) {				// You will get an error if you try to register a class
		err = GetLastError();		// using a class name for an existing window class.
		err = WindowsErrorToIgorError(err);
	}
	return err;
}

/*
	Create the updater window.  Called from init_gencurvefitinternals in GenCurvefit.c
*/
HWND
CreateXOPWindow(void)
{
	HWND hwnd, parentHWND;
	int style, extendedStyle;
	int x, y, width, height;
	HMODULE hXOPModule;
	HMENU hMenu;

	// Now we can create the window.
	hXOPModule = XOPModule();
	style = WS_VISIBLE | WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_CAPTION | WS_THICKFRAME | WS_SYSMENU;
	extendedStyle = WS_EX_MDICHILD;
	x = 200;
	y = 200;
	width = 400;
	height = 250;
	
	/*	When we are creating an MDI window, this makes the window the child of the Igor MDI client window.
		When we are creating and overlapped window, this makes the window owned by Igor MDI client window.
	*/
	parentHWND = IgorClientHWND();
	
	/*	For an MDI child window, the hMenu parameter is not a menu handle but rather is a
		"child window identifier". According to the Windows documentation, this is
		supposed to be "unique for all child windows with the same parent". We use
		the GetTickCount function to insure uniqueness.
	*/
	hMenu = (HMENU)GetTickCount();
	
	hwnd = CreateWindowEx(extendedStyle, gXOPWindowClassName, "GenCurvefit Update", style, x, y, width, height, parentHWND, hMenu, hXOPModule, (LPARAM)NULL);
	return hwnd;
}

/*
	Kill the window resource. called from freeAllocMem in GenCurvefit.c
*/
void
DestroyXOPWindow(HWND hwnd)
{
	// Do not use DestroyWindow to destroy an MDI child window!
	SendMessage(IgorClientHWND(), WM_MDIDESTROY, (WPARAM)hwnd, 0);
}

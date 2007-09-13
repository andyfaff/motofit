/*	GenCurveFit.c -- An XOP for curvefitting via Differential Evolution.
	See:
	Wormington, et. al., "Characterisation of structures from X-ray Scattering
	Data using Genetic Algorithms", Phil. Trans. R. Soc. Lond. A (1999) 357, 2827-2848

	And
	The Motofit packages: http://motofit.sourceforge.net/
	Nelson, "Co-refinement of multiple-contrast neutron/X-ray reflectivity data using Motofit",
	J. Appl. Cryst. (2006). 39,273-276.

	@copyright: Andrew Nelson and the Australian Nuclear Science and Technology Organisation 2007.

*/
#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h
#include "GenCurveFit.h"
#include <time.h>
#include <stdlib.h>

#ifdef _WINDOWS_
#include "malloc2d.c"
#endif

#define MAX_MDFIT_SIZE 50
// Custom error codes
#define REQUIRES_IGOR_500 1 + FIRST_XOP_ERR
#define NON_EXISTENT_WAVE 2 + FIRST_XOP_ERR
#define REQUIRES_SP_OR_DP_WAVE 3 + FIRST_XOP_ERR
#define WAVES_NOT_SAME_LENGTH 4 + FIRST_XOP_ERR
#define INPUT_WAVES_NOT_1D 5 + FIRST_XOP_ERR
#define INPUT_WAVES_NO_POINTS 6 + FIRST_XOP_ERR
#define INPUT_WAVES_CONTAINS_NANINF 7 + FIRST_XOP_ERR
#define COEF_HAS_NO_POINTS 8 + FIRST_XOP_ERR
#define COEF_HAS_NANINF 9 + FIRST_XOP_ERR
#define SCALING_OF_YWAVE 10 + FIRST_XOP_ERR
#define GenCurveFit_PARS_INCORRECT 11 + FIRST_XOP_ERR
#define HOLDSTRING_NOT_SPECIFIED 12 + FIRST_XOP_ERR
#define HOLDSTRING_INVALID 13 + FIRST_XOP_ERR
#define STOPPING_TOL_INVALID 14 + FIRST_XOP_ERR
#define INVALID_FIT_FUNC 15 + FIRST_XOP_ERR
#define FITFUNC_DOESNT_RETURN_NUMBER 16 + FIRST_XOP_ERR
#define SPARSE_INDEPENDENT_VARIABLE 17 + FIRST_XOP_ERR
#define INVALID_AFITFUNC_INPUT 18 + FIRST_XOP_ERR
#define FITFUNC_NOT_SPECIFIED 19 + FIRST_XOP_ERR
#define LIMITS_WRONG_DIMS 20 + FIRST_XOP_ERR
#define LIMITS_INVALID 21 + FIRST_XOP_ERR
#define FITFUNC_RETURNED_NANINF 22 + FIRST_XOP_ERR
#define UNSPECIFIED_ERROR 23 + FIRST_XOP_ERR
#define HOLDSTRING_NOT_RIGHT_SIZE 24 + FIRST_XOP_ERR
#define ALL_COEFS_BEING_HELD 25 + FIRST_XOP_ERR
#define FIT_ABORTED 26 + FIRST_XOP_ERR
#define OUTPUT_WAVE_WRONG_SIZE 27 + FIRST_XOP_ERR
#define OUTPUT_WAVE_OVERWRITING_INPUT 28 + FIRST_XOP_ERR
#define STANDARD_DEV_IS_ZERO 29 + FIRST_XOP_ERR
#define USER_CHANGED_FITWAVE 30 + FIRST_XOP_ERR
#define INCORRECT_COST_FUNCTION 31 + FIRST_XOP_ERR
#define SUBRANGE_SPECIFIED_ASX 32 + FIRST_XOP_ERR

//gTheWindow is a window created to show the latest position of the fit
XOP_WINDOW_REF gTheWindow = NULL;


#include "XOPStructureAlignmentTwoByte.h"	// All structures passed to Igor are two-byte aligned.
/*
	Structures passed to the XOP from IGOR
*/
struct GenCurveFitRuntimeParams {

	/*
	what (bitwise)options do you want to use
	bit 0: use initial guesses for starting fit, instead of random initialisation
	*/
	int OPTFlagEncountered;
	double opt;
	int OPTFlagParamsSet[1];

	// Flag parameters.

	/*
	Q - quiet mode
	if this flag is specified then results aren't printed in the history window.
	*/
	int QFlagEncountered;

	/*
	N - no updates during fit.  This makes the fit faster
	*/
	int NFlagEncountered;

	/*
	L - Destination Length
	this option specifies the length of the output wave (assuming the /D flag is not specified.
	*/
	int LFlagEncountered;
	double LFlag_destlen;
	int LFlagParamsSet[1];

	/*
	R - residual wave
	the user can specify if a residual wave is to be created after the fit
	The user can specify a residual wave to be used, but it must be the same length as the datawave
	*/
	int RFlagEncountered;
	waveHndl RFlag_resid;					// Optional parameter.
	int RFlagParamsSet[1];

	/*
	METH - costfunction used.
	Chi2, METH = 0
	or
	sum of absolute deviations, METH = 1
	*/
	int METHFlagEncountered;
	double METHFlag_method;
	int METHFlagParamsSet[1];

	/*
	X	-	xwaves for dataset (optional)
	If this is not specified then fit uses dataWave scaling.
	If the fit is multivariate then these must be specified.  For dimensions>1 then XFlagWaveH must be 
	specified.
	*/
	int XFlagEncountered;
	waveHndl XFlag_xx;
	waveHndl XFlagWaveH[49];				// Optional parameter.
	int XFlagParamsSet[50];

	/*
	D	-	output from the fit
	If the user specifies this option, then the supplied wave (outputwave) is filled with calculated values from the 
	model fit.  
	The supplied wave must be the same length as the dataWave, and be 1D.
	*/
	int DFlagEncountered;
	waveHndl outputwave;
	int DFlagParamsSet[1];

	/*
	W	-	weighting wave
	if specified this wave contains values for weighting the costfunction.
	It must be 1D and the same length as the dataWave.
	*/
	int WFlagEncountered;
	waveHndl weights;
	int WFlagParamsSet[1];

	/*
	I	-	what the weight wave contains
	I=0 (default) means W contains weights.
	I=1 means W contains standard deviations.
	*/
	int IFlagEncountered;
	double weighttype;
	int IFlagParamsSet[1];

	/* 
	M	-	maskwave
	If specified use this wave to mask points from the fit.
	Set element = 0 or NaN to mask a point from the fit.  Wave must be 1D and same length as dataWave.
	*/
	int MFlagEncountered;
	waveHndl maskwave;
	int MFlagParamsSet[1];

	/*
	K	-	Parameters for initialising genetic optimisation.
	defaults:
	iterations = 100 (legal range > 1)
	popsize = 20	(legal rangle >1)
	km = 0.5		(legal range 0 < km < 1)
	recomb = 0.7	(legal range 0 < recomb <1)
	To ensure global minima increase popsize,  decrease km and recomb.
	*/
	int KFlagEncountered;
	double iterations;
	double popsize;
	double km;
	double recomb;
	int KFlagParamsSet[4];

	/*
	TOL	-	tolerance for stopping fit.
	If standard deviation of all the chi2 values for the different genetic strains is less then this value 
	then the fit stops.
	*/
	int TOLFlagEncountered;
	double tol;
	int TOLFlagParamsSet[1];

	// Main parameters.

	/*
	fitfun	-	the user fit function
	This may be:
	normal (independent variables are passed to the user function as variables)
	-or-
	all-at-once (independent variables are passed to the user function as waves)
	
	Either may be multivariate, i.e. more than one independent variable
	e.g. myfitfun(coefwave, ywave, xwave0,xwave1,xwave2) - specifies all-at-once fitfunction for 3 independent variables
	*/
	int fitfunEncountered;
	char fitfun[MAX_OBJ_NAME+1];
	int fitfunParamsSet[1];

	/*
	dataWave	-	data to be fitted
	Must be single precision or double precision and 1D
	*/
	int dataWaveEncountered;
	WaveRange dataWave;
	int dataWaveParamsSet[1];

	/*
	coefs	-	starting coefficients to supply to fit function (fitfun)
	*/
	int coefsEncountered;
	waveHndl coefs;
	int coefsParamsSet[1];

	/*
	holdstring	-	specifies which parameters are to be held.
	e.g. "1001110"
	contains:
	0 (vary)
	-or- 
	1 (hold)
	Must be same length as coefs wave
	*/
	int HEncountered;
	Handle holdstring;
	int holdstringParamsSet[1];

	/*
	limitswave - upper and lower bounds for each coefficient.
	Has dimensions [numpnts(coefs)][2].  First column contains lower limit, second column contains upper limit.
	Legal use:
	lowerlimit[parameter1] < coefs[parameter1] < upperlimit[parameter1]
	The check to see whether the coefficients are within the upper and lower limits is only performed if bit 0 of the /OPT flag is set.
	*/
	int limitswaveEncountered;
	waveHndl limitswave;
	int limitswaveParamsSet[1];

	// These are postamble fields that Igor sets.
	int calledFromFunction;					// 1 if called from a user function, 0 otherwise.
	int calledFromMacro;					// 1 if called from a macro, 0 otherwise.
};
typedef struct GenCurveFitRuntimeParams GenCurveFitRuntimeParams;
typedef struct GenCurveFitRuntimeParams* GenCurveFitRuntimeParamsPtr;
#include "XOPStructureAlignmentReset.h"		// Reset structure alignment to default.

#include "XOPStructureAlignmentTwoByte.h"	// All structures passed to Igor are two-byte aligned.
//this structure contains all the internal memory arrays necessary for the fit to proceed.
struct GenCurveFitInternals{
	
	//how many parameters are being varied
	int numvarparams;
	//how many dimensions you are trying to fit
	int numVarMD;
	//totalsize of the population
	int totalpopsize;
	//which parameters are varying
	int *varparams;
	//an array which holds all the different guesses for the fit.
	//it has dimensions popsize*numvarparams, numvarparams
	double **gen_populationvector;
	//an array which holds the coefficients ready to be sent to IGOR.
	double *gen_coefsCopy;
	//an array used in setting up an individual genetic guess.
	double *gen_bprime;
	//an individual genetic guess.
	double *gen_trial;
	//a utility array, same length as gen_trial.
	double *gen_pvector;

	//cost function for minimisation
	int METH;
	//an array which holds all the chi2 values for all the different guesses in the population vector.
	double *chi2Array;
	//the current chi2
	double chi2;
	//number of fititerations done
	long V_numfititers;

	//a full copy of the y data being fitted
	double *dataObsFull;
	//the number of dataPoints;
	long dataPoints;
	//a copy of the y data being fitted, without the masked points.
	double *dataObs;
	//which weight type?
	int weighttype;
	//the corresponding errors for each of those points.
	double *dataSig;
	//corresponding independent variable points for each of the masked data points.
	double *independentVariable;
	//corresponding independent variable points for each of the unmasked data points.
	double *allIndependentVariable;
	//an array which holds the calculated data
	double *dataTemp;
	//a copy of the limits that are being used.
	double *limits;
	//an array specifying which y points are not included.
	double *mask;
	//if a range is specified for the ywave needs start and endpoints
	long startPoint;
	long endPoint;
	//how many points are being fitted.
	long unMaskedPoints;
	//the ywave scaling, in case no x-wave is specified.
	double ystart,ydelta;
	//the function being fitted.
	FunctionInfo fi;
	//is it all at once?
	int isAAO;
	
	//utility arrays, size of full dataset
	double *temp;

	//the current datafolder needs to be stored, so we have a place to put temporary waves.
	//dataCalc, xcalc,GenCurveFitCoefs are temporary waves created so that we can call a function.
	
	//a handle to the current data folder
	DataFolderHandle cDF;
	//a handle to the calculated data
	waveHndl dataCalc;
	//a handle to the xwave used to calculate the model (excluding masked points)
	waveHndl xcalc[MAX_MDFIT_SIZE]; 
	//the coefficients used to calculate the model
	waveHndl GenCurveFitCoefs;
	//the full range of xpoints being used (including masked points)
	waveHndl fullExtentOfData[MAX_MDFIT_SIZE];
	//a temporary wave handle.  This will be made if /D is specified and if the independent data is univariate
	waveHndl tempWaveHndl_OUTx;
	
	//Wave Handles for the output, i.e. the fit waves.
	//the output y wave
	waveHndl OUT_data;
	//the output xwave
	waveHndl OUT_x[MAX_MDFIT_SIZE];	//these aren't actual waves, but handles to prexisting waves.
	//the output residual wave
	waveHndl OUT_res;
};
typedef struct GenCurveFitInternals GenCurveFitInternals;
typedef struct GenCurveFitInternals* GenCurveFitInternalsPtr;
#include "XOPStructureAlignmentReset.h"		// Reset structure alignment to default.

#include "XOPStructureAlignmentTwoByte.h" // Set structure alignment.
struct fitFunc { // Used to pass parameters to the function.
	waveHndl waveH; // For the first function parameter.
	double x[MAX_MDFIT_SIZE];
};
typedef struct fitFunc fitFunc;
typedef struct fitFunc* fitFuncPtr;
#include "XOPStructureAlignmentReset.h" // Reset structure alignment.

#include "XOPStructureAlignmentTwoByte.h" // Set structure alignment.
struct allFitFunc { // Used to pass parameters to the function.
	waveHndl waveC; // For the coefficients.
	waveHndl waveY;	// for filling up by the function
	waveHndl waveX[MAX_MDFIT_SIZE];	// supplies independent values for function
};

typedef struct allFitFunc allFitFunc;
typedef struct allFitFunc* allFitFuncPtr;
#include "XOPStructureAlignmentReset.h" // Reset structure alignment.

struct waveStats {
	double V_avg;
	double V_stdev;
	long V_maxloc;
	long V_minloc;
};
typedef struct waveStats waveStats;
typedef struct waveStats* waveStatsPtr;

static int checkInput(GenCurveFitRuntimeParamsPtr, GenCurveFitInternalsPtr);
static int checkNanInf(waveHndl);
static int checkZeros(waveHndl ,long* );
static void freeAllocMem(GenCurveFitInternalsPtr goiP);
static int randomInteger(int upper);
static double randomDouble(double lower, double upper);
static int calcModel(FunctionInfo*, waveHndl, waveHndl, double*, waveHndl[MAX_MDFIT_SIZE], double*,int,int);
static int calcModelXY(FunctionInfo*, waveHndl , waveHndl , waveHndl[MAX_MDFIT_SIZE] , int ,int );
static int insertVaryingParams(GenCurveFitInternalsPtr , GenCurveFitRuntimeParamsPtr );
static int setPvectorFromPop(GenCurveFitInternalsPtr , int );
static int findmin(double* , int );
static int findmax(double* , int );
static void swapChi2values(GenCurveFitInternalsPtr , int i, int j);
static int swapPopVector(GenCurveFitInternalsPtr , int popsize, int i, int j);
static void ensureConstraints(GenCurveFitInternalsPtr , GenCurveFitRuntimeParamsPtr );
static void createTrialVector(GenCurveFitInternalsPtr , GenCurveFitRuntimeParamsPtr , int );
static int setPopVectorFromPVector(GenCurveFitInternalsPtr ,double* , int , int );
static int optimiseloop(GenCurveFitInternalsPtr , GenCurveFitRuntimeParamsPtr );
static int CleanUp(GenCurveFitInternalsPtr);
static int ReturnFit(GenCurveFitInternalsPtr, GenCurveFitRuntimeParamsPtr);
static int calcChi2(double*, double*, double*, long, double*,int);
static int calcMaxLikelihood(double* , double* , double* , long , double* , int );
static int calcRobust(double* , double* , double* , long , double* , int );
static int init_GenCurveFitInternals(GenCurveFitRuntimeParamsPtr, GenCurveFitInternalsPtr);
static int identicalWaves(waveHndl , waveHndl , int* );
static int subtractTwoWaves(waveHndl, waveHndl   );
static int isWaveDisplayed(waveHndl, int *);
static long numInArray3SD(double*, double , long);
static double arrayMean(double* , long );
static double arraySD(double* , long );
static int getRange (WaveRange ,long *,long *);
static double roundDouble(double);
static waveStats getWaveStats(double*,long,int);
static void checkLimits(GenCurveFitInternalsPtr,GenCurveFitRuntimeParamsPtr);
static int WindowMessage(void);
/*
	ExecuteGenCurveFit performs the genetic curvefitting routines
	returns 0 if no error
	returns errorcode otherwise
*/
static int
ExecuteGenCurveFit(GenCurveFitRuntimeParamsPtr p)
{
	/* the function that is called by IGOR. Here's where we farm the work out to different places.*/

	/*
	err carries the errors for all the operations
	err2 carries the error code if we still want to return err, but we need to finish off
		something else first.	
	*/
	int err = 0, err2=0;
	//variables listed below are purely for outputs sake.
	char varname[MAX_OBJ_NAME+1];
	double t1,t2;
	long lt1=0;
	char note[200],note_buffer1[MAX_WAVE_NAME+1],note_buffer2[MAX_WAVE_NAME+1],cmd[MAXCMDLEN+1];
	int output,ii,isDisplayed;
	
	/*
	GenCurveFitInternals carries the internal data structures for doing the fitting.
	*/
	GenCurveFitInternals goi;
	//initialise the structure to be zero

	memset(&goi, 0, sizeof(goi));

	if( igorVersion < 503 )
		return REQUIRES_IGOR_500;
	
	strcpy(cmd,"");
	strcpy(varname, "V_Fiterror");
	if(FetchNumVar(varname, &t1, &t2)!=-1){
		if(!err){
			lt1 = 0;
		} else {
			lt1 = 1;
		}
		err = 0;
		err2 = SetIgorIntVar(varname, lt1, 1);
	}	

	/*
	Genetic Optimisation uses a lot of random numbers, we are seeding the generator here.
	*/
	srand( (unsigned)time( NULL ) );
	
	/*
	checkInput checks the input that IGOR sends to the XOP.  If everything is correct it returns 0, 
	else it returns an error.  Errors can be caused by, e.g. different x and y wave lengths, etc.
	*/
	if(!err){
		err = checkInput(p,&goi);
	}
	
	/*
	init_GenCurveFitInternals sets up the internal data arrays in the GenCurveFitInternals structure.  It holds
	copies of the datapoints being fitted, arrays of the fitting structures, etc.  It calls malloc
	several times to set aside memory for all this.  If this procedure works without a hitch then the function
	returns 0.
	*/
	if(!err){
		err = init_GenCurveFitInternals(p,&goi);
	}
	/*
	optimiseloop does the Differential Evolution, according to Storn and Price.  When this returns 0, then 
	you have the best fit in the GenCurveFitInternals structure.  Otherwise it returns an error code.  If the user aborts
	then the FIT_ABORTED error code is returned, but it is still possible to retrieve the best solution so far
	*/
	if(!err){
		err = optimiseloop(&goi, p);
	}
	/*
	if there are no errors, or if the user aborted, then return the best fit.
	If the data is displayed in the top graph append the fitcurve to the top graph
	*/
	if((err ==0 || err == FIT_ABORTED)){
		err2 = ReturnFit( &goi,  p);
		
		err2 = isWaveDisplayed(p->dataWave.waveH,&isDisplayed);
		if(isDisplayed && goi.numVarMD == 1){
			err2 = isWaveDisplayed(goi.OUT_data,&isDisplayed);
			if(!isDisplayed){
				strcpy(cmd,"");
				strcpy(cmd,"appendtograph/w=$(winname(0,1)) ");
				WaveName(goi.OUT_data,&note_buffer1[0]);
				strcat(cmd,&note_buffer1[0]);

				if(p->DFlagEncountered && p->XFlagEncountered){
					WaveName(p->XFlag_xx,&note_buffer2[0]);
					strcat(cmd," vs ");
					strcat(cmd,&note_buffer2[0]);
				}
				if(err = XOPSilentCommand(&cmd[0]))
					return err;
			}
		}
	}

	/*this section sets history and global variables
	V_Chisq
	V_Fiterror
	If there are no errors returned above, then V_Chisq is produced in the current datafolder.
	V_fiterror is for if there is a problem with the fitting.  
	If this global variable exists in IGOR at runtime, and there is no XOPerror then V_fiterror = 0.  
	If there is an XOPerror, bit 0 of V_fiterror is set. However, the XOP will return gracefully to IGOR,
	allowing the user that called it to detect this and carry on.
	In normal situations V_fiterror may not exist, so the GenCurveFit XOP will return an error message.
	*/
	if(!err){
		strcpy(cmd,"");
		strcpy(varname, "V_Chisq");
		t1 = *(goi.chi2Array);
		t2 = 0;
		err2 = SetIgorFloatingVar(varname, &t1, 1);
		strcpy(cmd,"");
		strcpy(varname, "V_fitIters");
		t1 = (goi.V_numfititers);
		t2 = 0;
		err2 = SetIgorFloatingVar(varname, &t1, 1);
		strcpy(cmd,"");
		strcpy(varname, "V_npnts");
		t1 = (goi.unMaskedPoints);
		err2 = SetIgorFloatingVar(varname, &t1, 1);
		strcpy(cmd,"");
		strcpy(varname, "V_nterms");
		t1 = WavePoints(p->coefs);
		err2 = SetIgorFloatingVar(varname, &t1, 1);
		strcpy(cmd,"");
		strcpy(varname, "V_nheld");
		t1 = WavePoints(p->coefs) - goi.numvarparams;
		err2 = SetIgorFloatingVar(varname, &t1, 1);
	}		
	strcpy(cmd,"");
	strcpy(varname, "V_Fiterror");
	if(FetchNumVar(varname, &t1, &t2)!=-1){
		if(!err){
			lt1 = 0;
		} else {
			lt1 = 1;
		}
		err = 0;
		err2 = SetIgorIntVar(varname, lt1, 1);
	}
	/*
	This section puts a copy of the fit parameters into the history area, unless one sets quiet mode.
	*/
	if(!p->QFlagEncountered && (!err || err == FIT_ABORTED) && lt1==0 ){
		if(!err)
			{output = sprintf(note,"_______________________________\rGenetic Optimisation Successful\r");XOPNotice(note);}
		if(err == FIT_ABORTED)
			{output = sprintf(note,"_______________________________\rGenetic Optimisation ABORTED\r");XOPNotice(note);}
		WaveName(p->dataWave.waveH,note_buffer1);
		
		output = sprintf(note,"Fitting: %s to %s\r",note_buffer1,goi.fi.name);XOPNotice(note);
		output = sprintf(note,"V_fitIters = %d; V_Chisq = %g; V_npnts= %d; V_nterms= %d; V_nheld= %d\r",goi.V_numfititers,*(goi.chi2Array),goi.unMaskedPoints,WavePoints(p->coefs),WavePoints(p->coefs) - goi.numvarparams);
		XOPNotice(note);
		for(ii=0;ii<WavePoints(p->coefs);ii+=1){
			output = sprintf(note,"\tw[%d] =\t %g\r",ii,*(goi.gen_coefsCopy+ii));XOPNotice(note);
		}
		output = sprintf(note,"_______________________________\r");XOPNotice(note);
	}
	/*
	freeAllocMem frees all the internal data structures which have had memory allocated to them.
	this is ultra essential for no memory leaks.
	*/
	freeAllocMem(&goi);

	return err;
}

static int
RegisterGenCurveFit(void)
{
	char* cmdTemplate;
	char* runtimeNumVarList;
	char* runtimeStrVarList;

	// NOTE: If you change this template, you must change the GenCurveFitRuntimeParams structure as well.
	cmdTemplate = "GenCurveFit /opt=number:opt /q /n /L=number:destLen /R[=Wave:resid] /meth=number:method /X={Wave:xx[,Wave[49]]}  /D=wave:outputwave /W=wave:weighttype /I=[number:weighttype] /M=wave:maskwave /k={number:iterations, number:popsize, number:km, number:recomb} /TOL=number:tol name:fitfun, waveRange:dataWave, wave:coefs, string:holdstring, wave:limitswave";
	runtimeNumVarList = "";
	runtimeStrVarList = "";
	return RegisterOperation(cmdTemplate, runtimeNumVarList, runtimeStrVarList, sizeof(GenCurveFitRuntimeParams), (void*)ExecuteGenCurveFit, 0);
}

static int
RegisterOperations(void)		// Register any operations with Igor.
{
	int result;
	
	// Register XOP1 operation.
	if (result = RegisterGenCurveFit())
		return result;
	
	// There are no more operations added by this XOP.
		
	return 0;
}

/*	XOPEntry()

	This is the entry point from the host application to the XOP for all
	messages after the INIT message.
*/
static void
XOPEntry(void)
{	
	long result = 0;
	
	if (WindowMessage())							// Handle all messages related to XOP window.
		return;
	
	switch (GetXOPMessage()) {
		// We don't need to handle any messages for this XOP.
	}
	SetXOPResult(result);
}

/*	main(ioRecHandle)

	This is the initial entry point at which the host application calls XOP.
	The message sent by the host must be INIT.
	
	main does any necessary initialization and then sets the XOPEntry field of the
	ioRecHandle to the address to be called for future messages.
*/
HOST_IMPORT void
main(IORecHandle ioRecHandle){
	int result;
	
	XOPInit(ioRecHandle);							// Do standard XOP initialization.

	SetXOPEntry(XOPEntry);							// Set entry point for future calls.
	
	//CreateXOP Window Class for the update window.  This is not needed for Mac usage.
	#ifdef _WINDOWS_
	{
		if (result = CreateXOPWindowClass()) {
			SetXOPResult(result);
			return;
		}
	}
	#endif

	if (result = RegisterOperations()) {
		SetXOPResult(result);
		return;
	}
	
	SetXOPResult(0);
}



/*
this function checks the input from all the parameters IGOR gives it.
returns 0 if error
returns error code otherwise
*/
int checkInput(GenCurveFitRuntimeParamsPtr p, GenCurveFitInternalsPtr goiP){
	long numdimensions;
	long dimsize[MAX_DIMENSIONS+1];
	long  coefsdimsize = 0;
	int  err =0;
	int badParameterNumber;
	int sameWave;
	long numzeros = 0;
	char *comparison = NULL;
	double* dpL = NULL;
	double* dpC = NULL;
	char *holdstr = NULL;
	int requiredParameterTypes[MAX_MDFIT_SIZE+2];
	int METH=0, ii=0;

	//get the current datafolder
	if(err = GetCurrentDataFolder(&goiP->cDF)){
		goto done;
	}

	//start analysing the fitfunction
	goiP->isAAO = 0;
	goiP->numVarMD = -1;

	if (p->fitfunEncountered) {
		//couldn't get function information
		if(err = GetFunctionInfo(p->fitfun, &goiP->fi))
			goto done;

		// function is not proper fitfunc
		if(goiP->fi.totalNumParameters < 2 || goiP->fi.totalNumParameters > MAX_MDFIT_SIZE){
			err = INVALID_FIT_FUNC;
			goto done;
		}

		//first argument is always a wave containing the coefficients.
		requiredParameterTypes[0] = WAVE_TYPE;

		for(ii = 1 ; ii <goiP->fi.totalNumParameters ; ii+=1){
			requiredParameterTypes[ii] = NT_FP64;
		}
		goiP->numVarMD = goiP->fi.totalNumParameters-1;
		goiP->isAAO = 0;
		err = CheckFunctionForm(&goiP->fi,goiP->fi.totalNumParameters,requiredParameterTypes,&badParameterNumber,-1);
		
		if(err){ //it may be all-at-once
			for(ii = 0 ; ii <goiP->fi.totalNumParameters ; ii+=1)
				requiredParameterTypes[ii] = WAVE_TYPE;
			goiP->numVarMD = goiP->fi.totalNumParameters-2;
			goiP->isAAO = 1;
			if(err = CheckFunctionForm(&goiP->fi,goiP->fi.totalNumParameters,requiredParameterTypes,&badParameterNumber,-1)){
				err = INVALID_FIT_FUNC;					
				goto done;
			}
		}
		//fit function always has to return a number, not complex or text, even if its all-at-once.
		if(goiP->fi.returnType != NT_FP64){
			err = FITFUNC_DOESNT_RETURN_NUMBER;
			goto done;
		}
	} else {
		//no fit function was specified.
		err = FITFUNC_NOT_SPECIFIED;
		goto done;
	}

	if(p->LFlagEncountered){
		if(IsNaN64(&p->LFlag_destlen) || IsINF64(&p->LFlag_destlen) || p->LFlag_destlen<1){
			err = BAD_FLAG_NUM;
			goto done;
		}
	} else {
		p->LFlag_destlen = 200;
	}

	if (p->dataWaveEncountered) {
		//if y wave doesn't exist go no further
		if(p->dataWave.waveH == NULL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}

		//the ywave has to be SP or DP.
		if(!((WaveType(p->dataWave.waveH) == NT_FP64) || (WaveType(p->dataWave.waveH) == NT_FP32))){
			err = REQUIRES_SP_OR_DP_WAVE;
			goto done;
		}

		//check how many points are in the wave
		if(err = MDGetWaveDimensions(p->dataWave.waveH, &numdimensions,dimsize)) 
			goto done;
		
		goiP->dataPoints = dimsize[0];
		//if the dataWave isn't 1D then we can't fit it.
		if(numdimensions>1){
			err = INPUT_WAVES_NOT_1D;
			goto done;
		}

		//if there are no points to fit, then you can't do anything.
		if(goiP->dataPoints == 0){
			err = INPUT_WAVES_NO_POINTS;
			goto done;
		}
		////we're not going to do the fit if there are any NaN or INFS in the input.
		//if(err = checkNanInf(p->dataWave.waveH)){
		//	err = INPUT_WAVES_CONTAINS_NANINF;
		//	goto done;
		//} 
	}
		
	if (p->coefsEncountered) {
		//if ceofs wave doesn't exist go no further
		if(p->coefs == NIL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}
		//if the coefsWave isn't Double precision
		if(!((WaveType(p->coefs) == NT_FP64) || (WaveType(p->coefs) == NT_FP32))){
			err = REQUIRES_SP_OR_DP_WAVE;
			goto done;
		}
		//check how many points are in the wave
		if(err = MDGetWaveDimensions(p->coefs, &numdimensions,dimsize))
			goto done;
		//if the coefswave isn't 1D then we can't fit it.
		if(numdimensions>1){
			err = INPUT_WAVES_NOT_1D;
			goto done;
		}
		//if there are no coefficients, then you can't do anything.
		if(dimsize[0] == 0){
			err =COEF_HAS_NO_POINTS;
			goto done;
		}
		//all the parameters have to be usable numbers.
		if(err = checkNanInf(p->coefs)){
			err = COEF_HAS_NANINF; 
			goto done;
		}
		coefsdimsize = dimsize[0];
	}
	
	//get the ywave scaling just in case the xwave isn't specified.
	if (err = MDGetWaveScaling(p->dataWave.waveH, ROWS, &goiP->ydelta, &goiP->ystart)) // Get X scaling
		goto done;

	//check if the independent variables are specified.
	if (p->XFlagEncountered) {
		if(p->XFlag_xx == NULL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}
		if(goiP->numVarMD > 1){
			if(err = MDGetWaveDimensions(p->XFlag_xx, &numdimensions,dimsize)) 
				goto done;
			switch(numdimensions){
				case 1:
					if(p->XFlagParamsSet[goiP->numVarMD-1] == 0){
						err =  SPARSE_INDEPENDENT_VARIABLE;
						goto done;
					}
					for(ii=0 ; ii < goiP->numVarMD-1 ; ii+=1){
						if(p->XFlagWaveH[ii] == NULL){
							err = NON_EXISTENT_WAVE;
							goto done;
						}
						//if the xwave isn't Double precision
						if(!((WaveType(p->XFlagWaveH[ii]) == NT_FP64) || (WaveType(p->XFlagWaveH[ii]) == NT_FP32))){
							err = REQUIRES_SP_OR_DP_WAVE;
							goto done;
						}
						//check how many points are in the wave
						if(err = MDGetWaveDimensions(p->XFlagWaveH[ii], &numdimensions,dimsize)) 
							goto done;
						//if the xwave isn't 1D then we can't fit it.
						if(numdimensions>1){
							err = INPUT_WAVES_NOT_1D;
							goto done;
						}
						//if it isn't the same size as the datawave abort.
						if(dimsize[0] != goiP->dataPoints){
							err = WAVES_NOT_SAME_LENGTH;
							goto done;
						}
						//if the xwave contains NaN or INF, then stop.
						if(err = checkNanInf(p->XFlagWaveH[ii])){
							err = INPUT_WAVES_CONTAINS_NANINF; 
							goto done;
						}
					}
					break;
				case 2:
					if(p->XFlagParamsSet[1] != 0){
						err = SPARSE_INDEPENDENT_VARIABLE;
						goto done;
					}
					if(dimsize[0] != goiP->dataPoints){
						err = err = WAVES_NOT_SAME_LENGTH;
						goto done;
					}
					if(dimsize[1] != goiP->numVarMD){
						err = SPARSE_INDEPENDENT_VARIABLE;
						goto done;
					}
					break;
				default:
					err = SPARSE_INDEPENDENT_VARIABLE;
					goto done;
					break;
			}
		} else {	//we are fitting 1D data
			//if the xwave isn't Double precision
			if(!((WaveType(p->XFlag_xx) == NT_FP64) || (WaveType(p->XFlag_xx) == NT_FP32))){
				err = REQUIRES_SP_OR_DP_WAVE;
				goto done;
			}
			//check how many points are in the wave
			if(err = MDGetWaveDimensions(p->XFlag_xx, &numdimensions,dimsize)) 
				goto done;
			//if the ywave isn't 1D then we can't fit it.
			if(numdimensions>1){
				err = INPUT_WAVES_NOT_1D;
				goto done;
			}
			//if it isn't the same size as the ywave abort.
			if(dimsize[0] != goiP->dataPoints){
				err = WAVES_NOT_SAME_LENGTH;
				goto done;
			}
			//if the xwave contains NaN or INF, then stop.
			if(err = checkNanInf(p->XFlag_xx)){
				err = INPUT_WAVES_CONTAINS_NANINF; 
				goto done;
			}
		}
	} else {
		//we're just going to work with the y wave scaling
		//if the scaling of the y wave is buggered up
		if(goiP->numVarMD != 1){
			err = SPARSE_INDEPENDENT_VARIABLE;
			goto done;
		}
		if(IsNaN64(&goiP->ystart) || IsNaN64(&goiP->ydelta) || IsINF64(&goiP->ystart) || IsINF64(&goiP->ydelta)){
			err = SCALING_OF_YWAVE;
			goto done;
		}
	}
	// if the weightwave contains standard deviations then goiP->weighttype=1 otherwise
	// the wave contains weighting values, goiP->weighttype = 0.
	// if no weight wave is specified then goiP->weighttype = -1.
	if(p->IFlagEncountered){
		if(p->IFlagParamsSet[0])
			goiP->weighttype = p->weighttype;
	}  else {
			goiP->weighttype = 0;
	}

	//was there a weight (sd) wave specified?
	if (p->WFlagEncountered) {
		if(p->weights == NULL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}
		//if the weightwave isn't Double precision
		if(!((WaveType(p->weights) == NT_FP64) || (WaveType(p->weights) == NT_FP32))){
			err = REQUIRES_SP_OR_DP_WAVE;
			goto done;
		}
		//check how many points are in the wave
		if(err = MDGetWaveDimensions(p->weights, &numdimensions,dimsize)) 
			goto done;
		//if the weight wave isn't 1D then we can't fit it.
		if(numdimensions>1){
			err = INPUT_WAVES_NOT_1D;
			goto done;
		}
		//if it isn't the same size as the ywave abort.
		if(dimsize[0] != goiP->dataPoints){
			err = WAVES_NOT_SAME_LENGTH;
			goto done;
		}
		//check the weightwave for NaN/INF
		if(err = checkNanInf(p->weights)){
			err = INPUT_WAVES_CONTAINS_NANINF;
			goto done;
		}
		//check if there are any zeros in the weightwave
		//this is because you will get a divide by zero error if chi2 uses the value
		//as a denominator
		if(err = checkZeros(p->weights, &numzeros))
			goto done;
		if(goiP->weighttype == 1 && numzeros>0){
			err = STANDARD_DEV_IS_ZERO;
			goto done;
		}
	} else {
		goiP->weighttype = -1;
	}
	
	//was there a mask wave specified?  Set to 0 or NaN to mask points from a fit.
	if (p->MFlagEncountered) {
		if(p->maskwave == NIL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}
		//if the maskwave isn't Double precision
		if(!((WaveType(p->maskwave) == NT_FP64) || (WaveType(p->maskwave) == NT_FP32))){
			err = REQUIRES_SP_OR_DP_WAVE;
			goto done;
		}
		//check how many points are in the wave
		if(err = MDGetWaveDimensions(p->maskwave, &numdimensions,dimsize)) 
			goto done;
		//if the weight wave isn't 1D then we can't fit it.
		if(numdimensions>1){
			err = INPUT_WAVES_NOT_1D;
			goto done;
		}
		//if it isn't the same size as the ywave abort.
		if(dimsize[0] != goiP->dataPoints){
			err = WAVES_NOT_SAME_LENGTH;
			goto done;
		}
	}

	//check if we are producing residuals.
	if (p->RFlagEncountered) {
		if(p->RFlag_resid != NULL){
			if(!((WaveType(p->RFlag_resid) == NT_FP64) || (WaveType(p->RFlag_resid) == NT_FP32))){
				err = REQUIRES_SP_OR_DP_WAVE;
				goto done;
			}
			//check how many points are in the wave
			if(err = MDGetWaveDimensions(p->RFlag_resid, &numdimensions,dimsize)) 
				goto done;
			//if the ywave isn't 1D then we can't fit it.
			if(numdimensions>1){
				err = INPUT_WAVES_NOT_1D;
				goto done;
			}
			//if it isn't the same size as the ywave abort.
			if(dimsize[0] != goiP->dataPoints){
				err = WAVES_NOT_SAME_LENGTH;
				goto done;
			}
		}
	}

	//these parameters control how the differential evolution operates.
	if (p->KFlagEncountered) {
		//can't have duff genetic optimisation input
		if(IsNaN64(&p->iterations) || IsINF64(&p->iterations) || p->iterations<1){
			err = GenCurveFit_PARS_INCORRECT;
			goto done;
		}
		if(IsNaN64(&p->popsize) || IsINF64(&p->popsize) || p->popsize <1){
			err = GenCurveFit_PARS_INCORRECT;
			goto done;
		}
		if(IsNaN64(&p->km) || IsINF64(&p->km) || p->km<=0 || p->km > 1){
			err = GenCurveFit_PARS_INCORRECT;
			goto done;
		}
		if(IsNaN64(&p->recomb) || IsINF64(&p->recomb) || p->recomb<=0 || p->recomb>1){
			err = GenCurveFit_PARS_INCORRECT;
			goto done;
		}
	} else {
		p->iterations = 100.;
		p->popsize = 20.;
		p->km = 0.5;
		p->recomb = 0.7;
	}

	//the cost function for minimisation is now specified.  
	if(p->METHFlagEncountered){
		METH = (int)p->METHFlag_method;
		switch(METH){
			case 0:		//this will be Chi2
				goiP->METH = METH;
				break;
			case 1:		//robust fitting
				goiP->METH = METH;
				break;
			default:
				err = INCORRECT_COST_FUNCTION;
				goto done;
				break;
		}
	} else {
		goiP->METH = 0;
	}

	//a holdstring is used to work out which parameters are being fitted.  i.e. "0001000111".
	//0=fit, 1=hold
	if (!p->HEncountered) {
	//please specify holdstring
		err = HOLDSTRING_NOT_SPECIFIED;
		goto done;
	} else {
		//if we have a holdstring we want to use it.
		if(p->holdstring !=NULL)
		{
			long len;
			long ii;
			int val;

			len = GetHandleSize(p->holdstring);
			//if specified the holdstring should be the same length as the coefficient wave
			if(len != coefsdimsize){
				err = HOLDSTRING_NOT_RIGHT_SIZE;
				goto done;
			}

			holdstr = (char*)malloc((len+1)*sizeof(char));
			if(holdstr == NULL){
				err = NOMEM;
				goto done;
			}
			comparison = (char*)malloc(2*sizeof(char));
			if(comparison == NULL){
				err = NOMEM;
				goto done;
			}

			*(comparison+1) = '\0';
			//get the holdstring from the operation handle
			if(err = GetCStringFromHandle(p->holdstring,holdstr,len)){
				goto done;
			}
			goiP->numvarparams = 0;
			//we have to check that the holdstring is simply 0 or 1's.
			for(ii = 0L; ii<len ; ii++){
				//if its not a digit its not a correct holdstring
				if(!isdigit(*(holdstr+ii))){
					err = HOLDSTRING_INVALID;
					goto done;
				}
				*comparison = *(holdstr+ii);
				val = atoi(comparison);
				// you may have an invalid holdstring
				if(!(val == 0 || val==1)){
					err = HOLDSTRING_INVALID;
					goto done;
				} else {
				// if the holdstring = '0' then you want to vary that parameter
					if(val == 0)
						goiP->numvarparams +=1;
				}
			}
			//if all the parameters are being held then go no further.
			if(goiP->numvarparams == 0){
				err = ALL_COEFS_BEING_HELD;
				goto done;
			}
		} else {
			//please specify holdstring
			err = HOLDSTRING_NOT_SPECIFIED;
			goto done;
		}
	}

	//the fractional tolerance for stopping the fit.
	if (p->TOLFlagEncountered) {
		if(IsNaN64(&p->tol) || IsINF64(&p->tol) || p->tol<0){
			err = STOPPING_TOL_INVALID;
			goto done;
		}
	} else {
		p->tol = 0.0001;
	}

	// Main parameters.
	if (p->limitswaveEncountered) {
		long len;
		long ii;
		int val;
		long numBytesL,numBytesC;

		//if the limitswave handle doesn't exist.
		if(p->limitswave == NULL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}
		//if the ywave isn't Double precision
		if(!((WaveType(p->limitswave) == NT_FP64) || (WaveType(p->limitswave) == NT_FP32))){
			err = REQUIRES_SP_OR_DP_WAVE;
			goto done;
		}
		//check how many points are in the wave
		if(err = MDGetWaveDimensions(p->limitswave, &numdimensions,dimsize)) 
			goto done;
		//we need an upper and lower boundary.
		if(numdimensions != 2){
			err = LIMITS_WRONG_DIMS;
			goto done;
		}
		//if it isn't the same size as input coefs abort.
		if(dimsize[0] != coefsdimsize){
			err = LIMITS_WRONG_DIMS;
			goto done;
		}
		//if there any Nan/Inf's there will be a problem
		if(err = checkNanInf(p->limitswave)){
			err = INPUT_WAVES_CONTAINS_NANINF;
			goto done;
		}

		//now we need to check that the coefficients lie between the limits and
		//that the limits are sane

		numBytesL = WavePoints(p->limitswave) * sizeof(double); // Bytes needed for copy
		numBytesC = WavePoints(p->coefs) * sizeof(double);

		dpL = (double*)malloc(numBytesL);
		dpC = (double*)malloc(numBytesC);
		if (dpC==NULL || dpL == NULL){
			err = NOMEM;
			goto done;
		}
		if (err = MDGetDPDataFromNumericWave(p->coefs, dpC)) { // Get copy.
			goto done;
		}
		if (err = MDGetDPDataFromNumericWave(p->limitswave, dpL)) { // Get copy.
			goto done;
		}
		//get the holdstring
		len = GetHandleSize(p->holdstring);
		holdstr = (char*)malloc((len+1)*sizeof(char));
		if(holdstr == NULL){
			err = NOMEM;
			goto done;
		}
		comparison = (char*)malloc(2*sizeof(char));
		if(comparison == NULL){
			err = NOMEM;
			goto done;
		}

		*(comparison+1) = '\0';
		if(err = GetCStringFromHandle(p->holdstring,holdstr,len)){
			goto done;
		}
		for(ii = 0L; ii<len ; ii++){
			*comparison = *(holdstr+ii);
			val = atoi(comparison);
			if(val==0){
				//lowerlim must be < upperlim and param must be in between.
				if(p->OPTFlagEncountered && (((long)p->opt) & (long)pow(2,0))){
					if(*(dpC+ii)<*(dpL + ii) || *(dpC+ii) > *(dpL + ii+len) || *(dpL + ii+len) <*(dpL + ii)){
						err = LIMITS_INVALID;
						goto done;
					}
				} else {//it doesn't need to be inbetween because we generate our own values
					if(*(dpL + ii+len) <*(dpL + ii)){
						err = LIMITS_INVALID;
						goto done;
					}
				}
			}
		}
	} else {
		//if you don't have a limits wave you can't do anything
		err = NON_EXISTENT_WAVE;
		goto done;
	}
	
	//DFlag will be the output
	if(p->DFlagEncountered){
		if(p->outputwave == NULL){
			err = NON_EXISTENT_WAVE;
			goto done;
		}
		// the output wave has to be the same size as the input fit wave
		if(WavePoints(p->outputwave) != WavePoints(p->dataWave.waveH)){
			err = OUTPUT_WAVE_WRONG_SIZE;
			goto done;
		}
		// the input waves and output wave shouldn't be the same
		if(err = identicalWaves(p->outputwave,p->coefs,&sameWave)) goto done;
		if(sameWave == 1){
			err = OUTPUT_WAVE_OVERWRITING_INPUT;
			goto done;
		}
		if(err = identicalWaves(p->outputwave,p->dataWave.waveH,&sameWave))	goto done;
		if(sameWave == 1){
			err = OUTPUT_WAVE_OVERWRITING_INPUT;
			goto done;
		}
		if(err = identicalWaves(p->outputwave,p->XFlag_xx,&sameWave))	goto done;
		if(sameWave == 1){
			err = OUTPUT_WAVE_OVERWRITING_INPUT;
			goto done;
		}
		if(err = identicalWaves(p->outputwave,p->limitswave,&sameWave))	goto done;
		if(sameWave == 1){
			err = OUTPUT_WAVE_OVERWRITING_INPUT;
			goto done;
		}
		if(err = identicalWaves(p->outputwave,p->maskwave,&sameWave)) goto done;
		if(sameWave == 1){
			err = OUTPUT_WAVE_OVERWRITING_INPUT;
			goto done;
		}
		if(err = identicalWaves(p->outputwave,p->weights,&sameWave)) goto done;
		if(sameWave == 1){
			err = OUTPUT_WAVE_OVERWRITING_INPUT;
			goto done;
		}
	}
// free all memory allocated during this function
done:
	if(comparison != NULL)
		free(comparison);
	if(holdstr != NULL)
		free(holdstr);
	if(dpC !=NULL)
		free(dpC);
	if(dpL !=NULL)
		free(dpL);
	return err;
}

static int
//this will return if a wave contains NaN or INF.
checkNanInf(waveHndl wav){
//this check examines to see if there are any NaN/Infs in a wave
//this is really important if you want to calculate Chi2.
	int err = 0;
	long ii;
	double *dp=NULL;
	long points;
	if(wav==NULL)
		return NON_EXISTENT_WAVE;
	points = WavePoints(wav);
	dp = (double*)malloc(sizeof(double)*WavePoints(wav));
	if(dp==NULL)
		return NOMEM;

	if(err = MDGetDPDataFromNumericWave(wav,dp))
		goto done;

	for(ii=0 ; ii<points ; ii+=1)
		if(IsNaN64(dp+ii) || IsINF64(dp+ii)) break;


	
	if(err>0)
		err = INPUT_WAVES_CONTAINS_NANINF;
done:
	if(dp!=NULL)
		free(dp);
	return err;
}


/*
	checkZeros sees how many zero points are in the wave
	returns 0 if no error
	returns errorcode otherwise
*/
static int
checkZeros(waveHndl wavH,long* numzeros){
	int result = 0;
	long numBytes;
	double* dp = NULL;
	long points,ii;
	points = WavePoints(wavH);

	numBytes = points * sizeof(double); // Bytes needed for copy
	dp = (double*)malloc(numBytes);
	
	if (dp==NULL)
		return NOMEM;
	
	if (result = MDGetDPDataFromNumericWave(wavH, dp)) { // Get copy.
		free(dp);
		return result;
	}
	
	for(ii=0 ; ii<points ; ii+=1){
		if(*(dp+ii)==0)
			numzeros+=1;
	}
	if(dp != NULL)
		free(dp);
	return result;
}



/*
	calcMaxLikelihood calculates Maximum Likelihood as a cost function for the fit
	dataObs		-	array containing the experimental data
	dataTemp		-	array containing theoretical model
	ysig		-	array containing the weighting
	len			-	the number of fit points
	*chi2		-	the calculated chi2 value
	weighttype	-	0 if ysig is weightarray, 1 if ysig is standard deviation
	returns 0 if no error
	returns errorcode otherwise
*/
static int
calcMaxLikelihood(double* dataObs, double* dataTemp, double* dataSig, long len, double* chi2, int weighttype){
	
	int err = 0;
	long ii;
	double abserr=0;
	if(dataObs == NULL || dataTemp == NULL || dataSig  == NULL)
		return UNSPECIFIED_ERROR;

	*chi2 = 0;
	
	for(ii=0 ; ii<len ; ii+=1){
		if(*(dataObs+ii) ==0 || *(dataTemp+ii)==0){
			abserr = *(dataTemp+ii) - *(dataObs+ii);
		} else {
			abserr = *(dataTemp+ii)-*(dataObs+ii)+(*(dataObs+ii)* log((*(dataObs+ii)/(*(dataTemp+ii)))));
		}
		*chi2 += abserr;
	}
	*chi2 *= 2;
	return err;
}


/*
	calcChi2 calculates chi2 for the fit
	yobs		-	array containing the experimental data
	dataTemp		-	array containing theoretical model
	ysig		-	array containing the weighting
	len			-	the number of fit points
	*chi2		-	the calculated chi2 value
	weighttype	-	0 if ysig is weightarray, 1 if ysig is standard deviation
	returns 0 if no error
	returns errorcode otherwise
*/
static int
calcChi2(double* dataObs, double* dataTemp, double* dataSig, long len, double* chi2, int weighttype){
	
	int err = 0;
	long ii;
	double abserr=0;
	if(dataObs == NULL || dataTemp == NULL || dataSig  == NULL)
		return UNSPECIFIED_ERROR;

	*chi2 = 0;
	
	for(ii=0 ; ii<len ; ii+=1){
		abserr = (*(dataObs+ii)-*(dataTemp+ii));
		switch(weighttype){
			case -1:
				break;
			case 0:
				abserr *= (*(dataSig+ii));
				break;
			case 1:
				abserr /= (*(dataSig+ii));
				break;
		}
		*chi2 += pow(abserr,2);
	}
	return err;
}




/*
	calcRobust calculates absolute errors for the fit
	yobs		-	array containing the experimental data
	dataTemp		-	array containing theoretical model
	ysig		-	array containing the weighting
	len			-	the number of fit points
	*chi2		-	the calculated chi2 value
	weighttype	-	0 if ysig is weightarray, 1 if ysig is standard deviation
	returns 0 if no error
	returns errorcode otherwise
*/
static int
calcRobust(double* dataObs, double* dataTemp, double* dataSig, long len, double* chi2, int weighttype){
	
	int err = 0;
	long ii;
	double abserr=0;
	if(dataObs == NULL || dataTemp == NULL || dataSig  == NULL)
		return UNSPECIFIED_ERROR;

	*chi2 = 0;
	
	for(ii=0 ; ii<len ; ii+=1){
		abserr = (*(dataObs+ii)-*(dataTemp+ii));
		switch(weighttype){
			case 0:
				abserr *= (*(dataSig+ii));
				break;
			case 1:
				abserr /= (*(dataSig+ii));
				break;
		}
		*chi2 += fabs(abserr);
	}
	return err;
}





/*
	init_GenCurveFitInternals initialises the GenCurveFitInternals structure
	returns 0 if no error
	returns errorcode otherwise
*/
static int
init_GenCurveFitInternals(GenCurveFitRuntimeParamsPtr p, GenCurveFitInternalsPtr goiP){
	int err = 0, minpos,maxpos;
	long len;
	char *holdstr = NULL;
	long ii,jj,kk;
	char comparison[2];
	long dimensionSizes[MAX_DIMENSIONS+1],numdimensions;
	double value[2];
	long indices[MAX_DIMENSIONS];
	double bot,top;
	double chi2;
	long timeOutTicks=0;
	char xwavename[MAX_WAVE_NAME+1];
	char datawavename[MAX_WAVE_NAME+1];
	char reswavename[MAX_WAVE_NAME+1];
	char datawavestring[MAX_WAVE_NAME+1];
	char cmd[MAXCMDLEN];
	char letter[3];
	int toDisplay=0;
	double temp1=0;
	long temp;
	waveStats wavStats;

	//initialise the chi2value
	goiP->chi2 = -1;
	
	//initialise an array to hold the parameters that are going to be varied.
	goiP->varparams = (int*) malloc(goiP->numvarparams*sizeof(int));
	//the total number of vectors in the population
	goiP->totalpopsize = goiP->numvarparams * (int)p->popsize;

	if(goiP->varparams == NULL){
		err = NOMEM;
		goto done;
	}
	
	/*
		Following section works out which parameters are going to vary
	*/
	len = GetHandleSize(p->holdstring);
	holdstr = (char*)malloc((len+1)*sizeof(char));
	if(holdstr == NULL){
		err = NOMEM;
		goto done;
	}
	comparison[1] = '\0';
	if(err = GetCStringFromHandle(p->holdstring,holdstr,len))
		goto done;
	jj=0;
	for(ii = 0L; ii<len ; ii++){
		comparison[0] = *(holdstr+ii);
		if(atoi(comparison)==0){
			*(goiP->varparams+jj)=ii;
			jj+=1;
		}
	}
	
	/*
		goiP->temp is a utility array the same size as the input data
		this needs to be specified at the top of the function
	*/
	goiP->temp = (double*)malloc(WavePoints(p->dataWave.waveH) * sizeof(double));
	if (goiP->temp == NULL){
		err = NOMEM;
		goto done;
	}

	/* get a full copy of the datawave */
	goiP->dataObsFull = (double*)malloc(WavePoints(p->dataWave.waveH) *sizeof(double));
	if (goiP->dataObsFull == NULL){
		err = NOMEM;
		goto done;
	}
	//get a copy of all the datawave.  This is so we can fill dataobs
	if (err = MDGetDPDataFromNumericWave(p->dataWave.waveH, goiP->dataObsFull)) // Get copy.
		goto done;

	/*
		goiP->mask contains an array copy of the mask wave
	*/
	goiP->mask = (double*)malloc(WavePoints(p->dataWave.waveH) * sizeof(double));
	if (goiP->mask == NULL){
		err = NOMEM;
		goto done;
	}

	/*
		if there is a range specified then we're fitting a subset of ywave
	*/
	if(p->dataWave.rangeSpecified){
			//the range was specified in point terms
			if(!p->dataWave.isPoint){
				err = SUBRANGE_SPECIFIED_ASX;
				goto done;
			} else {
				goiP->startPoint = (long)roundDouble(p->dataWave.startCoord);
				goiP->endPoint = (long)roundDouble(p->dataWave.endCoord);
				if(goiP->startPoint>goiP->endPoint){
					temp = goiP->startPoint;
					goiP->startPoint = goiP->endPoint;
					goiP->endPoint = temp;
				}
				if(goiP->startPoint<0)
					goiP->startPoint = 0;
				if(goiP->endPoint>WavePoints(p->dataWave.waveH)-1)
					goiP->endPoint=WavePoints(p->dataWave.waveH)-1;
			}
		} else {
			//if there is no range specified then we'll use the entire range
			goiP->startPoint = 0;
			goiP->endPoint = WavePoints(p->dataWave.waveH)-1;
	}
	/*
		use the mask wave and the waverange specified to work out the points we need to fit
	*/
	goiP->unMaskedPoints = WavePoints(p->dataWave.waveH);
	if(p->MFlagEncountered){
		if(err = MDGetDPDataFromNumericWave(p->maskwave, goiP->mask)) // Get copy.
			goto done;
	} else {
		//there was no mask wave specfied, use unit weighting
		for(ii = 0 ; ii< WavePoints(p->dataWave.waveH) ; ii+=1)
			*(goiP->mask + ii) = 1;
	}
	/* 
		set up the mask array
		need to correct goiP->unMaskedPoints as we go along, which specifies how many unmasked points there will be in the fit 
	*/
	for(ii=0;ii<WavePoints(p->dataWave.waveH);ii+=1){
		temp1 = *(goiP->mask+ii);
		if(*(goiP->mask+ii)==0 || IsNaN64(goiP->mask+ii) || ii < goiP->startPoint || ii>goiP->endPoint || IsNaN64(goiP->dataObsFull+ii) || IsINF64(goiP->dataObsFull+ii)){
			goiP->unMaskedPoints-=1;
			*(goiP->mask+ii)=0;
		}
	}

	//you can't fit the data if there's no fit points to be used.
	if(goiP->unMaskedPoints <1){
		err = INPUT_WAVES_NO_POINTS;
		goto done;
	}

	//now make the dataCalcwave in the current datafolder
	dimensionSizes[0] = goiP->unMaskedPoints;
	dimensionSizes[1] = 0;
	dimensionSizes[2] = 0;
	if(err = MDMakeWave(&goiP->dataCalc,"GenCurveFit_dataCalc",goiP->cDF,dimensionSizes,NT_FP64, 1))
		goto done;
	
	if(goiP->isAAO){
		for(ii=0 ; ii<goiP->numVarMD ; ii+=1){
			sprintf(letter,"%i",ii);
			strcpy(xwavename,"GenCurveFit_xcalc");
			strcat(&xwavename[0],&letter[0]);
			if(err = MDMakeWave(&goiP->xcalc[ii],xwavename,goiP->cDF,dimensionSizes,NT_FP64, 1))
				goto done;
		}
	}
	
	////create a utility wave that will contains the x range of the original ywave
	dimensionSizes[0] = goiP->dataPoints;
	for(ii=0 ; ii<goiP->numVarMD ; ii+=1){
		strcpy(letter,"");
		sprintf(letter,"%i",ii);		
		strcpy(xwavename,"GenCurveFit_fullExtentOfData0");
		strcat(&xwavename[0],&letter[0]);
		if(err = MDMakeWave(&goiP->fullExtentOfData[ii],xwavename,goiP->cDF,dimensionSizes,NT_FP64, 1))
			goto done;
	}


	
	////make the temporary coefficients in the current datafolder
	dimensionSizes[0] = WavePoints(p->coefs);
	if(err = MDMakeWave(&goiP->GenCurveFitCoefs,"GenCurveFit_coefs",goiP->cDF,dimensionSizes,NT_FP64, 1))
		goto done;

	//initialise population vector
	goiP->gen_populationvector = (double**)malloc2d(goiP->totalpopsize,goiP->numvarparams,sizeof(double));
	if(goiP->gen_populationvector == NULL){
		err = NOMEM;
		goto done;
	}
	//initialise Chi2array
	goiP->chi2Array = (double*)malloc(goiP->totalpopsize*sizeof(double));
	if(goiP->chi2Array == NULL){
		err = NOMEM;
		goto done;
	}
	//initialise the trial vector
	goiP->gen_trial = (double*)malloc(goiP->numvarparams*sizeof(double));
	if(goiP->gen_trial == NULL){
		err = NOMEM;
		goto done;
	}
	//initialise the bprime vector
	goiP->gen_bprime = (double*)malloc(goiP->numvarparams*sizeof(double));
	if(goiP->gen_trial == NULL){
		err = NOMEM;
		goto done;
	}
	//initialise the pvector
	goiP->gen_pvector = (double*)malloc(goiP->numvarparams*sizeof(double));
	if(goiP->gen_pvector == NULL){
		err = NOMEM;
		goto done;
	}
	//initialise space for a full array copy of the coefficients
	goiP->gen_coefsCopy = (double*)malloc(WavePoints(p->coefs)*sizeof(double));
	if(goiP->gen_coefsCopy == NULL){
		err = NOMEM;
		goto done;
	}
	//put the coefficients into the temporary space
	if(err = MDGetDPDataFromNumericWave(p->coefs, goiP->gen_coefsCopy))
		goto done;

	//initialise space for an array containing the unmasked fitpoint ydata 
	goiP->dataObs = (double*)malloc(goiP->unMaskedPoints * sizeof(double));
	if (goiP->dataObs == NULL){
		err = NOMEM;
		goto done;
	}

	//now fill up the dataObs array, if a point isn't being masked
	jj=0;
	for(ii=0;ii<WavePoints(p->dataWave.waveH);ii+=1){
		if(!(*(goiP->mask+ii) == 0 || IsNaN64(goiP->mask+ii))){
			*(goiP->dataObs+jj) = *(goiP->dataObsFull+ii);
			jj+=1;
		}
	}

	//initialise array space for putting the calculated model in 
	goiP->dataTemp = (double*)malloc(goiP->unMaskedPoints * sizeof(double));
	if (goiP->dataTemp == NULL){
		err = NOMEM;
	    goto done;
	}
	//initialise array space for putting the limits in
	goiP->limits = (double*)malloc(WavePoints(p->limitswave) * sizeof(double));
	if (goiP->limits == NULL){
		err = NOMEM;
		goto done;
	}
	//put the limits in the dedicated limits array
	if (err = MDGetDPDataFromNumericWave(p->limitswave, goiP->limits))// Get copy.
		goto done;
	
	//initialise space for the weighting data
	goiP->dataSig = (double*)malloc(goiP->unMaskedPoints * sizeof(double));
	if (goiP->dataSig == NULL){
		err = NOMEM;
		goto done;
	}
	/*
		this section initialises the weightwave, except for those that are masked
		if there is no weightwave specified then set the weight wave to unity
	*/
	if(p->WFlagEncountered){
		if (err = MDGetDPDataFromNumericWave(p->weights, goiP->temp)) // Get copy.
			goto done;
		jj=0;
		for(ii=0;ii<WavePoints(p->dataWave.waveH);ii+=1){
			if(!(*(goiP->mask+ii) == 0 || IsNaN64(goiP->mask+ii))){
				*(goiP->dataSig+jj) = *(goiP->temp+ii);
				jj+=1;
			}
		}
	} else {
		for(ii = 0 ; ii< goiP->unMaskedPoints ; ii+=1){
			*(goiP->dataSig+ii)=1;
		}
	}

	//initialise array space for x values
	goiP->independentVariable = (double*)malloc(goiP->unMaskedPoints*goiP->numVarMD*sizeof(double));
	if (goiP->independentVariable == NULL){
		err = NOMEM;
		goto done;
	}
	goiP->allIndependentVariable = (double*)malloc(goiP->dataPoints*goiP->numVarMD*sizeof(double));
	if (goiP->allIndependentVariable == NULL){
		err = NOMEM;
		goto done;
	}

	/*
		if there was an xwave specified then fill up the temporary x array
		with the unmasked points from the x-wave, otherwise use waveform scaling of ydata.
		Either way, fill goiP->fullExtentOfData with the total range of x-values.
	*/
	if(p->XFlagEncountered){
		if(err = MDGetWaveDimensions(p->XFlag_xx, &numdimensions,dimensionSizes)) 
			goto done;
		if(goiP->numVarMD > 1 && numdimensions == 1){
			if (err = MDGetDPDataFromNumericWave(p->XFlag_xx, goiP->allIndependentVariable))// Get copy.
				goto done;
			for(ii=1 ; ii < goiP->numVarMD ; ii+=1){
				if (err = MDGetDPDataFromNumericWave(p->XFlagWaveH[ii-1], goiP->allIndependentVariable+(ii*goiP->dataPoints)))// Get copy.
					goto done;
			}
		} else {
			if (err = MDGetDPDataFromNumericWave(p->XFlag_xx, goiP->allIndependentVariable))// Get copy.
				goto done;
		}
		jj=0;
		for(ii=0 ; ii<goiP->dataPoints ; ii+=1){
			if(!(*(goiP->mask+ii) == 0 || IsNaN64(goiP->mask+ii))){
				for(kk=0 ; kk < goiP->numVarMD ; kk+=1){
					*(goiP->independentVariable+(kk*goiP->unMaskedPoints)+jj) = *(goiP->allIndependentVariable+(kk*goiP->dataPoints)+ii);
				}
				jj+=1;
			}
		}
	} else {	
		//by now the program should've aborted if you haven't specified xwaves and you
		//are fitting multivariate data
		jj=0;
		for(ii=0 ; ii<WavePoints(p->dataWave.waveH);ii+=1){
			*(goiP->allIndependentVariable+ii) = goiP->ystart + ((double)ii)*goiP->ydelta;
			if(!(*(goiP->mask+ii) == 0 || IsNaN64(goiP->mask+ii))){
				*(goiP->independentVariable+jj) = goiP->ystart + ((double)ii)*goiP->ydelta;
				jj+=1;
			}
		}
	}
	for(ii=0; ii<goiP->numVarMD ; ii+=1){
		if(goiP->fullExtentOfData[ii] == NULL){
			err = NOWAV;
			goto done;
		}
		if (err = MDStoreDPDataInNumericWave(goiP->fullExtentOfData[ii],goiP->allIndependentVariable+(ii*goiP->dataPoints)))//put the full extent of x vals into the utilitywave
			goto done;
	}
	
	//store the x array in an x wave used to calculate the theoretical model, but only if you are fitting all at once functions
	//creating these waves is necessary for all-at-once fits.
	if(goiP->isAAO){
		for(ii=0; ii<goiP->numVarMD ; ii+=1){
			if (err = MDStoreDPDataInNumericWave(goiP->xcalc[ii],goiP->independentVariable+(ii*goiP->unMaskedPoints)))//put the full extent of x vals into the utilitywave
				goto done;
		}
	}

/*	setup output
	if the Dflag is set, then that wave needs to be the same length as the original ywave.  If its not an error
	will have already been returned.  If the flag is set, then no Xwave will be produced, as you can use the original X-wave.
	if there is no flag set, then we will return the fit in new waves called coef_ywavename, fit_ywavename
	BUT BEWARE, YOU MAY BE USING WAVESCALING.
*/
	WaveName(p->dataWave.waveH,datawavestring);
	strcpy(datawavename,"fit_");
	strcpy(xwavename,"fitx_");
	strcpy(reswavename,"res_");
	for(ii=0;ii<MAX_WAVE_NAME-4;ii+=1){
		letter[0] = datawavestring[ii];
		datawavename[ii+4] =letter[0];
		xwavename[ii+5] =letter[0];
		reswavename[ii+4] = letter[0];
	}
	dimensionSizes[1] = 0;
	dimensionSizes[2] = 0;
	
	if(!p->DFlagEncountered){		//if there is no destination wave specified
		if(goiP->numVarMD == 1){	//and if the data is 1D
			dimensionSizes[0] = (long)p->LFlag_destlen;
			if(err = MDMakeWave(&goiP->OUT_data,datawavename,goiP->cDF,dimensionSizes,NT_FP64, 1))
				goto done;
			minpos = findmin(goiP->allIndependentVariable,goiP->dataPoints);
			maxpos = findmax(goiP->allIndependentVariable,goiP->dataPoints);
			temp1 = *(goiP->allIndependentVariable+maxpos)-*(goiP->allIndependentVariable+minpos);
			temp1 /= floor(p->LFlag_destlen)-1;
				
			if(err = MDSetWaveScaling(goiP->OUT_data, ROWS, &temp1,goiP->allIndependentVariable+minpos))
				goto done;
			if(err = MDMakeWave(&goiP->tempWaveHndl_OUTx,xwavename,goiP->cDF,dimensionSizes,NT_FP64, 1))
				goto done;
			goiP->OUT_x[0] = goiP->tempWaveHndl_OUTx;
			
			for(ii=0 ; ii<(long)p->LFlag_destlen ; ii+=1){
				indices[0] = ii;
				value[0] = *(goiP->allIndependentVariable+minpos)+((double)ii)*temp1;
				if(err = MDSetNumericWavePointValue(goiP->OUT_x[0], indices, value))
					goto done;
			}
		} else {		//no destination wave and data is MD
				dimensionSizes[0] = goiP->dataPoints;
				if(err = MDMakeWave(&goiP->OUT_data,datawavename,goiP->cDF,dimensionSizes,NT_FP64, 1))
					goto done;
				for(ii=0;  ii<MAX_MDFIT_SIZE ; ii+=1) 
					goiP->OUT_x[ii] = goiP->fullExtentOfData[ii];
		}	
	} else {		//destination wave specified
		for(ii=0;  ii<MAX_MDFIT_SIZE ; ii+=1)
			goiP->OUT_x[ii] = goiP->fullExtentOfData[ii];
			goiP->OUT_data = p->outputwave;	
	}

	if(p->RFlagEncountered){
		if(p->RFlag_resid != NULL){
			goiP->OUT_res = p->RFlag_resid;
		} else {
			dimensionSizes[1] = 0;
			dimensionSizes[0] = WavePoints(p->dataWave.waveH);
			if(err = MDMakeWave(&goiP->OUT_res,reswavename,goiP->cDF,dimensionSizes,NT_FP64, 1))
				goto done;
		}
	}

	//if you are doing updates, then append fit output to the topgraph (if data is shown there)
	if(!p->NFlagEncountered){
		//window for displaying output
		gTheWindow = CreateXOPWindow();
		if(gTheWindow == NULL){
			err = UNSPECIFIED_ERROR;
			return err;
		}

		if(goiP->numVarMD == 1){
			if(err = isWaveDisplayed(p->dataWave.waveH,&toDisplay))
				goto done;
			if(toDisplay){
				if(err = isWaveDisplayed(goiP->OUT_data,&toDisplay))
					goto done;
				if(!toDisplay){
					strcpy(cmd,"appendtograph/w=$(winname(0,1)) ");
					WaveName(goiP->OUT_data,&datawavename[0]);
					strcat(cmd,&datawavename[0]);

					if(p->DFlagEncountered){
						if(p->XFlagEncountered){
							WaveName(p->XFlag_xx,&xwavename[0]);
						} else {
							WaveName(goiP->OUT_x[0],&xwavename[0]);
						}
						strcat(cmd," vs ");
						strcat(cmd,&xwavename[0]);
					}
					if(err = XOPSilentCommand(&cmd[0]))
						goto done;
				}
			}
		}
	}

	//initialise population vector guesses, from between the limits
	for(ii=0; ii<goiP->totalpopsize ; ii+=1){
		for(jj=0 ; jj<goiP->numvarparams ; jj+=1){
			bot = *(goiP->limits+*(goiP->varparams+jj));
			top = *(goiP->limits+*(goiP->varparams+jj)+WavePoints(p->coefs));
			goiP->gen_populationvector[ii][jj] = randomDouble(bot,top);
		}
	}
	
	//if bit 0 of p->opt is set, then the initial guesses are used for the fit.
	if(p->OPTFlagEncountered && (((long)p->opt) & (long)pow(2,0))){
		for(jj=0 ; jj<goiP->numvarparams ; jj+=1){
			ii = *(goiP->varparams+jj);
			goiP->gen_populationvector[0][jj] = *(goiP->gen_coefsCopy+ii);
		}
	}

	//initialise Chi2array
	for(ii=0; ii<goiP->totalpopsize ; ii+=1){
		//perhaps the user wants to abort the fit straightaway, this GUI button does that.
		if(!p->NFlagEncountered){
			#ifdef _MACINTOSH_
			if (ManuallyCheckButton( gTheWindow ))
				return FIT_ABORTED;
			#endif				
		}
		//cmd-dot or abort button
		if(CheckAbort(timeOutTicks) == -1){
			err = FIT_ABORTED;
			goto done;
		}
		if(err = setPvectorFromPop(goiP, ii))
			goto done;
		if(err = insertVaryingParams(goiP, p))
			goto done;
		if(err = calcModel(&goiP->fi,goiP->GenCurveFitCoefs,goiP->dataCalc,goiP->dataTemp,goiP->xcalc,goiP->independentVariable,goiP->numVarMD,goiP->isAAO))
			goto done;
		switch(goiP->METH){//which cost function
			case 0:
				if(err = calcChi2(goiP->dataObs,goiP->dataTemp,goiP->dataSig,goiP->unMaskedPoints,&chi2,goiP->weighttype))
					goto done;
				break;
			case 1:
				if(err = calcRobust(goiP->dataObs,goiP->dataTemp,goiP->dataSig,goiP->unMaskedPoints,&chi2,goiP->weighttype))
					goto done;
				break;
			default:
				break;
		}
		*(goiP->chi2Array+ii)= chi2;
	}
	//find best chi2 and put that into number 0 pos.
	wavStats = getWaveStats(goiP->chi2Array,goiP->totalpopsize,0);

	swapChi2values(goiP,0,wavStats.V_minloc);
	if(err = swapPopVector(goiP,goiP->totalpopsize,0,wavStats.V_minloc))
		goto done;

done:
if(holdstr != NULL)
	free(holdstr);

	return err;
}


/*
	freeAllocMem frees all the temporary arrays in the GenCurveFitInternals structure
*/
static void
freeAllocMem(GenCurveFitInternalsPtr goiP){
	int err=0,ii=0;

	waveHndl exists = NULL;
	if(goiP->temp!=NULL)
		free(goiP->temp);
	if(goiP->chi2Array!=NULL)
		free(goiP->chi2Array);
	if(goiP->gen_populationvector!=NULL)
		free(goiP->gen_populationvector);
	if(goiP->gen_coefsCopy!=NULL)
		free(goiP->gen_coefsCopy);
	if(goiP->gen_bprime!=NULL)
		free(goiP->gen_bprime);
	if(goiP->gen_trial!=NULL)
		free(goiP->gen_trial);
	if(goiP->limits!=NULL)
		free(goiP->limits);
	if(goiP->mask!=NULL)
		free(goiP->mask);
	if(goiP->varparams!=NULL)
		free(goiP->varparams);
	if(goiP->independentVariable!=NULL)
		free(goiP->independentVariable);
	if(goiP->allIndependentVariable!=NULL)
		free(goiP->allIndependentVariable);
	if(goiP->dataObs!=NULL)
		free(goiP->dataObs);
	if(goiP->dataObsFull)
		free(goiP->dataObsFull);
	if(goiP->dataSig!=NULL)
		free(goiP->dataSig);
	if(goiP->dataTemp!=NULL)
		free(goiP->dataTemp);
	if(goiP->gen_pvector!=NULL)
		free(goiP->gen_pvector);
	exists = FetchWaveFromDataFolder(goiP->cDF,"GenCurveFit_coefs");
	if(exists != NULL)
		err= KillWave(exists);	
	exists = FetchWaveFromDataFolder(goiP->cDF,"GenCurveFit_dataCalc");
	if(exists != NULL)
		err = KillWave(goiP->dataCalc);
	
	for(ii=0 ; ii<goiP->numVarMD ; ii+=1){
		if(goiP->xcalc[ii] != NULL)
			err = KillWave(goiP->xcalc[ii]);
	}
	if(goiP->tempWaveHndl_OUTx != NULL)
			err = KillWave(goiP->tempWaveHndl_OUTx);
	
	for(ii=0 ; ii<goiP->numVarMD ; ii+=1){
		if(goiP->fullExtentOfData[ii] != NULL)
			err = KillWave(goiP->fullExtentOfData[ii]);
	}
	//gTheWindow is a window created to show the latest position of the fit
	if (gTheWindow != NULL) {
		DestroyXOPWindow(gTheWindow);
		gTheWindow = NULL;
	}
}


static void
checkLimits(GenCurveFitInternalsPtr goiP,GenCurveFitRuntimeParamsPtr p){
	int ii;
	for(ii=0 ; ii<goiP->numvarparams ; ii+=1){
		if(*(goiP->gen_trial+ii) < *(goiP->limits+*(goiP->varparams+ii)) || *(goiP->gen_trial+ii) > *(goiP->limits+*(goiP->varparams+ii)+WavePoints(p->coefs)))
			*(goiP->gen_trial+ii) = randomDouble(*(goiP->limits+*(goiP->varparams+ii)),*(goiP->limits+*(goiP->varparams+ii)+WavePoints(p->coefs)));
	}
}



/*
	randomInteger returns an integer between 0 and upper inclusive
*/
static int
randomInteger (int upper){
	int val;
	while (upper <= (val = rand() / (RAND_MAX/upper)));
	return val;
}

/*
	randomDouble returns a double value between lower and upper
*/
static double
randomDouble(double lower, double upper){
	return lower + (upper-lower)*rand()/(((double)RAND_MAX + 1));
}

/*
	insertVaryingParams inserts the current pvector into an array copy of the coefficients,
	then into a temporary wave
	returns 0 if no error
	returns errorcode otherwise
*/
static int
insertVaryingParams(GenCurveFitInternalsPtr goiP, GenCurveFitRuntimeParamsPtr p){
	int err=0,ii;

	for(ii=0 ; ii< goiP->numvarparams; ii+=1){
		*(goiP->gen_coefsCopy+*(goiP->varparams+ii)) =  *(goiP->gen_pvector+ii);
	}
	err = MDStoreDPDataInNumericWave(goiP->GenCurveFitCoefs,goiP->gen_coefsCopy);
	return err;
}

/*
	extractVaryingParams copies the entire fit parameters from a wave into a temporary array
	it then extracts the varying parameters from that array and puts them into the pvector
	returns 0 if no error
	returns errorcode otherwise
*/
static int 
extractVaryingParams(GenCurveFitInternalsPtr goiP, GenCurveFitRuntimeParamsPtr p){
	int err=0,ii;
	
	if(err = MDGetDPDataFromNumericWave(goiP->GenCurveFitCoefs,goiP->gen_coefsCopy))
		return err;
	for(ii=0 ; ii< goiP->numvarparams; ii+=1){
		*(goiP->gen_pvector+ii) = *(goiP->gen_coefsCopy+*(goiP->varparams+ii));
	}
	return err;
}

/*
	calcModel calculates the theoretical curve for the model, given the coefficients
	fip			-	the function
	coefs		-	the coefficients to use in calculation
	output		-	where to put the theoretical fit (if using all-at-once function)
	outputPtr	-	where to put the theoretical fit (if you are using normal fit function)
	xx			-	wave containing the x values (if using all-at-once function)
	xpnts		-	array containing the x values (if you are using normal fit function)
	ndims		-	the dimensionality of the fit (i.e. how many independent variables there are
	isAAO		-	is the fit all-at-once?
	returns 0 if no error
	returns errorcode otherwise
*/
static int
calcModel(FunctionInfo* fip, waveHndl coefs, waveHndl output, double* outputPtr, waveHndl xx[MAX_MDFIT_SIZE], double* xpnts, int ndims,int isAAO){
	int err = 0, ii,jj;
	int requiredParameterTypes[MAX_MDFIT_SIZE+2];
	int badParameterNumber;
	allFitFunc allParameters;
	fitFunc parameters;
	double result;
	long numfitpoints = WavePoints(output);
		
	// check if all the input isn't NULL
	if(coefs == NULL || output==NULL){
		err = UNSPECIFIED_ERROR;
		goto done;
	}
	if(fip == NULL){
		err = FITFUNC_NOT_SPECIFIED;	
		goto done;
	}
	if(outputPtr == NULL){
		err = UNSPECIFIED_ERROR;
		goto done;
	}
	
	switch(isAAO){
		case 0:
			if(xpnts == NULL){
				err = UNSPECIFIED_ERROR;
				goto done;
			}
			parameters.waveH = coefs;
			requiredParameterTypes[0] = WAVE_TYPE;
			for(ii=0 ; ii<ndims ; ii+=1)
				requiredParameterTypes[ii+1] = NT_FP64;
			if (err = CheckFunctionForm(fip, ndims+1 , requiredParameterTypes,&badParameterNumber, NT_FP64))
				goto done;
			
			for(ii=0 ; ii<numfitpoints ; ii+=1){
				for(jj=0 ; jj<ndims ; jj+=1){
					parameters.x[jj] = *(xpnts+(jj*numfitpoints)+ ii);
				}
				// call the users fit function and put the result in the output array
				if (err = CallFunction(fip, (void*)&parameters, &result))
					goto done;
				*(outputPtr+ii) = result;
			}
			// copy the output array into an output wave
			if(err = MDStoreDPDataInNumericWave(output,outputPtr))
				goto done;
			break;
		case 1:
			allParameters.waveC = coefs;
			allParameters.waveY = output;
			requiredParameterTypes[0] = WAVE_TYPE;
			requiredParameterTypes[1] = WAVE_TYPE;
			
			for(ii=0 ; ii<ndims ; ii+=1){
				requiredParameterTypes[ii+2] = WAVE_TYPE;
				if(xx[ii] == NULL){
					err = UNSPECIFIED_ERROR;
					goto done;
				}
				allParameters.waveX[ii] = xx[ii];
			}
			if (err = CheckFunctionForm(fip, ndims + 2, requiredParameterTypes,&badParameterNumber, -1))
				goto done;
			// call the users fit function and put the result in the output wave
			if (err = CallFunction(fip, (void*)&allParameters, &result))
				goto done;
			// the user may have changed the number of points in the output wave
			if(output == NULL || WavePoints(output) != numfitpoints){
				err = USER_CHANGED_FITWAVE;
				goto done;
			}
			// get the output wave and put it into the output array
			if(err = MDGetDPDataFromNumericWave(output,outputPtr))
				goto done;
			break;
		default:
			err = UNSPECIFIED_ERROR;
			goto done;
			break;
	}
				
	// check that the fitfunction didn't return any NaN or INF
	if(err = checkNanInf(output)){
		err = FITFUNC_RETURNED_NANINF;
		goto done;
	}
done:

	return err;
}


/*
	calcModelXY calculates the theoretical curve for the model, used for returning the results of the fit to igor
	fip			-	the function
	coefs		-	the coefficients to use in calculation
	output		-	where to put the theoretical curve
	xx			-	wave containing the x values
	ndims		-	the dimensionality of the fit (i.e. how many independent variables there are
	isAAO		-	is the fit all-at-once?
	returns 0 if no error
	returns errorcode otherwise
*/
static int
calcModelXY(FunctionInfo* fip, waveHndl coefs, waveHndl output, waveHndl xx[MAX_MDFIT_SIZE], int ndims,int isAAO){
	int err = 0, ii,jj;
	int requiredParameterTypes[MAX_MDFIT_SIZE+2];
	int badParameterNumber;
	allFitFunc allParameters;
	fitFunc parameters;
	double result;
	double *tempX = NULL;
	double *tempY = NULL;
	long numfitpoints = WavePoints(output);
		
	// check if all the input isn't NULL
	if(coefs == NULL || output==NULL){
		err = UNSPECIFIED_ERROR;
		goto done;
	}
	if(fip == NULL){
		err = FITFUNC_NOT_SPECIFIED;	
		goto done;
	}

	switch(isAAO){
		case 0:
			tempX = (double*)malloc(ndims*numfitpoints*sizeof(double));
			if(tempX == NULL){
				err = NOMEM;
				goto done;
			}
			tempY = (double*)malloc(numfitpoints*sizeof(double));
			if(tempY == NULL){
				err = NOMEM;
				goto done;
			}
			for(ii=0 ; ii<ndims ; ii+=1){
				if(xx[ii] == NULL){
					err = UNSPECIFIED_ERROR;
					goto done;
				}
				if(err = MDGetDPDataFromNumericWave(xx[ii],tempX+(numfitpoints*ii)))
					goto done;
			}

			parameters.waveH = coefs;
			requiredParameterTypes[0] = WAVE_TYPE;
			for(ii=0 ; ii<ndims ; ii+=1)
				requiredParameterTypes[ii+1] = NT_FP64;
			if (err = CheckFunctionForm(fip, ndims+1 , requiredParameterTypes,&badParameterNumber, NT_FP64))
				goto done;
			
			for(ii=0 ; ii<numfitpoints ; ii+=1){
				for(jj=0 ; jj<ndims ; jj+=1){
					parameters.x[jj] = *(tempX+(jj*numfitpoints)+ ii);
				}
				// call the users fit function and put the result in the output array
				if (err = CallFunction(fip, (void*)&parameters, &result))
					goto done;
				*(tempY+ii) = result;
			}
			// copy the output array into an output wave
			if(err = MDStoreDPDataInNumericWave(output,tempY))
				goto done;
			break;
		case 1:
			allParameters.waveC = coefs;
			allParameters.waveY = output;
			requiredParameterTypes[0] = WAVE_TYPE;
			requiredParameterTypes[1] = WAVE_TYPE;
			
			for(ii=0 ; ii<ndims ; ii+=1){
				requiredParameterTypes[ii+2] = WAVE_TYPE;
				if(xx[ii] == NULL){
					err = UNSPECIFIED_ERROR;
					goto done;
				}
				allParameters.waveX[ii] = xx[ii];
			}
			if (err = CheckFunctionForm(fip, ndims + 2, requiredParameterTypes,&badParameterNumber, -1))
				goto done;
			// call the users fit function and put the result in the output wave
			if (err = CallFunction(fip, (void*)&allParameters, &result))
				goto done;
			// the user may have changed the number of points in the output wave
			if(output == NULL || WavePoints(output) != numfitpoints){
				err = USER_CHANGED_FITWAVE;
				goto done;
			}
			break;
		default:
			err = UNSPECIFIED_ERROR;
			goto done;
			break;
	}
				
	// check that the fitfunction didn't return any NaN or INF
	if(err = checkNanInf(output)){
		err = FITFUNC_RETURNED_NANINF;
		goto done;
	}

done:
if(tempX != NULL)
	free(tempX);
if(tempY != NULL)
	free(tempY);

	return err;
}



/*
	subtractTwoWaves subtracts wav2 from wav1
	returns 0 if no error
	returns errorcode otherwise
*/
static int
subtractTwoWaves(waveHndl wav1, waveHndl wav2){
	int err = 0;
	long ii;
	double *temp1 = NULL,*temp2 = NULL;
	double val=0,val2=0,val3=0;
	//check if the wave references are NULL
	if(wav1 == NULL)
		return NON_EXISTENT_WAVE;
	if(wav2 == NULL)
		return NON_EXISTENT_WAVE;
	if(WavePoints(wav1)!=WavePoints(wav2))
		return WAVE_LENGTH_MISMATCH;

	// we have to create temporary arrays to hold the wave data
	if((temp1 = (double*)malloc(sizeof(double)*WavePoints(wav1))) ==  NULL ){
		err = NOMEM;
		goto done;
	}
	if((temp2 = (double*)malloc(sizeof(double)*WavePoints(wav1))) ==  NULL ){
		err = NOMEM;
		goto done;
	}
	// get the data from the waves and put it into the temporary arrays
	if(err = MDGetDPDataFromNumericWave(wav1,temp1))
		goto done;
	if(err = MDGetDPDataFromNumericWave(wav2,temp2))
		goto done;
	// do the subtraction
	for(ii=0;ii<WavePoints(wav1);ii+=1){
		val = *(temp1+ii);
		val2 = *(temp2+ii);
		val3 = val - val2;
		*(temp1+ii) = val - val2;
	}
	// store the subtraction in wav1
	if(err = MDStoreDPDataInNumericWave(wav1,temp1))
		goto done;

	WaveHandleModified(wav1);
done:
	if(temp1!=NULL)
		free(temp1);
	if(temp2!=NULL)
		free(temp2);

	return err;
}
/*
	multiplies wav1 by scalar
	returns 0 if no error
	returns errorcode otherwise
*/
static int
scalarMultiply(waveHndl wav1, double scalar){
	int err = 0;
	long ii;
	double *temp1 = NULL;
	double val=0;
	//check if the wave references are NULL
	if(wav1 == NULL)
		return NON_EXISTENT_WAVE;

		// we have to create temporary arrays to hold the wave data
	if((temp1 = (double*)malloc(sizeof(double)*WavePoints(wav1))) ==  NULL ){
		err = NOMEM;
		goto done;
	}

		if(err = MDGetDPDataFromNumericWave(wav1,temp1))
			goto done;
		// do the subtraction
		for(ii=0;ii<WavePoints(wav1);ii+=1){
			val = *(temp1+ii)*scalar;
			*(temp1+ii) = val;
		}
		// store the subtraction in wav1
		if(err = MDStoreDPDataInNumericWave(wav1,temp1))
			goto done;

	WaveHandleModified(wav1);

done:
	if(temp1!=NULL)
		free(temp1);

	return err;
}

/*
	swapPopVector swaps the i vector with index j in the populationvector
	returns 0 if no error
	returns errorcode otherwise
*/
static int
swapPopVector(GenCurveFitInternalsPtr goiP,int popsize, int i, int j){
	double *tempparams = NULL;
	if(i<0 || j<0 || i>popsize-1 || j>popsize-1){
		return UNSPECIFIED_ERROR;
	} else {
		//do swap with pointers
		tempparams = *(goiP->gen_populationvector+j);
		*(goiP->gen_populationvector+j) = *(goiP->gen_populationvector+i);
		*(goiP->gen_populationvector+i) = tempparams;
	return 0;
	}
}
/*
	setPvector sets the pvector with a double array, checking to make sure the sizes are right
	returns 0 if no error
	returns errorcode otherwise
*/
static int 
setPvector(GenCurveFitInternalsPtr goiP,double* vector, int vectorsize){
	int ii;
	if(vectorsize == goiP->numvarparams){
		for(ii=0 ; ii<vectorsize ; ii+=1){
			*(goiP->gen_pvector+ii) = *(vector+ii);
		}
		return 0;
	} else return UNSPECIFIED_ERROR;
	return 0;
}
/*
	setPvectorFromPop sets the pvector from index vector from the population vector
	returns 0 if no error
	returns errorcode otherwise
*/

static int 
setPvectorFromPop(GenCurveFitInternalsPtr goiP, int vector){
	int ii;
	double val;
	for(ii = 0 ; ii<goiP->numvarparams ; ii+=1){
		val = goiP->gen_populationvector[vector][ii];
		*(goiP->gen_pvector+ii) = goiP->gen_populationvector[vector][ii];
	}
	return 0;
}

/*
	setPopVectorFromPVector sets the populationvector with index replace, with a double array
	returns 0 if no error
	returns errorcode otherwise
*/
static int 
setPopVectorFromPVector(GenCurveFitInternalsPtr goiP,double* vector, int vectorsize, int replace){
	int ii;
	if(vectorsize == goiP->numvarparams){
		for(ii=0 ; ii<vectorsize ; ii+=1){
			goiP->gen_populationvector[replace][ii] = *(vector+ii);
		}
		return 0;
	} else return UNSPECIFIED_ERROR;
}

/*
	swapChi2values swaps two values (i,j) in the goiP->chi2array 
*/
static void
swapChi2values(GenCurveFitInternalsPtr goiP, int i, int j){
	double temp = *(goiP->chi2Array+i);
	*(goiP->chi2Array+i) = *(goiP->chi2Array+j);
	*(goiP->chi2Array+j) = temp;
}
/*
	findmin finds the minimum value in a pointer array
	returns minimum position.
*/
static int
findmin(double* sort, int sortsize){
int ii = 0 , minpos = 0;
double minval = *(sort+ii);
	for(ii=0 ; ii<sortsize ; ii+=1){
		if(*(sort+ii) < minval){
			minval = *(sort+ii);
			minpos = ii;
		}
	}
	return minpos;
}
/*
	findMax finds the minimum value in a pointer array
	returns max position.
*/
static int
findmax(double* sort, int sortsize){
int ii = 0 , maxpos = 0;
double maxval = *(sort+ii);
	for(ii=0 ; ii<sortsize ; ii+=1){
		if(*(sort+ii) > maxval){
			maxval = *(sort+ii);
			maxpos = ii;
		}
	}
	return maxpos;
}


/*
	createTrialVector makes a mutated vector.  It fills the trialVector from the current pvector and from bPrime,
	in modulo.
	bPrime is created from two random population vectors and the best fit vector.
*/
static void 
createTrialVector(GenCurveFitInternalsPtr goiP, GenCurveFitRuntimeParamsPtr p, int currentpvector){
	int randomA,randomB,ii;
	int fillpos,numvarparams,totalpopsize;
	double km,recomb;
	km = p->km;
	recomb = p->recomb;
	totalpopsize = goiP->totalpopsize;
	numvarparams = goiP->numvarparams;

	do{
		randomA = randomInteger(totalpopsize);
	}while(randomA == currentpvector);
	do{
		randomB = randomInteger(totalpopsize);
	}while(randomB == currentpvector);

	fillpos = randomInteger(numvarparams);
	
	for(ii=0 ; ii<numvarparams ; ii+=1){
		*(goiP->gen_bprime+ii) = goiP->gen_populationvector[0][ii] + km*(goiP->gen_populationvector[randomA][ii] - goiP->gen_populationvector[randomB][ii]);
	}
	for(ii=0 ; ii<numvarparams ; ii+=1){
		*(goiP->gen_trial+ii) = goiP->gen_populationvector[currentpvector][ii];
	}

	ii=0;
	do{
		if ((randomDouble(0,1) < recomb) || (ii == numvarparams)){
			*(goiP->gen_trial+fillpos) =  *(goiP->gen_bprime+fillpos);
		}
		fillpos ++;
		fillpos = fillpos % numvarparams;
		ii +=1;
	}while(ii < numvarparams);
}

/*
	ensureConstraints takes the current trial vector and makes sure that all the individual 
	parameters lie inbetween the upper and lower limits.
	returns void
*/
static void
ensureConstraints(GenCurveFitInternalsPtr goiP,GenCurveFitRuntimeParamsPtr p){
int ii;
long points = WavePoints(p->coefs);

	for(ii=0 ; ii < goiP->numvarparams ; ii+=1){
		if(*(goiP->gen_trial+ii) <*(goiP->limits+*(goiP->varparams+ii)) || *(goiP->gen_trial+ii)>(*(goiP->limits+*(goiP->varparams+ii)+points))){
			*(goiP->gen_trial+ii) = randomDouble(*(goiP->limits+*(goiP->varparams+ii)),(*(goiP->limits+*(goiP->varparams+ii)+points)));
		}
	}
}

/*
optimiseloop performs the optimisation.  It takes the initial population and mutates it until we find the best fit solution
returns 0 if no errors
returns errorcode otherwise.
*/
static int
optimiseloop(GenCurveFitInternalsPtr goiP, GenCurveFitRuntimeParamsPtr p){
	
	long ii,kk;
	int err=0;
	int currentpvector;
	double chi2pvector,chi2trial;
	long timeOutTicks=0;
	waveStats wavStats;

	//Display the coefficients so far.
	if(!p->NFlagEncountered){
		DisplayWindowXOP1Message(gTheWindow,WavePoints(p->coefs),goiP->gen_coefsCopy,*(goiP->chi2Array),goiP->fi.name,goiP->V_numfititers);
		ShowAndActivateXOPWindow(gTheWindow);
	}

	// the user sets how many times through the entire population
	for(kk=0; kk<p->iterations ; kk+=1){
		goiP->V_numfititers = kk;

		//iterate over all the individual members of the population
		for(ii=0 ; ii<goiP->totalpopsize ; ii+=1){
			// perhaps the user wants to abort the fit using gui panel?
			if(!p->NFlagEncountered){
				#ifdef _MACINTOSH_
				if (ManuallyCheckButton( gTheWindow ))
					return FIT_ABORTED;
				#endif				
			}	
			//cmd-dot or abort button
			if(CheckAbort(timeOutTicks) == -1){
				return FIT_ABORTED;
			}

			currentpvector=ii;
			//now set up the trial vector using a wave from the populationvector and bprime
			//first set the pvector 
	// create a mutated trial vector from the best fit and two random population members
			createTrialVector(goiP,p,currentpvector);
	// make sure the trial vector parameters lie between the user defined limits
			ensureConstraints(goiP, p);

			chi2pvector = *(goiP->chi2Array+ii);
	/*
	find out the chi2 value of the trial vector		
	*/
			if(err = setPvector(goiP,goiP->gen_trial,goiP->numvarparams))
				return err;
			if(err = insertVaryingParams(goiP, p))
				return err;
			if(err = calcModel(&goiP->fi,goiP->GenCurveFitCoefs,goiP->dataCalc,goiP->dataTemp,goiP->xcalc,goiP->independentVariable,goiP->numVarMD,goiP->isAAO))
				return err;
			switch(goiP->METH){//which cost function
				case 0:
					if(err = calcChi2(goiP->dataObs, goiP->dataTemp, goiP->dataSig, goiP->unMaskedPoints, &chi2trial,goiP->weighttype))
						return err;
					break;
				case 1:
					if(err = calcRobust(goiP->dataObs, goiP->dataTemp, goiP->dataSig, goiP->unMaskedPoints, &chi2trial,goiP->weighttype))
						return err;
					break;
				default:
					break;
			}
	/*
	if the chi2 of the trial vector is less than the current populationvector then replace it
	*/
			if(chi2trial<chi2pvector){
				if(err = setPopVectorFromPVector(goiP,goiP->gen_pvector, goiP->numvarparams,currentpvector))
					return err;
				*(goiP->chi2Array+ii) = chi2trial;
	/*
	if chi2 of the trial vector is less than that of the best fit, then replace the best fit vector
	*/
				if(chi2trial<*(goiP->chi2Array)){		//if this trial vector is better than the current best then replace it
					if(err = setPopVectorFromPVector(goiP,goiP->gen_pvector, goiP->numvarparams,0))
						return err;
	/*
	if you're in update mode then update fit curve and the coefficients
	*/
					if(!p->NFlagEncountered){
						//DisplayWindowXOP1Message calls code in updateXOP<x>.c
						//this gives a window that gives the user the current chi2 value
						//and the number of iterations.
						DisplayWindowXOP1Message(gTheWindow,WavePoints(p->coefs),goiP->gen_coefsCopy,*(goiP->chi2Array),goiP->fi.name,goiP->V_numfititers);

						if(err = ReturnFit(goiP,p))
							return err;
					}
	/*
	if the fractional decrease in chi2 is less than the tolerance then abort the fit
	*/
					wavStats = getWaveStats(goiP->chi2Array,goiP->totalpopsize,1);

					if( wavStats.V_stdev/wavStats.V_avg < p->tol){	//if the fractional decrease is less and 0.5% stop.
						*(goiP->chi2Array) = chi2trial;
						return err;
					}
					//if( (fabs(chi2trial-*(goiP->chi2Array)) / (*(goiP->chi2Array)) )<p->tol){	//if the fractional decrease is less and 0.5% stop.
					//	*(goiP->chi2Array) = chi2trial;
					//	return err;
					//}

	/*
	update the best chi2 if you've just found a better fit (but not yet reached termination
	*/
					*(goiP->chi2Array) = chi2trial;
				}
			}
		}
	}
	return err;
}

/*
ReturnFit updates the model fits and coefficients, then informs IGOR
that we've changed the waves.
returns 0 if no errors
returns errorcode otherwise
*/
static int
ReturnFit(GenCurveFitInternalsPtr goiP, GenCurveFitRuntimeParamsPtr p){
	int err = 0;

	if(err = setPvectorFromPop(goiP,0))
		return err;
	if(err = insertVaryingParams(goiP, p))
		return err;
	if(err = MDStoreDPDataInNumericWave(p->coefs,goiP->gen_coefsCopy))
		return err;
	WaveHandleModified(p->coefs);
	
	switch(goiP->numVarMD){
		case 1:
			if(p->DFlagEncountered && p->XFlagEncountered){
				if(err = calcModelXY(&goiP->fi,p->coefs,goiP->OUT_data,goiP->fullExtentOfData,goiP->numVarMD, goiP->isAAO))
					return err;
			} else {
				if(err = calcModelXY(&goiP->fi,p->coefs,goiP->OUT_data,goiP->OUT_x,goiP->numVarMD, goiP->isAAO))
					return err;
			}
			break;
		default:
			if(err = calcModelXY(&goiP->fi,p->coefs,goiP->OUT_data,goiP->fullExtentOfData,goiP->numVarMD, goiP->isAAO))
				return err;
			break;
	}

	WaveHandleModified(goiP->OUT_data);

	if(p->RFlagEncountered){
		if(err = calcModelXY(&goiP->fi,p->coefs,goiP->OUT_res,goiP->fullExtentOfData,goiP->numVarMD,goiP->isAAO))
			return err;
		if(err = subtractTwoWaves(goiP->OUT_res,p->dataWave.waveH))
			return err;
		if(err = scalarMultiply(goiP->OUT_res, -1))
			return err;
		WaveHandleModified(goiP->OUT_res);
	}
	DoUpdate();
done:

	return err;
};

/*
identicalWaves tests whether two waveHandles refer to the same wave.
returns 0 if no errors
returns errorcode otherwise
if(wav1 == wav2) then isSame=1 
*/
static int
identicalWaves(waveHndl wav1, waveHndl wav2, int* isSame){
	int err = 0;
	char wav1Name[MAX_WAVE_NAME+1];
	char wav2Name[MAX_WAVE_NAME+1];
	DataFolderHandle df1H,df2H;
	long df1,df2;
	if(wav1 == NULL || wav2 == NULL){
		return 0;
	}
	*isSame = 0;
	WaveName(wav1,wav1Name);
	WaveName(wav2,wav2Name);
	
	if(err = GetWavesDataFolder(wav1,&df1H))
		return err;
	if(err = GetWavesDataFolder(wav2,&df2H))
		return err;
	if(err= GetDataFolderIDNumber(df1H,&df1))
		return err;
	if(err= GetDataFolderIDNumber(df2H,&df2))
		return err;

	if(CmpStr(wav1Name,wav2Name)==0 && df1 == df2)
		*isSame = 1;

	return err;
}

/*
 isWaveDisplayed tests if wav is displayed in the top graph
 returns 0 if no error
 returns errorcode otherwise
 if(wav is displayed in top graph) then isDisplayed=1
*/
static int
isWaveDisplayed(waveHndl wav, int *isDisplayed){
	char cmd[MAXCMDLEN+1];
	char varName[MAX_OBJ_NAME+1];
	char gwaveName[MAX_WAVE_NAME+1];
	double re=-1,imag=-1;
	int err=0;
	*isDisplayed = 0;

	if(wav == NULL)
		return NON_EXISTENT_WAVE;
	
	strcpy(varName, "TEMPGenCurveFit_GLOBALVAR");
	re = -1;
	if(err = SetIgorFloatingVar(varName, &re, 1))
		return err;
	strcpy(cmd,"TEMPGenCurveFit_GLOBALVAR=whichlistitem(\"");
	
	WaveName(wav,gwaveName);
	strcat(cmd,gwaveName);
	strcat(cmd,"\",(tracenamelist(winname(0,1),\";\",1)))");
	if(err = XOPSilentCommand(&cmd[0]))
		return err;
	if(FetchNumVar(varName, &re, &imag)==-1)
		return EXPECTED_VARNAME;
	if(re != -1) 
		*isDisplayed = 1;
	strcpy(cmd,"Killvariables/z TEMPGenCurveFit_GLOBALVAR");
	if(err = XOPSilentCommand(&cmd[0]))
		return err;
	return 0;
}
/*
	arraySd returns the standard deviation of a pointer to an array of doubles
*/
static double
arraySD(double* data, long datasize){
	long ii=0;
	double sd = 0;
	double nx2=0,nx=0,mean=0;
	for(ii=0;ii<datasize;ii+=1){
		nx += (*(data+ii));
	}
	mean = nx/(double)datasize;
	for(ii=0;ii<datasize;ii+=1){
		nx2 += pow((*(data+ii)-mean),2);
	}
	sd = nx2/(double)datasize;
	sd = sqrt(sd);

	return sd;
}
/*
	arrayMean returns the arithmetic mean of a pointer array
*/
static double
arrayMean(double* data, long datasize){
	long ii=0;
	double mean = 0;
	double nx=0; 
	for(ii=0;ii<datasize;ii+=1){
		nx+= (*(data+ii));
	}
	mean = nx/(double)datasize;

	return mean;
}
static long
numInArray3SD(double* data, double sd, long datasize){
	double mean = arrayMean(data,datasize);

	long ii=0;
	long num=0;
	for(ii=0;ii<datasize;ii+=1){
		if(abs(*(data+ii)-mean)<(3*sd))
			num+=1;
	}
	return num;
}
static int
getRange (WaveRange range,long *startPoint,long *endPoint){
	int direction;
	int err = 0;
	*startPoint = (double)range.startCoord;
	*endPoint = (double)range.endCoord;
	direction = 1;
	if (range.rangeSpecified) {
		WaveRangeRec wr;
		MemClear(&wr,sizeof(WaveRangeRec));
		wr.x1 = range.startCoord;
		wr.x2 = range.endCoord;
		wr.rangeMode = 3;
		wr.isBracket = range.isPoint;
		wr.gotRange = 1;
		wr.waveHandle = range.waveH;
		wr.minPoints = 2;
		if (err = CalcWaveRange(&wr))
		return err;
		*startPoint = wr.p1;
		*endPoint = wr.p2;
		direction = wr.wasBackwards ? -1:1;
	}
	return err;
}

/*
	roundDouble returns a rounded value for val
*/
static double
roundDouble(double val){
	double retval;
	if(val>0){
	if(val-floor(val) < 0.5){
		retval = floor(val);
	} else {
		retval = ceil(val);
	}
	} else {
	if(val-floor(val) <= 0.5){
		retval = floor(val);
	} else {
		retval = ceil(val);
	}
}
	return retval;
}


static int
WindowMessage(void){
	long item0;										// Item from IO list.
	long message;
	
	message = GetXOPMessage();

	if ((message & XOPWINDOWCODE) == 0)
		return 0;
		
	item0 = GetXOPItem(0);
	
	switch (message) {
		#ifdef _MACINTOSH_			// [
			case UPDATE:
				{
					WindowPtr wPtr;
					wPtr = (WindowPtr)item0;
					BeginUpdate(wPtr);
					EndUpdate(wPtr);
				}
				break;
			
			case ACTIVATE:
				{
					WindowPtr wPtr;
					wPtr = (WindowPtr)item0;
				}
				break;

			case CLICK:
				{
		//			WindowPtr wPtr;
		//			EventRecord* ePtr;
		//			wPtr = (WindowPtr)item0;
		//			ePtr = (EventRecord*)GetXOPItem(1);
		//			XOPWindowClickMac(wPtr, ePtr);
				}
				break;
		#endif						// _MACINTOSH_ ]
			
		case CLOSE:
			HideAndDeactivateXOPWindow(gTheWindow);
			break;
		
		case NULLEVENT:				// This is not sent on Windows. Instead, similar processing is done in response to the WM_MOUSEMOVE message.
			ArrowCursor();
			break;
	}												// Ignore other window messages.
	return 1;
}

static waveStats getWaveStats(double *sort, long length,int moment){
long ii=0;
double minval = *sort, maxval = *sort;
long minpos=0,maxpos=0;
double nx2=0,nx=0;
struct waveStats retval;

switch(moment){
	case 0:
		for(ii=0;ii<length;ii+=1){
			if(*(sort+ii)>maxval){
					maxval = *(sort+ii);
					maxpos = ii;
				}
			if(*(sort+ii)<minval){
					minval = *(sort+ii);
					minpos = ii;
			}
		}
		retval.V_maxloc = maxpos;
		retval.V_minloc = minpos;
		break;
	case 1:
		for(ii=0;ii<length;ii+=1){
			nx += (*(sort+ii));
			nx2 += pow(*(sort+ii),2);
			if(*(sort+ii)>maxval){
				maxval = *(sort+ii);
				maxpos = ii;
			}
			if(*(sort+ii)<minval){
				minval = *(sort+ii);
				minpos = ii;
			}
		}
		retval.V_maxloc = maxpos;
		retval.V_minloc = minpos;
		retval.V_avg = nx/(double)length;
		retval.V_stdev = sqrt((nx2/(double)length)-pow(retval.V_avg,2));
		break;
}
	return retval;
}
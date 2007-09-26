/*
	
GenCurvefit.c -- An XOP for curvefitting via Differential Evolution.
@copyright: Andrew Nelson and the Australian Nuclear Science and Technology Organisation 2007.

*/
#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h
#include <time.h>
#include <stdlib.h>

//maximum dimension of fit
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

#include "XOPStructureAlignmentTwoByte.h"	// All structures passed to Igor are two-byte aligned.
/*
	Structures passed to the XOP from IGOR
*/
struct GenCurveFitRuntimeParams {

	// Flag parameters.
	
	/*
	what (bitwise)options do you want to use
	bit 0: use initial guesses for starting fit, instead of random initialisation
	*/
	int OPTFlagEncountered;
	double opt;
	int OPTFlagParamsSet[1];

	/*
	MAT - correlation matrix produced
	*/
	int MATFlagEncountered;
	
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
	SEED - seed to initialise random number generator to have reproducible fit
	*/
	int SEEDFlagEncountered;
	double SEEDFlag_seed;
	int SEEDFlagParamsSet[1];
	
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
	//total number of parameters
	int totalnumparams;
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
	//an estimated covariance Matrix
	double **covarianceMatrix;
	//a handle for the covariance matrix
	waveHndl M_covariance;
	//a handle for the error wave
	waveHndl W_sigma;
	
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

/*
	A structure to hold statistics of a wave
*/
struct waveStats {
	double V_avg;
	double V_stdev;
	long V_maxloc;
	long V_minloc;
};
typedef struct waveStats waveStats;
typedef struct waveStats* waveStatsPtr;

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

/*
	Functions contained in Gencurvefit.c
*/
static int checkInput(GenCurveFitRuntimeParamsPtr, GenCurveFitInternalsPtr);
static int checkNanInf(waveHndl);
static int checkZeros(waveHndl ,long* );
static void freeAllocMem(GenCurveFitInternalsPtr goiP);
static int randomInteger(int upper);
static double randomDouble(double lower, double upper);
int calcModel(FunctionInfo*, waveHndl, waveHndl, double*, waveHndl[MAX_MDFIT_SIZE], double*,int,int);
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

/*
functions contained in errorEstimation.c
*/
static int ludcmp(double**,int,int*,double*);
static int lubksb(double **a, int n, int *indx, double b[]);
static int matrixInversion(double **a, int N);
int getCovarianceMatrix(GenCurveFitRuntimeParamsPtr p, GenCurveFitInternalsPtr goiP);
int updatePartialDerivative(double**, GenCurveFitRuntimeParamsPtr p, GenCurveFitInternalsPtr goiP);
int partialDerivative(double**, int, GenCurveFitRuntimeParamsPtr, GenCurveFitInternalsPtr,int);
int updateAlpha(double**,double**, GenCurveFitInternalsPtr goiP);
int calculateAlphaElement(int row, int col, double **alpha, double **derivativeMatrix, GenCurveFitInternalsPtr goiP);
int packAlphaSymmetric(double** alpha,GenCurveFitInternalsPtr);

//in malloc2D.c
void* malloc2d(int ii, int jj, int sz);

/* Prototypes */
HOST_IMPORT void main(IORecHandle ioRecHandle);






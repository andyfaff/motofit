/*
GenCurveFit.c -- An XOP for curvefitting via Differential Evolution.
@copyright: Andrew Nelson and the Australian Nuclear Science and Technology Organisation 2007.
*/
#include "XOPStandardHeaders.r"

resource 'vers' (1) {						// XOP version info.
	0x01, 0x20, release, 0x00, 0,			// version bytes and country integer.
	"1.",
	"1, © andyfaff@gmail.com all rights reserved."
};

resource 'vers' (2) {						// Igor version info.
	0x05, 0x00, release, 0x00, 0,			// Version bytes and country integer.
	"5.00",
	"(for Igor 5.00 or later)"
};

resource 'STR#' (1100) {					/* custom error messages */
	{
	"GenCurvefit requires Igor Pro 5.03 or later.",
	"Non-Existent Wave.",
	"Requires Double or Single Precision Wave.",
	"Waves not the same length0",
	"Input data must be 1D.",
	"Input data has no points.",
	"Input data contains NaN/INF.",
	"Coefficient Wave has no points.",
	"Coefficient Wave contains NaN/INF.",
	"Scaling of Y wave is NaN/INF.",
	"/K --> genetic optimisation parameters not specified correctly.",
	"Please specify holdstring.",
	"Holdstring should only contain 0 and 1 (fit,don't fit).",
	"Stopping tolerance must be 0<tol and not NaN/INF .",
	"Invalid FitFunction.",
	"Fitfunction doesn't return a number.",
	"Multivariate fitfunction supplied, but wrong independent variable information supplied.",
	"Parameters for fitfunc must be f(Wave,Wave,Wave).",
	"Fit function wasn't specified.",
	"Limits Wave must have dimensions NUMROWS=numpnts(coefs), NUMCOLS=2.",
	"Limits and/or coefficient waves not specified correctly.\n lowerlim<coef<upperlim.",
	"FitFunction returned NaN/INF for one or more values.",
	"Unspecified GeneticOptimisation Error.",
	"Holdstring should be same length as coefficient wave.",
	"All parameters are being held.",
	"Genetic Optimisation Aborted.",
	"Output wave requires same number of points as ywave (/R/D).",
	"You are trying to overwrite an Input/Output wave with an output wave (/R/D).",
	"you are trying to weight with standard deviations, but one of them is zero - DIVIDE BY ZERO.",
	"User redimensioned/killed Internal GenOpt fitwave.",
	"Subrange limited to point specification (you specified xscaling) - remember to sort wave.",
	}
};

resource 'STR#' (1101) {					// Misc strings for XOP.
	{
		"-1",								// This item is no longer supported by the Carbon XOP Toolkit.
		"No Menu Item",						// This item is no longer supported by the Carbon XOP Toolkit.
		"GenCurveFit Help",					// Name of XOP's help file.
	}
};

// No menu item

resource 'XOPI' (1100) {
	XOP_VERSION,							// XOP protocol version.
	DEV_SYS_CODE,							// Development system information.
	0,										// Obsolete - set to zero.
	0,										// Obsolete - set to zero.
	XOP_TOOLKIT_VERSION,					// XOP Toolkit version.
};

resource 'WIND' (1100) {					/* WindowXOP1 window */
	{50, 300, 300, 795},
	noGrowDocProc,
	visible,
	goAway,
	0x0,
	"GenCurveFit",
	noAutoCenter							// Added 980303 because Apple changed the Rez templates.
};

resource 'XOPC' (1100) {
	{
		"GenCurveFit",								// Name of operation.
		XOPOp+UtilOP+compilableOp,			// Operation's category.
	}
};



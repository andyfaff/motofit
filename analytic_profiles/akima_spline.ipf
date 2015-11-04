#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This code was translated into IGOR from the Python code available at
// http://www.lfd.uci.edu/~gohlke/code/akima.py.html

// Copyright (c) 2007-2015, Christoph Gohlke
// Copyright (c) 2007-2015, The Regents of the University of California
// Produced at the Laboratory for Fluorescence Dynamics
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
// * Neither the name of the copyright holders nor the names of any
//   contributors may be used to endorse or promote products derived
//   from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

//Akima's interpolation method uses a continuously differentiable sub-spline
//built from piecewise cubic polynomials. The resultant curve passes through
//the given data points and will appear smooth and natural.
//
//:Author:
//  `Christoph Gohlke <http://www.lfd.uci.edu/~gohlke/>`_
//
//:Organization:
//  Laboratory for Fluorescence Dynamics, University of California, Irvine
//
//References
//----------
//(1) A new method of interpolation and smooth curve fitting based
//    on local procedures. Hiroshi Akima, J. ACM, October 1970, 17(4), 589-602.

    
Function akima(x, y, x_new, y_new)
//	Return interpolated data using Akima's method.
//
//	Parameters
//	----------
//	x_new : wave
//	1D array of monotonically increasing real values.
//	y : wave
//	N-D array of real values. y's length along the interpolation
//	axis must be equal to the length of x.
//	x_new : wave
//	New independent variables.
//	y_new : wave
//	Wave to receive results. The number of points must be the same as x_new

//    make/d/n=2 y_new
//    akima({0, 1, 2}, {0, 0, 1}, {0.5, 1.5}, y_new)
//    print y_new
//    y_new[0]= {-0.125,0.375}
    
	Wave x, y, x_new, y_new

	variable n, mm, mmm, mp, mpp, ii, wm

	duplicate/o x_new, x_i

	n = numpnts(x)

	make/d/n=(numpnts(x) - 1)/free dx, dy, m, m1
	dx = x[p + 1] - x[p]
	dy = y[p + 1] - y[p]

	m = dy / dx
	mm = 2 * m[0] - m[1]
	mmm = 2 * mm - m[0]
	mp = 2 * m[n - 2] - m[n - 3]
	mpp = 2 * mp - m[n - 2]

	m1 = m
	insertpoints 0, 2, m1
	m1[0] = mmm
	m1[1] = mm
	insertpoints numpnts(m1), 2, m1
	m1[numpnts(m1) - 2] = mp
	m1[numpnts(m1) - 1] = mpp

	make/d/free/n=(numpnts(m1) - 1) dm
	dm = abs(m1[p + 1] - m1[p])

	duplicate/r=[2, n + 1]/free dm, f1
	duplicate/r=[0, n - 1]/free dm, f2
	duplicate/free f1, f12
	f12 = f1 + f2

	duplicate/free f12, ids
	ids = f12[p] > 1e-9 * wavemax(f12) ? p : -1

	duplicate/free/r=[1, n] m1, b

	b = m1[p + 1]
	b = ids[p] >= 0 ? (f1[p] * m1[p + 1] + f2[p] * m1[p + 2]) / f12[p]: 0

	duplicate/free m, c, d
	c = (3.0 * m[p] - 2.0 * b[p] - b[p + 1]) / dx[p]
	d = (b[p] + b[p + 1] - 2.0 * m) / dx ^ 2

	duplicate/free x_i, bins
	bins = binarysearch(x, x_i)
	bins = min(bins[p], n - 1)

	duplicate/free/r=[0, numpnts(x_i) - 1] bins, bb

	duplicate/free x_i, wj
	wj = x_i - x[bb]

	y_new = ((wj * d[bb] + c[bb]) * wj + b[bb]) * wj + y[bb]

End


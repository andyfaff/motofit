#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Function cheby_fit(w, yy, xx): fitfunc
	Wave w, yy, xx
	//a fitfunction for fitting with a basis set of Chebyshev polynomials.
	//the polynomial degree is controlled by the length of w.
	//Let [numpnts(w) - 1] = n
	//n  is from 0 to INF.
	//n = 1 is linear fit
	//n = 2 is quadratic
	//n = 3 is cubic
	//n = 4 is quartic, etc
	//yy[] = w[0] * T_0(xx) + ... + w[n] * T_n(xx)

	variable n = numpnts(w) - 1
	//have to place xx in [-1, 1]
	make/n=(numpnts(xx))/free/d tempxx
	variable vmin = Wavemin(xx)
	variable vmax = Wavemax(xx)
	multithread tempxx = cheby_range_transform(xx[p], vmin, vmax)
	
	//cache the results, you may call this function a lot
	Wave/z M_cheby2 = root:packages:cheby:M_cheby
	Wave/z tempxx2 = root:packages:cheby:xx
	if(waveexists(tempxx2) && waveexists(M_cheby2) && equalwaves(tempxx2, tempxx, 1, 0) && dimsize(M_cheby2, 1) == n + 1)
		Wave/z M_cheby = root:packages:cheby:M_cheby
	else
		newdatafolder/o root:packages
		newdatafolder/o root:packages:cheby
		duplicate/o tempxx, root:packages:cheby:xx
		make/o/d/n=(numpnts(xx), n + 1) root:packages:cheby:M_cheby
		Wave M_cheby = root:packages:cheby:M_cheby
		M_cheby[][] = chebyshev(q, tempxx[p])
	endif

	matrixop/free/NTHR=0 output = M_cheby x w
	multithread yy = output
End

Function cheby_guess_params(N, yy, xx)
	//guess parameters required for a Chebyshev non-linear least squares fit.
	//polynomial order is N
	//these will be the actual fit parameters if there is no error
	//weighting
	//creates a wave called W_coefs
	variable N
	wave yy, xx

	make/n=(numpnts(xx))/free/d tempxx
	variable vmin = Wavemin(xx)
	variable vmax = Wavemax(xx)
	multithread tempxx = cheby_range_transform(xx[p], vmin, vmax)
	
	make/n=(numpnts(xx), N + 1)/d/free M_cheby
	M_cheby = chebyshev(q, tempxx[p])
	
	matrixlls M_cheby, yy
	Wave M_b, M_a
	make/n=(N + 1)/d/o W_coefs
	W_coefs[] = M_b[p][0]
	killwaves/z M_b, M_a
End

Threadsafe Function cheby_range_transform(xx, vmin, vmax)
	variable xx, vmin, vmax
	//converts a point x, lying in the range [vmin, vmax] into a value
	//lying in the range [-1, 1]
	return (2 * xx - (vmin + vmax))/(vmax - vmin)
End

Threadsafe Function cheby_range_untransform(val, vmin, vmax)
	variable val, vmin, vmax
	//converts a point val, lying in the range [-1, 1] into a value
	//lying in the range [vmin, vmax]
	if (abs(val) > 1)
		print "val is supposed to be [-1, 1]"
	endif
	return ((vmax - vmin) * val + (vmax + vmin)) / 2
End

Function/wave cheby_interp_nodes(N)
	variable N
	//These values are used as nodes in polynomial interpolation because
	//the resulting interpolation polynomial minimizes the effect of Runge's phenomenon
	//N is the order of the Chebyshev polynomial.

	make/free/d/n=(N ) W_chebnodes
	W_chebnodes = 0
	W_chebnodes = cos(Pi / 2 / N * (2 * (p + 1) - 1))
	reverse W_chebnodes
	return W_chebnodes
End

Function cheby_interpolation(f, N, xmin, xmax, [xx])
	Funcref polyinterp f
	variable N, xmin, xmax
	Wave/z xx
	//provides a Chebyshev interpolating polynomial for a given function, f.  The interpolation is
	//done with an N'th order polynomial.
	//creates the W_chebinterp wave that contains the interpolating coefficients
	//creates the W_func wave that contains the polynomial evaluated over the range
	//[xmin, xmax]. THe default is 100 equally spaced points.  If the xx wave is specified
	//then W_func is evaluated at those points.

	//calculate the interpolating nodes first.
	Wave W_chebnodes = cheby_interp_nodes(N + 1)
	make/n=(numpnts(W_chebnodes))/free/d funcvals
	funcvals[] = f(cheby_range_untransform(W_chebnodes[p], xmin, xmax))

	//now calculate chebyshev polynomials at those nodes
	make/n=(N + 1)/d/free M_cheby
	M_cheby[][] = chebyshev(q, W_chebnodes[p])

	//now calculate the best coefficients, a_n
	//f(x) = a_0 * T_0(x) + ... + a_n * T_n(x)
	if(N == 0)
		make/n=1/d/o M_b
		M_b = funcvals[0]
	else
		matrixlls M_cheby, funcvals
		Wave M_a, M_b
	endif
	make/n=(N + 1)/d/o W_chebinterp
	W_chebinterp[] = M_b[p][0]

	if(!paramisdefault(xx) && waveexists(xx))
		make/n=(numpnts(xx))/d/o W_func
		cheby_fit(W_chebinterp, W_func, xx)
	else
		make/n=100/d/o W_func
		setscale/I x, xmin, xmax, W_func
		duplicate/free W_func, tempxx
		tempxx[] = pnt2x(W_func, p)
		cheby_fit(W_chebinterp, W_func, tempxx)
	endif

	killwaves/z M_b, M_a
End

Function polyinterp(x)
	variable x
	print "You are calling the polynomial interpolation FUNCREF by mistake"
End

Function runge(x)
	variable x
	//the Runge function
	//cheby_interpolation(runge, 25, -1, 1)
	return 1 / (1 + 25 * x * x)
End


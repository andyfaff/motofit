#pragma rtGlobals=1		// Use modern global access method.
//http://en.wikipedia.org/wiki/Propagation_of_uncertainty
 
Threadsafe Function EP_add(a, da, b, db, c, dc, [covar])
	wave a, da, b, db, c, dc
	variable covar
	// C = A + B
	duplicate/free a, tempa
	duplicate/free b, tempb
	duplicate/free da, tempda
	duplicate/free db, tempdb
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(covar))
		covar = 0
	endif
 
	multithread c = tempa + tempb
	multithread dc = sqrt(tempda ^ 2 + tempdb ^ 2 + 2 * covar)	
End
 
Threadsafe Function/c EP_addV(a, da, b, db, [covar])
	variable a, da, b, db, covar
	// C = A + B
 
	if(paramisdefault(covar))
		covar = 0
	endif
	
	return cmplx(a + b,  sqrt(da ^ 2 + db ^ 2 + 2 * covar))
End
 
Function EP_sub(a, da, b, db, c, dc, [covar])
	wave a, da, b, db, c, dc
	variable covar
	//C = A - B
	duplicate/free a, tempa
	duplicate/free b, tempb
	duplicate/free da, tempda
	duplicate/free db, tempdb
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(covar))
		covar = 0
	endif
 
	multithread c = tempa - tempb
	multithread dc = sqrt(tempda ^ 2 + tempdb ^ 2 - 2 * covar)	
End
 
Threadsafe Function/c EP_subV(a, da, b, db, [covar])
	variable a, da, b, db, covar
	//C = A - B

	if(paramisdefault(covar))
		covar = 0
	endif
 
	return cmplx(a - b, sqrt(da ^ 2 + db ^ 2 - 2 * covar))
End

Threadsafe Function EP_mult(a, da, b, db, c, dc, [covar])
	wave a, da, b, db, c, dc
	variable covar
	//C = A * B (B is an array)
	duplicate/free a, tempa
	duplicate/free b, tempb
	duplicate/free da, tempda
	duplicate/free db, tempdb
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(covar))
		covar = 0
	endif
 
	multithread c = tempa * tempb
	multithread dc = sqrt((tempb * tempda)^2 + (tempa * tempdb)^2 + 2 * tempa * tempb * covar)
End

Threadsafe Function/C EP_multV(a, da, b, db, [covar])
	variable a, da, b, db, covar
	//C = A * B 

	if(paramisdefault(covar))
		covar = 0
	endif
	return cmplx(a * b,  sqrt((b * da)^2 + (a * db)^2 + 2 * a * b * covar))
End

Threadsafe Function EP_mulK(a, da, c, dc, k)
	wave a, da, c, dc
	variable k
	//C = k * A
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
 
	multithread c = tempa * k
	multithread dc = abs(tempda * k)
End

Threadsafe Function/C EP_mulKV(a, da, k)
	variable a, da, k
	//C = k * A
	return cmplx(a * k, abs(da * k))
End

Threadsafe Function EP_div(a, da, b, db, c, dc, [covar])
	wave a, da, b, db, c, dc
	variable covar
	//C =  A / B
	duplicate/free a, tempa
	duplicate/free b, tempb
	duplicate/free da, tempda
	duplicate/free db, tempdb
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(covar))
		covar = 0
	endif
 
	multithread c = tempa / tempb
	multithread dc = sqrt(((tempda / tempb)^2 + (tempa^2 / (tempb^4)) * tempdb^2) - (2 * covar * tempa / (tempb^3)))
End

Threadsafe Function/C EP_divV(a, da, b, db, c, dc, [covar])
	variable a, da, b, db, covar
	//C =  A / B
	if(paramisdefault(covar))
		covar = 0
	endif
	
	return cmplx(a / b,  sqrt(((da / b)^2 + (a^2 / (b^4)) * db^2) - (2 * covar * a / (b^3))))
End

 
Threadsafe Function EP_pow(a, da, c, dc, k, [n])
	wave a, da, c, dc
	variable k, n
	//C = n * (A ^ k)
 
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(n))
		n = 1
	endif
 
	multithread c = n * (tempa ^ k)
	multithread dc = abs(n * k * tempda * tempa^(k -1))
End
 
 Threadsafe Function EP_powV(a, da, k, [n])
	variable a, da, k, n
	//C = n * (A ^ k)
 
	if(paramisdefault(n))
		n = 1
	endif
	return cmplx( n * (a ^ k),  abs(n * k * da * a^(k -1)))
End

Threadsafe Function EP_powK(a, da, c, dc, k, [n])
	wave a, da, c, dc
	variable k, n
	//C = k ^ (A * n)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(n))
		n = 1
	endif
 
	multithread c = k ^ (tempA * n)
	multithread dc = abs(n * ln(k) * tempda * k^(tempA * n))
End
 
 Threadsafe Function/c EP_powKV(a, da, k, [n])
	variable a, da,  k, n
	//C = k ^ (A * n)
	if(paramisdefault(n))
		n = 1
	endif
 	return cmplx(k ^ (a * n), abs(n * ln(k) * da * k^(a * n)))
End

Threadsafe Function EP_ln(a, da, c, dc, [k, n])
	wave a, da, c, dc
	variable k, n
	//C = n * ln(k * A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(k))
		k = 1
	endif
	if(paramisdefault(n))
		n = 1
	endif
	multithread c = n * ln(k * tempa)
	multithread dc = abs(n * tempda / tempa)
End
 
Threadsafe Function EP_lnV(a, da,  [k, n])
	variable a, da,  k, n
	//C = n * ln(k * A)
	if(paramisdefault(k))
		k = 1
	endif
	if(paramisdefault(n))
		n = 1
	endif
	return cmplx(n * ln(k * a), abs(n * da / a))
End

Threadsafe Function EP_log(a, da, c, dc, [k, n])
	wave a, da, c, dc
	variable k, n
	//C = n * log(k * A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(k))
		k = 1
	endif
	if(paramisdefault(n))
		n = 1
	endif
	multithread c = n * log(k * tempa)
	multithread dc = abs(n * tempda / (tempa * ln(10)))
End

Threadsafe Function/C EP_logV(a, da, [k, n])
	variable a, da, k, n
	//C = n * log(k * A)
	if(paramisdefault(k))
		k = 1
	endif
	if(paramisdefault(n))
		n = 1
	endif
	return cmplx(n * log(k * a), abs(n * da / (a * ln(10))))
End

Threadsafe Function EP_exp(a, da, c, dc, [k, n])
	wave a, da, c, dc
	variable k, n
	//C = n * exp(k * A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(k))
		k = 1
	endif
	if(paramisdefault(n))
		n = 1
	endif
 
	multithread c = n * exp(k * tempa)
	multithread dc = abs(k * tempda * c)
End

Threadsafe Function/C EP_expV(a, da,  [k, n])
	variable a, da,  k, n
	//C = n * exp(k * A)
	if(paramisdefault(k))
		k = 1
	endif
	if(paramisdefault(n))
		n = 1
	endif
 	return cmplx( n * exp(k * a), abs(k * da * c))
End

 
Threadsafe Function EP_sin(a, da, c, dc)
	wave a, da, c, dc
	//C = sin(A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
 
	multithread c = sin(A)
	multithread dc = abs(cos(A) * da)
End

Threadsafe Function/c EP_sinV(a, da)
	variable a, da
	//C = sin(A)
	return cmplx(sin(a), abs(cos(A) * da))
End
 
threadsafe Function EP_cos(a, da, c, dc)
	wave a, da, c, dc
	//C = cos(A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
 
	multithread c = cos(A)
	multithread dc = abs(-sin(A) * da)
End

Threadsafe Function/c EP_cosV(a, da)
	variable a, da
	//C = cos(A)
	return cmplx(cos(a), abs(-sin(A) * da)
End
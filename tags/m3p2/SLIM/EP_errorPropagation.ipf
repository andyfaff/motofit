#pragma rtGlobals=1		// Use modern global access method.
//http://en.wikipedia.org/wiki/Propagation_of_uncertainty
 
Function EP_add(a, da, b, db, c, dc, [covar])
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
 
Function EP_mult(a, da, b, db, c, dc, [covar])
wave a, da, b, db, c, dc
variable covar
	//C = A * B
	duplicate/free a, tempa
	duplicate/free b, tempb
	duplicate/free da, tempda
	duplicate/free db, tempdb
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
	if(paramisdefault(covar))
		covar = 0
	endif
 
	multithread c = tempa * tempb
	multithread dc = abs(c) * sqrt((tempda / tempa)^2 + (tempdb / tempb) ^ 2 + 2 * tempda * tempdb / (tempa * tempb) * covar)	
End
 
Function EP_mulK(a, da, c, dc, k)
wave a, da, c, dc
variable k
	//C = k * A
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
 
	multithread c = tempa * k
	multithread dc = abs(tempda * k)
End
 
Function EP_div(a, da, b, db, c, dc, [covar])
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
	multithread dc = abs(c) * sqrt((tempda / tempa) ^ 2 + (tempdb / tempb) ^ 2 - 2 * tempda * tempdb / (tempa * tempb) * covar)	
End
 
Function EP_pow(a, da, c, dc, k, [n])
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
	multithread dc = abs(c * k * tempda / tempa)
End
 
Function EP_powK(a, da, c, dc, k, [n])
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
	multithread dc = abs(c * n * tempda * ln(k))
End
 
Function EP_ln(a, da, c, dc, [k, n])
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
 
Function EP_log(a, da, c, dc, [k, n])
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

Function EP_exp(a, da, c, dc, [k, n])
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
 
Function EP_sin(a, da, c, dc)
wave a, da, c, dc
//C = sin(A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
 
	multithread c = sin(A)
	multithread dc = abs(cos(A) * da)
End
 
Function EP_cos(a, da, c, dc)
wave a, da, c, dc
//C = cos(A)
	duplicate/free a, tempa
	duplicate/free da, tempda
 
	redimension/n=(dimsize(a, 0), dimsize(a, 1), dimsize(a, 2), dimsize(a, 3)) c, dc
 
	multithread c = cos(A)
	multithread dc = abs(-sin(A) * da)
End
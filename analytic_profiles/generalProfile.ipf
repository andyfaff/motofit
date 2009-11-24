#pragma rtGlobals=1		// Use modern global access method.
Function modelWrapper(w,y,x):fitfunc
Wave w,y,x
make/n=(4*w[0]+6)/free/d forRef = w
variable ii

for(ii=0 ; ii<w[0] ; ii+=1)
	forRef[4*ii+6] = w[6]
	forRef[4*ii+7] = w[8+ii]
	forRef[4*ii+8] = 0
	forRef[4*ii+8] = w[7]
		
endfor

Abelesall(forRef,y,x)
y = log(y)
End
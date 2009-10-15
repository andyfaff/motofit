#pragma rtGlobals=1		// Use modern global access method.

CONSTANT SLABS_PER_PERIOD = 21

Function cubosome(w,yy,xx):fitfunc
Wave w, yy, xx

//w[0] = scalefactor
//w[1] = sldsuperphase (silicon?)
//w[2] = sldsubphase (d2o)
//w[3] = background
//w[4] = roughsubphase (between bulk subphase and cubosome)
//w[5] = thick1 (closest to superphase)
//w[6] = sld1
//w[7] = rough1
//w[8] = thick2
//w[9] = sld2
//w[10] = rough2
//w[11] = thick3 
//w[12] = sld3
//w[13] = rough3
//w[14] = thick4(closest to cubosome)
//w[15] = SLD4
//w[16] = rough4
//w[17] = thick5
//w[18] = sld5
//w[19] = rough5
//w[20] = N_rep (number of repeats)
//w[21] = rho_av-rep (average SLD)
//w[22] = A_rep (amplitude of oscillation)
//w[23] = l_rep (period)
//w[24] = phi

variable N_rep = abs(round(w[20]))
variable zed, ii, rho

//variable nlayers = 5 + SLABS_PER_PERIOD * N_rep
//make/n=(nlayers*4+6)/d/o funcoefs
//funcoefs[0] = nlayers

make/n=((5+SLABS_PER_PERIOD) *4+6)/d/o funcoefs

funcoefs[0] = 5
funcoefs[1] = w[0]
funcoefs[2] = w[1]
funcoefs[3] = w[2]
funcoefs[4] = w[3]
funcoefs[5] = w[4]

funcoefs[6] = w[5]
funcoefs[7] = w[6]
funcoefs[8] = 0
funcoefs[9] = w[7]

funcoefs[10] = w[8]
funcoefs[11] = w[9]
funcoefs[12] = 0
funcoefs[13] = w[10]

funcoefs[14] = w[11]
funcoefs[15] = w[12]
funcoefs[16] = 0
funcoefs[17] = w[13]

funcoefs[18] = w[14]
funcoefs[19] = w[15]
funcoefs[20] = 0
funcoefs[21] = w[16]

funcoefs[22] = w[17]
funcoefs[23] = w[18]
funcoefs[24] = 0
funcoefs[25] = w[19]

//for(ii = 0 ; ii< SLABS_PER_PERIOD * N_rep ; ii+=1)
//	zed = (ii+0.5) * w[23] / SLABS_PER_PERIOD
//	funcoefs[4*(ii+5)+6] = w[23]/SLABS_PER_PERIOD
//	funcoefs[4*(ii+5)+7] = w[21] + w[22]*sin((2*Pi*zed/w[23])+w[24])
//	funcoefs[4*(ii+5)+8] = 0
//	funcoefs[4*(ii+5)+9] = 0
//endfor

variable/g root:packages:motofit:reflectivity:tempwaves:Vmulrep=N_Rep
variable/g root:packages:motofit:reflectivity:tempwaves:Vmullayers=SLABS_PER_PERIOD
variable/g root:packages:motofit:reflectivity:tempwaves:Vappendlayer=5

for(ii = 0 ; ii< SLABS_PER_PERIOD ; ii+=1)
	zed = (ii+0.5) * w[23] / SLABS_PER_PERIOD
	
	funcoefs[4*(ii+5)+6] = w[23]/SLABS_PER_PERIOD
	funcoefs[4*(ii+5)+7] = w[21] + w[22]*sin((2*Pi*zed/w[23])+w[24])
	funcoefs[4*(ii+5)+8] = 0
	funcoefs[4*(ii+5)+9] = 0
endfor

//AbelesAll(funcoefs, yy, xx)
//yy = log(yy)
motofit(funcoefs,yy,xx)


End
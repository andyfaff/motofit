#pragma rtGlobals=3		// Use modern global access method.

//Constant SLDcation = 
Constant ANUMSLICES =150//00
Constant CONVREDUCER = 1
Constant VOLCAT = 263.5
Constant VOLANION = 239.6
CONSTANT RESOLUTION = 0.052

Threadsafe Function gaussonAu_OSC(w,yy,xx):fitfunc
wave w,yy,xx

//w[0] = scale
//w[1] = SLDsuperphase
//w[2] = SLDsubphase
//w[3] = back
//w[4] = roughness of Au
//w[5] = thickSiO2
//w[6] = SLDSiO2
//w[7] = roughSiO2
//w[8] = thickCr
//w[9] = SLDCr
//w[10] = roughCr
//w[11] = thickAu
//w[12] = SLDAu	
//w[13] = roughAu
//w[14] = multiplying factor between -1 and 1 MOLEFRACTION
//w[15] = wavelength
//w[16] = exp damping factor
//w[17] = thickness of box layer
//w[18] = SLD of cation (-0.21)
//w[19] = SLD of anion

variable ii, volfracAu, volFracCat, volFracBulk, zed, volfracanion, NUMSLICES
NUMSLICES = ANUMSLICES * 4 + 1

//create a Heaviside wave for the Au and box wave for the layer and a gauss wave for the convolution
make/n=(NUMSLICES)/free/d gau,heavi,cbox1,abox1

//work out the thickness ofeach of the slices.  
variable interfacialthickness = 2*(2*w[17] + 5*w[16]+3*w[4])
variable thickslice

//set the scaling on the waves
setscale/I x, -interfacialthickness, interfacialthickness, gau, heavi, cbox1,abox1

//work out the unsmeared volume fractions for each of the waves
gau = gauss(x, 0, w[4])
heavi = (x<0) ? 1: 0
heavi = (x==0) ? 0.5 : heavi

//MOLE FRACTION
cbox1 = 0
cbox1 =  (0 <= x && x < w[17]) ? w[14] : cbox1[p]
cbox1 =  w[17] <= x ?   0.5 * (((w[14]-0.5)/0.5) * cos(2 * Pi * (x - w[17]) / w[15]) * exp(-(x - w[17]) / w[16]) + 1):cbox1[p]

//CONVERT TO VOL FRACTION
cbox1 = cbox1 * VOLCAT / (cbox1 * VOLCAT + (1-cbox1) * VOLANION)

cbox1 = (x==0) ? 0.5 * cbox1 : cbox1

abox1 = 1-cbox1-heavi
//now smear the waves
convolve/a gau, heavi, cbox1, abox1

//now cut off the end bits which were designed to contain the wrap-around of the gaussian
deletepoints/m=0 3 * ANUMSLICES + 1, inf, heavi, cbox1,abox1
deletepoints/m=0 0, ANUMSLICES , heavi, cbox1, abox1

setscale/I x, -interfacialthickness/2, interfacialthickness/2, heavi, cbox1,abox1
thickslice = deltax(heavi)

//have to account for the fact that the convolution ignores the wavescaling, but the gaussian has non-unity wavescaling.  Simply 
//multiply by the thickness of the slice.
cbox1 *= thickslice
abox1 *= thickslice
heavi *= thickslice

make/d/n=(4*(numpnts(heavi) + 3) + 6)/free funcoefs

funcoefs[0] = numpnts(heavi) + 3
funcoefs[1] = w[0]
funcoefs[2] = w[1]
funcoefs[3] = w[2]
funcoefs[4] = 0
funcoefs[5] = 0
funcoefs[6] = w[5]
funcoefs[7] = w[6]
funcoefs[8] = 0
funcoefs[9] = w[7]
funcoefs[10] = w[8]
funcoefs[11] = w[9]
funcoefs[12] = 0
funcoefs[13] = w[10]

//now work out the volfrac profile for the gold and the box
//reduce Au layer thickness by the roughness  of the Au, plus half a box width
funcoefs[14] = w[11] - (interfacialthickness * 0.5) - (thickslice * 0.5)
funcoefs[15] = w[12]
funcoefs[16] = 0
funcoefs[17] = w[13]

//now we get to define the roughness
	for(ii=0 ; ii < numpnts(heavi) ; ii+=1)
		//thickness, solv and roughness
		funcoefs[4*ii+18] = thickslice
		funcoefs[4*ii+20] = 0
		funcoefs[4*ii+21] = 0

		volfracAu = Heavi[ii]
		volfracCat = cbox1[ii] 
		volfracanion = abox1[ii]
		volfracbulk = 1- volfracAu - volfracCat-volfracanion
		funcoefs[4*ii+19] = volfracAu*w[12] + volfraccat * w[18] + volfracanion*w[19]+volfracbulk*w[2]
	endfor
	
	//now calculate the reflectivity
	make/n=(dimsize(xx, 0), 2)/free xxtemp
	xxtemp[][0] = xx[p]
	xxtemp[][1] = xx[p] * RESOLUTION
	
	Abelesall(funcoefs,yy,xx)
	multithread yy += w[3]
	multithread yy = log(yy)
End

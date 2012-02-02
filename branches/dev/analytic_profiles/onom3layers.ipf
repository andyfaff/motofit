#pragma rtGlobals=1		// Use modern global access method.
Function add_bin_mix(w, y, x) : fitfunc
Wave w, y, x

//0 = scalefactor
//1 = SLD superphase
//2 = SLD subphase
//3 = background
//4 = subrough
//5 = dA
//6 = phiA
//7 = dC
//8 = phiC
//9 = dT
//10 = mu
//11 = SLDp
//12 = SLDd
//13 = sigA (superphase/A roughness)
//14 = sigB (A/B roughness)
//15 = sigC (B/C roughness)
//16 = thickSiO2
//17 = SLDSiO2
//18 = roughSiO2

make/d/free/n=(4 * 4 + 6) coef_forReflectivity = 0

variable sldA, sldB, sldC, phiB, dB
sldA = w[6] * w[11] + (1 - w[6]) * w[12]
sldC = w[8] * w[11] + (1 - w[8]) * w[12]
dB = w[9] - w[5] - w[7]

phiB = ((w[10] - w[6]) * w[5] + (w[10] - w[8]) * w[7] +  w[10] * dB) / dB
sldB = phiB * w[11] + (1 - phiB) * w[12]

coef_forReflectivity[0] = 4
coef_forReflectivity[1] = w[0]
coef_forReflectivity[2] = w[1]
coef_forReflectivity[3] = w[2]
coef_forReflectivity[4] = w[3]
coef_forReflectivity[5] = w[4]

coef_forReflectivity[6] = w[5]
coef_forReflectivity[7] = sldA
coef_forReflectivity[9] = w[13]

coef_forReflectivity[10] = dB
coef_forReflectivity[11] = sldB
coef_forReflectivity[13] = w[14]

coef_forReflectivity[14] = w[7]
coef_forReflectivity[15] = sldC
coef_forReflectivity[17] = w[15]

coef_forReflectivity[18] = w[16]
coef_forReflectivity[19] = w[17]
coef_forReflectivity[21] = w[18]

//AbelesAll(coef_forReflectivity, y, x)
//y = log(y)

Motofit(coef_forReflectivity, y, x)
End
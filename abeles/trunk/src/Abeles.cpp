/*	Abeles.c
	A simplified project designed to act as a template for your curve fitting function.
	The fitting function is a simple polynomial. It works but is of no practical use.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h
#include <math.h>

#include <exception>
#include "MyComplex.h"

using namespace std;
using namespace MyComplexNumber;
// Prototypes
#ifdef _MACINTOSH_
HOST_IMPORT int main(IORecHandle ioRecHandle);
#endif	
#ifdef _WINDOWS
HOST_IMPORT void main(IORecHandle ioRecHandle);
#endif

// Custom error codes
#define REQUIRES_IGOR_400 1 + FIRST_XOP_ERR
#define NON_EXISTENT_WAVE 2 + FIRST_XOP_ERR
#define REQUIRES_SP_OR_DP_WAVE 3 + FIRST_XOP_ERR
#define INCORRECT_INPUT 4 + FIRST_XOP_ERR
#define WAVES_NOT_SAME_LENGTH 5 + FIRST_XOP_ERR
#define REQUIRES_DP_WAVE 6 + FIRST_XOP_ERR

#define PI 3.14159265358979323846


/*	Abeles calculates reflectivity given a model description.

	Warning:
		The call to WaveData() below returns a pointer to the middle
		of an unlocked Macintosh handle. In the unlikely event that your
		calculations could cause memory to move, you should copy the coefficient
		values to local variables or an array before such operations.
*/


#include "XOPStructureAlignmentTwoByte.h"	// All structures passed to Igor are two-byte aligned.



typedef struct FitParams {
	double x;				// Independent variable.
	waveHndl waveHandle;	// Coefficient wave.
	double result;
} FitParams, *FitParamsPtr;

typedef struct FitParamsAll {
	waveHndl XWaveHandle;	// X wave (input).
	waveHndl YWaveHandle;	// Y wave (output).
	waveHndl CoefHandle;	// Coefficient wave.
	DOUBLE result;			// not actually used.
}FitParamsAll, *FitParamsAllPtr;

#include "XOPStructureAlignmentReset.h"
static int AbelescalcAll(double*,double*,double*,long);
static int Abelescalc_imagAll(double*,double*,double*,long);
static int Abelescalc(double*,double, double*);
static int Abelescalc_imag(double*,double,double*);
static void matmul(MyComplex,MyComplex,MyComplex);
static MyComplex fres(MyComplex,MyComplex,double);

static int
AbelesAll(FitParamsAllPtr p){
	long ncoefs,npoints;
	double realVal,imagVal;
	int nlayers,Vmullayers=-1, err=0;
	double *coefP = NULL;
	double *xP = NULL;
	double *yP = NULL;

	if (p->CoefHandle == NULL || p->YWaveHandle == NULL || p->XWaveHandle == NULL ) 
	{
		SetNaN64(&p->result);
		err = NON_EXISTENT_WAVE;
		goto done;
	}
	if (!(WaveType(p->CoefHandle) != NT_FP64 || WaveType(p->YWaveHandle) != NT_FP64 || WaveType(p->XWaveHandle) != NT_FP64
		|| WaveType(p->XWaveHandle) != NT_FP32 || WaveType(p->YWaveHandle) != NT_FP32 || WaveType(p->CoefHandle) != NT_FP32)){
		SetNaN64(&p->result);
		err = REQUIRES_SP_OR_DP_WAVE;
		goto done;
	}
	
	if(FetchNumVar("Vmullayers", &realVal, &imagVal) == -1){
		Vmullayers=0;
	} else{
		Vmullayers=(long)realVal;
	}

	ncoefs= WavePoints(p->CoefHandle);
	npoints = WavePoints(p->YWaveHandle);
	if (npoints != WavePoints(p->XWaveHandle)){
		SetNaN64(&p->result);
		err = WAVES_NOT_SAME_LENGTH;
		goto done;
	}
	
	try{
		coefP =  new double[ncoefs];
		xP =  new double[npoints];
		yP = new double[npoints];
	} catch (...){
		err = NOMEM;
		goto done;
	}

	if(err = MDGetDPDataFromNumericWave(p->CoefHandle, coefP))
		goto done;
	if(err = MDGetDPDataFromNumericWave(p->YWaveHandle, yP))
		goto done;
	if(err = MDGetDPDataFromNumericWave(p->XWaveHandle, xP))
		goto done;

	nlayers = (long)coefP[0];
	if(ncoefs != (4*Vmullayers+(4*nlayers+6))){
		err = INCORRECT_INPUT;
		goto done;
	};
	
	if(err = AbelescalcAll(coefP,yP,xP,npoints))
		goto done;
	if(err = MDStoreDPDataInNumericWave(p->YWaveHandle,yP))
		goto done;
	
	WaveHandleModified(p->YWaveHandle);
	p->result = 0;		// not actually used by FuncFit

done:
	if(xP != NULL)
		delete [] xP;
	if(yP != NULL)
		delete [] yP;
	if(coefP != NULL)
		delete [] coefP;

	return err;	
}

static int
Abeles_imagAll(FitParamsAllPtr p)
{
	long ncoefs,npoints;
	double *coefP = NULL;
	double *xP = NULL;
	double *yP = NULL;
	int err = 0;
	double realVal,imagVal;
	long nlayers,Vmullayers;
	
	if (p->CoefHandle == NIL ||	p->YWaveHandle == NIL || p->XWaveHandle == NIL ){
		SetNaN64(&p->result);
		err = NON_EXISTENT_WAVE;
		goto done;
	}
	if (!(WaveType(p->CoefHandle) != NT_FP64 || WaveType(p->YWaveHandle) != NT_FP64 || WaveType(p->XWaveHandle) != NT_FP64
		|| WaveType(p->XWaveHandle) != NT_FP32 || WaveType(p->YWaveHandle) != NT_FP32 || WaveType(p->CoefHandle) != NT_FP32)){
		SetNaN64(&p->result);
		err = REQUIRES_SP_OR_DP_WAVE;
		goto done;
	}
	
	ncoefs = WavePoints(p->CoefHandle);
	npoints = WavePoints(p->YWaveHandle);
	if (npoints != WavePoints(p->XWaveHandle)){
		SetNaN64(&p->result);
		err = WAVES_NOT_SAME_LENGTH;
		goto done;
	}

	if(FetchNumVar("Vmullayers", &realVal, &imagVal) == -1){
		Vmullayers=0;
	} else{
		Vmullayers=(long)realVal;
	}

	try{
		coefP =  new double[ncoefs];
		xP =  new double[npoints];
		yP = new double[npoints];
	} catch (...){
		err = NOMEM;
		goto done;
	}
		
	if(err = MDGetDPDataFromNumericWave(p->CoefHandle, coefP))
		goto done;
	if(err = MDGetDPDataFromNumericWave(p->YWaveHandle, yP))
		goto done;
	if(err = MDGetDPDataFromNumericWave(p->XWaveHandle, xP))
		goto done;

	nlayers = (long)coefP[0];
	if(ncoefs != (long)(4*Vmullayers+4*nlayers+8)){
		err = INCORRECT_INPUT;
		goto done;
	}

	if(err = Abelescalc_imagAll(coefP,yP,xP,npoints))
		goto done;
	if(err = MDStoreDPDataInNumericWave(p->YWaveHandle,yP))
		goto done;
	
	WaveHandleModified(p->YWaveHandle);
	p->result = 0;		// not actually used by FuncFit
	
done:
	if(xP != NULL)
		delete [] xP;
	if(yP != NULL)
		delete [] yP;
	if(coefP != NULL)
		delete [] coefP;

	return err;		
}

static int
Abeles(FitParamsPtr p){
	int np,err = 0;
	double *Abelesparams = NULL;
	double x;
	char varName[MAX_OBJ_NAME+1];
	double realVal,imagVal;
	int Vmullayers;
	
	if (p->waveHandle == NULL){
		SetNaN64(&p->result);
		err = NON_EXISTENT_WAVE;
		goto done;
	}
	
	np= WavePoints(p->waveHandle);

	Abelesparams= (double*)malloc((np) * sizeof(double));	//pointer to my copy of the data.
	if(Abelesparams == NULL){
		err = NOMEM;
		goto done;
	}

	strcpy(varName, "Vmullayers");
	if(FetchNumVar("Vmullayers", &realVal, &imagVal) == -1){
		Vmullayers=0;
	} else{
		Vmullayers=(long)realVal;
	}
	
	x= p->x;
	
	if(err = MDGetDPDataFromNumericWave(p->waveHandle, Abelesparams)){
		goto done;
	}
	if((int)np!=(int)(4*Vmullayers+4*Abelesparams[0]+6)){
		err = INCORRECT_INPUT;
		goto done;
	};

	if(err = Abelescalc(Abelesparams,x,&p->result))
		goto done;
done:
	if(Abelesparams!=NULL)
		free(Abelesparams);

	return err;
}

static int
Abeles_imag(FitParamsPtr p){
	int np, err = 0;
	double *Abelesparams = NULL;
	double x,result;
	char varName[MAX_OBJ_NAME+1];
	double realVal,imagVal;
	int Vmullayers;
	
	if (p->waveHandle == NULL){
		SetNaN64(&p->result);
		err = NON_EXISTENT_WAVE;
		goto done;
	}
	
	np= WavePoints(p->waveHandle);

	Abelesparams= (double*)malloc((np) * sizeof(double));	//pointer to my copy of the data.
	if(Abelesparams == NULL){
		err = NOMEM;
		goto done;
	}

	strcpy(varName, "Vmullayers");
	if(FetchNumVar("Vmullayers", &realVal, &imagVal) == -1){
		Vmullayers=0;
	} else{
		Vmullayers=(long)realVal;
	}
		
	x= p->x;
	
	if(err = MDGetDPDataFromNumericWave(p->waveHandle, Abelesparams)){
		goto done;
	}
	if((int)np!=(int)(4*Vmullayers+4*Abelesparams[0]+8)){
		err = INCORRECT_INPUT;
		goto done;
	};

	if(err = Abelescalc_imag(Abelesparams,x,&result))
		goto done;
	p->result = result;

done:
	if(Abelesparams!=NULL)
		free(Abelesparams);

	return err;
}


static long
RegisterFunction()
{
	int funcIndex;

	funcIndex = GetXOPItem(0);			// Which function invoked ?
	switch (funcIndex) {
		case 0:							// y = Abeles(w,x) (curve fitting function).
			return((long)Abeles);	// This function is called using the direct method.
			break;
		case 1:
			return((long)Abeles_imag);
			break;
		case 2:
			return((long)AbelesAll);
			break;
		case 3:
			return((long)Abeles_imagAll);
			break;
	}
	return NIL;
}

/*	XOPEntry()

	This is the entry point from the host application to the XOP for all
	messages after the INIT message.
*/
static void
XOPEntry(void)
{	
	long result = 0;

	switch (GetXOPMessage()) {
		case FUNCADDRS:
			result = RegisterFunction();	// This tells Igor the address of our function.
			break;
	}
	SetXOPResult(result);
}

/*	main(ioRecHandle)

	This is the initial entry point at which the host application calls XOP.
	The message sent by the host must be INIT.
	main() does any necessary initialization and then sets the XOPEntry field of the
	ioRecHandle to the address to be called for future messages.
*/
#ifdef _MACINTOSH_
HOST_IMPORT int main(IORecHandle ioRecHandle)
#endif	
#ifdef _WINDOWS
HOST_IMPORT void main(IORecHandle ioRecHandle)
#endif
{	
	XOPInit(ioRecHandle);							// Do standard XOP initialization.
	SetXOPEntry(XOPEntry);							// Set entry point for future calls.
	
	if (igorVersion < 400)
		SetXOPResult(REQUIRES_IGOR_400);
	else
		SetXOPResult(0L);
}

static void
matmul(MyComplex a[2][2],MyComplex b[2][2],MyComplex c[2][2]){
	c[0][0] = a[0][0]*b[0][0] + a[0][1]*b[1][0];
	c[0][1] = a[0][0]*b[0][1] + a[0][1]*b[1][1];
	c[1][0]	= a[1][0]*b[0][0] + a[1][1]*b[1][0];
	c[1][1] = a[1][0]*b[0][1] + a[1][1]*b[1][1];	
}
static MyComplex
fres(MyComplex a,MyComplex b,double rough){
	MyComplex c;
	MyComplex arg = a*b;
	arg = MyComplex(-2*rough*rough,0)*arg;
//	arg = c.compexp(arg);
	arg = compexp(arg);
	c = (a-b)/(a+b);
	c = c*arg;
	return c;
}

static int
Abelescalc(double *coefP, double x, double *result){
	int err = 0;
	
	int Vmulrep=0,Vmulappend=0,Vmullayers=0;
	double realVal,imagVal;
	int ii=0,jj=0,kk=0;

	double scale,bkg,subrough;
	double num=0,den=0, answer=0,qq;
	double anum,anum2;
	MyComplex temp,SLD,beta,rj;
	double numtemp=0;
	int offset=0;
	MyComplex  MRtotal[2][2];
	MyComplex subtotal[2][2];
	MyComplex MI[2][2];
	MyComplex temp2[2][2];
	MyComplex qq2;
	MyComplex oneC = MyComplex(1,0);
	MyComplex *pj_mul = NULL;
	MyComplex *pj = NULL;
	double *SLDmatrix = NULL;
	double *SLDmatrixREP = NULL;

	int nlayers = (int)coefP[0];
	
	try{
		pj = new MyComplex [nlayers+2];
		SLDmatrix = new double [nlayers+2];
	} catch(...){
		err = NOMEM;
		goto done;
	}

	memset(pj, 0, sizeof(pj));
	memset(SLDmatrix, 0, sizeof(SLDmatrix));

	scale = coefP[1];
	bkg = fabs(coefP[4]);
	subrough = coefP[5];

	//offset tells us where the multilayers start.
	offset = 4 * nlayers + 6;

	//fillout all the SLD's for all the layers
	for(ii=1; ii<nlayers+1;ii+=1){
		numtemp = 1e-6 * ((100 - coefP[4*ii+4])/100) * coefP[4*ii+3]+ (coefP[4*ii+4]*coefP[3]*1e-6)/100;		//sld of the layer
		*(SLDmatrix+ii) = 4*PI*(numtemp  - (coefP[2]*1e-6));
	}
	*(SLDmatrix) = 0;
	*(SLDmatrix+nlayers+1) = 4*PI*((coefP[3]*1e-6) - (coefP[2]*1e-6));
	
	if(FetchNumVar("Vmullayers", &realVal, &imagVal)!=-1){ // Fetch value
		Vmullayers=(int)realVal;
		if(FetchNumVar("Vappendlayer", &realVal, &imagVal)!=-1)
			Vmulappend=(int)realVal;
		if(FetchNumVar("Vmulrep", &realVal, &imagVal) !=-1) // Fetch value
			Vmulrep=(int)realVal;

		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >= 0){
		//set up an array for wavevectors
			try{
				SLDmatrixREP = new double [Vmullayers];
				pj_mul = new MyComplex [Vmullayers];
			} catch(...){
				err = NOMEM;
				goto done;
			}
			memset(pj_mul, 0, sizeof(pj_mul));
			for(ii=0; ii<Vmullayers;ii+=1){
				numtemp = (coefP[3]*1e-6*coefP[(4*ii)+offset+2]/100) +(1e-6 * ((100 - coefP[(4*ii)+offset+2])/100) * coefP[(4*ii)+offset+1]);		//sld of the layer
				*(SLDmatrixREP+ii) = 4*PI*(numtemp  - (coefP[2]*1e-6));
			}
		}
	}
	
		//intialise the matrices
		memset(MRtotal,0,sizeof(MRtotal));
		MRtotal[0][0] = oneC ; MRtotal[1][1] = oneC;

		qq = x*x/4;
		qq2=MyComplex(qq,0);

		for(ii=0; ii<nlayers+2 ; ii++){			//work out the wavevector in each of the layers
			pj[ii] = (*(SLDmatrix+ii)>qq) ? compsqrt(qq2-MyComplex(*(SLDmatrix+ii),0)): MyComplex(sqrt(qq-*(SLDmatrix+ii)),0);
			//pj[ii] = (*(SLDmatrix+ii)>qq) ? oneC.compsqrt(qq2-MyComplex(*(SLDmatrix+ii),0)): MyComplex(sqrt(qq-*(SLDmatrix+ii)),0);
		}
		
		//workout the wavevector in the toplayer of the multilayer, if it exists.
		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >=0){
			memset(subtotal,0,sizeof(subtotal));
			subtotal[0][0]=MyComplex(1,0);subtotal[1][1]=MyComplex(1,0);
			pj_mul[0] = (*(SLDmatrixREP)>qq) ? compsqrt(qq2-MyComplex(*SLDmatrixREP,0)): MyComplex(sqrt(qq-*SLDmatrixREP),0);
		//	pj_mul[0] = (*(SLDmatrixREP)>qq) ? oneC.compsqrt(qq2-MyComplex(*SLDmatrixREP,0)): MyComplex(sqrt(qq-*SLDmatrixREP),0);
		}
		
		//now calculate reflectivities
		for(ii = 0 ; ii < nlayers+1 ; ii++){
			//work out the fresnel coefficients
			//this looks more complicated than it really is.
			//the reason it looks so convoluted is because if there is no complex part of the wavevector,
			//then it is faster to do the calc with real arithmetic then put it into a complex number.
			if(Vmullayers>0 && ii==Vmulappend && Vmulrep>0 ){
				rj=fres(pj[ii],pj_mul[0],coefP[offset+3]);
			} else {
				if((pj[ii]).im == 0 && (pj[ii+1]).im==0){
					anum = (pj[ii]).re;
					anum2 = (pj[ii+1]).re;
					rj = (ii==nlayers) ?
					MyComplex(((anum-anum2)/(anum+anum2))*exp(anum*anum2*-2*subrough*subrough),0)
					:
					MyComplex(((anum-anum2)/(anum+anum2))*exp(anum*anum2*-2*coefP[4*(ii+1)+5]*coefP[4*(ii+1)+5]),0);
				} else {
					rj = (ii == nlayers) ?
						((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*subrough*subrough,0))
						:
						((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*coefP[4*(ii+1)+5]*coefP[4*(ii+1)+5],0));	
				};
			}

			//work out the beta for the (non-multi)layer
			beta = (ii==0)? oneC : compexp(pj[ii] * MyComplex(0,fabs(coefP[4*ii+2])));

			//this is the characteristic matrix of a layer
			MI[0][0]=beta;
			MI[0][1]=rj*beta;
			MI[1][1]=oneC/beta;
			MI[1][0]=rj*MI[1][1];

			temp2[0][0] = MRtotal[0][0];
			temp2[0][1] = MRtotal[0][1];
			temp2[1][0] = MRtotal[1][0];
			temp2[1][1] = MRtotal[1][1];
			//multiply MR,MI to get the updated total matrix.			
			matmul(temp2,MI,MRtotal);

		if(Vmullayers > 0 && ii == Vmulappend && Vmulrep > 0){
		//workout the wavevectors in each of the layers
			for(jj=1 ; jj < Vmullayers; jj++){
				pj_mul[jj] = (*(SLDmatrixREP+jj)>qq) ? compsqrt(qq2-MyComplex(*(SLDmatrixREP+jj),0)): MyComplex(sqrt(qq-*(SLDmatrixREP+jj)),0);
			}

			//work out the fresnel coefficients
			for(jj = 0 ; jj < Vmullayers; jj++){

				rj = (jj == Vmullayers-1) ?
				//if you're in the last layer then the roughness is the roughness of the top
				((pj_mul[jj]-pj_mul[0])/(pj_mul[jj]+pj_mul[0]))*compexp((pj_mul[jj]*pj_mul[0])*MyComplex(-2*coefP[offset+3]*coefP[offset+3],0))
				:
				//otherwise it's the roughness of the layer below
				((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
				
				//Beta's
				beta = compexp(MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]);

				MI[0][0]=beta;
				MI[0][1]=rj*beta;
				MI[1][1]=oneC/beta;
				MI[1][0]=rj*MI[1][1];

				temp2[0][0] = subtotal[0][0];
				temp2[0][1] = subtotal[0][1];
				temp2[1][0] = subtotal[1][0];
				temp2[1][1] = subtotal[1][1];

				matmul(temp2,MI,subtotal);
			};

			for(kk = 0; kk < Vmulrep; kk++){		//if you are in the last multilayer
				if(kk==Vmulrep-1){					//if you are in the last layer of the multilayer
					for(jj=0;jj<Vmullayers;jj++){
						beta = compexp((MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]));

						if(jj==Vmullayers-1){
							if(Vmulappend==nlayers){
								rj = ((pj_mul[Vmullayers-1]-pj[nlayers+1])/(pj_mul[Vmullayers-1]+pj[nlayers+1]))*compexp((pj_mul[Vmullayers-1]*pj[nlayers+1])*MyComplex(-2*subrough*subrough,0));
							} else {
								rj = ((pj_mul[Vmullayers-1]-pj[Vmulappend+1])/(pj_mul[Vmullayers-1]+pj[Vmulappend+1]))*compexp((pj_mul[Vmullayers-1]*pj[Vmulappend+1])*MyComplex(-2*coefP[4*(Vmulappend+1)+5]*coefP[4*(Vmulappend+1)+5],0));
							};
						} else {
							rj = ((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
						}

						MI[0][0]=beta;
						MI[0][1]=(rj*beta);
						MI[1][1]=oneC/beta;
						MI[1][0]=(rj*MI[1][1]);

						temp2[0][0] = MRtotal[0][0];
						temp2[0][1] = MRtotal[0][1];
						temp2[1][0] = MRtotal[1][0];
						temp2[1][1] = MRtotal[1][1];

						matmul(temp2,MI,MRtotal);
					}
				} else {
					temp2[0][0] = MRtotal[0][0];
					temp2[0][1] = MRtotal[0][1];
					temp2[1][0] = MRtotal[1][0];
					temp2[1][1] = MRtotal[1][1];
					
					matmul(temp2,subtotal,MRtotal);
				};
			};
		};

		}
		
		den=compnorm(MRtotal[0][0]);
		num=compnorm(MRtotal[1][0]);
		answer=(num)/(den);
		answer=(answer*scale)+bkg;

		*result = answer;
	
done:
	if(pj != NULL)
		delete [] pj;
	if(pj_mul !=NULL)
		delete[] pj_mul;
	if(SLDmatrix != NULL)
		delete[] SLDmatrix;
	if(SLDmatrixREP != NULL)
		delete[] SLDmatrixREP;

	return err;
}


static int
Abelescalc_imag(double *coefP, double x, double *result){
	int err = 0;
	
	int Vmulrep=0,Vmulappend=0,Vmullayers=0;
	double realVal,imagVal;
	int ii=0,jj=0,kk=0;

	double scale,bkg,subrough;
	double num=0,den=0, answer=0;

	MyComplex super;
	MyComplex sub;
	MyComplex temp,SLD,beta,rj,arg;
	MyComplex oneC = MyComplex(1,0);
	int offset=0;
	MyComplex MRtotal[2][2];
	MyComplex subtotal[2][2];
	MyComplex MI[2][2];
	MyComplex temp2[2][2];
	MyComplex qq2;
	MyComplex *pj_mul = NULL;
	MyComplex *pj = NULL;
	MyComplex *SLDmatrix = NULL;
	MyComplex *SLDmatrixREP = NULL;

	int nlayers = (int)coefP[0];
	
	try{
		pj = new MyComplex[nlayers+2];
		SLDmatrix = new MyComplex[nlayers+2];
	} catch(...){
		err = NOMEM;
		goto done;
	}

	memset(pj, 0, sizeof(pj));
	memset(SLDmatrix, 0, sizeof(SLDmatrix));

	scale = coefP[1];
	bkg = coefP[6];
	subrough = coefP[7];
	sub= MyComplex(coefP[4]*1e-6,coefP[5]);
	super = MyComplex(coefP[2]*1e-6,coefP[3]);

	//offset tells us where the multilayers start.
	offset = 4 * nlayers + 8;

	//fillout all the SLD's for all the layers
	for(ii=1; ii<nlayers+1;ii+=1){
		*(SLDmatrix+ii) = MyComplex(4*PI,0)*(MyComplex(coefP[4*ii+5]*1e-6,coefP[4*ii+6])-super);
	}
	*(SLDmatrix) = MyComplex(0,0);
	*(SLDmatrix+nlayers+1) = MyComplex(4*PI,0)*(sub-super);
	
	if(FetchNumVar("Vmullayers", &realVal, &imagVal)!=-1){ // Fetch value
		Vmullayers=(int)realVal;
		if(FetchNumVar("Vappendlayer", &realVal, &imagVal)!=-1) // Fetch value
			Vmulappend=(int)realVal;
		if(FetchNumVar("Vmulrep", &realVal, &imagVal) !=-1) // Fetch value
			Vmulrep=(int)realVal;

		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >= 0){
		//set up an array for wavevectors
			try{
				SLDmatrixREP = new MyComplex[Vmullayers];
				pj_mul = new MyComplex[Vmullayers];
			} catch(...){
				err = NOMEM;
				goto done;
			}
			memset(pj_mul, 0, sizeof(pj_mul));
			memset(SLDmatrixREP,0,sizeof(SLDmatrixREP));
			for(ii=0; ii<Vmullayers;ii+=1){
				*(SLDmatrixREP+ii) = MyComplex(4*PI,0)*(MyComplex(coefP[(4*ii)+offset+1]*1e-6,coefP[(4*ii)+offset+2])  - super);
		}
		}
	}

		//intialise the matrices
		memset(MRtotal,0,sizeof(MRtotal));
		MRtotal[0][0]=oneC;MRtotal[1][1]=oneC;

		qq2=MyComplex(x*x/4,0);

		for(ii=0; ii<nlayers+2 ; ii++){			//work out the wavevector in each of the layers
			pj[ii] = compsqrt(qq2-*(SLDmatrix+ii));
		}

		//workout the wavevector in the toplayer of the multilayer, if it exists.
		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >=0){
			memset(subtotal,0,sizeof(subtotal));
			subtotal[0][0]=MyComplex(1,0);subtotal[1][1]=MyComplex(1,0);
			pj_mul[0] = compsqrt(qq2-*SLDmatrixREP);
		}
		
		//now calculate reflectivities
		for(ii = 0 ; ii < nlayers+1 ; ii++){
			//work out the fresnel coefficient
			if(Vmullayers>0 && ii==Vmulappend && Vmulrep>0 ){
				rj=fres(pj[ii],pj_mul[0],coefP[offset+3]);
			} else {
				rj = (ii == nlayers) ?
					((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*subrough*subrough,0))
					:
					((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*coefP[4*(ii+1)+7]*coefP[4*(ii+1)+7],0));
			}

			//work out the beta for the (non-multi)layer
			beta = (ii==0)? oneC : compexp(pj[ii] * MyComplex(0,fabs(coefP[4*ii+4])));

			//this is the characteristic matrix of a layer
			MI[0][0]=beta;
			MI[0][1]=rj*beta;
			MI[1][1]=oneC/beta;
			MI[1][0]=rj*MI[1][1];

			temp2[0][0] = MRtotal[0][0];
			temp2[0][1] = MRtotal[0][1];
			temp2[1][0] = MRtotal[1][0];
			temp2[1][1] = MRtotal[1][1];
			//multiply MR,MI to get the updated total matrix.			
			matmul(temp2,MI,MRtotal);

		if(Vmullayers > 0 && ii == Vmulappend && Vmulrep > 0){
		//workout the wavevectors in each of the layers
			for(jj=1 ; jj < Vmullayers; jj++){
				pj_mul[jj] = compsqrt(qq2-*(SLDmatrixREP+jj));
			}

			//work out the fresnel coefficients
			for(jj = 0 ; jj < Vmullayers; jj++){
				rj = (jj == Vmullayers-1) ?
				//if you're in the last layer then the roughness is the roughness of the top
				((pj_mul[jj]-pj_mul[0])/(pj_mul[jj]+pj_mul[0]))*compexp((pj_mul[jj]*pj_mul[0])*MyComplex(-2*coefP[offset+3]*coefP[offset+3],0))
				:
				//otherwise it's the roughness of the layer below
				((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
				
				
				//Beta's
				beta = compexp(MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]);

				MI[0][0]=beta;
				MI[0][1]=rj*beta;
				MI[1][1]=oneC/MI[0][0];
				MI[1][0]=rj*MI[1][1];

				temp2[0][0] = subtotal[0][0];
				temp2[0][1] = subtotal[0][1];
				temp2[1][0] = subtotal[1][0];
				temp2[1][1] = subtotal[1][1];

				matmul(temp2,MI,subtotal);
			};

			for(kk = 0; kk < Vmulrep; kk++){		//if you are in the last multilayer
				if(kk==Vmulrep-1){					//if you are in the last layer of the multilayer
					for(jj=0;jj<Vmullayers;jj++){
						beta = compexp((MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]));

						if(jj==Vmullayers-1){
							if(Vmulappend==nlayers){
								rj = ((pj_mul[Vmullayers-1]-pj[nlayers+1])/(pj_mul[Vmullayers-1]+pj[nlayers+1]))*compexp((pj_mul[Vmullayers-1]*pj[nlayers+1])*MyComplex(-2*subrough*subrough,0));
							} else {
								rj = ((pj_mul[Vmullayers-1]-pj[Vmulappend+1])/(pj_mul[Vmullayers-1]+pj[Vmulappend+1]))*compexp((pj_mul[Vmullayers-1]*pj[Vmulappend+1])*MyComplex(-2*coefP[4*(Vmulappend+1)+7]*coefP[4*(Vmulappend+1)+7],0));
							};
						} else {
							rj = ((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
						}
						
						MI[0][0]=beta;
						MI[0][1]=rj*beta;
						MI[1][1]=MyComplex(1,0)/MI[0][0];
						MI[1][0]=rj*MI[1][1];

						temp2[0][0] = MRtotal[0][0];
						temp2[0][1] = MRtotal[0][1];
						temp2[1][0] = MRtotal[1][0];
						temp2[1][1] = MRtotal[1][1];

						matmul(temp2,MI,MRtotal);
					}
				} else {
					temp2[0][0] = MRtotal[0][0];
					temp2[0][1] = MRtotal[0][1];
					temp2[1][0] = MRtotal[1][0];
					temp2[1][1] = MRtotal[1][1];
					
					matmul(temp2,subtotal,MRtotal);
				};
			};
		};

		}
		
		den=compnorm(MRtotal[0][0]);

		num=compnorm(MRtotal[1][0]);
		answer=(num/den);//(num*num)/(den*den);
		answer=(answer*scale)+fabs(bkg);

		*result = answer;
	
done:
	if(pj != NULL)
		delete [] pj;
	if(pj_mul !=NULL)
		delete[] pj_mul;
	if(SLDmatrix != NULL)
		delete[] SLDmatrix;
	if(SLDmatrixREP != NULL)
		delete[] SLDmatrixREP;

	return err;	
}



static int 
AbelescalcAll(double *coefP, double *yP, double *xP,long npoints){
	int err = 0;
	int j;
	
	int Vmulrep=0,Vmulappend=0,Vmullayers=0;
	double realVal,imagVal;
	int ii=0,jj=0,kk=0;

	double scale,bkg,subrough;
	double num=0,den=0, answer=0,qq;
	double anum,anum2;
	MyComplex temp,SLD,beta,rj;
	double numtemp=0;
	int offset=0;
	MyComplex  MRtotal[2][2];
	MyComplex subtotal[2][2];
	MyComplex MI[2][2];
	MyComplex temp2[2][2];
	MyComplex qq2;
	MyComplex oneC = MyComplex(1,0);
	MyComplex *pj_mul = NULL;
	MyComplex *pj = NULL;
	double *SLDmatrix = NULL;
	double *SLDmatrixREP = NULL;

	int nlayers = (int)coefP[0];
	
	try{
		pj = new MyComplex [nlayers+2];
		SLDmatrix = new double [nlayers+2];
	} catch(...){
		err = NOMEM;
		goto done;
	}

	memset(pj, 0, sizeof(pj));
	memset(SLDmatrix, 0, sizeof(SLDmatrix));

	scale = coefP[1];
	bkg = fabs(coefP[4]);
	subrough = coefP[5];

	//offset tells us where the multilayers start.
	offset = 4 * nlayers + 6;

	//fillout all the SLD's for all the layers
	for(ii=1; ii<nlayers+1;ii+=1){
		numtemp = 1.e-6 * ((100. - coefP[4*ii+4])/100.) * coefP[4*ii+3]+ (coefP[4*ii+4]*coefP[3]*1.e-6)/100.;		//sld of the layer
		*(SLDmatrix+ii) = 4*PI*(numtemp  - (coefP[2]*1e-6));
	}
	*(SLDmatrix) = 0;
	*(SLDmatrix+nlayers+1) = 4*PI*((coefP[3]*1e-6) - (coefP[2]*1e-6));
	
	if(FetchNumVar("Vmullayers", &realVal, &imagVal)!=-1){ // Fetch value
		Vmullayers=(int)realVal;
		if(FetchNumVar("Vappendlayer", &realVal, &imagVal)!=-1) // Fetch value
			Vmulappend=(int)realVal;
		if(FetchNumVar("Vmulrep", &realVal, &imagVal) !=-1) // Fetch value
			Vmulrep=(int)realVal;

		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >= 0){
		//set up an array for wavevectors
			try{
				SLDmatrixREP = new double [Vmullayers];
				pj_mul = new MyComplex [Vmullayers];
			} catch(...){
				err = NOMEM;
				goto done;
			}
			memset(pj_mul, 0, sizeof(pj_mul));
			for(ii=0; ii<Vmullayers;ii+=1){
				numtemp = (coefP[3]*1e-6*coefP[(4*ii)+offset+2]/100) +(1e-6 * ((100 - coefP[(4*ii)+offset+2])/100) * coefP[(4*ii)+offset+1]);		//sld of the layer
				*(SLDmatrixREP+ii) = 4*PI*(numtemp  - (coefP[2]*1e-6));
			}
		}
	}
	
	for (j = 0; j < npoints; j++) {
		//intialise the matrices
		memset(MRtotal,0,sizeof(MRtotal));
		MRtotal[0][0] = oneC ; MRtotal[1][1] = oneC;

		qq = xP[j]*xP[j]/4;
		qq2=MyComplex(qq,0);

		for(ii=0; ii<nlayers+2 ; ii++){			//work out the wavevector in each of the layers
			pj[ii] = (*(SLDmatrix+ii)>qq) ? compsqrt(qq2-MyComplex(*(SLDmatrix+ii),0)): MyComplex(sqrt(qq-*(SLDmatrix+ii)),0);
		}
		
		//workout the wavevector in the toplayer of the multilayer, if it exists.
		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >=0){
			memset(subtotal,0,sizeof(subtotal));
			subtotal[0][0]=MyComplex(1,0);subtotal[1][1]=MyComplex(1,0);
			pj_mul[0] = (*(SLDmatrixREP)>qq) ? compsqrt(qq2-MyComplex(*SLDmatrixREP,0)): MyComplex(sqrt(qq-*SLDmatrixREP),0);
		}
		
		//now calculate reflectivities
		for(ii = 0 ; ii < nlayers+1 ; ii++){
			//work out the fresnel coefficients
			//this looks more complicated than it really is.
			//the reason it looks so convoluted is because if there is no complex part of the wavevector,
			//then it is faster to do the calc with real arithmetic then put it into a complex number.
			if(Vmullayers>0 && ii==Vmulappend && Vmulrep>0 ){
				rj=fres(pj[ii],pj_mul[0],coefP[offset+3]);
			} else {
				if((pj[ii]).im == 0 && (pj[ii+1]).im==0){
					anum = (pj[ii]).re;
					anum2 = (pj[ii+1]).re;
					rj = (ii==nlayers) ?
					MyComplex(((anum-anum2)/(anum+anum2))*exp(anum*anum2*-2*subrough*subrough),0)
					:
					MyComplex(((anum-anum2)/(anum+anum2))*exp(anum*anum2*-2*coefP[4*(ii+1)+5]*coefP[4*(ii+1)+5]),0);
				} else {
					rj = (ii == nlayers) ?
						((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*subrough*subrough,0))
						:
						((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*coefP[4*(ii+1)+5]*coefP[4*(ii+1)+5],0));	
				};
			}

			//work out the beta for the (non-multi)layer
			beta = (ii==0)? oneC : compexp(pj[ii] * MyComplex(0,fabs(coefP[4*ii+2])));

			//this is the characteristic matrix of a layer
			MI[0][0]=beta;
			MI[0][1]=rj*beta;
			MI[1][1]=oneC/beta;
			MI[1][0]=rj*MI[1][1];

			temp2[0][0] = MRtotal[0][0];
			temp2[0][1] = MRtotal[0][1];
			temp2[1][0] = MRtotal[1][0];
			temp2[1][1] = MRtotal[1][1];
			//multiply MR,MI to get the updated total matrix.			
			matmul(temp2,MI,MRtotal);

		if(Vmullayers > 0 && ii == Vmulappend && Vmulrep > 0){
		//workout the wavevectors in each of the layers
			for(jj=1 ; jj < Vmullayers; jj++){
				pj_mul[jj] = (*(SLDmatrixREP+jj)>qq) ? compsqrt(qq2-MyComplex(*(SLDmatrixREP+jj),0)): MyComplex(sqrt(qq-*(SLDmatrixREP+jj)),0);
			}

			//work out the fresnel coefficients
			for(jj = 0 ; jj < Vmullayers; jj++){

				rj = (jj == Vmullayers-1) ?
				//if you're in the last layer then the roughness is the roughness of the top
				((pj_mul[jj]-pj_mul[0])/(pj_mul[jj]+pj_mul[0]))*compexp((pj_mul[jj]*pj_mul[0])*MyComplex(-2*coefP[offset+3]*coefP[offset+3],0))
				:
				//otherwise it's the roughness of the layer below
				((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
				
				//Beta's
				beta = compexp(MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]);

				MI[0][0]=beta;
				MI[0][1]=rj*beta;
				MI[1][1]=oneC/beta;
				MI[1][0]=rj*MI[1][1];

				temp2[0][0] = subtotal[0][0];
				temp2[0][1] = subtotal[0][1];
				temp2[1][0] = subtotal[1][0];
				temp2[1][1] = subtotal[1][1];

				matmul(temp2,MI,subtotal);
			};

			for(kk = 0; kk < Vmulrep; kk++){		//if you are in the last multilayer
				if(kk==Vmulrep-1){					//if you are in the last layer of the multilayer
					for(jj=0;jj<Vmullayers;jj++){
						beta = compexp((MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]));

						if(jj==Vmullayers-1){
							if(Vmulappend==nlayers){
								rj = ((pj_mul[Vmullayers-1]-pj[nlayers+1])/(pj_mul[Vmullayers-1]+pj[nlayers+1]))*compexp((pj_mul[Vmullayers-1]*pj[nlayers+1])*MyComplex(-2*subrough*subrough,0));
							} else {
								rj = ((pj_mul[Vmullayers-1]-pj[Vmulappend+1])/(pj_mul[Vmullayers-1]+pj[Vmulappend+1]))*compexp((pj_mul[Vmullayers-1]*pj[Vmulappend+1])*MyComplex(-2*coefP[4*(Vmulappend+1)+5]*coefP[4*(Vmulappend+1)+5],0));
							};
						} else {
							rj = ((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
						}

						MI[0][0]=beta;
						MI[0][1]=(rj*beta);
						MI[1][1]=oneC/beta;
						MI[1][0]=(rj*MI[1][1]);

						temp2[0][0] = MRtotal[0][0];
						temp2[0][1] = MRtotal[0][1];
						temp2[1][0] = MRtotal[1][0];
						temp2[1][1] = MRtotal[1][1];

						matmul(temp2,MI,MRtotal);
					}
				} else {
					temp2[0][0] = MRtotal[0][0];
					temp2[0][1] = MRtotal[0][1];
					temp2[1][0] = MRtotal[1][0];
					temp2[1][1] = MRtotal[1][1];
					
					matmul(temp2,subtotal,MRtotal);
				};
			};
		};

		}
		
		den=compnorm(MRtotal[0][0]);
		num=compnorm(MRtotal[1][0]);
		answer=((num/den)*scale)+bkg;

		*yP++ = answer;
	}
	
done:
	if(pj != NULL)
		delete [] pj;
	if(pj_mul !=NULL)
		delete[] pj_mul;
	if(SLDmatrix != NULL)
		delete[] SLDmatrix;
	if(SLDmatrixREP != NULL)
		delete[] SLDmatrixREP;

	return err;
}


static int
Abelescalc_imagAll(double *coefP, double *yP, double *xP,long npoints){
	int err = 0;
	int j;
	
	int Vmulrep=0,Vmulappend=0,Vmullayers=0;
	double realVal,imagVal;
	int ii=0,jj=0,kk=0;

	double scale,bkg,subrough;
	double num=0,den=0, answer=0;

	MyComplex super;
	MyComplex sub;
	MyComplex temp,SLD,beta,rj,arg;
	MyComplex oneC = MyComplex(1,0);
	int offset=0;
	MyComplex MRtotal[2][2];
	MyComplex subtotal[2][2];
	MyComplex MI[2][2];
	MyComplex temp2[2][2];
	MyComplex qq2;
	MyComplex *pj_mul = NULL;
	MyComplex *pj = NULL;
	MyComplex *SLDmatrix = NULL;
	MyComplex *SLDmatrixREP = NULL;

	int nlayers = (int)coefP[0];
	
	try{
		pj = new MyComplex[nlayers+2];
		SLDmatrix = new MyComplex[nlayers+2];
	} catch(...){
		err = NOMEM;
		goto done;
	}

	memset(pj, 0, sizeof(pj));
	memset(SLDmatrix, 0, sizeof(SLDmatrix));

	scale = coefP[1];
	bkg = coefP[6];
	subrough = coefP[7];
	sub= MyComplex(coefP[4]*1e-6,coefP[5]);
	super = MyComplex(coefP[2]*1e-6,coefP[3]);

	//offset tells us where the multilayers start.
	offset = 4 * nlayers + 8;

	//fillout all the SLD's for all the layers
	for(ii=1; ii<nlayers+1;ii+=1){
		*(SLDmatrix+ii) = MyComplex(4*PI,0)*(MyComplex(coefP[4*ii+5]*1e-6,coefP[4*ii+6])-super);
	}
	*(SLDmatrix) = MyComplex(0,0);
	*(SLDmatrix+nlayers+1) = MyComplex(4*PI,0)*(sub-super);
	
	if(FetchNumVar("Vmullayers", &realVal, &imagVal)!=-1){ // Fetch value
		Vmullayers=(int)realVal;
		if(FetchNumVar("Vappendlayer", &realVal, &imagVal)!=-1) // Fetch value
			Vmulappend=(int)realVal;
		if(FetchNumVar("Vmulrep", &realVal, &imagVal) !=-1) // Fetch value
			Vmulrep=(int)realVal;

		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >= 0){
		//set up an array for wavevectors
			try{
				SLDmatrixREP = new MyComplex[Vmullayers];
				pj_mul = new MyComplex[Vmullayers];
			} catch(...){
				err = NOMEM;
				goto done;
			}
			memset(pj_mul, 0, sizeof(pj_mul));
			memset(SLDmatrixREP,0,sizeof(SLDmatrixREP));
			for(ii=0; ii<Vmullayers;ii+=1){
				*(SLDmatrixREP+ii) = MyComplex(4*PI,0)*(MyComplex(coefP[(4*ii)+offset+1]*1e-6,coefP[(4*ii)+offset+2])  - super);
		}
		}
	}


	for (j = 0; j < npoints; j++) {
		//intialise the matrices
		memset(MRtotal,0,sizeof(MRtotal));
		MRtotal[0][0]=oneC;MRtotal[1][1]=oneC;

		qq2=MyComplex(xP[j]*xP[j]/4,0);

		for(ii=0; ii<nlayers+2 ; ii++){			//work out the wavevector in each of the layers
			pj[ii] = compsqrt(qq2-*(SLDmatrix+ii));
		}

		//workout the wavevector in the toplayer of the multilayer, if it exists.
		if(Vmullayers > 0 && Vmulrep > 0 && Vmulappend >=0){
			memset(subtotal,0,sizeof(subtotal));
			subtotal[0][0]=MyComplex(1,0);subtotal[1][1]=MyComplex(1,0);
			pj_mul[0] = compsqrt(qq2-*SLDmatrixREP);
		}
		
		//now calculate reflectivities
		for(ii = 0 ; ii < nlayers+1 ; ii++){
			//work out the fresnel coefficient
			if(Vmullayers>0 && ii==Vmulappend && Vmulrep>0 ){
				rj=fres(pj[ii],pj_mul[0],coefP[offset+3]);
			} else {
				rj = (ii == nlayers) ?
					((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*subrough*subrough,0))
					:
					((pj[ii]-pj[ii+1])/(pj[ii]+pj[ii+1]))*compexp(pj[ii]*pj[ii+1]*MyComplex(-2*coefP[4*(ii+1)+7]*coefP[4*(ii+1)+7],0));
			}

			//work out the beta for the (non-multi)layer
			beta = (ii==0)? oneC : compexp(pj[ii] * MyComplex(0,fabs(coefP[4*ii+4])));

			//this is the characteristic matrix of a layer
			MI[0][0]=beta;
			MI[0][1]=rj*beta;
			MI[1][1]=oneC/beta;
			MI[1][0]=rj*MI[1][1];

			temp2[0][0] = MRtotal[0][0];
			temp2[0][1] = MRtotal[0][1];
			temp2[1][0] = MRtotal[1][0];
			temp2[1][1] = MRtotal[1][1];
			//multiply MR,MI to get the updated total matrix.			
			matmul(temp2,MI,MRtotal);

		if(Vmullayers > 0 && ii == Vmulappend && Vmulrep > 0){
		//workout the wavevectors in each of the layers
			for(jj=1 ; jj < Vmullayers; jj++){
				pj_mul[jj] = compsqrt(qq2-*(SLDmatrixREP+jj));
			}

			//work out the fresnel coefficients
			for(jj = 0 ; jj < Vmullayers; jj++){
				rj = (jj == Vmullayers-1) ?
				//if you're in the last layer then the roughness is the roughness of the top
				((pj_mul[jj]-pj_mul[0])/(pj_mul[jj]+pj_mul[0]))* compexp((pj_mul[jj]*pj_mul[0])*MyComplex(-2*coefP[offset+3]*coefP[offset+3],0))
				:
				//otherwise it's the roughness of the layer below
				((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
				
				
				//Beta's
				beta = compexp(MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]);

				MI[0][0]=beta;
				MI[0][1]=rj*beta;
				MI[1][1]=oneC/beta;
				MI[1][0]=rj*MI[1][1];

				temp2[0][0] = subtotal[0][0];
				temp2[0][1] = subtotal[0][1];
				temp2[1][0] = subtotal[1][0];
				temp2[1][1] = subtotal[1][1];

				matmul(temp2,MI,subtotal);
			};

			for(kk = 0; kk < Vmulrep; kk++){		//if you are in the last multilayer
				if(kk==Vmulrep-1){					//if you are in the last layer of the multilayer
					for(jj=0;jj<Vmullayers;jj++){
						beta = compexp((MyComplex(0,fabs(coefP[4*jj+offset]))*pj_mul[jj]));

						if(jj==Vmullayers-1){
							if(Vmulappend==nlayers){
								rj = ((pj_mul[Vmullayers-1]-pj[nlayers+1])/(pj_mul[Vmullayers-1]+pj[nlayers+1]))*compexp((pj_mul[Vmullayers-1]*pj[nlayers+1])*MyComplex(-2*subrough*subrough,0));
							} else {
								rj = ((pj_mul[Vmullayers-1]-pj[Vmulappend+1])/(pj_mul[Vmullayers-1]+pj[Vmulappend+1]))* compexp((pj_mul[Vmullayers-1]*pj[Vmulappend+1])*MyComplex(-2*coefP[4*(Vmulappend+1)+7]*coefP[4*(Vmulappend+1)+7],0));
							};
						} else {
							rj = ((pj_mul[jj]-pj_mul[jj+1])/(pj_mul[jj]+pj_mul[jj+1]))*compexp((pj_mul[jj]*pj_mul[jj+1])*MyComplex(-2*coefP[4*(jj+1)+offset+3]*coefP[4*(jj+1)+offset+3],0));
						}
						
						MI[0][0]=beta;
						MI[0][1]=rj*beta;
						MI[1][1]=MyComplex(1,0)/MI[0][0];
						MI[1][0]=rj*MI[1][1];

						temp2[0][0] = MRtotal[0][0];
						temp2[0][1] = MRtotal[0][1];
						temp2[1][0] = MRtotal[1][0];
						temp2[1][1] = MRtotal[1][1];

						matmul(temp2,MI,MRtotal);
					}
				} else {
					temp2[0][0] = MRtotal[0][0];
					temp2[0][1] = MRtotal[0][1];
					temp2[1][0] = MRtotal[1][0];
					temp2[1][1] = MRtotal[1][1];
					
					matmul(temp2,subtotal,MRtotal);
				};
			};
		};

		}
		
		den= compnorm(MRtotal[0][0]);
		num=compnorm(MRtotal[1][0]);
		answer=(num/den);//(num*num)/(den*den);
		answer=(answer*scale)+fabs(bkg);

		*yP++ = answer;
	}
	
done:
	if(pj != NULL)
		delete [] pj;
	if(pj_mul !=NULL)
		delete[] pj_mul;
	if(SLDmatrix != NULL)
		delete[] SLDmatrix;
	if(SLDmatrixREP != NULL)
		delete[] SLDmatrixREP;

	return err;
}


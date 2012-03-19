#pragma rtGlobals=1		// Use modern global access method.
#include "MOTOFIT_all_at_once"
ThreadSafe Function motoMCWorkerFunc()
	do
		do
			DFRef tdf  =ThreadGroupGetDFR(0,1000)	
			if(!Datafolderrefstatus(tdf))
				if( GetRTError(2) )	// New in 6.2 to allow this distinction:
					Print "worker closing down due to group release"
				else
					Print "worker thread still waiting for input queue"
				endif
			else
				break
			endif
		while(1)

		SetDataFolder tdf

		Wave/z wtemp, yytemp, xxtemp, eetemp, holdwavetemp, limitstemp
		SVAR fntemp
		NVAR iterstemp
		NVAR popsizetemp  
		NVAR recombtemp  
		NVAR k_mtemp  
		NVAR fittoltemp 
		NVAR fakeweighttemp
		variable/g V_Fiterror
		if(fakeweighttemp)
			yytemp = yytemp + gnoise(eetemp)
			Gencurvefit/q/n/hold=holdwavetemp/X=xxtemp/K={iterstemp, popsizetemp, k_mtemp, recombtemp}/TOL=(fittoltemp) $fntemp, yytemp, wtemp, "", limitstemp
		else
			Gencurvefit/MC/q/n/hold=holdwavetemp/X=xxtemp/I=1/W=eetemp/K={iterstemp, popsizetemp, k_mtemp, recombtemp}/TOL=(fittoltemp) $fntemp, yytemp, wtemp, "", limitstemp
		endif		
//		print V_chisq,V_fitIters, V_fiterror
		Setdatafolder ::
		NewDataFolder/S outDF
		
		make/n=(dimsize(wtemp, 0))/d W_output
		W_output = wtemp
		Waveclear wtemp, yytemp, xxtemp, eetemp, holdwavetemp, limitstemp, W_output
		ThreadGroupPutDF 0,:		
		KillDataFolder tdf		// We are done with the input data folder
	while(1)

	return 0
End

Threadsafe function momo(w, yy, xx):fitfunc
Wave w, yy, xx
AbelesAll(w, yy, xx)
yy = log(yy)
End

Function motoMC_parallel(fn, w, yy, xx, ee, holdwave, Iters, [limits, cursA, cursB, fakeweight])
	String fn
	Wave w, yy, xx, ee, holdwave
	variable Iters
	Wave/z limits
	variable cursA, cursB
	variable fakeweight //fake weight means that you know the weights, but aren't prepared to weight the data as well.

	string saveDF = GetDataFolder(1)

	Variable ii, nthreads= ThreadProcessorCount
	string holdstring
	
	try
		if(paramisdefault(limits) && !waveexists(limits))
			SOCKITwavetostring/txt="" holdwave, holdstring
			GEN_setlimitsforGENcurvefit(w, holdstring)
			Wave limits = root:packages:motofit:old_genoptimise:GENcurvefitlimits
			NVAR  iterations = root:packages:motofit:old_genoptimise:iterations
			NVAR  popsize = root:packages:motofit:old_genoptimise:popsize
			NVAR recomb =  root:packages:motofit:old_genoptimise:recomb
			NVAR k_m =  root:packages:motofit:old_genoptimise:k_m
			NVAR fittol = root:packages:motofit:old_genoptimise:fittol
		endif
	
		
	variable/G tgID= ThreadGroupCreate(nthreads)
	for(ii =0 ; ii < nthreads ; ii += 1)
		ThreadStart tgID, ii, motoMCWorkerFunc()
	endfor
	
	for(ii = 0 ; ii < iters ; ii += 1)
		NewDataFolder/S $(saveDF+"forThread")
      	duplicate w, wtemp
		duplicate yy, yytemp
		duplicate xx, xxtemp
		duplicate ee, eetemp
		duplicate holdwave, holdwavetemp
		duplicate limits, limitstemp
		string/g fntemp = fn
		variable/g iterstemp = iterations
		variable/g popsizetemp = popsize
		variable/g recombtemp = recomb
		variable/g k_mtemp = k_m
		variable/g fittoltemp = fittol
		variable/g fakeweighttemp = fakeweight
		waveclear wtemp, yytemp, xxtemp, eetemp, holdwavetemp, limitstemp
		ThreadGroupPutDF tgID, :
	endfor

	make/n=(iters, dimsize(w, 0))/o/d M_Montecarlo = 0
	for(ii = 0 ; ii < iters ; ii += 1)
		print ii
		do
			DFREF dfr= ThreadGroupGetDFR(tgID,1000)	// Get results in free data folder
			if ( DatafolderRefStatus(dfr) == 0 )
				Print "Main still waiting for worker thread results"
			else
				break
			endif
		while(1)
		Wave/sdfr=dfr W_output
		M_Montecarlo[ii][] = W_output[q]
		
		// The next two statements are not really needed as the same action
		// will happen the next time through the loop or, for the last iteration,
		// when this function returns.
		WAVEClear W_output
		KillDataFolder dfr
	endfor
	
	catch
		SetDataFolder saveDF			// and restore
	endtry
	
		// This terminates the MyWorkerFunc by setting an abort flag
	Variable tstatus= ThreadGroupRelease(tgID)
	if( tstatus == -2 )
		Print "Thread would not quit normally, had to force kill it. Restart Igor."
	endif
	SetDataFolder saveDF			// and restore

End

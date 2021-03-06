#! /bin/csh


#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-
#                                                                        
#    3dDeconvolve Regression
#
#    Auto-generated by ScriptWriter.py
#    kiefer katovich 2012
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-

cd ..
set MAINDIR = $PWD
# set MAINDIR = ${HOME}/cueexp
set SCRIPTSDIR = ${MAINDIR}/scripts
set DATADIR = ${MAINDIR}/data

# define directories w/behavior data (INDIR) and for saving out regs (OUTDIR)
# directories are relative to subject specific dir
set INDIR = behavior 	
set OUTDIR = regs 	

# set to 1 to use last vols of run, otherwise 0
set wEND = 1
if ($wEND == 1) then
	set REGFILE = mid_vecs_wEnd.txt
	set nvols = 548
else 	
	set REGFILE = mid_vecs.txt
	set nvols = 540
endif	



#-#-#-#-#-#-#-#-#-#-#-		Cycle through subjects:		-#-#-#-#-#-#-#-#-#-#-#


foreach subject ( subj002 subj003 )

    cd ${DATADIR}/${subject}
    echo processing ${subject} 

    if (! -d ${OUTDIR}) then
		mkdir ${OUTDIR}
	endif

	cd ${INDIR}



#-#-#-#-#-#-#-#-#-#-#-		Run makeVec on model file:		-#-#-#-#-#-#-#-#-#-#-#

	
	python ${SCRIPTSDIR}/makeVec.py ${SCRIPTSDIR}/${REGFILE}
	


#-#-#-#-#-#-#-#-#-#-#-		Run waver on vectors:		-#-#-#-#-#-#-#-#-#-#-#

	waver -dt 2.0 -GAM -numout ${nvols} -input ant_mid.1D > ant_midc.1D
	waver -dt 2.0 -GAM -numout ${nvols} -input out_mid.1D > out_midc.1D
	waver -dt 2.0 -GAM -numout ${nvols} -input gvn_ant_mid.1D > gvn_ant_midc.1D
	waver -dt 2.0 -GAM -numout ${nvols} -input lvn_ant_mid.1D > lvn_ant_midc.1D
	waver -dt 2.0 -GAM -numout ${nvols} -input gvn_out_mid.1D > gvn_out_midc.1D
	waver -dt 2.0 -GAM -numout ${nvols} -input nvl_out_mid.1D > nvl_out_midc.1D
	waver -dt 2.0 -GAM -numout ${nvols} -input lvn_out_mid.1D > lvn_out_midc.1D

	mv *1D ../${OUTDIR}

end

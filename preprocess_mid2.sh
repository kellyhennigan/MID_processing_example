#!/bin/bash

##############################################

# usage: process anatomy for MID data
# for P50 project

# written by Kelly MacNiven, Nov 12, 2019

# assumes raw data are stored within the following directory structure:

	# mainDir/data/subjid/raw

# where subjid is subject id. Processed data will be saved out to: 
	
	# mainDir/data/subjid/func_proc

# output files are: 

	# pp_mid.nii.gz - pre-processed mid data, both runs concatenated
	# mid_enorm.1D - vector containing an estimate of movement (euclidean norm) from each volume to the next
	# mid_censor.1D - vector containing 0 for volumes with bad movement, otherwise 1
	# mid_vr.1D - matrix with the following columns: 
		# 1 is the volume number, 
		# 2-7 are the 6 motion parameter estimates, 
		# 8-9 are root mean square error from 1 volume to the next before (8) and after (9) motion correction



########################## DEFINE VARIABLES #############################


# dataDir is the parent directory of subject-specific directories
# define main directory & data dir
cd ..
mainDir=$(pwd)
dataDir=$mainDir/data 

# anatomical template in mni space
t1_template=$mainDir/templates/TT_N27.nii # %s is data_dir
func_template=$mainDir/templates/TT_N27_func_dim.nii # %s is data_dir


# subject ids to process (assumes directory structure is dataDir/subjid, e)
subjects='subj002'  # e.g. 'jj180618 ab180619 cd180620'

runs='1 2' # 2 runs of data

############################# RUN IT ###################################

for subject in $subjects
do
	
	echo WORKING ON SUBJECT $subject

	# subject input & output directories
	inDir=$dataDir/$subject/raw
	outDir=$dataDir/$subject/func_proc


	# make outDir if it doesn't exist & cd to it: 
	if [ ! -d "$outDir" ]; then
		mkdir $outDir
	fi 	
	cd $outDir


	for run in $runs
	do

		echo WORKING ON RUN $RUN

		# drop the first 6 volumes to allow longitudinal magentization (t1) to reach steady state
		3dTcat -output mid$run.nii.gz $inDir/mid$run.nii.gz[6..$]


		# correct for slice time differences
		3dTshift -prefix tmid$run.nii.gz -slice 0 -tpattern altplus mid$run.nii.gz


		# pull out a reference volume for motion correction and for later checking out coregistration between functional and structural data 
		if [ $run = '1' ];
		then
			3dTcat -output ref_mid.nii.gz tmid1.nii.gz[4]
		fi


		# motion correction & saves out the motion parameters in file, 'mid1_vr.1D' 
		3dvolreg -Fourier -twopass -zpad 4 -dfile vr_mid$run.1D -base ref_mid.nii.gz -prefix mtmid$run.nii.gz tmid$run.nii.gz


		# create a “censor vector” that denotes bad movement volumes with a 0 and good volumes with a 1
		# to be used later for glm estimation and making timecourses
		1d_tool.py -infile vr_mid$run.1D[1..6] -show_censor_count -censor_prev_TR -censor_motion 0.5 mid$run


		# smooth data with a 4 mm full width half max gaussian kernel
		3dmerge -1blur_fwhm 4 -doall -quiet -prefix smtmid$run.nii.gz mtmid$run.nii.gz


		# calculate the mean timeseries for each voxel
		3dTstat -mean -prefix mean_mid$run.nii.gz smtmid$run.nii.gz


		# convert voxel values to be percent signal change
		cmd="3dcalc -a smtmid${run}.nii.gz -b mean_mid${run}.nii.gz -expr \"((a-b)/b)*100\" -prefix psmtmid${run}.nii.gz -datum float"
		echo $cmd	# print it out in terminal 
		eval $cmd	# execute the command
	

		# high-pass filter the data 
		3dFourier -highpass 0.011 -prefix fpsmtmid$run.nii.gz psmtmid$run.nii.gz

	
		echo DONE WITH RUN $RUN


	done # run loop


	# concatenate pre-processed data for runs 1 & 2
	3dTcat -output pp_mid.nii.gz fpsmtmid1.nii.gz fpsmtmid2.nii.gz


	# clear out any pre-existing concatenated motion files 
	rm mid_vr.1D; rm mid_censor.1D; rm mid_enorm.1D


	# concatenate motion files 
	cat  vr_mid1.1D vr_mid2.1D >> mid_vr.1D
	cat  mid1_censor.1D mid2_censor.1D >> mid_censor.1D
	cat  mid1_enorm.1D mid2_enorm.1D >> mid_enorm.1D


	# # remove intermediate files 
	# # NOTE: ONLY DO THIS ONCE YOU'RE CONFIDENT THAT THE PIPELINE IS WORKING! 
	# # (because you may want to view intermediate files to troubleshoot the pipeline)
	# rm *mid2*
	# rm *mid1*


######################## transform to tlrc space

	3dAllineate -base t1_tlrc.nii.gz -1Dmatrix_apply xfs/mid2tlrc_xform -prefix pp_mid_tlrc -input pp_mid.nii.gz -verb -master BASE -mast_dxyz 2.9 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -onepass

	3dAFNItoNIFTI -prefix pp_mid_tlrc.nii.gz pp_mid_tlrc+tlrc

	rm pp_mid_tlrc+tlrc*


######################## create WM, CSF, insula and nacc time series

	3dmaskave -mask $mainDir/templates/csf_func.nii -quiet -mrange 1 2 pp_mid_tlrc.nii.gz > mid_csf_ts.1D

	3dmaskave -mask $mainDir/templates/wm_func.nii -quiet -mrange 1 2 pp_mid_tlrc.nii.gz > mid_wm_ts.1D

	3dmaskave -mask $mainDir/templates/nacc_desai_func.nii -quiet -mrange 1 2 pp_mid_tlrc.nii.gz > mid_nacc_ts.1D

	3dmaskave -mask $mainDir/templates/ins_desai_func.nii -quiet -mrange 1 2 pp_mid_tlrc.nii.gz > mid_ins_ts.1D

########################

done # subject loop



#!/bin/bash

##############################################

# usage: process anatomy for MID data

# written by Kelly MacNiven, Nov 12, 2019

# assumes raw data are stored within the following directory structure:

	# mainDir/data/subjid/raw

# where subjid is subject id. Processed data will be saved out to: 
	
	# mainDir/data/subjid/func_proc


###########################################

###### IMPORTANT: VISUALLY CHECK CO-REGISTRATION BEFORE MOVING ON!! 

# once this script finishes for a subject, check to make sure the subject's
# functional data looks good in MNI space. To do this, temporarily copy the file
# mni_ns.nii.gz into the subject's func_proc directory. 

# this should give you the following files in the subject's func_proc folder (among others):

# mni_ns.nii.gz - MNI template that subjects' data is aligned to
# t1_mni.nii.gz - subject's anatomical data in MNI space
# mid_vol1_mni.nii.gz - the first volume of the subject's mid data aligned in MNI space

# check to make sure subject's data in mni space looks well-aligned. 
# Do this from afni viewer by loading:
# 	- mni_ns.nii.gz as underlay & t1_mni.nii.gz as overlay, then
#   - t1_mni.nii.gz as underlay & mid_vol1_mni.nii.gz as overlay

# If these don't look good, it's likely because the alignment between 
# a subject's anatomy & functional data messed up. You'll have to 
# "nudge" the subject's anatomical data to make it closer in space 
# to the functional data, save out the "nudged" anatomical volume, and 
# re-run this script using the nudged anatomy instead of the raw anatomy. 

# to do that: 
# open afni from subject's raw dir, 
# > plugins> NUDGE
# > nudge t1 file to match raw functional data (you can use the file, "mid_vol1.nii.gz" in the subject's raw dir )
# > say "print" to print out nudge command and apply it to t1 data, eg: 
# 3drotate -quintic -clipit -rotate 0.00I 0.00R 0.00A -ashift 0.00S 0.00L 0.00P -prefix t1w_nudge.nii.gz raw_t1w.nii.gz
# then, delete all files previously created by this script for the subject, 
# and re-run the script using the nudged anatomical nii for the "rawt1files" variable





########################## DEFINE VARIABLES #############################



# define main directory & data dir
cd ..
mainDir=$(pwd)
dataDir=$mainDir/data 


# anatomical template in mni space
t1_template=$mainDir/templates/TT_N27.nii # %s is data_dir
func_template=$mainDir/templates/TT_N27_func_dim.nii # %s is data_dir


# subject ids to process (assumes directory structure is dataDir/subjid, e)
subjects='subj002'  # e.g., subjects=('subj001 subj002 subj003')


# assumes these files are in directory: $dataDir/subjid/raw
rawt1_file='t1_raw.nii.gz'
rawmid_file='raw_mid.nii.gz'


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


	# also make a "xfs" directory within outDir to house all xform files
	if [ ! -d xfs ]; then
		mkdir xfs
	fi 	


	# remove skull from t1 anatomical data
	3dSkullStrip -prefix t1_ns.nii.gz -input $inDir/t1_raw.nii.gz


	# estimate transform to put t1 in tlrc space
	@auto_tlrc -no_ss -base $t1_template -suffix _tlrc -input t1_ns.nii.gz


	# clean files
	gzip t1_ns_tlrc.nii; 
	mv t1_ns_tlrc.nii.gz t1_tlrc.nii.gz; 
	mv t1_ns_tlrc.Xat.1D xfs/t12tlrc_xform; 
	mv t1_ns_tlrc.nii_WarpDrive.log xfs/t12tlrc_xform.log; 
	rm t1_ns_tlrc.nii.Xaff12.1D


	# take first volume of raw functional data:
	3dTcat -output $inDir/vol1_mid.nii.gz $inDir/mid1.nii.gz[0]

	
	# skull-strip functional vol
	3dSkullStrip -prefix vol1_mid_ns.nii.gz -input $inDir/vol1_mid.nii.gz


	# estimate xform between anatomy and functional data
	align_epi_anat.py -epi2anat -epi vol1_mid_ns.nii.gz -anat t1_ns.nii.gz -epi_base 0 -tlrc_apar t1_tlrc.nii.gz -epi_strip None -anat_has_skull no

	
	# put in nifti format 
	3dAFNItoNIFTI -prefix vol1_mid_tlrc.nii.gz vol1_mid_ns_tlrc_al+tlrc
	3dAFNItoNIFTI -prefix vol1_mid_ns_al.nii.gz vol1_mid_ns_al+orig

	# clean files
	rm vol1_mid_ns_tlrc_al+tlrc*
	mv t1_ns_al_mat.aff12.1D xfs/t12mid_xform; 
	mv vol1_mid_ns_al_mat.aff12.1D xfs/mid2t1_xform; 
	mv vol1_mid_ns_al_tlrc_mat.aff12.1D xfs/mid2tlrc_xform; 
	rm vol1_mid_ns_al_reg_mat.aff12.1D; 
	rm vol1_mid_ns_al+orig*


done # subject loop



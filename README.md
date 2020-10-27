# Processing pipeline for fmrieat project 

This repository has code for pre-processing and analyzing functional mri (fmri) data during the Monetary Incentive Delay (MID) task. We will analyze data from 2 subjects. Each subject performed the MID task over 2 scan runs with the following info: 

- 6 conditions (0,1,5 gain/loss trials)
- 15 trials per condition, so 90 trials total
- trial timing: 
	* 0-2 s: cue presentation 
	* 4.25-5 s: target "window" (i.e., target will appear sometime within this time window)
	* 6-8 s: outcome presentation
	* intertrial interval (ITI) of either 2, 4 or 6 s, averaging 4 s across all trials


## Getting started


### Software requirements 

* [Python 2.7](https://www.python.org/)
* [Matlab](https://www.mathworks.com/products/matlab.html)
* [AFNI](https://afni.nimh.nih.gov/) (fmri pipeline only)


### Permissions

make sure the user has permission to execute scripts. From a terminal command line, cd to the directory containing these scripts. Then type:
```
chmod 777 *sh
chmod 777 *py
```
to be able to execute them. This only needs to be run once. 


## fMRI pipeline

- [Check raw data](#check-raw-data)
- [Estimate transforms from subject's native to standard space](#estimate-transforms-from-subject's-native-to-standard-space)
- [Quality Assurance (QA) check the coregistation](#QA-coreg)
- [Pre-process fmri data](#pre-process-fmri-data)
- [QA check head motion](#QA-motion)
- [Get stimulus onset times and make regressors](#get-stimulus-onset-times-and-make-regressors)
- [Subject-level GLMs](#subject-level-glms)
- [Group-level whole brain analyses](#group-level-whole-brain-analyses)
- [Generate VOI timecourses](#generate-voi-timecourses)
- [Behavioral analyses](#behavioral-analyses)



### Check raw data 
Raw fMRI and anatomical data should be here, relative to your main project directory: 
* data/[subjid]/raw/mid1.nii.gz 		# 1st MID scan
* data/[subjid]/raw/mid2.nii.gz 		# 2nd MID scan
* data/[subjid]/raw/t1_raw.nii.gz 		# t1-weighted anatomical volume

Within the directory containing the raw MRI data, try running this afni command: 
```
3dinfo mid1.nii.gz
```
Use that command to confirm that the mid1 nifti file contains 262 volumes and that mid2 contains 298 volumes. 


Behavioral data should be here: 
* data/[subjid]/behavior/mid_matrix_wEnd.csv 	# stim timing file

Open up that file and confirm that there are 549 rows, including the header file. Because we use a "TR-locked" design, meaning that our trial timing is locked to the timing of fmri data acquisition, each row in the stim file will correspond to a volume of fmri data after we omit the first 6 volumes from each scan and concatenate the scans together. 



### Estimate transforms from subject's native to standard space
from a terminal command line, run: 
```
./preprocess_mid1.sh
```
this script does the following using AFNI commands:
* skull strips t1 data using afni command "3dSkullStrip"
* aligns skull-stripped t1 data to t1 template in tlrc space using afni command @auto_tlrc, which allows for a 12 parameter affine transform
* pulls out the first volume of functional data to be co-registered to anatomy and skullstrips this volume using "3dSkullStrip"
* coregisters anatomy to functional data, and then calculates the transform from native functional space to standard group space (tlrc space)

#### output 
this should create the directory, **data/[subjid]/func_proc**, which should contain: 		
* t1_ns.nii.gz 				# subject's t1 with no skull in native space
* t1_tlrc.nii.gz			# " " in standard (tlrc) space
* vol1_mid_ns.nii.gz 		# 1st vol of fmri data with no skull in native space
* vol1_mid_ns_al.nii.gz		# " " aligned to t1 in native space
* vol1_mid_tlrc.nii.gz		# " " in standard (tlrc) space
* xfs 						# sub-directory containing all estimated transforms



### Quality Assurance (QA) check the coregistation 
Visually check to make sure the coregistration looks alright. In afni viewer, load subject's anatomy and functional volume in tlrc space (files "t1_tlrc.nii.gz" and "vol1_mid_tlrc.nii.gz"). These should be reasonably aligned. If they aren't, that means 1) the anatomical <-> functional alignment in native space messed up (most likely), 2) the subject's anatomical <-> tlrc template alignment messed up, or 3) both messed up. 

Here's an example of decent coregistration: 
<p align="center">
  <img width="161" height="151" src="https://github.com/kellyhennigan/fmrieat/blob/master/coreg_examples/decent_coreg_y.jpg">
</p>

And here's an example of bad coregistration (where something went terribly wrong!)
<p align="center">
  <img width="161" height="151" src="https://github.com/kellyhennigan/fmrieat/blob/master/coreg_examples/bad_coreg_y.jpg">
</p>

**To correct bad coregistration: **

- if the problem appears to be bad alignment between a subject's anatomical and functional data (to check this, load files "t1_ns.nii.gz" and "vol1_mid_ns_al.nii.gz" in afni viewer), you may need to first manually "nudge" the subject's raw t1-weighted volume to be in better alignment with their functional data. To do that: 
* open afni in subject's raw directory, 
* > plugins> NUDGE
* > nudge t1 file to match functional volume 1 of mid1.nii.gz
* > say "print" to print out the nudge command and then apply it to t1 data, eg: 
```
3drotate -quintic -clipit -rotate 0.00I 0.00R 0.00A -ashift 0.00S 0.00L 0.00P -prefix t1_nudged.nii.gz t1_raw.nii.gz
```
* then re-run preprocess_mid1.sh script, only change the "rawt1_file" variable to the newly nudged t1 nifti file 

- if the problem appears to be bad alignment between a subject's anatomy & the anatomical template (to check this, load files "t1_tlrc.nii.gz" and "TT_N27.nii" in afni viewer; note you'll have to place a copy the TT_N27.nii file in the subject's func_proc directory), try using different options for the "@auto_tlrc" command (see documentation here: https://afni.nimh.nih.gov/pub/dist/doc/program_help/@auto_tlrc.html). 



### Pre-process fmri data
from a terminal command line, run:
```
./preprocess_mid2.sh
```
this script does the following using AFNI commands:
* removes first 6 volumes from functional scan (to allow t1 to reach steady state)
* slice time correction
* motion correction (6-parameter rigid body)
* saves out a vector of which volumes have lots of motion (will use this to censor volumes in glm estimation step)
* spatially smooths data 
* converts data to be in units of percent change (mean=100; so a value of 101 means 1% signal change above that voxel's mean signal)
* highpass filters the data to remove low frequency fluctuations
* transforms pre-processed functional data into standard group (tlrc) space using transforms estimated in "preprocess_mid1.sh" script
* saves out white matter, csf, and nacc VOI time series as single vector text files (e.g., 'mid_csf_ts.1D') 

#### output 
files saved out to directory **data/subjid/func_proc** are: 
* pp_mid.nii.gz				# pre-processed fmri data in native space
* pp_mid_tlrc.nii.gz		# " " in standard space
* mid_vr.1D					# volume-to-volume motion estimates (located in columns 2-7 of the file)
* mid_censor.1D 			# vector denoting which volumes to censor from glm estimation due to bad motion
* mid_enorm.1D 				# euclidean norm of volume-to-volume motion (combines x,y,z displacement and rotation)
* mid_[ROI_]ts.1D			# ROI time series files for a few relevant ROIs. 



### QA check head motion & spikes 

Now that we've estimated a subject's head motion, plot it to make sure it looks okay using afni's 1dplot command, e.g:  
```
1dplot mid_vr.1D[1..6] # plots all 6 displacement & rotation motion parameters 
```
or try: 
```
1dplot mid_enorm.1D # to plot a summary measure (euclidean norm) of volume-to-volume motion 
```
In general, we consider "bad" motion to be anything greater than a euclidean norm value of 0.5-1, and we censor timepoints with bad motion from our analyses. We also then decide on a threshold of how many "bad" timepoints a subject can have before they are excluded from analysis for bad motion. A typical value for this would be, say, 1% of the data (i.e., subject's that have bad motion in 1% or more of their volumes for a given task would be excluded from analysis). 

You might also want to plot some ROI timeseries to make sure they look okay (e.g., no strange spikes that can't be explained by head motion):
```
1dplot mid_nacc_ts.1D # plot NAcc ROI timeseries
```



### Get stimulus onset times and make regressors
In matlab, run: 
```
createRegs_script
```
this script loads behavioral data to get stimulus onset times and saves out regressors of interest. Saved out files each contain a single vector of length equal to the number of TRs in the task with mostly 0 entries, and than 1 to indicate when an event of interest occurs. These vectors are then convolved with an hrf using AFNI's waver command to model the hemodynamic response. 

Note that the output files from this script are used for estimating single-subject GLMs as well as for plotting VOI timecourses. 

#### output 
this should create directory **fmrieat/derivatives/subjid/regs** which should contain all the regressor and stimulus timing files. To check out regressor time series, from a terminal command line, cd to output "regs" directory, then type, e.g., `1dplot food_cue_cuec.1D`. 



### Subject-level GLMs
From terminal command line, run: 
```
python glm_mid.py
```
to specify GLM and fit that model to data using afni's 3dDeconvolve. There's excellent documentation on this command [here](https://afni.nimh.nih.gov/pub/dist/doc/manual/Deconvolvem.pdf). 

#### output 
saves out the following files to directory **fmrieat/derivatives/results_cue**:
* subjid_glm_B+tlrc 	# file containing only beta coefficients for each regressor in GLM
* subjid_glm+tlrc 		# file containing a bunch of GLM stats
To check out glm results, open these files in afni as an overlay (with, e.g., TT_N27.nii as underlay). You can also get info about these files using afni's 3dinfo command, e.g., from the terminal command line, `3dinfo -verb subjid_glm_B+tlrc`.



### Group-level whole brain analyses
From terminal command line, run: 
```
python ttest_cue.py
```
to use AFNI's command 3dttest++ to perform t-ttests on subjects' brain maps.

#### output 
Saves out resulting Z-maps to directory **fmrieat/derivatives/results_cue**. Check out results in afni viewer. 



### Generate VOI timecourses
In matlab, run: 
```
saveRoiTimeCourses_script
```
and then: 
```
plotRoiTimeCourses_script
```
to save out and plot VOI timecourses for events of interest.

#### output 
Saves out VOI timecourses to directory **fmrieat/derivatives/timecourses_cue** and saves out figures to **fmrieat/figures/timecourses_cue/**.



### Behavioral analyses
In matlab, run: 
```
analyzeBehavior_script & analyzeBehavior_singlesubject_script
```
to check out behavioral data. 



### TO DO: 
- qualtrics questionnaire analyses
- pipeline data collected on paper (weight, height, etc.)
- get follow-up data!



## dMRI pipeline

This pipeline is specifically designed for identifying the medial forebrain bundle. 

### Acpc-align t1 data
In matlab, run:
```
mrAnatAverageAcpcNifti
```
Use GUI to manually acpc-align t1 data 

#### output
Save out acpc-aligned nifti to **fmrieat/derivatives/anat_proc/t1_acpc.nii.gz**. 


### Run freesurfer recon
From terminal command line, cd to dir with subject's acpc-aligned t1 and run: 
```
recon-all -i t1_acpc.nii.gz -subjid subjid -all
```
This calls freesurfer's recon command to segment brain tissue

#### output
Saves out a bunch of files to directory, **/usr/local/freesurfer/subjects/subjid**.



### Convert freesurfer files to nifti and save out ROI masks
In matlab, run:
```
convertFsSegFiles_script.m
createRoiMasks_script.m
```
To convert freesurfer segmentation files to be in nifti format & save out desired ROI masks based on FS segmentation labels

#### output
Saves out files to directory, **fmrieat/derivatives/subjid/anat_proc**



### Convert midbrain ROI from standard > native space
From terminal command line, run:
```
t12mni_ANTS_script.py
```
and then in matlab, run:
```
xformROIs_script.m
```
To estimate the tranform (using ANTs) between subject's acpc-aligned native space and standard space and to apply the inverse transform to take a midbrain ROI in standard space > subject native space. 

We're currently trying out a midbrain ROI placed on the CIT168 atlas (Pauli et al., 2018) using these labels combined (all dopaminergic regions): VTA, SNc, and PBP. 

#### output
Saves out acpc-aligned<->standard space transforms to directory, **fmrieat/derivatives/subjid/anat_proc**, and saves out a midbrain ROI ("PauliAtlasDA.nii.gz") in directory: **fmrieat/derivatives/subjid/ROIs**



### dilate ROIs (if desired)
Following procedures in MacNiven et al (2020), at least for tracking between the midbrain and NAcc, dilate these ROIs by 2 voxels using an mrtrix command (e.g., "maskfilter -npass 2 naccL.nii.gz dilate naccL_dil2.nii.gz")

#### output
dilated ROI nifti files to directory, **fmrieat/derivatives/subjid/ROIs**



### Pre-process diffusion data
In Matlab, run:
```
dtiPreProcess_script
```
To do vistasoft standard pre-processing steps on diffusion data.

#### output
Saves out files to directory, **fmrieat/derivatives/subjid/dti96trilin**



### mrtrix pre-processing steps 
From terminal command line, run:
```
python mrtrix_proc.py
```
This script: 
* copies b_file and brainmask to mrtrix output dir
* make mrtrix tensor file and fa map (for comparison with mrvista maps and for QA)
* estimate response function using lmax of 8
* estimate fiber orientation distribution (FOD) (for tractography)

#### output
Saves out files to directory, **fmrieat/derivatives/subjid/dti96trilin/mrtrix**



### Track fibers
From terminal command line, run:
```
python mrtrix_fibertrack_mfb.py, 		 	 # for inferior NAcc tract
python mrtrix_fibertrack_mfb_aboveAC.py, or  # for superior NAcc tract
python mrtrix_fibertrack.py			 	     # for all other tracts
```
tracks fiber pathways between 2 ROIs with desired parameters. The "mfb" script includes an exclusionary ROI to not include any streamlines that go above the anterior commissure; the "...mfb_aboveAC" script has an exclusionary ROI to not include any streamlines that run below the anterior commissure.

##### output
Saves out files to directory, **fmrieat/derivatives/fibers/dti96trilin/mrtrix**



### Clean fiber bundles
In matlab:
```
cleanFibersMFB_script, 			# for inferior NAcc tract
cleanFibersAboveAC_script, or  	# for superior NAcc tract
cleanFibers_script 				# for all other tracts

```
uses AFQ software to iteratively remove errant fibers 

##### output
Saves out fiber group files to directory, **fmrieat/derivatives/subjid/fibers**



### Save out measurements from fiber bundles cores
In matlab:
```
dtiSaveFGMeasures_script & dtiSaveFGMeasures_csv_script
```
to save out summary tract measures 

##### output
Saves out .mat files with summary measures to directory, **fmrieat/derivatives/fgMeasures/mrtrix_fa/**



### Regression and correlation analyses to test relationships between tract coherence, personality, behavior, and/or fMRI measures













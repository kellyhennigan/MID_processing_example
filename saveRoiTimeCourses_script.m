% script to save out roi time courses. This script does the following:

% load event onset files: each file should be a text file with a column
% vector of 0s and 1s to signify an event onset. Length of the vector should be
% equal to the # of acquired TRs.

% load roi binary mask files: volumes w/value of 1 signifying which voxels
% are in the roi mask; otherwise 0 values

% load pre-processed functional data & get averaged roi time courses

% get stim-locked time series based on event onset files

% for each subject, for each roi, for each event type, get the average time
% course & save out in csv file. A separate csv file is saved for each ROI
% for each event type/condition, with subject timecourses in rows. 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% define variables and filepaths 

% clear workspace
clear all
close all


%%%%%%%%%%%%%%%%%%%  define experiment directories %%%%%%%%%%%%%%%%%%%%%%%%

% assume this is being run from the "script" directory
scriptsDir=pwd;
cd ..; mainDir = pwd; cd(scriptsDir);
dataDir = [mainDir '/data']; 


% add scripts to matlab's search path
path(path,genpath(scriptsDir)); % add scripts dir to matlab search path


subjects = {'subj002','subj003'};


%%%%%%%%%%%%%%%%%%%%%%%%%% FMRI data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% filepath to pre-processed functional data where %s is subject 
funcFilePath = fullfile(dataDir, '%s','func_proc','pp_mid_tlrc.nii.gz');

% OPTIONAL: include path to file that says which volumes to censor
% (exclude) due to head movement, spiky data, etc. If included, this file
% should be a vector of 1s and 0s with the # of entries=# of fmri volumes. 
% 0 means censor that volume, otherwise, 1.

censorBadTRs=1; % 0 to NOT do this, 1 to do this
censorFilePath = fullfile(dataDir,'%s','func_proc','mid_censor.1D'); % this is only used if censorBadTRs=1


%%%%%%%%%%%%%%%%%%%%%%%%%% event files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% directory containing event times (in TR units) where %s is subject
stimDir =  fullfile(dataDir,'%s','regs');

% get names of stim files to process. Each file should be a vector of 1s
% and 0s with the # of entries=# of fmri volumes. 1 indicates the onset of
% a trial of that event type. Otherwise, 0. 
stimFiles = {'gain0_trial_mid.1D',...
    'gain1_trial_mid.1D',...
    'gain5_trial_mid.1D',...
    'gainwin_trial_mid.1D',...
    'gainmiss_trial_mid.1D',...
    'loss0_trial_mid.1D',...
    'loss1_trial_mid.1D',...
    'loss5_trial_mid.1D',...
    'losswin_trial_mid.1D',...
    'lossmiss_trial_mid.1D'}; 


% list corresponding to stims to use in outfile name
outStimNames = {'gain0','gain1','gain5','gainwin','gainmiss',...
    'loss0','loss1','loss5','losswin','lossmiss'};


%%%%%%%%%%%%%%%%%%%%%%%%%% ROI masks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% roi directory
roiDir = fullfile(mainDir,'templates');

% get list of rois to potentially process
roiNames = {'nacc_desai_func','mpfc_func','ins_desai_func'}; 

% list corresponding to roiNames to use in outfile name
outRoiNames = {'nacc','mpfc','ins'}; 



%%%%%%%%%%%%%%%%%%%%%%%%%% other variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% name of dir to save to where %s is task
outDir = fullfile(dataDir,'timecourses_mid');


nTRs = 12; % # of TRs to extract
TR = 2; % TR (in units of seconds)
t = 0:TR:TR*(nTRs-1); % time points (in seconds) to plot


plotSingleTrials=input('plot single trials?\n Note this GREATLY increases processing time!\n Use this only for troubleshooting potentially bad/spiky timepoints.\n1=yes 0=no ');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% run it; ideally you shouldn't have to edit below this line


% cell array to house timecourses
TC = cell(numel(roiNames),numel(stimFiles)); % cell array that will contain 


% get roi masks
roiFiles = cellfun(@(x) [x '.nii'], roiNames,'UniformOutput',0);
rois = cellfun(@(x) niftiRead(fullfile(roiDir,x)), roiFiles,'uniformoutput',0);


i=1; j=1; k=1;
for i=1:numel(subjects) % subject loop
    
    subject = subjects{i};
    
    fprintf(['\n\nworking on subject ' subject '...\n\n']);
    
    % load pre-processed data
    func = niftiRead(sprintf(funcFilePath,subject));
    
    
    % if provided, load subject's censor file that says which volumes to
    % censor due to motion
    if censorBadTRs
        censorVols = find(dlmread(sprintf(censorFilePath,subject))==0);
    end
    
    
    % get stim onset times
    onsetTRs = cellfun(@(x) find(dlmread(fullfile(sprintf(stimDir,subject),x))), stimFiles, 'uniformoutput',0);
    
    
    for j=1:numel(rois)
        
        % this roi time series
        roi_ts = roi_mean_ts(func.data,rois{j}.data);
        
        % nan pad the end in case there aren't enough TRs for the last
        % trial
        roi_ts = [roi_ts;nan(nTRs,1)];
        
        
        for k=1:numel(stimFiles)
            
            % this stim time series
            this_stim_tc = [];
            
            % set time courses to nan if there are no stim events
            if isempty(onsetTRs{k})
                TC{j,k}(i,:) = nan(1,nTRs);
                
                % otherwise, process stim event time courses
            else
                
                % this is an array of integers indicating which volumes of
                % data to get
                this_stim_TRs = repmat(onsetTRs{k},1,nTRs)+repmat(0:nTRs-1,numel(onsetTRs{k}),1);
                
                % single trial time courses for this stim
                this_stim_tc=roi_ts(this_stim_TRs);
                
                
                %%%%% TO ONLY OMIT CENSORED TRS:
                if censorBadTRs
                    censor_idx=find(ismember(this_stim_TRs,censorVols));
                    [~,cc]=ind2sub(size(this_stim_TRs),censor_idx);
                    censored_trs = this_stim_tc(censor_idx);
                    this_stim_tc(censor_idx)=nan;
                      
                    % keep count of the # of censored & outlier TRs
                    nBadTRs{j}(i,k) = numel(censor_idx);
            
                end
                
                
                % average over trials to get 1 timecourse for this subject
                % for this ROI for this trial type
                TC{j,k}(i,:) = nanmean(this_stim_tc,1);
                
                   
                % plot single trials if desired
                if plotSingleTrials
                    h = figure;
                    hold on
                    set(gca,'fontName','Helvetica','fontSize',12)
                 
                    % plot good and bad (censored) single trials
                    plot(t,this_stim_tc','linewidth',1.5,'color',[.15 .55 .82])
                    titleStr=[subject ' ' outStimNames{k} ' trials'];
                    if ~isempty(censored_trs)
                        plot(t(cc),censored_trs,'*','color',[1 0 0],'markersize',20,'Linewidth',1.5)
                        titleStr = [titleStr ' (* means censored TR(s) )'];
                    end
                    xlim([t(1) t(end)])
                    set(gca,'XTick',t)
                    xlabel('time (in seconds) relative to cue onset')
                    ylabel('%\Delta BOLD')
                    set(gca,'box','off');
                    title(gca,titleStr)
                    
                    % save out plot
                    thisOutDir = fullfile(outDir,outRoiNames{j},'single_trial_plots');
                    if ~exist(thisOutDir,'dir')
                        mkdir(thisOutDir);
                    end
                    outName = [subject '_' outStimNames{k}];
                    print(gcf,'-dpng','-r300',fullfile(thisOutDir,outName));
                end
                
                
            end % isempty(onsetTRs)
            
        end % stims
        
    end % rois
    
end % subject loop


%%  save out time courses
%

% make sure subjects are in a column array
if size(subjects,2)>1
    subjects=subjects';
end


for j=1:numel(rois)
    
    % roi specific directory
    thisOutDir = fullfile(outDir,outRoiNames{j});
    if ~exist(thisOutDir,'dir')
        mkdir(thisOutDir);
    end
    
    for k=1:numel(outStimNames)
        
        T = table([subjects],[TC{j,k}]);
        writetable(T,fullfile(thisOutDir,[outStimNames{k} '.csv']),'WriteVariableNames',0);
    end
end








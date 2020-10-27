% plot roi time courses


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% define variables and filepaths 

% clear workspace
clear all
close all


%%%%%%%%%%%%%%%%%%%%%  define relevant variables %%%%%%%%%%%%%%%%%%%%%%%%%%

% EDIT MAIN DIR PATH HERE 
mainDir = '/Users/kelly/MID_pilot';
scriptsDir = [mainDir '/scripts']; % this should be the directory where this script is located
dataDir = [mainDir '/data']; 


% add scripts to matlab's search path
path(path,genpath(scriptsDir)); % add scripts dir to matlab search path


subjects = {'subj002','subj003'};


% timecourse directory
tcDir='timecourses_mid';
tcPath = fullfile(dataDir,tcDir);


% which rois to process?
roiNames = {'nacc','mpfc','ins'};


nTRs = 12; % # of TRs to plot
TR = 2; % TR (in units of seconds)
t = 0:TR:TR*(nTRs-1); % time points (in seconds) to plot
xt = t; %  xticks on the plotted x axis



% each row determines what will be plotted in a single figure
% stim names should be separated by a space and must correspond to the
% names of the csv files with saved timecourses. 
% this script will recognize '-' and perform a subtract of those stims. 

% e.g. plotStims = {'gain0 gain1 gain5'} will plot a figure with 3
% lines: one line for gain0, one line for gain1, etc. 

% e.g. plotStims = {'gain5-gain0'} will plot a figure with 1 line: gain5
% trial timecourses minus gain0 trial timecourses

plotStims = {'gain0 gain1 gain5';
    'gain5-gain0';
    'gainwin gainmiss',
    'loss0 loss1 loss5';
    'loss5-loss0';
    'losswin lossmiss'};


% must have the same # of rows as plotStims; this will be used for the
% outfile names. It should be a desription of what is being plotted as
% determined by plotStims entries.
plotStimStrs = {'gain trials';
    'gain5-gain0 trials';
    'gain trials by outcome';
    'loss trials';
    'loss5-loss0 trials';
    'loss trials by outcome'};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%r
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% run it - you shouldnt have to edit past this line 


nFigs=size(plotStims,1);

% get ROI time courses
r=1;
for r = 1:numel(roiNames)
    
    roiName = roiNames{r};
    
    inDir = fullfile(tcPath,roiName); % time courses dir for this ROI
    
    
    %% define time courses to plot
    
    f=1;
    for f = 1:nFigs
        
        % get the name & stims to plot for this figure
        stims = splitstring(plotStims{f});
        stimStr = plotStimStrs{f};
        
        tc = {}; % time course cell array
        
        c=1;
        for c = 1:numel(stims)
            
            % if there's a minus sign, assume desired plot is stim1-stim2
            if strfind(stims{c},'-')
                stim1 = stims{c}(1:strfind(stims{c},'-')-1);
                stim2 = stims{c}(strfind(stims{c},'-')+1:end);
                tc1=loadRoiTimeCourses(fullfile(inDir,[stim1 '.csv']),subjects,1:nTRs);
                tc2=loadRoiTimeCourses(fullfile(inDir,[stim2 '.csv']),subjects,1:nTRs);
                tc{c}=tc1-tc2;
            else
                stimFile = fullfile(inDir,[stims{c} '.csv']);
                tc{c}=loadRoiTimeCourses(stimFile,subjects,1:nTRs);
            end
            
        end % stims
        
        
        % make sure all the time courses are loaded
        if any(cellfun(@isempty, tc))
            error('\hold up - time courses for at least one stim/group weren''t loaded.')
        end
        
        % if there's more than 1 subject, get the average and standard error across
        % subjects
        if numel(subjects)>1
            mean_tc = cellfun(@nanmean, tc,'uniformoutput',0);
            se_tc = cellfun(@(x) nanstd(x,1)./sqrt(size(x,1)), tc,'uniformoutput',0);
            
            % otherwise, just plot the single subject's data without standard error
        else
            mean_tc=tc;
            se_tc = repmat({zeros(1,nTRs)},size(tc));
        end
        
      
        
        %% set up all plotting params
        
        % fig title
        figtitle = [strrep(roiName,'_',' ') ' response to ' stimStr ];
        
        % x and y labels
        xlab = 'time (s)';
        ylab = '%\Delta BOLD';
      
        
        
        % labels for each line plot (goes in the legend)
        lineLabels = stims;
        
        % line colors & line specs
        cols = getTCPlotColors(stims);
      
      
        % filepath, if saving
        savePath = [];
        outDir = fullfile(figDir,tcDir,roiName);
        if ~exist(outDir,'dir')
            mkdir(outDir)
        end
        outName = [roiName '_' stimStr];
        savePath = fullfile(outDir,outName);
        
        
        
        %% finally, plot the thing!
        
        fprintf(['\n\n plotting figure: ' figtitle '...\n\n']);
        
        % you could add code here to do statistical testing at each time
        % point and get p-values. If you give p-values to the plot function
        % below, it will plot asterisks on the figure.
        pvals = []; 
        
        [fig,leg]=plotNiceLinesEBar(t,mean_tc,se_tc,cols,pvals,lineLabels,xlab,ylab,figtitle,savePath);
        
        
        fprintf('done.\n\n');
        
        
    end % figures
    
end %roiNames



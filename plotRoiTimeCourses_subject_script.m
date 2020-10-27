% plot roi time courses by subject 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% define variables and filepaths 

% clear workspace
clear all
close all


%%%%%%%%%%%%%%%%%%%%%  define relevant variables %%%%%%%%%%%%%%%%%%%%%%%%%%

% assume this is being run from the "script" directory
scriptsDir=pwd;
cd ..; mainDir = pwd; cd(scriptsDir);
dataDir = [mainDir '/data']; 
figDir = [mainDir '/figures']; 


% add scripts to matlab's search path
path(path,genpath(scriptsDir)); % add scripts dir to matlab search path

subjects = {'subj002','subj003'};


% timecourse directory
tcDir='timecourses_mid';
tcPath = fullfile(dataDir,tcDir);


nTRs = 12; % # of TRs to plot
TR = 2; % TR (in units of seconds)
t = 0:TR:TR*(nTRs-1); % time points (in seconds) to plot
xt = t; %  xticks on the plotted x axis


stim = 'gain5';
stimStr = stim;

roiName = 'nacc'; % roi to process


% color scheme for plotting: 'rand' for random or 'relapse' for relapse color scheme
% colorScheme = 'mean'; 
colorScheme = 'rand'; 


plotLegend=1; % 1 to include plot legend, otherwise 0


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%r
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% do it

     
% get ROI time courses
inDir = fullfile(dataDir,tcDir,roiName); % time courses dir for this ROI

stimFile = fullfile(inDir,[stim '.csv']);
tc=loadRoiTimeCourses(stimFile,subjects,1:nTRs);


% calculate mean and se of time courses
mean_tc = nanmean(tc);
se_tc = nanstd(tc)./sqrt(size(tc,1));
   
%%%%%%
% put each subjects time course into its own cell in an array 
tc=mat2cell(tc,[ones(size(tc,1),1)],[size(tc,2)]); 


% make sure all the time courses are loaded
if any(cellfun(@isempty, tc))
    tc
    error('\hold up - time courses for at least one stim/group weren''t loaded.')
end

n = numel(subjects);


%% set up all plotting params

% fig title
figtitle = [strrep(roiName,'_',' ') ' response to ' stim ' by subject'];

% x and y labels
xlab = 'time (s) relative to cue onset';
ylab = '%\Delta BOLD';


% labels for each line plot (goes in the legend)
if plotLegend
lineLabels = subjects;
else
    lineLabels='';
end

%%%%%% colors: 
if strcmp(colorScheme,'rand') % random colors
    cols = solarizedColors(n); % line colors - Nx3 matrix of rgb vals (1 row/subject)
    cols = cols(randperm(n),:);
   
elseif strcmp(colorScheme,'mean') % each line is gray and mean is blue
    cols=repmat([.6 .6 .6],n,1);
    mean_col= [0.1490    0.5451    0.8235]; % color to plot mean timecourse
    
else
    cols = solarizedColors(n); % line colors - Nx3 matrix of rgb vals (1 row/subject)
end


% filename, if saving
savePath = [];
outDir = fullfile(figDir,tcDir,roiName);
if ~exist(outDir,'dir')
    mkdir(outDir)
end
% nomenclature: roiName_stimStr_groupStr
outName = [roiName '_' stimStr '_by_subject'];
savePath = fullfile(outDir,outName);



%% finally, plot the thing!

fprintf(['\n\n plotting figure: ' figtitle '...\n\n']);

   
[fig,leg]=plotNiceLines(t,tc,{},cols,[],lineLabels,xlab,ylab,figtitle,savePath);
set(leg,'Location','EastOutside')

if strcmp(colorScheme,'mean')
    plot(t,mean_tc,'color',mean_col,'Linewidth',5)
end

if savePath
    print(gcf,'-dpng','-r300',savePath);
end

fprintf('done.\n\n')


%% plot single subject(s) in black

% gcf
% hold on
% subjects
% plot(t,tc{12},'color','k','linewidth',2)
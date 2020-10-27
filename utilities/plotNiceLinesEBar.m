function [fig,leg]=plotNiceLinesEBar(x,y,se,cols,pvals,lineLabels,xlab,ylab,figtitle,savePath)
% [fig,leg] = plotNiceBars(d,dName,condNames,groupNames,cols,plotSig,savePath)
% -------------------------------------------------------------------------
% usage: function to make nice line plots with shaded error;
%
% INPUT:
%   x - 1 x n vector of values of x-axis, e.g., seconds or TRs
%   y - m x n matrix where each row of values will be plotted as a line
%   se - standard error values corresponding to values in y
%   cols - cell array of colors for plotting
%   pvals - 1 x n vector of p values from tests comparing values of lines;
%       if given, '*'s will be plotted above lines for sig differences
% 	lineLabels - cell array with names corresponding to each line
%   xlab & ylab - labels for x and y axes
%   figtitle - title for plot
%   savePath - filepath to save out figure to; if not given, it won't be
%      saved.

% OUTPUT:
%   fig - figure handle
%   leg - legend handle
%
% NOTES:
%
% author: Kelly, kelhennigan@gmail.com, 05-Aug-2016

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

% put y & se values into cells, if they're not already
if ~iscell(y)
    y=mat2cell(y,ones(1,size(y,1)),size(y,2));
end
if ~iscell(se)
    se=mat2cell(se,ones(1,size(se,1)),size(se,2));
end


% deal with default values
if notDefined('cols')
    cols = lines(numel(y));
end

if ~iscell(cols)
    cols=mat2cell(cols,[ones(1,size(cols,1))],size(cols,2));
end

if notDefined('savePath')
    savePath = ''; % don't save out fig unless savePath is given
end

if notDefined('plotToScreen')
    plotToScreen = 1; % default is to plot to screen.
end


% this determines the type of line, e.g., '--' will plot dotted lines. 
%  See matlab documentation for lspec to see more options.
lspec='-';


%%

fig=figure;

hold on
ss = get(0,'Screensize'); % screen size
set(fig,'Position',[ss(3)-700 ss(4)-525 700 525]) % make figure 700 x 525 pixels
set(gca,'fontName','Helvetica','fontSize',16)
set(gca,'box','off');
set(gcf,'Color','w','InvertHardCopy','off','PaperPositionMode','auto');

% plot lines
for i=1:numel(y)
    eh = errorbar(x,y{i},se{i},lspec,'color',cols{i},'linewidth',2);
    eh.CapSize = 6; % determines error bar cap size; default is 6
end


% legend
leg=legend(reshape(lineLabels,1,[]),'Location','Best')
legend(gca,'boxoff')
% xlim([1 numel(xt)])
% set(gca,'XTick',xt)
xlabel(xlab)
ylabel(ylab)


% title
title(figtitle)


%% if plotting stats:


if ~isempty(pvals)
    y_ast = max([y{:}]+1.5.*[se{:}]); % y-level for plotting sig asterisks
    for i=1:numel(pvals)
        if pvals(i)<.001
            text(x(i),y_ast,'***','FontName','Times','FontSize',24,'HorizontalAlignment','center','color','k')
        elseif pvals(i) < .01
            text(x(i),y_ast,'**','FontName','Times','FontSize',24,'HorizontalAlignment','center','color','k')
        elseif pvals(i) < .05
            text(x(i),y_ast,'*','FontName','Times','FontSize',24,'HorizontalAlignment','center','color','k')
        end
    end
    
    % move up the upper y-axis limit for asterisks, if needed
    yL = ylim;
    if yL(2) < y_ast+max([se{:}])./2
        ylim([yL(1) y_ast+max([se{:}])./2])
    end
end

% set xlim?
xlim([x(1) x(end)])


%% save figure?

if savePath
    print(gcf,'-dpng','-r300',savePath);
end

fprintf('done.\n\n')


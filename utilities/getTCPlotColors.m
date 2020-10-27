function colors=getTCPlotColors(stims)
% -------------------------------------------------------------------------
% usage: use this to define your desired plotting colors. This is useful so
% that lines for a given condition are always plotted in the color you
% choos
%
% INPUT:
%   stims - cell array of stim names (e.g., {'gain5','gain0'}
%
% OUTPUT:
%   colors - rgb values to use for plotting timecourses
%
%
% author: Kelly, kelhennigan@gmail.com, 12-Dec-2019

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% determine which colors to return based on input labels %%%%%%%%%%%%%


colors = [];
   
for i=1:numel(stims)
    
    
    switch lower(stims{i})

        % add/edit as desired!!!
        
        case {'gain5','gain5-gain0'}
            colors(i,:)=  [250 32 161]./255; % pink
            
        case 'gain1'
            colors(i,:)=[29 186 154]./255; % green
            
        case 'gain0'
            colors(i,:)= [2 117 180]./255;     % blue
            
        case {'loss5','loss5-loss0'}
            colors(i,:)=  [250 32 161]./255; % pink
            
        case 'loss1'
            colors(i,:)=[29 186 154]./255; % green
            
        case 'loss0'
            colors(i,:)=[2 117 180]./255;     % blue
            
        case {'gainwin','gainwin-gainmiss'}
            colors(i,:)= [2 117 180]./255; % blue
            
        case 'gainmiss'
            colors(i,:)=[ 253 44 20 ]./255; % red
            
        case {'losswin','losswin-lossmiss','losshit'}
            colors(i,:)=[2 117 180]./255; % blue
            
        case 'lossmiss'
             colors(i,:)= [ 253 44 20 ]./255; % red
            
    end
   
    
    

    
end


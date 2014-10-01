function varargout = UpdateDisplay(varargin)
% UpdateDisplay is called by FieldUniformity when initializing or
% updating a plot display.  When called with no input arguments, this
% function returns a string cell array of available plots that the user can
% choose from.  When called with two input arguments, the first being a GUI
% handles structure and the second a string indicating the head number (h1,
% h2, or h3), this function will look for measured data and update the 
% display based on the display menu UI component.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2014 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Run in try-catch to log error via Event.m
try

% Specify plot options and order
plotoptions = {
    ''
    'Reference Profile'
    'MLC X Profile'
    'MLC Y Profile'
    'Timing'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the plot options
    varargout{1} = plotoptions;
    
    % Stop execution
    return;
    
% Otherwise, if 2, set the input variables and update the plot
elseif nargin == 2
    
    % Set input variables
    handles = varargin{1};
    head = varargin{2};
    
    % Log start
    Event('Updating plot display');
    tic;
    
% Otherwise, throw an error
else 
    Event('Incorrect number of inputs to UpdateDisplay', 'ERROR');
end

% Clear and set reference to axis
cla(handles.([head, 'axes']), 'reset');
axes(handles.([head, 'axes']));
Event(['Current plot set to ', head, 'axes']);

% Turn off the display while building
set(allchild(handles.([head, 'axes'])), 'visible', 'off'); 
set(handles.([head, 'axes']), 'visible', 'off');

% Execute code block based on display GUI item value
switch get(handles.([head, 'display']),'Value')
    
    %% Plot reference dose array
    case 2
        % Log selection
        Event('Reference Profile selected for display');
        
        % If data exists
        if isfield(handles, 'refData')
            % Plot transposed reference field
            imagesc(handles.refData);
            
            % Calculate where the x labels should go in order to be
            % uniformly spaced around zero
            xlabels = interp1(handles.refX(1,:), ...
                1:length(handles.refX(1,:)), -200:50:200, 'linear', 'extrap');
            
            % Set x ticks and labels
            set(gca, 'XTick', xlabels);
            set(gca, 'XTickLabel', -200:50:200);
            
            % Calculate where the y labels should go in order to be
            % uniformly spaced around zero
            ylabels = sort(interp1(fliplr(handles.refY(1,:)), ...
                1:length(handles.refY(1,:)), -200:50:200, 'linear', 'extrap'));
            
            % Set y ticks and labels
            set(gca, 'YTick', ylabels);
            set(gca, 'YTickLabel', -200:50:200);
            
            % Turn on grid, color bar, and make image square
            grid on;
            colorbar;
            axis image;
        end
    
    %% Plot MLC X data
    case 3
        % Log selection
        Event('MLC X Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'X']) && ...
                size(handles.([head,'X']), 2) > 0
            
            % Enable plot hold to overlay multiple plots
            hold on;
            
            % Plot reference data
            plot(handles.refX(1,:), handles.refX(2,:), 'blue');
            
            % Plot measured data
            plot(handles.([head,'X'])(1,:), handles.([head,'X'])(2,:), 'red');
            
            % Plot gamma
            plot(handles.([head,'X'])(1,:), handles.([head,'X'])(3,:), ...
                'Color', [0 0.75 0.75]);
                      
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', 'SouthEast');
            
            % Format plot
            hold off;
            ylabel('Normalized Value');
            ylim([0 1.05]);
            xlabel('MLC X Position (mm)');
            xlim([-160 160]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
     
    %% Plot MLC Y data   
    case 4
        % Log selection
        Event('MLC Y Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'Y']) && ...
                size(handles.([head,'Y']), 2) > 0
            
            % Enable plot hold to overlay multiple plots
            hold on;
            
            % Plot reference data
            plot(handles.refY(1,:), handles.refY(2,:), 'blue');
            
            % Plot measured data
            plot(handles.([head,'Y'])(1,:), handles.([head,'Y'])(2,:), 'red');
            
            % Plot gamma
            plot(handles.([head,'Y'])(1,:), handles.([head,'Y'])(3,:), ...
                'Color', [0 0.75 0.75]);
            
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', 'SouthEast');
            
            % Format plot
            hold off;
            ylabel('Normalized Value');
            ylim([0 1.05]);
            xlabel('MLC Y Position (mm)');
            xlim([-160 160]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    
    %% Plot time profile
    case 5
        % Log selection
        Event('Timing Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'T']) && ...
                size(handles.([head,'T']), 2) > 0
            
            % Plot reference data
            plot(handles.([head,'T'])(1,:), handles.([head,'T'])(2,:), 'blue');
            
            % Format plot
            ylabel('Detector Signal (counts/sec)');
            xlabel('Time (sec)');
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
end

% Log completion
Event(sprintf('Plot updated successfully in %0.3f seconds', toc));

% Return the modified handles
varargout{1} = handles; 

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end
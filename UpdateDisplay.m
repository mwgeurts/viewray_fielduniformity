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
    handles = varargin{1};
    head = varargin{2};

% Otherwise, throw an error
else 
    error('Incorrect number of inputs');
end

% Clear and set reference to axis
cla(handles.([head, 'axes']), 'reset');
axes(handles.([head, 'axes']));

% Turn off the display while building
set(allchild(handles.([head, 'axes'])), 'visible', 'off'); 
set(handles.([head, 'axes']), 'visible', 'off');

% Execute code block based on display GUI item value
switch get(handles.([head, 'display']),'Value')
    %% Plot reference dose array
    case 2
        % If data exists
        if isfield(handles, 'refData')
            % Plot transposed reference field
            imagesc(handles.refData');
            
            % Calculate where the x labels should go in order to be
            % uniformly spaced around zero
            xlabels = interp1(handles.refY(1,:), ...
                1:length(handles.refY(1,:)), -200:50:200);
            
            % Set x ticks and labels
            set(gca, 'XTick', xlabels);
            set(gca, 'XTickLabel', -200:50:200);
            
            % Calculate where the y labels should go in order to be
            % uniformly spaced around zero
            ylabels = interp1(handles.refX(1,:), ...
                1:length(handles.refX(1,:)), -200:50:200);
            
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
            
            % Format plot
            hold off;
            ylabel('Normalized Measurement');
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
            
            % Format plot
            hold off;
            ylabel('Normalized Measurement');
            ylim([0 1.05]);
            xlabel('MLC Y Position (mm)');
            xlim([-160 160]);
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    
end

% Return the modified handles
varargout{1} = handles; 
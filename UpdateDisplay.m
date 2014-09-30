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
    case 2
        % If data exists
        if isfield(handles, 'refData')
            
            imagesc(handles.refData');
            
            xlabels = interp1(handles.refY(1,:), ...
                1:length(handles.refY(1,:)), -200:50:200);
            
            set(gca, 'XTick', xlabels);
            set(gca, 'XTickLabel', -200:50:200);
            
            ylabels = interp1(handles.refY(1,:), ...
                1:length(handles.refY(1,:)), -200:50:200);
            
            set(gca, 'YTick', ylabels);
            set(gca, 'YTickLabel', -200:50:200);
            
            grid on;
            colorbar;
            axis image;
        end
    
    case 3
        % If data exists
        if isfield(handles, [head,'X']) && ...
                size(handles.([head,'X']), 1) > 0
            
            
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    
end

% Return the modified handles
varargout{1} = handles; 
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
% Copyright (C) 2015 University of Wisconsin Board of Regents
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
    'MLC X Profile'
    'MLC Y Profile'
    'Positive Diagonal'
    'Negative Diagonal'
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
    
    %% Plot MLC X profile
    case 2
        % Log selection
        Event('MLC X Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'results']) && ...
                isfield(handles.([head,'results']), 'ydata') && ...
                size(handles.([head,'results']).ydata, 2) > 0
            
            % Enable plot hold to overlay multiple plots
            hold on;
            
            % Plot reference data
            plot(handles.([head,'refresults']).ydata(1,:) * 10, ...
                handles.([head,'refresults']).ydata(2,:), 'blue');
            
            % Plot measured data
            plot(handles.([head,'results']).ydata(1,:) * 10, ...
                handles.([head,'results']).ydata(2,:), 'red');
            
            % Plot gamma
            plot(handles.([head,'results']).ygamma(1,:) * 10, ...
                handles.([head,'results']).ygamma(2,:), ...
                'Color', [0 0.75 0.75]);
                      
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', ...
                'SouthEast');
            
            % Format plot
            hold off;
            ylabel('Normalized Value');
            ylim([0 1.05]);
            xlabel('MLC X Position (mm)');
            xlim([-160 160]);
            grid on;
            box on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
     
    %% Plot MLC Y profile   
    case 3
        % Log selection
        Event('MLC Y Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'results']) && ...
                isfield(handles.([head,'results']), 'xdata') && ...
                size(handles.([head,'results']).xdata, 2) > 0
            
            % Enable plot hold to overlay multiple plots
            hold on;
            
            % Plot reference data
            plot(handles.([head,'refresults']).xdata(1,:) * 10, ...
                handles.([head,'refresults']).xdata(2,:), 'blue');
            
            % Plot measured data
            plot(handles.([head,'results']).xdata(1,:) * 10, ...
                handles.([head,'results']).xdata(2,:), 'red');
            
            % Plot gamma
            plot(handles.([head,'results']).xgamma(1,:) * 10, ...
                handles.([head,'results']).xgamma(2,:), ...
                'Color', [0 0.75 0.75]);
                      
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', ...
                'SouthEast');
            
            % Format plot
            hold off;
            ylabel('Normalized Value');
            ylim([0 1.05]);
            xlabel('MLC Y Position (mm)');
            xlim([-160 160]);
            grid on;
            box on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    
    %% Plot positive diagonal profile   
    case 4
        % Log selection
        Event('Positive Diagonal Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'results']) && ...
                isfield(handles.([head,'results']), 'pdiag') && ...
                size(handles.([head,'results']).pdiag, 2) > 0
            
            % Enable plot hold to overlay multiple plots
            hold on;
            
            % Plot reference data
            plot(handles.([head,'refresults']).pdiag(1,:) * 10, ...
                handles.([head,'refresults']).pdiag(2,:), 'blue');
            
            % Plot measured data
            plot(handles.([head,'results']).pdiag(1,:) * 10, ...
                handles.([head,'results']).pdiag(2,:), 'red');
            
            % Plot gamma
            plot(handles.([head,'results']).pgamma(1,:) * 10, ...
                handles.([head,'results']).pgamma(2,:), ...
                'Color', [0 0.75 0.75]);
                      
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', ...
                'SouthEast');
            
            % Format plot
            hold off;
            ylabel('Normalized Value');
            ylim([0 1.05]);
            xlabel('Positive Diagonal Position (mm)');
            xlim([-225 225]);
            grid on;
            box on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    
    %% Plot negative diagonal profile  
    case 5
        % Log selection
        Event('Negative Diagonal Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'results']) && ...
                isfield(handles.([head,'results']), 'ndiag') && ...
                size(handles.([head,'results']).ndiag, 2) > 0
            
            % Enable plot hold to overlay multiple plots
            hold on;
            
            % Plot reference data
            plot(handles.([head,'refresults']).ndiag(1,:) * 10, ...
                handles.([head,'refresults']).ndiag(2,:), 'blue');
            
            % Plot measured data
            plot(handles.([head,'results']).ndiag(1,:) * 10, ...
                handles.([head,'results']).ndiag(2,:), 'red');
            
            % Plot gamma
            plot(handles.([head,'results']).ngamma(1,:) * 10, ...
                handles.([head,'results']).ngamma(2,:), ...
                'Color', [0 0.75 0.75]);
                      
            % Add legend
            legend('Reference', 'Measured', 'Gamma', 'location', ...
                'SouthEast');
            
            % Format plot
            hold off;
            ylabel('Normalized Value');
            ylim([0 1.05]);
            xlabel('Negative Diagonal Position (mm)');
            xlim([-225 225]);
            grid on;
            box on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    
    %% Plot time profile
    case 6
        % Log selection
        Event('Timing Profile selected for display');
        
        % If data exists
        if isfield(handles, [head,'results']) && ...
                isfield(handles.([head,'results']), 'ydata') && ...
                size(handles.([head,'results']).tdata, 2) > 0
            
            % Plot reference data
            plot(handles.([head,'results']).tdata(1,:)/1e3, ...
                handles.([head,'results']).tdata(2,:), 'blue');
            
            % Format plot
            ylabel('Detector Signal (counts/sec)');
            xlabel('Time (sec)');
            grid on;
            box on;
            
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
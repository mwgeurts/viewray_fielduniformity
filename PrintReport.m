function varargout = PrintReport(varargin)
% PrintReport is called by AnalyzeMLCProfiles after SNC IC Profiler 
% profiles have been loaded and analyzed, and creates a "report" figure of
% the plots and statistics generated in AnalyzeMLCProfiles.  This report is 
% then saved to a temporary file in PDF format and opened using the default
% application.  Once the PDF is opened, this figure is deleted. The visual 
% layout of the report is defined in PrintReport.fig.
%
% When calling PrintReport, the GUI handles structure (or data structure
% containing the daily and patient specific variables) should be passed
% immediately following the string 'Data', as shown in the following
% example:
%
% PrintReport('Data', handles);
%
% For more information on the variables required in the data structure, see
% BrowseCallback, UpdateDisplay, UpdateMLCStatistics, and LoadVersionInfo.
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

% Last Modified by GUIDE v2.5 09-Nov-2014 20:08:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PrintReport_OpeningFcn, ...
                   'gui_OutputFcn',  @PrintReport_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintReport_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PrintReport (see VARARGIN)

% Choose default command line output for PrintReport
handles.output = hObject;

% Log start of printing and start timer
Event('Printing report');
tic;

% Load data structure from varargin
for i = 1:length(varargin)
    if strcmp(varargin{i}, 'Data')
        data = varargin{i+1}; 
        break; 
    end
end

% Set logo
axes(handles.logo);
rgb = imread('UWCrest_4c.png', 'BackgroundColor', [1 1 1]);
image(rgb);
axis equal;
axis off;
clear rgb;

% Set report date/time
set(handles.text12, 'String', datestr(now));

% Set user name
[s, cmdout] = system('whoami');
if s == 0
    set(handles.text7, 'String', cmdout);
else
    cmdout = inputdlg('Enter your name:', 'Username', [1 50]);
    set(handles.text7, 'String', cmdout{1});
end
clear s cmdout;

% Set version
set(handles.text8, 'String', sprintf('%s (%s)', data.version, ...
    data.versionInfo{6}));

% Set SNC software
set(handles.text44, 'String', data.sncversion);

% Set collector
set(handles.text41, 'String', data.collector);

% Set collector serial number:
set(handles.text42, 'String', data.serial);

% If head 1 data was loaded
if isfield(data, 'h1results') && isfield(data.h1results, 'ydata') ...
        && size(data.h1results.ydata, 2) > 0
    
    % Set file
    set(handles.text14, 'String', get(data.h1file, 'String'));
    
    % Log event
    Event('Plotting head 1 MLC X profiles');

    % Set axes
    axes(handles.axes1);

    % Hold rendering for overlapping plots
    hold on;

    % Plot reference data
    plot(data.h1refresults.ydata(1,:) * 10, ...
        data.h1refresults.ydata(2,:), 'blue');

    % Plot measured data
    plot(data.h1results.ydata(1,:) * 10, ...
        data.h1results.ydata(2,:), 'red');

    % Plot gamma
    plot(data.h1results.ygamma(1,:) * 10, ...
        data.h1results.ygamma(2,:), ...
        'Color', [0 0.75 0.75]);

    % Add legend
    legend('Reference', 'Measured', 'Gamma', 'location', ...
        'SouthEast');

    % Format plot
    hold off;
    ylim([0 1.05]);
    xlabel('MLC X Position (mm)');
    xlim([-160 160]);
    grid on;
    box on;

    % Log event
    Event('Plotting head 1 MLC Y profiles');

    % Set axes
    axes(handles.axes2);

    % Hold rendering for overlapping plots
    hold on;

    % Plot reference data
    plot(data.h1refresults.xdata(1,:) * 10, ...
        data.h1refresults.xdata(2,:), 'blue');

    % Plot measured data
    plot(data.h1results.xdata(1,:) * 10, ...
        data.h1results.xdata(2,:), 'red');

    % Plot gamma
    plot(data.h1results.xgamma(1,:) * 10, ...
        data.h1results.xgamma(2,:), ...
        'Color', [0 0.75 0.75]);

    % Add legend
    legend('Reference', 'Measured', 'Gamma', 'location', ...
        'SouthEast');

    % Format plot
    hold off;
    ylim([0 1.05]);
    xlabel('MLC Y Position (mm)');
    xlim([-160 160]);
    grid on;
    box on;
    
    % Log start
    Event('Updating head 1 table statistics');
    
    % Add statistics table
    table = get(data.h1table, 'Data');
    set(handles.text19, 'String', sprintf('%s\n\n', table{1:8,1}));
    set(handles.text20, 'String', sprintf('%s\n\n', table{1:8,2}));
    
    % Clear temporary variables
    clear table h i names c;

else
    
    % Hide input file
    set(handles.text13, 'visible', 'off'); 
    set(handles.text14, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes1), 'visible', 'off'); 
    set(handles.axes1, 'visible', 'off'); 
    set(allchild(handles.axes2), 'visible', 'off'); 
    set(handles.axes2, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text17, 'visible', 'off'); 
    set(handles.text18, 'visible', 'off'); 
    set(handles.text19, 'visible', 'off'); 
    set(handles.text20, 'visible', 'off'); 
end

% If head 2 data was loaded
if isfield(data, 'h2results') && isfield(data.h2results, 'ydata') ...
        && size(data.h2results.ydata, 2) > 0
    
    % Set file
    set(handles.text28, 'String', get(data.h2file, 'String'));
    
    % Log event
    Event('Plotting head 2 MLC X profiles');

    % Set axes
    axes(handles.axes3);

    % Hold rendering for overlapping plots
    hold on;

    % Plot reference data
    plot(data.h2refresults.ydata(1,:) * 10, ...
        data.h2refresults.ydata(2,:), 'blue');

    % Plot measured data
    plot(data.h2results.ydata(1,:) * 10, ...
        data.h2results.ydata(2,:), 'red');

    % Plot gamma
    plot(data.h2results.ygamma(1,:) * 10, ...
        data.h2results.ygamma(2,:), ...
        'Color', [0 0.75 0.75]);

    % Add legend
    legend('Reference', 'Measured', 'Gamma', 'location', ...
        'SouthEast');

    % Format plot
    hold off;
    ylim([0 1.05]);
    xlabel('MLC X Position (mm)');
    xlim([-160 160]);
    grid on;
    box on;

    % Log event
    Event('Plotting head 2 MLC Y profiles');

    % Set axes
    axes(handles.axes4);

    % Hold rendering for overlapping plots
    hold on;

    % Plot reference data
    plot(data.h2refresults.xdata(1,:) * 10, ...
        data.h2refresults.xdata(2,:), 'blue');

    % Plot measured data
    plot(data.h2results.xdata(1,:) * 10, ...
        data.h2results.xdata(2,:), 'red');

    % Plot gamma
    plot(data.h2results.xgamma(1,:) * 10, ...
        data.h2results.xgamma(2,:), ...
        'Color', [0 0.75 0.75]);

    % Add legend
    legend('Reference', 'Measured', 'Gamma', 'location', ...
        'SouthEast');

    % Format plot
    hold off;
    ylim([0 1.05]);
    xlabel('MLC Y Position (mm)');
    xlim([-160 160]);
    grid on;
    box on;
    
    % Log start
    Event('Updating head 2 table statistics');
    
    % Add statistics table
    table = get(data.h2table, 'Data');
    set(handles.text31, 'String', sprintf('%s\n\n', table{1:8,1}));
    set(handles.text32, 'String', sprintf('%s\n\n', table{1:8,2}));
    
    % Clear temporary variables
    clear table h i names c;

else
    
    % Hide input file
    set(handles.text27, 'visible', 'off'); 
    set(handles.text28, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes3), 'visible', 'off'); 
    set(handles.axes3, 'visible', 'off'); 
    set(allchild(handles.axes4), 'visible', 'off'); 
    set(handles.axes4, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text29, 'visible', 'off'); 
    set(handles.text30, 'visible', 'off'); 
    set(handles.text31, 'visible', 'off'); 
    set(handles.text32, 'visible', 'off'); 
end

% If head 3 data was loaded
if isfield(data, 'h3results') && isfield(data.h3results, 'ydata') ...
        && size(data.h3results.ydata, 2) > 0
    
    % Set file
    set(handles.text34, 'String', get(data.h3file, 'String'));
    
    % Log event
    Event('Plotting head 3 MLC X profiles');

    % Set axes
    axes(handles.axes5);

    % Hold rendering for overlapping plots
    hold on;

    % Plot reference data
    plot(data.h3refresults.ydata(1,:) * 10, ...
        data.h3refresults.ydata(2,:), 'blue');

    % Plot measured data
    plot(data.h3results.ydata(1,:) * 10, ...
        data.h3results.ydata(2,:), 'red');

    % Plot gamma
    plot(data.h3results.ygamma(1,:) * 10, ...
        data.h3results.ygamma(2,:), ...
        'Color', [0 0.75 0.75]);

    % Add legend
    legend('Reference', 'Measured', 'Gamma', 'location', ...
        'SouthEast');

    % Format plot
    hold off;
    ylim([0 1.05]);
    xlabel('MLC X Position (mm)');
    xlim([-160 160]);
    grid on;
    box on;

    % Log event
    Event('Plotting head 3 MLC Y profiles');

    % Set axes
    axes(handles.axes6);

    % Hold rendering for overlapping plots
    hold on;

    % Plot reference data
    plot(data.h3refresults.xdata(1,:) * 10, ...
        data.h3refresults.xdata(2,:), 'blue');

    % Plot measured data
    plot(data.h3results.xdata(1,:) * 10, ...
        data.h3results.xdata(2,:), 'red');

    % Plot gamma
    plot(data.h3results.xgamma(1,:) * 10, ...
        data.h3results.xgamma(2,:), ...
        'Color', [0 0.75 0.75]);

    % Add legend
    legend('Reference', 'Measured', 'Gamma', 'location', ...
        'SouthEast');

    % Format plot
    hold off;
    ylim([0 1.05]);
    xlabel('MLC Y Position (mm)');
    xlim([-160 160]);
    grid on;
    box on;
    
    % Log start
    Event('Updating head 3 table statistics');
    
    % Add statistics table
    table = get(data.h3table, 'Data');
    set(handles.text37, 'String', sprintf('%s\n\n', table{1:8,1}));
    set(handles.text38, 'String', sprintf('%s\n\n', table{1:8,2}));
    
    % Clear temporary variables
    clear table h i names c;

else
    
    % Hide input file
    set(handles.text33, 'visible', 'off'); 
    set(handles.text34, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes5), 'visible', 'off'); 
    set(handles.axes5, 'visible', 'off'); 
    set(allchild(handles.axes6), 'visible', 'off'); 
    set(handles.axes6, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text35, 'visible', 'off'); 
    set(handles.text36, 'visible', 'off'); 
    set(handles.text37, 'visible', 'off'); 
    set(handles.text38, 'visible', 'off'); 
end

% Update handles structure
guidata(hObject, handles);

% Clear temporary variable
clear data;

% Get temporary file name
temp = [tempname, '.pdf'];

% Print report
Event(['Saving report to ', temp]);
saveas(hObject, temp);

% Open file
Event(['Opening file ', temp]);
open(temp);

% Log completion
Event(sprintf('Report saved successfully in %0.3f seconds', toc));

% Close figure
close(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintReport_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

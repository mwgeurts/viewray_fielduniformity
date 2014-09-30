function varargout = FieldUniformity(varargin)
% FieldUniformity computes ...
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

% Last Modified by GUIDE v2.5 29-Sep-2014 14:03:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FieldUniformity_OpeningFcn, ...
                   'gui_OutputFcn',  @FieldUniformity_OutputFcn, ...
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
function FieldUniformity_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FieldUniformity (see VARARGIN)

% Choose default command line output for FieldUniformity
handles.output = hObject;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'ViewRay Field Uniformity/Timing Check'
    sprintf('Version: %s', handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

% Turn off images
set(allchild(handles.h1axes), 'visible', 'off'); 
set(handles.h1axes, 'visible', 'off'); 
set(allchild(handles.h2axes), 'visible', 'off'); 
set(handles.h2axes, 'visible', 'off'); 
set(allchild(handles.h3axes), 'visible', 'off'); 
set(handles.h3axes, 'visible', 'off'); 

% Set plot options
handles.plotoptions = UpdateDisplay();
set(handles.h1display, 'String', handles.plotoptions);
set(handles.h2display, 'String', handles.plotoptions);
set(handles.h3display, 'String', handles.plotoptions);

% Initialize tables
set(handles.h1table, 'Data', cell(4,2));
set(handles.h2table, 'Data', cell(4,2));
set(handles.h3table, 'Data', cell(4,2));

% Initialize global variables
handles.path = userpath;
Event(['Default file path set to ', handles.path]);

handles.time = 30; % seconds (expected)
Event(sprintf('Expected time set to %0.1f seconds', handles.time));

handles.abs = 2.0; % percent
handles.dta = 1.0; % mm
Event(sprintf('Gamma criteria set to %0.1f%%/%0.1f mm', ...
    [handles.abs handles.dta]));

% Load reference profiles
[handles.refX, handles.refY, handles.refData] = ...
    LoadReferenceProfiles('AP_27P3X27P3_PlaneDose_Vertical_Isocenter.dcm');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = FieldUniformity_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h1file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file_CreateFcn(hObject, ~, ~)
% hObject    handle to h1file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse_Callback(hObject, ~, handles)
% hObject    handle to h1browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H1 browse button selected');
t = tic;

% Load profile data
handles = LoadSNCprm(handles, 'h1');

% If data was loaded
if isfield(handles, 'h1data') && ~isempty(handles.h1data) > 0
    % Extract X/Y profile data and compute Gamma
    handles = ParseSNCProfiles(handles, 'h1');
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h1');

    % Update plot to show MLC X profiles
    set(handles.h1display, 'Value', 3);
    handles = UpdateDisplay(handles, 'h1');
    
    % Log event
    Event(sprintf('H1 data loaded successfully in %0.3f seconds', toc(t)));
    clear t;
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_Callback(hObject, ~, handles)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H1 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_CreateFcn(hObject, ~, ~)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1clear_Callback(hObject, ~, handles)
% hObject    handle to h1clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H1 clear all button selected');

% Clear data
handles.h1num = [];
handles.h1width = [];
handles.h1bkgdcnt = [];
handles.h1bkgd = [];
handles.h1cal = [];
handles.h1ignore = [];
handles.h1data = [];
handles.h1X = [];
handles.h1Y = [];
handles.h1T = [];

% Clear file
set(handles.h1file, 'String', '');

% Call UpdateDisplay to clear plot
handles = UpdateDisplay(handles, 'h1');

% Clear statistics table
set(handles.h1table, 'Data', cell(4,2));

% Log event
Event('H1 data cleared from memory');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h2file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file_CreateFcn(hObject, ~, ~)
% hObject    handle to h2file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse_Callback(hObject, ~, handles)
% hObject    handle to h2browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H2 browse button selected');
t = tic;

% Load profile data
handles = LoadSNCprm(handles, 'h2');

% If data was loaded
if isfield(handles, 'h2data') && ~isempty(handles.h2data) > 0
    % Extract X/Y profile data and compute Gamma
    handles = ParseSNCProfiles(handles, 'h2');
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h2');

    % Update plot to show gamma
    set(handles.h2display, 'Value', 3);
    handles = UpdateDisplay(handles, 'h2');
    
    % Log event
    Event(sprintf('H2 data loaded successfully in %0.3f seconds', toc(t)));
    clear t;
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_Callback(hObject, ~, handles)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H2 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_CreateFcn(hObject, ~, ~)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2clear_Callback(hObject, ~, handles)
% hObject    handle to h2clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H2 clear all button selected');

% Clear data
handles.h2num = [];
handles.h2width = [];
handles.h2bkgdcnt = [];
handles.h2bkgd = [];
handles.h2cal = [];
handles.h2ignore = [];
handles.h2data = [];
handles.h2X = [];
handles.h2Y = [];
handles.h2T = [];

% Clear file
set(handles.h2file, 'String', '');

% Call UpdateDisplay to clear plot
handles = UpdateDisplay(handles, 'h2');

% Clear statistics table
set(handles.h2table, 'Data', cell(4,2));

% Log event
Event('H2 data cleared from memory');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h3file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file_CreateFcn(hObject, ~, ~)
% hObject    handle to h3file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse_Callback(hObject, ~, handles)
% hObject    handle to h3browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H3 browse button selected');
t = tic;

% Load profile data
handles = LoadSNCprm(handles, 'h3');

% If data was loaded
if isfield(handles, 'h3data') && ~isempty(handles.h3data) > 0
    % Extract X/Y profile data and compute Gamma
    handles = ParseSNCProfiles(handles, 'h3');
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h3');

    % Update plot to show gamma
    set(handles.h3display, 'Value', 3);
    handles = UpdateDisplay(handles, 'h3');
    
    % Log event
    Event(sprintf('H1 data loaded successfully in %0.3f seconds', toc(t)));
    clear t;
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_Callback(hObject, ~, handles)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H3 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_CreateFcn(hObject, ~, ~)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3clear_Callback(hObject, ~, handles)
% hObject    handle to h3clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H3 clear all button selected');

% Clear data
handles.h3num = [];
handles.h3width = [];
handles.h3bkgdcnt = [];
handles.h3bkgd = [];
handles.h3cal = [];
handles.h3ignore = [];
handles.h3data = [];
handles.h3X = [];
handles.h3Y = [];
handles.h3T = [];

% Clear file
set(handles.h3file, 'String', '');

% Call UpdateDisplay to clear plot
handles = UpdateDisplay(handles, 'h3');

% Clear statistics table
set(handles.h3table, 'Data', cell(4,2));

% Log event
Event('H3 data cleared from memory');

% Update handles structure
guidata(hObject, handles);

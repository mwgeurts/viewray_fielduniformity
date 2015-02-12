function handles = BrowseCallback(handles, head)
% BrowseCallback is called by FieldUniformity when the user selects a
% Browse button to read SNC IC Profiler data.  The files themselves are 
% parsed using the snc_extract submodule. The first input argument is the 
% guidata handles structure, while the second is a string indicating which 
% head and file number to load. This function returns a modified handles 
% structure upon successful completion.
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

% Log event
Event([head, ' browse button selected']);

% Request the user to select the SNC Profiler PRM file
Event('UI window opened to select file');
[name, path] = uigetfile('*.prm', 'Select SNC Profiler data', handles.path);

% If a file was selected
if ~isempty(name)
    
    % Start timer
    t = tic;

    % Update text box with file name
    set(handles.([head,'file']), 'String', fullfile(path, name));
           
    % Log names
    Event([fullfile(path, name),' selected\n']);
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % If the user selected PRM data
    if ~isempty(regexpi(name, '.prm$'))
        
        % Load Profiler PRM data
        data = ParseSNCprm(handles.path, name);
        handles.sncversion = data.version;
        handles.collector = data.dmodel;
        handles.serial = data.dserial;
    
    % Otherwise, unknown data was passed to function
    else
        
        % Throw an error
        Event('An unknown file format was selected', 'ERROR');
    end
    
    % Apply gamma criteria to refdata
    handles.refdata.abs = handles.abs;
    handles.refdata.dta = handles.dta;
    
    % Process profiles, comparing to reference data (normalized to center)
    [handles.([head, 'results']), handles.([head, 'refresults'])] = ...
        AnalyzeProfilerFields(data, handles.refdata, 'center');
    
    % Update statistics
    handles = UpdateStatistics(handles, head);
    
    % Update plot to show MLC X profiles
    set(handles.([head,'display']), 'Value', 2);
    handles = UpdateDisplay(handles, head);
    
    % Enable print button
    set(handles.print_button, 'enable', 'on');
    
    % Log event
    Event(sprintf('%s data loaded successfully in %0.3f seconds', ...
        head, toc(t)));
    
    % Clear temporary variables
    clear t data;
end

% Clear temporary variables
clear name path;
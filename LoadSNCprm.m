function handles = LoadSNCprm(handles, head)
% LoadSNCprm is called by FieldUniformity when the user selects a Browse
% button to read SNC IC Profiler prm exported data.
%
% This function requires the GUI handles structure and a string indicating 
% the head number (h1, h2, or h3). It returns a modified GUI handles 
% structure.
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

% Request the user to select the SNC ArcCHECK acm file
[name, path] = uigetfile('*.prm', ...
    'Select an SNC IC Profiler Movie File', handles.path);

% If a file was selected
if ~name == 0
    
    % Update text box with file name
    set(handles.([head,'file']), 'String', fullfile(path, name));
    
    % Update default path
    handles.path = path;
      
    % Initialize data arrays
    handles.([head,'h1X']) = [];
    handles.([head,'h1Y']) = [];
    handles.([head,'h1time']) = [];

    % Open file handle
    fid = fopen(fullfile(path, name), 'r');

    % While the end-of-file has not been reached
    while ~feof(fid)
        % Retrieve the next line in the file
        tline = fgetl(fid);
        
        % Search for the number of detectors
        [match, nomatch] = regexp(tline, ...
            sprintf('^Detectors:\t'), 'match', 'split');
        if size(match,1) > 0
            % Extract X and Y detectors
            handles.([head,'num']) = cell2mat(textscan(nomatch{2}, ...
                repmat('%f ', 1, 6)));
        end
        
        % Search for the detector spacing
        [match, nomatch] = regexp(tline, ...
            sprintf('^Detector Spacing:\t'), 'match', 'split');
        if size(match,1) > 0
            % Extract spacing
            scan = textscan(nomatch{2}, '%f');
            handles.([head,'width']) = scan{1};
        end
        
        % Search for background counts
        [match, nomatch] = regexp(tline, ...
            sprintf('^BIAS1\t\t([0-9]+)\t\t\t'), 'match', 'split');
        if size(match,1) > 0
            % Extract background counts
            scan = textscan(match{1}, '%s %f');
            handles.([head,'bkgdcnt']) = scan{2};
            
            % Extract all background counts
            handles.([head,'bkgd']) = cell2mat(textscan(nomatch{2}, ...
                repmat('%f ', 1, sum(handles.([head,'num'])) + 1)));
        end

        % Search for array calibration
        [match, nomatch] = regexp(tline, ...
            sprintf('^Calibration\t\t\t\t\t'), 'match', 'split');
        if size(match,1) > 0
            % Extract calibration values
            handles.([head,'cal']) = cell2mat(textscan(nomatch{2}, ...
                repmat('%f ', 1, sum(handles.([head,'num'])) - 6)));
        end

        % Search for ignore flags and data
        [match, nomatch] = regexp(tline, ...
            sprintf('^IgnoreDet\t\t\t\t\t'), 'match', 'split');
        if size(match,1) > 0
            % Extract all ignore flags
            handles.([head,'ignore']) = cell2mat(textscan(nomatch{2}, ...
                repmat('%f ', 1, sum(handles.([head,'num'])) + 1)));

            % Scan for all data
            data = textscan(fid, ['%s', repmat(' %f', 1, sum(handles.([head,'num'])) + 8)]);
            data{1,1} = zeros(size(data{1,2},1),1);
            handles.([head,'data']) = cell2mat(data);
        end
    end
    
    % Close file handle
    fclose(fid);
end
    
    
    
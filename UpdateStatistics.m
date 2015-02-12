function handles = UpdateStatistics(handles, head)
% UpdateStatistics is called by FieldUniformity to compute and update
% the statistics table for each head.  See below for more information on
% the statistics computed.  This function uses GUI handles data (passed in
% the first input variable) loaded by BrowseCallback. This function also 
% uses the input variable head, which should be a string indicating the 
% head number (h1, h2, or h3) to determine which UI table to modify. Upon 
% successful completion, an updated GUI handles structure is returned.
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

% Run in try-catch statement
try
    
% Log start
Event(['Updating ', head, 'table statistics']);
tic;

% Load table data cell array
table = get(handles.([head, 'table']), 'Data');

% Initialize row counter
c = 0;

% Gamma parameters
c = c + 1;
table{c,1} = 'Gamma criteria';
table{c,2} = sprintf('%0.1f%%/%0.1f mm', [handles.abs, handles.dta]);

% Measured time
c = c + 1;
table{c,1} = 'Beam on time difference';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'tdata') && ...
        size(handles.([head, 'results']).tdata, 2) > 0
    
    % Find maximum value in profile
    [C, I] = max(handles.([head, 'results']).tdata(2,:));
    
    % Find highest lower index just below half maximum
    lI = find(handles.([head, 'results']).tdata(2, 1:I) < C/2, 1, 'last');

    % Find lowest upper index just above half maximum
    uI = find(handles.([head, 'results']).tdata(2, I:end) ...
        < C/2, 1, 'first');

    % Verify edges were found
    if isempty(uI) || isempty(lI)

        Event('Beam on/off times were not found', 'WARN');

    % Otherwise, verify edges are sufficiently far from array edges
    elseif lI-1 < 1 || lI+2 > size(handles.([head, 'results']).tdata, 2) || ...
            I+uI-3 < 1 || I+uI > size(handles.([head, 'results']).tdata, 2)

        Event(['Profiler data is too close to beam on/off to ', ...
            'compute beam on time'], 'WARN');
        
    % Otherwise, continue edge calculation
    else

        % Interpolate to find lower half-maximum value
        l = interp1(handles.([head, 'results']).tdata(2, lI-1:lI+2), ...
            handles.([head, 'results']).tdata(1, lI-1:lI+2), C/2, ...
            'linear')/1e3;

        % Interpolate to find upper half-maximum value
        u = interp1(handles.([head, 'results']).tdata(2, I+uI-3:I+uI), ...
            handles.([head, 'results']).tdata(1, I+uI-3:I+uI), C/2, ...
            'linear')/1e3;
        
        % Report FWHM of time signal
        table{c,2} = sprintf('%0.2f sec', (u - l) - handles.time);
        Event(sprintf(['Beam on time edges identified at %0.3f and ', ...
            '%0.3f seconds'], [l u]));
    end

    % Clear temporary variables
    clear l lI u uI C I;
end

% MLC X FWHM Difference
c = c + 1;
table{c,1} = 'MLC X FWHM difference';
if isfield(handles, [head, 'refresults']) && ...
        isfield(handles.([head, 'refresults']), 'yfwhm') && ...
        isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'yfwhm')
    
    % Report FWHM difference
    table{c,2} = sprintf('%0.2f mm', handles.([head, 'results']).yfwhm(1) ...
        - handles.([head, 'refresults']).yfwhm(1));
end

% MLC X Flatness
c = c + 1;
table{c,1} = 'MLC X flatness';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'yflat')
    
    % Report flatness
    table{c,2} = sprintf('%0.2f%%', ...
        handles.([head, 'results']).yflat(1) * 100);
end

% MLC X Areal Symmetry
c = c + 1;
table{c,1} = 'MLC X areal symmetry';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'ysym')
    
    % Report flatness
    table{c,2} = sprintf('%0.2f%%', ...
        handles.([head, 'results']).ysym(1) * 100);
end

% MLC Y FWHM Difference
c = c + 1;
table{c,1} = 'MLC Y FWHM difference';
if isfield(handles, [head, 'refresults']) && ...
        isfield(handles.([head, 'refresults']), 'xfwhm') && ...
        isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'xfwhm')
    
    % Report FWHM difference
    table{c,2} = sprintf('%0.2f mm', handles.([head, 'results']).xfwhm(1) ...
        - handles.([head, 'refresults']).xfwhm(1));
end

% MLC Y Flatness
c = c + 1;
table{c,1} = 'MLC Y flatness';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'xflat')
    
    % Report flatness
    table{c,2} = sprintf('%0.2f%%', ...
        handles.([head, 'results']).xflat(1) * 100);
end

% MLC Y Areal Symmetry
c = c + 1;
table{c,1} = 'MLC Y areal symmetry';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'xsym')
    
    % Report flatness
    table{c,2} = sprintf('%0.2f%%', ...
        handles.([head, 'results']).xsym(1) * 100);
end

% MLC X Max Gamma
c = c + 1;
table{c,1} = 'MLC X max gamma';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'ygamma')
    
    % Report max gamma
    table{c,2} = sprintf('%0.2f', ...
        max(handles.([head, 'results']).ygamma(2,:)));
end

% MLC Y Max Gamma
c = c + 1;
table{c,1} = 'MLC Y max gamma';
if isfield(handles, [head, 'results']) && ...
        isfield(handles.([head, 'results']), 'xgamma')
    
    % Report max gamma
    table{c,2} = sprintf('%0.2f', ...
        max(handles.([head, 'results']).xgamma(2,:)));
end
    
% Set table data
set(handles.([head, 'table']), 'Data', table);

% Log completion
Event(sprintf('Statistics table updated successfully in %0.3f seconds', toc));

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end
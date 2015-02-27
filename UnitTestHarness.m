function UnitTestHarness()
% UnitTestHarness is a function that automatically runs a series of unit 
% tests on the most current and previous versions of this application.  The 
% unit test results are written to a GitHub Flavored Markdown text file 
% specified in the first line of this function below.  Also declared is the 
% location of any test data necessary to run the unit tests and locations 
% of the most recent and previous application vesion source code.
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

%% Declare Runtime Variables
% Log start
Event('Beginning unit test harness', 'UNIT');
time = tic;

% Declare name of report file (will be appended by _R201XX.md based on 
% MATLAB version)
report = './test_reports/unit_test';

% Declare location of test data. Column 1 is the name of the 
% test suite, column 2 is the absolute path to the file(s)
testData = {
    '27.3cm'     './test_data/Head1_G90_27p3.prm'
%    '10.5cm'     './test_data/Head3_G90_10p5.prm'
};

% Declare current version directory
currentApp = './';

% Declare prior version directories
priorApps = {
    '../viewray_fielduniformity-1.0'
    '../viewray_fielduniformity-1.1.0'
};

%% Load submodules and toolboxes
% Add snc_extract submodule to search path
addpath('./snc_extract/gamma');

% Check if MATLAB can find CalcGamma
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event('The snc_extract/gamma submodule does not exist in the path.', ...
        'ERROR');
end

%% Initialize Report
% Retrieve MATLAB version
v = regexp(version, '\((.+)\)', 'tokens');

% Open a write file handle to the report
Event(['Initializing report file ', ...
    char(fullfile(pwd, strcat(report, '_', v{1}, '.md')))], 'UNIT');
fid = fopen(char(fullfile(pwd, strcat(report, '_', v{1}, '.md'))), 'wt');

% Write introduction
Event('Writing introduction', 'UNIT');
fprintf(fid, ['The principal features of the ViewRay Field Uniformity-', ...
    'Timing Check tool have been tested between versions for a set of test', ...
    'cases to determine if regressions have been introduced which may ', ...
    'effect the results. These results are summarized below, grouped by ', ...
    'test suite. Note that pre-releases have not been included in this ', ...
    'unit testing. Computation times are presented based on the ', ...
    'following system configuration.\n\n']);

% Start table containing test configuration
Event('Writing test system configuration', 'UNIT');
fprintf(fid, '| Specification | Test System Configuration |\n');
fprintf(fid, '|----|----|\n');

% Retrieve CPU info
Event('Retrieving test system CPU status', 'UNIT');
info = cpuinfo();

% Write processor information
fprintf(fid, '| Operating System | %s %s |\n', info.OSType, info.OSVersion);
fprintf(fid, '| Processor | %s |\n', info.Name);
fprintf(fid, '| Frequency | %s |\n', info.Clock);
fprintf(fid, '| Number of Cores | %i |\n', info.NumProcessors);
fprintf(fid, '| L2 Cache (per core) | %s |\n', info.Cache);

% Retrieve memory info
Event('Retrieving test system memory status', 'UNIT');
info = meminfo();

% Write memory information
fprintf(fid, '| Memory | %0.2f GB (%0.2f GB available) |\n', ...
    info.Total/1024^3, info.Unused/1024^3);

% Test for GPU
Event('Retrieving compatible GPU status', 'UNIT');
try 
    % Store GPU information to temporary variable
    g = gpuDevice(1);
    
    % Print GPU information
    fprintf(fid, '| Graphics Card | %s |\n', g.Name);
    fprintf(fid, '| Graphics Memory | %0.0f MB (%0.0f MB available) |\n', ...
        g.TotalMemory / 1024^2, g.FreeMemory / 1024^2);
    fprintf(fid, '| CUDA Version | %s |\n', g.ComputeCapability);
    
    % Clear temporary variable
    clear g;
catch 
    fprintf(fid, '| Graphics Card | No compatible GPU device found |\n');
    fprintf(fid, '| Graphics Total Memory | |\n');
    fprintf(fid, '| Graphics Memory Available | |\n');
    fprintf(fid, '| CUDA Version | |\n');
end

% Write MATLAB version
fprintf(fid, '| MATLAB Version | %s |\n', v{1}{1});
fprintf(fid, '\n');

% Clear temporary variables
clear info;

% Write remainder of introduction
Event('Writing unit test summary', 'UNIT');
fprintf(fid, ['Unit testing was performed using an automated test harness ', ...
    'developed to test each application component and, where relevant, ', ...
    'compare the results to pre-validated reference data.  Refer to the ', ...
    'documentation in `UnitTestHarness()` for details on how each test ', ...
    'case was performed.  Each Unit Test is referenced to one or more ', ...
    'requirements through the [[Traceability Matrix]] using the Test ID', ...
    '.\n\n']);

%% Execute Unit Tests
% Store current working directory
cwd = pwd;
Event(['Unit test harness working directory is ', cwd], 'UNIT');

% Start profiler
profile off;
profile on -history;
S = profile('status');
Event(sprintf(['MATLAB profiler initialized\nStatus: %s\n', ...
    'Detail level: %s\nTimer: %s\nHistory tracking: %s\nHistory size: %i'], ...
    S.ProfilerStatus, S.DetailLevel, S.Timer, S.HistoryTracking, ...
    S.HistorySize), 'UNIT');
clear S;

% Loop through each test case
for i = 1:size(testData, 1)
    
    % Restore default search path
    Event('Restoring MATLAB default path', 'UNIT');
    restoredefaultpath;

    % Restore current directory
    Event('Reverting to unit test working directory', 'UNIT');
    cd(cwd);
    
    % Execute unit test of current/reference version
    Event(sprintf(['Executing UnitTest(%s) with test dataset %i and ', ...
        'collecting reference'], fullfile(cwd, currentApp), i), 'UNIT');
    [preamble, t, footnotes, reference] = ...
        UnitTest(fullfile(cwd, currentApp), fullfile(cwd, testData{i,2}));

    % Pre-allocate results cell array
    results = cell(size(t,1), length(priorApps)+3);

    % Store reference tempresults in first and last columns
    results(:,1) = t(:,1);
    results(:,2) = t(:,2);
    results(:,length(priorApps)+3) = t(:,3);

    % Loop through each prior version
    for j = 1:length(priorApps)

        % Restore default search path
        Event('Restoring MATLAB default path', 'UNIT');
        restoredefaultpath;
        
        % Restore current directory
        Event('Reverting to unit test working directory', 'UNIT');
        cd(cwd);
        
        % Execute unit test on prior version
        Event(sprintf('Executing UnitTest(%s) with test dataset %i', ...
            fullfile(cwd, priorApps{j}), i), 'UNIT');
        [~, t, ~] = UnitTest(fullfile(cwd, priorApps{j}), ...
            fullfile(cwd, testData{i,2}), reference);

        % Store prior version results
        results(:,j+2) = t(:,3);
        
        % Clear temporary variables
        clear t;
    end

    % Print unit test header
    Event(sprintf('Writing test suite results for dataset %i', i), 'UNIT');
    fprintf(fid, '## %s Test Suite Results\n\n', testData{i,1});
    
    % Print preamble
    Event('Writing test suite preamble', 'UNIT');
    for j = 1:length(preamble)
        fprintf(fid, '%s\n', preamble{j});
    end
    fprintf(fid, '\n');
    
    % Loop through each table row
    Event('Writing test suite results table', 'UNIT');
    for j = 1:size(results,1)
        
        % Print table row
        fprintf(fid, '| %s |\n', strjoin(results(j,:), ' | '));
       
        % If this is the first column
        if j == 1
            
            % Also print a separator row
            fprintf(fid, '|%s\n', repmat('----|', 1, size(results,2)));
        end

    end
    fprintf(fid, '\n');
    
    % Print footnotes
    Event('Writing test suite footnotes', 'UNIT');
    for j = 1:length(footnotes) 
        fprintf(fid, '%s<br>\n', footnotes{j});
    end
    fprintf(fid, '\n');
end

% Stop profiler
stats = profile('info');
Event(sprintf(['Stopping and retrieving MATLAB profiler status\n', ...
    'Functions profiled: %i'], size(stats.FunctionTable, 1)), 'UNIT');

% Initialize file list with currentApp
fList = cell(0);
f = matlab.codetools.requiredFilesAndProducts(...
    fullfile(cwd, currentApp, 'FieldUniformity.m'));
Event(sprintf('%i required functions identified in %s', length(f), ...
    fullfile(cwd, currentApp)), 'UNIT');

% Loop through files, saving file names
for i = 1:length(f)
    
    % Retrieve file name
    [~, name, ~] = fileparts(f{i});
    
    % If file is within currentApp
    if strncmp(fullfile(cwd, currentApp), f{j}, ...
            length(fullfile(cwd, currentApp)))
    
        % Store file name
        fList{length(fList)+1} = name;
    end
end

% Loop through priorApps
for i = 1:length(priorApps)

    % Retrieve priorApp file list
    f = matlab.codetools.requiredFilesAndProducts(...
        fullfile(cwd, priorApps{i}, 'FieldUniformity.m'));
    Event(sprintf('%i required functions identified in %s', length(f), ...
        fullfile(cwd, priorApps{i})), 'UNIT');

    % Loop through files, saving file names
    for j = 1:length(f)
        
        % Retrieve file name
        [~, name, ~] = fileparts(f{j});
       
        % If file is within priorApps
        if strncmp(fullfile(cwd, priorApps{i}), f{j}, ...
                length(fullfile(cwd, priorApps{i})))
        
            % Store file name
            fList{length(fList)+1} = name;
        end
    end
end

% Remove duplicates
fList = unique(fList);
Event(sprintf('%i unique functions identified', length(fList)), 'UNIT');

% Sort array
fList = sort(fList);

% Initialize code coverage table
Event('Computing code coverage', 'UNIT');
executed = zeros(length(fList), size(results, 2)-2);
total = zeros(length(fList), size(results, 2)-2);

% Loop through FunctionTable
for i = 1:size(stats.FunctionTable, 1)
    
    % Initialize column and row indices
    c = 0;
    
    % Extract the filename
    [~, name, ~] = fileparts(stats.FunctionTable(i).FileName);
        
    % If the filename is this file, skip it
    if strcmp(name, 'UnitTestHarness'); continue; end
    
    % If FileName is within the currentApp
    if strncmp(fullfile(cwd, currentApp), stats.FunctionTable(i).FileName, ...
            length(fullfile(cwd, currentApp)))
        
        % Set column index
        c = size(executed, 2);
    else
        % Loop through priorApps
        for j = 1:length(priorApps)
            
            % If FileName is within priorApps
            if strncmp(fullfile(cwd, priorApps{j}), ...
                    stats.FunctionTable(i).FileName, ...
                    length(fullfile(cwd, priorApps{j})))
                
                % Set column index and end for loop
                c = j;
                break;
            end
        end
    end
    
    % If the column index was set
    if c > 0
        
        % Loop through the file list
        for j = 1:length(fList)
           
            % If the current file already exists in the list (this will 
            % happen for subfunctions) or the file list is empty (the file
            % was not found)
            if strcmp(fList{j}, name) || isempty(fList{j})
                
                % Update files cell array
                fList{j} = name;
                
                % Add the number of executed lines
                executed(j, c) = executed(j, c) + ...
                    size(stats.FunctionTable(i).ExecutedLines, 1);
                
                % If the total number of lines has not been computed yet
                if total(j, c) == 0
                    total(j, c) = sloc(stats.FunctionTable(i).FileName);
                    Event(sprintf('Total line count for %s computed as %i', ...
                        stats.FunctionTable(i).FileName, total(j, c)), ...
                        'UNIT');
                end
                
                % Break from the loop
                break;
            end
        end
    end
end

% Print code coverage header
Event('Writing code coverage results', 'UNIT');
fprintf(fid, '## Code Coverage\n\n');

% Print table header row
fprintf(fid, '| Function |');
fprintf(fid, ' %s |', results{1, 3:end});
fprintf(fid, '\n');

% Print a separator row
fprintf(fid, '|%s', repmat('----|', 1, size(results,2)-1));

% Loop through each file
for i = 1:length(fList)
    
    % If a file name exists
    if ~isempty(fList{i})
       
        % Write the file name
        fprintf(fid, '\n| %s |', fList{i});
        
        % Loop through the results
        for j = 1:size(executed, 2)
            
            % If the total number of lines were computed
            if total(i,j) > 0
                
                % Printf the coverage
                fprintf(fid, ' %0.1f%% |', executed(i,j)/total(i,j) * 100);
            else
                
                % Otherwise, print an empty cell
                fprintf(fid, '   |');
            end
        end
    end
end

% Close file handle
fclose(fid);

% Save profiler results to HTML file
% [path, ~, ~] = fileparts(char(fullfile(cwd, report)));
% Event(['Saving profiler results to ', path]);
% profsave(stats, path);

% Restore current directory
Event('Reverting to unit test working directory', 'UNIT');
cd(cwd);

% Log completion and time
Event(sprintf('Unit test harness completed successfully in %0.1f minutes', ...
    toc(time)/60), 'UNIT');

% Clear temporary variables
clear c i j v f t fid fList preamble results footnotes reference cwd ...
    executed total name currentApp priorApps report stats testData time;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = UnitTest(varargin)
% UnitTest is a subfunction of UnitTestHarness and is what really executes 
% the unit test cases for each software version.  Either two or three input
% arguments can be passed to UnitTestWorker, as described below.
%
% The following variables are required for proper execution: 
%   varargin{1}: string containing the path to the main function
%   varargin{2}: string containing the path to the test data
%   varargin{3} (optional): structure containing reference data to be used
%       for comparison.  If not provided, it is assumed that this version
%       is the reference and therefore all comparison tests will "Pass".
%
% The following variables are returned upon succesful completion:
%   varargout{1}: cell array of strings containing preamble text that
%       summarizes the test, where each cell is a line. This text will
%       precede the results table in the report.
%   varargout{2}: n x 3 cell array of strings containing the test ID in
%       the first column, name in the second, and result (Pass/Fail or 
%       numerical values typically) of the test in the third.
%   varargout{3}: cell array of strings containing footnotes referenced by
%       the tests, where each cell is a line.  This text will follow the
%       results table in the report.
%   varargout{4} (optional): structure containing reference data created by 
%       executing this version.  This structure can be passed back into 
%       subsequent executions of UnitTestWorker as varargin{3} to compare
%       results between versions.

% Initialize static test result text variables
pass = 'Pass';
fail = 'Fail';
unk = 'N/A';

%% Start Unit Testing
% Initialize preamble text
preamble = {
    '| Input Data | Value |'
    '|------------|-------|'
};

% Initialize results cell array
results = cell(0,3);

% Initialize footnotes cell array
footnotes = cell(0,1);

%% TEST 1: Application Load Time
% Change to directory of version being tested
cd(varargin{1});

% Open application, storing figure handle
t = tic;
h = FieldUniformity;
time = toc(t);

% Retrieve guidata
data = guidata(h);

% Set unit test flag to 1 (to avoid uigetfile/questdlg/user input)
data.unitflag = 1; 

% Compute numeric version (equal to major * 10000 + minor * 100 + bug)
c = regexp(data.version, '^([0-9]+)\.([0-9]+)\.*([0-9]*)', 'tokens');
version = str2double(c{1}{1})*10000 + str2double(c{1}{2})*100 + ...
    max(str2double(c{1}{3}),0);

% Add version to results
results{size(results,1)+1,1} = 'ID';
results{size(results,1),2} = 'Test Case';
results{size(results,1),3} = sprintf('Version&nbsp;%s', data.version);

% Update guidata
guidata(h, data);

%% TEST 2/3: Code Analyzer Messages, Cumulative Cyclomatic Complexity
fList = matlab.codetools.requiredFilesAndProducts('FieldUniformity.m');

% Initialize complexity and messages counters
comp = 0;
mess = 0;

% Loop through each dependency
for i = 1:length(fList)
    
    % Execute checkcode
    inform = checkcode(fList{i}, '-cyc');
    
    % Loop through results
    for j = 1:length(inform)
       
        % Check for McCabe complexity output
        c = regexp(inform(j).message, ...
            '^The McCabe complexity .+ is ([0-9]+)\.$', 'tokens');
        
        % If regular expression was found
        if ~isempty(c)
            
            % Add complexity
            comp = comp + str2double(c{1});
            
        else
            
            % If not an invalid code message
            if ~strncmp(inform(j).message, 'Filename', 8)
                
                % Log message
                Event(sprintf('%s in %s', inform(j).message, fList{i}), ...
                    'CHCK');

                % Add as code analyzer message
                mess = mess + 1;
            end
        end
        
    end
end

% Add code analyzer messages counter to results
results{size(results,1)+1,1} = '1';
results{size(results,1),2} = 'Code Analyzer Messages';
results{size(results,1),3} = sprintf('%i', mess);

% Add complexity results
results{size(results,1)+1,1} = '2';
results{size(results,1),2} = 'Cumulative Cyclomatic Complexity';
results{size(results,1),3} = sprintf('%i', comp);

% Add application load time
results{size(results,1)+1,1} = '3';
results{size(results,1),2} = 'Application Load Time<sup>1</sup>';
results{size(results,1),3} = sprintf('%0.1f sec', time);
footnotes{length(footnotes)+1} = ['<sup>1</sup>Prior to Version 1.1 ', ...
    'only the 27.3 cm x 27.3 cm reference profile existed'];

%% TEST 4/5: Reference Data Loads Successfully, Load Time
% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100

    % Execute LoadProfilerReference in try/catch statement
    try
        t = tic;
        pf = pass;
        LoadProfilerDICOMReference(data.references, '90');
    catch
        
        % If it errors, record fail
        pf = fail;
    end
    
    % Record completion time
    time = toc(t);
    
% If version < 1.1.0    
else
    
    % Execute LoadReferenceProfiles in try/catch statement
    try
        t = tic;
        pf = pass;
        LoadReferenceProfiles(...
            'AP_27P3X27P3_PlaneDose_Vertical_Isocenter.dcm');
    catch
        
        % If it errors, record fail
        pf = fail;
    end
    
    % Record completion time
    time = toc(t);
end

% Add success message
results{size(results,1)+1,1} = '4';
results{size(results,1),2} = 'Reference Data Loads Successfully';
results{size(results,1),3} = pf;

% Add result (with footnote)
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Reference Data Load Time<sup>1</sup>';
results{size(results,1),3} = sprintf('%0.1f sec', time);

%% TEST 6/7: Reference Data Identical
% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100
    
    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.refdata, varargin{3}.refdata)

            % Record pass
            xpf = pass;
            ypf = pass;
        else
            
            % Record fail
            xpf = fail;
            ypf = pass;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.refdata = data.refdata;

        % Assume pass
        xpf = pass;
        ypf = pass;

        % Add reference profiles to preamble
        preamble{length(preamble)+1} = ['| Reference&nbsp;Data | ', ...
            data.references{1}, '<br>', strjoin(data.references(2:end), ...
            '<br>'), ' |'];
    end
    
% If version < 1.1.0    
else
    
    % If reference data exists
    if nargin == 3

        % Compute MLC X gamma using 1%/0.1 mm and global method
        target.start = data.refX(1,1)/10;
        target.width = (data.refX(1,2)-data.refX(1,1))/10;
        target.data = data.refX(2,:)/max(data.refX(2,:));
        ref.start = varargin{3}.refdata.ydata(1,1);
        ref.width = varargin{3}.refdata.ydata(1,2) - ...
            varargin{3}.refdata.ydata(1,1);
        ref.data = varargin{3}.refdata.ydata(3,:)/...
            max(varargin{3}.refdata.ydata(3,:));
        gamma = CalcGamma(ref, target, 1, 0.01, 0);

        % If the gamma rate is less than one
        if max(gamma) < 1

            % Record pass
            xpf = pass;
        else
            
            % Record fail
            xpf = fail;
        end

        % Compute MLC Y gamma using 1%/0.1 mm and global method
        target.start = data.refY(1,1)/10;
        target.width = (data.refY(1,2)-data.refY(1,1))/10;
        target.data = data.refY(2,:)/max(data.refY(2,:));
        ref.start = varargin{3}.refdata.xdata(1,1);
        ref.width = varargin{3}.refdata.xdata(1,2) - ...
            varargin{3}.refdata.xdata(1,1);
        ref.data = varargin{3}.refdata.xdata(3,:)/...
            max(varargin{3}.refdata.xdata(3,:));
        gamma = CalcGamma(ref, target, 1, 0.01, 0);

        % If the gamma rate is less than one
        if max(gamma) < 1

            % Record pass
            ypf = pass;
        else
            
            % Record fail
            ypf = fail;
        end

    % Otherwise, no reference data exists
    else
        xpf = unk;
        ypf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '6';
results{size(results,1),2} = 'Reference MLC X Data within 1%/0.1 mm';
results{size(results,1),3} = xpf;

% Add result with footnote
results{size(results,1)+1,1} = '7';
results{size(results,1),2} = 'Reference MLC Y Data within 1%/0.1 mm<sup>2</sup>';
results{size(results,1),3} = ypf;
footnotes{length(footnotes)+1} = ['<sup>2</sup>[#10](../issues/10) ', ...
    'In Version 1.0 a bug was identified where MLC Y T&G effect was not', ...
    ' accounted for in the reference data'];

%% TEST 8/9: H1 Browse Loads Data Successfully/Load Time
% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 browse button
callback = get(data.h1browse, 'Callback');

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    pf = pass;
    callback(data.h1browse, data);
catch

    % If it errors, record fail
    pf = fail;
end

% Record completion time
time = toc(t);

% Add result
results{size(results,1)+1,1} = '8';
results{size(results,1),2} = 'H1 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '9';
results{size(results,1),2} = 'Browse Callback Load Time';
results{size(results,1),3} = sprintf('%0.1f sec', time);

%% TEST 10: MLC X Profile Identical
% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ydata(1,:), varargin{3}.ydata(1,:)) && ...
                isequal(data.h1results.ydata(2,:), varargin{3}.ydata(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ydata = data.h1results.ydata;

        % Assume pass
        pf = pass;

        % Add test data to preamble
        preamble{length(preamble)+1} = sprintf('| Measured Data | %s |', ...
            data.unitname);
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1%
        if isequal(data.h1X(1,:)/10, varargin{3}.ydata(1,:)) && ...
                max(abs(data.h1X(2,:) - varargin{3}.ydata(2,:))) < 0.001

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '10';
results{size(results,1),2} = 'MLC X Profile within 0.1%';
results{size(results,1),3} = pf;

%% TEST 11: MLC Y Profile Identical
% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.xdata(1,:), varargin{3}.xdata(1,:)) && ...
                isequal(data.h1results.xdata(2,:), varargin{3}.xdata(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.xdata = data.h1results.xdata;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1%
        if isequal(data.h1Y(1,:)/10, varargin{3}.xdata(1,:)) && ...
                max(abs(data.h1Y(2,:) - varargin{3}.xdata(2,:))) < 0.001

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '11';
results{size(results,1),2} = 'MLC Y Profile within 0.1%';
results{size(results,1),3} = pf;

%% TEST 12: Positive Diagonal Profile Identical (> 1.1.0)
% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.pdiag(1,:), varargin{3}.pdiag(1,:)) && ...
                isequal(data.h1results.pdiag(2,:), varargin{3}.pdiag(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.pdiag = data.h1results.pdiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result with footnote
results{size(results,1)+1,1} = '12';
results{size(results,1),2} = 'Positive Diagonal Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;
footnotes{length(footnotes)+1} = ['<sup>3</sup>Prior to Version 1.1 ', ...
    'diagonal profiles were not available'];

%% TEST 13: Negative Diagonal Profile Identical (>1.1.0)
% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ndiag(1,:), varargin{3}.ndiag(1,:)) && ...
                isequal(data.h1results.ndiag(2,:), varargin{3}.ndiag(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ndiag = data.h1results.ndiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result
results{size(results,1)+1,1} = '13';
results{size(results,1),2} = 'Negative Diagonal Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 14: Timing Profile Identical
% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ndiag(1,:), varargin{3}.ndiag(1,:)) && ...
                isequal(data.h1results.ndiag(2,:), varargin{3}.ndiag(2,:))

            % Record pass
            pf = pass;
        else

            % Record fail
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ndiag = data.h1results.ndiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result
results{size(results,1)+1,1} = '14';
results{size(results,1),2} = 'Timing Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 15: MLC X Gamma Identical

%% TEST 16: MLC Y Gamma Identical

%% TEST 17: Positive Diagonal Gamma Identical (> 1.1.0)

%% TEST 18: Negative Diagonal Gamma Identical (> 1.1.0)

%% TEST 19: Statistics Identical

%% TEST 20: H1 Figures Functional

%% TEST 21/22: H2/H3 Browse Loads Data Successfully

%% TEST 23: Print Report Functional (> 1.1.0)

%% TEST 24/25: H2/H3 Figures Functional

%% TEST 26/27/28: Clear All Buttons Functional

%% TEST 29: Documentation Correct


%% Finish up
% Close all figures
close all force;

% Store return variables
varargout{1} = preamble;
varargout{2} = results;
varargout{3} = footnotes;
if nargout == 4
    varargout{4} = reference;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = meminfo()
%MEMINFO  return system physical memory information
%
%   info = MEMINFO() returns a structure containing various bits of
%   information about the system memory. This information includes:
%     * TOTAL Memory in bytes
%     * USED Memory in bytes
%     * UNUSED Memory in bytes
%
%   See also: COMPUTER, ISUNIX, ISMAC

if isunix
    if ismac
        [~, text] = unix('top -l 1');
        fields = textscan(text, '%s', 'Delimiter', '\n' ); 
        fields = fields{1};
        fields( cellfun( 'isempty', fields ) ) = [];
        for i = 1:length(fields)
            tokens = regexp(fields{i}, ['^PhysMem[^0-9]+([0-9]+)M used', ...
                '[^0-9]+([0-9]+)M wired[^0-9]+([0-9]+)M unused'], 'tokens');
            if ~isempty(tokens)
                info = struct('Used', str2double(tokens{1}{1})*1024^2, ...
                    'Wired', str2double(tokens{1}{2})*1024^2, ...
                    'Unused', str2double(tokens{1}{3})*1024^2, ...
                    'Total', (str2double(tokens{1}{1}) + ...
                    str2double(tokens{1}{3}))*1024^2);
                break;
            end
        end
    else
        [~, text] = unix('top -n 1');
        fields = textscan(text, '%s', 'Delimiter', '\n' ); 
        fields = fields{1};
        fields( cellfun( 'isempty', fields ) ) = [];
        for i = 1:length(fields)
            tokens = regexp(fields{i}, ['^Mem[^0-9]+([0-9]+)k total', ...
                '[^0-9]+([0-9]+)k used[^0-9]+([0-9]+)M free'], 'tokens');
            if ~isempty(tokens)
                info = struct('Total', str2double(tokens{1}{1})*1024, ...
                    'Used', str2double(tokens{1}{2})*1024, ...
                    'Unused', str2double(tokens{1}{3})*1024);
                break;
            end
        end
    end
else
    [~, sys] = memory;
    info = struct('Total', sys.PhysicalMemory.Total, 'Used', ...
        sys.PhysicalMemory.Total - sys.PhysicalMemory.Available, ...
        'Unused', sys.PhysicalMemory.Available);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuinfo()
%CPUINFO  read CPU configuration
%
%   info = CPUINFO() returns a structure containing various bits of
%   information about the CPU and operating system as provided by /proc/cpu
%   (Unix), sysctl (Mac) or WMIC (Windows). This information includes:
%     * CPU name
%     * CPU clock speed
%     * CPU Cache size (L2)
%     * Number of physical CPU cores
%     * Operating system name & version
%
%   See also: COMPUTER, ISUNIX, ISMAC

%   Author: Ben Tordoff
%   Copyright 2011 The MathWorks, Inc.

if isunix
    if ismac
        info = cpuInfoMac();
    else
        info = cpuInfoUnix();
    end
else
    info = cpuInfoWindows();
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuInfoWindows()
sysInfo = callWMIC( 'cpu' );
osInfo = callWMIC( 'os' );

info = struct( ...
    'Name', sysInfo.Name, ...
    'Clock', [sysInfo.MaxClockSpeed,' MHz'], ...
    'Cache', [sysInfo.L2CacheSize,' KB'], ...
    'NumProcessors', str2double( sysInfo.NumberOfCores ), ...
    'OSType', 'Windows', ...
    'OSVersion', osInfo.Caption );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = callWMIC( alias )
% Call the MS-DOS WMIC (Windows Management) command
olddir = pwd();
cd( tempdir );
sysinfo = evalc( sprintf( '!wmic %s get /value', alias ) );
cd( olddir );
fields = textscan( sysinfo, '%s', 'Delimiter', '\n' ); 
fields = fields{1};
fields( cellfun( 'isempty', fields ) ) = [];
% Each line has "field=value", so split them
values = cell( size( fields ) );
for ff=1:numel( fields )
    idx = find( fields{ff}=='=', 1, 'first' );
    if ~isempty( idx ) && idx>1
        values{ff} = strtrim( fields{ff}(idx+1:end) );
        fields{ff} = strtrim( fields{ff}(1:idx-1) );
    end
end

% Remove any duplicates (only occurs for dual-socket PC's and we will
% assume that all sockets have the same processors in them).
numResults = sum( strcmpi( fields, fields{1} ) );
if numResults>1
    % If we are counting cores, sum them.
    numCoresEntries = find( strcmpi( fields, 'NumberOfCores' ) );
    if ~isempty( numCoresEntries )
        cores = cellfun( @str2double, values(numCoresEntries) );
        values(numCoresEntries) = {num2str( sum( cores ) )};
    end
    % Now remove the duplicate results
    [fields,idx] = unique(fields,'first');
    values = values(idx);
end

% Convert to a structure
info = cell2struct( values, fields );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuInfoMac()
machdep = callSysCtl( 'machdep.cpu' );
hw = callSysCtl( 'hw' );
info = struct( ...
    'Name', machdep.brand_string, ...
    'Clock', [num2str(str2double(hw.cpufrequency_max)/1e6),' MHz'], ...
    'Cache', [machdep.cache.size,' KB'], ...
    'NumProcessors', str2double( machdep.core_count ), ...
    'OSType', 'Mac OS X', ...
    'OSVersion', getOSXVersion() );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = callSysCtl( namespace )
infostr = evalc( sprintf( '!sysctl -a %s', namespace ) );
% Remove the prefix
infostr = strrep( infostr, [namespace,'.'], '' );
% Now break into a structure
infostr = textscan( infostr, '%s', 'delimiter', '\n' );
infostr = infostr{1};
info = struct();
for ii=1:numel( infostr )
    colonIdx = find( infostr{ii}==':', 1, 'first' );
    if isempty( colonIdx ) || colonIdx==1 || colonIdx==length(infostr{ii})
        continue
    end
    prefix = infostr{ii}(1:colonIdx-1);
    value = strtrim(infostr{ii}(colonIdx+1:end));
    while ismember( '.', prefix )
        dotIndex = find( prefix=='.', 1, 'last' );
        suffix = prefix(dotIndex+1:end);
        prefix = prefix(1:dotIndex-1);
        value = struct( suffix, value );
    end
    info.(prefix) = value;
    
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function vernum = getOSXVersion()
% Extract the OS version number from the system software version output.
ver = evalc('system(''sw_vers'')');
vernum = ...
    regexp(ver, 'ProductVersion:\s([1234567890.]*)', 'tokens', 'once');
vernum = strtrim(vernum{1});

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = cpuInfoUnix()
txt = readCPUInfo();
cpuinfo = parseCPUInfoText( txt );

txt = readOSInfo();
osinfo = parseOSInfoText( txt );

% Merge the structures
info = cell2struct( [struct2cell( cpuinfo );struct2cell( osinfo )], ...
    [fieldnames( cpuinfo );fieldnames( osinfo )] );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = parseCPUInfoText( txt )
% Now parse the fields
lookup = {
    'model name', 'Name'
    'cpu Mhz', 'Clock'
    'cpu cores', 'NumProcessors'
    'cache size', 'Cache'
    };
info = struct( ...
    'Name', {''}, ...
    'Clock', {''}, ...
    'Cache', {''} );
for ii=1:numel( txt )
    if isempty( txt{ii} )
        continue;
    end
    % Look for the colon that separates the property name from the value
    colon = find( txt{ii}==':', 1, 'first' );
    if isempty( colon ) || colon==1 || colon==length( txt{ii} )
        continue;
    end
    fieldName = strtrim( txt{ii}(1:colon-1) );
    fieldValue = strtrim( txt{ii}(colon+1:end) );
    if isempty( fieldName ) || isempty( fieldValue )
        continue;
    end
    
    % Is it one of the fields we're interested in?
    idx = find( strcmpi( lookup(:,1), fieldName ) );
    if ~isempty( idx )
        newName = lookup{idx,2};
        info.(newName) = fieldValue;
    end
end

% Convert clock speed
info.Clock = [info.Clock, ' MHz'];

% Convert num cores
info.NumProcessors = str2double( info.NumProcessors );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function info = parseOSInfoText( txt )
info = struct( ...
    'OSType', 'Linux', ...
    'OSVersion', '' );
% find the string "linux version" then look for the bit in brackets
[~,b] = regexp( txt, '[^\(]*\(([^\)]*)\).*', 'match', 'tokens', 'once' );
info.OSVersion = b{1}{1};

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = readCPUInfo()

fid = fopen( '/proc/cpuinfo', 'rt' );
if fid<0
    error( 'cpuinfo:BadPROCCPUInfo', ...
        'Could not open /proc/cpuinfo for reading' );
end
out = onCleanup( @() fclose( fid ) );

txt = textscan( fid, '%s', 'Delimiter', '\n' );
txt = txt{1};

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = readOSInfo()

fid = fopen( '/proc/version', 'rt' );
if fid<0
    error( 'cpuinfo:BadProcVersion', ...
        'Could not open /proc/version for reading' );
end
out = onCleanup( @() fclose( fid ) );

txt = textscan( fid, '%s', 'Delimiter', '\n' );
txt = txt{1};

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sl = sloc(file)
%SLOC Counts number source lines of code.
%   SL = SLOC(FILE) returns the line count for FILE.  If there are multiple
%   functions in one file, subfunctions are not counted separately, but
%   rather together.
%
%   The following lines are not counted as a line of code:
%   (1) The "function" line
%   (2) A line that is continued from the previous line --> ...
%   (3) A comment line, a line that starts with --> % or a line that is
%       part of a block comment (   %{...%}   )
%   (4) A blank line
%
%   Note: If more than one statement is on the line, it counts that as one
%   line of code.  For instance the following:
%
%        minx = 32; maxx = 100;
%
%   is considered to be one line of code.  Also, if the creation of a
%   matrix is continued onto several line without the use of '...', SLOC
%   will deem that as separate lines of code.  Using '...' will "tie" the
%   lines together.
%
%   Example:
%   ========
%      sl = sloc('sloc')
%      sl =
%                41

%   Copyright 2004-2005 MathWorks, Inc.
%   Raymond S. Norris (rayn@mathworks.com)
%   $Revision: 1.4 $ $Date: 2006/03/08 19:50:30 $

if nargin==0
   help(mfilename)
   return
end

% Check to see if the ".m" is missing from the M-file name
file = deblank(file);
if length(file)<3 || ~strcmp(file(end-1:end),'.m')
   file = [file '.m'];
end

fid = fopen(file,'r');
if fid<0
   disp(['Failed to open ''' file ''' for reading.'])
   return
end

sl = 0;
done = false;
previous_line = '-99999';

v = ver('matlab');
atLeastR14 = datenum(v.Date)>=732519;

inblockcomment = false;

while done==false

   % Get the next line
   m_line = fgetl(fid);

   % If line is -1, we've reached the end of the file
   if m_line==-1
      break
   end

   % The Profiler doesn't include the "function" line of a function, so
   % skip it.  Because nested functions may be indented, trim the front of
   % the line of code.  Since we are string trimming the line, we may as 
   % well check here if the resulting string it empty.  If any of the above
   % is true, just continue onto the next line.
   m_line = strtrim(m_line);
   if strncmp(m_line,'function ',9) || isempty(m_line)
      continue
   end

   if atLeastR14
      % In R14, block comments where introduced ( %{...%} )
      if length(m_line)>1 && ...
            strcmp(m_line(1:2),'%{')
         inblockcomment = true;
      elseif length(previous_line)>1 && ...
            strcmp(previous_line(1:2),'%}')
         inblockcomment = false;
      end
   end

   % Check if comment line or if line continued from previous line
   if ~strcmp(m_line(1),'%') && ...
         ~(length(previous_line)>2 && ...
         strcmp(previous_line(end-2:end),'...') && ...
         ~strcmp(previous_line(1),'%')) && ...
         ~inblockcomment
      sl = sl+1;
   end

   % Keep track of current line to see if the next line is a continuation
   % of the current
   previous_line = m_line;
end

fclose(fid);

end
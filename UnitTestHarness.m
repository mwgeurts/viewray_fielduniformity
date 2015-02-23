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
% Declare name of report file (will be appended by _R201XX.md based on 
% MATLAB version)
report = './test_reports/unit_test';

% Declare location of test data. Column 1 is the name of the 
% test suite, column 2 is the absolute path to the file(s)
testData = {
    '27.3cm'     './test_data/Head1_G90_27p3.prm'
    '10.5cm'     './test_data/Head3_G90_10p5.prm'
};

% Declare current version directory
currentApp = './';

% Declare prior version directories
priorApps = {
    '../viewray_fielduniformity-1.0'
    '../viewray_fielduniformity-1.1.0'
};

%% Initialize Report
% Retrieve MATLAB version
v = regexp(version, '\((.+)\)', 'tokens');

% Open a write file handle to the report
fid = fopen(char(fullfile(pwd, strcat(report, '_', v{1}, '.md'))), 'wt');

% Write introduction
fprintf(fid, ['The principal features of the ViewRay Field Uniformity-', ...
    'Timing Check tool have been tested between versions for a set of test', ...
    'cases to determine if regressions have been introduced which may ', ...
    'effect the results. These results are summarized below, grouped by ', ...
    'test suite. Note that pre-releases have not been included in this ', ...
    'unit testing. Computation times are presented based on the ', ...
    'following system configuration.\n\n']);

% Start table containing test configuration
fprintf(fid, '| Specification | Test System Configuration |\n');
fprintf(fid, '|--|--|\n');

% Retrieve CPU info
info = cpuinfo();

% Write processor information
fprintf(fid, '| Operating System | %s %s |\n', info.OSType, info.OSVersion);
fprintf(fid, '| Processor | %s |\n', info.Name);
fprintf(fid, '| Frequency | %s |\n', info.Clock);
fprintf(fid, '| Number of Cores | %s |\n', info.NumProcessors);
fprintf(fid, '| L2 Cache (per core) | %s |\n', info.Cache);

% Retrieve memory info
info = meminfo();

% Write memory information
fprintf(fid, '| Memory | %0.2f GB (%0.2f GB available) |\n', ...
    info.Total/1024^3, info.Unused/1024^3);

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

fprintf(fid, '| MATLAB Version | %s |\n', v{1}{1});
fprintf(fid, '\n');

% Clear temporary variables
clear info;

% Write remainder of introduction
fprintf(fid, ['Unit testing was performed using an automated test harness ', ...
    'developed to test each application component and, where relevant, ', ...
    'compare the results to pre-validated reference data.  Refer to the ', ...
    'documentation in `UnitTestHarness()` for details on how each test ', ...
    'case was performed.\n\n']);

%% Execute Unit Tests
% Store current working directory
cwd = pwd;

% Loop through each test case
for i = 1:length(testData)
    
    % Restore default search path
    restoredefaultpath;

    % Restore current directory
    cd(cwd);
    
    % Execute unit test of current/reference version
    [preamble, t, footnotes, reference] = ...
        UnitTest(currentApp, testData{i,2});

    % Pre-allocate results cell array
    results = cell(size(t,1), length(priorApps)+3);

    % Store reference tempresults in first and last columns
    results(:,1) = t(:,1);
    results(:,2) = t(:,2);
    results(:,length(priorApps)+3) = t(:,3);

    % Loop through each prior version
    for j = 1:length(priorApps)

        % Restore default search path
        restoredefaultpath;
        
        % Restore current directory
        cd(cwd);
        
        % Execute unit test on prior version
        [~, t, ~] = UnitTest(priorApps{j}, testData{i,2}, reference);

        % Store prior version results
        results(:,j+2) = t(:,3);
        
        % Clear temporary variables
        clear t;
    end

    % Print unit test header
    fprintf(fid, '## %s Test Suite Results\n\n', testData{i,1});
    
    % Print preamble
    for j = 1:length(preamble)
        fprintf(fid, '%s\n', preamble{j});
    end
    fprintf(fid, '\n');
    
    % Loop through each table row
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
    for j = 1:length(footnotes) 
        fprintf(fid, '%s\n', footnotes{j});
    end
    fprintf(fid, '\n');
end

% Close file handle
fclose(fid);

% Clear temporary variables
clear i j v fid preamble results footnotes reference;

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
unk = 'Unknown';

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
results{size(results,1),3} = sprintf('Version %s', data.version);

% Update guidata
guidata(h, data); 

%% Application Complexity
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
            
            % Add as code analyzer message
            mess = mess + 1;
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
results{size(results,1),3} = sprintf('%0.3f sec', time);
footnotes{length(footnotes)+1} = ['<sup>1</sup>Prior to Version 1.1 ', ...
    'only one reference profile existed'];

%% Verify reference data load
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
        pf = fail;
    end
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
        pf = fail;
    end
    time = toc(t);
end

% Add success message
results{size(results,1)+1,1} = '4';
results{size(results,1),2} = 'Reference Data Loads Successfully';
results{size(results,1),3} = pf;

% Add result (with footnote)
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Reference Data Load Time<sup>1</sup>';
results{size(results,1),3} = sprintf('%0.3f sec', time);

%% Verify reference profiles are identical
% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100
    
    % If reference data exists
    if nargin == 3

    % If current value equals the reference
    if isequal(data.refdata, varargin{3}.refdata)

        pf = pass;
    else
        pf = fail;
    end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.refdata = data.refdata;

        % Assume pass
        pf = pass;
    end
    
    % Add reference profiles to preamble
    preamble{length(preamble)+1} = ['| Reference Data | ', ...
        data.references{1}, ' ', strjoin(data.references(2:end), ' '), ' |'];
    
% If version < 1.1.0    
else
    pf = unk;
end

% Add result
results{size(results,1)+1,1} = '6';
results{size(results,1),2} = 'Reference Data Identical<sup>1</sup>';
results{size(results,1),3} = pf;

%% Verify PRM data loads in H1
% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 browse button
callback = get(data.h1browse, 'Callback');



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
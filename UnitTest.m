function varargout = UnitTest(varargin)
% UnitTest executes the unit tests for this application, and can be called 
% either independently (when testing just the latest version) or via 
% UnitTestHarness (when testing for regressions between versions).  Either 
% two or three input arguments can be passed to UnitTest as described 
% below.
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
%       subsequent executions of UnitTest as varargin{3} to compare results
%       between versions (or to a priori validated reference data).

%% Initialize Unit Testing
% Initialize static test result text variables
pass = 'Pass';
fail = 'Fail';
unk = 'N/A';

% Initialize preamble text
preamble = {
    '| Input Data | Value |'
    '|------------|-------|'
};

% Initialize results cell array
results = cell(0,3);

% Initialize footnotes cell array
footnotes = cell(0,1);

% Add snc_extract/gamma submodule to search path
addpath('./snc_extract/gamma');

% Check if MATLAB can find CalcGamma (used by the unit tests later)
if exist('CalcGamma', 'file') ~= 2
    
    % If not, throw an error
    Event('The CalcGamma submodule does not exist in the path.', ...
        'ERROR');
end

%% TEST 1/2: Application Loads Successfully, Time
%
% DESCRIPTION: This unit test attempts to execute the main application
%   executable and times how long it takes.  This test also verifies that
%   errors are present if the required submodules do not exist and that the
%   print report button is initially disabled.
%
% RELEVANT REQUIREMENTS: U001, F001, F021, F027, P001
%
% INPUT DATA: No input data required
%
% CONDITION A (+): With the appropriate submodules present, opening the
%   application andloads without error in the required time
%
% CONDITION B (-): With the snc_extract submodule missing, opening the 
%   application throws an error
%
% CONDITION C (-): The print report button is disabled
%   following application load (the positive condition for this requirement
%   is tested during unit test 25).
%
% CONDITION D (+): Gamma criteria are set upon application load

% Change to directory of version being tested
cd(varargin{1});

% Start with fail
pf = fail;

% Attempt to open application without submodule
try
    FieldUniformity('unitParseSNCprm');

% If it fails to open, the test passed
catch
    pf = pass;
end

% Close all figures
close all force;

% Open application again with submodule, this time storing figure handle
try
    t = tic;
    h = FieldUniformity;
    time = sprintf('%0.1f sec', toc(t));

% If it fails to open, the test failed  
catch
    pf = fail;
end

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

% If version >= 1.1.0
if version >= 010100
    
    % Verify that the print button is disabled
    if ~strcmp(get(data.print_button, 'enable'), 'off')
        pf = fail;
    end
end

% Verify that Gamma criteria exist
if ~isfield(data, 'abs') || ~isfield(data, 'dta') || data.abs == 0 || ...
        data.dta == 0
    pf = fail;
end

% Add application load result
results{size(results,1)+1,1} = '1';
results{size(results,1),2} = 'Application Loads Successfully';
results{size(results,1),3} = pf;

% Add application load time
results{size(results,1)+1,1} = '2';
results{size(results,1),2} = 'Application Load Time<sup>1</sup>';
results{size(results,1),3} = time;
footnotes{length(footnotes)+1} = ['<sup>1</sup>Prior to Version 1.1 ', ...
    'only the 27.3 cm x 27.3 cm reference profile existed'];

%% TEST 3/4: Code Analyzer Messages, Cumulative Cyclomatic Complexity
%
% DESCRIPTION: This unit test uses the checkcode() MATLAB function to check
%   each function used by the application and return any Code Analyzer
%   messages that result.  The cumulative cyclomatic complexity is also
%   computed for each function and summed to determine the total
%   application complexity.  Although this test does not reference any
%   particular requirements, it is used during development to help identify
%   high risk code.
%
% RELEVANT REQUIREMENTS: none 
%
% INPUT DATA: No input data required
%
% CONDITION A (+): Report any code analyzer messages for all functions
%   called by FieldUniformity
%
% CONDITION B (+): Report the cumulative cyclomatic complexity for all
%   functions called by FieldUniformity

% Search for required functions
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
results{size(results,1)+1,1} = '3';
results{size(results,1),2} = 'Code Analyzer Messages';
results{size(results,1),3} = sprintf('%i', mess);

% Add complexity results
results{size(results,1)+1,1} = '4';
results{size(results,1),2} = 'Cumulative Cyclomatic Complexity';
results{size(results,1),3} = sprintf('%i', comp);

%% TEST 5: Reference Data Loads Successfully
%
% DESCRIPTION: This unit test verifies that the reference data load
% subfunction runs without error.
%
% RELEVANT REQUIREMENTS: F002
%
% INPUT DATA: file names of reference profiles.  In version 1.1.0 and
%   later, this is stored in handles.references.  In earlier versions the
%   file name is written into the function call.
%
% CONDITION A (+): Execute LoadProfilerReference (version 1.1.0 and later)
%   or LoadReferenceProfiles with a valid reference DICOM file and verify
%   that the application executes correctly.
%
% CONDITION B (-): Execute the same function with invalid inputs and verify
%   that the function fails.

% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100

    % Execute LoadProfilerReference in try/catch statement
    try
        pf = pass;
        LoadProfilerDICOMReference(data.references, '90');
    
    % If it errors, record fail
    catch
        pf = fail;
    end
  
    % Execute LoadProfilerReference with no inputs in try/catch statement
    try
        LoadProfilerDICOMReference();
        pf = fail;
    catch
        % If it fails, test passed
    end
    
    % Execute LoadProfilerReference with one incorrect input in try/catch 
    % statement
    try
        LoadProfilerDICOMReference('asd');
        pf = fail;
    catch
        % If it fails, test passed
    end
    
% If version < 1.1.0    
else
    
    % Execute LoadReferenceProfiles in try/catch statement
    try
        pf = pass;
        LoadReferenceProfiles(...
            'AP_27P3X27P3_PlaneDose_Vertical_Isocenter.dcm');
    
    % If it errors, record fail
    catch
        pf = fail;
    end
    
    % Execute LoadReferenceProfiles with one incorrect input in try/catch 
    % statement
    try
        LoadReferenceProfiles('asd');
        pf = fail;
    catch
        % If it fails, test passed
    end
end

% Add success message
results{size(results,1)+1,1} = '5';
results{size(results,1),2} = 'Reference Data Loads Successfully';
results{size(results,1),3} = pf;

%% TEST 6/7: Reference Data Identical
%
% DESCRIPTION: This unit test verifies that the primary axis data (MLC X,
%   MLC Y) extracted from the reference data is identical to its expected
%   value.  For this test equivalency is defined as being within 1%/0.1mm
%   using a Gamma analysis.  For versions prior to 1.1.0, the reference
%   profile is compared to the first expected reference profile (which is
%   assumed to be 27.3 cm x 27.3 cm).
%
% RELEVANT REQUIREMENTS: F002, C013, C014
%
% INPUT DATA: Validated expected MLC X (data.refdata.xdata) and MLC Y 
%   profile data (data.refdata.ydata)
%
% CONDITION A (+): The extracted reference data matches expected MLC X and
%   MLC Y data exactly (version 1.1.0 and later) or within 1%/0.1 mm.
%
% CONDITION B (-): Modified reference data no longer matches expected MLC X
%   and MLC Y data.

% Retrieve guidata
data = guidata(h);
    
% If version >= 1.1.0
if version >= 010100
    
    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.refdata, varargin{3}.refdata)
            xpf = pass;
            ypf = pass;
        
        % Otherwise, it failed
        else
            xpf = fail;
            ypf = fail;
        end
        
        % Modify refdata
        data.refdata(1,1) = 0;
        
        % Verify current value now fails
        if isequal(data.refdata, varargin{3}.refdata)
            xpf = fail;
            ypf = fail;
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
            xpf = pass;
        else
            xpf = fail;
        end
        
        % Calc gamma again with different start value
        target.start = target.start + 1;
        gamma = CalcGamma(ref, target, 1, 0.01, 0);
        
        % If the gamma rate is less than one
        if max(gamma) < 1
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
            ypf = pass;
        else
            ypf = fail;
        end
        
        % Calc gamma again with different start value
        target.start = target.start + 1;
        gamma = CalcGamma(ref, target, 1, 0.01, 0);
        
        % If the gamma rate is less than one
        if max(gamma) < 1
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
%
% DESCRIPTION: This unit test verifies a callback exists for the H1 browse
%   button and executes it under unit test conditions (such that a file 
%   selection dialog box is skipped), simulating the process of a user
%   selecting input data.  The time necessary to load the file is also
%   checked.
%
% RELEVANT REQUIREMENTS: U002, U003, U004, U005, U006, F003, F004, F017, 
%   F018, P002, C012
%
% INPUT DATA: PRM file to be loaded (varargin{2})
%
% CONDITION A (+): The callback for the H1 browse button can be executed
%   without error when a valid filename is provided
%
% CONDITION B (-): The callback will throw an error if an invalid filename
%   is provided
%
% CONDITION C (+): The callback will return without error when no filename
%   is provided
%
% CONDITION D (+): Upon receiving a valid filename, the PRM data will be
%   automatically processed, storing a structure to data.h1results
%
% CONDITION E (+): Upon receiving a valid filename, the filename will be
%   displayed on the user interface
%
% CONDITION F (+): Report the time taken to execute the browse callback and 
%   parse the data
%
% CONDITION G (-): If measured data is provided where the FWHM is too close
%   to the edge, the application will return a FWHM of 0. 
%
% CONDITION H (+): Correlation data will exist in data.h1results.corr

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 browse button
callback = get(data.h1browse, 'Callback');

% Set empty unit path/name
data.unitpath = '';
data.unitname = '';

% Force specific gamma criteria (3%/1mm)
data.abs = 3;

% If version >= 1.1.0
if version >= 010100
    
    % Store DTA in cm
    data.dta = 0.1;
else
    
    % Store DTA in mm
    data.dta = 1;
end

% Add gamma criteria to preamble
preamble{length(preamble)+1} = '| Gamma Criteria | 3%/1mm |';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.h1browse, data);

% If it errors, record fail
catch
    pf = fail;
end

% Set invalid unit path/name
data.unitpath = '/';
data.unitname = 'asd';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement (this should fail)
try
    callback(data.h1browse, data);
    pf = fail;
    
% If it errors
catch
	% The test passed
end

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    callback(data.h1browse, data);

% If it errors, record fail
catch
    pf = fail;
end

% Record completion time
time = sprintf('%0.1f sec', toc(t));

% Retrieve guidata
data = guidata(h);

% Verify that h1results exists and the file name matches the input data
if strcmp(pf, pass) && ~isempty(data.h1results) && ...
        strcmp(data.h1file.String, fullfile(varargin{2}))
    pf = pass;
else
    pf = fail;
end

% If version >= 1.1.0, execute SRS-F017 test
if version >= 010100
    
    % Load the SNC profiler data
    prm = ParseSNCprm(data.unitpath, data.unitname);

    % Adjust the data such that the X axis profile is uniform (no edges)
    prm.data(:, 5 + (1:prm.num(2))) = ones(size(prm.data,1), prm.num(2)) * 1e7;
    prm.data(1, 5 + (1:prm.num(2))) = zeros(1, prm.num(2));

    % Run AnalyzeProfilerFields with bad X axis data
    result = AnalyzeProfilerFields(prm);

    % Verify FWHM is zero
    if result.xfwhm ~= 0
        pf = fail;
    end

    % Adjust the data such that the X axis profile is uniform (no edges)
    prm.data(:, 5 + (2:prm.num(2)-1)) = ones(size(prm.data,1), prm.num(2)-2) ...
        * 1e8;
    prm.data(1, 5 + (1:prm.num(2))) = zeros(1, prm.num(2));

    % Run AnalyzeProfilerFields with bad X axis data
    result = AnalyzeProfilerFields(prm);

    % Verify FWHM is zero
    if result.xfwhm ~= 0
        pf = fail;
    end

    % Clear temporary variables
    clear prm result;
end

% If version >= 1.1.0, execute SRS-F018 test
if version >= 010100
    
    % If correlation data does not exist
    if ~isfield(data.h1results, 'corr') || ...
            max(max(max(data.h1results.corr))) == 0
        pf = fail;
    end
end

% Add result
results{size(results,1)+1,1} = '8';
results{size(results,1),2} = 'H1 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '9';
results{size(results,1),2} = 'Browse Callback Load Time';
results{size(results,1),3} = time;

%% TEST 10: MLC X Profile Identical
%
% DESCRIPTION: This unit test compares the SNC IC Profiler Y-axis data to
%   an expected value to validate that the data is extracted from the PRM
%   data and that corrections (array calibration, ignored detectors, etc)
%   are processed correctly.  Note, in versions prior to 1.1.0 the Y-axis
%   data is stored as H1X, where X refers to the MLC axis.
%
% RELEVANT REQUIREMENTS: F005, F007, F008
%
% INPUT DATA: Expected IC Profiler Y-axis data (varargin{3}.ydata)
%
% CONDITION A (+): Extracted Y-axis data exactly matches expected data
%   (Version 1.1.0 or later) or is within 0.1%
%
% CONDITION B (-): Extracted X-axis data does not match expected Y-axis 
%   data using the same tolerance

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ydata(1,:), varargin{3}.ydata(1,:)) && ...
                isequal(data.h1results.ydata(2,:), varargin{3}.ydata(2,:))
            pf = pass;
        
        % Otherwise the test fails
        else
            pf = fail;
        end
        
        % If the current xdata equals the reference, record failure
        if isequal(data.h1results.xdata(1,:), varargin{3}.ydata(1,:)) && ...
                isequal(data.h1results.xdata(2,:), varargin{3}.ydata(2,:))
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
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If current x data equals the reference to within 0.1%, record
        % failure
        if isequal(data.h1Y(1,:)/10, varargin{3}.ydata(1,:)) && ...
                max(abs(data.h1Y(2,:) - varargin{3}.ydata(2,:))) < 0.001
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
%
% DESCRIPTION: This unit test compares the SNC IC Profiler X-axis data to
%   an expected value to validate that the data is extracted from the PRM
%   data and that corrections (array calibration, ignored detectors, etc)
%   are processed correctly.  Note, in versions prior to 1.1.0 the X-axis
%   data is stored as H1Y, where Y refers to the MLC axis.
%
% RELEVANT REQUIREMENTS: F005, F007, F008
%
% INPUT DATA: Expected IC Profiler X-axis data (varargin{3}.xdata)
%
% CONDITION A (+): Extracted X-axis data exactly matches expected data
%   (Version 1.1.0 or later) or is within 0.1%
%
% CONDITION B (-): Extracted Y-axis data does not match expected Y-axis 
%   data using the same tolerance

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.xdata(1,:), varargin{3}.xdata(1,:)) && ...
                isequal(data.h1results.xdata(2,:), varargin{3}.xdata(2,:))
            pf = pass;
        
        % Otherwise the test fails
        else
            pf = fail;
        end
        
        % If the current xdata equals the reference, record failure
        if isequal(data.h1results.ydata(1,:), varargin{3}.xdata(1,:)) && ...
                isequal(data.h1results.ydata(2,:), varargin{3}.xdata(2,:))
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
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If current x data equals the reference to within 0.1%, record
        % failure
        if isequal(data.h1X(1,:)/10, varargin{3}.xdata(1,:)) && ...
                max(abs(data.h1X(2,:) - varargin{3}.xdata(2,:))) < 0.001
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

%% TEST 12: Positive Diagonal Profile Identical
%
% DESCRIPTION: This unit test compares the SNC IC Profiler positive 
%   diagonal data to an expected value to validate that the data is 
%   extracted from the PRM data and that corrections (array calibration, 
%   ignored detectors, etc) are processed correctly.  This test is only
%   applicable in Version 1.1.0 and later (in prior versions diagonals were
%   not extracted).
%
% RELEVANT REQUIREMENTS: F005, F007, F008
%
% INPUT DATA: Expected IC Profiler positive diagonal data 
%   (varargin{3}.pdiag)
%
% CONDITION A (+): Extracted positive diagonal data exactly matches 
%   expected data
%
% CONDITION B (-): Extracted negative diagonal data does not match
%   expected data

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.pdiag(1,:), varargin{3}.pdiag(1,:)) && ...
                isequal(data.h1results.pdiag(2,:), varargin{3}.pdiag(2,:))
            pf = pass;
        
        % Otherwise the test fails
        else
            pf = fail;
        end

        % If the negative diagonal equals the reference
        if isequal(data.h1results.ndiag(1,:), varargin{3}.pdiag(1,:)) && ...
                isequal(data.h1results.ndiag(2,:), varargin{3}.pdiag(2,:))
            pf = fail;
        end
        
    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.pdiag = data.h1results.pdiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0, profiles do not exist
else
    pf = unk;
end

% Add result with footnote
results{size(results,1)+1,1} = '12';
results{size(results,1),2} = 'Positive Diagonal Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;
footnotes{length(footnotes)+1} = ['<sup>3</sup>Prior to Version 1.1 ', ...
    'diagonal profiles were not available'];

%% TEST 13: Negative Diagonal Profile Identical
%
% DESCRIPTION: This unit test compares the SNC IC Profiler negative 
%   diagonal data to an expected value to validate that the data is 
%   extracted from the PRM data and that corrections (array calibration, 
%   ignored detectors, etc) are processed correctly.  This test is only
%   applicable in Version 1.1.0 and later (in prior versions diagonals were
%   not extracted).
%
% RELEVANT REQUIREMENTS: F005, F007, F008
%
% INPUT DATA: Expected IC Profiler negative diagonal data 
%   (varargin{3}.ndiag)
%
% CONDITION A (+): Extracted negative diagonal data exactly matches 
%   expected data
%
% CONDITION B (-): Extracted positive diagonal data does not match
%   expected data

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ndiag(1,:), varargin{3}.ndiag(1,:)) && ...
                isequal(data.h1results.ndiag(2,:), varargin{3}.ndiag(2,:))
            pf = pass;
        
        % Otherwise the test fails
        else
            pf = fail;
        end

        % If the positive diagonal equals the reference
        if isequal(data.h1results.pdiag(1,:), varargin{3}.ndiag(1,:)) && ...
                isequal(data.h1results.pdiag(2,:), varargin{3}.ndiag(2,:))
            pf = fail;
        end
        
    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ndiag = data.h1results.ndiag;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0, profiles do not exist
else
    pf = unk;
end

% Add result with footnote
results{size(results,1)+1,1} = '13';
results{size(results,1),2} = 'Negative Diagonal Profile within 0.1%<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 14: Timing Profile Identical
%
% DESCRIPTION: This unit test compares the SNC IC Profiler central detector
%   time-dependent response to an expected value. to validate that the data 
%   is extracted from the PRM data and that corrections (array calibration, 
%   ignored detectors, etc) are processed correctly.
%
% RELEVANT REQUIREMENTS: F006
%
% INPUT DATA: Expected IC Profiler timing data (varargin{3}.tdata)
%
% CONDITION A (+): Extracted timing data exactly matches expected data
%   (Version 1.1.0 or later) or is within 0.1%
%
% CONDITION B (-): Modified extracted timing data is not within 0.1%

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.tdata(1,:), varargin{3}.tdata(1,:)) && ...
                isequal(data.h1results.tdata(2,:), varargin{3}.tdata(2,:))
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If modified value equals the reference, the test fails
        if isequal(data.h1results.tdata(1,:), varargin{3}.tdata(1,:)) && ...
                isequal(data.h1results.tdata(2,:), varargin{3}.tdata(2,:) ...
                * 1.01)
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.tdata = data.h1results.tdata;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1%
        if max(abs(data.h1T(2,2:end)/max(data.h1T(2,:)) - ...
                varargin{3}.tdata(2,2:end)/max(varargin{3}.tdata(2,:)))) ...
                < 0.001
            pf = pass;
        
        % Otherwise, test fails
        else
            pf = fail;
        end

        % If modified value equals the reference, the test fails
        if max(abs(data.h1T(2,2:end)/max(data.h1T(2,:)) - ...
                (varargin{3}.tdata(2,2:end)/max(varargin{3}.tdata(2,:))) ...
                * 1.01)) ...
                < 0.001
            pf = fail;
        end
        
    % Otherwise, no reference data exists
    else
        pf = unk;
    end

end

% Add result
results{size(results,1)+1,1} = '14';
results{size(results,1),2} = 'Timing Profile within 0.1%';
results{size(results,1),3} = pf;

%% TEST 15: MLC X Gamma Identical
%
% DESCRIPTION: This unit test compares the Gamma profile computed for the
%   SNC IC Profiler Y-axis to an expected value, using a consistent set of
%   Gamma criteria (3%/1mm) defined in unit test 8/9.  As such, this test
%   verifies that the combination of reference extraction, measured
%   extraction, and Gamma computation all function correctly. Note, prior
%   to version 1.1.0 the Gamma profile is stored in h1X(3,:), where X
%   refers to the MLC axis.
%
% RELEVANT REQUIREMENTS: F022
%
% INPUT DATA: Expected Y-axis Gamma profile (varargin{3}.ygamma)
%
% CONDITION A (+): Computed Y-axis Gamma profile exactly matches expected
%   profile (Version 1.1.0 or later) or is within 0.1
%
% CONDITION B (-): Modified Y-axis Gamma profile is not within 0.1

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ygamma(1,:), varargin{3}.ygamma(1,:)) && ...
                isequal(data.h1results.ygamma(2,:), varargin{3}.ygamma(2,:))
            pf = pass;
        
        % Otherwise the test fails
        else
            pf = fail;
        end
        
        % If the modified value equals the reference, the test fails
        if isequal(data.h1results.ygamma(1,:), varargin{3}.ygamma(1,:)) && ...
                isequal(data.h1results.ygamma(2,:), varargin{3}.ygamma(2,:) ...
                * 1.1)
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ygamma = data.h1results.ygamma;

        % Assume pass
        pf = pass;

    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference to within 0.1
        if max(abs(data.h1X(3,:) - varargin{3}.ygamma(2,:)) .* ...
                (abs(varargin{3}.ydata(1,:)) < 15)) < 0.1
            pf = pass;
        
        % Otherwise the test fails
        else
            pf = fail;
        end
        
        % If the modified value equals the reference, the test fails
        if max(abs(data.h1X(3,:) - varargin{3}.ygamma(2,:) * 1.1) .* ...
                (abs(varargin{3}.ydata(1,:)) < 15)) < 0.1
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '15';
results{size(results,1),2} = 'MLC X Gamma within 0.1';
results{size(results,1),3} = pf;

%% TEST 16: MLC Y Gamma Identical
%
% DESCRIPTION: This unit test compares the Gamma profile computed for the
%   SNC IC Profiler X-axis to an expected value, using a consistent set of
%   Gamma criteria (3%/1mm) defined in unit test 8/9.  As such, this test
%   verifies that the combination of reference extraction, measured
%   extraction, and Gamma computation all function correctly. Note, prior
%   to version 1.1.0 the Gamma profile is stored in h1Y(3,:), where Y
%   refers to the MLC axis.
%
% RELEVANT REQUIREMENTS: F022
%
% INPUT DATA: Expected X-axis Gamma profile (varargin{3}.xgamma)
%
% CONDITION A (+): Computed X-axis Gamma profile exactly matches expected
%   profile (Version 1.1.0 or later) or is within 0.1
%
% CONDITION B (-): Modified X-axis Gamma profile is not within 0.1

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.xgamma(1,:), varargin{3}.xgamma(1,:)) && ...
                isequal(data.h1results.xgamma(2,:), varargin{3}.xgamma(2,:))
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If modified value equals the reference, the test fails
        if isequal(data.h1results.xgamma(1,:), varargin{3}.xgamma(1,:)) && ...
                isequal(data.h1results.xgamma(2,:), varargin{3}.xgamma(2,:) ...
                * 1.1)
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.xgamma = data.h1results.xgamma;

        % Assume pass
        pf = pass;

    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % Remove interpolated values
        h1Y = [data.h1Y(3,1:31) data.h1Y(3,33) ...
            data.h1Y(3,35:end)];
        
        % If current value equals the reference to within 0.1
        if max(abs(h1Y - varargin{3}.xgamma(2,:)) .* ...
                (abs(varargin{3}.xgamma(1,:)) < 15)) < 0.1
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If modified value equals the reference, the test fails
        if max(abs(h1Y - varargin{3}.xgamma(2,:) * 1.1) .* ...
                (abs(varargin{3}.xgamma(1,:)) < 15)) < 0.1
            pf = fail;
        end

    % Otherwise, no reference data exists
    else
        pf = unk;
    end
end

% Add result
results{size(results,1)+1,1} = '16';
results{size(results,1),2} = 'MLC Y Gamma within 0.1<sup>2</sup>';
results{size(results,1),3} = pf;

%% TEST 17: Positive Diagonal Gamma Identical
%
% DESCRIPTION: This unit test compares the Gamma profile computed for the
%   SNC IC Profiler positive diagonal to an expected value, using a 
%   consistent set of Gamma criteria (3%/1mm) defined in unit test 8/9.  
%   As such, this test verifies that the combination of reference 
%   extraction, measured extraction, and Gamma computation all function 
%   correctly. 
%
% RELEVANT REQUIREMENTS: F022
%
% INPUT DATA: Expected positive diagonal axis Gamma profile 
%   (varargin{3}.pgamma)
%
% CONDITION A (+): Computed positive diagonal axis Gamma profile exactly 
%   matches expected profile
%
% CONDITION B (-): Modified positive diagonal axis Gamma profile does not
%   match expected profile

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.pgamma(1,:), varargin{3}.pgamma(1,:)) && ...
                isequal(data.h1results.pgamma(2,:), varargin{3}.pgamma(2,:))
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If modified value equals the reference, the test fails
        if isequal(data.h1results.pgamma(1,:), varargin{3}.pgamma(1,:)) && ...
                isequal(data.h1results.pgamma(2,:), varargin{3}.pgamma(2,:) ...
                * 1.1)
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.pgamma = data.h1results.pgamma;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result with footnote
results{size(results,1)+1,1} = '17';
results{size(results,1),2} = 'Positive Diagonal Gamma within 0.1<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 18: Negative Diagonal Gamma Identical
%
% DESCRIPTION: This unit test compares the Gamma profile computed for the
%   SNC IC Profiler negative diagonal to an expected value, using a 
%   consistent set of Gamma criteria (3%/1mm) defined in unit test 8/9.  
%   As such, this test verifies that the combination of reference 
%   extraction, measured extraction, and Gamma computation all function 
%   correctly. 
%
% RELEVANT REQUIREMENTS: F022
%
% INPUT DATA: Expected negative diagonal axis Gamma profile 
%   (varargin{3}.ngamma)
%
% CONDITION A (+): Computed negative diagonal axis Gamma profile exactly 
%   matches expected profile
%
% CONDITION B (-): Modified negative diagonal axis Gamma profile does not
%   match expected profile

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(data.h1results.ngamma(1,:), varargin{3}.ngamma(1,:)) && ...
                isequal(data.h1results.ngamma(2,:), varargin{3}.ngamma(2,:))
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end
        
        % If modified value equals the reference, the test fails
        if isequal(data.h1results.ngamma(1,:), varargin{3}.ngamma(1,:)) && ...
                isequal(data.h1results.ngamma(2,:), varargin{3}.ngamma(2,:) ...
                * 1.1)
            pf = fail;
        end

    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.ngamma = data.h1results.ngamma;

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % Diagonal profiles do not exist
    pf = unk;

end

% Add result with footnote
results{size(results,1)+1,1} = '18';
results{size(results,1),2} = 'Negative Diagonal Gamma within 0.1<sup>3</sup>';
results{size(results,1),3} = pf;

%% TEST 19: Statistics Identical
%
% DESCRIPTION: This unit test compares the statistics displayed on the user
%   interface to a set of expected values.  The statistics compared are the
%   time difference and X/Y axis flatness, symmetry, FWHM difference, and 
%   max gamma.  In this manner both the presence of and accuracy of the 
%   statistics are verified.
%
% RELEVANT REQUIREMENTS: U007, U008, U010, U012, F009, F010, F012, F013,
%   F016, F019, F020, F026
%
% INPUT DATA: Expected beam on time difference (varargin{3}.statbot), MLC X
%   axis FWHM difference (varargin{3}.statxfwhm), MLC X axis measured
%   flatness (varargin{3}.xflat), MLC X axis measured symmetry 
%   (varargin{3}.xsym), MLC X axis max gamma (varargin{3}.xmax), MLC Y axis
%   FWHM difference (varargin{3}.statyfwhm), MLC Y axis measured flatness 
%   (varargin{3}.yflat), MLC Y axis measured symmetry (varargin{3}.ysym), 
%   MLC Y axis max gamma (varargin{3}.ymax)
%
% CONDITION A (+): The expected beam on time difference equals the expected
%   value exactly (Version 1.1.0 and later) or within 0.1 sec
%
% CONDITION B (-): The expected beam on time difference does not equal 0
%
% CONDITION C (+): The MLC X axis FWHM difference equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1 mm
%
% CONDITION D (-): The MLC X axis FWHM difference does not equal 0
%
% CONDITION E (+): The MLC X axis flatness equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1%
%
% CONDITION F (-): The MLC X axis flatness does not equal 0
%
% CONDITION G (+): The MLC X axis symmetry equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1%
%
% CONDITION H (-): The MLC X axis symmetry does not equal 0
%
% CONDITION I (+): The MLC X max gamma equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1
%
% CONDITION J (-): The MLC X max gamma does not equal 0
%
% CONDITION K (+): The MLC Y axis FWHM difference equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1 mm
%
% CONDITION L (-): The MLC Y axis FWHM difference does not equal 0
%
% CONDITION M (+): The MLC Y axis flatness equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1%
%
% CONDITION N (-): The MLC Y axis flatness does not equal 0
%
% CONDITION O (+): The MLC Y axis symmetry equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1%
%
% CONDITION P (-): The MLC Y axis symmetry does not equal 0
%
% CONDITION Q (+): The MLC Y max gamma equals the expected value
%   exactly (Version 1.1.0 and later) or within 0.1
%
% CONDITION R (-): The MLC Y max gamma does not equal 0

% Retrieve guidata
data = guidata(h);

% If version >= 1.1.0
if version >= 010100

    % If reference data exists
    if nargin == 3

        % If current value equals the reference
        if isequal(textscan(data.h1table.Data{2,2}, '%f'), ...
                varargin{3}.statbot) && ...
                isequal(textscan(data.h1table.Data{3,2}, '%f'), ...
                varargin{3}.statxfwhm) && ...
                isequal(textscan(data.h1table.Data{4,2}, '%f'), ...
                varargin{3}.statxflat) && ...
                isequal(textscan(data.h1table.Data{5,2}, '%f'), ...
                varargin{3}.statxsym) && ...
                isequal(textscan(data.h1table.Data{6,2}, '%f'), ...
                varargin{3}.statyfwhm) && ...
                isequal(textscan(data.h1table.Data{7,2}, '%f'), ...
                varargin{3}.statyflat) && ...
                isequal(textscan(data.h1table.Data{8,2}, '%f'), ...
                varargin{3}.statysym) && ...
                isequal(textscan(data.h1table.Data{9,2}, '%f'), ...
                varargin{3}.statxmax) && ...
                isequal(textscan(data.h1table.Data{10,2}, '%f'), ...
                varargin{3}.statymax)
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end

        % If current value equals 0, the test fails
        z{1} = 0;
        if isequal(textscan(data.h1table.Data{2,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{3,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{4,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{5,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{6,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{7,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{8,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{9,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{10,2}, '%f'), z)
            pf = fail;
        end
        clear z;
        
    % Otherwise, no reference data exists
    else

        % Set current value as reference
        reference.statbot = textscan(data.h1table.Data{2,2}, '%f');
        reference.statxfwhm = textscan(data.h1table.Data{3,2}, '%f');
        reference.statxflat = textscan(data.h1table.Data{4,2}, '%f');
        reference.statxsym = textscan(data.h1table.Data{5,2}, '%f');
        reference.statyfwhm = textscan(data.h1table.Data{6,2}, '%f');
        reference.statyflat = textscan(data.h1table.Data{7,2}, '%f');
        reference.statysym = textscan(data.h1table.Data{8,2}, '%f');
        reference.statxmax = textscan(data.h1table.Data{9,2}, '%f');
        reference.statymax = textscan(data.h1table.Data{10,2}, '%f');

        % Assume pass
        pf = pass;
    end

% If version < 1.1.0    
else

    % If reference data exists
    if nargin == 3

        % If current value equals the reference (within 0.1 sec/0.1 mm/0.1%)
        if abs(cell2mat(textscan(data.h1table.Data{4,2}, '%f')) - ...
                varargin{3}.statbot{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{8,2}, '%f')) - ...
                varargin{3}.statxfwhm{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{9,2}, '%f')) - ...
                varargin{3}.statxflat{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{10,2}, '%f')) - ...
                varargin{3}.statxsym{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{14,2}, '%f')) - ...
                varargin{3}.statyfwhm{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{15,2}, '%f')) - ...
                varargin{3}.statyflat{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{16,2}, '%f')) - ...
                varargin{3}.statysym{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{11,2}, '%f')) - ...
                varargin{3}.statxmax{1}) < 0.1 && ...
                abs(cell2mat(textscan(data.h1table.Data{17,2}, '%f')) - ...
                varargin{3}.statymax{1}) < 0.1
            pf = pass;
        
        % Otherwise, the test fails
        else
            pf = fail;
        end

        % If current value equals 0, the test fails
        z{1} = 0;
        if isequal(textscan(data.h1table.Data{4,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{8,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{9,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{10,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{14,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{15,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{16,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{11,2}, '%f'), z) || ...
                isequal(textscan(data.h1table.Data{17,2}, '%f'), z)
            pf = fail;
        end
        clear z;
        
    % Otherwise, no reference data exists
    else
        pf = unk;
    end

end

% Add result with footnote
results{size(results,1)+1,1} = '19';
results{size(results,1),2} = 'Statistics within 0.1 sec/mm/%<sup>4</sup>';
results{size(results,1),3} = pf;
footnotes{length(footnotes)+1} = ['<sup>4</sup>[#11](../issues/11) In ', ...
    'Version 1.1.0 a bug was identified where flatness was computed', ...
    ' incorrectly'];

%% TEST 20: H1 Figures Functional
%
% DESCRIPTION: This unit test tests the different options available in the
%   Head 1 plot display dropdown menu by executing the dropdown callback
%   for all options.  In the positive condition of each case the plot is
%   attempted with result data present, while in the negative condition the
%   plot is attempted with no data present.  Note, this test does also
%   require the user to visually verify that the plot displays correctly
%   (and with the correct colors, in the case of SRS-F024).
%
% RELEVANT REQUIREMENTS: U009, U011, F014, F015, F023, F024, F025
%
% INPUT DATA: No input data required
%
% CONDITION A (+): The time-dependent central channel response is displayed
%   when h1results data is present.
%
% CONDITION B (-): The time-dependent response is not displayed when
%   h1results data is not present, but exits gracefully.
%
% CONDITION C (+): The MLC X Gamma index, measured, and reference profiles
%   are displayed when h1results data is present.
%
% CONDITION D (-): The MLC X Gamma index, measured, and reference profiles
%   are not displayed when h1results data is not present.
%
% CONDITION E (+): The MLC Y Gamma index, measured, and reference profiles
%   are displayed when h1results data is present.
%
% CONDITION F (-): The MLC Y Gamma index, measured, and reference profiles
%   are not displayed when h1results data is not present.
%
% CONDITION G (+): The positive diagonal Gamma index, measured, and 
%   reference profiles are displayed when h1results data is present.
%
% CONDITION H (-): The positive diagonal Gamma index, measured, and 
%   reference profiles are not displayed when h1results data is not 
%   present.
%
% CONDITION I (+): The negative diagonal Gamma index, measured, and 
%   reference profiles are displayed when h1results data is present.
%
% CONDITION J (-): The negative diagonal Gamma index, measured, and 
%   reference profiles are not displayed when h1results data is not 
%   present.

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H1 display dropdown
callback = get(data.h1display, 'Callback');

% Execute callbacks in try/catch statement
try
    
    % Start with pass
    pf = pass;
    
    % Loop through each display option
    for i = 1:length(data.h1display.String)
        
        % Set value
        data.h1display.Value = i;
        guidata(h, data);
        
        % Execute callback
        callback(data.h1display, data);
        
        % Execute callback without results data
        callback(data.h1display, rmfield(data, 'h1results'));
    end
    
% If callback fails, record failure    
catch
    pf = fail; 
end

% Add result with footnote
results{size(results,1)+1,1} = '20';
results{size(results,1),2} = 'H1 Figure Display Functional';
results{size(results,1),3} = pf;

%% TEST 21/22: H2/H3 Browse Loads Data Successfully
%
% DESCRIPTION: This unit test repeats test 8 on the callbacks for Heads 2
%   and 3 to verify that those GUI features are also functional.
%
% RELEVANT REQUIREMENTS: U013, F011
%
% INPUT DATA: PRM file to be loaded (varargin{2})
%
% CONDITION A (+): The callback for the H2 browse button can be executed
%   without error when a valid filename is provided
%
% CONDITION B (-): The H2 callback will throw an error if an invalid 
%   filename is provided
%
% CONDITION C (+): The H2 callback will return without error when no 
%   filename is provided
%
% CONDITION D (+): Upon receiving a valid filename, the PRM data will be
%   automatically processed, storing a structure to data.h2results
%
% CONDITION E (+): Upon receiving a valid filename, the H2 filename will be
%   displayed on the user interface
%
% CONDITION F (+): The callback for the H3 browse button can be executed
%   without error when a valid filename is provided
%
% CONDITION G (-): The H3 callback will throw an error if an invalid 
%   filename is provided
%
% CONDITION H (+): The H3 callback will return without error when no 
%   filename is provided
%
% CONDITION I (+): Upon receiving a valid filename, the PRM data will be
%   automatically processed, storing a structure to data.h3results
%
% CONDITION F (+): Upon receiving a valid filename, the H3 filename will be
%   displayed on the user interface

% Retrieve guidata
data = guidata(h);

% Retrieve callback to H2 browse button
callback = get(data.h2browse, 'Callback');

% Set empty unit path/name
data.unitpath = '';
data.unitname = '';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.h2browse, data);

% If it errors, record fail
catch
    pf = fail;
end

% Set invalid unit path/name
data.unitpath = '/';
data.unitname = 'asd';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement (this should fail)
try
    callback(data.h2browse, data);
    pf = fail;
    
% If it errors
catch
	% The test passed
end

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    callback(data.h2browse, data);

% If it errors, record fail
catch
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Verify that h1results exists and the file name matches the input data
if strcmp(pf, pass) && ~isempty(data.h2results) && ...
        strcmp(data.h2file.String, fullfile(varargin{2}))
    pf = pass;
else
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '21';
results{size(results,1),2} = 'H2 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

% Retrieve callback to H3 browse button
callback = get(data.h3browse, 'Callback');

% Set empty unit path/name
data.unitpath = '';
data.unitname = '';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    pf = pass;
    callback(data.h3browse, data);

% If it errors, record fail
catch
    pf = fail;
end

% Set invalid unit path/name
data.unitpath = '/';
data.unitname = 'asd';

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement (this should fail)
try
    callback(data.h3browse, data);
    pf = fail;
    
% If it errors
catch
	% The test passed
end

% Set unit path/name
[path, name, ext] = fileparts(varargin{2});
data.unitpath = path;
data.unitname = [name, ext];

% Store guidata
guidata(h, data);

% Execute callback in try/catch statement
try
    t = tic;
    callback(data.h3browse, data);

% If it errors, record fail
catch
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Verify that h1results exists and the file name matches the input data
if strcmp(pf, pass) && ~isempty(data.h3results) && ...
        strcmp(data.h3file.String, fullfile(varargin{2}))
    pf = pass;
else
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '22';
results{size(results,1),2} = 'H3 Browse Loads Data Successfully';
results{size(results,1),3} = pf;

%% TEST 23/24: H2/H3 Figures Functional
%
% DESCRIPTION: This unit test repeats test 20 for the plot display
%   selection and figure user interface features for Heads 2 and 3.
%
% RELEVANT REQUIREMENTS: U009, U011, U013, F014, F015, F023, F024, F025
%
% INPUT DATA: No input data required
%
% CONDITION A (+): The time-dependent central channel response is displayed
%   when h2results data is present.
%
% CONDITION B (-): The time-dependent response is not displayed when
%   h2results data is not present, but exits gracefully.
%
% CONDITION C (+): The MLC X Gamma index, measured, and reference profiles
%   are displayed when h2results data is present.
%
% CONDITION D (-): The MLC X Gamma index, measured, and reference profiles
%   are not displayed when h2results data is not present.
%
% CONDITION E (+): The MLC Y Gamma index, measured, and reference profiles
%   are displayed when h2results data is present.
%
% CONDITION F (-): The MLC Y Gamma index, measured, and reference profiles
%   are not displayed when h2results data is not present.
%
% CONDITION G (+): The positive diagonal Gamma index, measured, and 
%   reference profiles are displayed when h2results data is present.
%
% CONDITION H (-): The positive diagonal Gamma index, measured, and 
%   reference profiles are not displayed when h2results data is not 
%   present.
%
% CONDITION I (+): The negative diagonal Gamma index, measured, and 
%   reference profiles are displayed when h2results data is present.
%
% CONDITION J (-): The negative diagonal Gamma index, measured, and 
%   reference profiles are not displayed when h2results data is not 
%   present.
%
% CONDITION K (+): The time-dependent central channel response is displayed
%   when h3results data is present.
%
% CONDITION L (-): The time-dependent response is not displayed when
%   h3results data is not present, but exits gracefully.
%
% CONDITION M (+): The MLC X Gamma index, measured, and reference profiles
%   are displayed when h3results data is present.
%
% CONDITION N (-): The MLC X Gamma index, measured, and reference profiles
%   are not displayed when h3results data is not present.
%
% CONDITION O (+): The MLC Y Gamma index, measured, and reference profiles
%   are displayed when h3results data is present.
%
% CONDITION P (-): The MLC Y Gamma index, measured, and reference profiles
%   are not displayed when h3results data is not present.
%
% CONDITION Q (+): The positive diagonal Gamma index, measured, and 
%   reference profiles are displayed when h3results data is present.
%
% CONDITION R (-): The positive diagonal Gamma index, measured, and 
%   reference profiles are not displayed when h3results data is not 
%   present.
%
% CONDITION S (+): The negative diagonal Gamma index, measured, and 
%   reference profiles are displayed when h3results data is present.
%
% CONDITION T (-): The negative diagonal Gamma index, measured, and 
%   reference profiles are not displayed when h3results data is not 
%   present.

% Retrieve guidata
data = guidata(h);
    
% Retrieve callback to H2 display dropdown
callback = get(data.h2display, 'Callback');

% Execute callbacks in try/catch statement
try
    % Start with pass
    pf = pass;
    
    % Loop through each display option
    for i = 1:length(data.h2display.String)
        
        % Set value
        data.h2display.Value = i;
        guidata(h, data);
        
        % Execute callback
        callback(data.h2display, data);
        
        % Execute callback without results data
        callback(data.h2display, rmfield(data, 'h2results'));
    end
catch
    
    % If callback fails, record failure
    pf = fail; 
end

% Add result
results{size(results,1)+1,1} = '23';
results{size(results,1),2} = 'H2 Figure Display Functional';
results{size(results,1),3} = pf;

% Retrieve callback to H3 display dropdown
callback = get(data.h3display, 'Callback');

% Execute callbacks in try/catch statement
try
    % Start with pass
    pf = pass;
    
    % Loop through each display option
    for i = 1:length(data.h3display.String)
        
        % Set value
        data.h3display.Value = i;
        guidata(h, data);
        
        % Execute callback
        callback(data.h3display, data);
        
        % Execute callback without results data
        callback(data.h3display, rmfield(data, 'h3results'));
    end
catch
    
    % If callback fails, record failure
    pf = fail; 
end

% Add result
results{size(results,1)+1,1} = '24';
results{size(results,1),2} = 'H3 Figure Display Functional';
results{size(results,1),3} = pf;

%% TEST 25/26: Print Report Functional
%
% DESCRIPTION: This unit test evaluates the print report feature by
%   executing the print report button callback.  Note, the contents and 
%   clarity of the report are verified manually by the user. This unit test
%   is only applicable to Version 1.1.0 and later (when reports became 
%   available).
%
% RELEVANT REQUIREMENTS: U014, F027, F028, F029, F030, F031, F032, F033,
%   F034
%
% INPUT DATA: No input data required
%
% CONDITION A (+): The print report button is enabled
%
% CONDITION B (+/-): A report is generated without error and with the user
%   name (or "Unit test" if whoami does not exist), current date and time,
%   SNC version/collector model/serial, MLC X/Y Gamma profiles, and
%   statistics.

% If version >= 1.1.0
if version >= 010100
    
    % Retrieve guidata
    data = guidata(h);

    % Retrieve callback to print button
    callback = get(data.print_button, 'Callback');

    % Execute callback in try/catch statement
    try
        % Start with pass
        pf = pass;
    
        % Start timer
        t = tic;
        
        % Execute callback
        callback(data.print_button, data);
    catch
        
        % If callback fails, record failure
        pf = fail; 
    end

    % Record completion time
    time = sprintf('%0.1f sec', toc(t)); 
    
    % If the print report button is disabled, the test fails
    if ~strcmp(get(data.print_button, 'enable'), 'on')
        pf = fail;
    end
    
    

% If version < 1.1.0
else
    
    % This feature does not exist
    pf = unk;
    time = unk;
end

% Add result
results{size(results,1)+1,1} = '25';
results{size(results,1),2} = 'Print Report Functional';
results{size(results,1),3} = pf;

% Add result
results{size(results,1)+1,1} = '26';
results{size(results,1),2} = 'Print Report Time';
results{size(results,1),3} = time;

%% TEST 27/28/29: Clear All Buttons Functional
%
% DESCRIPTION: This unit test evaluates the Clear All Data button on the
%   user interface for each head and verifies that all data is successfully
%   cleared from the user interface and internally.
%
% RELEVANT REQUIREMENTS: U015, F035, F036
%
% INPUT DATA: No input data required
%
% CONDITION A (-): Prior to executing the H1 clear button callback, the
%   file location, plot dropdown menu, plot, statistics, and internal 
%   variables (h1results, h1refresults) contain data. 
%
% CONDITION B (+): After executing the H1 clear button, the file location, 
%   plot dropdown menu, plot, statistics, and internal variables 
%   (h1results, h1refresults) become empty.
%
% CONDITION C (-): Prior to executing the H2 clear button callback, the
%   file location, plot dropdown menu, plot, statistics, and internal 
%   variables (h2results, h2refresults) contain data. 
%
% CONDITION D (+): After executing the H2 clear button, the file location, 
%   plot dropdown menu, plot, statistics, and internal variables 
%   (h2results, h2refresults) become empty.
%
% CONDITION E (-): Prior to executing the H3 clear button callback, the
%   file location, plot dropdown menu, plot, statistics, and internal 
%   variables (h3results, h3refresults) contain data. 
%
% CONDITION F (+): After executing the H3 clear button, the file location, 
%   plot dropdown menu, plot, statistics, and internal variables 
%   (h3results, h3refresults) become empty.

% Retrieve guidata
data = guidata(h);

% Retrieve callback to H1 clear button
callback = get(data.h1clear, 'Callback');

% Start with pass
pf = pass;

% Verify file location, plot dropdown menu, plot, statistics, and internal 
% variables exist
if isempty(data.h1file.String) || data.h1display.Value == 1
    pf = fail;
end

% If version >= 1.1.0
if version >= 010100 
    if isempty(data.h1results) || isempty(data.h1refresults) || ...
            isequal(data.h1table, cell(10, 2))
        pf = fail;
    end
    
% Otherwise, if version < 1.1.0    
else
    if isempty(data.h1data) || isempty(data.h1X)  || isempty(data.h1Y) || ...
             isempty(data.h1T) || isequal(data.h1table, cell(4, 2))
        pf = fail;
    end
end

% Execute callback in try/catch statement
try
    
    % Execute callback
    callback(data.h1clear, h);
catch
    
    % Callback failed, so record error
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Verify file location, plot dropdown menu, plot, statistics, and internal 
% variables are now cleared
if ~isempty(data.h1file.String) || ~data.h1display.Value == 1
    pf = fail;
end

% If version >= 1.1.0
if version >= 010100 
    if ~isempty(data.h1results) || ~isempty(data.h1refresults) || ...
            ~isequal(data.h1table, cell(10, 2))
        pf = fail;
    end
    
% Otherwise, if version < 1.1.0    
else
    if ~isempty(data.h1data) || ~isempty(data.h1X)  || ~isempty(data.h1Y) ...
             || ~isempty(data.h1T) || ~isequal(data.h1table, cell(4, 2))
        pf = fail;
    end
end

% Add result
results{size(results,1)+1,1} = '27';
results{size(results,1),2} = 'H1 Clear Button Functional';
results{size(results,1),3} = pf;

% Retrieve callback to H2 clear button
callback = get(data.h2clear, 'Callback');

% Start with pass
pf = pass;

% Verify file location, plot dropdown menu, plot, statistics, and internal 
% variables exist
if isempty(data.h2file.String) || isempty(data.h2results) || ...
        isempty(data.h2refresults) || data.h2display.Value == 1 || ...
        isequal(data.h2table, cell(10, 4))
    pf = fail;
end

% Execute callback in try/catch statement
try
    
    % Execute callback
    callback(data.h2clear, h);
catch
    
    % Callback failed, so record error
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Verify file location, plot dropdown menu, plot, statistics, and internal 
% variables are now cleared
if ~isempty(data.h2file.String) || ~isempty(data.h2results) || ...
        ~isempty(data.h2refresults) || ~data.h2display.Value == 1 || ...
        ~isequal(data.h2table, cell(10, 4))
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '28';
results{size(results,1),2} = 'H2 Clear Button Functional';
results{size(results,1),3} = pf;

% Retrieve callback to H3 clear button
callback = get(data.h3clear, 'Callback');

% Start with pass
pf = pass;

% Verify file location, plot dropdown menu, plot, statistics, and internal 
% variables exist
if isempty(data.h3file.String) || isempty(data.h3results) || ...
        isempty(data.h3refresults) || data.h3display.Value == 1 || ...
        isequal(data.h3table, cell(10, 4))
    pf = fail;
end

% Execute callback in try/catch statement
try
    
    % Execute callback
    callback(data.h3clear, h);
catch
    
    % Callback failed, so record error
    pf = fail;
end

% Retrieve guidata
data = guidata(h);

% Verify file location, plot dropdown menu, plot, statistics, and internal 
% variables are now cleared
if ~isempty(data.h3file.String) || ~isempty(data.h3results) || ...
        ~isempty(data.h3refresults) || ~data.h3display.Value == 1 || ...
        ~isequal(data.h3table, cell(10, 4))
    pf = fail;
end

% Add result
results{size(results,1)+1,1} = '29';
results{size(results,1),2} = 'H3 Clear Button Functional';
results{size(results,1),3} = pf;

%% TEST 30: Documentation Exists
%
% DESCRIPTION: This unit test checks that a README file is present.  The
% contents of the README are manually verified by the user.
%
% RELEVANT REQUIREMENTS: D001, D002, D003, D004
%
% INPUT DATA: No input data required
%
% CONDITION A (+): A file named README.md exists in the file directory.

% Look for README.md
fid = fopen('README.md', 'r');

% If file handle was valid, record pass
if fid >= 3
    pf = pass;
else
    pf = fail;
end

% Close file handle
fclose(fid);

% Add result
results{size(results,1)+1,1} = '30';
results{size(results,1),2} = 'Documentation Exists';
results{size(results,1),3} = pf;

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
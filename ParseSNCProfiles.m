function handles = ParseSNCProfiles(handles, head)
% ParseSNCProfiles is called by FieldUniformity to extract the MLC X, Y,
% and timing profiles from the PRM file data and compare them to reference
% profiles using the Gamma function.  Note, ParseSNCProfiles uses measured
% data loaded using LoadSNCprm.m, assuming the IC Profiler was positioned
% vertically at 105 cm SAD and Gantry 90, and compares to reference
% profiles loaded using LoadReferenceProfiles.m.  Gamma is calculated using
% CalcGamma.m.
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

if isfield(handles, [head, 'data'])
    %% Parse MLC Y values
    % Initialize data array
    handles.([head,'Y']) = zeros(3, handles.([head,'num'])(2));
    
    % Set MLC Y locations to IC Profiler X detector locations. Note that
    % the X detectors have two less detectors
    handles.([head,'Y'])(1,1:handles.([head,'num'])(2)) = ...
        ([1:(handles.([head,'num'])(2)-1)/2, ...
        (handles.([head,'num'])(2)+3)/2, ...
        (handles.([head,'num'])(2)+7)/2:handles.([head,'num'])(2)+2] - ...
        (handles.([head,'num'])(2)+3)/2) * -handles.([head,'width']);
    
    % Set MLC Y data to corrected IC Profiler X detector data, using
    % leakage and correction factors
    handles.([head,'Y'])(2,1:handles.([head,'num'])(2)) = ...
        (handles.([head,'data'])(size(handles.([head,'data']),1), ...
        5 + (1:handles.([head,'num'])(2))) - ...
        handles.([head,'data'])(size(handles.([head,'data']),1), 3) * ...
        handles.([head,'bkgd'])(1:handles.([head,'num'])(2))) .* ...
        handles.([head,'cal'])(1:handles.([head,'num'])(2));
    
    % Prepare CalcGamma inputs (which uses start/width/data format)
    target.start = handles.([head,'Y'])(1,1);
    target.width = handles.([head,'width']);
    target.data = squeeze(handles.([head,'Y'])(2,:));
    
    reference.start = handles.refY(1,1);
    reference.width = handles.refY(1,2) - handles.refY(1,1);
    reference.data = squeeze(handles.refY(2,:));
    
    % Calculate 1-D gamma
    handles.([head,'Y'])(3,1:handles.([head,'num'])(2)) = ...
        CalcGamma(reference);
    
    % Clear temporary variables
    clear target reference;
end
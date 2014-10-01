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

% Run in try-catch to log error via Event.m
try
    
% If data exists to parse
if isfield(handles, [head, 'data'])
    % Log start
    Event('Parsing SNC PRM file contents');
    tic;

    %% Parse MLC Y values
    % Initialize data array
    handles.([head,'Y']) = zeros(3, handles.([head,'num'])(2));
    
    % Set MLC Y locations to IC Profiler X detector locations. Note that
    % the X detectors have two less detectors
    handles.([head,'Y'])(1,1:handles.([head,'num'])(2)) = ...
        ([1:(handles.([head,'num'])(2)-1)/2, ...
        (handles.([head,'num'])(2)+3)/2, ...
        (handles.([head,'num'])(2)+7)/2:handles.([head,'num'])(2)+2] - ...
        (handles.([head,'num'])(2)+3)/2) * -handles.([head,'width']) * 10;
    
    % Set MLC Y data to corrected IC Profiler X detector data, using
    % leakage and correction factors
    handles.([head,'Y'])(2,1:handles.([head,'num'])(2)) = ...
        (handles.([head,'data'])(size(handles.([head,'data']),1), ...
        5 + (1:handles.([head,'num'])(2))) - ...
        handles.([head,'data'])(size(handles.([head,'data']),1), 3) * ...
        handles.([head,'bkgd'])(1:handles.([head,'num'])(2))) .* ...
        handles.([head,'cal'])(1:handles.([head,'num'])(2));
    
    % Log event
    Event('MLC Y profile extracted');
    
    % Interpolate ignored channels
    for i = 2:size(handles.([head,'Y']),2) - 1
        % If the ignore flag is set
        if handles.([head,'ignore'])(i) == 1
            % Interpolate linearly from neighboring values
            handles.([head,'Y'])(2,i) = (handles.([head,'Y'])(2,i-1) + ...
                handles.([head,'Y'])(2,i+1)) / 2;
            
            % Log event
            Event(sprintf(['Detector %i ignored, interpolated from ', ...
                'neighboring values'], i));
        end
    end
    
    % Add missing channels (to make spacing uniform)
    for i = 2:size(handles.([head,'Y']),2) - 1
        % If the spacing differs
        if (handles.([head,'Y'])(1,i+1) - handles.([head,'Y'])(1,i)) < ...
                (handles.([head,'Y'])(1,i) - handles.([head,'Y'])(1,i-1))
            
            % Interpolate linearly from neighboring values
            handles.([head,'Y']) = cat(2, handles.([head,'Y'])(:,1:i), ...
                (handles.([head,'Y'])(:,i) + handles.([head,'Y'])(:,i+1))/2, ...
                handles.([head,'Y'])(:,i+1:size(handles.([head,'Y']),2)));
            
            % Log event
            Event(sprintf(['Uniform spacing interpolated between ', ...
                'detectors %i and %i'], i, i+1));
        end
    end
    
    % Determine location and value of maximum in reference data
    [C, I] = max(handles.refY(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.refY(2,j) == C/2
            l = handles.refY(2,j);
            break;
        elseif handles.refY(2,j) < C/2 && handles.refY(2,j+1) > C/2
            l = interp1(handles.refY(2,j:j+1), ...
                handles.refY(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.refY,2)-1
        if handles.refY(2,j) == C/2
            r = handles.refY(2,j);
            break;
        elseif handles.refY(2,j) > C/2 && handles.refY(2,j+1) < C/2
            r = interp1(handles.refY(2,j:j+1), ...
                handles.refY(1,j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute reference center
    refCenter = (r + l) / 2;
    Event(sprintf('Reference MLC Y profile center computed at %0.3f mm', ...
        (r + l) / 2));
    
    % Determine location and value of maximum in measured data
    [C, I] = max(handles.([head,'Y'])(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.([head,'Y'])(2,j) == C/2
            l = handles.([head,'Y'])(2,j);
            break;
        elseif handles.([head,'Y'])(2,j) < C/2 && ...
                handles.([head,'Y'])(2,j+1) > C/2
            l = interp1(handles.([head,'Y'])(2,j:j+1), ...
                handles.([head,'Y'])(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.([head,'Y']),2)-1
        if handles.([head,'Y'])(2,j) == C/2
            r = handles.([head,'Y'])(2,j);
            break;
        elseif handles.([head,'Y'])(2,j) > C/2 && ...
                handles.([head,'Y'])(2,j+1) < C/2
            r = interp1(handles.([head,'Y'])(2,j:j+1), ...
                handles.([head,'Y'])(1,j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Offset measured data to center on reference
    handles.([head,'Y'])(1,:) = handles.([head,'Y'])(1,:) ...
        - (r + l) / 2 + refCenter;
    Event(sprintf('Measured MLC Y profile center computed at %0.3f mm', ...
        (r + l) / 2));
    Event(sprintf('Measured MLC Y profile centered on reference'));
    
    % Normalize measured data
    handles.([head,'Y'])(2,:) = handles.([head,'Y'])(2,:) / ...
        max(handles.([head,'Y'])(2,:));
    Event('Measured MLC Y profile normalized to 1');
    
    % Prepare CalcGamma inputs (which uses start/width/data format)
    target.start = handles.([head,'Y'])(1,1);
    target.width = -handles.([head,'width']) * 10;
    target.data = squeeze(handles.([head,'Y'])(2,:));
    
    reference.start = handles.refY(1,1);
    reference.width = handles.refY(1,2) - handles.refY(1,1);
    reference.data = squeeze(handles.refY(2,:));
    
    % Calculate 1-D GLOBAL gamma
    handles.([head,'Y'])(3,1:size(handles.([head,'Y']),2)) = ...
        CalcGamma(reference, target, handles.abs, handles.dta, 1);
    
    % Clear temporary variables
    clear target reference;
    
    %% Parse MLC X values
    % Initialize data array
    handles.([head,'X']) = zeros(3, handles.([head,'num'])(1));
    
    % Set MLC X locations to IC Profiler Y detector locations.
    handles.([head,'X'])(1,1:handles.([head,'num'])(1)) = ...
        ((1:handles.([head,'num'])(1)) - (handles.([head,'num'])(1)+1)/2) ...
        * handles.([head,'width']) * 10;
    
    % Set MLC X data to corrected IC Profiler Y detector data, using
    % leakage and correction factors
    handles.([head,'X'])(2,1:handles.([head,'num'])(1)) = ...
        (handles.([head,'data'])(size(handles.([head,'data']),1), ...
        5 + handles.([head,'num'])(2) + (1:handles.([head,'num'])(1))) - ...
        handles.([head,'data'])(size(handles.([head,'data']),1), 3) * ...
        handles.([head,'bkgd'])(1 + handles.([head,'num'])(2):...
        handles.([head,'num'])(2) + handles.([head,'num'])(1))) .* ...
        handles.([head,'cal'])(1 + handles.([head,'num'])(2):...
        handles.([head,'num'])(2) + handles.([head,'num'])(1));
    
    % Log event
    Event('MLC Y profile extracted');
    
    % Interpolate ignored channels
    for i = 2:size(handles.([head,'X']),2) - 1
        % If the ignore flag is set
        if handles.([head,'ignore'])(i) == 1
            
            % Interpolate linearly from neighboring values
            handles.([head,'X'])(2,i) = (handles.([head,'X'])(2,i-1) + ...
                handles.([head,'X'])(2,i+1)) / 2;
            
            % Log event
            Event(sprintf(['Detector %i ignored, interpolated from ', ...
                'neighboring values'], i));
        end
    end
    
    % Determine location and value of maximum in reference data
    [C, I] = max(handles.refX(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.refX(2,j) == C/2
            l = handles.refX(2,j);
            break;
        elseif handles.refX(2,j) < C/2 && handles.refX(2,j+1) > C/2
            l = interp1(handles.refX(2,j:j+1), ...
                handles.refX(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.refX,2)-1
        if handles.refX(2,j) == C/2
            r = handles.refX(2,j);
            break;
        elseif handles.refX(2,j) > C/2 && handles.refX(2,j+1) < C/2
            r = interp1(handles.refX(2,j:j+1), ...
                handles.refX(1,j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Compute reference center
    refCenter = (r + l) / 2;
    Event(sprintf('Reference MLC X profile center computed at %0.3f mm', ...
        (r + l) / 2));
    
    % Determine location and value of maximum in measured data
    [C, I] = max(handles.([head,'X'])(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.([head,'X'])(2,j) == C/2
            l = handles.([head,'X'])(2,j);
            break;
        elseif handles.([head,'X'])(2,j) < C/2 && ...
                handles.([head,'X'])(2,j+1) > C/2
            l = interp1(handles.([head,'X'])(2,j:j+1), ...
                handles.([head,'X'])(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.([head,'X']),2)-1
        if handles.([head,'X'])(2,j) == C/2
            r = handles.([head,'X'])(2,j);
            break;
        elseif handles.([head,'X'])(2,j) > C/2 && ...
                handles.([head,'X'])(2,j+1) < C/2
            r = interp1(handles.([head,'X'])(2,j:j+1), ...
                handles.([head,'X'])(1,j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Offset measured data to center on reference
    handles.([head,'X'])(1,:) = handles.([head,'X'])(1,:) ...
        - (r + l) / 2 + refCenter;
    Event(sprintf('Measured MLC X profile center computed at %0.3f mm', ...
        (r + l) / 2));
    Event(sprintf('Measured MLC X profile centered on reference'));
    
    % Normalize measured data
    handles.([head,'X'])(2,:) = handles.([head,'X'])(2,:) / ...
        max(handles.([head,'X'])(2,:));
    Event('Measured MLC Y profile normalized to 1');
    
    % Prepare CalcGamma inputs (which uses start/width/data format)
    target.start = handles.([head,'X'])(1,1);
    target.width = handles.([head,'width']) * 10;
    target.data = squeeze(handles.([head,'X'])(2,:));
    
    reference.start = handles.refX(1,1);
    reference.width = handles.refX(1,2) - handles.refX(1,1);
    reference.data = squeeze(handles.refX(2,:));
    
    % Calculate 1-D GLOBAL gamma
    handles.([head,'X'])(3,1:size(handles.([head,'X']),2)) = ...
        CalcGamma(reference, target, handles.abs, handles.dta, 1);
    
    % Clear temporary variables
    clear target reference;
    
    %% Parse Timing profile
    % Initialize data array
    handles.([head,'T']) = zeros(2, size(handles.([head,'data']),1));
    
    % Store time tics (in seconds)
    handles.([head,'T'])(1,:) = handles.([head,'data'])(:,3)/1000000;
    
    % Store center IC Profiler Y detector response
    handles.([head,'T'])(2,:) = handles.([head,'data'])(:,5 + ...
        handles.([head,'num'])(2) + (handles.([head,'num'])(1) + 1)/2);
    Event('Timing cumulative profile extracted');
    
    % Convert signal from integral to differential
    handles.([head,'T'])(2,:) = handles.([head,'T'])(2,:) - ...
        circshift(handles.([head,'T'])(2, :),1,2);
    Event('Timing cumulative profile converted to differential profile');
    
    % Divide signal by tics per packet
    handles.([head,'T'])(2,:) = handles.([head,'T'])(2,:) ./ ...
        (handles.([head,'T'])(1,:) - ...
        circshift(handles.([head,'T'])(1, :),1,2));
    
    % Fix first value (artifact of using circshift)
    handles.([head,'T'])(2,1) = handles.([head,'data'])(1,5 + ...
        handles.([head,'num'])(2) + (handles.([head,'num'])(1) + 1)/2) / ...
        handles.([head,'data'])(1,3) * 1000000;
    
    % Log completion
    Event(sprintf(['SNC PRM profiles parsed successfully in ', ...
        '%0.3f seconds'], toc));
end

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end
function handles = UpdateStatistics(handles, head)
% UpdateStatistics is called by FieldUniformity to compute and update
% the statistics table for each head.  See below for more information on
% the statistics computed.  This function uses GUI handles data (passed in
% the first input variable) loaded by ParseSNCProfiles. This function also 
% uses the input variable head, which should be a string indicating the 
% head number (h1, h2, or h3) to determine which UI table to modify. Upon 
% successful completion, an updated GUI handles structure is returned.
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

% Load table data cell array
table = get(handles.([head, 'table']), 'Data');

% Initialize row counter
c = 0;

% Set time signal packet buffer (number of channels from edge that the SNR
% is measured)
b = 5;

% Set area interpolation factor (for computing area under field)
a = 10000;

% Gamma parameters
c = c + 1;
table{c,1} = 'Gamma criteria';
table{c,2} = sprintf('%0.1f%%/%0.1f mm', [handles.abs, handles.dta]);

% Expected time
c = c + 1;
table{c,1} = 'Expected beam on time';
table{c,2} = sprintf('%0.2f sec', handles.time);

% Measured time
c = c + 1;
table{c,1} = 'Measured beam on time';
if isfield(handles, [head,'T']) && size(handles.([head,'T']), 2) > 0
    % Determine location and value of maximum in time signal
    [C, I] = max(handles.([head,'T'])(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.([head,'T'])(2,j) == C/2
            l = handles.([head,'T'])(2,j);
            break;
        elseif handles.([head,'T'])(2,j) < C/2 && ...
                handles.([head,'T'])(2,j+1) > C/2
            l = interp1(handles.([head,'T'])(2,j:j+1), ...
                handles.([head,'T'])(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.([head,'T']),2)-1
        if handles.([head,'T'])(2,j) == C/2
            r = handles.([head,'T'])(2,j);
            break;
        elseif handles.([head,'T'])(2,j) > C/2 && ...
                handles.([head,'T'])(2,j+1) < C/2
            r = interp1(handles.([head,'T'])(2,j:j+1), ...
                handles.([head,'T'])(1,j:j+1), C/2, 'linear');
            break;
        end
    end   
    
    % Report FWHM of time signal
    table{c,2} = sprintf('%0.2f sec', r-l);
end

% Measured time
c = c + 1;
table{c,1} = 'Time difference';
if isfield(handles, [head,'T']) && size(handles.([head,'T']), 2) > 0
    table{c,2} = sprintf('%0.2f sec', (r-l) - handles.time);
end

% SNR
c = c + 1;
table{c,1} = 'Signal SNR';
if isfield(handles, [head,'T']) && size(handles.([head,'T']), 2) > 0
    table{c,2} = sprintf('%0.2f dB', 20 * ...
        log10(mean(handles.([head,'T'])(2,ceil(l)+b:floor(r)-b)) / ...
        sqrt(sum(var(handles.([head,'T'])(2,1:floor(l)-b))/(floor(l)-b)))));
end

% Reference X FWHM
c = c + 1;
table{c,1} = 'Reference MLC X FWHM';
if isfield(handles, 'refX') && size(handles.refX, 2) > 0
    % Determine location and value of maximum in X signal
    [C, I] = max(handles.refX(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.refX(2,j) == C/2
            l = handles.refX(2,j);
            break;
        elseif handles.refX(2,j) < C/2 && ...
                handles.refX(2,j+1) > C/2
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
        elseif handles.refX(2,j) > C/2 && ...
                handles.refX(2,j+1) < C/2
            r = interp1(handles.refX(2,j:j+1), ...
                handles.refX(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Report FWHM
    refXFWHM = r-l;
    table{c,2} = sprintf('%0.2f mm', refXFWHM);
end

% MLC X FWHM
c = c + 1;
table{c,1} = 'Measured MLC X FWHM';
if isfield(handles, [head,'X']) && size(handles.([head,'X']), 2) > 0
    % Determine location and value of maximum in X signal
    [C, I] = max(handles.([head,'X'])(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.([head,'X'])(2,j) == C/2
            l = handles.([head,'X'])(2,j);
            li = j;
            break;
        elseif handles.([head,'X'])(2,j) < C/2 && ...
                handles.([head,'X'])(2,j+1) > C/2
            l = interp1(handles.([head,'X'])(2,j:j+1), ...
                handles.([head,'X'])(1,j:j+1), C/2, 'linear');
            li = j;
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.([head,'X']),2)-1
        if handles.([head,'X'])(2,j) == C/2
            r = handles.([head,'X'])(2,j);
            ri = j;
            break;
        elseif handles.([head,'X'])(2,j) > C/2 && ...
                handles.([head,'X'])(2,j+1) < C/2
            r = interp1(handles.([head,'X'])(2,j:j+1), ...
                handles.([head,'X'])(1,j:j+1), C/2, 'linear');
            ri = j;
            break;
        end
    end
    
    % Report FWHM
    table{c,2} = sprintf('%0.2f mm', r-l);
end

% MLC X FWHM Difference
c = c + 1;
table{c,1} = 'MLC X FWHM difference';
if isfield(handles, [head,'X']) && size(handles.([head,'X']), 2) > 0
    table{c,2} = sprintf('%0.2f mm', r-l - refXFWHM);
end

% MLC X Flatness
c = c + 1;
table{c,1} = 'MLC X flatness (central 80%)';
if isfield(handles, [head,'X']) && size(handles.([head,'X']), 2) > 0
    dmax = max(handles.([head,'X'])(2,ceil(li+(ri-li)*0.1):floor(ri-(ri-li)*0.1)));
    dmin = min(handles.([head,'X'])(2,ceil(li+(ri-li)*0.1):floor(ri-(ri-li)*0.1)));
    
    table{c,2} = sprintf('%0.2f%%', (dmax-dmin)/(dmax+dmin) * 100);
end

% MLC X Areal Symmetry
c = c + 1;
table{c,1} = 'MLC X areal symmetry (central 80%)';
if isfield(handles, [head,'X']) && size(handles.([head,'X']), 2) > 0
    aleft = interp1(handles.([head,'X'])(1,:), ...
        handles.([head,'X'])(2,:), l+(r-l)*0.1:...
        ((l+r)/2-(l+(r-l)*0.1))/a:(l+r)/2);
    aright = interp1(handles.([head,'X'])(1,:), ...
        handles.([head,'X'])(2,:), (l+r)/2:...
        ((r-(r-l)*0.1)-(l+r)/2)/a:r-(r-l)*0.1);
    
    table{c,2} = sprintf('%0.2f%%', (sum(aright)-sum(aleft)) / ...
        (sum(aright)+sum(aleft)) * 200);
end

% MLC X Point Symmetry
% c = c + 1;
% table{c,1} = 'MLC X point symmetry (central 80%)';
% if isfield(handles, [head,'X']) && size(handles.([head,'X']), 2) > 0   
%     table{c,2} = sprintf('%0.2f%%', max(abs(1 - aleft(a/5:a) ./ ...
%         fliplr(aright(1:4*a/5+1)))) / (2 * aleft(a+1)) * 100);
% end

% MLC X Max Gamma
c = c + 1;
table{c,1} = 'MLC X max gamma (central 50%)';
if isfield(handles, [head,'X']) && size(handles.([head,'X']), 2) > 0
    % Report max gamma
    table{c,2} = sprintf('%0.2f', max(handles.([head,'X'])(3,li:ri)));
end

% Reference Y FWHM
c = c + 1;
table{c,1} = 'Reference MLC Y FWHM';
if isfield(handles, 'refY') && size(handles.refY, 2) > 0
    % Determine location and value of maximum in Y signal
    [C, I] = max(handles.refY(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.refY(2,j) == C/2
            l = handles.refY(2,j);
            break;
        elseif handles.refY(2,j) < C/2 && ...
                handles.refY(2,j+1) > C/2
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
        elseif handles.refY(2,j) > C/2 && ...
                handles.refY(2,j+1) < C/2
            r = interp1(handles.refY(2,j:j+1), ...
                handles.refY(1,j:j+1), C/2, 'linear');
            break;
        end
    end
    
    % Report FWHM
    refYFWHM = r-l;
    table{c,2} = sprintf('%0.2f mm', refYFWHM);
end

% MLC Y FWHM
c = c + 1;
table{c,1} = 'Measured MLC Y FWHM';
if isfield(handles, [head,'Y']) && size(handles.([head,'Y']), 2) > 0
    % Determine location and value of maximum in Y signal
    [C, I] = max(handles.([head,'Y'])(2,:));
    
    % Search left side for half-maximum value
    for j = 1:I-1
        if handles.([head,'Y'])(2,j) == C/2
            l = handles.([head,'Y'])(2,j);
            li = j;
            break;
        elseif handles.([head,'Y'])(2,j) < C/2 && ...
                handles.([head,'Y'])(2,j+1) > C/2
            l = interp1(handles.([head,'Y'])(2,j:j+1), ...
                handles.([head,'Y'])(1,j:j+1), C/2, 'linear');
            li = j;
            break;
        end
    end
    
    % Search right side for half-maximum value
    for j = I:size(handles.([head,'Y']),2)-1
        if handles.([head,'Y'])(2,j) == C/2
            r = handles.([head,'Y'])(2,j);
            ri = j;
            break;
        elseif handles.([head,'Y'])(2,j) > C/2 && ...
                handles.([head,'Y'])(2,j+1) < C/2
            r = interp1(handles.([head,'Y'])(2,j:j+1), ...
                handles.([head,'Y'])(1,j:j+1), C/2, 'linear');
            ri = j;
            break;
        end
    end
    
    % Report FWHM
    table{c,2} = sprintf('%0.2f mm', abs(r-l));
end

% MLC Y FWHM Difference
c = c + 1;
table{c,1} = 'MLC Y FWHM difference';
if isfield(handles, [head,'Y']) && size(handles.([head,'Y']), 2) > 0
    table{c,2} = sprintf('%0.2f mm', abs(r-l) - refYFWHM);
end

% MLC Y Flatness
c = c + 1;
table{c,1} = 'MLC Y flatness (central 80%)';
if isfield(handles, [head,'Y']) && size(handles.([head,'Y']), 2) > 0
    dmax = max(handles.([head,'Y'])(2,ceil(li+(ri-li)*0.1):floor(ri-(ri-li)*0.1)));
    dmin = min(handles.([head,'Y'])(2,ceil(li+(ri-li)*0.1):floor(ri-(ri-li)*0.1)));
    
    table{c,2} = sprintf('%0.2f%%', (dmax-dmin)/(dmax+dmin) * 100);
end

% MLC Y Areal Symmetry
c = c + 1;
table{c,1} = 'MLC Y areal symmetry (central 80%)';
if isfield(handles, [head,'Y']) && size(handles.([head,'Y']), 2) > 0
    aleft = interp1(handles.([head,'Y'])(1,:), ...
        handles.([head,'Y'])(2,:), l+(r-l)*0.1:...
        ((l+r)/2-(l+(r-l)*0.1))/a:(l+r)/2);
    aright = interp1(handles.([head,'Y'])(1,:), ...
        handles.([head,'Y'])(2,:), (l+r)/2:...
        ((r-(r-l)*0.1)-(l+r)/2)/a:r-(r-l)*0.1);
    
    table{c,2} = sprintf('%0.2f%%', (sum(aright)-sum(aleft)) / ...
        (sum(aright)+sum(aleft)) * 200);
end

% MLC Y Point Symmetry
% c = c + 1;
% table{c,1} = 'MLC Y point symmetry (central 80%)';
% if isfield(handles, [head,'Y']) && size(handles.([head,'Y']), 2) > 0   
%     table{c,2} = sprintf('%0.2f%%', max(abs(1 - aleft(a/5:a) ./ ...
%         fliplr(aright(1:4*a/5+1)))) / (2 * aleft(a+1)) * 100);
% end

% MLC Y Max Gamma
c = c + 1;
table{c,1} = 'MLC Y max gamma (central 50%)';
if isfield(handles, [head,'Y']) && size(handles.([head,'Y']), 2) > 0
    % Report max gamma
    table{c,2} = sprintf('%0.2f', max(handles.([head,'Y'])(3,li:ri)));
end
    
% Set table data
set(handles.([head, 'table']), 'Data', table);
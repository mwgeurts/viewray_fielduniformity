function [refX, refY, data] = LoadReferenceProfiles(file)
% LoadReferenceProfiles is called by FieldUniformity to read in the TPS
% calculated data and extract IEC X/Y profiles for comparison to SNC IC 
% Profiler data.  The DICOM data is read from the input variable and the
% MLC X and Y profiles are extracted and returned as refX and refY,
% respectively.
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
    
% Log start
Event(['Loading reference dataset ', file]);
tic;

% Load DICOM data
info = dicominfo(file);
width = info.PixelSpacing;
start = [info.ImagePositionPatient(3); info.ImagePositionPatient(1)];
data = single(dicomread(file)) * info.DoseGridScaling;
    
% Generate mesh
[meshX, meshY]  = meshgrid(start(2):width(2):start(2)+width(2)*...
    (size(data,2)-1),start(1)+width(1)*(size(data,1)-1):-width(1):start(1));
    
% Extract MLC X axis data
refX(1,:) = meshX(1,:);
refX(2,:) = interp2(meshX, meshY, single(data), refX(1,:), ...
    zeros(1,size(refX,2)), '*linear', 0);

% Extract MLC Y axis data
refY(1,:) = meshY(:,1);
refY(2,:) = interp2(meshX, meshY, single(data), zeros(1,size(refY,2)), ...
    refY(1,:), '*linear', 0);

% Flip MLC Y data, as DICOM coordinates are inverted
refY = fliplr(refY);

% Normalize return variables
refX(2,:) = refX(2,:) / max(refX(2,:));
refY(2,:) = refY(2,:) / max(refY(2,:));
data = data / max(max(data));
Event('Reference profiles normalized to 1');

% Log completion
Event(sprintf('Reference dataset successfully loaded in %0.3f seconds', toc));

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end
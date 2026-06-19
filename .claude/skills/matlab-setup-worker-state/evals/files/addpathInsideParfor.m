function results = addpathInsideParfor(data, utilsPath)
%ADDPATHINSIDEPARFOR Process data using utility functions from a custom path
%   Adds a path on every parfor iteration to access helper functions.
% Copyright 2026 The MathWorks, Inc.

pool = parpool("MyCluster"); %#ok<NASGU>

results = zeros(1, numel(data));
parfor i = 1:numel(data)
    addpath(utilsPath);
    results(i) = customProcess(data(i));
    rmpath(utilsPath);
end
end

function results = loadlibraryInsideParfor(data)
%LOADLIBRARYINSIDEPARFOR Process data using a shared library in parfor
%   Loads and unloads the library on every iteration.
% Copyright 2026 The MathWorks, Inc.

results = zeros(1, numel(data));
parfor i = 1:numel(data)
    loadlibrary("mylib", "mylib.h");
    results(i) = calllib("mylib", "compute", data(i));
    unloadlibrary("mylib");
end
end

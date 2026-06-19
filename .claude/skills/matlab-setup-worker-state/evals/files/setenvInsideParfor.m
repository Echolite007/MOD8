function results = setenvInsideParfor(data, licenseServer, cacheDir)
%SETENVINSIDEPARFOR Process data in parfor with third-party engine
%   The engine requires LICENSE_SERVER and CACHE_DIR to be set in the
%   worker process environment before calling computeWithEngine.
% Copyright 2026 The MathWorks, Inc.

setenv("LICENSE_SERVER", licenseServer);
setenv("CACHE_DIR", cacheDir);
pool = parpool("MyCluster"); %#ok<NASGU>

results = zeros(1, numel(data));
parfor i = 1:numel(data)
    setenv("LICENSE_SERVER", licenseServer);
    setenv("CACHE_DIR", cacheDir);
    results(i) = computeWithEngine(data(i));
end
end

function result = computeWithEngine(x)
    result = x.^2 + sin(x);
end

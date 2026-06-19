function results = spmdWorkerTempDirs(data)
%SPMDWORKERTEMPDIRS Process data on workers using isolated scratch directories
%   Each worker must have its own scratch directory.
% Copyright 2026 The MathWorks, Inc.

arguments
    data (:,1) double
end

pool = parpool("Processes", 4);

spmd
    scratchDir = tempname;
    mkdir(scratchDir);
    cd(scratchDir);
end

results = zeros(1, numel(data));
parfor i = 1:numel(data)
    results(i) = solveWithTempFiles(data(i));
end

spmd
    cd(tempdir);
    rmdir(scratchDir, 's');
end

delete(pool);
end

function result = solveWithTempFiles(x)
    % Solver writes intermediate temp files in the current directory
    tmpFile = fullfile(pwd, "scratch.tmp");
    fid = fopen(tmpFile, 'w');
    fwrite(fid, x);
    fclose(fid);
    result = x.^2 + sin(x);
    delete(tmpFile);
end

%% parforLoadMat
% Slow-on-laptop reduction: load a .mat file per iteration and process the
% contents. Used as an eval input for matlab-use-thread-pool to verify the
% agent does NOT pre-emptively claim load() is unsupported on threads.

dataDir = fullfile(tempdir, "parforLoadMat");
if ~exist(dataDir, "dir")
    mkdir(dataDir);
    for ii = 1:50
        data = rand(1000, 1);
        save(fullfile(dataDir, sprintf("data_%d.mat", ii)), "data");
    end
end

out = zeros(1, 50);
parfor ii = 1:50
    data = load(fullfile(dataDir, sprintf("data_%d.mat", ii))).data;
    out(ii) = doProcess(data, ii);
end

function y = doProcess(data, ii)
    y = sum(data) + ii;
end

% Copyright 2026 The MathWorks, Inc.

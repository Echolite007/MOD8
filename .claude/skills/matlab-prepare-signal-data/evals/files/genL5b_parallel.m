function dataDir = genL5b_parallel()
%GENL5B_PARALLEL  Generate flat folder of .mat files for parallel-partition eval.
%   dataDir = genL5b_parallel() creates 60 .mat files (downsized from the
%   prior project's 1000 to keep eval runtime small while still being
%   large enough that worker partitioning is meaningful). Each file holds
%   one variable `signal`. Filenames are class-agnostic — this eval is
%   about parallel dispatch, not labels. rng(0) is seeded for
%   reproducibility.
%
%   Adapted from data-samples/_generators/genL5b_parallel.m in the
%   signal-ml-data-ingestion-tbd prep project.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'L5b_parallel_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

fs = 500;
N = 256;
nFiles = 60;
toneHz = [50, 80, 130];

for k = 1:nFiles
    f0 = toneHz(mod(k-1, numel(toneHz)) + 1);
    t = (0:N-1)' / fs;
    signal = sin(2*pi*f0*t) + 0.3*randn(N,1); %#ok<NASGU>
    fname = sprintf('sample_%04d.mat', k);
    save(fullfile(dataDir, fname), 'signal');
end

fprintf('genL5b_parallel: %d files in %s\n', nFiles, dataDir);
end

% Copyright 2026 The MathWorks, Inc.

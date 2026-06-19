function dataDir = genL6_CSV_B_sampleratecol()
%GENL6_CSV_B_SAMPLERATECOL  Generate fake CSV dataset with sample-rate column.
%   dataDir = genL6_CSV_B_sampleratecol() creates 30 .csv files in a flat
%   folder. Each file has two columns: `signal` (the waveform) and `fs`
%   (the sample rate, repeated on every row). fs varies across files
%   (250 / 500 / 1000 Hz) to make per-file sample-rate handling visible.
%   rng(0) is seeded for reproducibility.
%
%   Adapted from data-samples/_generators/genL6_CSV_B_sampleratecol.m
%   in the signal-ml-data-ingestion-tbd prep project.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'L6_CSV_B_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

N = 256;
nFiles = 30;
fsOptions = [250, 500, 1000];
toneHz = [50, 80, 130];

for k = 1:nFiles
    fs = fsOptions(mod(k-1, numel(fsOptions)) + 1);
    f0 = toneHz(mod(k-1, numel(toneHz)) + 1);
    t = (0:N-1)' / fs;
    signal = sin(2*pi*f0*t) + 0.3*randn(N,1);
    fsCol = repmat(fs, N, 1);
    T = table(signal, fsCol, 'VariableNames', {'signal','fs'});
    fname = sprintf('sample_%02d.csv', k);
    writetable(T, fullfile(dataDir, fname));
end

fprintf('genL6_CSV_B_sampleratecol: %d files in %s\n', nFiles, dataDir);
end

% Copyright 2026 The MathWorks, Inc.

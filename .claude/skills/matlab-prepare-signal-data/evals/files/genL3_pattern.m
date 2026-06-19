function dataDir = genL3_pattern()
%GENL3_PATTERN  Generate flat folder of .mat files for the L3 eval.
%   dataDir = genL3_pattern() creates 16 .mat files in a flat folder.
%   Each file holds a single variable `signal`. rng(0) is seeded for
%   reproducibility.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'L3_pattern_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

fs = 1000;
N = 2048;

catalog = {
    "subj01",   "G3",  "02";
    "subj01",   "G3",  "03";
    "subj01",   "G7",  "01";
    "subj02",   "G3",  "01";
    "subj02",   "G11", "02";
    "subj02",   "G11", "03";
    "subj03",   "G7",  "01";
    "subj03",   "G7",  "02";
    "subj03",   "G11", "01";
    "subj004",  "G3",  "01";
    "subj004",  "G7",  "01";
    "subj005",  "G11", "01";
    "subj005",  "G11", "02";
    "subj006",  "G3",  "01";
    "subj006",  "G3",  "02";
    "subj006",  "G7",  "01";
};

gestureFreq = containers.Map({'G3','G7','G11'}, {30, 70, 110});

for k = 1:size(catalog, 1)
    subj    = catalog{k,1};
    gesture = catalog{k,2};
    trialId = catalog{k,3};
    f0 = gestureFreq(char(gesture));

    t = (0:N-1)' / fs;
    signal = sin(2*pi*f0*t) + 0.25*randn(N,1); %#ok<NASGU>

    fname = sprintf('%s_%s_trial%s.mat', subj, gesture, trialId);
    save(fullfile(dataDir, fname), 'signal');
end

fprintf('genL3_pattern: %d files in %s\n', size(catalog,1), dataDir);
end

% Copyright 2026 The MathWorks, Inc.

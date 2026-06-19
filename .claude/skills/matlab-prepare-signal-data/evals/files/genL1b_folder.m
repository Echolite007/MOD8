function dataDir = genL1b_folder()
%GENL1B_FOLDER  Generate fake folder-labeled .mat dataset for the L1b eval.
%   dataDir = genL1b_folder() creates a small dataset with three subfolders
%   (ClassA, ClassB, ClassC) of .mat files; each file holds a single
%   variable called `signal`. Counts are imbalanced (10/8/6) to make the
%   stratified split visible. rng(0) is seeded for reproducibility.
%
%   Adapted from data-samples/_generators/genL1b_folder.m in the
%   signal-ml-data-ingestion-tbd prep project.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'L1b_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

fs = 500;
N = 1024;
classes = ["ClassA", "ClassB", "ClassC"];
counts = [10, 8, 6];
toneHz = [50, 80, 130];

for c = 1:numel(classes)
    cls = classes(c);
    f0 = toneHz(c);
    classDir = fullfile(dataDir, cls);
    if ~exist(classDir, 'dir'); mkdir(classDir); end
    for k = 1:counts(c)
        t = (0:N-1)' / fs;
        signal = sin(2*pi*f0*t) + 0.3*randn(N,1); %#ok<NASGU>
        fname = sprintf('sample_%03d.mat', k);
        save(fullfile(classDir, fname), 'signal');
    end
end

fprintf('genL1b_folder: %d files across %d subfolders in %s\n', ...
    sum(counts), numel(classes), dataDir);
end

% Copyright 2026 The MathWorks, Inc.

function dataDir = genStringLabelMat()
%GENSTRINGLABELMAT  Flat folder of .mat files with in-file string labels.
%   dataDir = genStringLabelMat() creates 30 .mat files in a flat folder.
%   Each file holds three variables: `data` (200x4 double, multi-channel
%   signal), `lbl` (string scalar, one of "ALPHA"/"BETA"/"GAMMA"), and
%   `Fs` (scalar). Class counts are imbalanced (12/10/8) so stratified
%   splitting produces a non-trivial split. rng(0) is seeded.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'string_label_mat_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

classes = ["ALPHA", "BETA", "GAMMA"];
counts  = [12, 10, 8];
toneHz  = [40, 80, 130];
nCh     = 4;
N       = 200;
Fs      = 256; %#ok<NASGU>

idx = 0;
for c = 1:numel(classes)
    cls = classes(c);
    f0  = toneHz(c);
    for k = 1:counts(c)
        idx = idx + 1;
        t = (0:N-1)' / 256;
        base = sin(2*pi*f0*t);
        data = repmat(base, 1, nCh) + 0.2 * randn(N, nCh); %#ok<NASGU>
        lbl  = cls; %#ok<NASGU>
        fname = sprintf('clip_%03d.mat', idx);
        save(fullfile(dataDir, fname), 'data', 'lbl', 'Fs');
    end
end

fprintf('genStringLabelMat: %d files in %s\n', sum(counts), dataDir);
end

% Copyright 2026 The MathWorks, Inc.

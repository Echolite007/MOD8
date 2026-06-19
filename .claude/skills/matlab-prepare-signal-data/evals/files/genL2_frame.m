function matFile = genL2_frame()
%GENL2_FRAME  Generate single .mat with signal + ROI table for the L2 eval.
%   matFile = genL2_frame() creates one .mat file holding `signal`,
%   `fs`, and `roiTable` (variables `ROILimits` + `Category`). rng(0)
%   is seeded for reproducibility.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'L2_frame_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

fs = 16000;
durSec = 30;
N = fs * durSec;
t = (0:N-1)' / fs;

signal = 0.02 * randn(N, 1);

limits = [
        1   100000
    30000    50000
    70000    90000
   100001   180000
   180001   280000
   200000   240000
   280001   480000
];
cats = categorical([
    "speech"; "voiced"; "voiced"; "silence"; ...
    "speech"; "voiced"; "silence"
], ["voiced", "speech", "silence"]);

isSpeech1 = (1:N)' >= 1      & (1:N)' <= 100000;
isSpeech2 = (1:N)' >= 180001 & (1:N)' <= 280000;
signal(isSpeech1) = signal(isSpeech1) + 0.15 * randn(sum(isSpeech1), 1) ...
    + 0.2 * sin(2*pi*220 * t(isSpeech1));
signal(isSpeech2) = signal(isSpeech2) + 0.15 * randn(sum(isSpeech2), 1) ...
    + 0.2 * sin(2*pi*180 * t(isSpeech2));

voicedRanges = [30000 50000; 70000 90000; 200000 240000];
voicedFreqs  = [180, 220, 200];
for v = 1:size(voicedRanges, 1)
    idx = (voicedRanges(v,1):voicedRanges(v,2))';
    signal(idx) = signal(idx) + 0.4 * sin(2*pi*voicedFreqs(v) * t(idx));
end

roiTable = table(limits, cats, 'VariableNames', {'ROILimits', 'Category'}); %#ok<NASGU>

matFile = fullfile(dataDir, 'speech_voicing.mat');
save(matFile, 'signal', 'fs', 'roiTable');

fprintf('genL2_frame: 1 file (%d samples, %d ROIs) in %s\n', N, size(limits,1), dataDir);
end

% Copyright 2026 The MathWorks, Inc.

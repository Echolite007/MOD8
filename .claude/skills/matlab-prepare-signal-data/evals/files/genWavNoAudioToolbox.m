function dataDir = genWavNoAudioToolbox()
%GENWAVNOAUDIOTOOLBOX  Generate flat folder of .wav files for an eval.
%   dataDir = genWavNoAudioToolbox() creates 12 .wav files in a flat
%   folder. Sample rates vary across files (8 kHz / 16 kHz). rng(0) is
%   seeded for reproducibility.

rng(0);

caseDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(caseDir, 'wav_no_audio_toolbox_data');
if ~exist(dataDir, 'dir'); mkdir(dataDir); end

fsList = [8000, 16000];
durSec = 0.5;
toneHz = [220, 440, 660, 880];
nFiles = 12;

for k = 1:nFiles
    fs = fsList(mod(k-1, numel(fsList)) + 1);
    f0 = toneHz(mod(k-1, numel(toneHz)) + 1);
    t = (0:round(fs*durSec)-1)' / fs;
    y = 0.5 * sin(2*pi*f0*t) + 0.05*randn(size(t));
    fname = sprintf('clip_%02d.wav', k);
    audiowrite(fullfile(dataDir, fname), y, fs);
end

fprintf('genWavNoAudioToolbox: %d files in %s\n', nFiles, dataDir);
end

% Copyright 2026 The MathWorks, Inc.

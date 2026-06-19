function validate_eval11()
%VALIDATE_EVAL11  Sanity-check the canonical answer to eval-11.
%   Runs the generator, builds a signalDatastore with the canonical
%   custom-ReadFcn fallback (audioread inside ReadFcn), reads one file,
%   prints data shape + per-file SampleRate. Used to confirm the eval is
%   runnable before spawning baseline / with-skill agents.

dataDir = genWavNoAudioToolbox;

sds = signalDatastore(dataDir, ...
    FileExtensions=".wav", ...
    ReadFcn=@readWav);

[data, info] = read(sds);

fprintf('VALIDATE_EVAL11 OK\n');
fprintf('  files          = %d\n', numel(sds.Files));
fprintf('  data class     = %s\n', class(data));
fprintf('  data size      = [%s]\n', num2str(size(data)));
fprintf('  info.SampleRate= %d\n', info.SampleRate);
fprintf('  info.FileName  = %s\n', info.FileName);
end

function [data, info] = readWav(filename)
[data, fs] = audioread(filename);
info.SampleRate = fs;
end

% Copyright 2026 The MathWorks, Inc.

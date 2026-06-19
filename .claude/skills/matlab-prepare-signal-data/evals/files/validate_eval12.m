function validate_eval12()
%VALIDATE_EVAL12  Sanity-check the canonical answer to eval-12.
%   Runs the generator, builds two signalDatastores (predictor + label),
%   pins the category list across splits via `categorical(str, cats)`,
%   and runs trainnet for one short epoch with ValidationData wired in.
%   Used to confirm eval-12 is runnable before spawning baseline /
%   with-skill agents.

dataDir = genStringLabelMat;

sds = signalDatastore(dataDir, ...
    FileExtensions=".mat", ...
    SignalVariableNames=["data","lbl"]);

labelSds = signalDatastore(dataDir, ...
    FileExtensions=".mat", ...
    SignalVariableNames="lbl");
labelCells = readall(labelSds);
labels = categorical(vertcat(labelCells{:}));

cats = categories(labels);

splitIdx = splitlabels(labels, [0.7 0.15 0.15]);
sdsTrain = subset(sds, splitIdx{1});
sdsVal   = subset(sds, splitIdx{2});

prepFcn = @(c) {single(c{1}), categorical(string(c{2}), cats)};
sdsTrainT = transform(sdsTrain, prepFcn);
sdsValT   = transform(sdsVal,   prepFcn);

layers = [
    sequenceInputLayer(4, MinLength=200)
    convolution1dLayer(8, 8, Padding="same")
    reluLayer
    globalAveragePooling1dLayer
    fullyConnectedLayer(numel(cats))
    softmaxLayer
];

opts = trainingOptions("adam", ...
    MaxEpochs=1, MiniBatchSize=4, ...
    ValidationData=sdsValT, ValidationFrequency=2, ...
    Verbose=false, Plots="none");

net = trainnet(sdsTrainT, layers, "crossentropy", opts); %#ok<NASGU>

fprintf('VALIDATE_EVAL12 OK\n');
fprintf('  files          = %d\n', numel(sds.Files));
fprintf('  classes        = %d (%s)\n', numel(cats), strjoin(cats, ', '));
fprintf('  split sizes    = train=%d, val=%d, test=%d\n', ...
    numel(splitIdx{1}), numel(splitIdx{2}), numel(splitIdx{3}));
end

% Copyright 2026 The MathWorks, Inc.

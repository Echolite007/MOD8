function [detections, rdMap] = processRadarPulses(rxSignal, waveParams, nPulses)
    % Process coherent radar pulses: match filter, Doppler FFT, CFAR detection
    % rxSignal: nSamples x nPulses x nChannels received signal
    % waveParams: struct with .bandwidth, .pulseWidth, .sampleRate, .fc
    % nPulses: number of pulses in the CPI
    %
    % For typical parameters: nSamples=8192, nPulses=128, nChannels=16
    % "This function uses too much memory for large arrays"

    arguments
        rxSignal double
        waveParams struct
        nPulses (1,1) double
    end

    [nSamples, ~, nChannels] = size(rxSignal);

    %% Generate matched filter (small — called once)
    matchedFilter = generateMatchedFilter(waveParams, nSamples);

    %% Apply window for sidelobe suppression (small)
    window = repmat(taylorwin(nSamples, 4, -35), 1, nPulses, nChannels);
    rxWindowed = rxSignal .* window;

    %% Pulse compression via matched filtering
    % This looks expensive but is an FFT-based built-in operation
    compressed = zeros(nSamples, nPulses, nChannels);
    for ch = 1:nChannels
        compressed(:,:,ch) = fftfilt(matchedFilter, rxWindowed(:,:,ch));
    end

    %% Doppler processing
    dopplerWindow = repmat(hann(nPulses).', nSamples, 1, nChannels);
    compressedWindowed = compressed .* dopplerWindow;
    rdMap = fft(compressedWindowed, nPulses, 2);

    %% Adaptive beamforming across channels
    % Estimate covariance and apply weights per range-Doppler bin
    beamOutput = zeros(nSamples, nPulses);
    for rBin = 1:nSamples
        snapshot = squeeze(rdMap(rBin, :, :));  % nPulses x nChannels
        R = (snapshot' * snapshot) / nPulses;   % nChannels x nChannels (small!)
        weights = R \ ones(nChannels, 1);       % Capon beamformer
        weights = weights / (ones(1,nChannels) * weights);
        beamOutput(rBin, :) = (weights' * snapshot.').';
    end

    %% CFAR detection on beamformed output
    detections = cfarDetect2D(beamOutput, waveParams);

    %% Store range-Doppler map for display
    rdMap = abs(beamOutput).^2;
end

function mf = generateMatchedFilter(params, nSamples)
    % LFM matched filter (tiny — nSamples x 1)
    t = (0:nSamples-1).' / params.sampleRate;
    chirp = exp(1j * pi * params.bandwidth / params.pulseWidth * t.^2);
    mf = conj(flipud(chirp));
end

function dets = cfarDetect2D(powerMap, params)
    % 2D CA-CFAR detection
    [nRange, nDoppler] = size(powerMap);
    guardR = 2; guardD = 2;
    trainR = 4; trainD = 4;
    threshold = 12; % dB above noise floor

    dets = struct('range', {}, 'doppler', {}, 'power', {});
    noiseFloor = zeros(nRange, nDoppler);

    for r = (guardR+trainR+1):(nRange-guardR-trainR)
        for d = (guardD+trainD+1):(nDoppler-guardD-trainD)
            % Training cells (exclude guard band)
            trainCells = powerMap(r-trainR-guardR:r+trainR+guardR, ...
                                  d-trainD-guardD:d+trainD+guardD);
            guardMask = zeros(size(trainCells));
            cR = trainR+guardR+1; cD = trainD+guardD+1;
            guardMask(cR-guardR:cR+guardR, cD-guardD:cD+guardD) = 1;
            trainCells(guardMask==1) = 0;
            nTrain = numel(trainCells) - sum(guardMask(:));
            noiseFloor(r,d) = sum(trainCells(:)) / nTrain;
        end
    end

    % Detect targets
    detMask = powerMap > noiseFloor * db2pow(threshold);
    [rIdx, dIdx] = find(detMask);
    for k = 1:numel(rIdx)
        dets(k).range = rIdx(k);
        dets(k).doppler = dIdx(k);
        dets(k).power = powerMap(rIdx(k), dIdx(k));
    end
end

% Copyright 2026 The MathWorks, Inc.

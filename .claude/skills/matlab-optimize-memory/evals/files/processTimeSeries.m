function [results, stats] = processTimeSeries(data, windowSize, overlap)
%processTimeSeries Sliding-window analysis of multi-channel time series.
%   [results, stats] = processTimeSeries(data, windowSize, overlap)
%   processes each channel with overlapping windows, computing FFT-based
%   features per window.
%
%   Inputs:
%       data       - T x nChannels matrix of time-series samples
%       windowSize - number of samples per window
%       overlap    - fraction overlap between windows (0 to 0.99)
%
%   Outputs:
%       results - struct with per-window spectral features
%       stats   - summary statistics across all windows

    arguments
        data (:,:) double
        windowSize (1,1) double {mustBePositive, mustBeInteger}
        overlap (1,1) double {mustBeInRange(overlap, 0, 0.99)} = 0.5
    end

    [T, nChannels] = size(data);
    stepSize = round(windowSize * (1 - overlap));
    nWindows = floor((T - windowSize) / stepSize) + 1;

    % Preallocate window matrix for all channels at once
    allWindows = zeros(windowSize, nWindows, nChannels);
    for ch = 1:nChannels
        for w = 1:nWindows
            startIdx = (w-1) * stepSize + 1;
            allWindows(:, w, ch) = data(startIdx:startIdx+windowSize-1, ch);
        end
    end

    % Apply Hanning window via repmat
    win = hanning(windowSize);
    winMatrix = repmat(win, 1, nWindows, nChannels);
    windowedData = allWindows .* winMatrix;

    % Compute FFT for all windows
    nfft = 2^nextpow2(windowSize);
    spectra = fft(windowedData, nfft, 1);
    halfSpec = spectra(1:nfft/2+1, :, :);

    % Power spectral density
    psd = abs(halfSpec).^2 / windowSize;

    % Compute features per window — growing arrays
    peakFreqs = [];
    bandPowers = [];
    spectralEntropy = [];

    for w = 1:nWindows
        for ch = 1:nChannels
            psdSlice = psd(:, w, ch);

            % Peak frequency
            [~, peakIdx] = max(psdSlice);
            peakFreqs = [peakFreqs; peakIdx]; %#ok<AGROW>

            % Band power (sum in 4 bands)
            nBins = numel(psdSlice);
            bandEdges = round(linspace(1, nBins, 5));
            bp = zeros(1, 4);
            for b = 1:4
                bp(b) = sum(psdSlice(bandEdges(b):bandEdges(b+1)));
            end
            bandPowers = [bandPowers; bp]; %#ok<AGROW>

            % Spectral entropy
            pNorm = psdSlice / sum(psdSlice);
            pNorm(pNorm == 0) = eps;
            se = -sum(pNorm .* log2(pNorm));
            spectralEntropy = [spectralEntropy; se]; %#ok<AGROW>
        end
    end

    % Reshape results
    results.peakFreqs = reshape(peakFreqs, nChannels, nWindows)';
    results.bandPowers = reshape(bandPowers, nChannels, nWindows, 4);
    results.spectralEntropy = reshape(spectralEntropy, nChannels, nWindows)';
    results.psd = psd;

    % Summary statistics
    stats.meanPSD = squeeze(mean(psd, 2));
    stats.meanEntropy = mean(results.spectralEntropy, 1);
    stats.meanBandPower = squeeze(mean(results.bandPowers, 2));
end

% Copyright 2026 The MathWorks, Inc.

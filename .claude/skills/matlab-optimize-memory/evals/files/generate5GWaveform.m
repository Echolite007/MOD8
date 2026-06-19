function [waveform, gridInfo] = generate5GWaveform(carrier, nBWP, nAntennas)
    % Generate a 5G NR downlink waveform with SSB bursts and BWP grids
    % carrier: struct with .NSizeGrid, .SubcarrierSpacing, .NCellID
    % nBWP: number of bandwidth parts (typically 1-4)
    % nAntennas: number of transmit antennas (4-8)

    arguments
        carrier struct
        nBWP (1,1) double = 2
        nAntennas (1,1) double = 4
    end

    carrierK = double(carrier.NSizeGrid) * 12;  % subcarriers
    symbolsPerSlot = 14;
    nSlots = 20;  % 10ms frame
    totalSymbols = symbolsPerSlot * nSlots;

    %% Generate SSB burst waveform (loop over half-frames)
    nHalfFrames = 8;
    samplesPerHF = carrierK * symbolsPerSlot * 2;  % samples per half-frame
    burstWaveform = complex(zeros(0, nAntennas));
    burstGrid = complex(zeros(carrierK, 0, nAntennas));

    for hf = 1:nHalfFrames
        % Generate SSB for this half-frame
        ssbWave = generateSSB(carrier, hf, nAntennas, samplesPerHF);
        ssbGrid = generateSSBGrid(carrier, hf, nAntennas, symbolsPerSlot);

        % Accumulate burst waveform and grid
        burstWaveform = [burstWaveform; ssbWave];
        burstGrid = [burstGrid, ssbGrid];

        % Also build a sync raster (small, needed later)
        syncRaster(hf) = computeSyncPosition(carrier, hf);
    end

    %% Generate BWP resource element grids
    bwpGridsXRS = cell(nBWP, 1);
    bwpGridsPDCCH = cell(nBWP, 1);
    bwpGridsPDSCH = cell(nBWP, 1);
    bwpGridsCSIRS = cell(nBWP, 1);

    for bp = 1:nBWP
        bwpGridsXRS{bp} = generateXRS(carrier, bp, nAntennas, carrierK, totalSymbols);
        bwpGridsPDCCH{bp} = generatePDCCH(carrier, bp, nAntennas, carrierK, totalSymbols);
        bwpGridsPDSCH{bp} = generatePDSCH(carrier, bp, nAntennas, carrierK, totalSymbols);
        bwpGridsCSIRS{bp} = generateCSIRS(carrier, bp, nAntennas, carrierK, totalSymbols);
    end

    %% Combine BWP grids into carrier grid
    carrierGrid = repmat(complex(zeros(carrierK, totalSymbols, 1)), 1, 1, nAntennas);

    for bp = 1:nBWP
        % Combine all channel grids for this BWP
        bwpCombined = bwpGridsXRS{bp} + bwpGridsPDCCH{bp} + bwpGridsPDSCH{bp} + bwpGridsCSIRS{bp};
        carrierGrid = carrierGrid + bwpCombined;
    end

    %% OFDM modulate (this is a built-in, cannot optimize)
    waveform = ofdmModulate(carrierGrid, carrier);

    %% Combine with burst
    waveform(1:size(burstWaveform,1), :) = waveform(1:size(burstWaveform,1), :) + burstWaveform;

    gridInfo.carrierGrid = carrierGrid;
    gridInfo.burstGrid = burstGrid;
    gridInfo.syncRaster = syncRaster;
end

function ssbWave = generateSSB(carrier, halfFrame, nAnt, nSamples)
    ssbWave = complex(randn(nSamples, nAnt), randn(nSamples, nAnt)) * 0.1;
end

function ssbGrid = generateSSBGrid(carrier, halfFrame, nAnt, symbolsPerSlot)
    K = double(carrier.NSizeGrid) * 12;
    ssbGrid = complex(zeros(K, symbolsPerSlot*2, nAnt));
    ssbGrid(1:240, 1:4, :) = complex(randn(240,4,nAnt), randn(240,4,nAnt));
end

function pos = computeSyncPosition(carrier, halfFrame)
    pos = (halfFrame-1) * 2 + 1;
end

function grid = generateXRS(carrier, bwp, nAnt, K, T)
    grid = complex(zeros(K, T, nAnt));
    grid(1:4:end, 1:4:end, :) = complex(randn(ceil(K/4), ceil(T/4), nAnt));
end

function grid = generatePDCCH(carrier, bwp, nAnt, K, T)
    grid = complex(zeros(K, T, nAnt));
    grid(1:48, 1:14, :) = complex(randn(48, 14, nAnt));
end

function grid = generatePDSCH(carrier, bwp, nAnt, K, T)
    grid = complex(zeros(K, T, nAnt));
    grid(:, 3:end, :) = complex(randn(K, T-2, nAnt), randn(K, T-2, nAnt));
end

function grid = generateCSIRS(carrier, bwp, nAnt, K, T)
    grid = complex(zeros(K, T, nAnt));
    grid(1:2:end, 1:14:end, :) = complex(randn(K/2, ceil(T/14), nAnt));
end

function waveform = ofdmModulate(grid, carrier)
    % Placeholder for built-in OFDM modulation
    waveform = ifft(grid, [], 1);
    waveform = reshape(waveform, [], size(grid, 3));
end

% Copyright 2026 The MathWorks, Inc.

%% monteCarloChannel
% Edric review Example 1: Monte Carlo communication-system simulation.
% User reports parfor only gets 2-3x speedup on 8 cores. The skill should
% recommend parpool("Threads") without over-claiming that thread workers
% eliminate "all" serialization or IPC cost.

function monteCarloChannel
    config = configInit();
    numIterations = 100;
    parfor i = 1:numIterations
        txSig = transmit(config); %#ok<NASGU>
        rxSig = channel(txSig); %#ok<NASGU>
        detect(rxSig); %#ok<NASGU>
    end
end

function config = configInit
    config.snr = 10;
    config.numSymbols = 1024;
end

function tx = transmit(config)
    tx = randn(config.numSymbols, 1) + 1i*randn(config.numSymbols, 1);
end

function rx = channel(tx)
    rx = tx + 0.1*(randn(size(tx)) + 1i*randn(size(tx)));
end

function bits = detect(rx)
    bits = real(rx) > 0;
end

% Copyright 2026 The MathWorks, Inc.

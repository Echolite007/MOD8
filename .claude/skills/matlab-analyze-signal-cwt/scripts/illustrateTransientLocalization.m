% Copyright 2026 The MathWorks, Inc.
%% illustrateTransientLocalization - Compare wavelet time localization
% Demonstrates time localization quality for three wavelet choices on an
% impulse signal. Shows finest-scale CWT coefficients for:
%   1. Morse with low TimeBandwidth (best time localization)
%   2. Analytic Morlet / amor (good time localization)
%   3. Bump (worst time localization — compact in frequency, not time)
%
% Run this script when the user asks about transient detection or wants to
% understand why wavelet choice matters for time localization.

%% Create synthetic impulse signal
Fs = 100;                       % Sampling frequency (Hz)
N = 1000;                       % Signal length (samples)
t = (0:N-1) / Fs;              % Time vector
signal = zeros(1, N);
signal(500) = 1;               % Impulse at t = 5 s

%% Compute CWT with three wavelet configurations
% Morse with low TimeBandwidth — best time localization
[cfsMorse, fMorse] = cwt(signal, "Morse", Fs, TimeBandwidth=15);
finestMorse = abs(cfsMorse(1, :));

% Analytic Morlet (amor) — good time localization
[cfsAmor, fAmor] = cwt(signal, "amor", Fs);
finestAmor = abs(cfsAmor(1, :));

% Bump — worst time localization (compact in frequency, spread in time)
[cfsBump, fBump] = cwt(signal, "bump", Fs);
finestBump = abs(cfsBump(1, :));

%% Normalize for visual comparison
finestMorse = finestMorse / max(finestMorse);
finestAmor = finestAmor / max(finestAmor);
finestBump = finestBump / max(finestBump);

%% Plot comparison
figure
tiledlayout(3, 1, TileSpacing="compact", Padding="compact")

nexttile
plot(t, finestMorse, "b", LineWidth=1.2)
ylabel("|CWT|")
title("Morse, TimeBandwidth = 15 (Best Time Localization)")
xlim([3 7])
grid on

nexttile
plot(t, finestAmor, "r", LineWidth=1.2)
ylabel("|CWT|")
title("Analytic Morlet / amor (Good Time Localization)")
xlim([3 7])
grid on

nexttile
plot(t, finestBump, Color=[0.5 0 0.8], LineWidth=1.2)
xlabel("Time (s)")
ylabel("|CWT|")
title("Bump (Worst Time Localization — Compact in Frequency)")
xlim([3 7])
grid on

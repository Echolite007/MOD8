% Copyright 2026 The MathWorks, Inc.
%% Illustrate the correctness of the L1 normalization for Amplitudes
%
Fs = 1000;
% Keep the frequencies low for this demonstration because wavelet filters
% are more localized in frequency at lower frequencies. This is their
% constant-Q property.
t = linspace(0,1,Fs);
f1 = 32;
f2 = 64;
x = cos(2*pi*f1*t)+3/4*cos(2*pi*f2*t);
fb = cwtfilterbank(SignalLength=length(x),SamplingFrequency=Fs,...
    Boundary="periodic");
Nx = length(x);
% Use WT method of cwtfilterbank.
[cfs,f] = wt(fb,x);
[~,f32idx] = min(abs(f-f1));
[~,f64idx] = min(abs(f-f2));
% Extract and plot scalogram scales (frequencies) best matching f1 and f2.
cfs32 = cfs(f32idx,:);
cfs64 = cfs(f64idx,:);
tl = tiledlayout(2,1);
nexttile
plot(t,abs(cfs32),LineWidth=1.5);
ylim([0.5 1.5])
hold on
plot(t,ones(Nx,1),'r--',LineWidth=1.5);
legend("Scalogram Magnitude","True Amplitude")
ylabel("Magnitude")
grid on
nexttile
plot(t,abs(cfs64))
hold on
plot(t,0.75*ones(Nx,1),'r--',LineWidth=1.5);
ylim([0.25 1.25])
legend("Scalogram Magnitude","True Amplitude")
ylabel("Magnitude")
xlabel("Seconds")
grid on
title(tl,'Scalogram Magnitudes for Sinusoids of Known Amplitude')
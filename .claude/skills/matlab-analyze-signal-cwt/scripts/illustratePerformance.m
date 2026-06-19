% Copyright 2026 The MathWorks, Inc.
%% Create a long signal consisting of 365,000 samples.
t = linspace(0,365,365000);
Fs = 1000;
x = cos(2*pi*32*t)+3/4*cos(2*pi*64*t)+0.01*randn(size(t));
% First let's time the CWT function performance a few times.
fcwt = @()cwt(x,Fs);
timeit(fcwt)
%% Now let's time the two-step filter bank
fb = cwtfilterbank(SignalLength=length(x),SamplingFrequency=Fs);
fwt = @()wt(fb,x);
timeit(fwt)
%% Now change to periodic boundary conditions which does not extend the signal.
fb = cwtfilterbank(SignalLength=length(x),boundary="periodic",SamplingFrequency=Fs);
fwt = @()wt(fb,x);
timeit(fwt)
%% Reducing Frequency Range if Possible
%
assessSpectralEnergy(x, Fs);
%%
% Use recommended limits with zero padding boundary. It will extend the signal
% as much as reflection. Use suggested frequency limits from the
% assessSpectralEnergy helper but relax them a bit to be conservative.
fb = cwtfilterbank(SignalLength=length(x),boundary="zeropad",...
    SamplingFrequency=Fs,FrequencyLimits=[25,70]);
fwt = @()wt(fb,x);
timeit(fwt)
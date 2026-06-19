% Copyright 2026 The MathWorks, Inc.
%% Scale-to-Frequency conversion
% Let $\psi(t)$ be a wavelet with Fourier transform $\hat{\psi}(f)$.
% Suppose the wavelet has a center frequency of $f_{\psi}$, this must be
% positive because we are starting with analytic wavelets. Now dilating the
% wavelet using our L1-normalization convention results in a wavelet with a
% Fourier transform of $\hat{\psi}(sf)$ where $s$ denotes scale. This
% wavelet filter has a center frequency of $\frac{f_{\psi}}{f}$. You can see that 
% by substituting in for $s$ in the expression for the Fourier transform. 
% This means that the relationship between scale and frequency is given by 
% $s =\frac{f_{\psi}}{f}$. Note that no matter the convention for the Fourier
% transform, scale is unitless.
%%
% Create a cwtfilterbank object using the default Morse wavelet
fb = cwtfilterbank;
% Locale function to get peak frequency.
[~,peakCF] = wavpeakfreq(fb.Wavelet,3,fb.TimeBandwidth);
scales = fb.scales;
F = centerFrequencies(fb);
plot(scales,peakCF./F);


function [peakAF, peakCF] = wavpeakfreq(wav,ga,timebandwidth)
arguments
    wav {mustBeTextScalar} = "morse"
    ga = 3;
    timebandwidth = 60;
end
be = timebandwidth/ga;
if startsWith(wav,"m","IgnoreCase",true)
    %$(\frac{\beta}{\gamma})^{1/\gamma}$
    peakAF = exp(1/ga*(log(be)-log(ga)));
    % Obtain the peak frequency in cyclical frequency
    peakCF = peakAF/(2*pi);
elseif startsWith(wav,"a","IgnoreCase",true)
    peakAF = 6;
    peakCF = 6/(2*pi);
else
    peakAF = 5;
    peakCF = 5/(2*pi);
end
end
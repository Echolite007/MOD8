# Pattern Comparison and Analysis Templates

## Pattern Comparison (Steered vs. Broadside)

```matlab
% Broadside
arr.PhaseShift = zeros(1, arr.NumElements);
D_broadside = patternAzimuth(arr, freq, 0);

% Steered to 30 deg
ps = phaseShift(arr, freq, [30, 0]);
arr.PhaseShift = ps;
D_steered = patternAzimuth(arr, freq, 0);

az = -180:1:180;
figure;
pp = polarpattern(az, D_broadside);
add(pp, az, D_steered);
pp.AntennaMetrics = true;
pp.LegendLabels = {'Broadside', 'Steered 30°'};
pp.TitleTop = sprintf("Azimuth Pattern Comparison at %.2f GHz", freq/1e9);
```

## Pattern Comparison (Tapered vs. Uniform)

```matlab
% Uniform taper
arr.AmplitudeTaper = ones(1, arr.NumElements);
D_uniform = patternAzimuth(arr, freq, 0);

% Taylor taper
try
    arr.AmplitudeTaper = taylorwin(arr.NumElements, 4, -30)';
catch
    arr.AmplitudeTaper = ones(1, arr.NumElements);
end
D_tapered = patternAzimuth(arr, freq, 0);

az = -180:1:180;
figure;
pp = polarpattern(az, D_uniform);
add(pp, az, D_tapered);
pp.AntennaMetrics = true;
pp.LegendLabels = {'Uniform', 'Taylor -30 dB'};
pp.TitleTop = sprintf("Taper Comparison at %.2f GHz", freq/1e9);
```

## Multi-Frequency Pattern

```matlab
freqs = [freq * 0.9, freq, freq * 1.1];
az = -180:1:180;

D1 = patternAzimuth(arr, freqs(1), 0);
figure;
pp = polarpattern(az, D1);
for i = 2:numel(freqs)
    D = patternAzimuth(arr, freqs(i), 0);
    add(pp, az, D);
end
pp.AntennaMetrics = true;
pp.LegendLabels = arrayfun(@(f) sprintf('%.2f GHz', f/1e9), freqs, UniformOutput=false);
pp.TitleTop = "Multi-Frequency Array Pattern";
```

## Full Finite Array Analysis Template

```matlab
freq = <design_frequency>;
c = physconst("LightSpeed");
lambda = c / freq;

% --- Create array with element ---
arr = <arrayType>;
arr.NumElements = <N>;
arr = design(arr, freq, <elementType>);

% --- Geometry ---
figure; show(arr);
figure; layout(arr);

% --- Array factor (fast, no coupling) ---
figure; arrayFactor(arr, freq);

% --- Full-wave 3D pattern ---
figure; pattern(arr, freq);

% --- 2D azimuth cut with metrics ---
elCut = 0;
D = patternAzimuth(arr, freq, elCut);
az = -180:1:180;
figure;
pp = polarpattern(az, D);
pp.AntennaMetrics = true;
pp.TitleTop = sprintf("Array Azimuth Pattern (Elevation = %g°) at %.2f GHz", elCut, freq/1e9);

% --- S-parameters ---
bw = 0.2 * freq;
hasSubstrate = isprop(arr.Element, "Substrate") && ~isempty(arr.Element.Substrate);
if hasSubstrate
    freqRange = linspace(freq - bw/2, freq + bw/2, 51);
    try
        s = sparameters(arr, freqRange, SweepOption="interp");
    catch
        s = sparameters(arr, freqRange);
    end
else
    freqRange = linspace(freq - bw/2, freq + bw/2, 21);
    s = sparameters(arr, freqRange);
end
figure; rfplot(s);

% --- Key metrics ---
[peakVal, peakAz, peakEl] = peakRadiation(arr, freq);
fprintf("Peak directivity: %.2f dBi at Az=%.1f°, El=%.1f°\n", peakVal, peakAz, peakEl);
```

## Full Infinite Array Analysis Template

```matlab
freq = <design_frequency>;
c = physconst("LightSpeed");
lambda = c / freq;

% --- Create infinite array ---
infa = design(infiniteArray, freq, <elementType>);

% --- Mesh (only for non-Air substrate elements) ---
if ~strcmp(infa.Substrate.Name, "Air")
    mesh(infa, MaxEdgeLength=lambda/8);
end

% --- Show unit cell ---
figure; show(infa);

% --- Report unit cell size ---
fprintf("Unit cell: %.4f x %.4f m (%.2f x %.2f lambda)\n", ...
    infa.Element.GroundPlaneLength, infa.Element.GroundPlaneWidth, ...
    infa.Element.GroundPlaneLength/lambda, infa.Element.GroundPlaneWidth/lambda);

% --- Broadside scan impedance vs. frequency ---
infa.ScanElevation = 90;
bw = 0.2 * freq;
freqRange = linspace(freq - bw/2, freq + bw/2, 51);
figure; impedance(infa, freqRange);

% --- S-parameters ---
hasSubstrate = isprop(infa.Element, "Substrate") && ~isempty(infa.Element.Substrate);
if hasSubstrate
    try
        s = sparameters(infa, freqRange, SweepOption="interp");
    catch
        s = sparameters(infa, freqRange);
    end
else
    s = sparameters(infa, freqRange);
end
figure; rfplot(s);

% --- 3D scan element pattern ---
figure; pattern(infa, freq);

% --- Scan impedance vs. angle ---
scanEls = 90:-5:10;
zScan = zeros(size(scanEls));
for i = 1:numel(scanEls)
    infa.ScanElevation = scanEls(i);
    zScan(i) = impedance(infa, freq);
end

thetaScan = 90 - scanEls;
figure;
yyaxis left; plot(thetaScan, real(zScan), "-o", LineWidth=1.5); ylabel("Resistance (\Omega)");
yyaxis right; plot(thetaScan, imag(zScan), "-s", LineWidth=1.5); ylabel("Reactance (\Omega)");
xlabel("Scan Angle from Broadside (deg)"); grid on;
title(sprintf("Scan Impedance at %.2f GHz", freq/1e9));
legend("Resistance", "Reactance", Location="best");

% --- Key metrics ---
infa.ScanElevation = 90;
Z = impedance(infa, freq);
fprintf("Broadside impedance: %.2f + j%.2f ohm\n", real(Z), imag(Z));
```

## Return Loss vs. Scan Angle (Infinite Array)

```matlab
scanEls = 90:-5:10;
rl = zeros(size(scanEls));
for i = 1:numel(scanEls)
    infa.ScanElevation = scanEls(i);
    rl(i) = returnLoss(infa, freq);
end

thetaScan = 90 - scanEls;
figure;
plot(thetaScan, rl, "-o", LineWidth=1.5);
xlabel("Scan Angle from Broadside (deg)"); ylabel("Return Loss (dB)");
grid on; title(sprintf("Return Loss vs. Scan Angle at %.2f GHz", freq/1e9));
yline(10, "--r", "10 dB threshold");
```

----

Copyright 2026 The MathWorks, Inc.

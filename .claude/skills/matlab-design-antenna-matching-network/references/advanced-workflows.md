# Advanced Matching Network Workflows

## Bandwidth Tradeoff — 2-Element vs 3-Element

Side-by-side comparison to decide when the extra component is worth the added loss:

```matlab
freq = 2.4e9;
bw = 400e6;
ant = design(pifa, freq);
sAntLoad = sparameters(ant, linspace(freq - bw, freq + bw, 51));
freqRange = linspace(freq - bw, freq + bw, 201);

% 2-element design
mn2 = matchingnetwork;
mn2.CenterFrequency = freq;
mn2.Bandwidth = bw;
mn2.LoadImpedance = sAntLoad;
mn2.Components = 2;
addEvaluationParameter(mn2, 'gammain', '<', -10, [freq-bw/2 freq+bw/2], 1);

% 3-element design
mn3 = matchingnetwork;
mn3.CenterFrequency = freq;
mn3.Bandwidth = bw;
mn3.LoadImpedance = sAntLoad;
mn3.Components = 3;
addEvaluationParameter(mn3, 'gammain', '<', -10, [freq-bw/2 freq+bw/2], 1);

% Compare bandwidth performance
sAnt = sparameters(ant, freqRange);
gammaLoad = squeeze(sAnt.Parameters(1,1,:));

sMN2 = sparameters(mn2, freqRange);
S2 = sMN2.Parameters;
gammain2 = squeeze(S2(1,1,:)) + squeeze(S2(1,2,:)).*squeeze(S2(2,1,:)).*gammaLoad ./ ...
    (1 - squeeze(S2(2,2,:)).*gammaLoad);

sMN3 = sparameters(mn3, freqRange);
S3 = sMN3.Parameters;
gammain3 = squeeze(S3(1,1,:)) + squeeze(S3(1,2,:)).*squeeze(S3(2,1,:)).*gammaLoad ./ ...
    (1 - squeeze(S3(2,2,:)).*gammaLoad);

figure;
plot(freqRange/1e9, 20*log10(abs(gammaLoad)), 'k--', ...
     freqRange/1e9, 20*log10(abs(gammain2)), 'b-', ...
     freqRange/1e9, 20*log10(abs(gammain3)), 'r-', 'LineWidth', 1.5);
yline(-10, 'k:', 'LineWidth', 1);
xlabel("Frequency (GHz)"); ylabel("S_{11} (dB)");
legend("Unmatched", "2-Element", "3-Element", "-10 dB");
grid on;
title("Bandwidth Comparison: 2-Element vs 3-Element Matching");

% Print matched bandwidths
fprintf("2-element candidates: %d\n", height(circuitDescriptions(mn2)));
fprintf("3-element candidates: %d\n", height(circuitDescriptions(mn3)));
```

**Decision guide:**
- 2-element: simpler, less loss, sufficient for narrowband (BW < 5% of center)
- 3-element: wider bandwidth, more design freedom, but ~0.2-0.5 dB extra insertion loss

----

Copyright 2026 The MathWorks, Inc.

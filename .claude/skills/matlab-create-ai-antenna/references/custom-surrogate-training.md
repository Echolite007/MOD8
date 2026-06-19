# Training Custom Surrogate Models with fitrauto

For antennas **not** in the AIAntenna catalog (custom pcbStack designs, modified geometries), train your own surrogate model using `fitrauto` from the Statistics and Machine Learning Toolbox.

## When to Use

- Custom pcbStack geometries not covered by AIAntenna's 12 supported types
- Multi-parameter optimization where full-wave is too slow for sweeps
- Building a reusable model for a specific antenna family

## Complete Workflow

```matlab
%% 1. Define parameterized antenna (e.g., C-shaped patch)
function ant = buildAntenna(L, W, notchL, notchW, h, feedX)
    patch = antenna.Rectangle(Length=L, Width=W);
    notch = antenna.Rectangle(Length=notchL, Width=notchW, Center=[L/2-notchL/2, 0]);
    radiator = patch - notch;
    ground = antenna.Rectangle(Length=L*2, Width=W*2);
    sub = dielectric("FR4");

    ant = pcbStack;
    ant.BoardShape = ground;
    ant.BoardThickness = h;
    ant.Layers = {radiator, sub, ground};
    ant.FeedLocations = [feedX, 0, 1, 3];
    ant.FeedDiameter = 1e-3;
end

%% 2. Generate training data (parametric sweep)
N = 200;  % number of samples
params = lhsdesign(N, 4);  % Latin hypercube sampling
% Scale to physical ranges
Lvec = 0.02 + params(:,1) * 0.03;    % 20-50 mm
Wvec = 0.02 + params(:,2) * 0.03;
notchLvec = 0.005 + params(:,3) * 0.015;
notchWvec = 0.002 + params(:,4) * 0.008;

freqRange = linspace(1e9, 5e9, 101);
fRes = zeros(N, 1);

for k = 1:N
    ant = buildAntenna(Lvec(k), Wvec(k), notchLvec(k), notchWvec(k), 1.6e-3, Lvec(k)/4);
    s = sparameters(ant, freqRange);
    s11 = rfparam(s, 1, 1);
    [~, idx] = min(20*log10(abs(s11)));
    fRes(k) = freqRange(idx);
end

%% 3. Train surrogate with fitrauto
data = table(Lvec, Wvec, notchLvec, notchWvec, fRes);
[trainIdx, testIdx] = cvpartition(N, "HoldOut", 0.2);

opts = struct(MaxObjectiveEvaluations=50, ShowPlots=false);
mdl = fitrauto(data(training(trainIdx),:), "fRes", ...
    Learners=["gp", "svm", "net"], ...
    HyperparameterOptimizationOptions=opts);

%% 4. Predict (instant)
fPred = predict(mdl, data(test(testIdx), 1:4));
fActual = data.fRes(test(testIdx));
errPct = abs(fPred - fActual) ./ fActual * 100;
fprintf("Mean prediction error: %.2f%%\n", mean(errPct));
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `lhsdesign` | Latin hypercube sampling for design-of-experiments |
| `fitrauto` | Automated ML model selection and hyperparameter tuning |
| `predict` | Instant prediction from trained model |
| `cvpartition` | Train/test split |

## Notes

- Data generation is the bottleneck — each `sparameters` call takes seconds. Use `parfor` with Parallel Computing Toolbox.
- `fitrauto` tries multiple model types (GP, SVM, neural net) and selects the best via Bayesian optimization.
- The trained model can predict resonant frequency, bandwidth, or any scalar metric in milliseconds.
- Save the model with `save("myModel.mat", "mdl")` for reuse across sessions.

----

Copyright 2026 The MathWorks, Inc.

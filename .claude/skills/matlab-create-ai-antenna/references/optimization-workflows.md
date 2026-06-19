# Advanced AIAntenna Workflows: Full-Factorial Sweeps and Optimization

## Full-Factorial Parametric Sweep

Use `combinations()` to generate a full-factorial grid of parameter scaling factors, then sweep all tunable parameters simultaneously to identify optimal configurations.

### Pattern

```matlab
freq = 10e9;

% Define scaling factors (±15% around defaults)
a = 0.85:0.1:1.15;
kc = combinations(a, a, a, a, a);  % 4^5 = 1024 combinations for 4 levels
k = table2array(kc);
n = size(k, 1);

% Preallocate results
pg = zeros(n, 1);
bdw = zeros(n, 1);
bmwth = zeros(n, 1);
fres = zeros(n, 1);

for i = 1:n
    antAI = design(horn, freq, ForAI=true);

    % Scale tunable parameters
    antAI.Width       = antAI.Width * k(i,1);
    antAI.Height      = antAI.Height * k(i,2);
    antAI.FlareLength = antAI.FlareLength * k(i,3);
    antAI.FlareHeight = antAI.FlareHeight * k(i,4);
    antAI.FeedHeight  = antAI.FeedHeight * k(i,5);

    % Check matching status before computing resonant frequency
    [~, ~, ~, matching] = bandwidth(antAI);
    switch string(matching)
        case "Matched"
            fres(i) = resonantFrequency(antAI);
            [bdw(i), ~, ~, ~] = bandwidth(antAI);
        case {"Almost", "Not Matched"}
            fres(i) = NaN;
            bdw(i) = NaN;
    end
    pg(i) = peakRadiation(antAI, freq);
    [bm, ~, ~] = beamwidth(antAI, freq);
    bmwth(i) = bm(1);
end

% Collect results in table
results = table(fres, bdw, bmwth, pg);
```

### Filtering by Performance Criteria

```matlab
% Find designs meeting all specs
ifr = find(results.fres > 9.8e9 & results.fres < 10.2e9);  % ±2% of target
ibw = find(results.bdw > 3.8e9);
ipg = find(results.pg > 15.8);
ibmwth = find(results.bmwth > 20 & results.bmwth < 25);

% Intersection of all criteria
bestIdx = intersect(intersect(intersect(ifr, ibmwth), ibw), ipg);
```

### Key Points

- `combinations()` generates all parameter permutations as a table
- 1024 AI evaluations complete in ~120 seconds (vs. days with full-wave)
- Always check `bandwidth` matching status before trusting `resonantFrequency`
- Filter results post-sweep using logical indexing or `intersect`

## OptimizerTRSADEA Integration

`OptimizerTRSADEA` is a trust-region surrogate-assisted differential evolution optimizer that integrates directly with AIAntenna for fast multi-objective optimization.

### Setup

```matlab
freq = 10e9;
antAI = design(horn, freq, ForAI=true);

% Get default parameter values
defaults = defaultTunableParameters(antAI);
W = defaults.Width;
H = defaults.Height;
L = defaults.FlareLength;
Flh = defaults.FlareHeight;
Fdh = defaults.FeedHeight;

% Define bounds (2-by-N: [lower; upper])
Bounds = [0.85*W 0.85*H 0.85*L 0.85*Flh 0.85*Fdh;
          1.15*W 1.15*H 1.15*L 1.15*Flh 1.15*Fdh];

% Create optimizer
s = OptimizerTRSADEA(Bounds);

% Assign custom evaluation function
s.CustomEvaluationFunction = @customEval;

% Define linear geometric constraints (A*x <= b)
constraintsStructure.A = [0 -1 0 0 1];  % -Height + FeedHeight <= 0
constraintsStructure.b = 0;
s.GeometricConstraints = constraintsStructure;

% Enable logging
s.EnableLog(true);

% Run optimization (50 iterations, ~40 seconds with AI)
s.optimize(50);

% Retrieve best result
bestData = s.getBestMemberData;
fprintf("Best fitness: %.4f\n", bestData.fitness);
fprintf("Best params: W=%.4f H=%.4f L=%.4f Flh=%.4f Fdh=%.4f\n", ...
    bestData.member(1), bestData.member(2), bestData.member(3), ...
    bestData.member(4), bestData.member(5));
```

### Custom Evaluation Function Template

The fitness function receives a parameter vector and returns a scalar fitness value (lower is better for minimization):

```matlab
function fitness = customEval(var)
    freq = 10e9;
    antAI = design(horn, freq, ForAI=true);

    % Assign parameters from optimizer
    antAI.Width       = var(1);
    antAI.Height      = var(2);
    antAI.FlareLength = var(3);
    antAI.FlareHeight = var(4);
    antAI.FeedHeight  = var(5);

    try
        % Evaluate performance
        gain = peakRadiation(antAI, freq);
        fr = resonantFrequency(antAI);
        [bw, ~, ~, ~] = bandwidth(antAI);
        [bwth, ~, ~] = beamwidth(antAI, freq);
        if numel(bwth) > 1
            bwth = bwth(1);
        end

        % Weighted objectives (lower fitness = better)
        fitGain = -5 * gain;                      % maximize gain
        fitFreq = 100 * abs(fr - freq) / freq;    % minimize freq deviation
        fitBW   = -(bw / 1e8);                    % maximize bandwidth
        fitBmw  = bwth;                           % minimize beamwidth

        fitness = fitGain + fitFreq + fitBW + fitBmw;

        % Hard penalties for invalid designs
        if bw < 10e6 || gain < 0 || bwth < 10 || bwth > 180
            fitness = 1e6;
        end
    catch
        fitness = 1e6;  % penalty for failed evaluations
    end
end
```

### OptimizerTRSADEA Key Methods

| Method/Property | Purpose |
|-----------------|---------|
| `OptimizerTRSADEA(Bounds)` | Constructor with 2-by-N bounds matrix |
| `.CustomEvaluationFunction` | Function handle `@(var) scalar_fitness` |
| `.GeometricConstraints` | Struct with `.A` and `.b` for linear constraints A*x <= b |
| `.EnableLog(true)` | Enable iteration logging |
| `.optimize(N)` | Run N iterations |
| `.optimizeWithPlots(N)` | Run N iterations with live convergence plot |
| `.getBestMemberData` | Returns struct with `.member` (params) and `.fitness` |
| `.getIterationData` | Returns data for all iterations |
| `.showConvergenceTrend` | Plot fitness vs. iteration |
| `isConverged(s)` | Check if optimizer converged early |

### When to Use OptimizerTRSADEA vs. Full-Factorial

| Criterion | Full-Factorial | OptimizerTRSADEA |
|-----------|---------------|------------------|
| Design space | Small (3-5 levels per param) | Large (continuous bounds) |
| Objective | Explore sensitivities | Find global optimum |
| Parameters | ≤5 (combinatorial explosion) | Any number |
| Runtime | O(levels^params) | O(iterations) |
| Output | Pareto-like landscape | Single best design |

### Geometric Constraints

Linear constraints take the form `A * x <= b`:

```matlab
% Example: FeedHeight must be less than Height
% Variables: [Width, Height, FlareLength, FlareHeight, FeedHeight]
% -Height + FeedHeight <= 0  =>  [0, -1, 0, 0, 1] * x <= 0
constraintsStructure.A = [0 -1 0 0 1];
constraintsStructure.b = 0;
s.GeometricConstraints = constraintsStructure;
```

Multiple constraints: stack rows in `A` and entries in `b`.

----

Copyright 2026 The MathWorks, Inc.

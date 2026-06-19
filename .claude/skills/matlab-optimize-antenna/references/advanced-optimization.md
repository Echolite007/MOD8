# Advanced Optimization Techniques

This reference covers advanced patterns for antenna optimization using SADEA and TR-SADEA. Load this when the user needs custom objectives in Tier 1, penalty shaping, convergence diagnostics, AI-accelerated optimization, or operational features (resume, save, inspect history).

## Custom Objective Function in Tier 1

When built-in objective strings are insufficient (e.g., multi-frequency, dual-band, or custom combined metrics), pass a function handle as the objective. The function receives the **antenna object** (with updated design variable properties) and returns a scalar fitness. SADEA **minimizes** the return value -- negate metrics you want to maximize.

```matlab
% Custom objective: must be a named function in a separate .m file
function val = maximizeGainAtBoresight(obj)
    fc = 2.4e9;
    val = pattern(obj, fc, Azimuth=0, Elevation=0);
    val = -1 * val;    % negate to maximize
end
```

Unlike Tier 2 evaluation functions, `try/catch` is not required -- the optimizer handles invalid geometries internally. The function can also return a vector `[objective, constraint1, constraint2, ...]` when using the `Weights` parameter.

If the custom objective needs extra parameters (frequency, constraints struct, etc.), use an anonymous wrapper:

```matlab
customObj = @(y)myObjective(y, fc, Z0, constraints);
[optAnt, optinfo] = optimize(ant, fc, customObj, designVars, LBUB, Iterations=150);
```

Anonymous wrappers are allowed for custom objectives. The "must be a named function" rule applies only to `gc.nlcon` (nonlinear geometric constraints).

## Penalty Weight Selection

Constraint violations and objectives may have different magnitudes. First, apply scaling factors to normalize them to a similar range. Then assign penalty weights to prioritize constraints -- weights should sum to 100.

```matlab
% Normalize: gain ~5-10, S11 ~0-20 (similar scale, no factor needed)
% Bandwidth violation in Hz (~1e8) needs scaling down
bwScale = 1e-7;

% Weights sum to 100; higher = higher priority
wS11 = 70;    % S11 is critical
wBW  = 30;    % bandwidth is secondary

fitness = objective + wS11 * s11Violation + wBW * (bwScale * bwViolation);
```

## Conditional Penalty Shaping

For more nuanced control, use if/else logic to reward good performance more strongly than bad performance is penalized:

```matlab
% Strong reward when gain exceeds threshold, weak penalty when below
if gain < 15.5
    pen1 = -gain;        % weak: just negate gain
else
    pen1 = -5 * gain;    % strong: 5x multiplier rewards exceeding threshold
end

% No penalty when constraint is met, large penalty when violated
if deltaf > 0.002
    pen2 = 1e2 * deltaf;    % penalty scales with violation magnitude
else
    pen2 = 0;               % no penalty when within tolerance
end

fitness = pen1 + pen2 + pen3;
```

This is more expressive than the `max(violation, 0)` clamping pattern. Use it when you want the optimizer to strongly prefer designs that exceed a threshold.

## Alternative: Vector Output with `Weights` Property

Instead of combining objective and constraints into a scalar fitness, return them as a vector and let the optimizer handle weighting:

```matlab
function fitness = evaluateAntenna(x)
    % Return vector: [objective, constraint1, constraint2, ...]
    % Do NOT combine -- the optimizer applies Weights internally
    bwScale = 1e-7;
    fitness = [objective, s11Violation, bwScale * bwViolation];
end
```

Then set `Weights` on the optimizer object -- one weight per constraint (not for the objective). Weights should sum to 100:

```matlab
s = OptimizerSADEA(bounds);
s.CustomEvaluationFunction = @evaluateAntenna;
s.Weights = [70, 30];    % [s11Weight, bwWeight] -- sum to 100
```

The preferred pattern is scalar fitness with manual penalty (full control). Use vector output when you want the optimizer to manage weighting.

## Geometric Constraints in Custom Evaluation Workflow

Geometric constraints can also be applied directly on OptimizerSADEA/OptimizerTRSADEA:

```matlab
gc = initGeomConstraint;

% Linear inequality: A*x <= b
gc.A = [1, -3, 0];
gc.b = 0;

% Linear equality: Aeq*x = beq
gc.Aeq = [1, 1, 0];
gc.beq = 0.05;    % e.g., Length + Width = 0.05

s = OptimizerSADEA(bounds);
s.CustomEvaluationFunction = @evaluateAntenna;
s.GeometricConstraints = gc;
```

Nonlinear constraints (`gc.nlcon`, `gc.nrlv`) work the same way as in Tier 1.

## Validating and Timing the Setup

Before running a full optimization, use `validateSetup` to verify the evaluation function works and estimate total run time:

```matlab
s.validateSetup;    % runs one random point within bounds
```

This catches errors early. Multiply per-evaluation time by expected evaluations (see Iteration Guidelines in SKILL.md) to estimate total time.

If evaluations are slow (> 1 hour total), consider coarser meshing:

```matlab
c = physconst("LightSpeed");
lambda = c / freq;
mesh(ant, MaxEdgeLength=lambda/8);
```

## Resuming Optimization

Calling `optimize` or `optimizeWithPlots` with a number greater than completed iterations resumes from where it left off:

```matlab
s.optimizeWithPlots(50);    % runs 50 iterations
s.optimizeWithPlots(100);   % resumes from iteration 51
```

If optimization was abruptly terminated and resuming throws an error, use `performRestore`:

```matlab
s.performRestore;           % only if resume throws an error
s.optimizeWithPlots(100);   % resumes from last completed iteration
```

## Saving Optimizer State

The optimizer object is autosaved to prevent loss during long runs. You can also save manually:

```matlab
save("optimizer_state.mat", "s");

% Later, reload and continue:
load("optimizer_state.mat");
s.optimizeWithPlots(100);   % resumes from where it left off
```

## Post-Analysis: Inspecting Search History

Use `getInitializationData` and `getIterationData` to inspect all evaluated designs:

```matlab
initData = getInitializationData(s);   % initial Latin hypercube samples
iterData = getIterationData(s);        % optimization iteration samples

% Each struct has:
%   .members       -- design variable vectors
%   .performances  -- raw objective/constraint values
%   .fitness       -- combined fitness values
```

## Interpreting Convergence Status

After optimization, check both flags:

```matlab
fprintf("Converged: %d\n", s.isConverged);
fprintf("Evaluations exhausted: %d\n", s.isFunctionEvaluationsExhausted);
```

`isConverged` = true when fitness stagnates (no improvement for consecutive iterations). `isFunctionEvaluationsExhausted` = true when the cap from `setMaxFunctionEvaluations` is reached.

| `isConverged` | `isFunctionEvaluationsExhausted` | Meaning | Action |
|:---:|:---:|---------|--------|
| true | false | Stable optimum found | Proceed to validation |
| false | true | Hit evaluation cap | Increase with `setMaxFunctionEvaluations(s, higher)` and resume |
| false | false | Still improving | Resume: `s.optimizeWithPlots(moreIterations)` |

If result is unsatisfactory after convergence:
1. **Widen bounds** -- optimum may be at boundary
2. **Switch algorithms** -- TR-SADEA is faster per iteration; SADEA can be more accurate globally
3. **Revise evaluation function** -- adjust penalties, relax constraints

## AI-Accelerated Optimization

For faster exploration, use AI-surrogate antenna models instead of full EM simulations. Create with `design(ant, freq, ForAI=true)` -- evaluates orders of magnitude faster.

```matlab
ant = horn;
f = 10e9;
antAI = design(ant, f, ForAI=true);

% Get nominal dimensions from AI model
L = antAI.defaultTunableParameters.FlareLength;
W = antAI.defaultTunableParameters.Width;

% Set bounds (+/-15% is typical for AI models)
Bounds = [0.85*W 0.85*L; 1.15*W 1.15*L];
s = OptimizerTRSADEA(Bounds);
s.CustomEvaluationFunction = @myAIEval;
s.optimize(100);
```

The AI model supports fast analysis functions: `peakRadiation`, `resonantFrequency`, `bandwidth`, `beamwidth`. Use these instead of `pattern`/`sparameters` inside the evaluation function.

**After optimization, always validate with full EM:**

```matlab
bestVars = s.getBestMemberData.member;
antAI.Width = bestVars(1);
antAI.FlareLength = bestVars(2);

% Convert AI model to full EM antenna for validation
antEM = exportAntenna(antAI);
pattern(antEM, f);
sparameters(antEM, linspace(0.8*f, 1.2*f, 51));
```

Use this approach when evaluation speed is critical (many design variables, fast iteration cycles). The AI model is an approximation -- EM validation is mandatory.

## Uniform-Bounded Vector Properties (Tier 1)

When a property is a vector with all elements sharing the same bounds (e.g., `DirectorLength = [d1, d2, d3, d4]`), use a single scalar bounds pair -- it applies uniformly to all elements:

```matlab
% DirectorLength has 4 elements, all bounded [0.35*lambda, 0.5*lambda]
optimize(ant, freq, "maximizeGain", ...
    {'ReflectorLength', 'DirectorLength'}, ...
    {0.4*lambda, 0.35*lambda; 0.6*lambda, 0.5*lambda}, ...
    Iterations=150);
```

## Multi-Port S-Parameter Constraint

For arrays with multiple feed ports, check return loss on all ports and use the worst case:

```matlab
% Inside evaluation function
sParams = sparameters(ant, freqRange);
RetLoss1 = 20*log10(max(abs(rfparam(sParams, 1, 1))));
RetLoss2 = 20*log10(max(abs(rfparam(sParams, 2, 2))));
worstRetLoss = max([RetLoss1, RetLoss2]);
constraint = max(worstRetLoss - (-10), 0);    % zero if all ports < -10 dB
```

----

Copyright 2026 The MathWorks, Inc.

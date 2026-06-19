# measuredAntenna Workflow Templates

Complete code templates for creating `measuredAntenna` objects from simulated antennas. Each template is self-contained and ready to run -- adjust the source antenna, frequency, and grid resolution to your requirements.

## 1. Single-Element E-Field (Multi-Frequency)

Captures the full E-field from a catalog antenna at multiple frequencies. Use when you need to preserve field data for downstream analysis (near-field, SAR, custom processing).

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;
ant = design(patchMicrostrip, f0);

% --- Spherical grid (az-fast ordering) ---
az = -180:5:180;
el = -90:5:90;
R = 100 * lambda;

[phi, elv] = meshgrid(az, el);
phi = phi';    % Transpose for az-fast
elv = elv';
numPoints = numel(phi);

[x, y, z] = sph2cart(deg2rad(phi(:)), deg2rad(elv(:)), R);
points = [x, y, z].';     % 3-by-P for EHfields

Direction = [phi(:) elv(:) R*ones(numPoints, 1)];  % P-by-3

% --- Extract E-field at each frequency ---
fieldFreqs = [2.2e9, 2.4e9, 2.6e9];
numFreqs = numel(fieldFreqs);

E_data = zeros(numPoints, 3, numFreqs);
for k = 1:numFreqs
    [e, ~] = EHfields(ant, fieldFreqs(k), points);
    E_data(:, :, k) = e.';  % Transpose 3-by-P to P-by-3
end

% --- S-parameters ---
sParams = sparameters(ant, fieldFreqs);

% --- Build measuredAntenna ---
mAnt = measuredAntenna( ...
    E = E_data, ...
    Direction = Direction, ...
    FieldFrequency = fieldFreqs(:), ...
    FieldCoordinate = "rectangular", ...
    Azimuth = az, ...
    Elevation = el, ...
    Sparameters = sParams);

% --- Verify ---
figure; pattern(ant, f0, "Type", "efield");
figure; pattern(mAnt, f0);
```

**Design notes:**
- `E` is P-by-3-by-F where F is the number of frequencies. Single-frequency: P-by-3.
- `FieldCoordinate = "rectangular"` means Ex/Ey/Ez components, not the Direction format.
- `Sparameters` is optional but enables impedance and return loss queries on the measuredAntenna.
- Grid resolution (5-degree here) trades accuracy for speed. Use 1-degree for publication quality.

## 2. Directivity-Only for RF Site Planning (txsite/rxsite)

Creates a `measuredAntenna` with directivity data only. Required by `txsite` and `rxsite` -- these functions reject objects with non-empty `E`.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;
ant = design(patchMicrostrip, f0);

% --- Spherical grid (az-fast ordering) ---
az = -180:5:180;
el = -90:5:90;
R = 100 * lambda;

[phi, elv] = meshgrid(az, el);
phi = phi';
elv = elv';
numPoints = numel(phi);

Direction = [phi(:) elv(:) R*ones(numPoints, 1)];

% --- Extract directivity at each frequency ---
fieldFreqs = [2.2e9, 2.4e9, 2.6e9];
numFreqs = numel(fieldFreqs);

D_data = zeros(numPoints, numFreqs);
for k = 1:numFreqs
    [pat, ~, ~] = pattern(ant, fieldFreqs(k), az, el, Type="directivity");
    pat1 = pat';            % Transpose el-by-az to az-by-el
    D_data(:, k) = pat1(:);  % Flatten az-fast
end

% --- Build measuredAntenna ---
mAntSite = measuredAntenna( ...
    E = [], ...
    Directivity = D_data, ...
    Direction = Direction, ...
    FieldFrequency = fieldFreqs(:), ...
    Azimuth = az, ...
    Elevation = el);

% --- Use with txsite/rxsite ---
tx = txsite( ...
    Name = "Patch TX", ...
    Antenna = mAntSite, ...
    AntennaHeight = 30, ...
    TransmitterFrequency = f0, ...
    TransmitterPower = 10);

rx = rxsite( ...
    Name = "Receiver", ...
    Latitude = 42.30, Longitude = -71.35, ...
    AntennaHeight = 1.5, ...
    ReceiverSensitivity = -90);

ss = sigstrength(rx, tx);
fprintf("Signal strength: %.1f dBm\n", ss);

coverage(tx, SignalStrengths=[-60 -70 -80 -90], MaxRange=5000);
```

**Design notes:**
- `E = []` must be set explicitly -- `txsite` errors if E-field data is present.
- `Directivity` is P-by-F in dBi (one column per frequency).
- `pattern()` returns el-by-az. Always transpose then flatten: `pat'` then `(:)`.
- No `Sparameters` needed for site planning -- `txsite`/`rxsite` only use the directivity pattern.
- `coverage` requires Antenna Toolbox and Communications Toolbox (or Propagation Toolbox).

## 3. Tilted Antenna for Satellite Communication

Tilts the antenna beam toward zenith for ground-to-satellite uplink, creates a Directivity-only `measuredAntenna`, and integrates it into a satellite scenario with gimbal tracking.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Tilted antenna (beam toward zenith) ---
antTilted = design(patchMicrostrip, f0);
antTilted.Tilt = 90;
antTilted.TiltAxis = [0 1 0];

% --- Spherical grid (az-fast ordering) ---
az = -180:5:180;
el = -90:5:90;
R = 100 * lambda;

[phi, elv] = meshgrid(az, el);
phi = phi';
elv = elv';
numPoints = numel(phi);

Direction = [phi(:) elv(:) R*ones(numPoints, 1)];

% --- Extract directivity ---
fieldFreqs = [2.2e9, 2.4e9, 2.6e9];
numFreqs = numel(fieldFreqs);

D_data = zeros(numPoints, numFreqs);
for k = 1:numFreqs
    [pat, ~, ~] = pattern(antTilted, fieldFreqs(k), az, el, Type="directivity");
    pat1 = pat';
    D_data(:, k) = pat1(:);
end

mAntSat = measuredAntenna( ...
    E = [], ...
    Directivity = D_data, ...
    Direction = Direction, ...
    FieldFrequency = fieldFreqs(:), ...
    Azimuth = az, ...
    Elevation = el);

% --- Satellite scenario ---
startTime = datetime(2025, 1, 1, 0, 0, 0);
stopTime = startTime + hours(6);
sampleTime = 60;

sc = satelliteScenario(startTime, stopTime, sampleTime);

% LEO satellite (ISS-like orbit)
semiMajorAxis = 6778e3;      % ~400 km altitude
eccentricity = 0.0;
inclination = 51.6;
RAAN = 0;
argPeriapsis = 0;
trueAnomaly = 0;
sat = satellite(sc, semiMajorAxis, eccentricity, inclination, ...
    RAAN, argPeriapsis, trueAnomaly);

% Ground station
gs = groundStation(sc, 42.36, -71.06, MaskElevationAngle=10);

% --- Gimbal on ground station to track satellite ---
gimGS = gimbal(gs);
pointAt(gimGS, sat);

gsTx = transmitter(gimGS, ...
    Antenna = mAntSat, ...
    Frequency = f0, ...
    Power = 100, ...
    BitRate = 1, ...
    SystemLoss = 3);

% --- Gimbal on satellite pointing at ground station ---
gimSat = gimbal(sat);
pointAt(gimSat, gs);
satRx = receiver(gimSat, SystemLoss=3, RequiredEbNo=5);
gaussianAntenna(satRx, DishDiameter=0.5);

% --- Link budget ---
lnk = link(gsTx, satRx);
lnkIntervals = linkIntervals(lnk);
disp(lnkIntervals);
```

**Design notes:**
- `Tilt=90` with `TiltAxis=[0 1 0]` rotates beam from broadside (+z) to zenith (+x).
- Always mount the transmitter on a `gimbal`, not directly on the ground station -- `pointAt` only works on gimbals.
- Both ground station and satellite need gimbals for proper beam tracking.
- `gaussianAntenna` on the satellite receiver provides a simple dish model without needing another `measuredAntenna`.
- Requires Satellite Communications Toolbox (or Aerospace Toolbox with satellite scenario support).

## 4. Array with EmbeddedE for Beam Steering

Extracts per-element embedded E-fields from a finite array, building a `measuredAntenna` that supports `PhaseShift` and `AmplitudeTaper` for beam steering.

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Source array ---
arr = linearArray( ...
    Element = design(patchMicrostrip, f0), ...
    NumElements = 4, ...
    ElementSpacing = lambda/2);

% --- Spherical grid (az-fast ordering) ---
az = -180:5:180;
el = -90:5:90;
R = 100 * lambda;

[phi, elv] = meshgrid(az, el);
phi = phi';
elv = elv';
numPoints = numel(phi);

[x, y, z] = sph2cart(deg2rad(phi(:)), deg2rad(elv(:)), R);
points = [x, y, z].';

Direction = [phi(:) elv(:) R*ones(numPoints, 1)];

% --- Extract embedded E-field per element ---
fieldFreqs = [2.2e9, 2.4e9, 2.6e9];
numFreqs = numel(fieldFreqs);
numElements = arr.NumElements;

sParamsArr = sparameters(arr, fieldFreqs);

EmbE = zeros(numPoints, 3, numElements, numFreqs);
for k = 1:numFreqs
    for n = 1:numElements
        [e, ~] = EHfields(arr, fieldFreqs(k), points, ElementNumber=n);
        EmbE(:, :, n, k) = e.';
    end
end

% --- Build measuredAntenna ---
mAntArray = measuredAntenna( ...
    E = [], ...
    EmbeddedE = EmbE, ...
    Direction = Direction, ...
    NumPorts = numElements, ...
    FieldFrequency = fieldFreqs(:), ...
    FieldCoordinate = "rectangular", ...
    Azimuth = az, ...
    Elevation = el, ...
    Sparameters = sParamsArr, ...
    CalculateTotalField = true);

% --- Beam steering ---
steerAz = 30;
ps = phaseShift(arr, f0, [steerAz, 0]);
mAntArray.PhaseShift = ps;
figure; pattern(mAntArray, f0);

% --- Amplitude tapering (optional) ---
mAntArray.AmplitudeTaper = [0.5 1.0 1.0 0.5];
figure; pattern(mAntArray, f0);

% --- Verify total pattern ---
figure; pattern(arr, f0, "Type", "efield");
figure; pattern(mAntArray, f0);

% --- Verify per-element embedded pattern ---
figure; pattern(arr, f0, az, el, ElementNumber=1, Type="efield");
figure; pattern(mAntArray, f0, az, el, ElementNumber=1);
```

**Design notes:**
- `EmbeddedE` is P-by-3-by-N-by-F (N = number of elements, F = number of frequencies).
- `E = []` must be set explicitly when using `EmbeddedE`.
- `CalculateTotalField = true` is required to sum element contributions in `pattern()`.
- `PhaseShift` and `AmplitudeTaper` are 1-by-N vectors (one value per element).
- Use `phaseShift(originalArray, freq, [az, el])` to compute the progressive phase vector -- do not compute manually.
- EmbeddedE extraction is O(numElements x numFreqs x numPoints) -- warn the user for arrays with more than 8 elements.

## 5. measuredAntenna as Element in Array (patternMultiply)

Creates a `measuredAntenna` from a single element's E-field, then assigns it as the `Element` of a larger array. Uses `patternMultiply` for the combined pattern.

```matlab
f0 = 3e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;

% --- Single element ---
ant = design(patchMicrostrip, f0);

% --- Spherical grid (az-fast ordering) ---
az = -180:5:180;
el = -90:5:90;
R = 100 * lambda;

[phi, elv] = meshgrid(az, el);
phi = phi';
elv = elv';
numPoints = numel(phi);

[x, y, z] = sph2cart(deg2rad(phi(:)), deg2rad(elv(:)), R);
points = [x, y, z].';

Direction = [phi(:) elv(:) R*ones(numPoints, 1)];

% --- Extract single-frequency E-field ---
E0 = EHfields(ant, f0, points);

mesAnt = measuredAntenna( ...
    E = E0.', ...
    Direction = Direction, ...
    NumPorts = 1, ...
    Azimuth = az, ...
    Elevation = el, ...
    FieldCoordinate = "rectangular", ...
    FieldFrequency = f0);

% --- Assign as element in a rectangular array ---
rectArray = design(rectangularArray, f0, ant);
rectArrayMes = copy(rectArray);
rectArrayMes.Element = mesAnt;

% --- Compare using patternMultiply (NOT pattern) ---
figure; patternMultiply(rectArray, f0);
figure; patternMultiply(rectArrayMes, f0);

% --- 2D azimuth cut comparison ---
D_orig = patternMultiply(rectArray, f0, az, 0);
D_mes = patternMultiply(rectArrayMes, f0, az, 0);
figure;
polarpattern(az, [D_orig(:) D_mes(:)]);
```

**Design notes:**
- Single-frequency E-field: `E0` is 3-by-P from `EHfields`. Transpose to P-by-3.
- `NumPorts = 1` for a single-element measuredAntenna.
- Only `patternMultiply` works when `measuredAntenna` is the `Element` of an array. Calling `pattern` on such an array produces an error.
- `copy(rectArray)` creates an independent copy so the original is preserved for comparison.
- This workflow is useful when the element was measured externally (imported data) or comes from a different simulation tool.

## 6. Importing External Measured Data

When antenna data comes from a measurement system or external simulation (not from MATLAB Antenna Toolbox), construct the `measuredAntenna` directly from the data arrays.

```matlab
% --- Suppose you have measured data ---
% measuredAz: 1-by-Naz vector (degrees)
% measuredEl: 1-by-Nel vector (degrees)
% measuredE:  P-by-3 complex matrix (Ex, Ey, Ez at each point)
% measuredFreq: scalar or vector of frequencies (Hz)

% Example: load from a MAT file
data = load("antenna_chamber_data.mat");
measuredAz = data.azimuth;
measuredEl = data.elevation;
measuredE = data.efield;       % P-by-3 or P-by-3-by-F
measuredFreq = data.frequency;

% --- Build Direction matrix ---
R = data.measurementRadius;    % distance from antenna to probe (meters)
[phi, elv] = meshgrid(measuredAz, measuredEl);
phi = phi';    % Transpose for az-fast
elv = elv';
Direction = [phi(:) elv(:) R*ones(numel(phi), 1)];

% --- Build measuredAntenna ---
mAnt = measuredAntenna( ...
    E = measuredE, ...
    Direction = Direction, ...
    FieldFrequency = measuredFreq(:), ...
    FieldCoordinate = "rectangular", ...
    Azimuth = measuredAz, ...
    Elevation = measuredEl);

% --- Verify ---
figure; pattern(mAnt, measuredFreq(1));
```

**Design notes:**
- External data must already be in azimuth-fast order. If your measurement sweeps elevation first, transpose the data before flattening.
- `FieldCoordinate = "rectangular"` expects Ex/Ey/Ez. If your data is in spherical (Etheta, Ephi), you must convert to rectangular first.
- If only directivity is available (no E-field), use `Directivity` instead of `E` and set `E = []`.
- Measurement radius `R` must match the actual probe distance -- it affects the E-field magnitude scaling.
- If S-parameters were measured separately, create an `sparameters` object and pass it via the `Sparameters` property.

## 7. Importing from External EM Tools with ffsReader (R2026a+)

`ffsReader` imports Far-Field Source (.ffs) files — the native export format from CST Studio Suite — and returns a `measuredAntenna` directly. No manual grid setup or data ordering required.

**Syntax:** `mAnt = ffsReader(filename)`

```matlab
% Basic import — single .ffs file
mAnt = ffsReader("antenna_pattern.ffs");

% Verify
figure;
pattern(mAnt, mAnt.FieldFrequency(1));
```

### Selective Import (Multi-Port / Multi-Frequency)

```matlab
% Import only specific ports and frequencies
mAnt = ffsReader("array_element.ffs", ...
    PortList = [1 2], ...
    FrequencyList = [2.4e9, 2.5e9]);
```

### Adding S-Parameters from Touchstone File

```matlab
% Import field data + S-parameters from separate files
mAnt = ffsReader("antenna.ffs", SparametersFile = "antenna.s1p");

% Now impedance/return loss queries work
figure;
impedance(mAnt, linspace(2e9, 3e9, 101));
```

### Scaling E-Fields with scaleEField

`scaleEField` normalizes the E-field data in a `measuredAntenna` so that the radiated power matches the accepted power derived from S-parameters. Use after importing when field magnitudes seem inconsistent with S-parameter data.

```matlab
mAnt = ffsReader("antenna.ffs", SparametersFile = "antenna.s1p");
mAntScaled = scaleEField(mAnt);

figure;
pattern(mAntScaled, mAntScaled.FieldFrequency(1));
```

### Using ffsReader Output with txsite

`ffsReader` returns a `measuredAntenna` with E-field data populated. For `txsite`/`rxsite`, you still need Directivity with `E = []`:

```matlab
mAnt = ffsReader("antenna.ffs");
freq = mAnt.FieldFrequency(1);

% Extract directivity from the imported measuredAntenna
az = mAnt.Azimuth;
el = mAnt.Elevation;
[pat, ~, ~] = pattern(mAnt, freq, az, el);

% Build directivity-only version for txsite
[phi_d, elv_d] = meshgrid(az, el);
phi_d = phi_d';   % Transpose for az-fast
elv_d = elv_d';
numPoints = numel(phi_d);
R = 100;
Direction = [phi_d(:) elv_d(:) R*ones(numPoints, 1)];
D = pat'; D = D(:);  % az-fast Directivity

mAntSite = measuredAntenna( ...
    E = [], ...
    Directivity = D, ...
    Direction = Direction, ...
    FieldFrequency = freq, ...
    Azimuth = az, ...
    Elevation = el);

tx = txsite(Antenna=mAntSite, TransmitterFrequency=freq, ...
    TransmitterPower=10, AntennaHeight=30);
coverage(tx, SignalStrengths=[-60 -70 -80 -90], MaxRange=5000);
```

### Importing HFSS .ffd Files (Manual Workflow)

HFSS exports far-field data in `.ffd` format. There is no built-in `ffdReader` — use a helper function to parse the file. See the example `openExample("antenna/VisualizeRadiationPatternDataFromFFDFileExample")` for the complete `loadData` helper.

```matlab
% Parse .ffd file (use loadData helper from the MATLAB example)
fileName = "antenna_data.ffd";
coordinateSystem = "Phi-Theta";
[theta1, phi1, numFreqs, Etheta, Ephi, freqs] = loadData(fileName, coordinateSystem);

% Convert theta to elevation
elev = 90 - theta1;

% Build E-field array: [Ephi, Etheta, Er] in polar coordinates
numPt = numel(theta1) * numel(phi1);
ESph = [Ephi; Etheta; zeros(numPt, numFreqs)];
eField = reshape(ESph, numPt, 3, numFreqs);

% Build Direction (meshgrid default, no transpose)
lambda = physconst("LightSpeed") / max(freqs);
radius = 100 * lambda * ones(numPt, 1);
[theta, phi] = meshgrid(elev, phi1);
direction = [phi(:) theta(:) radius];

% Create measuredAntenna
mAnt = measuredAntenna(NumPorts=1);
mAnt.E = eField;
mAnt.Direction = direction;
mAnt.PhaseCenter = [0 0 0];
mAnt.FieldFrequency = freqs;
mAnt.Azimuth = phi1;
mAnt.Elevation = elev;
mAnt.FieldCoordinate = "polar";

% Verify
figure;
pattern(mAnt, freqs(1));
```

**Key points for .ffd import:**
- `FieldCoordinate = "polar"` because HFSS exports Etheta/Ephi (spherical components)
- E column order is `[Ephi, Etheta, Er]` — not `[Etheta, Ephi, Er]`
- Er is zero in the far field — fill with zeros
- The `loadData` helper parses the header for grid sizes and frequencies, then reads the complex E-field columns

**When to use which import method:**

| Source | Method | Built-in? |
|--------|--------|-----------|
| CST (.ffs files) | `ffsReader` (R2026a+) | Yes |
| HFSS (.ffd files) | Custom `loadData` helper | No — see example |
| Chamber measurements | Manual array construction (Section 6) | No |
| Raw directivity/gain | `measuredAntenna` with `Directivity` | N/A |

**Requirements:** `ffsReader` requires Antenna Toolbox R2026a or later. The .ffd workflow works in any release that supports `measuredAntenna`.

## 8. Visualizing Raw Data Before Building measuredAntenna

Use `patternCustom` and `fieldsCustom` to sanity-check raw pattern or field data before constructing a `measuredAntenna`. This helps catch data ordering issues, import errors, or unexpected nulls early.

### patternCustom — Scalar Magnitude Data

Plots a 3D radiation pattern from user-supplied magnitude data. Uses **spherical coordinates (theta, phi)**, not azimuth/elevation.

**Syntax — two calling conventions:**

1. **All vectors (same length):** `patternCustom(magE(:), theta(:), phi(:))`
   - `magE`: P-by-1 magnitude values (dB or linear)
   - `theta`: P-by-1 theta angles in degrees
   - `phi`: P-by-1 phi angles in degrees
   - All three must be the same length (flattened meshgrids)

2. **Matrix + vectors:** `patternCustom(magE_matrix, theta_vec, phi_vec)`
   - `magE_matrix`: Nphi-by-Ntheta matrix
   - `theta_vec`: 1-by-Ntheta vector
   - `phi_vec`: 1-by-Nphi vector

**Theta range:**
- `theta = 0:180` (true spherical) → full sphere (0° = z-axis/zenith, 90° = horizon, 180° = nadir)
- `theta = -90:90` (elevation-like) → upper hemisphere only (useful for ground-plane-backed antennas)

**Coordinate conversion:** Antenna Toolbox's `pattern()` uses azimuth/elevation, but `patternCustom` uses theta/phi. The relationship is:
- `theta = 90 - elevation`
- `phi = azimuth`

```matlab
f0 = 2.4e9;
ant = design(patchMicrostrip, f0);

% --- Convention 1: All vectors (flattened meshgrid) ---
theta = 0:5:180;
phi = -180:5:180;

% Extract directivity — pass phi as azimuth, 90-theta as elevation
[pat, ~, ~] = pattern(ant, f0, phi, 90-theta, Type="directivity");
% pat is Ntheta-by-Nphi

% Expand theta/phi to match pat size, then flatten all to column vectors
[phiGrid, thetaGrid] = meshgrid(phi, theta);

figure;
patternCustom(pat(:), thetaGrid(:), phiGrid(:));

% --- Convention 2: Matrix + vectors (simpler) ---
% Transpose pat to Nphi-by-Ntheta for matrix form
figure;
patternCustom(pat.', theta, phi);
```

**From az/el data (e.g., measuredAntenna directivity):**

```matlab
% If you already extracted directivity in az/el format
az = -180:5:180;
el = -90:5:90;
[pat_azel, ~, ~] = pattern(ant, f0, az, el, Type="directivity");
% pat_azel is Nel-by-Naz

% Convert: theta = 90 - el, phi = az
theta_vec = 90 - el;   % elevation to theta (will be 180:-5:0)
phi_vec = az;

% Matrix form: patternCustom wants Nphi-by-Ntheta
% pat_azel is Nel-by-Naz = Ntheta-by-Nphi, so transpose
figure;
patternCustom(pat_azel.', theta_vec, phi_vec);
```

**Common use cases:**
- Verify imported measurement data looks correct before wrapping in `measuredAntenna`
- Quick visual comparison when debugging data ordering issues
- Plot intermediate results during multi-step workflows
- Visualize raw gain/directivity from chamber measurements

### fieldsCustom — Complex E-Field Quiver Plot

Plots E-field (or H-field) vectors as a 3D quiver plot at specified Cartesian points. This is NOT a radiation pattern — it visualizes field arrows in space.

**Syntax:** `fieldsCustom(field, points)`
- `field`: 3-by-P complex matrix (Ex, Ey, Ez rows) — same format as `EHfields` output
- `points`: 3-by-P real matrix (x, y, z rows) — same format as `EHfields` input

```matlab
f0 = 2.4e9;
c0 = physconst("LightSpeed");
lambda = c0 / f0;
ant = design(patchMicrostrip, f0);

az = -180:10:180;
el = -90:10:90;
R = 100 * lambda;

[phi, elv] = meshgrid(az, el);
phi = phi'; elv = elv';
numPoints = numel(phi);

[x, y, z] = sph2cart(deg2rad(phi(:)), deg2rad(elv(:)), R);
points = [x, y, z].';  % 3-by-P

% Extract E-field (3-by-P)
[e, ~] = EHfields(ant, f0, points);

% Visualize E-field vectors in 3D space
figure;
fieldsCustom(e, points);

% Compare: build measuredAntenna and show pattern
Direction = [phi(:) elv(:) R*ones(numPoints, 1)];
mAnt = measuredAntenna( ...
    E = e.', ...
    Direction = Direction, ...
    FieldFrequency = f0, ...
    FieldCoordinate = "rectangular", ...
    Azimuth = az, ...
    Elevation = el);

figure;
pattern(mAnt, f0);
```

**Common use cases:**
- Visualize E-field polarization and direction at measurement points
- Inspect per-element embedded fields (EmbeddedE workflow) to confirm field orientation
- Debug field data from external tools before importing into `measuredAntenna`
- Visualize near-field probe measurements

### When to Use Which

| Goal | Function | Input Format |
|------|----------|--------------|
| 3D radiation pattern from scalar data | `patternCustom(magE, theta, phi)` | magnitude + spherical angles |
| E-field vector arrows in 3D space | `fieldsCustom(field, points)` | 3-by-P field + 3-by-P points |
| Pattern from `measuredAntenna` object | `pattern(mAnt, freq)` | object + frequency |

**Key difference:** `patternCustom` shows the radiation pattern shape (like `pattern`), while `fieldsCustom` shows field vector arrows at discrete points in space (like a quiver plot).

----

Copyright 2026 The MathWorks, Inc.

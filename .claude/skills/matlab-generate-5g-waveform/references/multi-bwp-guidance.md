# Multi-BWP Waveform Generation

Generate waveforms with multiple bandwidth parts at different numerologies.
This is the most complex configuration pattern because of interdependencies
between SCS carriers, BWPs, and channel allocations.

## Key Constraints

1. **Each BWP needs its own SCS carrier** at the matching subcarrier spacing
2. **Each BWP must fit within its SCS carrier** (see BWP containment rule)
3. **Channels in different BWPs must not overlap** in time-frequency resources
4. **BWP IDs must be unique** across all bandwidth parts
5. **CORESET is only needed in the BWP that carries PDCCH**

## Layout Strategy

SCS carriers can overlap in frequency (both `NStartGrid = 0`) or be separated
with `NStartGrid` offsets. Choose based on your use case:

- **Overlapping carriers** — simpler config, BWPs share the same frequency region
- **Offset carriers** — each BWP gets a dedicated frequency band

For offset layouts with two BWPs (e.g., 15 kHz and 30 kHz):

1. **Divide the channel bandwidth** between the two SCS carriers
2. **Offset the second carrier** using `NStartGrid`
3. **Size each BWP** to fit within its SCS carrier

When calculating offsets, remember that `NStartGrid` for the 30 kHz carrier
is in units of 30 kHz RBs. Two 15 kHz RBs occupy the same bandwidth as one
30 kHz RB.

## Example: 40 MHz, Two BWPs (15 kHz + 30 kHz)

```matlab
cfg = nrDLCarrierConfig;
cfg.ChannelBandwidth = 40;
cfg.FrequencyRange = 'FR1';
cfg.NCellID = 1;
cfg.NumSubframes = 10;

% SCS Carrier 1: 15 kHz, lower half
scsC1 = nrSCSCarrierConfig;
scsC1.SubcarrierSpacing = 15;
scsC1.NStartGrid = 0;
scsC1.NSizeGrid = 52;     % ~half of 40 MHz at 15 kHz (max 216)

% SCS Carrier 2: 30 kHz, upper half
scsC2 = nrSCSCarrierConfig;
scsC2.SubcarrierSpacing = 30;
scsC2.NStartGrid = 28;    % Offset so carriers occupy different frequency bands
scsC2.NSizeGrid = 38;

cfg.SCSCarriers = {scsC1, scsC2};

% BWP 1: uses 15 kHz SCS carrier
bwp1 = nrWavegenBWPConfig;
bwp1.BandwidthPartID = 1;
bwp1.SubcarrierSpacing = 15;
bwp1.NStartBWP = 0;
bwp1.NSizeBWP = 48;       % Fits within 52-RB carrier

% BWP 2: uses 30 kHz SCS carrier
bwp2 = nrWavegenBWPConfig;
bwp2.BandwidthPartID = 2;
bwp2.SubcarrierSpacing = 30;
bwp2.NStartBWP = 28;      % Matches carrier NStartGrid
bwp2.NSizeBWP = 34;       % Fits within 38-RB carrier

cfg.BandwidthParts = {bwp1, bwp2};

% CORESET on BWP 1 only — sized to fit
cfg.CORESET{1}.FrequencyResources = ones(1,4);  % 24 RBs
cfg.CORESET{1}.Duration = 2;
cfg.PDCCH{1}.BandwidthPartID = 1;

% PDSCH 1: BWP 1, starts after CORESET symbols
pdsch1 = nrWavegenPDSCHConfig;
pdsch1.BandwidthPartID = 1;
pdsch1.Modulation = '16QAM';
pdsch1.SymbolAllocation = [2 12];  % After 2-symbol CORESET
pdsch1.PRBSet = 0:47;
pdsch1.SlotAllocation = 0:4;

% PDSCH 2: BWP 2, full slot
pdsch2 = nrWavegenPDSCHConfig;
pdsch2.BandwidthPartID = 2;
pdsch2.Modulation = 'QPSK';
pdsch2.SymbolAllocation = [0 14];
pdsch2.PRBSet = 0:33;
pdsch2.SlotAllocation = 0:9;

cfg.PDSCH = {pdsch1, pdsch2};

% SSBurst on BWP 1 (15 kHz carrier has 52 RBs >= 20)
cfg.SSBurst.BlockPattern = 'Case A';

[waveform, info] = nrWaveformGenerator(cfg);
```

## Plotting Multiple BWP Resource Grids

```matlab
figure;
tiledlayout(2, 1);

nexttile;
imagesc(abs(info.ResourceGrids(1).ResourceGridBWP(:,:,1)));
axis xy;
xlabel('OFDM Symbols');
ylabel('Subcarriers');
title('BWP 1 — 15 kHz SCS');
colorbar;

nexttile;
imagesc(abs(info.ResourceGrids(2).ResourceGridBWP(:,:,1)));
axis xy;
xlabel('OFDM Symbols');
ylabel('Subcarriers');
title('BWP 2 — 30 kHz SCS');
colorbar;
```

## Avoiding Channel Conflicts

If `nrWaveformGenerator` reports conflicting channels (e.g., "PDCCH{1} and
PDSCH{2} are in conflict"), separate them by:

- **Time:** Use `SlotAllocation` to schedule channels in different slots
- **Frequency:** Use `PRBSet` to assign non-overlapping RBs
- **BWP:** Assign channels to different BWPs (which use different SCS carriers)

Remember: channels in different BWPs at different numerologies can still
conflict if their physical frequency ranges overlap.

Copyright 2026 The MathWorks, Inc.

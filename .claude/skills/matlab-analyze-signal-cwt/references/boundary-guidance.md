# Boundary Selection Guidance

## Decision Logic

### Check 1: Signal Size

For signals >100K samples, `"periodic"` boundary avoids ~2x FFT cost. Only valid if endpoints match.

### Check 2: Endpoint Similarity

Inspect first and last ~100 samples:

- **Endpoints match (value and trend):** `"periodic"` is valid and fastest
- **Endpoints differ but signal is stable at edges:** `"reflection"` (default)
- **Signal decays to zero at both ends:** `"zeropad"`

### Check 3: Local Stationarity at Edges

Even with `"reflection"`, check for abrupt transitions at boundaries:

- If the signal has a frequency discontinuity right at the edge (e.g., a tone shift), reflection mirrors that discontinuity creating an artificial high-low-low-high artifact
- If there is an oscillation at the boundary, reflection reverses the wave direction, "splitting" the sine wave (creating a cusp instead of a smooth continuation). In this case, `"periodic"` is best if endpoints match (wave continues seamlessly), otherwise `"zeropad"`.
- In general, if reflection would create an unnatural signal shape at the boundary, prefer `"zeropad"` or `"periodic"` (if valid)

## Why Performance Differs

The CWT computation is dominated by the inverse FFT of the product of the signal with each wavelet filter:

- **`"periodic"`:** FFT length = signal length (N). The DFT naturally assumes periodicity — circular convolution is inherent.
- **`"reflection"` or `"zeropad"`:** Signal is extended (approximately doubled) before transforming. FFT/IFFT operates on ~2N points.

For a 500K-sample signal, this is the difference between a 500K-point and a 1M-point FFT at every scale.

## Demonstration Script

Run `scripts/illustrateBoundary.m` to show the user all three boundary effects on a signal with a 100 Hz sine at the start and 400 Hz sine at the end. The plots show:

- **Periodic:** 400 Hz content wraps to the beginning, 100 Hz wraps to the end — cross-contamination
- **Reflection:** Oscillation at the boundary is reversed, "splitting" the sine wave — artificial cusp
- **Zeropad:** Cleanest result — no false continuity assumed

Use this when the user asks why a boundary matters or wants visual proof.

## Relationship to Cone of Influence

The boundary choice determines what the wavelet "sees" beyond the signal edges. The COI marks where this matters:

- A well-matched boundary (e.g., periodic for truly periodic data) makes COI coefficients more trustworthy
- A poorly matched boundary increases artifacts in the COI region
- No boundary method eliminates the COI — it is inherent to the finite-length analysis

----

Copyright 2026 The MathWorks, Inc.

----

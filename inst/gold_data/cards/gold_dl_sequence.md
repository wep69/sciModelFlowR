# Gold dataset card: `gold_dl_sequence`

**Purpose.** Frozen synthetic sequence fixture for recurrent, temporal-convolution and attention smoke tests.

**Generator seed:** `260916`. **Sequences:** 160. **Length:** 24.

Each sequence combines a 12-step periodic signal, random amplitude and phase, a small linear trend and Gaussian observation noise. Generator parameters are included solely for validation. The response `target` is a deterministic function of latent amplitude, phase and trend.

This dataset is simulated teaching/validation material, not empirical evidence.

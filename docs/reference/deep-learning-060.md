# Deep Learning and probabilistic Deep Learning interfaces

Package-native declarations and optional execution interfaces introduced
in version 0.6.0 for Deep Learning architectures, training, checkpoints,
probabilistic prediction, uncertainty, and gradient-based explanations.
Heavy backends remain optional and runtime certification is deferred to
the consolidated local validation campaign.

## Details

The API keeps scientific design, development-validation boundaries,
reproducibility metadata, and non-causal explanation semantics explicit.
Final or external test data must not drive early stopping or checkpoint
selection. Backend checkpoint deserialization is blocked unless trust is
explicitly declared.

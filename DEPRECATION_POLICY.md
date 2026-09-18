# sciModelFlowR Deprecation Policy

**API freeze:** 0.9.0

The 0.9.0 public API is the release-candidate contract for 1.0.0. Changes between 0.9.0 and 1.0.0 are restricted to critical scientific, numerical, security, installation, serialization, documentation, or release blockers discovered during the consolidated local validation campaign.

After 1.0.0, public 1.x functions and portable contracts should not be removed or semantically redefined without a documented deprecation period, a replacement or rationale, and a migration example. Portable serialized schemas require explicit migration logic. Backend-native escape-hatch objects are not stable serialization contracts and follow the lifecycle of their external backend.

Deprecation notices should distinguish syntax migration from scientific-semantic migration. A scientifically invalid historical behavior, such as leakage or test-set tuning, is not preserved merely for numerical backward compatibility.

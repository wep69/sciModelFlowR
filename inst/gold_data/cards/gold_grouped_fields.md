# gold_grouped_fields

## Scientific scenario

Synthetic observations nested within agricultural fields. Rows from the same field share a latent field effect. This dataset exists to test design declarations and to demonstrate why random row-wise validation can create optimistic performance when groups are split across training and testing.

## Experimental structure

`field` is the grouping unit. `obs_id` identifies individual plot observations within field. The latent field effect is shared by all plots from the same field.

## Validation target

A design-aware workflow must preserve the field declaration and should warn when a naive row-level holdout is used. Full group cross-validation is scheduled for version 0.2.0.

## Pedagogical trap

Rows are not exchangeable across fields merely because they are stored in one rectangular data frame.

## Frozen artifact

- Seed: `260915`
- Generator version: `0.1.0`
- SHA-256: `9a40d20dcb4fdf0f75ebc6c9377e326ec3e79314a3d44eb2f2f95b7ba7979418`
- This dataset is synthetic and is not empirical field evidence.

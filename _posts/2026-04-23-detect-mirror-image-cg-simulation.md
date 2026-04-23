---
layout: post
title: Detecting Mirror Images in Coarse-Grained Simulations
date: 2026-04-23 10:00:00-0400
description: A practical checklist to identify mirror-image structures in CG trajectories.
tags: coarse-grained-simulation protein-folding chirality analysis
categories: research-notes
giscus_comments: true
related_posts: false
---

In coarse-grained structure-based folding simulations, a protein can sometimes fold into a global mirror-image structure rather than the physically correct native fold. These mirror-image states are typically artifacts for an all-L polypeptide and should be removed from downstream analysis.

## Purpose

This workflow is designed to:

- Flag trajectories trapped in a global mirror-image basin
- Distinguish them from native-like and non-mirror misfolded trajectories
- Remove only global mirror-image artifacts

## Why mirror-image states appear in CG models

In many structure-based CG models:

- Native contact topology is preserved
- Global fold geometry is approximated
- Chirality is not strictly enforced

As a result, a mirrored fold can still be compact, stable, and even have high `Q`, despite being physically invalid for all-L proteins.

## Detection principle

A global mirror-image trajectory is expected to satisfy all of the following:

- Folded or near-folded (`Q` is high)
- Low agreement with native chirality (inverted handedness)
- Geometrically closer to reflected native than to native

So detection combines:

- `Q` (folded-state filter)
- Global chirality agreement score vs native
- `RMSD_native`
- `RMSD_reflected`

## Why `Q` alone is not enough

`Q` measures native-contact similarity but does not encode handedness. Therefore, mirror-image conformations can still show high `Q`.

## Recommended workflow

Use the same late-time window for all time-averaged quantities below (for example, last 10 ns).

### Step 1: Keep folded trajectories

For each trajectory, compute late-window mean `⟨Q⟩_last` and keep:

`⟨Q⟩_last > 0.6`

### Step 2: Compute global chirality agreement

Compute a scalar chirality agreement score against the native chirality structure:

- Larger values: better native handedness agreement
- Smaller values: mirror-like inversion

Threshold used here:

`chirality < 0.2`

### Step 3: Build reflected native reference

Reflect the native structure by flipping one coordinate axis (for example, `x -> -x`). One axis flip is sufficient because reflections differ only by rotation.

### Step 4: Compare RMSD to both references

Compute late-window means of:

- `RMSD_native` (rotation-only alignment to native)
- `RMSD_reflected` (rotation-only alignment to reflected native)

Important: use proper rotations only (`det = +1`). Reflection should enter through the reflected reference structure, not through allowing improper alignment transforms.

## Final classification rule

Classify trajectory as mirror-image artifact if and only if:

`(⟨Q⟩_last > 0.6) and (chirality < 0.2) and (RMSD_reflected < RMSD_native)`

This three-way AND is important to reduce false positives from any single metric.

## Optional refinement

Define:

`mirror_score = RMSD_reflected / RMSD_native`

and add a stricter cutoff such as:

`mirror_score < 0.8`

to remove borderline cases.

## What this intentionally keeps

- Unfolded trajectories (`⟨Q⟩_last <= 0.6`)
- Local chirality defects (not global inversion)
- Near-native misfolded states closer to native than reflected native

These classes can still contain meaningful physics and should remain available for analysis.

## Summary

Mirror-image folds can look folded in CG simulations, so filtering should not rely on `Q` alone. A robust practical filter is the joint rule:

`(⟨Q⟩_last > 0.6) and (chirality < 0.2) and (RMSD_reflected < RMSD_native)`

This removes global mirror artifacts while preserving informative non-mirror misfolded states.

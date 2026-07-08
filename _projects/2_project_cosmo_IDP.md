---
layout: page
title: COSMO for IDP simulations
description: An OpenMM-based package for coarse-grained simulations of intrinsically disordered proteins
img: assets/img/publication_preview/NCLE_IDP.png
importance: 2
category: fun
---

{% include figure.liquid loading="eager" path="assets/img/publication_preview/NCLE_IDP.png" title="COSMO coarse-grained IDP simulations" class="img-fluid rounded z-depth-1" caption="COSMO supports coarse-grained simulations of intrinsically disordered proteins and related biomolecular systems." %}

**COSMO** (*COarse-grained Simulation of intrinsically disordered prOteins*) is a Python library and command-line toolkit for coarse-grained molecular dynamics of intrinsically disordered proteins (IDPs) and related biomolecules such as RNA and DNA, built on [OpenMM](https://openmm.org/). From a sequence, it builds a one-bead-per-residue, sequence-based model and runs Langevin dynamics — interactions come from the sequence, not from a folded structure, so COSMO is built for disordered chains.

**The model**

- One bead per residue, built directly from the sequence (a CA/P PDB).
- Hydropathy-scale **HPS** (Ashbaugh–Hatch) or **Mpipi** (Wang–Frenkel) force field, plus Debye–Hückel electrostatics.
- Additional force fields can be added through the package parameter files.

**Workflow A — IDP simulation**

- Single-chain dimensions (radius of gyration) from a sequence.
- Periodic box with temperature and pressure coupling.
- Slab simulations of liquid–liquid phase separation (LLPS).
- Protein–RNA complexes and mixtures.
- Checkpoint restart, trajectory output, and final-structure export; CPU/GPU execution.

**Workflow B — Protein synthesis**

- Grow the nascent chain N→C, one residue at a time, timed by each mRNA codon (O'Brien Continuous Synthesis Protocol).
- `cosmo-cylinder` — fast analytic cylindrical exit tunnel (no explicit ribosome beads).
- `cosmo-csp` — growth through an explicit coarse-grained ribosome with codon-timed sub-stages.
- Per-codon dwell-time tables and ribosome preparation.

Code and documentation:

- [GitHub repository](https://github.com/vuqv/cosmo)
- [COSMO documentation](https://vuqv.github.io/cosmo/)

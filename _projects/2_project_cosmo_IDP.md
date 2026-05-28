---
layout: page
title: COSMO for IDP simulations
description: An OpenMM-based package for coarse-grained simulations of intrinsically disordered proteins
img: assets/img/publication_preview/NCLE_IDP.png
importance: 2
category: fun
---

{% include figure.liquid loading="eager" path="assets/img/publication_preview/NCLE_IDP.png" title="COSMO coarse-grained IDP simulations" class="img-fluid rounded z-depth-1" caption="COSMO supports coarse-grained simulations of intrinsically disordered proteins and related biomolecular systems." %}

[COSMO](https://github.com/vuqv/cosmo) is a Python package for coarse-grained molecular simulations of intrinsically disordered proteins (IDPs) and related biomolecules. The project was developed to make IDP simulations easier to set up, run, restart, and analyze using the OpenMM simulation engine.

The package implements several residue-level models commonly used for disordered proteins and biomolecular condensates, including HPS variants and Mpipi-style interactions. COSMO currently supports `hps_urry`, `hps_kr`, `hps_ss`, and `mpipi`, with model parameters organized so that additional force-field definitions can be added through the package parameter files.

At the workflow level, COSMO provides a high-level model builder for PDB/CIF structures, OpenMM force construction, control-file based simulation setup, CPU/GPU execution, checkpoint restart, trajectory output, and final structure export. These pieces are designed for practical simulation projects, where the same system may need to be equilibrated, extended, restarted, or run across many conditions on a cluster.

This software has been used in projects involving IDP conformational ensembles, phase-separation-related models, and coarse-grained studies of protein topology. The package also includes examples for standard single-chain simulations, periodic-box simulations, slab simulations, RNA/protein systems, and growing nascent-chain simulations.

Code and documentation:

- [GitHub repository](https://github.com/vuqv/cosmo)
- [COSMO documentation](https://vuqv.github.io/cosmo/)

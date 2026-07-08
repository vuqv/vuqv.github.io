---
layout: page
title: TOPO for folded-protein simulations
description: An OpenMM-based package for topology-based coarse-grained simulations of folded proteins
img: assets/img/publication_preview/topo_folded.gif
importance: 4
category: fun
github: https://github.com/vuqv/topo
---

<div class="row justify-content-center">
    <div class="col-sm-6 mt-3 mt-md-0">
        {% include figure.liquid loading="eager" path="assets/img/publication_preview/topo_folded.gif" title="TOPO coarse-grained folded-protein model" class="img-fluid rounded z-depth-1" caption="TOPO builds a one-bead-per-residue, structure-based (Gō-like) model from a folded-protein structure for coarse-grained molecular dynamics." %}
    </div>
</div>

**TOPO** (*TOPOlogy-based coarse-grained model for folded prOteins*) is a Python library and command-line toolkit for coarse-grained molecular dynamics of globular (folded) proteins, built on the [OpenMM](https://openmm.org/) engine. From a single PDB/CIF structure, it automatically builds a one-bead-per-residue (Cα) structure-based (Gō-like) model where the native fold is the energy minimum — ideal for studying folding, unfolding, thermal and mechanical stability, and multidomain motions.

**The model**

- One bead per residue (alpha-carbon), carrying its amino-acid mass, charge, and radius.
- Bonded terms: rigid/harmonic Cα–Cα bonds, a bimodal backbone-angle potential (helical + extended basins), and sequence-dependent torsions.
- Non-bonded terms: Debye–Hückel screened electrostatics plus a 12-10-6 Gō-type contact potential.
- Native contacts (from STRIDE H-bonds + heavy-atom proximity) get attractive wells at native distances; all other pairs get soft excluded-volume repulsion.
- Implicit solvent (no explicit water/box) and a large 15 fs time step via bond constraints.

**Key features**

- Single-domain quickstart: one `md.ini` control file, one structure, run and analyze.
- Multidomain proteins with per-domain and per-interface contact scaling via `domain.yaml` (including discontiguous domains).
- Automatic contact `nscale` optimization (`topo-optimize`) — finds the smallest scale that keeps each domain/interface folded.
- Temperature annealing and quenching to unfold then refold, with separate quench/production trajectories.
- Native-contact (*Q*) analysis to measure how folded the protein and each domain is, frame by frame.
- Checkpoint restart for long runs, and many copies in one GPU-filling simulation for independent trajectories.
- Co-translational protein synthesis (`topo.csp`) — grow the chain residue by residue under codon-resolved kinetics, either through an analytic cylinder tunnel (`topo-cylinder`) or on an explicit coarse-grained ribosome (`topo-csp`).
- CPU/GPU execution, command line (`topo-mdrun`) plus a Python API for scripting.

**Relationship to COSMO**

- Companion to COSMO (adapted from its code base): COSMO targets disordered proteins, TOPO targets folded ones.
- Both packages support co-translational protein synthesis with the same two exit-tunnel models (cylinder and coarse-grained ribosome).

Code and documentation:

- [GitHub repository](https://github.com/vuqv/topo)
- [TOPO documentation](https://vuqv.github.io/topo/main/index.html)

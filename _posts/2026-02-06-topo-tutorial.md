---
layout: post
title: "TOPO tutorial, Part A — simulating folded proteins"
date: 2026-02-06 15:09:00-0500
description: A hands-on walkthrough of TOPO's coarse-grained folded-protein workflow — from a single-domain quickstart to multidomain scaling, nscale optimization, and temperature annealing.
thumbnail: assets/img/publication_preview/topo_folded.gif
thumbnail_fit: contain
tags: topo coarse-grained molecular-dynamics protein-folding openmm structural-biology
categories: research-notes
giscus_comments: true
related_posts: false
---

`TOPO` (*TOPOlogy-based coarse-grained model for folded prOteins*) turns a folded-protein structure into a one-bead-per-residue, structure-based (Gō-like) model and runs it in [OpenMM](https://openmm.org/). Because the native structure you supply *defines* the energy minimum, TOPO is well suited to folding and unfolding, domain motions, and thermal or mechanical stability.

This is Part A of a two-part tutorial. It covers the folded-protein workflow — running a protein in isolation. [Part B]({% post_url 2026-07-07-topo-tutorial-translation %}) covers protein synthesis, where the chain grows on a ribosome and folds co-translationally. Work through Part A first; Part B builds on the same model. Everything here mirrors the [official TOPO tutorials](https://vuqv.github.io/topo/main/tutorials/index.html) (tutorials 1–6).

## The model in one minute

TOPO keeps only the alpha-carbon (Cα) of each residue, so a 106-residue protein becomes 106 beads. The force field combines:

- **Bonds, angles, torsions** — the CA-chain geometry. Bonds are rigid constraints by default, which allows a large 15 fs (`dt = 0.015`) timestep.
- **Yukawa electrostatics** — Debye–Hückel screened Coulomb between charged residues (ASP/GLU carry −1, ARG/LYS carry +1).
- **Structure-based contacts** — the heart of the model. Residue pairs in contact in your input structure get attractive wells at their native distances; every other pair gets soft excluded-volume repulsion.

The full functional forms and constants are documented in [The TOPO model: theory and force field](https://vuqv.github.io/topo/main/usage/model_theory.html).

## Prerequisites

- **Python** with **TOPO** and **OpenMM** installed, plus NumPy, ParmEd, MDAnalysis, mdtraj, pandas, and PyYAML.
- **STRIDE** on your `PATH` — TOPO calls it to detect backbone hydrogen bonds for the contact potential.
- **(Optional) a CUDA GPU** — the tutorials default to CPU so they run anywhere.

The dependencies install cleanly from `conda-forge`:

```bash
mamba create -n topo -c conda-forge python">=3.9" openmm parmed \
    mdanalysis mdtraj numpy pandas pyyaml
mamba activate topo
pip install -e .          # from the repo root
```

Confirm your environment:

```bash
python -c "import topo, openmm; print('OpenMM', openmm.__version__)"
which stride              # should print a path
```

If `stride_output_file` is not set, TOPO runs `stride -h` for you and caches the result next to the PDB as `<prefix>_stride.dat`. If STRIDE is not installed, precompute the file once (`stride -h protein.pdb > stride.dat`) and point `stride_output_file` at it.

## 1. The single-domain quickstart

The minimal workflow needs four files: an input structure, a `domain.yaml`, an `md.ini` config, and the runner script.

| File | Role |
| --- | --- |
| `P0CX28_clean.pdb` | Input structure (all-atom PDB; TOPO keeps only CA atoms). |
| `domain.yaml` | Defines the domain and its calibrated contact `nscale`. |
| `md.ini` | Simulation configuration (steps, temperature, I/O, hardware). |
| `run_simulation.py` | The runner (reads `md.ini`, builds the model, runs MD). |

The important lines in `md.ini`:

```ini
md_steps = 5000          # how long to run (short, for a demo)
ref_t = 300              # temperature in Kelvin
pbc = no                 # no periodic box (single protein, implicit solvent)
pdb_file = P0CX28_clean.pdb
domain_def = domain.yaml # single domain with the calibrated contact nscale
device = CPU             # switch to GPU if you have CUDA
minimize = no            # native structure is already the energy minimum
```

Run it:

```bash
python run_simulation.py -f md.ini
# equivalently:
topo-mdrun -f md.ini
python -m topo.mdrun -f md.ini
```

TOPO builds the model (prints the chain count, adds each force term, runs STRIDE, builds the contact matrices), steps the dynamics, and ends with `--- Finished in … seconds ---`. On a CPU this finishes in about two seconds.

### The nscale calibration parameter

Even for a single domain, `domain.yaml` carries an `nscale` — the global scale factor on the sidechain–sidechain contact energies. It is tuned so the model reproduces a target stability at 300 K. For `P0CX28` the calibrated value is **2.5044**; the raw unscaled value (1.0) would leave the protein only marginally folded. Tutorial 5 (below) shows how to find this value automatically.

### The outputs

Everything lands in the `traj/` run folder:

| File | What it is |
| --- | --- |
| `traj/traj.log` | Fixed-width energy/temperature log (one line every `nstlog` steps). |
| `traj/traj.dcd` | Trajectory — open with VMD or MDAnalysis. |
| `traj/traj.chk` | Binary checkpoint (positions + velocities) for restarting. |
| `traj/traj.psf` | Topology of the CA model, for loading the DCD in analysis tools. |
| `traj/traj_final.pdb` | Last conformation; reuse as `init_position` to seed a follow-up run. |
| `traj/traj_runinfo.log` | Run provenance: package versions, hardware, timing. |

A stable temperature near 300 K and a non-exploding potential energy mean the run is healthy:

```bash
head traj/traj.log
```

## 2. Multidomain proteins & per-domain scaling

In a structure-based model every native contact gets an attractive well, and by default all wells share the same relative strength. A multidomain protein often needs *different* stabilities per domain and per interface. `domain.yaml` sets a scale factor on the sidechain–sidechain contact energy **within** each domain (`intra_domains[...].nscale`) and **between** domains (`inter_domains`).

The instructive case is a **discontiguous domain**. Adenylate kinase (`1AKE` chain A, 214 residues) has a CORE domain made of two separate sequence segments — residues 1–117 and 166–214 — folding around an inserted NMP-binding domain (118–165). One domain can list multiple ranges:

```yaml
n_residues: 214
intra_domains:
  A:
    residues: [1-117, 166-214]   # ONE domain, TWO sequence segments
    nscale: 1.1556
  B:
    residues: [118-165]
    nscale: 1.6871
inter_domains:
  A-B: 1.8611
```

The only change needed in `md.ini` is the single line `domain_def = domain.yaml`, which switches on domain-aware scaling. A few rules worth remembering:

- Set `n_residues` to the true residue count; any residue you forget is auto-assigned to a fallback domain at `nscale` 1.0.
- Every domain needs a numeric `nscale` (a blank value errors).
- An unspecified interface defaults to 1.0 (native contacts kept, unscaled). To intentionally **decouple** two domains, set their pair to `0.0` explicitly.

## 3. Restarting a run

Long production runs restart cleanly from a checkpoint. Set `restart = yes` and point at the checkpoint, then set `md_steps` to the *total* desired step count — the remaining steps are computed from the checkpoint:

```ini
restart = yes
checkpoint = traj.chk
md_steps = 1000000       # total, not additional
```

When restarting, `minimize` is forced off, the run continues from the checkpoint step, and the log and trajectory are **appended** rather than overwritten.

## 4. Many copies in one run

A single CA chain of a few hundred beads barely uses a GPU. Set `n_copies > 1` to pack that many **independent, non-interacting** copies into one run and collect one trajectory per copy:

```ini
n_copies = 10          # independent chains in one simulation
copy_shift = 5.0       # nm, initial x-offset between copies
```

The copies never interact — the total potential energy is exactly `n_copies ×` the single-chain energy. After the run, split the combined trajectory into per-chain DCDs:

```bash
python split_chains.py -f md.ini
# or: python -m topo.utils.multichain -f combined.dcd -n 10 -o out/
```

## 5. Optimizing the contact nscale automatically

Choosing an `nscale` by hand is tedious and not reproducible, especially for a multidomain protein that needs a separate value per domain and per interface. The `topo-optimize` optimizer searches for the **smallest** `nscale`, drawn from a small discrete ladder, at which each domain and interface stays folded across many independent trajectories.

The algorithm, per round: write the current `nscale` values, run `ntraj` independent trajectories at 310 K (a multi-copy run), score the fraction of native contacts *Q* per frame for every domain and interface, then decide. A unit is *stable* when all `ntraj` trajectories keep its *Q* above **0.6688** for at least **98%** of frames. Any unit that fails climbs one ladder level while the stable ones freeze; the test repeats until everything is stable (or a median fallback is used after level 5).

Each domain declares its structural `class` (α, β, or α/β), which picks the ladder it climbs:

```yaml
n_residues: 139
intra_domains:
  A:
    residues: [1-90]
    class: beta            # alpha | beta | alpha-beta — selects the ladder
    nscale: 1.1556       # placeholder — overwritten each round
  B:
    residues: [91-139]
    class: alpha
    nscale: 1.6871
inter_domains:
  A-B: 1.8611              # placeholder too
```

Run it with a minimal `optimize.ini`:

```bash
topo-optimize -f optimize.ini -o opt_out
```

The result is `opt_out/domain_optimized.yaml` — a ready-to-use `domain.yaml`. Point a production run straight at it:

```ini
domain_def = domain_optimized.yaml
```

## 6. Temperature annealing & quenching

Instead of a single constant temperature, you can drive the run through a **temperature protocol**: hold the protein hot enough to unfold, then bring it back to `ref_t` to watch it refold. Turn it on with `anneal = yes`, which splits the run into two phases that each write their own trajectory and log:

| Phase | What it does | Output files |
| --- | --- | --- |
| **Quench** | Hold at `t_high` (the protein unfolds here). | `<outname>_quench.dcd`, `<outname>_quench.log` |
| **Production** | Run at `ref_t` (the protein refolds; you collect the equilibrium ensemble). | `<outname>.dcd`, `<outname>.log` |

`anneal_steps` is separate from `md_steps`, so the grand total is their sum. Because the quench writes to `_quench.*`, the hot part never contaminates your production trajectory. The quench writes no checkpoint and the production clock resets to zero, so restarting an annealed run is identical to restarting a normal one.

There are two ways down from `t_high` to `ref_t`, set by `anneal_ramp`:

- **`jump`** (default) — the thermostat drops to `ref_t` instantaneously at the phase boundary. Use it for **folding kinetics and mechanism**; folding happens at one well-defined temperature, mirroring an experimental T-jump.
- **`linear`** — the temperature cools gradually over `anneal_ramp_steps`. Use it for **refolding yield** (classic simulated annealing toward the native minimum); not for clean kinetics, since cooling and folding overlap.

One physical caveat: a Langevin thermostat relaxes toward a new setpoint over roughly `1/tau_t`, so `anneal_steps` must be many relaxation times — long enough that the protein genuinely unfolds (*Q* → 0 in `traj_quench.dcd`). The tutorial configs use `tau_t = 1.0` for speed; production runs typically use `tau_t ≈ 0.05`, which needs a proportionally longer hold.

## Where to go next

That is the full folded-protein workflow: build a model, scale its domains, calibrate it, and drive it through temperature protocols. From here:

- Measure how folded each domain is with [native-contact (*Q*) analysis](https://vuqv.github.io/topo/main/usage/native_contacts.html).
- Script the model directly with the [Python API](https://vuqv.github.io/topo/main/usage/python_api.html).
- Continue to [Part B]({% post_url 2026-07-07-topo-tutorial-translation %}) to grow the protein on a ribosome and watch it fold co-translationally.

The ready-to-run input files for every tutorial live under [`tutorials/`](https://github.com/vuqv/topo/tree/main/tutorials) in the repository.

## Resources

- **TOPO documentation**: <https://vuqv.github.io/topo/main/index.html>
- **GitHub repository**: <https://github.com/vuqv/topo>
- **OpenMM**: <https://openmm.org/documentation>
- **STRIDE**: <http://webclu.bio.wzw.tum.de/stride/>

---
layout: post
title: "TOPO tutorial, Part B — co-translational protein synthesis"
date: 2026-07-07 12:00:00-0400
description: Growing a protein residue by residue on the ribosome with TOPO — the analytic cylinder tunnel and the explicit coarse-grained ribosome, under codon-resolved kinetics.
thumbnail: assets/img/publication_preview/cylinder.gif
thumbnail_fit: contain
tags: topo coarse-grained molecular-dynamics protein-synthesis co-translational-folding ribosome openmm
categories: research-notes
giscus_comments: true
related_posts: false
---

This is Part B of the TOPO tutorial. [Part A]({% post_url 2026-02-06-topo-tutorial %}) covered simulating a folded protein in isolation. Here the protein is not pre-folded — it is **synthesized**, growing one residue at a time out of a ribosome while the nascent chain folds *as it emerges*. This reproduces co-translational folding under codon-resolved kinetics, and it builds directly on the Part A structure-based model. Everything below mirrors the [official TOPO tutorials](https://vuqv.github.io/topo/main/tutorials/index.html) (tutorials 7–8) and the [protein-synthesis overview](https://vuqv.github.io/topo/main/usage/synthesis_overview.html).

## The biology in one minute

A ribosome builds a protein one residue at a time, N-terminus first, threading the growing (nascent) chain out through the roughly 80 Å **exit tunnel**, where it begins to fold before the full sequence even exists. How long the ribosome dwells on each codon sets how much time each segment has to sample conformations before the next residue arrives — slow, rare codons act as translational pauses that can change folding outcomes.

Each residue is added through one elongation cycle: codon-dependent tRNA **decoding** (usually rate-limiting), **peptidyl transfer** at the peptidyl-transferase centre (PTC), and **translocation**. TOPO times each residue from its mRNA codon using the O'Brien Continuous Synthesis Protocol.

## Two ribosome models

Both models grow the same structure-based (Gō-like) Cα nascent chain from Part A, and both use the same codon kinetics. They differ only in **how the exit tunnel is represented**:

| | Analytic cylinder | Explicit CG ribosome |
| --- | --- | --- |
| **Runner** | `topo-cylinder` | `topo-csp` |
| **Tunnel** | an analytic cylindrical bore through an infinite wall | a real truncated, coarse-grained large subunit (~4,600 rigid beads) |
| **Interactions** | geometric confinement only | ribosome↔chain excluded volume + electrostatics; tRNA tether; A→P translocation |
| **Needs a structure?** | no | yes — a `ribosome_trunc.pdb` |
| **Per residue** | one MD segment | three MD sub-stages |
| **Cost / robustness** | fast; never jams | heavier; realistic tunnel wall |

Reach for the **cylinder** for fast exploration of how tunnel geometry and codon kinetics shape folding, or when you have no ribosome structure. Reach for the **explicit ribosome** when the tunnel-wall charge, the real tunnel shape (constriction site, vestibule), or translocation-coupled forces matter to your question.

> **A caveat before comparing runs.** The two models are comparable only in the *mean* per-residue dwell time, not in confinement chemistry. The cylinder omits the ribosome's electrostatics and surface excluded volume and uses a uniform straight bore. Do not compare folding observables (folding order, *Q*-vs-length, radius of gyration) across the two models without accounting for those missing terms.

## Tutorial 7 — synthesis through an analytic exit tunnel

{% include figure.liquid loading="eager" path="assets/img/publication_preview/cylinder.gif" title="Protein synthesis through an analytic exit tunnel" class="img-fluid rounded z-depth-1" caption="The nascent chain grows from the PTC and extrudes N-terminus-first down the analytic cylindrical bore, then folds once it clears the exit-face wall." %}

Here the exit tunnel is modelled analytically: a cylindrical **bore** of radius `r` along the X-axis, drilled through an **infinite wall** at `x_exit` — essentially a "hole in a wall." There are no ribosome beads, so the system is the nascent chain only. That makes it fast and means it never jams. The chain is a folded protein built with TOPO's structure-based contacts, so it can fold co-translationally as it extrudes and once it clears the bore.

A bead is penalized by how far it penetrates the forbidden solid region (everything outside the bore, plus the closed PTC end), escaping via whichever face is nearer — the bore wall pushes it radially inward, keeping the chain extended, while the exit face pushes it in `+x`. The C-terminus is seeded and position-restrained on the tunnel axis at the PTC, and each new residue is seeded there too.

Run it from the tutorial folder:

```bash
cd tutorials/07_translation_cylinder
topo-cylinder -f cylinder.ini
# or: python -m topo.csp.cylinder -f cylinder.ini
```

All parameters live in `cylinder.ini`. The demo nascent chain is the 106-residue P0CX28, with its `domain.yaml` and precomputed STRIDE for the contact map, and `P0CX28_mrna.txt` for the codon kinetics. The tunnel defaults are a bore radius of 0.9 nm and length 10.0 nm along X. The kinetics keys (`mrna`, `scale_factor`, `time_stage_1/2`, `max_steps_per_stage`) are the same as the explicit-ribosome runner; the demo caps each residue at 2000 steps, which you would remove for production.

### Ejection and dissociation

Once the chain reaches full length, two optional post-synthesis free runs continue from the finished structure, both releasing the C-terminus restraint so the completed protein can diffuse. The analytic tunnel stays on, so the only way out is `+x` through the exit — this tests whether the protein diffuses out and folds in the cytosol:

```ini
ejection_steps     = 300_000   # long enough for the protein to clear the tunnel
dissociation_steps = 0         # 0 -> skip
```

Stitch the per-length trajectories into a movie that also draws the analytic tunnel:

```bash
python make_movie_cylinder.py -o synth_out -f cylinder.ini
vmd -e synth_out/movie.tcl
```

## Tutorial 8 — synthesis on a coarse-grained ribosome

This is the ribosome-based counterpart. Everything is standalone TOPO: the ribosome is a truncated CG bead model (`ribosome_trunc.pdb`) — no external CHARMM `.cor`/`.psf`/`.prm` files. The nascent chain grows N→C through the exit region and is ejected once complete. Four organisms ship ready-made, so you don't have to build the ribosome yourself.

Two systems are worked out:

| System | Residues | Notes |
| --- | --- | --- |
| `4c5c/` | 306, multidomain | Full-length synthesis `L = 1 → 306`, then ejection. The main validation case. |
| `P0CX28/` | 106, single-domain | The protein from Part A, `L = 1 → 106`, `nscale = 2.5044`. |

Each system folder holds the target folded structure (`*_clean.pdb`, which defines the native contacts), precomputed STRIDE, a `domain.yaml`, the mRNA codon sequence (`*_mrna.txt`), per-codon translation times (`trans_times.txt`), the ribosome (`ribosome_trunc.pdb`), and the run config (`csp_val.ini`).

Run it from a system folder:

```bash
cd tutorials/08_ribosome_synthesis/4c5c
topo-csp -f csp_val.ini        # -> synth_out/
```

The runner uses codon-resolved kinetics with each elongation cycle split into three kinetic sub-stages, a per-stage timestep-halving stability guard, rigid `AllBonds`, and always-on equilibrium-PTC seeding — each new residue is placed one peptide bond from the previous C-terminus, clear of the ribosome, so the rigid bonds seed cleanly. A clean full-length run shows no `[stability]` lines in the log.

### What it produces, and validating

The run writes one folder per chain length (`synth_out/L_001/ … L_306/`), each with the MD trajectory and the nascent structure at that length, plus `synth_out/ejection/` for the post-synthesis release. A validation script checks the run:

```bash
python analyze_standalone.py
```

It confirms that per-stage potential energy stays finite (no blow-ups) and that the ejected chain diffuses cleanly out of the tunnel without penetrating the ribosome.

## Which to reach for

Start with the **cylinder** (Tutorial 7) — it is the simplest entry point, needs no ribosome structure, and never jams, so it is ideal for exploring how tunnel geometry and codon timing shape folding. Move to the **explicit ribosome** (Tutorial 8) when the physical tunnel — its wall charge, its shape, its translocation-coupled forces — is central to the question you are asking.

## Resources

- **Protein synthesis overview**: <https://vuqv.github.io/topo/main/usage/synthesis_overview.html>
- **Codon dwell-time tables**: <https://vuqv.github.io/topo/main/usage/codon_dwell_times.html>
- **The ribosome structure**: <https://vuqv.github.io/topo/main/usage/ribosome_preparation.html>
- **TOPO documentation**: <https://vuqv.github.io/topo/main/index.html>
- **GitHub repository**: <https://github.com/vuqv/topo>

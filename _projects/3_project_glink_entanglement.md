---
layout: page
title: GLink entanglement
description: A Python command-line tool for calculating and clustering Gaussian-linking protein entanglements
img: assets/img/posts/glink-entanglement/Fig1.png
importance: 3
category: fun
github: https://github.com/vuqv/glink_entanglement
---

{% include figure.liquid loading="eager" path="assets/img/posts/glink-entanglement/Fig1.png" title="GLink protein entanglement analysis" class="img-fluid rounded z-depth-1" caption="GLink entanglement detects candidate loop-threading contacts in protein structures and summarizes them into representative entanglements." %}

[GLink entanglement](https://github.com/vuqv/glink_entanglement) is a Python workflow for calculating Gaussian-linking entanglements in all-atom protein structures. It identifies residue contacts that can close loops, measures how strongly the N- and C-terminal chain segments thread through those loops, confirms candidates with Topoly crossing residues, and writes the results as CSV tables.

The package exposes two command-line tools. `glink` runs the contact-level screen from a PDB file and reports retained entangled contacts with Gaussian-linking scores, loop endpoints, and crossing labels. `glink-cluster` then groups related contact-level hits into a smaller representative table, making it easier to compare entanglement patterns across structures or protein sets.

The workflow is intended for practical structural-biology analyses where an all-atom PDB, AlphaFold-style model, or representative molecular-dynamics structure needs a residue-level topology screen. Raw output keeps the contact-level audit trail, while the clustered output provides the compact summary usually used for downstream comparison.

Code and tutorial:

- [GitHub repository](https://github.com/vuqv/glink_entanglement)
- [GLink Entanglement Tutorial]({% post_url 2026-05-31-glink-entanglement-tutorial %})

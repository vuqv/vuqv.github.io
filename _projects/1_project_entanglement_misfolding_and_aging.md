---
layout: page
title: Native entanglement misfolding and aging
description: Protein topology in age-associated yeast proteome remodeling
img: assets/img/publication_preview/yeast_aging.png
importance: 1
category: work
related_publications: true
---

{% include figure.liquid loading="eager" path="assets/img/publication_preview/yeast_aging.png" title="Native entanglement misfolding and age-associated structural change" class="img-fluid rounded z-depth-1" caption="Native entanglement misfolding can generate long-lived, near-native states that accumulate as protein quality-control capacity declines with age." %}

This project asks whether protein topology helps explain age-associated structural remodeling across the yeast proteome. Aging cells accumulate molecular damage and misfolded proteins, and their capacity to maintain protein homeostasis gradually declines. We focus on native non-covalent lasso entanglements (NCLEs), structural motifs in which one part of a protein chain threads through a loop closed by non-covalent contacts. If this threading is lost or formed incorrectly, the protein can become trapped in a near-native but topologically altered state.

In our bioRxiv preprint, "[Native entanglement misfolding contributes to age-associated structural changes across the Saccharomyces cerevisiae proteome](https://www.biorxiv.org/content/10.64898/2026.04.15.717356v1)," we combine proteome-wide limited proteolysis mass spectrometry from young and aged *Saccharomyces cerevisiae*, AlphaFold-based entanglement annotations, and molecular simulations. After filtering for high-confidence structures and excluding knots and covalent lassos, the analysis covers 2,256 proteins, including 1,686 proteins with at least one native NCLE and 438 proteins with age-associated structural changes.

The central result is that natively entangled proteins are enriched among proteins that structurally change with age. Proteins containing native NCLEs are 121% more likely to exhibit an age-associated structural change after controlling for protein length, and within entangled proteins, the altered regions are 59% more likely to fall in the native entangled region. These associations suggest that native entanglements mark local structural vulnerabilities in the aging proteome.

We then use coarse-grained refolding simulations to ask whether native entanglements create an intrinsic biophysical risk. In length-matched protein sets, natively entangled proteins with age-associated structural changes are seven times more likely to misfold than non-entangled proteins without such changes. Simulations of GDP dissociation inhibitor GDI1 provide a structural example: the protein can populate near-native states with altered entanglement topology, and several simulated states are consistent with the LiP-MS proteolytic changes observed during aging.

The broader goal is to understand aging as a structural and topological problem in the proteome. Some proteins may be vulnerable not only because they are damaged over time, but because their native folds contain features that make persistent misfolding more likely when cellular quality-control capacity declines. A separate manuscript in preparation extends this idea specifically to the proteostasis network; here, the focus is the proteome-wide yeast aging signal.

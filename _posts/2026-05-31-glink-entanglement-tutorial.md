---
layout: post
title: GLink Entanglement Tutorial
date: 2026-05-31 12:00:00-0400
description: A practical tutorial for detecting and clustering Gaussian-linking entanglements in protein structures.
tags: protein-entanglement gaussian-linking topology python structural-biology
categories: research-notes
giscus_comments: true
related_posts: false
---

`glink-entanglement` is a Python workflow for finding candidate protein entanglements from an all-atom PDB structure. It combines three ideas:

- heavy-atom residue contacts define possible loop-closing contacts;
- C-alpha traces are used to calculate partial Gaussian linking values;
- Topoly confirms whether a candidate loop has a crossing residue.

The package then provides a second command, `glink-cluster`, to merge many similar raw contacts into a smaller set of representative entanglements.

This tutorial walks through installation, a complete command-line workflow, how to interpret the output files, how to tune the main parameters, and how to call the code from Python.

## When to use this workflow

Use `glink-entanglement` when you have an all-atom protein structure and want a residue-level screen for loop-threading entanglements. Typical inputs include:

- an experimental PDB structure;
- an AlphaFold model saved as PDB;
- a representative structure extracted from a molecular dynamics trajectory.

The method is designed for protein chains. It uses `protein and not name H*` to select heavy atoms, then calculates topology on each chain separately. If your biological assembly has multiple chains, each chain is analyzed independently.

## What the package does

The workflow has two stages.

First, `glink` scans one PDB file and writes raw entangled contacts:

```bash
glink -f PDB/2ww4.pdb -o out
```

Second, `glink-cluster` groups similar raw contacts into representative entanglements:

```bash
glink-cluster \
  -r out/2ww4_glink_contacts.csv \
  -o clustered \
  -g Human
```

The first command produces a CSV of contact-level entanglement candidates. The second command produces a CSV of clustered representatives.

## Installation

Clone the repository and install the package:

```bash
git clone https://github.com/vuqv/glink_entanglement.git
cd glink_entanglement
pip install .
```

For development, use editable mode:

```bash
pip install -e .
```

The package requires Python 3.10 or newer and installs the following Python dependencies:

- `MDAnalysis`
- `numpy`
- `pandas`
- `scipy`
- `topoly`

After installation, confirm that the two command-line tools are available:

```bash
glink --help
glink-cluster --help
```

If either command is not found, check that the active shell is using the same Python environment where you installed the package:

```bash
python -m pip show glink-entanglement
which glink
which glink-cluster
```

## Input requirements

The main input is an all-atom PDB file:

```text
PDB/2ww4.pdb
```

The structure should satisfy these conditions:

- protein atoms are recognizable by MDAnalysis;
- each residue has a C-alpha atom;
- residue ordering within each chain is meaningful;
- chain or segment identifiers are present when the file contains multiple chains;
- missing residues are either absent from the analysis intentionally or repaired before running.

Hydrogen atoms are ignored. Contacts are defined using protein heavy atoms.

## Step 1: Detect raw GLink contacts

Run `glink` on a PDB file:

```bash
glink -f PDB/2ww4.pdb -o out
```

The `-f` argument gives the input PDB. The `-o` argument can be either an output directory or a full CSV path.

If `-o` is a directory, the output file is named from the PDB stem:

```text
out/2ww4_glink_contacts.csv
```

You can also write to an explicit file:

```bash
glink \
  -f PDB/2ww4.pdb \
  -o out/my_2ww4_contacts.csv
```

At the end of a successful run, the command prints how many contacts were written and the runtime:

```text
Wrote 91 contacts to out/2ww4_glink_contacts.csv
Runtime: 12.345678 seconds
```

Your exact runtime will depend on the protein size and Topoly settings.

## How contacts are defined

For each chain, `glink` selects:

```text
protein and not name H*
```

Then it marks two residues as a contact when:

- any pair of heavy atoms is within the contact cutoff;
- the residues are separated by at least four positions along the sequence.

The default heavy-atom contact cutoff is:

```text
4.5 A
```

You can change it with:

```bash
glink \
  -f PDB/2ww4.pdb \
  -o out \
  --contact_cutoff 5.0
```

A larger cutoff usually increases the number of candidate contacts. A smaller cutoff is stricter and may miss loose but meaningful loop-closing contacts.

## How Gaussian linking is calculated

For each contact between residues `i` and `j`, the segment from `i` to `j` is treated as the loop. The C-alpha trace is used as the protein curve.

The package calculates two partial Gaussian linking values:

- `gn`: linking between the loop and the N-terminal side of the chain;
- `gc`: linking between the loop and the C-terminal side of the chain.

The absolute values are rounded into integer-like scores:

- `Gn`: rounded form of `abs(gn)`;
- `Gc`: rounded form of `abs(gc)`.

By default, the rounding threshold is:

```text
0.6
```

For example, an absolute value at or above the threshold is rounded up to the nearest integer score. You can tune the threshold:

```bash
glink \
  -f PDB/2ww4.pdb \
  -o out \
  --GLN_threshold 0.6
```

Contacts with both `Gn == 0` and `Gc == 0` are discarded before Topoly confirmation.

## Topoly confirmation

Gaussian linking is used as a candidate screen. A contact is only written to the final raw CSV when Topoly finds a crossing residue on a side with nonzero rounded linking.

The logic is:

- if `Gn != 0` and `Gc == 0`, the contact must have an N-terminal crossing;
- if `Gn == 0` and `Gc != 0`, the contact must have a C-terminal crossing;
- if `Gn != 0` and `Gc != 0`, either side can confirm the contact;
- if Topoly finds no relevant crossing, the contact is dropped.

The default Topoly density in this package is:

```text
0
```

This is faster than Topoly's package default. If you need the higher-density surface, run:

```bash
glink \
  -f PDB/2ww4.pdb \
  -o out \
  --topoly_density 1
```

You can also tune Topoly's crossing-reduction distances:

```bash
glink \
  -f PDB/2ww4.pdb \
  -o out \
  --topoly_min_dist 10 6 5
```

The three values correspond to crossing, loop, and tail-end distances.

## Raw CSV output

The raw CSV has one row per retained entangled contact. A typical file begins like this:

```text
chain,resid_i,resname_i,resid_j,resname_j,contact_i_index,contact_j_index,gn,gc,Gn,Gc,crossingsN,crossingsC,crossings
SYSTEM,15,LEU,208,SER,14,207,-0.80898,-0.57081,1,0,-7,,-7
SYSTEM,15,LEU,209,ASN,14,208,-0.80928,-0.66592,1,1,-7,,-7
```

The most important columns are:

| Column | Meaning |
| --- | --- |
| `chain` | Chain or segment identifier used by MDAnalysis. |
| `resid_i`, `resid_j` | Residue IDs for the contact that closes the loop. |
| `resname_i`, `resname_j` | Residue names for the contact residues. |
| `contact_i_index`, `contact_j_index` | Zero-based C-alpha indices used internally. |
| `gn`, `gc` | Raw partial Gaussian linking values. |
| `Gn`, `Gc` | Rounded absolute linking values. |
| `crossingsN` | Topoly crossing residues on the N-terminal side. |
| `crossingsC` | Topoly crossing residues on the C-terminal side. |
| `crossings` | Combined crossing list used by clustering. |

Crossing labels preserve chirality. For example:

```text
-7
+172
```

The sign is the crossing chirality reported by Topoly, and the number is the mapped PDB residue ID.

## Step 2: Cluster raw contacts

Raw contact files can contain many rows describing essentially the same entanglement. `glink-cluster` reduces them to representative entanglements.

Run clustering with an organism preset:

```bash
glink-cluster \
  -r out/2ww4_glink_contacts.csv \
  -o clustered \
  -g Human
```

Available organism presets are:

| Organism | Cutoff |
| --- | --- |
| `Human` | `52` |
| `Ecoli` | `57` |
| `Yeast` | `49` |

You can also provide a custom spatial cutoff:

```bash
glink-cluster \
  -r out/2ww4_glink_contacts.csv \
  -o clustered \
  -c 52
```

To choose the exact output file:

```bash
glink-cluster \
  -r out/2ww4_glink_contacts.csv \
  -o clustered \
  -g Human \
  -w clustered/2ww4_representative_entanglements.csv
```

If `-w` is not provided, the output file is named:

```text
<input_csv_stem>_clustered.csv
```

For the example above, that gives:

```text
clustered/2ww4_glink_contacts_clustered.csv
```

## How clustering works

The clustering step performs several filters and merges:

1. Read the raw `glink` CSV.
2. Drop rows without crossing residues.
3. Group rows by chain and exact crossing set.
4. For each exact crossing set, keep the shortest loop as the first representative.
5. Merge larger overlapping loops when they share chain, crossing count, chirality sequence, overlapping loop endpoints, and nearby crossing residues.
6. Spatially cluster the remaining representatives using coordinates built from:

```text
(resid_i, resid_j, crossing_residue_ids...)
```

Clustering is separated by chain, number of crossings, and chirality sequence. This prevents a one-crossing entanglement from being merged into a two-crossing entanglement, even if the loop endpoints are nearby.

## Clustered CSV output

The clustered CSV has one row per representative entanglement:

```text
cluster_id,chain,resid_i,resid_j,gn,gc,Gn,Gc,crossings,num_contacts,contacts
0,A,53,78,-0.70753,0.0,1,0,-45,3,52-79;53-78;53-79
```

The columns are:

| Column | Meaning |
| --- | --- |
| `cluster_id` | Integer cluster ID. |
| `chain` | Chain or segment identifier. |
| `resid_i`, `resid_j` | Representative loop-closing contact. |
| `gn`, `gc` | Raw linking values for the representative contact. |
| `Gn`, `Gc` | Rounded linking values for the representative contact. |
| `crossings` | Representative crossing residue set. |
| `num_contacts` | Number of raw contacts represented by the cluster. |
| `contacts` | Semicolon-delimited raw contact list. |

In the example row above, the representative entanglement uses loop-closing residues `53` and `78`, has one crossing residue at `-45`, and summarizes three raw contacts.

## End-to-end example

Here is a complete workflow using the example PDB directory from the repository:

```bash
git clone https://github.com/vuqv/glink_entanglement.git
cd glink_entanglement
pip install -e .

mkdir -p out clustered

glink \
  -f PDB/2ww4.pdb \
  -o out \
  --GLN_threshold 0.6 \
  --contact_cutoff 4.5 \
  --topoly_density 0 \
  --topoly_min_dist 10 6 5

glink-cluster \
  -r out/2ww4_glink_contacts.csv \
  -o clustered \
  -g Human
```

Inspect the outputs:

```bash
head out/2ww4_glink_contacts.csv
head clustered/2ww4_glink_contacts_clustered.csv
```

For a quick count:

```bash
wc -l out/2ww4_glink_contacts.csv
wc -l clustered/2ww4_glink_contacts_clustered.csv
```

Remember that `wc -l` includes the header line.

## Running many PDB files

For a directory of PDB files:

```bash
mkdir -p out clustered

for pdb in PDB/*.pdb; do
  glink -f "$pdb" -o out
done

for csv in out/*_glink_contacts.csv; do
  glink-cluster -r "$csv" -o clustered -g Human
done
```

Use a custom cutoff if the organism presets are not appropriate:

```bash
for csv in out/*_glink_contacts.csv; do
  glink-cluster -r "$csv" -o clustered -c 52
done
```

## Calling the package from Python

The command-line tools are the most convenient interface, but the core functions can also be imported.

To calculate raw contacts:

```python
from glink_entanglement.glink import calculate_pdb_glink

df = calculate_pdb_glink(
    "PDB/2ww4.pdb",
    threshold=0.6,
    cutoff=4.5,
    topoly_density=0,
    topoly_min_dist=(10, 6, 5),
)

df.to_csv("out/2ww4_glink_contacts.csv", index=False)
print(df.head())
```

To cluster a raw CSV:

```python
from glink_entanglement.clustering import cluster_glink

clustered = cluster_glink(
    "out/2ww4_glink_contacts.csv",
    cutoff=52,
)

clustered.to_csv("clustered/2ww4_glink_contacts_clustered.csv", index=False)
print(clustered)
```

This is useful when you want to integrate entanglement detection into a larger Python analysis pipeline.

## Choosing parameters

Start with the defaults:

```bash
glink \
  -f structure.pdb \
  -o out \
  --GLN_threshold 0.6 \
  --contact_cutoff 4.5 \
  --topoly_density 0 \
  --topoly_min_dist 10 6 5
```

Then adjust one parameter at a time.

Use `--contact_cutoff` when the contact definition is too strict or too permissive. A value around `4.5 A` is a reasonable heavy-atom contact cutoff.

Use `--GLN_threshold` when you want to change how aggressively raw `gn` and `gc` values are rounded into nonzero `Gn` and `Gc` scores.

Use `--topoly_density 1` when you want Topoly's denser surface calculation and can tolerate a slower run.

Use `glink-cluster -c` when the organism preset is not appropriate for the proteins being analyzed.

## Practical interpretation

A row in the raw CSV means:

- two residues form a heavy-atom contact;
- the loop closed by that contact has nonzero rounded Gaussian linking against one side of the chain;
- Topoly found at least one crossing residue consistent with the nonzero side.

A row in the clustered CSV means:

- one or more raw contacts were judged to represent the same entanglement class;
- the reported contact is the representative loop-closing contact;
- `num_contacts` tells you how many raw contacts were summarized.

For downstream analysis, the clustered CSV is often the easier starting point. Use the raw CSV when you need contact-level detail or want to understand why a particular representative was selected.

## Troubleshooting

If `glink` writes zero contacts, check the PDB first:

- Does the file contain protein atoms recognized by MDAnalysis?
- Are C-alpha atoms present?
- Are chain breaks or missing residues expected?
- Is the contact cutoff too small?
- Is the GLN threshold too strict?

If Topoly is slow, keep the package default:

```bash
--topoly_density 0
```

Use density `1` only for cases where the slower, denser Topoly calculation is worth the extra cost.

If all atoms appear under chain `SYSTEM`, your PDB may not contain explicit chain or segment identifiers. The calculation can still run, but adding chain identifiers is better when you need chain-specific interpretation.

If clustering fails with a missing-column error, make sure the input to `glink-cluster` is the raw CSV produced by `glink`, not a manually edited table or a previously clustered CSV.

If the shell cannot find `glink` or `glink-cluster`, reinstall in the active environment:

```bash
python -m pip install -e .
```

Then open a new shell or refresh the shell's command cache:

```bash
hash -r
```

## Summary

`glink-entanglement` turns an all-atom protein PDB into two useful tables:

- a raw contact-level table from `glink`;
- a representative entanglement table from `glink-cluster`.

The raw table is best for auditing individual loop-closing contacts. The clustered table is best for reporting and comparing entanglement patterns across structures.

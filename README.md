# Dishisclst

## description

Repository (repo) designed to characterize a patient cohort by means of the MCL cluster software. 

Ref. [MICANS](https://micans.org/mcl/) (URL: https://micans.org/mcl/)

* Patient ID (PID)
* Diagnosis code (ICD10)

The repo was developed on CentIOS (HPC) and tested wihtin an x64 architecture.

## prerequisites

- [ ] conda (URL: https://anaconda.org)
- [ ] snakemake (URL: https://snakemake.github.io)

Terminal command to create environment

$ `conda env create -f environment.yml`

## structure

As **input** the repo takes patients and their disease history represented as ICD-10 codes.

The repo comes with a synthetic data set: `input/features.tsv` 

The repo **outputs** a file with three columns

* Patient ID (PID)
* Inflation parameter (ip)
* Cluster (cluster)

For **intermediate** steps see `dag.pdf`

For an **overview** of the impact of _ip_ on clustering see `sankey.pdf`

## to run repo

The repo was developed to run from a terminal with the command typed below

$ `snakemake --profile pbs-trans <target_rule/target_file>`

For dry add **flag n**

$ `snakemake -n --profile pbs-trans <target_rule/target_file>`

To execute rules with wild cards, add **flag R**

$ `snakemake -n --profile pbs-trans -R <target_rule>`

To force repo execution (overwrite existing files), add **flag dash forceall**

$ `snakemake --profile pbs-trans --forceall`

To overwrite specific files or rules, include **flag dash force**

$ `snakemake -n --profile pbs-trans --force <target_rule/target_file>`

## snakefile wildcards

| wildcard    | content |
| -------- | ------- |
| co  | mcl edge-weight cutoff  |
| cnn | mcl inflation parameter |
| pi    | mcl pre-inflation |
| ip    | mcl inflation parameter  |

## more info

e-mail-address: amalie.haue@cpr.ku.dk

e-mail-address: peter.holm@cpr.ku.dk





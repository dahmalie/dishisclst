#! /usr/bin/env bash

spec=("qsub -l nodes=1:ppn={threads},"
      "mem={resources.mem_mb}mb,"
      "walltime={resources.t_min}:00"
      " -j eo -e ~/.qsub_logs/")

call=$(printf "%s" "${spec[@]}")

snakemake $@ -p --jobs 20 --notemp --verbose \
    --cluster "$call" --latency-wait 35

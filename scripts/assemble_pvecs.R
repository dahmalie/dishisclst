library(tidyverse)
library(lubridate)

# Paths to the different files
feat_path <- snakemake@input[["feat"]]

# Read in the different files
features <- read_tsv(feat_path, col_types = cols())

# Save counts for potential downstream analyses
freq <- features %>%
    count(PID, ICD10, name = "term_freq")

freq %>%
  write_tsv(snakemake@output[["freq"]])

# Pivot the data and add PID's with no codes
feat_wide <- freq %>%
  ungroup() %>% 
  pivot_wider(names_from = ICD10, values_from = term_freq, values_fill = 0) %>%
  select(!starts_with('NA'))

feat_wide %>%
  write_tsv(snakemake@output[["pvec"]])

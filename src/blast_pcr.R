#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

# parse arguments
args = commandArgs(trailingOnly = T)

# read data
blast_res_path <- args[1]
blast_res <- fread(blast_res_path, sep = "\t")

# rename data columns
colnames(blast_res) <- c("qseqid", "sseqid", "pident",
                         "length", "mismatch", "gapopen",
                         "qstart", "qend", "sstart", "send",
                         "evalue", "bitscore")

# identify PCR products
## must have forward and reverse primer hits
primer_hits <- blast_res %>% 
  filter(pident >= 90) %>% # at least 90% identity
  group_by(qseqid, sseqid) %>%
  arrange(desc(pident)) %>%
  slice(1) %>%
  ungroup() %>%
  group_by(sseqid) %>%
  tally() %>% 
  filter(n == 2)

# write output
writeLines(unique(primer_hits$sseqid), args[2])
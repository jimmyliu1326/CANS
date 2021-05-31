#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(pastecs))

# parse arguments
args = commandArgs(trailingOnly = T)
expected_length <- as.numeric(args[2])
deviation <- as.numeric(args[3])

# read data
read_stats <- fread(args[1], header = T, sep = "\t")

## calculate read length density
length_density <- density(read_stats$length)
## find peaks in read lengths density
tps <- turnpoints(length_density$y)
peaks <- data.frame(x = length_density$x[which(extract(tps) == 1)],
                    y = length_density$y[which(extract(tps) == 1)],
                    prob = tps$prob[which(tps$tppos %in% which(extract(tps) == 1))]) %>%
            filter(prob <= 0.00005)
## select the peak closest to the expected length
best_peak <- peaks %>% 
  mutate(difference = abs(x - expected_length)) %>%
  arrange(-desc(difference)) %>%
  slice(1) %>%
  pull(x)
message(paste0("Peak selected at: ", best_peak, " bps"))

# identify fastq sequence IDs for consensus building
fastq_ids <- read_stats %>%
  filter(length <= best_peak+deviation,
         length >= best_peak-deviation) %>%
  pull(`#id`)

# write output
writeLines(unique(fastq_ids))
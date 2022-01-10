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
tryCatch( {
  length_density <- density(read_stats$length)
  tps <- turnpoints(length_density$y)
  ## find peaks in read lengths density
  peaks <- data.frame(x = length_density$x[which(extract(tps) == 1)],
                    y = length_density$y[which(extract(tps) == 1)],
                    prob = tps$prob[which(tps$tppos %in% which(extract(tps) == 1))]) %>%
            filter(prob <= 0.00005)
  },
  error = function(e) {
    message("CANS: Cannot compute density distribution from read length data, falling back to using --mode static")
  }
)

# switch to static mode if no peaks detected
if ( exists("peaks") ) {
  if ( nrow(peaks) >= 1 ) {
    best_peak <- peaks %>% 
  mutate(difference = abs(x - expected_length)) %>%
  arrange(-desc(difference)) %>%
  slice(1) %>%
  pull(x)
  if (length(best_peak) == 0) {best_peak <- expected_length}
  } else {
    message("CANS: Cannot detect any peaks from read length distribution, falling back to using --mode static")
    best_peak <- expected_length
  }
} else {
  best_peak <- expected_length
}

## print peak length
message(paste0("Peak selected at: ", best_peak, " bps"))

# identify fastq sequence IDs for consensus building
fastq_ids <- read_stats %>%
  filter(length <= best_peak+deviation,
         length >= best_peak-deviation) %>%
  pull(`#id`)

# write output
writeLines(unique(fastq_ids), args[4])
writeLines(as.character(best_peak), args[5])
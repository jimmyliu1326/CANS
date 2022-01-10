import pandas as pd
import os
from datetime import datetime
import glob

# parse samples metadata
samples_tbl=config["samples"]
samples_meta=pd.read_csv(samples_tbl, header = None, dtype = str)
samples_meta.columns=["Sample", "Path"]
samples_meta=samples_meta.set_index("Sample", drop = False)

# check if file is gz compressed
def is_gz_file(filepath):
    with open(filepath, 'rb') as test_f:
        return test_f.read(2) == b'\x1f\x8b'

# select input fastq for dehosting
def dehost_input(wildcards):
  sample=wildcards["sample"]
  path=samples_meta.Path[wildcards.sample]
  file=glob.glob(path+"/*.fastq*")[0]
  if config["trim"] == 0:
    if is_gz_file(file):
      return os.path.join(sample, sample+".fastq.gz")
    else:
      return os.path.join(sample, sample+".fastq")
  else:
    return os.path.join(sample, "porechop", sample+"_trimmed.fastq")

# select input fastq for dynamic length filtering
def length_selection_input(wildcards):
  sample=wildcards["sample"]
  path=samples_meta.Path[wildcards.sample]
  file=glob.glob(path+"/*.fastq*")[0]
  if os.path.basename(config["reference"]) == "NA":
    if config["trim"] == 0:
      if is_gz_file(file):
        return os.path.join(sample, sample+".fastq.gz")
      else:
        return os.path.join(sample, sample+".fastq")
    else:
      return os.path.join(sample, "porechop", sample+"_trimmed.fastq")
  else:
    return os.path.join(sample, "dehost", sample+".fastq")

# select input fastq for static length filtering
def static_length_selection_input(wildcards):
  sample=wildcards["sample"]
  path=samples_meta.Path[wildcards.sample]
  file=glob.glob(path+"/*.fastq*")[0]
  if os.path.basename(config["reference"]) == "NA":
    if config["trim"] == 0:
      if is_gz_file(file):
        return os.path.join(sample, sample+".fastq.gz")
      else:
        return os.path.join(sample, sample+".fastq")
    else:
      return os.path.join(sample, "porechop", sample+"_trimmed.fastq")
  else:
    return os.path.join(sample, "dehost", sample+".fastq")

# select input fastq for primers search
def primer_search_input(wildcards):
  sample=wildcards["sample"]
  if config['mode'] == "dynamic":
    return os.path.join(sample, "length_fastq", sample+".fastq")
  else:
    return os.path.join(sample, "filtered_fastq", sample+".fastq")

# select input fastq for subsampling
def read_subsample_input(wildcards):
  sample=wildcards["sample"]
  if (config['mode'] == "dynamic" and os.path.basename(config["primers"]) == "NA"):
    return os.path.join(sample, "length_fastq", sample+".fastq")
  if (config['mode'] == "static" and os.path.basename(config["primers"]) == "NA"):
    return os.path.join(sample, "filtered_fastq", sample+".fastq")
  else:
    return os.path.join(sample, "primers_fastq", sample+".fastq")

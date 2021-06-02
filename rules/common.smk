import pandas as pd
import os

# parse samples metadata
samples_tbl=config["samples"]
samples_meta=pd.read_csv(samples_tbl, header = None, dtype = str)
samples_meta.columns=["Sample", "Path"]
samples_meta=samples_meta.set_index("Sample", drop = False)

# select input fastq for dehosting
def dehost_input(wildcards):
  sample=wildcards["sample"]
  if config["trim"] == 0:
    return os.path.join(sample, sample+".fastq")
  else:
    return os.path.join(sample, "porechop", sample+"_trimmed.fastq")

# select input fastq for filtering
def read_selection_input(wildcards):
  sample=wildcards["sample"]
  if config["reference"] == "NA":
    if config["trim"] == 0:
      return os.path.join(sample, sample+".fastq")
    else:
      return os.path.join(sample, "porechop", sample+"_trimmed.fastq")
  else:
    return os.path.join(sample, "dehost", sample+".fastq")
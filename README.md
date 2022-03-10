[![CANS](https://circleci.com/gh/jimmyliu1326/CANS.svg?style=svg)](https://app.circleci.com/pipelines/github/jimmyliu1326/CANS)
# CANS: Consensus calling for Amplicon Nanopore Sequencing

## Description
A Snakemake pipeline designed to generate consensus sequences for target amplicon Nanopore sequencing. The pipeline supports dehosting of raw reads followed by automated selection of the most probable full-length reads for consensus building.

## Install method 1 (Conda)

```bash
# Clone the repository
git clone https://github.com/jimmyliu1326/CANS.git
# Modify CANS.sh permission and add to $PATH in .bashrc
chmod +x CANS/CANS.sh
echo "export PATH=$PWD/CANS:\$PATH" >> ~/.bashrc
source ~/.bashrc
# Create a new conda environment called `cans`
conda env create -f CANS/conda_env.yml

#### Compile ThermonucleotideBLAST (Optional)
# To search for reads that represent PCR products, the pipeline uses thermonucleotideBLAST
# Because the tool is not available as a conda package, manual compilation is required
# This step is only required if you intend to utilize the primer search functionality

# install dependencies (tested on Ubuntu 16.04+)
apt-get update && apt-get install -y \
    libmpich-dev \
    libopenmpi-dev \
    libz-dev
# Clone the forked thermonucleotideBLAST respository
git clone https://github.com/jimmyliu1326/thermonucleotideBLAST.git
# Compile
cd thermonucleotideBLAST
make all
# Add tntblast to $PATH 
```

## Install method 2 (Docker)

```
docker pull jimmyliu1326/cans
```

## Install method 3 (Singularity)

```
singularity pull docker://jimmyliu1326/cans
```

## Usage
```
Required arguments:
-i|--input            .csv file with first column as sample name and second column as path to a DIRECTORY of fastq file(s), no headers required
-o|--output           Path to output directory
-e|--expected_length  Expected sequence length (bps) of target amplicon
--mode                Select the mode for full-length reads identification (Options: dynamic/static)
                      dynamic: infers the most likely length of target amplicon based on the read length distribution of input data
                      static: selects reads solely based on the user-defined expected length of the target amplicon

Optional arguments:
--primers             Path to a headerless .tsv file containing forward and reverse primer sequences to select PCR products for consensus building
                      The primers file should only contain a single set of primers with primer ID, forward, and reverse primer sequences separated by tabs.
-r|--reference        Reference sequence used for dehosting
-s|--subsample        Specify the target coverage for consensus calling [Default = 1000]
-d|--deviation        Specify the read length deviation from (+/-) expected read length allowed for consensus building [Default = 50 bps]
-m|--model            Specify the flowcell chemistry used for Nanopore sequencing {Options: r9, r10} [Default = r9]
-t|--threads          Number of threads [Default = 32]
--notrim              Disable adaptor trimming by Porechop
--unlock              Unlock Snakemake working directory
--keep-tmp            Keep all temporary files
-h|--help             Display help message
-v|--version          Print version
```

## Example Pipeline Call
```
CANS.sh -i samples.csv -o /path/to/outdir -e 2050 --mode dynamic
```

## Dependencies
* R >= 3.6
* porechop >= 0.2.4
* spoa >= 4.0.7
* medaka >= 1.3.3
* seqkit >= 0.16.1
* seqtk >= 1.3
* snakemake >= 5.3.0
* NanoFilt >= 2.8.0
* tntblast >= 2.4
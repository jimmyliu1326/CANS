# CANS: Consensus calling for Amplicon Nanopore Sequencing

## Description
A Snakemake pipeline designed to generate consensus sequences for target amplicon Nanopore sequencing. The pipeline supports dehosting of raw reads followed by automated selection of the most probable full-length reads for consensus building.

## Usage
```
Required arguments:
-i|--input            .csv file with first column as sample name and second column as path to fastq, no headers required
-o|--output           Path to output directory
-e|--expected_length  Expected sequence length (bps) of target amplicon

Optional arguments:
-r|--reference        Reference sequence used for dehosting
-s|--subsample        Specify the target coverage for consensus calling [Default = 1000]
-d|--deviation        Specify the read length deviation from (+/-) expected read length allowed for consensus building [Default = 50 bps]
-m|--model            Specify the flowcell chemistry used for Nanopore sequencing {Options: r9, r10} [Default = r9]
-t|--threads          Number of threads [Default = 32]
--notrim              Disable adaptor trimming by Porechop
--keep-tmp            Keep all temporary files
-h|--help             Display help message
-v|--version          Print version number
```

## Example Pipeline Call
```
CANS.sh -i samples.csv -o /path/to/outdir -e 2050
```

## Dependencies
* R >= 3.6
* porechop >= 0.2.4
* spoa >= 4.0.7
* medaka >= 1.3.3
* seqkit >= 0.16.1
* seqtk >= 1.3
* snakemake >= 5.3.0
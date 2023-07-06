#!/usr/bin/env bash

usage() {
echo "
$(basename $0) v${VERSION} [options]

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
--keep-tmp            Keep all temporary files
-h|--help             Display help message
-v|--version          Print version
"
}

# define global variables
script_dir=$(dirname $(realpath $0))
script_name=$(basename $0 .sh)
THREADS=32
TRIM=1
SUBSAMPLE=1000
KEEP_TMP=0
REFERENCE_PATH="NA"
DEVIATION=50
VERSION="1.0"
PRIMERS_PATH="NA"
EXPECTED_LENGTH=0

# parse arguments
opts=`getopt -o hi:o:t:s:m:r:e:s:d:v -l help,input:,output:,threads:,reference:,notrim,model:,keep-tmp,subsample:,expected_length:,version,primers:,mode: -- "$@"`
eval set -- "$opts"
if [ $? != 0 ] ; then echo "${script_name}: Invalid arguments used, exiting"; usage; exit 1 ; fi
if [[ $1 =~ ^--$ ]] ; then echo "${script_name}: Invalid arguments used, exiting"; usage; exit 1 ; fi

while true; do
    case "$1" in
        -i|--input) INPUT_PATH=$2; shift 2;;
        -o|--output) OUTPUT_PATH=$2; shift 2;;
        -r|--reference) REFERENCE_PATH=$2; shift 2;;
        --mode) MODE=$2; shift 2;;
        --primers) PRIMERS_PATH=$2; shift 2;;
        -t|--threads) THREADS=$2; shift 2;;
        -m|--model) MODEL=$2; shift 2;;
        -s|--subsample) SUBSAMPLE=$2; shift 2;;
        -d|--deviation) DEVIATION=$2; shift 2;;
        -e|--expected_length) EXPECTED_LENGTH=$2; shift 2;;
        --notrim) TRIM=0; shift 1;;
        --keep-tmp) KEEP_TMP=1; shift 1;;
        --) shift; break ;;
        -h|--help) usage; exit 0;;
        -v|--version) echo "${script_name}: v${VERSION}"; exit 0;;
    esac
done

# check if required arguments are given
if test -z $INPUT_PATH; then echo "${script_name}: Required argument -i is missing, exiting"; exit 1; fi
if test -z $OUTPUT_PATH; then echo "${script_name}: Required argument -o is missing, exiting"; exit 1; fi
if test -z $MODE; then echo "${script_name}: Required argument --mode is missing, exiting"; exit 1; fi
if [[ $EXPECTED_LENGTH -eq 0 ]]; then echo "${script_name}: Required argument -e is missing, exiting"; exit 1; fi

# validate mode selection
if ! [[ $MODE =~ ^(dynamic|static)$ ]]; then echo "${script_name}: Invalid mode option passed to the --mode argument, accepted values are dynamic/static, exiting"; exit 1; fi

# check dependencies
medaka_consensus -h 2&>1 /dev/null
if [[ $? != 0 ]]; then echo "${script_name}: medaka cannot be called, check its installation"; exit 1; fi

seqtk 2&>1 /dev/null
if [[ $? != 1 ]]; then echo "${script_name}: seqtk cannot be called, check its installation"; exit 1; fi

snakemake -h > /dev/null
if [[ $? != 0 ]]; then echo "${script_name}: snakemake cannot be called, check its installation"; exit 1; fi

porechop -h > /dev/null
if [[ $? != 0 ]]; then echo "${script_name}: porechop cannot be called, check its installation"; exit 1; fi

spoa -h > /dev/null
if [[ $? != 0 ]]; then echo "${script_name}: spoa cannot be called, check its installation"; exit 1; fi

seqkit -h > /dev/null
if [[ $? != 0 ]]; then echo "${script_name}: seqkit cannot be called, check its installation"; exit 1; fi

NanoFilt -h > /dev/null
if [[ $? != 0 ]]; then echo "${script_name}: nanofilt cannot be called, check its installation"; exit 1; fi

# validate model parameter input if specified
if ! test -z $MODEL; then
  # test if invalid characters used
  if ! [[ $MODEL =~ ^(r9|r10)$ ]]; then echo "${script_name}: Invalid model specification passed to the -m argument, exiting"; fi
  # set medaka model
  if [[ $MODEL == "r9" ]]; then MODEL="r941_min_high_g360"; else MODEL="r103_min_high_g360"; fi
else
  # Set default model if not specified
  if test -z $MODEL; then MODEL="r941_min_high_g360"; fi
fi

# validate primers FASTA file
if [[ $PRIMERS_PATH != "NA" ]]; then
  if ! test -f $PRIMERS_PATH; then echo "${script_name}: The Primers FASTA file does not exist, exiting"; exit 1; fi 
  primers_n=$(cat $PRIMERS_PATH | wc -l)
  if [[ $primers_n -ne 1 ]]; then echo "${script_name}: Primers FASTA file should be a one liner with primer pair ID, forward, and reverse primer in a single line separated by tabs, exiting"; exit 1; fi
fi

# validate input samples.csv
if ! test -f $INPUT_PATH; then echo "${script_name}: Input csv file does not exist, exiting"; exit 1; fi

while read lines; do
  sample=$(echo $lines | cut -f1 -d',')
  path=$(echo $lines | cut -f2 -d',')
  if ! test -d $path; then
    echo "${script_name}: ${sample} directory cannot be found, check its path listed in the input file, exiting"
    exit 1
  fi
done < $INPUT_PATH

# create output directory if does not exist
if ! test -d $OUTPUT_PATH; then mkdir -p $OUTPUT_PATH; fi

# call snakemake
snakemake -k --snakefile $script_dir/Snakefile --cores $THREADS \
  --config samples=$(realpath $INPUT_PATH) \
  outdir=$(realpath $OUTPUT_PATH) \
  pipeline_dir=$script_dir \
  trim=$TRIM \
  model=$MODEL \
  threads=$THREADS \
  subsample=$SUBSAMPLE \
  reference=$(realpath $REFERENCE_PATH) \
  expected_l=$EXPECTED_LENGTH \
  deviation=$DEVIATION \
  mode=$MODE \
  primers=$(realpath $PRIMERS_PATH) \
  --nolock

# get pipeline error code
error_code=$(echo $?)

# clean up temporary directories
if [[ $KEEP_TMP -eq 0 ]]; then
  echo "$script_name: Cleaning up temporary directories..."
  while read lines; do
    sample=$(echo $lines | cut -f1 -d',')
    for dir in medaka porechop dehost draft_consensus subsample_fastq length_fastq primers_fastq filtered_fastq; do
      if test -d $(realpath $OUTPUT_PATH)/$sample/$dir; then
        rm -r $(realpath $OUTPUT_PATH)/$sample/$dir
      fi
    done
  done < $INPUT_PATH
fi

# check pipeline success
if [[ $error_code -eq 0 ]]; then
  echo "${script_name}: Analysis ran to completion successfully!"
  echo "${script_name}: Results have been written to: $(realpath $OUTPUT_PATH)"
  exit 0
else
  echo "${script_name}: Error(s) encountered during analysis run, check the above logs"
  exit 1
fi
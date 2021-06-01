#!/usr/bin/env bash

usage() {
echo "
$(basename $0) [options]

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
DEIVATION=50
VERSION="1.0"

# parse arguments
opts=`getopt -o hi:o:t:s:m:r:e:s:d:v -l help,input:,output:,threads:,reference:,notrim,model:,keep-tmp,subsample:,expected_length:,version -- "$@"`
eval set -- "$opts"
if [ $? != 0 ] ; then echo "${script_name}: Invalid arguments used, exiting"; usage; exit 1 ; fi
if [[ $1 =~ ^--$ ]] ; then echo "${script_name}: Invalid arguments used, exiting"; usage; exit 1 ; fi

while true; do
    case "$1" in
        -i|--input) INPUT_PATH=$2; shift 2;;
        -o|--output) OUTPUT_PATH=$2; shift 2;;
        -r|--reference) REFERENCE_PATH=$2; shift 2;;
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
if test -z $EXPECTED_LENGTH; then echo "${script_name}: Required argument -e is missing, exiting"; exit 1; fi

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

# validate model parameter input if specified
if ! test -z $MODEL; then
  # test if invalid characters used
  if ! [[ $MODEL =~ ^(r9|r10)$ ]]; then echo "Invalid model specification passed to the -m argument, exiting"; fi
  # set medaka model
  if [[ $MODEL == "r9" ]]; then MODEL="r941_min_high_g360"; else MODEL="r103_min_high_g360"; fi
else
  # Set default model if not specified
  if test -z $MODEL; then MODEL="r941_min_high_g360"; fi
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

# Remove existing analysis html report in OUTPUT_PATH
if test -f $OUTPUT_PATH/report_summary.html; then rm $OUTPUT_PATH/report_summary.html; fi

# call snakemake
snakemake --snakefile $script_dir/Snakefile --cores $THREADS \
  --config samples=$(realpath $INPUT_PATH) \
  outdir=$(realpath $OUTPUT_PATH) \
  pipeline_dir=$script_dir \
  trim=$TRIM \
  model=$MODEL \
  threads=$THREADS \
  subsample=$SUBSAMPLE \
  reference=$(realpath $REFERENCE_PATH) \
  expected_l=$EXPECTED_LENGTH \
  deviation=$DEVIATION

# clean up temporary directories
if [[ $KEEP_TMP -eq 0 ]]; then
  while read lines; do
    sample=$(echo $lines | cut -f1 -d',')
    for dir in medaka porechop dehost draft_consensus subsample_fastq filtered_fastq; do
      if test -d $OUTPUT_PATH/$sample/$dir; then
        rm -rf $OUTPUT_PATH/$sample/$dir
      fi
    done
  done < $INPUT_PATH
fi
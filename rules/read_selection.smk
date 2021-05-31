rule fx2tab:
  input:
    reads=read_selection_input
  threads: 4
  output:
    tab_out=temp("{sample}/read_stats.tsv")
  shell:
    """
    seqkit fx2tab {input.reads} -q -l -H -i -n > {output.tab_out}
    """
    
rule read_selection:
  input:
    reads=read_selection_input,
    read_stats="{sample}/read_stats.tsv"
  threads: 4
  params:
    expect=config['expected_l'],
    deviation=config['deviation'],
    subsample_n=config["subsample"],
    pipeline_dir=config["pipeline_dir"]
  output:
    read_ids="{sample}/filtered_fastq/{sample}.ids",
    filter_fastq="{sample}/filtered_fastq/{sample}.fastq",
    subsample_fastq="{sample}/subsample_fastq/{sample}.fastq"
  
  shell:
    """
    Rscript {params.pipeline_dir}/src/peak_detect.R {input.read_stats} {params.expect} {params.deviation} > {output.read_ids}

    seqtk subseq {input.reads} {output.read_ids} > {output.filter_fastq}

    if (( $(echo $(cat {output.filter_fastq} | wc -l) / 4 | bc) > 1000 )); then
      seqtk sample -s100 {output.filter_fastq} {params.subsample_n} > {output.subsample_fastq}
    else
      cp {output.filter_fastq} {output.subsample_fastq}
    fi
    """
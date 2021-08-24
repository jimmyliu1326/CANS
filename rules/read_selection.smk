rule fx2tab:
  input:
    reads=length_selection_input
  threads: 4
  output:
    tab_out=temp("{sample}/read_stats.tsv")
  shell:
    """
    seqkit fx2tab {input.reads} -q -l -H -i -n > {output.tab_out}
    """
    
rule selection_by_length:
  input:
    reads=length_selection_input,
    read_stats="{sample}/read_stats.tsv"
  threads: 4
  params:
    expect=config['expected_l'],
    deviation=config['deviation'],
    pipeline_dir=config["pipeline_dir"]
  output:
    read_ids=temp("{sample}/length_fastq/{sample}.ids"),
    length_fastq="{sample}/length_fastq/{sample}.fastq",
    best_peak=temp("{sample}/best_peak.txt")
  
  shell:
    """
    Rscript {params.pipeline_dir}/src/peak_detect.R {input.read_stats} {params.expect} {params.deviation} {output.read_ids} {output.best_peak}
    seqtk subseq {input.reads} {output.read_ids} > {output.length_fastq}
    """

rule selection_by_primers:
  input:
    primers=config['primers'],
    fastq=primer_search_input
  threads: 4
  params:
    pipeline_dir=config["pipeline_dir"],
    blast_db="{sample}/primers_fastq/{sample}"
  output:
    fasta="{sample}/primers_fastq/{sample}.fasta",
    primers_reads="{sample}/primers_fastq/pcr_product.list",
    blast_res="{sample}/primers_fastq/blast_res.tab",
    primers_fastq="{sample}/primers_fastq/{sample}.fastq"
  shell:
    """
    seqtk seq -a {input.fastq} > {output.fasta}
    makeblastdb -dbtype nucl -input_type fasta -in {output.fasta} -out {params.blast_db}
    blastn -outfmt 6 -dust no -soft_masking false -evalue 1 -out {output.blast_res} -db {params.blast_db} -query {input.primers} -num_threads {threads} -max_target_seqs 100000000
    Rscript {params.pipeline_dir}/src/blast_pcr.R {output.blast_res} {output.primers_reads}
    seqtk subseq {input.fastq} {output.primers_reads} > {output.primers_fastq}
    """

rule length_filter:
  input:
    fastq=static_length_selection_input
  threads: 4
  params:
    min_l=int(config['expected_l']-config['deviation']),
    max_l=int(config['expected_l']+config['deviation'])
  output:
    filtered_fastq="{sample}/filtered_fastq/{sample}.fastq"
  shell:
    """
    if file {input.fastq} | grep -q compressed; then
      zcat {input.fastq} | NanoFilt -l {params.min_l} --maxlength {params.max_l} > {output.filtered_fastq}
    else
      cat {input.fastq} | NanoFilt -l {params.min_l} --maxlength {params.max_l} > {output.filtered_fastq}
    fi
    """

rule subsample:
  input: read_subsample_input
  threads: 1
  params:
    subsample_n=config["subsample"]
  output:
    subsample_fastq="{sample}/subsample_fastq/{sample}.fastq"
  shell:
    """
    if (( $(echo $(cat {input} | wc -l) / 4 | bc) > 1000 )); then
      seqtk sample -s100 {input} {params.subsample_n} > {output.subsample_fastq}
    else
      cp {input} {output.subsample_fastq}
    fi
    """
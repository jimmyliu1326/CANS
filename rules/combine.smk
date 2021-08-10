rule combine_fastq:
  input:
    fastq_dir=lambda wildcards: samples_meta.Path[wildcards.sample]
  output:
    combined_fastq=temp("{sample}/{sample}.fastq")
  threads: 1
  shell:
    "cat {input.fastq_dir}/*.fastq > {output.combined_fastq}"

rule combine_fastq_gz:
  input:
    fastq_dir=lambda wildcards: samples_meta.Path[wildcards.sample]
  output:
    combined_fastq=temp("{sample}/{sample}.fastq.gz")
  threads: 1
  shell:
    """
    cat {input.fastq_dir}/*.fastq.gz > {output.combined_fastq}
    """
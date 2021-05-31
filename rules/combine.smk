rule combine_fastq:
  input:
    fastq_dir=lambda wildcards: samples_meta.Path[wildcards.sample]
  output:
    combined_fastq="{sample}/{sample}.fastq"
  threads: 1
  shell:
    "cat {input.fastq_dir}/*.fastq > {output.combined_fastq}"
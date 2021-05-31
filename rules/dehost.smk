rule dehost:
  input:
    fastq=dehost_input,
    reference=config['reference']
  output:
    cleaned_fastq="{sample}/dehost/{sample}.fastq"
  threads: 8
  shell:
    """
    minimap2 -ax map-ont -t {threads} {input.reference} {input.fastq} | samtools view -bS -f4 -@ {threads} - | samtools fastq -@ {threads} - > {output.bam}
    """
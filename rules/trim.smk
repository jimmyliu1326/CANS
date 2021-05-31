rule porechop:
  input:
    reads="{sample}/{sample}.fastq"
  threads: 32
  output:
    trimmed_reads="{sample}/porechop/{sample}_trimmed.fastq"
  shell:
    """
    porechop -t {threads} -i {input.reads} -o {output.trimmed_reads}
    """
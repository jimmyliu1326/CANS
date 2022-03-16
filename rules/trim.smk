rule porechop:
  input:
    reads=trim_input
  threads: 32
  output:
    trimmed_reads="{sample}/porechop/{sample}_trimmed.fastq"
  shell:
    """
    porechop -t {threads} -i {input.reads} -o {output.trimmed_reads}
    """
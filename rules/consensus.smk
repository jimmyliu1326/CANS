rule draft_consensus:
  input: "{sample}/subsample_fastq/{sample}.fastq"
  output: "{sample}/draft_consensus/draft.fasta"
  threads: 4
  shell:
    """
    spoa -l 1 -s {input} > {output}
    """

rule medaka:
  input:
    subsample_reads="{sample}/subsample_fastq/{sample}.fastq",
    draft_consensus="{sample}/draft_consensus/draft.fasta"
  threads: config["threads"]
  params:
    outdir="{sample}/medaka",
    model=config["model"]
  output:
    consensus="{sample}/consensus/consensus.fa"
  shell:
    """
    medaka_consensus -i {input.subsample_reads} -d {input.draft_consensus} -o {params.outdir} -t {threads} -m {params.model} -f
    cp {params.outdir}/consensus.fasta {output.consensus}
    """  
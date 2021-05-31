# load rules
include: "rules/common.smk"
include: "rules/combine.smk"
include: "rules/consensus.smk"
include: "rules/dehost.smk"
include: "rules/read_selection.smk"
include: "rules/trim.smk"

# override current working directory
workdir: config["outdir"]

# define pipeline target
rule all:
  input: 
      expand("{sample}/consensus/consensus.fa", sample=samples_meta.Sample)
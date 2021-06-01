rule read_summary_report:
  input: 
    readlength_res=expand("{sample}/read_stats.tsv", sample=samples_meta.Sample),
    best_peak=expand("{sample}/best_peak.txt", sample=samples_meta.Sample)
  output: "report_summary.html"
  params:
    outdir=config["outdir"],
    subsample_n=config["subsample"],
    deviation=config['deviation']
  threads: 4
  script: config["pipeline_dir"]+"/src/report_viz.Rmd"


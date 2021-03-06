if config['mode'] == "dynamic":
  rule read_summary_report:
    input: 
      readlength_res=expand("{sample}/read_stats.tsv", sample=samples_meta.Sample),
      best_peak=expand("{sample}/best_peak.txt", sample=samples_meta.Sample)
    output: 
      # report=os.path.join("CANS_report_"+datetime.today().strftime('%Y%m%d%H%M%S')+".html")
      report="CANS_report.html"
    params:
      mode=config['mode'],
      outdir=config["outdir"],
      subsample_n=config["subsample"],
      deviation=config['deviation']
    threads: 4
    script: config["pipeline_dir"]+"/src/report_viz.Rmd"
else:
  rule read_summary_report:
    input: 
      readlength_res=expand("{sample}/read_stats.tsv", sample=samples_meta.Sample)
    output: 
      # report=os.path.join("CANS_report_"+datetime.today().strftime('%Y%m%d%H%M%S')+".html")
      report="CANS_report.html"
    params:
      mode=config['mode'],
      expected_l=config['expected_l'],
      outdir=config["outdir"],
      subsample_n=config["subsample"],
      deviation=config['deviation']
    threads: 4
    script: config["pipeline_dir"]+"/src/report_viz.Rmd"


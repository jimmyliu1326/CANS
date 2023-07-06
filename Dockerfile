FROM mambaorg/micromamba:0.14.0

RUN apt-get update && \
    apt-get install -y procps git bc && \
    rm -rf /var/lib/apt/lists/* && \
    CONDA_DIR="/opt/conda" && \
    git clone https://github.com/jimmyliu1326/CANS.git && \
    chmod +x /CANS/CANS.sh && \
    ln -s /CANS/CANS.sh /usr/local/bin/CANS.sh && \
    mkdir /.cache && \
    chmod a+rwX /.cache

RUN micromamba install -n base -y -c bioconda -c conda-forge -f /CANS/conda_env.yml && \
    micromamba clean --all --yes && \
    rm -rf $CONDA_DIR/conda-meta && \
    rm -rf $CONDA_DIR/include && \
    rm -rf $CONDA_DIR/lib/python3.*/site-packages/pip && \
    find $CONDA_DIR -name '__pycache__' -type d -exec rm -rf '{}' '+'
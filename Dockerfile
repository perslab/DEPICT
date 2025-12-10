# Dockerfile for DEPICT (perslab/depict) with Python 2.7, PLINK 1.9, Java
# Build (for HPC-compatible amd64) with e.g.:
#   docker buildx build --platform linux/amd64 -t depict:py2 .

FROM continuumio/miniconda3

LABEL maintainer="arno.vanhilten@sund.ku.dk"
LABEL description="Container for DEPICT (perslab/depict) with Python 2.7, PLINK 1.9, and Java"

# 1. System dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        unzip \
        git \
        default-jre-headless \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Create a dedicated Python 2.7 environment
RUN conda create -y -p /opt/conda/envs/depict python=2.7 && \
    conda clean -afy

# 3. Install required Python packages into that env
RUN /opt/conda/envs/depict/bin/pip install --no-cache-dir \
        pandas==0.24.2 \
        intervaltree

# 4. Make the Python 2.7 env the default Python in the container
ENV DEPICT_ENV=/opt/conda/envs/depict
ENV PATH="${DEPICT_ENV}/bin:/opt/plink:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 5. Install PLINK 1.9
RUN mkdir -p /opt/plink && \
    cd /opt/plink && \
    wget -qO plink.zip "https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip" && \
    unzip plink.zip && \
    rm plink.zip && \
    chmod +x plink && \
    ln -s /opt/plink/plink /usr/local/bin/plink

# 6. Clone DEPICT
WORKDIR /opt
COPY . /opt/depict
ENV DEPICT_HOME=/opt/depict

# 7. Data directory to mount user data (configs, GWAS, outputs)
RUN mkdir -p /data
VOLUME ["/data"]

# 8. Default working dir
WORKDIR /data

# Default shell
CMD ["bash"]

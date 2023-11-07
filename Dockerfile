FROM ubuntu:18.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    git \
    libx11-6 \
    python3-pip \
    gnupg \
    build-essential \
    apt-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /

# Set a working directory
RUN wget https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64
RUN dpkg -i /cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64
COPY libcudnn7_7.6.4.38-1+cuda10.0_amd64.deb /
RUN dpkg -i /libcudnn7_7.6.4.38-1+cuda10.0_amd64.deb
RUN apt-key add /var/cuda-repo-10-0-local-10.0.130-410.48/7fa2af80.pub
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y cuda-toolkit-10-0 libcudnn7=7.6.4.38-1+cuda10.0

# Install Miniconda and Python 3.6
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /miniconda && \
    rm ~/miniconda.sh && \
    /miniconda/bin/conda clean -tip && \
    ln -s /miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /miniconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    /miniconda/bin/conda create -y -n chemvae python=3.6 && \
    /miniconda/bin/conda clean -afy

# Make RUN commands use the new environment
SHELL ["/bin/bash", "--login", "-c"]

RUN echo '#! /bin/sh' > /usr/bin/mesg
RUN chmod 755 /usr/bin/mesg

# Activate the conda environment
RUN echo "source activate chemvae" > ~/.bashrc
ENV PATH /miniconda/envs/chemvae/bin:$PATH
ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs

RUN ln -sf /usr/lib/x86_64-linux-gnu/libcudnn.so.7 /usr/local/cuda/lib64/

WORKDIR /data

COPY . /data

ENV PIP_ROOT_USER_ACTION=ignore
RUN conda activate chemvae
RUN pip install -r requirements.txt

# Install any needed packages specified in setup.py
RUN python setup.py install

# Make port 8888 available to the world outside this container
EXPOSE 8888

# Define environment variable
ENV NAME chemvae

ENV PATH /miniconda/bin:$PATH

WORKDIR /workfiles

#ENTRYPOINT ["conda", "run", "-n", "chemvae", "python", "-m" "chemvae.trainvae.py"]


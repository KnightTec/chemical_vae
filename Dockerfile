# Use an official NVIDIA runtime as a parent image
FROM nvidia/cuda:10.0-cudnn7-runtime-ubuntu18.04

# Set a working directory
WORKDIR /workspace

RUN wget https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64
RUN dpkg -i cuda-repo-ubuntu1804-10-0-local-10.0.130-410.48_1.0-1_amd64.deb
RUN apt-key add /var/cuda-repo-<version>/7fa2af80.pub
RUN sudo apt-get update
RUN sudo apt-get install cuda

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    git \
    libx11-6 \
    python3-pip \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda and Python 3.6
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /miniconda && \
    rm ~/miniconda.sh && \
    /miniconda/bin/conda clean -tipsy && \
    ln -s /miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /miniconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    /miniconda/bin/conda create -y -n chemvae python=3.6 && \
    /miniconda/bin/conda clean -afy

# Make RUN commands use the new environment
SHELL ["/bin/bash", "--login", "-c"]

# Activate the conda environment
RUN echo "source activate chemvae" > ~/.bashrc
ENV PATH /miniconda/envs/chemvae/bin:$PATH

RUN cd chemical_vae

# Install the required packages
RUN pip install -r requirements.txt

# Install any needed packages specified in setup.py
RUN python setup.py install

# Make port 8888 available to the world outside this container
EXPOSE 8888

# Define environment variable
#ENV NAME chemvae

# Run a command under the conda environment
#CMD ["conda", "run", "-n", "chemvae", "python", "your_script.py"]

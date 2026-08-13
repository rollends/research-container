FROM ubuntu:noble

# Shell Configuration (use Bash).
RUN chsh -s /bin/bash
SHELL ["/bin/bash", "-c"]

# OS Package Installation.
RUN apt-get update &&\
    apt-get install -y build-essential curl git hunspell hunspell-en-ca imagemagick libffi-dev libffi8 libgmp10 libgmp-dev libncurses-dev locales pkg-config poppler-utils python3 python3-pip python3-venv rsync texlive-full zlib1g zlib1g-dev &&\
    rm -rf /var/lib/apt/lists/* &&\
    localedef -i en_CA -c -f UTF-8 -A /usr/share/locale/locale.alias en_CA.UTF-8 &&\
    apt-get clean

RUN mkhomedir_helper ubuntu
USER ubuntu
WORKDIR /home/ubuntu/

ENV LANG=en_CA.utf8

# Setting up the Haskell Install.
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_VERBOSE=1
ENV BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
ENV BOOTSTRAP_HASKELL_INSTALL_HLS=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION="9.10.3"
ENV BOOTSTRAP_HASKELL_STACK_VERSION="recommended"
ENV BOOTSTRAP_HASKELL_HLS_VERSION="latest"

# Install/Configure Haskell using ghcup
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | /bin/bash
RUN echo "source /home/ubuntu/.ghcup/env" >> /home/ubuntu/.bashrc

# Install Conda.
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" &&\
    bash Miniforge3-$(uname)-$(uname -m).sh -b &&\
    source /home/ubuntu/miniforge3/bin/activate &&\
    conda init bash

# Use a Conda activated environment as the default shell.
SHELL ["/home/ubuntu/miniforge3/bin/conda", "run", "--live-stream", "/bin/bash", "-c"]

# Install Sage in an environment named Sage.
RUN conda create -n sage sage python=3.11 pytest sphinx furo

# Ensure the Sage environment is used so that we can install the Sage (Jupyter) kernel.
SHELL ["/home/ubuntu/miniforge3/bin/conda", "run", "--live-stream", "-n", "sage", "/bin/bash", "-c"]

# Install the Sage Kernel.
COPY install_sage_kernel.py /tmp/
RUN python3 /tmp/install_sage_kernel.py

# Force GPG TTY to be set.
RUN echo "export GPG_TTY=$(tty)" >> /home/ubuntu/.bashrc
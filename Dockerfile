FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1 \
    PYTHON_VERSION=3.12.3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /home

COPY custom_rasterizer /custom_rasterizer

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
       wget \
       git \
       mc \
       build-essential \
       nvidia-cuda-toolkit && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean -y

# Компиляция Python 3.12
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz && \
    tar -xf Python-${PYTHON_VERSION}.tar.xz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tar.xz

RUN ln -fs /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -fs /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ln -fs /usr/local/bin/pip3.12 /usr/local/bin/pip

RUN pip install --no-cache-dir \
    torch==2.6.0 \
    torchvision==0.21.0 \
    torchaudio==2.6.0 \
    --index-url https://download.pytorch.org/whl/cu124

# Устанавливаем инструменты сборки
RUN pip install wheel ninja setuptools

# Настраиваем переменные окружения CUDA
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV TORCH_CUDA_ARCH_LIST="6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0"
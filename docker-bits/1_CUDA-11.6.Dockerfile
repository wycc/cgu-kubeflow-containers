# 更新基礎包並安裝必要的工具和 liburcu6
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates wget && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/libu/liburcu/liburcu6_0.11.1-2_amd64.deb && \
    dpkg -i liburcu6_0.11.1-2_amd64.deb && \
    rm liburcu6_0.11.1-2_amd64.deb && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*

# 配置 ld.so.conf.d 以包含 liburcu6
RUN echo "/usr/lib/x86_64-linux-gnu" > /etc/ld.so.conf.d/liburcu6.conf && ldconfig

ENV CUDA_VERSION 11.6.2

# 安裝 CUDA 11.6 的存儲庫密鑰
RUN apt-get update && apt-get install -y wget && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-11-6=11.6.55-1 \
    cuda-compat-11-6 \
    && ln -s cuda-11.6 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# 配置必要的環境變量
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# NVIDIA 容器運行時環境配置
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.6 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=450,driver<451 brand=tesla,driver>=470,driver<471"

ENV NCCL_VERSION 2.12.12

# 安裝 CUDA 11.6 相關的庫
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-11-6=11.6.2-1 \
    libnpp-11-6=11.6.3.124-1 \
    cuda-nvtx-11-6=11.6.124-1 \
    libcusparse-11-6=11.7.2.124-1 \
    libcublas-11-6=11.9.2.110-1 \
    libnccl2=$NCCL_VERSION-1+cuda11.6 \
    && apt-mark hold libnccl2 \
    && rm -rf /var/lib/apt/lists/*

ENV CUDNN_VERSION 8.4.1.50

LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

# 安裝 cuDNN
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcudnn8=$CUDNN_VERSION-1+cuda11.6 \
    && apt-mark hold libcudnn8 && \
    rm -rf /var/lib/apt/lists/*

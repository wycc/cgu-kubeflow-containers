# Cuda stuff for v11.1

## https://gitlab.com/nvidia/container-images/cuda/-/raw/master/dist/11.1/ubuntu18.04-x86_64/base/Dockerfile

###########################
### Base
###########################
# https://gitlab.com/nvidia/container-images/cuda/-/raw/master/dist/11.1/ubuntu18.04-x86_64/base/Dockerfile

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 11.2.0

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y wget && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-11-2=11.2.72-1 \
    cuda-compat-11-2 \
    && ln -s cuda-11.2 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.2 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441 brand=tesla,driver>=450,driver<451"
ENV NVIDIA_DISABLE_REQUIRE true

# ###########################
# ### Devel
# ###########################
# # https://gitlab.com/nvidia/container-images/cuda/-/raw/master/dist/11.1/ubuntu18.04-x86_64/devel/Dockerfile
#
# $(curl -s https://gitlab.com/nvidia/container-images/cuda/-/raw/master/dist/11.1/ubuntu18.04-x86_64/devel/Dockerfile)

###########################
### Runtime
###########################
# https://gitlab.com/nvidia/container-images/cuda/-/raw/master/dist/11.1/ubuntu18.04-x86_64/runtime/Dockerfile

ENV NCCL_VERSION 2.8.4

RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-11-2=11.2.0-1 \
    libnpp-11-2=11.2.1.68-1 \
    cuda-nvtx-11-2=11.2.67-1 \
    libcublas-11-2=11.3.1.68-1 \
    libnccl2=$NCCL_VERSION-1+cuda11.2 \
    && apt-mark hold libnccl2 \
    && rm -rf /var/lib/apt/lists/*

###########################
### CudNN
###########################
# https://gitlab.com/nvidia/container-images/cuda/-/raw/master/dist/11.1/ubuntu18.04-x86_64/runtime/cudnn8/Dockerfile

# ENV CUDNN_VERSION 8.1.1.33

# LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libcudnn8=$CUDNN_VERSION-1+cuda11.2 \
#     && apt-mark hold libcudnn8 && \
#     rm -rf /var/lib/apt/lists/*


ENV CUDNN_VERSION 8.2.1.32

LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcudnn8=$CUDNN_VERSION-1+cuda11.3 \
    && apt-mark hold libcudnn8 && \
    rm -rf /var/lib/apt/lists/*

# install TensorRT
RUN cd /tmp && \
    wget https://120.126.23.245:12345/data/tensorrt.tar.gz --no-check-certificate && \
    tar xzvf tensorrt.tar.gz && \
    cp -r TensorRT-8.2.1.8/bin/* /usr/bin && \
    cp -r TensorRT-8.2.1.8/lib/* /usr/lib && \
    cp -r TensorRT-8.2.1.8/include/* /usr/include && \
    pip install TensorRT-8.2.1.8/python/tensorrt-8.2.1.8-cp39-none-linux_x86_64.whl && \
    pip install TensorRT-8.2.1.8/uff/uff-0.6.9-py2.py3-none-any.whl && \
    pip install TensorRT-8.2.1.8/graphsurgeon/graphsurgeon-0.4.5-py2.py3-none-any.whl && \
    rm tensorrt.tar.gz && \
    rm -rf TensorRT-8.2.1.8

RUN apt-get update && apt-get install -y --allow-change-held-packages nvidia-cuda-toolkit libcudnn8 libcudnn8-dev

# fix lubcublas function mismatch
RUN rm /usr/lib/x86_64-linux-gnu/libcublas.so &&\
    ln -s /usr/local/cuda/lib64/libcublasLt.so.11 /usr/lib/x86_64-linux-gnu/libcublas.so
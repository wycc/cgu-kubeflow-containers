
###############################
###  .tmp/tensorflow.Dockerfile
###############################


###############################
###  docker-bits/0_cpu.Dockerfile
###############################

# Docker-stacks version tags (eg: `r-4.0.3`) are LIVE images that are frequently updated.  To avoid unexpected
# image updates, pin to the docker-stacks git commit SHA tag.
# It can be obtained by running `docker inspect repo/imagename:tag@digest` or from
# https://github.com/jupyter/docker-stacks/wiki

ARG BASE_VERSION=ed2908bbb62e
FROM jupyter/datascience-notebook:$BASE_VERSION

USER root

ENV PATH="/home/jovyan/.local/bin/:${PATH}"

RUN apt-get update --yes \
    && apt-get install --yes language-pack-fr \
    && rm -rf /var/lib/apt/lists/*

###############################
###  docker-bits/1_CUDA-11.1.Dockerfile
###############################

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
COPY TensorRT-8.2.1.8.Linux.x86_64-gnu.cuda-11.4.cudnn8.2.tar.gz /tmp/tensorrt.tar.gz
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

###############################
###  docker-bits/2_tensorflow.Dockerfile
###############################

# Install Tensorflow
RUN pip install --quiet \
        'tensorflow==2.5.0' \
        'keras' \
        'ipykernel==6.21.3' \
        'jupyterlab_tensorboard_pro' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install common package
RUN pip install --quiet \
        # 'git+https://github.com/fdsf53451001/nb_serverproxy_gradio.git' \
        'gradio' \
        'matplotlib' \
        'gdown' \
        'opencv-python' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# fix numpy for tensorflow
RUN pip install --quiet --no-dependencies \
    'numpy==1.20' \
&& \
fix-permissions $CONDA_DIR && \
fix-permissions /home/$NB_USER

###############################
###  docker-bits/3_Kubeflow.Dockerfile
###############################

USER root

# https://github.com/StatCan/aaw-kubeflow-containers/issues/293
RUN pip3 --no-cache-dir install --quiet \
      'Pillow==9.0.1' \
      'notebook==6.4.1' \
      'PyYAML==5.4.1' \
      'jupyterlab==3.5.3' && \
      fix-permissions $CONDA_DIR && \
      fix-permissions /home/$NB_USER

RUN pip3 --no-cache-dir install --quiet \
      'kubeflow-metadata==0.2.0' \
      'kubeflow-pytorchjob==0.1.3' \
      'kubeflow-tfjob==0.1.3' \
      'minio==5.0.10' \
      'joblib==1.2.0' \
      'git+https://github.com/zachomedia/s3fs@8aa929f78666ff9e323cde7d9be9262db5a17985' && \
      fix-permissions $CONDA_DIR && \
      fix-permissions /home/$NB_USER

RUN pip3 --no-cache-dir install --quiet \
      'fire==0.3.1' && \
      fix-permissions $CONDA_DIR && \
      fix-permissions /home/$NB_USER

###############################
###  docker-bits/4_CLI.Dockerfile
###############################

USER root

# Dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
      'byobu' \
      'htop' \
      'jq' \
      'less' \
      'openssl' \
      'ranger' \
      'tig' \
      'tmux' \
      'tree' \
      'vim' \
      'zip' \
      'zsh' \
      'wget' \
      'curl' \
  && \
    rm -rf /var/lib/apt/lists/*

COPY --from=minio/mc:RELEASE.2022-03-17T20-25-06Z /bin/mc /usr/local/bin/mc-original

ARG KUBECTL_VERSION=v1.15.10
ARG KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
ARG KUBECTL_SHA=38a0f73464f1c39ca383fd43196f84bdbe6e553fe3e677b6e7012ef7ad5eaf2b

ARG AZCLI_URL=https://aka.ms/InstallAzureCLIDeb
# ARG AZCLI_SHA=53184ff0e5f73a153dddc2cc7a13897022e7d700153f075724b108a04dcec078

ARG OH_MY_ZSH_URL=https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh
ARG OH_MY_ZSH_SHA=22811faf34455a5aeaba6f6b36f2c79a0a454a74c8b4ea9c0760d1b2d7022b03

ARG TRINO_URL=https://repo1.maven.org/maven2/io/trino/trino-cli/406/trino-cli-406-executable.jar
ARG TRINO_SHA=70f7ab57cf74f655942d14f4baafebac32ca64ca833790411691a69b574c16bb
# Add helpers for shell initialization
COPY shell_helpers.sh /tmp/shell_helpers.sh

# Install OpenJDK-8
RUN apt-get update && \
    apt-get install -y openjdk-8-jre && \
    apt-get clean && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# kubectl, mc, and az
RUN curl -LO "${KUBECTL_URL}" \
    && echo "${KUBECTL_SHA} kubectl" | sha256sum -c - \
    && chmod +x ./kubectl \
    && sudo mv ./kubectl /usr/local/bin/kubectl \
  && \
    curl -sLO https://aka.ms/InstallAzureCLIDeb \
    && bash InstallAzureCLIDeb \
    && rm InstallAzureCLIDeb \
    && echo "azcli: ok" \
  && \
    wget -q "${OH_MY_ZSH_URL}" -O /tmp/oh-my-zsh-install.sh \
    && echo "${OH_MY_ZSH_SHA} /tmp/oh-my-zsh-install.sh" | sha256sum -c \
    && echo "oh-my-zsh: ok" \
  && \
    wget -q "${TRINO_URL}" -O /tmp/trino-original \
    && echo ${TRINO_SHA} /tmp/trino-original | sha256sum -c \
    && echo "trinocli: ok" \
    && chmod +x /tmp/trino-original \
    && sudo mv /tmp/trino-original /usr/local/bin/trino-original

###############################
###  docker-bits/5_DB-Drivers.Dockerfile
###############################

# ODBC drivers
RUN apt-get update && \
    apt-get install -y alien unixodbc unixodbc-dev && \
    pip install --no-cache-dir --quiet 'pyodbc==4.0.30' && \
    rm -rf /var/lib/apt/lists/* && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

###############################
###  docker-bits/6_jupyterlab.Dockerfile
###############################

# installs vscode server, python & conda packages and jupyter lab extensions.

# Using JupyterLab 3.0 inherited docker-stacks base image. A few extensions we used to install do not yet support
# this version of Jupyterlab and/or are not OL-compliant so they have been removed until new compatible versions are available:
    # jupyterlab-kale
    # jupyterlab-variableinspector
    # jupyterlab-archive
    # jupyterlab-spellchecker
    # jupyterlab-spreadsheet

# Install vscode
ARG VSCODE_VERSION=4.10.0
ARG VSCODE_SHA=e0746fe7f013d367193060ec40eb81627957d8a8d6b850778a30d56fc54db276
ARG VSCODE_URL=https://github.com/coder/code-server/releases/download/v${VSCODE_VERSION}/code-server_${VSCODE_VERSION}_amd64.deb

USER root

ENV CS_DISABLE_FILE_DOWNLOADS=1
ENV XDG_DATA_HOME=/etc/share
ENV SERVICE_URL=https://extensions.coder.com/api

RUN wget -q "${VSCODE_URL}" -O ./vscode.deb \
    && echo "${VSCODE_SHA}  ./vscode.deb" | sha256sum -c - \
    && apt-get update \
    && apt-get install -y nginx \
    && dpkg -i ./vscode.deb \
    && rm ./vscode.deb \
    && rm -f /etc/apt/sources.list.d/vscode.list \
    && mkdir -p $HOME/.local/share \
    && mkdir -p $XDG_DATA_HOME/code-server/extensions

COPY vscode-overrides.json $XDG_DATA_HOME/code-server/Machine/settings.json
# Fix for VSCode extensions and CORS
# Languagepacks.json needs to exist for code-server to recognize the languagepack
COPY languagepacks.json $XDG_DATA_HOME/code-server/
ARG SHA256py=10368d0175e34583a84935e691dba122d4ece2e23305700f226b6807508a30b1

RUN code-server --install-extension ms-python.python@2022.16.1 && \
    code-server --install-extension REditorSupport.r@2.7.0 && \
    code-server --install-extension ms-ceintl.vscode-language-pack-fr@1.75.0 && \
    code-server --install-extension quarto.quarto@1.53.1 && \
    fix-permissions $XDG_DATA_HOME

# Default environment
RUN pip install --quiet \
      'jupyter-lsp==1.5.1' \
      'jupyter-server-proxy==3.2.2' \
      'jupyterlab_execute_time==2.3.1' \
      'markupsafe==2.1.2' \
      'git+https://github.com/betatim/vscode-binder' \
    && \
    # install custom extensions for jupyterlab
    pip install \
      'jupyterlab_tensorboard_pro' \
      'jupyterlab-rise' \
      'rise' \
    && \
    conda install --quiet --yes \
    -c conda-forge \
      'ipywidgets==8.0.4' \
      'ipympl==0.9.3' \
      'jupyter_contrib_nbextensions==0.7.0' \
      'nb_conda_kernels==2.3.1' \
    && \
    conda install --quiet --yes \
      -c plotly \
      'jupyter-dash==0.4.2' \
    && \
    pip install \
      'jupyterlab-git==0.41.0' \
      'jupyterlab-lsp==3.10.2' \
      'jupyterlab-language-pack-fr-FR' \
    && \
    conda clean --all -f -y && \
    jupyter serverextension enable --py jupyter_server_proxy && \
    jupyter nbextension enable codefolding/main --sys-prefix && \
    jupyter labextension install --no-build \
      '@jupyterlab/translation-extension@3.0.4' \
      '@jupyterlab/server-proxy@2.1.2' \
      'jupyterlab-plotly@4.14.3' \
      'nbdime-jupyterlab' \
    && \
    jupyter lab build && \
    jupyter lab clean && \
  npm cache clean --force && \
  rm -rf /home/$NB_USER/.cache/yarn && \
  rm -rf /home/$NB_USER/.node-gyp && \
  fix-permissions $CONDA_DIR && \
  fix-permissions /home/$NB_USER

# Update and pin packages
# See https://github.com/StatCan/aaw-kubeflow-containers/issues/293
RUN pip3 --no-cache-dir install --quiet \
      'pillow==9.4.0' \
      'matplotlib' \
      'ipywebrtc' \
      'notebook==6.5.3' \
      'pyyaml==6.0' \
      'jupyterlab==3.6.1' && \
      fix-permissions $CONDA_DIR && \
      fix-permissions /home/$NB_USER && \
      jupyter lab build && \
      jupyter lab clean

# Install python, R, Julia and other useful language servers
RUN julia -e 'using Pkg; Pkg.add("LanguageServer")' \
    && \
    conda install -c conda-forge \
      'r-languageserver' \
      'python-lsp-server' \
    && \
    npm i -g \
    'bash-language-server'  \
    'dockerfile-language-server-nodejs' \
    'javascript-typescript-langserver' \
    'unified-language-server' \
    'yaml-language-server@0.18.0'  && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER  \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install common package
RUN pip install --quiet \
        # 'git+https://github.com/fdsf53451001/nb_serverproxy_gradio.git' \
        'gradio' \
        'matplotlib' \
        'gdown' \
        'opencv-python' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Solarized Theme and Cell Execution Time
COPY jupyterlab-overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json

ENV DEFAULT_JUPYTER_URL=/lab
ENV GIT_EXAMPLE_NOTEBOOKS=https://github.com/fdsf53451001/cgu-contrib-jupyter-notebooks

###############################
###  docker-bits/7_remove_vulnerabilities.Dockerfile
###############################

# Remove libpdfbox-java due to CVE-2019-0228. See https://github.com/StatCan/aaw-kubeflow-containers/issues/249#issuecomment-834808115 for details.
# Issue opened https://github.com/jupyter/docker-stacks/issues/1299.
# This line of code should be removed once a solution or better alternative is found.
USER root
RUN apt-get update --yes \
    && dpkg -r --force-depends libpdfbox-java \
    && rm -rf /var/lib/apt/lists/*
USER $NB_USER

###############################
###  docker-bits/∞_CMD.Dockerfile
###############################

# Configure container startup

USER root
WORKDIR /home/$NB_USER
EXPOSE 8888
COPY start-custom.sh /usr/local/bin/
COPY mc-tenant-wrapper.sh /usr/local/bin/mc
COPY trino-wrapper.sh /usr/local/bin/trino

# Add --user to all pip install calls and point pip to Artifactory repository
# COPY pip.conf /tmp/pip.conf
# RUN cat /tmp/pip.conf >> /etc/pip.conf && rm /tmp/pip.conf \
#     && pip config set global.timeout 300

# Point R to Artifactory repository
COPY Rprofile.site /tmp/Rprofile.site
RUN cat /tmp/Rprofile.site >> /opt/conda/lib/R/etc/Rprofile.site && rm /tmp/Rprofile.site

# Point conda to Artifactory repository
# RUN conda config --add channels http://jfrog-platform-artifactory-ha.jfrog-system:8081/artifactory/api/conda/conda-forge-remote --system && \
#     conda config --remove channels conda-forge --system && \
#     conda config --add channels http://jfrog-platform-artifactory-ha.jfrog-system:8081/artifactory/api/conda/conda-forge-nvidia --system && \
#     conda config --add channels http://jfrog-platform-artifactory-ha.jfrog-system:8081/artifactory/api/conda/conda-pytorch-remote --system


USER root
ENTRYPOINT ["tini", "--"]
CMD ["start-custom.sh"]

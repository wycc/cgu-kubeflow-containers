
# mamba: conda's classic solver runs out of memory resolving this environment
# numpy 1.26.4 (the last 1.x release): pytorch 1.12 is built against numpy 1.x
RUN conda create -n pytorch python=3.9 && \
   mamba install -n pytorch --quiet --yes -c pytorch \
     'mkl-devel=2022.1.0'\
     'pytorch==1.12.1' \
     'torchvision==0.13.1' \
     'torchaudio==0.12.1' \
     'ipykernel==6.21.3' \
     'torchtext==0.13.1' \
     'numpy==1.26.4' \
   && \
   conda clean --all -f -y && \
   touch /etc/conda_disable_copy && \
   fix-permissions $CONDA_DIR && \
   fix-permissions /home/$NB_USER

# Install common package
# Versions are pinned: newer opencv-python requires numpy 2, newer huggingface_hub is incompatible with gradio 4
RUN source /opt/conda/bin/activate pytorch && \
    pip install --quiet \
        # 'git+https://github.com/fdsf53451001/nb_serverproxy_gradio.git' \
        'gradio==4.44.1' \
        'huggingface_hub==0.30.2' \
        'matplotlib==3.6.0' \
        'RISE==5.7.1' \
        'ipyvolume==0.6.3' \
        'gdown==5.2.0' \
        'opencv-python==4.11.0.86' \
        'numpy==1.26.4' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER
COPY  enable_persistent.ipynb /opt/conda/

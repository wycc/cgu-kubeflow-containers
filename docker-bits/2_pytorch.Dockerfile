# 安裝PyTorch
RUN pip install --quiet \
    'torch==1.12.1' \
    'torchvision==0.13.1' \
    'torchaudio==0.12.1' \
    'ipykernel==6.21.3' \
    'jupyterlab_tensorboard_pro' \
    'tensorboard==2.13.0' \
    'matplotlib' \
    'RISE' \
    'ipyvolume' \
    'gdown' \
    'tqdm' \
    'opencv-python' \
    && fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER
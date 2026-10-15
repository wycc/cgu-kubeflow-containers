# 安裝PyTorch
# Versions are pinned: newer opencv-python requires numpy 2, which breaks pandas, scikit-learn and matplotlib
RUN pip install --quiet \
    'torch==1.13.1' \
    'torchvision==0.14.1' \
    'torchaudio==0.13.1' \
    'ipykernel==6.21.3' \
    'jupyterlab_tensorboard_pro==4.0.0' \
    'tensorboard==2.13.0' \
    'matplotlib==3.6.0' \
    'RISE==5.7.1' \
    'ipyvolume==0.6.3' \
    'gdown==5.2.0' \
    'tqdm==4.64.1' \
    'opencv-python==4.11.0.86' \
    && fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

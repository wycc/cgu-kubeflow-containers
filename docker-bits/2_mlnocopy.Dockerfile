RUN pip install --quiet \
        'jupyterlab_tensorboard_pro' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# 建立PyTorch環境，但是不在這邊安裝
RUN conda create -n pytorch python=3.9 -y && \
    touch /etc/conda_disable_copy && \
    conda clean --all -f -y

# 在PyTorch環境中使用pip安裝所有需要的package
RUN conda run -n pytorch pip install --quiet \
    'torch==1.12.1' \
    'torchvision==0.13.1' \
    'torchaudio==0.12.1' \
    'ipykernel==6.21.3' \
    'tensorboard==2.13.0' \
    'matplotlib' \
    'RISE' \
    'ipyvolume' \
    'gdown' \
    'tqdm' \
    'opencv-python' \
    && fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# 建立TensorFlow環境，同樣不在建立時安裝package
RUN conda create -n tensorflow python=3.9 -y && \
    conda clean --all -f -y

# 在TensorFlow環境中使用pip安裝需要的package
RUN conda run -n tensorflow pip install --quiet \
    'tensorflow==2.8.2' \
    'keras' \
    'ipykernel==6.21.3' \
    'gradio' \
    'matplotlib' \
    'RISE' \
    'ipyvolume' \
    'gdown' \
    'opencv-python' \
    'numpy==1.20' \
    && fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER
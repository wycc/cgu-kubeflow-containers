# 創建並激活名為 monai 的 PyTorch conda 環境
RUN conda create -n monai python=3.9 && \
    conda install -n monai --quiet --yes -c pytorch \
     'pytorch==1.12.1' \
     'torchvision==0.13.1' \
     'torchaudio==0.12.1' \
     'ipykernel==6.21.3' \
     'torchtext==0.13.1' \
   && \
   touch /etc/conda_disable_copy && \
   conda clean --all -f -y && \
   fix-permissions $CONDA_DIR && \
   fix-permissions /home/$NB_USER

# 安裝常用套件至 monai 環境
RUN source /opt/conda/bin/activate monai && \ 
    pip install --quiet \
        'tensorboard==2.13.0' \
        'numpy==1.25.1' \
        'itk==5.3.0' \
        'nibabel==5.1.0' \
        'scikit-image==0.21.0' \
        'Pillow==10.0.0' \
        'gdown==4.7.1' \
        'tqdm==4.65.0' \
        'lmdb==1.4.1' \
        'psutil==5.9.0' \
        'pandas==2.0.3' \
        'einops==0.6.1' \
        'transformers==4.31.0' \
        'mlflow==2.5.0' \
        'pynrrd==1.0.0'

# 安裝 MONAI 和 pytorch-ignite 到 monai 環境
RUN source /opt/conda/bin/activate monai && \ 
    pip install --quiet \
        'monai==1.3.0' \
        'pytorch-ignite==0.4.12' && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

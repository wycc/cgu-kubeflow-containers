# 創建並激活名為 cv 的 PyTorch conda 環境
RUN conda create -n cv python=3.9 && \
    conda install -n cv --quiet --yes -c pytorch \
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

# 安裝 cv相關套件 到 cv 環境
RUN source /opt/conda/bin/activate cv && \ 
    pip install --quiet \
        'opencv-python' \
        'open3d==0.17.0' \
        'Pillow==10.0.0' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

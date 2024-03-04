# pytorch
RUN conda create -n pytorch python=3.9 && \
   conda install -n pytorch --quiet --yes -c pytorch \
     'pytorch==1.12.1' \
     'torchvision==0.13.1' \
     'torchaudio==0.12.1' \
     'ipykernel==6.21.3' \
     'torchtext==0.13.1' \
   && \
   conda clean --all -f -y && \
   fix-permissions $CONDA_DIR && \
   fix-permissions /home/$NB_USER

RUN conda run -n pytorch pip install --quiet \
        # 'git+https://github.com/fdsf53451001/nb_serverproxy_gradio.git' \
        'gradio' \
        'matplotlib' \
        'gdown' \
        'opencv-python' \
        # 'rise' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Tensorflow
RUN conda create -n tensorflow python=3.9 && \
    conda install -n tensorflow --quiet --yes -c "https://repo.anaconda.com/pkgs/main" \
        'tensorflow==2.8.2=gpu_py39hc0c9373_0' \
        'keras' \
        'ipykernel==6.21.3' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN conda run -n tensorflow pip install --quiet \
        'gradio' \
        'matplotlib' \
        'gdown' \
        'opencv-python' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

ENV CONDA_COPY yes
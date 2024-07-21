
RUN conda create -n pytorch python=3.9 && \
   conda install -n pytorch --quiet --yes -c pytorch \
     'mkl-devel=2022.1.0'\
     'pytorch==1.12.1' \
     'torchvision==0.13.1' \
     'torchaudio==0.12.1' \
     'ipykernel==6.21.3' \
     'torchtext==0.13.1' \
   && \
   conda clean --all -f -y && \
   touch /etc/conda_disable_copy && \
   fix-permissions $CONDA_DIR && \
   fix-permissions /home/$NB_USER

# Install common package
RUN source /opt/conda/bin/activate pytorch && \ 
    pip install --quiet \
        # 'git+https://github.com/fdsf53451001/nb_serverproxy_gradio.git' \
        'gradio' \
        'matplotlib' \
        'RISE' \
        'ipyvolume' \
        'gdown' \
        'opencv-python' \
        'pycairo==1.22.0' \
        'manim==0.18.1' \
    && \
    apt install dvisvgm -y  && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER
COPY  enable_persistent.ipynb /opt/conda/

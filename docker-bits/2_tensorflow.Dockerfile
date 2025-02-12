# Install Tensorflow
RUN pip install --quiet \
        'tensorflow==2.8.2' \
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

# fix numpy for tensorflow
RUN pip install --quiet --no-dependencies \
    'numpy==1.20' \
&& \
fix-permissions $CONDA_DIR && \
fix-permissions /home/$NB_USER

COPY  enable_persistent.ipynb /opt/conda/

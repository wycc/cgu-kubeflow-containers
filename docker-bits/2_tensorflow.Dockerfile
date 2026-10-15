# Install Tensorflow
# protobuf is pinned: TensorFlow 2.8 does not work with protobuf 4+
RUN pip install --quiet \
        'tensorflow==2.8.2' \
        'keras==2.8.0' \
        'protobuf==3.19.6' \
        'ipykernel==6.21.3' \
        'jupyterlab_tensorboard_pro==4.0.0' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install common package
# Versions are pinned: newer opencv-python requires numpy 2, newer huggingface_hub is incompatible with gradio 4
RUN pip install --quiet \
        # 'git+https://github.com/fdsf53451001/nb_serverproxy_gradio.git' \
        'gradio==4.44.1' \
        'huggingface_hub==0.30.2' \
        'matplotlib==3.6.0' \
        'RISE==5.7.1' \
        'ipyvolume==0.6.3' \
        'gdown==5.2.0' \
        'opencv-python==4.11.0.86' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# fix numpy for tensorflow
# numpy 1.26.4 works with both TensorFlow 2.8.2 and the base image's pandas 1.5.0
RUN pip install --quiet --no-dependencies \
    'numpy==1.26.4' \
&& \
fix-permissions $CONDA_DIR && \
fix-permissions /home/$NB_USER

COPY  enable_persistent.ipynb /opt/conda/

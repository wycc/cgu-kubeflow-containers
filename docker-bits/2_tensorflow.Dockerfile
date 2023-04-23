# Install Tensorflow
RUN pip install --quiet \
        'tensorflow==2.5.0' \
        'keras' \
        'ipykernel==6.21.3' \
        'jupyterlab_tensorboard_pro' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

RUN pip install --quiet --no-dependencies \
        'numpy==1.20' \
    && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Configure container startup

USER root

WORKDIR /home/$NB_USER
EXPOSE 8888
COPY start-remote-desktop.sh /usr/local/bin/
COPY mc-tenant-wrapper.sh /usr/local/bin/mc
COPY trino-wrapper.sh /usr/local/bin/trino
RUN chmod +x /usr/local/bin/trino
RUN chsh -s /bin/bash $NB_USER

# Add --user to all pip install calls and point pip to Artifactory repository
#COPY pip.conf /tmp/pip.conf
#RUN cat /tmp/pip.conf >> /etc/pip.conf && rm /tmp/pip.conf \
#    && pip config set global.timeout 300

# Point conda to Artifactory repository
#COPY .condarc /tmp/.condarc
#RUN cat /tmp/.condarc > /opt/conda/.condarc && rm /tmp/.condarc
RUN rm -rf /opt/conda/envs && \
    ln -s /home/jovyan/envs /opt/conda && \
    mkdir -p /home/jovyan/envs

# Point R to Artifactory repository
COPY Rprofile.site /tmp/Rprofile.site
RUN cat /tmp/Rprofile.site >> /usr/local/lib/R/etc/Rprofile.site && rm /tmp/Rprofile.site


#USER $NB_USER
USER root
ENTRYPOINT ["tini", "--"]
CMD ["start-remote-desktop.sh"]


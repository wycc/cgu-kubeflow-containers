# Configure container startup

USER root
WORKDIR /home/$NB_USER
EXPOSE 8888
COPY start-custom.sh /usr/local/bin/ 
COPY mc-tenant-wrapper.sh /usr/local/bin/mc
COPY trino-wrapper.sh /usr/local/bin/trino

# Add --user to all pip install calls and point pip to Artifactory repository
# COPY pip.conf /tmp/pip.conf
# RUN cat /tmp/pip.conf >> /etc/pip.conf && rm /tmp/pip.conf \
#     && pip config set global.timeout 300

# Point R to Artifactory repository
COPY Rprofile.site /tmp/Rprofile.site
RUN cat /tmp/Rprofile.site >> /opt/conda/lib/R/etc/Rprofile.site && rm /tmp/Rprofile.site

# Point conda to Artifactory repository
# RUN conda config --add channels http://jfrog-platform-artifactory-ha.jfrog-system:8081/artifactory/api/conda/conda-forge-remote --system && \
#     conda config --remove channels conda-forge --system && \
#     conda config --add channels http://jfrog-platform-artifactory-ha.jfrog-system:8081/artifactory/api/conda/conda-forge-nvidia --system && \
#     conda config --add channels http://jfrog-platform-artifactory-ha.jfrog-system:8081/artifactory/api/conda/conda-pytorch-remote --system

# This is for manim
RUN apt-get update && apt-get install -y --fix-broken && \
    apt-get install -y libcogl-pango-dev gir1.2-coglpango-1.0 libcairo2-dev libcogl-dev libcogl-pango20 libdrm-dev libglib2.0-dev libpango1.0-dev libx11-dev libxcomposite-dev libxdamage-dev libxext-dev libxfixes-dev libpdfbox-java

USER root
ENTRYPOINT ["tini", "--"]
# change the start script
CMD ["start-custom.sh"]

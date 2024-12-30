# 移除 libpdfbox-java 以避免 CVE-2019-0228 的安全問題
# 詳情參見 https://github.com/StatCan/aaw-kubeflow-containers/issues/249#issuecomment-834808115
# 問題已在 https://github.com/jupyter/docker-stacks/issues/1299 中提出
# 一旦找到解決方案或更好的替代方案，應該移除此行代碼。

USER root

# 更新並安裝 libcogl-pango-dev 及其依賴項，然後移除 libpdfbox-java
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcogl-pango-dev \
    gir1.2-coglpango-1.0 \
    libcairo2-dev \
    libcogl-dev \
    libcogl-pango20 \
    libdrm-dev \
    libglib2.0-dev \
    libpango1.0-dev \
    libx11-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxext-dev \
    libxfixes-dev \
    && apt-get install -f \
    && dpkg -r --force-depends libpdfbox-java \
    && rm -rf /var/lib/apt/lists/*

USER $NB_USER

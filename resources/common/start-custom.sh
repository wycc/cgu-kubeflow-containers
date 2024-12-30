#!/bin/bash

# 設置MPS環境變量
export CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps
export CUDA_MPS_LOG_DIRECTORY=/var/log/nvidia-mps
export CUDA_MPS_ACTIVE_THREAD_PERCENTAGE=50

# 啟動MPS控制守護進程
nvidia-cuda-mps-control -d

# 設置默認的設備pinned內存限制
echo set_default_device_pinned_mem_limit 0 12G | nvidia-cuda-mps-control

# 添加等待以確保MPS控制守護進程完全啟動
sleep 5

# 確保MPS守護進程啟動成功後再設置具體的內存限制
pid=$(pgrep -f nvidia-cuda-mps-control)
if [ -n "$pid" ]; then
    echo set_device_pinned_mem_limit $pid 0 12G | nvidia-cuda-mps-control
else
    echo "MPS控制守護進程未啟動"
fi

# 限制具體客戶端的內存限制
export CUDA_MPS_DEVICE_MEM_LIMIT="0=12G"

# 啟動其他應用或任務
# 這裡可以放其他需要啟動的命令或腳本


# move conda env to home directory to keep packages data
echo "--------------------Do we need to copy files?--------------------"
if [ ! -f /etc/conda_disable_copy ]; then
  if [ ! -d /home/jovyan/envs ]; then
    echo "--------------------Copy files now--------------------"
    cp -a /opt/conda/envs /home/jovyan/conda/envs
  fi
else
  if [ ! -f /home/jovyan/enable_persistent.ipynb ]; then
    (cd /home/jovyan; wget https://raw.githubusercontent.com/wycc/cgu-kubeflow-containers/master/resources/common/enable_persistent.ipynb)
  fi
fi

if [ -d /home/jovyan/envs/tensorflow ]; then
  echo "--------------------build symbolic links for tensorflow --------------------"
  mv /opt/conda/envs /opt/conda/envs.old
  ln -s /home/jovyan/envs /opt/conda/envs
fi

if [ -d /home/jovyan/envs/pytorch ]; then
  echo "--------------------build symbolic links for pytorch --------------------"
  mv /opt/conda/envs /opt/conda/envs.old 
  ln -s /home/jovyan/envs /opt/conda/envs
fi

echo "--------------------Starting up--------------------"
if [ -d /var/run/secrets/kubernetes.io/serviceaccount ]; then
  while ! curl -s -f http://127.0.0.1:15020/healthz/ready; do sleep 1; done
fi

echo "Checking if we want to sleep infinitely"
if [[ -z "${INFINITY_SLEEP}" ]]; then
  echo "Not sleeping"
else
  echo "--------------------zzzzzz--------------------"
  sleep infinity
fi

test -z "$GIT_EXAMPLE_NOTEBOOKS" || git clone "$GIT_EXAMPLE_NOTEBOOKS"

# Configure the shell! If not already configured.
# if [ ! -f /home/$NB_USER/.zsh-installed ]; then
#     if [ -f /tmp/oh-my-zsh-install.sh ]; then
#       sh /tmp/oh-my-zsh-install.sh --unattended --skip-chsh
#     fi

#     if conda --help > /dev/null 2>&1; then
#       conda init bash
#       conda init zsh
#     fi
#     cat /tmp/shell_helpers.sh >> /home/$NB_USER/.bashrc
#     cat /tmp/shell_helpers.sh >> /home/$NB_USER/.zshrc
#     touch /home/$NB_USER/.zsh-installed
#     touch /home/$NB_USER/.hushlogin
# fi

export VISUAL="/usr/bin/nano"
export EDITOR="$VISUAL"

echo "shell has been configured"

# create .profile
cat <<EOF > $HOME/.profile
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
EOF

echo ".profile has been created"

# Configure the language
if [ -n "${KF_LANG}" ]; then
    if [ "${KF_LANG}" = "en" ]; then
        export LANG="en_US.utf8"
    else
        export LANG="fr_CA.utf8"
        #  User's browser lang is set to French, open jupyterlab and vs_code in French (fr_FR)
        if [ "${DEFAULT_JUPYTER_URL}" != "/rstudio" ]; then
          export LANG="fr_FR"
          lang_file="/home/${NB_USER}/.jupyter/lab/user-settings/@jupyterlab/translation-extension/plugin.jupyterlab-settings"
          mkdir -p "$(dirname "${lang_file}")" && touch $lang_file
          ( echo    '{'
            echo     '   // Langue'
            echo     '   // @jupyterlab/translation-extension:plugin'
            echo     '   // Paramètres de langue.'
            echo  -e '   // ****************************************\n'
            echo     '   // Langue locale'
            echo     '   // Définit la langue d'\''affichage de l'\''interface. Exemples: '\''es_CO'\'', '\''fr'\''.'
            echo     '   "locale": "'${LANG}'"'
            echo     '}'
          ) > $lang_file
          vscode_language="${XDG_DATA_HOME}/code-server/User/argv.json"
          echo "{\"locale\":\"fr\"}" >> $vscode_language
        fi
    fi
fi

echo "language has been configured"

# Configure KFP multi-user
if [ -n "${NB_NAMESPACE}" ]; then
mkdir -p $HOME/.config/kfp
cat <<EOF > $HOME/.config/kfp/context.json
{"namespace": "${NB_NAMESPACE}"}
EOF
fi

echo "KFP multi-user has been configured"

# Introduced by RStudio 1.4
# See https://github.com/jupyterhub/jupyter-rsession-proxy/issues/95
# And https://github.com/blairdrummond/jupyter-rsession-proxy/blob/master/jupyter_rsession_proxy/__init__.py
export RSERVER_WWW_ROOT_PATH=$NB_PREFIX/rstudio

# Remove a Jupyterlab 2.x config setting that breaks Jupyterlab 3.x
NOTEBOOK_CONFIG="$HOME/.jupyter/jupyter_notebook_config.json"
NOTEBOOK_CONFIG_TMP="$HOME/.jupyter/jupyter_notebook_config.json.tmp"

if [ -f "$NOTEBOOK_CONFIG" ]; then
  jq 'del(.NotebookApp.server_extensions)' "$NOTEBOOK_CONFIG" > "$NOTEBOOK_CONFIG_TMP" \
      && mv -f "$NOTEBOOK_CONFIG_TMP" "$NOTEBOOK_CONFIG"
fi

echo "broken configuration settings removed"

export NB_NAMESPACE=$(echo $NB_PREFIX | awk -F '/' '{print $3}')
export JWT="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Revert forced virtualenv, was causing issues with users
#export PIP_REQUIRE_VIRTUALENV=true
#echo "Checking if Python venv exists"
#if [[ -d "base-python-venv" ]]; then
#  echo "Base python venv exists, not going to create again"
#else
#  echo "Creating python venv"
#  python3 -m venv $HOME/base-python-venv
#  echo "adding include-system-site-packages"
#fi

echo "Checking for .condarc file in hom directory"
if [[ -f "$HOME/.condarc" ]]; then
  echo ".condarc file exists, not going to do anything"
else
  echo "Creating basic .condarc file"
  printf 'envs_dirs:\n  - $HOME/.conda/envs' > $HOME/.condarc
  mkdir -p $HOME/.conda/envs
fi


printenv | grep KUBERNETES >> /opt/conda/lib/R/etc/Renviron

VS_CODE_SETTINGS=/etc/share/code-server/Machine/settings.json
VS_CODE_PRESISTED=$HOME/.local/share/code-server/Machine/settings.json
if [ -f "$VS_CODE_PRESISTED" ]; then
  cp "$VS_CODE_PRESISTED" "$VS_CODE_SETTINGS"
else
  cp vscode-overrides.json "$VS_CODE_SETTINGS"
fi


# Check and restore symbolic link for Conda
echo "--------------------Checking and restoring symbolic link for Conda if needed--------------------"
if [ -d /home/jovyan/conda ] && [ ! "$(readlink -f /opt/conda)" = "/home/jovyan/conda" ]; then
  echo "Restoring symbolic link for Conda environment..."
  # Remove any existing Conda directory or symbolic link
  rm -rf /opt/conda
  # Create a new symbolic link pointing to the correct Conda directory
  ln -s /home/jovyan/conda /opt/conda
  echo "Symbolic link for Conda environment restored."
else
  echo "Symbolic link for Conda environment is intact."
fi

echo "--------------------starting jupyter--------------------"

/opt/conda/bin/jupyter server --notebook-dir=/home/${NB_USER} \
                 --allow-root \
                 --ip=0.0.0.0 \
                 --no-browser \
                 --port=8888 \
                 --ServerApp.token='' \
                 --ServerApp.password='' \
                 --ServerApp.allow_origin='*' \
                 --ServerApp.authenticate_prometheus=False \
                 --ServerApp.base_url=${NB_PREFIX} \
                 --ServerApp.default_url=${DEFAULT_JUPYTER_URL:-/tree}

echo "--------------------shutting down, persisting VS_CODE settings--------------------"
# persist vscode server remote settings (Machine dir)
VS_CODE_SETTINGS_PERSIST=$HOME/.local/share/code-server/Machine/settings.json
cp $VS_CODE_SETTINGS $VS_CODE_SETTINGS_PERSIST

#!/bin/bash

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


if conda --help > /dev/null 2>&1; then
    conda init bash
    conda init zsh
fi

# Configure the language
if [ -n "${KF_LANG}" ]; then
    if [ "${KF_LANG}" = "en" ]; then
        export LANG="en_US.utf8"
    else
        export LANG="fr_CA.utf8"
        #  User's browser lang is set to french, open jupyterlab in french (fr_FR)
        if [ "${DEFAULT_JUPYTER_URL}" != "/rstudio" ]; then
          export LANG="fr_FR"
          lang_file="$HOME/.jupyter/lab/user-settings/@jupyterlab/translation-extension/plugin.jupyterlab-settings"
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
        fi
    fi

    # VS-Code i18n stuff
    if [ "${KF_LANG}" = "fr" ]; then
        export LANG="fr_FR.UTF-8"
        export LANGUAGE="fr_FR.UTF-8"
        export LC_ALL="fr_FR.UTF-8"
        #Set the locale for vscode
        mkdir -p $HOME/.vscode
        jq -e '.locale="fr"' $HOME/.vscode/argv.json > /tmp/file.json.tmp
        mv /tmp/file.json.tmp $HOME/.vscode/argv.json
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

# Create desktop shortcuts
if [ -d $RESOURCES_PATH/desktop-files ]; then
    mkdir -p ~/.local/share/applications/ $HOME/Desktop
    echo find $RESOURCES_PATH/desktop-files/ $HOME/Desktop/
    find $RESOURCES_PATH/desktop-files/ -type f -iname "*.desktop" -exec cp {} $HOME/Desktop/ \;
    rsync $RESOURCES_PATH/desktop-files/.config/ $HOME/.config/
    find $HOME/Desktop -type f -iname "*.desktop" -exec chmod +x {} \;
    mkdir -p $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/
    cp /opt/install/desktop-files/.config/xfce4/xfce4-panel.xml $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/

    if [ -d /opt/lampp/ ]; then
        # 確保 $HOME/lampp/ 存在
        mkdir -p $HOME/lampp
        # 對於 logs 資料夾
        if [ -d /opt/lampp/logs/ ]; then
            if [ ! -d "$HOME/lampp/logs" ]; then
                cp -a /opt/lampp/logs $HOME/lampp
            fi
            mv /opt/lampp/logs /opt/lampp/logs.old
            ln -sfT $HOME/lampp/logs/ /opt/lampp/logs
        fi
        # 對於 phpmyadmin 資料夾
        if [ -d /opt/lampp/phpmyadmin/ ]; then
            if [ ! -d "$HOME/lampp/phpmyadmin" ]; then
                cp -a /opt/lampp/phpmyadmin $HOME/lampp
            fi
            mv /opt/lampp/phpmyadmin /opt/lampp/phpmyadmin.old
            ln -sfT $HOME/lampp/phpmyadmin/ /opt/lampp/phpmyadmin
        fi
        # 對於 temp 資料夾
        if [ -d /opt/lampp/temp/ ]; then
            if [ ! -d "$HOME/lampp/temp" ]; then
                cp -a /opt/lampp/temp $HOME/lampp
            fi
            mv /opt/lampp/temp /opt/lampp/temp.old
            ln -sfT $HOME/lampp/temp/ /opt/lampp/temp
        fi
        # 對於 var 資料夾
        if [ -d /opt/lampp/var/ ]; then
            if [ ! -d "$HOME/lampp/var" ]; then
                cp -a /opt/lampp/var $HOME/lampp
            fi
            mv /opt/lampp/var /opt/lampp/var.old
            ln -sfT $HOME/lampp/var/ /opt/lampp/var
        fi
    fi
    if [ -d /opt/catkin_ws/ ]; then
        . /opt/ros/noetic/setup.bash
        if [ ! -d $HOME/catkin_ws ]; then
            mkdir -p $HOME/catkin_ws
            mv /opt/catkin_ws/src $HOME/catkin_ws
            mv /opt/catkin_ws/devel $HOME/catkin_ws
            mv /opt/catkin_ws/build $HOME/catkin_ws
            cd $HOME/catkin_ws && catkin_make
            echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc
            cd $HOME/catkin_ws && catkin_make && . devel/setup.bash
            echo "export TURTLEBOT3_MODEL=waffle_pi" >> ~/.bashrc
            echo "export CUDA_CACHE_MAXSIZE=4294967296" >> ~/.bashrc
        fi
    fi
fi

export NB_NAMESPACE=$(echo $NB_PREFIX | awk -F '/' '{print $3}')
export JWT="$(echo /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Revert, is causing issues
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
fi

mkdir -p $HOME/.vnc
[ -f $HOME/.vnc/xstartup ] || {
    cat <<EOF > $HOME/.vnc/xstartup
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
sed -i '86a export XMODIFIERS=@im=ibus\nexport GTK_IM_MODULE=ibus\nexport QT_IM_MODULE=ibus\nibus-daemon -dxr\nsleep 5s' /etc/xdg/xfce4/xinitrc
startxfce4 &


# Makes an unbelievable difference in speed
(sleep 10 && xdg-settings set default-web-browser firefox.desktop) &
(sleep 10 && xfconf-query -c xfwm4 -p /general/use_compositing -s false && dconf write /org/gnome/terminal/legacy/profiles/custom-command "'/bin/bash'") &
EOF
    chmod +x $HOME/.vnc/xstartup
}

mkdir -p /tmp/vnc-socket/
VNC_SOCKET=$(mktemp /tmp/vnc-socket/vnc-XXXXXX.sock)
trap "rm -f $VNC_SOCKET" EXIT
vncserver -SecurityTypes None -rfbunixpath $VNC_SOCKET -geometry 1680x1050 :1
cat $HOME/.vnc/*.log

(socat -d -d PTY,link=/dev/ttyS0,waitslave,echo=0,raw,unlink-close=0 TCP-LISTEN:5680,reuseaddr,fork) &
(/usr/bin/python3 /usr/local/bin/websockify --cert /opt/novnc/utils/self.pem 5679 127.0.0.1:5680) &


echo "novnc has been configured, launching novnc"
#TODO: Investigate adding vscode extensions to be persisted
# Launch noVNC
(
    # cd /tmp/novnc/
    cd /opt/novnc/
    ./utils/novnc_proxy --web $(pwd) --heartbeat 30 --vnc --unix-target=$VNC_SOCKET --listen 5678
) &

NB_PREFIX=${NB_PREFIX:-/vnc}
sed -i "s~\${NB_PREFIX}~$NB_PREFIX~g" /etc/nginx/nginx.conf

# start php service, and tinyfilemanager
service php8.1-fpm start
mv /var/www/html/index.php $HOME/index.php

# fix home folder permission
# chown jovyan:users $HOME/*



nginx
wait

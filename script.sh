#!/bin/bash

set -e

sudo dnf update -y && sudo dnf upgrade -y

echo "instalando programas que uso"


sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install -y fd-find wget curl gcc fzf pipx vim dnf-plugins-core \
	 make automake gcc gcc-c++ kernel-devel google-chrome-stable golang virtualbox emacs \
	 python3-tkinter swaylock swayidle waybar wlroots foot wofi mako \
	 akmod-nvidia xorg-x11-drv-nvidia-cudamesa-vulkan-drivers mesa-dri-drivers \
	 podman podman-compose 

curl -fsSL https://repo.librewolf.net/librewolf.repo | pkexec tee /etc/yum.repos.d/librewolf.repo
sudo dnf install -y librewolf


echo "instalando flatpaks"
flatpak install flathub io.github.shiftey.Desktop
flatpak install flathub org.soapui.SoapUI
flatpak install flathub io.dbeaver.DBeaverCommunity

echo "instalando o docker"
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

echo "instalando e configurando UV Python"
pipx install uv

echo 'Criando o comando "atualizar"'
sudo tee /usr/local/bin/atualizar >/dev/null <<'EOF'
#!/bin/bash

set -e

echo -e "Atualizando pacotes DNF..."
sudo dnf update -y

echo -e "Fazendo upgrade do sistema..."
sudo dnf upgrade -y

echo -e "Atualizando Flatpaks..."
sudo flatpak update -y

echo -e "Removendo pacotes não utilizados..."
sudo dnf autoremove -y
EOF

echo 'Configurando Emacs'



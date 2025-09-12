#!/bin/bash

set -e

sudo dnf update -y && sudo dnf upgrade -y

echo "instalando programas que uso"


sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install -y wget curl gcc pipx vim dnf-plugins-core emacs \
	 make automake gcc gcc-c++ kernel-devel google-chrome-stable golang virtualbox \
	 python3-tkinter swaylock swayidle waybar wlroots wofi mako \
	 akmod-nvidia xorg-x11-drv-nvidia-cudamesa-vulkan-drivers mesa-dri-drivers \
	 podman podman-compose 

echo "instalando Flatpaks"
flatpak install flathub io.github.shiftey.Desktop org.soapui.SoapUI io.dbeaver.DBeaverCommunity io.github.ungoogled_software.ungoogled_chromium

echo "instalando o docker"
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo groupadd docker
sudo usermod -aG docker "$USER"

echo "instalando e configurando UV Python"
pipx install uv

echo 'Criando o comando "atualizar"'
sudo tee /usr/local/bin/atualizar >/dev/null <<'EOF'
#!/bin/bash

# Comando 'atualizar' - Atualização automática do Fedora
# Coloque este arquivo em: /usr/local/bin/atualizar
# chmod +x /usr/local/bin/atualizar

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

show_progress() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

update_dnf() {
    show_progress "Atualizando sistema via DNF"
    
    if ! command_exists dnf; then
        log_error "DNF não encontrado!"
        return 1
    fi
    
    log_info "Limpando cache do DNF..."
    sudo dnf clean all >/dev/null 2>&1
    
    log_info "Verificando atualizações disponíveis..."
    local updates=$(dnf list --upgrades 2>/dev/null | grep -c '^[^[:space:]]' || echo "0")
    
    if [ "$updates" -gt 0 ]; then
        log_info "Encontradas $updates atualizações - iniciando..."
        sudo dnf upgrade -y --best --allowerasing
        log_success "Sistema DNF atualizado!"
    else
        log_success "Sistema DNF já está atualizado!"
    fi
}

update_flatpak() {
    show_progress "Atualizando Flatpaks"
    
    if ! command_exists flatpak; then
        log_warning "Flatpak não instalado - pulando..."
        return 0
    fi
    
    local apps=$(flatpak list --app 2>/dev/null | wc -l || echo "0")
    
    if [ "$apps" -eq 0 ]; then
        log_warning "Nenhum Flatpak instalado"
        return 0
    fi
    
    log_info "Atualizando $apps aplicações Flatpak..."
    sudo flatpak update -y --system >/dev/null 2>&1 || true
    flatpak update -y --user >/dev/null 2>&1 || true
    log_success "Flatpaks atualizados!"
}

cleanup_system() {
    show_progress "Limpeza do sistema"
    
    log_info "Removendo pacotes desnecessários..."
    sudo dnf autoremove -y >/dev/null 2>&1
    
    log_info "Limpando cache do DNF..."
    sudo dnf clean all >/dev/null 2>&1
    
    if command_exists flatpak; then
        log_info "Removendo Flatpaks não utilizados..."
        flatpak uninstall --unused -y >/dev/null 2>&1 || true
    fi
    
    log_success "Limpeza concluída!"
}

show_summary() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "ATUALIZAÇÃO CONCLUÍDA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "Sistema: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    log_info "Data/Hora: $(date '+%d/%m/%Y %H:%M:%S')"
    
    if [ -f /var/run/reboot-required ] || (command_exists needs-restarting && needs-restarting -r &>/dev/null); then
        log_warning "Reinicialização recomendada!"
        echo -e "Execute: ${YELLOW}sudo reboot${NC}"
    else
        log_success "Nenhuma reinicialização necessária"
    fi
    
    echo
    log_success "Sistema Fedora atualizado com sucesso! ✓"
}

main() {
    local start_time=$(date +%s)
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "🚀 ATUALIZANDO FEDORA"
    log_info "Iniciado em: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$EUID" -eq 0 ]; then
        log_error "Não execute como root! Use como usuário normal."
        exit 1
    fi
    
    log_info "Verificando conectividade..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        log_error "Sem conexão com internet!"
        exit 1
    fi
    log_success "Conexão OK"
    
    update_dnf
    update_flatpak
    cleanup_system
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    show_summary
    log_info "Tempo total: ${duration}s"
}

trap 'log_error "Interrompido pelo usuário"; exit 130' INT TERM

main "$@"
EOF

sudo chmod +x /usr/local/bin/atualizar
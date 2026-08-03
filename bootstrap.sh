#!/usr/bin/env bash
# bootstrap.sh — Instalador interactivo de paquetes para Juferoga
# Uso: ./bootstrap.sh [--auto] [--dry-run]
#   --auto     Instala todo sin preguntar
#   --dry-run  Muestra qué haría sin ejecutar nada

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m';    GREEN='\033[0;32m';   YELLOW='\033[1;33m'
BLUE='\033[0;34m';   CYAN='\033[0;36m';   MAGENTA='\033[0;35m'
BOLD='\033[1m';      DIM='\033[2m';        NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR ]${NC}  $*" >&2; }
section() { echo -e "\n${BOLD}${CYAN}══════ $* ══════${NC}"; }
skip()    { echo -e "${DIM}[SKIP]  $* (ya instalado)${NC}"; }

# ─── Flags ───────────────────────────────────────────────────────────────────
DRY_RUN=false
AUTO=false

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --auto)    AUTO=true ;;
    --help|-h)
      echo "Uso: $0 [--auto] [--dry-run]"
      echo "  --auto      Instala todo sin TUI"
      echo "  --dry-run   Muestra acciones sin ejecutar"
      exit 0 ;;
  esac
done

# ─── Run helper ──────────────────────────────────────────────────────────────
run() {
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] $*"
  else
    eval "$@"
  fi
}

has() { command -v "$1" &>/dev/null; }

# ─── Arte braille ────────────────────────────────────────────────────────────

# Fantasma pequeño (selector / inicio)
GHOST_MAIN=$(cat << 'GHOST'
        ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀     ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀
        ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁     ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁
        ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀     ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀
        ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀     ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀
        ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀     ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀
        ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀     ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀
        ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀     ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀

          Juferoga · Dotfiles Bootstrap · selecciona con ESPACIO
GHOST
)

# Fantasma grande celebrando (pantalla final)
GHOST_DONE=$(cat << 'GHOST'
  ⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁
  ⠀⠀⠀⠀⠀⠀⠀⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀
  ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀
  ⠀⠀⠀⠀⠀⠀⠠⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀
  ⠀⠀⠀⠀⠀⠀⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀

                   ✓  Bootstrap completado  ✓
                   ejecuta: exec zsh
GHOST
)

# Fantasma instalando (aparece entre secciones)
GHOST_THINKING=$(cat << 'GHOST'
        ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀
        ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁
        ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀    instalando...
        ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀    dame un seg
        ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀
        ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀
        ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀
GHOST
)

# Header principal (reemplaza el bloque ASCII horrible)
GHOST_HEADER=$(cat << 'GHOST'

  ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀                          ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀
  ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁   dotfiles bootstrap    ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁
  ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀      by Juferoga        ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀
  ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀   Ubuntu 26.04 LTS      ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀
  ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀                         ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀
  ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀                         ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀
  ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀                         ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀

GHOST
)

# ─── Detección de distro ─────────────────────────────────────────────────────
detect_distro() {
  if [[ ! -f /etc/os-release ]]; then
    error "No se encontró /etc/os-release"
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  case "$ID" in
    ubuntu|linuxmint|pop|elementary|zorin|neon)
                                DISTRO="debian" ;;
    debian|raspbian)            DISTRO="debian" ;;
    arch|manjaro|endeavouros|garuda|artix)
                                DISTRO="arch"   ;;
    fedora)                     DISTRO="fedora" ;;
    rhel|centos|almalinux|rocky|ol)
                                DISTRO="fedora" ;;  # todos usan dnf
    opensuse-leap|opensuse-tumbleweed|opensuse|sles)
                                DISTRO="opensuse" ;;
    *)
      # Fallback por ID_LIKE
      case "${ID_LIKE:-}" in
        *ubuntu*|*debian*)  DISTRO="debian"   ;;
        *arch*)             DISTRO="arch"     ;;
        *fedora*|*rhel*)    DISTRO="fedora"   ;;
        *suse*)             DISTRO="opensuse" ;;
        *)
          error "Distro no soportada: $ID (ID_LIKE=${ID_LIKE:-vacío})"
          error "Soportadas: Ubuntu/Mint/Debian · Arch/Manjaro · Fedora/RHEL/Alma · openSUSE"
          exit 1 ;;
      esac ;;
  esac

  DISTRO_NAME="${PRETTY_NAME:-$ID}"
}

detect_distro

# Actualizar header con la distro detectada
GHOST_HEADER=$(echo "$GHOST_HEADER" | sed "s/Ubuntu 26.04 LTS/$DISTRO_NAME/")

# ─── Instalar gum si no está ─────────────────────────────────────────────────
ensure_gum() {
  if has gum; then return; fi

  echo -e "${YELLOW}Instalando gum (TUI engine)...${NC}"
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] instalaría gum"
    return
  fi

  # Función helper: descarga binario de gum desde GitHub (fallback universal)
  _gum_from_github() {
    local ver
    ver=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
    curl -sLo /tmp/gum.tar.gz \
      "https://github.com/charmbracelet/gum/releases/latest/download/gum_${ver}_Linux_x86_64.tar.gz"
    tar -xzf /tmp/gum.tar.gz -C /tmp "gum"
    sudo mv /tmp/gum /usr/local/bin/gum
    rm -f /tmp/gum.tar.gz
  }

  case "$DISTRO" in
    debian)
      if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key \
          | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
          | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        sudo apt-get update -qq
      fi
      sudo apt-get install -y gum ;;
    arch)
      if has yay;        then yay  -S --noconfirm gum
      elif has paru;     then paru -S --noconfirm gum
      else _gum_from_github; fi ;;
    fedora)
      # Charm tiene repo RPM oficial
      if [[ ! -f /etc/yum.repos.d/charm.repo ]]; then
        sudo rpm --import https://repo.charm.sh/yum/gpg.key
        printf '[charm]\nname=Charm\nbaseurl=https://repo.charm.sh/yum/\nenabled=1\ngpgcheck=1\ngpgkey=https://repo.charm.sh/yum/gpg.key\n' \
          | sudo tee /etc/yum.repos.d/charm.repo > /dev/null
      fi
      sudo dnf install -y gum ;;
    opensuse)
      # Charm también tiene repo RPM para openSUSE
      if ! zypper lr charm &>/dev/null 2>&1; then
        sudo rpm --import https://repo.charm.sh/yum/gpg.key
        sudo zypper addrepo --refresh https://repo.charm.sh/yum/ charm 2>/dev/null || true
      fi
      sudo zypper install -y gum 2>/dev/null || _gum_from_github ;;
  esac
  ok "gum instalado"
}

# ─── Helpers de instalación ──────────────────────────────────────────────────

# Instala con el gestor nativo según distro
# Uso: pkg_install "debian" "arch" "fedora" "opensuse"
# Parámetros opcionales — si se omite usa el anterior como fallback
pkg_install() {
  local pkg_debian="$1"
  local pkg_arch="${2:-$pkg_debian}"
  local pkg_fedora="${3:-$pkg_debian}"
  local pkg_opensuse="${4:-$pkg_fedora}"   # opensuse suele coincidir con fedora

  case "$DISTRO" in
    debian)
      if dpkg -s "$pkg_debian" &>/dev/null 2>&1; then skip "$pkg_debian"; return; fi
      info "apt: $pkg_debian"
      run sudo apt-get install -y "$pkg_debian"
      ok "$pkg_debian" ;;
    arch)
      if pacman -Q "$pkg_arch" &>/dev/null 2>&1; then skip "$pkg_arch"; return; fi
      info "pacman: $pkg_arch"
      run sudo pacman -S --noconfirm --needed "$pkg_arch"
      ok "$pkg_arch" ;;
    fedora)
      if rpm -q "$pkg_fedora" &>/dev/null 2>&1; then skip "$pkg_fedora"; return; fi
      info "dnf: $pkg_fedora"
      run sudo dnf install -y "$pkg_fedora"
      ok "$pkg_fedora" ;;
    opensuse)
      if rpm -q "$pkg_opensuse" &>/dev/null 2>&1; then skip "$pkg_opensuse"; return; fi
      info "zypper: $pkg_opensuse"
      run sudo zypper install -y "$pkg_opensuse"
      ok "$pkg_opensuse" ;;
  esac
}

# Instala desde AUR (solo Arch)
aur_install() {
  local pkg="$1"
  [[ "$DISTRO" != "arch" ]] && return
  if pacman -Q "$pkg" &>/dev/null 2>&1; then skip "aur: $pkg"; return; fi
  if has yay;       then run yay  -S --noconfirm "$pkg"
  elif has paru;    then run paru -S --noconfirm "$pkg"
  else warn "Sin helper AUR (yay/paru). Instalar manualmente: $pkg"; return; fi
  ok "aur: $pkg"
}

brew_install() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null 2>&1; then skip "brew: $pkg"; return; fi
  info "brew: $pkg"
  run brew install "$pkg"
  ok "brew: $pkg"
}

snap_install() {
  local pkg="$1"; shift; local flags="${*:-}"
  case "$DISTRO" in
    arch|fedora|opensuse)
      if ! has snap; then
        warn "snap no disponible por defecto en $DISTRO_NAME. Instalar $pkg manualmente."
        return
      fi ;;
  esac
  if snap list "$pkg" &>/dev/null 2>&1; then skip "snap: $pkg"; return; fi
  info "snap: $pkg $flags"
  run sudo snap install "$pkg" $flags
  ok "snap: $pkg"
}

pip_install() {
  local pkg="$1"
  if python3 -m pip show "$pkg" &>/dev/null 2>&1; then skip "pip: $pkg"; return; fi
  info "pip: $pkg"
  run python3 -m pip install --quiet "$pkg"
  ok "pip: $pkg"
}

npm_global_install() {
  local pkg="$1"
  if npm list -g "$pkg" &>/dev/null 2>&1; then skip "npm: $pkg"; return; fi
  info "npm: $pkg"
  run npm install -g "$pkg"
  ok "npm: $pkg"
}

# ─── Bloques de instalación ──────────────────────────────────────────────────

install_system() {
  section "Paquetes del sistema — $DISTRO_NAME"

  case "$DISTRO" in
    debian)   run sudo apt-get update -qq ;;
    arch)     run sudo pacman -Sy ;;
    fedora)   run sudo dnf check-update -y || true ;;
    opensuse) run sudo zypper refresh ;;
  esac

  # pkg_install "debian"  "arch"  "fedora"  "opensuse"
  # Si algún nombre es igual al anterior se puede omitir (hereda)

  # ── Base ──────────────────────────────────────────────────────────────────
  pkg_install build-essential   base-devel        "@Development Tools"  patterns-devel-base
  pkg_install curl
  pkg_install wget
  pkg_install git
  pkg_install make
  pkg_install pkg-config        pkgconf           pkgconf               pkgconf
  pkg_install ca-certificates   ca-certificates   ca-certificates       ca-certificates
  pkg_install gnupg             gnupg             gnupg2                gpg2

  # ── Shell & terminal ──────────────────────────────────────────────────────
  pkg_install zsh
  pkg_install tmux
  pkg_install screen

  # ── CLI tools ─────────────────────────────────────────────────────────────
  pkg_install bat               bat               bat                   bat
  pkg_install fd-find           fd                fd-find               fd
  pkg_install fzf
  pkg_install ripgrep           ripgrep           ripgrep               ripgrep
  pkg_install lsd               lsd               lsd                   lsd
  pkg_install jq
  pkg_install tree
  pkg_install ncdu
  pkg_install htop
  pkg_install btop
  pkg_install nvtop
  pkg_install fastfetch         fastfetch         fastfetch             fastfetch
  pkg_install chafa
  pkg_install cmatrix
  pkg_install hexyl
  pkg_install hyperfine
  pkg_install tokei
  pkg_install vim
  pkg_install git-delta         git-delta         git-delta             git-delta
  pkg_install glow              glow              glow                  glow
  pkg_install visidata          visidata          visidata              visidata
  pkg_install bmon              bmon              bmon                  bmon
  pkg_install httpie            python-httpie     httpie                httpie

  # ── Fuentes ───────────────────────────────────────────────────────────────
  pkg_install fonts-firacode    ttf-fira-code     fira-code-fonts       fira-code-fonts
  pkg_install fonts-hack        ttf-hack          jetbrains-mono-fonts  hack-fonts
  pkg_install fonts-jetbrains-mono ttf-jetbrains-mono jetbrains-mono-fonts jetbrains-mono-fonts

  # ── Lenguajes y runtime ───────────────────────────────────────────────────
  pkg_install gcc
  pkg_install golang            go                golang                go
  pkg_install default-jdk       jdk-openjdk       java-latest-openjdk   java-21-openjdk
  pkg_install maven
  pkg_install ruby3.3-dev       ruby              ruby                  ruby
  pkg_install pipx              python-pipx       pipx                  python313-pipx
  pkg_install autoconf

  # ── Libs de desarrollo ────────────────────────────────────────────────────
  pkg_install libssl-dev        openssl           openssl-devel         libopenssl-devel
  pkg_install libfontconfig1-dev fontconfig       fontconfig-devel      fontconfig-devel
  pkg_install libpam0g-dev      pam               pam-devel             pam-devel
  pkg_install libev-dev         libev             libev-devel           libev-devel
  pkg_install libasound2-dev    alsa-lib          alsa-lib-devel        alsa-devel
  pkg_install libjpeg-dev       libjpeg-turbo     libjpeg-turbo-devel   libjpeg8-devel
  pkg_install libgif-dev        giflib            giflib-devel          giflib-devel
  pkg_install libfuse2t64       fuse2             fuse                  fuse
  pkg_install libxdo-dev        xdotool           libxdo-devel          xdotool
  pkg_install libxkbcommon-dev  libxkbcommon      libxkbcommon-devel    libxkbcommon-devel
  pkg_install libxkbcommon-x11-dev libxkbcommon-x11 libxkbcommon-x11-devel libxkbcommon-x11-devel

  # ── Docker ────────────────────────────────────────────────────────────────
  pkg_install docker.io         docker            docker                docker
  pkg_install docker-compose-plugin docker-compose docker-compose       docker-compose

  # ── Multimedia ────────────────────────────────────────────────────────────
  pkg_install ffmpeg
  pkg_install mpv
  pkg_install vlc
  pkg_install imagemagick       imagemagick       ImageMagick           ImageMagick
  pkg_install obs-studio        obs-studio        obs-studio            obs-studio

  # ── GUI ───────────────────────────────────────────────────────────────────
  pkg_install inkscape
  pkg_install blender
  pkg_install flameshot
  pkg_install scrot
  pkg_install thunar
  pkg_install xfce4
  pkg_install xfce4-goodies

  # ── i3 ────────────────────────────────────────────────────────────────────
  pkg_install i3                i3-wm             i3                    i3
  pkg_install suckless-tools    dmenu             dmenu                 dmenu
  pkg_install arandr

  # ── Utilidades ────────────────────────────────────────────────────────────
  pkg_install ranger
  pkg_install zoxide
  pkg_install entr
  pkg_install socat
  pkg_install nmap
  pkg_install openssh-server    openssh           openssh-server        openssh
  pkg_install graphviz
  pkg_install awscli            aws-cli           awscli                aws-cli
  pkg_install gparted
  pkg_install xournalpp
  pkg_install audacity
  pkg_install musescore         musescore3        musescore             musescore
  pkg_install bc
  pkg_install btrfs-progs       btrfs-progs       btrfs-progs           btrfsprogs
  pkg_install efibootmgr

  # ── OCR / Docs ────────────────────────────────────────────────────────────
  pkg_install tesseract-ocr     tesseract         tesseract             tesseract-ocr
  pkg_install tesseract-ocr-eng tesseract-data-eng tesseract-langpack-eng tesseract-ocr-traineddata-english
  pkg_install tesseract-ocr-spa tesseract-data-spa tesseract-langpack-spa tesseract-ocr-traineddata-spanish
  pkg_install poppler-utils     poppler           poppler-utils         poppler-tools
  pkg_install libimage-exiftool-perl perl-image-exiftool perl-Image-ExifTool perl-Image-ExifTool

  # ── Nvidia / CUDA ─────────────────────────────────────────────────────────
  pkg_install nvidia-cuda-toolkit cuda             cuda-toolkit          cuda-toolkit

  # ── LaTeX ─────────────────────────────────────────────────────────────────
  pkg_install texlive-full      texlive-most      texlive-scheme-full   texlive-scheme-full

  # ── Solo Debian/Ubuntu/Mint ───────────────────────────────────────────────
  if [[ "$DISTRO" == "debian" ]]; then
    pkg_install software-properties-common
    pkg_install apt-transport-https
    pkg_install lsb-release
    pkg_install python3.13-venv
    pkg_install hunspell-es
    pkg_install language-pack-es
    pkg_install bpytop
    pkg_install ncurses-base
    pkg_install evtest
    pkg_install xinput
    pkg_install peek

    # VS Code via repo Microsoft
    if ! has code; then
      info "Instalando VS Code..."
      run wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
      run echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list
      run sudo apt-get update -qq && sudo apt-get install -y code
      ok "VS Code"
    else skip "VS Code"; fi

    # GitHub CLI via repo oficial
    if ! has gh; then
      info "Instalando GitHub CLI..."
      run curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
      run echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list
      run sudo apt-get update -qq && sudo apt-get install -y gh
      ok "GitHub CLI"
    else skip "GitHub CLI"; fi
  fi

  # ── Solo Arch ─────────────────────────────────────────────────────────────
  if [[ "$DISTRO" == "arch" ]]; then
    # Instalar yay si no hay helper AUR
    if ! has yay && ! has paru; then
      info "Instalando yay (AUR helper)..."
      run git clone https://aur.archlinux.org/yay.git /tmp/yay-build
      run cd /tmp/yay-build && makepkg -si --noconfirm
      ok "yay"
    fi
    pkg_install hunspell-es_es  hunspell-es_es
    ! has code && aur_install visual-studio-code-bin
    pkg_install github-cli      github-cli
    aur_install bpytop
  fi

  # ── Solo Fedora/RHEL ──────────────────────────────────────────────────────
  if [[ "$DISTRO" == "fedora" ]]; then
    # RPM Fusion para multimedia (ffmpeg, vlc, etc.)
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
      info "Habilitando RPM Fusion..."
      run sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
      ok "RPM Fusion"
    else skip "RPM Fusion"; fi

    pkg_install hunspell-es     hunspell-es     hunspell-es
    pkg_install evtest          evtest          evtest
    pkg_install xorg-x11-utils  xorg-x11-utils  xorg-x11-utils

    # VS Code via repo Microsoft
    if ! has code; then
      info "Instalando VS Code..."
      run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      run printf '[code]\nname=VS Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
        | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
      run sudo dnf install -y code
      ok "VS Code"
    else skip "VS Code"; fi

    # GitHub CLI via repo dnf
    if ! has gh; then
      info "Instalando GitHub CLI..."
      run sudo dnf install -y 'dnf-command(config-manager)'
      run sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      run sudo dnf install -y gh
      ok "GitHub CLI"
    else skip "GitHub CLI"; fi
  fi

  # ── Solo openSUSE ─────────────────────────────────────────────────────────
  if [[ "$DISTRO" == "opensuse" ]]; then
    # Packman para multimedia
    if ! zypper lr packman &>/dev/null 2>&1; then
      info "Habilitando repo Packman..."
      run sudo zypper addrepo --refresh \
        https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman 2>/dev/null || true
      run sudo zypper --gpg-auto-import-keys refresh
      ok "Packman"
    else skip "Packman"; fi

    pkg_install hunspell-es_ES  hunspell-es_ES  hunspell-es_ES
    pkg_install xorg-x11-xinput xinput          xinput

    # VS Code via repo Microsoft (usa el mismo RPM que Fedora)
    if ! has code; then
      info "Instalando VS Code..."
      run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
      run sudo zypper addrepo https://packages.microsoft.com/yumrepos/vscode vscode 2>/dev/null || true
      run sudo zypper --gpg-auto-import-keys refresh
      run sudo zypper install -y code
      ok "VS Code"
    else skip "VS Code"; fi

    # GitHub CLI
    if ! has gh; then
      info "Instalando GitHub CLI..."
      run sudo zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo gh-cli 2>/dev/null || true
      run sudo zypper --gpg-auto-import-keys refresh
      run sudo zypper install -y gh
      ok "GitHub CLI"
    else skip "GitHub CLI"; fi
  fi

  warn "Instalar manualmente: AnyDesk, Cursor, DBeaver CE"
}

install_brew() {
  section "Homebrew"
  if ! has brew; then
    info "Instalando Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    ok "Homebrew"
  else skip "Homebrew"; fi

  for pkg in gh node ripgrep python@3.14; do
    brew_install "$pkg"
  done
}

install_snap() {
  section "Snap packages"
  snap_install ghostty --classic
  snap_install firefox
  snap_install spotify
  snap_install telegram-desktop
  snap_install onlyoffice-desktopeditors
}

install_zsh() {
  section "Zsh + Oh My Zsh"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh"
  else skip "Oh My Zsh"; fi

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  declare -A plugins=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  )
  for name in "${!plugins[@]}"; do
    local path="$ZSH_CUSTOM/plugins/$name"
    if [[ -d "$path" ]]; then skip "plugin: $name"
    else
      run git clone --depth=1 "${plugins[$name]}" "$path"
      ok "plugin: $name"
    fi
  done

  if [[ "$SHELL" != "$(which zsh)" ]]; then
    run chsh -s "$(which zsh)"
    ok "Shell → zsh"
  else skip "Shell ya es zsh"; fi
}

install_node() {
  section "Node — NVM"
  if [[ ! -d "$HOME/.nvm" ]]; then
    run curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    ok "NVM"
  else skip "NVM"; fi

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"

  for v in 22 26; do
    nvm ls "$v" &>/dev/null 2>&1 && skip "node v$v" || { run nvm install "$v"; ok "node v$v"; }
  done

  for pkg in mcporter openclaw; do npm_global_install "$pkg"; done
}

install_bun() {
  section "Bun"
  has bun && { skip "Bun"; return; }
  run curl -fsSL https://bun.sh/install | bash
  ok "Bun"
}

install_rust() {
  section "Rust — rustup"
  if has rustup; then
    run rustup update stable; ok "Rust actualizado"
  else
    run curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    [[ "$DRY_RUN" == false ]] && source "$HOME/.cargo/env" || true
    ok "Rust"
  fi
  has rust-analyzer && skip "rust-analyzer" || { run cargo install rust-analyzer; ok "rust-analyzer"; }
}

install_python() {
  section "Python — pip packages"
  if ! has uv; then
    run curl -LsSf https://astral.sh/uv/install.sh | sh
    ok "uv"
  else skip "uv"; fi

  local pkgs=(
    torch torchvision transformers accelerate
    huggingface_hub safetensors openai-whisper ollama
    numpy pandas scipy matplotlib scikit-learn jupyterlab ipykernel
    langchain langchain-core langgraph langsmith
    opencv-python pillow imageio moviepy
    edge-tts sounddevice gtts
    docling pypdf python-docx python-pptx pytesseract
    boto3 kubernetes redis python-dotenv requests httpx
    beautifulsoup4 duckdb firecrawl-py pytest
    black ruff isort mypy pre-commit
  )
  for pkg in "${pkgs[@]}"; do pip_install "$pkg"; done
}

install_ai() {
  section "Herramientas AI"
  if ! has ollama; then
    run curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama"
  else skip "Ollama"; fi

  has kiro-cli    && skip "Kiro CLI"    || warn "Kiro CLI: instalar desde https://kiro.dev"
  has claude      && skip "Claude CLI"  || warn "Claude CLI: instalar manualmente"
  has lms         && skip "LM Studio"   || warn "LM Studio: https://lmstudio.ai"
}

# ─── Mapa de secciones ───────────────────────────────────────────────────────
declare -A SECTION_LABELS=(
  ["system"]="Sistema — CLI, Docker, Nvidia, LaTeX, fuentes ($DISTRO_NAME)"
  ["brew"]="Brew    — Homebrew + node, gh, ripgrep, python@3.14"
  ["snap"]="Snap    — Ghostty, Firefox, Spotify, Telegram, OnlyOffice"
  ["zsh"]="Zsh     — Oh My Zsh + plugins autosuggestions/syntax"
  ["node"]="Node    — NVM + v22 + v26 + npm globals (openclaw)"
  ["bun"]="Bun     — Bun runtime"
  ["rust"]="Rust    — rustup + rust-analyzer"
  ["python"]="Python  — uv + pip (torch, langchain, opencv...)"
  ["ai"]="AI      — Ollama + avisos Kiro/Claude/LMStudio"
)

SECTION_ORDER=(system brew snap zsh node bun rust python ai)

run_section() {
  echo -e "${MAGENTA}${GHOST_THINKING}${NC}"
  case "$1" in
    system) install_system ;;
    brew)   install_brew   ;;
    snap)   install_snap   ;;
    zsh)    install_zsh    ;;
    node)   install_node   ;;
    bun)    install_bun    ;;
    rust)   install_rust   ;;
    python) install_python ;;
    ai)     install_ai     ;;
  esac
}

# ─── TUI con gum ─────────────────────────────────────────────────────────────
tui_select() {
  local args=()
  for key in "${SECTION_ORDER[@]}"; do
    args+=("$key" "${SECTION_LABELS[$key]}")
  done

  gum choose \
    --no-limit \
    --cursor="👻 " \
    --selected.foreground="212" \
    --header="$(echo -e "${BOLD}Selecciona con ESPACIO, confirma con ENTER${NC}")" \
    --header.foreground="99" \
    "${args[@]}"
}

# ─── Main ────────────────────────────────────────────────────────────────────
clear
echo -e "${MAGENTA}${GHOST_HEADER}${NC}"
[[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}  ⚠  Modo DRY-RUN activo — no se instalará nada${NC}\n"

if [[ "$AUTO" == true ]]; then
  # Modo automático: instala todo
  warn "Modo --auto: instalando todo sin preguntar"
  SELECTED=("${SECTION_ORDER[@]}")
else
  # Instalar gum para la TUI
  ensure_gum

  echo -e "${CYAN}${GHOST_MAIN}${NC}"
  echo -e "${DIM}  Usa las flechas para moverte · ESPACIO para seleccionar · ENTER para confirmar${NC}\n"

  # Lanzar selector
  mapfile -t SELECTED < <(tui_select)

  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    echo -e "\n${YELLOW}No seleccionaste nada. ¡Hasta luego! 👻${NC}\n"
    exit 0
  fi
fi

# Confirmación
echo ""
echo -e "${BOLD}Vas a instalar:${NC}"
for s in "${SELECTED[@]}"; do
  echo -e "  ${GREEN}▸${NC} ${SECTION_LABELS[$s]}"
done
echo ""

if [[ "$AUTO" == false && "$DRY_RUN" == false ]]; then
  if ! gum confirm "¿Arrancamos? 👻"; then
    echo -e "\n${YELLOW}Cancelado. Hasta la próxima 👻${NC}\n"
    exit 0
  fi
fi

# Ejecutar secciones seleccionadas
echo ""
for s in "${SELECTED[@]}"; do
  run_section "$s"
done

# ─── Symlinks al final ───────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$DOTFILES_DIR/install.sh" ]]; then
  echo ""
  if [[ "$AUTO" == true ]]; then
    "$DOTFILES_DIR/install.sh"
  elif gum confirm "¿Aplicar symlinks de dotfiles también? (install.sh)"; then
    "$DOTFILES_DIR/install.sh"
  fi
fi

# ─── Fin ─────────────────────────────────────────────────────────────────────
clear
echo -e "${GREEN}${GHOST_DONE}${NC}"
echo -e "\n${BOLD}  Todo listo${NC} — reinicia el shell con: ${CYAN}exec zsh${NC}\n"

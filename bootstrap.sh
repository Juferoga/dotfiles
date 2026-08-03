#!/usr/bin/env bash
# bootstrap.sh — Instalador automático de paquetes para Juferoga
# Uso: ./bootstrap.sh [--dry-run] [--only=<sección>]
#   Secciones: apt, brew, snap, node, python, rust, go, bun, zsh, ai
#
# Ejemplo: ./bootstrap.sh --only=apt

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC}  $* (ya instalado)"; }

# ─── Flags ───────────────────────────────────────────────────────────────────
DRY_RUN=false
ONLY=""

for arg in "$@"; do
  case $arg in
    --dry-run)     DRY_RUN=true ;;
    --only=*)      ONLY="${arg#--only=}" ;;
    --help|-h)
      echo "Uso: $0 [--dry-run] [--only=<sección>]"
      echo "Secciones: apt, brew, snap, node, python, rust, go, bun, zsh, ai"
      exit 0 ;;
  esac
done

[[ "$DRY_RUN" == true ]] && warn "Modo DRY-RUN — no se instalará nada"

# ─── Helpers ─────────────────────────────────────────────────────────────────
run() {
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] $*"
  else
    eval "$@"
  fi
}

# Retorna 0 si el comando existe
has() { command -v "$1" &>/dev/null; }

# Instala un paquete apt si no está instalado
apt_install() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null 2>&1; then
    skip "$pkg"
  else
    info "apt install $pkg"
    run sudo apt-get install -y "$pkg"
    ok "$pkg"
  fi
}

# Instala un paquete brew si no está instalado
brew_install() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null 2>&1; then
    skip "brew: $pkg"
  else
    info "brew install $pkg"
    run brew install "$pkg"
    ok "brew: $pkg"
  fi
}

# Instala un snap si no está instalado
snap_install() {
  local pkg="$1"; shift
  local flags="${*:-}"
  if snap list "$pkg" &>/dev/null 2>&1; then
    skip "snap: $pkg"
  else
    info "snap install $pkg $flags"
    run sudo snap install "$pkg" $flags
    ok "snap: $pkg"
  fi
}

# Instala un paquete pip si no está instalado
pip_install() {
  local pkg="$1"
  if python3 -m pip show "$pkg" &>/dev/null 2>&1; then
    skip "pip: $pkg"
  else
    info "pip install $pkg"
    run python3 -m pip install --quiet "$pkg"
    ok "pip: $pkg"
  fi
}

# ─── Sección selector ────────────────────────────────────────────────────────
should_run() {
  [[ -z "$ONLY" || "$ONLY" == "$1" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Bootstrap installer — Juferoga         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ─── APT ─────────────────────────────────────────────────────────────────────
if should_run apt; then
  section "APT — System packages"
  run sudo apt-get update -qq

  APT_PACKAGES=(
    # Sistema base
    build-essential curl wget git make pkg-config ca-certificates
    software-properties-common apt-transport-https gnupg lsb-release
    # Shell & terminal
    zsh tmux screen
    # Herramientas CLI esenciales
    bat fd-find fzf ripgrep lsd jq tree ncdu htop btop bpytop nvtop
    fastfetch chafa cmatrix hexyl hyperfine tokei glow visidata bmon
    # Git extras
    git-delta
    # Editores
    vim
    # Fuentes
    fonts-firacode fonts-hack fonts-jetbrains-mono
    # Desarrollo
    gcc golang default-jdk maven ruby3.3-dev
    python3.13-venv pipx
    autoconf libssl-dev libfontconfig1-dev libpam0g-dev
    libx11-xcb-dev libxcb-composite0-dev libxcb-image0-dev
    libxcb-keysyms1-dev libxcb-randr0-dev libxcb-util-dev
    libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xrm-dev libxcb1-dev
    libxdo-dev libxkbcommon-dev libxkbcommon-x11-dev
    libev-dev libasound2-dev libjpeg-dev libgif-dev libfuse2t64
    # Docker
    docker-buildx-plugin docker-compose-plugin docker.io
    # Multimedia
    ffmpeg mpv obs-studio vlc imagemagick
    # GUI apps
    inkscape blender flameshot peek scrot
    thunar xfce4 xfce4-goodies
    # Window manager
    i3 suckless-tools arandr
    # Utilidades
    ranger zoxide entr socat nmap openssh-server
    poppler-utils tesseract-ocr tesseract-ocr-eng tesseract-ocr-spa
    graphviz httpie awscli
    # Idioma
    language-pack-es hunspell-es wspanish
    # Nvidia
    nvidia-cuda-toolkit
    # LaTeX
    texlive-full
    # Extras
    gparted ncurses-base xournal xournalpp audacity musescore
    bc btrfs-progs efibootmgr evtest xinput
    libimage-exiftool-perl
  )

  for pkg in "${APT_PACKAGES[@]}"; do
    apt_install "$pkg"
  done
fi

# ─── Repositorios externos (apt) ─────────────────────────────────────────────
if should_run apt; then
  section "APT — Repos externos"

  # VS Code
  if ! has code; then
    info "Instalando VS Code..."
    run wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
    run echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    run sudo apt-get update -qq && sudo apt-get install -y code
    ok "VS Code"
  else
    skip "VS Code"
  fi

  # GitHub CLI (gh)
  if ! has gh; then
    info "Instalando GitHub CLI..."
    run curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    run echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
    run sudo apt-get update -qq && sudo apt-get install -y gh
    ok "GitHub CLI"
  else
    skip "GitHub CLI"
  fi

  # Docker GPG (si docker.io no es suficiente)
  # AnyDesk — requiere descarga manual (omitido por seguridad)
  warn "AnyDesk / Cursor / DBeaver: instalar manualmente desde sus sitios oficiales"
fi

# ─── SNAP ────────────────────────────────────────────────────────────────────
if should_run snap; then
  section "Snap packages"
  snap_install ghostty --classic
  snap_install firefox
  snap_install spotify
  snap_install telegram-desktop
  snap_install onlyoffice-desktopeditors
fi

# ─── Homebrew ────────────────────────────────────────────────────────────────
if should_run brew; then
  section "Homebrew"

  if ! has brew; then
    info "Instalando Homebrew..."
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Cargar brew en el PATH actual
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    ok "Homebrew instalado"
  else
    skip "Homebrew"
  fi

  BREW_PACKAGES=(
    gh
    node
    ripgrep
    python@3.14
  )

  for pkg in "${BREW_PACKAGES[@]}"; do
    brew_install "$pkg"
  done
fi

# ─── ZSH / Oh My Zsh ─────────────────────────────────────────────────────────
if should_run zsh; then
  section "Zsh + Oh My Zsh"

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Instalando Oh My Zsh..."
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh"
  else
    skip "Oh My Zsh"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Plugins
  declare -A ZSH_PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  )

  for name in "${!ZSH_PLUGINS[@]}"; do
    local_path="$ZSH_CUSTOM/plugins/$name"
    if [[ -d "$local_path" ]]; then
      skip "zsh plugin: $name"
    else
      info "Instalando plugin: $name"
      run git clone --depth=1 "${ZSH_PLUGINS[$name]}" "$local_path"
      ok "zsh plugin: $name"
    fi
  done

  # Cambiar shell a zsh
  if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Cambiando shell a zsh..."
    run chsh -s "$(which zsh)"
    ok "Shell cambiado a zsh"
  else
    skip "Shell ya es zsh"
  fi
fi

# ─── Node / NVM ──────────────────────────────────────────────────────────────
if should_run node; then
  section "Node — NVM"

  if [[ ! -d "$HOME/.nvm" ]]; then
    info "Instalando NVM..."
    run curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    ok "NVM instalado"
  else
    skip "NVM"
  fi

  # Cargar nvm para usarlo en el script
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  NVM_VERSIONS=(22 26)
  for version in "${NVM_VERSIONS[@]}"; do
    if nvm ls "$version" &>/dev/null 2>&1; then
      skip "node v$version"
    else
      info "Instalando node v$version..."
      run nvm install "$version"
      ok "node v$version"
    fi
  done

  # NPM globals
  NPM_GLOBALS=(mcporter openclaw)
  for pkg in "${NPM_GLOBALS[@]}"; do
    if npm list -g "$pkg" &>/dev/null 2>&1; then
      skip "npm global: $pkg"
    else
      info "npm install -g $pkg"
      run npm install -g "$pkg"
      ok "npm: $pkg"
    fi
  done
fi

# ─── Bun ─────────────────────────────────────────────────────────────────────
if should_run bun; then
  section "Bun"
  if has bun; then
    skip "Bun"
  else
    info "Instalando Bun..."
    run curl -fsSL https://bun.sh/install | bash
    ok "Bun"
  fi
fi

# ─── Rust ────────────────────────────────────────────────────────────────────
if should_run rust; then
  section "Rust — rustup"
  if has rustup; then
    info "Actualizando Rust..."
    run rustup update stable
    ok "Rust actualizado"
  else
    info "Instalando rustup..."
    run curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    [[ "$DRY_RUN" == false ]] && . "$HOME/.cargo/env"
    ok "Rust instalado"
  fi

  # Herramientas cargo
  CARGO_TOOLS=(rust-analyzer)
  for tool in "${CARGO_TOOLS[@]}"; do
    if has "$tool"; then
      skip "cargo: $tool"
    else
      info "cargo install $tool"
      run cargo install "$tool"
      ok "cargo: $tool"
    fi
  done
fi

# ─── Python / pip ────────────────────────────────────────────────────────────
if should_run python; then
  section "Python — pip packages"

  if ! has uv; then
    info "Instalando uv..."
    run curl -LsSf https://astral.sh/uv/install.sh | sh
    ok "uv instalado"
  else
    skip "uv"
  fi

  PIP_PACKAGES=(
    # ML / AI
    torch torchvision transformers accelerate
    huggingface_hub datasets safetensors
    openai-whisper ollama
    # Data / ciencia
    numpy pandas scipy matplotlib scikit-learn
    jupyterlab ipykernel
    # LLM frameworks
    langchain langchain-core langgraph langsmith
    # Visión
    opencv-python pillow imageio
    # Audio / Video
    moviepy edge-tts sounddevice gtts
    # Docs
    docling pypdf python-docx python-pptx
    pytesseract
    # Utils
    boto3 kubernetes redis
    python-dotenv requests httpx
    beautifulsoup4 feedparser
    duckdb
    firecrawl-py
    pytest
    # Dev
    black ruff isort mypy
    pre-commit
  )

  for pkg in "${PIP_PACKAGES[@]}"; do
    pip_install "$pkg"
  done
fi

# ─── Herramientas AI (binarios) ───────────────────────────────────────────────
if should_run ai; then
  section "Herramientas AI"

  # Kiro CLI
  if ! has kiro-cli; then
    warn "Kiro CLI: instalar manualmente desde https://kiro.dev"
  else
    skip "Kiro CLI"
  fi

  # Claude CLI
  if ! has claude; then
    warn "Claude CLI: instalar manualmente"
  else
    skip "Claude CLI"
  fi

  # Ollama
  if ! has ollama; then
    info "Instalando Ollama..."
    run curl -fsSL https://ollama.com/install.sh | sh
    ok "Ollama"
  else
    skip "Ollama"
  fi

  # LM Studio CLI (lms)
  if ! has lms; then
    warn "LM Studio: instalar desde https://lmstudio.ai"
  else
    skip "LM Studio CLI"
  fi
fi

# ─── Fin ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════╗${NC}"
if [[ "$DRY_RUN" == true ]]; then
  echo -e "${BOLD}${GREEN}║  DRY-RUN completado — sin cambios        ║${NC}"
else
  echo -e "${BOLD}${GREEN}║  Bootstrap completado ✓                  ║${NC}"
  echo -e "${BOLD}${GREEN}║  Siguiente paso: ./install.sh            ║${NC}"
fi
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

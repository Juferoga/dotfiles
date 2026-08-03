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

# ─── Fantasmas ASCII ─────────────────────────────────────────────────────────
GHOST_MAIN=$(cat << 'GHOST'

        .-.      .-.      .-.      .-.
       (   )    (   )    (   )    (   )
        '-'      '-'      '-'      '-'
      Juferoga  Dotfiles Bootstrap  👻
GHOST
)

GHOST_DONE=$(cat << 'GHOST'

         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
         ░  .-.    Bootstrap  .-.     ░
         ░ (   )   completado (   )   ░
         ░  '-'      ✓✓✓✓✓    '-'    ░
         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
GHOST
)

GHOST_THINKING=$(cat << 'GHOST'

          .-"""-.
         /        \
        |  o    o  |
        |    __    |   Instalando...
         \  (__) /    dame un seg 👻
          '------'
GHOST
)

GHOST_HEADER=$(cat << 'GHOST'

  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

           👻  by Juferoga  👻       ubuntu bootstrap
GHOST
)

# ─── Instalar gum si no está ─────────────────────────────────────────────────
ensure_gum() {
  if has gum; then return; fi

  echo -e "${YELLOW}Instalando gum (TUI engine)...${NC}"
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] instalaría gum via apt"
    return
  fi

  if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key \
      | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
      | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt-get update -qq
  fi
  sudo apt-get install -y gum
  ok "gum instalado"
}

# ─── Helpers de instalación ──────────────────────────────────────────────────
apt_install() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null 2>&1; then skip "$pkg"; return; fi
  info "apt: $pkg"
  run sudo apt-get install -y "$pkg"
  ok "$pkg"
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

install_apt() {
  section "APT — Paquetes del sistema"
  run sudo apt-get update -qq

  local pkgs=(
    build-essential curl wget git make pkg-config ca-certificates
    software-properties-common apt-transport-https gnupg lsb-release
    zsh tmux screen
    bat fd-find fzf ripgrep lsd jq tree ncdu htop btop bpytop nvtop
    fastfetch chafa cmatrix hexyl hyperfine tokei glow visidata bmon
    git-delta vim
    fonts-firacode fonts-hack fonts-jetbrains-mono
    gcc golang default-jdk maven ruby3.3-dev
    python3.13-venv pipx
    autoconf libssl-dev libfontconfig1-dev libpam0g-dev
    libx11-xcb-dev libxcb-composite0-dev libxcb-image0-dev
    libxcb-keysyms1-dev libxcb-randr0-dev libxcb-util-dev
    libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xrm-dev libxcb1-dev
    libxdo-dev libxkbcommon-dev libxkbcommon-x11-dev
    libev-dev libasound2-dev libjpeg-dev libgif-dev libfuse2t64
    docker-buildx-plugin docker-compose-plugin docker.io
    ffmpeg mpv vlc imagemagick obs-studio
    inkscape blender flameshot peek scrot
    thunar xfce4 xfce4-goodies
    i3 suckless-tools arandr
    ranger zoxide entr socat nmap openssh-server
    poppler-utils tesseract-ocr tesseract-ocr-eng tesseract-ocr-spa
    graphviz httpie awscli
    language-pack-es hunspell-es wspanish
    nvidia-cuda-toolkit
    texlive-full
    gparted ncurses-base xournal xournalpp audacity musescore
    bc btrfs-progs efibootmgr evtest xinput libimage-exiftool-perl
  )

  for pkg in "${pkgs[@]}"; do apt_install "$pkg"; done

  # VS Code
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

  # GitHub CLI
  if ! has gh; then
    info "Instalando GitHub CLI..."
    run curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    run echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list
    run sudo apt-get update -qq && sudo apt-get install -y gh
    ok "GitHub CLI"
  else skip "GitHub CLI"; fi

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
  ["apt"]="APT  — Sistema, CLI, Docker, Nvidia, LaTeX, fuentes"
  ["brew"]="Brew — Homebrew + node, gh, ripgrep, python@3.14"
  ["snap"]="Snap — Ghostty, Firefox, Spotify, Telegram, OnlyOffice"
  ["zsh"]="Zsh  — Oh My Zsh + plugins autosuggestions/syntax"
  ["node"]="Node — NVM + v22 + v26 + npm globals (openclaw)"
  ["bun"]="Bun  — Bun runtime"
  ["rust"]="Rust — rustup + rust-analyzer"
  ["python"]="Python — uv + pip (torch, langchain, opencv...)"
  ["ai"]="AI   — Ollama + avisos Kiro/Claude/LMStudio"
)

SECTION_ORDER=(apt brew snap zsh node bun rust python ai)

run_section() {
  echo -e "$GHOST_THINKING"
  case "$1" in
    apt)    install_apt    ;;
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

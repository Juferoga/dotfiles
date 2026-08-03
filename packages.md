# Packages Inventory

> Sistema: Ubuntu 26.04 LTS (Resolute Raccoon) | Kernel: 7.0.0-28-generic  
> Generado: 2026-08-03

---

## APT (instalados manualmente)

```bash
sudo apt install -y \
  alsa-utils arandr audacity autoconf awscli \
  bat bc blender bmon bpytop btop btrfs-progs build-essential \
  ca-certificates chafa cmatrix curl \
  default-jdk diffutils docker-buildx-plugin docker-compose-plugin docker.io \
  efibootmgr entr evtest \
  fastfetch fd-find ffmpeg file findutils flameshot \
  fonts-firacode fonts-hack fonts-jetbrains-mono fzf \
  gcc gh git git-delta glow golang google-chrome-stable gparted graphviz grep gzip \
  hexyl htop httpie hyperfine \
  i3 imagemagick inkscape jq \
  kbd language-pack-es libasound2-dev libc6 libev-dev libfontconfig1-dev \
  libfuse2t64 libgif-dev libimage-exiftool-perl libjpeg-dev libpam0g-dev \
  libssl-dev libx11-xcb-dev libxcb-composite0-dev libxcb-image0-dev \
  libxcb-keysyms1-dev libxcb-randr0-dev libxcb-util-dev libxcb-xinerama0-dev \
  libxcb-xkb-dev libxcb-xrm-dev libxcb1-dev libxdo-dev libxkbcommon-dev \
  libxkbcommon-x11-dev libreoffice-l10n-es \
  lsd make maven mpv musescore \
  ncdu ncurses-base ncurses-bin nmap nvtop nvidia-cuda-toolkit nvidia-driver-590-open \
  obs-studio obsidian octave openssh-server \
  peek pipx pkg-config poppler-utils python3.13-venv \
  ranger ripgrep ruby3.3-dev \
  scrot socat software-properties-common suckless-tools \
  tesseract-ocr tesseract-ocr-eng tesseract-ocr-spa texlive-full \
  thunar tmux tokei tree \
  ubuntu-desktop-minimal ubuntu-restricted-addons \
  vim visidata vlc vmpk \
  wget wpasupplicant wspanish \
  xfce4 xfce4-goodies xinput xournal xournalpp \
  zoxide zsh
```

### APT - Externos (requieren repo/deb manual)
| Paquete | Fuente |
|---|---|
| `anydesk` | https://anydesk.com/en/downloads/linux |
| `code` (VS Code) | https://code.visualstudio.com/ |
| `cursor` | https://www.cursor.com/ |
| `dbeaver-ce` | https://dbeaver.io/download/ |
| `google-chrome-stable` | https://www.google.com/chrome/ |
| `cloudflared` | https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/ |
| `docker.io` | https://docs.docker.com/engine/install/ubuntu/ |

---

## Homebrew (linuxbrew)

```bash
# Instalar Homebrew primero:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install \
  gh \
  node \
  python@3.14 \
  ripgrep \
  engram \
  merve \
  obsidian-cli \
  qwen-code \
  rtk
```

---

## Snap

```bash
sudo snap install ghostty --classic
sudo snap install firefox
sudo snap install spotify
sudo snap install telegram-desktop
sudo snap install onlyoffice-desktopeditors
```

---

## Node / NPM globals

```bash
# Instalar NVM primero:
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 22
nvm install 26

npm install -g mcporter openclaw
```

---

## Python / pip

```bash
# Instalar uv primero:
# curl -LsSf https://astral.sh/uv/install.sh | sh

pip install \
  accelerate aiohttp arxiv \
  beautifulsoup4 boto3 \
  docling duckdb \
  edge-tts \
  firecrawl-py \
  gitpython gtts \
  huggingface_hub \
  langchain langgraph langsmith \
  matplotlib moviepy \
  nltk numpy \
  ollama openai-whisper opencv-python openpyxl \
  pandas pillow \
  pytest python-dotenv \
  redis requests \
  scikit-learn scipy sounddevice \
  torch torchvision transformers \
  tqdm tree-sitter \
  whisper \
  langchain-core
```

---

## Rust / Cargo

```bash
# Instalar rustup:
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

rustup update stable
cargo install rust-analyzer
```

---

## Go

```bash
# Instalar Go desde https://go.dev/dl/
# o via: sudo apt install golang
```

---

## Bun

```bash
curl -fsSL https://bun.sh/install | bash
```

---

## Herramientas AI (binarios / instaladores propios)

| Herramienta | Instalación |
|---|---|
| Claude CLI | `pip install claude` o binario |
| Kiro CLI | `~/.local/bin/kiro-cli` |
| OpenCode | `~/.opencode/bin/` |
| LM Studio | https://lmstudio.ai |
| Ollama | `curl -fsSL https://ollama.com/install.sh \| sh` |
| Devin | `~/.local/bin/devin` |
| Codex | `npm install -g @openai/codex` |

---

## Fuentes

```bash
# JetBrains Mono, Fira Code, Hack (ya en apt arriba)
# Nerd Fonts (para lsd/fastfetch iconos)
# https://www.nerdfonts.com/font-downloads
```

---

## Post-instalación

```bash
chsh -s $(which zsh)          # Cambiar shell a zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"  # Oh My Zsh

# Plugins zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

#!/usr/bin/env bash
# install.sh — Dotfiles de Juferoga
# Crea symlinks de los dotfiles hacia su ubicación original en $HOME
# Uso: ./install.sh [--dry-run]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# Parse args
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "Uso: $0 [--dry-run]"
      echo "  --dry-run   Muestra los symlinks que se crearían sin ejecutar nada"
      exit 0
      ;;
  esac
done

[[ "$DRY_RUN" == true ]] && warn "Modo DRY-RUN activado — no se modificará nada"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     Dotfiles installer — Juferoga    ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ─── Función principal de symlink ────────────────────────────────────────────
link() {
  local src="$1"   # relativo al repo
  local dst="$2"   # destino absoluto en $HOME

  local full_src="$DOTFILES_DIR/$src"

  if [[ ! -e "$full_src" ]]; then
    error "Fuente no encontrada: $full_src"
    return
  fi

  # Crear directorio padre si no existe
  local parent_dir
  parent_dir="$(dirname "$dst")"
  if [[ ! -d "$parent_dir" ]]; then
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$parent_dir"
    fi
    info "mkdir -p $parent_dir"
  fi

  # Si ya existe un symlink apuntando al mismo sitio, skip
  if [[ -L "$dst" && "$(readlink "$dst")" == "$full_src" ]]; then
    ok "Ya enlazado: $dst"
    return
  fi

  # Si existe algo (archivo/symlink diferente), hacer backup
  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backup: $dst → $backup"
    if [[ "$DRY_RUN" == false ]]; then
      mv "$dst" "$backup"
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] ln -sf $full_src $dst"
  else
    ln -sf "$full_src" "$dst"
    ok "Enlazado: $dst → $full_src"
  fi
}

# ─── Shell ────────────────────────────────────────────────────────────────────
echo "── Shell ──────────────────────────────"
link "shell/.zshrc"    "$HOME/.zshrc"
link "shell/.bashrc"   "$HOME/.bashrc"
link "shell/.zshenv"   "$HOME/.zshenv"
link "shell/.zprofile" "$HOME/.zprofile"
link "shell/.profile"  "$HOME/.profile"

# ─── Git ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Git ────────────────────────────────"
link "git/.gitconfig"        "$HOME/.gitconfig"
link "git/hooks/commit-msg"  "$HOME/.git-hooks/commit-msg"

# Asegurar que el hook sea ejecutable
if [[ "$DRY_RUN" == false && -f "$HOME/.git-hooks/commit-msg" ]]; then
  chmod +x "$HOME/.git-hooks/commit-msg"
fi

# ─── SSH ──────────────────────────────────────────────────────────────────────
echo ""
echo "── SSH ────────────────────────────────"
link "ssh/config" "$HOME/.ssh/config"

# Permisos correctos para SSH
if [[ "$DRY_RUN" == false ]]; then
  chmod 700 "$HOME/.ssh" 2>/dev/null || true
  chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
fi

# ─── Config apps ─────────────────────────────────────────────────────────────
echo ""
echo "── App configs ────────────────────────"
link "config/i3/config"   "$HOME/.config/i3/config"
link "config/htop/htoprc" "$HOME/.config/htop/htoprc"

# ─── Scripts ─────────────────────────────────────────────────────────────────
echo ""
echo "── Scripts ────────────────────────────"
link "scripts/ia-mapper.js" "$HOME/scripts/ia-mapper.js"

# Asegurar que el script sea ejecutable
if [[ "$DRY_RUN" == false && -f "$HOME/scripts/ia-mapper.js" ]]; then
  chmod +x "$HOME/scripts/ia-mapper.js"
fi

# ─── Oh My Zsh plugins (si no están instalados) ──────────────────────────────
echo ""
echo "── Oh My Zsh plugins ──────────────────"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_zsh_plugin() {
  local name="$1"
  local url="$2"
  local path="$ZSH_CUSTOM/plugins/$name"
  if [[ -d "$path" ]]; then
    ok "Plugin ya instalado: $name"
  else
    if [[ "$DRY_RUN" == true ]]; then
      info "[DRY] git clone $url $path"
    else
      info "Instalando plugin: $name"
      git clone --depth=1 "$url" "$path"
      ok "Plugin instalado: $name"
    fi
  fi
}

install_zsh_plugin "zsh-autosuggestions"   "https://github.com/zsh-users/zsh-autosuggestions"
install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

# ─── Resumen ─────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════╗"
if [[ "$DRY_RUN" == true ]]; then
  echo "║  DRY-RUN completado — sin cambios    ║"
else
  echo "║  Instalación completada ✓            ║"
  echo "║  Reinicia el shell: exec zsh         ║"
fi
echo "╚══════════════════════════════════════╝"
echo ""

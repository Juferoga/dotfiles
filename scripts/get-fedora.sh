#!/usr/bin/env bash
# get-fedora.sh — Descarga Fedora 42 Workstation y lo copia a USB con Ventoy
# Uso: ./get-fedora.sh [--usb /dev/sdX] [--dry-run]

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m';  MAGENTA='\033[0;35m'
BOLD='\033[1m';    DIM='\033[2m';       NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR ]${NC}  $*" >&2; }

# ─── Arte ────────────────────────────────────────────────────────────────────
GHOST=$(cat << 'GHOST'

  ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀                       ⠀⠀⠄⠀⠀⠂⠀⠀⠀⡀⠀⠀
  ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁   get-fedora.sh     ⠁⠀⠀⣠⣶⣿⣷⣶⣄⠀⠀⠁
  ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀    by Juferoga      ⠈⠀⢰⡿⠛⢿⡿⠻⣿⡆⠀⡀
  ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀   Fedora 42 USB    ⠀⠠⣾⡇⠀⢸⡇⠀⢸⣧⠀⠀
  ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀                       ⠀⠀⣿⣷⣤⣿⣷⣤⣿⣿⠀⠀
  ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀                       ⠠⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⡀
  ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀                       ⠄⡀⠙⠟⢿⣿⡿⠿⠿⠋⠀⠀

GHOST
)

# ─── Config ───────────────────────────────────────────────────────────────────
FEDORA_VERSION="44"
FEDORA_ISO="Fedora-Workstation-Live-x86_64-${FEDORA_VERSION}-1.1.iso"
FEDORA_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VERSION}/Workstation/x86_64/iso/${FEDORA_ISO}"
FEDORA_CHECKSUM_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VERSION}/Workstation/x86_64/iso/Fedora-Workstation-${FEDORA_VERSION}-1.1-x86_64-CHECKSUM"
DOWNLOAD_DIR="${HOME}/Descargas"
DRY_RUN=false
USB_PATH=""

# ─── Args ────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --usb)     USB_PATH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      echo "Uso: $0 [--usb /punto/de/montaje] [--dry-run]"
      echo "  --usb PATH   Ruta de montaje del USB con Ventoy (ej: /media/juferoga/Ventoy)"
      echo "  --dry-run    Muestra qué haría sin hacer nada"
      exit 0 ;;
    *) error "Argumento desconocido: $1"; exit 1 ;;
  esac
done

# ─── Header ───────────────────────────────────────────────────────────────────
clear
echo -e "${MAGENTA}${GHOST}${NC}"
[[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}  ⚠  Modo DRY-RUN${NC}\n"

# ─── Verificar dependencias ───────────────────────────────────────────────────
for cmd in curl wget sha256sum; do
  command -v "$cmd" &>/dev/null || { error "$cmd no encontrado. Instálalo primero."; exit 1; }
done

# ─── Detectar USB con Ventoy automáticamente si no se pasó --usb ─────────────
detect_ventoy() {
  info "Buscando USB con Ventoy montado..."

  # Buscar partición con label VTOYEFI o Ventoy
  local ventoy_mount
  ventoy_mount=$(lsblk -o LABEL,MOUNTPOINT | awk '$1~/[Vv]entoy|VTOY/ && $2!="" {print $2}' | head -1)

  # Fallback: buscar por archivo vtoy_version en el montaje
  if [[ -z "$ventoy_mount" ]]; then
    for mp in /run/media/"$USER"/*/; do
      if [[ -f "${mp}.ventoy" || -f "${mp}ventoy/ventoy.json" ]]; then
        ventoy_mount="${mp}"
        break
      fi
    done
  fi

  echo "$ventoy_mount"
}

if [[ -z "$USB_PATH" ]]; then
  USB_PATH=$(detect_ventoy)
  if [[ -z "$USB_PATH" ]]; then
    warn "No se encontró USB con Ventoy automáticamente."
    echo -e "  Monta el USB con Ventoy y vuelve a correr el script, o pasa la ruta:"
    echo -e "  ${CYAN}$0 --usb /ruta/al/usb${NC}"
    echo ""
    echo -e "  USBs montados actualmente:"
    lsblk -o NAME,SIZE,LABEL,MOUNTPOINT | grep -v loop | grep -v "^$" | grep " /" | sed 's/^/    /'
    echo ""
    # Preguntar interactivo
    read -rp "  Ingresa la ruta del USB manualmente (o Enter para omitir copia): " USB_PATH
  else
    ok "Ventoy encontrado en: $USB_PATH"
  fi
fi

# ─── Verificar espacio en destino ─────────────────────────────────────────────
ISO_PATH="${DOWNLOAD_DIR}/${FEDORA_ISO}"
ISO_SIZE_GB=2.2

if [[ -n "$USB_PATH" && -d "$USB_PATH" ]]; then
  USB_FREE=$(df -BG "$USB_PATH" | awk 'NR==2 {gsub("G",""); print $4}')
  if [[ "$USB_FREE" -lt 3 ]]; then
    error "USB tiene solo ${USB_FREE}GB libres. Fedora necesita ~2.2GB."
    error "Libera espacio en el USB y vuelve a intentarlo."
    exit 1
  fi
  ok "USB tiene ${USB_FREE}GB disponibles"
fi

# ─── Verificar si el ISO ya existe ───────────────────────────────────────────
section() { echo -e "\n${BOLD}${CYAN}══════ $* ══════${NC}"; }

section "Descarga"

if [[ -f "$ISO_PATH" ]]; then
  ISO_ACTUAL_SIZE=$(du -BM "$ISO_PATH" | cut -f1 | tr -d 'M')
  if [[ "$ISO_ACTUAL_SIZE" -gt 2000 ]]; then
    ok "ISO ya existe y parece completo: $ISO_PATH"
    SKIP_DOWNLOAD=true
  else
    warn "ISO existe pero parece incompleto (${ISO_ACTUAL_SIZE}MB). Re-descargando..."
    SKIP_DOWNLOAD=false
  fi
else
  SKIP_DOWNLOAD=false
fi

# ─── Descargar ISO ────────────────────────────────────────────────────────────
if [[ "$SKIP_DOWNLOAD" == false ]]; then
  info "Descargando Fedora ${FEDORA_VERSION} Workstation (~2.2 GB)..."
  info "URL: ${FEDORA_URL}"
  info "Destino: ${ISO_PATH}"
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] wget -c --show-progress -O '${ISO_PATH}' '${FEDORA_URL}'"
  else
    mkdir -p "$DOWNLOAD_DIR"
    # -c = resume si se cortó
    wget -c --show-progress -O "${ISO_PATH}" "${FEDORA_URL}"
    ok "Descarga completa"
  fi
fi

# ─── Verificar checksum ───────────────────────────────────────────────────────
section "Verificación de integridad"

CHECKSUM_FILE="${DOWNLOAD_DIR}/fedora-checksum.txt"

if [[ "$DRY_RUN" == true ]]; then
  info "[DRY] Descargaría checksum y verificaría SHA256"
else
  info "Descargando checksum oficial..."
  wget -q -O "$CHECKSUM_FILE" "$FEDORA_CHECKSUM_URL" 2>/dev/null || {
    warn "No se pudo descargar el checksum. Saltando verificación."
    CHECKSUM_FILE=""
  }

  if [[ -n "$CHECKSUM_FILE" && -f "$CHECKSUM_FILE" ]]; then
    info "Verificando SHA256..."
    EXPECTED=$(grep "$FEDORA_ISO" "$CHECKSUM_FILE" | grep SHA256 | awk '{print $NF}' | tr '[:upper:]' '[:lower:]')
    if [[ -z "$EXPECTED" ]]; then
      # Formato alternativo del checksum
      EXPECTED=$(grep "$FEDORA_ISO" "$CHECKSUM_FILE" | awk '{print $1}')
    fi

    if [[ -n "$EXPECTED" ]]; then
      ACTUAL=$(sha256sum "$ISO_PATH" | awk '{print $1}')
      if [[ "$ACTUAL" == "$EXPECTED" ]]; then
        ok "SHA256 verificado ✓"
      else
        error "SHA256 no coincide. El ISO puede estar corrupto."
        error "Esperado: $EXPECTED"
        error "Actual:   $ACTUAL"
        error "Borra ${ISO_PATH} y vuelve a correr el script."
        exit 1
      fi
    else
      warn "No se encontró el hash para este ISO en el checksum. Continuando..."
    fi
  fi
fi

# ─── Copiar al USB ────────────────────────────────────────────────────────────
section "Copia al USB"

if [[ -z "$USB_PATH" || ! -d "$USB_PATH" ]]; then
  warn "No se especificó USB válido. El ISO quedó en: ${ISO_PATH}"
  warn "Cópialo manualmente al USB con Ventoy cuando lo montes:"
  echo -e "  ${CYAN}cp '${ISO_PATH}' /ruta/a/ventoy/${NC}"
else
  info "Copiando ISO al USB con Ventoy..."
  info "Destino: ${USB_PATH}/${FEDORA_ISO}"

  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY] cp '${ISO_PATH}' '${USB_PATH}/${FEDORA_ISO}'"
  else
    # Mostrar progreso con rsync si está disponible, si no cp
    if command -v rsync &>/dev/null; then
      rsync --progress --human-readable "$ISO_PATH" "${USB_PATH}/${FEDORA_ISO}"
    else
      cp --progress "$ISO_PATH" "${USB_PATH}/${FEDORA_ISO}" 2>/dev/null \
        || cp "$ISO_PATH" "${USB_PATH}/${FEDORA_ISO}"
    fi
    sync  # flush buffers al USB
    ok "ISO copiado al USB"
  fi
fi

# ─── Resumen final ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  Fedora ${FEDORA_VERSION} listo para instalar               ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}ISO:${NC}    ${ISO_PATH}"
[[ -n "$USB_PATH" && -d "$USB_PATH" ]] && \
  echo -e "${BOLD}USB:${NC}    ${USB_PATH}/${FEDORA_ISO}"
echo ""
echo -e "${BOLD}Particionado recomendado (NVMe — todo para Fedora):${NC}"
echo -e "  ${CYAN}/boot/efi${NC}  →  nvme0n1p1  100MB  vfat   ${DIM}NO formatear (EFI compartido)${NC}"
echo -e "  ${CYAN}/boot${NC}      →  nuevo      1GB    ext4   ${DIM}crear nuevo${NC}"
echo -e "  ${CYAN}/swap${NC}      →  nuevo      8GB    swap   ${DIM}(ya tienes 32GB RAM, opcional)${NC}"
echo -e "  ${CYAN}/${NC}          →  resto      ~190GB btrfs  ${DIM}formatear (adiós Ubuntu+Win)${NC}"
echo -e "  ${CYAN}/home${NC}      →  sda3       406GB  ext4   ${DIM}NO formatear (tus datos)${NC}"
echo ""
echo -e "${BOLD}Post-instalación Nvidia (1 comando):${NC}"
echo -e "  ${CYAN}sudo dnf install -y \\"
echo -e "    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm \\"
echo -e "    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
echo -e "  sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda${NC}"
echo ""
echo -e "${BOLD}Dotfiles (después de instalar):${NC}"
echo -e "  ${CYAN}git clone git@github.com:Juferoga/dotfiles.git ~/repos/personal/dotfiles"
echo -e "  cd ~/repos/personal/dotfiles && ./bootstrap.sh${NC}"
echo ""

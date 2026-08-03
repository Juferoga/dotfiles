# Packages

> Para instalar todo automáticamente usa `bootstrap.sh`.
> Este archivo es solo referencia de lo que instala el script.

```bash
./bootstrap.sh              # instala todo
./bootstrap.sh --dry-run    # previsualizar sin cambios
./bootstrap.sh --only=apt   # solo una sección
```

## Secciones disponibles

| Sección  | Qué instala |
|----------|-------------|
| `apt`    | Paquetes del sistema, herramientas CLI, drivers Nvidia, LaTeX, Docker |
| `brew`   | Homebrew + paquetes (node, gh, ripgrep, python@3.14) |
| `snap`   | Ghostty, Firefox, Spotify, Telegram, OnlyOffice |
| `zsh`    | Oh My Zsh + plugins (autosuggestions, syntax-highlighting) |
| `node`   | NVM + Node v22 + v26 + NPM globals (openclaw, mcporter) |
| `bun`    | Bun runtime |
| `rust`   | rustup + rust-analyzer |
| `python` | uv + pip packages (torch, langchain, opencv, etc.) |
| `ai`     | Ollama + avisos de instalación manual para Kiro/Claude/LMStudio |

## Instalaciones manuales (requieren cuenta o .deb)

- [AnyDesk](https://anydesk.com/en/downloads/linux)
- [Cursor](https://www.cursor.com/)
- [DBeaver CE](https://dbeaver.io/download/)
- [Kiro CLI](https://kiro.dev)
- [LM Studio](https://lmstudio.ai)

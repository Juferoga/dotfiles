# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf zoxide docker aws tmux)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias map-ia='node ~/scripts/ia-mapper.js'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# AI Context Extractor CLI
alias map-ia='node /home/juferoga/repos/personal/ai-context-extractor/dist/index.js'

alias matlab-ex-file='matlab -nodesktop -nojvm < '

# opencode
export PATH=/home/juferoga/.opencode/bin:$PATH
export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# OpenClaw Completion
source "/home/juferoga/.openclaw/completions/openclaw.zsh"
eval "$(zoxide init zsh)"

# Alias Visuales
alias ls="lsd"
alias ll="lsd -l"
alias la="lsd -la"
alias tree="lsd --tree"

# Agentes Lectores
leer_pdf() { pdftotext "$1" - | openclaw "Resume los puntos clave de este texto, enfócate en la metodología: 

" }
leer_img() { tesseract "$1" stdout -l spa+eng 2>/dev/null | openclaw "Analiza el siguiente texto extraído por OCR y explícame de qué trata: 

" }

# Agentes Lectores
leer_pdf() { pdftotext "$1" - | openclaw "Resume los puntos clave de este texto, enfócate en la metodología: 

" }
leer_img() { tesseract "$1" stdout -l spa+eng 2>/dev/null | openclaw "Analiza el siguiente texto extraído por OCR y explícame de qué trata: 

" }

# Módulo de Voz Neuronal (Jarvis Mode)
alias voces="edge-tts --list-voices | grep -i es-"
habla() { edge-playback --voice "es-CO-SalomeNeural" --text "$1" }

# OpenClaw Parlante
oc_habla() { RESPUESTA=$(openclaw "$1"); echo "$RESPUESTA"; edge-playback --voice "es-CO-SalomeNeural" --text "$RESPUESTA" }

# Full Jarvis Mode
jarvis() {
  echo "🎙️ Grabando 6 segundos de audio... ¡Habla!"
  arecord -f cd -d 6 -q /tmp/input.wav
  echo "🧠 Transcribiendo con Whisper..."
  TEXTO=$(whisper /tmp/input.wav --model tiny --language es --output_format txt --output_dir /tmp >/dev/null 2>&1 && cat /tmp/input.txt)
  echo "👤 Tú: $TEXTO"
  echo "🤖 OpenClaw:"
  oc_habla "$TEXTO"
}

# El Flex Definitivo
clear
fastfetch

# Protocolo de Inicio Táctico (Jarvis Morning Briefing)
briefing() {
  echo "🔍 Recopilando telemetría del sistema..."
  CLIMA=$(curl -s "wttr.in/Bogota?format=%C+%t" 2>/dev/null || echo "Desconocido")
  DISCO=$(df -h / | awk 'NR==2 {print $5}')
  RAM=$(free -m | awk 'NR==2{printf "%d%%", $3*100/$2 }')
  DOCKER=$(docker ps -q 2>/dev/null | wc -l)
  HORA=$(date "+%H:%M")
  
  PROMPT="Actúa como la IA de mi nave. Son las $HORA. El clima afuera es $CLIMA. Mi disco está al $DISCO de capacidad, la RAM al $RAM y tengo $DOCKER contenedores activos. Dame un reporte de estado corto (máximo 3 líneas), motivador y con humor cyberpunk. Recuérdame sutilmente que los modelos de difusión para la tesis de esteganografía no se van a entrenar solos. Termina confirmando que el sistema está en línea."
  
  echo "🧠 Jarvis está procesando el entorno..."
  RESP=$(openclaw "$PROMPT")
  
  clear
  fastfetch
  echo -e "\n🤖 Jarvis: $RESP\n"
  edge-playback --voice "es-CO-SalomeNeural" --text "$RESP"
}

# OpenClaw voz helper
if [ -f "$HOME/.local/bin/oc_voice.sh" ]; then source "$HOME/.local/bin/oc_voice.sh"; fi

# bun completions
[ -s "/home/juferoga/.bun/_bun" ] && source "/home/juferoga/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/juferoga/.lmstudio/bin"
# End of LM Studio CLI section


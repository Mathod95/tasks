# PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export PATH="/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/bin"
source $HOMEBREW_PREFIX/opt/zinit/zinit.zsh
#source "$(brew --prefix)"/opt/fzf/shell/key-bindings.zsh
#source "$(brew --prefix)"/opt/fzf/shell/completion.zsh
export PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"

# LANG
export LANG=en_US.utf8

# BIND
bindkey -e                       # Use Emacs-style keybindings in the shell
bindkey "^[[3~" delete-char      # Map Delete key to delete-char
bindkey "^[[H" beginning-of-line # Map Home key to move to beginning of line
bindkey "^[[F" end-of-line       # Map End key to move to end of line

# OPTIONS
setopt AUTO_CD                   # Allow changing directories by typing the directory name without 'cd'
setopt INTERACTIVE_COMMENTS      # Enable comments in interactive shell commands
setopt HIST_IGNORE_DUPS          # Ignore duplicate commands in history
setopt HIST_IGNORE_SPACE         # Ignore commands starting with a space
setopt INC_APPEND_HISTORY        # Append commands to history immediately, not at shell exit
setopt SHARE_HISTORY             # Share command history across all sessions
setopt APPEND_HISTORY            # Append to the history file rather than overwrite it
setopt BANG_HIST                 # Enable history expansion using '!' syntax
setopt EXTENDED_HISTORY          # Save timestamps and durations in history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before saving to history
setopt HIST_VERIFY               # Show history-expanded command before running it

# OTHER
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=100000

# ALIASES
alias kubectl="kubecolor"
alias szshrc="source ~/.zshrc"
alias zshrc="vim ~/.zshrc"
alias nabbr="vim ~/.config/zsh-abbr/user-abbreviations"
# COMPLETION
autoload -Uz compinit           # Disable if zsh-autocomplete
compinit                        # Disable if zsh-autocomplete
compdef kubecolor=kubectl

# ZSTYLE
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# ZINIT PLUGINS
zinit ice wait"0" lucid
zinit load Aloxaf/fzf-tab
#zinit light marlonrichert/zsh-autocomplete
zinit ice wait lucid
zinit load zdharma-continuum/fast-syntax-highlighting
zinit ice wait lucid
zinit load zsh-users/zsh-autosuggestions
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light olets/zsh-abbr
zinit light hlissner/zsh-autopair
#zinit light unixorn/fzf-zsh-plugin # Pas de timestamp, pas d'historique complet juste 1 commandes
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search

# CONFIG ###################################################################################################

## ZELLIJ
if [[ -z "$ZELLIJ" ]]; then
    zellij attach -c MATHOD
fi

# POWERLEVEL10K
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ABBR
ABBR_EXPAND_PUSH_ABBREVIATION_TO_HISTORY=0
ABBR_SET_EXPANSION_CURSOR=1
ABBR_EXPANSION_CURSOR_MARKER=%
ABBR_SET_LINE_CURSOR=1
ABBR_GET_AVAILABLE_ABBREVIATION=1
ABBR_LOG_AVAILABLE_ABBREVIATION=0

# FUNCTION
autoload -U add-zsh-hook
add-zsh-hook preexec my_abbreviation_reminder

my_abbreviation_reminder() {
  if [[ -n "$ABBR_UNUSED_ABBREVIATION" ]]; then
    # Set color codes
    local green="\e[32m"
    local red="\e[31m"
    local reset="\e[0m"  # Reset color back to normal

    # Display the custom reminder with proper colors
    echo -e "💡 Reminder: You could have used the abbreviation '${green}$ABBR_UNUSED_ABBREVIATION${reset}' for '${red}$ABBR_UNUSED_ABBREVIATION_EXPANSION${reset}'."
  fi
}

if [[ -z "$DISABLE_AUTO_EZA" ]]; then
  function auto_eza_on_cd() {
    eza --icons --group-directories-first --git
  }

  # Override the default cd function to run auto_eza_on_cd
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd auto_eza_on_cd
fi
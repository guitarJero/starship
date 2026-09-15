# Transient prompt for starship (zsh only).
#
# Once a command is submitted, collapses the prompt down to just the
# character. RPROMPT is left untouched, so it keeps showing whatever it had
# at that moment (e.g. the time). Requires the "transient" profile defined
# in prompt.toml.
#
# Must be sourced AFTER `starship init zsh` has run, e.g.:
#   eval "$(starship init zsh)"
#   source "$HOME/.config/starship/transient.zsh"

if [[ -o interactive ]] && (( $+functions[starship_zle-keymap-select] )) && [[ -z "$_STARSHIP_TRANSIENT_LOADED" ]]; then
  _STARSHIP_TRANSIENT_LOADED=1

  TRANSIENT_PROMPT="${PROMPT// prompt / prompt --profile transient }"

  autoload -Uz add-zle-hook-widget
  transient_prompt_render() {
    PROMPT="$TRANSIENT_PROMPT" zle .reset-prompt
  }
  add-zle-hook-widget zle-line-finish transient_prompt_render
fi

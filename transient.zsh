# Transient prompt for starship (zsh only).
#
# Once a command is submitted, collapses the prompt down to a fill line and
# the prompt character. RPROMPT is left untouched, so it keeps showing
# whatever it had at that moment (e.g. the time). Requires the "transient"
# profile defined in prompt.toml.
#
# Must be sourced AFTER `starship init zsh` has run, e.g.:
#   eval "$(starship init zsh)"
#   source "$HOME/.config/starship/transient.zsh"

if [[ -o interactive ]] && (( $+functions[starship_zle-keymap-select] )) && [[ -z "$_STARSHIP_TRANSIENT_LOADED" ]]; then
  _STARSHIP_TRANSIENT_LOADED=1

  _starship_full_prompt=$PROMPT

  _starship_transient_render() {
    PROMPT="${_starship_full_prompt// prompt / prompt --profile transient }"
    zle .reset-prompt
  }
  zle -N zle-line-finish _starship_transient_render

  _starship_restore_prompt() {
    PROMPT=$_starship_full_prompt
  }
  add-zsh-hook precmd _starship_restore_prompt
fi

#!/usr/bin/env bash
#
# Installs this starship config into the current machine. Safe to re-run.
#
# Sets up zsh and bash, both with the transient prompt. zsh uses zle hooks
# (transient.zsh); bash needs ble.sh (https://github.com/akinomyoga/ble.sh),
# which this script installs if missing.
#
# Usage:
#   git clone git@github.com:guitarJero/starship.git ~/.config/starship
#   ~/.config/starship/install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/starship"
MARKER_START="# >>> starship (guitarJero/starship) >>>"
MARKER_END="# <<< starship (guitarJero/starship) <<<"

echo "==> Repo directory: $REPO_DIR"

if [[ "$REPO_DIR" != "$TARGET_DIR" ]]; then
  echo "This repo needs to live at $TARGET_DIR (starship + this setup expect it there)."
  if [[ -L "$TARGET_DIR" && "$(readlink "$TARGET_DIR")" == "$REPO_DIR" ]]; then
    echo "==> $TARGET_DIR already symlinked to $REPO_DIR"
  elif [[ -e "$TARGET_DIR" ]]; then
    echo "Error: $TARGET_DIR already exists and is not this repo. Move it aside and re-run." >&2
    exit 1
  else
    echo "==> Symlinking $TARGET_DIR -> $REPO_DIR"
    mkdir -p "$(dirname "$TARGET_DIR")"
    ln -s "$REPO_DIR" "$TARGET_DIR"
  fi
  REPO_DIR="$TARGET_DIR"
fi

if ! command -v starship >/dev/null 2>&1; then
  echo "==> starship not found, installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install starship
  else
    curl -sS https://starship.rs/install.sh | sh
  fi
else
  echo "==> starship already installed ($(command -v starship))"
fi

# Appends the marked config block to $1 unless it's already there.
# $2 = shell init line (e.g. 'eval "$(starship init zsh)"')
# $3 = extra line to append after it (optional, e.g. sourcing transient.zsh)
configure_rc() {
  local rc="$1" init_line="$2" extra_line="${3:-}"
  mkdir -p "$(dirname "$rc")"
  touch "$rc"
  if grep -qF "$MARKER_START" "$rc"; then
    echo "==> $rc already configured, leaving it as-is"
    return
  fi
  echo "==> Adding starship setup to $rc"
  {
    echo ""
    echo "$MARKER_START"
    echo 'export STARSHIP_CONFIG="$HOME/.config/starship/prompt.toml"'
    echo "$init_line"
    [[ -n "$extra_line" ]] && echo "$extra_line"
    echo "$MARKER_END"
  } >> "$rc"
}

if command -v zsh >/dev/null 2>&1; then
  # Respect $ZDOTDIR if set, then the XDG-style ~/.config/zsh/.zshrc some
  # setups use, falling back to the classic ~/.zshrc.
  if [[ -n "${ZDOTDIR:-}" ]]; then
    ZSHRC="$ZDOTDIR/.zshrc"
  elif [[ -f "$HOME/.config/zsh/.zshrc" ]]; then
    ZSHRC="$HOME/.config/zsh/.zshrc"
  else
    ZSHRC="$HOME/.zshrc"
  fi
  configure_rc "$ZSHRC" 'eval "$(starship init zsh)"' 'source "$HOME/.config/starship/transient.zsh"'
else
  echo "==> zsh not found, skipping zsh setup"
fi


# Installs ble.sh (nightly build) into ~/.local/share if it isn't there yet.
# Prints the path to ble.sh on stdout; progress messages go to stderr.
install_ble_sh() {
  local blesh_sh="$HOME/.local/share/blesh/ble.sh"
  if [[ -f "$blesh_sh" ]]; then
    echo "==> ble.sh already installed ($blesh_sh)" >&2
    echo "$blesh_sh"
    return
  fi
  echo "==> ble.sh not found, installing nightly build..." >&2
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$tmp_dir"
  bash "$tmp_dir/ble-nightly/ble.sh" --install "$HOME/.local/share" >&2
  rm -rf "$tmp_dir"
  echo "$blesh_sh"
}

# Sets up ~/.bashrc: sources ble.sh (--attach=none) as the first line, adds
# our starship + bleopt block, and keeps `ble-attach` as the last line.
setup_bash() {
  local blesh_sh="$1"
  local rc="$HOME/.bashrc"
  local source_line="[[ \$- == *i* ]] && source -- \"$blesh_sh\" --attach=none"
  local attach_line='[[ ! ${BLE_VERSION-} ]] || ble-attach'

  mkdir -p "$(dirname "$rc")"
  touch "$rc"

  if ! grep -qF -- "$blesh_sh" "$rc"; then
    echo "==> Adding ble.sh source line to the top of $rc"
    { echo "$source_line"; echo ""; cat "$rc"; } > "$rc.tmp"
    mv "$rc.tmp" "$rc"
  fi

  # Drop any previous `ble-attach` line so it can be safely re-appended last.
  grep -vF "$attach_line" "$rc" > "$rc.tmp" || true
  mv "$rc.tmp" "$rc"

  if grep -qF "$MARKER_START" "$rc"; then
    echo "==> $rc already has the starship block, leaving it as-is"
  else
    echo "==> Adding starship + transient (bleopt) setup to $rc"
    {
      echo ""
      echo "$MARKER_START"
      echo 'export STARSHIP_CONFIG="$HOME/.config/starship/prompt.toml"'
      echo 'eval "$(starship init bash)"'
      echo 'bleopt prompt_ps1_transient=always'
      echo "bleopt prompt_ps1_final='\$(starship module character)'"
      echo "bleopt prompt_rps1_final='\$(starship module time)'"
      echo "$MARKER_END"
    } >> "$rc"
  fi

  echo "" >> "$rc"
  echo "$attach_line" >> "$rc"
}

if command -v bash >/dev/null 2>&1; then
  BLESH_SH="$(install_ble_sh)"
  setup_bash "$BLESH_SH"
else
  echo "==> bash not found, skipping bash setup"
fi

echo "==> Done. Restart your shell."

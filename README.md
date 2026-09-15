# starship config

Mi configuración de [starship](https://starship.rs), con un transient prompt:
al ejecutar un comando, esa línea se colapsa a solo el `❯` (dejando el
lado derecho tal como quedó, con la hora del momento en que se corrió).
Funciona tanto en zsh como en bash.

## Requisitos

- [starship](https://starship.rs) (el instalador lo agrega solo si falta)
- `zsh` y/o `bash`
- [ble.sh](https://github.com/akinomyoga/ble.sh) para el transient prompt en
  bash (el instalador lo agrega solo si falta; no aplica si solo usas zsh)
- Un [Nerd Font](https://www.nerdfonts.com/) instalado y seleccionado en la
  terminal (para los íconos)

## Instalación rápida

```sh
git clone git@github.com:guitarJero/starship.git ~/.config/starship
~/.config/starship/install.sh
exec zsh   # o: exec bash
```

`install.sh` es idempotente (se puede correr de nuevo sin duplicar nada). Hace lo siguiente:

1. Si el repo no está clonado en `~/.config/starship`, crea un symlink ahí.
2. Instala `starship` si no está (vía `brew` en macOS, o el instalador oficial en otros casos).
3. Si detecta `zsh`, agrega a su `.zshrc` (respetando `$ZDOTDIR`, luego
   `~/.config/zsh/.zshrc`, y por último `~/.zshrc`) un bloque marcado con:
   ```sh
   export STARSHIP_CONFIG="$HOME/.config/starship/prompt.toml"
   eval "$(starship init zsh)"
   source "$HOME/.config/starship/transient.zsh"
   ```
4. Si detecta `bash`, instala [ble.sh](https://github.com/akinomyoga/ble.sh)
   (build nightly) en `~/.local/share/blesh` si hace falta, y configura
   `~/.bashrc` con:
   ```sh
   [[ $- == *i* ]] && source -- "$HOME/.local/share/blesh/ble.sh" --attach=none

   export STARSHIP_CONFIG="$HOME/.config/starship/prompt.toml"
   eval "$(starship init bash)"
   bleopt prompt_ps1_transient=always
   bleopt prompt_ps1_final='$(starship module character)'
   bleopt prompt_rps1_final='$(starship module time)'

   [[ ! ${BLE_VERSION-} ]] || ble-attach
   ```
   (`ble.sh` tiene que cargarse primero y hacer `ble-attach` al final del
   archivo — el instalador respeta ese orden aunque el `.bashrc` ya tenga
   otras cosas en medio.)

## Instalación manual

Si prefieres no correr el script, agrega tú mismo las líneas de arriba a tu
`.zshrc` y/o `.bashrc` (en ese orden), y asegúrate de que el repo esté
clonado en `~/.config/starship` (o ajusta las rutas si lo tienes en otro
lado).

## Cómo funciona el transient prompt

- `prompt.toml` define un perfil `[profiles] transient = "$fill\n$character"`,
  una versión reducida del prompt completo.
- En **zsh**, `transient.zsh` engancha `zle-line-finish` (se dispara al
  aceptar una línea) y redibuja el `PROMPT` usando ese perfil
  (`starship prompt --profile transient ...`), sin tocar `RPROMPT`.
- En **bash**, [ble.sh](https://github.com/akinomyoga/ble.sh) provee el
  equivalente vía `bleopt prompt_ps1_transient` / `prompt_ps1_final` /
  `prompt_rps1_final`, usando `starship module character` y
  `starship module time` directamente (bash no soporta `right_format` de
  forma nativa, por eso el lado derecho en bash solo existe gracias a
  ble.sh).
- `add_newline = false` evita el salto de línea en blanco que starship
  agrega por defecto antes de cada prompt.

Para cambiar qué queda visible en las líneas ya ejecutadas, edita el perfil
`transient` en `prompt.toml` (aplica igual para zsh y, vía
`starship module character`, para bash).

## Notas

- Si solo usas uno de los dos shells, el instalador simplemente se salta la
  configuración del otro.
- ble.sh cambia el line editor de bash (agrega resaltado de sintaxis,
  autosugerencias, etc.), no es solo el transient prompt.

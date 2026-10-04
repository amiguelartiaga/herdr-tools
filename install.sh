#!/usr/bin/env bash
# install.sh            symlink bin/* into ~/.local/bin (local machine)
# install.sh HOST...    copy bin/herdr-view and bin/v to HOST:~/.local/bin (remote machines)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

if (($#)); then
  for host in "$@"; do
    printf '%s: ' "$host"
    ssh -o BatchMode=yes "$host" 'mkdir -p ~/.local/bin' && \
      scp -q "$here/bin/herdr-view" "$here/bin/v" "$host:.local/bin/" && echo "herdr-view and v installed"
  done
  exit 0
fi

mkdir -p ~/.local/bin
for tool in "$here"/bin/*; do
  [[ -f $tool && -x $tool ]] || continue
  ln -sfn "$tool" ~/.local/bin/"$(basename "$tool")"
  echo "Installed: ~/.local/bin/$(basename "$tool") -> $tool"
done
echo
echo "Hyprland bindings for ~/.config/hypr/bindings.lua (Omarchy), then: hyprctl reload"
echo '  o.bind("SUPER + SHIFT + H", "Terminal on herdr machine/dir", "~/.local/bin/herdr-here")'
echo '  o.bind("SUPER + SHIFT + K", "Kitty on herdr machine/dir", "~/.local/bin/herdr-here -t kitty")'

#!/bin/zsh
# Installs the `vpn` zsh function: copies vpn.zsh to ~/.config/vpn/ and sources it
# from your .zshrc. Safe to run again (updates the file, never duplicates the line).
set -euo pipefail

src="${0:A:h}/vpn.zsh"
dest_dir="$HOME/.config/vpn"
rc="${ZDOTDIR:-$HOME}/.zshrc"
line='[[ -r "$HOME/.config/vpn/vpn.zsh" ]] && source "$HOME/.config/vpn/vpn.zsh"'

[[ -r "$src" ]] || { echo "vpn.zsh not found next to install.sh" >&2; exit 1; }

mkdir -p "$dest_dir"
cp "$src" "$dest_dir/vpn.zsh"
echo "Installed $dest_dir/vpn.zsh"

touch "$rc"
if grep -qF '.config/vpn/vpn.zsh' "$rc"; then
  echo "$rc already sources it"
else
  printf '\n# GlobalProtect on/off/status (gp-vpn)\n%s\n' "$line" >> "$rc"
  echo "Added a source line to $rc"
fi

[[ -d /Applications/GlobalProtect.app ]] || echo "Note: GlobalProtect.app is not installed; only 'vpn status' will be useful."
echo "Open a new terminal (or run: exec zsh), then try: vpn status"

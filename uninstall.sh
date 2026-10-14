#!/bin/zsh
# Removes the `vpn` function and its source line. Leaves GlobalProtect itself alone.
set -euo pipefail

rc="${ZDOTDIR:-$HOME}/.zshrc"

rm -f "$HOME/.config/vpn/vpn.zsh"
rmdir "$HOME/.config/vpn" 2>/dev/null || true
echo "Removed ~/.config/vpn/vpn.zsh"

if [[ -f "$rc" ]] && grep -qF '.config/vpn/vpn.zsh' "$rc"; then
  cp "$rc" "$rc.gp-vpn.bak"
  grep -vF -e '.config/vpn/vpn.zsh' -e '# GlobalProtect on/off/status (gp-vpn)' "$rc.gp-vpn.bak" > "$rc"
  echo "Removed the source line from $rc (backup: $rc.gp-vpn.bak)"
fi

echo "If you ran 'vpn off', GlobalProtect stays stopped until a reboot. Run 'vpn on' first if you want it back now."

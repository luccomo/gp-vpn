# vpn — manual on/off/status for Palo Alto GlobalProtect on macOS.
#
# Works around GlobalProtect 6.2.x auto-reconnecting after you click Disconnect
# (GPC-26003): `vpn off` unloads the launchd jobs that keep GlobalProtect alive,
# so nothing is left that can reconnect. `vpn on` loads them back.
#
# Optional settings (export before this file is sourced, e.g. in ~/.zshrc):
#   VPN_GP_PREFIX   IPv4 prefix of your corporate tunnel address, e.g. "10." or "172.16.".
#                   Unset: any utun IPv4 address outside Tailscale's 100.64.0.0/10 counts.
#   VPN_TAILSCALE   "0" hides the Tailscale/exit-node line in `vpn status`.
#                   Unset: shown only when Tailscale is installed.

vpn() {
  local daemon=/Library/LaunchDaemons/com.paloaltonetworks.gp.pangpsd.plist
  local svc=/Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist
  local agent=/Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist
  local uid=$(id -u)
  local has_gp=0; [[ -d /Applications/GlobalProtect.app ]] && has_gp=1

  if [[ "$1" == (on|off) ]] && (( ! has_gp )); then
    echo "GlobalProtect is not installed on $(hostname -s)"; return 1
  fi

  case "$1" in
    off)
      echo "Stopping GlobalProtect (sudo needed for the system daemon)…"
      launchctl bootout gui/$uid "$agent" 2>/dev/null
      launchctl bootout gui/$uid "$svc" 2>/dev/null
      sudo launchctl bootout system "$daemon" 2>/dev/null
      sleep 2
      vpn status ;;
    on)
      echo "Starting GlobalProtect (sudo needed for the system daemon)…"
      sudo launchctl bootstrap system "$daemon" 2>/dev/null
      launchctl bootstrap gui/$uid "$svc" 2>/dev/null
      launchctl bootstrap gui/$uid "$agent" 2>/dev/null
      open -a GlobalProtect
      echo "GlobalProtect started, click Connect" ;;
    status|"")
      (( has_gp )) && _vpn_gp_status
      _vpn_tailscale_status ;;
    *)
      echo "usage: vpn on|off|status" ; return 2 ;;
  esac
}

# GlobalProtect tunnel = a utun interface with a non-Tailscale IPv4 address
# (or one matching VPN_GP_PREFIX when set).
_vpn_gp_status() {
  local tun=$(ifconfig 2>/dev/null | awk -v pre="${VPN_GP_PREFIX:-}" '
    /^[a-z]/ { ifc = $1; sub(/:$/, "", ifc) }
    ifc ~ /^utun/ && $1 == "inet" {
      split($2, o, ".")
      if (pre != "" ? index($2, pre) == 1 : !(o[1] == 100 && o[2] >= 64 && o[2] <= 127))
        { print ifc " " $2; exit }
    }')
  if [[ -n "$tun" ]]; then echo "GlobalProtect: CONNECTED (${tun% *}, ${tun#* })"
  else echo "GlobalProtect: no tunnel"; fi

  if pgrep -x PanGPS >/dev/null 2>&1; then echo "GP agent: running"
  else echo "GP agent: stopped (cannot reconnect until 'vpn on' or a reboot)"; fi
}

# Optional: report whether Tailscale is routing through an exit node (e.g. Mullvad).
_vpn_tailscale_status() {
  [[ "${VPN_TAILSCALE:-}" == 0 ]] && return
  local ts=${commands[tailscale]:-/Applications/Tailscale.app/Contents/MacOS/Tailscale}
  [[ -x "$ts" ]] || return

  local out
  if ! out=$("$ts" status 2>/dev/null); then
    echo "Tailscale: not running"; return
  fi
  # The exit node in use is the peer whose status reads "active; exit node" / "idle; exit node"
  # (peers that merely *offer* one read "offers exit node").
  local exit=$(print -r -- "$out" | awk '/^[0-9]/ && /; exit node/ { print $2; exit }')
  case "$exit" in
    *mullvad*) echo "Tailscale: up, Mullvad exit node $exit" ;;
    ?*)        echo "Tailscale: up, exit node $exit" ;;
    *)         echo "Tailscale: up, no exit node" ;;
  esac
}

(( $+functions[compdef] )) && { _vpn() { compadd on off status }; compdef _vpn vpn }

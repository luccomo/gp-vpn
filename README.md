# gp-vpn

A `vpn` command for zsh on macOS that really turns Palo Alto GlobalProtect off.

GlobalProtect 6.2.x has a bug (GPC-26003): after you click **Disconnect**, it reconnects
by itself. `vpn off` gets around that by unloading the launchd jobs that keep GlobalProtect
running, so nothing is left that can reconnect.

```
vpn on       # load GlobalProtect again and open it, then click Connect
vpn off      # stop GlobalProtect completely, then show status
vpn status   # tunnel, agent and (optionally) Tailscale exit node; plain `vpn` does the same
```

Example:

```
$ vpn status
GlobalProtect: CONNECTED (utun4, 10.12.34.56)
GP agent: running
Tailscale: up, no exit node
```

## Install

```
git clone <this repo> gp-vpn   # or unzip it
cd gp-vpn
./install.sh
exec zsh
```

`install.sh` copies `vpn.zsh` to `~/.config/vpn/` and adds one `source` line to your
`.zshrc` (`$ZDOTDIR/.zshrc` if you set `ZDOTDIR`). Running it again updates the file
without adding a second line. `./uninstall.sh` removes both and backs up your `.zshrc` first.

## Things to know

- **`on` and `off` ask for your password.** The GlobalProtect daemon is a system launchd
  job, so loading and unloading it needs `sudo`.
- **`off` lasts until the next reboot.** macOS loads GlobalProtect's jobs at startup again.
  Run `vpn off` after booting if you want it off.
- **How "connected" is detected.** A `utun` network interface with an IPv4 address outside
  Tailscale's `100.64.0.0/10` range counts as the GlobalProtect tunnel. If your company's
  tunnel address always starts the same way, set it so other VPNs aren't mistaken for it:

  ```
  export VPN_GP_PREFIX="10."
  ```

## Optional: Tailscale

When Tailscale is installed, `vpn status` adds a line saying whether it is up and which
exit node (for example a Mullvad one) your traffic is going through. Without Tailscale the
line simply doesn't appear. To hide it even when Tailscale is installed:

```
export VPN_TAILSCALE=0
```

Put these `export` lines in your `.zshrc` **above** the `source` line that `install.sh` added.

## Requirements

macOS, zsh (the default shell), GlobalProtect installed in `/Applications`. Nothing else:
no Homebrew, Python or jq needed.

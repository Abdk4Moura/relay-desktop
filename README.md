# Relay desktop receiver

Turns your **computer** into a target for the **Relay** phone app over **WiFi** —
wireless keyboard, mouse/trackpad, clipboard sync and two-way file transfer.
Runs on **Linux, Windows and macOS**.

- **Linux** injects via the kernel's **uinput** (works under X11 *and* Wayland).
- **Windows / macOS** inject via the OS synthetic-input APIs (SendInput / CGEvent).

> WiFi mode is for **computers**. iPads can't be controlled this way — use Relay's
> Bluetooth HID mode for those. WiFi unlocks clipboard sync, file drop, longer
> range and no pairing.

## Install (one line)

**Linux / macOS**
```sh
curl -fsSL https://github.com/Abdk4Moura/relay-desktop/releases/latest/download/install.sh | sh
```

**Windows** (PowerShell)
```powershell
irm https://github.com/Abdk4Moura/relay-desktop/releases/latest/download/install.ps1 | iex
```

This downloads the right prebuilt binary, enables **start-on-login**, and launches it.
Then open the Relay app on your phone — it discovers this computer automatically.
Manage autostart later with `relay-desktop autostart on|off`.

> Unsigned for now: macOS Gatekeeper / Windows SmartScreen will warn on first launch.
> Allow it through ("More info → Run anyway" / right-click → Open). Signing is on the roadmap.

## Build from source

```sh
cargo build --release
```

Needs a Rust toolchain (`rustup`). On Linux, `evdev` talks to `/dev/uinput` directly
(no kernel headers); Windows/macOS pull `enigo`/`arboard`/`notify-rust` automatically.

## Grant uinput access — Linux only (one-time, avoids running as root)

The one-line installer does this for you. Manually:

```sh
sudo cp 99-uinput.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG input $USER     # log out / back in for the group to take effect
```

(Or just run the binary with `sudo` to skip this.) On **macOS**, grant Relay
**Accessibility** permission the first time (System Settings → Privacy & Security).

## Run

```sh
./target/release/relay-desktop --token 1234 --port 47600
```

On launch it opens a **control panel** in your browser (`http://127.0.0.1:47601`)
showing the PIN, this machine's IP, a live connection indicator, and an injected-event
counter. In the Relay app, switch to **WiFi mode**, enter this machine's **IP** + the
**PIN**, and connect. (The terminal also prints the PIN/port if you have no browser.)

## Protocol (for the app side)

Newline-delimited JSON over TCP, UTF-8. First line must authenticate:

| message | meaning |
|---|---|
| `{"t":"hello","token":"1234"}` | handshake (required first) |
| `{"t":"text","s":"hello"}` | type a UTF-8 string |
| `{"t":"key","code":40,"mods":8}` | HID usage code + HID modifier bitmask (bit0 Ctrl, 1 Shift, 2 Alt, 3 GUI) |
| `{"t":"move","dx":12,"dy":-4}` | relative pointer move |
| `{"t":"scroll","dy":2}` | wheel |
| `{"t":"button","b":"left","down":true}` | hold/release a button (`left`/`right`/`middle`) |
| `{"t":"click","b":"right"}` | press + release |
| `{"t":"consumer","usage":205}` | media/brightness (Consumer-page usage) |

The codes are exactly what Relay already produces for Bluetooth HID, so the app
just serializes the same events to the socket instead of the HID report.

## Roadmap

- **Phase 1 (this):** type / move / click / scroll / media over WiFi.
- **Phase 2:** mDNS auto-discovery (`_relay._tcp`), TLS, clipboard sync, file drop.
- **Phase 3:** absolute pointing via a streamed desktop thumbnail; multi-host.

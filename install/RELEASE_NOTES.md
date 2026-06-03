## Relay desktop receiver

Turn this computer into a wireless keyboard / mouse / clipboard / file target for the [Relay](https://github.com/Abdk4Moura/relay-hid) phone app. **Linux, Windows and macOS.**

### Install (one line)

**Linux / macOS**
```sh
curl -fsSL https://github.com/Abdk4Moura/relay-desktop/releases/latest/download/install.sh | sh
```

**Windows** (PowerShell)
```powershell
irm https://github.com/Abdk4Moura/relay-desktop/releases/latest/download/install.ps1 | iex
```

The installer downloads the right binary, enables start-on-login, and launches it. Then open the Relay app on your phone — it discovers this computer automatically over Wi-Fi. Control panel: <http://127.0.0.1:47601>.

### Or grab a binary

Download the archive for your platform below, extract `relay-desktop`, and run it.

> Unsigned for now: macOS Gatekeeper / Windows SmartScreen will warn on first launch — allow it through ("More info → Run anyway" / right-click → Open).

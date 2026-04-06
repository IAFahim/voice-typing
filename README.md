# Voice Typing with Whisper

Push-to-talk voice transcription for Linux (Wayland/GNOME).

Hold **Ctrl+Alt+V**, speak, release -- text appears at your cursor.

## Quick Install

```bash
git clone https://github.com/IAFahim/voice-typing.git ~/voice-typing
cd ~/voice-typing
chmod +x setup.sh
./setup.sh
```

Then **log out and back in** (required for `input` group to take effect).

## Requirements

- Ubuntu 25.04+ / GNOME 45+ on Wayland
- Python 3.10+
- Microphone (USB headset, built-in, etc.)

The `setup.sh` script handles everything else:
- ALSA / ffmpeg / xclip / ydotool / wl-clipboard
- Python venv with faster-whisper
- ydotoold systemd user service
- GNOME custom keyboard shortcut
- Whisper base model pre-download

## Usage

1. Press **Ctrl+Alt+V** -- notification sound plays, recording starts
2. Speak into your microphone
3. Press **Ctrl+Alt+V** again -- bell sound, recording stops, text types at your cursor

## Architecture

```
toggle.sh  (triggered by Ctrl+Alt+V via GNOME shortcut)
├── No recording active → start arecord (ALSA) in background
└── Recording active     → stop arecord
                          → transcribe.py (faster-whisper on CPU)
                          → ydotool type (Wayland-native keystroke injection)
```

### Files

| File | Purpose |
|------|---------|
| `setup.sh` | One-time installation script |
| `toggle.sh` | Main hotkey toggle (record start/stop + paste) |
| `transcribe.py` | Whisper transcription (writes result to file) |

### How typing works (Wayland)

`ydotool` creates a virtual input device via `/dev/uinput` and the `ydotoold` daemon. This injects keystrokes at the kernel level, bypassing Wayland compositor restrictions. Unlike `wtype` (needs `zwp_virtual_keyboard` which GNOME/Mutter doesn't implement) or `xdotool` (X11/XWayland only), ydotool works with **all** native Wayland apps.

## Configuration

### Microphone device

```bash
arecord -l  # list available devices
```

Edit `MIC_DEVICE` in `toggle.sh` (default: `hw:1,0`).

### Model size

Edit `transcribe.py`:

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| `tiny` | 39M | Fastest | Basic |
| `base` | 74M | Fast | Good (default) |
| `small` | 244M | Moderate | Better |
| `medium` | 769M | Slow | Great |
| `large` | 1550M | Slowest | Best |
| `turbo` | 809M | Fast | Great |

### Language

Edit `transcribe.py` -- change `language="en"` to any of 99 supported languages.

### Hotkey

```bash
# Or change via GNOME Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Shortcut not firing | Restart gsd-media-keys: `killall gsd-media-keys; /usr/libexec/gsd-media-keys &` |
| No audio detected | Check mic with `arecord -D hw:1,0 -f S16_LE -r 44100 -c 2 -d 3 test.wav && aplay test.wav` |
| Text not typing | Check `systemctl --user status ydotoold` -- should be active |
| ydotoold crashes | Log out/in for `input` group: `groups` should show `input` |
| Double triggering | Debounce is 1s in toggle.sh, increase if needed |

## Uninstall

```bash
systemctl --user disable --now ydotoold
rm -rf ~/voice-typing
# Remove shortcut: GNOME Settings → Keyboard → Custom Shortcuts
# Remove udev rule: sudo rm /etc/udev/rules.d/60-ydotool.rules
```

## License

MIT

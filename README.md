# Voice Typing with Whisper

Push-to-talk voice transcription for Linux (Wayland/GNOME).

Hold a hotkey, speak, release -- text appears at your cursor.

## Requirements

- Linux with GNOME (Wayland or X11)
- Python 3.10+
- ffmpeg / arecord (audio recording)
- xclip, xdotool (clipboard & paste)
- NVIDIA GPU optional (falls back to CPU)

## Setup

```bash
# Create venv and install dependencies
python3 -m venv ~/voice-typing
~/voice-typing/bin/pip install faster-whisper sounddevice numpy pynput

# Install system packages
sudo apt install arecord xclip xdotool inotify-tools pulseaudio-utils wl-clipboard

# Make executable
chmod +x ~/voice-typing/toggle.sh ~/voice-typing/transcribe.py
```

## Usage

1. Press **Ctrl+Alt+V** to start recording
2. Speak into your microphone
3. Press **Ctrl+Alt+V** again to stop -- text is transcribed and pasted at your cursor

## Configuration

Edit `transcribe.py` to change:

- `MODEL_SIZE` -- `"tiny"`, `"base"`, `"small"`, `"medium"`, `"large"`, `"turbo"` (default: `"base"`)
- `language` -- `"en"`, `"es"`, `"fr"`, etc. (default: `"en"`)

Edit `toggle.sh` to change:

- `MIC_DEVICE` -- ALSA device for your mic (default: `hw:1,0`)
- Shortcut keybinding -- set via GNOME Settings > Keyboard > Custom Shortcuts

## How It Works

```
toggle.sh
├── Ctrl+Alt+V (no recording) → start arecord in background
└── Ctrl+Alt+V (recording)    → stop arecord
                                → transcribe.py (faster-whisper)
                                → xclip + xdotool paste
```

- **faster-whisper** -- CTranslate2-based Whisper, 4x faster than openai-whisper
- **arecord** -- ALSA direct recording, no Python audio deps needed
- **xclip + xdotool** -- clipboard + simulated paste
- Debounce prevents double-trigger from key repeat
- Minimum 2-second recording to avoid accidental triggers

## Auto-start

A desktop entry is installed at:
```
~/.config/autostart/voice-typing.desktop
```

## Changing the Hotkey

```bash
# Via gsettings
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>v'

# Or: GNOME Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts
```

## Troubleshooting

- **No audio detected** -- Check your mic device with `arecord -l` and update `MIC_DEVICE` in `toggle.sh`
- **Shortcut not firing** -- Restart gsd-media-keys: `kill -HUP $(pgrep gsd-media-keys)`
- **Text not pasting** -- On Wayland, xdotool may need XWayland. Check with `xdotool type 'test'`
- **Low accuracy** -- Switch to `"small"` or `"turbo"` model in `transcribe.py`

## Log

```
~/voice-typing/voice_type.log
```

## License

MIT

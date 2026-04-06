#!/bin/bash
set -e

VENV="$HOME/voice-typing"
LOG="$VENV/setup.log"

echo "=== Voice Typing Setup ===" | tee "$LOG"

echo "[1/7] Installing system packages..." | tee -a "$LOG"
sudo apt install -y \
  alsa-utils \
  ffmpeg \
  xclip \
  xdotool \
  inotify-tools \
  pulseaudio-utils \
  wl-clipboard \
  ydotool \
  ydotoold \
  python3-venv \
  2>&1 | tail -5 | tee -a "$LOG"

echo "[2/7] Creating venv and installing Python packages..." | tee -a "$LOG"
python3 -m venv "$VENV"
"$VENV/bin/pip" install --quiet faster-whisper sounddevice numpy 2>&1 | tail -3 | tee -a "$LOG"

echo "[3/7] Setting udev rules for ydotool..." | tee -a "$LOG"
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/60-ydotool.rules > /dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG input "$USER"

echo "[4/7] Setting up ydotoold systemd user service..." | tee -a "$LOG"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/ydotoold.service" << 'EOF'
[Unit]
Description=ydotool daemon

[Service]
ExecStart=/usr/bin/sg input -c /usr/bin/ydotoold
Restart=always

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now ydotoold

echo "[5/7] Setting up GNOME keyboard shortcut (Ctrl+Alt+V)..." | tee -a "$LOG"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null | sed "s/]/, '\/org\/gnome\/settings-daemon\/plugins\/media-keys\/custom-keybindings\/voice-typing\/']/" | sed "s/\[,/[/")" \
  2>/dev/null || true

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voice-typing/ name 'Voice Typing'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voice-typing/ command "$VENV/toggle.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voice-typing/ binding '<Ctrl><Alt>v'

echo "[6/7] Making scripts executable..." | tee -a "$LOG"
chmod +x "$VENV/toggle.sh" "$VENV/transcribe.py"

echo "[7/7] Pre-downloading Whisper base model..." | tee -a "$LOG"
"$VENV/bin/python3" -c "
from faster_whisper import WhisperModel
WhisperModel('base', device='cpu', compute_type='int8')
print('Model downloaded.')
" 2>&1 | tail -3 | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "=== Setup Complete ===" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "USAGE:" | tee -a "$LOG"
echo "  Ctrl+Alt+V  - start recording" | tee -a "$LOG"
echo "  Ctrl+Alt+V  - stop recording, transcribe, type text" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "NOTE: Log out and back in for the 'input' group to take effect." | tee -a "$LOG"
echo "      After logout/login, ydotoold will work properly." | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "CONFIG:" | tee -a "$LOG"
echo "  Mic device:    edit MIC_DEVICE in toggle.sh (arecord -l to list)" | tee -a "$LOG"
echo "  Model size:    edit MODEL_SIZE in transcribe.py" | tee -a "$LOG"
echo "  Language:      edit LANGUAGE in transcribe.py" | tee -a "$LOG"
echo "  Hotkey:        GNOME Settings > Keyboard > Custom Shortcuts" | tee -a "$LOG"
echo "  Log:           $VENV/voice_type.log" | tee -a "$LOG"

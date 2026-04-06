#!/bin/bash
LOCK="/tmp/voice_typing_recording.lock"
DEBOUNCE="/tmp/voice_typing_debounce"
WAV="/tmp/voice_typing_audio.wav"
LOG="/home/i/voice-typing/voice_type.log"
PYTHON="/home/i/voice-typing/bin/python3"
TRANSCRIBE="/home/i/voice-typing/transcribe.py"
RESULT="/tmp/voice_typing_result.txt"

ts() { date '+%H:%M:%S'; }

if [ -f "$DEBOUNCE" ]; then
    NOW=$(date +%s)
    THEN=$(cat "$DEBOUNCE")
    DIFF=$((NOW - THEN))
    if [ "$DIFF" -lt 1 ]; then
        exit 0
    fi
fi
date +%s > "$DEBOUNCE"

if [ -f "$LOCK" ]; then
    START=$(cat /tmp/voice_typing_start_time 2>/dev/null || echo 0)
    NOW=$(date +%s)
    ELAPSED=$((NOW - START))
    if [ "$ELAPSED" -lt 2 ]; then
        echo "[$(ts)] Too short (${ELAPSED}s)" >> "$LOG"
        exit 0
    fi

    echo "[$(ts)] Stopping (${ELAPSED}s)..." >> "$LOG"
    kill "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null
    rm -f "$LOCK"
    sleep 0.5

    if [ -f "$WAV" ]; then
        paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null &
        echo "[$(ts)] Transcribing..." >> "$LOG"
        rm -f "$RESULT"
        $PYTHON "$TRANSCRIBE" >> "$LOG" 2>&1

        # Paste right here in the shortcut's own process context
        if [ -f "$RESULT" ]; then
            TEXT=$(cat "$RESULT")
            if [ -n "$TEXT" ]; then
                echo "[$(ts)] Pasting: $TEXT" >> "$LOG"
                printf '%s' "$TEXT" | xclip -selection clipboard
                sleep 0.1
                xdotool key --clearmodifiers ctrl+v
            fi
        fi
    else
        echo "[$(ts)] No audio" >> "$LOG"
    fi
else
    echo "[$(ts)] Recording..." >> "$LOG"
    rm -f "$WAV"
    arecord -D hw:1,0 -f S16_LE -r 44100 -c 2 "$WAV" &>/dev/null &
    echo $! > "$LOCK"
    date +%s > /tmp/voice_typing_start_time
    paplay /usr/share/sounds/freedesktop/stereo/message-new-instant.oga 2>/dev/null &
    echo "[$(ts)] PID $(cat "$LOCK")" >> "$LOG"
fi

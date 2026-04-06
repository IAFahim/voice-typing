#!/home/i/voice-typing/bin/python3
import sys
import os
import shlex
from faster_whisper import WhisperModel

WAVFILE = "/tmp/voice_typing_audio.wav"
RESULT = "/tmp/voice_typing_result.txt"

model = WhisperModel("base", device="cpu", compute_type="int8")

segments, info = model.transcribe(WAVFILE, language="en", beam_size=3, vad_filter=True)
text = " ".join(s.text for s in segments).strip()

if text:
    print(f'Heard: "{text}"')
    with open(RESULT, "w") as f:
        f.write(text)
else:
    print("No speech detected")

if os.path.exists(WAVFILE):
    os.remove(WAVFILE)

#!/usr/bin/env python3
"""Generate short crack and reveal sound effects for the fortune cookie app."""

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "FortuneCookie" / "Sounds"


def write_wav(path: Path, samples: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", max(-32768, min(32767, sample))) for sample in samples)
        wav_file.writeframes(frames)


def generate_crack() -> list[int]:
    duration = 0.28
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 18)
        noise = random.uniform(-1, 1) * decay
        pop = math.sin(2 * math.pi * 90 * t) * decay * 0.45
        snap = math.sin(2 * math.pi * 220 * t) * decay * 0.2 * (1 if i < total // 4 else 0)
        value = (noise + pop + snap) * 32767 * 0.85
        samples.append(int(value))
    return samples


def generate_rustle() -> list[int]:
    """Short plastic-bag crinkle — layered noise bursts, no pitched tones."""
    duration = 0.26
    total = int(SAMPLE_RATE * duration)
    buffer = [0.0] * total

    for _ in range(random.randint(10, 16)):
        start = int(random.uniform(0, total * 0.72))
        length = int(random.uniform(SAMPLE_RATE * 0.006, SAMPLE_RATE * 0.028))
        amplitude = random.uniform(0.2, 1.0)
        decay = random.uniform(40.0, 95.0)

        for j in range(length):
            idx = start + j
            if idx >= total:
                break
            t = j / SAMPLE_RATE
            envelope = amplitude * math.exp(-t * decay)
            # Alternating noise sign mimics high-frequency crinkle texture.
            grain = random.uniform(-1, 1)
            if j % 2 == 0:
                grain *= random.uniform(0.6, 1.0)
            buffer[idx] += grain * envelope

    peak = max(abs(sample) for sample in buffer) or 1.0
    target = 32767 * 0.8
    return [int(max(-32768, min(32767, sample * target / peak))) for sample in buffer]


def generate_reveal() -> list[int]:
    duration = 0.45
    total = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 4.5)
        tone = (
            math.sin(2 * math.pi * 523.25 * t) * 0.35
            + math.sin(2 * math.pi * 659.25 * t) * 0.25
            + math.sin(2 * math.pi * 783.99 * t) * 0.15
        )
        value = tone * env * 32767 * 0.55
        samples.append(int(value))
    return samples


def main() -> None:
    write_wav(OUTPUT_DIR / "crack.wav", generate_crack())
    write_wav(OUTPUT_DIR / "reveal.wav", generate_reveal())
    write_wav(OUTPUT_DIR / "rustle.wav", generate_rustle())
    print(f"Generated sounds in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()

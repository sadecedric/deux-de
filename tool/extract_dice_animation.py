"""Extract the repeating three-second idle animation from the supplied clip.

Usage: python tool/extract_dice_animation.py VIDEO [FFMPEG]
"""

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw


video = Path(sys.argv[1])
ffmpeg = sys.argv[2] if len(sys.argv) > 2 else "ffmpeg"
destination = Path(__file__).resolve().parents[1] / "assets" / "dice"
destination.mkdir(parents=True, exist_ok=True)

width, height, frame_count = 640, 416, 90
result = subprocess.check_output(
    [
        ffmpeg, "-loglevel", "error", "-ss", "1.633333", "-i", str(video),
        "-frames:v", str(frame_count), "-vf", "fps=30,format=rgb24",
        "-f", "rawvideo", "-",
    ]
)
frame_bytes = width * height * 3
assert len(result) == frame_count * frame_bytes, len(result)

size = 184
mask = Image.new("L", (size, size))
ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
for name, x in (("left", 55), ("right", 334)):
    sheet = Image.new("RGBA", (size * 10, size * 9))
    for index in range(frame_count):
        frame = Image.frombytes(
            "RGB", (width, height), result[index * frame_bytes:(index + 1) * frame_bytes]
        )
        die = frame.crop((x, 29, x + 254, 283))
        die = die.resize((size, size), Image.Resampling.LANCZOS).convert("RGBA")
        die.putalpha(mask)
        sheet.paste(die, ((index % 10) * size, (index // 10) * size))
    sheet.save(destination / f"{name}_idle.webp", lossless=True, method=6)

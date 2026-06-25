"""
Generate icon_1024.png for Rheum Pie.
Run: python _make_icon.py
Requires: Pillow (pip install Pillow)

Design: warm cream background, teal pie-slice chart (evokes "pie chart" / rheumatology lab charts),
clean readable aesthetic.
"""
from PIL import Image, ImageDraw, ImageFont
import math
import sys

SIZE = 1024
RADIUS = 380
CENTER = SIZE // 2
BG_COLOR = (255, 248, 235)       # warm cream
TEAL = (32, 178, 143)            # teal accent
TEAL_DARK = (20, 130, 100)       # darker teal for border/shadow
RUST = (200, 80, 60)             # warm rust red slice
GOLD = (230, 175, 50)            # gold slice

img = Image.new("RGB", (SIZE, SIZE), BG_COLOR)
draw = ImageDraw.Draw(img)

# Draw a circular clip background (pill shape)
draw.ellipse(
    [CENTER - RADIUS, CENTER - RADIUS, CENTER + RADIUS, CENTER + RADIUS],
    fill=(245, 220, 190)
)

# Draw pie slices  (start angle: -90 = top; PIL measures clockwise)
def draw_pie_slice(draw, cx, cy, r, start_deg, sweep_deg, fill, outline=None):
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.pieslice(bbox, start=start_deg - 90, end=(start_deg + sweep_deg) - 90, fill=fill, outline=outline)

# Three slices totaling 360
draw_pie_slice(draw, CENTER, CENTER, RADIUS - 20, 0,   180, TEAL, outline=BG_COLOR)
draw_pie_slice(draw, CENTER, CENTER, RADIUS - 20, 180, 120, RUST, outline=BG_COLOR)
draw_pie_slice(draw, CENTER, CENTER, RADIUS - 20, 300, 60,  GOLD, outline=BG_COLOR)

# Inner white circle (donut cutout)
inner_r = RADIUS * 0.45
draw.ellipse(
    [CENTER - inner_r, CENTER - inner_r, CENTER + inner_r, CENTER + inner_r],
    fill=BG_COLOR
)

# Draw a simple text label "Rp" in the donut hole
try:
    font = ImageFont.truetype("arial.ttf", int(inner_r * 1.1))
except Exception:
    font = ImageFont.load_default()

label = "Rp"
bbox = draw.textbbox((0, 0), label, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text((CENTER - tw // 2, CENTER - th // 2 - 10), label, fill=TEAL_DARK, font=font)

# Save opaque RGB (no alpha — iOS blanks icons with alpha channels)
img.save("icon_1024.png", "PNG")
print("Wrote icon_1024.png")

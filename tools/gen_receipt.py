#!/usr/bin/env python3
"""Generate a realistic Indonesian thermal receipt PNG for OCR testing."""
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "C:/Windows/Fonts/consola.ttf"
WIDTH = 720
MARGIN = 36
LINE_H = 44
FONT_SIZE = 30

lines = [
    ("KOPI SENJA CAFE", "center"),
    ("Jl. Riau No. 45, Bandung", "center"),
    ("Telp: 022-9876543", "center"),
    ("------------------------------", "center"),
    ("Nama Item        Qty  Harga", "left"),
    ("------------------------------", "center"),
    ("Kopi Susu Gula Aren.. 1X 28.000", "left"),
    ("Roti Bakar Coklat.... 2X 30.000", "left"),
    ("Avocado Coffee....... 1X 34.000", "left"),
    ("Toast Smoked Beef.... 1X 38.000", "left"),
    ("Es Teh Manis Manis... 2X 5.000", "left"),
    ("------------------------------", "center"),
    ("Subtotal............. 170.000", "left"),
    ("PPN 11%.............. 18.700", "left"),
    ("Service Charge....... 8.500", "left"),
    ("------------------------------", "center"),
    ("TOTAL................ 197.200", "left"),
    ("Bayar (Cash)......... 200.000", "left"),
    ("Kembali.............. 2.800", "left"),
    ("------------------------------", "center"),
    ("Terima kasih, sampai jumpa!", "center"),
]

font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
# Measure heights
tmp = Image.new("RGB", (10, 10), "white")
td = ImageDraw.Draw(tmp)
text_heights = [td.textbbox((0, 0), t, font=font)[3] for t, _ in lines]
height = MARGIN * 2 + sum(max(LINE_H, h + 10) for h in text_heights)

img = Image.new("RGB", (WIDTH, height), (252, 250, 246))
d = ImageDraw.Draw(img)

y = MARGIN
for (text, align), th in zip(lines, text_heights):
    if align == "center":
        w = td.textlength(text, font=font)
        x = (WIDTH - w) / 2
    else:
        x = MARGIN
    d.text((x, y), text, font=font, fill=(30, 30, 30))
    y += max(LINE_H, th + 10)

out = "receipt_test.png"
img.save(out)
print(f"saved {out} {WIDTH}x{height}")

"""Writes the 1024x1024 placeholder app icon: flat teal with a white "W". RGB, no alpha.
Pure standard library. Run: python scripts/make_icon.py"""
import math, struct, zlib

N = 1024
BG, FG = (15, 118, 110), (255, 255, 255)
W = 120  # stroke width
# the W as four strokes
PTS = [(220, 270), (370, 760), (512, 420), (654, 760), (804, 270)]
SEGS = list(zip(PTS, PTS[1:]))


def dist(px, py, a, b):
    (ax, ay), (bx, by) = a, b
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


rows = []
for y in range(N):
    row = bytearray([0])  # PNG filter: none
    for x in range(N):
        d = min(dist(x, y, a, b) for a, b in SEGS)
        k = max(0.0, min(1.0, W / 2 - d + 0.5))  # 1px antialias edge
        row += bytes(round(BG[i] + (FG[i] - BG[i]) * k) for i in range(3))
    rows.append(bytes(row))


def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    return c + struct.pack(">I", zlib.crc32(tag + data))


png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 2, 0, 0, 0))  # 8-bit RGB
       + chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
       + chunk(b"IEND", b""))
open("Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png", "wb").write(png)

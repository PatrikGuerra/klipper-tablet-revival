#!/usr/bin/env python3
"""Minimal libsdl-settings.cfg patch validated with XSDL 1.11.40.

Reads primitive Java ObjectOutputStream blocks, requires a known layout, and creates
another file without overwriting an existing input/output file. Does not run ADB.
Based on the Settings.java layout and SettingsMenuMouse.java options from the
pelya/commandergenius project. See docs/TOUCH.md.
"""
import argparse
import io
import struct
from pathlib import Path


def patch(raw):
    if raw[:4] != b"\xac\xed\x00\x05":
        raise ValueError("Unexpected Java header")
    data, positions = bytearray(), []
    k = 4
    while k < len(raw):
        tag = raw[k]
        k += 1
        if tag == 0x7A:
            n = struct.unpack_from(">I", raw, k)[0]
            k += 4
        elif tag == 0x77:
            n = raw[k]
            k += 1
        else:
            raise ValueError("Java object is outside the validated format")
        if n > len(raw) - k:
            raise ValueError("Truncated block")
        positions.extend(range(k, k + n))
        data.extend(raw[k:k + n])
        k += n
    # Specific observed profile: reject other layouts instead of guessing.
    if len(data) != 1538:
        raise ValueError("Size differs from the validated profile (1538 bytes)")
    s = io.BytesIO(data)

    def integer():
        return struct.unpack(">i", s.read(4))[0]

    def skip(n):
        if n < 0 or n > len(data) - s.tell():
            raise ValueError("Invalid length")
        s.read(n)

    if integer() != 5:
        raise ValueError("File version differs from 5")
    skip(5 + 24)
    right, zoom = integer(), integer()
    click_offset = s.tell()
    click = integer()
    skip(2 + 8 + 1 + 8)
    for width in (4, 4, 1):
        skip(integer() * width)
    integer()  # keyboard transparency
    skip(integer() * 5)  # gestures: int + bool
    integer()  # gesture sensitivity
    calibration = [integer() for _ in range(4)]
    for _ in range(2):
        skip(integer() * 2)  # UTF-16 strings
    skip(integer() * 16)  # keyboard rectangles
    skip(4 + 4 + 1 + 4 + 4)
    relative_offset = s.tell()
    relative = s.read(1)[0]
    if (click_offset, relative_offset) != (41, 1457):
        raise ValueError("Offsets differ from the validated profile")
    if click not in (0, 7) or relative not in (0, 1) or zoom != 0:
        raise ValueError("Mode differs from the observed one; use the XSDL menus")
    out = bytearray(raw)
    for i in range(click_offset, click_offset + 4):
        out[positions[i]] = 0  # LEFT_CLICK_NORMAL
    out[positions[relative_offset]] = 0  # absolute movement
    print(f"Click {click}->0; relative {relative}->0; preserved calibration {calibration}; right button {right}")
    return bytes(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    output = patch(args.input.read_bytes())
    with args.output.open("xb") as handle:
        handle.write(output)


if __name__ == "__main__":
    main()

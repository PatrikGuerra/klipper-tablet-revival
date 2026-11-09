#!/usr/bin/env python3
"""Patch mínimo do libsdl-settings.cfg validado com XSDL 1.11.40.

Lê blocos primitivos Java ObjectOutputStream, exige layout conhecido e cria
outro arquivo sem sobrescrever entrada/saída existente. Não executa ADB.
Baseado no layout Settings.java e nas opções de SettingsMenuMouse.java do
projeto pelya/commandergenius. Veja docs/TOUCH.md.
"""
import argparse
import io
import struct
from pathlib import Path


def patch(raw):
    if raw[:4] != b"\xac\xed\x00\x05":
        raise ValueError("Cabeçalho Java inesperado")
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
            raise ValueError("Objeto Java fora do formato validado")
        if n > len(raw) - k:
            raise ValueError("Bloco truncado")
        positions.extend(range(k, k + n))
        data.extend(raw[k:k + n])
        k += n
    # Perfil específico observado: recusar outros layouts em vez de adivinhar.
    if len(data) != 1538:
        raise ValueError("Tamanho diferente do perfil validado (1538 bytes)")
    s = io.BytesIO(data)

    def integer():
        return struct.unpack(">i", s.read(4))[0]

    def skip(n):
        if n < 0 or n > len(data) - s.tell():
            raise ValueError("Comprimento inválido")
        s.read(n)

    if integer() != 5:
        raise ValueError("Versão do arquivo diferente de 5")
    skip(5 + 24)
    right, zoom = integer(), integer()
    click_offset = s.tell()
    click = integer()
    skip(2 + 8 + 1 + 8)
    for width in (4, 4, 1):
        skip(integer() * width)
    integer()  # transparência do teclado
    skip(integer() * 5)  # gestos: int + bool
    integer()  # sensibilidade dos gestos
    calibration = [integer() for _ in range(4)]
    for _ in range(2):
        skip(integer() * 2)  # strings UTF-16
    skip(integer() * 16)  # retângulos do teclado
    skip(4 + 4 + 1 + 4 + 4)
    relative_offset = s.tell()
    relative = s.read(1)[0]
    if (click_offset, relative_offset) != (41, 1457):
        raise ValueError("Offsets diferentes do perfil validado")
    if click not in (0, 7) or relative not in (0, 1) or zoom != 0:
        raise ValueError("Modo diferente do observado; use os menus do XSDL")
    out = bytearray(raw)
    for i in range(click_offset, click_offset + 4):
        out[positions[i]] = 0  # LEFT_CLICK_NORMAL
    out[positions[relative_offset]] = 0  # movimento absoluto
    print(f"Clique {click}->0; relativo {relative}->0; calibração preservada {calibration}; botão direito {right}")
    return bytes(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("entrada", type=Path)
    parser.add_argument("saida", type=Path)
    args = parser.parse_args()
    output = patch(args.entrada.read_bytes())
    with args.saida.open("xb") as handle:
        handle.write(output)


if __name__ == "__main__":
    main()

# BBC Micro GEOS Port

This is a proof-of-concept port of the GEOS KERNAL to the **BBC Micro Model B**.

The kernel runs as a **16 KB sideways ROM** at `$8000-$BFFF`. At boot it initialises
the hardware, draws a desktop picture, and attempts to load `DESK TOP` from disk.

## Status

- Kernel ROM (16 KB): **builds and fits** (`GEOS_BBC.rom`, 16384 bytes)
- Boot: hardware init, VIA 100 Hz IRQ, matrix keyboard scan, desktop drawing
- SSD disk image: **created** (`GEOS_BBC.ssd`) with `DESK TOP` application
- File system driver: **not yet implemented** — the ROM will boot but cannot load
  the desktop from disk yet

## Requirements

- [cc65](https://github.com/cc65/cc65) (ca65/ld65)
- make
- python3 (for SSD creation)

## Building

```sh
make SYSTEM=bbc          # build kernel ROM
make SYSTEM=bbc ssd      # build kernel ROM + SSD disk image
```

Output goes to `build/bbc/`:
- `GEOS_BBC.rom` — 16 KB sideways ROM image
- `GEOS_BBC.ssd` — 40-track single-sided DFS disk image

## Testing

Load `GEOS_BBC.rom` in [BeebEm](https://github.com/stardot/beebem-macos) as a
sideways ROM (e.g. ROM slot 4). Attach `GEOS_BBC.ssd` as disk drive 0 and
`*GEOS` to start.

## Memory Map

| Range      | Description                         |
|-----------|-------------------------------------|
| `$3000`   | BBC screen memory (mode 1, 2bpp)    |
| `$5800-$6FFF` | Kernel BSS / variables          |
| `$7000`   | GEOS linear framebuffer (1bpp)      |
| `$8000-$BFFF` | Kernel ROM (sideways ROM)       |
| `$8100`   | Jump table                          |

## Files

- `kernal/kernal_bbc.cfg` — linker configuration for sideways ROM + RAM layout
- `kernal/start/start_bbc.s` — ROM header, reset handler, hardware init, desktop
- `kernal/hw/hw_bbc.s` — I/O initialisation
- `kernal/hw/bank_jmptab_bbc.s` — bank-call stubs for BBC
- `kernal/irq/irq_bbc.s` — VIA timer 1 IRQ handler (100 Hz)
- `kernal/keyboard/keyboard_bbc.s` — matrix keyboard driver
- `kernal/sprites/sprites_bbc.s` — software sprite stubs
- `kernal/time/time_bbc.s` — timekeeping stub
- `inc/bbc.inc` — BBC Micro hardware register definitions
- `inc/bbc_sym.inc` — BBC-specific symbol overrides

## Desktop Application

The `DESK TOP` binary on the SSD is built from
[polluks/geos-desktop2.1](https://github.com/polluks/geos-desktop2.1-master),
a from-scratch cc65 implementation. Use `tools/mkssd.py` to build the SSD
from any `.cvt` file.

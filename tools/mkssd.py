#!/usr/bin/env python3
"""
Build a BBC DFS SSD disk image containing GEOS Converted (.cvt) files.
Output is a 40-track single-sided SSD suitable for BeebEm.

Usage: mkssd.py [-o output.ssd] [-n diskname] file.cvt [file.cvt ...]
"""
import struct, sys, os

SEC = 256
SPT = 10
TRKS = 40
TOT_SEC = TRKS * SPT

def sec_off(track, sector):
    return (track * SPT + sector) * SEC

def mark(sector_bitmap, track, sector):
    n = track * SPT + sector
    sector_bitmap[n // 8] |= 1 << (n % 8)

def make_ssd(cvt_files, diskname=b'GEOS'):
    ssd = bytearray(TOT_SEC * SEC)
    bitmap = [0] * (TOT_SEC // 8)

    # Reserve catalog and directory sectors
    for s in range(3):
        mark(bitmap, 0, s)

    # Build directory entries from .cvt files
    dir_entries = []
    data_sector = 3  # track 0, sector 3

    for cvt_path in cvt_files:
        with open(cvt_path, 'rb') as f:
            raw = f.read()

        if len(raw) < 508:
            print(f'{cvt_path}: too short, skipping')
            continue

        cbm_entry = raw[:254]
        geos_header = raw[254:508]
        file_data = raw[508:]

        # Validate GEOS signature
        sig = cbm_entry[33:33+20]
        if sig != b' formatted GEOS file':
            print(f'{cvt_path}: not a GEOS Converted file, skipping')
            continue

        load_addr = struct.unpack_from('<H', geos_header, 71)[0]
        exec_addr = struct.unpack_from('<H', geos_header, 75)[0]
        length = len(file_data)

        dir_entries.append((load_addr, exec_addr, length, file_data))
        print(f'  {os.path.basename(cvt_path)}: load=${load_addr:04X} exec=${exec_addr:04X} {length} bytes')

    if not dir_entries:
        print('No valid files found')
        return None

    # Catalog sector (track 0, sector 0)
    off = sec_off(0, 0)
    ssd[off] = len(dir_entries)
    name = diskname[:7].ljust(7, b' ')
    for i, b in enumerate(name):
        ssd[off + 1 + i] = b
    ssd[off + 8] = 0  # cycle
    ssd[off + 9] = 0  # boot=0

    # Directory sectors (track 0, sectors 1-2)
    for idx, (load_addr, exec_addr, length, file_data) in enumerate(dir_entries):
        if idx >= 31:
            print('Too many files, max 31')
            break

        # Sector 1: filename entry
        d1 = sec_off(0, 1) + idx * 8
        fname = os.path.basename(cvt_files[idx]).rsplit('.', 1)[0].upper().encode('ascii', errors='replace')
        fname = fname[:7].ljust(7, b' ')
        for i, b in enumerate(fname):
            ssd[d1 + i] = b
        ssd[d1 + 7] = 0  # directory

        # Sector 2: file info
        d2 = sec_off(0, 2) + idx * 8
        ssd[d2]     = load_addr & 0xFF
        ssd[d2 + 1] = (load_addr >> 8) & 0xFF
        ssd[d2 + 2] = 0
        ssd[d2 + 3] = exec_addr & 0xFF
        ssd[d2 + 4] = (exec_addr >> 8) & 0xFF
        ssd[d2 + 5] = 0
        ssd[d2 + 6] = length & 0xFF
        ssd[d2 + 7] = (length >> 8) & 0xFF

        # Write file data to sectors
        fs = 0
        while fs < length:
            trk = data_sector // SPT
            sec = data_sector % SPT
            soff = sec_off(trk, sec)
            chunk = file_data[fs:fs + SEC]
            ssd[soff:soff + len(chunk)] = chunk
            mark(bitmap, trk, sec)
            fs += SEC
            data_sector += 1

    # Write free space bitmap into catalog
    for i, bv in enumerate(bitmap):
        ssd[off + 0x60 + i] = bv

    return ssd

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Build BBC DFS SSD disk image')
    parser.add_argument('files', nargs='+', help='.cvt files to include')
    parser.add_argument('-o', '--output', default='GEOS_BBC.ssd', help='Output SSD path')
    parser.add_argument('-n', '--name', default='GEOS', help='Disk name')
    args = parser.parse_args()

    ssd = make_ssd(args.files, diskname=args.name.encode('ascii'))
    if ssd is None:
        sys.exit(1)

    with open(args.output, 'wb') as f:
        f.write(ssd)
    print(f'Wrote {args.output} ({len(ssd)} bytes)')

"""Archive the library's source trees into zips, verify them, and prune the loose copies.

The owner's ruling: every sprite the game needs is already inside the Godot project, so the
library's `raw/` and `cut/` trees — 1.1 GB of PNG that nothing at runtime reads — become zips in
`asset-library/_archive/`, and the loose copies go. `_prekey_backup/` and `_keying/` stay loose:
they are the reversibility store for keying and the paid-answer cache that keeps a re-key from
re-billing, and the icon pass still reads them.

Nothing is deleted before the zip it lands in has been verified two ways: the entry count and the
per-entry CRC are checked by `zipfile.testzip`, and a random sample of files is md5-compared
between disk and the extracted bytes. `--prune` refuses to delete any file the zip does not hold.

Usage:
    py -3.14 staging/cut/archive.py --state
    py -3.14 staging/cut/archive.py --make raw cut dropped _review
    py -3.14 staging/cut/archive.py --prune raw cut dropped
    py -3.14 staging/cut/archive.py --verify raw
    py -3.14 staging/cut/archive.py --restore raw cut

JSON, markdown and text manifests inside those trees are never pruned: they are a few kilobytes
and they are what a reader greps for provenance.
"""

from __future__ import annotations

import hashlib
import io
import os
import random
import shutil
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIBRARY = os.path.join(ROOT, "asset-library")
ARCHIVE = os.path.join(LIBRARY, "_archive")
KEEP_SUFFIXES = (".json", ".md", ".txt", ".csv")
PRUNABLE = ("raw", "cut", "dropped")
TAG = "2026-09-21"
SAMPLE = 12


def tree(name: str) -> str:
    for candidate in (name, "_" + name):
        path = os.path.join(LIBRARY, candidate)
        if os.path.isdir(path):
            return path
    return os.path.join(LIBRARY, name)


def zip_path(name: str) -> str:
    return os.path.join(ARCHIVE, f"{name.lstrip('_')}_{TAG}.zip")


def files_of(name: str) -> list[str]:
    root = tree(name)
    out: list[str] = []
    for dir_path, _, file_names in os.walk(root):
        for file_name in file_names:
            out.append(os.path.join(dir_path, file_name))
    return sorted(out)


def md5(path: str) -> str:
    digest = hashlib.md5()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def stat_size(path: str) -> int:
    with open(path, "rb") as handle:
        return len(handle.read())


def make(name: str) -> None:
    root = tree(name)
    if not os.path.isdir(root):
        print(f"  {name}: no such tree, skipped")
        return
    os.makedirs(ARCHIVE, exist_ok=True)
    target = zip_path(name)
    members = files_of(name)
    total = sum(os.path.getsize(p) for p in members)
    print(f"  {name}: {len(members)} files, {total / 1e6:.1f} MB -> {os.path.basename(target)}")
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as archive:
        for path in members:
            archive.write(path, os.path.relpath(path, LIBRARY).replace("\\", "/"))
    print(f"     wrote {os.path.getsize(target) / 1e6:.1f} MB; verifying ...")
    verify(name)


def verify(name: str) -> bool:
    target = zip_path(name)
    if not os.path.exists(target):
        print(f"  {name}: no archive at {target}")
        return False
    with zipfile.ZipFile(target) as archive:
        bad = archive.testzip()
        names = archive.namelist()
        if bad is not None:
            print(f"  {name}: CRC FAILED on {bad}")
            return False
        loose = [p for p in files_of(name) if not p.endswith(KEEP_SUFFIXES)]
        missing = [p for p in loose if os.path.relpath(p, LIBRARY).replace("\\", "/") not in names]
        if missing:
            print(f"  {name}: {len(missing)} loose files absent from the archive, e.g. {missing[0]}")
            return False
        sample = random.sample(loose, min(SAMPLE, len(loose))) if loose else []
        for path in sample:
            rel = os.path.relpath(path, LIBRARY).replace("\\", "/")
            if md5(path) != hashlib.md5(archive.read(rel)).hexdigest():
                print(f"  {name}: MD5 MISMATCH for {rel}")
                return False
    print(f"  {name}: OK - {len(names)} entries, {len(sample)} md5-checked against disk")
    return True


def prune(name: str) -> None:
    if not verify(name):
        print(f"  {name}: NOT pruned (verification failed)")
        return
    removed = 0
    freed = 0
    for path in files_of(name):
        if path.endswith(KEEP_SUFFIXES):
            continue
        freed += os.path.getsize(path)
        os.remove(path)
        removed += 1
    for dir_path, dir_names, file_names in os.walk(tree(name), topdown=False):
        if not os.listdir(dir_path):
            os.rmdir(dir_path)
    print(f"  {name}: pruned {removed} files, freed {freed / 1e6:.1f} MB")


def restore(name: str) -> None:
    target = zip_path(name)
    if not os.path.exists(target):
        print(f"  {name}: no archive at {target}")
        return
    os.makedirs(tree(name), exist_ok=True)
    with zipfile.ZipFile(target) as archive:
        archive.extractall(LIBRARY)
        print(f"  {name}: restored {len(archive.namelist())} entries from {os.path.basename(target)}")


def state() -> None:
    print("library source trees:")
    for name in PRUNABLE + ("_prekey_backup", "_keying", "_review", "_archive"):
        root = tree(name)
        if not os.path.isdir(root):
            continue
        members = files_of(name)
        total = sum(os.path.getsize(p) for p in members)
        print(f"  {name:16s} {len(members):5d} files {total / 1e6:9.1f} MB")
        archive = zip_path(name)
        if os.path.exists(archive):
            print(f"  {'':16s} archive {os.path.basename(archive)} {os.path.getsize(archive) / 1e6:.1f} MB")


def main() -> int:
    args = set(sys.argv[1:])
    names = [a for a in sys.argv[1:] if not a.startswith("--")] or list(PRUNABLE)
    if "--state" in args:
        state()
        return 0
    if "--make" in args:
        for name in names:
            make(name)
        return 0
    if "--verify" in args:
        for name in names:
            verify(name)
        return 0
    if "--prune" in args:
        for name in names:
            prune(name)
        return 0
    if "--restore" in args:
        for name in names:
            restore(name)
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

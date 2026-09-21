"""Phase F.1 Stage 4 - import settings for the new resolution bands.

ICONS_SPEC section 9.3 / the work order Stage 4: `_96` and `_192` icon cuts (and the
`@2x` chrome cuts) import with

    mipmaps/generate=true       - so a 96 px texture scaled down on a 1080p canvas
                                  has a mip chain instead of aliasing
    compress/mode=0             - lossless, the mandated mode
    detect_3d/compress_to=0     - 3D auto-detection disabled

Only the `[params]` block of an existing `.import` file is rewritten; the `[remap]`
block (uid, imported path) is left byte-identical so the editor does not have to
re-derive it. The editor still has to reimport the files afterwards.

`--only <pattern...>` narrows a run to the files a wave actually touched, instead of the
whole 1620-file target set (1080 of which currently want the quartet). Each pattern is
matched with shell wildcards, case-insensitively, against every form a file can be
addressed by: the asset-relative path (`icons/ingot/icon_ingot_iron_96.png.import`), the
workspace-relative path, the file name, the `.png` stem (`icon_ingot_iron_96.png`) and the
bare name (`icon_ingot_iron_96`). A pattern ending in `/` scopes to that folder; values may
be space-separated or comma-separated. A pattern that matches nothing aborts the run
before any file is written, so a typo can never half-apply a scope. `--only` only ever
narrows `targets()` - it cannot add a file the `_96`/`_192`/`@2x` rule does not cover.

Usage:
  py -3.14 staging/phase_f/apply_import_settings.py                          # dry run
  py -3.14 staging/phase_f/apply_import_settings.py --apply
  py -3.14 staging/phase_f/apply_import_settings.py --only 'icons/tint/*' --apply
  py -3.14 staging/phase_f/apply_import_settings.py --only icon_ingot_iron_96,icons/status/
"""

from __future__ import annotations

import fnmatch
import re
import sys
from pathlib import Path

# Derived from this file's location, not hardcoded: `staging/phase_f/x.py` sits two
# levels under the workspace root on every host (the mirror runs Windows `G:/...` and
# Linux `~/VajbOrbit`).
WORKSPACE = Path(__file__).resolve().parents[2]
ASSETS = WORKSPACE / "vajb-orbit" / "assets"

WANT = {
    "mipmaps/generate": "true",
    "compress/mode": "0",
    "detect_3d/compress_to": "0",
}

USAGE = "usage: apply_import_settings.py [--apply] [--only PATTERN [PATTERN ...]]"


def targets() -> list[Path]:
    found: list[Path] = []
    for family in ("icons", "ui"):
        # rglob: the naming pass filed the masters into subfolders, so the derived cuts
        # sit next to them (`icons/<group>/icon_<name>_96.png.import`) rather than flat.
        for path in sorted((ASSETS / family).rglob("*.png.import")):
            stem = path.name[: -len(".png.import")]
            if family == "ui":
                if stem.endswith("@2x"):
                    found.append(path)
                continue
            if stem.endswith(("_96", "_192")):
                found.append(path)
    for path in sorted((ASSETS / "icons" / "tint").glob("*.png.import")):
        stem = path.name[: -len(".png.import")]
        if stem.endswith(("_96", "_192")):
            found.append(path)
    return found


def candidate_names(path: Path) -> list[str]:
    """Every form `--only` may address this file by: the workspace-relative path, the
    asset-relative path and the file name, each also without its `.import` suffix, plus
    the bare stem - so a path to either the sidecar or the `.png` itself both work."""
    names: list[str] = []
    for form in (path.relative_to(WORKSPACE).as_posix(),
                 path.relative_to(ASSETS).as_posix(),
                 path.name):
        names.append(form)
        if form.endswith(".import"):
            names.append(form[: -len(".import")])
    names.append(path.name[: -len(".png.import")])
    return names


def select(files: list[Path], patterns: list[str]) -> tuple[list[Path], list[str]]:
    """Narrow `files` to the ones any pattern matches, plus the patterns that matched none.

    Matching is case-insensitive so a pattern written on the Windows mirror behaves the
    same on Linux; a trailing `/` turns the pattern into a folder scope.
    """
    if not patterns:
        return files, []
    globs = [pattern.lower() + "*" if pattern.endswith("/") else pattern.lower()
             for pattern in patterns]
    kept: list[Path] = []
    hit: set[str] = set()
    for path in files:
        names = [name.lower() for name in candidate_names(path)]
        match = next((glob for glob in globs
                      if any(fnmatch.fnmatch(name, glob) for name in names)), None)
        if match is None:
            continue
        hit.add(match)
        kept.append(path)
    return kept, [pattern for pattern, glob in zip(patterns, globs) if glob not in hit]


def usage_error(message: str) -> None:
    """Print the usage line plus `message` and exit 2: a scope problem is never a partial run."""
    sys.stderr.write(f"{USAGE}\n{message}\n")
    sys.exit(2)


def parse_args(argv: list[str]) -> tuple[bool, list[str]]:
    """Return (apply, patterns). Exits 2 on an unknown flag or a patternless `--only`."""
    apply = False
    patterns: list[str] = []
    index = 0
    while index < len(argv):
        arg = argv[index]
        index += 1
        if arg == "--apply":
            apply = True
            continue
        if arg == "--only" or arg.startswith("--only="):
            values = [arg[len("--only="):]] if arg.startswith("--only=") else []
            while index < len(argv) and not argv[index].startswith("--"):
                values.append(argv[index])
                index += 1
            patterns.extend(part.strip() for value in values for part in value.split(",")
                            if part.strip())
            if not patterns:
                usage_error("--only needs at least one pattern")
            continue
        usage_error(f"unknown argument: {arg}")
    return apply, patterns


def rewrite(path: Path, apply: bool) -> list[str]:
    text = path.read_text(encoding="utf-8")
    if "[params]" not in text:
        return []
    head, _, params = text.partition("[params]")
    changed = []
    for key, value in WANT.items():
        pattern = re.compile(rf"^{re.escape(key)}=.*$", re.MULTILINE)
        if not pattern.search(params):
            params = params.rstrip("\n") + f"\n{key}={value}\n"
            changed.append(f"{key}={value} (added)")
            continue
        current = pattern.search(params).group(0)
        if current != f"{key}={value}":
            params = pattern.sub(f"{key}={value}", params)
            changed.append(f"{current} -> {key}={value}")
    if apply and changed:
        path.write_text(head + "[params]" + params, encoding="utf-8")
    return changed


def main() -> int:
    apply, patterns = parse_args(sys.argv[1:])
    found = targets()
    files = found
    if patterns:
        files, unmatched = select(found, patterns)
        print(f"SCOPE: {len(files)} of {len(found)} .import files match "
              f"{len(patterns)} pattern(s): {', '.join(patterns)}")
        if unmatched:
            for pattern in unmatched:
                print(f"UNMATCHED PATTERN: {pattern!r} matches no file in the target set")
            print("no writes: fix the pattern(s) and re-run")
            return 2
    touched = 0
    for path in files:
        changed = rewrite(path, apply)
        if changed:
            touched += 1
            print(f"{path.relative_to(ASSETS)}: {'; '.join(changed)}")
    print(f"\n{'APPLIED' if apply else 'DRY RUN'}: {touched} of {len(files)} .import files "
          f"need the quartet settings (mipmaps on, lossless, 3D detection off)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

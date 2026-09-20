"""D4c checks: every res:// path in the spec and in the mockup resolves on disk, plus a
static audit of the two edited mockup files.

Usage: py -3.14 d4c_paths.py
"""

import os
import re

ROOT = r"G:/Mój dysk/Projekty/Vajb Orbit"
PROJECT = os.path.join(ROOT, "vajb-orbit")
SPEC = os.path.join(ROOT, "docs/design/MAIN_MENU_V2.md")
SCENE = os.path.join(PROJECT, "ui/screens/_mockup_main_menu.tscn")
SCRIPT = os.path.join(PROJECT, "ui/screens/_mockup_main_menu.gd")

RES_PATTERN = re.compile(r"res://[A-Za-z0-9_./-]+")
BARE_PATTERN = re.compile(r"(?:assets|ui|tools|autoload)/[A-Za-z0-9_./-]+\.(?:png|jpg|ogg|wav|tres|tscn|gd)")


def clean(token):
    return token.rstrip("`.,;:)")


def report(path, label):
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    found = []
    for match in RES_PATTERN.findall(text):
        found.append(("res://", clean(match)))
    for match in BARE_PATTERN.findall(text):
        if not match.startswith("res://"):
            found.append(("bare", "res://" + clean(match)))
    seen = []
    for kind, token in found:
        if token not in [t for _, t in seen]:
            seen.append((kind, token))
    print("== %s (%s): %d distinct paths" % (label, os.path.basename(path), len(seen)))
    missing = 0
    for kind, token in seen:
        local = token.replace("res://", "")
        full = os.path.join(PROJECT, local)
        if os.path.exists(full):
            print("   OK   %-52s %8d  %s" % (token, os.path.getsize(full), kind))
        else:
            missing += 1
            print("   MISS %-52s %8s  %s" % (token, "-", kind))
    print("   missing: %d" % missing)
    return missing


def audit():
    for path in (SCENE, SCRIPT):
        with open(path, "r", encoding="utf-8") as handle:
            text = handle.read()
        print("== %s: %d lines, %d bytes" % (os.path.basename(path),
                                             text.count("\n"), len(text.encode("utf-8"))))
    with open(SCENE, "r", encoding="utf-8") as handle:
        scene = handle.read()
    with open(SCRIPT, "r", encoding="utf-8") as handle:
        script = handle.read()
    hexes = re.findall(r"#[0-9a-fA-F]{6}", scene) + re.findall(r"#[0-9a-fA-F]{6}", script)
    print("   hex literals (scene + script):", hexes)
    print("   Color(...) literals in the scene:",
          re.findall(r"Color\([^)]*\)", scene))
    print("   Color(...) literals in the script:",
          re.findall(r"Color\([^)]*\)", script))
    print("   func _process present:", "_process(" in script)
    print("   add_theme_font_size_override present:", "add_theme_font_size_override" in script)
    print("   add_theme_color_override calls:", re.findall(r"add_theme_color_override\([^)]*\)", script))
    print("   class_name / autoload / Router in the script:",
          re.findall(r"class_name|Router\.|AudioManager|SettingsManager|get_node\(\"/root/", script))
    print("   theme_type_variation in the scene:",
          sorted(set(re.findall(r'theme_type_variation = &"([^"]+)"', scene))))
    unique = sorted(set(re.findall(r'\[node name="([^"]+)"[^\]]*\]\nunique_name_in_owner = true', scene)))
    print("   unique_name_in_owner nodes (%d): %s" % (len(unique), unique))
    refs = sorted(set(re.findall(r"%([A-Za-z_]+)", script)))
    print("   %%refs in the script (%d): %s" % (len(refs), refs))
    print("   %%refs with no unique node:", [r for r in refs if r not in unique])
    print("   custom_minimum_size values in the scene:",
          sorted(set(re.findall(r"custom_minimum_size = (Vector2\([^)]*\))", scene))))
    print("   separation values in the scene:",
          sorted(set(re.findall(r"theme_override_constants/separation = (\d+)", scene))))
    print("   load_steps:", re.findall(r"load_steps=(\d+)", scene))


def main():
    missing = report(SPEC, "spec")
    missing += report(SCENE, "scene")
    missing += report(SCRIPT, "script")
    print("TOTAL MISSING: %d" % missing)
    audit()


main()

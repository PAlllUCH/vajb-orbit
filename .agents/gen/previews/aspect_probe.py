"""Launch the station mockup windowed at a given resolution, grab its client area,
then close it. Used for the aspect-ratio probes the movie writer cannot produce.

Usage: py -3.14 aspect_probe.py <width> <height> <out.png> [extra godot args...]
"""

import subprocess
import sys
import time

import ctypes
import ctypes.wintypes as wintypes
import mss

GODOT = r"C:\Godot_4_7_2\Godot_v4.7.2-stable_win64.exe"
PROJECT = r"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
SCENE = "res://ui/screens/_mockup_station.tscn"

user32 = ctypes.windll.user32


def windows_for_pid(pid):
    handles = []

    @ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
    def callback(hwnd, _lparam):
        owner = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
        if owner.value == pid and user32.IsWindowVisible(hwnd):
            handles.append(hwnd)
        return True

    user32.EnumWindows(callback, 0)
    return handles


def client_rect(hwnd):
    rect = wintypes.RECT()
    user32.GetClientRect(hwnd, ctypes.byref(rect))
    point = wintypes.POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(point))
    return (point.x, point.y, rect.right - rect.left, rect.bottom - rect.top)


def main():
    width = sys.argv[1]
    height = sys.argv[2]
    out = sys.argv[3]
    extra = sys.argv[4:]
    args = [
        GODOT,
        "--path",
        PROJECT,
        "--position",
        "60,60",
        "--always-on-top",
        "--resolution",
        "%sx%s" % (width, height),
    ] + extra + [SCENE]
    print("launch", " ".join(args))
    process = subprocess.Popen(args)
    try:
        time.sleep(9)
        handles = windows_for_pid(process.pid)
        if not handles:
            print("no window for pid", process.pid)
            return 1
        left, top, cw, ch = client_rect(handles[0])
        print("client %d,%d %dx%d" % (left, top, cw, ch))
        with mss.mss() as grabber:
            shot = grabber.grab({"left": left, "top": top, "width": cw, "height": ch})
        data = mss.tools.to_png(shot.rgb, shot.size)
        with open(out, "wb") as handle:
            handle.write(data)
        print("saved %s bytes=%d" % (out, len(data)))
    finally:
        process.terminate()
        time.sleep(1)
        if process.poll() is None:
            process.kill()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

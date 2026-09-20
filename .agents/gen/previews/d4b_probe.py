"""Launch the main menu mockup windowed at a given resolution, grab its client area,
then close it. The movie writer always records the root viewport (1920x1080 under
canvas_items stretch), so a real 1600x900 frame needs this instead.

Usage: py -3.14 d4b_probe.py <width> <height> <out.png> [extra godot args...]
"""

import ctypes
import ctypes.wintypes as wintypes
import subprocess
import sys
import time

import mss

GODOT = r"C:\Godot_4_7_2\Godot_v4.7.2-stable_win64.exe"
PROJECT = r"G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
SCENE = "res://ui/screens/_mockup_main_menu.tscn"

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


SW_RESTORE = 9


def pick_window(pid, attempts=20, delay=1.5):
    for _ in range(attempts):
        for hwnd in windows_for_pid(pid):
            if user32.IsIconic(hwnd):
                user32.ShowWindow(hwnd, SW_RESTORE)
                time.sleep(0.4)
            left, top, width, height = client_rect(hwnd)
            if width > 100 and height > 100:
                user32.SetForegroundWindow(hwnd)
                time.sleep(0.4)
                return client_rect(hwnd)
        time.sleep(delay)
    return None


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
        time.sleep(8)
        found = pick_window(process.pid)
        if found is None:
            print("no usable window for pid", process.pid)
            return 1
        left, top, client_width, client_height = found
        print("client %d,%d %dx%d" % (left, top, client_width, client_height))
        with mss.mss() as grabber:
            shot = grabber.grab({"left": left, "top": top,
                                 "width": client_width, "height": client_height})
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

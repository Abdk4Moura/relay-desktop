#!/usr/bin/env python3
"""Headless runtime test for the Linux receiver.

Starts nothing itself — assumes `relay-desktop --token 1234 --port 47600` is already
running and has created its "Relay Virtual Input" uinput device. Then it:
  1. opens the virtual device and starts capturing kernel input events,
  2. connects as a fake phone, authenticates, and sends a few protocol messages,
  3. asserts the matching real input events came out the other side.

This proves the whole WiFi→uinput injection path end-to-end, not just that it compiles.
"""
import json
import socket
import sys
import threading
import time

import evdev
from evdev import InputDevice, ecodes

TOKEN = "1234"
PORT = 47600


def find_device(timeout=10.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        for path in evdev.list_devices():
            try:
                d = InputDevice(path)
            except OSError:
                continue
            if d.name == "Relay Virtual Input":
                return d
        time.sleep(0.3)
    return None


def main():
    dev = find_device()
    if dev is None:
        print("FAIL: 'Relay Virtual Input' uinput device never appeared")
        return 1
    print(f"capturing on {dev.path} ({dev.name})")

    seen = {"key_a": False, "rel_x": False}

    def reader():
        for ev in dev.read_loop():
            if ev.type == ecodes.EV_KEY and ev.code == ecodes.KEY_A and ev.value == 1:
                seen["key_a"] = True
            if ev.type == ecodes.EV_REL and ev.code == ecodes.REL_X and ev.value != 0:
                seen["rel_x"] = True
            if all(seen.values()):
                return

    t = threading.Thread(target=reader, daemon=True)
    t.start()

    s = socket.create_connection(("127.0.0.1", PORT), timeout=5)
    s.settimeout(5)
    s.sendall((json.dumps({"t": "hello", "token": TOKEN}) + "\n").encode())
    time.sleep(0.4)  # let auth settle
    # HID usage 0x04 = 'a'
    s.sendall((json.dumps({"t": "key", "code": 4, "mods": 0}) + "\n").encode())
    s.sendall((json.dumps({"t": "move", "dx": 60, "dy": 0}) + "\n").encode())
    s.sendall((json.dumps({"t": "move", "dx": 60, "dy": 0}) + "\n").encode())

    t.join(timeout=6)

    ok = all(seen.values())
    print(f"key 'a' injected: {seen['key_a']}   mouse moved: {seen['rel_x']}")
    print("PASS" if ok else "FAIL: expected events did not reach the kernel")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())

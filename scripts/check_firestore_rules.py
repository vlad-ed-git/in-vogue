#!/usr/bin/env python3
"""Check firestore.rules on the Firestore emulator with client requests.

    JAVA_HOME=/Users/vlad/Development/java/jdk-21.0.1.jdk/Contents/Home \
      firebase emulators:exec --only firestore --project demo-in-vogue \
      "python3 scripts/check_firestore_rules.py"

The emulator needs Java 21 or newer. A demo- project never reaches a real
one, and each person signs in with the emulator's unsigned test tokens.
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.request

PROJECT = "demo-in-vogue"
HOST = os.environ.get("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080")
BASE = f"http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents"


def b64(data):
    return base64.urlsafe_b64encode(json.dumps(data).encode()).rstrip(b"=").decode()


def token(uid):
    if uid == "admin":
        return "owner"  # the emulator's rules-bypassing admin token
    payload = {
        "sub": uid, "user_id": uid, "iat": 1, "exp": 9999999999, "auth_time": 1,
        "aud": PROJECT, "iss": f"https://securetoken.google.com/{PROJECT}",
        "firebase": {"sign_in_provider": "google.com"},
    }
    return f"{b64({'alg': 'none', 'typ': 'JWT'})}.{b64(payload)}."


class Time(str):
    """An RFC 3339 time, sent as a Firestore timestamp."""


def value(v):
    if isinstance(v, Time):
        return {"timestampValue": v}
    return {"integerValue": str(v)} if isinstance(v, int) else {"stringValue": v}


def call(method, path, uid, data=None, query=""):
    body = None if data is None else json.dumps(
        {"fields": {k: value(v) for k, v in data.items()}}
    ).encode()
    request = urllib.request.Request(
        f"{BASE}/{path}{query}", method=method, data=body,
        headers={"Content-Type": "application/json"},
    )
    if uid is not None:
        request.add_header("Authorization", f"Bearer {token(uid)}")
    try:
        with urllib.request.urlopen(request) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def create(path, uid, data):
    return call("PATCH", path, uid, data, "?currentDocument.exists=false")


def merge(path, uid, data):
    """Like the app's set(..., merge: true) on an existing document."""
    mask = "&".join(f"updateMask.fieldPaths={k}" for k in data)
    return call("PATCH", path, uid, data, f"?currentDocument.exists=true&{mask}")


def replace(path, uid, data):
    return call("PATCH", path, uid, data, "?currentDocument.exists=true")


ALLOW, DENY = 200, 403
REPORT = {
    "account": "a", "at": Time("2026-10-18T09:30:00Z"), "where": "DayRepositoryImpl.watch",
    "error": "FirebaseException cloud_firestore/unavailable", "stack": "#0 main",
    "flavor": "development", "platform": "ios", "version": "1.0.0+7", "build": "release",
    "install": "install-1",
}
cases = [
    ("new account on the demo plan", lambda: create("users/a", "a", {"name": "A", "plan": "pro"}), ALLOW),
    ("new account with no plan", lambda: create("users/c", "c", {"name": "C"}), ALLOW),
    ("new account on another plan", lambda: create("users/b", "b", {"name": "B", "plan": "free"}), DENY),
    ("someone else's new account", lambda: create("users/d", "a", {"name": "D", "plan": "pro"}), DENY),
    ("signed out new account", lambda: create("users/f", None, {"name": "F"}), DENY),
    ("change the name", lambda: merge("users/a", "a", {"name": "A2"}), ALLOW),
    ("save the same plan again", lambda: merge("users/a", "a", {"name": "A3", "plan": "pro"}), ALLOW),
    ("change the plan", lambda: merge("users/a", "a", {"plan": "free"}), DENY),
    ("give a plan to an account with none", lambda: merge("users/c", "c", {"plan": "pro"}), DENY),
    ("drop the plan by replacing the account", lambda: replace("users/a", "a", {"name": "A4"}), DENY),
    ("the console sets a free plan", lambda: create("users/e", "admin", {"name": "E", "plan": "free"}), ALLOW),
    ("upgrade after the console set free", lambda: merge("users/e", "e", {"plan": "pro"}), DENY),
    ("update someone else's account", lambda: merge("users/a", "b", {"name": "B"}), DENY),
    ("read your account", lambda: call("GET", "users/a", "a"), ALLOW),
    ("read someone else's account", lambda: call("GET", "users/a", "b"), DENY),
    ("read signed out", lambda: call("GET", "users/a", None), DENY),
    ("write under your account", lambda: create("users/a/wishlist/w", "a", {"id": "w"}), ALLOW),
    ("write deeper under your account", lambda: create("users/a/days/d/x/y", "a", {"v": 1}), ALLOW),
    ("read under your account", lambda: call("GET", "users/a/wishlist/w", "a"), ALLOW),
    ("write under someone else's", lambda: create("users/a/wishlist/v", "b", {"id": "v"}), DENY),
    ("read under someone else's", lambda: call("GET", "users/a/wishlist/w", "b"), DENY),
    ("write outside users", lambda: create("lists/x", "a", {"id": "x"}), DENY),
    ("delete under your account", lambda: call("DELETE", "users/a/wishlist/w", "a"), ALLOW),
    ("delete someone else's account", lambda: call("DELETE", "users/c", "a"), DENY),
    ("delete your account", lambda: call("DELETE", "users/a", "a"), ALLOW),
    ("file an error report", lambda: create("errors/r1", "a", REPORT), ALLOW),
    ("file a report as someone else", lambda: create("errors/r2", "b", REPORT), DENY),
    ("file a report signed out", lambda: create("errors/r3", None, REPORT), DENY),
    ("file a report with another field", lambda: create("errors/r4", "a", {**REPORT, "message": "x"}), DENY),
    ("file a report missing a field", lambda: create("errors/r5", "a", {k: v for k, v in REPORT.items() if k != "install"}), DENY),
    ("file a report with a long stack", lambda: create("errors/r6", "a", {**REPORT, "stack": "x" * 4001}), DENY),
    ("file a report from another platform", lambda: create("errors/r7", "a", {**REPORT, "platform": "web"}), DENY),
    ("read an error report", lambda: call("GET", "errors/r1", "a"), DENY),
    ("change an error report", lambda: merge("errors/r1", "a", {"where": "x"}), DENY),
    ("delete an error report", lambda: call("DELETE", "errors/r1", "a"), DENY),
]
failed = 0
for name, run, expected in cases:
    status = run()
    ok = status == expected
    failed += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {'ALLOW' if expected == ALLOW else 'DENY ':<5} {name} ({status})")
print(f"{len(cases) - failed}/{len(cases)} as expected")
sys.exit(1 if failed else 0)

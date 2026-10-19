#!/usr/bin/env python3
"""Check storage.rules on the Storage emulator with client requests.

    JAVA_HOME=/Users/vlad/Development/java/jdk-21.0.1.jdk/Contents/Home \
      firebase emulators:exec --only storage --project demo-in-vogue \
      "python3 scripts/check_storage_rules.py"

A demo- project never reaches a real one, and each person signs in with the
emulator's unsigned test tokens.
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT = "demo-in-vogue"
HOST = os.environ.get("FIREBASE_STORAGE_EMULATOR_HOST", "127.0.0.1:9199")
BUCKET = f"{PROJECT}.appspot.com"
BASE = f"http://{HOST}/v0/b/{BUCKET}/o"
JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 64


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


def send(request, uid):
    if uid is not None:
        request.add_header("Authorization", f"Bearer {token(uid)}")
    try:
        with urllib.request.urlopen(request) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def upload(path, uid, content_type="image/jpeg", body=JPEG):
    """Uploads with its metadata, as the app's putFile does, so the rules see the content type."""
    boundary = "check-storage-rules"
    metadata = json.dumps({"name": path, "contentType": content_type}).encode()
    data = (f"--{boundary}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n".encode() + metadata
            + f"\r\n--{boundary}\r\nContent-Type: {content_type}\r\n\r\n".encode() + body
            + f"\r\n--{boundary}--".encode())
    query = urllib.parse.urlencode({"name": path})
    return send(urllib.request.Request(
        f"{BASE}?{query}", method="POST", data=data,
        headers={"Content-Type": f"multipart/related; boundary={boundary}", "X-Goog-Upload-Protocol": "multipart"},
    ), uid)


def read(path, uid):
    return send(urllib.request.Request(f"{BASE}/{urllib.parse.quote(path, safe='')}?alt=media"), uid)


def delete(path, uid):
    return send(urllib.request.Request(f"{BASE}/{urllib.parse.quote(path, safe='')}", method="DELETE"), uid)


ALLOW, DENY = 200, 403
cases = [
    ("upload your own image", lambda: upload("users/a/face.jpg", "a"), ALLOW),
    ("upload a file that isn't an image", lambda: upload("users/a/notes.txt", "a", "text/plain", b"x"), DENY),
    ("upload to someone else's files", lambda: upload("users/b/face.jpg", "a"), DENY),
    ("upload signed out", lambda: upload("users/a/other.jpg", None), DENY),
    ("read your own image", lambda: read("users/a/face.jpg", "a"), ALLOW),
    ("read someone else's image", lambda: read("users/a/face.jpg", "b"), DENY),
    ("read an image signed out", lambda: read("users/a/face.jpg", None), DENY),
    ("the admin key uploads a sample picture", lambda: upload("catalog/v2/sample/s1.jpg", "admin"), ALLOW),
    ("the admin key uploads an outfit picture", lambda: upload("catalog/v2/outfits/n1.jpg", "admin"), ALLOW),
    ("read a sample picture signed out", lambda: read("catalog/v2/sample/s1.jpg", None), ALLOW),
    ("read an outfit picture signed out", lambda: read("catalog/v2/outfits/n1.jpg", None), DENY),
    ("read an outfit picture signed in", lambda: read("catalog/v2/outfits/n1.jpg", "a"), ALLOW),
    ("upload a catalog picture", lambda: upload("catalog/v2/outfits/x1.jpg", "a"), DENY),
    ("replace a sample picture", lambda: upload("catalog/v2/sample/s1.jpg", "a"), DENY),
    ("delete a catalog picture", lambda: delete("catalog/v2/sample/s1.jpg", "a"), DENY),
    ("read elsewhere in the bucket", lambda: read("catalog/v2/other/s1.jpg", "a"), DENY),
    ("delete your own image", lambda: delete("users/a/face.jpg", "a"), ALLOW),
]
failed = 0
for name, run, expected in cases:
    status = run()
    # The emulator answers 204 to a delete it allows.
    ok = status == expected or (expected == ALLOW and status == 204)
    failed += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {'ALLOW' if expected == ALLOW else 'DENY ':<5} {name} ({status})")
print(f"{len(cases) - failed}/{len(cases)} as expected")
sys.exit(1 if failed else 0)

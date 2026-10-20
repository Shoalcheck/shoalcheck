#!/usr/bin/env python3
"""A recorded Kubernetes API, for reading a cluster where no cluster can run.

GitHub's macOS and Windows runners cannot run kind, so release-smoke could only read a cluster on Linux. This
serves the responses a kind cluster gave — the same "smoke" cluster the Linux job builds — so the published
binaries on every platform make a real reading over HTTP: discovery, every list, the pipeline, the rules.

  record <upstream> <file>   forward every request to <upstream> (e.g. `kubectl proxy` on :8001) and keep
                             each answer in <file>
  replay <file>              answer from <file>; a request it holds no answer for gets a 404 and is listed
                             at /__misses, so a recording older than the binary shows up as a failure —
                             and so does any write, which the product never makes

Both listen on 127.0.0.1:18080, which is what kubeconfig.yaml beside this file points at. Standard library only.
"""
import hashlib
import http.client
import http.server
import json
import sys
import threading
import urllib.parse

ADDR = ("127.0.0.1", 18080)


def key(method, path, body):
    k = method + " " + path
    if body:
        k += " #" + hashlib.sha256(body).hexdigest()[:16]
    return k


class Recorder(http.server.BaseHTTPRequestHandler):
    upstream = None
    store = {}
    lock = threading.Lock()
    out = None

    def _forward(self):
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        u = urllib.parse.urlsplit(self.upstream)
        conn = http.client.HTTPConnection(u.hostname, u.port, timeout=60)
        headers = {k: v for k, v in self.headers.items() if k.lower() not in ("host", "accept-encoding", "connection")}
        conn.request(self.command, self.path, body=body or None, headers=headers)
        resp = conn.getresponse()
        data = resp.read()
        ctype = resp.getheader("Content-Type") or "application/json"
        with self.lock:
            self.store[key(self.command, self.path, body)] = {
                "status": resp.status, "type": ctype, "body": data.decode("utf-8")}
            with open(self.out, "w", encoding="utf-8") as f:
                json.dump(self.store, f, indent=0, sort_keys=True)
        self.send_response(resp.status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = _forward

    def log_message(self, *a):
        pass


class Replayer(http.server.BaseHTTPRequestHandler):
    store = {}
    misses = []
    lock = threading.Lock()

    def _answer(self):
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if self.path == "/__misses":
            data = "".join(m + "\n" for m in self.misses).encode()
            status, ctype = 200, "text/plain"
        else:
            hit = self.store.get(key(self.command, self.path, body))
            if hit is None:
                with self.lock:
                    self.misses.append(key(self.command, self.path, body))
                data = json.dumps({"kind": "Status", "apiVersion": "v1", "status": "Failure",
                                   "reason": "NotFound", "code": 404,
                                   "message": "not in the recording: " + self.path}).encode()
                status, ctype = 404, "application/json"
            else:
                data, status, ctype = hit["body"].encode("utf-8"), hit["status"], hit["type"]
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = _answer

    def _write(self):
        # The product writes nothing to a cluster. A write here is listed with the misses, so the step fails.
        with self.lock:
            self.misses.append("WRITE " + self.command + " " + self.path)
        self.send_response(405)
        self.send_header("Content-Length", "0")
        self.end_headers()

    do_PUT = do_PATCH = do_DELETE = _write

    def log_message(self, *a):
        pass


def main(argv):
    if len(argv) == 4 and argv[1] == "record":
        Recorder.upstream, Recorder.out = argv[2], argv[3]
        handler = Recorder
    elif len(argv) == 3 and argv[1] == "replay":
        with open(argv[2], encoding="utf-8") as f:
            Replayer.store = json.load(f)
        handler = Replayer
    else:
        sys.exit(__doc__)
    srv = http.server.ThreadingHTTPServer(ADDR, handler)
    print("listening on http://%s:%d (%s)" % (ADDR[0], ADDR[1], argv[1]), flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main(sys.argv)

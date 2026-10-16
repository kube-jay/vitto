"""Serves the Flutter Web build with SPA fallback (deep links like /l/<id>).

Usage:
    python scripts/serve_web.py [port] [build_dir]
Defaults: port 5000, apps/vitto_app/build/web. Local development only.
"""

import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
ROOT = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else "apps/vitto_app/build/web")


class SpaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def send_head(self):
        path = self.translate_path(self.path.split("?", 1)[0])
        if not os.path.exists(path):
            self.path = "/index.html"
        return super().send_head()

    def end_headers(self):
        # Always fetch the latest build during development.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    print(f"Serving {ROOT} on http://localhost:{PORT}")
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), SpaHandler).serve_forever()

"""Creates a few demo Listings (with generated photos) on LOCAL Supabase.

Usage:
    python scripts/seed_demo_listings.py
Safe to rerun: Listings that already exist are skipped. Uses the seeded test
accounts. Never point at production.
"""

import json
import struct
import sys
import urllib.error
import urllib.parse
import urllib.request
import zlib

API = "http://127.0.0.1:54321"
KEY = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"  # local default key
PASSWORD = "VittoTest123!"

DEMO = [
    ("ada.ng@vitto.test", "phones-tablets", "iPhone 12 – 128 GB, blue",
     "Very clean, battery 89%. Comes with charger and case.", 32000000, True, "used",
     "NG", "LA", "Ikeja", (40, 90, 200)),
    ("ada.ng@vitto.test", "home-furniture", "3-seater fabric sofa",
     "Grey sofa, 2 years old, no stains. Pickup in Lekki.", 15000000, True, "used",
     "NG", "LA", "Lekki", (120, 120, 130)),
    ("chidi.ng@vitto.test", "electronics", "Samsung 43\" Smart TV",
     "Brand new in box, warranty included.", 28500000, False, "new",
     "NG", "FC", "Wuse", (20, 20, 30)),
    ("koffi.bj@vitto.test", "fashion", "Pagne wax – 6 yards",
     "Tissu wax neuf, motifs variés. Livraison possible à Cotonou.", 15000, True, "new",
     "BJ", "LI", "Cotonou", (230, 140, 30)),
    ("awa.bj@vitto.test", "computers", "HP EliteBook 840 G5",
     "Core i5, 8 Go RAM, SSD 256 Go. Très bon état.", 185000, True, "used",
     "BJ", "OU", "Porto-Novo", (60, 60, 70)),
]


def png(rgb, size=480):
    """Solid-colour PNG with a lighter centre square (no dependencies)."""
    r, g, b = rgb
    light = tuple(min(255, c + 70) for c in rgb)
    rows = []
    for y in range(size):
        row = bytearray([0])
        for x in range(size):
            inner = size // 4 < x < 3 * size // 4 and size // 4 < y < 3 * size // 4
            row += bytes(light if inner else (r, g, b))
        rows.append(bytes(row))
    raw = zlib.compress(b"".join(rows), 9)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", raw) + chunk(b"IEND", b""))


def call(method, path, token=None, body=None, raw=None, ctype="application/json",
         prefer=None):
    headers = {"apikey": KEY, "content-type": ctype}
    if token:
        headers["authorization"] = f"Bearer {token}"
    if prefer:
        headers["prefer"] = prefer
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(API + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req) as res:
            out = res.read()
            return json.loads(out) if out else None
    except urllib.error.HTTPError as err:
        sys.exit(f"FAILED {method} {path}: {err.code} {err.read().decode()}")


tokens = {}
for (email, slug, title, desc, price, negotiable, condition, country, region, city,
     colour) in DEMO:
    if email not in tokens:
        res = call("POST", "/auth/v1/token?grant_type=password",
                   body={"email": email, "password": PASSWORD})
        tokens[email] = (res["access_token"], res["user"]["id"])
    token, uid = tokens[email]
    existing = call("GET", "/rest/v1/listings?select=id&seller_id=eq." + uid
                    + "&title=eq." + urllib.parse.quote(title), token)
    if existing:
        print(f"  --  {title} (already there)")
        continue
    cat = call("GET", f"/rest/v1/categories?slug=eq.{slug}&select=id", token)[0]["id"]
    listing = call("POST", "/rest/v1/listings", token, {
        "category_id": cat, "title": title, "description": desc, "price_minor": price,
        "negotiable": negotiable, "condition": condition, "country_code": country,
        "region_code": region, "city": city}, prefer="return=representation")[0]
    path = f"{uid}/{listing['id']}/cover.png"
    call("POST", f"/storage/v1/object/listing-images/{path}", token,
         raw=png(colour), ctype="image/png")
    call("POST", "/rest/v1/listing_images", token,
         {"listing_id": listing["id"], "storage_path": path, "sort_order": 0})
    call("POST", "/rest/v1/rpc/listing_set_status", token,
         {"p_listing_id": listing["id"], "p_status": "active"})
    print(f"  ok  {title} ({listing['currency']})")
print("Demo listings ready.")

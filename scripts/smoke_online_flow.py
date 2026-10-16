"""Smoke test of the full online Deal flow against LOCAL Supabase.

Listing -> Conversation -> Offer -> accept -> Deal -> online -> mock payment
-> handover code -> completion -> payout -> rating.

Usage (after `npx supabase start` and `npx supabase db reset`):
    python scripts/smoke_online_flow.py
Uses the seeded test accounts (supabase/seed.sql). Never point at production.
"""

import json
import sys
import urllib.error
import urllib.request
import uuid

API = "http://127.0.0.1:54321"
KEY = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"  # local default key
PASSWORD = "VittoTest123!"


def call(method, path, token=None, body=None, prefer=None):
    headers = {"apikey": KEY, "content-type": "application/json"}
    if token:
        headers["authorization"] = f"Bearer {token}"
    if prefer:
        headers["prefer"] = prefer
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req) as res:
            raw = res.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as err:
        sys.exit(f"FAILED {method} {path}: {err.code} {err.read().decode()}")


def login(email):
    res = call("POST", "/auth/v1/token?grant_type=password",
               body={"email": email, "password": PASSWORD})
    return res["access_token"], res["user"]["id"]


def rpc(name, token, **params):
    return call("POST", f"/rest/v1/rpc/{name}", token, params)


def fn(name, token, **body):
    return call("POST", f"/functions/v1/{name}", token, body)["data"]


def step(label, value=""):
    print(f"  ok  {label} {value}")


seller, seller_id = login("ada.ng@vitto.test")
buyer, _ = login("chidi.ng@vitto.test")
admin, _ = login("admin@vitto.test")
step("signed in seller, buyer, admin")

category = call("GET", "/rest/v1/categories?slug=eq.phones-tablets&select=id", seller)[0]["id"]
listing = call("POST", "/rest/v1/listings", seller, {
    "category_id": category, "title": f"Smoke test phone {uuid.uuid4().hex[:6]}",
    "description": "Created by scripts/smoke_online_flow.py", "price_minor": 25000000,
    "negotiable": True, "condition": "used", "country_code": "NG",
    "region_code": "LA", "city": "Lagos"}, prefer="return=representation")[0]
call("POST", "/rest/v1/listing_images", seller, {
    "listing_id": listing["id"], "storage_path": f"{seller_id}/{listing['id']}/placeholder.jpg"})
rpc("listing_set_status", seller, p_listing_id=listing["id"], p_status="active")
step("listing published", listing["currency"])

conv = rpc("start_conversation", buyer, p_listing_id=listing["id"])
offer = rpc("offer_create", buyer, p_conversation_id=conv, p_amount_minor=22000000)
counter = rpc("offer_respond", seller, p_offer_id=offer["id"], p_action="counter",
              p_counter_amount_minor=23500000)["counter_offer"]
deal_id = rpc("offer_respond", buyer, p_offer_id=counter["id"], p_action="accept")["deal_id"]
step("offer -> counter -> accept -> deal", deal_id)

rpc("deal_select_mode", buyer, p_deal_id=deal_id, p_mode="online")
checkout = fn("payment-initialize", buyer, deal_id=deal_id, idempotency_key=str(uuid.uuid4()))
step("checkout initialized", checkout["reference"])
paid = fn("payment-mock-complete", buyer, reference=checkout["reference"], outcome="successful")
assert paid["outcome"] == "deal_paid", paid
deal = call("GET", f"/rest/v1/deals?id=eq.{deal_id}&select=status", buyer)[0]
assert deal["status"] == "paid", deal
payouts = call("GET", f"/rest/v1/payouts?deal_id=eq.{deal_id}", seller)
assert payouts == [], "payout must not exist before handover"
step("payment verified, deal paid, no payout yet")

code = rpc("deal_handover_code", buyer, p_deal_id=deal_id)["code"]
result = rpc("deal_confirm_online", seller, p_deal_id=deal_id, p_code=code)
assert result["ok"] is True, result
step("handover code accepted, deal completed")

payout = fn("payout-request", admin, deal_id=deal_id)
assert payout["status"] == "paid", payout
step("admin released payout (mock)")

rating = rpc("rating_submit", buyer, p_deal_id=deal_id, p_stars=5, p_comment="Smooth deal")
step("buyer rated seller", rating["stars"])
print("SMOKE TEST PASSED")

extends Node

signal purchase_result(message: String)

const CATALOG := [
    {"id":"founder_pack", "name":"Founder Pack", "price":"₹199", "description":"Cosmetic HQ theme and founder badge."},
    {"id":"growth_boost", "name":"Growth Boost", "price":"₹99", "description":"Optional 24-hour revenue multiplier."},
    {"id":"supporter_bundle", "name":"Supporter Bundle", "price":"₹299", "description":"Three district color themes and premium profile frame."}
]

var entitlements: Dictionary = {}
var billing_ready := false

func list_offers() -> Array:
    return CATALOG.duplicate(true)

func offers_summary() -> String:
    var text := "MONETIZATION\nStore-ready offers (billing not connected in this build):\n"
    for offer in CATALOG:
        var owned := "  OWNED" if bool(entitlements.get(offer.id, false)) else ""
        text += "%s  %s  %s%s\n" % [offer.name, offer.price, offer.description, owned]
    text += "\nGoogle Play Billing adapter is required for real purchases."
    return text

func request_purchase(offer_id: String) -> void:
    var offer := _find_offer(offer_id)
    if offer.is_empty():
        purchase_result.emit("Offer unavailable.")
        return
    purchase_result.emit("%s is ready for Google Play Billing, but billing is not connected in this sandbox." % offer.name)

func _find_offer(offer_id: String) -> Dictionary:
    for offer in CATALOG:
        if offer.id == offer_id:
            return offer
    return {}

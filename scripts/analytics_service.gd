extends Node

const PATH := "user://startup_tycoon_analytics.json"
const MAX_EVENTS := 240

var events: Array[Dictionary] = []
var counters: Dictionary = {}
var session_started_unix: int = 0

func _ready() -> void:
    _load_local()
    session_started_unix = int(Time.get_unix_time_from_system())
    track("session_started", {})

func track(event_name: String, payload: Dictionary = {}) -> void:
    events.append({"name":event_name, "time":int(Time.get_unix_time_from_system()), "payload":payload})
    if events.size() > MAX_EVENTS:
        events.pop_front()
    counters[event_name] = int(counters.get(event_name, 0)) + 1
    _flush_local()

func record_day(state: Node) -> void:
    var net: float = float(state.revenue_per_day) - float(state.expenses_per_day)
    track("day_closed", {"day":state.day, "cash":state.cash, "net":net})

func record_building_upgrade(building: Dictionary) -> void:
    track("building_upgraded", {"id":building.get("id", ""), "level":building.get("level", 1)})

func record_offer_viewed(offer_id: String) -> void:
    track("offer_viewed", {"offer_id":offer_id})

func summary(state: Node) -> String:
    var net: float = float(state.revenue_per_day) - float(state.expenses_per_day)
    return "ANALYTICS\nSessions: %d   Events: %d\nDay: %d   Cash: ₹%s\nDaily net: ₹%s\nUpgrades: %d   Offers viewed: %d" % [int(counters.get("session_started", 0)), events.size(), state.day, _money(state.cash), _money(net), int(counters.get("building_upgraded", 0)), int(counters.get("offer_viewed", 0))]

func _money(value: float) -> String:
    if value >= 1000000.0: return "%.1fM" % (value / 1000000.0)
    if value >= 1000.0: return "%.1fK" % (value / 1000.0)
    return str(int(value))

func _flush_local() -> void:
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"version":1, "counters":counters, "events":events}))
        file.close()

func _load_local() -> void:
    if not FileAccess.file_exists(PATH):
        return
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        counters = parsed.get("counters", {})
        events = parsed.get("events", [])

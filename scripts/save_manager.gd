class_name SaveManager
extends RefCounted

const PATH := "user://startup_tycoon_save.json"
const MAX_OFFLINE_SECONDS := 72 * 60 * 60

static func save_game(state: Node) -> bool:
    state.last_saved_unix = int(Time.get_unix_time_from_system())
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(state.to_dict()))
    file.close()
    return true

static func load_game(state: Node) -> String:
    if not FileAccess.file_exists(PATH): return ""
    var file := FileAccess.open(PATH, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        var saved_at := int(parsed.get("last_saved_unix", 0))
        state.from_dict(parsed)
        var now := int(Time.get_unix_time_from_system())
        var elapsed := clampi(now - saved_at, 0, MAX_OFFLINE_SECONDS) if saved_at > 0 else 0
        if elapsed >= 60:
            var hours := float(elapsed) / 3600.0
            var net_per_day: float = float(state.revenue_per_day) - float(state.expenses_per_day)
            var earned: float = net_per_day * hours / 24.0
            state.cash = maxf(0.0, state.cash + earned)
            state.day += int(hours / 24.0)
            state.research = mini(100, state.research + int(hours / 24.0))
            state.offline_summary = "While you were away: +₹%s revenue, %0.1f hours." % [format_money(earned), hours]
            state.notify()
            return state.offline_summary
        return "Game loaded from Day %d." % state.day
    return "Save data could not be read. Starting a fresh city."

static func format_money(amount: float) -> String:
    if amount >= 1000000.0: return "%.1fM" % (amount / 1000000.0)
    if amount >= 1000.0: return "%.1fK" % (amount / 1000.0)
    return str(int(amount))

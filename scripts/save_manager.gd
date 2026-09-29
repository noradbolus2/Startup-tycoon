class_name SaveManager
extends RefCounted

const PATH := "user://startup_tycoon_save.json"

static func save_game(state: Node) -> bool:
    var file := FileAccess.open(PATH, FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(state.to_dict()))
    file.close()
    return true

static func load_game(state: Node) -> bool:
    if not FileAccess.file_exists(PATH): return false
    var file := FileAccess.open(PATH, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        state.from_dict(parsed)
        return true
    return false

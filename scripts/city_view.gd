class_name CityView
extends Node2D

signal building_selected(building: Dictionary)

var state: Node
var camera_offset := Vector2(420, 310)
var zoom := 1.0
var dragging := false
var last_pointer := Vector2.ZERO
var selected_id := ""
var pulse := 0.0

func setup(game_state: Node) -> void:
    state = game_state
    state.state_changed.connect(queue_redraw)
    queue_redraw()

func _process(delta: float) -> void:
    pulse += delta
    queue_redraw()

func iso(tile: Vector2) -> Vector2:
    return camera_offset + Vector2((tile.x - tile.y) * 48.0, (tile.x + tile.y) * 24.0) * zoom

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#07142b"))
    draw_circle(Vector2(240, 120), 190, Color(0.05, 0.17, 0.29, 0.55))
    draw_circle(Vector2(920, 610), 260, Color(0.02, 0.22, 0.29, 0.4))
    for y in range(-7, 8):
        for x in range(-9, 10):
            var p := iso(Vector2(x, y))
            var diamond := PackedVector2Array([p + Vector2(0, -23) * zoom, p + Vector2(48, 0) * zoom, p + Vector2(0, 23) * zoom, p + Vector2(-48, 0) * zoom])
            var land := Color("#173d45") if (x + y) % 3 else Color("#1b4850")
            draw_colored_polygon(diamond, land)
            draw_polyline(diamond, Color(0.25, 0.62, 0.63, 0.22), 1.0)
    draw_river()
    for x in range(-8, 9):
        draw_road(iso(Vector2(x, -7)), iso(Vector2(x, 7)))
    for y in range(-7, 8):
        draw_road(iso(Vector2(-9, y)), iso(Vector2(9, y)))
    for building in state.buildings:
        draw_building(building)
    draw_string(ThemeDB.fallback_font, Vector2(35, 38), "STARTUP VALLEY  •  DAY %02d" % state.day, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8f4ff"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 64), "Drag to explore  •  Pinch / wheel to zoom  •  Tap a building", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#82a9c4"))

func draw_river() -> void:
    var points := PackedVector2Array([Vector2(240, -20), Vector2(310, 160), Vector2(440, 320), Vector2(510, 530), Vector2(690, 760)])
    draw_polyline(points, Color("#126083"), 82.0 * zoom, true)
    draw_polyline(points, Color("#208bb0"), 68.0 * zoom, true)
    for t in range(4):
        var bridge_y := 210.0 + t * 118.0
        draw_line(Vector2(280 + t * 36, bridge_y - 20), Vector2(350 + t * 36, bridge_y + 20), Color("#e38b52"), 8.0 * zoom)

func draw_road(a: Vector2, b: Vector2) -> void:
    draw_line(a, b, Color("#162434"), 9.0 * zoom, true)
    draw_line(a, b, Color("#496174"), 1.5 * zoom, true)

func draw_building(building: Dictionary) -> void:
    var base := iso(building.pos)
    var level: int = int(building.level)
    var h := (22.0 + level * 12.0) * zoom
    var w := (30.0 + level * 3.0) * zoom
    var colors := {"hq":Color("#3dd6ff"), "lab":Color("#bd7cff"), "studio":Color("#43e6a4"), "hub":Color("#ffb55d")}
    var c: Color = colors.get(building.kind, Color("#62c9d5"))
    var shadow := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, 12 * zoom), base + Vector2(w, 0), base + Vector2(0, -12 * zoom)])
    draw_colored_polygon(shadow, Color(0.01, 0.04, 0.08, 0.7))
    var body := PackedVector2Array([base + Vector2(-w * 0.72, -h * 0.1), base + Vector2(0, h * 0.22), base + Vector2(w * 0.72, -h * 0.1), base + Vector2(w * 0.72, -h), base + Vector2(0, -h * 0.68), base + Vector2(-w * 0.72, -h)])
    draw_colored_polygon(body, c.darkened(0.22))
    draw_polyline(PackedVector2Array([base + Vector2(-w * 0.72, -h), base + Vector2(0, -h * 0.68), base + Vector2(w * 0.72, -h)]), c.lightened(0.3), 2.0)
    for row in range(max(1, level + 1)):
        var yy := base.y - h + 12.0 * zoom + row * 13.0 * zoom
        for col in range(3):
            var xx := base.x - 12.0 * zoom + col * 12.0 * zoom
            draw_rect(Rect2(xx, yy, 5.0 * zoom, 4.0 * zoom), Color("#d4f8ff"))
    if building.id == selected_id:
        draw_arc(base + Vector2(0, 5), 34.0 * zoom, 0, TAU, 32, Color("#ffd166"), 3.0)
        draw_string(ThemeDB.fallback_font, base + Vector2(-55, -h - 16), "%s  LV.%d" % [building.name, level], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff1b8"))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed
            last_pointer = event.position
            if not dragging:
                select_at(event.position)
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = clamp(zoom + 0.1, 0.65, 1.6)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = clamp(zoom - 0.1, 0.65, 1.6)
    elif event is InputEventMouseMotion and dragging:
        camera_offset += event.relative
        last_pointer = event.position
    elif event is InputEventScreenTouch:
        if event.pressed: last_pointer = event.position
        else: select_at(event.position)
    elif event is InputEventScreenDrag:
        camera_offset += event.relative
    queue_redraw()

func select_at(point: Vector2) -> void:
    var closest := ""
    var best := 55.0
    for building in state.buildings:
        var distance := point.distance_to(iso(building.pos))
        if distance < best:
            best = distance
            closest = building.id
    selected_id = closest
    for building in state.buildings:
        if building.id == selected_id:
            building_selected.emit(building)
            break
    queue_redraw()

class_name CityView
extends Node2D

signal building_selected(building: Dictionary)

var state: Node
var camera_offset := Vector2(470, 340)
var target_offset := Vector2(470, 340)
var zoom := 0.88
var target_zoom := 0.88
var dragging := false
var selected_id := ""
var pulse := 0.0
var decor_buildings: Array[Dictionary] = []
var parks: Array[Vector2] = []
var trees: Array[Vector2] = []
var cars: Array[Dictionary] = []
var boats: Array[Dictionary] = []
var touches: Dictionary = {}
var last_pinch_distance := 0.0
var touch_start := Vector2.ZERO
var touch_moved := false

const TILE_W := 42.0
const TILE_H := 21.0
const WORLD_X := 13
const WORLD_Y := 11

func setup(game_state: Node) -> void:
    state = game_state
    state.state_changed.connect(queue_redraw)
    build_city_layout()
    queue_redraw()

func build_city_layout() -> void:
    decor_buildings.clear()
    parks.clear()
    trees.clear()
    cars.clear()
    boats.clear()
    var styles := ["startup", "tech", "industrial", "financial", "corporate", "research", "retail"]
    var palette := {
        "startup": [Color("#e98d62"), Color("#ffd4a8")],
        "tech": [Color("#3e98d8"), Color("#8de8f4")],
        "industrial": [Color("#a96555"), Color("#e3a45c")],
        "financial": [Color("#345ca8"), Color("#9bc8e8")],
        "corporate": [Color("#533c9f"), Color("#c6a7ff")],
        "research": [Color("#287c73"), Color("#86f0c8")],
        "retail": [Color("#b94782"), Color("#ffb2d4")]
    }
    for y in range(-WORLD_Y, WORLD_Y + 1):
        for x in range(-WORLD_X, WORLD_X + 1):
            if (x * 7 + y * 11) % 9 == 0 or (abs(x) < 2 and abs(y) < 2):
                continue
            var district := district_for(Vector2(x, y))
            var style: String = styles[district]
            var level := 1 + absi((x * 3 + y * 5) % 4)
            var size := 0.72 + float((x * 5 + y * 3) % 4) * 0.12
            decor_buildings.append({"pos":Vector2(x, y), "style":style, "level":level, "size":size, "colors":palette[style]})
    parks = [Vector2(-9, -4), Vector2(-6, 5), Vector2(6, -5), Vector2(8, 4), Vector2(0, 7)]
    for park in parks:
        for i in range(7):
            trees.append(park + Vector2((i % 3) - 1, (i / 3) - 1))
    for i in range(18):
        cars.append({"lane": i % 4, "progress": fmod(float(i) * 0.071, 1.0), "speed": 0.025 + float(i % 3) * 0.009})
    boats = [{"progress":0.18, "speed":0.012}, {"progress":0.67, "speed":-0.009}]

func district_for(tile: Vector2) -> int:
    if tile.x < -6: return 2
    if tile.x > 7: return 3
    if tile.y < -5: return 5
    if tile.y > 5: return 4
    if tile.x > 2 and tile.y > 1: return 6
    return 1 if tile.x >= -2 else 0

func _process(delta: float) -> void:
    pulse += delta
    camera_offset = camera_offset.lerp(target_offset, minf(1.0, delta * 7.0))
    zoom = lerpf(zoom, target_zoom, minf(1.0, delta * 8.0))
    for car in cars:
        car.progress = fmod(car.progress + delta * car.speed, 1.0)
    for boat in boats:
        boat.progress = fmod(boat.progress + delta * boat.speed + 1.0, 1.0)
    queue_redraw()

func iso(tile: Vector2) -> Vector2:
    return camera_offset + Vector2((tile.x - tile.y) * TILE_W, (tile.x + tile.y) * TILE_H) * zoom

func _draw() -> void:
    var viewport := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, viewport), Color("#07152a"))
    draw_gradient_sky(viewport)
    draw_city_terrain()
    draw_river()
    draw_roads()
    draw_parks()
    draw_decor_buildings()
    draw_state_buildings()
    draw_city_life()
    draw_district_labels()
    draw_string(ThemeDB.fallback_font, Vector2(178, 38), "STARTUP VALLEY  •  DAY %02d" % state.day, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e7f8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(178, 61), "A living business city  •  drag to explore  •  wheel / pinch to zoom", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fb5c8"))

func draw_gradient_sky(viewport: Vector2) -> void:
    for i in range(12):
        var t := float(i) / 11.0
        draw_rect(Rect2(0, i * viewport.y / 12.0, viewport.x, viewport.y / 12.0 + 1), Color("#0b2140").lerp(Color("#163c54"), t * 0.65))
    draw_circle(Vector2(840, 114), 62.0, Color(1.0, 0.72, 0.34, 0.16))
    draw_circle(Vector2(840, 114), 35.0, Color("#ffc978"))
    for i in range(8):
        draw_circle(Vector2(190 + i * 110, 126 + (i % 3) * 14), 17 + (i % 3) * 6, Color(0.82, 0.93, 0.95, 0.08))

func draw_city_terrain() -> void:
    for y in range(-WORLD_Y, WORLD_Y + 1):
        for x in range(-WORLD_X, WORLD_X + 1):
            var p := iso(Vector2(x, y))
            var diamond := PackedVector2Array([p + Vector2(0, -TILE_H) * zoom, p + Vector2(TILE_W, 0) * zoom, p + Vector2(0, TILE_H) * zoom, p + Vector2(-TILE_W, 0) * zoom])
            var district := district_for(Vector2(x, y))
            var land_colors := [Color("#21504b"), Color("#1e5357"), Color("#574d43"), Color("#293f61"), Color("#3b315b"), Color("#245957"), Color("#664358")]
            draw_colored_polygon(diamond, land_colors[district])
            draw_polyline(diamond, Color(0.55, 0.83, 0.79, 0.12), 0.8)

func draw_river() -> void:
    var points := PackedVector2Array([iso(Vector2(-12, -10)) + Vector2(-20, -5), iso(Vector2(-8, -5)) + Vector2(-14, -4), iso(Vector2(-3, -1)) + Vector2(-8, -1), iso(Vector2(2, 4)) + Vector2(12, 0), iso(Vector2(8, 10)) + Vector2(32, 9)])
    draw_polyline(points, Color(0.02, 0.08, 0.14, 0.65), 66.0 * zoom, true)
    draw_polyline(points, Color("#146080"), 53.0 * zoom, true)
    draw_polyline(points, Color("#258eaa"), 43.0 * zoom, true)
    for i in range(12):
        var p := points[i % points.size()].lerp(points[(i + 1) % points.size()], 0.35) + Vector2(i * 19.0, (i % 2) * 7.0)
        draw_line(p, p + Vector2(12, 2), Color(0.64, 0.93, 0.96, 0.42), 1.5)
    for t in range(3):
        var bridge_center := iso(Vector2(-4 + t * 5, -2 + t * 4))
        draw_line(bridge_center + Vector2(-52, -18) * zoom, bridge_center + Vector2(52, 18) * zoom, Color("#152332"), 12.0 * zoom)
        draw_line(bridge_center + Vector2(-46, -16) * zoom, bridge_center + Vector2(46, 16) * zoom, Color("#d98252"), 5.0 * zoom)
        for rail in range(5):
            var r := bridge_center + Vector2(-32 + rail * 16, -11 + rail * 6) * zoom
            draw_line(r, r + Vector2(0, -11) * zoom, Color("#f1c17a"), 1.5 * zoom)
    for boat in boats:
        var bp := points[1].lerp(points[3], boat.progress)
        draw_colored_polygon(PackedVector2Array([bp + Vector2(-9, 0), bp + Vector2(10, 0), bp + Vector2(4, 5), bp + Vector2(-5, 5)]), Color("#fff0c2"))
        draw_line(bp + Vector2(0, 0), bp + Vector2(0, -14), Color("#d9e8ea"), 1.5)

func draw_roads() -> void:
    for x in range(-WORLD_X + 1, WORLD_X):
        var a := iso(Vector2(x, -WORLD_Y))
        var b := iso(Vector2(x, WORLD_Y))
        draw_road_segment(a, b, x % 4 == 0)
    for y in range(-WORLD_Y + 1, WORLD_Y):
        var a := iso(Vector2(-WORLD_X, y))
        var b := iso(Vector2(WORLD_X, y))
        draw_road_segment(a, b, y % 4 == 0)
    for p in [iso(Vector2(-5, -5)), iso(Vector2(4, 3)), iso(Vector2(-8, 5)), iso(Vector2(7, -2))]:
        draw_circle(p, 15.0 * zoom, Color(0.88, 0.8, 0.48, 0.18))
        draw_arc(p, 15.0 * zoom, 0, TAU, 20, Color("#e5bd69"), 1.0)

func draw_road_segment(a: Vector2, b: Vector2, main_road: bool) -> void:
    var width := 11.0 if main_road else 7.0
    draw_line(a, b, Color("#0d1725"), (width + 7.0) * zoom, true)
    draw_line(a, b, Color("#354657"), width * zoom, true)
    draw_line(a, b, Color("#778b91"), 1.0 * zoom, true)
    if main_road:
        var steps := int(a.distance_to(b) / 34.0)
        for i in range(steps):
            var p := a.lerp(b, float(i) / maxf(1.0, steps))
            draw_line(p, p + (b - a).normalized() * 10.0, Color(1.0, 0.83, 0.38, 0.75), 1.5 * zoom)
    for side in [-1.0, 1.0]:
        var normal: Vector2 = (b - a).normalized().rotated(PI / 2.0) * side * (width * 0.75) * zoom
        draw_line(a + normal, b + normal, Color(0.62, 0.67, 0.63, 0.45), 2.0 * zoom)

func draw_parks() -> void:
    for park in parks:
        var center := iso(park)
        draw_circle(center, 26.0 * zoom, Color("#1e684d"))
        draw_circle(center, 19.0 * zoom, Color("#2f8856"))
        for i in range(4):
            var path := center + Vector2(cos(i * PI / 2.0), sin(i * PI / 2.0)) * 20.0 * zoom
            draw_line(center, path, Color(0.84, 0.74, 0.49, 0.6), 2.0 * zoom)
        draw_circle(center, 4.0 * zoom, Color("#c7df97"))
    for tree in trees:
        var p := iso(tree)
        draw_line(p + Vector2(0, 5) * zoom, p + Vector2(0, -7) * zoom, Color("#654832"), 2.0 * zoom)
        draw_circle(p + Vector2(0, -10) * zoom, 7.0 * zoom, Color("#2c9c5b"))
        draw_circle(p + Vector2(-3, -13) * zoom, 4.0 * zoom, Color("#63ca78"))

func draw_decor_buildings() -> void:
    for building in decor_buildings:
        draw_procedural_building(iso(building.pos), int(building.level), float(building.size), building.style, building.colors)

func draw_state_buildings() -> void:
    for building in state.buildings:
        var style := "corporate" if building.kind == "hq" else ("research" if building.kind == "lab" else ("retail" if building.kind == "studio" else "industrial"))
        var colors := [Color("#e8b55d"), Color("#c9f3ff")] if building.kind == "hq" else [Color("#5cd4e8"), Color("#e6fdff")]
        draw_procedural_building(iso(building.pos), int(building.level) + 1, 1.18, style, colors)
        if building.id == selected_id:
            var bp := iso(building.pos)
            draw_arc(bp + Vector2(0, 7), 37.0 * zoom, 0, TAU, 40, Color("#ffd166"), 3.0)
            draw_string(ThemeDB.fallback_font, bp + Vector2(-68, -90) * zoom, "%s  •  LV.%d" % [building.name, building.level], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff1b8"))

func draw_procedural_building(base: Vector2, level: int, size: float, style: String, colors: Array) -> void:
    var h := (24.0 + level * 15.0) * size * zoom
    var w := (25.0 + minf(level, 7) * 2.5) * size * zoom
    var c: Color = colors[0]
    var glass: Color = colors[1]
    var footprint := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, 12 * zoom), base + Vector2(w, 0), base + Vector2(0, -12 * zoom)])
    draw_colored_polygon(footprint, Color(0.02, 0.06, 0.1, 0.55))
    var left := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, 12 * zoom), base + Vector2(0, -h + 12 * zoom), base + Vector2(-w * 0.84, -h)])
    var right := PackedVector2Array([base + Vector2(0, 12 * zoom), base + Vector2(w, 0), base + Vector2(w * 0.84, -h), base + Vector2(0, -h + 12 * zoom)])
    draw_colored_polygon(left, c.darkened(0.25))
    draw_colored_polygon(right, c.darkened(0.05))
    var roof := PackedVector2Array([base + Vector2(-w * 0.84, -h), base + Vector2(0, -h + 12 * zoom), base + Vector2(w * 0.84, -h), base + Vector2(0, -h - 12 * zoom)])
    draw_colored_polygon(roof, c.lightened(0.2))
    var window_rows := clampi(level + 1, 2, 10)
    var window_cols := clampi(int(w / (7.0 * zoom)), 2, 6)
    for row in range(window_rows):
        var y := base.y - h + (row + 1) * h / float(window_rows + 1)
        for col in range(window_cols):
            var x := base.x - (window_cols - 1) * 4.0 * zoom + col * 8.0 * zoom
            var glow := Color("#fff2a8") if int(pulse * 2.0 + row + col) % 7 == 0 else glass
            draw_rect(Rect2(x, y, 4.0 * zoom, 5.0 * zoom), glow)
    if style == "tech" or style == "research":
        draw_line(base + Vector2(0, -h), base + Vector2(0, -h - 17.0 * zoom), Color("#9deeff"), 2.0 * zoom)
        draw_circle(base + Vector2(0, -h - 18.0 * zoom), 3.0 * zoom, Color("#7ff4ff"))
    elif style == "industrial":
        for i in range(2):
            draw_circle(base + Vector2(-w * 0.45 + i * 12.0, -h * 0.45), 6.0 * zoom, Color("#b8c2c3"))
            draw_line(base + Vector2(-w * 0.45 + i * 12.0, -h * 0.45 - 5), base + Vector2(-w * 0.45 + i * 12.0, -h * 0.45 - 16), Color(0.8, 0.86, 0.83, 0.42), 3.0 * zoom)
    elif style == "retail":
        draw_line(base + Vector2(-w * 0.7, -h * 0.26), base + Vector2(w * 0.7, -h * 0.26), Color("#ffdb72"), 3.0 * zoom)
    elif style == "financial" or style == "corporate":
        draw_line(base + Vector2(-w * 0.72, -h * 0.84), base + Vector2(w * 0.72, -h * 0.84), Color(0.9, 0.95, 1.0, 0.5), 2.0 * zoom)

func draw_city_life() -> void:
    for car in cars:
        var lane := int(car.lane)
        var p: Vector2
        if lane < 2:
            p = iso(Vector2(-WORLD_X + car.progress * WORLD_X * 2.0, -4 + lane * 8))
        else:
            p = iso(Vector2(-7 + (lane - 2) * 10, -WORLD_Y + car.progress * WORLD_Y * 2.0))
        draw_rect(Rect2(p - Vector2(3, 2) * zoom, Vector2(7, 4) * zoom), Color("#f6d36d"))
        draw_circle(p + Vector2(4, 0) * zoom, 1.4 * zoom, Color("#ff684f"))
    var construction := iso(Vector2(-5, 2))
    draw_rect(Rect2(construction + Vector2(-18, -10) * zoom, Vector2(36, 9) * zoom), Color("#e29a42"))
    draw_line(construction + Vector2(0, -10) * zoom, construction + Vector2(0, -42) * zoom, Color("#d9a65e"), 2.0 * zoom)
    draw_line(construction + Vector2(0, -38) * zoom, construction + Vector2(20, -28) * zoom, Color("#d9a65e"), 2.0 * zoom)
    draw_circle(construction + Vector2(0, -45) * zoom, 3.0 * zoom, Color("#ffc85a"))

func draw_district_labels() -> void:
    var labels := [
        ["STARTUP DISTRICT", Vector2(-9, -7), Color("#ffc88a")],
        ["TECH PARK", Vector2(-1, -8), Color("#8fe9ff")],
        ["INDUSTRIAL ZONE", Vector2(-10, 8), Color("#ffb777")],
        ["FINANCIAL DISTRICT", Vector2(8, -6), Color("#c1d4ff")],
        ["CORPORATE CITY", Vector2(7, 5), Color("#d7b6ff")]
    ]
    for item in labels:
        var p := iso(item[1])
        draw_string(ThemeDB.fallback_font, p, item[0], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, item[2])

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragging = true
            else:
                dragging = false
                select_at(event.position)
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            target_zoom = clampf(target_zoom + 0.1, 0.58, 1.65)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            target_zoom = clampf(target_zoom - 0.1, 0.58, 1.65)
    elif event is InputEventMouseMotion and dragging:
        target_offset += event.relative
        target_offset.x = clampf(target_offset.x, 250.0, 720.0)
        target_offset.y = clampf(target_offset.y, 180.0, 500.0)
    elif event is InputEventScreenTouch:
        if event.pressed:
            touches[event.index] = event.position
            if touches.size() == 1:
                touch_start = event.position
                touch_moved = false
        else:
            touches.erase(event.index)
            if touches.is_empty():
                if not touch_moved and event.position.distance_to(touch_start) < 24.0:
                    select_at(event.position)
                last_pinch_distance = 0.0
    elif event is InputEventScreenDrag:
        touches[event.index] = event.position
        if touches.size() == 1:
            if event.position.distance_to(touch_start) > 14.0: touch_moved = true
            target_offset += event.relative
        elif touches.size() >= 2:
            touch_moved = true
            var points := touches.values()
            var distance: float = points[0].distance_to(points[1])
            if last_pinch_distance > 0.0:
                target_zoom = clampf(target_zoom + (distance - last_pinch_distance) * 0.002, 0.58, 1.65)
            last_pinch_distance = distance
    queue_redraw()

func select_at(point: Vector2) -> void:
    var closest := ""
    var best := 58.0
    for building in state.buildings:
        var distance: float = point.distance_to(iso(building.pos))
        if distance < best:
            best = distance
            closest = building.id
    selected_id = closest
    for building in state.buildings:
        if building.id == selected_id:
            building_selected.emit(building)
            break
    queue_redraw()

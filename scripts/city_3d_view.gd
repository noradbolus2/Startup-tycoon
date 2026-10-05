class_name City3DView
extends Node3D

signal building_selected(building: Dictionary)

var state: Node
var camera: Camera3D
var world_root: Node3D
var building_nodes: Dictionary = {}
var vehicles: Array[Node3D] = []
var camera_target := Vector3(0.0, 0.0, 0.0)
var camera_distance := 31.0
var camera_yaw := 42.0
var camera_pitch := -48.0
var dragging := false
var drag_start := Vector2.ZERO
var selected_id := ""

const GRID := 4.0
const CITY_RADIUS := 11
const WATER_Z := 3.5

func setup(game_state: Node) -> void:
    state = game_state
    state.state_changed.connect(_on_state_changed)
    _build_world()

func _ready() -> void:
    if state == null:
        return

func _build_world() -> void:
    world_root = Node3D.new()
    world_root.name = "GeneratedBusinessCity"
    add_child(world_root)
    _create_environment()
    _create_terrain()
    _create_roads()
    _create_water_and_bridge()
    _create_district_landmarks()
    _create_decor_buildings()
    _create_state_buildings()
    _create_city_life()
    _create_camera()

func _create_environment() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#071a31")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#9fc9e5")
    env.ambient_light_energy = 0.75
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.name = "CitySun"
    sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
    sun.light_color = Color("#ffe4b0")
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)

func _create_camera() -> void:
    camera = Camera3D.new()
    camera.name = "IsometricCamera"
    camera.current = true
    camera.fov = 48.0
    add_child(camera)
    _update_camera()

func _update_camera() -> void:
    if camera == null:
        return
    var yaw := deg_to_rad(camera_yaw)
    var pitch := deg_to_rad(camera_pitch)
    var offset := Vector3(cos(yaw) * cos(pitch), -sin(pitch), sin(yaw) * cos(pitch)) * camera_distance
    camera.position = camera_target + offset
    camera.look_at(camera_target, Vector3.UP)

func _create_terrain() -> void:
    _add_box("Terrain", Vector3(52.0, 0.5, 52.0), Vector3(0.0, -0.35, 0.0), Color("#285c53"), world_root)
    for x in range(-CITY_RADIUS, CITY_RADIUS + 1):
        for z in range(-CITY_RADIUS, CITY_RADIUS + 1):
            if (x * 7 + z * 11) % 9 == 0:
                _create_tree(Vector3(x * GRID, 0.0, z * GRID), 0.8)

func _create_roads() -> void:
    for axis in [-1, 1]:
        for lane in range(-CITY_RADIUS, CITY_RADIUS + 1, 4):
            if axis == -1:
                _add_box("RoadX", Vector3(48.0, 0.08, 1.25), Vector3(0.0, 0.04, lane * GRID), Color("#273746"), world_root)
            else:
                _add_box("RoadZ", Vector3(1.25, 0.08, 48.0), Vector3(lane * GRID, 0.045, 0.0), Color("#273746"), world_root)
    for x in range(-CITY_RADIUS, CITY_RADIUS + 1, 4):
        for z in range(-CITY_RADIUS, CITY_RADIUS + 1, 4):
            _add_box("Intersection", Vector3(2.8, 0.09, 2.8), Vector3(x * GRID, 0.07, z * GRID), Color("#344d59"), world_root)
            _create_streetlight(Vector3(x * GRID + 1.0, 0.0, z * GRID + 1.0))

func _create_water_and_bridge() -> void:
    _add_box("River", Vector3(8.0, 0.12, 52.0), Vector3(WATER_Z * GRID, 0.12, 0.0), Color("#197da0"), world_root)
    for z in [-12.0, 4.0, 20.0]:
        _add_box("Bridge", Vector3(11.0, 0.5, 3.0), Vector3(WATER_Z * GRID, 0.35, z), Color("#a65f48"), world_root)
        for side in [-1.0, 1.0]:
            _add_box("BridgeRail", Vector3(10.0, 0.22, 0.18), Vector3(WATER_Z * GRID, 1.0, z + side * 1.2), Color("#e6b36b"), world_root)

func _create_district_landmarks() -> void:
    var landmarks := [
        {"name":"Tech Tower", "pos":Vector3(-28.0, 0.0, -26.0), "height":11.0, "color":Color("#35a8d8")},
        {"name":"Financial Spire", "pos":Vector3(28.0, 0.0, -22.0), "height":14.0, "color":Color("#556fc5")},
        {"name":"Research Campus", "pos":Vector3(-28.0, 0.0, 24.0), "height":8.0, "color":Color("#2d9d84")},
        {"name":"Corporate Tower", "pos":Vector3(28.0, 0.0, 24.0), "height":17.0, "color":Color("#7356c7")}
    ]
    for landmark in landmarks:
        _create_building_mesh(landmark.name, landmark.pos, landmark.height, 3.2, landmark.color, Color("#c9f5ff"), world_root)

func _create_decor_buildings() -> void:
    var styles := [Color("#d17863"), Color("#3e98d8"), Color("#a96555"), Color("#345ca8"), Color("#533c9f"), Color("#287c73"), Color("#b94782")]
    for z in range(-CITY_RADIUS, CITY_RADIUS + 1):
        for x in range(-CITY_RADIUS, CITY_RADIUS + 1):
            if (x * 7 + z * 11) % 5 != 0 or (abs(x) < 2 and abs(z) < 2):
                continue
            var height := 2.0 + float(absi((x * 3 + z * 5) % 6)) * 1.15
            var style: Color = styles[absi(x + z * 2) % styles.size()]
            _create_building_mesh("DistrictBuilding", Vector3(x * GRID, 0.0, z * GRID), height, 1.25, style, Color("#d8f5ff"), world_root)

func _create_state_buildings() -> void:
    for building in state.buildings:
        var pos: Vector2 = building.pos
        var style := Color("#e8b55d") if building.kind == "hq" else (Color("#5cd4e8") if building.kind == "lab" else Color("#d47c9e"))
        var level := int(building.level)
        var height := 3.0 + level * 1.8
        var node := _create_building_mesh(building.name, Vector3(pos.x * GRID, 0.0, pos.y * GRID), height, 1.8 + level * 0.12, style, Color("#e9fbff"), world_root)
        node.set_meta("building_id", building.id)
        node.set_meta("building_data", building)
        building_nodes[building.id] = node
        _add_building_collision(node, Vector3(1.8 + level * 0.12, height, 1.8 + level * 0.12), building)

func _create_city_life() -> void:
    for i in range(12):
        var vehicle := _add_box("Vehicle", Vector3(0.65, 0.28, 1.25), Vector3(-22.0 + i * 4.0, 0.35, -12.0), Color("#f4c95d") if i % 2 == 0 else Color("#66c7e6"), world_root)
        vehicles.append(vehicle)

func _create_building_mesh(label: String, position: Vector3, height: float, footprint: float, color: Color, glass: Color, parent: Node3D) -> Node3D:
    var root := Node3D.new()
    root.name = label
    root.position = position
    parent.add_child(root)
    var body := _add_box("Structure", Vector3(footprint, height, footprint), Vector3(0.0, height * 0.5, 0.0), color, root)
    var roof := _add_box("Rooftop", Vector3(footprint * 1.08, 0.22, footprint * 1.08), Vector3(0.0, height + 0.12, 0.0), color.lightened(0.22), root)
    for floor in range(maxi(2, int(height / 1.7))):
        var y := 0.8 + floor * 1.5
        _add_box("WindowBand", Vector3(footprint * 1.01, 0.34, 0.06), Vector3(0.0, y, footprint * 0.51), glass, root)
        _add_box("WindowBand", Vector3(footprint * 1.01, 0.34, 0.06), Vector3(0.0, y, -footprint * 0.51), glass, root)
    _add_box("Entrance", Vector3(0.5, 0.8, 0.08), Vector3(0.0, 0.4, footprint * 0.53), Color("#172a3d"), root)
    return root

func _add_building_collision(node: Node3D, size: Vector3, building: Dictionary) -> void:
    var body := StaticBody3D.new()
    body.position = Vector3(0.0, size.y * 0.5, 0.0)
    body.set_meta("building_id", building.id)
    body.set_meta("building_data", building)
    node.add_child(body)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)

func _add_box(label: String, size: Vector3, position: Vector3, color: Color, parent: Node3D) -> Node3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color)
    parent.add_child(mesh_instance)
    return mesh_instance

func _create_tree(position: Vector3, scale_value: float) -> void:
    var trunk := _add_box("TreeTrunk", Vector3(0.24, 1.0, 0.24), position + Vector3(0.0, 0.5, 0.0), Color("#694735"), world_root)
    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.0 * scale_value
    sphere.height = 2.0 * scale_value
    crown.mesh = sphere
    crown.position = position + Vector3(0.0, 1.8 * scale_value, 0.0)
    crown.material_override = _material(Color("#3fa861"))
    world_root.add_child(crown)

func _create_streetlight(position: Vector3) -> void:
    _add_box("LampPole", Vector3(0.08, 1.8, 0.08), position + Vector3(0.0, 0.9, 0.0), Color("#a9bdc7"), world_root)
    _add_box("Lamp", Vector3(0.32, 0.08, 0.32), position + Vector3(0.0, 1.85, 0.0), Color("#ffe89c"), world_root)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.72
    return material

func _on_state_changed() -> void:
    for node in building_nodes.values():
        node.queue_free()
    building_nodes.clear()
    await get_tree().process_frame
    _create_state_buildings()

func _process(delta: float) -> void:
    for i in range(vehicles.size()):
        var vehicle := vehicles[i]
        vehicle.position.x += delta * (1.2 + (i % 3) * 0.35)
        if vehicle.position.x > 28.0:
            vehicle.position.x = -28.0
    if camera:
        _update_camera()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed
            drag_start = event.position
            if not dragging and event.position.distance_to(drag_start) < 14.0:
                _select_at(event.position)
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = clampf(camera_distance - 2.0, 16.0, 48.0)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = clampf(camera_distance + 2.0, 16.0, 48.0)
    elif event is InputEventMouseMotion and dragging:
        camera_yaw -= event.relative.x * 0.22
        camera_target.x = clampf(camera_target.x - event.relative.x * 0.03, -14.0, 14.0)
        camera_target.z = clampf(camera_target.z - event.relative.y * 0.03, -14.0, 14.0)
    elif event is InputEventScreenTouch and not event.pressed:
        _select_at(event.position)
    elif event is InputEventScreenDrag:
        camera_target.x = clampf(camera_target.x - event.relative.x * 0.025, -14.0, 14.0)
        camera_target.z = clampf(camera_target.z - event.relative.y * 0.025, -14.0, 14.0)

func _select_at(screen_position: Vector2) -> void:
    if camera == null:
        return
    var origin := camera.project_ray_origin(screen_position)
    var direction := camera.project_ray_normal(screen_position)
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var collider: Object = hit.get("collider")
    if collider and collider.has_meta("building_id"):
        selected_id = str(collider.get_meta("building_id"))
        for building in state.buildings:
            if building.id == selected_id:
                building_selected.emit(building)
                break

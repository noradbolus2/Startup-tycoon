extends Node

signal profile_changed(profile_name: String)

var profile := "medium"
var sample_seconds := 0.0
var frames := 0
var frame_time_total := 0.0
var last_fps := 0.0
var average_frame_ms := 0.0
var draw_calls := 0
var object_count := 0
var ssao_enabled := true
var adaptive_quality := true
var below_target_samples := 0
var above_target_samples := 0
var active_environment: Environment
var active_sun: DirectionalLight3D

func _ready() -> void:
    Engine.max_fps = 60

func _process(delta: float) -> void:
    frames += 1
    frame_time_total += delta
    sample_seconds += delta
    if sample_seconds < 2.0:
        return
    average_frame_ms = (frame_time_total / maxf(1.0, float(frames))) * 1000.0
    last_fps = Engine.get_frames_per_second()
    draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    object_count = int(Performance.get_monitor(Performance.OBJECT_COUNT))
    sample_seconds = 0.0
    frames = 0
    frame_time_total = 0.0
    _adapt_quality()

func configure_environment(environment: Environment, sun: DirectionalLight3D) -> void:
    active_environment = environment
    active_sun = sun
    var requested := str(ProjectSettings.get_setting("startup_tycoon/visual_profile", "medium"))
    profile = requested if requested in ["low", "medium", "high"] else "medium"
    _apply_profile()

func set_profile(profile_name: String) -> void:
    if profile_name not in ["low", "medium", "high"]:
        return
    profile = profile_name
    _apply_profile()
    profile_changed.emit(profile)

func _adapt_quality() -> void:
    if not adaptive_quality or last_fps <= 1.0:
        return
    if last_fps < 45.0:
        below_target_samples += 1
        above_target_samples = 0
    elif last_fps > 56.0:
        above_target_samples += 1
        below_target_samples = 0
    else:
        below_target_samples = 0
        above_target_samples = 0
    if below_target_samples >= 2 and profile != "low":
        set_profile("low")
        below_target_samples = 0
    elif above_target_samples >= 4 and profile == "low":
        set_profile("medium")
        above_target_samples = 0

func _apply_profile() -> void:
    if active_environment == null or active_sun == null:
        return
    if profile == "low":
        active_environment.ssao_enabled = false
        ssao_enabled = false
        active_sun.shadow_enabled = false
        active_sun.light_energy = 1.1
    elif profile == "high":
        active_environment.ssao_enabled = true
        active_environment.ssao_radius = 2.4
        active_environment.ssao_intensity = 2.0
        active_environment.ssao_power = 1.35
        ssao_enabled = true
        active_sun.shadow_enabled = true
        active_sun.directional_shadow_max_distance = 70.0
        active_sun.shadow_bias = 0.035
        active_sun.shadow_normal_bias = 1.0
    else:
        active_environment.ssao_enabled = true
        active_environment.ssao_radius = 1.6
        active_environment.ssao_intensity = 1.25
        active_environment.ssao_power = 1.1
        ssao_enabled = true
        active_sun.shadow_enabled = true
        active_sun.directional_shadow_max_distance = 52.0
        active_sun.shadow_bias = 0.05
        active_sun.shadow_normal_bias = 1.2

func diagnostics() -> String:
    var fps_text := "--" if last_fps <= 0.0 else "%.0f" % last_fps
    return "PERFORMANCE\nProfile: %s   Target: 60 FPS\nSSAO: %s   Adaptive: %s\nFPS sample: %s   Frame: %.1f ms\nDraw calls: %d   Objects: %d" % [profile.to_upper(), "ON" if ssao_enabled else "OFF", "ON" if adaptive_quality else "OFF", fps_text, average_frame_ms, draw_calls, object_count]

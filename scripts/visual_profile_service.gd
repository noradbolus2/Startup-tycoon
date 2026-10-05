extends Node

var profile := "medium"
var sample_seconds := 0.0
var frames := 0
var frame_time_total := 0.0
var last_fps := 0.0
var average_frame_ms := 0.0
var ssao_enabled := true

func _process(delta: float) -> void:
    frames += 1
    frame_time_total += delta
    sample_seconds += delta
    if sample_seconds >= 2.0:
        average_frame_ms = (frame_time_total / maxf(1.0, float(frames))) * 1000.0
        last_fps = Engine.get_frames_per_second()
        sample_seconds = 0.0
        frames = 0
        frame_time_total = 0.0

func configure_environment(environment: Environment, sun: DirectionalLight3D) -> void:
    var requested := str(ProjectSettings.get_setting("startup_tycoon/visual_profile", "medium"))
    profile = requested if requested in ["low", "medium", "high"] else "medium"
    if profile == "low":
        environment.ssao_enabled = false
        ssao_enabled = false
        sun.shadow_enabled = false
        sun.light_energy = 1.1
    elif profile == "high":
        environment.ssao_enabled = true
        environment.ssao_radius = 2.4
        environment.ssao_intensity = 2.0
        environment.ssao_power = 1.35
        ssao_enabled = true
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 70.0
        sun.shadow_bias = 0.035
        sun.shadow_normal_bias = 1.0
    else:
        environment.ssao_enabled = true
        environment.ssao_radius = 1.6
        environment.ssao_intensity = 1.25
        environment.ssao_power = 1.1
        ssao_enabled = true
        sun.shadow_enabled = true
        sun.directional_shadow_max_distance = 52.0
        sun.shadow_bias = 0.05
        sun.shadow_normal_bias = 1.2

func diagnostics() -> String:
    var fps_text := "--" if last_fps <= 0.0 else "%.0f" % last_fps
    return "VISUAL PROFILE: %s\nSSAO: %s\nFPS sample: %s\nFrame time: %.1f ms" % [profile.to_upper(), "ON" if ssao_enabled else "OFF", fps_text, average_frame_ms]

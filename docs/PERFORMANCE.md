# Android Performance — v0.5.0

## Target

The runtime targets a capped **60 FPS** on modern mid-range Android devices and a stable fallback profile on lower-end devices. The project setting and runtime service both enforce a 60 FPS ceiling so frame pacing is measurable rather than unlimited.

## Implemented optimizations

- Adaptive visual profile service with `low`, `medium` and `high` profiles.
- Automatic fallback to the low profile after repeated sub-45 FPS samples.
- Automatic return from low to medium after sustained samples above 56 FPS.
- SSAO and directional shadows disabled in low profile.
- Reduced shadow distance and tuned bias in medium profile.
- Extended shadows and stronger AO reserved for high profile.
- City vehicles update at a bounded 20 Hz simulation step instead of doing unnecessary work every render frame.
- Lower object counts for vehicles, streetlights and trees in low profile.
- Landmark local lights have shadows disabled; the single directional sun owns the main shadow map.
- Render diagnostics expose FPS sample, average frame time, draw calls and object count.
- Android release is ARM64 and uses the existing Godot native export path.

## Diagnostics

The in-game **VISUAL DIAGNOSTICS** action reports the active profile, target, SSAO state, adaptive state, FPS sample, average frame time, draw-call count and object count. These values should be recorded on physical test devices at city zoom, close-up landmark zoom and while vehicles are active.

## Test protocol

1. Install the release APK on a mid-range Android device.
2. Start a new city and record a 60-second baseline.
3. Pan across the complete city at default zoom.
4. Zoom into the largest landmark and rotate/pan for 30 seconds.
5. Advance several days and repeat while vehicles are moving.
6. Record diagnostics after each run.
7. Confirm that the adaptive profile does not oscillate continuously.

## Honest limitation

The current execution sandbox has no connected Android device or emulator, so a physical-device FPS number cannot be claimed here. The source contains the target, adaptive fallback and diagnostics needed for the next device test; the v0.5.0 APK is build-verified but not device-benchmark-certified.

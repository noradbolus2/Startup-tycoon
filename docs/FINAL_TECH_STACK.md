# Startup Tycoon — Final Technical Stack

**Status:** Locked for the current production line  
**Engine:** Godot 4.7.x  
**Language:** GDScript  
**Target:** Native Android mobile game

## Runtime stack

Startup Tycoon uses Godot 4.7.x with a procedural isometric/2.5D city renderer. The game is a native Godot application; it does not use Expo, React Native, WebView, HTML or browser packaging.

The current playable loop is intentionally modular:

- `main.gd` is the composition root and contextual UI coordinator.
- `city_view.gd` renders the procedural business city and handles camera, selection and touch/mouse input.
- `game_state.gd` owns persistent runtime state and day progression.
- `economy_engine.gd` owns revenue, expenses and upgrade formulas.
- `save_manager.gd` owns versioned JSON persistence in Godot user storage.

## Rendering direction

The visual target is a dense, colorful, readable isometric business city inspired only by the supplied high-level reference. The implementation uses original procedural geometry and styling rather than copied artwork.

Future city improvements should remain mobile-safe: aggregated procedural geometry, bounded object counts, reusable building generators, district palettes, lightweight animation, limited overdraw and explicit low/medium/high quality settings.

## Input and camera

The camera supports touch and mouse interaction, including pan, pinch-style zoom and building selection. Android touch behavior remains the primary input path; mouse input is retained for desktop testing.

## Simulation architecture

The simulation is separated from rendering so economy and progression can evolve without turning the renderer into a monolith. Planned systems remain separate modules for companies, employees, products, market conditions, research, finance, logistics, competitors, events and offline progression.

Static configuration may be represented as typed data resources as the project grows. Runtime player state remains serializable and independent of scene presentation.

## Save architecture

Player state is persisted as local JSON in Godot's user data directory. Save changes should remain versioned, tolerate missing fields and be migrated through explicit loaders when the schema changes. Autosave should occur on meaningful transitions and application pause/quit.

## Android build pipeline

The native Android preset is the supported release path. The verified environment uses:

- Godot 4.7.2 stable editor.
- Android SDK platform-tools and build-tools.
- OpenJDK 21 available in the sandbox.
- Godot Android export templates.
- ARM64-compatible Android export settings.
- Release signing configuration kept outside source control.

The project should produce development and release APKs. AAB export can be added when store delivery is required.

## Quality and performance

Android-first quality tiers should target stable 60 FPS on modern supported devices and stable 30 FPS on lower-end devices. Profiling takes priority over assumptions. Future optimizations include reducing draw work, bounded procedural generation, pooling repeated effects and vehicles, compact textures, and avoiding unnecessary per-frame simulation.

## Version control

The authoritative production line is `main` in `noradbolus2/Startup-tycoon`. The `pre-unity-migration` branch preserves the preceding visual milestone, while `unity-migration` records the abandoned Unity evaluation and is not the production stack.

## Honest scope

This stack is selected because it is installed, buildable and already contains a playable Android-oriented vertical slice. The project is not yet a finished commercial 3D game: authored 3D asset coverage, advanced simulation depth, living-city activity and final store polish remain future work.

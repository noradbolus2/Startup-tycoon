# Startup Tycoon Architecture

## Decision
The repository was empty apart from a README. The project uses **Godot 4.7 + GDScript** with native Android export as the target runtime. Godot was selected because it provides a mobile-ready 2D/2.5D rendering loop, touch input, input scaling, and reproducible Android export without Expo or a WebView.

## Current modules
- `scripts/main.gd` — composition root and UI actions.
- `scripts/city_view.gd` — original procedural isometric city renderer, camera pan/zoom, selection and touch/mouse input.
- `scripts/game_state.gd` — persistent domain state and day progression.
- `scripts/economy_engine.gd` — revenue, expense and upgrade formulas.
- `scripts/save_manager.gd` — JSON save/load in Godot user storage.

The first vertical slice intentionally prioritizes a playable city loop: **select → upgrade → hire/create company/develop product → advance day → save**. Future systems should remain separate modules and extend the same state/economy interfaces.

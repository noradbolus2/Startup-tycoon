# Startup Tycoon — Final Technical Stack

**Migration branch:** `unity-migration`  
**Target:** Native Android 3D/isometric business city-builder

## Engine

- **Unity 6.x LTS / latest stable Unity 6 release available in the build environment**
- **Universal Render Pipeline (URP)**
- **C#** with one-responsibility modules
- Native Android player; no WebView, Expo, React Native or browser packaging

## Rendering and city technology

- URP mobile renderer with scalable quality tiers.
- Orthographic/isometric camera with touch pan, pinch zoom, rotation and focus transitions.
- GPU instancing for repeated city props and building modules.
- LOD Groups for building and environment distance tiers.
- Occlusion Culling where the generated city layout benefits from it.
- Object pooling for vehicles, pedestrians, construction workers and VFX.
- Baked/static lighting where possible; limited real-time shadows on Android.
- Addressables for city districts, building families, UI and optional content.
- Texture atlases and mesh/material variants for consistent art direction.

## Input and UI

- Unity Input System for mouse, touch drag, pinch, rotation and selection.
- Unity UI for the first production slice; UI Toolkit may be used for data-heavy management panels where it improves maintainability.
- Contextual city panels so the city remains the primary screen.

## Data and simulation

- ScriptableObjects for immutable/static data:
  - building definitions
  - industries
  - employee roles
  - product definitions
  - research nodes
  - district rules
- Plain C# domain models and systems for runtime state:
  - companies
  - employees
  - products
  - market conditions
  - finance
  - competitors
  - logistics
  - events
  - progression
- Rendering and simulation remain separate so Android performance can be profiled independently.

## Save architecture

- Versioned JSON or binary save envelope for player state.
- Separate save DTOs from runtime domain objects.
- Autosave after meaningful state transitions and on application pause/quit.
- Migration handlers preserve older save versions.
- Save slots are planned after the first Unity Android slice.

## Asset pipeline

- Hybrid pipeline:
  - original modular business-city buildings
  - procedural placement and district variation
  - properly licensed modular environment assets where useful
  - custom Startup Tycoon signage, materials and UI
- Every building family must have authored visual progression, LOD variants and mobile-safe materials.
- Addressables groups will separate bootstrap content, city foundation, district content and optional content.

## Android

- Android native target.
- ARM64 first.
- IL2CPP for release builds.
- Proper package identifier: `com.noradbolus.startuptycoon`.
- Release keystore managed outside source control.
- Development APK and release APK from the same reproducible project.
- AAB is required for eventual store delivery.
- Splash/icon/orientation/permissions configured in the Unity Player settings.

## Build pipeline

- Unity 6 Android Build Support, Android SDK/NDK, JDK and Gradle must be installed in the active environment.
- Local command-line build is preferred for iteration.
- GitHub Actions should use a pinned Unity editor image/license workflow once Unity Build Support is available.
- Build stages:
  1. checkout
  2. restore/import Unity packages
  3. run edit-mode and play-mode tests
  4. build ARM64 IL2CPP development APK
  5. build ARM64 IL2CPP release APK
  6. verify artifact and package metadata
  7. upload APK/AAB artifact

## Version control

- GitHub repository: `noradbolus2/Startup-tycoon`
- Mainline: `main`
- Migration branch: `unity-migration`
- Backup of existing Godot line: `pre-unity-migration`
- Meaningful feature/build commits only; generated Library/Temp/Build artifacts stay ignored.

## Current environment note

This document locks the intended stack. At the time of writing, the active sandbox has Godot 4.7.2 and a working Godot Android toolchain, but no Unity 6 editor binary or Unity Android Build Support was found. Unity migration and the first Unity APK therefore require a real Unity editor/toolchain installation before they can be truthfully reported as built or tested.

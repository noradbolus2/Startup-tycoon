# Startup Tycoon — Engine Decision

**Decision date:** 2026-09-29  
**Repository:** `noradbolus2/Startup-tycoon`  
**Current branch:** `main`  
**Backup branch:** `pre-unity-migration`

## Executive decision

For the current repository and the next shippable milestones, **retain Godot 4.7.2** and continue improving the existing project. Do **not** claim a Unity or Unreal migration: neither editor/toolchain is available in the current build environment, and creating an empty Unity/Unreal project would not preserve the working game.

This is a scoped engineering decision, not a claim that Godot has the largest commercial 3D ecosystem. Unity 6 is the strongest alternate candidate if the project moves to a true asset-heavy 3D production pipeline. The current game is a stylized, procedural, isometric city-builder with a native Android APK already exporting and a modular simulation/rendering split. Godot can continue to deliver that visual direction without throwing away the working economy, save, input and Android pipeline.

## Engines considered

### Unity 6

**Strengths for this game**

- Strongest overall ecosystem for an asset-heavy commercial 3D city-builder.
- Mature 3D tooling, URP mobile rendering, profiling, LOD workflows, addressable content and animation tooling.
- GPU instancing is a first-class optimization path for repeated city props such as trees, cars and windows. Unity's documentation notes that instancing can reduce draw calls and that its benefits can be especially useful on mobile, while also requiring platform profiling.
- Best long-term option if the visual target becomes a fully modeled 3D city with a large content team and a deep asset pipeline.

**Tradeoffs**

- A real migration means recreating the current procedural city renderer, input, state schema, economy hooks, save format and Android export setup in C# and Unity scenes/prefabs.
- Unity 6 is not installed in this environment; there is no Unity editor, Android Unity module, project license setup or tested CI runner available here.
- Migration would temporarily reduce playable progress and would be dishonest if represented as complete without a real Unity build and gameplay test.

### Unreal Engine 5.x

**Strengths for this game**

- Highest ceiling for lighting, materials, cinematic 3D presentation and large-scale visual effects.
- Excellent editor and material ecosystem for premium 3D art.

**Tradeoffs**

- Highest mobile performance, memory and build-size risk of the three candidates for this particular dense Android target.
- Epic's mobile guidance describes explicit performance tiers: HDR lighting, post-processing, reflections and translucent materials can become expensive on mobile devices.
- Unreal is not installed in this environment, and no tested Android project/toolchain exists for this repository.
- The visual ceiling is unnecessary for the current stylized procedural slice and would slow simulation/product iteration.

### Godot 4.7

**Strengths for this game**

- Already used by the repository with separate city, state, economy, save and UI modules.
- Native Android export is installed and verified: SDK, build tools, Godot 4.7.2 Android templates, release signing and APK validation all work in this environment.
- Lightweight runtime and straightforward procedural drawing make it suitable for a stylized isometric city with controlled object counts.
- GDScript iteration speed is high for simulation, UI and input work.
- No WebView, Expo or browser packaging is involved.

**Tradeoffs**

- Smaller commercial 3D asset ecosystem than Unity.
- Fewer turnkey workflows for large-scale 3D content, advanced animation and high-end lighting.
- The current implementation is 2D procedural/isometric rather than a full 3D mesh city. It must not be called a finished commercial 3D product.
- For a major future move to modeled 3D buildings, Godot will require deliberate mesh batching, LOD, atlas and lighting work.

## Decision matrix

| Criterion | Unity 6 | Unreal 5.x | Godot 4.7 | Current decision |
|---|---:|---:|---:|---|
| Android performance control | High | Medium–High, higher cost | High for controlled stylized scenes | Godot now; Unity future candidate |
| Dense 3D city tooling | High | Very high | Medium | Unity strongest practical target |
| Premium lighting/materials | High | Very high | Medium | Unreal highest ceiling |
| Procedural simulation iteration | High | Medium | High | Godot fits current loop |
| Touch/camera/UI iteration | High | High | High | No decisive blocker |
| LOD/instancing ecosystem | Very high | High | Medium | Unity strongest |
| Current environment readiness | **Not installed** | **Not installed** | **Installed and tested** | Godot |
| Existing code reuse | Requires migration | Requires migration | Already modular | Godot |
| Verified Android APK pipeline | Not available here | Not available here | **Verified release APK** | Godot |
| Migration risk now | High | Very high | None | Godot |

## Reusable game design identified

The current Godot project contains reusable design and simulation concepts, independent of engine choice:

- City state with player buildings, levels, positions and building income.
- Economy formulas for revenue, operating expenses and upgrade costs.
- Company creation, employee hiring and product development actions.
- Local JSON save/load state.
- Android package/export identity and release signing configuration.

If a Unity migration becomes authorized and technically feasible, these rules should be recreated as engine-independent C# domain modules rather than mechanically translating the renderer.

## Migration decision

**No migration in this milestone.** A `pre-unity-migration` backup branch was created before making this decision. The main branch remains the verified Godot Android line.

A Unity migration should start only when all of the following are available:

1. Unity 6 editor and Android Build Support in the execution environment.
2. A committed Unity project that boots on Android.
3. A C# domain layer matching the current save/economy behavior.
4. A real 3D city scene with at least one selectable/upgradable building.
5. A reproducible APK build and a visual device/emulator test.
6. A migration comparison showing a material visual/performance gain over the Godot line.

Until then, switching engines would be an untested rewrite, not a quality improvement.

## Android build strategy

The current Godot strategy is native Android export:

- Godot 4.7.2 release templates.
- Android SDK platform/build tools configured locally.
- Release keystore and Android export preset committed without committing the private keystore.
- `StartupTycoon-v0.1.0-release.apk` exported and verified with `apksigner`.
- Future AAB work can use Godot's Gradle Android build path once the release pipeline is expanded.

Godot's official Android documentation recommends OpenJDK, Android SDK platform-tools/build-tools/platform packages, configured editor SDK/JDK paths and a non-debug keystore for store uploads. The current APK path follows the same requirements.

## Expected impact

### Performance

Retaining Godot keeps the current low-overhead stylized renderer and lets us control draw cost. The next work should add explicit quality tiers, aggregated simulation ticks, batching-friendly procedural geometry and mobile-safe effects. A full Unity 3D migration could improve tooling for instancing/LOD, but would introduce migration and content costs before any measured gain.

### Visual quality

Godot can materially improve the current presentation through denser procedural geometry, district-specific building generators, camera polish, lighting-style passes and mobile-safe animation. If the target changes from stylized isometric to a large library of authored 3D assets, Unity 6 becomes the recommended re-evaluation point.

## Sources

- [Unity 6 GPU instancing](https://docs.unity3d.com/6000.2/Documentation/Manual/GPUInstancing.html)
- [Unreal Engine mobile performance guidelines](https://dev.epicgames.com/documentation/en-us/unreal-engine/performance-guidelines-for-mobile-devices-in-unreal-engine)
- [Godot 4.7 Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

## Honest status

- **Engine evaluation:** Complete and documented.
- **Unity migration:** Not started; no migration is being falsely claimed.
- **Godot Android line:** Active and build-verified.
- **Commercial-grade final game:** Not complete.

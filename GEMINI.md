# ArchKing - Project Documentation & Handover

This document provides a comprehensive overview of the **ArchKing** Godot project, its architectural evolution, and the current state of the codebase. It is designed to help any AI model or human developer quickly understand, debug, and expand upon the project.
1
---

## 1. Project Core Identity
**ArchKing** is a 2D castle defense game built in **Godot 4.6**.
- **Perspective:** Stylized orthographic / top-down fortress defense.
- **Goal:** Defend the castle wall through alternating prep and battle phases.
- **Current layout:** A wall combat lane above and a back-area support/shop space below.
- **Controls:** Keyboard + mouse, with basic gamepad support. `F11` toggles fullscreen.

---

## 2. Architecture & Systems

### **Level Management (`level.gd`)**
- Acts as the central orchestrator (game state, UI, spawning, shop, fortress systems, audio, options).
- **Global States:** Manages `castle_hp`, `coins`, `score`, waves/phases, fortress progression, and game over state.
- **UI Interaction:** Controls HUD, shop tabs, prompts, temporary messages, boss UI, main menu, pause menu, game over, and options.
- **Input Action Bootstrapping:** Dynamically ensures keyboard, mouse, and gamepad InputMap actions exist at runtime.
- **Responsive Layout:** Repositions key world/camera/UI elements when viewport size changes.
- **Process Mode:** Set to `PROCESS_MODE_ALWAYS` to allow pause/options/menu logic while gameplay nodes are halted.

### **Player Controller (`player.gd`)**
- **Movement:** Horizontal movement constrained between towers (`left_bound`, `right_bound`).
- **Shooting:** Emits `shoot_requested(spawn_position, target_position)`.
- **Dynamic Animations:** SpriteFrames are built programmatically in `_build_animations()` from grid-based sprite sheets.
- **Facing Logic:** Sprite flips based on movement direction (default faces Right).

### **Enemy System (`enemy.gd`)**
- Supports multiple enemy archetypes and elite/boss variants.
- Enemies move toward the wall or use ranged attack behavior depending on configuration.
- Connects to kill, wall-hit, and hit-feedback signals used by `level.gd`.

### **Projectile System (`arrow.gd`)**
- Uses `set_direction(target_pos)` to calculate velocity and rotation.
- Shared by player and turret shots.
- Automatically frees itself when leaving the viewport.

### **Options UI (`options_panel.gd`)**
- Reusable settings panel scene used by the main menu / pause flow.
- Emits settings changes for display mode, resolution scale, and audio values.
- Supports focusable controls for keyboard/gamepad navigation.

---

## 3. Evolutionary Log (What was changed)

### **Current implemented systems**
- Split **prep vs battle** game loop.
- Ladder traversal between the lower support area and upper wall lane.
- Structured enemy waves with mixed compositions and periodic boss waves.
- Expanded shop with fortress, defenses, tactics, and traps tabs.
- Fortress progression including wall upgrades, keep upgrades, turrets, catapults, and trap coverage growth.
- Trap system with spike, fire, and slow trap deployment to battlefield points.
- Floating combat text and improved combat feedback.
- Main menu, pause, game over, and a reusable options panel.
- Procedural placeholder SFX plus generated background music.
- Responsive fullscreen/widescreen support with adaptive horizontal layout.

### **Recent additions**
- Added a dedicated `OptionsPanel` scene and saved settings via `user://settings.cfg`.
- Added display mode support: fullscreen, borderless, windowed.
- Added resolution scale setting.
- Added basic gamepad mappings and menu navigation support.
- Added/expanded turret gameplay:
	- cheaper and earlier unlock
	- stronger damage/range/fire rate
	- turret targeting controls
	- turret tracer, muzzle flash, impact sparks, and hover-only range preview
	- distinct turret sound
- Removed committed temporary `.tmp` scene files and added ignore rules for temp files.

---

## 4. Technical Constants & Layout Data
- **Base Viewport Size:** 1152 x 900.
- **Stretch Mode:** `canvas_items`
- **Stretch Aspect:** `expand`
- **Window Modes:** fullscreen, borderless, windowed
- **Wall Y Position:** approximately 470.0 in current layout logic.
- **Player Speed:** 350.0.
- **Collision Layers:**
	- Layer 1: Player
	- Layer 2: Enemy
	- Layer 3: Projectile
	- Layer 4: Shop

---

## 5. Potential Next Steps (Backlog)
- [ ] Split `level.gd` into smaller managers/systems.
- [ ] Replace generated music/SFX with authored assets.
- [ ] Add more distinct enemy behaviors beyond stat mixes.
- [ ] Add more fortress defenses / upgrades / synergies.
- [ ] Improve turret art so rotation affects a separate head/barrel instead of the full shape.
- [ ] Continue widescreen decoration/layout polish.

---

## 6. Debugging Notes
- If nodes are moving during pause, check their `process_mode` in the Inspector. `Level` and menu/options logic intentionally use `PROCESS_MODE_ALWAYS`.
- If the player goes off-screen or UI looks wrong on wide monitors, inspect `_update_responsive_layout()` in `level.gd`.
- If settings behave oddly, inspect `user://settings.cfg` and the `OptionsPanel` signals.
- If strict GDScript warnings are treated as errors, prefer explicit typing over `:=` when values may be inferred from `Variant`.
- Texture/resource UIDs are stored in `.import` files; if textures are missing, verify `ext_resource` IDs in `.tscn` files.

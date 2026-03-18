# ArchKing - Project Documentation & Handover

This document provides a comprehensive overview of the **ArchKing** Godot project, its architectural evolution, and the current state of the codebase. It is designed to help any AI model or human developer quickly understand, debug, and expand upon the project.

---

## 1. Project Core Identity
**ArchKing** is a 2D castle defense game built in **Godot 4.6**.
- **Perspective:** Top-down/Orthographic.
- **Goal:** Defend the castle wall at the bottom of the screen against falling/marching enemies.
- **Controls:** `A/D` or `Arrows` to move, `Mouse Click` to aim and shoot, `E` to interact with the shop, `Esc` to pause.

---

## 2. Architecture & Systems

### **Level Management (`level.gd`)**
- Acts as the central orchestrator (Game State, UI, Spawning).
- **Global States:** Manages `castle_hp`, `coins`, and `is_game_over`.
- **UI Interaction:** Controls the Main Menu, Pause Menu, Game Over screen, and HUD updates.
- **Input Action Bootstrapping:** Dynamically ensures required InputMap actions exist at runtime.
- **Process Mode:** Set to `PROCESS_MODE_ALWAYS` to allow pause menu logic while gameplay nodes are halted.

### **Player Controller (`player.gd`)**
- **Movement:** Horizontal movement constrained between towers (`left_bound`, `right_bound`).
- **Shooting:** Emits `shoot_requested(spawn_position, target_position)`.
- **Dynamic Animations:** SpriteFrames are built programmatically in `_build_animations()` from grid-based sprite sheets.
- **Facing Logic:** Sprite flips based on movement direction (default faces Right).

### **Enemy System (`enemy.gd`)**
- **Behavior:** March downward toward the wall.
- **Combat:** Connects to `enemy_killed` (gives coins) and `reached_wall` (deals damage) signals.
- **Group:** Belongs to the `"enemies"` group for projectile detection.

### **Projectile System (`arrow.gd`)**
- **Movement:** Uses `set_direction(target_pos)` to calculate velocity and rotation based on mouse input.
- **Cleanup:** Automatically frees itself when leaving the viewport.

---

## 3. Evolutionary Log (What was changed)

### **Phase 1: Initial Setup**
- Basic horizontal movement and vertical shooting.
- Simple color-band wall and tiled background.
- Basic Enemy spawning at the top.

### **Phase 2: UI & UX Enhancements**
- **Pause System:** Added `Esc` key handling and a `PausePanel`. Explicitly set gameplay nodes to `PAUSABLE` to ensure they stop during pause.
- **Game Flow:** Implemented a **Main Menu** (start game) and a **Game Over** panel with a **Restart** button (scene reload).
- **Shop System:** Added a `ShopZone` where players can spend coins to repair the wall.

### **Phase 3: Gameplay Mechanics Refinement**
- **Mouse Aiming:** Switched from fixed upward shooting to dynamic mouse-based aiming. The arrow now follows the vector from the player to the mouse click position.
- **Animation Fixes:** Corrected the sprite-flipping logic where the character was moving/facing backwards.

### **Phase 4: Visual Redesign (Reference Match)**
- **Perspective:** Shifted to match a "Forest Path" reference image.
- **Background:** Added a central path (`dirt_tile`) and forest floor (`grass_tile`).
- **Layout:** 
    - Added side towers (`LeftTower`, `RightTower`) that act as movement boundaries.
    - Repositioned the wall higher (`wall_y = 536`) to allow for a "behind-the-wall" shop area.
    - Added environment decorations (trees) and a visual `ShopStall` building.

---

## 4. Technical Constants & Layout Data
- **Viewport Size:** 1152 x 648.
- **Wall Y Position:** 536.0.
- **Player Speed:** 350.0.
- **Arrow Speed:** 700.0.
- **Collision Layers:**
    - Layer 1: Player
    - Layer 2: Enemy
    - Layer 3: Projectile
    - Layer 4: Shop

---

## 5. Potential Next Steps (Backlog)
- [ ] **Wave System:** Instead of infinite random spawning, implement structured waves with increasing difficulty.
- [ ] **Enemy Variety:** Add "Archer Goblins" (stay at a distance and shoot back) or "Shield Goblins" (higher HP).
- [ ] **Traps:** Use the remaining assets to implement placeable traps (e.g., bear traps seen in reference).
- [ ] **Sound Effects:** Add feedback for shooting, enemy death, and purchases.

---

## 6. Debugging Notes
- If nodes are moving during pause, check their `process_mode` in the Inspector. It should be `Pausable` (Inherit) while the `Level` root is `Always`.
- If the player goes off-screen, check `left_bound` and `right_bound` in `level.gd`.
- Texture UIDs are stored in `.import` files; if textures are missing, verify the `ext_resource` IDs in `Level.tscn`.

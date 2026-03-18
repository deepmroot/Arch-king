# ArchKing

ArchKing is a 2D castle defense prototype built with **Godot 4.6**.

The player stands on the castle wall, shoots incoming enemies, earns coins, and uses the shop to keep the defense alive.

---

## Current Gameplay

- Move left and right along the wall
- Aim with the mouse
- Shoot arrows at enemies approaching from the top
- Prevent enemies from reaching the wall
- Earn coins for kills
- Use the shop to repair the wall
- Pause, restart, and play through a basic survival loop

---

## Controls

- **A / D** or **Left / Right Arrow** → Move
- **Left Mouse Click** or **Space** → Shoot
- **E** → Interact with shop
- **Esc** → Pause

---

## Requirements

- **Godot 4.6**

This project uses:
- `run/main_scene = res://scenes/Level.tscn`

---

## How to Run

1. Install **Godot 4.6**.
2. Clone the repository.
3. Open Godot.
4. Import this folder as a project.
5. Run the project.

---

## Project Structure

### Main scene
- `scenes/Level.tscn` → main playable scene

### Scripts
- `scripts/level.gd` → game flow, UI, spawning, shop, pause/game over
- `scripts/player.gd` → player movement, aiming, shooting, animations
- `scripts/enemy.gd` → enemy movement and death/wall-hit logic
- `scripts/arrow.gd` → projectile movement and collision

### Docs
- `GEMINI.md` → current handover / project summary
- `REFERENCE_ALIGNMENT.md` → plan for matching the reference image vision

---

## Current State

Implemented:
- player movement
- directional shooting
- enemy spawning
- castle HP
- coins
- repair shop
- main menu
- pause menu
- game over screen
- forest path layout

Planned next:
- wave system
- traps
- expanded shop upgrades
- enemy variety
- stronger visual alignment with the reference image

---

## Team Notes

### Git workflow
Typical workflow:

```bash
git pull
# make changes
git add .
git commit -m "Describe changes"
git push
```

### Godot notes
- `.godot/` is ignored and should not be committed
- Main development should happen in:
  - `scenes/`
  - `scripts/`
  - `assets/`
  - project docs

### Reference direction
Use `reference_idea.png` as the target visual/gameplay direction.

---

## Known Important Files

- `project.godot`
- `scenes/Level.tscn`
- `scripts/level.gd`
- `reference_idea.png`

---

## Repository Goal

The long-term goal is to turn this prototype into a polished wall-defense game where players:
- defend the castle wall
- survive waves
- buy upgrades
- place traps
- match the feel of the provided reference image

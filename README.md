# ArchKing

ArchKing is a 2D wall-defense game prototype built with **Godot 4.6**.

The current version is structured around two connected spaces:
- the **wall / battle area** where the player fights incoming waves
- the **back area** where the player prepares, shops, and places traps between waves

---

## Core Gameplay Loop

1. Start in the **back area** behind the wall.
2. Move around, shop, and prepare.
3. Climb the ladder to the wall.
4. Fight an enemy wave.
5. Earn **coins** and **score**.
6. Survive until the wave is cleared.
7. Get a **prep phase** to shop and set traps.
8. Repeat with harder waves.

---

## Current Features

### Player
- Wall combat with directional shooting
- Mouse aiming
- Horizontal wall movement during battle
- Full 4-direction movement in the back area
- Ladder transition between back area and wall
- Fire-rate upgrades
- Damage upgrades

### Level / Camera
- Split level flow:
  - **battlefield view** on the wall
  - **back-area view** below the wall
- Camera transitions when moving up/down the ladder
- Tighter battle framing so more of the goblin lane is visible
- Back area for shop + trap setup

### Waves
- Structured wave system
- Prep phase before/after battle
- Wave start / wave cleared banners
- Infinite survival progression
- Enemy scaling over time:
  - more enemies
  - faster enemies
  - more HP
  - better rewards

### Shop
- Repair wall HP
- Upgrade fire rate
- Upgrade arrow damage
- Buy trap charges

### Traps
- Buy trap charges from the shop
- Place traps near trap slots in the back area
- Traps trigger during battle when enemies reach them
- Triggered traps are consumed

### Combat / Feedback
- Arrow glow polish
- Enemy hit flash
- Enemy death fade
- Shadows under player/enemies
- Wall-hit feedback and camera shake

### Game Flow
- Main menu
- Pause menu
- Game over screen
- Restart flow

---

## Controls

### General
- **A / D** or **Left / Right** → move left/right
- **W / Up** → move up in back area / climb up ladder
- **S / Down** → move down in back area / climb down ladder during prep
- **Left Mouse Click** or **Space** → shoot
- **E** → interact with shop / place trap near a trap slot during prep
- **Esc** → pause

### Ladder Rules
- Start in the **back area**
- Press **W** near the ladder bottom to go up to the wall
- Press **S** near the ladder top to go down during **prep phase only**
- During active battle, the player stays committed to the wall

---

## Wave / Phase Rules

### Prep Phase
- No enemy spawning
- Shop is available
- Player can move in the back area
- Player can place traps
- Prep timer counts down

### Battle Phase
- Enemies spawn and attack the wall
- Player fights from the wall
- Shop is not available
- Going back down the ladder is blocked during battle

---

## Current Shop Items

- **Repair Wall**
- **Fire Rate Upgrade**
- **Arrow Damage Upgrade**
- **Trap Charge**

---

## Requirements

- **Godot 4.6**

Main scene:
- `res://scenes/Level.tscn`

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

### Core scripts
- `scripts/level.gd` → game phases, waves, camera flow, shop, traps, HUD, menus
- `scripts/player.gd` → player movement, ladder-ready movement states, aiming, shooting, animations
- `scripts/enemy.gd` → enemy movement, HP, hit/death reactions, wall pressure
- `scripts/arrow.gd` → arrow movement, damage, collision, visual glow

### Scenes
- `scenes/Player.tscn`
- `scenes/Enemy.tscn`
- `scenes/Arrow.tscn`
- `scenes/Level.tscn`

### Docs
- `GEMINI.md` → project handover / technical summary
- `REFERENCE_ALIGNMENT.md` → reference-image implementation plan
- `reference_idea.png` → target look and gameplay direction

---

## Current State Summary

Implemented now:
- split wall + back-area structure
- ladder traversal
- prep / battle wave loop
- score tracking
- wave UI banners
- expanded shop
- trap purchase and placement
- trap triggering
- camera transitions
- wall-hit feedback
- visual polish pass for level and combat feel

Still good next targets:
- more enemy types
- better trap variety
- sound effects
- support archers / allied defenders
- stronger wall/tower art replacement

---

## Team Git Instructions

## If you do NOT have the project yet
Clone it:

```bash
git clone https://github.com/deepmroot/Arch-king.git
cd Arch-king
```

Then open the folder in Godot.

---

## If you ALREADY have the files and repo set up
To get the latest code:

```bash
git pull origin main
```

If you already made local changes, first check status:

```bash
git status
```

If you have unfinished edits, either:
- commit them first, or
- stash them

Example stash flow:

```bash
git stash
git pull origin main
git stash pop
```

---

## Basic team workflow

### 1. Get latest code
```bash
git pull origin main
```

### 2. Make your changes
Edit scenes/scripts/assets.

### 3. Check what changed
```bash
git status
```

### 4. Stage files
```bash
git add .
```

### 5. Commit
```bash
git commit -m "Describe your changes"
```

### 6. Push
```bash
git push origin main
```

---

## Recommended commit habits
- Keep commits focused
- Use clear messages
- Pull before starting new work
- Avoid committing temporary or editor junk files

Examples:
- `Add fast enemy wave variant`
- `Improve trap trigger visuals`
- `Fix ladder camera transition`

---

## Important Git / Godot Notes

- `.godot/` is ignored and should not be committed
- Temporary files should not be committed
- Main work usually happens in:
  - `scenes/`
  - `scripts/`
  - `assets/`
  - docs

---

## If Git Pull Fails Because of Conflicts
If Git says your local files conflict with incoming changes:

### Option A — commit your work first
```bash
git add .
git commit -m "WIP local changes"
git pull origin main
```

### Option B — stash your work
```bash
git stash
git pull origin main
git stash pop
```

If the stash pop creates conflicts, resolve them manually in the files.

---

## Important Files to Know

- `project.godot`
- `scenes/Level.tscn`
- `scripts/level.gd`
- `scripts/player.gd`
- `scripts/enemy.gd`
- `scripts/arrow.gd`
- `reference_idea.png`
- `REFERENCE_ALIGNMENT.md`

---

## Long-Term Goal

The long-term goal is to turn this prototype into a polished fantasy wall-defense game where players:
- defend the castle wall
- survive escalating waves
- return to the back area to prepare
- buy upgrades and place traps
- match the feel and composition of the reference image

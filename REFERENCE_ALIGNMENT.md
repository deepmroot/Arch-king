# ArchKing Reference Alignment Plan

This document translates `reference_idea.png` into a concrete implementation plan for the current Godot project.

---

## 1. Target Experience

The game should feel like a **wall-defense survival game** with a clear loop:

1. Enemies march down the central forest path.
2. The player defends from the castle wall.
3. Kills grant coins.
4. Coins are spent at the shop behind the wall.
5. The player buys repairs, traps, and combat upgrades.
6. Waves get harder over time.
7. The player survives as long as possible.

---

## 2. Reference Breakdown

## Visual requirements from the image
- Tall vertical battlefield composition.
- Dense forest framing on both sides.
- One central dirt path as the enemy lane.
- Two large stone towers left and right.
- A stone castle wall/parapet the player stands on.
- A ladder centered below the player.
- A shop stall behind/below the wall.
- Trap area behind/below the wall.
- Clear separation between:
  - enemy approach area
  - wall defense line
  - support/shop area

## Functional requirements from the image
- Enemies should primarily advance through the center path.
- The wall is the main defense line.
- The player should feel anchored to the wall top.
- Shop interaction should be an important progression system.
- Traps should be placeable and useful.
- Waves should escalate difficulty.
- Optional allied support units can fire into the lane.

---

## 3. Current State vs Target

## Already in place
- Player movement on the wall.
- Mouse-based shooting.
- Enemy spawning and downward movement.
- Castle HP system.
- Coins.
- Shop interaction.
- Main menu / pause / game over flow.
- Basic forest/path layout.
- Basic left/right tower blockers.

## Missing or too simple
- Proper wall/tower presentation.
- Ladder visual and traversal logic.
- Trap system.
- Wave-based progression.
- Path-focused enemy spawning.
- Expanded shop inventory.
- Support defenders / side archers.
- Stronger visual composition matching the reference.

---

## 4. Required Systems

## A. Battlefield Layout System
Goal: make the level read like the reference image.

### Needed changes
- Rebuild `scenes/Level.tscn` composition.
- Replace simple wall band presentation with a more intentional parapet layout.
- Make left and right towers visually larger and more integrated.
- Add a centered ladder below the player.
- Define a lower support area behind the wall for shop and traps.
- Tighten the enemy lane to the center path.

### Deliverables
- Updated level scene layout.
- New placement markers for:
  - player start
  - ladder
  - shop
  - trap slots
  - enemy spawn lane bounds

---

## B. Wave System
Goal: replace endless random spawning with structured survival gameplay.

### Required behavior
- Game starts at Wave 1.
- Each wave spawns a controlled number of enemies.
- Short downtime between waves.
- Later waves increase:
  - enemy count
  - spawn rate
  - enemy speed / health / variants
- UI shows current wave and wave transitions.

### Suggested data model
For each wave:
- `enemy_count`
- `spawn_interval`
- `enemy_types`
- `reward_modifier`

### Deliverables
- Wave controller in `scripts/level.gd` or a dedicated `wave_manager.gd`.
- HUD wave label.
- Inter-wave timing.

---

## C. Trap System
Goal: support the strategy shown in the image.

### Recommended first version
Use fixed trap slots rather than free placement.

### Why fixed slots
- Easier to build and balance.
- Cleaner UI.
- Matches the staged defense feel.
- Faster to implement in current architecture.

### Trap MVP behavior
- Several trap slots exist behind or near the wall.
- Player buys a trap from the shop.
- Trap is placed into an empty slot.
- When an enemy enters the trap area, it:
  - damages,
  - slows, or
  - kills depending on trap type.
- Trap may be single-use or have durability.

### Suggested first trap types
1. **Bear Trap**
   - cheap
   - single-use
   - high damage or root effect
2. **Spike Trap**
   - medium cost
   - reusable
   - lower repeated damage
3. **Fire Trap** later
   - area damage
   - more expensive

### Deliverables
- `TrapSlot` scene.
- `Trap` scene/script.
- Placement logic.
- Shop purchasing logic for traps.

---

## D. Shop Expansion
Goal: make the shop a core progression feature.

### Current shop
- Only repairs wall HP.

### Required expansion
Add real purchase choices:
- Wall Repair
- Bear Trap
- Fire Rate Upgrade
- Arrow Damage Upgrade
- Optional Support Archer unlock

### Recommended first shop menu
- Repair Wall (+1 HP)
- Buy Bear Trap
- Upgrade Fire Rate
- Upgrade Damage

### Deliverables
- Updated shop UI.
- Purchase validation.
- Persistent run upgrades for current session.

---

## E. Enemy Lane and Spawning
Goal: enemies should visually and functionally use the central path.

### Current issue
- Enemies spawn across almost the whole screen width.

### Required behavior
- Spawn only within the path lane width.
- Slight horizontal variance is okay.
- Some enemy types may later drift or zig-zag.
- Most enemies should clearly approach through the center.

### Deliverables
- Path lane spawn bounds.
- Optional lane markers in scene.
- Better readability of enemy approach.

---

## F. Combat Progression
Goal: add satisfying growth during a run.

### Upgrades to support
- Faster shooting.
- More arrow damage.
- Multi-shot or piercing later.
- Trap capacity increase later.

### Deliverables
- Player stats managed centrally.
- Upgrade values applied at runtime.
- Clear HUD feedback or shop descriptions.

---

## G. Support Defenders / Side Archers (Phase 2)
Goal: match the wider defensive fantasy in the reference.

### Role
- Automated allied archers fire toward enemies from side positions.
- Can be permanent, unlockable, or wave rewards.

### Why Phase 2
- Nice for reference match.
- Not required for first playable alignment.
- Better added after waves and traps are stable.

### Deliverables
- `SupportArcher` scene.
- Auto-targeting.
- Unlock/purchase system.

---

## 5. Recommended Milestone Order

## Milestone 1 — Reference Layout Pass
Focus: scene readability.

Tasks:
- Rework `scenes/Level.tscn` to better match image composition.
- Add ladder.
- Add trap slot markers.
- Improve tower/wall placement.
- Narrow enemy spawn lane.

Success condition:
- Screenshot of the level immediately resembles the reference structure.

## Milestone 2 — Wave System
Focus: proper game loop.

Tasks:
- Add wave progression.
- Add wave HUD.
- Add downtime between waves.
- Scale enemy count/speed over time.

Success condition:
- Game is no longer endless random spawning.

## Milestone 3 — Shop Expansion
Focus: player choice.

Tasks:
- Expand shop UI and inventory.
- Add damage/fire-rate upgrades.
- Keep wall repair.

Success condition:
- Coins create meaningful decisions.

## Milestone 4 — Trap System MVP
Focus: strategy layer.

Tasks:
- Add trap slots.
- Add purchasable bear traps.
- Trigger trap effects on enemies.

Success condition:
- Player can buy and deploy traps during a run.

## Milestone 5 — Visual/Feedback Polish
Focus: feel.

Tasks:
- Improve wall/tower visuals.
- Add hit FX, death FX, and audio.
- Improve shop presentation.
- Improve projectile readability.

Success condition:
- Gameplay feels responsive and visually cohesive.

## Milestone 6 — Reference Plus Features
Focus: depth.

Tasks:
- Support archers.
- Enemy variants.
- Better trap variety.
- Better wave compositions.

Success condition:
- Game feels close to the full fantasy implied by the image.

---

## 6. Concrete Code/Scene Task Map

## Files likely to change
- `scenes/Level.tscn`
- `scripts/level.gd`
- `scripts/player.gd`
- `scenes/Enemy.tscn`
- `scripts/enemy.gd`

## New files likely needed
- `scenes/TrapSlot.tscn`
- `scripts/trap_slot.gd`
- `scenes/BearTrap.tscn`
- `scripts/bear_trap.gd`
- `scripts/wave_manager.gd` or wave logic inside `level.gd`
- `scenes/SupportArcher.tscn` later
- `scripts/support_archer.gd` later

---

## 7. Priority Decisions

## Decision 1: Free placement vs fixed slots
Recommendation: **fixed slots first**.

## Decision 2: One currency or many
Recommendation: **coins only** for now.

## Decision 3: One enemy type or several
Recommendation: keep one enemy type until waves + traps work, then expand.

## Decision 4: Player movement scope
Recommendation: keep player wall-bound for now. Do not add full map traversal yet.

## Decision 5: Visual accuracy vs gameplay first
Recommendation: prioritize **layout readability + gameplay systems** before heavy polish.

---

## 8. Implementation Risks

## Risk: overbuilding visuals too early
If too much effort goes into decorative layout before wave/trap/shop systems, the game may look closer to the reference but still not play like it.

## Risk: trap placement complexity
Free placement can become a UI/input problem quickly. Fixed slots avoid this.

## Risk: keeping all logic in `level.gd`
As systems grow, `level.gd` may become too large. Consider splitting into:
- wave manager
- shop logic
- trap logic

---

## 9. Best Immediate Next Step

The best next implementation move is:

### **Step 1: Build the Reference Layout Pass**
Specifically:
- revise `Level.tscn`
- add ladder and trap slots
- improve wall/tower composition
- constrain enemy spawns to the center path

This gives the project the correct visual/gameplay frame before adding waves and traps.

---

## 10. Definition of Done for “Matches the Reference”

The game can be considered aligned with the reference when:
- The level composition clearly resembles the image.
- Enemies advance through a centered lane.
- The player defends from the wall.
- The shop supports repairs and upgrades.
- Traps are placeable and useful.
- Waves create escalating pressure.
- Optional support defenders enrich the battlefield.
- The moment-to-moment feel is “defend the wall, buy upgrades, survive waves.”

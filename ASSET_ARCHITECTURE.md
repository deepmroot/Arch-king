# ArchKing - Asset Architecture & Integration Plan

> **STATUS: INTEGRATED** - All assets wired into game code as of 2026-04-16.

## Organized Asset Tree (NEW)

```
assets/
├── audio/
│   ├── music/
│   │   ├── menu_theme.mp3            # Main menu BGM (upbeat game music)
│   │   └── battle_ambience.mp3       # In-game BGM (Chinese flute ambient, "Fujian Xiamen")
│   ├── sfx/
│   │   ├── arrow_whistle.mp3         # Arrow flight sound (Turkish whistle arrows)
│   │   ├── arrow_launch.m4a          # Arrow fire SFX [NEEDS CONVERSION]
│   │   ├── bear_trap_clamp.m4a       # Bear trap trigger SFX [NEEDS CONVERSION]
│   │   ├── goblin_death.m4a          # Enemy death SFX [NEEDS CONVERSION]
│   │   ├── cannon_fire.m4a           # Catapult/cannon SFX [NEEDS CONVERSION]
│   │   └── turret_crank.m4a          # Turret rotation SFX [NEEDS CONVERSION]
│   └── _voice_note_reference.m4a     # Design reference voice note
│
├── defenses/
│   ├── turret/
│   │   ├── turret_face.png           # Turret sprite sheet (8 frames: idle, aiming, firing, reloading)
│   │   └── turret_bullet.png         # Turret projectile (2 orange bullet variants)
│   ├── traps/
│   │   ├── bear_trap.png             # Spike/bear trap sprite (3 frames: open, closing, closed)
│   │   └── fire_trap.png             # Fire trap sprite sheet (idle embers + fire burst animation)
│   └── artillery/
│       └── artillery.png             # Catapult/artillery sprite (3 frames: idle, charging, firing)
│
├── enemies/
│   ├── goblin.png                    # [EXISTING] Current enemy sprite sheet
│   ├── goblins/                      # 5 goblin variant sprites (individual PNGs, 4-directional x 3 frames each)
│   │   ├── $Goblin_1.png             # Basic grunt (green, no gear)
│   │   ├── $Goblin_2.png             # Armored goblin (helmet)
│   │   ├── $Goblin_3.png             # Jester goblin (colorful hat) - Runner type
│   │   ├── $Goblin_4.png             # Warrior goblin (armed)
│   │   ├── $Goblin_5.png             # Shield goblin (carries shield)
│   │   └── Shadow.png                # Drop shadow for all goblins
│   ├── frost_goblins/                # Ice-themed variant pack (9 small + 9 large)
│   │   ├── Frost_Goblin_0-8.png      # Small frost goblins (9 individual poses/variants)
│   │   └── Large_Frost_Goblin_0-8.png # Large frost goblins (tank/elite variants)
│   ├── goblin_king/
│   │   └── goblin_king_sheet.png     # Boss: Goblin King (full sprite sheet, ~12 rows of animations)
│   │                                 #   Rows: idle, walk, attack_melee, attack_ranged, hurt, death,
│   │                                 #   special_summon, taunt, block, sit, mounted, misc
│   └── goblin_mech/
│       └── goblin_mech_sheet.png     # Boss: Goblin Mech Rider (5 rows of animations)
│                                     #   Rows: idle(2), walk(8), attack_swing(8), attack_slam(4), death(7)
│
├── environment/
│   ├── castle_wall.png               # [EXISTING] Current wall texture
│   ├── walls/                        # Upgraded wall art (replaces Polygon2D-drawn walls)
│   │   ├── wall_level1.png           # Basic stone wall (rough gray blocks)
│   │   ├── wall_level2.png           # Fortified wall (battlements + gate with hot oil)
│   │   ├── wall_level3.png           # Royal wall (battlements + banner)
│   │   └── wall_battlement.png       # Wide battlement strip (repeating crenellation pattern)
│   └── fantasy_tileset/              # [EXISTING] Fan-tasy Tileset pack
│
├── player/                           # [EXISTING] Player sprite sheets
│   ├── idle_run.png
│   ├── attack.png
│   └── death.png
│
├── projectiles/                      # [EXISTING]
│   └── arrow.png
│
└── ui/
    ├── shop/
    │   ├── shop_building.png         # Shop structure art (detailed pixel building)
    │   ├── shop_awning_up.png        # Shop open state animation (awning rolling up, ~21 frames)
    │   └── shop_awning_down.png      # Shop closed state animation (awning rolling down, ~28 frames)
    └── mainmenu/
        ├── menu_background.png       # Menu BG (screenshot of gameplay - can be replaced)
        ├── main_menu.tscn            # Reference scene (needs adaptation for arch-king)
        ├── main_menu.gd              # Menu logic: Start, Options, Exit
        ├── audio_control.gd          # Volume slider (HSlider with bus control)
        └── fullscreencontrol.gd      # Fullscreen toggle (CheckButton)
```

---

## Asset-to-System Mapping

### WHAT REPLACES WHAT (Currently Procedural -> Real Assets)

| Current (Procedural/Placeholder)     | New Asset                        | Code Change Needed                              |
|--------------------------------------|----------------------------------|-------------------------------------------------|
| Generated tone SFX for "shoot"       | `arrow_launch.m4a` + `arrow_whistle.mp3` | Replace `_play_sound("shoot")` with preloaded AudioStream |
| Generated tone SFX for "enemy_die"   | `goblin_death.m4a`              | Replace `_play_sound("enemy_die")`              |
| Generated tone SFX for "trap_spike"  | `bear_trap_clamp.m4a`           | Replace `_play_sound("trap_spike")`             |
| Generated tone SFX for "trap_fire"   | (fire_trap.png has visual only) | Keep generated or find fire SFX                 |
| Generated tone SFX for "turret_shoot"| `turret_crank.m4a`              | Replace `_play_sound("turret_shoot")`           |
| Generated tone SFX for catapult      | `cannon_fire.m4a`               | Replace catapult fire sound                     |
| Generated procedural music loop      | `battle_ambience.mp3`           | Replace `_setup_music()` / `_update_music()` with AudioStreamPlayer |
| No main menu music                   | `menu_theme.mp3`                | Add to main menu scene                          |
| Polygon2D turret visuals             | `turret_face.png`               | Replace `_create_turret_visual()` with Sprite2D |
| Polygon2D turret projectile tracer   | `turret_bullet.png`             | Replace tracer Line2D with projectile sprite    |
| Polygon2D trap visuals               | `bear_trap.png`, `fire_trap.png`| Replace `_create_trap_visual()` with AnimatedSprite2D |
| Polygon2D catapult visual            | `artillery.png`                 | Replace `_create_catapult_visual()` with Sprite2D |
| Polygon2D castle wall band           | `wall_level1/2/3.png` + `wall_battlement.png` | Replace wall Polygon2D with TextureRect, swap on upgrade |
| Single goblin.png for all enemies    | 5 goblin variants + frost pack  | Map enemy types to different sprites            |
| Tinted goblin for boss               | `goblin_king_sheet.png`         | New boss AnimatedSprite2D with full anims       |
| No mech boss                         | `goblin_mech_sheet.png`         | New boss type (wave 10+ alternating boss)       |
| Programmatic shop panel              | `shop_building.png` + awnings   | Replace/overlay shop area with sprite           |
| Built-in main menu in Level.tscn     | Dedicated MainMenu scene        | New scene, change project main_scene            |

---

### NEW CONTENT OPPORTUNITIES (What's Not Currently In Game)

| Asset                                | New Feature                                    | Priority |
|--------------------------------------|------------------------------------------------|----------|
| 5 Goblin variants ($Goblin_1-5)     | Visual variety per enemy type (grunt/runner/shield/armored/ranged) | HIGH |
| Frost Goblins (small + large)        | New "Frost" enemy type or winter-themed wave   | MEDIUM   |
| Goblin King sprite sheet             | Proper boss with unique attack animations       | HIGH     |
| Goblin Mech Rider sprite sheet       | Second boss type for higher waves              | HIGH     |
| Wall level progression art           | Visual wall upgrades (matches wall_level 1/2/3) | HIGH     |
| Shop building sprite                 | Replace the bland shop zone with a real building | MEDIUM   |
| Shop awning animation                | Open/close animation when player enters shop   | LOW      |
| Shadow.png for goblins               | Drop shadows under all enemies                 | LOW      |
| Separate main menu scene             | Clean game flow: MainMenu -> Level -> GameOver | HIGH     |

---

### ENEMY VARIANT MAPPING (Recommended)

| Enemy Type   | Sprite Source               | Notes                                           |
|--------------|-----------------------------|-------------------------------------------------|
| **Grunt**    | `$Goblin_1.png`            | Basic green, no gear - baseline enemy            |
| **Runner**   | `$Goblin_3.png`            | Jester hat, colorful - looks fast/chaotic        |
| **Ranged**   | `$Goblin_4.png`            | Armed goblin - suits ranged attacker             |
| **Shield**   | `$Goblin_5.png`            | Carries shield - perfect match                   |
| **Armored**  | `$Goblin_2.png`            | Helmet/armor - tanks damage                      |
| **Tank**     | `Large_Frost_Goblin_*.png` | Big frost goblins - visually large + tanky       |
| **Elite**    | `Frost_Goblin_*.png`       | Small frost variants - elite reskin              |
| **Boss (1)** | `goblin_king_sheet.png`    | Boss waves 5, 15, 25... Full animation set       |
| **Boss (2)** | `goblin_mech_sheet.png`    | Boss waves 10, 20, 30... Mechanical boss         |

---

### WALL UPGRADE VISUAL MAPPING

| wall_level | Asset                    | Visual                                 |
|------------|--------------------------|----------------------------------------|
| 1          | `wall_level1.png`        | Basic rough stone blocks               |
| 2          | `wall_level2.png`        | Fortified: battlements + boiling oil   |
| 3          | `wall_level3.png`        | Royal: battlements + kingdom banner    |
| strip      | `wall_battlement.png`    | Repeating battlement for full wall width |

---

## BLOCKERS / ACTION ITEMS

### Must Do Before Assets Work in Godot:
1. **Convert .m4a to .ogg** - Install ffmpeg, then:
   ```bash
   ffmpeg -i arrow_launch.m4a arrow_launch.ogg
   ffmpeg -i bear_trap_clamp.m4a bear_trap_clamp.ogg
   ffmpeg -i goblin_death.m4a goblin_death.ogg
   ffmpeg -i cannon_fire.m4a cannon_fire.ogg
   ffmpeg -i turret_crank.m4a turret_crank.ogg
   ```
   MP3 files (menu_theme, battle_ambience, arrow_whistle) work as-is in Godot 4.

2. **Grass Tiles.rar** - Couldn't extract (rar format). Contains grass tiles that could improve the battlefield ground. Low priority since fantasy_tileset already has grass.

3. **Goblin sprite sheets are grid-based (4 dir x 3 frames)** - The individual $Goblin PNGs have 12 frames in a 3x4 grid (3 columns x 4 rows = down/left/right/up facing, 3 frames each). Need to set up AtlasTexture slicing.

4. **Goblin King sheet is irregular** - Rows have different frame counts. Will need manual atlas region definitions per animation.

5. **Goblin Mech sheet is cleaner** - Roughly 5 rows x 8 columns. Easier to slice programmatically.

---

## INTEGRATION PRIORITY (Recommended Order)

1. **Real audio** - Replace procedural tones with actual SFX/music (biggest quality jump)
2. **Wall upgrade visuals** - Swap Polygon2D walls with sprite art per wall_level
3. **Enemy variety sprites** - Map the 5 goblin variants to enemy types
4. **Turret/trap sprites** - Replace Polygon2D defenses with real art
5. **Boss sprites** - Goblin King and Mech Rider with proper animations
6. **Main menu scene** - Separate scene with dedicated music
7. **Shop visuals** - Building sprite + awning animation
8. **Frost goblin wave** - New enemy type or elite reskin

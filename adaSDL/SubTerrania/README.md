# SubTerrania

SubTerrania is an Ada/SDL game project with a separate native GtkAda editor.

The current design treats the **editor as the primary tool**. The game runtime reads the data produced by the editor: levels, player definitions, enemies, bosses, weapons, powerups, triggers, objectives, and audio references.

## Project layout

```text
SubTerrania/
  alire.toml
  subterrania.gpr              # SDL game runtime project
  subterrania_editor.gpr       # native GtkAda editor project

  src/
    core/                      # SDL game application shell
    ecs/                       # existing ECS components and systems
    editor/                    # native GtkAda editor

  assets/
    levels/                    # level files, such as stage01.map
    ui/                        # GtkBuilder UI files
    images/
      maps/
      sprites/
      ui/
    audio/
      music/                   # local only, ignored by Git
      sfx/                     # local only, ignored by Git

  tools/
    build_all.sh
    build_editor.sh
    run_editor.sh
    check_editor_requirements.sh
```

## Requirements

On Kubuntu/Ubuntu:

```bash
sudo apt install libgtk-3-dev
```

Alire should install the Ada dependencies:

```bash
alr with gtkada
alr with sdlada
```

Check the editor requirements:

```bash
tools/check_editor_requirements.sh
```

## Build

Build the SDL game:

```bash
alr build
```

Build the native editor:

```bash
tools/build_editor.sh
```

Build both:

```bash
tools/build_all.sh
```

## Run

Run the SDL game:

```bash
alr run
```

Run the native editor:

```bash
tools/run_editor.sh
```

The SDL game's **FULL MAP EDITOR** menu item is intended to launch the native editor.

## Editor overview

The editor is organized like a professional content tool instead of a gameplay overlay.

Main areas:

```text
Top menu       File / Edit / View / Project / Test / Help
Toolbar        New / Open / Save / tools / grid / playtest / build
Left panels    Project tree, palette, layers
Center         Map canvas
Right panels   Inspector and level properties
Bottom         Timeline, output, notes, minimap
```

## Suggested editor workflow

1. Open the editor:

   ```bash
   tools/run_editor.sh
   ```

2. Load or create a level.

3. Use the palette to choose terrain or objects.

4. Place or select items on the map canvas.

5. Use the right-side inspector to edit the selected item.

6. Set level metadata such as title, background, music, boss music, and next level.

7. Save the project assets.

8. Use Playtest or run the SDL game.

## Editor workspaces

The long-term editor model is one application with multiple workspaces:

```text
Level Editor       terrain, collision, water, landing pads, starts, map objects
Player Editor      player ship physics, sprite, shield, fuel, audio, weapon slots
Enemy Editor       reusable enemy templates and ECS components
Boss Editor        phases, paths, timing, attacks, music, gates, damage states
Weapon Editor      projectiles, damage, cooldown, charge, sounds
Powerup Editor     pickup effects, pickup sounds, temporary effects
Audio Editor       music and sound references
Trigger Editor     conditions and actions
Objective Editor   mission goals and completion rules
Build/Test         build, run, playtest current level
```

## ECS design goal

The editor should create reusable **entity templates** made of ECS components.

Example:

```text
Enemy_Scout
  Transform
  Renderable
  Collider
  Velocity
  Health
  Weapon
  AI_Patrol
  Audio_Source
```

A level places instances of those templates.

## Audio design

Audio files should be referenced by data, not hardcoded in Ada.

Examples:

```text
LEVEL
NAME STAGE01
TITLE MISSION 1
MUSIC assets/audio/music/mission01.mp3
BOSS_MUSIC assets/audio/music/boss01.mp3
```

```text
SHIP RescueShip01
ENGINE_THRUST_SOUND assets/audio/sfx/ship/thrust.wav
SHIELD_HIT_SOUND assets/audio/sfx/shields/hit.wav
EXPLODE_SOUND assets/audio/sfx/ship/explode.wav
```

```text
WEAPON Laser
FIRE_SOUND assets/audio/sfx/weapons/laser_fire.wav
HIT_SOUND assets/audio/sfx/weapons/laser_hit.wav
CHARGE_SOUND assets/audio/sfx/weapons/laser_charge.wav
```

```text
POWERUP ShieldRecharge
PICKUP_SOUND assets/audio/sfx/pickups/shield.wav
EFFECT ADD_SHIELD 25
```

## Copyrighted audio

Do not commit copyrighted music or sound files.

The repository should ignore:

```gitignore
assets/audio/**/*.mp3
assets/audio/**/*.wav
assets/audio/**/*.ogg
assets/audio/**/*.flac
```

Commit placeholder `.keep` files only.

## Current status

The native editor builds and opens after the Phase 11 runtime fixes. Some behavior is still being stabilized:

- Save and Playtest need null-safe UI lookups.
- Grid rendering needs to preserve pan and zoom.
- Minimap placement needs to remain stable.
- Toolbar/menu behavior needs cleanup.
- The editor needs real data editing for each workspace.


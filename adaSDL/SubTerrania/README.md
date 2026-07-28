# SubTerrania

SubTerrania is an Ada/SDL game project with a separate GtkAda content editor.
The editor is intended to become the source of truth for levels, entity
instances, reusable definitions, paths, objectives, and audio references.

## Build and run

```bash
# SDL game
alr build
alr run

# GtkAda editor
tools/build_editor.sh
tools/run_editor.sh

# Build both
tools/build_all.sh
```

On Ubuntu/Kubuntu the editor requires GTK 3 development packages:

```bash
sudo apt install libgtk-3-dev
```

## Phase 13 editor layout

The editor was rewritten around the workflow used by RPG Maker-style tools.
The map stays central. Complicated data is moved into focused windows instead
of permanently surrounding the canvas.

```text
Main window
  Menu and icon toolbar
  Palette and layer controls on the left
  Project resources below the palette
  Large map canvas in the center
  Compact output and status information at the bottom

Focused windows
  Object Properties
  Level Properties
  Database
```

The Database is opened with the gear icon and contains:

```text
Player Ships
Enemies
Bosses
Weapons
Pickups
Platforms
Destructibles
Animations
Audio
Objectives
Project Settings
```

Database files are stored in `assets/database/` as readable key/value files.
They are editor data and a foundation for later runtime integration.

## Main controls

```text
Middle mouse drag     Pan from any mode
Pan tool + left drag  Pan
Mouse wheel           Zoom at the cursor
Zoom toolbar buttons  Zoom in/out
Fit                    Fit the complete level
Home                   Center near the Start/Base tile
Right click            Cancel the current canvas operation
```

### Map editing

1. Select the **Map** mode.
2. Choose Wall, Water, Landing Pad, Start/Base, or Clear Tile.
3. Click the map to paint.

### Object editing

1. Select the **Object** mode.
2. Choose Miner, Enemy, Platform, Gate, Boss Spawn, or a pickup.
3. Click to place an instance.
4. Choose Select and click the instance.
5. Open **Object Properties** from the toolbar or Edit menu.
6. Rename the instance or change its position and size.

### Motion paths

1. Select a placed object.
2. Choose **Path** mode or open Object Properties and choose
   **Edit Selected Object Path**.
3. The banner names the object whose path is being edited.
4. If the object has no route, choose **Create Simple Path** or Ctrl-click
   the canvas. START and END are created slightly apart.
5. Left-click a node to select it and left-drag it to move it.
6. Ctrl-click a dashed segment to insert an intermediate waypoint.
7. Ctrl-right-click a node to open its numeric properties. Intermediate
   waypoints can be deleted; START and END cannot.
8. Press **Enter** or choose **Finish Path** to keep the changes.
9. Press **Escape** or choose **Cancel** to restore the previous path.

The map is the primary path-editing interface. Numeric position and arrival
values are secondary controls. Segment timing, interpolation, and live motion
preview remain follow-up work.

## Layers

The Layers tab controls editor visibility for:

```text
Background
Terrain / Collision
Water
Pickups
Destructibles
Platforms
Miners
Enemies / Bosses
Triggers / Bases
Paths / Debug
```

The destructible layer is present as an architectural slot. The current
`Level.Object_Kind` does not yet include a destructible instance type. Runtime
support for hiding a pickup under a pixel-eroded destructible is still pending.

## Level properties

Level Properties defines:

```text
Internal stage name
Display title
Next level
Background image
Level music
Boss music
```

Audio files are referenced by path. The current SDL audio package still uses
hooks/stubs and does not yet decode the soundtrack files.

## Project layout

```text
src/editor/                   GtkAda editor source
src/ecs/systems/level.*       current level format shared with the game
assets/ui/                    GtkBuilder UI
assets/levels/                maps and editor sidecar metadata
assets/database/              reusable template/configuration data
assets/images/                map and sprite assets
assets/audio/                 local audio, ignored by Git
docs/                         design and workflow notes
```

## Copyrighted audio

Do not commit copyrighted music or sound files. Keep these patterns in
`.gitignore`:

```gitignore
assets/audio/**/*.mp3
assets/audio/**/*.wav
assets/audio/**/*.ogg
assets/audio/**/*.flac
```

## Current boundary

Phase 13 is a UI and workflow rewrite. It preserves the SDL game and existing
level format. It does not yet make every Database field affect gameplay.
Runtime synchronization should follow only after the editor workflow has been
validated.

## Capability roadmap

The comprehensive grouped editor capability plan is in:

```text
docs/MAP_EDITOR_CAPABILITIES.md
```

## Phase 13B runtime sync

Editor-created motion paths now run in the SDL game. The runtime reads the
level's `.map.editor` sidecar when the main `.map` file loads. MP3/Ogg/WAV/FLAC
music playback uses SDL2_mixer, and the game uses the level's `MUSIC` field.

```bash
sudo apt install libsdl2-mixer-dev
tools/check_phase13b_runtime.sh
alr build
alr run
```

See `docs/PHASE13B_RUNTIME_SYNC.md` for path timing and audio details.

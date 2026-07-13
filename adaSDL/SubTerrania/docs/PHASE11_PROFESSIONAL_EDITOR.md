# Phase 11 — Professional Native Editor

## Why this phase replaces the SDL editor overlay

The game runtime remains SDL-based. The editor is now a separate GtkAda
application because a desktop editor needs native menus, toolbars, notebooks,
file dialogs, panels, text fields, lists, and resizable split panes. Drawing all
of those controls manually in SDL caused the overlapping, hard-to-read UI from
the earlier phases.

The old SDL editor code remains temporarily so the game still builds while the
native editor is validated. The game menu item **FULL MAP EDITOR** launches the
new editor.

## Editor layout

The native editor follows the mockup workflow:

- real File, Edit, View, Project, Test, and Help menus;
- toolbar with New, Open, Save, Undo, Redo, Select, Brush, Erase, Pan, Grid,
  Fit Map, Playtest, and Build;
- left notebook for Project, Palette, and Layers;
- central document notebook for the map and project definitions;
- right inspector for level and selected-entity properties;
- bottom Timeline, Output, and Notes tabs;
- live minimap at the bottom right;
- status bar showing the current tool and brush.

## Functional map workflow

- Mouse wheel: zoom.
- Background drag: pan.
- Select tool: select and move object instances.
- Brush tool: paint the chosen tile.
- Object palette: place an entity instance.
- Erase tool: remove an object or clear a terrain tile.
- Right-click the map: cancel the current brush and return to Select.
- Grid can be toggled from the menu or toolbar.
- Fit Map frames the complete level.
- Fullscreen is available under View.

The map canvas and minimap use GtkAda Canvas_View. The background image, terrain
overlay, entity instances, selection, movement, zooming, and panning are kept in
editor code rather than in the game renderer.

## Project documents

The Project panel and Project menu open dedicated documents:

- Level Settings: stage ID, title, next stage, map image, level music, boss
  music.
- Player Ship: sprite, thrust, drag, fuel, shield, ship sounds, weapon slots.
- Enemy Template: behavior, health, weapon, fire rate, ECS components.
- Boss / Encounter: health, trigger, music, phases, paths, timing, attacks,
  damage-state animations.
- Weapon: damage, cooldown, projectile speed, charge states and sounds.
- Powerup: value, duration, effect and pickup sound.
- Audio: main-menu, level and boss music assignments.
- Triggers / Objectives: condition/action and mission-goal definitions.

Saving writes the level file and the current project definition files under
`assets/entities`, `assets/weapons`, `assets/powerups`, and `assets/config`.
These text files are intended to become the data consumed by the ECS runtime.

## Build and run

From the project root:

```bash
sudo apt install libgtk-3-dev
unzip ~/Downloads/subterrania_phase11_professional_native_editor.zip -d .
tools/apply_phase11_professional_editor.sh
tools/build_all.sh
tools/run_editor.sh
```

The SDL game remains:

```bash
alr run
```

The native editor is:

```bash
tools/run_editor.sh
```

## Copyrighted local audio

Audio assignments are paths only. Music and sound files remain local. The
project `.gitignore` excludes MP3, WAV, OGG, and FLAC files below
`assets/audio/`.

Commit the directories and `.keep` files, but not copyrighted soundtrack files.

## Scope

This phase is the architectural replacement for the debug overlay and provides
an actual native editor application. The map workflow, menus, panel layout,
project documents, save/load, undo/redo, pan/zoom, minimap, playtest and build
hooks are implemented.

The boss timeline and trigger/objective documents currently save structured
project data; the runtime execution of every boss animation, trigger action, and
weapon behavior remains later game-engine work. That distinction keeps editor
construction separate from gameplay implementation.

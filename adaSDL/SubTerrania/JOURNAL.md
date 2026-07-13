# SubTerrania Development Journal

This journal records the major editor/game errors encountered during the Phase 10C / Phase 11 transition and how they were addressed.

## Phase 10C: SDL editor overlay was not enough

**Problem:** The in-game SDL editor overlay had buttons for Boss, Ship, Weapon, Audio, and other workspaces, but they did not feel like professional editor tools. The UI still looked like a debug overlay drawn on top of the game.

**Decision:** Stop treating the SDL runtime as the main editor. Keep SDL for the game, and create a separate native editor application.

**Fix:** Phase 11 introduced a native GtkAda editor project:

```text
subterrania_editor.gpr
src/editor/
assets/ui/subterrania_editor.ui
```

The goal is to make the editor closer to tools like RPG Maker, GameMaker, Blender, or Tiled: menus, toolbar, panels, inspector, timeline, minimap, and a central canvas.

## Phase 11: GtkAda dependency setup

**Problem:** The project needed a native GUI library for a real editor.

**Fix:** Added GtkAda as an Alire dependency and installed GTK3 development files:

```bash
alr with gtkada
sudo apt install libgtk-3-dev
```

The dependency install succeeded, and the SDL game still built successfully.

## Error: Ada reserved word `entry` in `editor_app.adb`

**Symptom:**

```text
editor_app.adb:10:10: error: reserved word "entry" cannot be used as identifier
editor_app.adb:243:07: error: reserved word "entry" cannot be used as identifier
```

**Cause:** Ada reserved words are case-insensitive. `Entry` and `entry` are both illegal identifiers. The original editor code used `Gtk.Entry` and/or a local variable named `Entry`.

**Fix:** Replaced the illegal usage with GtkAda's `Gtk.GEntry` package and renamed local variables that used `Entry`.

## Error: Ada reserved word `entry` in `editor_canvas.adb`

**Symptom:**

```text
editor_canvas.adb:9:10: error: reserved word "entry" cannot be used as identifier
```

**Cause:** The same reserved-word mistake existed in the canvas source file.

**Fix:** Replaced `Gtk.Entry` with `Gtk.GEntry` in `editor_canvas.adb` too.

## Runtime error: GtkBuilder could not load `<packing>` tags

**Symptom:**

```text
Could not load assets/ui/subterrania_editor.ui
assets/ui/subterrania_editor.ui:202:27 Unhandled tag: <packing>
```

**Cause:** The generated GtkBuilder XML used `<packing>` tags that this GtkAda/GtkBuilder path did not accept.

**Fix:** Rewrote `assets/ui/subterrania_editor.ui` without `<packing>` tags, using a safer layout that GtkAda could load.

## Runtime error: `editor_app.adb:245 access check failed`

**Symptom:**

```text
raised CONSTRAINT_ERROR : editor_app.adb:245 access check failed
```

**Cause:** `editor_app.adb` tried to access UI entry widgets that were not present in the `.ui` file. A null widget reference caused an access check failure.

**Fix:** Added the missing widget IDs to the UI file and made entry loading safer so future missing fields warn instead of crashing immediately.

Examples of missing fields that were added:

```text
player_drag_entry
player_shield_hit_entry
player_shield_low_entry
enemy_fire_rate_entry
boss_trigger_entry
weapon cooldown/speed/charge/sound entries
menu_music_entry
```

## Runtime error: `editor_canvas.adb:284 access check failed`

**Symptom:**

```text
raised CONSTRAINT_ERROR : editor_canvas.adb:284 access check failed
```

**Cause:** `editor_canvas.adb` tried to update status labels that were missing from the `.ui` file.

**Fix:** Added missing labels:

```text
selected_name_label
selected_type_label
tool_status_label
```

The editor opened after these widgets were added.

## Runtime error: Save and Run Game crashed at `editor_app.adb:202`

**Symptom:**

```text
raised CONSTRAINT_ERROR : editor_app.adb:202 access check failed
```

**Cause:** Save and Playtest shared project-save logic. That logic referenced boss path/timing widgets that were missing or not null-checked.

**Fix:** Added missing path fields and made save/playtest safer.

Fields added:

```text
path1_x
path1_y
path1_t
path2_x
path2_y
path2_t
```

## Issue: minimap appeared in the wrong place on startup

**Symptom:** The minimap initially appeared near the upper-left and later moved toward the lower-right.

**Likely cause:** The minimap widget was being laid out without a stable size request or was being affected by early GTK allocation timing.

**Fix direction:** Give the minimap a fixed size request and keep it in a stable bottom-right panel instead of allowing it to float based on initial layout quirks.

## Issue: grid vanished after panning the map

**Symptom:** Grid was visible at first, but after moving the map the grid disappeared.

**Likely cause:** The grid was rebuilt as canvas objects in a way that did not preserve the current viewport or did not remain tied correctly to the world/map coordinate layer.

**Fix direction:** Rebuild the grid as stable map-layer objects and preserve the visible map area when toggling grid visibility.

## Issue: toggling grid snapped the map back to center

**Symptom:** Turning the grid back on recentered the map image.

**Cause:** Rebuilding the canvas reset the view instead of preserving pan/zoom.

**Fix direction:** Store visible area/pan/zoom before rebuilding the canvas and restore it afterward.

## Current design conclusion

The editor should be the main long-term product. The game runtime should consume the editor's data.

The editor should eventually support:

```text
Level editing
Player ship editing
Enemy template editing
Boss/encounter editing
Weapon editing
Powerup editing
Audio assignment
Trigger/action editing
Objective editing
Build/playtest tools
```

The first goal is not more gameplay. The first goal is a stable professional editor workflow.

## Phase 11 - Log helper compile failure

**Symptom**

`tools/build_editor.sh` failed with:

```text
editor_app.adb:66:10: error: "Log" is undefined
```

**Cause**

A stability patch added defensive logging calls named `Log (...)`, but
`editor_app.adb` did not define a `Log` procedure.

**Fix**

The unqualified `Log (...)` calls were replaced with
`Ada.Text_IO.Put_Line (...)`, and `with Ada.Text_IO;` was added to the file.

**Note**

If `tools/build_editor.sh` fails and `tools/run_editor.sh` is run afterward as
a separate command, the old previously-built editor binary may still launch.
Use `tools/build_editor.sh && tools/run_editor.sh` when testing changes.


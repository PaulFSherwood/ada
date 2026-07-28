# SubTerrania Editor Capability Plan

The editor's goal is to let a designer build, configure, validate, and
playtest SubTerrania-style content without changing Ada source code. The map
editor places level instances. The Database defines reusable player, enemy,
boss, weapon, pickup, platform, destructible, animation, audio, and objective
templates.

Status terms:

- **Current**: present in the Phase 13 editor foundation.
- **Next**: part of the immediate editor roadmap.
- **Planned**: intended after the core workflow is stable.

## 1. Project and file management

- **Current** Create, open, save, and save-as level files.
- **Current** Keep editor-only metadata in a sidecar file.
- **Current** Open Stage01 from the project area.
- **Current** Maintain separate game and editor executables.
- **Current** Build and playtest commands.
- **Next** Real level/project tree with multiple levels.
- **Next** Create, duplicate, rename, reorder, and delete levels.
- **Next** Recent-project and recent-level lists.
- **Next** Autosave and crash-recovery copies.
- **Next** Dirty-document indicators.
- **Next** Project-wide search for objects, templates, and references.
- **Planned** Import/export level packages.
- **Planned** Project templates and example levels.
- **Planned** Migration/versioning for older level formats.

## 2. Main map editing

- **Current** Display a level background image.
- **Current** Paint wall, water, landing, start/base, and empty tiles.
- **Current** Place basic object instances.
- **Current** Select map tiles and placed objects.
- **Current** Delete selected tiles or objects.
- **Current** Fit the entire map and center on the start location.
- **Next** Rectangle, line, flood-fill, eyedropper, and selection tools.
- **Next** Copy, cut, paste, duplicate, and multi-select.
- **Next** Drag selected objects.
- **Next** Marquee selection and selection filters.
- **Next** Snap settings independent of grid visibility.
- **Next** Configurable map dimensions and tile size.
- **Next** Map bounds and out-of-bounds warnings.
- **Planned** Prefabs/groups for repeated structures.
- **Planned** Stamp brushes and reusable room chunks.
- **Planned** Optional procedural cave/room generation.

## 3. Navigation and viewport

- **Current** Mouse-wheel zoom.
- **Current** Middle-mouse drag panning.
- **Current** Pan-tool left drag.
- **Current** Preserve pan/zoom when rebuilding the canvas.
- **Current** Grid visibility toggle.
- **Next** Zoom toward the cursor consistently.
- **Next** Keyboard panning and configurable shortcuts.
- **Next** 1:1 zoom and preset zoom percentages.
- **Next** Bookmarks for important map locations.
- **Next** Custom minimap with current viewport rectangle.
- **Next** Click/drag minimap navigation.
- **Next** Hide/show overlays without changing edit mode.
- **Planned** Multiple synchronized map views.

## 4. Layers

- **Current** Visibility slots for background, terrain, water, pickups,
  destructibles, platforms, miners, enemies, triggers, and paths.
- **Next** Real ordered layer stack.
- **Next** Per-layer visibility, locking, and selectability.
- **Next** Add, rename, duplicate, reorder, and delete custom layers.
- **Next** Set the active placement layer.
- **Next** Move selected instances between layers.
- **Next** Layer opacity and tint for debugging.
- **Next** Solo one layer and hide all others.
- **Next** Layer-specific collision and gameplay flags.
- **Planned** Layer groups and folders.
- **Planned** Parallax/background layers.

## 5. Terrain, collision, and environmental zones

- **Current** Wall/collision tiles.
- **Current** Water tiles.
- **Current** Landing tiles.
- **Current** Start/base location.
- **Next** Separate visual terrain from collision data.
- **Next** One-way surfaces and landing-only surfaces.
- **Next** Hazard surfaces such as lava, acid, electricity, or crushing zones.
- **Next** Destructible terrain masks.
- **Next** Physics zones for gravity, drag, current, wind, and buoyancy.
- **Next** Water properties such as gravity modifier and movement resistance.
- **Next** Damage zones and safe zones.
- **Next** Terrain material properties and impact sounds.
- **Planned** Slopes, curved boundaries, and polygon collision.
- **Planned** Animated environmental tiles.

## 6. Placed objects and instances

- **Current** Place miners, enemies, platforms, gates, boss spawns, fuel,
  shields, and powerups.
- **Current** Generate readable names such as Platform_01 and Enemy_02.
- **Current** Edit instance name, position, width, and height.
- **Current** Keep reusable definitions separate in the Database.
- **Next** Choose a template when placing an instance.
- **Next** Show sprite/icon previews in the palette.
- **Next** Instance-specific overrides without changing the template.
- **Next** Rotation, scale, pivot, and anchor settings.
- **Next** Parent/child and attached-object relationships.
- **Next** Group, align, distribute, and lock objects.
- **Next** Search/filter objects by name, type, layer, or component.
- **Next** Reference warnings when deleting a linked object.
- **Planned** Prefab variants and inherited templates.

## 7. Motion paths

- **Current** A path belongs to the selected object.
- **Current** The banner identifies the object being edited.
- **Current** START, intermediate waypoint, and END labels.
- **Current** Dashed route segments.
- **Current** Left-click selects a node.
- **Current** Left-drag moves a node.
- **Current** Ctrl-click a dashed segment to insert a waypoint.
- **Current** If no path exists, create START and END slightly apart.
- **Current** Ctrl-right-click a node opens its properties.
- **Current** Intermediate waypoints can be deleted; START and END remain.
- **Current** Enter finishes path editing; Escape restores the old path.
- **Current** Edit node position and arrival time numerically when needed.
- **Next** Segment selection and per-segment travel time.
- **Next** Straight, smooth, arc, and snap interpolation.
- **Next** Once, loop, and ping-pong playback.
- **Next** Pause/wait at a waypoint.
- **Next** Preview the moving object directly in the editor.
- **Next** Direction arrows and speed visualization.
- **Next** Start conditions: immediate, trigger, proximity, or objective state.
- **Next** Path copying, reversing, mirroring, and reusing.
- **Planned** Bezier handles for advanced curves.
- **Planned** Branching paths and conditional route changes.

## 8. Triggers, events, and actions

- **Current** Trigger mode foundation.
- **Next** Rectangle, circle, line, and object-bound trigger regions.
- **Next** Trigger on enter, exit, touch, landing, destruction, pickup, timer,
  weapon hit, objective change, or custom signal.
- **Next** Conditions using switches, counters, inventory, health, fuel,
  rescued miners, boss phase, or object state.
- **Next** Actions such as spawn, destroy, enable, disable, move, animate,
  play audio, change music, open gate, change gravity, or start encounter.
- **Next** Ordered event/action list similar to an event-command editor.
- **Next** Wait, repeat, branch, and random-choice actions.
- **Next** Named switches, variables, and signals.
- **Next** Validation for broken references and event loops.
- **Planned** Optional scripting for behavior not expressible as data.

## 9. Objectives and mission flow

- **Current** Objective Database foundation.
- **Next** Rescue a required number of miners.
- **Next** Return rescued miners to a selected base.
- **Next** Destroy required targets.
- **Next** Collect or deliver required items.
- **Next** Survive for a duration.
- **Next** Reach or land in a defined zone.
- **Next** Defeat a boss or encounter.
- **Next** Protect an object or miner.
- **Next** Required, optional, hidden, and bonus objectives.
- **Next** Objective prerequisites and ordering.
- **Next** Success/failure actions and next-level routing.
- **Next** Objective text, briefing text, and progress display.
- **Next** Validation that referenced miners, bases, items, and targets exist.

## 10. Database and reusable templates

- **Current** Separate Database window.
- **Current** Categories for player ships, enemies, bosses, weapons, pickups,
  platforms, destructibles, animations, audio, objectives, and project data.
- **Current** Readable key/value database files.
- **Next** Definition lists with add, copy, rename, delete, and reorder.
- **Next** Search/filter definitions.
- **Next** Image, sprite, sound, and animation pickers.
- **Next** ECS component list with add/remove/configure operations.
- **Next** Template inheritance and instance overrides.
- **Next** Usage/reference browser showing which levels use a definition.
- **Next** Validation and default-value reset.
- **Planned** Import/export template libraries.

## 11. Player ship editor

- **Current** Player Database foundation.
- **Next** Name, sprite, collision shape, animation set, and spawn behavior.
- **Next** Thrust, rotation, drag, gravity response, and maximum speed.
- **Next** Fuel capacity, fuel usage, and unlimited-fuel state.
- **Next** Shield capacity, recharge, hit behavior, and break behavior.
- **Next** Cargo/miner capacity and weight effects.
- **Next** Primary, secondary, and special weapon slots/fire groups.
- **Next** Engine, thrust, collision, shield, weapon, pickup, and explosion sounds.
- **Next** Idle, thrust, shield, damage, death, and pickup animations.
- **Next** Damage states and visual effects.
- **Next** Starting inventory and permanent upgrades.
- **Planned** Multiple selectable player ships.

## 12. Enemy editor

- **Current** Enemy Database foundation.
- **Next** Name, sprite, collision, health, damage, and ECS components.
- **Next** Flying, walking, stationary, ceiling, wall, jumping, or swimming
  movement types.
- **Next** Idle, flying, walking, attack, hit, and death animations.
- **Next** Motion path or autonomous movement.
- **Next** Player detection range and field/arc of view.
- **Next** Fire only when the player is above-left, above-right, horizontal,
  below, near, or within a configurable angle.
- **Next** Straight, aimed, random, spread, arc, dripping, homing, and gravity-
  affected projectile patterns.
- **Next** Fire rate, burst size, warmup, cooldown, and ammunition rules.
- **Next** Patrol, chase, retreat, guard, ambush, swarm, and flee behaviors.
- **Next** Drops, score/reward, sounds, and death actions.
- **Next** Variants for turrets, flying aliens, acid droppers, walker bots,
  howitzers, Beedles, and other level-specific enemies.
- **Planned** Behavior trees or state-machine graph editor.

## 13. Boss and encounter editor

- **Current** Boss Database and boss-spawn foundation.
- **Next** Boss name, sprite/body layout, health, collision, music, and arena.
- **Next** Multiple animated body parts such as arms, tentacles, beaks, faces,
  legs, turrets, or attached weapons.
- **Next** Idle, walking, attack, hit, transition, and death animations.
- **Next** Cardinal and path-based movement.
- **Next** Reuse all enemy detection, movement, and weapon behaviors.
- **Next** Health-, time-, objective-, and event-based phases.
- **Next** Per-phase movement, animation, weapon, vulnerability, and music.
- **Next** Attack timelines, cooldowns, summons, and environmental actions.
- **Next** Damage states and destructible body parts.
- **Next** Entrance, arena lock, victory, cleanup, and reward actions.
- **Next** Focused encounter preview/test.
- **Planned** Timeline and state-machine visualization.

## 14. Platforms, hazards, and attached mechanisms

- **Current** Platform instances and paths.
- **Next** Landable, non-landable, one-way, and crushing platforms.
- **Next** Movement paths with curves, pauses, loops, and triggers.
- **Next** Crush detection against terrain or another platform.
- **Next** Falling, collapsing, rotating, swinging, or extending platforms.
- **Next** Pendulum and attached-object joints.
- **Next** Laser repeaters/mirrors that redirect or reflect special weapons.
- **Next** Gates, doors, pistons, crushers, lifts, and timed hazards.
- **Next** Activation by trigger, shot, item, switch, or objective.
- **Planned** Basic joint/constraint preview in the editor.

## 15. Destructible objects

- **Current** Destructible Database and layer slot.
- **Next** Place destructible instances over pickups or passageways.
- **Next** Pixel/mask erosion similar to defense-block destruction.
- **Next** Damage brushes by projectile type and explosion radius.
- **Next** Remaining-pixel percentage and configurable final-destruction
  threshold such as 75 percent removed.
- **Next** Reveal or unlock covered objects when enough material is gone.
- **Next** Explosion animation, particles, debris, and sounds.
- **Next** Indestructible pixels/material regions.
- **Next** Weapon/material damage rules.
- **Next** Editor preview and reset of the destruction mask.
- **Planned** Runtime persistence of partially destroyed masks.

## 16. Miners and other NPCs

- **Current** Miner placement.
- **Next** Walking/idle animations.
- **Next** Patrol region or short left-right path.
- **Next** Detect a landed player ship nearby.
- **Next** Walk to the ship and board it.
- **Next** Boarded, rescued, delivered, killed, and stranded states.
- **Next** Capacity limits and boarding order.
- **Next** Rescue and return-to-base objective integration.
- **Next** Voice, alert, boarding, and rescue sounds.
- **Next** Optional NPC dialogue/event actions.

## 17. Pickups and items

- **Current** Fuel, shield, and generic powerup placement.
- **Next** Missiles, red laser, blue laser, green laser, Mega Shot, Tube Bomb,
  Mirror Laser, Nuclear Crystal, fuel, shield, and mission items.
- **Next** Idle/glow animation and collected/used visual state.
- **Next** Pickup sound and one-shot effect animation.
- **Next** Permanent, consumable, ammunition, key, and mission-item types.
- **Next** Hidden/covered state linked to a destructible object.
- **Next** Respawn, one-use, campaign-persistent, and conditional availability.
- **Next** Inventory limits and replacement rules.
- **Next** Item description and editor preview.

## 18. Weapons and projectiles

- **Current** Weapon Database foundation.
- **Next** Red laser: forward shot affected by gravity.
- **Next** Blue laser: forward and side shots.
- **Next** Green laser: wider forward range with homing.
- **Next** Missiles for heavy targets and fortified structures.
- **Next** Mega Shot charge while idle and multidirectional release.
- **Next** Tube Bomb behavior for restricted blast doors.
- **Next** Mirror Laser reflection/repeater behavior.
- **Next** Projectile sprite, animation, collision, damage, speed, lifetime,
  gravity, homing, spread, ricochet, piercing, and explosion.
- **Next** Friendly-fire and protected-object rules.
- **Next** Fire, charge, travel, impact, and explosion sounds.
- **Next** Weapon preview/test range.
- **Planned** Visual projectile-pattern editor.

## 19. Animation and visual effects

- **Current** Animation Database foundation.
- **Next** Sprite-sheet import and frame slicing.
- **Next** Frame duration, loop, ping-pong, and one-shot playback.
- **Next** Named clips: idle, move, attack, hit, death, glow, used, shield.
- **Next** Directional and body-part animation sets.
- **Next** Animation events for sounds, projectiles, damage, and state changes.
- **Next** Preview, scrub, and playback controls.
- **Next** Particles, flashes, trails, explosions, and screen effects.
- **Planned** Animation blending and skeletal/rigged animation support.

## 20. Audio and music

- **Current** Audio Database and level/boss music path fields.
- **Current** Keep copyrighted local files out of Git.
- **Next** Main-menu carousel music list.
- **Next** Level exploration, boss, victory, failure, and ambient music.
- **Next** Music loop points, fades, volume, and transitions.
- **Next** Player thrust, shield, collision, weapon, pickup, and explosion sounds.
- **Next** Enemy, boss, miner, platform, UI, and environmental sounds.
- **Next** Sound preview and missing-file validation.
- **Next** Positional audio, range, priority, looping, and random variants.
- **Next** Runtime SDL_mixer or equivalent audio backend.

## 21. Validation, debugging, and playtesting

- **Current** Validate background and start/base presence.
- **Current** Launch build and playtest commands.
- **Next** Test from cursor or selected start point.
- **Next** Test selected path, enemy, boss phase, trigger, or objective.
- **Next** Overlay collision, water, triggers, paths, firing arcs, detection
  ranges, spawn points, and objective links.
- **Next** Detect missing templates/assets/sounds, invalid paths, overlapping
  starts, unreachable miners, and broken references.
- **Next** Event and objective trace log.
- **Next** Pause, step, slow motion, and reset during playtest.
- **Next** Reload changed data without rebuilding where possible.
- **Next** Performance/entity-count statistics.
- **Planned** Automated level smoke tests.

## 22. Editing productivity and usability

- **Current** Undo/redo foundation.
- **Current** Icon toolbar and tooltips.
- **Current** Status area identifies mode, brush, selection, and path target.
- **Next** Reliable multi-step undo/redo for every edit type.
- **Next** Keyboard shortcut editor.
- **Next** Context menus and double-click editors.
- **Next** Tool-specific cursor and prominent mode banner.
- **Next** Drag/drop resources from Database to map.
- **Next** Favorites and recently used palette items.
- **Next** Property presets and copy/paste properties.
- **Next** Responsive dock sizing and remembered window layout.
- **Next** Searchable command palette.
- **Next** High-contrast overlays and scalable UI text/icons.

## 23. Possible beat-'em-up expansion

- **Planned** Lane/depth zones and walkable polygons.
- **Planned** Camera bounds and scrolling regions.
- **Planned** Enemy-wave and arena-lock events.
- **Planned** Spawn entrances and formation paths.
- **Planned** Dialogue and cutscene events.
- **Planned** Stage transitions and branching exits.
- **Planned** Breakable props and item drops.
- **Planned** Player/enemy combo and hitbox preview tools.
- **Planned** Boss arenas using the same encounter, path, animation, weapon,
  trigger, and objective systems.

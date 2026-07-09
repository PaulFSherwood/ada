# SubTerrania Ada Help File

This file explains how the current Ada SubTerrania project is connected, where the important code lives, and what to check when you want to change or debug something.

The current design is intentionally split into small systems instead of putting everything in `application.adb`.

```text
subterrania.adb
   -> Application.Init
   -> game loop
      -> Application.Update
      -> Application.Draw
   -> Application.Shutdown

Application
   -> owns SDL window/renderer
   -> owns the main game state
   -> calls Inputs, Movement, Collision, Render, Level

Level
   -> owns tile map data
   -> owns object/enemy/powerup/miner data
   -> saves/loads level01.map

Inputs
   -> turns SDL events into simple Input_State flags

Movement
   -> applies thrust, gravity, object patrol movement

Collision
   -> handles wall, landing, water, enemy, miner, powerup, goal, platform checks

Render
   -> draws background, tiles, objects, player sprite, editor overlay
```

---

## 1. First code that runs

The program starts here:

```text
src/core/subterrania.adb
```

The important loop is:

```ada
Application.Init;

while Application.Is_Running loop
   Application.Update;
   Application.Draw;
end loop;

Application.Shutdown;
```

Think of this as:

```text
Init once
Update game state
Draw current frame
Repeat until quit
Shutdown SDL
```

---

## 2. Application is the high-level coordinator

Main file:

```text
src/core/application.adb
```

`Application` owns the main state:

```ada
Tiles   : Level.Tile_Map;
Objects : Level.Object_Array;

Mode  : Level.Game_Mode := Level.Play_Mode;
Brush : Level.Brush_Mode := Level.Tile_Brush;

Cursor_X : Float := 400.0;
Cursor_Y : Float := 300.0;

Spawn_X : Float := 400.0;
Spawn_Y : Float := 300.0;

Camera_X : Float := 0.0;
Camera_Y : Float := 0.0;
```

Important idea:

```text
Application does not do all the work.
Application tells the other systems when to work.
```

Good `Application` responsibilities:

```text
SDL setup
create the player entity
load the level
call input/update/render systems
shutdown SDL
```

Bad `Application` responsibilities:

```text
drawing every object directly
handling every collision directly
storing every map rule directly
```

We moved those into systems.

---

## 3. ECS: why Player needs Mgr

The player is not a big object. The player is an entity ID.

```ada
Player := EM.Create_Entity (Mgr);
```

Mentally:

```text
Player = 1
```

The actual data is stored in the entity manager:

```text
Mgr.Transforms[Player]  -> X/Y/Rotation
Mgr.Velocities[Player]  -> X/Y speed
Mgr.Colliders[Player]   -> collision box size
Mgr.Renderables[Player] -> draw size/color
Mgr.Gravities[Player]   -> gravity state
```

So this:

```ada
EM.Add_Transform (Mgr, Player);
EM.Add_Velocity (Mgr, Player);
EM.Add_Collider (Mgr, Player);
EM.Add_Renderable (Mgr, Player);
EM.Add_Gravity (Mgr, Player);
```

means:

```text
Attach these component records to the player ID inside Mgr.
```

This:

```ada
T : constant EM.Transform_Map.Reference_Type :=
  EM.Get_Transform (Mgr, Player);
```

means:

```text
Get a reference to the player's Transform component.
```

Then:

```ada
T.Element.all.X := Spawn_X;
```

means:

```text
Player.Transform.X = Spawn_X
```

The `constant` part means the reference variable `T` cannot be pointed somewhere else. It does **not** mean the transform data cannot change.

---

## 4. Init chain

`Application.Init` does this:

```text
1. SDL.Initialise
2. Create SDL window
3. Create SDL renderer
4. EM.Initialize
5. Create Player entity
6. Add components to Player
7. Set player render/collider size
8. Load level01.map
9. If load fails, build test level
10. Find start tile
11. Put player at start
12. Update camera
```

Important startup code idea:

```ada
Level.Load_Level (Tiles, Objects, Map_Path, Loaded);

if not Loaded then
   Level.Build_Test_Level (Tiles, Objects);
end if;
```

This means:

```text
Use your saved level01.map if it exists.
Only build the default test level if loading fails.
```

---

## 5. Update chain

`Application.Update` runs once per frame.

Flow:

```text
Inputs.Poll_Events
   -> returns Input_State

if quit requested:
   Running := False

if E was pressed:
   Toggle_Mode

if editor mode:
   Handle_Editor_Input
else:
   Apply_Play_Input
   Configure gravity
   Apply gravity
   Move player
   Move enemies/platforms
   Check collisions
   Sync gravity component
   Update camera
```

The important split:

```text
Editor Mode changes the map.
Play Mode moves the player and runs gameplay.
```

---

## 6. Draw chain

`Application.Draw` calls the render system:

```ada
Render_System.Draw_Frame
  (Renderer,
   Screen_Width,
   Screen_Height,
   Tiles,
   Objects,
   Mode,
   Brush,
   Cursor_X,
   Cursor_Y,
   Current_Tile,
   Current_Kind,
   Current_Motion,
   Camera_X,
   Camera_Y,
   T.Element.all,
   R.Element.all,
   Gravity_Is_On);
```

Then:

```ada
Window.Update_Surface;
```

The render system decides what to draw:

```text
background image
collision/editor tile overlay
objects
player ship sprite
editor cursor
editor legend
```

Main file:

```text
src/ecs/systems/render.adb
```

---

## 7. PNG background vs level01.map

The project uses both.

### Visual background

```text
images/maps/sub-terrania-mission-1.png
```

In the current code, the PNG was converted into Ada drawing data here:

```text
src/ecs/systems/mission1_background.adb
src/ecs/systems/mission1_background.ads
```

This is visual only.

### Gameplay map

```text
level01.map
```

This defines the actual playable data:

```text
walls
water
landing tiles
start tile
miners
enemies
powerups
goal
platforms
```

Important rule:

```text
The PNG does not define collision.
level01.map defines collision and gameplay.
```

So if you see a wall in the picture but the ship flies through it, you need to place a Wall tile in editor mode and save.

---

## 8. Tile types

Defined in:

```text
src/ecs/systems/level.ads
```

```ada
type Tile_Kind is
  (Space_Tile,
   Wall_Tile,
   Landing_Tile,
   Water_Tile,
   Start_Tile);
```

Meaning:

```text
Space_Tile   = empty/passable
Wall_Tile    = solid/crash tile
Landing_Tile = safe landing surface
Water_Tile   = water/gravity behavior tile
Start_Tile   = player spawn location
```

Only this is solid:

```text
Wall_Tile
```

Collision uses functions in `level.adb`:

```ada
Level.Is_Solid_At
Level.Is_Solid_AABB
Level.Is_Landing_At
Level.Tile_At_World
```

---

## 9. How walls are defined

Walls are not read from the PNG.

Walls are tile entries inside `Tiles : Level.Tile_Map`.

When the editor places a wall:

```ada
Level.Set_Tile_At_World
  (Tiles,
   Cursor_X,
   Cursor_Y,
   Level.Wall_Tile);
```

Later collision checks:

```ada
Level.Is_Solid_AABB (Tiles, T.X, T.Y, C.Width, C.Height)
```

If true, the player crashes and resets.

---

## 10. Start position

Start position comes from the `Start_Tile` in `level01.map`.

Chain:

```text
Application.Init
   -> Level.Load_Level
   -> Configure_Player_From_Map
      -> Level.Find_Player_Start
      -> Reset_Player
```

Fallback values live in `application.adb`:

```ada
Spawn_X : Float := 400.0;
Spawn_Y : Float := 300.0;
```

But the saved map should override those when it has a `Start_Tile`.

When placing a new start tile, the code should clear the old start tile so only one start remains.

Workflow:

```text
E     editor mode
N/B   cycle to Start_Tile
P     place start
F     save level01.map
restart game
```

If the ship does not start at the new start, check:

```text
Did you press F to save?
Are you running from the project root?
Is level01.map timestamp updated?
Is there more than one Start_Tile?
```

Check timestamp:

```bash
ls -l level01.map
```

---

## 11. Objects

Defined in:

```text
src/ecs/systems/level.ads
```

```ada
type Object_Kind is
  (Miner,
   Enemy,
   Powerup,
   Goal,
   Platform);
```

Object data:

```ada
type Object_Record is record
   Used    : Boolean := False;
   Kind    : Object_Kind := Miner;
   Motion  : Motion_Kind := Static;

   X       : Float := 0.0;
   Y       : Float := 0.0;
   W       : Float := 24.0;
   H       : Float := 24.0;

   Min_Pos : Float := 0.0;
   Max_Pos : Float := 0.0;
   Speed   : Float := 0.0;
   Dir     : Float := 1.0;
end record;
```

Important fields:

```text
Used    = whether this slot is active
Kind    = miner/enemy/powerup/goal/platform
Motion  = static/patrol_x/patrol_y
X/Y     = world position
W/H     = size
Min_Pos = patrol lower bound
Max_Pos = patrol upper bound
Speed   = movement speed
Dir     = current movement direction
```

---

## 12. Object movement

Motion types:

```ada
type Motion_Kind is
  (Static,
   Patrol_X,
   Patrol_Y);
```

Object movement is called from `Application.Update`:

```ada
Movement.Move_Dynamic_Objects (Objects, DT);
```

That passes through to:

```ada
Level.Move_Dynamic_Objects (Objects, DT);
```

Meaning:

```text
Movement system says movement should happen.
Level system knows how objects store their movement data.
```

---

## 13. Collision behavior

Main file:

```text
src/ecs/systems/collision.adb
```

Called by:

```ada
Collision.Check_Player
  (Tiles,
   Objects,
   T.Element.all,
   V.Element.all,
   C.Element.all,
   Spawn_X,
   Spawn_Y,
   Gravity_On,
   Result);
```

Collision checks two major things:

```text
1. Tile collision
2. Object collision
```

### Tile collision

Wall:

```text
crash and reset player
```

Landing:

```text
if vertical speed is safe:
   land and turn gravity off
else:
   crash and reset
```

### Object collision

Miner:

```text
remove miner
increment Miner_Count
```

Powerup:

```text
remove powerup
increment Power_Count
```

Enemy:

```text
crash and reset
```

Goal:

```text
set Goal_Reached true
```

Platform:

```text
land on top if falling onto it
```

---

## 14. Gravity and water

Gravity component:

```text
src/ecs/components/ecs-components-gravity.ads
```

Gravity behavior:

```text
src/ecs/systems/movement.adb
```

Normal gravity:

```ada
G.Strength := 120.0;
```

Water gravity:

```ada
G.Strength := -40.0;
```

So in water, gravity changes direction/strength.

Important chain:

```text
Application.Update
   -> if gravity is on:
        Movement.Configure_Gravity
        Movement.Apply_Gravity
```

`Configure_Gravity` reads the tile under the player:

```ada
Tile : constant Level.Tile_Kind := Level.Tile_At_World (Tiles, T.X, T.Y);
```

Then water changes gravity.

---

## 15. Player movement

Main file:

```text
src/ecs/systems/movement.adb
```

Player input modifies velocity:

```ada
Movement.Apply_Player_Input
  (V.Element.all,
   Gravity_Is_On,
   State.Thrust,
   State.Brake,
   State.Turn_Left,
   State.Turn_Right,
   DT);
```

Then gravity modifies velocity:

```ada
Movement.Apply_Gravity
  (V.Element.all,
   G.Element.all,
   Max_Fall_Speed,
   DT);
```

Then velocity modifies position:

```ada
Movement.Move (T.Element.all, V.Element.all, DT);
```

Mental model:

```text
Input changes velocity.
Gravity changes velocity.
Velocity changes position.
Collision may correct position.
```

---

## 16. Camera

World size:

```ada
World_Width_Pixels  : constant Positive := 1_280;
World_Height_Pixels : constant Positive := 1_128;
```

Window size:

```ada
Screen_Width  : constant Natural := 800;
Screen_Height : constant Natural := 600;
```

The world is larger than the visible window.

Camera follows the player:

```text
Camera_X = player X - half screen width
Camera_Y = player Y - half screen height
```

Then it clamps so the camera does not move outside the map.

Render subtracts camera from world positions:

```ada
screen_x = world_x - Camera_X
screen_y = world_y - Camera_Y
```

That is why objects stay in world space but draw at different screen positions.

---

## 17. Editor controls

Play mode:

```text
W = thrust up
A = thrust/move left
D = thrust/move right
S = brake/down
E = toggle editor mode
```

Editor mode:

```text
W/A/S/D = move editor cursor
E       = return to play mode
T       = toggle Tile Brush / Object Brush
N       = next selected item for current brush
B       = next tile type
M       = next motion type
P       = place selected tile/object
O       = delete selected tile/object
F       = save level01.map
L       = load level01.map
```

Brush behavior:

```text
Tile Brush:
   P places Current_Tile
   O replaces tile with Space_Tile

Object Brush:
   P places Current_Kind with Current_Motion
   O deletes object under cursor
```

---

## 18. Editor legend overlay

The legend is drawn in editor mode by:

```text
src/ecs/systems/render.adb
```

Look for code like:

```ada
Draw_Text
Draw_Editor_Legend
Glyph_For
```

The text is not SDL_ttf. It is a tiny built-in pixel font.

Why:

```text
No extra SDL_ttf dependency.
Simple and works with plain rectangle drawing.
```

---

## 19. Save/load map file

Map path in `application.adb`:

```ada
Map_Path : constant String := "level01.map";
```

Save:

```ada
Level.Save_Level (Tiles, Objects, Map_Path);
```

Load:

```ada
Level.Load_Level (Tiles, Objects, Map_Path, Loaded);
```

Important:

```text
level01.map is relative to the working directory.
Run from project root.
```

Use:

```bash
alr run
```

from:

```text
/home/sherwood/Documents/src/ada/adaSDL/SubTerrania
```

If saves seem lost, the game may be reading/writing a different `level01.map` because it was launched from a different directory.

---

## 20. Background and sprites

Player ship sprite:

```text
images/sprites/ship01.png
```

Current code also has embedded sprite drawing:

```text
src/ecs/systems/sprites.adb
src/ecs/systems/sprites.ads
```

Mission 1 background:

```text
images/maps/sub-terrania-mission-1.png
```

Current render path:

```text
mission1_background.adb draws the background
sprites.adb draws the player ship
render.adb coordinates all drawing
```

Current project avoids SDL_image by embedding/converting image data. Later, a better advanced version could use SDL_image to load PNGs directly.

---

## 21. Important Ada syntax in this project

### `with`

Like an include/import:

```ada
with Level;
```

Means this file can see package `Level`.

### `use type`

Makes operators for a type visible:

```ada
use type Level.Game_Mode;
use type Level.Brush_Mode;
use type Level.Tile_Kind;
```

Needed for things like:

```ada
if Mode = Level.Editor_Mode then
```

Without `use type`, Ada may complain that `=` is not directly visible.

### Package rename

```ada
package EM renames ECS.Entity_System.Entity_Manager;
```

Means:

```text
Use EM as a short name for the long package name.
```

### References from maps

```ada
T : constant EM.Transform_Map.Reference_Type :=
  EM.Get_Transform (Mgr, Player);
```

Means:

```text
Get a reference to the player's transform inside the manager.
```

Then:

```ada
T.Element.all.X
```

means:

```text
The X field inside the referenced Transform.
```

### `in out`

```ada
procedure Move
  (T : in out Transform;
   V : Velocity);
```

`T : in out` means the procedure can modify `T`.

Plain `V : Velocity` defaults to `in`, so it is read-only.

---

## 22. Common questions and where to look

### Where does the program start?

```text
src/core/subterrania.adb
```

### Where is the player created?

```text
src/core/application.adb
Application.Init
```

### Where is the start position set?

```text
src/core/application.adb
Configure_Player_From_Map
Reset_Player
```

And:

```text
src/ecs/systems/level.adb
Find_Player_Start
```

### Where are walls defined?

```text
level01.map
Level.Tile_Map
Wall_Tile
```

Code:

```text
src/ecs/systems/level.adb
Is_Solid_At
Is_Solid_AABB
Set_Tile_At_World
```

### Where is gravity handled?

```text
src/ecs/systems/movement.adb
Configure_Gravity
Apply_Gravity
```

### Where is collision handled?

```text
src/ecs/systems/collision.adb
Check_Player
Check_Tile_Collision
Check_Object_Collision
```

### Where is input handled?

```text
src/ecs/systems/inputs.adb
Poll_Events
Handle_Key_Down
Handle_Key_Up
```

### Where is drawing handled?

```text
src/ecs/systems/render.adb
Draw_Frame
```

### Where is the map saved?

```text
level01.map
```

### Where is the visible mission background?

```text
src/ecs/systems/mission1_background.adb
```

---

## 23. Build and run

From project root:

```bash
alr build
alr run
```

If style warnings show:

```text
line too long
multiple blank lines
bad casing
```

Those are GNAT style checks. Fix them instead of disabling strict style.

Common fixes:

```text
Keep lines under 80 chars.
Use consistent casing.
Only one blank line where style expects one.
Remove duplicate use type clauses.
Remove unused with clauses.
```

---

## 24. Before commit checklist

Run:

```bash
alr build
```

Then check:

```bash
git status
```

Good files to commit:

```text
src/**/*.adb
src/**/*.ads
level01.map
images/sprites/ship01.png
images/maps/sub-terrania-mission-1.png
HELPFILE.md
```

Do not commit generated build output:

```text
obj/
bin/
alire/cache-like build folders if any
```

Potential `.gitignore` entries:

```gitignore
obj/
bin/
*.ali
*.o
```

---

## 25. Good next improvements

Good next steps that fit this architecture:

```text
1. Make actual enemy sprites.
2. Add ship rotation sprite drawing.
3. Add fuel.
4. Add damage/lives.
5. Add bullets/projectiles.
6. Add real mission completion.
7. Add multiple mission maps.
8. Add SDL_image later so PNGs load directly.
9. Add better editor UI for selected tile/object.
10. Save player spawn and mission metadata more cleanly.
```

Professional direction:

```text
Keep Application small.
Keep systems focused.
Keep Level as the source of map/object data.
Keep Render as the only drawing code.
Keep Collision as the only gameplay collision code.
Keep Inputs as the only SDL keyboard event code.
```

That structure makes the project easier to learn from and easier to grow.

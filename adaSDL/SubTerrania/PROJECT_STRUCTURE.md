# SubTerrania Project Structure

This project is moving toward a professional Ada game/editor layout.

## Current safe layout

```text
src/
  core/                 main application shell and path constants
  ecs/                  generic ECS components/entity storage
  ecs/systems/          current gameplay/editor systems, still being split

assets/
  levels/               playable/editable level files such as stage01.map
  images/maps/          visual map/background PNGs
  images/sprites/       ship/enemy/powerup sprites
  images/ui/            editor UI art, icons, selection outlines
  audio/music/          local music only, ignored by git
  audio/sfx/            shield/weapon/UI sounds
  fonts/                future bitmap font or TTF assets

docs/                   design notes and editor requirements
tools/                  migration/asset/conversion scripts
```

## Intended Ada package split

The next refactor should move code out of `src/ecs/systems` into clearer packages:

```text
src/game/               movement, collision, gameplay, objectives, triggers, bosses
src/editor/             editor app, editor input, editor rendering, panels, tools
src/engine/             reusable audio/input/rendering/resource helpers
src/generated/          generated embedded art/data such as mission backgrounds
```

We are not moving package names in this cleanup script because Ada source filenames,
`with` clauses, and the GPR project need to be changed together. That will be a
separate compile-tested refactor phase.

## Level files

The active level path is centralized in:

```text
src/core/app_paths.ads
```

The current default is:

```text
assets/levels/stage01.map
```

The old root `level01.map` path is only a temporary compatibility fallback.

## Music and copyright

Do not commit commercial/copyrighted music. Place local music in:

```text
assets/audio/music/
```

The `.gitignore` is set to ignore `.mp3`, `.wav`, `.ogg`, and `.flac` files under
`assets/audio/` while keeping `.keep` placeholder files.

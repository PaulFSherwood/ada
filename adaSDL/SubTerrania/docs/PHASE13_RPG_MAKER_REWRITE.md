# Phase 13: RPG Maker-style editor rewrite

## Purpose

Provide a clear content-authoring workflow instead of exposing every game
subsystem around the map at once.

## Mental model

- **Map window:** place and arrange things in a level.
- **Database:** define reusable things.
- **Object Properties:** edit one placed instance.
- **Level Properties:** edit metadata for the current map.
- **Playtest:** save and launch the game.

## Path workflow

```text
Select object
Choose Path mode
Banner identifies path owner
Ctrl-click numbered points
Finish Path
```

The selected object owns the route. Path coordinates are secondary data, not
the primary user interface.

## Layers

Layer visibility is editor-only in this phase. Layer serialization, ordering,
locking, and selectability are future additions.

## Database boundary

The Database writes human-readable files under `assets/database/`. These files
are not yet consumed by every SDL runtime system. Their purpose in Phase 13 is
to establish the correct editor architecture before runtime integration.

# Assets

Game/editor data lives here instead of the project root.

```text
assets/
  levels/          editable level files, e.g. stage01.map
  images/maps/     map/background images
  images/sprites/  ship, enemy, UI, and object sprites
  audio/           local music and sound effects
```

The Ada code now loads/saves `assets/levels/stage01.map` by default.
Older `level01.map` is only used as a fallback if the new file is missing.

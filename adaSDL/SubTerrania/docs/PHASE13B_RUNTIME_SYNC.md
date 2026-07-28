# Phase 13B — Runtime Path and Music Sync

Phase 13B connects editor-authored data to the SDL game runtime.

## Motion paths

The game now reads `<level>.editor` after loading the main level file. For
`stage01.map`, this is:

```text
assets/levels/stage01.map.editor
```

Path metadata is matched to the corresponding object index. An editor path
takes priority over the older `STATIC`, `PATROL_X`, and `PATROL_Y` movement.

Supported playback modes:

- `ONCE`
- `LOOP`
- `PINGPONG`

Supported easing:

- `SNAP`
- `LINEAR`
- `SMOOTH`
- `ARC` currently uses the same smooth interpolation as `SMOOTH`

Node `TIME` values are treated as elapsed seconds along the path. The
difference between adjacent node times is the segment travel duration. A
missing or zero duration falls back to one second.

## Music

The old console-only audio stub has been replaced for music playback with
SDL2_mixer. MP3 files do not need to be converted to Ogg.

Level music comes from the level metadata:

```text
MUSIC assets/audio/music/example.mp3
```

Menu and editor music come from:

```text
assets/database/audio.cfg
```

If a configured menu/editor track is missing, the runtime tries the first
supported file found under `assets/audio/music`.

Supported music extensions are MP3, Ogg Vorbis, WAV, and FLAC, subject to the
decoders included in the installed SDL2_mixer package.

Sound effects remain diagnostic hooks in this phase. Music playback is real.

## Requirements

On Ubuntu/Kubuntu:

```bash
sudo apt install libsdl2-mixer-dev
```

Check the project with:

```bash
tools/check_phase13b_runtime.sh
```

Then build and run:

```bash
alr build
alr run
```

At startup, the console should report messages similar to:

```text
SDL2_mixer audio ready
Loaded runtime paths: 4 from assets/levels/stage01.map.editor
Music playing: assets/audio/music/...
```

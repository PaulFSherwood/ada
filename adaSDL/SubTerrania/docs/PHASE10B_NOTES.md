# Phase 10B Notes

This phase fixes structure and editor readability without changing package names.

Changes:

- Moved top-level `images/` content into `assets/images/` and backed up the old folder.
- Moved root `level01.map` into `assets/levels/stage01.map` when needed.
- Centralized asset paths in `src/core/app_paths.ads`.
- Updated `.gitignore` so local music/sound files are not committed.
- Patched the temporary pixel text renderer so lowercase labels are converted to uppercase.
- Added future professional source directories: `src/game`, `src/editor`, `src/engine`, `src/generated`.

Next recommended phase:

- Replace the temporary 5x7 font with a real bitmap font atlas or SDL_ttf.
- Move editor rendering/input into dedicated `src/editor` packages.
- Move gameplay systems into `src/game` packages.

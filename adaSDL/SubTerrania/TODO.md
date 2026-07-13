# SubTerrania TODO

## Level Editor First

- Make the level editor the primary product for the next few phases.
- Keep gameplay playable, but avoid adding major gameplay features until the editor feels like a real tool.
- Keep editor data-driven so it can create ECS-style entities/templates.

### Phase 10C current goal

- [x] Add clickable workspace tabs.
- [x] Make File/Edit/View/Level/Test/Help do something basic.
- [x] Make toolbar Save/Load/Test/Grid buttons clickable.
- [x] Add a bottom workspace panel that changes by editor workspace.
- [x] Add a minimap overview area in the bottom-right.
- [x] Add placeholder workspaces for Player, Enemies, Weapons, Powerups, Audio, Build/Test, and Beat 'Em Up.

### Editor UI cleanup

- [ ] Split editor rendering out of `Render.Draw_Frame`.
- [ ] Split editor input out of `Application.Handle_Editor_Input`.
- [ ] Add proper map viewport clipping.
- [ ] Add real fullscreen toggle.
- [ ] Replace temporary 5x7 pixel font with a real bitmap font or SDL_ttf.
- [ ] Add scrollable palette and asset browser.
- [ ] Add real property editing controls.
- [ ] Add file picker/path entry for local audio and sprites.
- [ ] Add undo/redo.
- [ ] Add layer visibility and lock controls.

## Game

- [ ] Tune ship physics, gravity, thrust, drag, max speed.
- [ ] Add real fuel and shield UI.
- [ ] Add crash/explosion/restart flow.
- [ ] Add mission briefing screen.
- [ ] Add mission complete and next-level load flow.
- [ ] Add enemy projectile system.
- [ ] Add weapon/projectile collision.
- [ ] Add boss health, weapon usage, phases, and death actions.

## Data-driven systems

- [ ] Add entity templates for player, enemy, boss, weapon, and powerup.
- [ ] Add objective data model.
- [ ] Add trigger/action data model.
- [ ] Add boss phase data model.
- [ ] Add ship config data model.
- [ ] Add weapon config data model.
- [ ] Add powerup effect data model.

## Audio

- [ ] Keep commercial/copyrighted audio local only.
- [ ] Store audio references in level/entity/weapon/ship data.
- [ ] Add menu music metadata.
- [ ] Add level music metadata.
- [ ] Add boss music metadata.
- [ ] Add thrust/shield/weapon/pickup sound references.
- [ ] Later connect Audio package to SDL_mixer or another backend.

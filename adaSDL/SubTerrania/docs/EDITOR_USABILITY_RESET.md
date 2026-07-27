# Phase 12A - Editor Usability Reset

This phase moves the native editor closer to a real production workflow.

## Goals

- The top toolbar uses icon-style actions instead of large text buttons.
- Document tabs have meaningful names instead of Page 1 / Page 2.
- The minimap is docked to the lower right inspector area.
- Tool buttons behave as mutually exclusive tools.
- Grid menu and grid toolbar button stay synchronized.
- Grid is drawn last as a visible overlay so it stays easier to see.
- Background-scroll panning is restored for the canvas.

## Intended workflow

1. Open the Map workspace.
2. Pick a palette item from the left.
3. Paint or place it on the map.
4. Switch to Select and click an entity.
5. Use the Inspector to rename/edit geometry.
6. Use Path mode to add motion nodes to platforms, enemies, miners, and later bosses.
7. Save, then Playtest.

## Still planned

- Real icon assets / named icon theme selection.
- Dragging selected objects without moving map layers.
- Ctrl-click node creation from Select mode.
- Path segment duration/easing editor.
- Enemy/boss animation and fire arc editing.
- Destructible pixel masks.

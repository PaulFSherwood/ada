#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f alire.toml || ! -d src/core || ! -d src/ecs/systems ]]; then
  echo "Run this from the SubTerrania project after unzipping the patch."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="backups/phase11_professional_editor_${STAMP}"
mkdir -p "$BACKUP"

cp -a alire.toml "$BACKUP/" 2>/dev/null || true
cp -a subterrania.gpr "$BACKUP/" 2>/dev/null || true
cp -a src/core/application.adb "$BACKUP/" 2>/dev/null || true
cp -a src/ecs/systems/level.ads "$BACKUP/" 2>/dev/null || true
cp -a src/ecs/systems/level.adb "$BACKUP/" 2>/dev/null || true
cp -a assets/levels/stage01.map "$BACKUP/" 2>/dev/null || true

echo "Backup: $BACKUP"

python3 <<'PY'
from pathlib import Path

level_ads = Path("src/ecs/systems/level.ads")
text = level_ads.read_text()
if "Background_Image" not in text:
    old = '''      Next_Level : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("stage02.map");
'''
    new = '''      Next_Level : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("stage02.map");
      Background_Image : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("assets/images/maps/sub-terrania-mission-1.png");
      Music : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("assets/audio/music/mission01.ogg");
      Boss_Music : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("assets/audio/music/boss01.ogg");
'''
    if old not in text:
        raise SystemExit("Could not patch Level_Info in level.ads")
    level_ads.write_text(text.replace(old, new))

level_adb = Path("src/ecs/systems/level.adb")
text = level_adb.read_text()
if "Background_Image =>" not in text:
    old = '''         Title      => US.To_Unbounded_String ("Mission 1"),
         Next_Level => US.To_Unbounded_String ("stage02.map"));
'''
    new = '''         Title      => US.To_Unbounded_String ("Mission 1"),
         Next_Level => US.To_Unbounded_String ("stage02.map"),
         Background_Image => US.To_Unbounded_String
           ("assets/images/maps/sub-terrania-mission-1.png"),
         Music => US.To_Unbounded_String
           ("assets/audio/music/mission01.ogg"),
         Boss_Music => US.To_Unbounded_String
           ("assets/audio/music/boss01.ogg"));
'''
    if old not in text:
        raise SystemExit("Could not patch Default_Level_Info in level.adb")
    text = text.replace(old, new)

if 'Put_Line (File, "BACKGROUND "' not in text:
    old = '''      Put_Line (File, "NEXT " & US.To_String (Info.Next_Level));
'''
    new = '''      Put_Line (File, "NEXT " & US.To_String (Info.Next_Level));
      Put_Line
        (File, "BACKGROUND " & US.To_String (Info.Background_Image));
      Put_Line (File, "MUSIC " & US.To_String (Info.Music));
      Put_Line (File, "BOSS_MUSIC " & US.To_String (Info.Boss_Music));
'''
    if old not in text:
        raise SystemExit("Could not patch Save_Info in level.adb")
    text = text.replace(old, new)

if 'Starts_With (Line, Last, "BACKGROUND ")' not in text:
    old = '''            elsif Starts_With (Line, Last, "NEXT ") then
               Info.Next_Level :=
                 US.To_Unbounded_String (Tail_After (Line, Last, "NEXT "));
            elsif Starts_With (Line, Last, "TILES") then
'''
    new = '''            elsif Starts_With (Line, Last, "NEXT ") then
               Info.Next_Level :=
                 US.To_Unbounded_String (Tail_After (Line, Last, "NEXT "));
            elsif Starts_With (Line, Last, "BACKGROUND ") then
               Info.Background_Image :=
                 US.To_Unbounded_String
                   (Tail_After (Line, Last, "BACKGROUND "));
            elsif Starts_With (Line, Last, "MUSIC ") then
               Info.Music :=
                 US.To_Unbounded_String
                   (Tail_After (Line, Last, "MUSIC "));
            elsif Starts_With (Line, Last, "BOSS_MUSIC ") then
               Info.Boss_Music :=
                 US.To_Unbounded_String
                   (Tail_After (Line, Last, "BOSS_MUSIC "));
            elsif Starts_With (Line, Last, "TILES") then
'''
    if old not in text:
        raise SystemExit("Could not patch Load_Level metadata in level.adb")
    text = text.replace(old, new)

level_adb.write_text(text)

stage = Path("assets/levels/stage01.map")
if stage.exists():
    text = stage.read_text()
    if "BACKGROUND " not in text:
        marker = None
        for line in text.splitlines(True):
            if line.startswith("NEXT "):
                marker = line
                break
        if marker:
            insert = (
                marker
                + "BACKGROUND assets/images/maps/sub-terrania-mission-1.png\n"
                + "MUSIC assets/audio/music/mission01.ogg\n"
                + "BOSS_MUSIC assets/audio/music/boss01.ogg\n"
            )
            stage.write_text(text.replace(marker, insert, 1))

app = Path("src/core/application.adb")
text = app.read_text()
if "Launch_Native_Editor" not in text:
    if "with Interfaces.C;" not in text:
        text = text.replace(
            "with Ada.Text_IO; use Ada.Text_IO;\n",
            "with Ada.Text_IO; use Ada.Text_IO;\nwith Interfaces.C;\n",
            1,
        )

    marker = "package body Application is\n"
    declaration = '''package body Application is

   function C_System
     (Command : Interfaces.C.char_array) return Interfaces.C.int
   with Import, Convention => C, External_Name => "system";
'''
    if marker not in text:
        raise SystemExit("Could not patch application package body")
    text = text.replace(marker, declaration, 1)

    insert_before = "   procedure Handle_Main_Menu_Input\n"
    launcher = '''   procedure Launch_Native_Editor is
      Result : Interfaces.C.int;
      pragma Unreferenced (Result);
   begin
      Result := C_System
        (Interfaces.C.To_C
           ("sh -c 'tools/run_editor.sh > "
            & "/tmp/subterrania-editor.log 2>&1 &'"));
      Put_Line ("NATIVE EDITOR LAUNCHED");
   end Launch_Native_Editor;

'''
    if insert_before not in text:
        raise SystemExit("Could not find main-menu handler")
    text = text.replace(insert_before, launcher + insert_before, 1)
    text = text.replace(
        "            when 3 =>\n               Start_Editor;",
        "            when 3 =>\n               Launch_Native_Editor;",
        1,
    )
    app.write_text(text)
PY

mkdir -p assets/audio/sfx/ship assets/audio/sfx/pickups
: > assets/audio/sfx/ship/.keep
: > assets/audio/sfx/pickups/.keep

for line in \
  'assets/audio/**/*.mp3' \
  'assets/audio/**/*.wav' \
  'assets/audio/**/*.ogg' \
  'assets/audio/**/*.flac' \
  'bin/' \
  'obj/' \
  'backups/'
do
  grep -qxF "$line" .gitignore || echo "$line" >> .gitignore
done

if ! grep -Eq '^gtkada[[:space:]]*=' alire.toml; then
  echo "Adding GtkAda to the Alire crate..."
  alr with gtkada
else
  echo "GtkAda dependency already present."
fi

chmod +x \
  tools/build_editor.sh \
  tools/run_editor.sh \
  tools/build_all.sh \
  tools/check_editor_requirements.sh

if ! pkg-config --exists gtk+-3.0 2>/dev/null; then
  echo
  echo "GTK3 development files are missing. Install them with:"
  echo "  sudo apt install libgtk-3-dev"
  echo
fi

echo
cat <<'MESSAGE'
Phase 11 professional editor patch applied.

Build the SDL game:
  alr build

Check editor dependencies:
  tools/check_editor_requirements.sh

Build the native editor:
  tools/build_editor.sh

Run the native editor:
  tools/run_editor.sh

The game's FULL MAP EDITOR menu item now launches the native editor.
The old SDL overlay remains in source only for compatibility and can be
removed after the native editor has been validated.
MESSAGE

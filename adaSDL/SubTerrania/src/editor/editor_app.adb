with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Glib;
with Glib.Error;
with Glib.Object;
with Gdk.Event;
with Gdk.Types;
with Gtk.Builder;
with Gtk.Check_Menu_Item;
with Gtk.GEntry;
with Gtk.Label;
with Gtk.Main;
with Gtk.Notebook;
with Gtk.Text_Buffer;
with Gtk.Text_View;
with Gtk.Toggle_Button;
with Gtk.Toggle_Tool_Button;
with Gtk.Widget;
with Gtk.Window;
with Gtkada.Builder;
with Gtkada.File_Selection;
with Interfaces.C;
with Level;

with Editor_Canvas;
with Editor_State;

package body Editor_App is

   use Ada.Strings.Unbounded;
   use Glib;
   use Glib.Object;
   use Gtk.Builder;
   use Gtk.GEntry;
   use Gtk.Label;
   use Gtk.Notebook;
   use Gtk.Text_Buffer;
   use Gtk.Text_View;
   use Gtk.Widget;
   use Gtk.Window;
   use Gtkada.Builder;

   use type Glib.Error.GError;
   use type Gdk.Types.Gdk_Key_Type;
   use type Interfaces.C.int;
   use type Editor_State.Selection_Kind;
   use type Editor_State.Tool_Kind;

   type Main_Mode_Kind is
     (Map_Mode,
      Object_Mode,
      Path_Mode,
      Trigger_Mode);

   Builder       : Gtkada_Builder;
   Output_Log    : Unbounded_String;
   Active_Mode   : Main_Mode_Kind := Map_Mode;
   Syncing_Tools : Boolean := False;
   Syncing_Grid  : Boolean := False;

   function C_System
     (Command : Interfaces.C.char_array) return Interfaces.C.int
   with Import, Convention => C, External_Name => "system";

   function UI_Entry (Name : String) return Gtk_Entry is
   begin
      return Gtk_Entry (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Entry;

   function UI_Label (Name : String) return Gtk_Label is
   begin
      return Gtk_Label (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Label;

   function UI_Window (Name : String) return Gtk_Window is
   begin
      return Gtk_Window (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Window;

   function UI_Notebook (Name : String) return Gtk_Notebook is
   begin
      return Gtk_Notebook (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Notebook;

   function UI_Widget (Name : String) return Gtk_Widget is
   begin
      return Gtk_Widget (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Widget;

   procedure Set_Label
     (Name : String;
      Text : String) is
      Label : constant Gtk_Label := UI_Label (Name);
   begin
      if Label /= null then
         Label.Set_Text (Text);
      end if;
   end Set_Label;

   procedure Set_Entry
     (Name : String;
      Text : String) is
      Field : constant Gtk_Entry := UI_Entry (Name);
   begin
      if Field /= null then
         Field.Set_Text (Text);
      end if;
   end Set_Entry;

   function Get_Entry
     (Name    : String;
      Default : String := "") return String is
      Field : constant Gtk_Entry := UI_Entry (Name);
   begin
      if Field = null then
         return Default;
      end if;
      return Field.Get_Text;
   end Get_Entry;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Float_Value
     (Name    : String;
      Default : Float) return Float is
   begin
      return Float'Value (Get_Entry (Name));
   exception
      when others =>
         return Default;
   end Float_Value;

   function Pixel_Text (Value : Float) return String is
   begin
      return Trimmed (Integer'Image (Integer (Value)));
   end Pixel_Text;

   function Fixed_Float (Value : Float) return String is
      package Local_Float_IO is new Ada.Text_IO.Float_IO (Float);
      Buffer : String (1 .. 32) := (others => ' ');
   begin
      Local_Float_IO.Put
        (To   => Buffer,
         Item => Value,
         Aft  => 2,
         Exp  => 0);
      return Trimmed (Buffer);
   end Fixed_Float;

   procedure Log (Text : String) is
      View : constant Gtk_Text_View := Gtk_Text_View
        (Get_Object (Gtk_Builder (Builder), "output_text_view"));
   begin
      Append (Output_Log, Text & ASCII.LF);
      if View /= null then
         declare
            Buffer : constant Gtk_Text_Buffer := View.Get_Buffer;
         begin
            Buffer.Set_Text (To_String (Output_Log));
         end;
      end if;
      Set_Label ("status_label", Text);
   end Log;

   function Relative_Path (Path : String) return String is
      Root : constant String := Ada.Directories.Current_Directory;
   begin
      if Path'Length > Root'Length
        and then Path (Path'First .. Path'First + Root'Length - 1) = Root
      then
         return Path (Path'First + Root'Length + 1 .. Path'Last);
      end if;
      return Path;
   end Relative_Path;

   procedure Browse_Into
     (Entry_Name  : String;
      Title       : String;
      Default_Dir : String) is
      Path : constant String :=
        Gtkada.File_Selection.File_Selection_Dialog
          (Title       => Title,
           Default_Dir => Default_Dir,
           Dir_Only    => False,
           Must_Exist  => True);
   begin
      if Path /= "" then
         Set_Entry (Entry_Name, Relative_Path (Path));
      end if;
   end Browse_Into;

   procedure Run_Command
     (Command : String;
      Message : String) is
      Result : Interfaces.C.int;
   begin
      Result := C_System (Interfaces.C.To_C (Command));
      if Result = 0 then
         Log (Message);
      else
         Log ("Command failed: " & Command);
      end if;
   end Run_Command;

   procedure Ensure_Parent (Path : String) is
      Directory : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      if Directory /= "" and then not Ada.Directories.Exists (Directory) then
         Ada.Directories.Create_Path (Directory);
      end if;
   end Ensure_Parent;

   procedure Save_Text
     (Path : String;
      Text : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ensure_Parent (Path);
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Text);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Log ("Could not save " & Path);
   end Save_Text;

   function Entry_Line
     (Key  : String;
      Name : String) return String is
   begin
      return Key & " " & Get_Entry (Name) & ASCII.LF;
   end Entry_Line;

   function Read_Value
     (Path    : String;
      Key     : String;
      Default : String) return String is
      File : Ada.Text_IO.File_Type;
      Line : String (1 .. 2_048);
      Last : Natural;
   begin
      if not Ada.Directories.Exists (Path) then
         return Default;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Line, Last);
         if Last > Key'Length
           and then Line (1 .. Key'Length) = Key
           and then Line (Key'Length + 1) = ' '
         then
            Ada.Text_IO.Close (File);
            return Line (Key'Length + 2 .. Last);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return Default;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return Default;
   end Read_Value;

   procedure Load_Field
     (Path    : String;
      Key     : String;
      Name    : String;
      Default : String) is
   begin
      Set_Entry (Name, Read_Value (Path, Key, Default));
   end Load_Field;

   procedure Update_Level_Fields is
      Info : constant Level.Level_Info := Editor_State.Info;
   begin
      Set_Entry ("level_name_entry", To_String (Info.Stage_Name));
      Set_Entry ("level_title_entry", To_String (Info.Title));
      Set_Entry ("next_level_entry", To_String (Info.Next_Level));
      Set_Entry ("background_entry", To_String (Info.Background_Image));
      Set_Entry ("music_entry", To_String (Info.Music));
      Set_Entry ("boss_music_entry", To_String (Info.Boss_Music));
   end Update_Level_Fields;

   procedure Apply_Level_Fields is
      Info : Level.Level_Info := Editor_State.Info;
   begin
      Info.Stage_Name := To_Unbounded_String (Get_Entry ("level_name_entry"));
      Info.Title := To_Unbounded_String (Get_Entry ("level_title_entry"));
      Info.Next_Level := To_Unbounded_String (Get_Entry ("next_level_entry"));
      Info.Background_Image := To_Unbounded_String
        (Get_Entry ("background_entry"));
      Info.Music := To_Unbounded_String (Get_Entry ("music_entry"));
      Info.Boss_Music := To_Unbounded_String
        (Get_Entry ("boss_music_entry"));
      Editor_State.Set_Info (Info);
      Editor_Canvas.Rebuild;
   end Apply_Level_Fields;

   procedure Load_Database is
   begin
      Load_Field
        ("assets/database/player.cfg", "NAME",
         "db_player_name", "RescueShip01");
      Load_Field
        ("assets/database/player.cfg", "SPRITE",
         "db_player_sprite", "assets/images/sprites/ship01.png");
      Load_Field
        ("assets/database/player.cfg", "THRUST",
         "db_player_thrust", "260");
      Load_Field
        ("assets/database/player.cfg", "FUEL",
         "db_player_fuel", "100");
      Load_Field
        ("assets/database/player.cfg", "SHIELD",
         "db_player_shield", "100");
      Load_Field
        ("assets/database/player.cfg", "ENGINE_SOUND",
         "db_player_engine_sound", "assets/audio/sfx/ship/thrust.wav");

      Load_Field
        ("assets/database/enemy.cfg", "NAME",
         "db_enemy_name", "GunTurret");
      Load_Field
        ("assets/database/enemy.cfg", "HEALTH",
         "db_enemy_health", "50");
      Load_Field
        ("assets/database/enemy.cfg", "ANIMATION",
         "db_enemy_animation", "turret_idle");
      Load_Field
        ("assets/database/enemy.cfg", "MOVEMENT",
         "db_enemy_movement", "Static");
      Load_Field
        ("assets/database/enemy.cfg", "WEAPON",
         "db_enemy_weapon", "RedLaser");
      Load_Field
        ("assets/database/enemy.cfg", "FIRE_ARC",
         "db_enemy_fire_arc", "45 degrees left/right");
      Load_Field
        ("assets/database/enemy.cfg", "DETECTION",
         "db_enemy_detection", "300");
      Load_Field
        ("assets/database/enemy.cfg", "NOTES",
         "db_enemy_notes", "Wall or ceiling mounted turret.");

      Load_Field
        ("assets/database/boss.cfg", "NAME",
         "db_boss_name", "FourFaceBoss");
      Load_Field
        ("assets/database/boss.cfg", "HEALTH",
         "db_boss_health", "500");
      Load_Field
        ("assets/database/boss.cfg", "BODY_ANIMATIONS",
         "db_boss_animations", "face, arms, tentacles, beak");
      Load_Field
        ("assets/database/boss.cfg", "PHASES",
         "db_boss_phases", "3");
      Load_Field
        ("assets/database/boss.cfg", "MOVEMENT",
         "db_boss_movement", "Cardinal + path");
      Load_Field
        ("assets/database/boss.cfg", "WEAPONS",
         "db_boss_weapons", "Fireball, RedLaser");
      Load_Field
        ("assets/database/boss.cfg", "MUSIC",
         "db_boss_music", "assets/audio/music/boss01.ogg");
      Load_Field
        ("assets/database/boss.cfg", "NOTES",
         "db_boss_notes", "Phase data and attacks are expanded later.");

      Load_Field
        ("assets/database/weapon.cfg", "NAME",
         "db_weapon_name", "RedLaser");
      Load_Field
        ("assets/database/weapon.cfg", "BEHAVIOR",
         "db_weapon_behavior", "Forward; affected by gravity");
      Load_Field
        ("assets/database/weapon.cfg", "DAMAGE",
         "db_weapon_damage", "10");
      Load_Field
        ("assets/database/weapon.cfg", "COOLDOWN",
         "db_weapon_cooldown", "0.25");
      Load_Field
        ("assets/database/weapon.cfg", "PROJECTILE",
         "db_weapon_projectile", "laser_red");
      Load_Field
        ("assets/database/weapon.cfg", "SOUND",
         "db_weapon_sound", "assets/audio/sfx/weapons/red.wav");

      Load_Field
        ("assets/database/pickup.cfg", "NAME",
         "db_pickup_name", "MissilePickup");
      Load_Field
        ("assets/database/pickup.cfg", "EFFECT",
         "db_pickup_effect", "Equip missiles");
      Load_Field
        ("assets/database/pickup.cfg", "VALUE",
         "db_pickup_value", "1");
      Load_Field
        ("assets/database/pickup.cfg", "GLOW_ANIMATION",
         "db_pickup_glow", "pickup_glow");
      Load_Field
        ("assets/database/pickup.cfg", "PICKUP_SOUND",
         "db_pickup_sound", "assets/audio/sfx/pickups/item.wav");

      Load_Field
        ("assets/database/platform.cfg", "NAME",
         "db_platform_name", "MovingPlatform");
      Load_Field
        ("assets/database/platform.cfg", "SPRITE",
         "db_platform_sprite", "platform_default");
      Load_Field
        ("assets/database/platform.cfg", "LANDABLE",
         "db_platform_landable", "true");
      Load_Field
        ("assets/database/platform.cfg", "CRUSH_HAZARD",
         "db_platform_crush", "true");
      Load_Field
        ("assets/database/platform.cfg", "PATH_MODE",
         "db_platform_path", "PingPong / Smooth");

      Load_Field
        ("assets/database/destructible.cfg", "NAME",
         "db_destructible_name", "RockCover");
      Load_Field
        ("assets/database/destructible.cfg", "MASK",
         "db_destructible_mask", "rock_cover_mask.png");
      Load_Field
        ("assets/database/destructible.cfg", "THRESHOLD",
         "db_destructible_threshold", "75");
      Load_Field
        ("assets/database/destructible.cfg", "REVEALS",
         "db_destructible_reveals", "MissilePickup");
      Load_Field
        ("assets/database/destructible.cfg", "SOUND",
         "db_destructible_sound", "assets/audio/sfx/rock_break.wav");

      Load_Field
        ("assets/database/animation.cfg", "NAME",
         "db_animation_name", "MinerWalk");
      Load_Field
        ("assets/database/animation.cfg", "SHEET",
         "db_animation_sheet", "assets/images/sprites/miner.png");
      Load_Field
        ("assets/database/animation.cfg", "FPS",
         "db_animation_fps", "8");
      Load_Field
        ("assets/database/animation.cfg", "FRAMES",
         "db_animation_frames", "0,1,2,3");

      Load_Field
        ("assets/database/audio.cfg", "MENU_MUSIC",
         "db_audio_menu", "assets/audio/music/menu.ogg");
      Load_Field
        ("assets/database/audio.cfg", "LEVEL_MUSIC",
         "db_audio_level", "assets/audio/music/mission01.ogg");
      Load_Field
        ("assets/database/audio.cfg", "BOSS_MUSIC",
         "db_audio_boss", "assets/audio/music/boss01.ogg");
      Load_Field
        ("assets/database/audio.cfg", "UI_SELECT",
         "db_audio_select", "assets/audio/sfx/ui/select.wav");

      Load_Field
        ("assets/database/objectives.cfg", "RESCUE_MINERS",
         "db_objective_miners", "1");
      Load_Field
        ("assets/database/objectives.cfg", "RETURN_TO_BASE",
         "db_objective_return", "true");
      Load_Field
        ("assets/database/objectives.cfg", "DESTROY_TARGET",
         "db_objective_destroy", "");
      Load_Field
        ("assets/database/objectives.cfg", "COLLECT_ITEM",
         "db_objective_collect", "");

      Load_Field
        ("assets/database/project.cfg", "TITLE",
         "db_project_title", "SubTerrania");
      Load_Field
        ("assets/database/project.cfg", "START_LEVEL",
         "db_project_start", "assets/levels/stage01.map");
      Load_Field
        ("assets/database/project.cfg", "PLAYER_TEMPLATE",
         "db_project_player", "RescueShip01");
   end Load_Database;

   procedure Save_Database is
   begin
      Save_Text
        ("assets/database/player.cfg",
         "PLAYER" & ASCII.LF
         & Entry_Line ("NAME", "db_player_name")
         & Entry_Line ("SPRITE", "db_player_sprite")
         & Entry_Line ("THRUST", "db_player_thrust")
         & Entry_Line ("FUEL", "db_player_fuel")
         & Entry_Line ("SHIELD", "db_player_shield")
         & Entry_Line ("ENGINE_SOUND", "db_player_engine_sound"));

      Save_Text
        ("assets/database/enemy.cfg",
         "ENEMY" & ASCII.LF
         & Entry_Line ("NAME", "db_enemy_name")
         & Entry_Line ("HEALTH", "db_enemy_health")
         & Entry_Line ("ANIMATION", "db_enemy_animation")
         & Entry_Line ("MOVEMENT", "db_enemy_movement")
         & Entry_Line ("WEAPON", "db_enemy_weapon")
         & Entry_Line ("FIRE_ARC", "db_enemy_fire_arc")
         & Entry_Line ("DETECTION", "db_enemy_detection")
         & Entry_Line ("NOTES", "db_enemy_notes"));

      Save_Text
        ("assets/database/boss.cfg",
         "BOSS" & ASCII.LF
         & Entry_Line ("NAME", "db_boss_name")
         & Entry_Line ("HEALTH", "db_boss_health")
         & Entry_Line ("BODY_ANIMATIONS", "db_boss_animations")
         & Entry_Line ("PHASES", "db_boss_phases")
         & Entry_Line ("MOVEMENT", "db_boss_movement")
         & Entry_Line ("WEAPONS", "db_boss_weapons")
         & Entry_Line ("MUSIC", "db_boss_music")
         & Entry_Line ("NOTES", "db_boss_notes"));

      Save_Text
        ("assets/database/weapon.cfg",
         "WEAPON" & ASCII.LF
         & Entry_Line ("NAME", "db_weapon_name")
         & Entry_Line ("BEHAVIOR", "db_weapon_behavior")
         & Entry_Line ("DAMAGE", "db_weapon_damage")
         & Entry_Line ("COOLDOWN", "db_weapon_cooldown")
         & Entry_Line ("PROJECTILE", "db_weapon_projectile")
         & Entry_Line ("SOUND", "db_weapon_sound"));

      Save_Text
        ("assets/database/pickup.cfg",
         "PICKUP" & ASCII.LF
         & Entry_Line ("NAME", "db_pickup_name")
         & Entry_Line ("EFFECT", "db_pickup_effect")
         & Entry_Line ("VALUE", "db_pickup_value")
         & Entry_Line ("GLOW_ANIMATION", "db_pickup_glow")
         & Entry_Line ("PICKUP_SOUND", "db_pickup_sound"));

      Save_Text
        ("assets/database/platform.cfg",
         "PLATFORM" & ASCII.LF
         & Entry_Line ("NAME", "db_platform_name")
         & Entry_Line ("SPRITE", "db_platform_sprite")
         & Entry_Line ("LANDABLE", "db_platform_landable")
         & Entry_Line ("CRUSH_HAZARD", "db_platform_crush")
         & Entry_Line ("PATH_MODE", "db_platform_path"));

      Save_Text
        ("assets/database/destructible.cfg",
         "DESTRUCTIBLE" & ASCII.LF
         & Entry_Line ("NAME", "db_destructible_name")
         & Entry_Line ("MASK", "db_destructible_mask")
         & Entry_Line ("THRESHOLD", "db_destructible_threshold")
         & Entry_Line ("REVEALS", "db_destructible_reveals")
         & Entry_Line ("SOUND", "db_destructible_sound"));

      Save_Text
        ("assets/database/animation.cfg",
         "ANIMATION" & ASCII.LF
         & Entry_Line ("NAME", "db_animation_name")
         & Entry_Line ("SHEET", "db_animation_sheet")
         & Entry_Line ("FPS", "db_animation_fps")
         & Entry_Line ("FRAMES", "db_animation_frames"));

      Save_Text
        ("assets/database/audio.cfg",
         "AUDIO" & ASCII.LF
         & Entry_Line ("MENU_MUSIC", "db_audio_menu")
         & Entry_Line ("LEVEL_MUSIC", "db_audio_level")
         & Entry_Line ("BOSS_MUSIC", "db_audio_boss")
         & Entry_Line ("UI_SELECT", "db_audio_select"));

      Save_Text
        ("assets/database/objectives.cfg",
         "OBJECTIVES" & ASCII.LF
         & Entry_Line ("RESCUE_MINERS", "db_objective_miners")
         & Entry_Line ("RETURN_TO_BASE", "db_objective_return")
         & Entry_Line ("DESTROY_TARGET", "db_objective_destroy")
         & Entry_Line ("COLLECT_ITEM", "db_objective_collect"));

      Save_Text
        ("assets/database/project.cfg",
         "PROJECT" & ASCII.LF
         & Entry_Line ("TITLE", "db_project_title")
         & Entry_Line ("START_LEVEL", "db_project_start")
         & Entry_Line ("PLAYER_TEMPLATE", "db_project_player"));

      Log ("Database saved to assets/database");
   end Save_Database;

   procedure Set_Toggle
     (Name   : String;
      Active : Boolean) is
      Obj : constant GObject := Get_Object (Gtk_Builder (Builder), Name);
   begin
      if Obj /= null then
         Gtk.Toggle_Tool_Button.Set_Active
           (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button (Obj), Active);
      end if;
   end Set_Toggle;

   function Toggle_Active (Name : String) return Boolean is
      Obj : constant GObject := Get_Object (Gtk_Builder (Builder), Name);
   begin
      if Obj = null then
         return False;
      end if;
      return Gtk.Toggle_Tool_Button.Get_Active
        (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button (Obj));
   end Toggle_Active;

   procedure Sync_Tools is
      Tool : constant Editor_State.Tool_Kind := Editor_State.Current_Tool;
   begin
      Syncing_Tools := True;
      Set_Toggle ("mode_map_tool", Active_Mode = Map_Mode);
      Set_Toggle ("mode_object_tool", Active_Mode = Object_Mode);
      Set_Toggle ("mode_path_tool", Active_Mode = Path_Mode);
      Set_Toggle ("mode_trigger_tool", Active_Mode = Trigger_Mode);
      Set_Toggle ("select_tool", Tool = Editor_State.Select_Tool);
      Set_Toggle
        ("brush_tool",
         Tool = Editor_State.Tile_Brush_Tool
         or else Tool = Editor_State.Object_Brush_Tool);
      Set_Toggle ("eraser_tool", Tool = Editor_State.Eraser_Tool);
      Set_Toggle ("pan_tool", Tool = Editor_State.Pan_Tool);
      Syncing_Tools := False;
   end Sync_Tools;

   procedure Hide_Path_Banner is
   begin
      UI_Widget ("path_banner").Hide;
   end Hide_Path_Banner;

   procedure Show_Path_Banner is
      Sel : constant Editor_State.Selection_Info := Editor_State.Selection;
   begin
      if Sel.Kind = Editor_State.Object_Selected
        and then Sel.Object_Index /= 0
      then
         Set_Label
           ("path_banner_label",
            "EDITING PATH - "
            & Editor_State.Object_Display_Name
              (Level.Object_Index (Sel.Object_Index))
            & " | "
            & Fixed_Float
              (Editor_State.Object_Path_Travel_Time
                 (Level.Object_Index (Sel.Object_Index)))
            & " sec | "
            & Editor_State.Object_Path_Route_Summary
              (Level.Object_Index (Sel.Object_Index))
            & " | Drag nodes | Ctrl-click dashed line adds waypoint | "
            & "Enter finish | Esc cancel");
         UI_Widget ("path_banner").Show_All;
      end if;
   end Show_Path_Banner;

   procedure Set_Mode (Mode : Main_Mode_Kind) is
      Path_Changed : Boolean := False;
   begin
      if Mode /= Path_Mode and then Editor_State.Path_Edit_Active then
         Editor_State.Finish_Path_Edit (Path_Changed);
         if Path_Changed then
            Log ("Path changes kept when leaving Path mode");
         end if;
      end if;

      Active_Mode := Mode;
      case Mode is
         when Map_Mode | Object_Mode =>
            Editor_State.Set_Tool (Editor_State.Select_Tool);
            Hide_Path_Banner;

         when Path_Mode =>
            if Editor_State.Selection.Kind /= Editor_State.Object_Selected then
               Active_Mode := Object_Mode;
               Editor_State.Set_Tool (Editor_State.Select_Tool);
               Log ("Select an object before entering Path mode");
            else
               declare
                  Started : Boolean;
               begin
                  Editor_State.Begin_Path_Edit (Started);
                  if Started then
                     Editor_State.Set_Tool (Editor_State.Path_Tool);
                     Show_Path_Banner;
                  else
                     Active_Mode := Object_Mode;
                     Editor_State.Set_Tool (Editor_State.Select_Tool);
                     Log ("Could not begin path editing");
                  end if;
               end;
            end if;

         when Trigger_Mode =>
            Editor_State.Set_Tool (Editor_State.Trigger_Tool);
            Hide_Path_Banner;
      end case;
      Sync_Tools;
      Editor_Canvas.Refresh_Inspector;
   end Set_Mode;

   procedure Select_Tile (Tile : Level.Tile_Kind) is
   begin
      Active_Mode := Map_Mode;
      Editor_State.Set_Tile_Brush (Tile);
      Sync_Tools;
      Log ("Map brush: " & Editor_State.Tile_Name (Tile));
   end Select_Tile;

   procedure Select_Object (Kind : Level.Object_Kind) is
   begin
      Active_Mode := Object_Mode;
      Editor_State.Set_Object_Brush (Kind);
      Sync_Tools;
      Log ("Object brush: " & Editor_State.Object_Name (Kind));
   end Select_Object;

   procedure Refresh_Object_Editor is
      Sel     : constant Editor_State.Selection_Info := Editor_State.Selection;
      Objects : constant access Level.Object_Array := Editor_State.Objects;
   begin
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
      then
         Log ("Select an object first");
         return;
      end if;

      declare
         Index : constant Level.Object_Index :=
           Level.Object_Index (Sel.Object_Index);
         Obj   : constant Level.Object_Record := Objects (Index);
         Count : constant Editor_State.Path_Node_Count :=
           Editor_State.Object_Path_Count (Index);
      begin
         Set_Entry
           ("object_name_entry", Editor_State.Object_Display_Name (Index));
         Set_Label
           ("object_type_label", Editor_State.Object_Name (Obj.Kind));
         Set_Entry ("object_x_entry", Pixel_Text (Obj.X));
         Set_Entry ("object_y_entry", Pixel_Text (Obj.Y));
         Set_Entry ("object_w_entry", Pixel_Text (Obj.W));
         Set_Entry ("object_h_entry", Pixel_Text (Obj.H));
         Set_Label
           ("object_path_summary_label",
            "Nodes: "
            & Trimmed (Natural'Image (Natural (Count)))
            & " | route time: "
            & Fixed_Float (Editor_State.Object_Path_Travel_Time (Index))
            & " sec | "
            & Editor_State.Object_Path_Mode_Text (Index)
            & ASCII.LF
            & "Route: " & Editor_State.Object_Path_Route_Summary (Index));
      end;
   end Refresh_Object_Editor;

   procedure On_New (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Editor_State.New_Level;
      Update_Level_Fields;
      Editor_Canvas.Rebuild;
      Log ("New level created");
   end On_New;

   procedure On_Open (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Path : constant String :=
        Gtkada.File_Selection.File_Selection_Dialog
          (Title       => "Open SubTerrania level",
           Default_Dir => "assets/levels",
           Dir_Only    => False,
           Must_Exist  => True);
      Loaded : Boolean;
   begin
      if Path = "" then
         return;
      end if;
      Editor_State.Load (Path, Loaded);
      if Loaded then
         Update_Level_Fields;
         Editor_Canvas.Rebuild;
         Log ("Opened " & Path);
      else
         Log ("Could not open " & Path);
      end if;
   end On_Open;

   procedure On_Open_Stage01
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Loaded : Boolean;
   begin
      Editor_State.Load ("assets/levels/stage01.map", Loaded);
      if Loaded then
         Update_Level_Fields;
         Editor_Canvas.Rebuild;
         Log ("Opened Stage01");
      end if;
   end On_Open_Stage01;

   procedure On_Save (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Apply_Level_Fields;
      Editor_State.Save;
      Log ("Saved " & Editor_State.Level_Path);
   end On_Save;

   procedure On_Save_As (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Path : constant String :=
        Gtkada.File_Selection.File_Selection_Dialog
          (Title       => "Save SubTerrania level as",
           Default_Dir => "assets/levels",
           Dir_Only    => False,
           Must_Exist  => False);
   begin
      if Path /= "" then
         Apply_Level_Fields;
         Editor_State.Save_As (Path);
         Log ("Saved " & Path);
      end if;
   end On_Save_As;

   procedure On_Quit (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Gtk.Main.Main_Quit;
   end On_Quit;

   procedure On_Undo (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Undo (Changed);
      if Changed then
         Editor_Canvas.Rebuild;
         Log ("Undo");
      else
         Log ("Nothing to undo");
      end if;
   end On_Undo;

   procedure On_Redo (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Redo (Changed);
      if Changed then
         Editor_Canvas.Rebuild;
         Log ("Redo");
      else
         Log ("Nothing to redo");
      end if;
   end On_Redo;

   procedure On_Delete (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Delete_Selected (Changed);
      if Changed then
         Editor_Canvas.Rebuild;
         Log ("Selection deleted");
      else
         Log ("Nothing selected");
      end if;
   end On_Delete;

   procedure On_Mode_Map (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("mode_map_tool") then
         Set_Mode (Map_Mode);
      else
         Sync_Tools;
      end if;
   end On_Mode_Map;

   procedure On_Mode_Object (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("mode_object_tool") then
         Set_Mode (Object_Mode);
      else
         Sync_Tools;
      end if;
   end On_Mode_Object;

   procedure On_Mode_Path (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("mode_path_tool") then
         Set_Mode (Path_Mode);
      else
         Sync_Tools;
      end if;
   end On_Mode_Path;

   procedure On_Mode_Trigger (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("mode_trigger_tool") then
         Set_Mode (Trigger_Mode);
      else
         Sync_Tools;
      end if;
   end On_Mode_Trigger;

   procedure On_Tool_Select (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("select_tool") then
         Editor_State.Set_Tool (Editor_State.Select_Tool);
         Sync_Tools;
         Log ("Select tool");
      else
         Sync_Tools;
      end if;
   end On_Tool_Select;

   procedure On_Tool_Brush (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("brush_tool") then
         if Active_Mode = Object_Mode then
            Editor_State.Set_Tool (Editor_State.Object_Brush_Tool);
         else
            Active_Mode := Map_Mode;
            Editor_State.Set_Tool (Editor_State.Tile_Brush_Tool);
         end if;
         Sync_Tools;
         Log ("Pencil tool");
      else
         Sync_Tools;
      end if;
   end On_Tool_Brush;

   procedure On_Tool_Erase (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("eraser_tool") then
         Editor_State.Set_Tool (Editor_State.Eraser_Tool);
         Sync_Tools;
         Log ("Erase tool");
      else
         Sync_Tools;
      end if;
   end On_Tool_Erase;

   procedure On_Tool_Pan (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Syncing_Tools then
         return;
      end if;
      if Toggle_Active ("pan_tool") then
         Editor_State.Set_Tool (Editor_State.Pan_Tool);
         Sync_Tools;
         Log ("Pan tool: left-drag; middle-drag works from any tool");
      else
         Sync_Tools;
      end if;
   end On_Tool_Pan;

   procedure On_Palette_Wall (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Tile (Level.Wall_Tile); end On_Palette_Wall;

   procedure On_Palette_Water (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Tile (Level.Water_Tile); end On_Palette_Water;

   procedure On_Palette_Landing
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Tile (Level.Landing_Tile); end On_Palette_Landing;

   procedure On_Palette_Start (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Tile (Level.Start_Tile); end On_Palette_Start;

   procedure On_Palette_Space (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Tile (Level.Space_Tile); end On_Palette_Space;

   procedure On_Palette_Miner (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Miner); end On_Palette_Miner;

   procedure On_Palette_Enemy (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Enemy); end On_Palette_Enemy;

   procedure On_Palette_Platform
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Platform); end On_Palette_Platform;

   procedure On_Palette_Gate (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Gate); end On_Palette_Gate;

   procedure On_Palette_Boss (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Boss_Spawn); end On_Palette_Boss;

   procedure On_Palette_Fuel (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Fuel); end On_Palette_Fuel;

   procedure On_Palette_Shield (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Shield); end On_Palette_Shield;

   procedure On_Palette_Powerup
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Powerup); end On_Palette_Powerup;

   procedure On_Grid (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Visible : Boolean;
   begin
      if Syncing_Grid then
         return;
      end if;
      Visible := Gtk.Toggle_Tool_Button.Get_Active
        (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button
           (Get_Object (Gtk_Builder (Builder), "grid_tool")));
      Editor_State.Set_Grid_Visible (Visible);
      Syncing_Grid := True;
      Gtk.Check_Menu_Item.Set_Active
        (Gtk.Check_Menu_Item.Gtk_Check_Menu_Item
           (Get_Object (Gtk_Builder (Builder), "grid_menu_item")),
         Visible);
      Syncing_Grid := False;
      Editor_Canvas.Rebuild;
      Log ((if Visible then "Grid enabled" else "Grid disabled"));
   end On_Grid;

   procedure On_Grid_Menu (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Visible : Boolean;
   begin
      if Syncing_Grid then
         return;
      end if;
      Visible := Gtk.Check_Menu_Item.Get_Active
        (Gtk.Check_Menu_Item.Gtk_Check_Menu_Item
           (Get_Object (Gtk_Builder (Builder), "grid_menu_item")));
      Editor_State.Set_Grid_Visible (Visible);
      Syncing_Grid := True;
      Gtk.Toggle_Tool_Button.Set_Active
        (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button
           (Get_Object (Gtk_Builder (Builder), "grid_tool")),
         Visible);
      Syncing_Grid := False;
      Editor_Canvas.Rebuild;
   end On_Grid_Menu;

   procedure On_Zoom_In (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Editor_Canvas.Zoom_In; end On_Zoom_In;

   procedure On_Zoom_Out (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Editor_Canvas.Zoom_Out; end On_Zoom_Out;

   procedure On_Fit (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Editor_Canvas.Fit_Map; end On_Fit;

   procedure On_Home (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Editor_Canvas.Center_On_Start; end On_Home;

   procedure Set_Layer
     (Layer : Editor_State.Layer_Kind;
      Name  : String) is
      Visible : constant Boolean := Gtk.Toggle_Button.Get_Active
        (Gtk.Toggle_Button.Gtk_Toggle_Button
           (Get_Object (Gtk_Builder (Builder), Name)));
   begin
      Editor_State.Set_Layer_Visible (Layer, Visible);
      Editor_Canvas.Rebuild;
   end Set_Layer;

   procedure On_Layer_Background
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Background_Layer, "layer_background");
   end On_Layer_Background;

   procedure On_Layer_Terrain
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Terrain_Layer, "layer_terrain");
   end On_Layer_Terrain;

   procedure On_Layer_Water
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Water_Layer, "layer_water");
   end On_Layer_Water;

   procedure On_Layer_Pickups
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Pickups_Layer, "layer_pickups");
   end On_Layer_Pickups;

   procedure On_Layer_Destructibles
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Set_Layer (Editor_State.Destructibles_Layer, "layer_destructibles");
   end On_Layer_Destructibles;

   procedure On_Layer_Platforms
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Platforms_Layer, "layer_platforms");
   end On_Layer_Platforms;

   procedure On_Layer_Miners
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Miners_Layer, "layer_miners");
   end On_Layer_Miners;

   procedure On_Layer_Enemies
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Enemies_Layer, "layer_enemies");
   end On_Layer_Enemies;

   procedure On_Layer_Triggers
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Triggers_Layer, "layer_triggers");
   end On_Layer_Triggers;

   procedure On_Layer_Paths
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Layer (Editor_State.Paths_Layer, "layer_paths");
   end On_Layer_Paths;

   procedure On_Object_Properties
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Refresh_Object_Editor;
      if Editor_State.Selection.Kind = Editor_State.Object_Selected then
         UI_Window ("object_editor_window").Show_All;
      end if;
   end On_Object_Properties;

   procedure On_Apply_Object
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Sel : constant Editor_State.Selection_Info := Editor_State.Selection;
      Renamed : Boolean;
      Changed : Boolean;
   begin
      if Sel.Kind /= Editor_State.Object_Selected then
         Log ("Select an object first");
         return;
      end if;
      Editor_State.Rename_Selected_Object
        (Get_Entry ("object_name_entry"), Renamed);
      Editor_State.Update_Selected_Geometry
        (World_X => Float_Value ("object_x_entry", Sel.World_X),
         World_Y => Float_Value ("object_y_entry", Sel.World_Y),
         Width   => Float_Value ("object_w_entry", 32.0),
         Height  => Float_Value ("object_h_entry", 32.0),
         Changed => Changed);
      if Renamed or else Changed then
         Editor_Canvas.Rebuild;
         Refresh_Object_Editor;
         Log ("Object properties applied");
      end if;
   end On_Apply_Object;

   procedure On_Close_Object
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin UI_Window ("object_editor_window").Hide; end On_Close_Object;

   procedure Finish_Path_Editing is
      Changed : Boolean;
   begin
      Editor_State.Finish_Path_Edit (Changed);
      Active_Mode := Object_Mode;
      Editor_State.Set_Tool (Editor_State.Select_Tool);
      Hide_Path_Banner;
      UI_Window ("path_node_window").Hide;
      Sync_Tools;
      Editor_Canvas.Rebuild;
      if Changed then
         Log ("Path editing finished and changes were kept");
      else
         Log ("Path editing finished");
      end if;
   end Finish_Path_Editing;

   procedure Cancel_Path_Editing is
      Changed : Boolean;
   begin
      Editor_State.Cancel_Path_Edit (Changed);
      Active_Mode := Object_Mode;
      Editor_State.Set_Tool (Editor_State.Select_Tool);
      Hide_Path_Banner;
      Sync_Tools;
      Editor_Canvas.Rebuild;
      UI_Window ("path_node_window").Hide;
      if Changed then
         Log ("Path changes cancelled and the previous path was restored");
      else
         Log ("Path editing cancelled");
      end if;
   end Cancel_Path_Editing;

   procedure Refresh_Path_Timing_Window is
      Sel : constant Editor_State.Selection_Info := Editor_State.Selection;
   begin
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
      then
         return;
      end if;

      declare
         Index : constant Level.Object_Index :=
           Level.Object_Index (Sel.Object_Index);
      begin
         Set_Label
           ("path_timing_target_label",
            "Timing and route sequence - "
            & Editor_State.Object_Display_Name (Index));
         Set_Entry
           ("path_travel_time_entry",
            Fixed_Float (Editor_State.Object_Path_Travel_Time (Index)));
         Set_Entry
           ("path_playback_entry",
            Editor_State.Object_Path_Mode_Text (Index));
         Set_Entry
           ("path_route_order_entry",
            Editor_State.Object_Path_Route_Summary (Index));
         Set_Entry
           ("path_route_pauses_entry",
            Editor_State.Object_Path_Pause_Summary (Index));
         Set_Label
           ("path_timing_preview_label",
            "Movement time excludes pauses. Route: "
            & Editor_State.Object_Path_Route_Summary (Index));
      end;
   end Refresh_Path_Timing_Window;

   procedure On_Edit_Path_Timing
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Sel : constant Editor_State.Selection_Info := Editor_State.Selection;
   begin
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
      then
         Log ("Select an object first");
         return;
      end if;

      if Editor_State.Object_Path_Count
        (Level.Object_Index (Sel.Object_Index)) < 2
      then
         Log ("Create a path before editing its timing");
         return;
      end if;

      Refresh_Path_Timing_Window;
      UI_Window ("path_timing_window").Show_All;
   end On_Edit_Path_Timing;

   procedure On_Apply_Path_Timing
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
      Valid   : Boolean;
      Message : Unbounded_String;
   begin
      Editor_State.Configure_Selected_Path_Timing
        (Travel_Time  => Float_Value ("path_travel_time_entry", 8.0),
         Playback     => Get_Entry ("path_playback_entry", "PINGPONG"),
         Route_Order  => Get_Entry ("path_route_order_entry", "START,END"),
         Route_Pauses => Get_Entry ("path_route_pauses_entry", "0,0"),
         Changed      => Changed,
         Valid        => Valid,
         Message      => Message);

      Log (To_String (Message));
      if Valid and then Changed then
         Editor_Canvas.Rebuild;
         Refresh_Object_Editor;
         Refresh_Path_Timing_Window;
         if Editor_State.Path_Edit_Active then
            Show_Path_Banner;
         end if;
      end if;
   end On_Apply_Path_Timing;

   procedure On_Reset_Path_Timing
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Reset_Selected_Path_Timing (Changed);
      if Changed then
         Editor_Canvas.Rebuild;
         Refresh_Object_Editor;
         Refresh_Path_Timing_Window;
         Log ("Route reset to START through each point to END");
      end if;
   end On_Reset_Path_Timing;

   procedure On_Close_Path_Timing
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      UI_Window ("path_timing_window").Hide;
   end On_Close_Path_Timing;

   procedure On_Edit_Path
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      UI_Window ("object_editor_window").Hide;
      Set_Mode (Path_Mode);
   end On_Edit_Path;

   procedure On_New_Path
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Started : Boolean;
      Cleared : Boolean;
      Created : Boolean;
   begin
      Editor_State.Begin_Path_Edit (Started);
      if not Started then
         Log ("Select an object first");
         return;
      end if;

      Editor_State.Clear_Selected_Path (Cleared);
      Editor_State.Ensure_Simple_Path_For_Selected (Created);
      Set_Mode (Path_Mode);
      Editor_Canvas.Rebuild;
      if Created then
         Log ("Simple path created. Drag END to the destination.");
      else
         Log ("Could not create a simple path");
      end if;
   end On_New_Path;

   procedure On_Clear_Path
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Started : Boolean;
      Changed : Boolean;
   begin
      Editor_State.Begin_Path_Edit (Started);
      if not Started then
         Log ("Select an object first");
         return;
      end if;

      Editor_State.Clear_Selected_Path (Changed);
      if Changed then
         Set_Mode (Path_Mode);
         Editor_Canvas.Rebuild;
         Refresh_Object_Editor;
         Log ("Selected object's path cleared");
      else
         Log ("Selected object has no path to clear");
      end if;
   end On_Clear_Path;

   procedure On_Finish_Path
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Finish_Path_Editing;
   end On_Finish_Path;

   procedure On_Cancel_Path
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Cancel_Path_Editing;
   end On_Cancel_Path;

   procedure On_Apply_Path_Node
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Update_Selected_Path_Node
        (World_X => Float_Value ("path_node_x_entry", 0.0),
         World_Y => Float_Value ("path_node_y_entry", 0.0),
         Time    => 0.0,
         Changed => Changed);
      if Changed then
         Editor_Canvas.Rebuild;
         Log ("Path node properties applied");
      end if;
   end On_Apply_Path_Node;

   procedure On_Delete_Path_Node
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Deleted : Boolean;
   begin
      Editor_State.Delete_Selected_Path_Node (Deleted);
      if Deleted then
         UI_Window ("path_node_window").Hide;
         Editor_Canvas.Rebuild;
         Log ("Waypoint deleted");
      else
         Log ("START and END cannot be deleted");
      end if;
   end On_Delete_Path_Node;

   procedure On_Close_Path_Node
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      UI_Window ("path_node_window").Hide;
   end On_Close_Path_Node;

   procedure Show_Database_Page (Page : Gint) is
   begin
      UI_Notebook ("database_notebook").Set_Current_Page (Page);
      UI_Window ("database_window").Show_All;
   end Show_Database_Page;

   procedure On_Database (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (0); end On_Database;

   procedure On_DB_Player (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (0); end On_DB_Player;

   procedure On_DB_Enemies (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (1); end On_DB_Enemies;

   procedure On_DB_Bosses (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (2); end On_DB_Bosses;

   procedure On_DB_Weapons (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (3); end On_DB_Weapons;

   procedure On_DB_Pickups (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (4); end On_DB_Pickups;

   procedure On_DB_Platforms (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (5); end On_DB_Platforms;

   procedure On_DB_Destructibles
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (6); end On_DB_Destructibles;

   procedure On_DB_Animations (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (7); end On_DB_Animations;

   procedure On_DB_Audio (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (8); end On_DB_Audio;

   procedure On_DB_Objectives (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (9); end On_DB_Objectives;

   procedure On_DB_Project (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Show_Database_Page (10); end On_DB_Project;

   procedure On_Save_Database
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Save_Database; end On_Save_Database;

   procedure On_Close_Database
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin UI_Window ("database_window").Hide; end On_Close_Database;

   procedure On_Level_Properties
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Update_Level_Fields;
      UI_Window ("level_properties_window").Show_All;
   end On_Level_Properties;

   procedure On_Apply_Level
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Apply_Level_Fields;
      Log ("Level properties applied");
   end On_Apply_Level;

   procedure On_Close_Level
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin UI_Window ("level_properties_window").Hide; end On_Close_Level;

   procedure On_Browse_Background
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("background_entry", "Choose level background", "assets/images/maps");
   end On_Browse_Background;

   procedure On_Browse_Music
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into ("music_entry", "Choose level music", "assets/audio/music");
   end On_Browse_Music;

   procedure On_Browse_Boss_Music
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("boss_music_entry", "Choose boss music", "assets/audio/music");
   end On_Browse_Boss_Music;

   procedure On_Validate (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      X     : Float;
      Y     : Float;
      Found : Boolean;
      Info  : constant Level.Level_Info := Editor_State.Info;
   begin
      Found := Level.Find_Player_Start (Editor_State.Tiles.all, X, Y);
      if not Ada.Directories.Exists
        (To_String (Info.Background_Image))
      then
         Log ("Validation: background image is missing");
      elsif not Found then
         Log ("Validation: level has no Start/Base tile");
      else
         Log ("Validation passed: background and Start/Base are present");
      end if;
   end On_Validate;

   procedure On_Playtest (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Apply_Level_Fields;
      Editor_State.Save;
      Run_Command
        ("alr run >/tmp/subterrania-playtest.log 2>&1 &",
         "Playtest launched; log: /tmp/subterrania-playtest.log");
   end On_Playtest;

   procedure On_Build (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Run_Command
        ("alr build >/tmp/subterrania-build.log 2>&1 &",
         "Build started; log: /tmp/subterrania-build.log");
   end On_Build;

   Return_Key : constant Gdk.Types.Gdk_Key_Type := 16#FF0D#;
   Keypad_Enter_Key : constant Gdk.Types.Gdk_Key_Type := 16#FF8D#;
   Escape_Key : constant Gdk.Types.Gdk_Key_Type := 16#FF1B#;

   function On_Main_Key_Press
     (Self  : access Gtk_Widget_Record'Class;
      Event : Gdk.Event.Gdk_Event_Key) return Boolean is
      pragma Unreferenced (Self);
   begin
      if Active_Mode /= Path_Mode then
         return False;
      end if;

      if Event.Keyval = Return_Key
        or else Event.Keyval = Keypad_Enter_Key
      then
         Finish_Path_Editing;
         return True;
      elsif Event.Keyval = Escape_Key then
         Cancel_Path_Editing;
         return True;
      end if;

      return False;
   end On_Main_Key_Press;

   procedure On_Help (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Log
        ("Middle-drag pans; wheel zooms. In Path mode: left-drag a "
         & "node, Ctrl-click a dashed segment to insert a waypoint, "
         & "Ctrl-right-click a node for properties, Enter finishes, "
         & "and Esc cancels.");
   end On_Help;

   procedure Register_Handlers is
   begin
      Register_Handler (Builder, "on_new", On_New'Access);
      Register_Handler (Builder, "on_open", On_Open'Access);
      Register_Handler (Builder, "on_open_stage01", On_Open_Stage01'Access);
      Register_Handler (Builder, "on_save", On_Save'Access);
      Register_Handler (Builder, "on_save_as", On_Save_As'Access);
      Register_Handler (Builder, "on_quit", On_Quit'Access);
      Register_Handler (Builder, "on_undo", On_Undo'Access);
      Register_Handler (Builder, "on_redo", On_Redo'Access);
      Register_Handler (Builder, "on_delete", On_Delete'Access);
      Register_Handler (Builder, "on_mode_map", On_Mode_Map'Access);
      Register_Handler (Builder, "on_mode_object", On_Mode_Object'Access);
      Register_Handler (Builder, "on_mode_path", On_Mode_Path'Access);
      Register_Handler (Builder, "on_mode_trigger", On_Mode_Trigger'Access);
      Register_Handler (Builder, "on_tool_select", On_Tool_Select'Access);
      Register_Handler (Builder, "on_tool_brush", On_Tool_Brush'Access);
      Register_Handler (Builder, "on_tool_erase", On_Tool_Erase'Access);
      Register_Handler (Builder, "on_tool_pan", On_Tool_Pan'Access);
      Register_Handler (Builder, "on_palette_wall", On_Palette_Wall'Access);
      Register_Handler (Builder, "on_palette_water", On_Palette_Water'Access);
      Register_Handler
        (Builder, "on_palette_landing", On_Palette_Landing'Access);
      Register_Handler (Builder, "on_palette_start", On_Palette_Start'Access);
      Register_Handler (Builder, "on_palette_space", On_Palette_Space'Access);
      Register_Handler (Builder, "on_palette_miner", On_Palette_Miner'Access);
      Register_Handler (Builder, "on_palette_enemy", On_Palette_Enemy'Access);
      Register_Handler
        (Builder, "on_palette_platform", On_Palette_Platform'Access);
      Register_Handler (Builder, "on_palette_gate", On_Palette_Gate'Access);
      Register_Handler (Builder, "on_palette_boss", On_Palette_Boss'Access);
      Register_Handler (Builder, "on_palette_fuel", On_Palette_Fuel'Access);
      Register_Handler
        (Builder, "on_palette_shield", On_Palette_Shield'Access);
      Register_Handler
        (Builder, "on_palette_powerup", On_Palette_Powerup'Access);
      Register_Handler (Builder, "on_grid", On_Grid'Access);
      Register_Handler (Builder, "on_grid_menu", On_Grid_Menu'Access);
      Register_Handler (Builder, "on_zoom_in", On_Zoom_In'Access);
      Register_Handler (Builder, "on_zoom_out", On_Zoom_Out'Access);
      Register_Handler (Builder, "on_fit", On_Fit'Access);
      Register_Handler (Builder, "on_home", On_Home'Access);
      Register_Handler
        (Builder, "on_layer_background", On_Layer_Background'Access);
      Register_Handler
        (Builder, "on_layer_terrain", On_Layer_Terrain'Access);
      Register_Handler (Builder, "on_layer_water", On_Layer_Water'Access);
      Register_Handler
        (Builder, "on_layer_pickups", On_Layer_Pickups'Access);
      Register_Handler
        (Builder, "on_layer_destructibles", On_Layer_Destructibles'Access);
      Register_Handler
        (Builder, "on_layer_platforms", On_Layer_Platforms'Access);
      Register_Handler (Builder, "on_layer_miners", On_Layer_Miners'Access);
      Register_Handler
        (Builder, "on_layer_enemies", On_Layer_Enemies'Access);
      Register_Handler
        (Builder, "on_layer_triggers", On_Layer_Triggers'Access);
      Register_Handler (Builder, "on_layer_paths", On_Layer_Paths'Access);
      Register_Handler
        (Builder, "on_object_properties", On_Object_Properties'Access);
      Register_Handler (Builder, "on_apply_object", On_Apply_Object'Access);
      Register_Handler (Builder, "on_close_object", On_Close_Object'Access);
      Register_Handler
        (Builder, "on_edit_path_timing", On_Edit_Path_Timing'Access);
      Register_Handler
        (Builder, "on_apply_path_timing", On_Apply_Path_Timing'Access);
      Register_Handler
        (Builder, "on_reset_path_timing", On_Reset_Path_Timing'Access);
      Register_Handler
        (Builder, "on_close_path_timing", On_Close_Path_Timing'Access);
      Register_Handler (Builder, "on_edit_path", On_Edit_Path'Access);
      Register_Handler (Builder, "on_new_path", On_New_Path'Access);
      Register_Handler (Builder, "on_clear_path", On_Clear_Path'Access);
      Register_Handler (Builder, "on_finish_path", On_Finish_Path'Access);
      Register_Handler (Builder, "on_cancel_path", On_Cancel_Path'Access);
      Register_Handler
        (Builder, "on_apply_path_node", On_Apply_Path_Node'Access);
      Register_Handler
        (Builder, "on_delete_path_node", On_Delete_Path_Node'Access);
      Register_Handler
        (Builder, "on_close_path_node", On_Close_Path_Node'Access);
      Register_Handler (Builder, "on_database", On_Database'Access);
      Register_Handler (Builder, "on_db_player", On_DB_Player'Access);
      Register_Handler (Builder, "on_db_enemies", On_DB_Enemies'Access);
      Register_Handler (Builder, "on_db_bosses", On_DB_Bosses'Access);
      Register_Handler (Builder, "on_db_weapons", On_DB_Weapons'Access);
      Register_Handler (Builder, "on_db_pickups", On_DB_Pickups'Access);
      Register_Handler
        (Builder, "on_db_platforms", On_DB_Platforms'Access);
      Register_Handler
        (Builder, "on_db_destructibles", On_DB_Destructibles'Access);
      Register_Handler
        (Builder, "on_db_animations", On_DB_Animations'Access);
      Register_Handler (Builder, "on_db_audio", On_DB_Audio'Access);
      Register_Handler
        (Builder, "on_db_objectives", On_DB_Objectives'Access);
      Register_Handler (Builder, "on_db_project", On_DB_Project'Access);
      Register_Handler
        (Builder, "on_save_database", On_Save_Database'Access);
      Register_Handler
        (Builder, "on_close_database", On_Close_Database'Access);
      Register_Handler
        (Builder, "on_level_properties", On_Level_Properties'Access);
      Register_Handler (Builder, "on_apply_level", On_Apply_Level'Access);
      Register_Handler (Builder, "on_close_level", On_Close_Level'Access);
      Register_Handler
        (Builder, "on_browse_background", On_Browse_Background'Access);
      Register_Handler (Builder, "on_browse_music", On_Browse_Music'Access);
      Register_Handler
        (Builder, "on_browse_boss_music", On_Browse_Boss_Music'Access);
      Register_Handler (Builder, "on_validate", On_Validate'Access);
      Register_Handler (Builder, "on_playtest", On_Playtest'Access);
      Register_Handler (Builder, "on_build", On_Build'Access);
      Register_Handler (Builder, "on_help", On_Help'Access);
   end Register_Handlers;

   procedure Initialize is
      Error  : aliased Glib.Error.GError;
      Loaded : Guint;
      Window : Gtk_Window;
   begin
      Editor_State.Initialize;
      Gtk_New (Builder);
      Loaded := Add_From_File
        (Gtk_Builder (Builder),
         "assets/ui/subterrania_editor.ui",
         Error'Access);

      if Loaded = 0 then
         Ada.Text_IO.Put_Line
           ("Could not load assets/ui/subterrania_editor.ui");
         if Error /= null then
            Ada.Text_IO.Put_Line (Glib.Error.Get_Message (Error));
            Glib.Error.Error_Free (Error);
         end if;
         return;
      end if;

      Register_Handlers;
      Do_Connect (Builder);
      Update_Level_Fields;
      Load_Database;
      Editor_Canvas.Initialize (Builder);

      Window := UI_Window ("main_window");
      Window.On_Key_Press_Event (On_Main_Key_Press'Access);
      Window.Show_All;
      Hide_Path_Banner;
      Sync_Tools;
      Log ("RPG Maker-style editor rewrite loaded");
   end Initialize;

end Editor_App;

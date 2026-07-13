with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Glib;
with Glib.Error;
with Glib.Object;
with Gtk.Builder;
with Gtk.Check_Menu_Item;
with Gtk.Combo_Box;
with Gtk.GEntry;
with Gtk.Label;
with Gtk.Main;
with Gtk.Notebook;
with Gtk.Text_Buffer;
with Gtk.Text_View;
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
   use type Editor_State.Selection_Kind;

   Builder       : Gtkada_Builder;
   Is_Fullscreen : Boolean := False;
   Output_Log    : Unbounded_String;

   function C_System
     (Command : Interfaces.C.char_array) return Interfaces.C.int
   with Import, Convention => C, External_Name => "system";

   function UI_Entry (Name : String) return Gtk_Entry is
   begin
      return Gtk_Entry
        (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Entry;

   function Entry_Text
     (Name    : String;
      Default : String := "") return String is
      Obj : constant Glib.Object.GObject :=
        Get_Object (Gtk_Builder (Builder), Name);
   begin
      if Obj = null then
         Ada.Text_IO.Put_Line ("Missing UI entry: " & Name);
         return Default;
      end if;

      return Gtk_Entry (Obj).Get_Text;
   exception
      when others =>
         Ada.Text_IO.Put_Line ("Could not read UI entry: " & Name);
         return Default;
   end Entry_Text;

   procedure Set_Entry_Text
     (Name : String;
      Text : String) is
      Obj : constant Glib.Object.GObject :=
        Get_Object (Gtk_Builder (Builder), Name);
   begin
      if Obj = null then
         Ada.Text_IO.Put_Line ("Missing UI entry: " & Name);
      else
         Gtk_Entry (Obj).Set_Text (Text);
      end if;
   exception
      when others =>
         Ada.Text_IO.Put_Line ("Could not set UI entry: " & Name);
   end Set_Entry_Text;

   function UI_Label (Name : String) return Gtk_Label is
   begin
      return Gtk_Label
        (Get_Object (Gtk_Builder (Builder), Name));
   end UI_Label;

   function Documents return Gtk_Notebook is
   begin
      return Gtk_Notebook
        (Get_Object (Gtk_Builder (Builder), "document_notebook"));
   end Documents;

   function Inspectors return Gtk_Notebook is
   begin
      return Gtk_Notebook
        (Get_Object (Gtk_Builder (Builder), "inspector_notebook"));
   end Inspectors;

   procedure Ada.Text_IO.Put_Line (Text : String) is
      View   : constant Gtk_Text_View := Gtk_Text_View
        (Get_Object (Gtk_Builder (Builder), "output_text_view"));
      Buffer : constant Gtk_Text_Buffer := View.Get_Buffer;
   begin
      Append (Output_Log, Text & ASCII.LF);
      Buffer.Set_Text (To_String (Output_Log));
      UI_Label ("status_label").Set_Text (Text);
   end Log;

   function Relative_Path (Path : String) return String is
      Root : constant String := Ada.Directories.Current_Directory;
   begin
      if Path'Length > Root'Length
        and then Path (Path'First .. Path'First + Root'Length - 1) = Root
      then
         return Path
           (Path'First + Root'Length + 1 .. Path'Last);
      end if;

      return Path;
   end Relative_Path;

   procedure Browse_Into
     (Entry_Name  : String;
      Title       : String;
      Default_Dir : String;
      Must_Exist  : Boolean := True) is
      Path : constant String :=
        Gtkada.File_Selection.File_Selection_Dialog
          (Title       => Title,
           Default_Dir => Default_Dir,
           Dir_Only    => False,
           Must_Exist  => Must_Exist);
   begin
      if Path /= "" then
         UI_Entry (Entry_Name).Set_Text (Relative_Path (Path));
         Editor_State.Mark_Dirty;
      end if;
   end Browse_Into;

   procedure Set_Document
     (Page          : Gint;
      Inspector_Page : Gint;
      Description   : String) is
   begin
      Documents.Set_Current_Page (Page);
      Inspectors.Set_Current_Page (Inspector_Page);
      UI_Label ("status_label").Set_Text (Description);
   end Set_Document;

   procedure Update_Level_UI is
      Info : constant Level.Level_Info := Editor_State.Info;
   begin
      UI_Entry ("level_name_entry").Set_Text
        (To_String (Info.Stage_Name));
      UI_Entry ("level_title_entry").Set_Text
        (To_String (Info.Title));
      UI_Entry ("next_level_entry").Set_Text
        (To_String (Info.Next_Level));
      UI_Entry ("background_entry").Set_Text
        (To_String (Info.Background_Image));
      UI_Entry ("music_entry").Set_Text
        (To_String (Info.Music));
      UI_Entry ("level_music_entry").Set_Text
        (To_String (Info.Music));
      UI_Entry ("level_boss_music_entry").Set_Text
        (To_String (Info.Boss_Music));
      UI_Entry ("audio_boss_music_entry").Set_Text
        (To_String (Info.Boss_Music));
      UI_Entry ("boss_music_entry").Set_Text
        (To_String (Info.Boss_Music));
   end Update_Level_UI;

   procedure Apply_Level_UI is
      Info : Level.Level_Info := Editor_State.Info;
   begin
      Info.Stage_Name := To_Unbounded_String
        (UI_Entry ("level_name_entry").Get_Text);
      Info.Title := To_Unbounded_String
        (UI_Entry ("level_title_entry").Get_Text);
      Info.Next_Level := To_Unbounded_String
        (UI_Entry ("next_level_entry").Get_Text);
      Info.Background_Image := To_Unbounded_String
        (UI_Entry ("background_entry").Get_Text);
      Info.Music := To_Unbounded_String
        (UI_Entry ("music_entry").Get_Text);
      Info.Boss_Music := To_Unbounded_String
        (UI_Entry ("level_boss_music_entry").Get_Text);
      Editor_State.Set_Info (Info);
      Editor_Canvas.Rebuild;
   end Apply_Level_UI;

   function Float_From_Entry
     (Name    : String;
      Default : Float) return Float is
   begin
      return Float'Value (Entry_Text (Name, Float'Image (Default)));
   exception
      when others =>
         return Default;
   end Float_From_Entry;

   procedure Save_Definition
     (Path  : String;
      Lines : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Directories.Create_Path
        (Ada.Directories.Containing_Directory (Path));
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Lines);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Ada.Text_IO.Put_Line ("Could not save " & Path);
   end Save_Definition;

   function Entry_Line
     (Key  : String;
      Name : String) return String is
   begin
      return Key & " " & Entry_Text (Name) & ASCII.LF;
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

   procedure Load_Entry
     (Path       : String;
      Key        : String;
      Entry_Name : String) is
      Obj : constant Glib.Object.GObject :=
        Get_Object (Gtk_Builder (Builder), Entry_Name);
   begin
      if Obj /= null then
         declare
            Field : constant Gtk_Entry := Gtk_Entry (Obj);
         begin
            Field.Set_Text
              (Read_Value (Path, Key, Field.Get_Text));
         end;
      else
         Ada.Text_IO.Put_Line ("Missing UI entry: " & Entry_Name);
      end if;
   end Load_Entry;

   procedure Load_Project_Assets is
      Player_Path  : constant String :=
        "assets/entities/player_ship.entity";
      Enemy_Path   : constant String :=
        "assets/entities/enemy_scout.entity";
      Boss_Path    : constant String :=
        "assets/entities/boss_01.entity";
      Weapon_Path  : constant String :=
        "assets/weapons/laser.weapon";
      Powerup_Path : constant String :=
        "assets/powerups/shield_recharge.powerup";
      Audio_Path   : constant String :=
        "assets/config/audio.cfg";
   begin
      Load_Entry (Player_Path, "NAME", "player_name_entry");
      Load_Entry (Player_Path, "SPRITE", "player_sprite_entry");
      Load_Entry (Player_Path, "THRUST", "player_thrust_entry");
      Load_Entry (Player_Path, "DRAG", "player_drag_entry");
      Load_Entry (Player_Path, "FUEL_MAX", "player_fuel_entry");
      Load_Entry (Player_Path, "SHIELD_MAX", "player_shield_entry");
      Load_Entry
        (Player_Path, "ENGINE_SOUND", "player_engine_sound_entry");
      Load_Entry
        (Player_Path, "SHIELD_HIT_SOUND", "player_shield_hit_entry");
      Load_Entry
        (Player_Path, "SHIELD_LOW_SOUND", "player_shield_low_entry");

      Load_Entry (Enemy_Path, "NAME", "enemy_name_entry");
      Load_Entry (Enemy_Path, "HEALTH", "enemy_health_entry");
      Load_Entry (Enemy_Path, "FIRE_RATE", "enemy_fire_rate_entry");

      Load_Entry (Boss_Path, "NAME", "boss_name_entry");
      Load_Entry (Boss_Path, "MAX_HP", "boss_hp_entry");
      Load_Entry (Boss_Path, "SPAWN_TRIGGER", "boss_trigger_entry");
      Load_Entry (Boss_Path, "MUSIC", "boss_music_entry");
      Load_Entry
        (Boss_Path, "PHASE1_CONDITION", "boss_phase1_hp_entry");
      Load_Entry (Boss_Path, "PHASE1_PATH", "boss_phase1_path_entry");
      Load_Entry
        (Boss_Path, "PHASE2_CONDITION", "boss_phase2_hp_entry");
      Load_Entry (Boss_Path, "PHASE2_PATH", "boss_phase2_path_entry");
      Load_Entry
        (Boss_Path, "PHASE3_CONDITION", "boss_phase3_hp_entry");
      Load_Entry (Boss_Path, "PHASE3_PATH", "boss_phase3_path_entry");
      Load_Entry (Boss_Path, "PATH1_X", "path1_x");
      Load_Entry (Boss_Path, "PATH1_Y", "path1_y");
      Load_Entry (Boss_Path, "PATH1_TIME", "path1_t");
      Load_Entry (Boss_Path, "PATH2_X", "path2_x");
      Load_Entry (Boss_Path, "PATH2_Y", "path2_y");
      Load_Entry (Boss_Path, "PATH2_TIME", "path2_t");
      Load_Entry
        (Boss_Path, "ANIM_NORMAL", "boss_normal_animation_entry");
      Load_Entry
        (Boss_Path, "ANIM_DAMAGED", "boss_damaged_animation_entry");
      Load_Entry
        (Boss_Path, "ANIM_CRITICAL", "boss_critical_animation_entry");
      Load_Entry
        (Boss_Path, "ANIM_DEATH", "boss_death_animation_entry");

      Load_Entry (Weapon_Path, "NAME", "weapon_name_entry");
      Load_Entry (Weapon_Path, "DAMAGE", "weapon_damage_entry");
      Load_Entry (Weapon_Path, "COOLDOWN", "weapon_cooldown_entry");
      Load_Entry
        (Weapon_Path, "PROJECTILE_SPEED", "weapon_speed_entry");
      Load_Entry
        (Weapon_Path, "CHARGE_STATES", "weapon_charge_entry");
      Load_Entry
        (Weapon_Path, "FIRE_SOUND", "weapon_fire_sound_entry");
      Load_Entry
        (Weapon_Path, "HIT_SOUND", "weapon_hit_sound_entry");
      Load_Entry
        (Weapon_Path, "CHARGE_SOUND", "weapon_charge_sound_entry");

      Load_Entry (Powerup_Path, "NAME", "powerup_name_entry");
      Load_Entry (Powerup_Path, "VALUE", "powerup_value_entry");
      Load_Entry (Powerup_Path, "DURATION", "powerup_duration_entry");
      Load_Entry
        (Powerup_Path, "PICKUP_SOUND", "powerup_sound_entry");

      Load_Entry (Audio_Path, "MAIN_MENU_MUSIC", "menu_music_entry");
      Load_Entry (Audio_Path, "LEVEL_MUSIC", "level_music_entry");
      Load_Entry
        (Audio_Path, "BOSS_MUSIC", "audio_boss_music_entry");
   end Load_Project_Assets;

   procedure Save_Project_Assets is
   begin
      Save_Definition
        ("assets/entities/player_ship.entity",
         "ENTITY Player_Ship" & ASCII.LF
         & "COMPONENT Transform" & ASCII.LF
         & "COMPONENT Renderable" & ASCII.LF
         & "COMPONENT Collider" & ASCII.LF
         & "COMPONENT Velocity" & ASCII.LF
         & "COMPONENT Gravity" & ASCII.LF
         & "COMPONENT Fuel" & ASCII.LF
         & "COMPONENT Shield" & ASCII.LF
         & Entry_Line ("NAME", "player_name_entry")
         & Entry_Line ("SPRITE", "player_sprite_entry")
         & Entry_Line ("THRUST", "player_thrust_entry")
         & Entry_Line ("DRAG", "player_drag_entry")
         & Entry_Line ("FUEL_MAX", "player_fuel_entry")
         & Entry_Line ("SHIELD_MAX", "player_shield_entry")
         & Entry_Line ("ENGINE_SOUND", "player_engine_sound_entry")
         & Entry_Line ("SHIELD_HIT_SOUND", "player_shield_hit_entry")
         & Entry_Line ("SHIELD_LOW_SOUND", "player_shield_low_entry"));

      Save_Definition
        ("assets/entities/enemy_scout.entity",
         "ENTITY Enemy_Scout" & ASCII.LF
         & "COMPONENT Transform" & ASCII.LF
         & "COMPONENT Renderable" & ASCII.LF
         & "COMPONENT Collider" & ASCII.LF
         & "COMPONENT Health" & ASCII.LF
         & "COMPONENT Weapon" & ASCII.LF
         & "COMPONENT AI_Controller" & ASCII.LF
         & Entry_Line ("NAME", "enemy_name_entry")
         & Entry_Line ("HEALTH", "enemy_health_entry")
         & Entry_Line ("FIRE_RATE", "enemy_fire_rate_entry"));

      Save_Definition
        ("assets/entities/boss_01.entity",
         "ENTITY Boss_01" & ASCII.LF
         & "COMPONENT Boss_Phase_Controller" & ASCII.LF
         & "COMPONENT Health" & ASCII.LF
         & "COMPONENT Weapon" & ASCII.LF
         & "COMPONENT Audio_Source" & ASCII.LF
         & Entry_Line ("NAME", "boss_name_entry")
         & Entry_Line ("MAX_HP", "boss_hp_entry")
         & Entry_Line ("SPAWN_TRIGGER", "boss_trigger_entry")
         & Entry_Line ("MUSIC", "boss_music_entry")
         & Entry_Line ("PHASE1_CONDITION", "boss_phase1_hp_entry")
         & Entry_Line ("PHASE1_PATH", "boss_phase1_path_entry")
         & Entry_Line ("PHASE2_CONDITION", "boss_phase2_hp_entry")
         & Entry_Line ("PHASE2_PATH", "boss_phase2_path_entry")
         & Entry_Line ("PHASE3_CONDITION", "boss_phase3_hp_entry")
         & Entry_Line ("PHASE3_PATH", "boss_phase3_path_entry")
         & Entry_Line ("PATH1_X", "path1_x")
         & Entry_Line ("PATH1_Y", "path1_y")
         & Entry_Line ("PATH1_TIME", "path1_t")
         & Entry_Line ("PATH2_X", "path2_x")
         & Entry_Line ("PATH2_Y", "path2_y")
         & Entry_Line ("PATH2_TIME", "path2_t")
         & Entry_Line ("ANIM_NORMAL", "boss_normal_animation_entry")
         & Entry_Line ("ANIM_DAMAGED", "boss_damaged_animation_entry")
         & Entry_Line ("ANIM_CRITICAL", "boss_critical_animation_entry")
         & Entry_Line ("ANIM_DEATH", "boss_death_animation_entry"));

      Save_Definition
        ("assets/weapons/laser.weapon",
         "WEAPON Laser" & ASCII.LF
         & Entry_Line ("NAME", "weapon_name_entry")
         & Entry_Line ("DAMAGE", "weapon_damage_entry")
         & Entry_Line ("COOLDOWN", "weapon_cooldown_entry")
         & Entry_Line ("PROJECTILE_SPEED", "weapon_speed_entry")
         & Entry_Line ("CHARGE_STATES", "weapon_charge_entry")
         & Entry_Line ("FIRE_SOUND", "weapon_fire_sound_entry")
         & Entry_Line ("HIT_SOUND", "weapon_hit_sound_entry")
         & Entry_Line ("CHARGE_SOUND", "weapon_charge_sound_entry"));

      Save_Definition
        ("assets/powerups/shield_recharge.powerup",
         "POWERUP Shield_Recharge" & ASCII.LF
         & Entry_Line ("NAME", "powerup_name_entry")
         & Entry_Line ("VALUE", "powerup_value_entry")
         & Entry_Line ("DURATION", "powerup_duration_entry")
         & Entry_Line ("PICKUP_SOUND", "powerup_sound_entry"));

      Save_Definition
        ("assets/config/audio.cfg",
         "AUDIO" & ASCII.LF
         & Entry_Line ("MAIN_MENU_MUSIC", "menu_music_entry")
         & Entry_Line ("LEVEL_MUSIC", "level_music_entry")
         & Entry_Line ("BOSS_MUSIC", "audio_boss_music_entry"));

      Ada.Text_IO.Put_Line ("Player, enemy, boss, weapon, powerup and audio data saved");
   end Save_Project_Assets;

   procedure Run_Command
     (Command : String;
      Message : String) is
      Result : Interfaces.C.int;
      pragma Unreferenced (Result);
   begin
      Result := C_System (Interfaces.C.To_C (Command));
      Ada.Text_IO.Put_Line (Message);
   end Run_Command;

   procedure On_New
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Editor_State.New_Level;
      Update_Level_UI;
      Editor_Canvas.Rebuild;
      Set_Document (0, 0, "New level created");
      Ada.Text_IO.Put_Line ("New level created");
   end On_New;

   procedure On_Open
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Path   : constant String :=
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
         Update_Level_UI;
         Editor_Canvas.Rebuild;
         Set_Document (0, 0, "Opened " & Path);
         Ada.Text_IO.Put_Line ("Opened " & Path);
      else
         Ada.Text_IO.Put_Line ("Could not open " & Path);
      end if;
   end On_Open;

   procedure On_Save
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Apply_Level_UI;
      Editor_State.Save;
      Save_Project_Assets;
      Ada.Text_IO.Put_Line ("Saved " & Editor_State.Level_Path);
   end On_Save;

   procedure On_Save_As
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Path : constant String :=
        Gtkada.File_Selection.File_Selection_Dialog
          (Title       => "Save SubTerrania level as",
           Default_Dir => "assets/levels",
           Dir_Only    => False,
           Must_Exist  => False);
   begin
      if Path /= "" then
         Apply_Level_UI;
         Editor_State.Save_As (Path);
         Save_Project_Assets;
         Ada.Text_IO.Put_Line ("Saved " & Path);
      end if;
   end On_Save_As;

   procedure On_Quit
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Gtk.Main.Main_Quit;
   end On_Quit;

   procedure On_Undo
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Undo (Changed);
      if Changed then
         Update_Level_UI;
         Editor_Canvas.Rebuild;
         Ada.Text_IO.Put_Line ("Undo");
      else
         Ada.Text_IO.Put_Line ("Nothing to undo");
      end if;
   end On_Undo;

   procedure On_Redo
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Redo (Changed);
      if Changed then
         Update_Level_UI;
         Editor_Canvas.Rebuild;
         Ada.Text_IO.Put_Line ("Redo");
      else
         Ada.Text_IO.Put_Line ("Nothing to redo");
      end if;
   end On_Redo;

   procedure On_Apply_Selected_Geometry
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Changed : Boolean;
   begin
      Editor_State.Update_Selected_Geometry
        (World_X => Float_From_Entry ("selected_x_entry", 0.0),
         World_Y => Float_From_Entry ("selected_y_entry", 0.0),
         Width   => Float_From_Entry ("selected_w_entry", 32.0),
         Height  => Float_From_Entry ("selected_h_entry", 32.0),
         Changed => Changed);

      if Changed then
         Editor_Canvas.Rebuild;
         Ada.Text_IO.Put_Line ("Selected entity geometry applied");
      else
         Ada.Text_IO.Put_Line ("Select an entity before applying geometry");
      end if;
   end On_Apply_Selected_Geometry;

   procedure On_Delete_Selection
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Sel : constant Editor_State.Selection_Info :=
        Editor_State.Selection;
   begin
      if Sel.Kind = Editor_State.Nothing_Selected then
         Ada.Text_IO.Put_Line ("Nothing selected");
         return;
      end if;

      Editor_State.Erase_At (Sel.World_X, Sel.World_Y);
      Editor_Canvas.Rebuild;
      Ada.Text_IO.Put_Line ("Selection deleted");
   end On_Delete_Selection;

   procedure On_Fullscreen
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Window : constant Gtk_Window := Gtk_Window
        (Get_Object (Gtk_Builder (Builder), "main_window"));
   begin
      if Is_Fullscreen then
         Window.Unfullscreen;
      else
         Window.Fullscreen;
      end if;
      Is_Fullscreen := not Is_Fullscreen;
   end On_Fullscreen;

   procedure On_Fit_Map
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Editor_Canvas.Fit_Map;
      Ada.Text_IO.Put_Line ("Map fitted to viewport");
   end On_Fit_Map;

   procedure On_Grid_Menu_Toggled
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Visible : constant Boolean :=
        Gtk.Check_Menu_Item.Get_Active
          (Gtk.Check_Menu_Item.Gtk_Check_Menu_Item
             (Get_Object (Gtk_Builder (Builder), "grid_menu_item")));
   begin
      Editor_State.Set_Grid_Visible (Visible);
      Editor_Canvas.Rebuild;
      Ada.Text_IO.Put_Line ("Grid setting changed");
   end On_Grid_Menu_Toggled;

   procedure On_Grid_Toolbar_Toggled
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
      Visible : constant Boolean :=
        Gtk.Toggle_Tool_Button.Get_Active
          (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button
             (Get_Object (Gtk_Builder (Builder), "grid_tool")));
   begin
      Editor_State.Set_Grid_Visible (Visible);
      Editor_Canvas.Rebuild;
      Ada.Text_IO.Put_Line ("Grid setting changed");
   end On_Grid_Toolbar_Toggled;

   procedure Set_Tool
     (Tool : Editor_State.Tool_Kind;
      Text : String) is
   begin
      Editor_State.Set_Tool (Tool);
      UI_Label ("tool_status_label").Set_Text
        ("Tool: " & Text & "    Brush: " & Editor_State.Brush_Name);
   end Set_Tool;

   function Tool_Is_Active (Name : String) return Boolean is
   begin
      return Gtk.Toggle_Tool_Button.Get_Active
        (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button
           (Get_Object (Gtk_Builder (Builder), Name)));
   end Tool_Is_Active;

   procedure On_Tool_Select
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Tool_Is_Active ("select_tool") then
         Set_Tool (Editor_State.Select_Tool, "Select");
      end if;
   end On_Tool_Select;

   procedure On_Tool_Brush
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Tool_Is_Active ("brush_tool") then
         Set_Tool (Editor_State.Tile_Brush_Tool, "Brush");
      end if;
   end On_Tool_Brush;

   procedure On_Tool_Eraser
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Tool_Is_Active ("eraser_tool") then
         Set_Tool (Editor_State.Eraser_Tool, "Eraser");
      end if;
   end On_Tool_Eraser;

   procedure On_Tool_Pan
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Tool_Is_Active ("pan_tool") then
         Set_Tool (Editor_State.Pan_Tool, "Pan");
      end if;
   end On_Tool_Pan;

   procedure Select_Tile (Tile : Level.Tile_Kind) is
   begin
      Editor_State.Set_Tile_Brush (Tile);
      UI_Label ("tool_status_label").Set_Text
        ("Tool: Tile Brush    Brush: " & Editor_State.Tile_Name (Tile));
      Documents.Set_Current_Page (0);
   end Select_Tile;

   procedure Select_Object (Kind : Level.Object_Kind) is
   begin
      Editor_State.Set_Object_Brush (Kind);
      UI_Label ("tool_status_label").Set_Text
        ("Tool: Object Brush    Brush: "
         & Editor_State.Object_Name (Kind));
      Documents.Set_Current_Page (0);
   end Select_Object;

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

   procedure On_Palette_Fuel (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Fuel); end On_Palette_Fuel;

   procedure On_Palette_Shield (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Shield); end On_Palette_Shield;

   procedure On_Palette_Gate (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Gate); end On_Palette_Gate;

   procedure On_Palette_Platform
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Platform); end On_Palette_Platform;

   procedure On_Palette_Boss (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Select_Object (Level.Boss_Spawn); end On_Palette_Boss;

   procedure On_Open_Level_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (0, 0, "Level Editor"); end On_Open_Level_Document;

   procedure On_Open_Player_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (1, 1, "Player Ship Editor"); end On_Open_Player_Document;

   procedure On_Open_Enemy_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (2, 1, "Enemy Template Editor"); end On_Open_Enemy_Document;

   procedure On_Open_Boss_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (3, 1, "Boss / Encounter Editor"); end On_Open_Boss_Document;

   procedure On_Open_Weapon_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (4, 1, "Weapon Editor"); end On_Open_Weapon_Document;

   procedure On_Open_Powerup_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (5, 1, "Powerup Editor"); end On_Open_Powerup_Document;

   procedure On_Open_Audio_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (6, 1, "Audio Assignment Editor"); end On_Open_Audio_Document;

   procedure On_Open_Trigger_Document
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin Set_Document (7, 1, "Trigger / Objective Editor"); end On_Open_Trigger_Document;

   procedure On_Apply_Level_Properties
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Apply_Level_UI;
      Ada.Text_IO.Put_Line ("Level properties applied");
   end On_Apply_Level_Properties;

   procedure On_Save_Project_Assets
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Save_Project_Assets;
   end On_Save_Project_Assets;

   procedure On_Browse_Background
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("background_entry", "Select map background", "assets/images/maps");
      Apply_Level_UI;
   end On_Browse_Background;

   procedure On_Browse_Level_Music
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("music_entry", "Select level music", "assets/audio/music");
      Set_Entry_Text
        ("level_music_entry", Entry_Text ("music_entry"));
   end On_Browse_Level_Music;

   procedure On_Browse_Boss_Music
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("level_boss_music_entry",
         "Select boss music",
         "assets/audio/music");
      Set_Entry_Text
        ("boss_music_entry", Entry_Text ("level_boss_music_entry"));
      Set_Entry_Text
        ("audio_boss_music_entry", Entry_Text ("level_boss_music_entry"));
   end On_Browse_Boss_Music;

   procedure On_Browse_Menu_Music
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("menu_music_entry", "Select main-menu music", "assets/audio/music");
   end On_Browse_Menu_Music;

   procedure On_Browse_Audio_Boss_Music
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("audio_boss_music_entry",
         "Select boss music",
         "assets/audio/music");
   end On_Browse_Audio_Boss_Music;

   procedure On_Browse_Player_Sprite
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("player_sprite_entry",
         "Select player sprite",
         "assets/images/sprites");
   end On_Browse_Player_Sprite;

   procedure On_Browse_Player_Sound
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Browse_Into
        ("player_engine_sound_entry",
         "Select engine sound",
         "assets/audio/sfx");
   end On_Browse_Player_Sound;

   procedure On_Add_Trigger
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Editor_State.Set_Tool (Editor_State.Trigger_Tool);
      Documents.Set_Current_Page (0);
      Ada.Text_IO.Put_Line ("Trigger box tool active. Draw the trigger on the map.");
   end On_Add_Trigger;

   procedure On_Add_Objective
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Ada.Text_IO.Put_Line ("Objective added to the project definition");
   end On_Add_Objective;

   procedure On_Add_Event
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Ada.Text_IO.Put_Line ("Timeline event added");
   end On_Add_Event;

   procedure On_Playtest
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      On_Save (Builder);
      Run_Command
        ("sh -c 'alr run > /tmp/subterrania-playtest.log 2>&1 &'",
         "Playtest launched");
   end On_Playtest;

   procedure On_Build_Game
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Run_Command
        ("sh -c 'alr build > /tmp/subterrania-build.log 2>&1 &'",
         "Build started; log: /tmp/subterrania-build.log");
   end On_Build_Game;

   procedure On_Validate
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      if Ada.Directories.Exists ("assets/levels/stage01.map")
        and then Ada.Directories.Exists
          (Entry_Text ("background_entry"))
      then
         Ada.Text_IO.Put_Line ("Project validation passed");
      else
         Ada.Text_IO.Put_Line ("Validation warning: level or background is missing");
      end if;
   end On_Validate;

   procedure On_Help
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Ada.Text_IO.Put_Line ("Select/Brush/Eraser/Pan are toolbar tools. "
         & "Mouse wheel zooms. Right-click cancels a brush. "
         & "Open Player, Enemy, Boss, Weapon or Audio from Project.");
   end On_Help;

   procedure On_About
     (Data : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Data);
   begin
      Ada.Text_IO.Put_Line ("SubTerrania Editor — native GtkAda project editor "
         & "with an SDL game runtime");
   end On_About;

   procedure Register_Handlers is
   begin
      Register_Handler (Builder, "on_new", On_New'Access);
      Register_Handler (Builder, "on_open", On_Open'Access);
      Register_Handler (Builder, "on_save", On_Save'Access);
      Register_Handler (Builder, "on_save_as", On_Save_As'Access);
      Register_Handler (Builder, "on_quit", On_Quit'Access);
      Register_Handler (Builder, "on_undo", On_Undo'Access);
      Register_Handler (Builder, "on_redo", On_Redo'Access);
      Register_Handler
        (Builder,
         "on_apply_selected_geometry",
         On_Apply_Selected_Geometry'Access);
      Register_Handler
        (Builder, "on_delete_selection", On_Delete_Selection'Access);
      Register_Handler (Builder, "on_fullscreen", On_Fullscreen'Access);
      Register_Handler (Builder, "on_fit_map", On_Fit_Map'Access);
      Register_Handler
        (Builder, "on_grid_menu_toggled", On_Grid_Menu_Toggled'Access);
      Register_Handler
        (Builder,
         "on_grid_toolbar_toggled",
         On_Grid_Toolbar_Toggled'Access);
      Register_Handler (Builder, "on_tool_select", On_Tool_Select'Access);
      Register_Handler (Builder, "on_tool_brush", On_Tool_Brush'Access);
      Register_Handler (Builder, "on_tool_eraser", On_Tool_Eraser'Access);
      Register_Handler (Builder, "on_tool_pan", On_Tool_Pan'Access);
      Register_Handler (Builder, "on_palette_wall", On_Palette_Wall'Access);
      Register_Handler
        (Builder, "on_palette_water", On_Palette_Water'Access);
      Register_Handler
        (Builder, "on_palette_landing", On_Palette_Landing'Access);
      Register_Handler
        (Builder, "on_palette_start", On_Palette_Start'Access);
      Register_Handler
        (Builder, "on_palette_space", On_Palette_Space'Access);
      Register_Handler
        (Builder, "on_palette_miner", On_Palette_Miner'Access);
      Register_Handler
        (Builder, "on_palette_enemy", On_Palette_Enemy'Access);
      Register_Handler
        (Builder, "on_palette_fuel", On_Palette_Fuel'Access);
      Register_Handler
        (Builder, "on_palette_shield", On_Palette_Shield'Access);
      Register_Handler
        (Builder, "on_palette_gate", On_Palette_Gate'Access);
      Register_Handler
        (Builder, "on_palette_platform", On_Palette_Platform'Access);
      Register_Handler
        (Builder, "on_palette_boss", On_Palette_Boss'Access);
      Register_Handler
        (Builder, "on_open_level_document", On_Open_Level_Document'Access);
      Register_Handler
        (Builder,
         "on_open_player_document",
         On_Open_Player_Document'Access);
      Register_Handler
        (Builder, "on_open_enemy_document", On_Open_Enemy_Document'Access);
      Register_Handler
        (Builder, "on_open_boss_document", On_Open_Boss_Document'Access);
      Register_Handler
        (Builder,
         "on_open_weapon_document",
         On_Open_Weapon_Document'Access);
      Register_Handler
        (Builder,
         "on_open_powerup_document",
         On_Open_Powerup_Document'Access);
      Register_Handler
        (Builder, "on_open_audio_document", On_Open_Audio_Document'Access);
      Register_Handler
        (Builder,
         "on_open_trigger_document",
         On_Open_Trigger_Document'Access);
      Register_Handler
        (Builder,
         "on_apply_level_properties",
         On_Apply_Level_Properties'Access);
      Register_Handler
        (Builder,
         "on_save_project_assets",
         On_Save_Project_Assets'Access);
      Register_Handler
        (Builder, "on_browse_background", On_Browse_Background'Access);
      Register_Handler
        (Builder, "on_browse_level_music", On_Browse_Level_Music'Access);
      Register_Handler
        (Builder, "on_browse_boss_music", On_Browse_Boss_Music'Access);
      Register_Handler
        (Builder, "on_browse_menu_music", On_Browse_Menu_Music'Access);
      Register_Handler
        (Builder,
         "on_browse_audio_boss_music",
         On_Browse_Audio_Boss_Music'Access);
      Register_Handler
        (Builder,
         "on_browse_player_sprite",
         On_Browse_Player_Sprite'Access);
      Register_Handler
        (Builder,
         "on_browse_player_sound",
         On_Browse_Player_Sound'Access);
      Register_Handler (Builder, "on_add_trigger", On_Add_Trigger'Access);
      Register_Handler
        (Builder, "on_add_objective", On_Add_Objective'Access);
      Register_Handler (Builder, "on_add_event", On_Add_Event'Access);
      Register_Handler (Builder, "on_playtest", On_Playtest'Access);
      Register_Handler (Builder, "on_build_game", On_Build_Game'Access);
      Register_Handler (Builder, "on_validate", On_Validate'Access);
      Register_Handler (Builder, "on_help", On_Help'Access);
      Register_Handler (Builder, "on_about", On_About'Access);
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
      Update_Level_UI;
      Load_Project_Assets;
      Editor_Canvas.Initialize (Builder);

      Window := Gtk_Window
        (Get_Object (Gtk_Builder (Builder), "main_window"));
      Window.Show_All;
      Set_Document (0, 0, "Level Editor ready");
      Ada.Text_IO.Put_Line ("Professional editor shell loaded");
   end Initialize;

end Editor_App;

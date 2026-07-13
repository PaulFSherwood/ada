with Ada.Text_IO; use Ada.Text_IO;

with Audio;
with SDL;
with SDL.Video;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;

with Collision;
with Gameplay;
with Inputs;
with Level;
with Movement;
with Render;

package body Application is

   package EM renames ECS.Entity_System.Entity_Manager;
   package Render_System renames Render;

   use type Level.Game_Mode;
   use type Level.Brush_Mode;
   use type Level.Tile_Kind;
   use type Gameplay.Editor_View;

   type Screen_Mode is
     (Main_Menu_Screen,
      Load_Menu_Screen,
      Play_Screen,
      Map_Editor_Screen,
      Editor_Playtest_Screen);

   Screen_Width  : constant Natural := 800;
   Screen_Height : constant Natural := 600;

   DT             : constant Float := 1.0 / 60.0;
   Max_Fall_Speed : constant Float := 240.0;

   Map_Path : constant String := "level01.map";

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;

   Tiles         : Level.Tile_Map;
   Objects       : Level.Object_Array;
   Current_Level : Level.Level_Info := Level.Default_Level_Info;

   Mode  : Level.Game_Mode := Level.Play_Mode;
   Brush : Level.Brush_Mode := Level.Tile_Brush;

   Current_Screen : Screen_Mode := Main_Menu_Screen;
   Main_Menu_Item : Positive := 1;
   Load_Menu_Item : Positive := 1;

   Cursor_X       : Float := 400.0;
   Cursor_Y       : Float := 300.0;
   Cursor_Step    : constant Float := 16.0;
   Current_Tile   : Level.Tile_Kind := Level.Wall_Tile;
   Current_Kind   : Level.Object_Kind := Level.Miner;
   Current_Motion : Level.Motion_Kind := Level.Static;
   Current_View   : Gameplay.Editor_View := Gameplay.Terrain_View;

   Status : Gameplay.Player_Status;

   Spawn_X : Float := 400.0;
   Spawn_Y : Float := 300.0;

   Camera_X : Float := 0.0;
   Camera_Y : Float := 0.0;

   function Current_Input_Context return Inputs.Input_Context is
   begin
      case Current_Screen is
         when Main_Menu_Screen | Load_Menu_Screen =>
            return Inputs.Menu_Context;

         when Play_Screen | Editor_Playtest_Screen =>
            return Inputs.Play_Context;

         when Map_Editor_Screen =>
            return Inputs.Editor_Context;
      end case;
   end Current_Input_Context;

   procedure Advance_Menu_Item
     (Item      : in out Positive;
      Count     : Positive;
      Direction : Integer) is
   begin
      if Direction < 0 then
         if Item = 1 then
            Item := Count;
         else
            Item := Item - 1;
         end if;
      elsif Direction > 0 then
         if Item = Count then
            Item := 1;
         else
            Item := Item + 1;
         end if;
      end if;
   end Advance_Menu_Item;

   procedure Sync_Gravity_Component
     (Gravity_On : Boolean) is
   begin
      if Gravity_On then
         if not EM.Has_Gravity (Mgr, Player) then
            EM.Add_Gravity (Mgr, Player);
         end if;
      else
         EM.Remove_Gravity (Mgr, Player);
      end if;
   end Sync_Gravity_Component;

   function Gravity_Is_On return Boolean is
   begin
      return EM.Has_Gravity (Mgr, Player);
   end Gravity_Is_On;

   procedure Reset_Player is
      T : constant EM.Transform_Map.Reference_Type :=
        EM.Get_Transform (Mgr, Player);
      V : constant EM.Velocity_Map.Reference_Type :=
        EM.Get_Velocity (Mgr, Player);
   begin
      T.Element.all.X := Spawn_X;
      T.Element.all.Y := Spawn_Y;
      V.Element.all.X := 0.0;
      V.Element.all.Y := 0.0;
      Sync_Gravity_Component (True);
   end Reset_Player;

   procedure Configure_Player_From_Map is
      Found : Boolean;
   begin
      Found := Level.Find_Player_Start (Tiles, Spawn_X, Spawn_Y);

      if Found then
         Reset_Player;
         Sync_Gravity_Component (False);
         Put_Line ("Player start found");
      else
         Reset_Player;
      end if;
   end Configure_Player_From_Map;

   procedure Update_Camera is
      T : constant EM.Transform_Map.Reference_Type :=
        EM.Get_Transform (Mgr, Player);
      Max_X : constant Float := Level.World_Width - Float (Screen_Width);
      Max_Y : constant Float := Level.World_Height - Float (Screen_Height);
   begin
      Camera_X := T.Element.all.X - Float (Screen_Width) / 2.0;
      Camera_Y := T.Element.all.Y - Float (Screen_Height) / 2.0;

      if Camera_X < 0.0 then
         Camera_X := 0.0;
      elsif Camera_X > Max_X then
         Camera_X := Max_X;
      end if;

      if Camera_Y < 0.0 then
         Camera_Y := 0.0;
      elsif Camera_Y > Max_Y then
         Camera_Y := Max_Y;
      end if;
   end Update_Camera;

   procedure Start_Editor_Playtest is
   begin
      Configure_Player_From_Map;
      Gameplay.Reset_For_Level (Status, Objects);
      Update_Camera;
      Mode := Level.Play_Mode;
      Current_Screen := Editor_Playtest_Screen;
      Audio.Play_Music (Audio.Mission_One_Music);
      Put_Line ("EDITOR PLAYTEST");
   end Start_Editor_Playtest;

   procedure Return_To_Editor is
   begin
      Mode := Level.Editor_Mode;
      Current_Screen := Map_Editor_Screen;
      Cursor_X := Spawn_X;
      Cursor_Y := Spawn_Y;
      Audio.Play_Music (Audio.Editor_Music);
      Put_Line ("MAP EDITOR");
   end Return_To_Editor;

   procedure Toggle_Brush is
   begin
      if Brush = Level.Tile_Brush then
         Brush := Level.Object_Brush;
         Put_Line ("OBJECT BRUSH");
      else
         Brush := Level.Tile_Brush;
         Put_Line ("TILE BRUSH");
      end if;
   end Toggle_Brush;

   procedure Start_Game
     (Load_First : Boolean) is
      Loaded : Boolean := False;
   begin
      if Load_First then
         Level.Load_Level
           (Tiles,
            Objects,
            Current_Level,
            Map_Path,
            Loaded);

         if Loaded then
            Audio.Play_Sound (Audio.Level_Loaded);
         else
            Level.Build_Test_Level (Tiles, Objects, Current_Level);
         end if;
      end if;

      Configure_Player_From_Map;
      Gameplay.Reset_For_Level (Status, Objects);
      Update_Camera;
      Mode := Level.Play_Mode;
      Current_Screen := Play_Screen;
      Audio.Play_Music (Audio.Mission_One_Music);
   end Start_Game;

   procedure Start_Editor is
      Loaded : Boolean := False;
   begin
      Level.Load_Level
        (Tiles,
         Objects,
         Current_Level,
         Map_Path,
         Loaded);

      if not Loaded then
         Level.Build_Test_Level (Tiles, Objects, Current_Level);
      end if;

      Configure_Player_From_Map;
      Gameplay.Reset_For_Level (Status, Objects);
      Update_Camera;
      Mode := Level.Editor_Mode;
      Current_Screen := Map_Editor_Screen;
      Cursor_X := Spawn_X;
      Cursor_Y := Spawn_Y;
      Audio.Play_Music (Audio.Editor_Music);
   end Start_Editor;

   procedure Return_To_Main_Menu is
   begin
      Current_Screen := Main_Menu_Screen;
      Mode := Level.Play_Mode;
      Audio.Play_Music (Audio.Menu_Music);
   end Return_To_Main_Menu;

   procedure Handle_Main_Menu_Input
     (State : Inputs.Input_State) is
   begin
      if State.Menu_Up then
         Advance_Menu_Item (Main_Menu_Item, 4, -1);
         Audio.Play_Sound (Audio.Menu_Move);
      end if;

      if State.Menu_Down then
         Advance_Menu_Item (Main_Menu_Item, 4, 1);
         Audio.Play_Sound (Audio.Menu_Move);
      end if;

      if State.Menu_Select then
         Audio.Play_Sound (Audio.Menu_Select);

         case Main_Menu_Item is
            when 1 =>
               Start_Game (Load_First => False);

            when 2 =>
               Current_Screen := Load_Menu_Screen;
               Load_Menu_Item := 1;

            when 3 =>
               Start_Editor;

            when others =>
               Running := False;
         end case;
      end if;
   end Handle_Main_Menu_Input;

   procedure Handle_Load_Menu_Input
     (State : Inputs.Input_State) is
   begin
      if State.Menu_Up then
         Advance_Menu_Item (Load_Menu_Item, 2, -1);
         Audio.Play_Sound (Audio.Menu_Move);
      end if;

      if State.Menu_Down then
         Advance_Menu_Item (Load_Menu_Item, 2, 1);
         Audio.Play_Sound (Audio.Menu_Move);
      end if;

      if State.Menu_Back then
         Return_To_Main_Menu;
      end if;

      if State.Menu_Select then
         Audio.Play_Sound (Audio.Menu_Select);

         case Load_Menu_Item is
            when 1 =>
               Start_Game (Load_First => True);

            when others =>
               Return_To_Main_Menu;
         end case;
      end if;
   end Handle_Load_Menu_Input;

   procedure Handle_Editor_Input
     (State : Inputs.Input_State) is
      Deleted : Boolean := False;
      Loaded  : Boolean := False;
   begin
      if State.Cursor_DX /= 0.0 or else State.Cursor_DY /= 0.0 then
         Cursor_X := Cursor_X + State.Cursor_DX * Cursor_Step;
         Cursor_Y := Cursor_Y + State.Cursor_DY * Cursor_Step;
         Level.Clamp_Point
           (Cursor_X,
            Cursor_Y,
            Level.World_Width,
            Level.World_Height);
      end if;

      if State.Toggle_Brush then
         Toggle_Brush;
      end if;

      if State.Next_Tile then
         Current_Tile := Level.Next_Tile (Current_Tile);
         Put_Line ("Tile " & Level.Tile_Kind'Image (Current_Tile));
      end if;

      if State.Next_Kind then
         Current_Kind := Level.Next_Kind (Current_Kind);
         Put_Line ("Object " & Level.Object_Kind'Image (Current_Kind));
      end if;

      if State.Next_Motion then
         Current_Motion := Level.Next_Motion (Current_Motion);
         Put_Line ("Motion " & Level.Motion_Kind'Image (Current_Motion));
      end if;

      if State.Next_View then
         Current_View := Gameplay.Next_View (Current_View);
         Put_Line ("View " & Gameplay.View_Name (Current_View));
      end if;

      if State.Place then
         if Brush = Level.Tile_Brush then
            Level.Set_Tile_At_World
              (Tiles,
               Cursor_X,
               Cursor_Y,
               Current_Tile);

            if Current_Tile = Level.Start_Tile then
               Configure_Player_From_Map;
               Update_Camera;
            end if;
         else
            Level.Add_Object
              (Objects,
               Current_Kind,
               Cursor_X,
               Cursor_Y,
               Current_Motion);
         end if;
      end if;

      if State.Delete then
         if Brush = Level.Tile_Brush then
            Level.Set_Tile_At_World
              (Tiles,
               Cursor_X,
               Cursor_Y,
               Level.Space_Tile);
         else
            Level.Delete_Object_At (Objects, Cursor_X, Cursor_Y, Deleted);
            if Deleted then
               Put_Line ("Deleted object");
            end if;
         end if;
      end if;

      if State.Save_Level then
         Level.Save_Level (Tiles, Objects, Current_Level, Map_Path);
         Audio.Play_Sound (Audio.Level_Saved);
      end if;

      if State.Load_Level then
         Level.Load_Level
           (Tiles,
            Objects,
            Current_Level,
            Map_Path,
            Loaded);
         if Loaded then
            Configure_Player_From_Map;
            Audio.Play_Sound (Audio.Level_Loaded);
         end if;
      end if;
   end Handle_Editor_Input;

   procedure Apply_Play_Input
     (State : Inputs.Input_State) is
      V : constant EM.Velocity_Map.Reference_Type :=
        EM.Get_Velocity (Mgr, Player);
      Gravity_On : constant Boolean := Gravity_Is_On;
   begin
      if State.Thrust and then not Gravity_On then
         Sync_Gravity_Component (True);
      end if;

      Movement.Apply_Player_Input
        (V.Element.all,
         Gravity_Is_On,
         State.Thrust,
         State.Brake,
         State.Turn_Left,
         State.Turn_Right,
         DT,
         Gameplay.Thrust_Multiplier (Status));
   end Apply_Play_Input;

   procedure Init is
   begin
      if not SDL.Initialise (Flags => SDL.Enable_Screen) then
         Running := False;
         return;
      end if;

      SDL.Video.Windows.Makers.Create
        (Win      => Window,
         Title    => "Ada SubTerrania",
         Position => SDL.Natural_Coordinates'(X => 50, Y => 50),
         Size     =>
           SDL.Positive_Sizes'
             (SDL.Dimension (Screen_Width),
              SDL.Dimension (Screen_Height)),
         Flags    => 0);

      SDL.Video.Renderers.Makers.Create (Renderer, Window.Get_Surface);
      Audio.Initialise;

      EM.Initialize (Mgr);

      Player := EM.Create_Entity (Mgr);
      EM.Add_Transform (Mgr, Player);
      EM.Add_Velocity (Mgr, Player);
      EM.Add_Collider (Mgr, Player);
      EM.Add_Renderable (Mgr, Player);
      EM.Add_Gravity (Mgr, Player);

      declare
         T : constant EM.Transform_Map.Reference_Type :=
           EM.Get_Transform (Mgr, Player);
         R : constant EM.Renderable_Map.Reference_Type :=
           EM.Get_Renderable (Mgr, Player);
         C : constant EM.Collider_Map.Reference_Type :=
           EM.Get_Collider (Mgr, Player);
      begin
         R.Element.all.Width := 19.0;
         R.Element.all.Height := 19.0;
         R.Element.all.Red := 255;
         R.Element.all.Green := 0;
         R.Element.all.Blue := 200;
         R.Element.all.Alpha := 255;

         C.Element.all.Width := R.Element.all.Width;
         C.Element.all.Height := R.Element.all.Height;

         T.Element.all.Rotation := 0.0;
      end;

      declare
         Loaded : Boolean := False;
      begin
         Level.Load_Level
           (Tiles,
            Objects,
            Current_Level,
            Map_Path,
            Loaded);

         if not Loaded then
            Level.Build_Test_Level (Tiles, Objects, Current_Level);
         end if;
      end;

      Configure_Player_From_Map;
      Gameplay.Reset_For_Level (Status, Objects);
      Update_Camera;
      Current_Screen := Main_Menu_Screen;
      Audio.Play_Music (Audio.Menu_Music);
   end Init;

   procedure Update is
      State : Inputs.Input_State;
      T     : constant EM.Transform_Map.Reference_Type :=
        EM.Get_Transform (Mgr, Player);
      V     : constant EM.Velocity_Map.Reference_Type :=
        EM.Get_Velocity (Mgr, Player);
      C     : constant EM.Collider_Map.Reference_Type :=
        EM.Get_Collider (Mgr, Player);
      Result : Collision.Collision_Result;
      Gravity_On : Boolean := Gravity_Is_On;
   begin
      Inputs.Poll_Events
        (State,
         Current_Input_Context,
         Brush);

      if State.Quit_Requested then
         Running := False;
      end if;

      case Current_Screen is
         when Main_Menu_Screen =>
            Handle_Main_Menu_Input (State);

         when Load_Menu_Screen =>
            Handle_Load_Menu_Input (State);

         when Map_Editor_Screen =>
            if State.Menu_Back then
               Return_To_Main_Menu;
            elsif State.Toggle_Mode then
               Start_Editor_Playtest;
            else
               Handle_Editor_Input (State);
            end if;

         when Play_Screen | Editor_Playtest_Screen =>
            if State.Menu_Back then
               if Current_Screen = Editor_Playtest_Screen then
                  Return_To_Editor;
               else
                  Return_To_Main_Menu;
               end if;
            elsif State.Toggle_Mode
              and then Current_Screen = Editor_Playtest_Screen
            then
               Return_To_Editor;
            else
               Apply_Play_Input (State);

               Gravity_On := Gravity_Is_On;

               if Gravity_On then
                  declare
                     G : constant EM.Gravity_Map.Reference_Type :=
                       EM.Get_Gravity (Mgr, Player);
                  begin
                     Movement.Configure_Gravity
                       (G.Element.all,
                        Tiles,
                        T.Element.all);
                     Movement.Apply_Gravity
                       (V.Element.all,
                        G.Element.all,
                        Max_Fall_Speed,
                        DT);
                  end;
               end if;

               Movement.Move (T.Element.all, V.Element.all, DT);
               Movement.Move_Dynamic_Objects (Objects, DT);

               Collision.Check_Player
                 (Tiles,
                  Objects,
                  T.Element.all,
                  V.Element.all,
                  C.Element.all,
                  Spawn_X,
                  Spawn_Y,
                  Gravity_On,
                  Result);

               Gameplay.Apply_Collision_Result (Status, Result);
               Gameplay.Drain_Fuel (Status, DT);
               Gameplay.Update_Scripted_Systems
                 (Status,
                  Objects,
                  T.Element.all.X,
                  T.Element.all.Y,
                  DT);

               if Gameplay.Needs_Reset (Status) then
                  Reset_Player;
                  Gameplay.Reset_After_Crash (Status);
               end if;

               Sync_Gravity_Component (Gravity_On);
               Update_Camera;
            end if;
      end case;

      delay 0.016;
   end Update;

   procedure Draw is
      T : constant EM.Transform_Map.Reference_Type :=
        EM.Get_Transform (Mgr, Player);
      R : constant EM.Renderable_Map.Reference_Type :=
        EM.Get_Renderable (Mgr, Player);
   begin
      case Current_Screen is
         when Main_Menu_Screen =>
            Render_System.Draw_Main_Menu
              (Renderer,
               Screen_Width,
               Screen_Height,
               Main_Menu_Item);

         when Load_Menu_Screen =>
            Render_System.Draw_Load_Menu
              (Renderer,
               Screen_Width,
               Screen_Height,
               Load_Menu_Item,
               Current_Level);

         when Play_Screen | Map_Editor_Screen | Editor_Playtest_Screen =>
            Render_System.Draw_Frame
              (Renderer,
               Screen_Width,
               Screen_Height,
               Tiles,
               Objects,
               Mode,
               Brush,
               Cursor_X,
               Cursor_Y,
               Current_Tile,
               Current_Kind,
               Current_Motion,
               Camera_X,
               Camera_Y,
               T.Element.all,
               R.Element.all,
               Gravity_Is_On,
               Current_Screen = Editor_Playtest_Screen,
               Current_Level,
               Status,
               Current_View);
      end case;

      Window.Update_Surface;
   end Draw;

   procedure Shutdown is
   begin
      Audio.Shutdown;
      Window.Finalize;
      SDL.Finalise;
   end Shutdown;

   function Is_Running return Boolean is
   begin
      return Running;
   end Is_Running;

end Application;

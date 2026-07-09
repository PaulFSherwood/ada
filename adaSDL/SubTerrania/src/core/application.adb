with Ada.Text_IO; use Ada.Text_IO;

with SDL;
with SDL.Video;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;

with Collision;
with Inputs;
with Level;
with Movement;
with Render;

use type Level.Game_Mode;
use type Level.Brush_Mode;
use type Level.Tile_Kind;

package body Application is

   package EM renames ECS.Entity_System.Entity_Manager;
   package Render_System renames Render;

   Screen_Width  : constant Natural := 800;
   Screen_Height : constant Natural := 600;

   DT             : constant Float := 1.0 / 60.0;
   Max_Fall_Speed : constant Float := 240.0;

   Map_Path : constant String := "level01.map";

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;

   Tiles   : Level.Tile_Map;
   Objects : Level.Object_Array;

   Mode  : Level.Game_Mode := Level.Play_Mode;
   Brush : Level.Brush_Mode := Level.Tile_Brush;

   Cursor_X       : Float := 400.0;
   Cursor_Y       : Float := 300.0;
   Cursor_Step    : constant Float := 16.0;
   Current_Tile   : Level.Tile_Kind := Level.Wall_Tile;
   Current_Kind   : Level.Object_Kind := Level.Miner;
   Current_Motion : Level.Motion_Kind := Level.Static;

   Spawn_X : Float := 400.0;
   Spawn_Y : Float := 300.0;

   Camera_X : Float := 0.0;
   Camera_Y : Float := 0.0;

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

   procedure Toggle_Mode is
   begin
      if Mode = Level.Play_Mode then
         Mode := Level.Editor_Mode;
         Cursor_X := Spawn_X;
         Cursor_Y := Spawn_Y;
         Put_Line ("EDITOR MODE");
      else
         Mode := Level.Play_Mode;
         Put_Line ("PLAY MODE");
      end if;
   end Toggle_Mode;

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
         Level.Save_Level (Tiles, Objects, Map_Path);
      end if;

      if State.Load_Level then
         Level.Load_Level (Tiles, Objects, Map_Path, Loaded);
         if Loaded then
            Configure_Player_From_Map;
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
         DT);
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
         Level.Load_Level (Tiles, Objects, Map_Path, Loaded);

         if not Loaded then
            Level.Build_Test_Level (Tiles, Objects);
         end if;
      end;

      Configure_Player_From_Map;
      Update_Camera;
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
      Inputs.Poll_Events (State, Mode, Brush);

      if State.Quit_Requested then
         Running := False;
      end if;

      if State.Toggle_Mode then
         Toggle_Mode;
      end if;

      if Mode = Level.Editor_Mode then
         Handle_Editor_Input (State);
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

         Sync_Gravity_Component (Gravity_On);
         Update_Camera;
      end if;

      delay 0.016;
   end Update;

   procedure Draw is
      T : constant EM.Transform_Map.Reference_Type :=
        EM.Get_Transform (Mgr, Player);
      R : constant EM.Renderable_Map.Reference_Type :=
        EM.Get_Renderable (Mgr, Player);
   begin
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
         Gravity_Is_On);

      Window.Update_Surface;
   end Draw;

   procedure Shutdown is
   begin
      Window.Finalize;
      SDL.Finalise;
   end Shutdown;

   function Is_Running return Boolean is
   begin
      return Running;
   end Is_Running;

end Application;

with SDL;
with SDL.Video;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;

with SDL.Events;
with SDL.Events.Events;
with SDL.Events.Keyboards;
with Ada.Text_IO; use Ada.Text_IO;

--  with ECS.Components.Transform;
--  with ECS.Components.Velocity;
--  with ECS.Entity_System.Entity_Manager;
--  with ECS.Entity_System.Entity;
with Movement;

package body Application is

   package EM renames ECS.Entity_System.Entity_Manager;
   --  package Entity renames ECS.Entity_System.Entity;
   --  package Transform renames ECS.Components.Transform;
   --  package Velocity renames ECS.Components.Velocity;

   --  Window Setup
   Screen_Height : constant Natural := 800;
   Screen_Width  : constant Natural := 640;

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;

   use type SDL.Events.Event_Types;

   type Game_Mode is (Play_Mode, Editor_Mode);
   Mode : Game_Mode := Play_Mode;

   type Object_Kind is
      (Wall,
      Miner,
      Enemy,
      Powerup,
      Goal,
      Platform);

   type Motion_Kind is
      (Static,
      Patrol_X,
      Patrol_Y);

   type Object_Record is record
      Used     : Boolean := False;
      Kind     : Object_Kind := Wall;
      Motion   : Motion_Kind := Static;

      X        : Float := 0.0;
      Y        : Float := 0.0;
      W        : Float := 40.0;
      H        : Float := 40.0;

      Min_Pos  : Float := 0.0;
      Max_Pos  : Float := 0.0;
      Speed    : Float := 0.0;
      Dir      : Float := 1.0;
   end record;

   Max_Objects : constant Positive := 128;
   type Object_Index is range 1 .. Max_Objects;
   type Object_Array is array (Object_Index) of Object_Record;

   Objects : Object_Array;

   Cursor_X : Float := 100.0;
   Cursor_Y : Float := 100.0;
   Cursor_Step : constant Float := 20.0;

   Current_Kind   : Object_Kind := Wall;
   Current_Motion : Motion_Kind := Static;

   Player_Size : constant Float := 40.0;

   Event : SDL.Events.Events.Events;

   function To_Dim (V : Float) return SDL.Natural_Dimension is
   begin
      if V <= 0.0 then
         return SDL.Natural_Dimension (0);
      else
         return SDL.Natural_Dimension (Integer (V));
      end if;
   end To_Dim;

   procedure Draw_Box
      (X : Float;
      Y : Float;
      W : Float;
      H : Float)
   is
   begin
      Renderer.Fill
      (Rectangle =>
         (To_Dim (X),
         To_Dim (Y),
         To_Dim (W),
         To_Dim (H)));
   end Draw_Box;

   procedure Set_Colour_For (K : Object_Kind) is
   begin
      case K is
         when Wall =>
            Renderer.Set_Draw_Colour ((80, 80, 80, 255));
         when Miner =>
            Renderer.Set_Draw_Colour ((0, 200, 255, 255));
         when Enemy =>
            Renderer.Set_Draw_Colour ((255, 0, 0, 255));
         when Powerup =>
            Renderer.Set_Draw_Colour ((0, 255, 0, 255));
         when Goal =>
            Renderer.Set_Draw_Colour ((255, 255, 0, 255));
         when Platform =>
            Renderer.Set_Draw_Colour ((160, 80, 255, 255));
      end case;
   end Set_Colour_For;

   function Next_Kind (K : Object_Kind) return Object_Kind is
   begin
      case K is
         when Wall      => return Miner;
         when Miner     => return Enemy;
         when Enemy     => return Powerup;
         when Powerup   => return Goal;
         when Goal      => return Platform;
         when Platform  => return Wall;
      end case;
   end Next_Kind;

   function Next_Motion (M : Motion_Kind) return Motion_Kind is
   begin
      case M is
         when Static   => return Patrol_X;
         when Patrol_X => return Patrol_Y;
         when Patrol_Y => return Static;
      end case;
   end Next_Motion;

   procedure Clamp_Cursor is
   begin
      if Cursor_X < 0.0 then
         Cursor_X := 0.0;
      end if;

      if Cursor_Y < 0.0 then
         Cursor_Y := 0.0;
      end if;

      if Cursor_X > Float (Screen_Width - 40) then
         Cursor_X := Float (Screen_Height - 40);
      end if;

      if Cursor_Y > Float (Screen_Height - 40) then
         Cursor_Y := Float (Screen_Height - 40);
      end if;
   end Clamp_Cursor;

   procedure Set_Default_Object
      (Obj   : out Object_Record;
      K      : Object_Kind;
      X      : Float;
      Y      : Float;
      Motion : Motion_Kind)
   is
   begin
      Obj.Used    := True;
      Obj.Kind    := K;
      Obj.Motion  := Motion;
      Obj.X       := X;
      Obj.Y       := Y;
      Obj.Dir     := 1.0;

      case K is
         when Wall =>
            Obj.W := 80.0;
            Obj.H := 40.0;
            Obj.Motion := Static;
            Obj.Speed := 0.0;

         when Miner =>
            Obj.W := 24.0;
            Obj.H := 24.0;
            Obj.Motion := Static;
            Obj.Speed := 0.0;

         when Enemy =>
            Obj.W := 32.0;
            Obj.H := 32.0;
            Obj.Motion := Static;
            Obj.Speed := 2.0;

         when Powerup =>
            Obj.W := 24.0;
            Obj.H := 24.0;
            Obj.Motion := Static;
            Obj.Speed := 0.0;

         when Goal =>
            Obj.W := 40.0;
            Obj.H := 60.0;
            Obj.Motion := Static;
            Obj.Speed := 0.0;

         when Platform =>
            Obj.W := 100.0;
            Obj.H := 20.0;
            Obj.Motion := Static;
            Obj.Speed := 1.0;
      end case;

      case Obj.Motion is
         when Static =>
            Obj.Min_Pos := 0.0;
            Obj.Max_Pos := 0.0;

         when Patrol_X =>
            Obj.Min_Pos := X - 100.0;
            Obj.Max_Pos := X + 100.0;

         when Patrol_Y =>
            Obj.Min_Pos := Y - 80.0;
            Obj.Max_Pos := Y + 80.0;
      end case;
   end Set_Default_Object;

   procedure Add_Level_Object
      (K     : Object_Kind;
      X      : Float;
      Y      : Float;
      Motion : Motion_Kind := Static)
   is
   begin
      for I in Object_Index loop
         if not Objects (I).Used then
            Set_Default_Object (Objects (I), K, X, Y, Motion);
            return;
         end if;
      end loop;
   end Add_Level_Object;

   procedure Build_Test_Level is
   begin
      for I in Object_Index loop
         Objects (I).Used := False;
      end loop;

      Add_Level_Object (Wall,       0.0,     760.0);
      Add_Level_Object (Wall,       100.0,   760.0);
      Add_Level_Object (Wall,       200.0,   760.0);
      Add_Level_Object (Wall,       300.0,   760.0);
      Add_Level_Object (Wall,       400.0,   760.0);
      Add_Level_Object (Wall,       500.0,   760.0);

      Add_Level_Object (Miner,      300.0,   700.0);
      Add_Level_Object (Enemy,      420.0,   700.0, Patrol_X);
      Add_Level_Object (Powerup,    160.0,   700.0);
      Add_Level_Object (Goal,       560.0,   700.0);
      Add_Level_Object (Platform,   250.0,   600.0, Patrol_Y);
   end Build_Test_Level;

   procedure Place_Object is
   begin
      Add_Level_Object
         (Current_Kind,
         Cursor_X,
         Cursor_Y,
         Current_Motion);

      Put_Line ("Placed " & Object_Kind'Image (Current_Kind));
   end Place_Object;

   procedure Delete_Object_At_Cursor is
   begin
      for I in Object_Index loop
         if Objects (I).Used
            and then Cursor_X >= Objects (I).X
            and then Cursor_X <= Objects (I).X + Objects (I).W
            and then Cursor_Y >= Objects (I).Y
            and then Cursor_Y <= Objects (I).Y + Objects (I).H
         then
            Objects (I).Used := False;
            Put_Line ("Deleted object");
            return;
         end if;
      end loop;
   end Delete_Object_At_Cursor;

   procedure Update_Objects is
   begin
      for I in Object_Index loop
         if Objects (I).Used then
            case Objects (I).Motion is
               when Static =>
                  null;
               when Patrol_X =>
                  Objects (I).X :=
                     Objects (I).X + Objects (I).Speed * Objects (I).Dir;
                  if Objects (I).X < Objects (I).Min_Pos then
                     Objects (I).X := Objects (I).Min_Pos;
                     Objects (I).Dir := 1.0;
                  elsif Objects (I).X > Objects (I).Max_Pos then
                     Objects (I).Y := Objects (I).Max_Pos;
                     Objects (I).Dir := -1.0;
                  end if;
               when Patrol_Y =>
                  Objects (I).Y :=
                     Objects (I).Y + Objects (I).Speed * Objects (I).Dir;
                  if Objects (I).Y < Objects (I).Min_Pos then
                     Objects (I).Dir := 1.0;
                  elsif Objects (I).Y > Objects (I).Max_Pos then
                     Objects (I).Y := Objects (I).Max_Pos;
                     Objects (I).Dir := -1.0;
                  end if;
            end case;
         end if;
      end loop;
   end Update_Objects;

   function Overlaps
      (X1 : Float; Y1 : Float; W1 : Float; H1 : Float;
      X2  : Float; Y2 : Float; W2 : Float; H2 : Float)
      return Boolean
   is
   begin
      return X1 < X2 + W2
         and then X1 + W1 > X2
         and then Y1 < Y2 + H2
         and then Y1 + H1 > Y2;
   end Overlaps;

   procedure Check_Collisions
      (Prev_X : Float;
      Prev_Y  : Float)
   is
      T : constant EM.Transform_Map.Reference_Type :=
      EM.Get_Transform (Mgr, Player);
   begin
      for I in Object_Index loop
         if Objects (I).Used
            and then Overlaps
               (T.Element.all.X,
               T.Element.all.Y,
               Player_Size,
               Player_Size,
               Objects (I).X,
               Objects (I).Y,
               Objects (I).W,
               Objects (I).H)
         then
            case Objects (I).Kind is
               when Wall | Platform =>
                  T.Element.all.X := Prev_X;
                  T.Element.all.Y := Prev_Y;

               when Miner =>
                  Objects (I).Used := False;
                  Put_Line ("Miner rescued");
               when Enemy =>
                  T.Element.all.X := 200.0;
                  T.Element.all.Y := 200.0;
               when Powerup =>
                  Objects (I).Used := False;
                  Put_Line ("Powerup collected");
               when Goal =>
                  T.Element.all.X := 200.0;
                  T.Element.all.Y := 200.0;
                  Put_Line ("Goal reached");
            end case;
         end if;
      end loop;
   end Check_Collisions;

   procedure Toggle_Mode is
   begin
      if Mode = Play_Mode then
         Mode := Editor_Mode;
         Put_Line ("EDITOR MODE");
      else
         Mode := Play_Mode;
         Put_Line ("PLAY MODE");
      end if;
   end Toggle_Mode;

   procedure Process_Input
      (V : in out EM.Velocity.Velocity)
   is
   begin
      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            Running := False;
         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Down then
            case Event.Keyboard.Key_Sym.Key_Code is
               when SDL.Events.Keyboards.Code_E =>
                  Toggle_Mode;
               when SDL.Events.Keyboards.Code_N =>
                  if Mode = Editor_Mode then
                     Current_Kind := Next_Kind (Current_Kind);
                     Put_Line ("Selected " & Object_Kind'Image (Current_Kind));
                  end if;
               when SDL.Events.Keyboards.Code_M =>
                  if Mode = Editor_Mode then
                     Current_Motion := Next_Motion (Current_Motion);
                     Put_Line ("Motion " & Motion_Kind'Image (Current_Motion));
                  end if;
               when SDL.Events.Keyboards.Code_P =>
                  if Mode = Editor_Mode then
                     Place_Object;
                  end if;
               when SDL.Events.Keyboards.Code_O =>
                  if Mode = Editor_Mode then
                     Delete_Object_At_Cursor;
                  end if;
               when SDL.Events.Keyboards.Code_W =>
                  if Mode = Editor_Mode then
                     Cursor_Y := Cursor_Y - Cursor_Step;
                     Clamp_Cursor;
                  else
                     V.Y := -2.0;
                  end if;
               when SDL.Events.Keyboards.Code_S =>
                  if Mode = Editor_Mode then
                     Cursor_Y := Cursor_Y + Cursor_Step;
                     Clamp_Cursor;
                  else
                     V.Y := 2.0;
                  end if;
               when SDL.Events.Keyboards.Code_A =>
                  if Mode = Editor_Mode then
                     Cursor_X := Cursor_X - Cursor_Step;
                     Clamp_Cursor;
                  else
                     V.X := -2.0;
                  end if;
               when SDL.Events.Keyboards.Code_D =>
                  if Mode = Editor_Mode then
                     Cursor_X := Cursor_X + Cursor_Step;
                     Clamp_Cursor;
                  else
                     V.X := 2.0;
                  end if;
               when others =>
                  null;
            end case;
         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Up then
            if Mode = Play_Mode then
               case Event.Keyboard.Key_Sym.Key_Code is
                  when SDL.Events.Keyboards.Code_W |
                     SDL.Events.Keyboards.Code_S =>
                     V.Y := 0.0;
                  when SDL.Events.Keyboards.Code_A |
                     SDL.Events.Keyboards.Code_D =>
                     V.X := 0.0;
                  when others =>
                     null;
               end case;
            end if;
         end if;
      end loop;
   end Process_Input;

   --------------------------------------------------
   --  INIT
   --------------------------------------------------

   procedure Init is
   begin
      if not SDL.Initialise (Flags => SDL.Enable_Screen) then
         Running := False;
         return;
      end if;

      SDL.Video.Windows.Makers.Create
        (Win      => Window,
         Title    => "ADA, ECS, SDL Test",
         Position => SDL.Natural_Coordinates'(X => 50, Y => 50),
         Size     =>
           SDL.Positive_Sizes'
           (SDL.Dimension (Screen_Width),
           SDL.Dimension (Screen_Height)),
         Flags    => 0);

      SDL.Video.Renderers.Makers.Create (Renderer, Window.Get_Surface);

      --  ECS Setup
      EM.Initialize (Mgr);

      Player := EM.Create_Entity (Mgr);

      EM.Add_Transform (Mgr, Player);
      EM.Add_Velocity  (Mgr, Player);

      declare
         T : constant EM.Transform_Map.Reference_Type :=
            EM.Get_Transform (Mgr, Player);
         V : constant EM.Velocity_Map.Reference_Type :=
            EM.Get_Velocity (Mgr, Player);
      begin
         T.Element.all.X := 200.0;
         T.Element.all.Y := 200.0;

         V.Element.all.X := 0.0;
         V.Element.all.Y := 0.0;
      end;
      Build_Test_Level;
   end Init;

   --------------------------------------------------
   --  UPDATE
   --------------------------------------------------
   procedure Update is
      T : constant EM.Transform_Map.Reference_Type :=
         EM.Get_Transform (Mgr, Player);
      V : constant EM.Velocity_Map.Reference_Type :=
         EM.Get_Velocity (Mgr, Player);

      Prev_X : constant Float := T.Element.all.X;
      Prev_Y : constant Float := T.Element.all.Y;
   begin
      Process_Input (V.Element.all);

      if Mode = Play_Mode then
         Movement.Move (T.Element.all, V.Element.all, 1.0);
         Update_Objects;
         Check_Collisions (Prev_X, Prev_Y);
      end if;

      delay 0.016;
   end Update;

   --------------------------------------------------
   --  RENDER
   --------------------------------------------------
   procedure Render is
      T : constant EM.Transform_Map.Reference_Type :=
         EM.Get_Transform (Mgr, Player);
   begin
      Renderer.Set_Draw_Colour ((0, 0, 0, 255));

      Renderer.Fill
        (Rectangle =>
           (0,
            0,
            SDL.Natural_Dimension (Screen_Width),
            SDL.Natural_Dimension (Screen_Height)));

      for I in Object_Index loop
         if Objects (I).Used then
            Set_Colour_For (Objects (I).Kind);
            Draw_Box
               (Objects (I).X,
                Objects (I).Y,
                Objects (I).W,
                Objects (I).H);
         end if;
      end loop;

      Renderer.Set_Draw_Colour ((255, 0, 200, 255));
      Draw_Box
         (T.Element.all.X,
          T.Element.all.Y,
          Player_Size,
          Player_Size);

      if Mode = Editor_Mode then
         Renderer.Set_Draw_Colour ((255, 255, 255, 255));
         Draw_Box (Cursor_X, Cursor_Y, 40.0, 40.0);
      end if;

      Window.Update_Surface;
   end Render;

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

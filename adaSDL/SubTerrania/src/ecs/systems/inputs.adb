with SDL.Events;
with SDL.Events.Events;
with SDL.Events.Keyboards;
with SDL.Events.Mice;

package body Inputs is

   use type SDL.Events.Event_Types;
   use type SDL.Events.Mice.Buttons;
   use type Level.Brush_Mode;

   Event : SDL.Events.Events.Events;

   W_Down : Boolean := False;
   A_Down : Boolean := False;
   S_Down : Boolean := False;
   D_Down : Boolean := False;

   Mouse_X      : Float := 0.0;
   Mouse_Y      : Float := 0.0;
   Last_Mouse_X : Float := 0.0;
   Last_Mouse_Y : Float := 0.0;
   Left_Down    : Boolean := False;
   Right_Down   : Boolean := False;
   Middle_Down  : Boolean := False;

   procedure Handle_Menu_Key_Down
     (State : in out Input_State) is
   begin
      case Event.Keyboard.Key_Sym.Key_Code is
         when SDL.Events.Keyboards.Code_W =>
            State.Menu_Up := True;

         when SDL.Events.Keyboards.Code_S =>
            State.Menu_Down := True;

         when SDL.Events.Keyboards.Code_P |
              SDL.Events.Keyboards.Code_E =>
            State.Menu_Select := True;

         when SDL.Events.Keyboards.Code_Q =>
            State.Menu_Back := True;

         when others =>
            null;
      end case;
   end Handle_Menu_Key_Down;

   procedure Handle_Editor_Key_Down
     (State : in out Input_State;
      Brush : Level.Brush_Mode) is
   begin
      case Event.Keyboard.Key_Sym.Key_Code is
         when SDL.Events.Keyboards.Code_E =>
            State.Toggle_Mode := True;

         when SDL.Events.Keyboards.Code_Q =>
            State.Menu_Back := True;

         when SDL.Events.Keyboards.Code_T =>
            State.Toggle_Brush := True;

         when SDL.Events.Keyboards.Code_B =>
            State.Next_Tile := True;

         when SDL.Events.Keyboards.Code_N =>
            if Brush = Level.Tile_Brush then
               State.Next_Tile := True;
            else
               State.Next_Kind := True;
            end if;

         when SDL.Events.Keyboards.Code_M =>
            State.Next_Motion := True;

         when SDL.Events.Keyboards.Code_V =>
            State.Next_View := True;

         when SDL.Events.Keyboards.Code_P =>
            State.Place := True;

         when SDL.Events.Keyboards.Code_O =>
            State.Delete := True;

         when SDL.Events.Keyboards.Code_F =>
            State.Save_Level := True;

         when SDL.Events.Keyboards.Code_L =>
            State.Load_Level := True;

         when SDL.Events.Keyboards.Code_W =>
            State.Cursor_DY := -1.0;
            W_Down := True;

         when SDL.Events.Keyboards.Code_S =>
            State.Cursor_DY := 1.0;
            S_Down := True;

         when SDL.Events.Keyboards.Code_A =>
            State.Cursor_DX := -1.0;
            A_Down := True;

         when SDL.Events.Keyboards.Code_D =>
            State.Cursor_DX := 1.0;
            D_Down := True;

         when others =>
            null;
      end case;
   end Handle_Editor_Key_Down;

   procedure Handle_Play_Key_Down
     (State : in out Input_State) is
   begin
      case Event.Keyboard.Key_Sym.Key_Code is
         when SDL.Events.Keyboards.Code_E =>
            State.Toggle_Mode := True;

         when SDL.Events.Keyboards.Code_Q =>
            State.Menu_Back := True;

         when SDL.Events.Keyboards.Code_W =>
            W_Down := True;

         when SDL.Events.Keyboards.Code_S =>
            S_Down := True;

         when SDL.Events.Keyboards.Code_A =>
            A_Down := True;

         when SDL.Events.Keyboards.Code_D =>
            D_Down := True;

         when others =>
            null;
      end case;
   end Handle_Play_Key_Down;

   procedure Handle_Key_Down
     (State   : in out Input_State;
      Context : Input_Context;
      Brush   : Level.Brush_Mode) is
   begin
      case Context is
         when Menu_Context =>
            Handle_Menu_Key_Down (State);

         when Play_Context =>
            Handle_Play_Key_Down (State);

         when Editor_Context =>
            Handle_Editor_Key_Down (State, Brush);
      end case;
   end Handle_Key_Down;

   procedure Handle_Key_Up is
   begin
      case Event.Keyboard.Key_Sym.Key_Code is
         when SDL.Events.Keyboards.Code_W =>
            W_Down := False;

         when SDL.Events.Keyboards.Code_S =>
            S_Down := False;

         when SDL.Events.Keyboards.Code_A =>
            A_Down := False;

         when SDL.Events.Keyboards.Code_D =>
            D_Down := False;

         when others =>
            null;
      end case;
   end Handle_Key_Up;

   procedure Handle_Mouse_Motion
     (State : in out Input_State) is
      New_X : constant Float := Float (Event.Mouse_Motion.X);
      New_Y : constant Float := Float (Event.Mouse_Motion.Y);
   begin
      Mouse_X := New_X;
      Mouse_Y := New_Y;
      State.Mouse_X := Mouse_X;
      State.Mouse_Y := Mouse_Y;
      State.Mouse_DX := Mouse_X - Last_Mouse_X;
      State.Mouse_DY := Mouse_Y - Last_Mouse_Y;
      Last_Mouse_X := Mouse_X;
      Last_Mouse_Y := Mouse_Y;
   end Handle_Mouse_Motion;

   procedure Handle_Mouse_Button_Down
     (State : in out Input_State) is
   begin
      Mouse_X := Float (Event.Mouse_Button.X);
      Mouse_Y := Float (Event.Mouse_Button.Y);
      State.Mouse_X := Mouse_X;
      State.Mouse_Y := Mouse_Y;

      case Event.Mouse_Button.Button is
         when SDL.Events.Mice.Left =>
            Left_Down := True;
            State.Left_Click := True;

         when SDL.Events.Mice.Right =>
            Right_Down := True;
            State.Right_Click := True;

         when SDL.Events.Mice.Middle =>
            Middle_Down := True;
            State.Middle_Click := True;

         when others =>
            null;
      end case;
   end Handle_Mouse_Button_Down;

   procedure Handle_Mouse_Button_Up is
   begin
      case Event.Mouse_Button.Button is
         when SDL.Events.Mice.Left =>
            Left_Down := False;

         when SDL.Events.Mice.Right =>
            Right_Down := False;

         when SDL.Events.Mice.Middle =>
            Middle_Down := False;

         when others =>
            null;
      end case;
   end Handle_Mouse_Button_Up;

   procedure Handle_Mouse_Wheel
     (State : in out Input_State) is
   begin
      State.Mouse_Wheel :=
        State.Mouse_Wheel + Float (Event.Mouse_Wheel.Y);
   end Handle_Mouse_Wheel;

   procedure Poll_Events
     (State   : out Input_State;
      Context : Input_Context;
      Brush   : Level.Brush_Mode) is
   begin
      State := (others => <>);
      State.Mouse_X := Mouse_X;
      State.Mouse_Y := Mouse_Y;

      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            State.Quit_Requested := True;

         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Down then
            Handle_Key_Down (State, Context, Brush);

         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Up then
            Handle_Key_Up;

         elsif Event.Common.Event_Type = SDL.Events.Mice.Motion then
            Handle_Mouse_Motion (State);

         elsif Event.Common.Event_Type = SDL.Events.Mice.Button_Down then
            Handle_Mouse_Button_Down (State);

         elsif Event.Common.Event_Type = SDL.Events.Mice.Button_Up then
            Handle_Mouse_Button_Up;

         elsif Event.Common.Event_Type = SDL.Events.Mice.Wheel then
            Handle_Mouse_Wheel (State);
         end if;
      end loop;

      State.Left_Down := Left_Down;
      State.Right_Down := Right_Down;
      State.Middle_Down := Middle_Down;

      if Context = Play_Context then
         State.Thrust := W_Down;
         State.Brake := S_Down;
         State.Turn_Left := A_Down;
         State.Turn_Right := D_Down;
      end if;
   end Poll_Events;

end Inputs;

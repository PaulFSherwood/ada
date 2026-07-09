with SDL.Events;
with SDL.Events.Events;
with SDL.Events.Keyboards;

package body Inputs is

   use type SDL.Events.Event_Types;
   use type Level.Game_Mode;
   use type Level.Brush_Mode;

   Event : SDL.Events.Events.Events;

   W_Down : Boolean := False;
   A_Down : Boolean := False;
   S_Down : Boolean := False;
   D_Down : Boolean := False;

   procedure Handle_Key_Down
     (State : in out Input_State;
      Mode  : Level.Game_Mode;
      Brush : Level.Brush_Mode) is
   begin
      case Event.Keyboard.Key_Sym.Key_Code is
         when SDL.Events.Keyboards.Code_E =>
            State.Toggle_Mode := True;

         when SDL.Events.Keyboards.Code_T =>
            if Mode = Level.Editor_Mode then
               State.Toggle_Brush := True;
            end if;

         when SDL.Events.Keyboards.Code_B =>
            if Mode = Level.Editor_Mode then
               State.Next_Tile := True;
            end if;

         when SDL.Events.Keyboards.Code_N =>
            if Mode = Level.Editor_Mode then
               if Brush = Level.Tile_Brush then
                  State.Next_Tile := True;
               else
                  State.Next_Kind := True;
               end if;
            end if;

         when SDL.Events.Keyboards.Code_M =>
            if Mode = Level.Editor_Mode then
               State.Next_Motion := True;
            end if;

         when SDL.Events.Keyboards.Code_P =>
            if Mode = Level.Editor_Mode then
               State.Place := True;
            end if;

         when SDL.Events.Keyboards.Code_O =>
            if Mode = Level.Editor_Mode then
               State.Delete := True;
            end if;

         when SDL.Events.Keyboards.Code_F =>
            if Mode = Level.Editor_Mode then
               State.Save_Level := True;
            end if;

         when SDL.Events.Keyboards.Code_L =>
            if Mode = Level.Editor_Mode then
               State.Load_Level := True;
            end if;

         when SDL.Events.Keyboards.Code_W =>
            if Mode = Level.Editor_Mode then
               State.Cursor_DY := -1.0;
            end if;
            W_Down := True;

         when SDL.Events.Keyboards.Code_S =>
            if Mode = Level.Editor_Mode then
               State.Cursor_DY := 1.0;
            end if;
            S_Down := True;

         when SDL.Events.Keyboards.Code_A =>
            if Mode = Level.Editor_Mode then
               State.Cursor_DX := -1.0;
            end if;
            A_Down := True;

         when SDL.Events.Keyboards.Code_D =>
            if Mode = Level.Editor_Mode then
               State.Cursor_DX := 1.0;
            end if;
            D_Down := True;

         when others =>
            null;
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

   procedure Poll_Events
     (State : out Input_State;
      Mode  : Level.Game_Mode;
      Brush : Level.Brush_Mode) is
   begin
      State := (others => <>);

      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            State.Quit_Requested := True;

         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Down then
            Handle_Key_Down (State, Mode, Brush);

         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Up then
            Handle_Key_Up;
         end if;
      end loop;

      if Mode = Level.Play_Mode then
         State.Thrust := W_Down;
         State.Brake := S_Down;
         State.Turn_Left := A_Down;
         State.Turn_Right := D_Down;
      end if;
   end Poll_Events;

end Inputs;

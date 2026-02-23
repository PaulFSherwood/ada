with SDL;
with SDL.Events;
with SDL.Events.Events;
with SDL.Events.Keyboards;

with Ada.Text_IO; use Ada.Text_IO;
with ECS.Components.Velocity;

use type SDL.Events.Event_Types;

package body Inputs is

   Event : SDL.Events.Events.Events;

   procedure PollEvents
      (Running : in out Boolean;
      V        : in out ECS.Components.Velocity.Velocity) is
   begin
      while SDL.Events.Events.Poll (Event) loop
         --  Quit event
         if Event.Common.Event_Type = SDL.Events.Quit then
            Running := False;
         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Down then
            case Event.Keyboard.Key_Sym.Key_Code is
               when SDL.Events.Keyboards.Code_W =>
                  Put_Line ("W");
                  V.Y := -2.0;
               when SDL.Events.Keyboards.Code_S =>
                  Put_Line ("S");
                  V.Y := 2.0;
               when SDL.Events.Keyboards.Code_A =>
                  Put_Line ("A");
                  V.X := -2.0;
               when SDL.Events.Keyboards.Code_D =>
                  Put_Line ("D");
                  V.X := 2.0;
               when others =>
                  null;
            end case;

         elsif Event.Common.Event_Type = SDL.Events.Keyboards.Key_Up then
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

      end loop;
   end PollEvents;

end Inputs;

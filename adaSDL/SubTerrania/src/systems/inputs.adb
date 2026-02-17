with SDL;
with SDL.Events;
use SDL.Events;
with SDL.Events.Events;

with SDL.Events.Keyboards;
use SDL.Events.Keyboards;

with Ada.Text_IO; use Ada.Text_IO;
with Application;

package body Inputs is

   Event : SDL.Events.Events.Events;

   procedure PollEvents is
   begin
      while SDL.Events.Events.Poll (Event) loop
         --  Quit event
         if Event.Common.Event_Type = SDL.Events.Quit then
            Application.Running := False;
         end if;

         --  Key Down
         if Event.Common.Event_Type = SDL.Events.Keyboards.Key_Down then
            case Event.Keyboard.Key_Sym.Key_Code is
               when Code_W => Put_Line ("W Pressed");
               when Code_A => Put_Line ("A Pressed");
               when Code_S => Put_Line ("S Pressed");
               when Code_D => Put_Line ("D Pressed");
               when others => null;
            end case;
         end if;

      end loop;
   end PollEvents;

end Inputs;

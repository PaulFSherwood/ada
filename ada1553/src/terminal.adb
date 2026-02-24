with Ada.Text_IO;
with Bus;

package body Terminal is

   task body Remote_Terminal is
      use Ada.Text_IO;

      M : Bus.Message;
   begin
      loop
         Bus.Shared_Bus.Receive (M);

         if M.Destination = ID then
            Put_Line ("RT" & Integer'Image (ID) &
                     " responding");
            
            Bus.Shared_Bus.Send (
               (Source => ID,
               Destination => 0,
               Payload => M.Payload));
         end if;
      end loop;
   end Remote_Terminal;

end Terminal;

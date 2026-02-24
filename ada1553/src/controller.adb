with Ada.Text_IO;
with Ada.Calendar;
with Bus;

package body Controller is

   task body Bus_Controller is
      use Ada.Calendar;
      use Ada.Text_IO;

      M : Bus.Message;
      Now : Time;
   begin
      loop
         delay 1.0;

         Now := Clock;

         --  Send poll to RT1
         Bus.Shared_Bus.Send (
            (Source => 0,
            Destination => 1,
            Payload => Integer (Seconds (Now)) mod 60));

         --  Receive response
         Bus.Shared_Bus.Receive (M);

         Put_Line ("BC received from RT" &
            Integer'Image (M.Source) &
            " minute=" &
            Integer'Image (M.Payload));
      end loop;
   end Bus_Controller;

end Controller;

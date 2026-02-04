--  Owns the loop, does not own the state, does not know how counting works.
with Ada.Text_IO; use Ada.Text_IO;
with Counter;

procedure Package_Ownership is
   --  tick : Integer := 0;
begin
   --  use the Counter reset function
   Counter.Reset;

   loop
      --  Use the Counter Increment function
      --  tick := tick + 1;
      Counter.Increment;
      Put_Line ("Tick: " & Integer'Image (Counter.Value));
      delay 0.5;
      exit when Counter.Done; --  replace: tick >= 5;
   end loop;
end Package_Ownership;

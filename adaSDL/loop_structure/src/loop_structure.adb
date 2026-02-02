with Ada.Text_IO; use Ada.Text_IO;

procedure Loop_Structure is
   Start : Time := Clock;
   StartMs : Time;
   EndMs : Time;
   DelayMs : Time;
   loopNumber : integer := 0;
   FrameRate : integer := 0;
   FrameMs : integer := 1000 / FrameRate;  --| Calculate the length of each frame
begin
   loop
      StartMs := Clock;
      -- Update : Changes some state (a counter, position, etc)
      -- Render : Prints the current state
      EndMs := Clock;
      DelayMs := FrameMs - (EndMs - StartMs);
      loop
      exit when Clock >= DelayMs;
      Put_Line ("loop number: " & Integer'Image(loopNumber));
   end loop;
end Loop_Structure;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;

procedure Loop_Structure is
   StartMs : Time;
   EndMs : Time;
   DelayMs : Time;
   loopNumber : Integer := 0;
   FrameRate : constant Integer := 60; --
   FrameMs : constant Time_Span := To_Time_Span (1.0 / Float (FrameRate));
begin
   loop
      StartMs := Clock;
      -- Update : Changes some state (a counter, position, etc)
      -- Render : Prints the current state
      Put_Line ("loop number: " & Integer'Image(loopNumber));
      loopNumber := loopNumber + 1;
      EndMs := Clock;

      DelayMs := FrameMs - (EndMs - StartMs);

      --| busy loop over having a delay
      while Clock - StartMs < FrameMs loop
         null;
      end loop;
   end loop;
end Loop_Structure;

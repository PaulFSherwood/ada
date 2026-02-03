with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
--| Ada.Real_Time.Time -> Point in time.
--| Ada.Real_Time.Time_Span -> difference between times.
--| Duration -> Scalar seconds (used for math & conversion)
--
--| RULES:
--| Time - Time = Time_Span
--| Time + Time_Span = Time
--| Time_Span - Time_Span = Time_Span 
--| To_Time_Span (Duration) converts units

--| Units and Conversions
--| Frame period = 1.0 / Duration (FrameRate) seconds.
--| Avoid floats unless converting to Duration.
--| To_Time_Span takes Duration, not Float.
--
--

procedure Loop_Structure is
   StartMs : Time;
   EndMs : Time;
   DelayMs : Time_Span;
   loopNumber : Integer := 0;
   FrameRate : constant Integer := 60; --
   FrameMs : constant Time_Span := To_Time_Span (1.0 / Duration (FrameRate));
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
         -- Put_Line ("Wait");
      end loop;
   end loop;
end Loop_Structure;

with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;

procedure Dt_Test is
    Start        : Time := Clock;
    Last_Second  : Seconds_Count := -1;
    Now          : Time;
    Elapsed_Time : Time_Span;
    Sec          : Seconds_Count;
begin
    loop
        Now          := Clock;
        Elapsed_Time := Now - Start;
        Sec          := Seconds_Count (To_Duration (Elapsed_Time));

        if Sec /= Last_Second then
            -- Put_Line ("Total time: " & Duration'Image (Total_Time) & " Elapsed_Time: " & Duration'Image (Elapsed_Time));
            Put_Line ("Elapsed seconds:" & Seconds_Count'Image (Sec));
            Last_Second := Sec;
        end if;

        exit when Sec >= 5;
    end loop;
end Dt_Test;


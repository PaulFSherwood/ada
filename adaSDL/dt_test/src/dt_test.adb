with Ada.Text_IO; use Ada.Text_IO;

procedure Dt_Test is
    Total_Time : Duration := 0.00;
    Elapsed_Time : Duration := 0.00;
    Delay_Time : Duration := 5.0;
begin
    loop
        Elapsed_Time := 0.00;
        -- Put_Line ("Total time: " & Duration'Image (Total_Time) & " Elapsed_Time: " & Duration'Image (Elapsed_Time));
        delay Delay_Time;
        Elapsed_Time := Elapsed_Time + Delay_Time;
        Total_Time := Total_Time + Elapsed_Time;
        Put_Line ("Total time: " & Duration'Image (Total_Time) & " Elapsed_Time: " & Duration'Image (Elapsed_Time));
    end loop;
end Dt_Test;

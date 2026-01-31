with Ada.Text_IO; use Ada.Text_IO;

procedure Loop_Test is
    counter : Integer := 0;
    Delay_Time : Duration := 1.0;
begin
    loop 
        Counter := Counter + 1;
        Put_Line ("Count is: " & Integer'Image (counter));
        delay Delay_Time;

        exit when counter >= 10;
    end loop;
end Loop_Test;

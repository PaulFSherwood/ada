with Ada.Text_IO; use Ada.Text_IO;

procedure Loop_Test is
    counter : Integer := 0;
    Delay_Time : Duration := 1.0;   --| Timers require the predifined Duration type.
begin
    --| Execution starts here.
    loop 
        Counter := Counter + 1;
        Put_Line ("Count is: " & Integer'Image (counter));
        delay Delay_Time;

        exit when counter >= 10;
    end loop;
end Loop_Test;


-- with package

-- procedure name is 
--  variable1, 2 so on
-- begin the procedure
-- do what ever like the loop
-- end the think or loop i.e. end loop
-- end procedure

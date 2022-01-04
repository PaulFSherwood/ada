with Ada.Text_IO; use Ada.Text_IO;

procedure Greet_5b is
    -- Variable declaration:
    I : Integer := 1;
    --  ^ Type     ^ Initial value
begin
    loop
		-- Put_Line is a procedure call
		Put_Line ("Hello, World!" & Integer'Image (I));
		-- Exit statement:
        exit when I = 5;
        --            ^ Boolean condition
        -- Assignment
        I := I + 1;
        -- There is no I++ short from to
        -- increment a variable
	end loop;
end Greet_5b;

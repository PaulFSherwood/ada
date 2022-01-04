with Ada.Text_IO; use Ada.Text_IO;

procedure Greet_5c is
    -- Variable declaration:
    I : Integer := 1;
    --  ^ Type     ^ Initial value
begin
    -- Condition must be a Boolean vlaue
    -- (no Integers).
    -- Operator "<=" returns a Boolean
    while I <= 5 loop
        Put_Line ("Hello, World!" & Integer'Image (I));
        I := I + 1;
	end loop;
end Greet_5c;

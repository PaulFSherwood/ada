with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Check_Positive is
    N : Integer;
begin
    -- Put a String
    Put ("Enter an integer value: ");
    -- Read in an integer value
    Get (N);

    if N > 0 then
        -- Put an Integer
        Put (N);
        Put_Line (" is positive number");
    end if;

    if N < 0 then
        -- Put an Iteger
        Put (N);
        Put_Line (" is a negative number");
    else
        Put (N);
        Put_Line (" I dunno");
    end if;
end Check_Positive;

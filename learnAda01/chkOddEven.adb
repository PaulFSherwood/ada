with Ada.Text_IO; use Ada.Text_IO;

procedure chkOddEven is
begin
    for I in 1 .. 10 loop
        Put_Line (if I mod 2 = 0 then "Even" else "Ode");
    end loop;
end chkOddEven;

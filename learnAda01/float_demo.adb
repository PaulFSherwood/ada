with Ada.Text_IO;
use Ada.Text_IO;

procedure float_Demo is
	type Float is digits 18 range 0.0 .. 100.0;
begin
    Put_Line("Float'First is " & Float'Image(Float'First));
    Put_Line("Flaot'Last is "  & Float'Image(Float'Last));
    --Put_Line("Modular Mod is " & Integer'Image(Modular'Modulus));

    Put_Line("Float'Small is " & Float'Image(Float'Small));

    -- will fail "The Range needs to be a discrete type"
    -- for F in Float'Range loop
    --     Put_Line("F is " & Float'Image(F));
    -- end loop;
    Put_Line("Float'Digits is " & Integer'Image(Float'Digits));
end float_Demo;

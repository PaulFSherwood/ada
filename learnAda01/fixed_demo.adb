with Ada.Text_IO;
use Ada.Text_IO;

procedure Fixed_Demo is
	type Ordinary is delta 2.0/8.0 range -2.0**8 .. 2.0**8;

    type Decimal is delta 0.01 digits 18;
begin
    Put_Line("Ordinary'First is " & Ordinary'Image(Ordinary'First));
    Put_Line("Ordinary'Last is "  & Ordinary'Image(Ordinary'Last));
    --Put_Line("Modular Mod is " & Integer'Image(Modular'Modulus));

    Put_Line("Ordinary'Small is " & Ordinary'Image(Ordinary'Small));
    Put_Line("Ordinary'Delta is " & Ordinary'Image(Ordinary'Delta));
    -- Put_Line("Ordinary'Digits is " & Ordinary'Image(Ordinary'Digits));

    Put_Line("Decimal'First is " & Decimal'Image(Decimal'First));
    Put_Line("Decimal'Last is " & Decimal'Image(Decimal'Last));
    
    Put_Line("Decimal'Delta is " & Decimal'Image(Decimal'Delta));
    Put_Line("Decimal'Digits is " & Integer'Image(Decimal'Digits));
end Fixed_Demo;


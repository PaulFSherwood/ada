with Ada.Text_IO;
use Ada.Text_IO;

procedure Mod_Demo is
	type Modular is mod 2**8;
begin
    Put_Line("Modular'First is " & Modular'Image(Modular'First));
    Put_Line("Modular'Last is " & Modular'Image(Modular'Last));
    Put_Line("Modular Mod is " & Integer'Image(Modular'Modulus));
end Mod_Demo;

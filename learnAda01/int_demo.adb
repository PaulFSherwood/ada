with Ada.Text_IO;
use Ada.Text_IO;

procedure Int_Demo is
	A : Integer := 1;
	
	-- type Percent is range 1 .. 100;
	subtype Percent is Integer range 1 .. 100;
	
	P : Percent := 50;
	
	subtype Example is Integer range 50 .. 500;
	
	E : Example := 250;
begin
	Put_Line("A is " & Integer'Image(A));
	Put_Line("First Integer is " & Integer'Image(Integer'First));
	Put_Line("Last Integer is " & Integer'Image(Integer'Last));
	Put_Line("P is " & Percent'Image(P));
	-- Put_Line("P is " & Integer'Image(P));
	Put_Line("E is " & Percent'Image(E));
	E := P;
	Put_Line("E is " & Percent'Image(E));
	
	for I in Percent'Range loop
	-- for I in 2 .. 100 loop
		if I mod 12 = 0 then
			Put_Line("I is " & Integer'Image(I));
		end if;
	end loop;
end Int_Demo;
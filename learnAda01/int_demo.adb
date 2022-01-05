with Ada.Text_IO;
use Ada.Text_IO;

procedure Int_Demo is
	A : Integer := 1;
	
	-- type Percent is range 1 .. 100;
	type Percent is new Integer range 1 .. 100;
	
	P : Percent := 50;
begin
	Put_Line("A is " & Integer'Image(A));
	Put_Line("First Integer is " & Integer'Image(Integer'First));
	Put_Line("Last Integer is " & Integer'Image(Integer'Last));
	-- Put_Line("P is " & Percent'Image(P));
	Put_Line("P is " & Integer'Image(P));
end Int_Demo;
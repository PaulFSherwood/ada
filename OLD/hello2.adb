with Ada.Text_IO;

procedure Hello2 is
	package IO renames Ada.Text_IO;
begin

	IO.Put_Line("Hello, world@");
	IO.New_Line; 
	IO.Put_Line("I am an ada programe with pagacke rename");
end Hello2;

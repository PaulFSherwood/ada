with Ada.Text_IO;

--  C struct - Ada record
--  C array  - Ada array
procedure Hello_World is
   I : Integer := 1;
   use Ada.Text_IO;

   type Person is
     record
         Name : String (1 .. 7);
         Age : Integer;
     end record;

   Class : array (1 .. 3) of Person;
begin
   while I <= 5 loop
      Ada.Text_IO.Put_Line ("Hello_World!" & Integer'Image (I));
      I := I + 1;
   end loop;
   Put_Line ("Hello World");

   --
   Class (1) := (Name => "Alice  ", Age => 23);
   Class (2) := (Name => "Bob    ", Age => 20);
   Class (3) := (Name => "Charlie", Age => 22);

   -- Inspect them --
   for I in 1 .. Class'Length loop
      Put_Line (Class (I).Name & " is " & Class (I).Age'Image & " years old.");
   end loop;
end Hello_World;

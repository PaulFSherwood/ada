with Ada.Text_IO; use Ada.Text_IO;

procedure arraysExamples is
    type MyInt is range 0 .. 1000;
    type Index is range 1..5;

    type MyIntArray is
        array(Index) of MyInt;

    type A1 is array (Integer range <>) of Integer;
    type A2 is array (Character range 'a' .. 'z') of Integer;
    type A3 is array (Integer range 1 .. 0) of Integer;
    type A4 is array (Boolean) of Integer;

    Arr : MyIntArray := (2,3,5,7,11);

    v : MyInt;

begin
    for I in Index loop
        V := Arr(I);
        Put(MyInt'Image(V));
    end loop;
    New_Line;
end arraysExamples;
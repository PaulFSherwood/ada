with Ada.Text_IO; use Ada.Text_IO;

procedure Arrays is
    type MyInt is range 0 .. 1000;
    type Index is range 1 .. 5;

    type MyIntArray is
        array(Index) of MyInt;

    Arr : MyIntArray := (2,3,5,7,101);

    V : MyInt; -- single variable to hold information

begin
    for I in Index loop
        V := Arr(I);
        Put(MyInt'Image(V));
    end loop;
    New_Line;
    V := Arr(2);
    Put_Line("MyIntArray[2]=" & MyInt'Image(V));
end Arrays;

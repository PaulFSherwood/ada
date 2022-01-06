with Ada.Text_IO;
use Ada.Text_IO;

procedure ArraysTwo is
    type Integer_Array is array(Integer range 0 .. 7 ) of Integer;
    type Integer_Array2 is array(Integer range 1 .. 8) of Integer;

    IA : Integer_Array := (1, 2, 3, 4, 5, 6, 7, 8);
    IA2 : Integer_Array2 := (1, 2, 3, 4, 5, 6, 7, 8);
begin
    Put_Line("IA(1) is " & IA(1)'Img);
    Put_Line("IA2(1) is " & IA2(1)'Img);
end ArraysTwo;

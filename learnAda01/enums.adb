with Ada.Text_IO;
use Ada.Text_IO;

procedure Enums is
    -- type Example is (First, Second, Third);
    type Example is (First, 'B', 'C', Last);
    for Example use (
       First => 1,
       'B' => 2,
       'C' => 4,
       Last => 5
    );
begin
    Put_Line("First value: " & Example'First'Img);
    Put_Line("Second value: " & Example'Enum_Val(2)'Img);
    Put_Line("Before second value: " & Example'Pred(Example'Enum_Val(2))'Img);
    Put_Line("After second value: " & Example'Succ(Example'Enum_Val(2))'Img);
    Put_Line("Last value: " & Example'Last'Img);
    Put_Line("'C' Position: " & Example'Pos('C')'Img);
    -- Put_Line("First value: " & First'Img);
    -- Put_Line("Second value: " & Second'Img);
end Enums;

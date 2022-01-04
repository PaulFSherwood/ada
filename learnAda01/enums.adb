with Ada.Text_IO;
use Ada.Text_IO;

procedure Enums is
    type Example is (First, Second, Third);
    for Example use (
        First => 1,
        Second => 2,
        Third => 3
        );
begin
    Put_Line("First value: " & First'Img);
    Put_Line("Second value: " & Second'Img);
end Enums;

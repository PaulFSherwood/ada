with Ada.Text_IO;
use Ada.Text_IO;

procedure ArraysThree is
    type CarttonEggs is array(Integer range 1 .. 12 ) of Integer;
    type quartsPerGallon is array(Integer range 1 .. 4) of Integer;
	type comboArray is array(Integer range <>) of Integer;

    CA : CarttonEggs := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
    QG : quartsPerGallon := (1, 2, 3, 4);
	LL : comboArray := CA & QG;
begin
    Put_Line("CA(1) is " & CA(1)'Img);
    Put_Line("QG(1) is " & QG(1)'Img);
	Put_Line("----------");
	Put_Line("CA(First) is " & CA'First'Img);
	Put_Line("CA(Last) is " & CA'Last'Img);
	Put_Line("----------");
	Put_Line("QG(First) is " & QG'First'Img);
	Put_Line("QG(Last) is " & QG'Last'Img);
	Put_Line("----------");
	Put_Line("----------");
	Put_Line(Integer'Image(LL'Length));
	
end ArraysThree;

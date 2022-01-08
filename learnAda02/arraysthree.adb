with Ada.Text_IO;
use Ada.Text_IO;

procedure ArraysThree is
	type MyInt is new Integer range 1 .. 10;
	type Tee is array (MyInt) of Integer;
	V : Tee;
    type CarttonEggs is array(Integer range 1 .. 12 ) of Integer;
    type quartsPerGallon is array(Integer range 1 .. 4) of Integer;
	type comboArray is array(Integer range <>) of Integer;
	type T is array(Integer range <>) of Integer;
	
	A1 : T := (1,2,3);
	A2 : T := (4,5,6);
	A3 : T := A1 & A2;

    CA : CarttonEggs := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
    QG : quartsPerGallon := (1, 2, 3, 4);
	-- :)
	-- CC : comboArray := CA;
	-- QQ : comboArray := QG;
	-- LL : comboArray := CC & QQ;
	
	W : T := (1, 2, 3);
begin
	-- W(1) := W(3) + W(2);
	V(1) := 2;
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
	-- Put_Line(Integer'Image(LL'Length));
	-- Put_Line("==========");
	-- for I in LL'Range loop
	-- 	Put_Line("LL(" & I'Img & ")=");-- & LL(I)'Img);
	-- end loop;
	
end ArraysThree;

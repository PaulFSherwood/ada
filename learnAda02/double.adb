with Ada.Text_IO; use Ada.Text_IO;

procedure Double is
    function Double_Me (InputNumber : Integer) return Integer is
    begin
        return InputNumber * 5;
    end Double_Me;
begin
    Put_Line ("Double 5 is " & Integer'Image (Double_Me (5)));
end Double;

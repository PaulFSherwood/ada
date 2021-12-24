with Ada.Text_IO; use Ada.Text_IO;

procedure Learn is

    subtype Alphabet is Character range 'A' .. 'Z';

begin

    Put_line ("Learning Ada from " & Alphabet'First & " to " & Alphabet'Last);

end Learn;

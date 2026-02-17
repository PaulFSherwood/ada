with Ada.Text_IO; use Ada.Text_IO;

package body Transform is
   --  Permision modes
   --  in      -> read-only
   --  out      -> write-only (fresh value expected)
   --  in out   -> read + write (modify existing value)
   procedure Dummy_Body is
      num : Integer := 0;
   begin
      num := 1;
   end Dummy_Body;
end Transform;

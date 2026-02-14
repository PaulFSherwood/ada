with Ada.Text_IO; use Ada.Text_IO;

package body Transform is

   --  in      -> read-only
   -- out      -> write-only (fresh value expected)
   -- in out   -> read + write (modify existing value)
   procedure Move_Player (T : in out Transform) is
   begin
      T.X := T.X + 1.0;
      Put_Line ("T.X" & Float'Image (T.X));
   end Move_Player;
end Transform;

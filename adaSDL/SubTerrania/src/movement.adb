--  with Ada.Text_IO; use Ada.Text_IO;
--  with Transform;

package body Movement is
   procedure Update_Velocity
      (VX_Update : Float;
      VY_Update : Float;
      V : in out Transform.Velocity) is
   begin
      V.X := VX_Update;
      V.Y := VY_Update;
   end Update_Velocity;
   procedure Move
      (T : in out Transform.Transform;
      V : in Transform.Velocity;
      DT : Float) is
   begin
      T.X := T.X + V.X * (DT + Transform.Speed);
      T.Y := T.Y + V.Y * (DT + Transform.Speed);
      --  Put_Line ("T.X: " & Float'Image 
      --  (T.X) & " T.Y: " & Float'Image (T.Y));
   end Move;
end Movement;

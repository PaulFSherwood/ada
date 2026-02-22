--  with Ada.Text_IO; use Ada.Text_IO;
with ECS.Components.Transform;
with ECS.Components.Velocity;

package body Movement is

   procedure Move
      (T : in out ECS.Components.Transform.Transform;
      V : in ECS.Components.Velocity.Velocity;
      DT : Float) is
   begin
      T.X := T.X + V.X * DT;
      T.Y := T.Y + V.Y * DT;
      --  Put_Line ("T.X: " & Float'Image
      --  (T.X) & " T.Y: " & Float'Image (T.Y));
   end Move;

end Movement;

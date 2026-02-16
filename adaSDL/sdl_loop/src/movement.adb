with Transform;

package body Movement is
   procedure Move_Player (T : in out Transform; V : in Velocity) is
   begin
      T.X := T.X + V.X;
      T.Y := T.Y + V.Y;
      Put_Line ("T.X: " & Float'Image (T.X) & " T.Y: " & Float'Image (T.Y));
   end Move_Player;
   procedure Update_Velocity 
      (VX_Update : Float; 
      VY_Update : Float; 
      V : in out Velocity) is
   begin
      V.X := VX_Update;
      V.Y := VY_Update;
   end Update_Velocity;
end Movement;

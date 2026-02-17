with Transform;

package Movement is
   procedure Move_Player
      (T : in out Transform.Transform;
      V : in Transform.Velocity);
   procedure Update_Velocity
      (VX_Update : Float;
      VY_Update : Float;
      V : in out Transform.Velocity);
end Movement;

package Movement is
   procedure Move_Player (T : in out Transform; V : in Velocity);
   procedure Update_Velocity (VX_Update : Float; VY_Update : Float; V : in out Velocity);
end Movement;

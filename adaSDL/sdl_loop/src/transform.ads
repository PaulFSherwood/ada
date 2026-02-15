package Transform is
   type Transform is record
      X : Float := 0.0;
      Y : Float := 0.0;
   end record;
   type Velocity is record
      X : Float := 1.0;
      Y : Float := 1.0;
   end record;
   procedure Move_Player (T : in out Transform; V : in Velocity);
   procedure Update_Velocity (VX_Update : Float; VY_Update : Float; V : in out Velocity);
end Transform;

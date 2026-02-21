package Transform is
   procedure Dummy_Body;
   type Transform is record
      X : Float := 0.0;
      Y : Float := 0.0;
   end record;
   type Velocity is record
      X : Float := 1.0;
      Y : Float := 1.0;
   end record;
end Transform;

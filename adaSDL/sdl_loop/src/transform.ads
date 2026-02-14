package Transform is
   type Transform is record
      X : Float := 0.0;
      Y : Float := 0.0;
   end record;
   procedure Move_Player (T : in out Transform);
end Transform;

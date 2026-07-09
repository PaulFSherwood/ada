package ECS.Components.Gravity is

   type Gravity is record
      Strength : Float := 120.0;
      Active   : Boolean := True;
   end record;

end ECS.Components.Gravity;

package body Entity_Manager is
   procedure CreateEntity is
   end CreateEntity;
   procedure StoreTransform
      (XVal : Float; 
      YVal : Float;
      T : in Transform.Transform) is
      T.X := XVal;
      T.Y := YVal;
   end StoreTransform;
   procedure StoreVelocity
      (XVal : Float; 
      YVal : Float;
      V : in Transform.Velocity) is
      V.X := XVal;
      V.Y := YVal;
   end StoreVelocity;
end Entity_Manager;

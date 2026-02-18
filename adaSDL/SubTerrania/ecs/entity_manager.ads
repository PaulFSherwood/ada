with Transform;

package Entity_Manager is
   procedure CreateEntity;
   procedure StoreTransform
      (XVal : Float;
      YVal : Float;
      T : in Transform.Transform);
   procedure StoreVelocity
      (XVal : Float;
      YVal : Float;
      V : in Transform.Velocity);
end Entity_Manager;

with ECS.Components.Transform;
with ECS.Components.Velocity;

package Movement is
   procedure Move
      (T : in out ECS.Components.Transform.Transform;
      V : in ECS.Components.Velocity.Velocity;
      DT : Float);
end Movement;

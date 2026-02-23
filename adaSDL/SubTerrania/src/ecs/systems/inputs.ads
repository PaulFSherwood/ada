with ECS.Components.Velocity;

package Inputs is
   procedure PollEvents(Running : in out Boolean;
      V : in out ECS.Components.Velocity.Velocity);
end Inputs;

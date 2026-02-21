with Transform;

package Movement is
   procedure Move
      (T : in out Transform.Transform;
      V : in Transform.Velocity;
      DT : Float);
end Movement;

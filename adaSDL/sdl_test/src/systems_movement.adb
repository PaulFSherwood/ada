with ECS;
with Components_Transform;
with Components_Velocity;

package body Systems_Movement is

   procedure Update (Delta_Time : Float) is
      T : Components_Transform.Transform;
      V : Components_Velocity.Velocity;
   begin
      T := ECS.Get_Transform;
      V := ECS.Get_Velocity;

      T.X := T.X + V.VX * Delta_Time;
      T.Y := T.Y + V.VY * Delta_Time;

      ECS.Set_Transform (T);
   end Update;

end Systems_Movement;
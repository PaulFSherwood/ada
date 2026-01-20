with Components_Transform;
with Components_Velocity;

package body ECS is

   Current_Transform : Components_Transform.Transform :=
     (X => 0.0, Y => 0.0);

   Current_Velocity : Components_Velocity.Velocity :=
     (VX => 0.0, VY => 0.0);

   procedure Create_Entity (Id : out Entity_Id) is
   begin
      Id := 1;
   end Create_Entity;

   procedure Set_Transform
     (T : Components_Transform.Transform) is
   begin
      Current_Transform := T;
   end Set_Transform;

   function Get_Transform
     return Components_Transform.Transform is
   begin
      return Current_Transform;
   end Get_Transform;

   procedure Set_Velocity
     (V : Components_Velocity.Velocity) is
   begin
      Current_Velocity := V;
   end Set_Velocity;

   function Get_Velocity
     return Components_Velocity.Velocity is
   begin
      return Current_Velocity;
   end Get_Velocity;

end ECS;
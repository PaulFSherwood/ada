with Components_Transform;
with Components_Velocity;

package ECS is
   type Entity_Id is new Natural;

   procedure Create_Entity (Id : out Entity_Id);

   procedure Set_Transform
     (T : Components_Transform.Transform);

   function Get_Transform
     return Components_Transform.Transform;

   procedure Set_Velocity
     (V : Components_Velocity.Velocity);

   function Get_Velocity
     return Components_Velocity.Velocity;
end ECS;
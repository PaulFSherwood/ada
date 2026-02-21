with Transform;
with ECS.Entity;

package ECS.Entity_Manager is

   function Create_Entity return ECS.Entity.Entity_ID;

   procedure Add_Transform
     (E : ECS.Entity.Entity_ID;
      T : Transform.Transform);

   procedure Add_Velocity
     (E : ECS.Entity.Entity_ID;
      V : Transform.Velocity);

   function Get_Transform
     (E : ECS.Entity.Entity_ID)
      return Transform.Transform;

   function Get_Velocity
     (E : ECS.Entity.Entity_ID)
      return Transform.Velocity;

end ECS.Entity_Manager;


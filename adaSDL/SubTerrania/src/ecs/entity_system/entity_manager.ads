with Ada.Containers.Hashed_Maps;
with ECS.Entity_System.Entity;
with ECS.Components.Transform;
with ECS.Components.Velocity;

package ECS.Entity_System.Entity_Manager is

   package Entity    renames ECS.Entity_System.Entity;
   package Transform renames ECS.Components.Transform;
   package Velocity  renames ECS.Components.Velocity;

   type Entity_Manager_Type is tagged private;

   procedure Initialize (Mgr : in out Entity_Manager_Type);

   function Create_Entity
     (Mgr : in out Entity_Manager_Type)
      return Entity.Entity_ID;

   procedure Add_Transform
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID);

   procedure Add_Velocity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID);

   function Get_Transform
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return access Transform.Transform;

   function Get_Velocity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return access Velocity.Velocity;

private

   function Hash
     (Key : Entity.Entity_ID)
      return Ada.Containers.Hash_Type;

   package Transform_Map is new Ada.Containers.Hashed_Maps
     (Key_Type        => Entity.Entity_ID,
      Element_Type    => Transform.Transform,
      Hash            => Hash,
      Equivalent_Keys => "=");

   package Velocity_Map is new Ada.Containers.Hashed_Maps
     (Key_Type        => Entity.Entity_ID,
      Element_Type    => Velocity.Velocity,
      Hash            => Hash,
      Equivalent_Keys => "=");

   type Entity_Manager_Type is tagged record
      Next_ID    : Entity.Entity_ID := 1;
      Transforms : Transform_Map.Map;
      Velocities : Velocity_Map.Map;
   end record;

end ECS.Entity_System.Entity_Manager;

with Ada.Containers.Hashed_Maps;

with ECS.Entity_System.Entity;
with ECS.Components.Collider;
with ECS.Components.Gravity;
with ECS.Components.Renderable;
with ECS.Components.Transform;
with ECS.Components.Velocity;

use type ECS.Entity_System.Entity.Entity_ID;
use type ECS.Components.Collider.Collider;
use type ECS.Components.Gravity.Gravity;
use type ECS.Components.Renderable.Renderable;
use type ECS.Components.Transform.Transform;
use type ECS.Components.Velocity.Velocity;

package ECS.Entity_System.Entity_Manager is

   package Entity    renames ECS.Entity_System.Entity;
   package Collider  renames ECS.Components.Collider;
   package Gravity   renames ECS.Components.Gravity;
   package Renderable renames ECS.Components.Renderable;
   package Transform renames ECS.Components.Transform;
   package Velocity  renames ECS.Components.Velocity;

   function Hash
     (Key : Entity.Entity_ID)
      return Ada.Containers.Hash_Type;

   package Collider_Map is new Ada.Containers.Hashed_Maps
     (Key_Type        => Entity.Entity_ID,
      Element_Type    => Collider.Collider,
      Hash            => Hash,
      Equivalent_Keys => "=");

   package Gravity_Map is new Ada.Containers.Hashed_Maps
     (Key_Type        => Entity.Entity_ID,
      Element_Type    => Gravity.Gravity,
      Hash            => Hash,
      Equivalent_Keys => "=");

   package Renderable_Map is new Ada.Containers.Hashed_Maps
     (Key_Type        => Entity.Entity_ID,
      Element_Type    => Renderable.Renderable,
      Hash            => Hash,
      Equivalent_Keys => "=");

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

   procedure Add_Collider
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID);

   procedure Add_Renderable
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID);

   procedure Add_Gravity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID);

   procedure Remove_Gravity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID);

   function Has_Gravity
     (Mgr : Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Boolean;

   function Get_Transform
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Transform_Map.Reference_Type;

   function Get_Velocity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Velocity_Map.Reference_Type;

   function Get_Collider
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Collider_Map.Reference_Type;

   function Get_Renderable
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Renderable_Map.Reference_Type;

   function Get_Gravity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Gravity_Map.Reference_Type;

private

   type Entity_Manager_Type is tagged record
      Next_ID     : Entity.Entity_ID := 1;
      Colliders   : Collider_Map.Map;
      Gravities   : Gravity_Map.Map;
      Renderables : Renderable_Map.Map;
      Transforms  : Transform_Map.Map;
      Velocities  : Velocity_Map.Map;
   end record;

end ECS.Entity_System.Entity_Manager;

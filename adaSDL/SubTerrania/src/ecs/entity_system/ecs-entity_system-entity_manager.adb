package body ECS.Entity_System.Entity_Manager is

   function Hash
     (Key : Entity.Entity_ID)
      return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type (Key);
   end Hash;

   procedure Initialize
     (Mgr : in out Entity_Manager_Type) is
   begin
      Mgr.Next_ID := 1;
      Mgr.Colliders.Clear;
      Mgr.Gravities.Clear;
      Mgr.Renderables.Clear;
      Mgr.Transforms.Clear;
      Mgr.Velocities.Clear;
   end Initialize;

   function Create_Entity
     (Mgr : in out Entity_Manager_Type)
      return Entity.Entity_ID is
      ID : constant Entity.Entity_ID := Mgr.Next_ID;
   begin
      Mgr.Next_ID := Mgr.Next_ID + 1;
      return ID;
   end Create_Entity;

   procedure Add_Transform
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID) is
   begin
      Mgr.Transforms.Insert (E, Transform.Transform'(others => <>));
   end Add_Transform;

   procedure Add_Velocity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID) is
   begin
      Mgr.Velocities.Insert (E, Velocity.Velocity'(others => <>));
   end Add_Velocity;

   procedure Add_Collider
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID) is
   begin
      Mgr.Colliders.Insert (E, Collider.Collider'(others => <>));
   end Add_Collider;

   procedure Add_Renderable
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID) is
   begin
      Mgr.Renderables.Insert (E, Renderable.Renderable'(others => <>));
   end Add_Renderable;

   procedure Add_Gravity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID) is
   begin
      if not Mgr.Gravities.Contains (E) then
         Mgr.Gravities.Insert (E, Gravity.Gravity'(others => <>));
      end if;
   end Add_Gravity;

   procedure Remove_Gravity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID) is
   begin
      if Mgr.Gravities.Contains (E) then
         Mgr.Gravities.Delete (E);
      end if;
   end Remove_Gravity;

   function Has_Gravity
     (Mgr : Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Boolean is
   begin
      return Mgr.Gravities.Contains (E);
   end Has_Gravity;

   function Get_Transform
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Transform_Map.Reference_Type is
   begin
      return Mgr.Transforms.Reference (E);
   end Get_Transform;

   function Get_Velocity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Velocity_Map.Reference_Type is
   begin
      return Mgr.Velocities.Reference (E);
   end Get_Velocity;

   function Get_Collider
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Collider_Map.Reference_Type is
   begin
      return Mgr.Colliders.Reference (E);
   end Get_Collider;

   function Get_Renderable
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Renderable_Map.Reference_Type is
   begin
      return Mgr.Renderables.Reference (E);
   end Get_Renderable;

   function Get_Gravity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return Gravity_Map.Reference_Type is
   begin
      return Mgr.Gravities.Reference (E);
   end Get_Gravity;

end ECS.Entity_System.Entity_Manager;

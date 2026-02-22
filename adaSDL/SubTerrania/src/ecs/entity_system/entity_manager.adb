package body ECS.Entity_System.Entity_Manager is

   function Hash
     (Key : Entity.Entity_ID)
      return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type (Key);
   end Hash;

   procedure Initialize (Mgr : in out Entity_Manager_Type) is
   begin
      null;
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

   function Get_Transform
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return access Transform.Transform is
   begin
      return Mgr.Transforms.Reference (E).Element'Access;
   end Get_Transform;

   function Get_Velocity
     (Mgr : in out Entity_Manager_Type;
      E   : Entity.Entity_ID)
      return access Velocity.Velocity is
   begin
      return Mgr.Velocities.Reference (E).Element'Access;
   end Get_Velocity;

end ECS.Entity_System.Entity_Manager;

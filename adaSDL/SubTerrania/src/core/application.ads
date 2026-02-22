with ECS.Entity_System.Entity_Manager;
with ECS.Entity_System.Entity;

package Application is

   procedure Init;
   procedure Render;
   procedure Update;
   procedure Shutdown;

   function Is_Running return Boolean;

private

   --  package EM renames ECS.Entity_System.Entity_Manager;
   --  package Entity renames ECS.Entity_System.Entity;

   Mgr    : ECS.Entity_System.Entity_Manager.Entity_Manager_Type;
   Player : ECS.Entity_System.Entity.Entity_ID;

   Running : Boolean := True;

end Application;

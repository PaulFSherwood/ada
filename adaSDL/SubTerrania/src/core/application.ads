with ECS.Entity_System.Entity;
with ECS.Entity_System.Entity_Manager;

package Application is

   procedure Init;
   procedure Draw;
   procedure Update;
   procedure Shutdown;

   function Is_Running return Boolean;

private

   Mgr    : ECS.Entity_System.Entity_Manager.Entity_Manager_Type;
   Player : ECS.Entity_System.Entity.Entity_ID;

   Running : Boolean := True;

end Application;

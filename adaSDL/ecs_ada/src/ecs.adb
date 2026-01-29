package body ECS is 
   Next_Id : Entity_Id := 0;

   procedure Create_Entity (E : out Entity_Id) is
   begin
      Next_Id := Next_Id + 1;
      E := Next_Id;
   end Create_Entity;
end ECS;

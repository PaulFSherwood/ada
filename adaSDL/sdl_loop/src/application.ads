package Application is
   Running : Boolean := True;

   procedure Init;
   procedure PollEvents;
   procedure Render;
   procedure Update;
   procedure Shutdown;

   function GetWidth return Natural;
   function GetHeight return Natural;
   function Is_Running return Boolean;
end Application;

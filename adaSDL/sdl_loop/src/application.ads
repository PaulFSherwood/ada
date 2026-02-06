package Application is
   Running : Boolean := True;

   procedure Init;
   procedure PollEvents;
   procedure Render;
   procedure Update;
   procedure Shutdown;

   function GetWidth return Natural;
   function GetHeight return Natural;
end Application;

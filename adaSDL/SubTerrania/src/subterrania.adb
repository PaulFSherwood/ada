with SDL;
with SDL.Events.Events;
with Application;

procedure SubTerrania is
begin
   Application.Init;

   while Application.Is_Running loop
      Application.PollEvents;
      Application.Render;
      Application.Update;
   end loop;
   Application.Shutdown;
end SubTerrania;

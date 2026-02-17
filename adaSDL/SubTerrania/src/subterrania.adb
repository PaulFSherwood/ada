with SDL;
with SDL.Events.Events;
with Application;
with Inputs;

procedure SubTerrania is
begin
   Application.Init;

   while Application.Is_Running loop
      Inputs.PollEvents;
      Application.Render;
      Application.Update;
   end loop;
   Application.Shutdown;
end SubTerrania;

with SDL;
with SDL.Events.Events;
with Application;

procedure Sdl_Loop is
begin
   Application.Init;

   while Application.Is_Running loop
      Application.PollEvents;
      Application.Render;
      Application.Update;
   end loop;
   Application.Shutdown;
end Sdl_Loop;

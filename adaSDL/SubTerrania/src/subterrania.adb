--  with SDL;
--  with SDL.Events.Events;
with Application;
with Inputs;
with Transform;

procedure SubTerrania is
   Player_Velocity : Transform.Velocity;
begin
   Application.Init;

   while Application.Is_Running loop
      Inputs.PollEvents (Player_Velocity);
      Application.Render;
      Application.Update;
   end loop;
   Application.Shutdown;
end SubTerrania;

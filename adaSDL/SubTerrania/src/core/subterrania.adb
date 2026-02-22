--  with SDL;
--  with SDL.Events.Events;
with Application;
with Inputs;
with ECS.Components.Velocity;

procedure SubTerrania is
   Player_Velocity : ECS.Components.Velocity.Velocity;
begin
   Application.Init;

   while Application.Is_Running loop
      Inputs.PollEvents (Player_Velocity);
      Application.Render;
      Application.Update;
   end loop;

   Application.Shutdown;
end SubTerrania;

with ECS;
with Components_Transform;
with Components_Velocity;
with Systems_Render;
with Systems_Movement;

with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;
with SDL.Events.Events;

--  alr with
--  alr search sdl
--  alr with sdlada
--  alr with --del sdlada
--  alr with
--  alr with sdlada
--  alr with
--
--  ADD Linker arguments --
--  alr build -- -largs $(sdl2-config --libs)

procedure Sdl_Test is
   Screen_Width  : constant := 640;
   Screen_Height : constant := 480;
   Running       : Boolean := True;

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;
   Event    : SDL.Events.Events.Events;

   Player : ECS.Entity_Id;
   T      : Components_Transform.Transform;
   V      : Components_Velocity.Velocity;

   use type SDL.Events.Event_Types;
begin
   if not SDL.Initialise (Flags => SDL.Enable_Screen) then
      return;
   end if;

   SDL.Video.Windows.Makers.Create
     (Win      => Window,
      Title    => "SDL Test",
      Position => SDL.Natural_Coordinates'(X => 10, Y => 10),
      Size     => SDL.Positive_Sizes'(Screen_Width, Screen_Height),
      Flags    => 0);

   SDL.Video.Renderers.Makers.Create
     (Renderer, Window.Get_Surface);

   Renderer.Set_Draw_Colour ((64, 16, 48, 255));

   ECS.Create_Entity (Player);

   T := (X => 100.0, Y => 100.0);
   ECS.Set_Transform (T);

   V := (VX => 60.0, VY => 0.0);
   ECS.Set_Velocity (V);

   while Running loop
      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            Running := False;
         end if;
      end loop;

      Systems_Movement.Update (1.0 / 60.0);

      Renderer.Fill (Rectangle => (0, 0, Screen_Width, Screen_Height));
      Systems_Render.Draw (Renderer, ECS.Get_Transform);
      Window.Update_Surface;
   end loop;

   Window.Finalize;
   SDL.Finalise;
end Sdl_Test;
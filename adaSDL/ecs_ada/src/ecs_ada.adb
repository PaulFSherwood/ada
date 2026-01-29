with ECS;

with SDL;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;
with SDL.Events.Events;

procedure Ecs_Ada is
   Screen_Width : constant := 640;
   Screen_Height : constant := 480;
   Running : Boolean := True;

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;
   Event    : SDL.Events.Events.Events;

   Player : ECS.Entity_Id;

   use type SDL.Events.Event_Types;
begin
   if not SDL.Initialise (Flags => SDL.Enable_Screen) then
      return;
   end if;

   SDL.Video.Windows.Makers.Create
     (Win     => Window,
      Title    => "ECS Ada + SDL",
      Position => SDL.Natural_Coordinates'(X => 10, Y => 10),
      Size => SDL.Positive_Sizes'(Screen_Width, Screen_Height),
      Flags => 0);

   SDL.Video.Renderers.Makers.Create
     (Renderer, Window.Get_Surface);

   Renderer.Set_Draw_Colour ((32, 32, 64, 255));

   ECS.Create_Entity (Player);

   while Running loop
      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            Running := False;
         end if;
      end loop;

      Renderer.Fill
        (Rectangle => (0, 0, Screen_Width, Screen_Height));

      Window.Update_Surface;
   end loop;

   Window.Finalize;
   SDL.Finalise;

end Ecs_Ada;

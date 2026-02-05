with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;
with SDL.Events.Events;
with Application;

procedure Sdl_Loop is
   --  | SDL inital setup
   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;
   Event    : SDL.Events.Events.Events;

   use type SDL.Events.Event_Types;
begin
   --  | SDL Init startup and check
   if not SDL.Initialise (Flags => SDL.Enable_Screen) then
      return;
   end if;
   --  | SDL window setup
   SDL.Video.Windows.Makers.Create
      (Win      => Window,
       Title    => "SDL Loop Test",
       Position => SDL.Natural_Coordinates'(X => 10, Y => 0),
       Size     => SDL.Positive_Sizes'(Application.SSW, Application.SSH),
       Flags    => 0);

   SDL.Video.Renderers.Makers.Create
      (Renderer, Window.Get_Surface);

   Renderer.Set_Draw_Colour ((64, 16, 48, 255));

   while Application.Running loop
      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            Application.Running := False;
         end if;
      end loop;

      Renderer.Fill (Rectangle => (0, 0, Application.SSW, Application.SSH));
      Window.Update_Surface;
   end loop;
   Window.Finalize;
   SDL.Finalise;
end Sdl_Loop;

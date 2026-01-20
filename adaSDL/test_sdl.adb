with SDL;
with SDL.Video;
with SDL.Events;
with SDL.Render;

procedure Test_SDL is
   Window   : SDL.Video.Window;
   Renderer : SDL.Render.Renderer;
   Event    : SDL.Events.Event;
   Running  : Boolean := True;
begin
   SDL.Init (SDL.Init_Video);

   Window :=
     SDL.Video.Create_Window
       ("Ada SDL Test",
        SDL.Video.Windowpos_Centered,
        SDL.Video.Windowpos_Centered,
        640, 480,
        SDL.Video.Window_Shown);

   Renderer :=
     SDL.Render.Create_Renderer
       (Window, -1, SDL.Render.Renderer_Accelerated);

   while Running loop
      while SDL.Events.Poll (Event) loop
         if Event.Event_Type = SDL.Events.Quit then
            Running := False;
         end if;
      end loop;

      SDL.Render.Set_Draw_Color (Renderer, 20, 20, 30, 255);
      SDL.Render.Clear (Renderer);
      SDL.Render.Present (Renderer);
   end loop;

   SDL.Render.Destroy (Renderer);
   SDL.Video.Destroy (Window);
   SDL.Quit;
end Test_SDL;


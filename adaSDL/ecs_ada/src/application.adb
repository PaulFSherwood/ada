with SDL;
with SDL.Video;
with SDL.Events;
with SDL.Render;
with SDL.Timers;

package body Application is

   Window   : SDL.Video.Window;
   Renderer : SDL.Render.Renderer;
   Running  : Boolean := True;

   procedure Init is
   begin
      SDL.Init (SDL.Init_Video);

      Window :=
        SDL.Video.Create_Window
          ("Ada SDL Flight Demo",
           SDL.Video.Windowpos_Centered,
           SDL.Video.Windowpos_Centered,
           800, 600,
           SDL.Video.Window_Shown);

      Renderer :=
        SDL.Render.Create_Renderer
          (Window, -1, SDL.Render.Renderer_Accelerated);
   end Init;

   procedure Run is
      Event : SDL.Events.Event;
   begin
      while Running loop
         while SDL.Events.Poll (Event) loop
            if Event.Event_Type = SDL.Events.Quit then
               Running := False;
            end if;
         end loop;

         SDL.Render.Set_Draw_Color (Renderer, 15, 15, 20, 255);
         SDL.Render.Clear (Renderer);

         -- (nothing rendered yet)

         SDL.Render.Present (Renderer);
         SDL.Timers.Delay (16);
      end loop;
   end Run;

   procedure Shutdown is
   begin
      SDL.Render.Destroy (Renderer);
      SDL.Video.Destroy (Window);
      SDL.Quit;
   end Shutdown;

end Application;


with SDL;
with SDL.Video;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;
with SDL.Events.Events;
with Transform;

package body Application is

   --  Window Setup
   Screen_Height : constant Natural := 800;
   Screen_Width  : constant Natural := 640;

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;
   Event    : SDL.Events.Events.Events;

   use type SDL.Events.Event_Types;

   Player_Transform : Transform.Transform;
   Player_Velocity  : Transform.Velocity;

   procedure Init is
   begin
      if not SDL.Initialise (Flags => SDL.Enable_Screen) then
         Running := False;
         return;
      end if;

      SDL.Video.Windows.Makers.Create
        (Win      => Window,
         Title    => "SDL Loop Test",
         Position => SDL.Natural_Coordinates'(X => 10, Y => 10),
         Size     =>
           SDL.Positive_Sizes'
             (SDL.Dimension (GetWidth), SDL.Dimension (GetHeight)),
         Flags    => 0);

      SDL.Video.Renderers.Makers.Create (Renderer, Window.Get_Surface);

      Renderer.Set_Draw_Colour ((64, 16, 48, 255));
      Transform.Update_Velocity (1.1, 1.1, Player_Velocity);
   end Init;

   procedure PollEvents is
   begin
      while SDL.Events.Events.Poll (Event) loop
         if Event.Common.Event_Type = SDL.Events.Quit then
            Running := False;
         end if;
      end loop;
   end PollEvents;

   procedure Render is
   begin
      Renderer.Fill
        (Rectangle =>
           (0,
            0,
            SDL.Natural_Dimension (GetWidth),
            SDL.Natural_Dimension (GetHeight)));
   end Render;

   procedure Update is
   begin
      Transform.Move_Player (Player_Transform, Player_Velocity);
      Window.Update_Surface;
   end Update;

   procedure Shutdown is
   begin
      Window.Finalize;
      SDL.Finalise;
   end Shutdown;

   --  Helper functions to get variables.
   function GetWidth return Natural is
   begin
      return Screen_Width;
   end GetWidth;

   function GetHeight return Natural is
   begin
      return Screen_Height;
   end GetHeight;

   function Is_Running return Boolean is
   begin
      return Running;
   end Is_Running;

end Application;

with SDL;
with SDL.Video;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;

with ECS.Components.Transform;
with ECS.Components.Velocity;
with ECS.Entity_System.Entity_Manager;
with ECS.Entity_System.Entity;
with Movement;

package body Application is

   package EM renames ECS.Entity_System.Entity_Manager;
   package Entity renames ECS.Entity_System.Entity;
   package Transform renames ECS.Components.Transform;
   package Velocity renames ECS.Components.Velocity;

   --  Window Setup
   Screen_Height : constant Natural := 800;
   Screen_Width  : constant Natural := 640;

   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;

   --------------------------------------------------
   --  INIT
   --------------------------------------------------

   procedure Init is
      T : access Transform.Transform;
      V : access Velocity.Velocity;
   begin
      if not SDL.Initialise (Flags => SDL.Enable_Screen) then
         Running := False;
         return;
      end if;

      SDL.Video.Windows.Makers.Create
        (Win      => Window,
         Title    => "ADA, ECS, SDL Test",
         Position => SDL.Natural_Coordinates'(X => 50, Y => 50),
         Size     =>
           SDL.Positive_Sizes'
           (SDL.Dimension (GetWidth),
           SDL.Dimension (GetHeight)),
         Flags    => 0);

      SDL.Video.Renderers.Makers.Create (Renderer, Window.Get_Surface);

      --  ECS Setup
      EM.Initialize (Mgr);

      Player := EM.Create_Entity (Mgr);

      EM.Add_Transform (Mgr, Player);
      EM.Add_Velocity  (Mgr, Player);

      T := EM.Get_Transform (Mgr, Player);
      V := EM.Get_Velocity  (Mgr, Player);

      T.X := 200.0;
      T.Y := 200.0;

      V.X := 2.0;
      V.Y := 1.0;
   end Init;

   --------------------------------------------------
   --  UPDATE
   --------------------------------------------------
   procedure Update is
      T : access Transform.Transform;
      V : access Velocity.Velocity;
   begin
      T := EM.Get_Transform (Mgr, Player);
      V := EM.Get_Velocity  (Mgr, Player);

      Movement.Move (T.all, V.all, 1.0);

      Window.Update_Surface;
   end Update;

   --------------------------------------------------
   --  RENDER
   --------------------------------------------------
   procedure Render is
      T : access Transform.Transform;
   begin
      Renderer.Fill
        (Rectangle =>
           (0,
            0,
            SDL.Natural_Dimension (Screen_Width),
            SDL.Natural_Dimension (Screen_Height)));
      T := EM.Get_Transform (Mgr, Player);

      Renderer.Set_Draw_Colour ((255, 0, 200, 255));

      Renderer.Fill
      (Rectangle =>
      (SDL.Natural_Dimension (Integer (T.X)),
      SDL.Natural_Dimension (Integer (T.Y)),
      40,
      40));
   end Render;

   procedure Shutdown is
   begin
      Window.Finalize;
      SDL.Finalise;
   end Shutdown;

   function Is_Running return Boolean is
   begin
      return Running;
   end Is_Running;

end Application;

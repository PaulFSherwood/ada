with SDL;

package body Systems_Render is

   procedure Draw
     (Renderer : in out SDL.Video.Renderers.Renderer;
      T        : Components_Transform.Transform) is
   begin
      Renderer.Fill
        (Rectangle =>
           (SDL.Coordinate (T.X),
            SDL.Coordinate (T.Y),
            SDL.Coordinate (40),
            SDL.Coordinate (20)));
   end Draw;

end Systems_Render;
with SDL.Video.Renderers;

package Sprites is

   procedure Draw_Ship_01
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Center_X : Float;
      Center_Y : Float;
      Camera_X : Float;
      Camera_Y : Float);

end Sprites;

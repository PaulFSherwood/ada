with SDL.Video.Renderers;
with Components_Transform;

package Systems_Render is
   procedure Draw
     (Renderer : in out SDL.Video.Renderers.Renderer;
      T        : Components_Transform.Transform);
end Systems_Render;
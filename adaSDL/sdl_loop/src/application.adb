with SDL.Video;  --   For Dimension

package body Application is
   --  | Window setup
   Screen_Height : constant SDL.Video.Sizes.Dimension := 800;
   Screen_Width  : constant SDL.Video.Sizes.Dimension := 640;

   function SSW return SDL.Video.Sizes.Dimension is
   begin
      return Screen_Width;
   end SSW;

   function SSH return SDL.Video.Sizes.Dimension is
   begin
      return Screen_Height;
   end SSH;
end Application;

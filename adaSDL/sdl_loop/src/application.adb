with SDL.Video;  --   For Dimension

package body Application is
   --  | Window setup
   Screen_Height : constant Natural := 800;
   Screen_Width  : constant Natural := 640;

   function SSW return Natural is
   begin
      return Screen_Width;
   end SSW;

   function SSH return Natural is
   begin
      return Screen_Height;
   end SSH;
end Application;

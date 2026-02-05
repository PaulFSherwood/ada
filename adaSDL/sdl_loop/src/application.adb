package body Application is
   --  | Window setup
   Screen_Height : constant := 800;
   Screen_Width  : constant := 640;
   --  | Window setup
   Screen_Height : constant := 800;
   Screen_Width  : constant := 640;

   function SSW return Dimension is
      return Screen_Width;
   end SSW;
   function SSH return Dimension is
      return Screen_Height;
   end SSH;
end Application;

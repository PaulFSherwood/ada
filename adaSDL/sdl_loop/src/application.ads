with SDL.Video;

package Application is
   Running : Boolean := True;
   function SSW return SDL.Video.Sizes.Dimension;
   function SSH return SDL.Video.Sizes.Dimension;
end Application;

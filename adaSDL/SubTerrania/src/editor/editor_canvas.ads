with Gtkada.Builder;

package Editor_Canvas is

   procedure Initialize
     (Builder : Gtkada.Builder.Gtkada_Builder);

   procedure Rebuild;
   procedure Fit_Map;
   procedure Zoom_In;
   procedure Zoom_Out;
   procedure Center_On_Start;
   procedure Refresh_Inspector;

end Editor_Canvas;

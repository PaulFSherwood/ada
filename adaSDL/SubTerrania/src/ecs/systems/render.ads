with SDL;
with SDL.Video.Renderers;

with ECS.Components.Renderable;
with ECS.Components.Transform;
with Level;
with Gameplay;

package Render is

   procedure Draw_Frame
     (Renderer       : in out SDL.Video.Renderers.Renderer;
      Screen_Width   : Natural;
      Screen_Height  : Natural;
      Tiles          : Level.Tile_Map;
      Objects        : Level.Object_Array;
      Mode           : Level.Game_Mode;
      Brush          : Level.Brush_Mode;
      Cursor_X       : Float;
      Cursor_Y       : Float;
      Current_Tile   : Level.Tile_Kind;
      Current_Kind   : Level.Object_Kind;
      Current_Motion : Level.Motion_Kind;
      Camera_X       : Float;
      Camera_Y       : Float;
      Player_T       : ECS.Components.Transform.Transform;
      Player_R       : ECS.Components.Renderable.Renderable;
      Gravity_On     : Boolean;
      Is_Playtest    : Boolean;
      Info           : Level.Level_Info;
      Status         : Gameplay.Player_Status;
      View           : Gameplay.Editor_View);

   procedure Draw_Main_Menu
     (Renderer      : in out SDL.Video.Renderers.Renderer;
      Screen_Width  : Natural;
      Screen_Height : Natural;
      Selected      : Positive);

   procedure Draw_Load_Menu
     (Renderer      : in out SDL.Video.Renderers.Renderer;
      Screen_Width  : Natural;
      Screen_Height : Natural;
      Selected      : Positive;
      Info          : Level.Level_Info);

end Render;

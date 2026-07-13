package Editor_Layout is
   --  Phase 10A editor shell layout.  Keep editor geometry here so
   --  Application input routing and Render drawing cannot drift apart.

   Window_Width  : constant Natural := 1_280;
   Window_Height : constant Natural := 720;

   Menu_Bar_Top    : constant Float := 0.0;
   Menu_Bar_Height : constant Float := 28.0;

   Toolbar_Top    : constant Float := Menu_Bar_Height;
   Toolbar_Height : constant Float := 44.0;

   Content_Top : constant Float := Menu_Bar_Height + Toolbar_Height;

   Status_Bar_Height : constant Float := 28.0;
   Status_Bar_Top    : constant Float :=
     Float (Window_Height) - Status_Bar_Height;

   Bottom_Panel_Height : constant Float := 120.0;
   Bottom_Panel_Top    : constant Float :=
     Status_Bar_Top - Bottom_Panel_Height;

   Left_Panel_Left  : constant Float := 0.0;
   Left_Panel_Top   : constant Float := Content_Top;
   Left_Panel_Width : constant Float := 240.0;

   Right_Panel_Width : constant Float := 280.0;
   Right_Panel_Left  : constant Float :=
     Float (Window_Width) - Right_Panel_Width;
   Right_Panel_Top    : constant Float := Content_Top;
   Right_Panel_Height : constant Float :=
     Bottom_Panel_Top - Content_Top;

   Map_Left   : constant Float := Left_Panel_Width;
   Map_Top    : constant Float := Content_Top;
   Map_Right  : constant Float := Right_Panel_Left;
   Map_Bottom : constant Float := Bottom_Panel_Top;

   Map_Width  : constant Float := Map_Right - Map_Left;
   Map_Height : constant Float := Map_Bottom - Map_Top;

   Palette_Left   : constant Float := Left_Panel_Left;
   Palette_Top    : constant Float := Left_Panel_Top;
   Palette_Width  : constant Float := Left_Panel_Width;
   Palette_Height : constant Float := 360.0;

   Layers_Left   : constant Float := Left_Panel_Left;
   Layers_Top    : constant Float := Palette_Top + Palette_Height;
   Layers_Width  : constant Float := Left_Panel_Width;
   Layers_Height : constant Float := Bottom_Panel_Top - Layers_Top;

   Bottom_Panel_Left  : constant Float := Map_Left;
   Bottom_Panel_Width : constant Float :=
     Float (Window_Width) - Bottom_Panel_Left;

   --  Clickable palette rows.  These match Render.Draw_Editor_Palette.
   Palette_Row_X      : constant Float := Palette_Left + 18.0;
   Palette_Row_Width  : constant Float := Palette_Width - 36.0;
   Palette_Row_Height : constant Float := 24.0;

   Wall_Row_Y    : constant Float := Palette_Top + 88.0;
   Water_Row_Y   : constant Float := Palette_Top + 114.0;
   Landing_Row_Y : constant Float := Palette_Top + 140.0;
   Start_Row_Y   : constant Float := Palette_Top + 166.0;

   Miner_Row_Y   : constant Float := Palette_Top + 228.0;
   Enemy_Row_Y   : constant Float := Palette_Top + 254.0;
   Powerup_Row_Y : constant Float := Palette_Top + 280.0;

   --  Phase 10C clickable editor chrome.
   Menu_File_X  : constant Float := 6.0;
   Menu_Edit_X  : constant Float := 58.0;
   Menu_View_X  : constant Float := 110.0;
   Menu_Level_X : constant Float := 162.0;
   Menu_Test_X  : constant Float := 228.0;
   Menu_Help_X  : constant Float := 280.0;
   Menu_Item_W  : constant Float := 50.0;

   Toolbar_Button_Y : constant Float := Toolbar_Top + 6.0;
   Toolbar_Button_W : constant Float := 44.0;
   Toolbar_Button_H : constant Float := 28.0;

   Save_Button_X : constant Float := 12.0;
   Load_Button_X : constant Float := 62.0;
   Test_Button_X : constant Float := 112.0;
   Grid_Button_X : constant Float := 162.0;

   Workspace_Tab_X      : constant Float := 230.0;
   Workspace_Tab_Y      : constant Float := Toolbar_Top + 6.0;
   Workspace_Tab_W      : constant Float := 66.0;
   Workspace_Tab_H      : constant Float := 28.0;
   Workspace_Tab_Gap    : constant Float := 5.0;

   Mini_Map_Width  : constant Float := 220.0;
   Mini_Map_Height : constant Float := 96.0;
   Mini_Map_Left   : constant Float :=
     Float (Window_Width) - Mini_Map_Width - 12.0;
   Mini_Map_Top    : constant Float := Bottom_Panel_Top + 12.0;
end Editor_Layout;

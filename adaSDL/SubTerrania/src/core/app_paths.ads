package App_Paths is
   Assets_Root       : constant String := "assets";
   Levels_Root       : constant String := Assets_Root & "/levels";
   Images_Root       : constant String := Assets_Root & "/images";
   Maps_Image_Root   : constant String := Images_Root & "/maps";
   Sprites_Root      : constant String := Images_Root & "/sprites";
   UI_Image_Root     : constant String := Images_Root & "/ui";
   Audio_Root        : constant String := Assets_Root & "/audio";
   Music_Root        : constant String := Audio_Root & "/music";
   SFX_Root          : constant String := Audio_Root & "/sfx";
   Shield_SFX_Root   : constant String := SFX_Root & "/shields";
   Weapon_SFX_Root   : constant String := SFX_Root & "/weapons";
   UI_SFX_Root       : constant String := SFX_Root & "/ui";
   Fonts_Root        : constant String := Assets_Root & "/fonts";

   Default_Level_Path : constant String := Levels_Root & "/stage01.map";

   --  Temporary compatibility path for levels saved by older phases.
   --  This can be removed once all old saves have been migrated.
   Legacy_Level_Path  : constant String := "level01.map";
end App_Paths;

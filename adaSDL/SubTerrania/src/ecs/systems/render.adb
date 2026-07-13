with Ada.Strings.Unbounded;

with Gameplay;

with Mission1_Background;
with Sprites;
with SDL.Video.Palettes;

package body Render is

   package US renames Ada.Strings.Unbounded;

   use type Level.Game_Mode;
   use type Level.Brush_Mode;
   use type Level.Tile_Kind;
   use type Gameplay.Editor_View;

   function To_Dim
     (V : Float)
      return SDL.Natural_Dimension is
   begin
      if V <= 0.0 then
         return SDL.Natural_Dimension (0);
      else
         return SDL.Natural_Dimension (Integer (V));
      end if;
   end To_Dim;

   function To_Channel
     (C : ECS.Components.Renderable.Colour_Channel)
      return SDL.Video.Palettes.Colour_Component is
   begin
      return SDL.Video.Palettes.Colour_Component (C);
   end To_Channel;

   procedure Draw_Box
     (Renderer : in out SDL.Video.Renderers.Renderer;
      X        : Float;
      Y        : Float;
      W        : Float;
      H        : Float;
      Camera_X : Float;
      Camera_Y : Float) is
   begin
      Renderer.Fill
        (Rectangle =>
           (To_Dim (X - Camera_X),
            To_Dim (Y - Camera_Y),
            To_Dim (W),
            To_Dim (H)));
   end Draw_Box;

   procedure Draw_Centered_Box
     (Renderer : in out SDL.Video.Renderers.Renderer;
      X        : Float;
      Y        : Float;
      W        : Float;
      H        : Float;
      Camera_X : Float;
      Camera_Y : Float) is
   begin
      Draw_Box
        (Renderer,
         X - W / 2.0,
         Y - H / 2.0,
         W,
         H,
         Camera_X,
         Camera_Y);
   end Draw_Centered_Box;

   procedure Set_Tile_Colour
     (Renderer : in out SDL.Video.Renderers.Renderer;
      T        : Level.Tile_Kind) is
   begin
      case T is
         when Level.Space_Tile =>
            Renderer.Set_Draw_Colour ((0, 0, 0, 255));

         when Level.Wall_Tile =>
            Renderer.Set_Draw_Colour ((120, 80, 40, 255));

         when Level.Landing_Tile | Level.Start_Tile =>
            Renderer.Set_Draw_Colour ((50, 180, 50, 255));

         when Level.Water_Tile =>
            Renderer.Set_Draw_Colour ((36, 71, 88, 255));
      end case;
   end Set_Tile_Colour;

   procedure Set_Object_Colour
     (Renderer : in out SDL.Video.Renderers.Renderer;
      K        : Level.Object_Kind) is
   begin
      case K is
         when Level.Miner =>
            Renderer.Set_Draw_Colour ((0, 200, 255, 255));

         when Level.Enemy =>
            Renderer.Set_Draw_Colour ((255, 0, 0, 255));

         when Level.Powerup =>
            Renderer.Set_Draw_Colour ((0, 255, 0, 255));

         when Level.Fuel =>
            Renderer.Set_Draw_Colour ((255, 128, 0, 255));

         when Level.Shield =>
            Renderer.Set_Draw_Colour ((60, 160, 255, 255));

         when Level.Weight =>
            Renderer.Set_Draw_Colour ((180, 180, 180, 255));

         when Level.Goal =>
            Renderer.Set_Draw_Colour ((255, 255, 0, 255));

         when Level.Base =>
            Renderer.Set_Draw_Colour ((0, 180, 180, 255));

         when Level.Gate =>
            Renderer.Set_Draw_Colour ((210, 120, 40, 255));

         when Level.Boss_Spawn =>
            Renderer.Set_Draw_Colour ((255, 0, 255, 255));

         when Level.Platform =>
            Renderer.Set_Draw_Colour ((160, 80, 255, 255));
      end case;
   end Set_Object_Colour;

   subtype Glyph is String (1 .. 35);

   function Glyph_For
     (Ch : Character)
      return Glyph is
   begin
      case Ch is
         when 'A' =>
            return "01110" & "10001" & "10001" & "11111" &
                   "10001" & "10001" & "10001";
         when 'B' =>
            return "11110" & "10001" & "10001" & "11110" &
                   "10001" & "10001" & "11110";
         when 'C' =>
            return "01111" & "10000" & "10000" & "10000" &
                   "10000" & "10000" & "01111";
         when 'D' =>
            return "11110" & "10001" & "10001" & "10001" &
                   "10001" & "10001" & "11110";
         when 'E' =>
            return "11111" & "10000" & "10000" & "11110" &
                   "10000" & "10000" & "11111";
         when 'F' =>
            return "11111" & "10000" & "10000" & "11110" &
                   "10000" & "10000" & "10000";
         when 'G' =>
            return "01111" & "10000" & "10000" & "10011" &
                   "10001" & "10001" & "01111";
         when 'H' =>
            return "10001" & "10001" & "10001" & "11111" &
                   "10001" & "10001" & "10001";
         when 'I' =>
            return "11111" & "00100" & "00100" & "00100" &
                   "00100" & "00100" & "11111";
         when 'J' =>
            return "00111" & "00010" & "00010" & "00010" &
                   "10010" & "10010" & "01100";
         when 'K' =>
            return "10001" & "10010" & "10100" & "11000" &
                   "10100" & "10010" & "10001";
         when 'L' =>
            return "10000" & "10000" & "10000" & "10000" &
                   "10000" & "10000" & "11111";
         when 'M' =>
            return "10001" & "11011" & "10101" & "10101" &
                   "10001" & "10001" & "10001";
         when 'N' =>
            return "10001" & "11001" & "10101" & "10011" &
                   "10001" & "10001" & "10001";
         when 'O' =>
            return "01110" & "10001" & "10001" & "10001" &
                   "10001" & "10001" & "01110";
         when 'P' =>
            return "11110" & "10001" & "10001" & "11110" &
                   "10000" & "10000" & "10000";
         when 'Q' =>
            return "01110" & "10001" & "10001" & "10001" &
                   "10101" & "10010" & "01101";
         when 'R' =>
            return "11110" & "10001" & "10001" & "11110" &
                   "10100" & "10010" & "10001";
         when 'S' =>
            return "01111" & "10000" & "10000" & "01110" &
                   "00001" & "00001" & "11110";
         when 'T' =>
            return "11111" & "00100" & "00100" & "00100" &
                   "00100" & "00100" & "00100";
         when 'U' =>
            return "10001" & "10001" & "10001" & "10001" &
                   "10001" & "10001" & "01110";
         when 'V' =>
            return "10001" & "10001" & "10001" & "10001" &
                   "10001" & "01010" & "00100";
         when 'W' =>
            return "10001" & "10001" & "10001" & "10101" &
                   "10101" & "10101" & "01010";
         when 'X' =>
            return "10001" & "10001" & "01010" & "00100" &
                   "01010" & "10001" & "10001";
         when 'Y' =>
            return "10001" & "10001" & "01010" & "00100" &
                   "00100" & "00100" & "00100";
         when 'Z' =>
            return "11111" & "00001" & "00010" & "00100" &
                   "01000" & "10000" & "11111";
         when '0' =>
            return "01110" & "10001" & "10011" & "10101" &
                   "11001" & "10001" & "01110";
         when '1' =>
            return "00100" & "01100" & "00100" & "00100" &
                   "00100" & "00100" & "01110";
         when '2' =>
            return "01110" & "10001" & "00001" & "00010" &
                   "00100" & "01000" & "11111";
         when '3' =>
            return "11110" & "00001" & "00001" & "01110" &
                   "00001" & "00001" & "11110";
         when '4' =>
            return "00010" & "00110" & "01010" & "10010" &
                   "11111" & "00010" & "00010";
         when '5' =>
            return "11111" & "10000" & "10000" & "11110" &
                   "00001" & "00001" & "11110";
         when '6' =>
            return "01110" & "10000" & "10000" & "11110" &
                   "10001" & "10001" & "01110";
         when '7' =>
            return "11111" & "00001" & "00010" & "00100" &
                   "01000" & "01000" & "01000";
         when '8' =>
            return "01110" & "10001" & "10001" & "01110" &
                   "10001" & "10001" & "01110";
         when '9' =>
            return "01110" & "10001" & "10001" & "01111" &
                   "00001" & "00001" & "01110";
         when ':' =>
            return "00000" & "00100" & "00100" & "00000" &
                   "00100" & "00100" & "00000";
         when '-' =>
            return "00000" & "00000" & "00000" & "11111" &
                   "00000" & "00000" & "00000";
         when '>' =>
            return "10000" & "01000" & "00100" & "00010" &
                   "00100" & "01000" & "10000";
         when '/' =>
            return "00001" & "00010" & "00010" & "00100" &
                   "01000" & "01000" & "10000";
         when others =>
            return "00000" & "00000" & "00000" & "00000" &
                   "00000" & "00000" & "00000";
      end case;
   end Glyph_For;

   procedure Draw_Screen_Box
     (Renderer : in out SDL.Video.Renderers.Renderer;
      X        : Float;
      Y        : Float;
      W        : Float;
      H        : Float) is
   begin
      Renderer.Fill
        (Rectangle =>
           (To_Dim (X),
            To_Dim (Y),
            To_Dim (W),
            To_Dim (H)));
   end Draw_Screen_Box;

   procedure Draw_Char
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Ch       : Character;
      X        : Float;
      Y        : Float;
      Scale    : Float) is
      Data : constant Glyph := Glyph_For (Ch);
      P    : Positive;
   begin
      for Row in 0 .. 6 loop
         for Col in 0 .. 4 loop
            P := Positive (Row * 5 + Col + 1);
            if Data (P) = '1' then
               Draw_Screen_Box
                 (Renderer,
                  X + Float (Col) * Scale,
                  Y + Float (Row) * Scale,
                  Scale,
                  Scale);
            end if;
         end loop;
      end loop;
   end Draw_Char;

   procedure Draw_Text
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Text     : String;
      X        : Float;
      Y        : Float;
      Scale    : Float) is
      Pen_X : Float := X;
   begin
      for Ch of Text loop
         Draw_Char (Renderer, Ch, Pen_X, Y, Scale);
         Pen_X := Pen_X + 6.0 * Scale;
      end loop;
   end Draw_Text;

   procedure Draw_Menu_Item
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Label    : String;
      X        : Float;
      Y        : Float;
      Selected : Boolean) is
   begin
      if Selected then
         Renderer.Set_Draw_Colour ((80, 80, 120, 255));
         Draw_Screen_Box (Renderer, X - 14.0, Y - 6.0, 300.0, 24.0);
         Renderer.Set_Draw_Colour ((255, 255, 255, 255));
         Draw_Text (Renderer, ">", X - 8.0, Y, 2.0);
      else
         Renderer.Set_Draw_Colour ((180, 180, 190, 255));
      end if;

      Draw_Text (Renderer, Label, X + 12.0, Y, 2.0);
   end Draw_Menu_Item;

   procedure Draw_Menu_Background
     (Renderer      : in out SDL.Video.Renderers.Renderer;
      Screen_Width  : Natural;
      Screen_Height : Natural) is
   begin
      Renderer.Set_Draw_Colour ((8, 8, 16, 255));
      Renderer.Fill
        (Rectangle =>
           (0,
            0,
            SDL.Natural_Dimension (Screen_Width),
            SDL.Natural_Dimension (Screen_Height)));

      Renderer.Set_Draw_Colour ((30, 22, 45, 255));
      Draw_Screen_Box
        (Renderer,
         70.0,
         70.0,
         Float (Screen_Width) - 140.0,
         Float (Screen_Height) - 140.0);
   end Draw_Menu_Background;

   procedure Draw_Main_Menu
     (Renderer      : in out SDL.Video.Renderers.Renderer;
      Screen_Width  : Natural;
      Screen_Height : Natural;
      Selected      : Positive) is
      X : constant Float := Float (Screen_Width) / 2.0 - 150.0;
      Y : constant Float := 185.0;
   begin
      Draw_Menu_Background (Renderer, Screen_Width, Screen_Height);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text
        (Renderer,
         "ADA SUBTERRANIA",
         Float (Screen_Width) / 2.0 - 180.0,
         110.0,
         3.0);

      Draw_Menu_Item (Renderer, "START GAME", X, Y, Selected = 1);
      Draw_Menu_Item (Renderer, "LOAD GAME", X, Y + 36.0, Selected = 2);
            Draw_Menu_Item
        (Renderer, "FULL MAP EDITOR", X, Y + 72.0, Selected = 3);
      Draw_Menu_Item (Renderer, "QUIT", X, Y + 108.0, Selected = 4);

      Renderer.Set_Draw_Colour ((150, 150, 160, 255));
      Draw_Text (Renderer, "W S MOVE", X, 500.0, 2.0);
      Draw_Text (Renderer, "P OR E SELECT", X, 520.0, 2.0);
   end Draw_Main_Menu;

   procedure Draw_Load_Menu
     (Renderer      : in out SDL.Video.Renderers.Renderer;
      Screen_Width  : Natural;
      Screen_Height : Natural;
      Selected      : Positive;
      Info          : Level.Level_Info) is
      X : constant Float := Float (Screen_Width) / 2.0 - 150.0;
      Y : constant Float := 230.0;
   begin
      Draw_Menu_Background (Renderer, Screen_Width, Screen_Height);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text
        (Renderer,
         "LOAD GAME",
         Float (Screen_Width) / 2.0 - 100.0,
         90.0,
         3.0);

      Draw_Text
        (Renderer,
         "STAGE " & US.To_String (Info.Stage_Name),
         X,
         145.0,
         2.0);
      Draw_Text
        (Renderer,
         "TITLE " & US.To_String (Info.Title),
         X,
         165.0,
         2.0);
      Draw_Text
        (Renderer,
         "NEXT " & US.To_String (Info.Next_Level),
         X,
         185.0,
         2.0);

      Draw_Menu_Item (Renderer, "LOAD LEVEL MAP", X, Y, Selected = 1);
      Draw_Menu_Item (Renderer, "BACK", X, Y + 36.0, Selected = 2);

      Renderer.Set_Draw_Colour ((150, 150, 160, 255));
      Draw_Text (Renderer, "P OR E SELECT", X, 520.0, 2.0);
   end Draw_Load_Menu;

   function Brush_Name
     (Brush : Level.Brush_Mode)
      return String is
   begin
      case Brush is
         when Level.Tile_Brush =>
            return "TILE";
         when Level.Object_Brush =>
            return "OBJECT";
      end case;
   end Brush_Name;

   function Tile_Name
     (Tile : Level.Tile_Kind)
      return String is
   begin
      case Tile is
         when Level.Space_Tile =>
            return "SPACE";
         when Level.Wall_Tile =>
            return "WALL";
         when Level.Landing_Tile =>
            return "LAND";
         when Level.Water_Tile =>
            return "WATER";
         when Level.Start_Tile =>
            return "START";
      end case;
   end Tile_Name;

   function Object_Name
     (Kind : Level.Object_Kind)
      return String is
   begin
      case Kind is
         when Level.Miner =>
            return "MINER";
         when Level.Enemy =>
            return "ENEMY";
         when Level.Powerup =>
            return "POWER";
         when Level.Fuel =>
            return "FUEL";
         when Level.Shield =>
            return "SHIELD";
         when Level.Weight =>
            return "WEIGHT";
         when Level.Goal =>
            return "GOAL";
         when Level.Base =>
            return "BASE";
         when Level.Gate =>
            return "GATE";
         when Level.Platform =>
            return "PLAT";
         when Level.Boss_Spawn =>
            return "BOSS";
      end case;
   end Object_Name;

   function Motion_Name
     (Motion : Level.Motion_Kind)
      return String is
   begin
      case Motion is
         when Level.Static =>
            return "STATIC";
         when Level.Patrol_X =>
            return "PATROL X";
         when Level.Patrol_Y =>
            return "PATROL Y";
      end case;
   end Motion_Name;

   procedure Draw_Editor_Legend
     (Renderer       : in out SDL.Video.Renderers.Renderer;
      Screen_Width   : Natural;
      Brush          : Level.Brush_Mode;
      Current_Tile   : Level.Tile_Kind;
      Current_Kind   : Level.Object_Kind;
      Current_Motion : Level.Motion_Kind) is
      X     : constant Float := Float (Screen_Width) - 230.0;
      Y     : constant Float := 10.0;
      Scale : constant Float := 2.0;
   begin
      Renderer.Set_Draw_Colour ((0, 0, 0, 255));
      Draw_Screen_Box (Renderer, X, Y, 220.0, 180.0);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "EDIT MODE", X + 10.0, Y + 10.0, Scale);
      Draw_Text
        (Renderer,
         "BRUSH:" & Brush_Name (Brush),
         X + 10.0,
         Y + 30.0,
         Scale);

      if Brush = Level.Tile_Brush then
         Draw_Text
           (Renderer,
            "TILE:" & Tile_Name (Current_Tile),
            X + 10.0,
            Y + 50.0,
            Scale);
      else
         Draw_Text
           (Renderer,
            "OBJ:" & Object_Name (Current_Kind),
            X + 10.0,
            Y + 50.0,
            Scale);
      end if;

      Draw_Text
        (Renderer,
         "MOTION:" & Motion_Name (Current_Motion),
         X + 10.0,
         Y + 70.0,
         Scale);

      Draw_Text (Renderer, "E TEST", X + 10.0, Y + 100.0, Scale);
      Draw_Text (Renderer, "T BRUSH", X + 10.0, Y + 116.0, Scale);
      Draw_Text (Renderer, "N NEXT", X + 10.0, Y + 132.0, Scale);
      Draw_Text (Renderer, "P PLACE  O DELETE", X + 10.0, Y + 148.0, Scale);
      Draw_Text (Renderer, "F SAVE   L LOAD", X + 10.0, Y + 164.0, Scale);
      Draw_Text (Renderer, "Q MENU", X + 10.0, Y + 180.0, Scale);
   end Draw_Editor_Legend;

   procedure Draw_Editor_Palette
     (Renderer       : in out SDL.Video.Renderers.Renderer;
      Brush          : Level.Brush_Mode;
      Current_Tile   : Level.Tile_Kind;
      Current_Kind   : Level.Object_Kind;
      Current_Motion : Level.Motion_Kind) is
      X     : constant Float := 10.0;
      Y     : constant Float := 10.0;
      Scale : constant Float := 2.0;
   begin
      Renderer.Set_Draw_Colour ((0, 0, 0, 255));
      Draw_Screen_Box (Renderer, X, Y, 190.0, 360.0);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "PALETTE", X + 10.0, Y + 10.0, Scale);
      Draw_Text
        (Renderer,
         "BRUSH " & Brush_Name (Brush),
         X + 10.0,
         Y + 34.0,
         Scale);

      Draw_Text (Renderer, "TILE", X + 10.0, Y + 70.0, Scale);

      Set_Tile_Colour (Renderer, Level.Wall_Tile);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 92.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "WALL", X + 36.0, Y + 94.0, Scale);

      Set_Tile_Colour (Renderer, Level.Water_Tile);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 118.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "WATER", X + 36.0, Y + 120.0, Scale);

      Set_Tile_Colour (Renderer, Level.Landing_Tile);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 144.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "LAND", X + 36.0, Y + 146.0, Scale);

      Set_Tile_Colour (Renderer, Level.Start_Tile);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 170.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "START", X + 36.0, Y + 172.0, Scale);

      Draw_Text (Renderer, "OBJECT", X + 10.0, Y + 210.0, Scale);

      Set_Object_Colour (Renderer, Level.Miner);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 232.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "MINER", X + 36.0, Y + 234.0, Scale);

      Set_Object_Colour (Renderer, Level.Enemy);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 258.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "ENEMY", X + 36.0, Y + 260.0, Scale);

      Set_Object_Colour (Renderer, Level.Powerup);
      Draw_Screen_Box (Renderer, X + 10.0, Y + 284.0, 18.0, 18.0);
      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "POWER", X + 36.0, Y + 286.0, Scale);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text
        (Renderer,
         "SEL " & Tile_Name (Current_Tile),
         X + 10.0,
         Y + 318.0,
         Scale);

      if Brush = Level.Object_Brush then
         Draw_Text
           (Renderer,
            "OBJ " & Object_Name (Current_Kind),
            X + 10.0,
            Y + 338.0,
            Scale);
      else
         Draw_Text
           (Renderer,
            "MOT " & Motion_Name (Current_Motion),
            X + 10.0,
            Y + 338.0,
            Scale);
      end if;
   end Draw_Editor_Palette;

   procedure Draw_Tiles
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Tiles    : Level.Tile_Map;
      Camera_X : Float;
      Camera_Y : Float) is
   begin
      for Y in Level.Tile_Y loop
         for X in Level.Tile_X loop
            if Tiles (Y, X) /= Level.Space_Tile then
               Set_Tile_Colour (Renderer, Tiles (Y, X));
               Draw_Box
                 (Renderer,
                  Float ((X - 1) * Level.Tile_Size),
                  Float ((Y - 1) * Level.Tile_Size),
                  Float (Level.Tile_Size),
                  Float (Level.Tile_Size),
                  Camera_X,
                  Camera_Y);
            end if;
         end loop;
      end loop;
   end Draw_Tiles;

   procedure Draw_Objects
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Objects  : Level.Object_Array;
      Camera_X : Float;
      Camera_Y : Float) is
   begin
      for I in Level.Object_Index loop
         if Objects (I).Used then
            Set_Object_Colour (Renderer, Objects (I).Kind);
            Draw_Centered_Box
              (Renderer,
               Objects (I).X,
               Objects (I).Y,
               Objects (I).W,
               Objects (I).H,
               Camera_X,
               Camera_Y);
         end if;
      end loop;
   end Draw_Objects;

   procedure Draw_Mission_Background
     (Renderer      : in out SDL.Video.Renderers.Renderer;
      Camera_X      : Float;
      Camera_Y      : Float;
      Screen_Width  : Natural;
      Screen_Height : Natural) is
      subtype Cell_Channel is Mission1_Background.Colour_Channel;

      function To_SDL
        (C : Cell_Channel)
         return SDL.Video.Palettes.Colour_Component is
      begin
         return SDL.Video.Palettes.Colour_Component (C);
      end To_SDL;

      First_X : constant Integer :=
        Integer
          (Float'Floor
             (Camera_X / Float (Mission1_Background.Cell_Size))) + 1;
      First_Y : constant Integer :=
        Integer
          (Float'Floor
             (Camera_Y / Float (Mission1_Background.Cell_Size))) + 1;
      Last_X : constant Integer :=
        First_X + Screen_Width / Mission1_Background.Cell_Size + 2;
      Last_Y : constant Integer :=
        First_Y + Screen_Height / Mission1_Background.Cell_Size + 2;
      Draw_X : Float;
      Draw_Y : Float;
      Red    : Cell_Channel;
      Green  : Cell_Channel;
      Blue   : Cell_Channel;
   begin
      for Y in First_Y .. Last_Y loop
         if Y >= 1 and then Y <= Mission1_Background.Height_Cells then
            for X in First_X .. Last_X loop
               if X >= 1 and then X <= Mission1_Background.Width_Cells then
                  Mission1_Background.Colour_At
                    (X,
                     Y,
                     Red,
                     Green,
                     Blue);

                  Renderer.Set_Draw_Colour
                    ((To_SDL (Red),
                      To_SDL (Green),
                      To_SDL (Blue),
                      255));

                  Draw_X :=
                    Float ((X - 1) * Mission1_Background.Cell_Size);
                  Draw_Y :=
                    Float ((Y - 1) * Mission1_Background.Cell_Size);

                  Draw_Box
                    (Renderer,
                     Draw_X,
                     Draw_Y,
                     Float (Mission1_Background.Cell_Size),
                     Float (Mission1_Background.Cell_Size),
                     Camera_X,
                     Camera_Y);
               end if;
            end loop;
         end if;
      end loop;
   end Draw_Mission_Background;

   procedure Draw_Player
     (Renderer   : in out SDL.Video.Renderers.Renderer;
      Player_T   : ECS.Components.Transform.Transform;
      Player_R   : ECS.Components.Renderable.Renderable;
      Camera_X   : Float;
      Camera_Y   : Float;
      Gravity_On : Boolean) is
   begin
      Sprites.Draw_Ship_01
        (Renderer,
         Player_T.X,
         Player_T.Y,
         Camera_X,
         Camera_Y);

      if not Gravity_On then
         Renderer.Set_Draw_Colour
           ((To_Channel (Player_R.Red),
             To_Channel (Player_R.Green),
             To_Channel (Player_R.Blue),
             To_Channel (Player_R.Alpha)));
         Draw_Centered_Box
           (Renderer,
            Player_T.X,
            Player_T.Y,
            5.0,
            5.0,
            Camera_X,
            Camera_Y);
      end if;
   end Draw_Player;

   procedure Draw_Editor_Cursor
     (Renderer       : in out SDL.Video.Renderers.Renderer;
      Brush          : Level.Brush_Mode;
      Cursor_X       : Float;
      Cursor_Y       : Float;
      Current_Tile   : Level.Tile_Kind;
      Current_Kind   : Level.Object_Kind;
      Current_Motion : Level.Motion_Kind;
      Camera_X       : Float;
      Camera_Y       : Float) is
      Cursor_Size : constant Float := 32.0;
   begin
      if Brush = Level.Tile_Brush then
         Set_Tile_Colour (Renderer, Current_Tile);
         Draw_Box
           (Renderer,
            Float
              (Integer
                 (Float'Floor
                    (Cursor_X / Float (Level.Tile_Size)))
               * Level.Tile_Size),
            Float
              (Integer
                 (Float'Floor
                    (Cursor_Y / Float (Level.Tile_Size)))
               * Level.Tile_Size),
            Cursor_Size,
            Cursor_Size,
            Camera_X,
            Camera_Y);
      else
         Set_Object_Colour (Renderer, Current_Kind);
         Draw_Centered_Box
           (Renderer,
            Cursor_X,
            Cursor_Y,
            Cursor_Size,
            Cursor_Size,
            Camera_X,
            Camera_Y);
      end if;

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      case Current_Motion is
         when Level.Static =>
            Draw_Centered_Box
              (Renderer, Cursor_X, Cursor_Y, 8.0, 8.0, Camera_X, Camera_Y);

         when Level.Patrol_X =>
            Draw_Centered_Box
              (Renderer, Cursor_X, Cursor_Y, 48.0, 4.0, Camera_X, Camera_Y);

         when Level.Patrol_Y =>
            Draw_Centered_Box
              (Renderer, Cursor_X, Cursor_Y, 4.0, 48.0, Camera_X, Camera_Y);
      end case;
   end Draw_Editor_Cursor;



   procedure Draw_HUD
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Status   : Gameplay.Player_Status) is
      Fuel   : constant Integer := Integer (Status.Fuel);
      Shield : constant Integer := Integer (Status.Shield);
   begin
      Renderer.Set_Draw_Colour ((0, 0, 0, 255));
      Draw_Screen_Box (Renderer, 220.0, 8.0, 350.0, 64.0);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text (Renderer, "FUEL" & Integer'Image (Fuel), 230.0, 16.0, 2.0);
      Draw_Text
        (Renderer,
         "SHIELD" & Integer'Image (Shield),
         230.0,
         34.0,
         2.0);
      Draw_Text
        (Renderer,
         "MINERS" & Integer'Image (Status.Miners_Rescued)
         & "/" & Integer'Image (Status.Required_Miners),
         380.0,
         16.0,
         2.0);
      Draw_Text
        (Renderer,
         "WEIGHT" & Integer'Image (Status.Cargo_Weight),
         380.0,
         34.0,
         2.0);

      if Status.Objectives_Complete then
         Draw_Text (Renderer, "RETURN BASE", 230.0, 52.0, 2.0);
      end if;

      if Status.Mission_Complete then
         Draw_Text (Renderer, "MISSION COMPLETE", 370.0, 52.0, 2.0);
      end if;
   end Draw_HUD;

   procedure Draw_Boss
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Status   : Gameplay.Player_Status;
      Camera_X : Float;
      Camera_Y : Float) is
   begin
      if not Status.Boss_Active then
         return;
      end if;

      Renderer.Set_Draw_Colour ((150, 0, 180, 255));
      Draw_Centered_Box
        (Renderer,
         Status.Boss_X,
         Status.Boss_Y,
         52.0,
         52.0,
         Camera_X,
         Camera_Y);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text
        (Renderer,
         "BOSS HP" & Integer'Image (Status.Boss_HP),
         Status.Boss_X - Camera_X - 40.0,
         Status.Boss_Y - Camera_Y - 45.0,
         2.0);
   end Draw_Boss;

   procedure Draw_Editor_View_Panel
     (Renderer : in out SDL.Video.Renderers.Renderer;
      View     : Gameplay.Editor_View;
      Status   : Gameplay.Player_Status) is
      X : constant Float := 230.0;
      Y : constant Float := 505.0;
   begin
      Renderer.Set_Draw_Colour ((0, 0, 0, 255));
      Draw_Screen_Box (Renderer, X, Y, 560.0, 86.0);

      Renderer.Set_Draw_Colour ((255, 255, 255, 255));
      Draw_Text
        (Renderer,
         "VIEW " & Gameplay.View_Name (View),
         X + 10.0,
         Y + 10.0,
         2.0);

      case View is
         when Gameplay.Terrain_View =>
            Draw_Text
              (Renderer,
               "TILES WALL WATER LAND START",
               X + 10.0,
               Y + 32.0,
               2.0);

         when Gameplay.Objects_View =>
            Draw_Text
              (Renderer,
               "OBJECTS MINER FUEL SHIELD WEIGHT GATE BASE",
               X + 10.0,
               Y + 32.0,
               2.0);

         when Gameplay.Triggers_View =>
            Draw_Text
              (Renderer,
               "TRIGGERS BOSS ZONE ALL MINERS OPEN GATE",
               X + 10.0,
               Y + 32.0,
               2.0);

         when Gameplay.Objectives_View =>
            Draw_Text
              (Renderer,
               "RESCUE MINERS RETURN TO BASE NEXT LEVEL",
               X + 10.0,
               Y + 32.0,
               2.0);

         when Gameplay.Boss_View =>
            Draw_Text
              (Renderer,
               "BOSS PATH PHASES HP ATTACKS MUSIC",
               X + 10.0,
               Y + 32.0,
               2.0);
            Draw_Text
              (Renderer,
               "PHASE" & Integer'Image (Status.Boss_Phase),
               X + 10.0,
               Y + 54.0,
               2.0);

         when Gameplay.Audio_View =>
            Draw_Text
              (Renderer,
               "MUSIC SHIELDS WEAPONS PICKUPS EXPLOSIONS",
               X + 10.0,
               Y + 32.0,
               2.0);

         when Gameplay.Settings_View =>
            Draw_Text
              (Renderer,
               "NAME TITLE NEXT LEVEL BRIEFING TEMPLATE",
               X + 10.0,
               Y + 32.0,
               2.0);

         when Gameplay.Beat_Em_Up_View =>
            Draw_Text
              (Renderer,
               "FUTURE LANES WAVES ARENAS CAMERA LOCKS",
               X + 10.0,
               Y + 32.0,
               2.0);
      end case;

      Draw_Text (Renderer, "V NEXT VIEW", X + 390.0, Y + 54.0, 2.0);
   end Draw_Editor_View_Panel;

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
      View           : Gameplay.Editor_View) is
   begin
      Renderer.Set_Draw_Colour ((15, 15, 20, 255));
      Renderer.Fill
        (Rectangle =>
           (0,
            0,
            SDL.Natural_Dimension (Screen_Width),
            SDL.Natural_Dimension (Screen_Height)));

      Draw_Mission_Background
        (Renderer,
         Camera_X,
         Camera_Y,
         Screen_Width,
         Screen_Height);

      if Mode = Level.Editor_Mode then
         Draw_Tiles (Renderer, Tiles, Camera_X, Camera_Y);
      end if;

      Draw_Objects (Renderer, Objects, Camera_X, Camera_Y);
      Draw_Boss (Renderer, Status, Camera_X, Camera_Y);
      Draw_Player
        (Renderer,
         Player_T,
         Player_R,
         Camera_X,
         Camera_Y,
         Gravity_On);

      if Mode = Level.Play_Mode then
         Draw_HUD (Renderer, Status);
      end if;

      if Is_Playtest then
         Renderer.Set_Draw_Colour ((0, 0, 0, 255));
         Draw_Screen_Box (Renderer, 10.0, 10.0, 260.0, 54.0);
         Renderer.Set_Draw_Colour ((255, 255, 255, 255));
         Draw_Text
           (Renderer,
            "PLAYTEST " & US.To_String (Info.Stage_Name),
            20.0,
            20.0,
            2.0);
         Draw_Text (Renderer, "E EDITOR  Q EDITOR", 20.0, 42.0, 2.0);
      end if;

      if Mode = Level.Editor_Mode then
         Renderer.Set_Draw_Colour ((0, 0, 0, 255));
         Draw_Screen_Box (Renderer, 0.0, 0.0, 220.0, 600.0);
         Renderer.Set_Draw_Colour ((255, 255, 255, 255));
         Draw_Text
           (Renderer,
            US.To_String (Info.Stage_Name),
            12.0,
            380.0,
            2.0);
         Draw_Text
           (Renderer,
            US.To_String (Info.Title),
            12.0,
            400.0,
            2.0);

         Draw_Editor_Cursor
           (Renderer,
            Brush,
            Cursor_X,
            Cursor_Y,
            Current_Tile,
            Current_Kind,
            Current_Motion,
            Camera_X,
            Camera_Y);

         Draw_Editor_Palette
           (Renderer,
            Brush,
            Current_Tile,
            Current_Kind,
            Current_Motion);

         Draw_Editor_Legend
           (Renderer,
            Screen_Width,
            Brush,
            Current_Tile,
            Current_Kind,
            Current_Motion);

         Draw_Editor_View_Panel
           (Renderer,
            View,
            Status);
      end if;
   end Draw_Frame;

end Render;

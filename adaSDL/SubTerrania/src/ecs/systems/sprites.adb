with SDL;
with SDL.Video.Palettes;

package body Sprites is

   Ship_Width  : constant Positive := 19;
   Ship_Height : constant Positive := 19;

   subtype Sprite_Row is String (1 .. Ship_Width);
   type Sprite_Data is array (1 .. Ship_Height) of Sprite_Row;

   Ship_01 : constant Sprite_Data :=
     ("..9A...........9A..",
      ".2531.........2531.",
      ".6532...131...6532.",
      "..62...13631...62..",
      "..52.161486131.52..",
      "..421411555114142..",
      "..423171555171342..",
      ".14217518441571421.",
      ".22117B16661B71211.",
      "1252117133317115211",
      "3242161122211314213",
      "4242243112114324214",
      "5321383313183332135",
      "4252183312153315214",
      "62421831...18314216",
      "224213.......414212",
      "12421.........14211",
      ".242...........421.",
      "..32...........31..");

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

   function C
     (Value : Natural)
      return SDL.Video.Palettes.Colour_Component is
   begin
      return SDL.Video.Palettes.Colour_Component (Value);
   end C;

   procedure Set_Sprite_Colour
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Code     : Character) is
   begin
      case Code is
         when '1' =>
            Renderer.Set_Draw_Colour ((C (34), C (34), C (68), C (255)));

         when '2' =>
            Renderer.Set_Draw_Colour ((C (68), C (68), C (102), C (255)));

         when '3' =>
            Renderer.Set_Draw_Colour
              ((C (102), C (102), C (136), C (255)));

         when '4' =>
            Renderer.Set_Draw_Colour
              ((C (170), C (170), C (204), C (255)));

         when '5' =>
            Renderer.Set_Draw_Colour
              ((C (238), C (238), C (238), C (255)));

         when '6' =>
            Renderer.Set_Draw_Colour
              ((C (136), C (136), C (170), C (255)));

         when '7' =>
            Renderer.Set_Draw_Colour ((C (0), C (68), C (170), C (255)));

         when '8' =>
            Renderer.Set_Draw_Colour
              ((C (204), C (204), C (238), C (255)));

         when '9' =>
            Renderer.Set_Draw_Colour ((C (238), C (204), C (0), C (255)));

         when 'A' =>
            Renderer.Set_Draw_Colour ((C (238), C (102), C (0), C (255)));

         when 'B' =>
            Renderer.Set_Draw_Colour ((C (68), C (170), C (238), C (255)));

         when others =>
            null;
      end case;
   end Set_Sprite_Colour;

   procedure Draw_Ship_01
     (Renderer : in out SDL.Video.Renderers.Renderer;
      Center_X : Float;
      Center_Y : Float;
      Camera_X : Float;
      Camera_Y : Float) is
      Left : constant Float := Center_X - Float (Ship_Width) / 2.0;
      Top  : constant Float := Center_Y - Float (Ship_Height) / 2.0;
      Code : Character;
   begin
      for Row in Ship_01'Range loop
         for Col in Ship_01 (Row)'Range loop
            Code := Ship_01 (Row) (Col);

            if Code /= '.' then
               Set_Sprite_Colour (Renderer, Code);
               Renderer.Fill
                 (Rectangle =>
                    (To_Dim (Left + Float (Col - 1) - Camera_X),
                     To_Dim (Top + Float (Row - 1) - Camera_Y),
                     SDL.Natural_Dimension (1),
                     SDL.Natural_Dimension (1)));
            end if;
         end loop;
      end loop;
   end Draw_Ship_01;

end Sprites;

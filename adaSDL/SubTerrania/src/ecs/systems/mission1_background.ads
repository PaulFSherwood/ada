package Mission1_Background is

   Cell_Size     : constant Positive := 8;
   Width_Pixels  : constant Positive := 1280;
   Height_Pixels : constant Positive := 1128;
   Width_Cells   : constant Positive := 160;
   Height_Cells  : constant Positive := 141;

   type Colour_Channel is range 0 .. 255;

   procedure Colour_At
     (Cell_X : Positive;
      Cell_Y : Positive;
      Red    : out Colour_Channel;
      Green  : out Colour_Channel;
      Blue   : out Colour_Channel);

end Mission1_Background;

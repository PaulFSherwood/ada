package ECS.Components.Renderable is

   type Colour_Channel is range 0 .. 255;

   type Renderable is record
      Width  : Float := 28.0;
      Height : Float := 16.0;
      Red    : Colour_Channel := 255;
      Green  : Colour_Channel := 0;
      Blue   : Colour_Channel := 200;
      Alpha  : Colour_Channel := 255;
   end record;

end ECS.Components.Renderable;

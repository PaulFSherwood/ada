with ECS.Components.Gravity;
with ECS.Components.Transform;
with ECS.Components.Velocity;
with Level;

package Movement is

   procedure Apply_Player_Input
     (V          : in out ECS.Components.Velocity.Velocity;
      Has_Gravity : Boolean;
      Thrust     : Boolean;
      Brake      : Boolean;
      Left       : Boolean;
      Right      : Boolean;
      DT         : Float);

   procedure Configure_Gravity
     (G     : in out ECS.Components.Gravity.Gravity;
      Tiles : Level.Tile_Map;
      T     : ECS.Components.Transform.Transform);

   procedure Apply_Gravity
     (V              : in out ECS.Components.Velocity.Velocity;
      G              : ECS.Components.Gravity.Gravity;
      Max_Fall_Speed : Float;
      DT             : Float);

   procedure Move
     (T  : in out ECS.Components.Transform.Transform;
      V  : ECS.Components.Velocity.Velocity;
      DT : Float);

   procedure Move_Dynamic_Objects
     (Objects : in out Level.Object_Array;
      DT      : Float);

end Movement;

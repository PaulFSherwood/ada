with Ada.Text_IO; use Ada.Text_IO;

package body Collision is

   function Overlaps
     (Center_X1 : Float;
      Center_Y1 : Float;
      W1        : Float;
      H1        : Float;
      Center_X2 : Float;
      Center_Y2 : Float;
      W2        : Float;
      H2        : Float)
      return Boolean is
      Left1   : constant Float := Center_X1 - W1 / 2.0;
      Right1  : constant Float := Center_X1 + W1 / 2.0;
      Top1    : constant Float := Center_Y1 - H1 / 2.0;
      Bottom1 : constant Float := Center_Y1 + H1 / 2.0;
      Left2   : constant Float := Center_X2 - W2 / 2.0;
      Right2  : constant Float := Center_X2 + W2 / 2.0;
      Top2    : constant Float := Center_Y2 - H2 / 2.0;
      Bottom2 : constant Float := Center_Y2 + H2 / 2.0;
   begin
      return Left1 < Right2
        and then Right1 > Left2
        and then Top1 < Bottom2
        and then Bottom1 > Top2;
   end Overlaps;

   procedure Reset_Player
     (T       : in out ECS.Components.Transform.Transform;
      V       : in out ECS.Components.Velocity.Velocity;
      Reset_X : Float;
      Reset_Y : Float) is
   begin
      T.X := Reset_X;
      T.Y := Reset_Y;
      V.X := 0.0;
      V.Y := 0.0;
   end Reset_Player;

   procedure Check_Tile_Collision
     (Tiles      : Level.Tile_Map;
      T          : in out ECS.Components.Transform.Transform;
      V          : in out ECS.Components.Velocity.Velocity;
      C          : ECS.Components.Collider.Collider;
      Reset_X    : Float;
      Reset_Y    : Float;
      Gravity_On : in out Boolean;
      Result     : in out Collision_Result) is
      Safe_Landing_Speed : constant Float := 60.0;
      Bottom_Y           : constant Float := T.Y + C.Height / 2.0;
   begin
      if Level.Is_Solid_AABB (Tiles, T.X, T.Y, C.Width, C.Height) then
         Reset_Player (T, V, Reset_X, Reset_Y);
         Gravity_On := True;
         Result.Crashed := True;
         Put_Line ("Crashed into wall");
         return;
      end if;

      if V.Y >= 0.0 and then Level.Is_Landing_At (Tiles, T.X, Bottom_Y) then
         if abs V.Y <= Safe_Landing_Speed then
            T.Y := Level.Tile_Top_At (Bottom_Y) - C.Height / 2.0;
            V.X := 0.0;
            V.Y := 0.0;
            Gravity_On := False;
            Result.Landed := True;
         else
            Reset_Player (T, V, Reset_X, Reset_Y);
            Gravity_On := True;
            Result.Crashed := True;
            Put_Line ("Crashed: landing too fast");
         end if;
      end if;
   end Check_Tile_Collision;

   procedure Check_Object_Collision
     (Objects    : in out Level.Object_Array;
      T          : in out ECS.Components.Transform.Transform;
      V          : in out ECS.Components.Velocity.Velocity;
      C          : ECS.Components.Collider.Collider;
      Reset_X    : Float;
      Reset_Y    : Float;
      Gravity_On : in out Boolean;
      Result     : in out Collision_Result) is
   begin
      for I in Level.Object_Index loop
         if Objects (I).Used
           and then Overlaps
             (T.X,
              T.Y,
              C.Width,
              C.Height,
              Objects (I).X,
              Objects (I).Y,
              Objects (I).W,
              Objects (I).H)
         then
            case Objects (I).Kind is
               when Level.Miner =>
                  Objects (I).Used := False;
                  Result.Miner_Count := Result.Miner_Count + 1;
                  Put_Line ("Miner rescued");

               when Level.Powerup =>
                  Objects (I).Used := False;
                  Result.Power_Count := Result.Power_Count + 1;
                  Put_Line ("Powerup collected");

               when Level.Enemy =>
                  Reset_Player (T, V, Reset_X, Reset_Y);
                  Gravity_On := True;
                  Result.Crashed := True;
                  Put_Line ("Hit enemy");

               when Level.Goal =>
                  Result.Goal_Reached := True;
                  Put_Line ("Goal reached");

               when Level.Platform =>
                  if V.Y >= 0.0 and then T.Y < Objects (I).Y then
                     T.Y := Objects (I).Y
                       - Objects (I).H / 2.0
                       - C.Height / 2.0;
                     V.Y := 0.0;
                     Gravity_On := False;
                     Result.Landed := True;
                  end if;
            end case;
         end if;
      end loop;
   end Check_Object_Collision;

   procedure Check_Player
     (Tiles       : Level.Tile_Map;
      Objects     : in out Level.Object_Array;
      T           : in out ECS.Components.Transform.Transform;
      V           : in out ECS.Components.Velocity.Velocity;
      C           : ECS.Components.Collider.Collider;
      Reset_X     : Float;
      Reset_Y     : Float;
      Gravity_On  : in out Boolean;
      Result      : out Collision_Result) is
   begin
      Result := (others => <>);

      Check_Tile_Collision
        (Tiles,
         T,
         V,
         C,
         Reset_X,
         Reset_Y,
         Gravity_On,
         Result);

      if not Result.Crashed then
         Check_Object_Collision
           (Objects,
            T,
            V,
            C,
            Reset_X,
            Reset_Y,
            Gravity_On,
            Result);
      end if;
   end Check_Player;

end Collision;

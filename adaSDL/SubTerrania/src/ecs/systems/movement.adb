package body Movement is

   procedure Apply_Player_Input
     (V          : in out ECS.Components.Velocity.Velocity;
      Has_Gravity : Boolean;
      Thrust     : Boolean;
      Brake      : Boolean;
      Left       : Boolean;
      Right      : Boolean;
      DT         : Float;
      Thrust_Scale : Float := 1.0) is
      Thrust_Accel : constant Float := 260.0;
      Strafe_Accel : constant Float := 180.0;
      Drag         : constant Float := 0.96;
   begin
      if Left then
         V.X := V.X - Strafe_Accel * Thrust_Scale * DT;
      end if;

      if Right then
         V.X := V.X + Strafe_Accel * Thrust_Scale * DT;
      end if;

      if Thrust then
         V.Y := V.Y - Thrust_Accel * Thrust_Scale * DT;
      elsif not Has_Gravity then
         null;
      end if;

      if Brake then
         V.X := V.X * Drag;
         V.Y := V.Y * Drag;
      end if;
   end Apply_Player_Input;

   procedure Configure_Gravity
     (G     : in out ECS.Components.Gravity.Gravity;
      Tiles : Level.Tile_Map;
      T     : ECS.Components.Transform.Transform) is
      Tile : constant Level.Tile_Kind := Level.Tile_At_World (Tiles, T.X, T.Y);
   begin
      case Tile is
         when Level.Water_Tile =>
            G.Strength := -40.0;

         when others =>
            G.Strength := 120.0;
      end case;
   end Configure_Gravity;

   procedure Apply_Gravity
     (V              : in out ECS.Components.Velocity.Velocity;
      G              : ECS.Components.Gravity.Gravity;
      Max_Fall_Speed : Float;
      DT             : Float) is
   begin
      if G.Active then
         V.Y := V.Y + G.Strength * DT;

         if V.Y > Max_Fall_Speed then
            V.Y := Max_Fall_Speed;
         elsif V.Y < -Max_Fall_Speed then
            V.Y := -Max_Fall_Speed;
         end if;
      end if;
   end Apply_Gravity;

   procedure Move
     (T  : in out ECS.Components.Transform.Transform;
      V  : ECS.Components.Velocity.Velocity;
      DT : Float) is
   begin
      T.X := T.X + V.X * DT;
      T.Y := T.Y + V.Y * DT;
   end Move;

   procedure Move_Dynamic_Objects
     (Objects : in out Level.Object_Array;
      DT      : Float) is
   begin
      Level.Move_Dynamic_Objects (Objects, DT);
   end Move_Dynamic_Objects;

end Movement;

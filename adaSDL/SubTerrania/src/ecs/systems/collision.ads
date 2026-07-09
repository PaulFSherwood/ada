with ECS.Components.Collider;
with ECS.Components.Transform;
with ECS.Components.Velocity;
with Level;

package Collision is

   type Collision_Result is record
      Crashed      : Boolean := False;
      Landed       : Boolean := False;
      Miner_Count  : Natural := 0;
      Power_Count  : Natural := 0;
      Goal_Reached : Boolean := False;
   end record;

   procedure Check_Player
     (Tiles       : Level.Tile_Map;
      Objects     : in out Level.Object_Array;
      T           : in out ECS.Components.Transform.Transform;
      V           : in out ECS.Components.Velocity.Velocity;
      C           : ECS.Components.Collider.Collider;
      Reset_X     : Float;
      Reset_Y     : Float;
      Gravity_On  : in out Boolean;
      Result      : out Collision_Result);

end Collision;

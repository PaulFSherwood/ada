with Collision;
with Level;

package Gameplay is

   type Editor_View is
     (Terrain_View,
      Objects_View,
      Triggers_View,
      Objectives_View,
      Boss_View,
      Audio_View,
      Settings_View,
      Beat_Em_Up_View);

   type Game_Template is
     (Subterrania_Template,
      Beat_Em_Up_Template);

   type Player_Status is record
      Fuel                : Float := 100.0;
      Shield              : Float := 100.0;
      Cargo_Weight        : Natural := 0;

      Required_Miners     : Natural := 0;
      Miners_Rescued      : Natural := 0;
      Powerups_Collected  : Natural := 0;

      Objectives_Complete : Boolean := False;
      Mission_Complete    : Boolean := False;
      Gate_A_Open         : Boolean := False;

      Boss_Active         : Boolean := False;
      Boss_Defeated       : Boolean := False;
      Boss_HP             : Integer := 300;
      Boss_Phase          : Positive := 1;
      Boss_X              : Float := 960.0;
      Boss_Y              : Float := 360.0;
      Boss_Target         : Positive := 1;
      Boss_Timer          : Float := 0.0;

      Template            : Game_Template := Subterrania_Template;
   end record;

   function Next_View
     (View : Editor_View)
      return Editor_View;

   function View_Name
     (View : Editor_View)
      return String;

   procedure Reset_For_Level
     (Status  : out Player_Status;
      Objects : Level.Object_Array);

   function Thrust_Multiplier
     (Status : Player_Status)
      return Float;

   procedure Drain_Fuel
     (Status : in out Player_Status;
      DT     : Float);

   procedure Apply_Collision_Result
     (Status : in out Player_Status;
      Result : Collision.Collision_Result);

   procedure Update_Scripted_Systems
     (Status   : in out Player_Status;
      Objects  : in out Level.Object_Array;
      Player_X : Float;
      Player_Y : Float;
      DT       : Float);

   function Needs_Reset
     (Status : Player_Status)
      return Boolean;

   procedure Reset_After_Crash
     (Status : in out Player_Status);

end Gameplay;

with Ada.Text_IO; use Ada.Text_IO;

package body Gameplay is

   use type Level.Object_Kind;

   type Waypoint is record
      X : Float;
      Y : Float;
   end record;

   type Waypoint_Array is array (Positive range <>) of Waypoint;

   Boss_Path : constant Waypoint_Array :=
     ((X => 880.0,  Y => 300.0),
      (X => 1_080.0, Y => 320.0),
      (X => 1_080.0, Y => 480.0),
      (X => 880.0,  Y => 480.0));

   function Next_View
     (View : Editor_View)
      return Editor_View is
   begin
      case View is
         when Terrain_View    => return Objects_View;
         when Objects_View    => return Triggers_View;
         when Triggers_View   => return Objectives_View;
         when Objectives_View => return Boss_View;
         when Boss_View       => return Player_View;
         when Player_View     => return Enemies_View;
         when Enemies_View    => return Weapons_View;
         when Weapons_View    => return Powerups_View;
         when Powerups_View   => return Audio_View;
         when Audio_View      => return Settings_View;
         when Settings_View   => return Build_Test_View;
         when Build_Test_View => return Beat_Em_Up_View;
         when Beat_Em_Up_View => return Terrain_View;
      end case;
   end Next_View;

   function View_Name
     (View : Editor_View)
      return String is
   begin
      case View is
         when Terrain_View    => return "LEVEL";
         when Objects_View    => return "OBJECTS";
         when Triggers_View   => return "TRIGGERS";
         when Objectives_View => return "GOALS";
         when Boss_View       => return "BOSS";
         when Player_View     => return "PLAYER";
         when Enemies_View    => return "ENEMIES";
         when Weapons_View    => return "WEAPONS";
         when Powerups_View   => return "POWERUPS";
         when Audio_View      => return "AUDIO";
         when Settings_View   => return "SETTINGS";
         when Build_Test_View => return "BUILD TEST";
         when Beat_Em_Up_View => return "BEAT EM UP";
      end case;
   end View_Name;

   function Count_Miners
     (Objects : Level.Object_Array)
      return Natural is
      Count : Natural := 0;
   begin
      for I in Level.Object_Index loop
         if Objects (I).Used and then Objects (I).Kind = Level.Miner then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Count_Miners;

   procedure Reset_For_Level
     (Status  : out Player_Status;
      Objects : Level.Object_Array) is
   begin
      Status := (others => <>);
      Status.Required_Miners := Count_Miners (Objects);
      Status.Boss_X := 960.0;
      Status.Boss_Y := 360.0;
      Put_Line ("Mission systems reset");
   end Reset_For_Level;

   function Thrust_Multiplier
     (Status : Player_Status)
      return Float is
      Penalty : constant Float := Float (Status.Cargo_Weight) * 0.12;
   begin
      if Penalty > 0.70 then
         return 0.30;
      else
         return 1.0 - Penalty;
      end if;
   end Thrust_Multiplier;

   procedure Drain_Fuel
     (Status : in out Player_Status;
      DT     : Float) is
      Drain : constant Float :=
        (0.42 + Float (Status.Cargo_Weight) * 0.08) * DT;
   begin
      if Status.Mission_Complete then
         return;
      end if;

      if Status.Fuel > Drain then
         Status.Fuel := Status.Fuel - Drain;
      else
         Status.Fuel := 0.0;
      end if;
   end Drain_Fuel;

   procedure Apply_Collision_Result
     (Status : in out Player_Status;
      Result : Collision.Collision_Result) is
   begin
      if Result.Crashed then
         if Status.Shield > 15.0 then
            Status.Shield := Status.Shield - 15.0;
         else
            Status.Shield := 0.0;
         end if;
      end if;

      Status.Miners_Rescued :=
        Status.Miners_Rescued + Result.Miner_Count;
      Status.Powerups_Collected :=
        Status.Powerups_Collected + Result.Power_Count;
      Status.Cargo_Weight :=
        Status.Cargo_Weight + Result.Weight_Count;

      if Result.Fuel_Count > 0 then
         Status.Fuel := Float'Min
           (100.0,
            Status.Fuel + Float (Result.Fuel_Count) * 35.0);
      end if;

      if Result.Shield_Count > 0 then
         Status.Shield := Float'Min
           (100.0,
            Status.Shield + Float (Result.Shield_Count) * 25.0);
      end if;

      if Result.Goal_Reached then
         Status.Objectives_Complete := True;
         Status.Gate_A_Open := True;
      end if;

      if Status.Required_Miners = 0
        or else Status.Miners_Rescued >= Status.Required_Miners
      then
         Status.Objectives_Complete := True;
         Status.Gate_A_Open := True;
      end if;

      if Result.At_Base and then Status.Objectives_Complete then
         Status.Mission_Complete := True;
         Put_Line ("Mission complete - load next level later");
      elsif Result.At_Base then
         Put_Line ("Return after objectives are complete");
      end if;
   end Apply_Collision_Result;

   procedure Open_Object_Gates
     (Objects : in out Level.Object_Array) is
   begin
      for I in Level.Object_Index loop
         if Objects (I).Used and then Objects (I).Kind = Level.Gate then
            Objects (I).Used := False;
         end if;
      end loop;
   end Open_Object_Gates;

   function In_Boss_Zone
     (Player_X : Float;
      Player_Y : Float)
      return Boolean is
   begin
      return Player_X >= 840.0
        and then Player_X <= 1_170.0
        and then Player_Y >= 240.0
        and then Player_Y <= 560.0;
   end In_Boss_Zone;

   procedure Update_Boss_Phase
     (Status : in out Player_Status) is
   begin
      if Status.Boss_HP <= 80 then
         Status.Boss_Phase := 3;
      elsif Status.Boss_HP <= 200 then
         Status.Boss_Phase := 2;
      else
         Status.Boss_Phase := 1;
      end if;
   end Update_Boss_Phase;

   procedure Update_Boss_Path
     (Status : in out Player_Status;
      DT     : Float) is
      Target : constant Waypoint := Boss_Path (Status.Boss_Target);
      DX     : constant Float := Target.X - Status.Boss_X;
      DY     : constant Float := Target.Y - Status.Boss_Y;
      Dist   : constant Float := abs DX + abs DY;
      Speed  : Float := 70.0;
   begin
      case Status.Boss_Phase is
         when 1 => Speed := 60.0;
         when 2 => Speed := 95.0;
         when others => Speed := 130.0;
      end case;

      if Dist < 6.0 then
         if Status.Boss_Target = Boss_Path'Last then
            Status.Boss_Target := Boss_Path'First;
         else
            Status.Boss_Target := Status.Boss_Target + 1;
         end if;
      else
         Status.Boss_X := Status.Boss_X + DX / Dist * Speed * DT;
         Status.Boss_Y := Status.Boss_Y + DY / Dist * Speed * DT;
      end if;
   end Update_Boss_Path;

   procedure Update_Scripted_Systems
     (Status   : in out Player_Status;
      Objects  : in out Level.Object_Array;
      Player_X : Float;
      Player_Y : Float;
      DT       : Float) is
   begin
      if Status.Gate_A_Open then
         Open_Object_Gates (Objects);
      end if;

      if In_Boss_Zone (Player_X, Player_Y)
        and then not Status.Boss_Defeated
        and then not Status.Boss_Active
      then
         Status.Boss_Active := True;
         Status.Boss_HP := 300;
         Status.Boss_Phase := 1;
         Status.Boss_Target := Boss_Path'First;
         Put_Line ("Boss encounter started");
      end if;

      if Status.Boss_Active then
         Status.Boss_Timer := Status.Boss_Timer + DT;
         Update_Boss_Phase (Status);
         Update_Boss_Path (Status, DT);
      end if;
   end Update_Scripted_Systems;

   function Needs_Reset
     (Status : Player_Status)
      return Boolean is
   begin
      return Status.Fuel <= 0.0 or else Status.Shield <= 0.0;
   end Needs_Reset;

   procedure Reset_After_Crash
     (Status : in out Player_Status) is
   begin
      Status.Fuel := 100.0;
      Status.Shield := 100.0;
   end Reset_After_Crash;

end Gameplay;

with Ada.Strings.Unbounded;

package Level is

   Tile_Size           : constant Positive := 32;
   World_Width_Pixels  : constant Positive := 1_280;
   World_Height_Pixels : constant Positive := 1_128;

   Map_Width  : constant Positive :=
     (World_Width_Pixels + Tile_Size - 1) / Tile_Size;
   Map_Height : constant Positive :=
     (World_Height_Pixels + Tile_Size - 1) / Tile_Size;

   type Level_Info is record
      Stage_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("stage01");
      Title      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("Mission 1");
      Next_Level : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("stage02.map");
      Background_Image : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("assets/images/maps/sub-terrania-mission-1.png");
      Music : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("assets/audio/music/mission01.ogg");
      Boss_Music : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          ("assets/audio/music/boss01.ogg");
   end record;

   function Default_Level_Info return Level_Info;

   type Game_Mode is
     (Play_Mode,
      Editor_Mode);

   type Brush_Mode is
     (Tile_Brush,
      Object_Brush);

   type Tile_Kind is
     (Space_Tile,
      Wall_Tile,
      Landing_Tile,
      Water_Tile,
      Start_Tile);

   type Object_Kind is
     (Miner,
      Enemy,
      Powerup,
      Fuel,
      Shield,
      Weight,
      Goal,
      Base,
      Gate,
      Platform,
      Boss_Spawn);

   type Motion_Kind is
     (Static,
      Patrol_X,
      Patrol_Y);

   Max_Path_Nodes : constant Positive := 12;
   Max_Path_Steps : constant Positive := 24;

   subtype Motion_Path_Node_Count is Natural range 0 .. Max_Path_Nodes;
   subtype Motion_Path_Node_Index is Positive range 1 .. Max_Path_Nodes;

   type Path_Playback_Mode is
     (No_Path,
      Once_Path,
      Loop_Path,
      Pingpong_Path);

   type Path_Easing_Kind is
     (Snap_Ease,
      Linear_Ease,
      Smooth_Ease,
      Arc_Ease);

   type Motion_Path_Node is record
      X    : Float := 0.0;
      Y    : Float := 0.0;
      Time : Float := 0.0;
   end record;

   type Motion_Path_Node_Array is array
     (Motion_Path_Node_Index) of Motion_Path_Node;

   type Path_Route_Step is record
      Node  : Motion_Path_Node_Index := 1;
      Pause : Float := 0.0;
   end record;

   subtype Path_Route_Step_Count is Natural range 0 .. Max_Path_Steps;
   subtype Path_Route_Step_Index is Positive range 1 .. Max_Path_Steps;

   type Path_Route_Step_Array is array
     (Path_Route_Step_Index) of Path_Route_Step;

   subtype Tile_X is Positive range 1 .. Map_Width;
   subtype Tile_Y is Positive range 1 .. Map_Height;
   type Tile_Map is array (Tile_Y, Tile_X) of Tile_Kind;

   type Object_Record is record
      Used    : Boolean := False;
      Kind    : Object_Kind := Miner;
      Motion  : Motion_Kind := Static;

      X       : Float := 0.0;
      Y       : Float := 0.0;
      W       : Float := 24.0;
      H       : Float := 24.0;

      Min_Pos : Float := 0.0;
      Max_Pos : Float := 0.0;
      Speed   : Float := 0.0;
      Dir     : Float := 1.0;

      Path_Count  : Motion_Path_Node_Count := 0;
      Path_Nodes  : Motion_Path_Node_Array :=
        (others => (X => 0.0, Y => 0.0, Time => 0.0));
      Path_Mode   : Path_Playback_Mode := No_Path;
      Path_Easing : Path_Easing_Kind := Linear_Ease;
      Path_Travel_Time : Float := 8.0;
      Path_Route_Count : Path_Route_Step_Count := 0;
      Path_Route : Path_Route_Step_Array :=
        (others =>
           (Node => Motion_Path_Node_Index'First, Pause => 0.0));

      Path_From_Node : Natural range 0 .. Max_Path_Nodes := 0;
      Path_To_Node   : Natural range 0 .. Max_Path_Nodes := 0;
      Path_Direction : Integer range -1 .. 1 := 1;
      Path_Elapsed   : Float := 0.0;
      Path_Complete  : Boolean := False;
      Path_From_Step : Natural range 0 .. Max_Path_Steps := 0;
      Path_To_Step   : Natural range 0 .. Max_Path_Steps := 0;
      Path_Pause_Remaining : Float := 0.0;

      Delta_X : Float := 0.0;
      Delta_Y : Float := 0.0;
   end record;

   Max_Objects : constant Positive := 128;
   type Object_Index is range 1 .. Max_Objects;
   type Object_Array is array (Object_Index) of Object_Record;

   function World_Width return Float;
   function World_Height return Float;

   function Next_Tile
     (T : Tile_Kind)
      return Tile_Kind;

   function Next_Kind
     (K : Object_Kind)
      return Object_Kind;

   function Next_Motion
     (M : Motion_Kind)
      return Motion_Kind;

   procedure Clear_Objects
     (Objects : in out Object_Array);

   procedure Build_Test_Level
     (Tiles   : out Tile_Map;
      Objects : out Object_Array;
      Info    : out Level_Info);

   function Tile_At_World
     (Tiles : Tile_Map;
      X     : Float;
      Y     : Float)
      return Tile_Kind;

   function Is_Solid_At
     (Tiles : Tile_Map;
      X     : Float;
      Y     : Float)
      return Boolean;

   function Is_Solid_AABB
     (Tiles  : Tile_Map;
      Center_X : Float;
      Center_Y : Float;
      Width    : Float;
      Height   : Float)
      return Boolean;

   function Is_Landing_At
     (Tiles : Tile_Map;
      X     : Float;
      Y     : Float)
      return Boolean;

   function Find_Player_Start
     (Tiles : Tile_Map;
      X     : out Float;
      Y     : out Float)
      return Boolean;

   function Tile_Top_At
     (Y : Float)
      return Float;

   procedure Set_Tile_At_World
     (Tiles : in out Tile_Map;
      X     : Float;
      Y     : Float;
      Tile  : Tile_Kind);

   procedure Add_Object
     (Objects : in out Object_Array;
      K       : Object_Kind;
      X       : Float;
      Y       : Float;
      Motion  : Motion_Kind := Static);

   procedure Delete_Object_At
     (Objects : in out Object_Array;
      X       : Float;
      Y       : Float;
      Deleted : out Boolean);

   procedure Clamp_Point
     (X      : in out Float;
      Y      : in out Float;
      Width  : Float;
      Height : Float);

   procedure Move_Dynamic_Objects
     (Objects : in out Object_Array;
      DT      : Float);

   procedure Save_Level
     (Tiles   : Tile_Map;
      Objects : Object_Array;
      Info    : Level_Info;
      Path    : String);

   procedure Load_Level
     (Tiles   : out Tile_Map;
      Objects : out Object_Array;
      Info    : out Level_Info;
      Path    : String;
      Loaded  : out Boolean);

end Level;

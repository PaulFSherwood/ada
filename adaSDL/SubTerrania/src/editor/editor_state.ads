with Ada.Strings.Unbounded;
with Level;

package Editor_State is

   package US renames Ada.Strings.Unbounded;

   Max_Path_Nodes : constant Positive := 12;

   type Tool_Kind is
     (Select_Tool,
      Tile_Brush_Tool,
      Object_Brush_Tool,
      Eraser_Tool,
      Pan_Tool,
      Trigger_Tool,
      Path_Tool);

   type Selection_Kind is
     (Nothing_Selected,
      Tile_Selected,
      Object_Selected);

   type Path_Mode_Kind is
     (No_Path,
      Once_Path,
      Loop_Path,
      Pingpong_Path);

   type Path_Easing_Kind is
     (Snap_Ease,
      Linear_Ease,
      Smooth_Ease,
      Arc_Ease);

   type Layer_Kind is
     (Background_Layer,
      Terrain_Layer,
      Water_Layer,
      Pickups_Layer,
      Destructibles_Layer,
      Platforms_Layer,
      Miners_Layer,
      Enemies_Layer,
      Triggers_Layer,
      Paths_Layer);

   type Path_Node_Record is record
      X    : Float := 0.0;
      Y    : Float := 0.0;
      Time : Float := 0.0;
   end record;

   subtype Path_Node_Count is Natural range 0 .. Max_Path_Nodes;
   subtype Path_Node_Index is Positive range 1 .. Max_Path_Nodes;

   type Selection_Info is record
      Kind         : Selection_Kind := Nothing_Selected;
      Tile         : Level.Tile_Kind := Level.Space_Tile;
      Object_Index : Natural := 0;
      World_X      : Float := 0.0;
      World_Y      : Float := 0.0;
   end record;

   procedure Initialize;
   procedure New_Level;

   procedure Load
     (Path   : String;
      Loaded : out Boolean);

   procedure Save;
   procedure Save_As (Path : String);

   function Tiles return access Level.Tile_Map;
   function Objects return access Level.Object_Array;
   function Info return Level.Level_Info;
   procedure Set_Info (Value : Level.Level_Info);

   function Level_Path return String;
   function Is_Dirty return Boolean;
   procedure Mark_Clean;
   procedure Mark_Dirty;

   procedure Undo (Changed : out Boolean);
   procedure Redo (Changed : out Boolean);

   function Current_Tool return Tool_Kind;
   procedure Set_Tool (Tool : Tool_Kind);

   function Current_Tile return Level.Tile_Kind;
   procedure Set_Tile_Brush (Tile : Level.Tile_Kind);

   function Current_Object return Level.Object_Kind;
   procedure Set_Object_Brush (Kind : Level.Object_Kind);

   function Grid_Visible return Boolean;
   procedure Set_Grid_Visible (Visible : Boolean);

   function Layer_Visible (Layer : Layer_Kind) return Boolean;
   procedure Set_Layer_Visible
     (Layer   : Layer_Kind;
      Visible : Boolean);

   procedure Place_At
     (World_X : Float;
      World_Y : Float);

   procedure Erase_At
     (World_X : Float;
      World_Y : Float);

   procedure Select_At
     (World_X : Float;
      World_Y : Float);

   function Selection return Selection_Info;
   procedure Clear_Selection;

   procedure Update_Object_Position
     (Index   : Level.Object_Index;
      World_X : Float;
      World_Y : Float);

   procedure Update_Selected_Geometry
     (World_X : Float;
      World_Y : Float;
      Width   : Float;
      Height  : Float;
      Changed : out Boolean);

   procedure Rename_Selected_Object
     (Name    : String;
      Changed : out Boolean);

   procedure Delete_Selected (Changed : out Boolean);

   procedure Begin_Path_Edit (Started : out Boolean);
   procedure Finish_Path_Edit (Changed : out Boolean);
   procedure Cancel_Path_Edit (Changed : out Boolean);
   function Path_Edit_Active return Boolean;

   procedure Ensure_Simple_Path_For_Selected (Created : out Boolean);

   function Selected_Path_Node return Natural;
   procedure Select_Path_Node (Node : Natural);

   procedure Move_Selected_Path_Node
     (World_X : Float;
      World_Y : Float;
      Changed : out Boolean);

   procedure Update_Selected_Path_Node
     (World_X : Float;
      World_Y : Float;
      Time    : Float;
      Changed : out Boolean);

   procedure Insert_Path_Node
     (After_Node : Path_Node_Index;
      World_X    : Float;
      World_Y    : Float;
      Inserted   : out Boolean);

   procedure Delete_Selected_Path_Node (Deleted : out Boolean);

   procedure Add_Path_Node_To_Selected
     (World_X : Float;
      World_Y : Float;
      Added   : out Boolean);

   procedure Set_Selected_Two_Node_Path
     (X1      : Float;
      Y1      : Float;
      T1      : Float;
      X2      : Float;
      Y2      : Float;
      T2      : Float;
      Changed : out Boolean);

   procedure Clear_Selected_Path (Changed : out Boolean);

   function Object_Path_Count
     (Index : Level.Object_Index) return Path_Node_Count;

   function Object_Path_Node
     (Index : Level.Object_Index;
      Node  : Path_Node_Index) return Path_Node_Record;

   function Object_Path_Mode
     (Index : Level.Object_Index) return Path_Mode_Kind;

   function Object_Path_Easing
     (Index : Level.Object_Index) return Path_Easing_Kind;

   function Tool_Name return String;
   function Brush_Name return String;
   function Tile_Name (Tile : Level.Tile_Kind) return String;
   function Object_Name (Kind : Level.Object_Kind) return String;

   function Object_Display_Name
     (Index : Level.Object_Index) return String;

end Editor_State;

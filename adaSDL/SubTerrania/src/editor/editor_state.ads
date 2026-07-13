with Ada.Strings.Unbounded;
with Level;

package Editor_State is

   package US renames Ada.Strings.Unbounded;

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

   function Tool_Name return String;
   function Brush_Name return String;
   function Tile_Name (Tile : Level.Tile_Kind) return String;
   function Object_Name (Kind : Level.Object_Kind) return String;

end Editor_State;

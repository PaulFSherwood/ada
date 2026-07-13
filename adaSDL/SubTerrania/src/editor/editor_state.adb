with App_Paths;

package body Editor_State is

   Current_Tiles   : aliased Level.Tile_Map;
   Current_Objects : aliased Level.Object_Array;
   Current_Info    : Level.Level_Info := Level.Default_Level_Info;

   Current_Path : US.Unbounded_String :=
     US.To_Unbounded_String (App_Paths.Default_Level_Path);

   Dirty : Boolean := False;

   Active_Tool   : Tool_Kind := Select_Tool;
   Active_Tile   : Level.Tile_Kind := Level.Wall_Tile;
   Active_Object : Level.Object_Kind := Level.Miner;
   Show_Grid     : Boolean := True;
   Selected      : Selection_Info;

   Max_History : constant Positive := 32;

   type Snapshot is record
      Tiles   : Level.Tile_Map;
      Objects : Level.Object_Array;
      Info    : Level.Level_Info;
   end record;

   type History_Array is array (Positive range <>) of Snapshot;
   History          : History_Array (1 .. Max_History);
   History_Count    : Natural := 0;
   History_Position : Natural := 0;

   procedure Store_Current_Snapshot is
   begin
      if History_Position < History_Count then
         History_Count := History_Position;
      end if;

      if History_Count = Max_History then
         for I in 1 .. Max_History - 1 loop
            History (I) := History (I + 1);
         end loop;
         History_Count := Max_History - 1;
         History_Position := History_Count;
      end if;

      History_Count := History_Count + 1;
      History_Position := History_Count;
      History (History_Position) :=
        (Tiles   => Current_Tiles,
         Objects => Current_Objects,
         Info    => Current_Info);
   end Store_Current_Snapshot;

   procedure Restore (Position : Positive) is
   begin
      Current_Tiles := History (Position).Tiles;
      Current_Objects := History (Position).Objects;
      Current_Info := History (Position).Info;
      Selected := (others => <>);
      Dirty := True;
   end Restore;

   procedure Initialize is
      Loaded : Boolean;
   begin
      Load (App_Paths.Default_Level_Path, Loaded);

      if not Loaded then
         New_Level;
      end if;
   end Initialize;

   procedure New_Level is
   begin
      Level.Build_Test_Level
        (Tiles   => Current_Tiles,
         Objects => Current_Objects,
         Info    => Current_Info);

      Current_Path := US.To_Unbounded_String
        (App_Paths.Default_Level_Path);
      Active_Tool := Select_Tool;
      Selected := (others => <>);
      Dirty := False;
      History_Count := 0;
      History_Position := 0;
      Store_Current_Snapshot;
   end New_Level;

   procedure Load
     (Path   : String;
      Loaded : out Boolean) is
   begin
      Level.Load_Level
        (Tiles   => Current_Tiles,
         Objects => Current_Objects,
         Info    => Current_Info,
         Path    => Path,
         Loaded  => Loaded);

      if Loaded then
         Current_Path := US.To_Unbounded_String (Path);
         Selected := (others => <>);
         Dirty := False;
         History_Count := 0;
         History_Position := 0;
         Store_Current_Snapshot;
      end if;
   end Load;

   procedure Save is
   begin
      Save_As (US.To_String (Current_Path));
   end Save;

   procedure Save_As (Path : String) is
   begin
      Level.Save_Level
        (Tiles   => Current_Tiles,
         Objects => Current_Objects,
         Info    => Current_Info,
         Path    => Path);

      Current_Path := US.To_Unbounded_String (Path);
      Dirty := False;
   end Save_As;

   function Tiles return access Level.Tile_Map is
   begin
      return Current_Tiles'Access;
   end Tiles;

   function Objects return access Level.Object_Array is
   begin
      return Current_Objects'Access;
   end Objects;

   function Info return Level.Level_Info is
   begin
      return Current_Info;
   end Info;

   procedure Set_Info (Value : Level.Level_Info) is
   begin
      Current_Info := Value;
      Dirty := True;
      Store_Current_Snapshot;
   end Set_Info;

   function Level_Path return String is
   begin
      return US.To_String (Current_Path);
   end Level_Path;

   function Is_Dirty return Boolean is
   begin
      return Dirty;
   end Is_Dirty;

   procedure Mark_Clean is
   begin
      Dirty := False;
   end Mark_Clean;

   procedure Mark_Dirty is
   begin
      Dirty := True;
   end Mark_Dirty;

   procedure Undo (Changed : out Boolean) is
   begin
      Changed := False;
      if History_Position > 1 then
         History_Position := History_Position - 1;
         Restore (History_Position);
         Changed := True;
      end if;
   end Undo;

   procedure Redo (Changed : out Boolean) is
   begin
      Changed := False;
      if History_Position < History_Count then
         History_Position := History_Position + 1;
         Restore (History_Position);
         Changed := True;
      end if;
   end Redo;

   function Current_Tool return Tool_Kind is
   begin
      return Active_Tool;
   end Current_Tool;

   procedure Set_Tool (Tool : Tool_Kind) is
   begin
      Active_Tool := Tool;

      if Tool /= Select_Tool then
         Selected := (others => <>);
      end if;
   end Set_Tool;

   function Current_Tile return Level.Tile_Kind is
   begin
      return Active_Tile;
   end Current_Tile;

   procedure Set_Tile_Brush (Tile : Level.Tile_Kind) is
   begin
      Active_Tile := Tile;
      Active_Tool := Tile_Brush_Tool;
      Selected := (others => <>);
   end Set_Tile_Brush;

   function Current_Object return Level.Object_Kind is
   begin
      return Active_Object;
   end Current_Object;

   procedure Set_Object_Brush (Kind : Level.Object_Kind) is
   begin
      Active_Object := Kind;
      Active_Tool := Object_Brush_Tool;
      Selected := (others => <>);
   end Set_Object_Brush;

   function Grid_Visible return Boolean is
   begin
      return Show_Grid;
   end Grid_Visible;

   procedure Set_Grid_Visible (Visible : Boolean) is
   begin
      Show_Grid := Visible;
   end Set_Grid_Visible;

   procedure Place_At
     (World_X : Float;
      World_Y : Float) is
   begin
      case Active_Tool is
         when Tile_Brush_Tool =>
            Level.Set_Tile_At_World
              (Tiles => Current_Tiles,
               X     => World_X,
               Y     => World_Y,
               Tile  => Active_Tile);
            Dirty := True;
            Store_Current_Snapshot;

         when Object_Brush_Tool =>
            Level.Add_Object
              (Objects => Current_Objects,
               K       => Active_Object,
               X       => World_X,
               Y       => World_Y);
            Dirty := True;
            Store_Current_Snapshot;

         when Eraser_Tool =>
            Erase_At (World_X, World_Y);

         when others =>
            null;
      end case;
   end Place_At;

   procedure Erase_At
     (World_X : Float;
      World_Y : Float) is
      Deleted : Boolean;
   begin
      Level.Delete_Object_At
        (Objects => Current_Objects,
         X       => World_X,
         Y       => World_Y,
         Deleted => Deleted);

      if not Deleted then
         Level.Set_Tile_At_World
           (Tiles => Current_Tiles,
            X     => World_X,
            Y     => World_Y,
            Tile  => Level.Space_Tile);
      end if;

      Dirty := True;
      Selected := (others => <>);
      Store_Current_Snapshot;
   end Erase_At;

   procedure Select_At
     (World_X : Float;
      World_Y : Float) is
      Obj : constant access Level.Object_Array := Objects;
   begin
      Selected :=
        (Kind         => Tile_Selected,
         Tile         => Level.Tile_At_World
           (Current_Tiles, World_X, World_Y),
         Object_Index => 0,
         World_X      => World_X,
         World_Y      => World_Y);

      for I in reverse Level.Object_Index loop
         if Obj (I).Used
           and then World_X >= Obj (I).X
           and then World_X <= Obj (I).X + Obj (I).W
           and then World_Y >= Obj (I).Y
           and then World_Y <= Obj (I).Y + Obj (I).H
         then
            Selected :=
              (Kind         => Object_Selected,
               Tile         => Level.Space_Tile,
               Object_Index => Natural (I),
               World_X      => World_X,
               World_Y      => World_Y);
            return;
         end if;
      end loop;
   end Select_At;

   function Selection return Selection_Info is
   begin
      return Selected;
   end Selection;

   procedure Clear_Selection is
   begin
      Selected := (others => <>);
   end Clear_Selection;

   procedure Update_Object_Position
     (Index   : Level.Object_Index;
      World_X : Float;
      World_Y : Float) is
   begin
      if Current_Objects (Index).Used then
         Current_Objects (Index).X := World_X;
         Current_Objects (Index).Y := World_Y;
         Selected.World_X := World_X;
         Selected.World_Y := World_Y;
         Dirty := True;
         Store_Current_Snapshot;
      end if;
   end Update_Object_Position;

   procedure Update_Selected_Geometry
     (World_X : Float;
      World_Y : Float;
      Width   : Float;
      Height  : Float;
      Changed : out Boolean) is
      Index : Level.Object_Index;
   begin
      Changed := False;
      if Selected.Kind /= Object_Selected
        or else Selected.Object_Index = 0
      then
         return;
      end if;

      Index := Level.Object_Index (Selected.Object_Index);
      Current_Objects (Index).X := World_X;
      Current_Objects (Index).Y := World_Y;
      Current_Objects (Index).W := Width;
      Current_Objects (Index).H := Height;
      Selected.World_X := World_X;
      Selected.World_Y := World_Y;
      Dirty := True;
      Store_Current_Snapshot;
      Changed := True;
   end Update_Selected_Geometry;

   function Tool_Name return String is
   begin
      case Active_Tool is
         when Select_Tool       => return "Select";
         when Tile_Brush_Tool   => return "Tile Brush";
         when Object_Brush_Tool => return "Object Brush";
         when Eraser_Tool       => return "Eraser";
         when Pan_Tool          => return "Pan";
         when Trigger_Tool      => return "Trigger";
         when Path_Tool         => return "Path";
      end case;
   end Tool_Name;

   function Brush_Name return String is
   begin
      case Active_Tool is
         when Tile_Brush_Tool =>
            return Tile_Name (Active_Tile);
         when Object_Brush_Tool =>
            return Object_Name (Active_Object);
         when others =>
            return Tool_Name;
      end case;
   end Brush_Name;

   function Tile_Name (Tile : Level.Tile_Kind) return String is
   begin
      case Tile is
         when Level.Space_Tile   => return "Space";
         when Level.Wall_Tile    => return "Wall";
         when Level.Landing_Tile => return "Landing Pad";
         when Level.Water_Tile   => return "Water";
         when Level.Start_Tile   => return "Player Start";
      end case;
   end Tile_Name;

   function Object_Name (Kind : Level.Object_Kind) return String is
   begin
      case Kind is
         when Level.Miner      => return "Miner";
         when Level.Enemy      => return "Enemy";
         when Level.Powerup    => return "Powerup";
         when Level.Fuel       => return "Fuel";
         when Level.Shield     => return "Shield";
         when Level.Weight     => return "Heavy Cargo";
         when Level.Goal       => return "Goal";
         when Level.Base       => return "Base";
         when Level.Gate       => return "Gate";
         when Level.Platform   => return "Platform";
         when Level.Boss_Spawn => return "Boss Spawn";
      end case;
   end Object_Name;

end Editor_State;

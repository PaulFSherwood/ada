with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;

with App_Paths;

package body Editor_State is

   use type Level.Motion_Kind;

   use type Level.Object_Kind;

   package SF renames Ada.Strings.Fixed;
   package TIO renames Ada.Text_IO;

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

   type Layer_Visibility_Array is array (Layer_Kind) of Boolean;
   Layer_Visibility : Layer_Visibility_Array := (others => True);

   Selected      : Selection_Info;

   type Object_Name_Array is array
     (Level.Object_Index) of US.Unbounded_String;

   type Path_Node_Array is array
     (Path_Node_Index) of Path_Node_Record;

   type Object_Path_Node_Array is array
     (Level.Object_Index) of Path_Node_Array;

   type Object_Path_Count_Array is array
     (Level.Object_Index) of Path_Node_Count;

   type Object_Path_Mode_Array is array
     (Level.Object_Index) of Path_Mode_Kind;

   type Object_Path_Easing_Array is array
     (Level.Object_Index) of Path_Easing_Kind;

   Object_Names : Object_Name_Array :=
     (others => US.Null_Unbounded_String);

   Object_Path_Counts : Object_Path_Count_Array := (others => 0);

   Object_Path_Nodes : Object_Path_Node_Array :=
     (others => (others => (X => 0.0, Y => 0.0, Time => 0.0)));

   Object_Path_Modes : Object_Path_Mode_Array := (others => No_Path);

   Object_Path_Easings : Object_Path_Easing_Array :=
     (others => Linear_Ease);

   Path_Edit_Is_Active : Boolean := False;
   Path_Edit_Object     : Natural := 0;
   Path_Edit_Node       : Natural := 0;
   Path_Edit_Changed    : Boolean := False;
   Path_Edit_Old_Dirty  : Boolean := False;
   Path_Edit_Old_Count  : Path_Node_Count := 0;
   Path_Edit_Old_Nodes  : Path_Node_Array :=
     (others => (X => 0.0, Y => 0.0, Time => 0.0));
   Path_Edit_Old_Mode   : Path_Mode_Kind := No_Path;
   Path_Edit_Old_Easing : Path_Easing_Kind := Linear_Ease;

   Max_History : constant Positive := 32;

   type Snapshot is record
      Tiles        : Level.Tile_Map;
      Objects      : Level.Object_Array;
      Info         : Level.Level_Info;
      Names        : Object_Name_Array;
      Path_Counts  : Object_Path_Count_Array;
      Path_Nodes   : Object_Path_Node_Array;
      Path_Modes   : Object_Path_Mode_Array;
      Path_Easings : Object_Path_Easing_Array;
   end record;

   type History_Array is array (Positive range <>) of Snapshot;
   History          : History_Array (1 .. Max_History);
   History_Count    : Natural := 0;
   History_Position : Natural := 0;

   function Trim (Text : String) return String is
   begin
      return SF.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Starts_With
     (Text   : String;
      Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1)
          = Prefix;
   end Starts_With;

   function Tail_After
     (Text   : String;
      Prefix : String) return String is
   begin
      if Text'Length <= Prefix'Length then
         return "";
      else
         return Text (Text'First + Prefix'Length .. Text'Last);
      end if;
   end Tail_After;

   function Token
     (Text  : String;
      Index : Positive) return String is
      Current : Positive := 1;
      First   : Natural := 0;
      Last    : Natural := 0;
      I       : Integer := Text'First;
   begin
      while I <= Text'Last loop
         while I <= Text'Last and then Text (I) = ' ' loop
            I := I + 1;
         end loop;

         exit when I > Text'Last;
         First := I;

         while I <= Text'Last and then Text (I) /= ' ' loop
            I := I + 1;
         end loop;

         Last := I - 1;

         if Current = Index then
            return Text (First .. Last);
         end if;

         Current := Current + 1;
      end loop;

      return "";
   end Token;

   function To_Natural
     (Text    : String;
      Default : Natural) return Natural is
   begin
      return Natural'Value (Trim (Text));
   exception
      when others =>
         return Default;
   end To_Natural;

   function To_Float
     (Text    : String;
      Default : Float) return Float is
   begin
      return Float'Value (Trim (Text));
   exception
      when others =>
         return Default;
   end To_Float;

   function Metadata_Path (Path : String) return String is
   begin
      return Path & ".editor";
   end Metadata_Path;

   function Object_Kind_Code (Kind : Level.Object_Kind) return String;

   function Path_Mode_Code (Mode : Path_Mode_Kind) return String is
   begin
      case Mode is
         when No_Path       => return "NONE";
         when Once_Path     => return "ONCE";
         when Loop_Path     => return "LOOP";
         when Pingpong_Path => return "PINGPONG";
      end case;
   end Path_Mode_Code;

   function Path_Easing_Code (Easing : Path_Easing_Kind) return String is
   begin
      case Easing is
         when Snap_Ease   => return "SNAP";
         when Linear_Ease => return "LINEAR";
         when Smooth_Ease => return "SMOOTH";
         when Arc_Ease    => return "ARC";
      end case;
   end Path_Easing_Code;

   function Parse_Path_Mode (Text : String) return Path_Mode_Kind is
      Upper : constant String := Ada.Characters.Handling.To_Upper (Trim (Text));
   begin
      if Upper = "ONCE" then
         return Once_Path;
      elsif Upper = "LOOP" then
         return Loop_Path;
      elsif Upper = "PINGPONG" then
         return Pingpong_Path;
      else
         return No_Path;
      end if;
   end Parse_Path_Mode;

   function Parse_Path_Easing (Text : String) return Path_Easing_Kind is
      Upper : constant String := Ada.Characters.Handling.To_Upper (Trim (Text));
   begin
      if Upper = "SNAP" then
         return Snap_Ease;
      elsif Upper = "SMOOTH" then
         return Smooth_Ease;
      elsif Upper = "ARC" then
         return Arc_Ease;
      else
         return Linear_Ease;
      end if;
   end Parse_Path_Easing;

   function Trim_Natural (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Trim_Natural;

   function Two_Digits (Value : Natural) return String is
   begin
      if Value < 10 then
         return "0" & Trim_Natural (Value);
      else
         return Trim_Natural (Value);
      end if;
   end Two_Digits;

   function Generated_Object_Name
     (Index : Level.Object_Index) return String is
      Count : Natural := 0;
   begin
      if not Current_Objects (Index).Used then
         return "Unused Object";
      end if;

      for I in Level.Object_Index'First .. Index loop
         if Current_Objects (I).Used
           and then Current_Objects (I).Kind = Current_Objects (Index).Kind
         then
            Count := Count + 1;
         end if;
      end loop;

      return Object_Name (Current_Objects (Index).Kind)
        & "_" & Two_Digits (Count);
   end Generated_Object_Name;

   procedure Ensure_Metadata_Defaults is
   begin
      for I in Level.Object_Index loop
         if Current_Objects (I).Used then
            if US.Length (Object_Names (I)) = 0 then
               Object_Names (I) :=
                 US.To_Unbounded_String (Generated_Object_Name (I));
            end if;

            if Object_Path_Counts (I) = 0
              and then Current_Objects (I).Motion /= Level.Static
            then
               Object_Path_Counts (I) := 2;
               Object_Path_Modes (I) := Pingpong_Path;
               Object_Path_Easings (I) := Linear_Ease;

               case Current_Objects (I).Motion is
                  when Level.Static =>
                     null;

                  when Level.Patrol_X =>
                     Object_Path_Nodes (I) (1) :=
                       (X    => Current_Objects (I).Min_Pos,
                        Y    => Current_Objects (I).Y
                          + Current_Objects (I).H / 2.0,
                        Time => 0.0);
                     Object_Path_Nodes (I) (2) :=
                       (X    => Current_Objects (I).Max_Pos,
                        Y    => Current_Objects (I).Y
                          + Current_Objects (I).H / 2.0,
                        Time => 1.0);

                  when Level.Patrol_Y =>
                     Object_Path_Nodes (I) (1) :=
                       (X    => Current_Objects (I).X
                          + Current_Objects (I).W / 2.0,
                        Y    => Current_Objects (I).Min_Pos,
                        Time => 0.0);
                     Object_Path_Nodes (I) (2) :=
                       (X    => Current_Objects (I).X
                          + Current_Objects (I).W / 2.0,
                        Y    => Current_Objects (I).Max_Pos,
                        Time => 1.0);
               end case;
            end if;
         else
            Object_Names (I) := US.Null_Unbounded_String;
            Object_Path_Counts (I) := 0;
            Object_Path_Modes (I) := No_Path;
            Object_Path_Easings (I) := Linear_Ease;
         end if;
      end loop;
   end Ensure_Metadata_Defaults;

   procedure Reset_Editor_Metadata is
   begin
      Object_Names := (others => US.Null_Unbounded_String);
      Object_Path_Counts := (others => 0);
      Object_Path_Nodes :=
        (others => (others => (X => 0.0, Y => 0.0, Time => 0.0)));
      Object_Path_Modes := (others => No_Path);
      Object_Path_Easings := (others => Linear_Ease);
      Path_Edit_Is_Active := False;
      Path_Edit_Object := 0;
      Path_Edit_Node := 0;
      Path_Edit_Changed := False;
   end Reset_Editor_Metadata;

   procedure Save_Editor_Metadata (Path : String) is
      File : TIO.File_Type;
      package Float_IO is new TIO.Float_IO (Float);

      procedure Put_Float (Value : Float) is
      begin
         TIO.Put (File, " ");
         Float_IO.Put (File, Value, Fore => 1, Aft => 2, Exp => 0);
      end Put_Float;
   begin
      Ensure_Metadata_Defaults;
      Ada.Directories.Create_Path
        (Ada.Directories.Containing_Directory (Metadata_Path (Path)));
      TIO.Create (File, TIO.Out_File, Metadata_Path (Path));
      TIO.Put_Line (File, "SUBTERRANIA_EDITOR_METADATA_V1");

      for I in Level.Object_Index loop
         if Current_Objects (I).Used then
            TIO.Put_Line (File, "OBJECT " & Trim_Natural (Natural (I)));
            TIO.Put_Line (File, "NAME " & US.To_String (Object_Names (I)));
            TIO.Put_Line
              (File, "TYPE " & Object_Kind_Code (Current_Objects (I).Kind));
            TIO.Put_Line
              (File, "PATH_MODE " & Path_Mode_Code (Object_Path_Modes (I)));
            TIO.Put_Line
              (File,
               "PATH_EASING " & Path_Easing_Code (Object_Path_Easings (I)));
            TIO.Put_Line
              (File,
               "PATH_COUNT " & Trim_Natural (Object_Path_Counts (I)));

            for N in 1 .. Object_Path_Counts (I) loop
               TIO.Put (File, "NODE " & Trim_Natural (N));
               Put_Float (Object_Path_Nodes (I) (Path_Node_Index (N)).X);
               Put_Float (Object_Path_Nodes (I) (Path_Node_Index (N)).Y);
               Put_Float (Object_Path_Nodes (I) (Path_Node_Index (N)).Time);
               TIO.New_Line (File);
            end loop;

            TIO.Put_Line (File, "END_OBJECT");
         end if;
      end loop;

      TIO.Close (File);
   exception
      when others =>
         if TIO.Is_Open (File) then
            TIO.Close (File);
         end if;
   end Save_Editor_Metadata;

   procedure Load_Editor_Metadata (Path : String) is
      File          : TIO.File_Type;
      Line          : String (1 .. 512);
      Last          : Natural;
      Current_Index : Natural := 0;
      Node_Number   : Natural;
   begin
      Reset_Editor_Metadata;

      if not Ada.Directories.Exists (Metadata_Path (Path)) then
         Ensure_Metadata_Defaults;
         return;
      end if;

      TIO.Open (File, TIO.In_File, Metadata_Path (Path));
      while not TIO.End_Of_File (File) loop
         TIO.Get_Line (File, Line, Last);
         declare
            Text : constant String := Trim (Line (1 .. Last));
         begin
            if Starts_With (Text, "OBJECT ") then
               Current_Index := To_Natural (Tail_After (Text, "OBJECT "), 0);
            elsif Current_Index in Natural (Level.Object_Index'First)
              .. Natural (Level.Object_Index'Last)
            then
               declare
                  I : constant Level.Object_Index :=
                    Level.Object_Index (Current_Index);
               begin
                  if Starts_With (Text, "NAME ") then
                     Object_Names (I) :=
                       US.To_Unbounded_String (Tail_After (Text, "NAME "));
                  elsif Starts_With (Text, "PATH_MODE ") then
                     Object_Path_Modes (I) :=
                       Parse_Path_Mode (Tail_After (Text, "PATH_MODE "));
                  elsif Starts_With (Text, "PATH_EASING ") then
                     Object_Path_Easings (I) :=
                       Parse_Path_Easing (Tail_After (Text, "PATH_EASING "));
                  elsif Starts_With (Text, "NODE ") then
                     Node_Number := To_Natural (Token (Text, 2), 0);

                     if Node_Number in Path_Node_Index'Range then
                        Object_Path_Nodes (I) (Path_Node_Index (Node_Number)) :=
                          (X    => To_Float (Token (Text, 3), 0.0),
                           Y    => To_Float (Token (Text, 4), 0.0),
                           Time => To_Float (Token (Text, 5), 0.0));

                        if Node_Number > Object_Path_Counts (I) then
                           Object_Path_Counts (I) := Path_Node_Count (Node_Number);
                        end if;
                     end if;
                  end if;
               end;
            end if;
         end;
      end loop;

      TIO.Close (File);
      Ensure_Metadata_Defaults;
   exception
      when others =>
         if TIO.Is_Open (File) then
            TIO.Close (File);
         end if;
         Ensure_Metadata_Defaults;
   end Load_Editor_Metadata;

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

      Ensure_Metadata_Defaults;
      History_Count := History_Count + 1;
      History_Position := History_Count;
      History (History_Position) :=
        (Tiles        => Current_Tiles,
         Objects      => Current_Objects,
         Info         => Current_Info,
         Names        => Object_Names,
         Path_Counts  => Object_Path_Counts,
         Path_Nodes   => Object_Path_Nodes,
         Path_Modes   => Object_Path_Modes,
         Path_Easings => Object_Path_Easings);
   end Store_Current_Snapshot;

   procedure Restore (Position : Positive) is
   begin
      Current_Tiles := History (Position).Tiles;
      Current_Objects := History (Position).Objects;
      Current_Info := History (Position).Info;
      Object_Names := History (Position).Names;
      Object_Path_Counts := History (Position).Path_Counts;
      Object_Path_Nodes := History (Position).Path_Nodes;
      Object_Path_Modes := History (Position).Path_Modes;
      Object_Path_Easings := History (Position).Path_Easings;
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
      Reset_Editor_Metadata;
      Ensure_Metadata_Defaults;
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
         Load_Editor_Metadata (Path);
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

      Save_Editor_Metadata (Path);
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

      case Tool is
         when Tile_Brush_Tool | Object_Brush_Tool | Eraser_Tool =>
            Selected := (others => <>);
         when Select_Tool | Pan_Tool | Trigger_Tool | Path_Tool =>
            null;
      end case;
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

   function Layer_Visible (Layer : Layer_Kind) return Boolean is
   begin
      return Layer_Visibility (Layer);
   end Layer_Visible;

   procedure Set_Layer_Visible
     (Layer   : Layer_Kind;
      Visible : Boolean) is
   begin
      Layer_Visibility (Layer) := Visible;
   end Set_Layer_Visible;

   procedure Name_New_Object
     (Kind : Level.Object_Kind;
      X    : Float;
      Y    : Float) is
   begin
      for I in reverse Level.Object_Index loop
         if Current_Objects (I).Used
           and then Current_Objects (I).Kind = Kind
           and then abs (Current_Objects (I).X - X) < 1.0
           and then abs (Current_Objects (I).Y - Y) < 1.0
         then
            Object_Names (I) :=
              US.To_Unbounded_String (Generated_Object_Name (I));
            return;
         end if;
      end loop;
   end Name_New_Object;

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
            Name_New_Object (Active_Object, World_X, World_Y);
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
      Deleted_Index : Natural := 0;
   begin
      for I in Level.Object_Index loop
         if Current_Objects (I).Used
           and then World_X >= Current_Objects (I).X
           and then World_X <= Current_Objects (I).X + Current_Objects (I).W
           and then World_Y >= Current_Objects (I).Y
           and then World_Y <= Current_Objects (I).Y + Current_Objects (I).H
         then
            Deleted_Index := Natural (I);
            exit;
         end if;
      end loop;

      Level.Delete_Object_At
        (Objects => Current_Objects,
         X       => World_X,
         Y       => World_Y,
         Deleted => Deleted);

      if Deleted and then Deleted_Index /= 0 then
         declare
            I : constant Level.Object_Index :=
              Level.Object_Index (Deleted_Index);
         begin
            Object_Names (I) := US.Null_Unbounded_String;
            Object_Path_Counts (I) := 0;
            Object_Path_Modes (I) := No_Path;
            Object_Path_Easings (I) := Linear_Ease;
         end;
      end if;

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

   procedure Rename_Selected_Object
     (Name    : String;
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
      Object_Names (Index) := US.To_Unbounded_String (Trim (Name));
      Dirty := True;
      Store_Current_Snapshot;
      Changed := True;
   end Rename_Selected_Object;

   procedure Delete_Selected (Changed : out Boolean) is
      Index : Level.Object_Index;
   begin
      Changed := False;
      if Selected.Kind = Object_Selected
        and then Selected.Object_Index /= 0
      then
         Index := Level.Object_Index (Selected.Object_Index);
         Current_Objects (Index).Used := False;
         Object_Names (Index) := US.Null_Unbounded_String;
         Object_Path_Counts (Index) := 0;
         Object_Path_Modes (Index) := No_Path;
         Object_Path_Easings (Index) := Linear_Ease;
         Selected := (others => <>);
         Dirty := True;
         Store_Current_Snapshot;
         Changed := True;
      elsif Selected.Kind = Tile_Selected then
         Level.Set_Tile_At_World
           (Tiles => Current_Tiles,
            X     => Selected.World_X,
            Y     => Selected.World_Y,
            Tile  => Level.Space_Tile);
         Selected := (others => <>);
         Dirty := True;
         Store_Current_Snapshot;
         Changed := True;
      end if;
   end Delete_Selected;

   function Selected_Object_Index return Natural is
   begin
      if Selected.Kind = Object_Selected
        and then Selected.Object_Index /= 0
      then
         return Selected.Object_Index;
      end if;

      return 0;
   end Selected_Object_Index;

   procedure Mark_Path_Edit_Changed is
   begin
      Path_Edit_Changed := True;
      Dirty := True;
   end Mark_Path_Edit_Changed;

   procedure Begin_Path_Edit (Started : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
   begin
      Started := False;
      if Selected_Index = 0 then
         return;
      end if;

      if Path_Edit_Is_Active
        and then Path_Edit_Object = Selected_Index
      then
         Started := True;
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      Path_Edit_Is_Active := True;
      Path_Edit_Object := Selected_Index;
      Path_Edit_Node := 0;
      Path_Edit_Changed := False;
      Path_Edit_Old_Dirty := Dirty;
      Path_Edit_Old_Count := Object_Path_Counts (Index);
      Path_Edit_Old_Nodes := Object_Path_Nodes (Index);
      Path_Edit_Old_Mode := Object_Path_Modes (Index);
      Path_Edit_Old_Easing := Object_Path_Easings (Index);
      Started := True;
   end Begin_Path_Edit;

   procedure Finish_Path_Edit (Changed : out Boolean) is
   begin
      Changed := Path_Edit_Is_Active and then Path_Edit_Changed;

      if Changed then
         Store_Current_Snapshot;
      end if;

      Path_Edit_Is_Active := False;
      Path_Edit_Object := 0;
      Path_Edit_Node := 0;
      Path_Edit_Changed := False;
   end Finish_Path_Edit;

   procedure Cancel_Path_Edit (Changed : out Boolean) is
      Index : Level.Object_Index;
   begin
      Changed := Path_Edit_Is_Active and then Path_Edit_Changed;

      if Path_Edit_Is_Active and then Path_Edit_Object /= 0 then
         Index := Level.Object_Index (Path_Edit_Object);
         Object_Path_Counts (Index) := Path_Edit_Old_Count;
         Object_Path_Nodes (Index) := Path_Edit_Old_Nodes;
         Object_Path_Modes (Index) := Path_Edit_Old_Mode;
         Object_Path_Easings (Index) := Path_Edit_Old_Easing;
         Dirty := Path_Edit_Old_Dirty;
      end if;

      Path_Edit_Is_Active := False;
      Path_Edit_Object := 0;
      Path_Edit_Node := 0;
      Path_Edit_Changed := False;
   end Cancel_Path_Edit;

   function Path_Edit_Active return Boolean is
   begin
      return Path_Edit_Is_Active;
   end Path_Edit_Active;

   procedure Ensure_Simple_Path_For_Selected (Created : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
      Object_Data    : Level.Object_Record;
      Start_X        : Float;
      Start_Y        : Float;
   begin
      Created := False;
      if Selected_Index = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      if Object_Path_Counts (Index) /= 0 then
         return;
      end if;

      Object_Data := Current_Objects (Index);
      Start_X := Object_Data.X + Object_Data.W / 2.0;
      Start_Y := Object_Data.Y + Object_Data.H / 2.0;

      Object_Path_Counts (Index) := 2;
      Object_Path_Modes (Index) := Pingpong_Path;
      Object_Path_Easings (Index) := Smooth_Ease;
      Object_Path_Nodes (Index) (1) :=
        (X => Start_X, Y => Start_Y, Time => 0.0);
      Object_Path_Nodes (Index) (2) :=
        (X => Start_X + 96.0, Y => Start_Y, Time => 1.0);
      Path_Edit_Node := 2;
      Mark_Path_Edit_Changed;
      Created := True;
   end Ensure_Simple_Path_For_Selected;

   function Selected_Path_Node return Natural is
   begin
      return Path_Edit_Node;
   end Selected_Path_Node;

   procedure Select_Path_Node (Node : Natural) is
      Selected_Index : constant Natural := Selected_Object_Index;
   begin
      if Selected_Index = 0 then
         Path_Edit_Node := 0;
         return;
      end if;

      if Node = 0
        or else Node > Natural
          (Object_Path_Counts (Level.Object_Index (Selected_Index)))
      then
         Path_Edit_Node := 0;
      else
         Path_Edit_Node := Node;
      end if;
   end Select_Path_Node;

   procedure Move_Selected_Path_Node
     (World_X : Float;
      World_Y : Float;
      Changed : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
   begin
      Changed := False;
      if Selected_Index = 0 or else Path_Edit_Node = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      if Path_Edit_Node > Natural (Object_Path_Counts (Index)) then
         return;
      end if;

      Object_Path_Nodes (Index) (Path_Node_Index (Path_Edit_Node)).X := World_X;
      Object_Path_Nodes (Index) (Path_Node_Index (Path_Edit_Node)).Y := World_Y;
      Mark_Path_Edit_Changed;
      Changed := True;
   end Move_Selected_Path_Node;

   procedure Update_Selected_Path_Node
     (World_X : Float;
      World_Y : Float;
      Time    : Float;
      Changed : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
   begin
      Changed := False;
      if Selected_Index = 0 or else Path_Edit_Node = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      if Path_Edit_Node > Natural (Object_Path_Counts (Index)) then
         return;
      end if;

      Object_Path_Nodes (Index) (Path_Node_Index (Path_Edit_Node)) :=
        (X => World_X, Y => World_Y, Time => Time);
      Mark_Path_Edit_Changed;
      Changed := True;
   end Update_Selected_Path_Node;

   procedure Insert_Path_Node
     (After_Node : Path_Node_Index;
      World_X    : Float;
      World_Y    : Float;
      Inserted   : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
      Count          : Path_Node_Count;
      Insert_At      : Natural;
      Time_A         : Float;
      Time_B         : Float;
   begin
      Inserted := False;
      if Selected_Index = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      Count := Object_Path_Counts (Index);
      if Count < 2
        or else Count = Max_Path_Nodes
        or else Natural (After_Node) >= Natural (Count)
      then
         return;
      end if;

      Insert_At := Natural (After_Node) + 1;
      for N in reverse Insert_At .. Natural (Count) loop
         Object_Path_Nodes (Index) (Path_Node_Index (N + 1)) :=
           Object_Path_Nodes (Index) (Path_Node_Index (N));
      end loop;

      Time_A := Object_Path_Nodes (Index) (After_Node).Time;
      Time_B := Object_Path_Nodes
        (Index) (Path_Node_Index (Insert_At)).Time;
      Object_Path_Nodes (Index) (Path_Node_Index (Insert_At)) :=
        (X => World_X,
         Y => World_Y,
         Time => (Time_A + Time_B) / 2.0);
      Object_Path_Counts (Index) := Count + 1;
      Path_Edit_Node := Insert_At;
      Mark_Path_Edit_Changed;
      Inserted := True;
   end Insert_Path_Node;

   procedure Delete_Selected_Path_Node (Deleted : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
      Count          : Path_Node_Count;
   begin
      Deleted := False;
      if Selected_Index = 0 or else Path_Edit_Node = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      Count := Object_Path_Counts (Index);
      if Count <= 2
        or else Path_Edit_Node = 1
        or else Path_Edit_Node = Natural (Count)
      then
         return;
      end if;

      for N in Path_Edit_Node .. Natural (Count) - 1 loop
         Object_Path_Nodes (Index) (Path_Node_Index (N)) :=
           Object_Path_Nodes (Index) (Path_Node_Index (N + 1));
      end loop;

      Object_Path_Nodes (Index) (Path_Node_Index (Natural (Count))) :=
        (X => 0.0, Y => 0.0, Time => 0.0);
      Object_Path_Counts (Index) := Count - 1;
      if Path_Edit_Node > Natural (Object_Path_Counts (Index)) then
         Path_Edit_Node := Natural (Object_Path_Counts (Index));
      end if;
      Mark_Path_Edit_Changed;
      Deleted := True;
   end Delete_Selected_Path_Node;

   procedure Add_Path_Node_To_Selected
     (World_X : Float;
      World_Y : Float;
      Added   : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
      Count          : Path_Node_Count;
   begin
      Added := False;
      if Selected_Index = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      Count := Object_Path_Counts (Index);
      if Count = Max_Path_Nodes then
         return;
      end if;

      Count := Count + 1;
      Object_Path_Counts (Index) := Count;
      Object_Path_Nodes (Index) (Path_Node_Index (Count)) :=
        (X => World_X, Y => World_Y, Time => Float (Count - 1));
      Object_Path_Modes (Index) := Pingpong_Path;
      Object_Path_Easings (Index) := Smooth_Ease;
      Path_Edit_Node := Natural (Count);
      Mark_Path_Edit_Changed;
      Added := True;
   end Add_Path_Node_To_Selected;

   procedure Set_Selected_Two_Node_Path
     (X1      : Float;
      Y1      : Float;
      T1      : Float;
      X2      : Float;
      Y2      : Float;
      T2      : Float;
      Changed : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
   begin
      Changed := False;
      if Selected_Index = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      Object_Path_Counts (Index) := 2;
      Object_Path_Modes (Index) := Pingpong_Path;
      Object_Path_Easings (Index) := Smooth_Ease;
      Object_Path_Nodes (Index) (1) := (X => X1, Y => Y1, Time => T1);
      Object_Path_Nodes (Index) (2) := (X => X2, Y => Y2, Time => T2);
      Path_Edit_Node := 2;
      Mark_Path_Edit_Changed;
      Changed := True;
   end Set_Selected_Two_Node_Path;

   procedure Clear_Selected_Path (Changed : out Boolean) is
      Selected_Index : constant Natural := Selected_Object_Index;
      Index          : Level.Object_Index;
   begin
      Changed := False;
      if Selected_Index = 0 then
         return;
      end if;

      Index := Level.Object_Index (Selected_Index);
      if Object_Path_Counts (Index) = 0 then
         return;
      end if;

      Object_Path_Counts (Index) := 0;
      Object_Path_Modes (Index) := No_Path;
      Object_Path_Easings (Index) := Linear_Ease;
      Object_Path_Nodes (Index) :=
        (others => (X => 0.0, Y => 0.0, Time => 0.0));
      Path_Edit_Node := 0;
      Mark_Path_Edit_Changed;
      Changed := True;
   end Clear_Selected_Path;

   function Object_Path_Count
     (Index : Level.Object_Index) return Path_Node_Count is
   begin
      return Object_Path_Counts (Index);
   end Object_Path_Count;

   function Object_Path_Node
     (Index : Level.Object_Index;
      Node  : Path_Node_Index) return Path_Node_Record is
   begin
      return Object_Path_Nodes (Index) (Node);
   end Object_Path_Node;

   function Object_Path_Mode
     (Index : Level.Object_Index) return Path_Mode_Kind is
   begin
      return Object_Path_Modes (Index);
   end Object_Path_Mode;

   function Object_Path_Easing
     (Index : Level.Object_Index) return Path_Easing_Kind is
   begin
      return Object_Path_Easings (Index);
   end Object_Path_Easing;

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
         when Level.Goal       => return "Objective Marker";
         when Level.Base       => return "Base";
         when Level.Gate       => return "Gate";
         when Level.Platform   => return "Platform";
         when Level.Boss_Spawn => return "Boss Spawn";
      end case;
   end Object_Name;

   function Object_Kind_Code (Kind : Level.Object_Kind) return String is
   begin
      case Kind is
         when Level.Miner      => return "MINER";
         when Level.Enemy      => return "ENEMY";
         when Level.Powerup    => return "POWERUP";
         when Level.Fuel       => return "FUEL";
         when Level.Shield     => return "SHIELD";
         when Level.Weight     => return "WEIGHT";
         when Level.Goal       => return "OBJECTIVE_MARKER";
         when Level.Base       => return "BASE";
         when Level.Gate       => return "GATE";
         when Level.Platform   => return "PLATFORM";
         when Level.Boss_Spawn => return "BOSS_SPAWN";
      end case;
   end Object_Kind_Code;

   function Object_Display_Name
     (Index : Level.Object_Index) return String is
   begin
      if not Current_Objects (Index).Used then
         return "Unused Object";
      end if;

      if US.Length (Object_Names (Index)) = 0 then
         return Generated_Object_Name (Index);
      end if;

      return US.To_String (Object_Names (Index));
   end Object_Display_Name;

end Editor_State;

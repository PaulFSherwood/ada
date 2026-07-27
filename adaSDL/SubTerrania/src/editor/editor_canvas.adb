with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Gdk.Pixbuf;
with Gdk.RGBA;
with Gdk.Types;
with Glib;
with Glib.Error;
with Glib.Object;
with Gtk.Builder;
with Gtk.GEntry;
with Gtk.Enums;
with Gtk.Frame;
with Gtk.Label;
with Gtk.Scrolled_Window;
with Gtk.Widget;
with Gtkada.Canvas_View;
with Gtkada.Canvas_View.Views;
with Gtkada.Style;
with Level;

with Editor_State;

package body Editor_Canvas is

   use Gdk.RGBA;
   use Glib;
   use Glib.Object;
   use Gtk.Builder;
   use Gtk.GEntry;
   use Gtk.Frame;
   use Gtk.Label;
   use Gtk.Scrolled_Window;
   use Gtk.Widget;
   use Gtkada.Canvas_View;
   use Gtkada.Canvas_View.Views;
   use Gtkada.Style;

   use type Glib.Error.GError;
   use type Gtkada.Canvas_View.Abstract_Item;
   use type Gtkada.Canvas_View.Canvas_Event_Type;
   use type Level.Tile_Kind;
   use type Level.Motion_Kind;
   use type Editor_State.Selection_Kind;

   function On_Item_Event_Zoom is new On_Item_Event_Zoom_Generic
     (Modifier => 0);

   UI_Builder : Gtkada.Builder.Gtkada_Builder;
   Canvas     : Canvas_View;
   Model      : List_Canvas_Model;
   Minimap    : Minimap_View;

   Background_Item : Abstract_Item;

   type Object_Item_Array is array
     (Level.Object_Index) of Abstract_Item;

   Object_Items : Object_Item_Array := (others => null);

   function UI_Label (Name : String) return Gtk_Label is
   begin
      return Gtk_Label
        (Get_Object (Gtk_Builder (UI_Builder), Name));
   end UI_Label;

   function UI_Entry (Name : String) return Gtk_Entry is
   begin
      return Gtk_Entry
        (Get_Object (Gtk_Builder (UI_Builder), Name));
   end UI_Entry;

   procedure Set_Status (Text : String) is
   begin
      UI_Label ("status_label").Set_Text (Text);
      UI_Label ("tool_status_label").Set_Text
        ("Tool: " & Editor_State.Tool_Name
         & "    Brush: " & Editor_State.Brush_Name);
   end Set_Status;

   function Tile_Style
     (Tile : Level.Tile_Kind) return Drawing_Style is
   begin
      case Tile is
         when Level.Space_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.0, 0.0, 0.0, 0.0)),
               Stroke => (0.3, 0.3, 0.3, 0.2));

         when Level.Wall_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.55, 0.31, 0.12, 0.58)),
               Stroke => (0.86, 0.55, 0.20, 0.85));

         when Level.Landing_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.13, 0.80, 0.22, 0.48)),
               Stroke => (0.20, 1.0, 0.34, 0.90));

         when Level.Water_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.05, 0.38, 0.82, 0.48)),
               Stroke => (0.15, 0.68, 1.0, 0.90));

         when Level.Start_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.20, 0.95, 0.40, 0.58)),
               Stroke => (0.55, 1.0, 0.60, 1.0));
      end case;
   end Tile_Style;

   function Object_Style
     (Kind : Level.Object_Kind) return Drawing_Style is
   begin
      case Kind is
         when Level.Miner =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.0, 0.85, 1.0, 0.82)),
               Stroke => (0.5, 0.95, 1.0, 1.0));

         when Level.Enemy | Level.Boss_Spawn =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((1.0, 0.12, 0.12, 0.82)),
               Stroke => (1.0, 0.55, 0.55, 1.0));

         when Level.Powerup | Level.Fuel | Level.Shield =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.25, 1.0, 0.30, 0.82)),
               Stroke => (0.62, 1.0, 0.65, 1.0));

         when Level.Weight =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.72, 0.72, 0.72, 0.82)),
               Stroke => (1.0, 1.0, 1.0, 1.0));

         when Level.Goal | Level.Base =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((1.0, 0.86, 0.10, 0.82)),
               Stroke => (1.0, 0.95, 0.55, 1.0));

         when Level.Gate | Level.Platform =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.72, 0.22, 1.0, 0.82)),
               Stroke => (0.90, 0.62, 1.0, 1.0));
      end case;
   end Object_Style;


   function Motion_Style return Drawing_Style is
   begin
      return Gtk_New
        (Stroke     => (0.85, 0.20, 1.0, 0.95),
         Line_Width => 3.0);
   end Motion_Style;

   function Motion_Node_Style return Drawing_Style is
   begin
      return Gtk_New
        (Fill   => Create_Rgba_Pattern ((0.90, 0.20, 1.0, 0.88)),
         Stroke => (1.0, 0.78, 1.0, 1.0));
   end Motion_Node_Style;

   function Motion_Name (Motion : Level.Motion_Kind) return String is
   begin
      case Motion is
         when Level.Static   => return "Static";
         when Level.Patrol_X => return "Patrol X";
         when Level.Patrol_Y => return "Patrol Y";
      end case;
   end Motion_Name;

   function Components_For (Kind : Level.Object_Kind) return String is
   begin
      case Kind is
         when Level.Miner =>
            return "Components: Transform, Renderable, Collider, Rescue";
         when Level.Enemy =>
            return "Components: Transform, Renderable, Collider, AI, Motion";
         when Level.Powerup | Level.Fuel | Level.Shield | Level.Weight =>
            return "Components: Transform, Renderable, Collider, Pickup";
         when Level.Goal | Level.Base =>
            return "Components: Transform, Renderable, Collider, Objective";
         when Level.Gate =>
            return "Components: Transform, Renderable, Collider, Triggered";
         when Level.Platform =>
            return "Components: Transform, Renderable, Collider, Motion";
         when Level.Boss_Spawn =>
            return "Components: Transform, Trigger, Encounter";
      end case;
   end Components_For;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Float_Text (Value : Float) return String is
      package Float_IO is new Ada.Text_IO.Float_IO (Float);
      Buffer : String (1 .. 32) := (others => ' ');
   begin
      Float_IO.Put (Buffer, Value, Aft => 2, Exp => 0);
      return Trimmed (Buffer);
   end Float_Text;

   function Pixel_Text (Value : Float) return String is
   begin
      return Trimmed (Integer'Image (Integer (Value)));
   end Pixel_Text;

   procedure Set_Entry_Text
     (Name  : String;
      Value : String) is
      Field : constant Gtk_Entry := UI_Entry (Name);
   begin
      if Field /= null then
         Field.Set_Text (Value);
      end if;
   end Set_Entry_Text;

   procedure Set_Label_Text
     (Name  : String;
      Value : String) is
      Label : constant Gtk_Label := UI_Label (Name);
   begin
      if Label /= null then
         Label.Set_Text (Value);
      end if;
   end Set_Label_Text;

   function Background_Style return Drawing_Style is
   begin
      return Gtk_New (Stroke => (0.18, 0.35, 0.50, 1.0));
   end Background_Style;

   function Background_Path return String is
      Info : constant Level.Level_Info := Editor_State.Info;
   begin
      return Ada.Strings.Unbounded.To_String
        (Info.Background_Image);
   end Background_Path;

   procedure Add_Background is
      Pixbuf : Gdk.Pixbuf.Gdk_Pixbuf;
      Error  : Glib.Error.GError;
      Image  : Image_Item;
      Path   : constant String := Background_Path;
   begin
      Gdk.Pixbuf.Gdk_New_From_File
        (Pixbuf   => Pixbuf,
         Filename => Path,
         Error    => Error);

      if Error /= null then
         Set_Status ("Background not found: " & Path);
         Glib.Error.Error_Free (Error);
         Background_Item := null;
         return;
      end if;

      Image := Gtk_New_Image
        (Style         => Background_Style,
         Image         => Pixbuf,
         Allow_Rescale => True,
         Width         => Gdouble (Level.World_Width_Pixels),
         Height        => Gdouble (Level.World_Height_Pixels));

      Image.Set_Position ((0.0, 0.0));
      Model.Add (Image);
      Background_Item := Abstract_Item (Image);
   end Add_Background;

   procedure Add_Grid is
      Style : constant Drawing_Style := Gtk_New
        (Stroke => (0.25, 0.48, 0.70, 0.28));
      Line  : Polyline_Item;
   begin
      if not Editor_State.Grid_Visible then
         return;
      end if;

      for X in 0 .. Level.Map_Width loop
         Line := Gtk_New_Polyline
           (Style,
            ((Gdouble (X * Level.Tile_Size), 0.0),
             (Gdouble (X * Level.Tile_Size),
              Gdouble (Level.World_Height_Pixels))));
         Model.Add (Line);
      end loop;

      for Y in 0 .. Level.Map_Height loop
         Line := Gtk_New_Polyline
           (Style,
            ((0.0, Gdouble (Y * Level.Tile_Size)),
             (Gdouble (Level.World_Width_Pixels),
              Gdouble (Y * Level.Tile_Size))));
         Model.Add (Line);
      end loop;
   end Add_Grid;

   procedure Add_Tiles is
      Tiles : constant access Level.Tile_Map := Editor_State.Tiles;
      Rect  : Rect_Item;
   begin
      for Y in Level.Tile_Y loop
         for X in Level.Tile_X loop
            if Tiles (Y, X) /= Level.Space_Tile then
               Rect := Gtk_New_Rect
                 (Style  => Tile_Style (Tiles (Y, X)),
                  Width  => Gdouble (Level.Tile_Size),
                  Height => Gdouble (Level.Tile_Size));

               Rect.Set_Position
                 ((Gdouble ((Integer (X) - 1) * Level.Tile_Size),
                   Gdouble ((Integer (Y) - 1) * Level.Tile_Size)));
               Model.Add (Rect);
            end if;
         end loop;
      end loop;
   end Add_Tiles;

   procedure Add_Objects is
      Objects : constant access Level.Object_Array := Editor_State.Objects;
      Rect    : Rect_Item;
   begin
      Object_Items := (others => null);

      for I in Level.Object_Index loop
         if Objects (I).Used then
            Rect := Gtk_New_Rect
              (Style  => Object_Style (Objects (I).Kind),
               Width  => Gdouble (Objects (I).W),
               Height => Gdouble (Objects (I).H));

            Rect.Set_Position
              ((Gdouble (Objects (I).X), Gdouble (Objects (I).Y)));
            Model.Add (Rect);
            Object_Items (I) := Abstract_Item (Rect);
         end if;
      end loop;
   end Add_Objects;


   function Path_Mode_Name (Mode : Editor_State.Path_Mode_Kind) return String is
   begin
      case Mode is
         when Editor_State.No_Path       => return "None";
         when Editor_State.Once_Path     => return "Once";
         when Editor_State.Loop_Path     => return "Loop";
         when Editor_State.Pingpong_Path => return "PingPong";
      end case;
   end Path_Mode_Name;

   function Path_Easing_Name
     (Easing : Editor_State.Path_Easing_Kind) return String is
   begin
      case Easing is
         when Editor_State.Snap_Ease   => return "Snap";
         when Editor_State.Linear_Ease => return "Linear";
         when Editor_State.Smooth_Ease => return "Smooth";
         when Editor_State.Arc_Ease    => return "Arc";
      end case;
   end Path_Easing_Name;

   procedure Add_Motion_Guides is
      Sel     : constant Editor_State.Selection_Info :=
        Editor_State.Selection;
      Index   : Level.Object_Index;
      Count   : Editor_State.Path_Node_Count;
      Line    : Polyline_Item;
      Node    : Rect_Item;

      procedure Add_Node
        (Point : Editor_State.Path_Node_Record;
         Number : Natural) is
         pragma Unreferenced (Number);
      begin
         Node := Gtk_New_Rect
           (Style  => Motion_Node_Style,
            Width  => 10.0,
            Height => 10.0);
         Node.Set_Position ((Gdouble (Point.X - 5.0), Gdouble (Point.Y - 5.0)));
         Model.Add (Node);
      end Add_Node;
   begin
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
      then
         return;
      end if;

      Index := Level.Object_Index (Sel.Object_Index);
      Count := Editor_State.Object_Path_Count (Index);

      if Count = 0 then
         return;
      end if;

      if Natural (Count) >= 2 then
         for N in 1 .. Natural (Count) - 1 loop
            declare
               A : constant Editor_State.Path_Node_Record :=
                 Editor_State.Object_Path_Node
                   (Index, Editor_State.Path_Node_Index (N));
               B : constant Editor_State.Path_Node_Record :=
                 Editor_State.Object_Path_Node
                   (Index, Editor_State.Path_Node_Index (N + 1));
            begin
               Line := Gtk_New_Polyline
                 (Motion_Style,
                  ((Gdouble (A.X), Gdouble (A.Y)),
                   (Gdouble (B.X), Gdouble (B.Y))));
               Model.Add (Line);
            end;
         end loop;
      end if;

      for N in 1 .. Natural (Count) loop
         Add_Node
           (Editor_State.Object_Path_Node
              (Index, Editor_State.Path_Node_Index (N)),
            N);
      end loop;
   end Add_Motion_Guides;

   function Object_Index_For_Item
     (Item  : Abstract_Item;
      Index : out Level.Object_Index) return Boolean is
   begin
      for I in Level.Object_Index loop
         if Item /= null and then Object_Items (I) = Item then
            Index := I;
            return True;
         end if;
      end loop;

      Index := Level.Object_Index'First;
      return False;
   end Object_Index_For_Item;

   procedure Refresh_Inspector is
      Sel     : constant Editor_State.Selection_Info :=
        Editor_State.Selection;
      Objects : constant access Level.Object_Array := Editor_State.Objects;
      Index   : Level.Object_Index;

      procedure Show_Empty_Path is
      begin
         Set_Entry_Text ("path1_x", "0");
         Set_Entry_Text ("path1_y", "0");
         Set_Entry_Text ("path1_t", "0.00");
         Set_Entry_Text ("path2_x", "0");
         Set_Entry_Text ("path2_y", "0");
         Set_Entry_Text ("path2_t", "1.00");
      end Show_Empty_Path;

      procedure Show_Object_Path (Obj_Index : Level.Object_Index) is
         Count : constant Editor_State.Path_Node_Count :=
           Editor_State.Object_Path_Count (Obj_Index);
      begin
         if Count = 0 then
            Show_Empty_Path;
            return;
         end if;

         declare
            P1 : constant Editor_State.Path_Node_Record :=
              Editor_State.Object_Path_Node (Obj_Index, 1);
         begin
            Set_Entry_Text ("path1_x", Pixel_Text (P1.X));
            Set_Entry_Text ("path1_y", Pixel_Text (P1.Y));
            Set_Entry_Text ("path1_t", Float_Text (P1.Time));
         end;

         if Natural (Count) >= 2 then
            declare
               P2 : constant Editor_State.Path_Node_Record :=
                 Editor_State.Object_Path_Node (Obj_Index, 2);
            begin
               Set_Entry_Text ("path2_x", Pixel_Text (P2.X));
               Set_Entry_Text ("path2_y", Pixel_Text (P2.Y));
               Set_Entry_Text ("path2_t", Float_Text (P2.Time));
            end;
         else
            Set_Entry_Text ("path2_x", "0");
            Set_Entry_Text ("path2_y", "0");
            Set_Entry_Text ("path2_t", "1.00");
         end if;
      end Show_Object_Path;
   begin
      Set_Entry_Text ("selected_x_entry", Pixel_Text (Sel.World_X));
      Set_Entry_Text ("selected_y_entry", Pixel_Text (Sel.World_Y));

      case Sel.Kind is
         when Editor_State.Nothing_Selected =>
            Set_Label_Text ("selected_name_label", "Nothing selected");
            Set_Label_Text ("selected_type_label", "Select an item");
            Set_Label_Text ("selected_components_label", "Components: none");
            Set_Label_Text ("selected_motion_label", "Motion Path: none");
            Set_Entry_Text ("selected_w_entry", "0");
            Set_Entry_Text ("selected_h_entry", "0");
            Show_Empty_Path;

         when Editor_State.Tile_Selected =>
            Set_Label_Text
              ("selected_name_label", Editor_State.Tile_Name (Sel.Tile));
            Set_Label_Text ("selected_type_label", "Terrain tile");
            Set_Label_Text ("selected_components_label",
                            "Components: Terrain, Collision");
            Set_Label_Text ("selected_motion_label", "Motion Path: not available");
            Set_Entry_Text ("selected_w_entry", Integer'Image (Level.Tile_Size));
            Set_Entry_Text ("selected_h_entry", Integer'Image (Level.Tile_Size));
            Show_Empty_Path;

         when Editor_State.Object_Selected =>
            Index := Level.Object_Index (Sel.Object_Index);
            Set_Label_Text
              ("selected_name_label", Editor_State.Object_Display_Name (Index));
            Set_Label_Text
              ("selected_type_label",
               "Entity instance: "
               & Editor_State.Object_Name (Objects (Index).Kind));
            Set_Label_Text
              ("selected_components_label", Components_For (Objects (Index).Kind));
            Set_Label_Text
              ("selected_motion_label",
               "Motion Path: "
               & Path_Mode_Name (Editor_State.Object_Path_Mode (Index))
               & " / "
               & Path_Easing_Name (Editor_State.Object_Path_Easing (Index))
               & " / Nodes:"
               & Integer'Image
                 (Integer (Editor_State.Object_Path_Count (Index))));
            Set_Entry_Text ("selected_x_entry", Pixel_Text (Objects (Index).X));
            Set_Entry_Text ("selected_y_entry", Pixel_Text (Objects (Index).Y));
            Set_Entry_Text ("selected_w_entry", Pixel_Text (Objects (Index).W));
            Set_Entry_Text ("selected_h_entry", Pixel_Text (Objects (Index).H));
            Show_Object_Path (Index);
      end case;
   end Refresh_Inspector;

   function Handle_Map_Event
     (Self    : not null access GObject_Record'Class;
      Details : Event_Details_Access) return Boolean is
      pragma Unreferenced (Self);
      X : constant Float := Float (Details.M_Point.X);
      Y : constant Float := Float (Details.M_Point.Y);
   begin
      if Details.Event_Type = Button_Press and then Details.Button = 3 then
         Editor_State.Set_Tool (Editor_State.Select_Tool);
         Editor_State.Clear_Selection;
         Model.Clear_Selection;
         Refresh_Inspector;
         Set_Status ("Brush cancelled. Select tool active.");
         return True;
      end if;

      if Details.Event_Type /= Button_Release
        or else Details.Button /= 1
      then
         return False;
      end if;

      case Editor_State.Current_Tool is
         when Editor_State.Tile_Brush_Tool
            | Editor_State.Object_Brush_Tool
            | Editor_State.Eraser_Tool =>
            Editor_State.Place_At (X, Y);
            Rebuild;
            Set_Status ("Level changed");
            return True;

         when Editor_State.Select_Tool =>
            declare
               Index : Level.Object_Index;
            begin
               Editor_State.Select_At (X, Y);
               Refresh_Inspector;

               if Object_Index_For_Item
                 (Details.Toplevel_Item, Index)
               then
                  return False;
               end if;

               return True;
            end;

         when Editor_State.Pan_Tool =>
            return False;

         when Editor_State.Trigger_Tool =>
            Set_Status ("Trigger point noted at"
                        & Integer'Image (Integer (X))
                        & ","
                        & Integer'Image (Integer (Y)));
            return True;

         when Editor_State.Path_Tool =>
            declare
               Added : Boolean;
            begin
               Editor_State.Add_Path_Node_To_Selected (X, Y, Added);

               if Added then
                  Rebuild;
                  Set_Status ("Path node added to selected entity");
               else
                  Set_Status ("Select an entity before adding path nodes");
               end if;

               return True;
            end;
      end case;
   end Handle_Map_Event;

   function Handle_After_Move
     (Self    : not null access GObject_Record'Class;
      Details : Event_Details_Access) return Boolean is
      pragma Unreferenced (Self);
      Index : Level.Object_Index;
   begin
      if Details.Event_Type = End_Drag
        and then Object_Index_For_Item
          (Details.Toplevel_Item, Index)
      then
         declare
            Pos : constant Gtkada.Style.Point :=
              Details.Toplevel_Item.Position;
         begin
            Editor_State.Update_Object_Position
              (Index, Float (Pos.X), Float (Pos.Y));
            Refresh_Inspector;
            Set_Status ("Entity moved");
         end;
      end if;

      return False;
   end Handle_After_Move;

   procedure Rebuild is
      New_Model : List_Canvas_Model;
   begin
      Gtk_New (New_Model);
      New_Model.Set_Selection_Mode (Selection_Single);
      Model := New_Model;

      Add_Background;
      Add_Grid;
      Add_Tiles;
      Add_Objects;
      Add_Motion_Guides;

      Canvas.Set_Model (Model);
      Unref (Model);
      Refresh_Inspector;
      Set_Status ("Ready");
   end Rebuild;

   procedure Fit_Map is
   begin
      Canvas.Scale_To_Fit
        (Rect =>
           (0.0,
            0.0,
            Gdouble (Level.World_Width_Pixels),
            Gdouble (Level.World_Height_Pixels)),
         Min_Scale => 0.10,
         Max_Scale => 2.0);
   end Fit_Map;

   procedure Initialize
     (Builder : Gtkada.Builder.Gtkada_Builder) is
      Map_Frame     : Gtk_Frame;
      Minimap_Frame : Gtk_Frame;
      Scrolled      : Gtk_Scrolled_Window;
   begin
      UI_Builder := Builder;

      Map_Frame := Gtk_Frame
        (Get_Object (Gtk_Builder (Builder), "map_canvas_frame"));
      Minimap_Frame := Gtk_Frame
        (Get_Object (Gtk_Builder (Builder), "minimap_frame"));

      Canvas := new Canvas_View_Record;
      Gtkada.Canvas_View.Initialize (Canvas);
      Canvas.Set_Grid_Size (Gdouble (Level.Tile_Size));
      Canvas.Set_Snap
        (Snap_To_Grid   => True,
         Snap_To_Guides => True);

      Canvas.On_Item_Event (Handle_Map_Event'Access);
      Canvas.On_Item_Event (On_Item_Event_Zoom'Access);

      Gtk_New (Scrolled);
      Scrolled.Set_Policy
        (Gtk.Enums.Policy_Automatic, Gtk.Enums.Policy_Automatic);
      Scrolled.Add (Canvas);
      Map_Frame.Add (Scrolled);

      Gtk_New (Minimap);
      Minimap.Monitor (Canvas);
      Minimap_Frame.Add (Minimap);

      Rebuild;
      Map_Frame.Show_All;
      Minimap_Frame.Show_All;
      Fit_Map;
   end Initialize;

end Editor_Canvas;

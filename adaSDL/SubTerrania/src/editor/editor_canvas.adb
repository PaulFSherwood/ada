with Ada.Numerics.Elementary_Functions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Gdk.Pixbuf;
with Gdk.RGBA;
with Gdk.Types;
with Glib;
with Glib.Error;
with Glib.Object;
with Gtk.Builder;
with Gtk.Enums;
with Gtk.Frame;
with Gtk.GEntry;
with Gtk.Label;
with Gtk.Scrolled_Window;
with Gtk.Toggle_Tool_Button;
with Gtk.Widget;
with Gtk.Window;
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
   use Gtk.Frame;
   use Gtk.GEntry;
   use Gtk.Label;
   use Gtk.Scrolled_Window;
   use Gtk.Widget;
   use Gtk.Window;
   use Gtkada.Canvas_View;
   use Gtkada.Canvas_View.Views;
   use Gtkada.Style;

   use type Gdk.Types.Gdk_Modifier_Type;
   use type Glib.Error.GError;
   use type Gtkada.Canvas_View.Abstract_Item;
   use type Gtkada.Canvas_View.Canvas_Event_Type;
   use type Level.Object_Kind;
   use type Level.Tile_Kind;
   use type Editor_State.Layer_Kind;
   use type Editor_State.Selection_Kind;
   use type Editor_State.Tool_Kind;

   function On_Item_Event_Zoom is new On_Item_Event_Zoom_Generic
     (Modifier => 0);

   UI_Builder : Gtkada.Builder.Gtkada_Builder;
   Canvas     : Canvas_View;
   Model      : List_Canvas_Model;

   View_Initialized : Boolean := False;
   Pan_Active        : Boolean := False;
   Pan_Start_Root     : Gtkada.Style.Point := (0.0, 0.0);
   Pan_Start_Topleft  : Model_Point := (0.0, 0.0);
   Path_Drag_Active   : Boolean := False;
   Path_Drag_Node     : Natural := 0;

   type Object_Item_Array is array
     (Level.Object_Index) of Abstract_Item;

   Object_Items : Object_Item_Array := (others => null);

   type Path_Item_Array is array
     (Editor_State.Path_Node_Index) of Abstract_Item;

   Path_Node_Items  : Path_Item_Array := (others => null);
   Path_Label_Items : Path_Item_Array := (others => null);

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

   function UI_Window (Name : String) return Gtk_Window is
   begin
      return Gtk_Window
        (Get_Object (Gtk_Builder (UI_Builder), Name));
   end UI_Window;

   procedure Set_Entry
     (Name : String;
      Text : String) is
      Field : constant Gtk_Entry := UI_Entry (Name);
   begin
      if Field /= null then
         Field.Set_Text (Text);
      end if;
   end Set_Entry;

   procedure Set_Label
     (Name : String;
      Text : String) is
      Label : constant Gtk_Label := UI_Label (Name);
   begin
      if Label /= null then
         Label.Set_Text (Text);
      end if;
   end Set_Label;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Pixel_Text (Value : Float) return String is
   begin
      return Trimmed (Integer'Image (Integer (Value)));
   end Pixel_Text;

   function Time_Text (Value : Float) return String is
      Scaled   : constant Integer := Integer (Value * 100.0);
      Whole    : constant Integer := Scaled / 100;
      Fraction : constant Natural := Natural (abs Scaled rem 100);
      Tens     : constant Character :=
        Character'Val (Character'Pos ('0') + Fraction / 10);
      Ones     : constant Character :=
        Character'Val (Character'Pos ('0') + Fraction mod 10);
   begin
      return Trimmed (Integer'Image (Whole)) & "." & Tens & Ones;
   end Time_Text;

   function Path_Mode_Name
     (Mode : Editor_State.Path_Mode_Kind) return String is
   begin
      case Mode is
         when Editor_State.No_Path       => return "No path";
         when Editor_State.Once_Path     => return "Once";
         when Editor_State.Loop_Path     => return "Loop";
         when Editor_State.Pingpong_Path => return "Ping-pong";
      end case;
   end Path_Mode_Name;

   procedure Set_Status (Text : String) is
   begin
      Set_Label ("status_label", Text);
      Set_Label
        ("tool_status_label",
         "Mode: " & Editor_State.Tool_Name
         & "   Brush: " & Editor_State.Brush_Name);
   end Set_Status;

   procedure Activate_Select_UI is
      procedure Set_Active
        (Name   : String;
         Active : Boolean) is
         Obj : constant GObject := Get_Object (Gtk_Builder (UI_Builder), Name);
      begin
         if Obj /= null then
            Gtk.Toggle_Tool_Button.Set_Active
              (Gtk.Toggle_Tool_Button.Gtk_Toggle_Tool_Button (Obj), Active);
         end if;
      end Set_Active;
      Banner : constant Gtk_Widget := Gtk_Widget
        (Get_Object (Gtk_Builder (UI_Builder), "path_banner"));
   begin
      Editor_State.Set_Tool (Editor_State.Select_Tool);
      Set_Active ("select_tool", True);
      Set_Active ("brush_tool", False);
      Set_Active ("eraser_tool", False);
      Set_Active ("pan_tool", False);
      Set_Active ("mode_path_tool", False);
      Set_Active ("mode_object_tool", True);
      if Banner /= null then
         Banner.Hide;
      end if;
   end Activate_Select_UI;

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
              (Fill   => Create_Rgba_Pattern ((0.55, 0.31, 0.12, 0.52)),
               Stroke => (0.86, 0.55, 0.20, 0.85));

         when Level.Landing_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.13, 0.80, 0.22, 0.45)),
               Stroke => (0.20, 1.0, 0.34, 0.90));

         when Level.Water_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.05, 0.38, 0.82, 0.42)),
               Stroke => (0.15, 0.68, 1.0, 0.90));

         when Level.Start_Tile =>
            return Gtk_New
              (Fill   => Create_Rgba_Pattern ((0.20, 0.95, 0.40, 0.52)),
               Stroke => (0.55, 1.0, 0.60, 1.0));
      end case;
   end Tile_Style;

   function Object_Style
     (Kind        : Level.Object_Kind;
      Is_Selected : Boolean) return Drawing_Style is
      Width : constant Gdouble := (if Is_Selected then 4.0 else 2.0);
   begin
      case Kind is
         when Level.Miner =>
            return Gtk_New
              (Fill       => Create_Rgba_Pattern ((0.0, 0.85, 1.0, 0.80)),
               Stroke     => (0.5, 0.95, 1.0, 1.0),
               Line_Width => Width);

         when Level.Enemy | Level.Boss_Spawn =>
            return Gtk_New
              (Fill       => Create_Rgba_Pattern ((1.0, 0.12, 0.12, 0.80)),
               Stroke     => (1.0, 0.55, 0.55, 1.0),
               Line_Width => Width);

         when Level.Powerup | Level.Fuel | Level.Shield =>
            return Gtk_New
              (Fill       => Create_Rgba_Pattern ((0.25, 1.0, 0.30, 0.80)),
               Stroke     => (0.62, 1.0, 0.65, 1.0),
               Line_Width => Width);

         when Level.Weight =>
            return Gtk_New
              (Fill       => Create_Rgba_Pattern ((0.72, 0.72, 0.72, 0.80)),
               Stroke     => (1.0, 1.0, 1.0, 1.0),
               Line_Width => Width);

         when Level.Goal | Level.Base =>
            return Gtk_New
              (Fill       => Create_Rgba_Pattern ((1.0, 0.86, 0.10, 0.80)),
               Stroke     => (1.0, 0.95, 0.55, 1.0),
               Line_Width => Width);

         when Level.Gate | Level.Platform =>
            return Gtk_New
              (Fill       => Create_Rgba_Pattern ((0.72, 0.22, 1.0, 0.80)),
               Stroke     => (0.90, 0.62, 1.0, 1.0),
               Line_Width => Width);
      end case;
   end Object_Style;

   function Motion_Style return Drawing_Style is
   begin
      return Gtk_New
        (Stroke     => (0.95, 0.30, 1.0, 1.0),
         Line_Width => 4.0);
   end Motion_Style;

   function Motion_Node_Style
     (Number      : Positive;
      Last        : Positive;
      Is_Selected : Boolean) return Drawing_Style is
      Width : constant Gdouble := (if Is_Selected then 6.0 else 3.0);
   begin
      if Number = 1 then
         return Gtk_New
           (Fill       => Create_Rgba_Pattern ((0.15, 1.0, 0.35, 0.95)),
            Stroke     => (1.0, 1.0, 1.0, 1.0),
            Line_Width => Width);
      elsif Number = Last then
         return Gtk_New
           (Fill       => Create_Rgba_Pattern ((1.0, 0.20, 0.20, 0.95)),
            Stroke     => (1.0, 1.0, 1.0, 1.0),
            Line_Width => Width);
      else
         return Gtk_New
           (Fill       => Create_Rgba_Pattern ((0.90, 0.20, 1.0, 0.95)),
            Stroke     => (1.0, 1.0, 1.0, 1.0),
            Line_Width => Width);
      end if;
   end Motion_Node_Style;

   function Background_Path return String is
      Info : constant Level.Level_Info := Editor_State.Info;
   begin
      return Ada.Strings.Unbounded.To_String (Info.Background_Image);
   end Background_Path;

   function Object_Layer_Visible
     (Kind : Level.Object_Kind) return Boolean is
   begin
      case Kind is
         when Level.Miner =>
            return Editor_State.Layer_Visible (Editor_State.Miners_Layer);

         when Level.Enemy | Level.Boss_Spawn =>
            return Editor_State.Layer_Visible (Editor_State.Enemies_Layer);

         when Level.Powerup | Level.Fuel | Level.Shield | Level.Weight =>
            return Editor_State.Layer_Visible (Editor_State.Pickups_Layer);

         when Level.Platform =>
            return Editor_State.Layer_Visible (Editor_State.Platforms_Layer);

         when Level.Goal | Level.Base | Level.Gate =>
            return Editor_State.Layer_Visible (Editor_State.Triggers_Layer);
      end case;
   end Object_Layer_Visible;

   procedure Add_World_Bounds is
      Rect : Rect_Item;
      Style : constant Drawing_Style := Gtk_New
        (Fill   => Create_Rgba_Pattern ((0.08, 0.08, 0.09, 1.0)),
         Stroke => (0.25, 0.25, 0.28, 1.0));
   begin
      Rect := Gtk_New_Rect
        (Style  => Style,
         Width  => Gdouble (Level.World_Width_Pixels),
         Height => Gdouble (Level.World_Height_Pixels));
      Rect.Set_Position ((0.0, 0.0));
      Model.Add (Rect);
   end Add_World_Bounds;

   procedure Add_Background is
      Pixbuf : Gdk.Pixbuf.Gdk_Pixbuf;
      Error  : Glib.Error.GError;
      Image  : Image_Item;
      Path   : constant String := Background_Path;
   begin
      if not Editor_State.Layer_Visible (Editor_State.Background_Layer) then
         return;
      end if;

      Gdk.Pixbuf.Gdk_New_From_File
        (Pixbuf   => Pixbuf,
         Filename => Path,
         Error    => Error);

      if Error /= null then
         Set_Status ("Background not found: " & Path);
         Glib.Error.Error_Free (Error);
         return;
      end if;

      Image := Gtk_New_Image
        (Style         => Gtk_New (Stroke => (0.18, 0.35, 0.50, 1.0)),
         Image         => Pixbuf,
         Allow_Rescale => True,
         Width         => Gdouble (Level.World_Width_Pixels),
         Height        => Gdouble (Level.World_Height_Pixels));

      Image.Set_Position ((0.0, 0.0));
      Model.Add (Image);
   end Add_Background;

   procedure Add_Grid is
      Style : constant Drawing_Style := Gtk_New
        (Stroke     => (0.30, 0.60, 0.95, 0.55),
         Line_Width => 1.0);
      Line : Polyline_Item;
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
            if Tiles (Y, X) /= Level.Space_Tile
              and then
                ((Tiles (Y, X) = Level.Water_Tile
                  and then Editor_State.Layer_Visible
                    (Editor_State.Water_Layer))
                 or else
                   (Tiles (Y, X) /= Level.Water_Tile
                    and then Editor_State.Layer_Visible
                      (Editor_State.Terrain_Layer)))
            then
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
      Sel     : constant Editor_State.Selection_Info := Editor_State.Selection;
      Rect    : Rect_Item;
      Selected_Index : Natural := 0;
   begin
      Object_Items := (others => null);
      if Sel.Kind = Editor_State.Object_Selected then
         Selected_Index := Sel.Object_Index;
      end if;

      for I in Level.Object_Index loop
         if Objects (I).Used and then Object_Layer_Visible (Objects (I).Kind) then
            Rect := Gtk_New_Rect
              (Style  => Object_Style
                 (Objects (I).Kind,
                  Selected_Index = Natural (I)),
               Width  => Gdouble (Objects (I).W),
               Height => Gdouble (Objects (I).H));

            Rect.Set_Position
              ((Gdouble (Objects (I).X), Gdouble (Objects (I).Y)));
            Model.Add (Rect);
            Object_Items (I) := Abstract_Item (Rect);
         end if;
      end loop;
   end Add_Objects;

   function Path_Node_Label
     (Number : Positive;
      Last   : Positive) return String is
   begin
      if Number = 1 then
         return "START";
      elsif Number = Last then
         return "END";
      else
         return "P" & Trimmed (Natural'Image (Number - 1));
      end if;
   end Path_Node_Label;

   procedure Add_Dashed_Segment
     (A : Editor_State.Path_Node_Record;
      B : Editor_State.Path_Node_Record) is
      DX          : constant Float := B.X - A.X;
      DY          : constant Float := B.Y - A.Y;
      Length      : constant Float :=
        Ada.Numerics.Elementary_Functions.Sqrt (DX * DX + DY * DY);
      Dash_Length : constant Float := 16.0;
      Gap_Length  : constant Float := 10.0;
      Position    : Float := 0.0;
      Dash_End    : Float;
      T1          : Float;
      T2          : Float;
      Line        : Polyline_Item;
   begin
      if Length <= 0.01 then
         return;
      end if;

      while Position < Length loop
         Dash_End := Position + Dash_Length;
         if Dash_End > Length then
            Dash_End := Length;
         end if;

         T1 := Position / Length;
         T2 := Dash_End / Length;
         Line := Gtk_New_Polyline
           (Motion_Style,
            ((Gdouble (A.X + DX * T1), Gdouble (A.Y + DY * T1)),
             (Gdouble (A.X + DX * T2), Gdouble (A.Y + DY * T2))));
         Model.Add (Line);
         Position := Position + Dash_Length + Gap_Length;
      end loop;
   end Add_Dashed_Segment;

   procedure Add_Motion_Guides is
      Sel           : constant Editor_State.Selection_Info :=
        Editor_State.Selection;
      Selected_Node : constant Natural := Editor_State.Selected_Path_Node;
      Index         : Level.Object_Index;
      Count         : Editor_State.Path_Node_Count;
      Node          : Rect_Item;
      Node_Label    : Text_Item;
      Label_Style   : constant Drawing_Style := Gtk_New
        (Stroke => (1.0, 1.0, 1.0, 1.0));
   begin
      Path_Node_Items := (others => null);
      Path_Label_Items := (others => null);

      if not Editor_State.Layer_Visible (Editor_State.Paths_Layer)
        or else Sel.Kind /= Editor_State.Object_Selected
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
            Add_Dashed_Segment
              (Editor_State.Object_Path_Node
                 (Index, Editor_State.Path_Node_Index (N)),
               Editor_State.Object_Path_Node
                 (Index, Editor_State.Path_Node_Index (N + 1)));
         end loop;
      end if;

      for N in 1 .. Natural (Count) loop
         declare
            Point : constant Editor_State.Path_Node_Record :=
              Editor_State.Object_Path_Node
                (Index, Editor_State.Path_Node_Index (N));
            Text  : constant String := Path_Node_Label (N, Natural (Count));
            Width : constant Gdouble :=
              (if N = 1 or else N = Natural (Count) then 58.0 else 30.0);
         begin
            Node := Gtk_New_Rect
              (Style  => Motion_Node_Style
                 (N, Natural (Count), Selected_Node = N),
               Width  => 22.0,
               Height => 22.0);
            Node.Set_Position
              ((Gdouble (Point.X - 11.0), Gdouble (Point.Y - 11.0)));
            Model.Add (Node);
            Path_Node_Items (Editor_State.Path_Node_Index (N)) :=
              Abstract_Item (Node);

            Node_Label := Gtk_New_Text
              (Style  => Label_Style,
               Text   => Text,
               Width  => Width,
               Height => 20.0);
            Node_Label.Set_Position
              ((Gdouble (Point.X + 13.0), Gdouble (Point.Y - 11.0)));
            Model.Add (Node_Label);
            Path_Label_Items (Editor_State.Path_Node_Index (N)) :=
              Abstract_Item (Node_Label);
         end;
      end loop;
   end Add_Motion_Guides;

   procedure Refresh_Inspector is
      Sel     : constant Editor_State.Selection_Info := Editor_State.Selection;
      Objects : constant access Level.Object_Array := Editor_State.Objects;
   begin
      case Sel.Kind is
         when Editor_State.Nothing_Selected =>
            Set_Label ("selection_status_label", "Selected: none");
            Set_Label ("path_target_label", "No object selected");

         when Editor_State.Tile_Selected =>
            Set_Label
              ("selection_status_label",
               "Selected tile: " & Editor_State.Tile_Name (Sel.Tile)
               & " at " & Pixel_Text (Sel.World_X)
               & "," & Pixel_Text (Sel.World_Y));
            Set_Label ("path_target_label", "Paths apply to objects only");

         when Editor_State.Object_Selected =>
            declare
               Index : constant Level.Object_Index :=
                 Level.Object_Index (Sel.Object_Index);
               Count : constant Editor_State.Path_Node_Count :=
                 Editor_State.Object_Path_Count (Index);
            begin
               Set_Label
                 ("selection_status_label",
                  "Selected: " & Editor_State.Object_Display_Name (Index)
                  & " [" & Editor_State.Object_Name
                    (Objects (Index).Kind) & "]");
               Set_Label
                 ("path_target_label",
                  "Path target: " & Editor_State.Object_Display_Name (Index)
                  & " | " & Path_Mode_Name
                    (Editor_State.Object_Path_Mode (Index))
                  & " | nodes "
                  & Trimmed (Natural'Image (Natural (Count))));
            end;
      end case;
   end Refresh_Inspector;

   function Hit_Path_Node
     (World_X : Float;
      World_Y : Float;
      Node    : out Natural) return Boolean is
      Sel   : constant Editor_State.Selection_Info := Editor_State.Selection;
      Index : Level.Object_Index;
      Count : Editor_State.Path_Node_Count;
      Point : Editor_State.Path_Node_Record;
      DX    : Float;
      DY    : Float;
   begin
      Node := 0;
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
      then
         return False;
      end if;

      Index := Level.Object_Index (Sel.Object_Index);
      Count := Editor_State.Object_Path_Count (Index);
      for N in 1 .. Natural (Count) loop
         Point := Editor_State.Object_Path_Node
           (Index, Editor_State.Path_Node_Index (N));
         DX := World_X - Point.X;
         DY := World_Y - Point.Y;
         if DX * DX + DY * DY <= 18.0 * 18.0 then
            Node := N;
            return True;
         end if;
      end loop;

      return False;
   end Hit_Path_Node;

   function Segment_Distance_Squared
     (World_X : Float;
      World_Y : Float;
      A       : Editor_State.Path_Node_Record;
      B       : Editor_State.Path_Node_Record) return Float is
      DX      : constant Float := B.X - A.X;
      DY      : constant Float := B.Y - A.Y;
      Length2 : constant Float := DX * DX + DY * DY;
      T       : Float;
      Near_X  : Float;
      Near_Y  : Float;
      Error_X : Float;
      Error_Y : Float;
   begin
      if Length2 <= 0.01 then
         Error_X := World_X - A.X;
         Error_Y := World_Y - A.Y;
         return Error_X * Error_X + Error_Y * Error_Y;
      end if;

      T := ((World_X - A.X) * DX + (World_Y - A.Y) * DY) / Length2;
      if T < 0.0 then
         T := 0.0;
      elsif T > 1.0 then
         T := 1.0;
      end if;

      Near_X := A.X + DX * T;
      Near_Y := A.Y + DY * T;
      Error_X := World_X - Near_X;
      Error_Y := World_Y - Near_Y;
      return Error_X * Error_X + Error_Y * Error_Y;
   end Segment_Distance_Squared;

   function Hit_Path_Segment
     (World_X  : Float;
      World_Y  : Float;
      Segment  : out Natural) return Boolean is
      Sel      : constant Editor_State.Selection_Info := Editor_State.Selection;
      Index    : Level.Object_Index;
      Count    : Editor_State.Path_Node_Count;
      Best     : Float := 14.0 * 14.0;
      Distance : Float;
   begin
      Segment := 0;
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
      then
         return False;
      end if;

      Index := Level.Object_Index (Sel.Object_Index);
      Count := Editor_State.Object_Path_Count (Index);
      if Count < 2 then
         return False;
      end if;

      for N in 1 .. Natural (Count) - 1 loop
         Distance := Segment_Distance_Squared
           (World_X,
            World_Y,
            Editor_State.Object_Path_Node
              (Index, Editor_State.Path_Node_Index (N)),
            Editor_State.Object_Path_Node
              (Index, Editor_State.Path_Node_Index (N + 1)));
         if Distance <= Best then
            Best := Distance;
            Segment := N;
         end if;
      end loop;

      return Segment /= 0;
   end Hit_Path_Segment;

   procedure Show_Path_Node_Context (Node : Natural) is
      Sel   : constant Editor_State.Selection_Info := Editor_State.Selection;
      Index : Level.Object_Index;
      Count : Editor_State.Path_Node_Count;
      Point : Editor_State.Path_Node_Record;
   begin
      if Sel.Kind /= Editor_State.Object_Selected
        or else Sel.Object_Index = 0
        or else Node = 0
      then
         return;
      end if;

      Index := Level.Object_Index (Sel.Object_Index);
      Count := Editor_State.Object_Path_Count (Index);
      if Node > Natural (Count) then
         return;
      end if;

      Point := Editor_State.Object_Path_Node
        (Index, Editor_State.Path_Node_Index (Node));
      Editor_State.Select_Path_Node (Node);
      Set_Label
        ("path_node_title_label",
         Path_Node_Label (Node, Natural (Count))
         & " - " & Editor_State.Object_Display_Name (Index));
      Set_Label
        ("path_node_delete_note",
         (if Node = 1 or else Node = Natural (Count)
          then "START and END cannot be deleted."
          else "Delete removes this waypoint only."));
      Set_Entry ("path_node_x_entry", Pixel_Text (Point.X));
      Set_Entry ("path_node_y_entry", Pixel_Text (Point.Y));
      Set_Entry ("path_node_time_entry", Time_Text (Point.Time));
      UI_Window ("path_node_window").Show_All;
   end Show_Path_Node_Context;

   function Handle_Pan
     (Self    : not null access GObject_Record'Class;
      Details : Event_Details_Access) return Boolean is
      pragma Unreferenced (Self);
      Wants_Pan : constant Boolean :=
        Details.Button = 2
        or else
          (Details.Button = 1
           and then Editor_State.Current_Tool = Editor_State.Pan_Tool);
   begin
      if Details.Event_Type = Button_Press and then Wants_Pan then
         declare
            Area : constant Model_Rectangle := Canvas.Get_Visible_Area;
         begin
            Pan_Active := True;
            Pan_Start_Root := Details.Root_Point;
            Pan_Start_Topleft := (Area.X, Area.Y);
            Details.Allowed_Drag_Area := Drag_Anywhere;
            Details.Allow_Snapping := False;
            return True;
         end;
      end if;

      if Pan_Active
        and then
          (Details.Event_Type = Start_Drag
           or else Details.Event_Type = In_Drag)
      then
         declare
            Scale : constant Gdouble := Canvas.Get_Scale;
            DX : constant Gdouble :=
              (Details.Root_Point.X - Pan_Start_Root.X) / Scale;
            DY : constant Gdouble :=
              (Details.Root_Point.Y - Pan_Start_Root.Y) / Scale;
         begin
            Canvas.Set_Topleft
              ((Pan_Start_Topleft.X - DX,
                Pan_Start_Topleft.Y - DY));
            return True;
         end;
      end if;

      if Pan_Active
        and then
          (Details.Event_Type = End_Drag
           or else Details.Event_Type = Button_Release)
      then
         Pan_Active := False;
         return True;
      end if;

      return False;
   end Handle_Pan;

   function Handle_Map_Event
     (Self    : not null access GObject_Record'Class;
      Details : Event_Details_Access) return Boolean is
      pragma Unreferenced (Self);
      X             : constant Float := Float (Details.M_Point.X);
      Y             : constant Float := Float (Details.M_Point.Y);
      Control_Down  : constant Boolean :=
        (Details.State and Gdk.Types.Control_Mask) /= 0;
      Node_Number   : Natural := 0;
      Segment       : Natural := 0;
      Changed       : Boolean;
   begin
      if Details.Button = 2 or else Pan_Active then
         return False;
      end if;

      if Editor_State.Current_Tool = Editor_State.Path_Tool then
         if Details.Event_Type = Button_Press
           and then Details.Button = 3
           and then Control_Down
         then
            if Hit_Path_Node (X, Y, Node_Number) then
               Editor_State.Select_Path_Node (Node_Number);
               Rebuild;
               Show_Path_Node_Context (Node_Number);
               Set_Status
                 ("Path node selected. Edit properties or delete the waypoint.");
            else
               Set_Status ("Ctrl-right-click directly on a path node.");
            end if;
            return True;
         end if;

         if Details.Event_Type = Button_Press
           and then Details.Button = 1
           and then not Control_Down
           and then Hit_Path_Node (X, Y, Node_Number)
         then
            Editor_State.Select_Path_Node (Node_Number);
            Path_Drag_Active := True;
            Path_Drag_Node := Node_Number;
            Details.Allowed_Drag_Area := Drag_Anywhere;
            Details.Allow_Snapping := False;
            Set_Status
              ("Dragging path node "
               & Trimmed (Natural'Image (Node_Number)));
            return True;
         end if;

         if Path_Drag_Active
           and then
             (Details.Event_Type = Start_Drag
              or else Details.Event_Type = In_Drag)
         then
            Editor_State.Select_Path_Node (Path_Drag_Node);
            Editor_State.Move_Selected_Path_Node (X, Y, Changed);
            if Changed
              and then Path_Drag_Node in
                Natural (Editor_State.Path_Node_Index'First)
                .. Natural (Editor_State.Path_Node_Index'Last)
            then
               declare
                  Item_Index : constant Editor_State.Path_Node_Index :=
                    Editor_State.Path_Node_Index (Path_Drag_Node);
               begin
                  if Path_Node_Items (Item_Index) /= null then
                     Path_Node_Items (Item_Index).Set_Position
                       ((Gdouble (X - 11.0), Gdouble (Y - 11.0)));
                  end if;
                  if Path_Label_Items (Item_Index) /= null then
                     Path_Label_Items (Item_Index).Set_Position
                       ((Gdouble (X + 13.0), Gdouble (Y - 11.0)));
                  end if;
                  Model.Refresh_Layout;
               end;
            end if;
            return True;
         end if;

         if Path_Drag_Active
           and then
             (Details.Event_Type = End_Drag
              or else Details.Event_Type = Button_Release)
         then
            Editor_State.Select_Path_Node (Path_Drag_Node);
            Editor_State.Move_Selected_Path_Node (X, Y, Changed);
            Path_Drag_Active := False;
            Path_Drag_Node := 0;
            Rebuild;
            Set_Status ("Path node moved");
            return True;
         end if;

         if Details.Event_Type = Button_Release
           and then Details.Button = 1
           and then Control_Down
         then
            declare
               Sel     : constant Editor_State.Selection_Info :=
                 Editor_State.Selection;
               Count   : Editor_State.Path_Node_Count := 0;
               Created : Boolean;
               Inserted : Boolean;
            begin
               if Sel.Kind = Editor_State.Object_Selected
                 and then Sel.Object_Index /= 0
               then
                  Count := Editor_State.Object_Path_Count
                    (Level.Object_Index (Sel.Object_Index));
               end if;

               if Count = 0 then
                  Editor_State.Ensure_Simple_Path_For_Selected (Created);
                  if Created then
                     Rebuild;
                     Set_Status
                       ("START and END created. Drag END to the destination.");
                  else
                     Set_Status ("Select an object before creating a path.");
                  end if;
                  return True;
               end if;

               if Hit_Path_Segment (X, Y, Segment) then
                  Editor_State.Insert_Path_Node
                    (After_Node => Editor_State.Path_Node_Index (Segment),
                     World_X    => X,
                     World_Y    => Y,
                     Inserted   => Inserted);
                  if Inserted then
                     Rebuild;
                     Set_Status
                       ("Waypoint inserted. Drag it to refine the route.");
                  else
                     Set_Status ("The path cannot accept another waypoint.");
                  end if;
               else
                  Set_Status
                    ("Ctrl-click the dashed line to insert a waypoint.");
               end if;
               return True;
            end;
         end if;
      end if;

      if Details.Event_Type = Button_Press and then Details.Button = 3 then
         if Editor_State.Current_Tool = Editor_State.Path_Tool then
            Editor_State.Cancel_Path_Edit (Changed);
            if Changed then
               Rebuild;
            end if;
         end if;
         Activate_Select_UI;
         Set_Status ("Operation cancelled. Select mode active.");
         Refresh_Inspector;
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
            Editor_State.Select_At (X, Y);
            Rebuild;
            return True;

         when Editor_State.Pan_Tool =>
            return False;

         when Editor_State.Trigger_Tool =>
            Set_Status
              ("Trigger marker noted at "
               & Pixel_Text (X) & "," & Pixel_Text (Y));
            return True;

         when Editor_State.Path_Tool =>
            if Hit_Path_Node (X, Y, Node_Number) then
               Editor_State.Select_Path_Node (Node_Number);
               Rebuild;
               Set_Status ("Path node selected");
            else
               Set_Status
                 ("Drag a node, Ctrl-click a dashed segment, "
                  & "or Ctrl-right-click a node.");
            end if;
            return True;
      end case;
   end Handle_Map_Event;

   procedure Replace_Model is
      New_Model : List_Canvas_Model;
   begin
      Gtk_New (New_Model);
      New_Model.Set_Selection_Mode (Selection_Single);
      Model := New_Model;

      Add_World_Bounds;
      Add_Background;
      Add_Tiles;
      Add_Objects;
      Add_Motion_Guides;
      Add_Grid;

      Canvas.Set_Model (Model);
      Unref (Model);
   end Replace_Model;

   procedure Rebuild is
   begin
      if View_Initialized then
         declare
            Area  : constant Model_Rectangle := Canvas.Get_Visible_Area;
            Scale : constant Gdouble := Canvas.Get_Scale;
         begin
            Replace_Model;
            Canvas.Set_Scale (Scale);
            Canvas.Set_Topleft ((Area.X, Area.Y));
         end;
      else
         Replace_Model;
         View_Initialized := True;
      end if;

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

   procedure Zoom_In is
   begin
      Canvas.Set_Scale (Canvas.Get_Scale * 1.20);
   end Zoom_In;

   procedure Zoom_Out is
   begin
      Canvas.Set_Scale (Canvas.Get_Scale / 1.20);
   end Zoom_Out;

   procedure Center_On_Start is
      X     : Float;
      Y     : Float;
      Found : Boolean;
   begin
      Found := Level.Find_Player_Start (Editor_State.Tiles.all, X, Y);

      if Found then
         Canvas.Set_Topleft
           ((Gdouble (X - 320.0), Gdouble (Y - 240.0)));
      else
         Fit_Map;
      end if;
   end Center_On_Start;

   procedure Initialize
     (Builder : Gtkada.Builder.Gtkada_Builder) is
      Map_Frame : Gtk_Frame;
      Scrolled  : Gtk_Scrolled_Window;
   begin
      UI_Builder := Builder;

      Map_Frame := Gtk_Frame
        (Get_Object (Gtk_Builder (Builder), "map_canvas_frame"));

      Canvas := new Canvas_View_Record;
      Gtkada.Canvas_View.Initialize (Canvas);
      Canvas.Set_Grid_Size (Gdouble (Level.Tile_Size));
      Canvas.Set_Snap
        (Snap_To_Grid   => True,
         Snap_To_Guides => True);

      Canvas.On_Item_Event (Handle_Pan'Access);
      Canvas.On_Item_Event (Handle_Map_Event'Access);
      Canvas.On_Item_Event (On_Item_Event_Zoom'Access);

      Gtk_New (Scrolled);
      Scrolled.Set_Policy
        (Gtk.Enums.Policy_Automatic, Gtk.Enums.Policy_Automatic);
      Scrolled.Add (Canvas);
      Map_Frame.Add (Scrolled);

      Rebuild;
      Map_Frame.Show_All;
      Fit_Map;
   end Initialize;

end Editor_Canvas;

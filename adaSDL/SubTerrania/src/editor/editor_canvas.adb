with Ada.Strings.Unbounded;
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

   function On_Item_Event_Zoom is new On_Item_Event_Zoom_Generic
     (Modifier => 0);

   UI_Builder : Gtkada.Builder.Gtkada_Builder;
   Canvas     : Canvas_View;
   Model      : List_Canvas_Model;
   Minimap    : Minimap_View;
   View_Ready : Boolean := False;

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
        (Fill   => Create_Rgba_Pattern ((0.0, 0.0, 0.0, 0.0)),
         Stroke => (0.25, 0.48, 0.70, 0.32));
      Rect  : Rect_Item;
   begin
      if not Editor_State.Grid_Visible then
         return;
      end if;

      for Y in Level.Tile_Y loop
         for X in Level.Tile_X loop
            Rect := Gtk_New_Rect
              (Style  => Style,
               Width  => Gdouble (Level.Tile_Size),
               Height => Gdouble (Level.Tile_Size));
            Rect.Set_Position
              ((Gdouble ((Integer (X) - 1) * Level.Tile_Size),
                Gdouble ((Integer (Y) - 1) * Level.Tile_Size)));
            Model.Add (Rect);
         end loop;
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
   begin
      UI_Entry ("selected_x_entry").Set_Text
        (Integer'Image (Integer (Sel.World_X)));
      UI_Entry ("selected_y_entry").Set_Text
        (Integer'Image (Integer (Sel.World_Y)));

      case Sel.Kind is
         when Editor_State.Nothing_Selected =>
            UI_Label ("selected_name_label").Set_Text ("Nothing selected");
            UI_Label ("selected_type_label").Set_Text ("Select an item");

         when Editor_State.Tile_Selected =>
            UI_Label ("selected_name_label").Set_Text
              (Editor_State.Tile_Name (Sel.Tile));
            UI_Label ("selected_type_label").Set_Text ("Terrain tile");
            UI_Entry ("selected_w_entry").Set_Text
              (Integer'Image (Level.Tile_Size));
            UI_Entry ("selected_h_entry").Set_Text
              (Integer'Image (Level.Tile_Size));

         when Editor_State.Object_Selected =>
            Index := Level.Object_Index (Sel.Object_Index);
            UI_Label ("selected_name_label").Set_Text
              (Editor_State.Object_Name (Objects (Index).Kind));
            UI_Label ("selected_type_label").Set_Text ("Entity instance");
            UI_Entry ("selected_x_entry").Set_Text
              (Integer'Image (Integer (Objects (Index).X)));
            UI_Entry ("selected_y_entry").Set_Text
              (Integer'Image (Integer (Objects (Index).Y)));
            UI_Entry ("selected_w_entry").Set_Text
              (Integer'Image (Integer (Objects (Index).W)));
            UI_Entry ("selected_h_entry").Set_Text
              (Integer'Image (Integer (Objects (Index).H)));
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

         when Editor_State.Trigger_Tool | Editor_State.Path_Tool =>
            Set_Status ("Tool data point placed at"
                        & Integer'Image (Integer (X))
                        & ","
                        & Integer'Image (Integer (Y)));
            return True;
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
      Visible   : Model_Rectangle := No_Rectangle;
   begin
      if View_Ready then
         Visible := Canvas.Get_Visible_Area;
      end if;

      Gtk_New (New_Model);
      New_Model.Set_Selection_Mode (Selection_Single);
      Model := New_Model;

      Add_Background;
      Add_Tiles;
      Add_Grid;
      Add_Objects;

      Canvas.Set_Model (Model);
      Unref (Model);

      if View_Ready then
         Canvas.Scroll_Into_View (Visible);
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
      Minimap_Frame.Set_Size_Request (240, 150);

      Canvas := new Canvas_View_Record;
      Gtkada.Canvas_View.Initialize (Canvas);
      Canvas.Set_Grid_Size (Gdouble (Level.Tile_Size));
      Canvas.Set_Snap
        (Snap_To_Grid   => True,
         Snap_To_Guides => True);

      Canvas.On_Item_Event (Handle_Map_Event'Access);
      Canvas.On_Item_Event (On_Item_Event_Select'Access);
      Canvas.On_Item_Event (On_Item_Event_Move_Item'Access);
      Canvas.On_Item_Event (Handle_After_Move'Access);
      Canvas.On_Item_Event (On_Item_Event_Scroll_Background'Access);
      Canvas.On_Item_Event (On_Item_Event_Zoom'Access);

      Gtk_New (Scrolled);
      Scrolled.Set_Policy
        (Gtk.Enums.Policy_Automatic, Gtk.Enums.Policy_Automatic);
      Scrolled.Add (Canvas);
      Map_Frame.Add (Scrolled);

      Gtk_New (Minimap);
      Minimap.Set_Size_Request (220, 130);
      Minimap.Monitor (Canvas);
      Minimap_Frame.Add (Minimap);

      Rebuild;
      Map_Frame.Show_All;
      Minimap_Frame.Show_All;
      Fit_Map;
      View_Ready := True;
   end Initialize;

end Editor_Canvas;

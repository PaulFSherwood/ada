with Ada.Text_IO;
with Ada.Exceptions;
with Glib;
use Glib;

with Gtk.Main;
with Gtk.Window;
with Gtk.Widget;
with Gtk.Box;
with Gtk.Grid;
with Gtk.Label;
with Gtk.Button;
with Gtk.Spin_Button;
with Gtk.Progress_Bar;
with Gtk.Enums;

procedure Gtk_Fuel_Planner is

   --------------------------------------------------------------------
   --  Make the commonly used GTK types directly visible.
   --------------------------------------------------------------------

   use Gtk.Window;
   use Gtk.Widget;
   use Gtk.Box;
   use Gtk.Grid;
   use Gtk.Label;
   use Gtk.Button;
   use Gtk.Spin_Button;
   use Gtk.Progress_Bar;
   use Gtk.Enums;

   --------------------------------------------------------------------
   --  Application widgets
   --
   --  These are declared here because the callback procedures need
   --  access to them.
   --------------------------------------------------------------------

   Main_Window : Gtk_Window;
   Main_Box    : Gtk_Box;
   Input_Grid  : Gtk_Grid;

   Fuel_Label      : Gtk_Label;
   Burn_Label      : Gtk_Label;
   Reserve_Label   : Gtk_Label;
   Endurance_Label : Gtk_Label;
   Status_Label    : Gtk_Label;

   Fuel_Input    : Gtk_Spin_Button;
   Burn_Input    : Gtk_Spin_Button;
   Reserve_Input : Gtk_Spin_Button;

   Calculate_Button : Gtk_Button;
   Reset_Button     : Gtk_Button;

   Fuel_Bar : Gtk_Progress_Bar;

   --------------------------------------------------------------------
   --  Helper function
   --
   --  Convert a floating-point value to a cleaner string.
   --
   --  Float'Image normally places a space before positive values.
   --  For example:
   --
   --     Float'Image (5.0)
   --
   --  might produce:
   --
   --     " 5.00000E+00"
   --
   --  This function removes that leading space.
   --------------------------------------------------------------------

   function Clean_Image (Value : Float) return String is
      Image : constant String := Float'Image (Value);
   begin
      if Image'Length > 0 and then Image (Image'First) = ' ' then
         return Image (Image'First + 1 .. Image'Last);
      else
         return Image;
      end if;
   end Clean_Image;

   --------------------------------------------------------------------
   --  Calculate_Button callback
   --
   --  GTK calls this procedure whenever the user clicks Calculate.
   --------------------------------------------------------------------

   procedure On_Calculate
     (Button : access Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);

      Fuel_Available : Float;
      Burn_Per_Hour  : Float;
      Reserve        : Float;

      Usable_Fuel    : Float;
      Endurance      : Float;
      Remaining_Ratio : Float;
   begin
      -----------------------------------------------------------------
      --  Read values from the spin-button widgets.
      --
      --  Get_Value returns a Glib.Gdouble, so we explicitly convert
      --  each value to Ada's Float type.
      -----------------------------------------------------------------

      Fuel_Available := Float (Fuel_Input.Get_Value);
      Burn_Per_Hour  := Float (Burn_Input.Get_Value);
      Reserve        := Float (Reserve_Input.Get_Value);

      -----------------------------------------------------------------
      --  Determine how much fuel can actually be used.
      -----------------------------------------------------------------

      Usable_Fuel := Fuel_Available - Reserve;

      -----------------------------------------------------------------
      --  Validate the input.
      -----------------------------------------------------------------

      if Burn_Per_Hour <= 0.0 then

         Endurance_Label.Set_Text
           ("Endurance: invalid burn rate");

         Status_Label.Set_Text
           ("Burn rate must be greater than zero.");

         Fuel_Bar.Set_Fraction (0.0);

      elsif Usable_Fuel <= 0.0 then

         Endurance_Label.Set_Text
           ("Endurance: 0 hours");

         Status_Label.Set_Text
           ("Reserve fuel is greater than available fuel.");

         Fuel_Bar.Set_Fraction (0.0);

      else
         --------------------------------------------------------------
         --  Endurance is:
         --
         --       usable fuel
         --     ----------------
         --     fuel used/hour
         --------------------------------------------------------------

         Endurance := Usable_Fuel / Burn_Per_Hour;

         Endurance_Label.Set_Text
           ("Estimated endurance: "
            & Clean_Image (Endurance)
            & " hours");

         --------------------------------------------------------------
         --  Calculate the percentage of fuel that remains usable after
         --  setting aside the reserve.
         --
         --  GTK progress bars expect a fraction from 0.0 through 1.0.
         --------------------------------------------------------------

         Remaining_Ratio := Usable_Fuel / Fuel_Available;

         if Remaining_Ratio < 0.0 then
            Remaining_Ratio := 0.0;
         elsif Remaining_Ratio > 1.0 then
            Remaining_Ratio := 1.0;
         end if;

         Fuel_Bar.Set_Fraction (Gdouble (Remaining_Ratio));

         --------------------------------------------------------------
         --  Provide a simple condition assessment.
         --------------------------------------------------------------

         if Endurance < 1.0 then
            Status_Label.Set_Text
              ("CRITICAL: less than one hour of usable fuel.");

         elsif Endurance < 2.0 then
            Status_Label.Set_Text
              ("WARNING: limited fuel endurance.");

         else
            Status_Label.Set_Text
              ("Fuel level is acceptable.");
         end if;
      end if;

   exception
      -----------------------------------------------------------------
      --  A GUI application should normally catch unexpected callback
      --  exceptions. Otherwise, the user may click a button and see no
      --  obvious explanation of what went wrong.
      -----------------------------------------------------------------

      when Error : others =>
         Ada.Text_IO.Put_Line
           ("Calculation error: "
            & Ada.Exceptions.Exception_Information (Error));

         Status_Label.Set_Text
           ("An unexpected calculation error occurred.");
   end On_Calculate;

   --------------------------------------------------------------------
   --  Reset_Button callback
   --------------------------------------------------------------------

   procedure On_Reset
     (Button : access Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);
   begin
      Fuel_Input.Set_Value    (100.0);
      Burn_Input.Set_Value    (25.0);
      Reserve_Input.Set_Value (20.0);

      Endurance_Label.Set_Text
        ("Estimated endurance: not calculated");

      Status_Label.Set_Text
        ("Enter the fuel information and press Calculate.");

      Fuel_Bar.Set_Fraction (0.0);
   end On_Reset;

   --------------------------------------------------------------------
   --  Window-close callback
   --
   --  Closing the window stops GTK's event loop and ends the program.
   --------------------------------------------------------------------

   procedure On_Window_Destroy
     (Widget : access Gtk_Widget_Record'Class)
   is
      pragma Unreferenced (Widget);
   begin
      Gtk.Main.Main_Quit;
   end On_Window_Destroy;

begin
   --------------------------------------------------------------------
   --  Initialize GTK.
   --
   --  This must happen before creating GTK widgets.
   --------------------------------------------------------------------

   Gtk.Main.Init;

   --------------------------------------------------------------------
   --  Create the main application window.
   --------------------------------------------------------------------

   Gtk_New (Main_Window);

   Main_Window.Set_Title ("Ada Fuel Planner");
   Main_Window.Set_Default_Size
     (Width  => 520,
      Height => 340);

   Main_Window.Set_Border_Width (15);

   Main_Window.On_Destroy
     (On_Window_Destroy'Unrestricted_Access);

   --------------------------------------------------------------------
   --  Create the main vertical container.
   --------------------------------------------------------------------

   Gtk_New
     (Main_Box,
      Orientation => Orientation_Vertical,
      Spacing     => 12);

   Main_Window.Add (Main_Box);

   --------------------------------------------------------------------
   --  Title
   --------------------------------------------------------------------

   declare
      Title_Label : Gtk_Label;
   begin
      Gtk_New
        (Title_Label,
         "Aircraft Fuel Endurance Planner");

      Title_Label.Set_Xalign (0.0);

      Main_Box.Pack_Start
        (Child   => Title_Label,
         Expand  => False,
         Fill    => False,
         Padding => 0);
   end;

   --------------------------------------------------------------------
   --  Create the grid containing labels and numeric inputs.
   --------------------------------------------------------------------

   Gtk_New (Input_Grid);

   Input_Grid.Set_Row_Spacing    (8);
   Input_Grid.Set_Column_Spacing (15);

   Main_Box.Pack_Start
     (Child   => Input_Grid,
      Expand  => False,
      Fill    => True,
      Padding => 0);

   --------------------------------------------------------------------
   --  Available fuel input
   --------------------------------------------------------------------

   Gtk_New (Fuel_Label, "Available fuel:");

   Fuel_Label.Set_Xalign (0.0);

   Gtk_New
     (Fuel_Input,
      Min => 0.0,
      Max => 100_000.0,
      Step    => 1.0);

   Fuel_Input.Set_Value (100.0);
   Fuel_Input.Set_Digits (1);

   Input_Grid.Attach
     (Child  => Fuel_Label,
      Left   => 0,
      Top    => 0,
      Width  => 1,
      Height => 1);

   Input_Grid.Attach
     (Child  => Fuel_Input,
      Left   => 1,
      Top    => 0,
      Width  => 1,
      Height => 1);

   --------------------------------------------------------------------
   --  Fuel burn input
   --------------------------------------------------------------------

   Gtk_New (Burn_Label, "Fuel burn per hour:");

   Burn_Label.Set_Xalign (0.0);

   Gtk_New
     (Burn_Input,
      Min => 0.0,
      Max => 10_000.0,
      Step    => 1.0);

   Burn_Input.Set_Value (25.0);
   Burn_Input.Set_Digits (1);

   Input_Grid.Attach
     (Child  => Burn_Label,
      Left   => 0,
      Top    => 1,
      Width  => 1,
      Height => 1);

   Input_Grid.Attach
     (Child  => Burn_Input,
      Left   => 1,
      Top    => 1,
      Width  => 1,
      Height => 1);

   --------------------------------------------------------------------
   --  Reserve fuel input
   --------------------------------------------------------------------

   Gtk_New (Reserve_Label, "Required reserve:");

   Reserve_Label.Set_Xalign (0.0);

   Gtk_New
     (Reserve_Input,
      Min => 0.0,
      Max => 100_000.0,
      Step    => 1.0);

   Reserve_Input.Set_Value (20.0);
   Reserve_Input.Set_Digits (1);

   Input_Grid.Attach
     (Child  => Reserve_Label,
      Left   => 0,
      Top    => 2,
      Width  => 1,
      Height => 1);

   Input_Grid.Attach
     (Child  => Reserve_Input,
      Left   => 1,
      Top    => 2,
      Width  => 1,
      Height => 1);

   --------------------------------------------------------------------
   --  Buttons
   --------------------------------------------------------------------

   declare
      Button_Box : Gtk_Box;
   begin
      Gtk_New
        (Button_Box,
         Orientation => Orientation_Horizontal,
         Spacing     => 8);

      Gtk_New
        (Calculate_Button,
         "Calculate");

      Gtk_New
        (Reset_Button,
         "Reset");

      Calculate_Button.On_Clicked
        (On_Calculate'Unrestricted_Access);

      Reset_Button.On_Clicked
        (On_Reset'Unrestricted_Access);

      Button_Box.Pack_Start
        (Child   => Calculate_Button,
         Expand  => False,
         Fill    => False,
         Padding => 0);

      Button_Box.Pack_Start
        (Child   => Reset_Button,
         Expand  => False,
         Fill    => False,
         Padding => 0);

      Main_Box.Pack_Start
        (Child   => Button_Box,
         Expand  => False,
         Fill    => False,
         Padding => 0);
   end;

   --------------------------------------------------------------------
   --  Results
   --------------------------------------------------------------------

   Gtk_New
     (Endurance_Label,
      "Estimated endurance: not calculated");

   Endurance_Label.Set_Xalign (0.0);

   Main_Box.Pack_Start
     (Child   => Endurance_Label,
      Expand  => False,
      Fill    => True,
      Padding => 0);

   --------------------------------------------------------------------
   --  Progress bar
   --------------------------------------------------------------------

   Gtk_New (Fuel_Bar);

   Fuel_Bar.Set_Show_Text (True);
   Fuel_Bar.Set_Text ("Usable fuel after reserve");
   Fuel_Bar.Set_Fraction (0.0);

   Main_Box.Pack_Start
     (Child   => Fuel_Bar,
      Expand  => False,
      Fill    => True,
      Padding => 0);

   --------------------------------------------------------------------
   --  Status message
   --------------------------------------------------------------------

   Gtk_New
     (Status_Label,
      "Enter the fuel information and press Calculate.");

   Status_Label.Set_Xalign (0.0);
   Status_Label.Set_Line_Wrap (True);

   Main_Box.Pack_Start
     (Child   => Status_Label,
      Expand  => False,
      Fill    => True,
      Padding => 0);

   --------------------------------------------------------------------
   --  Show every widget attached to the window.
   --------------------------------------------------------------------

   Main_Window.Show_All;

   --------------------------------------------------------------------
   --  Enter GTK's event loop.
   --
   --  The program remains here while GTK waits for mouse clicks,
   --  keyboard input, window events, and other signals.
   --------------------------------------------------------------------

   Gtk.Main.Main;

end Gtk_Fuel_Planner;

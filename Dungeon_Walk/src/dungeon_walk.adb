--  Give this program access to Ada's standard text input/output tools.
--  "use Ada.Text_IO" lets us write Put_Line instead of Ada.Text_IO.Put_Line.
with Ada.Text_IO;
use Ada.Text_IO;

--  Gives access to mathematical constants such as Pi.
with Ada.Numerics;

--  Gives access to functions such as Sin, Cos, and Floor.
with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;

procedure Dungeon_Walk is

   ---------------------------------------------------------------------------
   --  SCREEN SETTINGS
   ---------------------------------------------------------------------------

   --  Width of the terminal-rendered first-person view.
   --  The screen contains 80 character columns.
   Screen_Width : constant Positive := 80;

   --  Height of the terminal-rendered view.
   --  The screen contains 24 character rows.
   Screen_Height : constant Positive := 24;

   ---------------------------------------------------------------------------
   --  MAP SETTINGS
   ---------------------------------------------------------------------------

   --  Width of the hidden top-down ship map.
   Map_Width : constant Positive := 16;

   --  Height of the hidden top-down ship map.
   Map_Height : constant Positive := 16;

   --  A map row is exactly 16 characters long.
   --
   --  This subtype prevents us from accidentally creating a row with the
   --  wrong number of map tiles.
   subtype Map_Row is String (1 .. Map_Width);

   --  The complete map is an array containing 16 Map_Row values.
   --
   --  Access order:
   --
   --     Ship_Map (Y) (X)
   --
   --  The first index selects the row.
   --  The second index selects the column inside that row.
   type Map_Array is array (1 .. Map_Height) of Map_Row;

   --  The fixed ship layout.
   --
   --  '#' means wall.
   --  '.' means open floor.
   --
   --  Because this is constant, the map cannot change while the program runs.
   Ship_Map : constant Map_Array :=
     ("################",
      "#..............#",
      "#..####........#",
      "#..#..#........#",
      "#..#..######...#",
      "#..#...........#",
      "#..######..#####",
      "#..............#",
      "#####..####....#",
      "#......#.......#",
      "#......#..###..#",
      "#.........#....#",
      "#..########....#",
      "#..............#",
      "#..............#",
      "################");

   ---------------------------------------------------------------------------
   --  SCREEN BUFFER
   ---------------------------------------------------------------------------

   --  Each screen row is a String containing Screen_Width characters.
   --
   --  Screen_Array therefore represents the complete terminal image.
   type Screen_Array is
     array (1 .. Screen_Height) of String (1 .. Screen_Width);

   --  This is the off-screen drawing buffer.
   --
   --  We draw walls, floor, minimap, and status text into this array.
   --  After everything is ready, we print the whole array to the terminal.
   Screen : Screen_Array;

   ---------------------------------------------------------------------------
   --  PLAYER STATE
   ---------------------------------------------------------------------------

   --  Player position on the map.
   --
   --  Float is used instead of Integer because the player can stand between
   --  tile centers and move in small increments.
   --
   --  Position 2.5 means halfway through map tile 2.
   Player_X : Float := 2.5;
   Player_Y : Float := 2.5;

   --  Direction the player is facing, measured in radians.
   --
   --  0 radians points mostly toward increasing X.
   --  Pi / 2 points mostly toward increasing Y.
   Player_Angle : Float := 0.0;

   ---------------------------------------------------------------------------
   --  RAY-CASTING SETTINGS
   ---------------------------------------------------------------------------

   --  The player's horizontal field of view.
   --
   --  Pi radians equals 180 degrees.
   --  Pi / 3 equals 60 degrees.
   Field_Of_View : constant Float := Ada.Numerics.Pi / 3.0;

   --  Maximum distance that a ray may travel before we stop searching.
   Maximum_Depth : constant Float := 16.0;

   --  Each ray advances through the map in steps of 0.05 map units.
   --
   --  Smaller values improve precision but require more calculations.
   Ray_Step : constant Float := 0.05;

   --  Distance moved for each press of W or S.
   Move_Speed : constant Float := 0.35;

   --  Rotation performed for each press of A or D.
   --
   --  This value is measured in radians.
   Turn_Speed : constant Float := 0.20;

   ---------------------------------------------------------------------------
   --  MAIN LOOP STATE
   ---------------------------------------------------------------------------

   --  The program continues running while this remains True.
   Running : Boolean := True;

   --  Stores the key read from the keyboard.
   Key : Character;

   ---------------------------------------------------------------------------
   --  IS_WALL
   ---------------------------------------------------------------------------

   --  Determines whether a world position is inside a wall.
   --
   --  X and Y are floating-point world coordinates.
   --  They must be converted into integer map coordinates before indexing
   --  Ship_Map.
   function Is_Wall
     (X : Float;
      Y : Float) return Boolean
   is
      --  Float'Floor removes the fractional portion by rounding downward.
      --
      --  Example:
      --
      --     2.1 becomes 2.0
      --     2.9 becomes 2.0
      --
      --  Integer then converts the Float result into an Integer index.
      Map_X : constant Integer :=
        Integer (Float'Floor (X));

      Map_Y : constant Integer :=
        Integer (Float'Floor (Y));
   begin
      --  Treat every position outside the map as a wall.
      --
      --  This prevents invalid array indexing and prevents the player or rays
      --  from escaping the map.
      if Map_X < 1
        or else Map_X > Map_Width
        or else Map_Y < 1
        or else Map_Y > Map_Height
      then
         return True;
      end if;

      --  Ship_Map uses row first, then column:
      --
      --     Ship_Map (Map_Y) (Map_X)
      --
      --  Return True when the selected tile contains '#'.
      return Ship_Map (Map_Y) (Map_X) = '#';
   end Is_Wall;

   ---------------------------------------------------------------------------
   --  CLEAR_TERMINAL
   ---------------------------------------------------------------------------

   procedure Clear_Terminal is
   begin
      --  ASCII.ESC is the terminal escape character.
      --
      --  ESC [2J clears the terminal screen.
      Put (ASCII.ESC & "[2J");

      --  ESC [H moves the cursor to the upper-left corner.
      Put (ASCII.ESC & "[H");
   end Clear_Terminal;

   ---------------------------------------------------------------------------
   --  FILL_BACKGROUND
   ---------------------------------------------------------------------------

   --  Initializes every character in the screen buffer.
   --
   --  The upper half becomes blank sky or ceiling.
   --  The lower half becomes dotted floor.
   procedure Fill_Background is
   begin
      --  Screen'Range means the complete valid row range of Screen.
      --
      --  For this array, that is 1 .. Screen_Height.
      for Row in Screen'Range loop

         --  Screen (Row)'Range means the valid character indexes for the
         --  selected screen row.
         --
         --  For each row, that is 1 .. Screen_Width.
         for Column in Screen (Row)'Range loop

            --  Rows above the midpoint are treated as empty ceiling space.
            if Row < Screen_Height / 2 then
               Screen (Row) (Column) := ' ';

            --  Rows below the midpoint are treated as floor.
            else
               Screen (Row) (Column) := '.';
            end if;
         end loop;
      end loop;
   end Fill_Background;

   ---------------------------------------------------------------------------
   --  WALL_CHARACTER
   ---------------------------------------------------------------------------

   --  Selects a wall character based on distance.
   --
   --  Darker or heavier-looking symbols represent nearby walls.
   --  Lighter symbols represent distant walls.
   function Wall_Character
     (Distance : Float) return Character
   is
   begin
      --  Less than 20% of the maximum viewing distance.
      if Distance < Maximum_Depth * 0.20 then
         return '#';

      --  Slightly farther away.
      elsif Distance < Maximum_Depth * 0.35 then
         return 'O';

      --  Medium distance.
      elsif Distance < Maximum_Depth * 0.50 then
         return 'o';

      --  Far distance.
      elsif Distance < Maximum_Depth * 0.70 then
         return ':';

      --  Very far away.
      else
         return '.';
      end if;
   end Wall_Character;

   ---------------------------------------------------------------------------
   --  CAST_RAYS
   ---------------------------------------------------------------------------

   --  Builds the first-person view one vertical screen column at a time.
   --
   --  For every screen column:
   --
   --  1. Calculate the ray's direction.
   --  2. Move the ray forward until it reaches a wall.
   --  3. Calculate how tall that wall should appear.
   --  4. Draw a vertical wall slice into the screen buffer.
   procedure Cast_Rays is

      --  Angle of the current ray.
      Ray_Angle : Float;

      --  Direction vector of the current ray.
      --
      --  Eye_X controls horizontal movement through the map.
      --  Eye_Y controls vertical movement through the map.
      Eye_X : Float;
      Eye_Y : Float;

      --  How far the ray has traveled.
      Distance_To_Wall : Float;

      --  Distance adjusted to reduce fish-eye distortion.
      Corrected_Distance : Float;

      --  Current world position being tested by the ray.
      Test_X : Float;
      Test_Y : Float;

      --  Top and bottom screen rows of the wall slice.
      Ceiling_Row : Integer;
      Floor_Row   : Integer;

      --  Character used to shade the wall.
      Wall_Symbol : Character;
   begin
      --  One ray is cast for every terminal screen column.
      for Column in 1 .. Screen_Width loop

         --------------------------------------------------------------------
         --  CALCULATE THIS COLUMN'S RAY ANGLE
         --------------------------------------------------------------------

         --  The leftmost screen column begins at:
         --
         --     Player_Angle - Field_Of_View / 2
         --
         --  The rightmost column ends at:
         --
         --     Player_Angle + Field_Of_View / 2
         --
         --  The division determines how far across the screen this column is.
         Ray_Angle :=
           Player_Angle
           - Field_Of_View / 2.0
           + Float (Column - 1)
             / Float (Screen_Width - 1)
             * Field_Of_View;

         --------------------------------------------------------------------
         --  CONVERT ANGLE INTO A DIRECTION VECTOR
         --------------------------------------------------------------------

         --  Cos determines the X component of the ray direction.
         Eye_X := Cos (Ray_Angle);

         --  Sin determines the Y component of the ray direction.
         Eye_Y := Sin (Ray_Angle);

         --  Every ray begins at the player's position.
         Distance_To_Wall := 0.0;

         --------------------------------------------------------------------
         --  MOVE THE RAY FORWARD UNTIL IT FINDS A WALL
         --------------------------------------------------------------------

         loop
            --  Move the ray slightly farther from the player.
            Distance_To_Wall := Distance_To_Wall + Ray_Step;

            --  Calculate the ray's current world position.
            Test_X := Player_X + Eye_X * Distance_To_Wall;
            Test_Y := Player_Y + Eye_Y * Distance_To_Wall;

            --  Stop when the current world position is inside a wall.
            exit when Is_Wall (Test_X, Test_Y);

            --  Also stop if the ray has traveled too far.
            exit when Distance_To_Wall >= Maximum_Depth;
         end loop;

         --------------------------------------------------------------------
         --  CORRECT FISH-EYE DISTORTION
         --------------------------------------------------------------------

         --  Rays near the left and right edges travel at an angle relative to
         --  the player's central viewing direction.
         --
         --  Without this correction, flat walls appear curved.
         Corrected_Distance :=
           Distance_To_Wall
           * Cos (Ray_Angle - Player_Angle);

         --  Prevent division by zero or extremely large wall heights.
         if Corrected_Distance < 0.1 then
            Corrected_Distance := 0.1;
         end if;

         --------------------------------------------------------------------
         --  CALCULATE WALL HEIGHT
         --------------------------------------------------------------------

         --  Nearby walls have a small distance.
         --  Dividing by that small distance creates a large wall height.
         --
         --  Distant walls have a larger distance and therefore appear shorter.
         Ceiling_Row :=
           Integer
             (Float (Screen_Height) / 2.0
              - Float (Screen_Height) / Corrected_Distance);

         --  Mirror the ceiling boundary around the center of the screen to
         --  calculate the wall's lower boundary.
         Floor_Row := Screen_Height - Ceiling_Row;

         --------------------------------------------------------------------
         --  KEEP DRAWING INSIDE THE SCREEN ARRAY
         --------------------------------------------------------------------

         --  Ensure the wall does not begin above row 1.
         Ceiling_Row := Integer'Max (1, Ceiling_Row);

         --  Ensure the wall does not extend below Screen_Height.
         Floor_Row := Integer'Min (Screen_Height, Floor_Row);

         --  Choose shading based on wall distance.
         Wall_Symbol := Wall_Character (Corrected_Distance);

         --------------------------------------------------------------------
         --  DRAW THIS VERTICAL WALL SLICE
         --------------------------------------------------------------------

         for Row in Ceiling_Row .. Floor_Row loop
            Screen (Row) (Column) := Wall_Symbol;
         end loop;
      end loop;
   end Cast_Rays;

   ---------------------------------------------------------------------------
   --  PLAYER_SYMBOL
   ---------------------------------------------------------------------------

   --  Chooses a minimap arrow based on the player's facing direction.
   function Player_Symbol return Character is

      --  Horizontal direction component.
      Horizontal : constant Float := Cos (Player_Angle);

      --  Vertical direction component.
      Vertical : constant Float := Sin (Player_Angle);
   begin
      --  Determine whether the player is facing more
      --  horizontally or vertically.
      if abs Horizontal > abs Vertical then

         --  Positive horizontal movement means east or right.
         if Horizontal > 0.0 then
            return '>';

         --  Negative horizontal movement means west or left.
         else
            return '<';
         end if;

      else
         --  Positive Y moves downward through the map rows.
         if Vertical > 0.0 then
            return 'v';

         --  Negative Y moves upward through the map rows.
         else
            return '^';
         end if;
      end if;
   end Player_Symbol;

   ---------------------------------------------------------------------------
   --  DRAW_MINIMAP
   ---------------------------------------------------------------------------

   --  Copies the hidden ship map into the upper-right portion of Screen.
   procedure Draw_Minimap is

      --  Leave one blank row above the minimap.
      Start_Row : constant Positive := 2;

      --  Position the minimap close to the right side of the terminal.
      Start_Column : constant Positive :=
        Screen_Width - Map_Width - 1;

      --  Convert the player's floating-point world position to map indexes.
      Player_Map_X : constant Integer :=
        Integer (Float'Floor (Player_X));

      Player_Map_Y : constant Integer :=
        Integer (Float'Floor (Player_Y));

      --  Actual positions inside the larger Screen buffer.
      Screen_Row    : Integer;
      Screen_Column : Integer;
   begin
      --  Visit every row of the hidden map.
      for Map_Y in 1 .. Map_Height loop

         --  Visit every tile in the current row.
         for Map_X in 1 .. Map_Width loop

            --  Translate a map row into a terminal screen row.
            Screen_Row :=
              Start_Row + Map_Y - 1;

            --  Translate a map column into a terminal screen column.
            Screen_Column :=
              Start_Column + Map_X - 1;

            --  Draw the player's directional arrow over the map tile that
            --  contains the player.
            if Map_X = Player_Map_X
              and then Map_Y = Player_Map_Y
            then
               Screen (Screen_Row) (Screen_Column) :=
                 Player_Symbol;

            --  Otherwise copy the original map character.
            else
               Screen (Screen_Row) (Screen_Column) :=
                 Ship_Map (Map_Y) (Map_X);
            end if;
         end loop;
      end loop;
   end Draw_Minimap;

   ---------------------------------------------------------------------------
   --  DRAW_STATUS
   ---------------------------------------------------------------------------

   --  Places control instructions on the final row of the screen.
   procedure Draw_Status is

      --  A fixed String containing the controls.
      Status : constant String :=
        "W/S move  A/D turn  Q quit";
   begin
      --  Status'Range is the valid index range of Status.
      for Index in Status'Range loop

         --  Stop if the text would extend beyond the screen.
         exit when Index > Screen_Width;

         --  Copy one character into the final screen row.
         Screen (Screen_Height) (Index) :=
           Status (Index);
      end loop;
   end Draw_Status;

   ---------------------------------------------------------------------------
   --  RENDER
   ---------------------------------------------------------------------------

   --  Creates and displays one complete frame.
   procedure Render is
   begin
      --  Reset the screen buffer with ceiling and floor characters.
      Fill_Background;

      --  Draw the first-person walls.
      Cast_Rays;

      --  Draw the top-down minimap over the first-person view.
      Draw_Minimap;

      --  Draw the controls on the last row.
      Draw_Status;

      --  Clear the old terminal frame.
      Clear_Terminal;

      --  Print every row of the completed screen buffer.
      for Row in Screen'Range loop
         Put_Line (Screen (Row));
      end loop;
   end Render;

   ---------------------------------------------------------------------------
   --  ATTEMPT_MOVE
   ---------------------------------------------------------------------------

   --  Attempts to move the player forward or backward.
   --
   --  Direction =  1.0 means forward.
   --  Direction = -1.0 means backward.
   procedure Attempt_Move
     (Direction : Float)
   is
      --  Calculate the proposed new X coordinate.
      New_X : constant Float :=
        Player_X
        + Cos (Player_Angle)
          * Move_Speed
          * Direction;

      --  Calculate the proposed new Y coordinate.
      New_Y : constant Float :=
        Player_Y
        + Sin (Player_Angle)
          * Move_Speed
          * Direction;
   begin
      --  Test horizontal movement separately.
      --
      --  Using the old Y coordinate allows the player to slide along walls
      --  instead of becoming completely stuck when moving diagonally into one.
      if not Is_Wall (New_X, Player_Y) then
         Player_X := New_X;
      end if;

      --  Test vertical movement separately.
      --
      --  Player_X may already contain the updated horizontal position.
      if not Is_Wall (Player_X, New_Y) then
         Player_Y := New_Y;
      end if;
   end Attempt_Move;

begin
   ---------------------------------------------------------------------------
   --  PROGRAM START
   ---------------------------------------------------------------------------

   --  Clear any existing terminal contents before displaying the first frame.
   Clear_Terminal;

   ---------------------------------------------------------------------------
   --  MAIN GAME LOOP
   ---------------------------------------------------------------------------

   while Running loop

      --  Draw the current game state.
      Render;

      --  Read one keyboard character immediately.
      --
      --  Unlike Get_Line, this does not require pressing Enter.
      Get_Immediate (Key);

      --  Perform an action based on the key.
      case Key is

         --  Move forward.
         when 'w' | 'W' =>
            Attempt_Move (1.0);

         --  Move backward.
         when 's' | 'S' =>
            Attempt_Move (-1.0);

         --  Turn left by subtracting from the current angle.
         when 'a' | 'A' =>
            Player_Angle :=
              Player_Angle - Turn_Speed;

         --  Turn right by adding to the current angle.
         when 'd' | 'D' =>
            Player_Angle :=
              Player_Angle + Turn_Speed;

         --  End the game loop.
         when 'q' | 'Q' =>
            Running := False;

         --  Ignore every other key.
         when others =>
            null;
      end case;
   end loop;

   ---------------------------------------------------------------------------
   --  PROGRAM SHUTDOWN
   ---------------------------------------------------------------------------

   Clear_Terminal;
   Put_Line ("You leave the ship.");

end Dungeon_Walk;

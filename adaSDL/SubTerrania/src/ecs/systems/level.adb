with Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;

package body Level is

   package US renames Ada.Strings.Unbounded;

   package Object_Kind_IO is new Ada.Text_IO.Enumeration_IO (Object_Kind);
   package Motion_Kind_IO is new Ada.Text_IO.Enumeration_IO (Motion_Kind);
   package Float_IO is new Ada.Text_IO.Float_IO (Float);

   function Default_Level_Info return Level_Info is
   begin
      return
        (Stage_Name => US.To_Unbounded_String ("stage01"),
         Title      => US.To_Unbounded_String ("Mission 1"),
         Next_Level => US.To_Unbounded_String ("stage02.map"));
   end Default_Level_Info;

   function World_Width return Float is
   begin
      return Float (World_Width_Pixels);
   end World_Width;

   function World_Height return Float is
   begin
      return Float (World_Height_Pixels);
   end World_Height;

   function Next_Tile
     (T : Tile_Kind)
      return Tile_Kind is
   begin
      case T is
         when Space_Tile   => return Wall_Tile;
         when Wall_Tile    => return Landing_Tile;
         when Landing_Tile => return Water_Tile;
         when Water_Tile   => return Start_Tile;
         when Start_Tile   => return Space_Tile;
      end case;
   end Next_Tile;

   function Next_Kind
     (K : Object_Kind)
      return Object_Kind is
   begin
      case K is
         when Miner      => return Enemy;
         when Enemy      => return Powerup;
         when Powerup    => return Fuel;
         when Fuel       => return Shield;
         when Shield     => return Weight;
         when Weight     => return Goal;
         when Goal       => return Base;
         when Base       => return Gate;
         when Gate       => return Platform;
         when Platform   => return Boss_Spawn;
         when Boss_Spawn => return Miner;
      end case;
   end Next_Kind;

   function Next_Motion
     (M : Motion_Kind)
      return Motion_Kind is
   begin
      case M is
         when Static   => return Patrol_X;
         when Patrol_X => return Patrol_Y;
         when Patrol_Y => return Static;
      end case;
   end Next_Motion;

   function Tile_To_Char
     (T : Tile_Kind)
      return Character is
   begin
      case T is
         when Space_Tile   => return '0';
         when Wall_Tile    => return '1';
         when Landing_Tile => return '2';
         when Water_Tile   => return '3';
         when Start_Tile   => return '4';
      end case;
   end Tile_To_Char;

   function Char_To_Tile
     (C : Character)
      return Tile_Kind is
   begin
      case C is
         when '1'    => return Wall_Tile;
         when '2'    => return Landing_Tile;
         when '3'    => return Water_Tile;
         when '4'    => return Start_Tile;
         when others => return Space_Tile;
      end case;
   end Char_To_Tile;

   procedure Clear_Objects
     (Objects : in out Object_Array) is
   begin
      for I in Object_Index loop
         Objects (I) := (others => <>);
      end loop;
   end Clear_Objects;

   procedure Clear_Tiles
     (Tiles : out Tile_Map) is
   begin
      for Y in Tile_Y loop
         for X in Tile_X loop
            Tiles (Y, X) := Space_Tile;
         end loop;
      end loop;
   end Clear_Tiles;

   procedure Set_Default_Object
     (Obj    : out Object_Record;
      K      : Object_Kind;
      X      : Float;
      Y      : Float;
      Motion : Motion_Kind) is
   begin
      Obj := (others => <>);
      Obj.Used := True;
      Obj.Kind := K;
      Obj.Motion := Motion;
      Obj.X := X;
      Obj.Y := Y;
      Obj.Dir := 1.0;

      case K is
         when Miner =>
            Obj.W := 24.0;
            Obj.H := 24.0;
            Obj.Motion := Static;

         when Enemy =>
            Obj.W := 32.0;
            Obj.H := 32.0;
            Obj.Speed := 70.0;

         when Powerup | Fuel | Shield =>
            Obj.W := 24.0;
            Obj.H := 24.0;
            Obj.Motion := Static;

         when Weight =>
            Obj.W := 26.0;
            Obj.H := 26.0;
            Obj.Motion := Static;

         when Goal | Base =>
            Obj.W := 40.0;
            Obj.H := 60.0;
            Obj.Motion := Static;

         when Gate =>
            Obj.W := 32.0;
            Obj.H := 120.0;
            Obj.Motion := Static;

         when Boss_Spawn =>
            Obj.W := 48.0;
            Obj.H := 48.0;
            Obj.Motion := Static;

         when Platform =>
            Obj.W := 100.0;
            Obj.H := 20.0;
            Obj.Speed := 40.0;
      end case;

      case Obj.Motion is
         when Static =>
            Obj.Min_Pos := 0.0;
            Obj.Max_Pos := 0.0;
            Obj.Speed := 0.0;

         when Patrol_X =>
            Obj.Min_Pos := X - 100.0;
            Obj.Max_Pos := X + 100.0;

         when Patrol_Y =>
            Obj.Min_Pos := Y - 80.0;
            Obj.Max_Pos := Y + 80.0;
      end case;
   end Set_Default_Object;

   procedure Add_Object
     (Objects : in out Object_Array;
      K       : Object_Kind;
      X       : Float;
      Y       : Float;
      Motion  : Motion_Kind := Static) is
   begin
      for I in Object_Index loop
         if not Objects (I).Used then
            Set_Default_Object (Objects (I), K, X, Y, Motion);
            return;
         end if;
      end loop;
   end Add_Object;

   procedure Add_Loaded_Object
     (Objects : in out Object_Array;
      Obj     : Object_Record) is
   begin
      for I in Object_Index loop
         if not Objects (I).Used then
            Objects (I) := Obj;
            Objects (I).Used := True;
            return;
         end if;
      end loop;
   end Add_Loaded_Object;

   procedure Delete_Object_At
     (Objects : in out Object_Array;
      X       : Float;
      Y       : Float;
      Deleted : out Boolean) is
   begin
      Deleted := False;

      for I in Object_Index loop
         if Objects (I).Used
           and then X >= Objects (I).X - Objects (I).W / 2.0
           and then X <= Objects (I).X + Objects (I).W / 2.0
           and then Y >= Objects (I).Y - Objects (I).H / 2.0
           and then Y <= Objects (I).Y + Objects (I).H / 2.0
         then
            Objects (I) := (others => <>);
            Deleted := True;
            return;
         end if;
      end loop;
   end Delete_Object_At;

   procedure Build_Test_Level
     (Tiles   : out Tile_Map;
      Objects : out Object_Array;
      Info    : out Level_Info) is
      Raw : constant array (Tile_Y) of String (1 .. Map_Width) :=
        (
         "0000000000000000000000000000000000000000",
         "0000000000000000000000000000000000000000",
         "0000000000000000000000000000000000000000",
         "0000000000000000000000011000000101000000",
         "0111111111100111111111111101011101111100",
         "1111110011011100011111100111110000111110",
         "0110000000110000001110000001000000100110",
         "1100000000100000000000000000000000000011",
         "1100000000000000000000000000000000000011",
         "1100000000000000000000000001000000000011",
         "1000000000000000000000000011111111000011",
         "1100000000000000000000000111010011000001",
         "1100000000000001111000001111000011000011",
         "0100000000000011111100001111100011000111",
         "1100100000001111101110001111110011000110",
         "1100000000011110000111011011111011000111",
         "1110000000111010000011100010011011000011",
         "1110000000111000000001110000011111000011",
         "0110000000011000000000111000001111111110",
         "1100000000110000000000011000000110111100",
         "1100001111110000000000011000000110000000",
         "1100001100000000001111101100000111110000",
         "0101101100000011011000111100000011111011",
         "0110001100000011010000001110000001111111",
         "1111000111100011110000000111000001001111",
         "0011000011100111101004000111100000000111",
         "0110000001111111000000000011110000000011",
         "0111000000111110000111000000110000000011",
         "1110000000100100000001110000110000000011",
         "1100000000000000000000110001100000000011",
         "1110000000000000000000100001110000000001",
         "1111101000001000000001100000111000000011",
         "1101111000111101111111110000011100010111",
         "1101111111110111111110100000011111111110",
         "0000111000000111111110000000001111100000",
         "0000100000000000000100000000000000000000");
   begin
      Info := Default_Level_Info;
      Clear_Objects (Objects);

      for Y in Tile_Y loop
         for X in Tile_X loop
            Tiles (Y, X) := Char_To_Tile (Raw (Y) (X));
         end loop;
      end loop;

      Add_Object (Objects, Miner,    887.0, 306.0);
      Add_Object (Objects, Enemy,    254.0, 490.0, Patrol_X);
      Add_Object (Objects, Enemy,    253.0, 352.0, Patrol_X);
      Add_Object (Objects, Powerup, 1_149.0, 580.0);
      Add_Object (Objects, Platform, 112.0, 724.0, Patrol_X);
      Add_Object (Objects, Platform, 749.0, 495.0, Patrol_X);
      Add_Object (Objects, Goal,    1_150.0, 834.0);
   end Build_Test_Level;

   function To_Tile_X
     (X : Float)
      return Integer is
   begin
      return Integer (Float'Floor (X / Float (Tile_Size))) + 1;
   end To_Tile_X;

   function To_Tile_Y
     (Y : Float)
      return Integer is
   begin
      return Integer (Float'Floor (Y / Float (Tile_Size))) + 1;
   end To_Tile_Y;

   function Tile_At_World
     (Tiles : Tile_Map;
      X     : Float;
      Y     : Float)
      return Tile_Kind is
      TX : constant Integer := To_Tile_X (X);
      TY : constant Integer := To_Tile_Y (Y);
   begin
      if TX < Tile_X'First or else TX > Tile_X'Last then
         return Space_Tile;
      elsif TY < Tile_Y'First or else TY > Tile_Y'Last then
         return Space_Tile;
      else
         return Tiles (Tile_Y (TY), Tile_X (TX));
      end if;
   end Tile_At_World;

   function Is_Solid_At
     (Tiles : Tile_Map;
      X     : Float;
      Y     : Float)
      return Boolean is
      TX : constant Integer := To_Tile_X (X);
      TY : constant Integer := To_Tile_Y (Y);
   begin
      if TX < Tile_X'First or else TX > Tile_X'Last then
         return True;
      elsif TY < Tile_Y'First or else TY > Tile_Y'Last then
         return True;
      else
         return Tiles (Tile_Y (TY), Tile_X (TX)) = Wall_Tile;
      end if;
   end Is_Solid_At;

   function Is_Solid_AABB
     (Tiles  : Tile_Map;
      Center_X : Float;
      Center_Y : Float;
      Width    : Float;
      Height   : Float)
      return Boolean is
      Left   : constant Float := Center_X - Width / 2.0;
      Right  : constant Float := Center_X + Width / 2.0;
      Top    : constant Float := Center_Y - Height / 2.0;
      Bottom : constant Float := Center_Y + Height / 2.0;
   begin
      return Is_Solid_At (Tiles, Left,  Top)
        or else Is_Solid_At (Tiles, Right, Top)
        or else Is_Solid_At (Tiles, Left,  Bottom)
        or else Is_Solid_At (Tiles, Right, Bottom);
   end Is_Solid_AABB;

   function Is_Landing_At
     (Tiles : Tile_Map;
      X     : Float;
      Y     : Float)
      return Boolean is
      T : constant Tile_Kind := Tile_At_World (Tiles, X, Y);
   begin
      return T = Landing_Tile or else T = Start_Tile;
   end Is_Landing_At;

   function Find_Player_Start
     (Tiles : Tile_Map;
      X     : out Float;
      Y     : out Float)
      return Boolean is
   begin
      for TY in Tile_Y loop
         for TX in Tile_X loop
            if Tiles (TY, TX) = Start_Tile then
               X := Float ((TX - 1) * Tile_Size) + Float (Tile_Size) / 2.0;
               Y := Float ((TY - 1) * Tile_Size) + Float (Tile_Size) / 2.0;
               return True;
            end if;
         end loop;
      end loop;

      X := 400.0;
      Y := 300.0;
      return False;
   end Find_Player_Start;

   function Tile_Top_At
     (Y : Float)
      return Float is
      TY : constant Integer := To_Tile_Y (Y);
   begin
      return Float ((TY - 1) * Tile_Size);
   end Tile_Top_At;

   procedure Set_Tile_At_World
     (Tiles : in out Tile_Map;
      X     : Float;
      Y     : Float;
      Tile  : Tile_Kind) is
      TX : constant Integer := To_Tile_X (X);
      TY : constant Integer := To_Tile_Y (Y);
   begin
      if Tile = Start_Tile then
         for Clear_Y in Tile_Y loop
            for Clear_X in Tile_X loop
               if Tiles (Clear_Y, Clear_X) = Start_Tile then
                  Tiles (Clear_Y, Clear_X) := Space_Tile;
               end if;
            end loop;
         end loop;
      end if;

      if TX >= Tile_X'First and then TX <= Tile_X'Last
        and then TY >= Tile_Y'First and then TY <= Tile_Y'Last
      then
         Tiles (Tile_Y (TY), Tile_X (TX)) := Tile;
      end if;
   end Set_Tile_At_World;

   procedure Clamp_Point
     (X      : in out Float;
      Y      : in out Float;
      Width  : Float;
      Height : Float) is
   begin
      if X < 0.0 then
         X := 0.0;
      elsif X > Width then
         X := Width;
      end if;

      if Y < 0.0 then
         Y := 0.0;
      elsif Y > Height then
         Y := Height;
      end if;
   end Clamp_Point;

   procedure Move_Dynamic_Objects
     (Objects : in out Object_Array;
      DT      : Float) is
   begin
      for I in Object_Index loop
         if Objects (I).Used then
            case Objects (I).Motion is
               when Static =>
                  null;

               when Patrol_X =>
                  Objects (I).X :=
                    Objects (I).X + Objects (I).Speed * Objects (I).Dir * DT;

                  if Objects (I).X < Objects (I).Min_Pos then
                     Objects (I).X := Objects (I).Min_Pos;
                     Objects (I).Dir := 1.0;
                  elsif Objects (I).X > Objects (I).Max_Pos then
                     Objects (I).X := Objects (I).Max_Pos;
                     Objects (I).Dir := -1.0;
                  end if;

               when Patrol_Y =>
                  Objects (I).Y :=
                    Objects (I).Y + Objects (I).Speed * Objects (I).Dir * DT;

                  if Objects (I).Y < Objects (I).Min_Pos then
                     Objects (I).Y := Objects (I).Min_Pos;
                     Objects (I).Dir := 1.0;
                  elsif Objects (I).Y > Objects (I).Max_Pos then
                     Objects (I).Y := Objects (I).Max_Pos;
                     Objects (I).Dir := -1.0;
                  end if;
            end case;
         end if;
      end loop;
   end Move_Dynamic_Objects;

   procedure Save_Float
     (File : File_Type;
      V    : Float) is
   begin
      Put (File, " ");
      Float_IO.Put (File, V, Fore => 1, Aft => 2, Exp => 0);
   end Save_Float;

   procedure Save_Info
     (File : File_Type;
      Info : Level_Info) is
   begin
      Put_Line (File, "LEVEL");
      Put_Line (File, "NAME " & US.To_String (Info.Stage_Name));
      Put_Line (File, "TITLE " & US.To_String (Info.Title));
      Put_Line (File, "NEXT " & US.To_String (Info.Next_Level));
   end Save_Info;

   function Starts_With
     (Line   : String;
      Last   : Natural;
      Prefix : String)
      return Boolean is
   begin
      return Last >= Prefix'Length
        and then Line (1 .. Prefix'Length) = Prefix;
   end Starts_With;

   function Tail_After
     (Line   : String;
      Last   : Natural;
      Prefix : String)
      return String is
      First : constant Natural := Prefix'Length + 1;
   begin
      if Last < First then
         return "";
      else
         return Line (First .. Last);
      end if;
   end Tail_After;

   procedure Save_Level
     (Tiles   : Tile_Map;
      Objects : Object_Array;
      Info    : Level_Info;
      Path    : String) is
      File : File_Type;
   begin
      Create (File, Out_File, Path);
      Save_Info (File, Info);
      Put_Line (File, "TILES");

      for Y in Tile_Y loop
         for X in Tile_X loop
            Put (File, Tile_To_Char (Tiles (Y, X)));
         end loop;
         New_Line (File);
      end loop;

      Put_Line (File, "OBJECTS");

      for I in Object_Index loop
         if Objects (I).Used then
            Object_Kind_IO.Put (File, Objects (I).Kind);
            Put (File, " ");
            Motion_Kind_IO.Put (File, Objects (I).Motion);
            Save_Float (File, Objects (I).X);
            Save_Float (File, Objects (I).Y);
            Save_Float (File, Objects (I).W);
            Save_Float (File, Objects (I).H);
            Save_Float (File, Objects (I).Min_Pos);
            Save_Float (File, Objects (I).Max_Pos);
            Save_Float (File, Objects (I).Speed);
            Save_Float (File, Objects (I).Dir);
            New_Line (File);
         end if;
      end loop;

      Close (File);
      Put_Line ("Saved " & Path);
   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;
         Put_Line ("Save failed: " & Path);
   end Save_Level;

   procedure Load_Level
     (Tiles   : out Tile_Map;
      Objects : out Object_Array;
      Info    : out Level_Info;
      Path    : String;
      Loaded  : out Boolean) is
      File : File_Type;
      Line : String (1 .. 256);
      Last : Natural;
   begin
      Loaded := False;
      Info := Default_Level_Info;
      Clear_Tiles (Tiles);
      Clear_Objects (Objects);
      Open (File, In_File, Path);

      Get_Line (File, Line, Last);

      if Starts_With (Line, Last, "LEVEL") then
         loop
            exit when End_Of_File (File);
            Get_Line (File, Line, Last);

            if Starts_With (Line, Last, "NAME ") then
               Info.Stage_Name :=
                 US.To_Unbounded_String (Tail_After (Line, Last, "NAME "));
            elsif Starts_With (Line, Last, "TITLE ") then
               Info.Title :=
                 US.To_Unbounded_String (Tail_After (Line, Last, "TITLE "));
            elsif Starts_With (Line, Last, "NEXT ") then
               Info.Next_Level :=
                 US.To_Unbounded_String (Tail_After (Line, Last, "NEXT "));
            elsif Starts_With (Line, Last, "TILES") then
               exit;
            end if;
         end loop;
      end if;

      for Y in Tile_Y loop
         Get_Line (File, Line, Last);
         for X in Tile_X loop
            if X <= Last then
               Tiles (Y, X) := Char_To_Tile (Line (X));
            else
               Tiles (Y, X) := Space_Tile;
            end if;
         end loop;
      end loop;

      if not End_Of_File (File) then
         Get_Line (File, Line, Last);
      end if;

      while not End_Of_File (File) loop
         declare
            Obj : Object_Record := (others => <>);
         begin
            Object_Kind_IO.Get (File, Obj.Kind);
            Motion_Kind_IO.Get (File, Obj.Motion);
            Float_IO.Get (File, Obj.X);
            Float_IO.Get (File, Obj.Y);
            Float_IO.Get (File, Obj.W);
            Float_IO.Get (File, Obj.H);
            Float_IO.Get (File, Obj.Min_Pos);
            Float_IO.Get (File, Obj.Max_Pos);
            Float_IO.Get (File, Obj.Speed);
            Float_IO.Get (File, Obj.Dir);
            Obj.Used := True;
            Add_Loaded_Object (Objects, Obj);

            if not End_Of_Line (File) then
               Skip_Line (File);
            end if;
         exception
            when End_Error =>
               exit;
         end;
      end loop;

      Close (File);
      Loaded := True;
      Put_Line ("Loaded " & Path);
   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;

         Loaded := False;
         Build_Test_Level (Tiles, Objects, Info);
         Put_Line ("Load failed, rebuilt test level: " & Path);
   end Load_Level;

end Level;

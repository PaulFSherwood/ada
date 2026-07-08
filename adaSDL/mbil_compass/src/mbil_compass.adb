with Ada.Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Interfaces.C;
with Interfaces.C.Strings;
with System;


procedure Mbil_Compass is
   pragma Linker_Options ("-lSDL2");

   package C  renames Interfaces.C;
   package CS renames Interfaces.C.Strings;
   package US renames Ada.Strings.Unbounded;
   package EF renames Ada.Numerics.Elementary_Functions;

   use type Interfaces.C.int;
   use type Interfaces.C.unsigned;
   use type System.Address;

   Screen_Width  : constant Integer := 500;
   Screen_Height : constant Integer := 500;

   Api_URL   : constant String := "http://192.168.56.110:8000/api/state";
   Temp_File : constant String := "/tmp/mbil_compass_state.json";

   SDL_INIT_VIDEO          : constant C.unsigned := 16#00000020#;
   SDL_WINDOW_SHOWN        : constant C.unsigned := 16#00000004#;
   SDL_RENDERER_ACCELERATED : constant C.unsigned := 16#00000002#;
   SDL_EVENT_QUIT                : constant C.unsigned := 16#00000100#;

   type SDL_Rect is record
      X : C.int;
      Y : C.int;
      W : C.int;
      H : C.int;
   end record
     with Convention => C;

   type Event_Padding is array (1 .. 52) of C.unsigned_char
     with Convention => C;

   type SDL_Event is record
      Event_Type : C.unsigned;
      Padding    : Event_Padding;
   end record
     with Convention => C;

   function SDL_Init
     (Flags : C.unsigned) return C.int
     with Import, Convention => C, External_Name => "SDL_Init";

   function SDL_CreateWindow
     (Title : CS.chars_ptr;
      X     : C.int;
      Y     : C.int;
      W     : C.int;
      H     : C.int;
      Flags : C.unsigned) return System.Address
     with Import, Convention => C, External_Name => "SDL_CreateWindow";

   function SDL_CreateRenderer
     (Window : System.Address;
      Index  : C.int;
      Flags  : C.unsigned) return System.Address
     with Import, Convention => C, External_Name => "SDL_CreateRenderer";

   function SDL_SetRenderDrawColor
     (Renderer : System.Address;
      R        : C.unsigned_char;
      G        : C.unsigned_char;
      B        : C.unsigned_char;
      A        : C.unsigned_char) return C.int
     with Import, Convention => C, External_Name => "SDL_SetRenderDrawColor";

   function SDL_RenderClear
     (Renderer : System.Address) return C.int
     with Import, Convention => C, External_Name => "SDL_RenderClear";

   function SDL_RenderDrawLine
     (Renderer : System.Address;
      X1       : C.int;
      Y1       : C.int;
      X2       : C.int;
      Y2       : C.int) return C.int
     with Import, Convention => C, External_Name => "SDL_RenderDrawLine";

   function SDL_RenderFillRect
     (Renderer : System.Address;
      Rect     : access SDL_Rect) return C.int
     with Import, Convention => C, External_Name => "SDL_RenderFillRect";

   procedure SDL_RenderPresent
     (Renderer : System.Address)
     with Import, Convention => C, External_Name => "SDL_RenderPresent";

   function SDL_PollEvent
     (Event : access SDL_Event) return C.int
     with Import, Convention => C, External_Name => "SDL_PollEvent";

   procedure SDL_Delay
     (MS : C.unsigned)
     with Import, Convention => C, External_Name => "SDL_Delay";

   procedure SDL_SetWindowTitle
     (Window : System.Address;
      Title  : CS.chars_ptr)
     with Import, Convention => C, External_Name => "SDL_SetWindowTitle";

   procedure SDL_DestroyRenderer
     (Renderer : System.Address)
     with Import, Convention => C, External_Name => "SDL_DestroyRenderer";

   procedure SDL_DestroyWindow
     (Window : System.Address)
     with Import, Convention => C, External_Name => "SDL_DestroyWindow";

   procedure SDL_Quit_All
     with Import, Convention => C, External_Name => "SDL_Quit";

   function C_System
     (Command : CS.chars_ptr) return C.int
     with Import, Convention => C, External_Name => "system";

   Window   : System.Address := System.Null_Address;
   Renderer : System.Address := System.Null_Address;
   Event    : aliased SDL_Event;

   Running      : Boolean := True;
   Heading      : Float := 0.0;
   Api_Ok       : Boolean := False;
   Fetch_Tick   : Natural := 0;

   procedure Ignore (Value : C.int) is
   begin
      null;
   end Ignore;

   function Trim_Image (N : Integer) return String is
   begin
      return Ada.Strings.Fixed.Trim
        (Integer'Image (N), Ada.Strings.Both);
   end Trim_Image;

   function Normalize_Heading (H : Float) return Float is
      Result : Float := H;
   begin
      while Result < 0.0 loop
         Result := Result + 360.0;
      end loop;

      while Result >= 360.0 loop
         Result := Result - 360.0;
      end loop;

      return Result;
   end Normalize_Heading;

   function Slurp_File (Path : String) return String is
      File : Ada.Text_IO.File_Type;
      Data : US.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);

      while not Ada.Text_IO.End_Of_File (File) loop
         US.Append (Data, Ada.Text_IO.Get_Line (File));
         US.Append (Data, " ");
      end loop;

      Ada.Text_IO.Close (File);
      return US.To_String (Data);
   exception
      when others =>
         return "";
   end Slurp_File;

   function Extract_Number
     (Json     : String;
      Key      : String;
      Fallback : Float) return Float
   is
      use Ada.Strings.Fixed;

      Key_Pos   : Natural := Index (Json, Key);
      Colon_Pos : Natural;
      Start_Pos : Natural;
      End_Pos   : Natural;
   begin
      if Key_Pos = 0 then
         return Fallback;
      end if;

      Colon_Pos := Index (Json (Key_Pos + Key'Length .. Json'Last), ":");

      if Colon_Pos = 0 then
         return Fallback;
      end if;

      Start_Pos := Colon_Pos + 1;

      while Start_Pos <= Json'Last and then
        (Json (Start_Pos) = ' ' or else
         Json (Start_Pos) = ASCII.HT or else
         Json (Start_Pos) = '"')
      loop
         Start_Pos := Start_Pos + 1;
      end loop;

      End_Pos := Start_Pos;

      while End_Pos <= Json'Last and then
        (Json (End_Pos) in '0' .. '9' or else
         Json (End_Pos) = '.' or else
         Json (End_Pos) = '-' or else
         Json (End_Pos) = '+')
      loop
         End_Pos := End_Pos + 1;
      end loop;

      if End_Pos = Start_Pos then
         return Fallback;
      end if;

      return Float'Value (Json (Start_Pos .. End_Pos - 1));
   exception
      when others =>
         return Fallback;
   end Extract_Number;

   type Heading_Update is record
      Value : Float;
      Ok    : Boolean;
   end record;

   function Fetch_Heading (Current : Float) return Heading_Update is
      Command_Text : constant String :=
        "curl -fsS --max-time 0.25 " & Api_URL &
        " -o " & Temp_File & " >/dev/null 2>&1";

      Command : CS.chars_ptr := CS.New_String (Command_Text);
      Status  : C.int;
   begin
      Status := C_System (Command);
      CS.Free (Command);

      if Status /= 0 then
         return (Value => Current, Ok => False);
      end if;

      declare
         Json      : constant String := Slurp_File (Temp_File);
         New_Value : Float := Current;
      begin
         New_Value := Extract_Number (Json, """heading""", Current);
         New_Value := Extract_Number (Json, """hdg""", New_Value);

         return
           (Value => Normalize_Heading (New_Value),
            Ok    => True);
      end;
   end Fetch_Heading;

   procedure Set_Color
     (Red   : Natural;
      Green : Natural;
      Blue  : Natural;
      Alpha : Natural := 255)
   is
   begin
      Ignore
        (SDL_SetRenderDrawColor
           (Renderer,
            C.unsigned_char (Red),
            C.unsigned_char (Green),
            C.unsigned_char (Blue),
            C.unsigned_char (Alpha)));
   end Set_Color;

   procedure Draw_Line
     (X1 : Integer;
      Y1 : Integer;
      X2 : Integer;
      Y2 : Integer)
   is
   begin
      Ignore
        (SDL_RenderDrawLine
           (Renderer,
            C.int (X1),
            C.int (Y1),
            C.int (X2),
            C.int (Y2)));
   end Draw_Line;

   procedure Fill_Rect
     (X : Integer;
      Y : Integer;
      W : Integer;
      H : Integer)
   is
      Rect : aliased SDL_Rect :=
        (X => C.int (X),
         Y => C.int (Y),
         W => C.int (W),
         H => C.int (H));
   begin
      Ignore (SDL_RenderFillRect (Renderer, Rect'Access));
   end Fill_Rect;

   procedure Draw_Circle
     (CX     : Integer;
      CY     : Integer;
      Radius : Integer)
   is
      Pi : constant Float := Float (Ada.Numerics.Pi);

      Prev_X : Integer := CX;
      Prev_Y : Integer := CY - Radius;
      New_X  : Integer;
      New_Y  : Integer;
      Angle  : Float;
   begin
      for Deg in 1 .. 360 loop
         Angle := Float (Deg) * Pi / 180.0;

         New_X := CX + Integer (Float (Radius) * EF.Sin (Angle));
         New_Y := CY - Integer (Float (Radius) * EF.Cos (Angle));

         Draw_Line (Prev_X, Prev_Y, New_X, New_Y);

         Prev_X := New_X;
         Prev_Y := New_Y;
      end loop;
   end Draw_Circle;

   procedure Update_Title is
      Hdg_Int : constant Integer := Integer (Heading);
      Status  : constant String :=
        (if Api_Ok then "MBIL Compass - HDG "
         else "MBIL Compass - STALE HDG ");

      Title_String : constant String := Status & Trim_Image (Hdg_Int);
      Title_C      : CS.chars_ptr := CS.New_String (Title_String);
   begin
      SDL_SetWindowTitle (Window, Title_C);
      CS.Free (Title_C);
   end Update_Title;

   procedure Draw_Compass is
     --| Get the center of the compass
      CX     : constant Integer := Screen_Width / 2;
      CY     : constant Integer := Screen_Height / 2;
      Radius : constant Integer := 190;

      Pi    : constant Float := Float (Ada.Numerics.Pi);
      Angle : Float;

      X1 : Integer;
      Y1 : Integer;
      X2 : Integer;
      Y2 : Integer;

      Inner : Integer;
   begin
      -- Background
      Set_Color (10, 14, 22);
      Ignore (SDL_RenderClear (Renderer));

      -- Outer ring
      Set_Color (90, 115, 140);
      Draw_Circle (CX, CY, Radius);

      -- Tick marks
      for I in 0 .. 35 loop
         declare
            Deg : constant Integer := I * 10;
         begin
            Angle := Float (Deg) * Pi / 180.0;

            if Deg mod 90 = 0 then
               Set_Color (235, 235, 235);
               Inner := Radius - 28;
            elsif Deg mod 30 = 0 then
               Set_Color (160, 170, 180);
               Inner := Radius - 20;
            else
               Set_Color (85, 95, 110);
               Inner := Radius - 10;
            end if;

            --| Take an angle
            --| Take a distance from the center
            --| Find the X/Y point on the circle
            X1 := CX + Integer (Float (Inner) * EF.Sin (Angle));
            Y1 := CY - Integer (Float (Inner) * EF.Cos (Angle));
            X2 := CX + Integer (Float (Radius) * EF.Sin (Angle));
            Y2 := CY - Integer (Float (Radius) * EF.Cos (Angle));

            Draw_Line (X1, Y1, X2, Y2);
         end;
      end loop;

      -- North reference marker
      Set_Color (120, 190, 255);
      Draw_Line (CX, CY - Radius - 18, CX, CY - Radius + 18);
      Draw_Line (CX - 10, CY - Radius - 5, CX, CY - Radius - 18);
      Draw_Line (CX + 10, CY - Radius - 5, CX, CY - Radius - 18);

      -- Heading needle
      Angle := Heading * Pi / 180.0;

      X2 := CX + Integer (Float (Radius - 45) * EF.Sin (Angle));
      Y2 := CY - Integer (Float (Radius - 45) * EF.Cos (Angle));

      X1 := CX - Integer (35.0 * EF.Sin (Angle));
      Y1 := CY + Integer (35.0 * EF.Cos (Angle));

      if Api_Ok then
         Set_Color (255, 210, 70);
      else
         Set_Color (180, 80, 80);
      end if;

      Draw_Line (X1, Y1, X2, Y2);
      Draw_Line (X1 + 1, Y1, X2 + 1, Y2);
      Draw_Line (X1 - 1, Y1, X2 - 1, Y2);

      -- Center block
      Set_Color (230, 230, 230);
      Fill_Rect (CX - 5, CY - 5, 10, 10);

      -- Small heading strength block at bottom
      if Api_Ok then
         Set_Color (50, 180, 90);
      else
         Set_Color (180, 60, 60);
      end if;

      Fill_Rect (CX - 60, Screen_Height - 45, 120, 12);
   end Draw_Compass;

   Title : CS.chars_ptr := CS.New_String ("MBIL Compass");

begin
   if SDL_Init (SDL_INIT_VIDEO) /= 0 then
      return;
   end if;

   Window :=
     SDL_CreateWindow
       (Title,
        100,
        100,
        C.int (Screen_Width),
        C.int (Screen_Height),
        SDL_WINDOW_SHOWN);

   CS.Free (Title);

   if Window = System.Null_Address then
      SDL_Quit_All;
      return;
   end if;

   Renderer :=
     SDL_CreateRenderer
       (Window,
        -1,
        SDL_RENDERER_ACCELERATED);

   if Renderer = System.Null_Address then
      SDL_DestroyWindow (Window);
      SDL_Quit_All;
      return;
   end if;

   while Running loop
      while SDL_PollEvent (Event'Access) /= 0 loop
         if Event.Event_Type = SDL_EVENT_QUIT then
            Running := False;
         end if;
      end loop;

      -- Poll MBIL about 4 times per second.
      if Fetch_Tick = 0 then
         declare
            Update : constant Heading_Update := Fetch_Heading (Heading);
         begin
            Heading := Update.Value;
            Api_Ok  := Update.Ok;
            Update_Title;
         end;
      end if;

      Draw_Compass;
      SDL_RenderPresent (Renderer);

      SDL_Delay (16);
      Fetch_Tick := (Fetch_Tick + 1) mod 15;
   end loop;

   SDL_DestroyRenderer (Renderer);
   SDL_DestroyWindow (Window);
   SDL_Quit_All;
end Mbil_Compass;

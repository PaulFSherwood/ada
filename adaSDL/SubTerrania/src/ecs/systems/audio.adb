with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

package body Audio is

   package IC renames Interfaces.C;
   package CS renames Interfaces.C.Strings;
   package US renames Ada.Strings.Unbounded;

   use type IC.int;
   use type CS.chars_ptr;
   use type System.Address;

   SDL_Init_Audio : constant IC.unsigned := 16#0000_0010#;

   Mix_Init_FLAC : constant IC.int := 16#0000_0001#;
   Mix_Init_MP3  : constant IC.int := 16#0000_0008#;
   Mix_Init_OGG  : constant IC.int := 16#0000_0010#;

   Default_Frequency : constant IC.int := 44_100;
   Default_Format    : constant IC.unsigned_short := 16#8010#;
   Default_Channels  : constant IC.int := 2;
   Default_Buffer    : constant IC.int := 2_048;

   function SDL_Init_Subsystem
     (Flags : IC.unsigned) return IC.int
   with Import, Convention => C, External_Name => "SDL_InitSubSystem";

   procedure SDL_Quit_Subsystem
     (Flags : IC.unsigned)
   with Import, Convention => C, External_Name => "SDL_QuitSubSystem";

   function SDL_Get_Error return CS.chars_ptr
   with Import, Convention => C, External_Name => "SDL_GetError";

   function Mix_Init
     (Flags : IC.int) return IC.int
   with Import, Convention => C, External_Name => "Mix_Init";

   procedure Mix_Quit
   with Import, Convention => C, External_Name => "Mix_Quit";

   function Mix_Open_Audio
     (Frequency : IC.int;
      Format    : IC.unsigned_short;
      Channels  : IC.int;
      Chunk_Size : IC.int) return IC.int
   with Import, Convention => C, External_Name => "Mix_OpenAudio";

   procedure Mix_Close_Audio
   with Import, Convention => C, External_Name => "Mix_CloseAudio";

   function Mix_Load_MUS
     (File_Name : CS.chars_ptr) return System.Address
   with Import, Convention => C, External_Name => "Mix_LoadMUS";

   function Mix_Play_Music
     (Music : System.Address;
      Loops : IC.int) return IC.int
   with Import, Convention => C, External_Name => "Mix_PlayMusic";

   function Mix_Halt_Music return IC.int
   with Import, Convention => C, External_Name => "Mix_HaltMusic";

   procedure Mix_Free_Music
     (Music : System.Address)
   with Import, Convention => C, External_Name => "Mix_FreeMusic";

   Audio_Subsystem_Ready : Boolean := False;
   Mixer_Ready           : Boolean := False;
   Audio_Ready           : Boolean := False;

   Current_Track : System.Address := System.Null_Address;
   Current_Path  : US.Unbounded_String := US.Null_Unbounded_String;

   Menu_Path   : US.Unbounded_String := US.Null_Unbounded_String;
   Level_Path  : US.Unbounded_String := US.Null_Unbounded_String;
   Editor_Path : US.Unbounded_String := US.Null_Unbounded_String;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Starts_With
     (Text   : String;
      Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text
          (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Tail_After
     (Text   : String;
      Prefix : String) return String is
   begin
      if Text'Length <= Prefix'Length then
         return "";
      else
         return Text
           (Text'First + Prefix'Length .. Text'Last);
      end if;
   end Tail_After;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean is
   begin
      return Text'Length >= Suffix'Length
        and then Text
          (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Is_Music_File (Name : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      return Ends_With (Lower, ".mp3")
        or else Ends_With (Lower, ".ogg")
        or else Ends_With (Lower, ".wav")
        or else Ends_With (Lower, ".flac");
   end Is_Music_File;

   function Error_Text return String is
      Error : constant CS.chars_ptr := SDL_Get_Error;
   begin
      if Error = CS.Null_Ptr then
         return "unknown SDL error";
      else
         return CS.Value (Error);
      end if;
   end Error_Text;

   procedure Load_Config is
      Config_Path : constant String := "assets/database/audio.cfg";
      File        : File_Type;
      Line        : String (1 .. 2_048);
      Last        : Natural;
   begin
      Menu_Path := US.Null_Unbounded_String;
      Level_Path := US.Null_Unbounded_String;
      Editor_Path := US.Null_Unbounded_String;

      if not Ada.Directories.Exists (Config_Path) then
         Put_Line ("Audio config not found: " & Config_Path);
         return;
      end if;

      Open (File, In_File, Config_Path);

      while not End_Of_File (File) loop
         Get_Line (File, Line, Last);

         if Last > 0 then
            declare
               Text : constant String := Trim (Line (1 .. Last));
            begin
               if Starts_With (Text, "MENU_MUSIC ") then
                  Menu_Path := US.To_Unbounded_String
                    (Tail_After (Text, "MENU_MUSIC "));
               elsif Starts_With (Text, "LEVEL_MUSIC ") then
                  Level_Path := US.To_Unbounded_String
                    (Tail_After (Text, "LEVEL_MUSIC "));
               elsif Starts_With (Text, "EDITOR_MUSIC ") then
                  Editor_Path := US.To_Unbounded_String
                    (Tail_After (Text, "EDITOR_MUSIC "));
               end if;
            end;
         end if;
      end loop;

      Close (File);
   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;

         Put_Line ("Could not read audio config: " & Config_Path);
   end Load_Config;

   function First_Available_Music return String is
      Music_Directory : constant String := "assets/audio/music";
      Search          : Ada.Directories.Search_Type;
      Directory_Item  : Ada.Directories.Directory_Entry_Type;
      Started         : Boolean := False;
   begin
      if not Ada.Directories.Exists (Music_Directory) then
         return "";
      end if;

      Ada.Directories.Start_Search
        (Search,
         Music_Directory,
         "*",
         (Ada.Directories.Ordinary_File => True,
          others => False));
      Started := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Directory_Item);

         if Is_Music_File (Ada.Directories.Simple_Name (Directory_Item)) then
            declare
               Result : constant String :=
                 Ada.Directories.Full_Name (Directory_Item);
            begin
               Ada.Directories.End_Search (Search);
               return Result;
            end;
         end if;
      end loop;

      Ada.Directories.End_Search (Search);
      return "";
   exception
      when others =>
         if Started then
            Ada.Directories.End_Search (Search);
         end if;

         return "";
   end First_Available_Music;

   function Resolve_Music_Path
     (Configured : US.Unbounded_String) return String is
      Candidate : constant String := US.To_String (Configured);
   begin
      if Candidate /= "" and then Ada.Directories.Exists (Candidate) then
         return Candidate;
      end if;

      if Candidate /= "" then
         Put_Line ("Configured music not found: " & Candidate);
      end if;

      return First_Available_Music;
   end Resolve_Music_Path;

   function Sound_Name
     (Sound : Sound_ID) return String is
   begin
      case Sound is
         when Menu_Move      => return "menu move";
         when Menu_Select    => return "menu select";
         when Shield_Hit     => return "shield hit";
         when Weapon_Laser   => return "weapon laser";
         when Weapon_Bomb    => return "weapon bomb";
         when Miner_Rescued  => return "miner rescued";
         when Player_Crashed => return "player crashed";
         when Level_Saved    => return "level saved";
         when Level_Loaded   => return "level loaded";
      end case;
   end Sound_Name;

   procedure Initialise is
      Requested : constant IC.int :=
        Mix_Init_FLAC + Mix_Init_MP3 + Mix_Init_OGG;
      Available : IC.int;
   begin
      Load_Config;

      if SDL_Init_Subsystem (SDL_Init_Audio) /= 0 then
         Put_Line ("Audio disabled: " & Error_Text);
         return;
      end if;

      Audio_Subsystem_Ready := True;
      Available := Mix_Init (Requested);
      Mixer_Ready := True;

      if Mix_Open_Audio
        (Default_Frequency,
         Default_Format,
         Default_Channels,
         Default_Buffer) /= 0
      then
         Put_Line ("SDL2_mixer could not open audio: " & Error_Text);
         Mix_Quit;
         Mixer_Ready := False;
         SDL_Quit_Subsystem (SDL_Init_Audio);
         Audio_Subsystem_Ready := False;
         return;
      end if;

      Audio_Ready := True;
      Put_Line
        ("SDL2_mixer audio ready; decoder flags:"
         & IC.int'Image (Available));
   exception
      when Error : others =>
         Put_Line
           ("Audio initialisation failed: "
            & Ada.Exceptions.Exception_Message (Error));
   end Initialise;

   procedure Play_Sound
     (Sound : Sound_ID) is
   begin
      Put_Line ("Sound hook: " & Sound_Name (Sound));
   end Play_Sound;

   procedure Stop_Music is
   begin
      if Current_Track /= System.Null_Address then
         declare
            Result : constant IC.int := Mix_Halt_Music;
            pragma Unreferenced (Result);
         begin
            Mix_Free_Music (Current_Track);
         end;

         Current_Track := System.Null_Address;
         Current_Path := US.Null_Unbounded_String;
      end if;
   end Stop_Music;

   procedure Play_Music_File
     (Path : String) is
      Clean_Path : constant String := Trim (Path);
      File_Name  : CS.chars_ptr := CS.Null_Ptr;
      New_Track  : System.Address := System.Null_Address;
   begin
      if Clean_Path = "" then
         Put_Line ("Music path is empty");
         return;
      elsif not Ada.Directories.Exists (Clean_Path) then
         Put_Line ("Music file not found: " & Clean_Path);
         return;
      elsif not Audio_Ready then
         Put_Line ("Audio is unavailable; cannot play: " & Clean_Path);
         return;
      elsif US.To_String (Current_Path) = Clean_Path
        and then Current_Track /= System.Null_Address
      then
         return;
      end if;

      Stop_Music;
      File_Name := CS.New_String (Clean_Path);
      New_Track := Mix_Load_MUS (File_Name);
      CS.Free (File_Name);
      File_Name := CS.Null_Ptr;

      if New_Track = System.Null_Address then
         Put_Line ("Could not load music: " & Clean_Path);
         Put_Line ("SDL2_mixer: " & Error_Text);
         return;
      end if;

      if Mix_Play_Music (New_Track, -1) /= 0 then
         Put_Line ("Could not play music: " & Clean_Path);
         Put_Line ("SDL2_mixer: " & Error_Text);
         Mix_Free_Music (New_Track);
         return;
      end if;

      Current_Track := New_Track;
      Current_Path := US.To_Unbounded_String (Clean_Path);
      Put_Line ("Music playing: " & Clean_Path);
   exception
      when Error : others =>
         if File_Name /= CS.Null_Ptr then
            CS.Free (File_Name);
         end if;

         if New_Track /= System.Null_Address
           and then New_Track /= Current_Track
         then
            Mix_Free_Music (New_Track);
         end if;

         Put_Line
           ("Music playback failed: "
            & Ada.Exceptions.Exception_Message (Error));
   end Play_Music_File;

   procedure Play_Music
     (Music : Music_ID) is
      Path : US.Unbounded_String;
   begin
      case Music is
         when Menu_Music =>
            Path := Menu_Path;

         when Mission_One_Music =>
            Path := Level_Path;

         when Editor_Music =>
            if US.Length (Editor_Path) > 0 then
               Path := Editor_Path;
            else
               Path := Menu_Path;
            end if;
      end case;

      declare
         Resolved : constant String := Resolve_Music_Path (Path);
      begin
         if Resolved = "" then
            Put_Line ("No playable music file was found");
         else
            Play_Music_File (Resolved);
         end if;
      end;
   end Play_Music;

   procedure Shutdown is
   begin
      Stop_Music;

      if Audio_Ready then
         Mix_Close_Audio;
         Audio_Ready := False;
      end if;

      if Mixer_Ready then
         Mix_Quit;
         Mixer_Ready := False;
      end if;

      if Audio_Subsystem_Ready then
         SDL_Quit_Subsystem (SDL_Init_Audio);
         Audio_Subsystem_Ready := False;
      end if;
   end Shutdown;

end Audio;

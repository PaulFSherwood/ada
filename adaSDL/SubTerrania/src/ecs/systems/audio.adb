with Ada.Text_IO; use Ada.Text_IO;

package body Audio is

   Current_Music : Music_ID := Menu_Music;
   Music_Active  : Boolean := False;

   function Sound_Name
     (Sound : Sound_ID)
      return String is
   begin
      case Sound is
         when Menu_Move     => return "menu move";
         when Menu_Select   => return "menu select";
         when Shield_Hit    => return "shield hit";
         when Weapon_Laser  => return "weapon laser";
         when Weapon_Bomb   => return "weapon bomb";
         when Miner_Rescued => return "miner rescued";
         when Player_Crashed => return "player crashed";
         when Level_Saved   => return "level saved";
         when Level_Loaded  => return "level loaded";
      end case;
   end Sound_Name;

   function Music_Name
     (Music : Music_ID)
      return String is
   begin
      case Music is
         when Menu_Music        => return "menu music";
         when Mission_One_Music => return "mission one music";
         when Editor_Music      => return "editor music";
      end case;
   end Music_Name;

   procedure Initialise is
   begin
      Put_Line ("Audio hooks ready");
   end Initialise;

   procedure Shutdown is
   begin
      Stop_Music;
   end Shutdown;

   procedure Play_Sound
     (Sound : Sound_ID) is
   begin
      Put_Line ("Sound: " & Sound_Name (Sound));
   end Play_Sound;

   procedure Play_Music
     (Music : Music_ID) is
   begin
      if not Music_Active or else Current_Music /= Music then
         Current_Music := Music;
         Music_Active := True;
         Put_Line ("Music: " & Music_Name (Music));
      end if;
   end Play_Music;

   procedure Stop_Music is
   begin
      if Music_Active then
         Music_Active := False;
         Put_Line ("Music stopped");
      end if;
   end Stop_Music;

end Audio;

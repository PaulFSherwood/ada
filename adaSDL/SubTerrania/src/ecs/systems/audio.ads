package Audio is

   type Sound_ID is
     (Menu_Move,
      Menu_Select,
      Shield_Hit,
      Weapon_Laser,
      Weapon_Bomb,
      Miner_Rescued,
      Player_Crashed,
      Level_Saved,
      Level_Loaded);

   type Music_ID is
     (Menu_Music,
      Mission_One_Music,
      Editor_Music);

   procedure Initialise;
   procedure Shutdown;

   procedure Play_Sound
     (Sound : Sound_ID);

   procedure Play_Music
     (Music : Music_ID);

   procedure Stop_Music;

end Audio;

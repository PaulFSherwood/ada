with Game;
with Game.IO;

procedure Tic_Tac_Toe is
   use Game;
   use Game.IO;

   Game_State     : Board;
   Current_Player : String (1 .. 1);
begin

   -- Set up for new game
   Game_State :=
     ((Blank, Blank, Blank), (Blank, Blank, Blank), (Blank, Blank, Blank));

   Current_Player := O;

   Display_Board (Game_State, Current_Player);
end Tic_Tac_Toe;

with Level;

package Inputs is

   type Input_State is record
      Quit_Requested : Boolean := False;
      Toggle_Mode    : Boolean := False;
      Toggle_Brush   : Boolean := False;

      Next_Tile      : Boolean := False;
      Next_Kind      : Boolean := False;
      Next_Motion    : Boolean := False;
      Place          : Boolean := False;
      Delete         : Boolean := False;
      Save_Level     : Boolean := False;
      Load_Level     : Boolean := False;

      Cursor_DX      : Float := 0.0;
      Cursor_DY      : Float := 0.0;

      Thrust         : Boolean := False;
      Brake          : Boolean := False;
      Turn_Left      : Boolean := False;
      Turn_Right     : Boolean := False;
   end record;

   procedure Poll_Events
     (State : out Input_State;
      Mode  : Level.Game_Mode;
      Brush : Level.Brush_Mode);

end Inputs;

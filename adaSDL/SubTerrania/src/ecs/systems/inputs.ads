with Level;

package Inputs is

   type Input_Context is
     (Menu_Context,
      Play_Context,
      Editor_Context);

   type Input_State is record
      Quit_Requested : Boolean := False;
      Toggle_Mode    : Boolean := False;
      Toggle_Brush   : Boolean := False;

      Menu_Up        : Boolean := False;
      Menu_Down      : Boolean := False;
      Menu_Select    : Boolean := False;
      Menu_Back      : Boolean := False;

      Next_Tile      : Boolean := False;
      Next_Kind      : Boolean := False;
      Next_Motion    : Boolean := False;
      Next_View      : Boolean := False;
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
     (State   : out Input_State;
      Context : Input_Context;
      Brush   : Level.Brush_Mode);

end Inputs;

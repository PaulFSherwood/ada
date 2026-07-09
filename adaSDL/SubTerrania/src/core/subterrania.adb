with Application;

procedure SubTerrania is
begin
   Application.Init;

   while Application.Is_Running loop
      Application.Update;
      Application.Draw;
   end loop;

   Application.Shutdown;
end SubTerrania;

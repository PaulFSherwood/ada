with Gtk.Main;
with Editor_App;

procedure Subterrania_Editor is
begin
   Gtk.Main.Init;
   Editor_App.Initialize;
   Gtk.Main.Main;
end Subterrania_Editor;

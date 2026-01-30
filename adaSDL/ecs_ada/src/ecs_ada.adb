--| Import application level ECS logic
with ECS;
--| Import SDLAda core and specific subsystems
--| {Ada favors dep, explicit namespaces over flat APIs}
with SDL;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers.Makers;
with SDL.Events.Events;

--| Procedure is the program
--| No main function, the program is the procedure
--| Entry point of the program 
--| In Ada, a pprocedure (not a class) is the executable
procedure Ecs_Ada is
   --| Compile-time constants (immutable)
   --| Compile time constants for window dimensions
   --| Using constants makes intent explicit and prevents mutation
   Screen_Width : constant := 640;
   Screen_Height : constant := 480;
   --| Main loop control Flag 
   --| Explicit state variable instead of hidden control flow
   Running : Boolean := True;
   --| SDL resources with strong typing
   --| Ada bindings avoid void* and enforce correct lifetimes
   Window   : SDL.Video.Windows.Window;
   Renderer : SDL.Video.Renderers.Renderer;
   Event    : SDL.Events.Events.Events;
   --| ECS entity identifier
   --| Game logic is kept independent of SDL and rendering
   Player : ECS.Entity_Id;
   --| Scoped operator visibility
   --| Enable equality comparisons for SDL event Event_Types
   --| Ada requires explicit permission for enum operations
   use type SDL.Events.Event_Types;
begin
   --| Initialize SDL subsystems
   --| Fail fast if initialization is unsuccessful
   if not SDL.Initialise (Flags => SDL.Enable_Screen) then
      return;
   end if;
   --| Create SDL window using named parameters
   --| Ada aggregates make structure and intent explicit
   SDL.Video.Windows.Makers.Create
     (Win     => Window,
      Title    => "ECS Ada + SDL",
      Position => SDL.Natural_Coordinates'(X => 10, Y => 10),
      Size => SDL.Positive_Sizes'(Screen_Width, Screen_Height),
      Flags => 0);
   --| Create renderer associated with the window Get_Surface
   --| Resources dependencies are explicit
   SDL.Video.Renderers.Makers.Create
     (Renderer, Window.Get_Surface);
   --| Set renderer draw color (background)
   --| Rendering configuration is separated from game logic
   Renderer.Set_Draw_Colour ((32, 132, 64, 255));
   --| Create a new ECS entity
   --| Entities are lightweight identifiers without behavior
   ECS.Create_Entity (Player);
   --| Main game loop
   --| Explicit control flow without framework magic
   while Running loop
      --| Pool and process all pending SDL Events
      --| Deterministic, explicit input handling
      while SDL.Events.Events.Poll (Event) loop
         --| Handel the quit event
         --| Exit loop cleanly instead of forcing termination
         if Event.Common.Event_Type = SDL.Events.Quit then
            Running := False;
         end if;
      end loop;
      --| Clearn screen by filling background Rectangle
      --| Explicit render pass step
      Renderer.Fill
        (Rectangle => (0, 0, Screen_Width, Screen_Height));
      --| Present rendered frame to the window
      --| Rendering and presentation are separate steps
      Window.Update_Surface;
   end loop;
   --| Clean up SDL resources
   --| Explicit finalization ensures predictable shutdown.
   Window.Finalize;
   SDL.Finalise;

end Ecs_Ada;

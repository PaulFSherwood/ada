package Bus is

   subtype Word is Integer;

   type Message is record
      Source      : Integer;
      Destination : Integer;
      Payload     : Word;
   end record;

   protected Shared_Bus is
      procedure Send (M : Message);
      entry Receive (M : out Message);
   private
      Has_Data  : Boolean := False;
      Buffer    : Message;
   end Shared_Bus;

end bus;

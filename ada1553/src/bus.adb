package body Bus is

   protected body Shared_Bus is
   
      procedure Send (M : Message) is
      begin
         Buffer    := M;
         Has_Data  := True;
      end Send;

      entry Receive (M : out Message) when Has_Data is
      begin
         M := Buffer;
         Has_Data := False;
      end Receive;

   end Shared_Bus;

end Bus;

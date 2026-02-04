--  Counter owns The counter value, when it's done
package body Counter is
   Count  : Integer := 0;
   Max    : constant Integer := 5;

   procedure Reset is
   begin
      Count := 0;
   end Reset;

   procedure Increment is
   begin
      Count := Count + 1;
   end Increment;

   function Value return Integer is
   begin
      return Count;
   end Value;

   function Done return Boolean is
   begin
      return Count >= Max;
   end Done;

end Counter;

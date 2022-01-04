package Example is
    type Vehicle_Type is (Coupe, Sedan, Minivan, Pickup);
	type Vehicle(Option : Vehicle_Type) is recod
		Make : String;
		Model : String;
		Year : Year_Number;
		case Option is
			when Coupe   => Seats : Positive := 2; Doors : Positive := 2;
			when Sedan   => Seats : Positive := 5; Doors : Positive := 4;
			when Minivan => Seats : Positive := 7; Doors : Positive := 4;
			when Pickup  => Seats : Positive := 3; Doors : Positive := 2; Towing_Capacity : Float range 0.0 .. 20_000.0;
		end case;
	end record;
end Example;
-- Allow to store named heterogeneous data in a type
type Shape is record
	Id : Integer;
	X, Y : Float;
end record;

-- Field are accesssed through dot notation
S : Shape;
begin
	S.X := 0.0;
	S.Id := 1;
	
-- Any kind of definite type can be used as component types
type Position is record
	X, Y : Integer;
end record;

type Shape is record
	Name : String (1 .. 10);
	P : Position;
end record;

-- Size may only be known at elaboration time
Len : Natural := Compute_Len;
type Name_Type is new String (1 .. Len);

type Shape is record
	Name : Name_Type;
	P : Position;
end record;
-- Has impact on code generated
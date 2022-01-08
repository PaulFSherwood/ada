-- Default values can be provided to record components
type Position is record
	X : Integer := 0;
	Y : Integer := 0;
end record;

-- Default values are dynamic expressions evaluated at object elaboration
Cx, Cy : Integer := 0;

type Position is record
	X : Integer := Cx;
	Y : Integer := Cy;
end record;

P1 : Position;  -- = (0, 0);

begin
	Cx := 1;
	Cy := 1;
	declare
		P2 : Positon; -- = (1, 1);
		
-- Aggregates (1/2)
-- Like arrays, record alues can be ginen through aggretates
type Position is record
	X, Y : Integer;
end record;

type Shape is record
	Name : String (1 .. 10);
	P : Position;
end record;

Center : Position := (0, 0);
Circle : Shape := ((others => ' '), Center);
-- Named aggretates are possible (but cannot switch back to positional)
P1 : Position := (0, Y => 0);      -- OK
P2 : Position := (X => 0, Y => 0); -- OK
P3 : Position := (Y => 0, X => 0); -- OK
P4 : Position := (X => 0, 0, 0);   -- NOK

-- Aggregates (2/2)
-- Named aggretates is required for one-elements records
type Singleton is record
	V : Integer;
end record;

V1 : Singleton := (V => 0);  -- OK
V2 : Singleton := (0);       -- NOK

-- Default values can be referred as <> after a nmae or others
type Rec is record
	A, B, C, D : Integer;
end record;

V1 : Rec := (others => <>);
V2 : Rec := (A => 0, B => <>, others => <>);

-- If all remaining types are the same, others can use an expressions
type Rec is record
	A, B : Integer;
	C, D : Float;
end record;

V1 : Rec := (0, 0, others => 0.0);

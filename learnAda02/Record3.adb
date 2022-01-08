-- this one failes
-- Compilation error, all components are not of the same type,
--  they can't be given a common value through others
type MyInteger is new Integer;
type R is record
	A, B, C : Integer := 0;
	D : MyInteger := 0;
end record;
V : R := (others => 1);

-- This is correct.  In the absence of explicit values given in the record 
--  definition, A, B, C, and D will be of whatever value is in the memory 
--  at this time
type MyInteger is new Integer;
type R is record
	A, B, C : Integer;
	D : MyInteger;
end record;
V : R := (other => <>);


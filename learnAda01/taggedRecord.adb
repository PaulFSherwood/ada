package Example is
    type Person is tagged record;
		Name : String;
		Age : String;
		end record;
		procedure Rename(Who : in out Person; New_Name : in String);
		
		type Programmer is new Person with record
			Known_Languages : String_Array;
		end record;
		procedure Learn_Language(Who : in out Programmer; Language : in String);

end Example;
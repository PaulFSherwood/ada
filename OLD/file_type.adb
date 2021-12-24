package Ada.Text_IO is

	type File_Type is limited private;

	-- more stuff

	procedure Open(File : in out File_Type;
			Mode : File_Mode;
			Name : String;
			Form : String := "");
	
	-- more stuff

	procedure Put_Line (Item : String);

	-- more stuff

end Ada.Text_IO; 

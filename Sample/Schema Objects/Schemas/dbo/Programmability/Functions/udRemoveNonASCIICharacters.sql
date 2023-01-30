CREATE FUNCTION dbo.udfRemoveNonASCIICharacters (@string NVARCHAR(MAX)) 

RETURNS NVARCHAR(MAX) 

AS

/*
		Purpose:	Remove Non ASCII characters in string
		
		Version		Date				Developer			Comment
LIVE	1.1			2022-05-23			Chris Ledger		Task 530 - Create function
*/

	-- FUNCTION TO REMOVE NON ASCII CHARACTERS
	BEGIN

		DECLARE @i INT = 1
		DECLARE @OutputString NVARCHAR(MAX) = ''

		WHILE (@i <= LEN(@string))
    
			BEGIN
    
				IF CHAR(ASCII(SUBSTRING(@string, @i, 1))) <> '?'
			
					BEGIN
				
						SET @OutputString = @OutputString + SUBSTRING(@string, @i, 1)
			
					END
		
				SET @i = @i + 1

			END
		
		RETURN @OutputString       
	
	END
GO
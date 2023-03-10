CREATE FUNCTION dbo.udfIdentifyNonASCIICharacters (@string NVARCHAR(MAX)) 

RETURNS INT 

AS

/*
		Purpose:	Identify Non ASCII characters in string
		
		Version		Date				Developer			Comment
LIVE	1.1			2022-05-23			Chris Ledger		Task 530 - Add comments
*/

	-- FUNCTION TO IDENTIFY NON ASCII CHARACTERS
	BEGIN

		DECLARE @i INT = 1
		DECLARE @result INT = 0

		WHILE (@i <= LEN(@string))
    
			BEGIN
    
				IF CHAR(ASCII(SUBSTRING(@string, @i, 1))) = '?'
			
					BEGIN
				
						SET @result = 1
						BREAK
			
					END
		
				SET @i = @i + 1

			END
		
		RETURN @result       
	
	END
GO
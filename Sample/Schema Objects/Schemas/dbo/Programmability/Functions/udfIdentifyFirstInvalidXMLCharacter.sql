CREATE FUNCTION [dbo].[udfIdentifyFirstInvalidXMLCharacter] 
(
    @InputString NVARCHAR(4000)
)
RETURNS INT

AS

/*
		Purpose:	Returns the first invalid XL character in string   
		
		Version		Date				Developer			Comment
LIVE	1.0			2022-05-23			Chris Ledger		Task 530 - Created
LIVE	1.1			2022-05-24			Chris Ledger		Task 530 - switch to XML 1.0 valid character set
*/

BEGIN
 
    DECLARE @FirstCharacter INT
    SET @FirstCharacter = 0
 
    DECLARE @NChar NVARCHAR(1)
    DECLARE @Position INT
 
    SET @Position = 1
    WHILE @Position <= LEN(@InputString)
    BEGIN
        SET @NChar = SUBSTRING(@InputString, @Position, 1)

		-- FIND INVALID XML CHARACTER
        IF UNICODE(@NChar) <> 1 AND  UNICODE(@NChar) <> 9 AND  UNICODE(@NChar) <> 10 AND  UNICODE(@NChar) <> 13 AND (UNICODE(@NChar) NOT BETWEEN 32 AND 55295) AND (UNICODE(@NChar) NOT BETWEEN 57344 AND 65533) AND (UNICODE(@NChar) NOT BETWEEN 65536 AND 1114111)	-- V1.1
        --IF (UNICODE(@NChar) NOT BETWEEN 1 AND 55295) AND (UNICODE(@NChar) NOT BETWEEN 57344 AND 65533) AND (UNICODE(@NChar) NOT BETWEEN 65536 AND 1114111)																											-- V1.1
			BEGIN
				SET @FirstCharacter = @Position
				BREAK
			END
		
		SET @Position = @Position + 1
    END
    
	RETURN @FirstCharacter
 
END
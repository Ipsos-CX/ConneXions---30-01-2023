CREATE FUNCTION [dbo].[udfRemoveInvalidXMLCharacters] 
(
    @InputString NVARCHAR(4000)
)
RETURNS NVARCHAR(4000)

AS

/*
		Purpose:	Removes invalid XML characters in string
		
		Version		Date				Developer			Comment
LIVE	1.0			2022-05-23			Chris Ledger		Task 530 - Created
LIVE	1.1			2022-05-24			Chris Ledger		Task 530 - switch to XML 1.0 valid character set
*/

BEGIN
 
    DECLARE @OutputString NVARCHAR(4000)
    SET @OutputString = ''
 
    DECLARE @NChar NVARCHAR(1)
    DECLARE @Position INT
 
    SET @Position = 1
    WHILE @Position <= LEN(@InputString)
    BEGIN
        SET @NChar = SUBSTRING(@InputString, @Position, 1)

		-- FIND INVALID XML CHARACTER
        IF UNICODE(@NChar) = 1 OR  UNICODE(@NChar) = 9 OR  UNICODE(@NChar) = 10 OR  UNICODE(@NChar) = 13 OR (UNICODE(@NChar) BETWEEN 32 AND 55295) OR (UNICODE(@NChar) BETWEEN 57344 AND 65533) OR (UNICODE(@NChar) BETWEEN 65536 AND 1114111)	-- V1.1
        --IF (UNICODE(@NChar) BETWEEN 1 AND 55295) OR (UNICODE(@NChar) BETWEEN 57344 AND 65533) OR (UNICODE(@NChar) BETWEEN 65536 AND 1114111)																									-- V1.1
			BEGIN
				SET @OutputString = @OutputString + @NChar
			END
		
		SET @Position = @Position + 1
    END
    
	RETURN @OutputString
 
END
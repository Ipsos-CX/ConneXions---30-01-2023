CREATE FUNCTION [dbo].[udf_ValidateEmail] (@email VARCHAR(255))
RETURNS BIT
AS
BEGIN
		RETURN
		(
		SELECT 
			CASE 
				WHEN 	@Email IS NULL THEN 0	                	--NULL Email is invalid
				WHEN	CHARINDEX(' ', @email) 	<> 0 OR		--Check for invalid character
						CHARINDEX('/', @email) 	<> 0 OR --Check for invalid character
						CHARINDEX(':', @email) 	<> 0 OR --Check for invalid character
						CHARINDEX(';', @email) 	<> 0 THEN 0 --Check for invalid character
				WHEN LEN(@Email)-1 <= CHARINDEX('.', @Email) THEN 0--check for '%._' at end of string
				WHEN 	@Email LIKE '%@%@%'OR 
						@Email NOT LIKE '%@%.%'  THEN 0--Check for duplicate @ or invalid format
				ELSE 1
			END
		)
END

USE [Sample]
GO

/****** Object:  UserDefinedFunction [dbo].[udf_ValidateEmail]    Script Date: 26/11/2014 11:29:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
GO


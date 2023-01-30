CREATE FUNCTION [Lookup].[udfClearDummyTelephoneNumbers]
(@String dbo.ContactNumber, @Pattern nvarchar(100))
RETURNS dbo.ContactNumber
AS
BEGIN

	SET @String = LTRIM(RTRIM(@String))
	
-- Replace strings that are '000000' Dummy Telephone Number with empty string
	SET @String = ISNULL(NULLIF(@String, @Pattern), N'')

--Return function result
	RETURN(@String)
END

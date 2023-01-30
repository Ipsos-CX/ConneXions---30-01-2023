CREATE FUNCTION [ContactMechanism].[udfGetInlinePostalAddress]
(@ContactMechanismID [dbo].[ContactMechanismID])
RETURNS NVARCHAR (2000)
AS

/*
	Purpose:	returns the postal address based on contactmechanisimid
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created
	1.1				17/09/2012		Pardip Mudhar		BUG 7581 - Check for null values to be replaced by N''

*/

BEGIN
	
	DECLARE @InlinePostalAddress NVARCHAR(2000)
	
	SELECT @InlinePostalAddress =
		LTRIM( RTRIM ( ISNULL ( PA.BuildingName, N'' ))) + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.SubStreetNumber, N'' ))) + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.SubStreet, N'' ))) + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.StreetNumber, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.Street, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.SubLocality, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.Locality, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.Town, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.Region, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( PA.PostCode, N'' )))  + CHAR(13) +
		LTRIM( RTRIM ( ISNULL ( C.Country, N'' ))) 
	FROM ContactMechanism.PostalAddresses PA
	INNER JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
	WHERE PA.ContactMechanismID = @ContactMechanismID
	
	RETURN ISNULL(@InlinePostalAddress, N'')

END


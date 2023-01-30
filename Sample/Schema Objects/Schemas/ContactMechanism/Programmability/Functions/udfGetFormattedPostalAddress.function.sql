CREATE FUNCTION [ContactMechanism].[udfGetFormattedPostalAddress]
(
	@ContactMechanismID dbo.ContactMechanismID
)
RETURNS NVARCHAR (4000)
AS
BEGIN
	
	DECLARE @PostalAddress NVARCHAR(4000)
	
	DECLARE @BuildingName dbo.AddressText
	DECLARE @SubStreetNumber dbo.AddressNumberText
	DECLARE @SubStreet dbo.AddressText
	DECLARE @StreetNumber dbo.AddressNumberText
	DECLARE @Street dbo.AddressText
	DECLARE @SubLocality dbo.AddressText
	DECLARE @Locality dbo.AddressText
	DECLARE @Town dbo.AddressText
	DECLARE @Region dbo.AddressText
	DECLARE @PostCode dbo.PostCode
	DECLARE @Country dbo.Country

	SELECT
		@BuildingName = LTRIM(RTRIM(ISNULL(PA.BuildingName, N''))),
		@SubStreetNumber = LTRIM(RTRIM(ISNULL(PA.SubStreetNumber, N''))),
		@SubStreet = LTRIM(RTRIM(ISNULL(PA.SubStreet, N''))),
		@StreetNumber = LTRIM(RTRIM(ISNULL(PA.StreetNumber, N''))),
		@Street = LTRIM(RTRIM(ISNULL(PA.Street, N''))),
		@SubLocality = LTRIM(RTRIM(ISNULL(PA.SubLocality, N''))),
		@Locality = LTRIM(RTRIM(ISNULL(PA.Locality, N''))),
		@Town = LTRIM(RTRIM(ISNULL(PA.Town, N''))),
		@Region = LTRIM(RTRIM(ISNULL(PA.Region, N''))),
		@PostCode = LTRIM(RTRIM(ISNULL(PA.PostCode, N''))),
		@Country = LTRIM(RTRIM(ISNULL(C.Country, N'')))
	FROM ContactMechanism.PostalAddresses PA
	INNER JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
	WHERE PA.ContactMechanismID = @ContactMechanismID


	SET @PostalAddress = 
	CASE WHEN LEN(@BuildingName) > 0 THEN @BuildingName + ', ' ELSE N'' END + 
	CASE WHEN LEN(@SubStreetNumber) > 0 THEN @SubStreetNumber + ', ' ELSE N'' END + 
	CASE WHEN LEN(@SubStreet) > 0 THEN @SubStreet + ', ' ELSE N'' END + 
	CASE WHEN LEN(@StreetNumber) > 0 THEN @StreetNumber + ', ' ELSE N'' END + 
	CASE WHEN LEN(@Street) > 0 THEN @Street + ', ' ELSE N'' END + 
	CASE WHEN LEN(@SubLocality) > 0 THEN @SubLocality + ', ' ELSE N'' END + 
	CASE WHEN LEN(@Locality) > 0 THEN @Locality + ', ' ELSE N'' END +
	CASE WHEN LEN(@Town) > 0 THEN @Town + ', ' ELSE N'' END +
	CASE WHEN LEN(@Region) > 0 THEN @Region + ', ' ELSE N'' END +
	CASE WHEN LEN(@PostCode) > 0 THEN @PostCode + ', ' ELSE N'' END +
	CASE WHEN LEN(@Country) > 0 THEN @Country + ', ' ELSE N'' END
	
	-- IF WE'VE GOT SOME DATA REMOVE THE COMMA AT THE END
	IF LEN(@PostalAddress) > 0
	BEGIN
		SET @PostalAddress = SUBSTRING(LTRIM(RTRIM(ISNULL(@PostalAddress, N''))), 1, LEN(@PostalAddress) - 1)
	END
	
	RETURN @PostalAddress

END
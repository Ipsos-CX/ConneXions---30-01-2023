CREATE FUNCTION dbo.udfGenerateAddressChecksum 
(
	 @BuildingName dbo.AddressText
	,@SubStreetNumber dbo.AddressNumberText
	,@SubStreet dbo.AddressText
	,@StreetNumber dbo.AddressNumberText
	,@Street dbo.AddressText
	,@SubLocality dbo.AddressText
	,@Locality dbo.AddressText
	,@Town dbo.AddressText
	,@Region dbo.AddressText
	,@PostCode dbo.Postcode
	,@CountryID dbo.CountryID
)
RETURNS BIGINT
AS
BEGIN
	
	DECLARE @AddressChecksum BIGINT
	
	-- WE GENERATE THE CHECK DIFFERENTLY FOR THE UK THAN OTHER MARKETS
	IF @CountryID = (SELECT CountryID FROM ContactMechanism.Countries WHERE Country = 'United Kingdom')
	BEGIN
		-- IF WE HAVE NO STREET NUMBER THEN USE THE BUILDING NAME / POSTCODE TO IDENTIFY AN ADDRESS. WE WOULDN'T USE
		-- THE BUILDING NAME IF WE HAD A STREET NUMBER WITHIN A POSTCODE BECAUSE WE SHOULDN'T GET A RECURRANCE OF STREET
		-- NUMBER BUT COULD GET A RECURRENCE OF BUILDING NAME. 
		IF (LEN(ISNULL(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), '')) = 0 AND
						ISNULL(LEN(@BuildingName), 0) > 0 AND
						ISNULL(LEN(REPLACE(@PostCode, ' ', '')), 0) > 0)
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(@BuildingName, @PostCode)
		END
		--STANDARD STREET NUMBER POSTCODE MATCH
		ELSE IF (LEN(ISNULL(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), '')) > 0 AND
						ISNULL(LEN(REPLACE(@PostCode, ' ', '')), 0) > 0)
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), REPLACE(@Postcode, ' ', ''))
		END
		--IF WE HAVE NO STREET NUMBER THEN USE STREET NAME AND POSTCODE
		ELSE IF (LEN(ISNULL(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), '')) = 0 AND
						LEN(ISNULL(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, '')), '')) > 0 AND
						ISNULL(LEN(REPLACE(@PostCode, ' ', '')), 0) > 0)
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(dbo.udfRemovePunctuation(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, ''))), REPLACE(@PostCode, ' ', ''))
		END
		-- DEFAULT CHECKSUM
		ELSE
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(	
								ISNULL(@BuildingName, ''),
								ISNULL(@SubStreetNumber, ''),
								dbo.udfRemovePunctuation(ISNULL(@SubStreet, '')),
								ISNULL(@StreetNumber, ''),
								dbo.udfRemovePunctuation(ISNULL(@Street, '')),
								ISNULL(@SubLocality, ''),
								ISNULL(@Locality, ''),
								ISNULL(@Town, ''),
								ISNULL(@Region, ''),
								ISNULL(@Postcode, '')
							)
		END
	END
	ELSE
	BEGIN
		IF (LEN(ISNULL(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), '')) = 0 AND
						ISNULL(LEN(@BuildingName), 0) > 0 AND
						LEN(ISNULL(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, '')), '')) > 0 AND
						ISNULL(LEN(REPLACE(@PostCode, ' ', '')), 0) > 0)
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(@BuildingName, dbo.udfRemovePunctuation(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, ''))), @PostCode)
		END
		ELSE IF (LEN(ISNULL(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), '')) > 0 AND
						LEN(ISNULL(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, '')), '')) > 0 AND
						ISNULL(LEN(REPLACE(@PostCode, ' ', '')), 0) > 0)
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), dbo.udfRemovePunctuation(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, ''))), REPLACE(@Postcode, ' ', ''))
		END
		ELSE IF (LEN(ISNULL(COALESCE(NULLIF(@SubStreetNumber, ''), NULLIF(@StreetNumber, '')), '')) = 0 AND
						LEN(ISNULL(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, '')), '')) > 0 AND
						ISNULL(LEN(REPLACE(@PostCode, ' ', '')), 0) > 0)
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(dbo.udfRemovePunctuation(COALESCE(NULLIF(@SubStreet, ''), NULLIF(@Street, ''))), REPLACE(@PostCode, ' ', ''))
		END
		ELSE 
		BEGIN
			SELECT @AddressChecksum = CHECKSUM(	
								ISNULL(@BuildingName, ''),
								ISNULL(@SubStreetNumber, ''),
								dbo.udfRemovePunctuation(ISNULL(@SubStreet, '')),
								ISNULL(@StreetNumber, ''),
								dbo.udfRemovePunctuation(ISNULL(@Street, '')),
								ISNULL(@SubLocality, ''),
								ISNULL(@Locality, ''),
								ISNULL(@Town, ''),
								ISNULL(@Region, ''),
								ISNULL(@Postcode, '')
							)
		END
	END
	
	-- Return the result of the function
	RETURN @AddressChecksum

END
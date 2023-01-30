CREATE PROCEDURE CustomerUpdate.uspPostalAddress_Transform

AS

/*
	Purpose:	Work out which address fields to stored in which column in the PostalAddresses table

	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspIP_CUSTOMERUPDATE_Transform_PostalAddress

*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	BEGIN TRAN


		-- CALCULATE HOW MANY FIELDS FROM Address1 TO Address7 HAVE BEEN FILLED IN
		-- AND DEPENDING ON THE NUMBER PUT THE FILLED FIELDS INTO THE APPROPRIATE COLUMN

		DECLARE @NumRows INT
		DECLARE @Counter INT
		DECLARE @NumFields INT
		DECLARE @AddressString NVARCHAR(4000)
		DECLARE @Field1Extracted NVARCHAR(440)
		DECLARE @Field2Extracted NVARCHAR(440)
		DECLARE @Field3Extracted NVARCHAR(440)
		DECLARE @Field4Extracted NVARCHAR(440)
		DECLARE @Field5Extracted NVARCHAR(440)
		DECLARE @Field6Extracted NVARCHAR(440)
		DECLARE @Field7Extracted NVARCHAR(440)

		SET @Counter = 1
		SELECT @NumRows = MAX(ID) FROM CustomerUpdate.PostalAddress

		WHILE @Counter <= @NumRows
		BEGIN
			
			SET @NumFields = 0
			SET @AddressString = ''
			
			IF (SELECT LEN(ISNULL(Address1, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address1 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			IF (SELECT LEN(ISNULL(Address2, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address2 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			IF (SELECT LEN(ISNULL(Address3, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address3 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			IF (SELECT LEN(ISNULL(Address4, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address4 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			IF (SELECT LEN(ISNULL(Address5, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address5 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			IF (SELECT LEN(ISNULL(Address6, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address6 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			IF (SELECT LEN(ISNULL(Address7, '')) FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter) > 0
			BEGIN
				SET @NumFields = @NumFields + 1
				SELECT @AddressString = @AddressString + Address7 + '|' FROM CustomerUpdate.PostalAddress WHERE [ID] = @Counter
			END
			
			-- IF @NumFields IS 1 WE WILL ASSUME STREET
			IF @NumFields = 1
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				UPDATE CustomerUpdate.PostalAddress
				SET StreetAndNumber = @Field1Extracted
				WHERE [ID] = @Counter
			END

			-- IF @NumFields IS 2 WE WILL ASSUME STREET AND TOWN
			IF @NumFields = 2
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field2Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				UPDATE CustomerUpdate.PostalAddress
				SET StreetAndNumber = @Field1Extracted,
				Town = @Field2Extracted
				WHERE [ID] = @Counter
			END

			-- IF @NumFields IS 3 WE WILL ASSUME STREET, TOWN AND REGION
			IF @NumFields = 3
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field2Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field3Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				UPDATE CustomerUpdate.PostalAddress
				SET StreetAndNumber = @Field1Extracted,
				Town = @Field2Extracted,
				Region = @Field3Extracted
				WHERE [ID] = @Counter
			END

			-- IF @NumFields IS 4 WE WILL CHECK IF THERE ARE DIGITS IN THE FIRST FILLED FIELD ONLY, IF SO, WE WILL ASSUME STREET, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 4 WE WILL CHECK IF THERE ARE DIGITS IN THE SECOND FILLED FIELD ONLY, IF SO, WE WILL ASSUME BUILDINGNAME, STREET, TOWN, REGION
			-- IF @NumFields IS 4 WE WILL CHECK IF THERE ARE DIGITS IN BOTH THE FIRST AND SECOND FILLED FIELDS, IF SO, WE WILL ASSUME SUBSTREET, STREET, TOWN, REGION
			-- IF @NumFields IS 4 WE WILL CHECK IF THERE ARE DIGITS IN BOTH THE SECOND AND THIRD FILLED FIELDS, IF SO, WE WILL ASSUME BUILDINGNAME, SUBSTREET, STREET, TOWN
			-- OTHERWISE, WE WILL ASSUME STREET, LOCALITY, TOWN, REGION
			IF @NumFields = 4
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field2Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field3Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field4Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				IF @Field1Extracted LIKE '%[0-9]%' AND @Field2Extracted NOT LIKE '%[0-9]%'
				BEGIN
					UPDATE CustomerUpdate.PostalAddress
					SET StreetAndNumber = @Field1Extracted,
					Locality = @Field2Extracted,
					Town = @Field3Extracted,
					Region = @Field4Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field2Extracted LIKE '%[0-9]%' AND @Field3Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET BuildingName = @Field1Extracted,
					SubStreetAndNumber = @Field2Extracted,
					StreetAndNumber = @Field3Extracted,
					Town = @Field4Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field1Extracted NOT LIKE '%[0-9]%' AND @Field2Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET BuildingName = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,
					Town = @Field3Extracted,
					Region = @Field4Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field1Extracted LIKE '%[0-9]%' AND @Field2Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET SubStreetAndNumber = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,
					Town = @Field3Extracted,
					Region = @Field4Extracted
					WHERE [ID] = @Counter
				END
				ELSE
				BEGIN
					UPDATE CustomerUpdate.PostalAddress
					SET StreetAndNumber = @Field1Extracted,
					Locality = @Field2Extracted,
					Town = @Field3Extracted,
					Region = @Field4Extracted
					WHERE [ID] = @Counter
				END
			END

			-- IF @NumFields IS 5 WE WILL CHECK IF THERE ARE DIGITS IN THE FIRST FILLED FIELD ONLY, IF SO, WE WILL ASSUME STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 5 WE WILL CHECK IF THERE ARE DIGITS IN THE SECOND FILLED FIELD ONLY, IF SO, WE WILL ASSUME BUILDINGNAME, STREET, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 5 WE WILL CHECK IF THERE ARE DIGITS IN BOTH THE FIRST AND SECOND FILLED FIELDS, IF SO, WE WILL ASSUME SUBSTREET, STREET, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 5 WE WILL CHECK IF THERE ARE DIGITS IN BOTH THE SECOND AND THIRD FILLED FIELDS, IF SO, WE WILL ASSUME BUILDINGNAME, SUBSTREET, STREET, TOWN, REGION
			-- OTHERWISE, WE WILL ASSUME STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			IF @NumFields = 5
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field2Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field3Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field4Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field5Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				IF @Field1Extracted LIKE '%[0-9]%' AND @Field2Extracted NOT LIKE '%[0-9]%'
				BEGIN
					UPDATE CustomerUpdate.PostalAddress
					SET StreetAndNumber = @Field1Extracted,
					SubLocality = @Field2Extracted,
					Locality = @Field3Extracted,
					Town = @Field4Extracted,
					Region = @Field5Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field2Extracted LIKE '%[0-9]%' AND @Field3Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET BuildingName = @Field1Extracted,
					SubStreetAndNumber = @Field2Extracted,
					StreetAndNumber = @Field3Extracted,
					Town = @Field4Extracted,
					Region = @Field5Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field1Extracted NOT LIKE '%[0-9]%' AND @Field2Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET BuildingName = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,
					Locality = @Field3Extracted,
					Town = @Field4Extracted,
					Region = @Field5Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field1Extracted LIKE '%[0-9]%' AND @Field2Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET SubStreetAndNumber = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,
					Locality = @Field3Extracted,
					Town = @Field4Extracted,
					Region = @Field5Extracted
					WHERE [ID] = @Counter
				END
				ELSE
				BEGIN
					UPDATE CustomerUpdate.PostalAddress
					SET StreetAndNumber = @Field1Extracted,
					SubLocality = @Field2Extracted,
					Locality = @Field3Extracted,
					Town = @Field4Extracted,
					Region = @Field5Extracted
					WHERE [ID] = @Counter
				END
			END

			-- IF @NumFields IS 6 WE WILL CHECK IF THERE ARE DIGITS IN THE FIRST FILLED FIELD ONLY, IF SO, WE WILL ASSUME SUBSTREET, STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 6 WE WILL CHECK IF THERE ARE DIGITS IN THE SECOND FILLED FIELD ONLY, IF SO, WE WILL ASSUME BUILDINGNAME, STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 6 WE WILL CHECK IF THERE ARE DIGITS IN BOTH THE FIRST AND SECOND FILLED FIELDS, IF SO, WE WILL ASSUME SUBSTREET, STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			-- IF @NumFields IS 6 WE WILL CHECK IF THERE ARE DIGITS IN BOTH THE SECOND AND THIRD FILLED FIELDS, IF SO, WE WILL ASSUME BUILDINGNAME, SUBSTREET, STREET, LOCALITY, TOWN, REGION
			-- OTHERWISE, WE WILL ASSUME SUBSTREET, STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			IF @NumFields = 6
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field2Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field3Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field4Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field5Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field6Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				IF @Field1Extracted LIKE '%[0-9]%' AND @Field2Extracted NOT LIKE '%[0-9]%'
				BEGIN
					UPDATE CustomerUpdate.PostalAddress
					SET SubStreetAndNumber = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,		
					SubLocality = @Field3Extracted,
					Locality = @Field4Extracted,
					Town = @Field5Extracted,
					Region = @Field6Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field2Extracted LIKE '%[0-9]%' AND @Field3Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET BuildingName = @Field1Extracted,
					SubStreetAndNumber = @Field2Extracted,
					StreetAndNumber = @Field3Extracted,
					Locality = @Field4Extracted,
					Town = @Field5Extracted,
					Region = @Field6Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field1Extracted NOT LIKE '%[0-9]%' AND @Field2Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET BuildingName = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,
					SubLocality = @Field3Extracted,
					Locality = @Field4Extracted,
					Town = @Field5Extracted,
					Region = @Field6Extracted
					WHERE [ID] = @Counter
				END
				ELSE IF @Field1Extracted LIKE '%[0-9]%' AND @Field2Extracted LIKE '%[0-9]%'
				BEGIN			
					UPDATE CustomerUpdate.PostalAddress
					SET SubStreetAndNumber = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,
					SubLocality = @Field3Extracted,
					Locality = @Field4Extracted,
					Town = @Field5Extracted,
					Region = @Field6Extracted
					WHERE [ID] = @Counter
				END
				ELSE
				BEGIN
					UPDATE CustomerUpdate.PostalAddress
					SET SubStreetAndNumber = @Field1Extracted,
					StreetAndNumber = @Field2Extracted,		
					SubLocality = @Field3Extracted,
					Locality = @Field4Extracted,
					Town = @Field5Extracted,
					Region = @Field6Extracted
					WHERE [ID] = @Counter
				END
			END

			-- IF @NumFields IS 7 WE WILL ASSUME BUILDINGNAME, SUBSTREET, STREET, SUBLOCALITY, LOCALITY, TOWN, REGION
			IF @NumFields = 7
			BEGIN
				SELECT @Field1Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field2Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field3Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field4Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field5Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field6Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)
				SELECT @AddressString = RIGHT(@AddressString, LEN(@AddressString) - CHARINDEX('|', @AddressString))

				SELECT @Field7Extracted = SUBSTRING(@AddressString, 1, CHARINDEX('|', @AddressString) - 1)

				UPDATE CustomerUpdate.PostalAddress
				SET BuildingName = @Field1Extracted,
				SubStreetAndNumber = @Field2Extracted,
				StreetAndNumber = @Field3Extracted,		
				SubLocality = @Field4Extracted,
				Locality = @Field5Extracted,
				Town = @Field6Extracted,
				Region = @Field7Extracted
				WHERE [ID] = @Counter
			END
			
			SET @Counter = @Counter + 1

		END


		EXEC CustomerUpdate.uspPostalAddress_ExtractSubStreetNumber
		EXEC CustomerUpdate.uspPostalAddress_ExtractStreetNumber

	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

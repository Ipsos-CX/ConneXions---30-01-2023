CREATE PROCEDURE [China].[uspLoadRoadsideToVWT]

AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


SET LANGUAGE ENGLISH
SET DATEFORMAT DMY


BEGIN TRY


	DECLARE @UKCountryID int
	SELECT	@UKCountryID = CountryID									--v1.2
	FROM	[$(SampleDB)].ContactMechanism.Countries c 
	WHERE	c.Country = 'United Kingdom'

	BEGIN TRAN

		INSERT INTO dbo.VWT 
		(
			RoadsideID, 
			AuditID, 
			PhysicalFileRow, 
			ManufacturerID, 
			SampleSupplierPartyID, 
			ODSEventTypeID, 
			RoadsideNetworkOriginatorPartyID,
			RoadsideNetworkCode, 
			RoadsideDateOrig, 
			RoadsideDate,
		
			CustomerIdentifier,
			CustomerIdentifierUsable,
			CustomerIdentifierOriginatorPartyID,	-- v1.3
		
			OrganisationNameOrig,
			Title,
			FirstName, 
			LastName, 
			SecondLastName,
			StreetAndNumberOrig ,
			StreetOrig,						-- v1.2
			Street,							-- v1.2
			SubLocality,
			Locality,
			Town,
			Region,
			Postcode,
			Country ,
			CountryID,
			Tel,
			MobileTel,
			ModelDescription,
			BuildYear,
			VehicleIdentificationNumber,
			VehicleIdentificationNumberUsable,
			VehicleRegistrationNumber,
			RegistrationDateOrig,
			RegistrationDate,
			EmailAddress,
			PrivEmailAddress,				-- v1.6
			LanguageID,
			PartySuppression,
			EmailSuppression,
			PostalSuppression,
			OwnershipCycle,
			GenderID,
			SampleTriggeredSelectionReqID	
		)
		SELECT 
			ID,
			AuditID,
			PhysicalFileRow,
			ManufacturerID,
			SampleSupplierPartyID,
			EventTypeID,
			RoadsideNetworkOriginatorPartyID,
			RoadsideNetworkCode, 
			RoadsideDateOrig, 
			RoadsideDate,
	
			CustomerUniqueId,
			CustIDUsable,
			CustomerIdentifierOriginatorPartyID,			--v1.3
			CompanyName, 
			Title, 
			Firstname, 
			SurnameField1, 
			SurnameField2,
			CASE WHEN CountryID = @UKCountryID THEN Address1 ELSE '' END AS StreetAndNumberOrig,  --v1.2
			CASE WHEN CountryID = @UKCountryID THEN '' ELSE Address1 END AS StreetOrig,			  --v1.2
			CASE WHEN CountryID = @UKCountryID THEN '' ELSE Address1 END AS Street,				  --v1.2
			Address2 AS SubLocality,
			RTRIM(RTRIM(Address3) + ' ' + Address4) AS Locality,
			[Address5] AS Town,
			[Address6] as Region,
			[Address7],
			[Address8],
			CountryID, 
			HomeTelephoneNumber, 
			MobileTelephoneNumber, 
			ModelName, 
			CASE WHEN ISNUMERIC(ModelYear) = 1 THEN ModelYear ELSE '' END AS ModelYear,		--v1.4 
			VIN, 
			CASE WHEN LEN(ISNULL(VIN, '')) = 17 THEN 1 ELSE 0 END AS VehicleIdentificationNumberUsable,
			RegistrationNumber, 
			VehicleRegistrationDateOrig,
			CASE WHEN ISDATE(VehicleRegistrationDateOrig) = 1 
						THEN CONVERT ( datetime, VehicleRegistrationDateOrig, 103 ) 
						ELSE NULL END AS VehicleRegistrationDate,
			EmailAddress1 AS EmailAddress,				-- v1.6
			EmailAddress2 AS PrivEmailAddress,			-- v1.6
			LanguageID,   
			CASE WHEN RTRIM(LTRIM(CompleteSuppression)) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS CompleteSuppression, 
			CASE WHEN RTRIM(LTRIM([SuppressionEmail])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionEmail, 
			CASE WHEN RTRIM(LTRIM([SuppressionMail]))  = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionMail, 
			OwnershipCycle,
			CASE WHEN SUBSTRING(Gender, 1,1) = 'M' THEN 1 
				 WHEN SUBSTRING(Gender, 1,1) = 'F' THEN 2 
				 ELSE 0 END AS GenderID,
			SampleTriggeredSelectionReqID	
		FROM China.vwFullRoadsideLoadToVWT
		ORDER BY AuditID, ID
	
		------------------------------------------------------------------------------------------
		-- Update the transferred to VWT flag
		------------------------------------------------------------------------------------------
		
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		UPDATE		s
		SET			s.[DateTransferredToVWT] = @Date
		FROM		dbo.VWT v
		INNER JOIN [China].[Roadside_WithResponses] s ON s.AuditID = v.AuditID AND s.PhysicalRowID = v.PhysicalFileRow 
	
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
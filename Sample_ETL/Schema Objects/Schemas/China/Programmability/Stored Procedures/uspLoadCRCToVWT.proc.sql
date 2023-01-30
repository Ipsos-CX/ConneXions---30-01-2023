CREATE PROCEDURE [China].[uspLoadCRCToVWT]
/*
	Purpose:		Copy China CRC with response records that need a CaseID's to the VWT for loading.
	
	Version			Date			Developer			Comment
	1.0				16/03/2018		Eddie Thomas		Created from Sample_ETL.CRC.uspLoadToVWT.proc.sql


*/
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


------------------------------------------------------------------------------------------
-- Get dummy CRC vehicles for when no VIN is supplied
------------------------------------------------------------------------------------------


DECLARE @JagCRCVehicleID  int,
		@JagCRCModelID	  int,
		@LR_CRCVehicleID  int,
		@LR_CRCModelID	  int

SELECT @JagCRCVehicleID = VehicleID ,
	   @JagCRCModelID = ModelID
FROM [$(SampleDB)].Vehicle.Vehicles
WHERE VIN = 'SAJ_CRC_Unknown_V'
	
SELECT @LR_CRCVehicleID = VehicleID ,
	   @LR_CRCModelID = ModelID 
FROM [$(SampleDB)].Vehicle.Vehicles
WHERE VIN = 'SAL_CRC_Unknown_V'





------------------------------------------------------------------------------------------
-- Copy records (not already transfered) to the VWT 
------------------------------------------------------------------------------------------

	DECLARE @UKCountryID int
	SELECT @UKCountryID = CountryID									
			from [$(SampleDB)].ContactMechanism.Countries c 
			where c.Country = 'United Kingdom'


	INSERT INTO dbo.VWT 
	(
		CRC_ID, 
		AuditID, 
		PhysicalFileRow, 
		ManufacturerID, 
		SampleSupplierPartyID, 
		ODSEventTypeID, 
		CRCCentreOriginatorPartyID,
		CRCCentreCode, 
		CRCDateOrig, 
		CRCDate,
		
		CustomerIdentifier,
		CustomerIdentifierUsable,
		CustomerIdentifierOriginatorPartyID,	
		
		OrganisationNameOrig,
		Title,
		FirstName, 
		LastName, 
		StreetAndNumberOrig ,
		StreetOrig,						
		Street,							
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
		VehicleIdentificationNumber,
		VehicleIdentificationNumberUsable,
		VehicleRegistrationNumber,
		EmailAddress,
		LanguageID,
		GenderID,
		MatchedODSVehicleID,
		MatchedODSModelID,
		SampleTriggeredSelectionReqID					-- v1.2
	)
	SELECT 
		v.ID,
		v.AuditID,
		v.PhysicalFileRow,
		v.ManufacturerID AS ManufacturerPartyID,
		v.SampleSupplierPartyID,
		v.EventTypeID,
		v.CRCCentreOriginatorPartyID,
		v.CRCCentreCode, 
		v.CRCDateOrig, 
		v.CRCDate,
	
		v.UniqueCustomerId,
		v.CustIDUsable,
		v.CustomerIdentifierOriginatorPartyID,			
		v.CompanyName, 
		v.CustomerTitle, 
		v.CustomerFirstname, 
		v.CustomerLastName, 
		CASE WHEN v.CountryID = @UKCountryID THEN v.AddressLine1 ELSE '' END AS StreetAndNumberOrig, 
		CASE WHEN v.CountryID = @UKCountryID THEN '' ELSE v.AddressLine1 END AS StreetOrig,			 
		CASE WHEN v.CountryID = @UKCountryID THEN '' ELSE v.AddressLine1 END AS Street,				  
		AddressLine2 AS SubLocality,
		RTRIM(RTRIM(v.AddressLine3) + ' ' + v.AddressLine4) AS Locality,
		v.AddressLine5,
		v.AddressLine6,
		v.AddressLine7,
		v.AddressLine8,
		v.CountryID, 
		v.PhoneHome, 
		v.PhoneMobile, 
		v.VehicleModel, 
		v.VIN, 
		CASE WHEN LEN(ISNULL(v.VIN, '')) = 17 THEN 1 ELSE 0 END AS VehicleIdentificationNumberUsable,
		CASE WHEN ISNULL(v.VIN, '') <> ''	THEN v.VehicleRegNumber					-- We only set the VehicleRegNumber if a VIN +has+ been supplied
			 ELSE NULL  END AS VehicleRegNumber,
		v.EmailAddress,
		v.PreferredLanguageID,   
		CASE WHEN SUBSTRING(v.Gender, 1,1) = 'M' THEN 1 
			 WHEN SUBSTRING(v.Gender, 1,1) = 'F' THEN 2 
			 ELSE 0 END AS GenderID,
		CASE WHEN ISNULL(v.VIN, '') <> ''			THEN 0					-- We only set the MatchedODSVehicleID if a VIN hasn't been supplied
			 WHEN b.Brand = 'Jaguar'		THEN @JagCRCVehicleID
			 WHEN b.Brand = 'Land Rover'	THEN @LR_CRCVehicleID
			 ELSE 0  END AS MatchedODSVehicleID,
		CASE WHEN ISNULL(v.VIN, '') <> ''			THEN 0					-- We only set the MatchedODSModelID if a VIN hasn't been supplied
			 WHEN b.Brand = 'Jaguar'		THEN @JagCRCModelID
			 WHEN b.Brand = 'Land Rover'	THEN @LR_CRCModelID
			 ELSE 0  END AS MatchedODSModelID,
		v.SampleTriggeredSelectionReqID							--v1.2
		FROM [China].[vwLoadCRCToVWT] v
		INNER JOIN [$(SampleDB)].dbo.Brands b ON b.ManufacturerPartyID = v.ManufacturerID
		ORDER BY AuditID, ID
	
		------------------------------------------------------------------------------------------
		-- Update the transferred to VWT flag
		------------------------------------------------------------------------------------------
		
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		UPDATE s
		SET s.[DateTransferredToVWT] = @Date
		FROM dbo.VWT v
		INNER JOIN [China].[CRC_WithResponses] s ON s.AuditID = v.AuditID
													AND s.PhysicalRowID = v.PhysicalFileRow 
		
	
END TRY
BEGIN CATCH

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
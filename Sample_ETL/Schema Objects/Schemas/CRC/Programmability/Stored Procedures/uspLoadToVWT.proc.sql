
CREATE PROCEDURE [CRC].[uspLoadToVWT]

AS

/*
	Purpose:	Transfers rows to VWT from CRCEvents that have not previously been transferred.
				Also populates the VIN with the appropriate CRC 'Unknown' vehicle where VIN is blank.
	
	Version			Date			Developer			Comment
	1.0				24-09-2014		Chris Ross			Created
	1.1				23-04-2015		Chris Ross			Only set the VehicleRegNumber if a VIN +has+ been supplied
	1.2				18-05-2015		Chris Ross			Add SampleTriggeredSelectionReqID column for loading into VWT
	1.3				04-06-2018		Chris Ledger		BUG 14721: Add Suppression fields and logic for Company Name
	1.4				10-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases
*/

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
from [$(SampleDB)].Vehicle.Vehicles
where VIN = 'SAJ_CRC_Unknown_V'
	
SELECT @LR_CRCVehicleID = VehicleID ,
	   @LR_CRCModelID = ModelID 
from [$(SampleDB)].Vehicle.Vehicles
where VIN = 'SAL_CRC_Unknown_V'





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
		SampleTriggeredSelectionReqID,					-- v1.2
		PartySuppression,								-- V1.3
		EmailSuppression,								-- V1.3
		PhoneSuppression,								-- V1.3
		PostalSuppression								-- V1.3
	)
	SELECT 
		v.CRC_ID,
		v.AuditID,
		v.PhysicalFileRow,
		v.ManufacturerPartyID,
		v.SampleSupplierPartyID,
		v.EventTypeID,
		v.CRCCentreOriginatorPartyID,
		v.CRCCentreCode, 
		v.CRCDateOrig, 
		v.CRCDate,
	
		v.UniqueCustomerId,
		v.CustIDUsable,
		v.CustomerIdentifierOriginatorPartyID,			
		CASE WHEN v.CustomerFirstname + ' ' + v.CustomerLastName LIKE '%' + v.CompanyName + '%' THEN '' ELSE v.CompanyName END AS CompanyName,	-- V1.3 Don't Load Company Name if Same as Customer Name 
		v.CustomerTitle,  
		v.CustomerFirstname, 
		v.CustomerLastName, 
		CASE WHEN v.CountryID = @UKCountryID THEN v.AddressLine1 ELSE '' END AS StreetAndNumberOrig, 
		CASE WHEN v.CountryID = @UKCountryID THEN '' ELSE v.AddressLine1 END AS StreetOrig,			 
		CASE WHEN v.CountryID = @UKCountryID THEN '' ELSE v.AddressLine1 END AS Street,				  
		AddressLine2 AS SubLocality,
		RTRIM(RTRIM(v.AddressLine3) + ' ' + v.AddressLine4) AS Locality,
		v.City,
		v.County,
		v.PostalCode,
		v.Country,
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
		v.SampleTriggeredSelectionReqID,						-- V1.2
		CASE WHEN UPPER(v.COMPLETE_SUPPRESSION) = 'YES' THEN 'True' ELSE 'False' END AS COMPLETE_SUPPRESSION,				-- V1.3
		CASE WHEN UPPER(v.SUPPRESSION_EMAIL) = 'YES' THEN 'True' ELSE 'False' END AS SUPPRESSION_EMAIL,						-- V1.3
		CASE WHEN UPPER(v.SUPPRESSION_PHONE) = 'YES' THEN 'True' ELSE 'False' END AS SUPPRESSION_PHONE,						-- V1.3
		CASE WHEN UPPER(v.SUPPRESSION_MAIL) = 'YES' THEN 'True' ELSE 'False' END AS	SUPPRESSION_MAIL						-- V1.3
	FROM CRC.vwLoadToVWT v
	INNER JOIN [$(SampleDB)].dbo.Brands b ON b.ManufacturerPartyID = v.ManufacturerPartyID
	ORDER BY CRC_ID
	
	
	
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
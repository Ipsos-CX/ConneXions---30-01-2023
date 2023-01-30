CREATE PROCEDURE [GeneralEnquiry].[uspLoadToVWT]

AS

/*
	Purpose:	Transfers rows to VWT FROM GeneralEnquiryEvents that have not previously been transferred.
				Also populates the VIN with the appropriate GeneralEnquiry 'Unknown' vehicle WHERE VIN is blank.
	
	Version			Date			Developer			Comment
	1.0				2021-03-16		Chris Ledger		Created
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
-- Get dummy GeneralEnquiery vehicles for when no VIN is supplied
------------------------------------------------------------------------------------------
DECLARE @JagGeneralEnquiryVehicleID	INT,
	@JagGeneralEnquiryModelID	INT,
	@LRGeneralEnquiryVehicleID	INT,
	@LRGeneralEnquiryModelID	INT

SELECT @JagGeneralEnquiryVehicleID = VehicleID,
	@JagGeneralEnquiryModelID = ModelID
FROM [$(SampleDB)].Vehicle.Vehicles
WHERE VIN = 'SAJ_CRC_Unknown_V'
	
SELECT @LRGeneralEnquiryVehicleID = VehicleID, 
	@LRGeneralEnquiryModelID = ModelID 
FROM [$(SampleDB)].Vehicle.Vehicles
WHERE VIN = 'SAL_CRC_Unknown_V'





------------------------------------------------------------------------------------------
-- Copy records (not already transfered) to the VWT 
------------------------------------------------------------------------------------------
	DECLARE @UKCountryID INT
	
	SELECT @UKCountryID = CountryID									
	FROM [$(SampleDB)].ContactMechanism.Countries C 
	WHERE C.Country = 'United Kingdom'


	INSERT INTO dbo.VWT 
	(
		GeneralEnquiryID, 
		AuditID, 
		PhysicalFileRow, 
		ManufacturerID, 
		SampleSupplierPartyID, 
		ODSEventTypeID, 
		CRCCentreOriginatorPartyID,
		CRCCentreCode, 
		GeneralEnquiryDateOrig, 
		GeneralEnquiryDate,
		
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
		SampleTriggeredSelectionReqID,
		PartySuppression,
		EmailSuppression,
		PhoneSuppression,
		PostalSuppression
	)
	SELECT 
		V.GeneralEnquiryID,
		V.AuditID,
		V.PhysicalFileRow,
		V.ManufacturerPartyID,
		V.SampleSupplierPartyID,
		V.EventTypeID,
		V.CRCCentreOriginatorPartyID,
		V.CRCCentreCode, 
		V.GeneralEnquiryDateOrig, 
		V.GeneralEnquiryDate,
		V.UniqueCustomerID,
		V.CustIDUsable,
		V.CustomerIdentifierOriginatorPartyID,			
		CASE	WHEN V.CustomerFirstname + ' ' + V.CustomerLastName LIKE '%' + V.CompanyName + '%' THEN '' 
				ELSE V.CompanyName END AS CompanyName, 
		V.CustomerTitle,  
		V.CustomerFirstname, 
		V.CustomerLastName, 
		CASE	WHEN V.CountryID = @UKCountryID THEN V.AddressLine1 
				ELSE '' END AS StreetAndNumberOrig, 
		CASE	WHEN V.CountryID = @UKCountryID THEN '' 
				ELSE V.AddressLine1 END AS StreetOrig,			 
		CASE	WHEN V.CountryID = @UKCountryID THEN '' 
				ELSE V.AddressLine1 END AS Street,				  
		AddressLine2 AS SubLocality,
		RTRIM(RTRIM(V.AddressLine3) + ' ' + V.AddressLine4) AS Locality,
		V.City,
		V.County,
		V.PostalCode,
		V.Country,
		V.CountryID, 
		V.PhoneHome, 
		V.PhoneMobile, 
		V.VehicleModel, 
		V.VIN, 
		CASE	WHEN LEN(ISNULL(V.VIN, '')) = 17 THEN 1 
				ELSE 0 END AS VehicleIdentificationNumberUsable,
		CASE	WHEN ISNULL(V.VIN, '') <> '' THEN V.VehicleRegNumber			-- We only set the VehicleRegNumber if a VIN +has+ been supplied
				ELSE NULL END AS VehicleRegNumber,
		V.EmailAddress,
		V.PreferredLanguageID,   
		CASE WHEN SUBSTRING(V.Gender, 1,1) = 'M' THEN 1 
			 WHEN SUBSTRING(V.Gender, 1,1) = 'F' THEN 2 
			 ELSE 0 END AS GenderID,
		CASE WHEN ISNULL(V.VIN, '') <> '' THEN 0							-- We only set the MatchedODSVehicleID if a VIN hasn't been supplied
			 WHEN B.Brand = 'Jaguar' THEN @JagGeneralEnquiryVehicleID
			 WHEN B.Brand = 'Land Rover' THEN @LRGeneralEnquiryVehicleID
			 ELSE 0 END AS MatchedODSVehicleID,
		CASE WHEN ISNULL(V.VIN, '') <> '' THEN 0							-- We only set the MatchedODSModelID if a VIN hasn't been supplied
			 WHEN B.Brand = 'Jaguar' THEN @JagGeneralEnquiryModelID
			 WHEN B.Brand = 'Land Rover' THEN @LRGeneralEnquiryModelID
			 ELSE 0 END AS MatchedODSModelID,
		V.SampleTriggeredSelectionReqID,	
		CASE	WHEN UPPER(V.COMPLETE_SUPPRESSION) = 'YES' THEN 'True' 
				ELSE 'False' END AS COMPLETE_SUPPRESSION,
		CASE	WHEN UPPER(V.SUPPRESSION_EMAIL) = 'YES' THEN 'True' 
				ELSE 'False' END AS SUPPRESSION_EMAIL,
		CASE	WHEN UPPER(V.SUPPRESSION_PHONE) = 'YES' THEN 'True' 
				ELSE 'False' END AS SUPPRESSION_PHONE,
		CASE	WHEN UPPER(V.SUPPRESSION_MAIL) = 'YES' THEN 'True' 
				ELSE 'False' END AS	SUPPRESSION_MAIL
	FROM GeneralEnquiry.vwLoadToVWT V
	INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = V.ManufacturerPartyID
	ORDER BY V.GeneralEnquiryID
	
	
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

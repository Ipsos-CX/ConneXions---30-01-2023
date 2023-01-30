
CREATE PROCEDURE [IAssistance].[uspLoadToVWT]

AS

/*
	Purpose:	Transfers rows to VWT from RoadsideEvents that have matched Vehicles / Parties and have not previously been transferred
	
	Version			Date			Developer			Comment
	1.0				2018-10-22		Chris Ledger		Created from [Sample_ETL].[Roadside].[uspLoadToVWT]
	1.1				2020-01-10		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
													
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


-- First copy over the records that have been matched specifically on VIN or Email or Telephone Number

	INSERT INTO dbo.VWT 
	(
		IAssistanceID, 
		AuditID, 
		PhysicalFileRow, 
		ManufacturerID, 
		SampleSupplierPartyID, 
		ODSEventTypeID, 
		
		VehicleIdentificationNumber,			
		VehicleIdentificationNumberUsable,
		VehicleRegistrationNumber,
		RegistrationDateOrig,
		RegistrationDate,
		
		MatchedODSVehicleID, 
		MatchedODSPersonID, 
		MatchedODSOrganisationID, 
		IAssistanceCentreOriginatorPartyID,
		IAssistanceCentreCode, 
		IAssistanceDateOrig, 
		IAssistanceDate,
		CountryID,
		PartySuppression,
		EmailSuppression,
		PostalSuppression,
		SampleTriggeredSelectionReqID,
		MatchedODSEmailAddressID,					
		MatchedODSPrivEmailAddressID,				
		LanguageID,									
		MatchedODSMobileTelID,						
		EmailAddress,								
		PrivEmailAddress							
	)
	SELECT 
		IAssistanceID,
		AuditID,
		PhysicalFileRow,
		ManufacturerID,
		SampleSupplierPartyID,
		EventTypeID,
		
		VIN,										
		CASE WHEN LEN(ISNULL(VIN, '')) = 17 
				THEN 1 
				ELSE 0 
				END AS VehicleIdentificationNumberUsable,
		RegistrationNumber, 
		VehicleRegistrationDateOrig,
		CASE WHEN ISDATE(VehicleRegistrationDateOrig) = 1 
					THEN CONVERT ( DATETIME, VehicleRegistrationDateOrig, 103 ) 
					ELSE NULL END AS VehicleRegistrationDate,
		
		ISNULL(MatchedODSVehicleID, 0) AS MatchedODSVehicleID,
		ISNULL(MatchedODSPersonID, 0) AS MatchedODSPersonID,
		ISNULL(MatchedODSOrganisationID, 0) AS MatchedODSOrganisationID,
		IAssistanceCentreOriginatorPartyID,
		IAssistanceCentreCode, 
		IAssistanceDateOrig, 
		IAssistanceDate,
		CountryID,
		CASE WHEN RTRIM(LTRIM(CompleteSuppression)) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS CompleteSuppression, 
		CASE WHEN RTRIM(LTRIM([Suppression-Email])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionEmail, 
		CASE WHEN RTRIM(LTRIM([Suppression-Mail]))  = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionMail,
		SampleTriggeredSelectionReqID,
		MatchedODSEmailAddress1ID,			
		MatchedODSEmailAddress2ID,			
		PreferredLanguageID,				
		MatchedODSMobileTelephoneNumberID,	
		EmailAddress1 AS EmailAddress,	
		EmailAddress2 AS PrivEmailAddress
	FROM IAssistance.vwLoadToVWT
	ORDER BY IAssistanceID
	
	

-- Secondly copy those records where we are doing normal VWT loading on -----------

	DECLARE @UKCountryID INT
	SELECT @UKCountryID = CountryID	
			FROM [$(SampleDB)].ContactMechanism.Countries c 
			WHERE c.Country = 'United Kingdom'


	INSERT INTO dbo.VWT 
	(
		IAssistanceID, 
		AuditID, 
		PhysicalFileRow, 
		ManufacturerID, 
		SampleSupplierPartyID, 
		ODSEventTypeID, 
		IAssistanceCentreOriginatorPartyID,
		IAssistanceCentreCode, 
		IAssistanceDateOrig, 
		IAssistanceDate,
		
		CustomerIdentifier,
		CustomerIdentifierUsable,
		CustomerIdentifierOriginatorPartyID,
		
		OrganisationNameOrig,
		Title,
		FirstName, 
		LastName, 
		SecondLastName,
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
		BuildYear,
		VehicleIdentificationNumber,
		VehicleIdentificationNumberUsable,
		VehicleRegistrationNumber,
		RegistrationDateOrig,
		RegistrationDate,
		EmailAddress,
		PrivEmailAddress,
		LanguageID,
		PartySuppression,
		EmailSuppression,
		PostalSuppression,
		OwnershipCycle,
		GenderID,
		SampleTriggeredSelectionReqID	
	)
	SELECT 
		IAssistanceID,
		AuditID,
		PhysicalFileRow,
		ManufacturerID,
		SampleSupplierPartyID,
		EventTypeID,
		IAssistanceCentreOriginatorPartyID,
		IAssistanceCentreCode, 
		IAssistanceDateOrig, 
		IAssistanceDate,
	
		CustomerUniqueId,
		CustIDUsable,
		CustomerIdentifierOriginatorPartyID,
		CompanyName, 
		Title, 
		Firstname, 
		SurnameField1, 
		SurnameField2,
		CASE WHEN CountryID = @UKCountryID THEN Address1 ELSE '' END AS StreetAndNumberOrig,
		CASE WHEN CountryID = @UKCountryID THEN '' ELSE Address1 END AS StreetOrig,
		CASE WHEN CountryID = @UKCountryID THEN '' ELSE Address1 END AS Street,
		Address2 AS SubLocality,
		RTRIM(RTRIM(Address3) + ' ' + Address4) AS Locality,
		[Address5(city)] AS Town,
		[Address6(County)] AS Region,
		[Address7(Postcode/Zipcode)],
		[Address8(Country)],
		CountryID, 
		HomeTelephoneNumber, 
		MobileTelephoneNumber, 
		ModelName, 
		CASE WHEN ISNUMERIC(ModelYear) = 1 THEN ModelYear ELSE '' END AS ModelYear,
		VIN, 
		CASE WHEN LEN(ISNULL(VIN, '')) = 17 THEN 1 ELSE 0 END AS VehicleIdentificationNumberUsable,
		RegistrationNumber, 
		VehicleRegistrationDateOrig,
		CASE WHEN ISDATE(VehicleRegistrationDateOrig) = 1 
					THEN CONVERT (DATETIME, VehicleRegistrationDateOrig, 103) 
					ELSE NULL END AS VehicleRegistrationDate,
		EmailAddress1 AS EmailAddress,
		EmailAddress2 AS PrivEmailAddress,
		PreferredLanguageID,   
		CASE WHEN RTRIM(LTRIM(CompleteSuppression)) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS CompleteSuppression, 
		CASE WHEN RTRIM(LTRIM([Suppression-Email])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionEmail, 
		CASE WHEN RTRIM(LTRIM([Suppression-Mail]))  = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionMail, 
		OwnershipCycle,
		CASE WHEN SUBSTRING(Gender, 1,1) = 'M' THEN 1 
			 WHEN SUBSTRING(Gender, 1,1) = 'F' THEN 2 
			 ELSE 0 END AS GenderID,
		SampleTriggeredSelectionReqID	
	FROM IAssistance.vwFullLoadToVWT
	ORDER BY IAssistanceID
	
	
	
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

CREATE PROCEDURE [Roadside].[uspLoadToVWT]

AS

/*
	Purpose:	Transfers rows to VWT from RoadsideEvents that have matched Vehicles / Parties and have not previously been transferred
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Chris Ross		Created from [Sample_ETL].[Warranty].[uspLoadToVWT]
														Only load UK records.
	1.1				14-10-2013		Chris Ross			BUG 8967 - Add in extra functionality to load in full details where flagged
	1.2				21-11-2013		Chris Ross			BUG 8967 - Fix bug to push non-UK Address1 into Street and StreetOrig, UK continues to be into StreetAndNumberOrig
	1.3				07-03-2014		Chris Ross			BUG 10075 - Add in CustomerIdentifierOrignatorPartyID for South Africa
	1.4				26-03-2014		Chris Ross			BUG 10152 - ModelYear only transfered into VWT if it is a numeric.
	1.5				31-03-2014		Eddie Thomas		BUG 10147 - Suppressions currently ignored when matcining on VIN
	1.6				05-05-2016		Chris Ross			BUG 12569 - Alter to include Matched EmailAddress1+2 ContactMechniasmIDs (and PreferredLanguageID) on a non-VWT load. Also, force a normal VWT load 
																    where an Email, Name(/Org) and Country is present on the row and the Market table AltRoadsideEmailMatching flag has been set.
	1.7				05-05-2018		Chris Ledger		BUG 14686 - Alter to include Matched Mobile Telephone Number ContactMechniasmIDs (and PreferredLanguageID) on a non-VWT load. Also, force a normal VWT load 
																    where an Mobile Telephone Number, Name(/Org) and Country is present on the row and the Market table AltRoadsideTelephoneMatching flag has been set.
	1.8				27-09-2018		Chris Ledger		BUG 15006 - Include EmailAddress1+2 on a non-VWT load (for Vehicle Matching).
	1.9				21-03-2019		Chris Ross			BUG 15285 - Populate Suppression-Phone column using values from the respective views.
	1.10			10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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
		RoadsideID, 
		AuditID, 
		PhysicalFileRow, 
		ManufacturerID, 
		SampleSupplierPartyID, 
		ODSEventTypeID, 
		
		VehicleIdentificationNumber,			-- BUG 1659 - add in Vehicle information for creation, in the case of matching on Name + Email
		VehicleIdentificationNumberUsable,
		VehicleRegistrationNumber,
		RegistrationDateOrig,
		RegistrationDate,
		
		MatchedODSVehicleID, 
		MatchedODSPersonID, 
		MatchedODSOrganisationID, 
		RoadsideNetworkOriginatorPartyID,
		RoadsideNetworkCode, 
		RoadsideDateOrig, 
		RoadsideDate,
		CountryID,
		PartySuppression,
		EmailSuppression,
		PhoneSuppression,							-- v1.9
		PostalSuppression,
		SampleTriggeredSelectionReqID,
		MatchedODSEmailAddressID,					-- v1.6
		MatchedODSPrivEmailAddressID,				-- v1.6
		LanguageID,									-- v1.6	
		MatchedODSMobileTelID,						-- V1.7	
		EmailAddress,								-- V1.8
		PrivEmailAddress							-- V1.8
	)
	SELECT 
		RoadsideID,
		AuditID,
		PhysicalFileRow,
		ManufacturerID,
		SampleSupplierPartyID,
		EventTypeID,
		
		VIN,										-- BUG 1659 - add in Vehicle information for creation, in the case of matching on Name + Email
		CASE WHEN LEN(ISNULL(VIN, '')) = 17 
				THEN 1 
				ELSE 0 
				END AS VehicleIdentificationNumberUsable,
		RegistrationNumber, 
		VehicleRegistrationDateOrig,
		CASE WHEN ISDATE(VehicleRegistrationDateOrig) = 1 
					THEN CONVERT ( datetime, VehicleRegistrationDateOrig, 103 ) 
					ELSE NULL END AS VehicleRegistrationDate,
		
		ISNULL(MatchedODSVehicleID, 0) AS MatchedODSVehicleID,
		ISNULL(MatchedODSPersonID, 0) AS MatchedODSPersonID,
		ISNULL(MatchedODSOrganisationID, 0) AS MatchedODSOrganisationID,
		RoadsideNetworkOriginatorPartyID,
		RoadsideNetworkCode, 
		RoadsideDateOrig, 
		RoadsideDate,
		CountryID,
		CASE WHEN RTRIM(LTRIM(CompleteSuppression)) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS CompleteSuppression, 
		CASE WHEN RTRIM(LTRIM([Suppression-Email])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionEmail, 
		CASE WHEN RTRIM(LTRIM([Suppression-Phone])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionPhone,		-- v1.9
		CASE WHEN RTRIM(LTRIM([Suppression-Mail]))  = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionMail,
		SampleTriggeredSelectionReqID,
		MatchedODSEmailAddress1ID,			-- v1.6
		MatchedODSEmailAddress2ID,			-- v1.6
		PreferredLanguageID,				-- v1.6		
		MatchedODSMobileTelephoneNumberID,			-- V1.7
		EmailAddress1 AS EmailAddress,				-- V1.8
		EmailAddress2 AS PrivEmailAddress			-- V1.8
	FROM Roadside.vwLoadToVWT
	--WHERE CountryID = (select countryID 
						--from [$(SampleDB)].ContactMechanism.Countries 
						--where  Country = 'United Kingdom' )
	--AND BreakdownCountryID = (select countryID 
							--from [$(SampleDB)].ContactMechanism.Countries 
							--where  Country = 'United Kingdom' )
	ORDER BY RoadsideID
	
	

-- Secondly copy those records where we are doing normal VWT loading on -----------

	DECLARE @UKCountryID int
	SELECT @UKCountryID = CountryID									--v1.2
			from [$(SampleDB)].ContactMechanism.Countries c 
			where c.Country = 'United Kingdom'


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
		PhoneSuppression,				-- v1.9
		PostalSuppression,
		OwnershipCycle,
		GenderID,
		SampleTriggeredSelectionReqID	
	)
	SELECT 
		RoadsideID,
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
		[Address5(city)] AS Town,
		[Address6(County)] as Region,
		[Address7(Postcode/Zipcode)],
		[Address8(Country)],
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
		PreferredLanguageID,   
		CASE WHEN RTRIM(LTRIM(CompleteSuppression)) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS CompleteSuppression, 
		CASE WHEN RTRIM(LTRIM([Suppression-Email])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionEmail, 
		CASE WHEN RTRIM(LTRIM([Suppression-Phone])) = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionPhone,			--v1.9
		CASE WHEN RTRIM(LTRIM([Suppression-Mail]))  = 'Yes' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS SuppressionMail, 
		OwnershipCycle,
		CASE WHEN SUBSTRING(Gender, 1,1) = 'M' THEN 1 
			 WHEN SUBSTRING(Gender, 1,1) = 'F' THEN 2 
			 ELSE 0 END AS GenderID,
		SampleTriggeredSelectionReqID	
	FROM Roadside.vwFullLoadToVWT
	ORDER BY RoadsideID
	
	
	
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
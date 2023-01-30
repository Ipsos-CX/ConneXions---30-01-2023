CREATE PROCEDURE [OWAPv2].[uspGetSelectionCases]
@SelectionRequirementID [dbo].[RequirementID], @RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
/*
	Purpose:	returns the postal address based on contactmechanisimid
		
	Version		Date				Developer			Comment
	1.0			$(ReleaseDate)		Simon Peacock		Created
	1.1			17/09/2012			Pardip Mudhar		BUG 7581 - Check for null values to be replaced by N''
	1.2			03/04/2013			Pardip Mudhar		BUG 8782 - South Africa OWAP Files download change
	1.3			16/12/2013			Martin Riverol		BUG 9761 - Add LanguageID to NCBS case outputs
	1.4			20/03/2014			Ali Yuksel			BUG 10128 - CountryID fixed (as in event.uspGetSelectionCases)
	1.5			14/09/2016			Chris Ross			Move to schema OWAPv2
	1.6			10/10/2018			Chris Ross			BUG 14399 - Filter out people that have been GDPR erased.
*/
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- GET THE QuestionRequirementID FOR THE SELECTION
	DECLARE @QuestionnaireRequirementID dbo.RequirementID
	DECLARE @Brand dbo.OrganisationName
	DECLARE @Selectname dbo.Requirement

	SELECT
		 @QuestionnaireRequirementID = RR.RequirementIDPartOf
		,@Brand = BMQ.Brand
		,@Selectname = BMQ.SelectionName
	FROM Requirement.RequirementRollups RR
	INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.QuestionnaireRequirementID = RR.RequirementIDPartOf
	WHERE RR.RequirementIDMadeUpOf = @SelectionRequirementID

	-- CREATE TEMP TABLE TO HOLD THE DATA
	CREATE TABLE #CaseDetails
	(
		VersionCode VARCHAR(200),
		SelectionTypeID SMALLINT,
		Manufacturer NVARCHAR(510),
		ManufacturerPartyID INT,
		QuestionnaireVersion TINYINT,
		CaseID INT,
		Salutation NVARCHAR(500),
		Title NVARCHAR(200),
		FirstName NVARCHAR(100),
		SecondLastName NVARCHAR(100),
		LastName NVARCHAR(100),
		Addressee NVARCHAR(500),
		OrganisationName  NVARCHAR(510),
		GenderID TINYINT,
		LanguageID SMALLINT,
		CountryID SMALLINT,
		PartyID INT,
		EventTypeID SMALLINT,
		RegistrationNumber NVARCHAR(100),
		RegistrationDate DATETIME2,
		ModelDescription VARCHAR(50),
		ModelRequirementID INT,
		DealerCode NVARCHAR(20),
		DealerName NVARCHAR(150),
		PostalAddressContactMechanismID INT,
		BuildingName NVARCHAR(400),
		SubStreet NVARCHAR(400),
		Street NVARCHAR(400),
		SubLocality NVARCHAR(400),
		Locality NVARCHAR(400),
		Town NVARCHAR(400),
		Region NVARCHAR(400),
		PostCode NVARCHAR(60),
		Country VARCHAR(200),
		EmailAddressContactMechanismID INT,
		EmailAddress NVARCHAR(510),
		VIN NVARCHAR(50),
		EventType NVARCHAR(200),
		Telephone NVARCHAR(100),
		MobilePhone NVARCHAR(100),
		WorkTel NVARCHAR(100),
		SaleType NVARCHAR(1),
		EventDate DATETIME2,
		ChassisNumber NVARCHAR(200),
		OwnershipCycle NVARCHAR(20),
		DealerPartyID INT
	)

	INSERT INTO #CaseDetails
	(
		 SelectionTypeID
		,Manufacturer
		,ManufacturerPartyID
		,QuestionnaireVersion
		,CaseID
		,Salutation
		,Title
		,FirstName
		,SecondLastName
		,LastName
		,Addressee
		,OrganisationName
		,GenderID
		,LanguageID
		,CountryID
		,PartyID
		,EventTypeID
		,RegistrationNumber
		,ModelDescription
		,ModelRequirementID
		,DealerName
		,PostalAddressContactMechanismID
		,Country
		,EmailAddressContactMechanismID
		,VIN
		,RegistrationDate
		,EventType
		,SaleType
		,DealerCode
		,EventDate
		,ChassisNumber
		,OwnershipCycle
		,DealerPartyID
	)
	SELECT
		 MC.SelectionTypeID
		,@Brand AS Manufacturer
		,MC.ManufacturerPartyID
		,MC.QuestionnaireVersion
		,MC.CaseID
		,Party.udfGetAddressingText(MC.PartyID, @QuestionnaireRequirementID, MC.CountryID, MC.LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Salutation')) AS Salutation
		,MC.Title 
		,COALESCE(NULLIF(MC.FirstName, N''), NULLIF(MC.Initials, N'')) AS FirstName
		,MC.SecondLastName
		,MC.LastName
		,Party.udfGetAddressingText(MC.PartyID, @QuestionnaireRequirementID, MC.CountryID, MC.LanguageID, (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')) AS Addressee
		,MC.OrganisationName
		,MC.GenderID
		,MC.LanguageID
		,MC.CountryID
		,MC.PartyID
		,MC.EventTypeID
		,MC.RegistrationNumber
		,ModelDescription =
				CASE
					WHEN @Brand = 'Jaguar' THEN @Brand + N' ' + MC.ModelDescription
					ELSE MC.ModelDescription
				END
		,MC.ModelRequirementID
		,MC.DealerName
		,MC.PostalAddressContactMechanismID
		,MC.Country
		,MC.EmailAddressContactMechanismID
		,MC.VIN
		,MC.RegistrationDate
		,MC.EventType
		,MC.SaleType
		,MC.DealerCode
		,MC.EventDate
		,MC.ChassisNumber
		,MC.OwnershipCycle
		,MC.DealerPartyID
	FROM Meta.CaseDetails MC
	LEFT JOIN EVENT.CaseRejections CR ON CR.CaseID = MC.CaseID 
	WHERE MC.SelectionRequirementID = @SelectionRequirementID
	AND CR.CaseID IS NULL
	AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.6
					WHERE er.PartyID = MC.PartyID)
	ORDER BY COALESCE(LastName, OrganisationName)


	-- GET THE POSTAL ADDRESS DETAILS
	UPDATE CD
	SET  CD.BuildingName = ISNULL( PA.BuildingName, N' ' )
		,CD.SubStreet = ISNULL( PA.SubStreetNumber, N' ' ) + N' ' + ISNULL( PA.SubStreet, N' ')
		,CD.Street = ISNULL( PA.StreetNumber, N' ') + N' ' + ISNULL( PA.Street, N' ' )
		,CD.SubLocality = ISNULL( PA.SubLocality, N' ' )
		,CD.Locality = ISNULL( PA.Locality, N' ' )
		,CD.Town = ISNULL( PA.Town, N' ' )
		,CD.Region = ISNULL( PA.Region, N' ' )
		,CD.PostCode = ISNULL( PA.PostCode, N' ' )
		,CD.CountryID = CASE WHEN CD.CountryID IS NULL THEN PA.CountryID ELSE CD.CountryID END
	FROM #CaseDetails CD
	INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CD.PostalAddressContactMechanismID
		
	-- GET COUNTRY DETAILS IN CASE PARTY DOESN'T HAVE A POSTALADDRESS				v1.4
	; WITH DealerCountries (DealerPartyID, CountryID) AS (
			SELECT DISTINCT
				PartyIDFrom, CountryID
			FROM ContactMechanism.DealerCountries
		)
	UPDATE CD
	SET CD.CountryID = DC.CountryID
	FROM #CaseDetails CD
	INNER JOIN DealerCountries DC ON DC.DealerPartyID = CD.DealerPartyID
	WHERE CD.CountryID IS NULL

	-- GET THE EMAIL ADDRESS DETAILS
	UPDATE CD
	SET CD.EmailAddress = EA.EmailAddress
	FROM #CaseDetails CD
	INNER JOIN ContactMechanism.EmailAddresses EA ON EA.ContactMechanismID = CD.EmailAddressContactMechanismID

	-- SET THE VersionCode VALUE
	UPDATE #CaseDetails
	SET VersionCode = CONVERT(VARCHAR, EventTypeID) + 
			SUBSTRING('000', 1, 3 - LEN(CountryID)) + 
			CONVERT(VARCHAR, CountryID) +
			SUBSTRING('00000', 1, 5 - LEN(ManufacturerPartyID)) + 
			CONVERT(Varchar, ManufacturerPartyID) +
			CONVERT(VARCHAR, SelectionTypeID) +
			CONVERT(VARCHAR, QuestionnaireVersion)

	UPDATE #CaseDetails
	SET Telephone = ContactMechanism.TelephoneNumbers.ContactNumber
	FROM ( Event.CaseContactMechanisms CM 
	INNER JOIN ContactMechanism.TelephoneNumbers ON CM.ContactMechanismID = ContactMechanism.TelephoneNumbers.ContactMechanismID)
	INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
		AND CMT.ContactMechanismType = N'Phone (landline)' 
	where #CaseDetails.CaseID = CM.CaseID

	UPDATE #CaseDetails
	SET WorkTel = ContactMechanism.TelephoneNumbers.ContactNumber
	FROM ( Event.CaseContactMechanisms CM 
	INNER JOIN ContactMechanism.TelephoneNumbers ON CM.ContactMechanismID = ContactMechanism.TelephoneNumbers.ContactMechanismID)
	INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
		AND CMT.ContactMechanismType = N'Phone' 
	where #CaseDetails.CaseID = CM.CaseID

	UPDATE #CaseDetails
	SET MobilePhone = ContactMechanism.TelephoneNumbers.ContactNumber
	FROM ( Event.CaseContactMechanisms CM 
	INNER JOIN ContactMechanism.TelephoneNumbers ON CM.ContactMechanismID = ContactMechanism.TelephoneNumbers.ContactMechanismID)
	INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID 
		AND CMT.ContactMechanismType = N'Phone (mobile)' 
	where #CaseDetails.CaseID = CM.CaseID

	DECLARE @COUNTRYNAME NVARCHAR(100)
	
	SELECT TOP 1 @COUNTRYNAME = UPPER(COUNTRY) FROM #CaseDetails WHERE Country IS NOT NULL
		
	IF ( ( Select CHARINDEX ( N'NCBS', @Selectname )) > 0 )
	BEGIN
			SELECT 
				  PartyID
				, CaseID
				, Country
				, Manufacturer
				, VIN
				, ChassisNumber
				, ModelDescription AS FullModelDescription
				, RegistrationNumber
				, ISNULL(CONVERT(VARCHAR(12), EventDate, 103), '') as DeliveryDate
				, Salutation
				, Addressee
				, Title
				, FirstName
				, SecondLastName
				, LastName
				, OrganisationName 
				, Street
				, SubLocality
				, Locality 
				, Town
				, Region
				, PostCode
				, WorkTel AS Phone
				, Telephone AS LandlinePrivate
				, MobilePhone as Mobile
				, EmailAddress as ElectronicAddress
				, CONVERT(varchar(12), GETDATE(), 103)  AS OutputDate
				, SaleType AS Ownership
				, @Selectname SelectionName
				, ModelDescription as SelectionQuotaLine
				, ISNULL(CONVERT(VARCHAR(12), RegistrationDate, 103), '') AS RegistrationDate
				, ISNULL(CONVERT(VARCHAR(12), EventDate, 103), '') AS EventDate
				, OwnershipCycle
				, GenderID
				, N'' AS ModelYear
				, LanguageID
			FROM
				#CaseDetails 

	END 
	ELSE IF ( @COUNTRYNAME = N'CHINA' OR @COUNTRYNAME = N'RUSSIAN FEDERATION' OR @COUNTRYNAME = N'SOUTH AFRICA'  )
	BEGIN
		SELECT
			 VIN
			,DealerCode
			,ModelDescription
			,ISNULL(CONVERT(VARCHAR(12), RegistrationDate, 103), '') AS RegistrationDate
			, CASE
				WHEN @COUNTRYNAME = N'CHINA' THEN ISNULL( LastName, '' )
				WHEN @COUNTRYNAME = N'RUSSIAN FEDERATION' THEN ISNULL( ISNULL( LastName, '' ) + ' ' + ISNULL( FirstName, '' ) + ' ' + ISNULL( SecondLastName, ''), '')
				WHEN @COUNTRYNAME = N'SOUTH AFRICA' THEN ISNULL( FirstName, '' ) + ' ' + ISNULL( LastName, '' )
			   END AS FullName
			,OrganisationName AS CompanyName
			,Street	AS ADDRESS1
			,Locality AS ADDRESS2
			,Town AS ADDRESS3
			,Region AS ADDRESS4
			,PostCode AS ADDRESS5
			,CASE @COUNTRYNAME WHEN N'SOUTH AFRICA' THEN MobilePhone
							   ELSE COALESCE ( Telephone, MobilePhone, WorkTel ) 
							   END AS Telephone
			,SaleType AS BusPri
			,PartyID
			,CaseID
			,CONVERT(varchar(12), GETDATE(), 101)  AS DATEOUTPUT
			,ManufacturerPartyID AS JLR
			,EventTypeID AS Event
			,RegistrationNumber AS RegistrationNumber
			,EmailAddress as EMail
		FROM 
			#CaseDetails		
	END
	ELSE IF ( @COUNTRYNAME = N'JAPAN' )
	BEGIN
	
		SELECT
			 PartyID
			,CaseID
			,ModelDescription
			,ModelDescription as FullModelDescription -- temporarily added for UAT - TODO: remove me
			,Manufacturer
			,RegistrationNumber
			,RegistrationDate
			,Title
			,FirstName
			,LastName
			,Addressee
			,Salutation
			,OrganisationName
			,BuildingName
			,SubStreet
			,Street
			,SubLocality
			,Locality
			,Town
			,Region
			,PostCode
			,Country
			,DealerName
			,VersionCode
			,CountryID
			,ModelRequirementID
			,LanguageID
			,ManufacturerPartyID
			,GenderID
			,QuestionnaireVersion
			,EventTypeID
			,SelectionTypeID
			,EmailAddress
			,VIN
		FROM #CaseDetails
	END
	ELSE
	BEGIN
		SELECT
			 PartyID
			,CaseID
			,ModelDescription as FullModelDescription -- temporarily added for UAT - TODO: remove me
			,ModelDescription
			,Manufacturer
			,VIN
			,RegistrationNumber
			,Title
			,FirstName
			,LastName
			,Salutation
			,Addressee
			,OrganisationName
			,BuildingName
			,SubStreet
			,Street
			,SubLocality
			,Locality
			,Town
			,Region
			,PostCode
			,Country
			,DealerName
			,VersionCode
			,CountryID
			,ModelRequirementID
			,LanguageID
			,ManufacturerPartyID
			,GenderID
			,QuestionnaireVersion
			,EventTypeID
			,SelectionTypeID
			,EmailAddress
		FROM #CaseDetails
	END

	SELECT @RowCount = @@RowCount

	DROP TABLE #CaseDetails
	
	SET @ErrorCode = @@Error
	

END TRY
BEGIN CATCH

	SET @ErrorCode = @@Error

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


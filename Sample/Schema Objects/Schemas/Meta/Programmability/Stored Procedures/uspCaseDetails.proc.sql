CREATE PROCEDURE [Meta].[uspCaseDetails]
@BuildType  VARCHAR(50)

AS

/*
		Purpose:	Flattened out view of all selected cases.
	
		Version		Date			Developer			Comment
LIVE	1.0			??/??/????		??????? ???????		Created
LIVE	1.1			21/03/2013		Martin Riverol		BUG #8757 Added ModelVariant/ID to output 
LIVE	1.2			14/02/2013		Chris Ross			BUG 9456 - Added in new index for faster reporting
LIVE	1.3			12/01/2015		Chris Ross			BUG 11125 - MENA market dealer name translations to be used REMOVED
LIVE	1.4			15/01/2015		Chris Ross			--> Overwritten code with optimised version we've been trialing in UAT 
															(overwrites previous update which is being re-coded to be cust/language specific)
LIVE	1.5			27/01/2015		Chris Ross			BUG 11143 (supersedes 111250).  Include MENA market + language specific 
														Dealer name translations.
LIVE	1.6			06/02/2015		Chris Ross			BUG 11193 - Fix: Country details not being set on MENA records as no postal address.
LIVE	1.7			04/03/2015		Chris Ross			BUG 11026 - Moved "MENA" native language check from SuperNationalRegion to BusinessRegion.
LIVE	1.8			28/07-2015		Chris Ross			BUG 11448 - Add in CountryID lookup on Dealer/CRC Centre/Roadside Network
LIVE	1.9			11/07/2016		Chris Ross			BUG 12777 - Add in OrganisationPartyID column for reference.
LIVE	1.10		01/11/2016		Chris Ledger		BUG 10961 - Add CURSOR to loop through years
LIVE	1.11		16/11/2016		Chris Ross			BUG 13334 - Modify to allow partial updates, i.e. we only update Cases created in the last 90 days, as well as full rebuilds. 
LIVE	1.12		26/06/2017		Chris Ross			BUG 14039 - Fix "associated Organisation" lookup to return correct Organisation PartyID. Requires using ROWNUMBER()/OVER clause.
LIVE	1.13		09/01/2017		Chris Ledger		BUG 14489 - Remove postfix for duplicate VINs (i.e. _01, _02 at end)
LIVE	1.14		18/04/2017		Chris Ross			BUG 14339 - Ensure data blanked out for PartyIDs where partial GDPR Right To Erasure has been applied
LIVE	1.15		01/11/2018		Chris Ledger		BUG 15056 - Add I-Assistance Centre
LIVE	1.16		14/02/2020		Chris Ledger		Add missing indexes
LIVE	1.17	    12/08/2021		Eddie Thomas		BUG 18289 - Modeldescription field is too small to accommodate a new model
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	-- Check @BuildType supplied is valid		-- V1.11
	IF ISNULL(@BuildType, '?') NOT IN ('Full', 'Partial')
	RAISERROR ('Error: @BuildType param not in valid values list: "Full", "Partial".', -- Message text.  
				1016, -- Severity.  
				1 -- State.
				);  


	------------------------------------------------------------------------
	-- Set then check GDPR system variables
	------------------------------------------------------------------------
	DECLARE @DummyEmailID BIGINT, 
			@DummyPhoneID BIGINT, 
			@DummyPostalID BIGINT, 
			@DummyJagVehicleID BIGINT,
			@DummyLRVehicleID BIGINT,
			@DummyJagModelID INT,
			@DummyLRModelID INT,
			@DummyOrganisationID BIGINT,
			@DummyCountryID INT
	
	SELECT @DummyEmailID = SV.DummyEmailID,
		@DummyPhoneID = SV.DummyPhoneID,
		@DummyPostalID = SV.DummyPostalID,
		@DummyJagVehicleID = SV.DummyJagVehicleID,
		@DummyLRVehicleID = SV.DummyLRVehicleID,
		@DummyJagModelID = M1.ModelID,
		@DummyLRModelID = M2.ModelID,
		@DummyOrganisationID = SV.DummyOrganisationID
	FROM GDPR.SystemValues SV
		LEFT JOIN Vehicle.Vehicles V1 ON V1.VehicleID = SV.DummyJagVehicleID
		LEFT JOIN Vehicle.Models M1 ON M1.ModelID = V1.ModelID
		LEFT JOIN Vehicle.Vehicles V2 ON V2.VehicleID = SV.DummyLRVehicleID
		LEFT JOIN Vehicle.Models M2 ON M2.ModelID = V2.ModelID
	
	SELECT @DummyCountryID = CountryID FROM ContactMechanism.Countries WHERE Country = 'GDPR Erased' 

	DECLARE @RemovalText  VARCHAR(20)
	SET @RemovalText = '[GDPR - Erased]'

	-- Check all present 
	IF @DummyEmailID IS NULL 
		OR @DummyPhoneID IS NULL 
		OR @DummyPostalID IS NULL
		OR @DummyJagVehicleID IS NULL 
		OR @DummyLRVehicleID IS NULL 
		OR @DummyJagModelID IS NULL 
		OR @DummyLRModelID IS NULL
		OR @DummyCountryID IS NULL 
	RAISERROR ('ERROR (Meta.uspCaseDetails) : GDPR system variables not configuring correctly.',  16, 1) 


	------------------------------------------------------------------------
	-- Drop and build temp CaseDetails table
	------------------------------------------------------------------------
	DROP TABLE IF EXISTS Meta.CaseDetails_TmpBuild

	CREATE TABLE Meta.CaseDetails_TmpBuild									-- V1.11
	(
		Questionnaire dbo.Requirement NOT NULL,
		QuestionnaireRequirementID dbo.RequirementID NOT NULL,
		QuestionnaireVersion TINYINT NULL,
		SelectionTypeID dbo.SelectionTypeID NULL,
		Selection dbo.Requirement NOT NULL,
		ModelDerivative dbo.Requirement NOT NULL,
		CaseStatusTypeID dbo.CaseStatusTypeID NOT NULL,
		CaseID dbo.CaseID NOT NULL,
		CaseRejection INT NOT NULL,
		Title dbo.Title NULL,
		FirstName dbo.NameDetail NULL,
		Initials dbo.NameDetail NULL,
		MiddleName dbo.NameDetail NULL,
		LastName dbo.NameDetail NULL,
		SecondLastName dbo.NameDetail NULL,
		GenderID INT NULL,
		LanguageID INT NULL,
		OrganisationName NVARCHAR(510) NULL,
		OrganisationPartyID dbo.PartyID NULL,								-- V1.9
		PostalAddressContactMechanismID dbo.ContactMechanismID NULL,
		EmailAddressContactMechanismID dbo.ContactMechanismID NULL,
		CountryID dbo.CountryID NULL,
		Country dbo.Country NULL,
		CountryISOAlpha3 CHAR(3) NULL,
		CountryISOAlpha2 CHAR(2) NULL,
		EventTypeID dbo.EventTypeID NOT NULL,
		EventType NVARCHAR(200) NOT NULL,
		EventDate DATETIME2(7) NULL,
		PartyID dbo.PartyID NULL,
		VehicleRoleTypeID dbo.VehicleRoleTypeID NULL,
		VehicleID dbo.VehicleID NULL,
		EventID dbo.EventID NULL,
		OwnershipCycle dbo.OwnershipCycle NULL,
		SelectionRequirementID dbo.RequirementID NOT NULL,
		ModelRequirementID dbo.RequirementID NOT NULL,
		RegistrationNumber dbo.RegistrationNumber NULL,
		RegistrationDate DATETIME2(7) NULL,
		--ModelDescription dbo.ModelDescription NOT NULL,
		ModelDescription VARCHAR(50) NOT NULL,								-- V1.17
		VIN dbo.VIN NOT NULL,
		VinPrefix dbo.VINPrefix NULL,
		ChassisNumber dbo.ChassisNumber NULL,
		ManufacturerPartyID dbo.PartyID NOT NULL,
		DealerPartyID dbo.PartyID NULL,
		DealerCode dbo.DealerCode NULL,
		DealerName dbo.DealerName NULL,
		RoadsideNetworkPartyID dbo.PartyID NULL, 
		RoadsideNetworkCode dbo.RoadsideNetworkCode  NULL,
		RoadsideNetworkName dbo.RoadsideNetworkName NULL,		
		SaleType VARCHAR(1) NULL,
		VariantID SMALLINT NULL,
		ModelVariant VARCHAR(50) NULL
	)


	DROP TABLE IF EXISTS #PartyPostalAddresses

	SELECT CCM.CaseID,
		MAX(PA.ContactMechanismID) AS ContactMechanismID,
		C.CountryID,
		C.Country,
		C.ISOAlpha2 AS CountryISOAlpha2,
		C.ISOAlpha3 AS CountryISOAlpha3,
		C.DefaultLanguageID
	INTO #PartyPostalAddresses
	FROM Event.CaseContactMechanisms CCM
		INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CCM.ContactMechanismID	
		INNER JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
	GROUP BY CCM.CaseID,
		C.CountryID,
		C.Country,
		C.ISOAlpha2,
		C.ISOAlpha3,
		C.DefaultLanguageID


    DROP TABLE IF EXISTS #PartyEmailAddresses

	SELECT CaseID,
		MAX(ContactMechanismID) AS ContactMechanismID
	INTO #PartyEmailAddresses
	FROM Event.CaseContactMechanisms
	WHERE ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address')
	GROUP BY CaseID

 
	DROP TABLE IF EXISTS #Registrations
	
	SELECT M.EventID, 
		M.VehicleID, 
		REG.RegistrationNumber, 
		REG.RegistrationDate
	INTO #Registrations
	FROM (	SELECT EventID, 
				VehicleID, 
				MAX(RegistrationID) AS MaxRegistrationID
			FROM Vehicle.VehicleRegistrationEvents
			GROUP BY EventID, VehicleID) M INNER JOIN Vehicle.Registrations REG ON REG.RegistrationID = M.MaxRegistrationID 
																					AND COALESCE(REG.ThroughDate, '31 December 2999') > CURRENT_TIMESTAMP

	---------------------------------------------------------------------------------------------------
	-- V1.10 ADD INDEX FOR #Registrations
	---------------------------------------------------------------------------------------------------
	CREATE NONCLUSTERED INDEX [IX_TemppDBRegistrations]
		ON [#Registrations] ([EventID],[VehicleID])
		INCLUDE ([RegistrationNumber],[RegistrationDate])
	---------------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------------
	-- V1.10 LOOP THROUGH CURSOR OF CREATION DATES (Either split by Years, for full build, or just last 90 days)
	-----------------------------------------------------------------------------------------------------
	DECLARE @CreationDateFrom DATE, @CreationDateTo DATE

	IF @BuildType = 'Full'
		BEGIN 
			DECLARE CreationYear_Cursor CURSOR FOR 
			
			SELECT CAST(CAST( DATEPART(YEAR, C.CreationDate) AS CHAR(4))+'0101' AS DATE) FromDate,
				CAST(CAST(DATEPART(YEAR, C.CreationDate) +1 AS CHAR(4))+'0101' AS DATE) ToDate
			FROM Event.Cases C
			GROUP BY DATEPART(YEAR, C.CreationDate)
		END
	ELSE 
		BEGIN  -- Partial
			DECLARE CreationYear_Cursor  CURSOR FOR 
			 
			SELECT CAST(GETDATE()-90 AS DATE) AS FromDate, 
				CAST(GETDATE()+1 AS DATE) AS ToDate
		END 


	OPEN CreationYear_Cursor 

	FETCH NEXT FROM CreationYear_Cursor INTO
		@CreationDateFrom, @CreationDateTo

	WHILE @@FETCH_STATUS = 0
	BEGIN		

		INSERT INTO Meta.CaseDetails_TmpBuild 
		(		
			Questionnaire,
			QuestionnaireRequirementID,
			QuestionnaireVersion,
			SelectionTypeID,
			Selection,
			ModelDerivative,
			CaseStatusTypeID,
			CaseID,
			CaseRejection,
			Title,
			FirstName,
			Initials,
			MiddleName,
			LastName,
			SecondLastName,
			GenderID,
			LanguageID,
			PostalAddressContactMechanismID,
			EmailAddressContactMechanismID,
			CountryID,
			Country,
			CountryISOAlpha3,
			CountryISOAlpha2,
			EventTypeID,
			EventType,
			EventDate,
			PartyID,
			VehicleRoleTypeID,
			VehicleID,
			EventID,
			OwnershipCycle,
			SelectionRequirementID,
			ModelRequirementID,
			RegistrationNumber,
			RegistrationDate,
			ModelDescription,
			VIN,
			VinPrefix,
			ChassisNumber,
			ManufacturerPartyID,
			VariantID,
			ModelVariant
		)

		SELECT DISTINCT
			Q.Requirement AS Questionnaire,
			Q.RequirementID AS QuestionnaireRequirementID,
			QR.QuestionnaireVersion,
			SR.SelectionTypeID,
			S.Requirement AS Selection, 
			M.Requirement AS ModelDerivative,
			C.CaseStatusTypeID,
			C.CaseID,
			CASE WHEN CR.CaseID IS NOT NULL THEN 1 ELSE 0 END AS CaseRejection,
			T.Title,
			P.FirstName,
			P.Initials,
			P.MiddleName,
			P.LastName,
			P.SecondLastName,
			COALESCE(P.GenderID, 3) AS GenderID,
			COALESCE(PL.LanguageID, PPA.DefaultLanguageID, 0) AS LanguageID,
			PPA.ContactMechanismID AS PostalAddressContactMechanismID,
			PEA.ContactMechanismID AS EmailAddressContactMechanismID,
			PPA.CountryID,
			PPA.Country,
			PPA.CountryISOAlpha3,
			PPA.CountryISOAlpha2,
			ET.EventTypeID,
			ET.EventType,
			COALESCE(E.EventDate, R.RegistrationDate) AS EventDate,
			AEBI.PartyID,
			AEBI.VehicleRoleTypeID,
			AEBI.VehicleID,
			AEBI.EventID,
			OC.OwnershipCycle,
			S.RequirementID AS SelectionRequirementID,
			M.RequirementID AS ModelRequirementID,
			R.RegistrationNumber,
			CASE	WHEN ET.EventType = 'Sales' THEN COALESCE(R.RegistrationDate, E.EventDate)
					ELSE R.RegistrationDate END AS RegistrationDate,
			MD.OutputFileModelDescription, -- USE THIS INSTEAD OF THE ACTUAL MODEL DESCRIPTION
			CASE	WHEN LEN(V.VIN) = 20 AND SUBSTRING(V.VIN,18,1) = '_' THEN SUBSTRING(V.VIN,1,17) 
					ELSE V.VIN END AS VIN,		-- V1.13
			V.VinPrefix,
			V.ChassisNumber,
			MD.ManufacturerPartyID,
			MV.VariantID,
			MV.Variant
		FROM Event.Cases C
			LEFT JOIN Event.CaseRejections CR ON C.CaseID = CR.CaseID
			INNER JOIN Requirement.SelectionCases SC ON C.CaseID = SC.CaseID
			INNER JOIN Requirement.Requirements M ON M.RequirementID = SC.RequirementIDMadeUpOf
			INNER JOIN Requirement.Requirements S ON S.RequirementID = SC.RequirementIDPartOf
			INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = S.RequirementID
			INNER JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = SC.RequirementIDPartOf
			INNER JOIN Requirement.Requirements Q ON Q.RequirementID = SQ.RequirementIDPartOf
			INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = Q.RequirementID
			INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = C.CaseID
			INNER JOIN Event.Events E 
					LEFT JOIN Event.OwnershipCycle OC ON E.EventID = OC.EventID
									ON AEBI.EventID = E.EventID
			INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
			INNER JOIN Vehicle.Vehicles V 
				LEFT JOIN Vehicle.ModelVariants MV ON V.ModelID = MV.ModelID
													AND V.ModelVariantID = MV.VariantID
										ON V.VehicleID = AEBI.VehicleID
			INNER JOIN Vehicle.Models MD ON MD.ModelID = V.ModelID
			LEFT JOIN #Registrations R ON R.EventID = E.EventID AND R.VehicleID = V.VehicleID
			LEFT JOIN Party.People P
				INNER JOIN Party.Titles T ON T.TitleID = P.TitleID
									ON P.PartyID = AEBI.PartyID
			LEFT JOIN Party.PartyLanguages PL ON PL.PartyID = AEBI.PartyID 
												AND PL.PreferredFlag = 1
			LEFT JOIN #PartyPostalAddresses PPA ON PPA.CaseID = C.CaseID
			LEFT JOIN #PartyEmailAddresses PEA ON PEA.CaseID = C.CaseID
		WHERE (C.CreationDate >= @CreationDateFrom AND C.CreationDate <  @CreationDateTo)
			OR (C.CreationDate IS NULL AND DATEPART (YEAR, @CreationDateTo) = 2016)   --- Pick up NULLS as part of latest year

		FETCH NEXT FROM CreationYear_Cursor INTO
		@CreationDateFrom, @CreationDateTo
	
	END
	
	CLOSE CreationYear_Cursor
	DEALLOCATE CreationYear_Cursor	
	-----------------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------------
	-- FOR CHINA AND RUSSIAN WE ALWAYS USE THE EVENT DATE FOR THE REGISTRAITON DATE
	-----------------------------------------------------------------------------------------------------
	UPDATE CD
	SET CD.RegistrationDate = CD.EventDate
	FROM Meta.CaseDetails_TmpBuild CD
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata B ON B.QuestionnaireRequirementID = CD.QuestionnaireRequirementID
	WHERE B.ISOAlpha3 IN ('CHN', 'RUS')
	-----------------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------------
	-- GET THE DEALER INFORMATION
 	-----------------------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #EventPartyRoles

	SELECT EventID,
		MAX(PartyID) AS DealerPartyID,
		RoleTypeID
	INTO #EventPartyRoles
	FROM Event.EventPartyRoles
	WHERE RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)
	GROUP BY EventID, 
		RoleTypeID
	-----------------------------------------------------------------------------------------------------
	
	
	---------------------------------------------------------------------------------------------------
	--- INCREMENTALLY UPDATE Meta.CaseDetails_TmpBuild using the Year to filter
	---------------------------------------------------------------------------------------------------
	-- First create an Index on EventDate
	CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_PartyID] 
		ON [Meta].[CaseDetails_TmpBuild] (EventDate ASC)
		INCLUDE (CaseID, EventID, ManufacturerPartyID, DealerPartyID, LanguageID)
	
	

	-----------------------------------------------------------------------------------------------------
	-- V1.10 LOOP THROUGH CURSOR OF EVENT YEARS
	-----------------------------------------------------------------------------------------------------
	DECLARE @EventYear INT

	DECLARE EventYear_Cursor CURSOR FOR 
		SELECT DATEPART(YEAR, C.EventDate) AS EventYear 
		FROM Meta.CaseDetails_TmpBuild C 
		GROUP BY DATEPART(YEAR, C.EventDate)

	OPEN EventYear_Cursor 

	FETCH NEXT FROM EventYear_Cursor INTO
		@EventYear

	WHILE @@FETCH_STATUS = 0
	BEGIN

		UPDATE CD
		SET	 CD.DealerPartyID = D.OutletPartyID,
			CD.DealerName = CASE	WHEN D.Market IN ('Russian Federation','Japan') OR D.BusinessRegion = 'MENA' THEN COALESCE(LOL.LegalName, LO.LegalName, D.Outlet)		-- V1.7
									ELSE D.Outlet END,
			CD.DealerCode = D.OutletCode
		FROM Meta.CaseDetails_TmpBuild CD
			INNER JOIN #EventPartyRoles EPR ON EPR.EventID = CD.EventID
			INNER JOIN DW_JLRCSPDealers D ON D.OutletPartyID = EPR.DealerPartyID 
											AND D.OutletFunctionID = EPR.RoleTypeID 
											AND D.ManufacturerPartyID = CD.ManufacturerPartyID
			LEFT JOIN Party.LegalOrganisations LO ON LO.PartyID = D.OutletPartyID
			LEFT JOIN Party.LegalOrganisationsByLanguage LOL ON LOL.PartyID = D.OutletPartyID 
																AND LOL.LanguageID = CD.LanguageID
			WHERE (CD.EventDate >= CAST(CAST(@EventYear AS CHAR(4))+'0101' AS DATE) AND CD.EventDate < CAST(CAST(@EventYear+1 AS CHAR(4))+'0101' AS DATE))
				OR (CD.EventDate IS NULL AND @EventYear = 2016)   -- Pick up NULLS as part of latest year

		FETCH NEXT FROM EventYear_Cursor INTO
		@EventYear
	
	END
	
	CLOSE EventYear_Cursor
	DEALLOCATE EventYear_Cursor	
	-----------------------------------------------------------------------------------------------------

	-- Remove the index now it has served it's purpose
	DROP INDEX IX_CaseDetails_TmpBuild_PartyID ON [Meta].[CaseDetails_TmpBuild] 


	-----------------------------------------------------------------------------------------
	-- GET THE ROADSIDE NETWORK INFORMATION
	-----------------------------------------------------------------------------------------
    DROP TABLE IF EXISTS #EventPartyRoles_R
	
	SELECT EventID,
		RoleTypeID,
		MAX(PartyID) AS RoadsideNetworkPartyID
	INTO #EventPartyRoles_R
	FROM Event.EventPartyRoles
	WHERE RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwRoadsideNetworkRoleTypes)
	GROUP BY EventID,
		RoleTypeID
	
	
	UPDATE CD
	SET CD.RoadsideNetworkPartyID = RN.PartyIDFrom,
		CD.RoadsideNetworkName = RN.RoadsideNetworkName, 
		CD.RoadsideNetworkCode = RN.RoadsideNetworkCode
	FROM Meta.CaseDetails_TmpBuild CD
		INNER JOIN #EventPartyRoles_R EPR ON EPR.EventID = CD.EventID
		INNER JOIN Party.RoadsideNetworks RN ON RN.PartyIDFrom = EPR.RoadsideNetworkPartyID 
												AND RN.RoleTypeIDFrom = EPR.RoleTypeID


	--------------------------------------------------------------------				
	-- NOW GET THE ORGANISATION DATA
	--------------------------------------------------------------------
	UPDATE CD
	SET CD.OrganisationName = O.OrganisationName,
		CD.OrganisationPartyID = O.PartyID				-- V1.9
	FROM Meta.CaseDetails_TmpBuild CD
		INNER JOIN Party.Organisations O ON O.PartyID = CD.PartyID

	UPDATE CD
	SET CD.OrganisationName = BE.OrganisationName,
		CD.OrganisationPartyID = BE.PartyID				-- V1.9
	FROM Meta.CaseDetails_TmpBuild CD
		INNER JOIN Meta.BusinessEvents BE ON BE.EventID = CD.EventID
								--AND BE.OrganisationName <> ''		-- V1.9
	WHERE CD.OrganisationName IS NULL

	
	-- V1.12 First order the associated people/organisations so that we can return the latest Organisation PartyID
	DROP TABLE IF EXISTS #Organisation_pre
		 
	SELECT ROW_NUMBER() OVER (PARTITION BY PCM.PartyID, PCM.ContactMechanismID ORDER BY PO.PartyID DESC) AS RowID,
		PCM.PartyID,
		PCM.ContactMechanismID,
		PO.OrganisationName AS OrganisationName,
		PO.PartyID AS OrganisationPartyID
	INTO #Organisation_pre
	FROM ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN Party.PartyRelationships PR
		INNER JOIN Party.Organisations PO ON PO.PartyID = PR.PartyIDTo
		INNER JOIN ContactMechanism.PartyContactMechanisms OPCM ON OPCM.PartyID = PO.PartyID
												ON PR.PartyIDFrom = PCM.PartyID
													AND PR.PartyRelationshipTypeID = 1
													AND PCM.ContactMechanismID = OPCM.ContactMechanismID

	
	-- V1.12 Populate the lookup table with just latest Organisation PartyID's
	DROP TABLE IF EXISTS #Organisation
		 
	SELECT PartyID,
		ContactMechanismID,
		OrganisationName,
		OrganisationPartyID
	INTO #Organisation
	FROM #Organisation_pre
	WHERE RowID = 1


	-- Populate with the associated organisation details, if they exist 
	UPDATE CD
	SET CD.OrganisationName = PO.OrganisationName,
		CD.OrganisationPartyID = PO.OrganisationPartyID 			-- V1.12
	FROM Meta.CaseDetails_TmpBuild CD
		INNER JOIN #Organisation PO ON PO.PartyID = CD.PartyID 
										AND PO.ContactMechanismID = CD.PostalAddressContactMechanismID
	WHERE CD.OrganisationName IS NULL



	UPDATE Meta.CaseDetails_TmpBuild
	SET SaleType = CASE	WHEN ISNULL(OrganisationName, '') <> '' THEN 'B' 
						ELSE 'P' END


	UPDATE Meta.CaseDetails_TmpBuild
	SET OrganisationName = ''
	WHERE OrganisationName IS NULL
	
	
	-- REMOVE INVALID REG NUMBERS FOR BELGIUM AND SPAIN
	UPDATE Meta.CaseDetails_TmpBuild
	SET RegistrationNumber = ''
	WHERE CountryISOAlpha3 = 'ESP'
		AND (RegistrationNumber LIKE '000AAA%'
				OR RegistrationNumber LIKE '0000AAA%'
				OR RegistrationNumber LIKE '000BBB%'
				OR RegistrationNumber LIKE '0000BBB%')
	

	UPDATE Meta.CaseDetails_TmpBuild
	SET RegistrationNumber = ''
	WHERE CountryISOAlpha3 = 'BEL'
		AND RegistrationNumber LIKE 'ZZZ001%'


	-- ALTER THE LUXEMBOURG COUNTRY TO BE BELGIUM
	UPDATE Meta.CaseDetails_TmpBuild
	SET CountryID = (SELECT CountryID FROM ContactMechanism.Countries WHERE Country = 'Belgium')
	WHERE CountryID = (SELECT CountryID FROM ContactMechanism.Countries WHERE Country = 'Luxembourg')


	-- CREATE KEYS AND INDEXES
	ALTER TABLE Meta.CaseDetails_TmpBuild 
		ADD CONSTRAINT PK_CaseDetails_TmpBuild PRIMARY KEY (CaseID)


	CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_SelectionRequirementID] 
		ON [Meta].[CaseDetails_TmpBuild] ([SelectionRequirementID] ASC)
		INCLUDE ([QuestionnaireVersion], [SelectionTypeID], [CaseID], [Title], [FirstName], [Initials], [LastName], [SecondLastName], [GenderID], [LanguageID], [OrganisationName], [PostalAddressContactMechanismID], [EmailAddressContactMechanismID], [CountryID], [Country], [EventTypeID], [EventType], [EventDate], [PartyID], [OwnershipCycle], [ModelRequirementID], [RegistrationNumber], [RegistrationDate], [ModelDescription], [VIN], [ChassisNumber], [ManufacturerPartyID], [DealerPartyID], [DealerCode], [DealerName], [SaleType])	


	-- New index to speed up reporting
	CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_PartyID] 
		ON [Meta].[CaseDetails_TmpBuild] (PartyID ASC)
		INCLUDE ( DealerPartyID)


	-- V1.16 Add Missing Indexes
	CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_EventID] 
		ON [Meta].[CaseDetails_TmpBuild] ([EventID]) 
		INCLUDE ([CaseID])


	CREATE NONCLUSTERED INDEX [IX_CaseDetails_TmpBuild_VehicleRoleTypeID_VehicleID_EventID] 
		ON [Meta].[CaseDetails_TmpBuild] ([VehicleRoleTypeID], [VehicleID], [EventID]) 
		INCLUDE ([QuestionnaireRequirementID])


	UPDATE V
	SET V.VINPrefix = SUBSTRING(V.VIN, 1, 11), 
		V.ChassisNumber = SUBSTRING(V.VIN, 12, 17) 
	FROM Sample.Vehicle.Vehicles V
	WHERE V.VehicleIdentificationNumberUsable = 1
		AND LEN(V.VIN) = 17



	-- V1.6 - If Country Details not set - then set using Dealer (for where there is no address associated with a customer)
	; WITH DealerCountries (DealerPartyID, CountryID) AS 
	(
		SELECT DISTINCT
			PartyIDFrom, 
			CountryID
		FROM ContactMechanism.DealerCountries
		UNION
		SELECT PartyIDFrom, 
			CountryID						-- V1.8
		FROM Party.CRCNetworks CRC
		UNION
		SELECT PartyIDFrom, 
			CountryID						-- V1.8
		FROM Party.RoadsideNetworks RN
		UNION
		SELECT PartyIDFrom, 
			CountryID						-- V1.15
		FROM Party.IAssistanceNetworks IA
	)
	UPDATE CD
	SET CD.CountryID = DC.CountryID,
		CD.Country = C.Country,
		CD.CountryISOAlpha2 = C.ISOAlpha2, 
		CD.CountryISOAlpha3 = C.ISOAlpha3, 
		CD.LanguageID =  CASE CD.LanguageID WHEN NULL THEN C.DefaultLanguageID ELSE CD.LanguageID END
	FROM Meta.CaseDetails_TmpBuild CD
		INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = CD.EventID			-- V1.8
		INNER JOIN DealerCountries DC ON DC.DealerPartyID = EPR.PartyID
		INNER JOIN ContactMechanism.Countries C ON C.CountryID = DC.CountryID
	WHERE CD.CountryID IS NULL


	--------------------------------------------------------------------------------------------------------------------------------------------
	-- UPDATE Meta.CaseDetails																								-- V1.11 
	-- -----------------------
	-- If we are doing a full build then replace the current Meta.CaseDetails table with the CaseDetails_TmpBuild table
	-- If we are doing an incremental update then only replace the Cases in Meta.CaseDetails table which we have in CaseDetails_TmpBuild.
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF @BuildType = 'Full'
		BEGIN 
			DROP TABLE IF EXISTS Meta.CaseDetails

			EXEC sp_rename 'Meta.CaseDetails_TmpBuild', 'CaseDetails'; 
			EXEC sp_rename N'Meta.CaseDetails.PK_CaseDetails_TmpBuild', N'PK_CaseDetails', N'INDEX';  
			EXEC sp_rename N'Meta.CaseDetails.IX_CaseDetails_TmpBuild_EventID', N'IX_CaseDetails_EventID', N'INDEX';									-- V1.16 
			EXEC sp_rename N'Meta.CaseDetails.IX_CaseDetails_TmpBuild_PartyID', N'IX_CaseDetails_PartyID', N'INDEX';  
			EXEC sp_rename N'Meta.CaseDetails.IX_CaseDetails_TmpBuild_SelectionRequirementID', N'IX_CaseDetails_SelectionRequirementID', N'INDEX';  
			EXEC sp_rename N'Meta.CaseDetails.IX_CaseDetails_TmpBuild_VehicleRoleTypeID_VehicleID_EventID', N'IX_CaseDetails_VehicleRoleTypeID_VehicleID_EventID', N'INDEX';									-- V1.16
		END
	ELSE 
		BEGIN  -- Partial
			-- Remove the OLD partial records from Meta.CaseDetails
			DELETE FROM Meta.CaseDetails
			WHERE CaseID IN (	SELECT CaseID 
					 			FROM Meta.CaseDetails_TmpBuild)

			-- Add in the NEW partial records to Meta.CaseDetails
			INSERT INTO Meta.CaseDetails
			SELECT * 
			FROM Meta.CaseDetails_TmpBuild
	END 



	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Ensure data blanked out for PartyIDs where partial GDPR Right To Erasure has been applied
	--------------------------------------------------------------------------------------------------------------------------------------------	
	UPDATE CD
	SET CD.ModelDerivative = @RemovalText, 
		CD.Title = @RemovalText, 
		CD.FirstName = @RemovalText, 
		CD.Initials = @RemovalText, 
		CD.MiddleName = @RemovalText, 
		CD.LastName = @RemovalText, 
		CD.SecondLastName = @RemovalText, 
		CD.GenderID = 0, 
		CD.LanguageID = NULL, 
		CD.OrganisationPartyID = @DummyOrganisationID,
		CD.OrganisationName = @RemovalText, 
		CD.PostalAddressContactMechanismID = @DummyPostalID, 
		CD.EmailAddressContactMechanismID = @DummyEmailID, 
		CD.CountryID = @DummyCountryID, 
		CD.Country = @RemovalText, 
		CD.CountryISOAlpha3 = NULL, 
		CD.CountryISOAlpha2 = NULL, 
		CD.VehicleID = CASE WHEN CD.ManufacturerPartyID = 2 THEN @DummyJagVehicleID ELSE @DummyLRVehicleID END, 
		CD.RegistrationNumber = NULL, 
		CD.RegistrationDate = '1900-01-01', 
		CD.ModelDescription = @RemovalText, 
		CD.VIN = @RemovalText, 
		CD.VinPrefix = '', 
		CD.ChassisNumber = '', 
		CD.ModelVariant = @RemovalText,
		CD.EventDate = '1900-01-01'
	FROM Meta.CaseDetails CD 
		INNER JOIN Sample_Audit.GDPR.ErasureRequests ER ON ER.PartyID = CD.PartyID 
														

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC Sample_Errors.dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	
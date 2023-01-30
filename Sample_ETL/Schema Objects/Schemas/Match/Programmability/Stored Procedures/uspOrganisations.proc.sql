CREATE PROCEDURE [Match].[uspOrganisations]

AS

/*
	Purpose:	Match the dealer codes in the VWT table against the dealer code held in DealerNetworks
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspCODING_Dealers
	1.1				23/07/2012		Chris Ross			Do not match South African organisations as cannot rely on address.
	1.2				02/12/2014		Chris Ross			(?)
	1.3				10/06/2016		Eddie Thomas		12449 - Added in telephone matching logic
	1.4				20/06/2016		Chris Ross			11771 - Modify to use new Lookup.vwOrganisations view
	1.5				02/08/2016		Chris Ross			12449/11771 - Re-write of telephone matching and email matching to lookup country correctly
	1.6				24/08/2016		Chris Ross			13043 - Fix to ensure existing matched Email and Phone IDs are not blanked out if parties are not matched on Email or Phone Matching.
	1.7				22/03/2017		Eddie Thomas		13700 - South Africa CRC CRM File Set up -  Moving South Africa to Telphone matching 
	1.8				22/10/2018		Chris Ledger		15056 - Add IAssistanceNetwork
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------------------------------------------------------------------------------
	-- NAME AND POSTAL ADDRESS MATCHING METHODOLOGY
	------------------------------------------------------------------------------------------------------------------

	BEGIN TRAN

		-- GET the Methodology ID
		DECLARE @PostalAddressMatchingMethodID INT
		SELECT @PostalAddressMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Postal Address'
		IF @PostalAddressMatchingMethodID IS NULL 
		BEGIN
			RAISERROR ('Name and Postal Address Party Matching Methodology - lookup ERROR.', 16, 1)
		END


		-- EXACT MATCH ORGANISATIONS
		CREATE TABLE #OrganisationMatches
		(
			 OrganisationParentAuditItemID BIGINT
			,PartyID INT
			,ContactMechanismID INT
			,Rating INT
		)
		
		-- WRITE EXACT PARENT COMPANY MATCHES TO WORKSPACE TABLE
		INSERT INTO #OrganisationMatches 
		(	
			OrganisationParentAuditItemID,
			PartyID,
			ContactMechanismID,
			Rating
		)
		SELECT
			MAX(VO.OrganisationParentAuditItemID),
			MAX(AO.PartyID),
			MAX(AO.ContactMechanismID),
			100 AS Rating
		FROM dbo.vwVWT_Organisations VO
		INNER JOIN Lookup.vwOrganisations AO ON VO.OrganisationNameChecksum = AO.OrganisationNameChecksum
										AND VO.MatchedODSAddressID = AO.ContactMechanismID
		WHERE VO.AuditItemID = VO.OrganisationParentAuditItemID -- PARENT ORGANISATIONS ONLY
		AND VO.CountryID NOT IN (SELECT CountryID FROM Lookup.vwCountries WHERE Country = 'South Africa')
		AND VO.PartyMatchingMethodologyID = @PostalAddressMatchingMethodID		-- v1.2
		GROUP BY VO.OrganisationParentAuditItemID, AO.ContactMechanismID


		-- UPDATE VWT WITH MATCHED ODS ID'S FOR PARTY AND ADDRESS
		UPDATE V
		SET
			V.MatchedODSOrganisationID = OM.PartyID,
			V.MatchedODSAddressID = OM.ContactMechanismID
		FROM dbo.VWT V
		INNER JOIN #OrganisationMatches OM ON V.OrganisationParentAuditItemID = OM.OrganisationParentAuditItemID
		WHERE ISNULL(V.MatchedODSOrganisationID, 0) = 0 -- WHERE WE'VE NOT ALREADY MATCHED
		AND V.PartyMatchingMethodologyID = @PostalAddressMatchingMethodID		-- v1.2

		-- CLEAR DOWN TEMP TABLE
		TRUNCATE TABLE #OrganisationMatches

		-- FUZZY MATCH REMAINING UNMATCHED PARENT ORGANISATIONS AND WRITE ALL MATCHES FOR EACH MATCHED ADDRESS TO TEMP TABLE
		INSERT INTO #OrganisationMatches 
		(
			OrganisationParentAuditItemID,
			PartyID,
			ContactMechanismID,
			Rating
		)
		SELECT 
			VO.OrganisationParentAuditItemID,
			AO.PartyID,
			ContactMechanismID,
			dbo.udfFuzzyMatchWeighted(VO.OrganisationName, AO.OrganisationName) AS Rating
		FROM vwVWT_Organisations VO
		INNER JOIN Lookup.vwOrganisations AO ON VO.MatchedODSAddressID = AO.ContactMechanismID
		WHERE VO.AuditItemID = VO.OrganisationParentAuditItemID 	--UNMATCHED PARENTS ONLY
		AND VO.MatchedODSOrganisationID = 0	
		AND VO.PartyMatchingMethodologyID = @PostalAddressMatchingMethodID		-- v1.2
		AND VO.CountryID NOT IN (SELECT CountryID FROM Lookup.vwCountries WHERE Country IN ('Japan', 'Republic of Korea', 'Thailand', 'South Africa'))

		-- WRITE BACK HIGHEST MATCHED RATING AND PARTY ID
		UPDATE V
		SET
			V.MatchedODSOrganisationID = TopMatches.OrganisationID,
			V.MatchedODSAddressID = TopMatches.ContactMechanismID
		FROM VWT V
		INNER JOIN (
			SELECT 	
				--IF THERE ARE 1+ ORGANISATIONS THAT ARE HIGHEST MATCHES ARBITRARILY TAKE THE LAST
				MAX(OrganisationParentAuditItemID) AS OrganisationParentAuditItemID,
				MAX(PartyID) AS OrganisationID,
				MAX(ContactMechanismID) AS ContactMechanismID,
				MAX(Rating) AS Rating
			FROM #OrganisationMatches OM
			WHERE Rating = (	
				SELECT MAX(Rating)
				FROM #OrganisationMatches OM2
				WHERE OM2.OrganisationParentAuditItemID = OM.OrganisationParentAuditItemID
				AND Rating > 50
			)
			GROUP BY 
				OrganisationParentAuditItemID,
				Rating
		) TopMatches ON V.OrganisationParentAuditItemID = TopMatches.OrganisationParentAuditItemID
		WHERE V.PartyMatchingMethodologyID = @PostalAddressMatchingMethodID		-- v1.2

		DROP  TABLE #OrganisationMatches

	COMMIT TRAN
	
	

	------------------------------------------------------------------------------------------------------------------
	-- NAME AND EMAIL ADDRESS MATCHING METHODOLOGY
	------------------------------------------------------------------------------------------------------------------

	-- GET the Methodology ID
	DECLARE @EmailAddressMatchingMethodID INT
	SELECT @EmailAddressMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address'
	IF @EmailAddressMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Email Address Party Matching Methodology - lookup ERROR.', 16, 1)
	END

	-- Get Dealers/CRC Centres/Roadside Networks that are in countries in which Email Address Lookup is allowed.  
	-- (Also include the Country so that we can ensure Companies are only matched within the same country)
	; WITH CTE_DealerCountries (DealerPartyID, CountryID) AS (
		SELECT DISTINCT
			PartyIDFrom, CountryID
		FROM [$(SampleDB)].ContactMechanism.DealerCountries
			UNION
		SELECT PartyIDFrom, CountryID				
		FROM [$(SampleDB)].Party.CRCNetworks crc
			UNION
		SELECT PartyIDFrom, CountryID				
		FROM [$(SampleDB)].Party.RoadsideNetworks rn
	)
	SELECT DISTINCT DealerPartyID, dc.CountryID 
	INTO #ValidEmailLookup_Dealers   
	FROM CTE_DealerCountries dc
	INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = dc.CountryID
	WHERE m.PartyMatchingMethodologyID = @EmailAddressMatchingMethodID



	-- Create and populate a table of all the Email Lookup Methodology records with Emails
	IF OBJECT_ID('tempdb..#RecordsForLookup') IS NOT NULL
	   DROP TABLE #RecordsForLookup
	CREATE TABLE #RecordsForLookup
		(
			AuditItemID				BIGINT, 
			OrganisationParentAuditItemID BIGINT,
			EmailAddress			NVARCHAR(510),
			PrivEmailAddress		NVARCHAR(510),
			OrganisationName		NVARCHAR(510),
			EmailContactMechanismID	INT,
			PrivEmailContactMechanismID	INT,
			PartyID					INT
		)


	INSERT INTO #RecordsForLookup (AuditItemID, OrganisationParentAuditItemID, EmailAddress, PrivEmailAddress, OrganisationName)
	SELECT	VO.AuditItemID, 
			VO.OrganisationParentAuditItemID, 
			VO.EmailAddress, 
			VO.PrivEmailAddress, 
			VO.OrganisationName
	FROM dbo.vwVWT_Organisations VO
	WHERE ( ISNULL(VO.EmailAddress, '') <> ''  OR ISNULL(VO.PrivEmailAddress, '') <> '')
	AND VO.MatchedODSOrganisationID = 0
	AND VO.PartyMatchingMethodologyID = @EmailAddressMatchingMethodID
	AND VO.CountryID NOT IN (SELECT CountryID FROM Lookup.vwCountries WHERE Country = 'South Africa')


	-- Build list of Emails and AuditIDs for lookup
	IF OBJECT_ID('tempdb..#EmailsForLookup') IS NOT NULL
	   DROP TABLE #EmailsForLookup
	CREATE TABLE #EmailsForLookup
		(
			EmailAddress			VARCHAR(200),
			OrganisationName		NVARCHAR(510),
			EmailContactMechanismID	INT,
			PartyID					INT
		)


	-- Build simplified list of names, checksums and emails for lookup
	INSERT INTO #EmailsForLookup (EmailAddress, OrganisationName)
	SELECT r.EmailAddress, r.OrganisationName
	FROM #RecordsForLookup r 
	WHERE ISNULL(r.EmailAddress, '') <> ''
	  UNION
	SELECT r.PrivEmailAddress, r.OrganisationName
	FROM #RecordsForLookup r 
	WHERE ISNULL(r.PrivEmailAddress, '') <> ''



	--- Match the organisation names and Email Addresses and update the temp table
	UPDATE l
	SET l.PartyID					= O.PartyID,
		l.EmailContactMechanismID	= pcm.ContactMechanismID
	FROM #EmailsForLookup l
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.OrganisationName = l.OrganisationName
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.PartyId = O.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = pcm.ContactMechanismID
															AND ea.EmailAddress = l.EmailAddress 
	WHERE (   EXISTS (SELECT * FROM [$(SampleDB)].Meta.PartyBestPostalAddresses bpa 	-- Use the parties postal address (where it exists) to get countryID to check whether email address matching is valid
					INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = bpa.ContactMechanismID 
					INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = pa.CountryID  AND m.PartyMatchingMethodologyID = @EmailAddressMatchingMethodID
					WHERE bpa.PartyID = pcm.PartyID)
			OR EXISTS (SELECT * FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre  -- Use Dealer PartyID from Event Party Role to check whether email address matching is valid
						INNER JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.EventID = vpre.EventID 
						INNER JOIN #ValidEmailLookup_Dealers ved ON ved.DealerPartyID = epr.PartyID
						WHERE vpre.PartyID = pcm.PartyID)
			)
		


	BEGIN TRAN  ------------------------------------------------------------
		

		-- Update the PrivEmailAddresses first  -- These have secondary priority and so any Matched +PartyIDs+ will be overwritten 
												-- in the next update of "EmailAddresses" (i.e. the main email address)
		UPDATE r
		SET r.PrivEmailContactMechanismID	= e.EmailContactMechanismID,
			r.PartyID						= e.PartyID
		FROM #RecordsForLookup r
		INNER JOIN #EmailsForLookup e ON e.EmailAddress		= r.PrivEmailAddress 
									 AND e.OrganisationName	= r.OrganisationName
									

		-- Update the EmailAddressess second - These have primary priority and so any +PartyIDs+ updated in the last step will be overwritten 
		UPDATE r
		SET r.EmailContactMechanismID	= e.EmailContactMechanismID,
			r.PartyID					= e.PartyID
		FROM #RecordsForLookup r
		INNER JOIN #EmailsForLookup e ON e.EmailAddress		= r.EmailAddress 
									 AND e.OrganisationName	= r.OrganisationName




		
		-- Set the Matched Organisation PartyID on the VWT Parent records first
		UPDATE V
		SET 
			V.MatchedODSOrganisationID = R.PartyID
		FROM dbo.VWT V
		INNER JOIN #RecordsForLookup R ON R.OrganisationParentAuditItemID = V.OrganisationParentAuditItemID
		WHERE R.PartyID IS NOT NULL

		-- Now set all of the Matched EmailAddress + PrivEmailAddress ContactMechanismIDs in the VWT
		UPDATE V															-- v1.5
		SET 
			V.MatchedODSEmailAddressID		= R.EmailContactMechanismID
		FROM dbo.VWT V
		INNER JOIN #RecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
		AND R.EmailContactMechanismID IS NOT NULL

		UPDATE V															-- v1.5
		SET 
			V.MatchedODSPrivEmailAddressID	= R.PrivEmailContactMechanismID
		FROM dbo.VWT V
		INNER JOIN #RecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
		AND R.PrivEmailContactMechanismID IS NOT NULL


	COMMIT TRAN 
	
	

	------------------------------------------------------------------------------------------------------------------
	-- NAME AND TELEPHONE MATCHING METHODOLOGY 
	------------------------------------------------------------------------------------------------------------------



	-- GET the Methodology ID
	DECLARE @TelephoneMatchingMethodID INT
	SELECT @TelephoneMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Telephone Number'
	IF @TelephoneMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Telephone Number Party Matching Methodology - lookup ERROR.', 16, 1)
	END

	-- Get Dealers/CRC Centres/Roadside Networks that are in countries in which Email Address Lookup is allowed.  
	-- (Also include the Country so that we can ensure Companies are only matched within the same country)
	; WITH CTE_DealerCountries (DealerPartyID, CountryID) AS (
		SELECT DISTINCT
			PartyIDFrom, CountryID
		FROM [$(SampleDB)].ContactMechanism.DealerCountries
			UNION
		SELECT PartyIDFrom, CountryID				
		FROM [$(SampleDB)].[Party].[CRCNetworks] crc
			UNION
		SELECT PartyIDFrom, CountryID				
		FROM [$(SampleDB)].[Party].[RoadsideNetworks] rn
			UNION
		SELECT PartyIDFrom, CountryID				
		FROM [$(SampleDB)].[Party].[IAssistanceNetworks] ian
	)
	SELECT DISTINCT DealerPartyID, dc.CountryID 
	INTO #ValidTelephoneLookup_Dealers   
	FROM CTE_DealerCountries dc
	INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = dc.CountryID
	WHERE m.PartyMatchingMethodologyID = @TelephoneMatchingMethodID



	-- Create and populate a table of all the Telephone Lookup Methodology records with Emails
	IF OBJECT_ID('tempdb..#TelRecordsForLookup') IS NOT NULL
	   DROP TABLE #TelRecordsForLookup
	CREATE TABLE #TelRecordsForLookup
		(
			AuditItemID						BIGINT, 
			OrganisationParentAuditItemID	BIGINT,
			MobileTel						NVARCHAR(70),
			PrivMobileTel					NVARCHAR(70),
			OrganisationName				NVARCHAR(510),
			MobileTelContactMechanismID		INT,
			PrivMobileTelContactMechanismID	INT,	
			PartyID							INT
		)


	INSERT INTO #TelRecordsForLookup (AuditItemID, OrganisationParentAuditItemID, MobileTel, PrivMobileTel, OrganisationName)
	SELECT	VO.AuditItemID, 
			VO.OrganisationParentAuditItemID, 
			VO.MobileTel,
			VO.PrivMobileTel,
			VO.OrganisationName
	FROM dbo.vwVWT_Organisations VO
	WHERE ( ISNULL(VO.MobileTel, '') <> ''  OR ISNULL(VO.PrivMobileTel, '') <> '')
	AND VO.MatchedODSOrganisationID = 0
	AND VO.PartyMatchingMethodologyID = @TelephoneMatchingMethodID
	
	--1.7
	--AND VO.CountryID NOT IN (SELECT CountryID FROM Lookup.vwCountries WHERE Country = 'South Africa')


	-- Build list of Emails and AuditIDs for lookup
	IF OBJECT_ID('tempdb..#TelNoForLookup') IS NOT NULL
	   DROP TABLE #TelNoForLookup
	CREATE TABLE #TelNoForLookup
		(
			TelephoneNumber				NVARCHAR(70),
			OrganisationName			NVARCHAR(510),
			TelephoneContactMechanismID	INT,
			PartyID						INT
		)


	-- Build simplified list of Org Names and Phone no's for lookup
	INSERT INTO #TelNoForLookup (TelephoneNumber, OrganisationName)
	SELECT r.MobileTel, r.OrganisationName
	FROM #TelRecordsForLookup r 
	WHERE ISNULL(r.MobileTel, '') <> ''
	  UNION
	SELECT r.PrivMobileTel, r.OrganisationName
	FROM #TelRecordsForLookup r 
	WHERE ISNULL(r.PrivMobileTel, '') <> ''



	--- Match the organisation names and Email Addresses and update the temp table
	UPDATE l
	SET l.PartyID						= O.PartyID,
		l.TelephoneContactMechanismID	= pcm.ContactMechanismID
	FROM #TelNoForLookup l
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.OrganisationName = l.OrganisationName
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.PartyId = O.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismID = pcm.ContactMechanismID
															AND tn.ContactNumber = l.TelephoneNumber 
	WHERE (   EXISTS (SELECT * FROM [$(SampleDB)].Meta.PartyBestPostalAddresses bpa 	-- Use the parties postal address (where it exists) to get countryID to check whether email address matching is valid
					INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = bpa.ContactMechanismID 
					INNER JOIN [$(SampleDB)].dbo.Markets m ON m.CountryID = pa.CountryID  AND m.PartyMatchingMethodologyID = @TelephoneMatchingMethodID
					WHERE bpa.PartyID = pcm.PartyID)
			OR EXISTS (SELECT * FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre  -- Use Dealer PartyID from Event Party Role to check whether email address matching is valid
						INNER JOIN [$(SampleDB)].Event.EventPartyRoles epr ON epr.EventID = vpre.EventID 
						INNER JOIN #ValidTelephoneLookup_Dealers ved ON ved.DealerPartyID = epr.PartyID
						WHERE vpre.PartyID = pcm.PartyID)
			)
		


	BEGIN TRAN  ------------------------------------------------------------
		

		--PrivMobileTel
		UPDATE r
		SET r.PrivMobileTelContactMechanismID	= e.TelephoneContactMechanismID,
			r.PartyID							= e.PartyID
		FROM #TelRecordsForLookup r
		INNER JOIN #TelNoForLookup e ON e.TelephoneNumber = r.PrivMobileTel 
									AND e.OrganisationName	= r.OrganisationName

		-- Update the MobileTel Last - These have primary priority and so any +PartyIDs+ updated in the last step will be overwritten 
		UPDATE r
		SET r.MobileTelContactMechanismID	= e.TelephoneContactMechanismID,
			r.PartyID						= e.PartyID
		FROM #TelRecordsForLookup r
		INNER JOIN #TelNoForLookup e ON e.TelephoneNumber = r.MobileTel 
									AND e.OrganisationName= r.OrganisationName

		

		-- Set the Matched Organisation PartyID on the VWT Parent records first
		UPDATE V
		SET 
			V.MatchedODSOrganisationID = R.PartyID
		FROM dbo.VWT V
		INNER JOIN #TelRecordsForLookup R ON R.OrganisationParentAuditItemID = V.OrganisationParentAuditItemID
		WHERE R.PartyID IS NOT NULL

		-- Now set all of the Matched MobileTel + PrivMobileTel ContactMechanismIDs in the VWT
		UPDATE V															--v1.5
		SET 
			V.MatchedODSMobileTelID		= R.MobileTelContactMechanismID
		FROM dbo.VWT V
		INNER JOIN #TelRecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
		AND R.MobileTelContactMechanismID IS NOT NULL


		UPDATE V															--v1.5
		SET 
			V.MatchedODSPrivMobileTelID	= R.PrivMobileTelContactMechanismID
		FROM dbo.VWT V
		INNER JOIN #TelRecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
		AND R.PrivMobileTelContactMechanismID IS NOT NULL



	COMMIT TRAN 
	

	
	
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
CREATE PROCEDURE [Match].[uspPeople]

AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


/*
	Purpose:	Match PARENT VWT to Audit records based on a Checksum of Name details and Address details
	
	Version			Date			Developer			Comment
	1.0				??????????		Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_People
	1.1				23/07/2012		Chris Ross			Do not match South African customers as they are using dummy addresses.
														Allow the macthing on Name and Vehicle to kick in.
	1.2				21-11-2013		Chris Ross			9678 - Add alternative matching for Roadside where we use LastName only (excluding Checksum) for matching people.
	1.3				02-12-2014		Chris Ross			11025 - Include name and email matching functionality and process based on the PartyMatchiongMethodology.
	1.4				15-06-2015		Chris Ross			11626 - Fixed bug which meant wasn't fully uniquely linking on all email match (tmp) table.
	1.5				10-06-2016		Eddie Thomas		12449 - Added in telephone matching logic
	1.6				20-06-2016		Chris Ross			11771 - Modify to use new Lookup.vwPeople and vwPeopleAndPostalAddresses views 
	1.7				15-07-2016		Chris Ross			11771/12449 - Fixes to Telephone and Email matching to use Dealer country if no address present.
	1.8				24-08-2016		Chris Ross			13043 - Fix to ensure existing matched Email and Phone IDs are not blanked out if parties are not matched on Email or Phone Matching.
	1.9				22-03-2017		Eddie Thomas		13700 - South Africa CRC CRM File Set up -  Moving South Africa to Telphone matching 
	1.10			26-03-2018		Chris Ledger		14610 - Remove South Africa specific references for using CHECKSUM. 
																South Africa uses normal matching now. 
	1.11			15-05-2018		Ben King			BUG 14561 - Customers not matching with capital letters within surnames
	1.12			22-10-2018		Chris Ledger		15056 - Add IAssistance Network
	1.13			10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	1.14			12-03-2020		Chris Ledger		BUG 18001 - Speed up LastName only + Email address lookup by splitting into 2 updates
	1.15			16-06-2021		Chris Ledger		Exclude Generic No-email Addresses from email matching 
	1.16			16-06-2021		Chris Ledger		Remove variables from queries
*/



BEGIN TRY

	------------------------------------------------------------------------------------------------------------------
	-- NAME AND POSTAL ADDRESS MATCHING METHODOLOGY
	------------------------------------------------------------------------------------------------------------------

	-- GET MATCHES PEOPLE
	CREATE TABLE #PeopleMatches
	(
		PersonParentAuditItemID BIGINT,
		PartyID INT,
		PostalAddressContactMechanismID INT,
		PartyMatchingMethodologyID INT
	)


	-- GET the Methodology ID
	DECLARE @PostalAddressMatchingMethodID INT
	SELECT @PostalAddressMatchingMethodID = ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Postal Address'
	IF @PostalAddressMatchingMethodID IS NULL 
	BEGIN
		RAISERROR ('Name and Postal Address Party Matching Methodology - lookup ERROR.', 16, 1)
	END


	--- Roadside (Non-UK only) matching - uses LastName only (not checksum) to match party 
	--------------------------------------------------------------------------
	INSERT INTO #PeopleMatches
	(
		PersonParentAuditItemID,
		PartyID,
		PostalAddressContactMechanismID,
		PartyMatchingMethodologyID 		
	)
	SELECT 
		VP.PersonParentAuditItemID,
		AP.PartyID,
		AP.ContactMechanismID,
		VP.PartyMatchingMethodologyID
	FROM dbo.vwVWT_People VP
		INNER JOIN Lookup.vwPeopleAndPostalAddresses AP ON VP.LastName = AP.LastName
													AND VP.MatchedODSAddressID = AP.ContactMechanismID
	WHERE VP.AuditItemID = VP.PersonParentAuditItemID	--UNMATCHED PARENTS ONLY
		AND VP.MatchedODSPersonID = 0
		--AND CountryID <> (	SELECT CountryID				-- V1.1  -- V1.10
		--						FROM [$(SampleDB)].ContactMechanism.Countries 
		--						WHERE Country = 'South Africa' )
		AND (VP.ODSEventTypeID IN (	SELECT EventTypeID 
									FROM [$(SampleDB)].Event.EventTypes 
									WHERE EventType IN ('I-Assistance','Roadside'))	-- V1.12  
				AND VP.CountryID <> (	SELECT CountryID 
										FROM [$(SampleDB)].ContactMechanism.Countries 
										WHERE Country = 'United Kingdom'))
		AND VP.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Postal Address') AS INT)		-- V1.16



	--- All other matching (i.e. Excluding Non-UK, Roadside) uses checksum to match party
	--------------------------------------------------------------------------
	INSERT INTO #PeopleMatches
	(
		PersonParentAuditItemID,
		PartyID,
		PostalAddressContactMechanismID,
		PartyMatchingMethodologyID 		
	)
	SELECT 
		VP.PersonParentAuditItemID,
		MAX(AP.PartyID) AS PartyID,				-- V1.11
		AP.ContactMechanismID,
		VP.PartyMatchingMethodologyID
	FROM dbo.vwVWT_People VP
		INNER JOIN Lookup.vwPeopleAndPostalAddresses AP ON VP.NameChecksum = AP.NameChecksum
													AND VP.MatchedODSAddressID = AP.ContactMechanismID
	WHERE VP.AuditItemID = VP.PersonParentAuditItemID	-- UNMATCHED PARENTS ONLY
		AND VP.MatchedODSPersonID = 0
		--AND CountryID <> (	SELECT CountryID								-- V1.1 -- V1.10
		--						FROM [$(SampleDB)].ContactMechanism.Countries 
		--						WHERE Country = 'South Africa' )
		AND (VP.ODSEventTypeID NOT IN (	SELECT EventTypeID 
										FROM [$(SampleDB)].Event.EventTypes 
										WHERE EventType IN ('I-Assistance','Roadside'))	-- V1.12   
				OR VP.CountryID = (	SELECT CountryID 
									FROM [$(SampleDB)].ContactMechanism.Countries 
									WHERE Country = 'United Kingdom'))
		AND VP.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Postal Address') AS INT)  -- V1.16
	GROUP BY VP.PersonParentAuditItemID, 
		AP.ContactMechanismID, 
		VP.PartyMatchingMethodologyID			-- V1.11

	
	-- UPDATE VWT ------------------------------------------------------------
	UPDATE V
	SET V.MatchedODSPersonID = PM.PartyID,
		V.MatchedODSAddressID = PM.PostalAddressContactMechanismID
	FROM dbo.VWT V
		INNER JOIN #PeopleMatches PM ON V.PersonParentAuditItemID = PM.PersonParentAuditItemID
	WHERE PM.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Postal Address') AS INT)  -- V1.16


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
	
	-- Create and populate a table of all the Email Lookup Methodology records with Emails
	DROP TABLE IF EXISTS #RecordsForLookup
	
	CREATE TABLE #RecordsForLookup
	(
		AuditItemID					BIGINT, 
		PersonParentAuditItemID		BIGINT,
		EmailAddress				NVARCHAR(510),
		PrivEmailAddress			NVARCHAR(510),
		LastName					NVARCHAR(100),
		NameChecksum				INT,
		LookupType					VARCHAR(50),
		EmailContactMechanismID		INT,
		PrivEmailContactMechanismID	INT,
		PartyID						INT
	)


	INSERT INTO #RecordsForLookup (AuditItemID, PersonParentAuditItemID, EmailAddress, PrivEmailAddress, LastName, NameChecksum, LookupType)
	SELECT VP.AuditItemID, 
		VP.PersonParentAuditItemID, 
		VP.EmailAddress, 
		VP.PrivEmailAddress, 
		VP.LastName, 
		VP.NameChecksum,
		CASE WHEN 	-- VP.CountryID <> (	SELECT CountryID			-- Determine whether we do a name only lookup or a LastName only lookup) -- V1.10
					--						FROM [$(SampleDB)].ContactMechanism.Countries 
					--						WHERE Country = 'South Africa' )
					--AND 
					(VP.ODSEventTypeID IN (	SELECT EventTypeID 
											FROM [$(SampleDB)].Event.EventTypes 
											WHERE EventType IN ('I-Assistance','Roadside'))				-- V1.12  
							AND VP.CountryID <> (	SELECT CountryID 
													FROM [$(SampleDB)].ContactMechanism.Countries 
													WHERE Country = 'United Kingdom'))
				THEN 'LastnameOnly' 
				ELSE 'Checksum'	END	AS LookupType
	FROM dbo.vwVWT_People VP
	WHERE (ISNULL(VP.EmailAddress, '') <> '' OR ISNULL(VP.PrivEmailAddress, '') <> '')
		AND VP.MatchedODSPersonID = 0
		AND VP.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address') AS INT)		-- V1.16


	-- Build list of Emails and AuditIDs for lookup (split by whether Checksum or LastName only lookup)
	DROP TABLE IF EXISTS #EmailsForLookup
	
	CREATE TABLE #EmailsForLookup
	(
		EmailAddress			VARCHAR(200),
		LastName				NVARCHAR(100),
		NameChecksum			INT,
		LookupType				VARCHAR(50),
		EmailContactMechanismID	INT,
		PartyID					INT
	)


	-- Build simplified list of names, checksums and emails for lookup
	INSERT INTO #EmailsForLookup (EmailAddress, LastName, NameChecksum, LookupType)
	SELECT R.EmailAddress, 
		R.LastName, 
		R.NameChecksum, 
		R.LookupType
	FROM #RecordsForLookup R 
	WHERE ISNULL(R.EmailAddress, '') <> ''
	UNION
	SELECT R.PrivEmailAddress, 
		R.LastName, 
		R.NameChecksum, 
		R.LookupType
	FROM #RecordsForLookup R 
	WHERE ISNULL(R.PrivEmailAddress, '') <> ''


	-- V1.15 Exclude Generic No-email Addresses from email matching
	DELETE FROM E
	FROM #EmailsForLookup E
		INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings BS ON E.EmailAddress = BS.BlacklistString
		INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes BT ON BS.BlacklistTypeID = BT.BlacklistTypeID
	WHERE BT.BlacklistType = 'Generic No-email Address'
		AND (GETDATE() BETWEEN BS.FromDate AND ISNULL(BS.Throughdate,'2099-01-01'))	


	-- Get Dealers that are in countries in which Email Address Lookup is allowed
	;WITH CTE_DealerCountries (DealerPartyID, CountryID) AS 
	(
		SELECT DISTINCT
			DC.PartyIDFrom, 
			DC.CountryID
		FROM [$(SampleDB)].ContactMechanism.DealerCountries DC
		UNION
		SELECT CRC.PartyIDFrom, 
			CRC.CountryID				
		FROM [$(SampleDB)].Party.CRCNetworks CRC
		UNION
		SELECT RN.PartyIDFrom, 
			RN.CountryID				
		FROM [$(SampleDB)].Party.RoadsideNetworks RN
			UNION
		SELECT IAN.PartyIDFrom, 
			IAN.CountryID				
		FROM [$(SampleDB)].Party.IAssistanceNetworks IAN
	)
	SELECT DealerPartyID 
	INTO #ValidEmailLookup_Dealers   
	FROM CTE_DealerCountries DC
		INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = DC.CountryID
	WHERE M.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address') AS INT)  -- V1.16

	
	-- Do Name Checksum + Email address lookups  -- CHECK PARTY MATCHING USING POSTAL ADDRESS OR DEALER
	--UPDATE L
	--SET L.PartyID = AP.PartyID,
	--	L.EmailContactMechanismID	= PCM.ContactMechanismID
	--FROM #EmailsForLookup L
	--INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.EmailAddress = L.EmailAddress 
	--INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = EA.ContactMechanismID
	--INNER JOIN Lookup.vwPeople AP ON AP.PartyID = PCM.PartyID 
	--						AND L.NameChecksum = AP.NameChecksum
	--WHERE EA.ContactMechanismID IS NOT NULL  
	--AND L.LookupType = 'Checksum'
	--AND (   EXISTS (SELECT * FROM [$(SampleDB)].Meta.PartyBestPostalAddresses BPA 	-- Use the parties postal address (where it exists) to get countryID to check whether email address matching is valid
	--				INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = BPA.ContactMechanismID 
	--				INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID  AND M.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address') AS INT)  -- V1.16
	--				WHERE BPA.PartyID = PCM.PartyID)
	--	 OR EXISTS (SELECT * FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE  -- Use Dealer PartyID from Event Party Role to check whether email address matching is valid
	--		  INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID 
	--		  INNER JOIN #ValidEmailLookup_Dealers VED ON VED.DealerPartyID = EPR.PartyID
	--		  WHERE VPRE.PartyID = PCM.PartyID)
	--	)


	-- V1.11 Do Name Checksum + Email address lookups  -- CHECK PARTY MATCHING USING POSTAL ADDRESS OR DEALER
	;WITH CTE_Max_PID_ContactMechanismID (PartyID, ContactMechanismID, EmailAddress, NameChecksum) AS
	(
		SELECT MAX(AP.PartyID), 
			PCM.ContactMechanismID, 
			EA.EmailAddress, 
			AP.NameChecksum
		FROM #EmailsForLookup L
			INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.EmailAddress = L.EmailAddress 
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = EA.ContactMechanismID
			INNER JOIN Lookup.vwPeople AP ON AP.PartyID = PCM.PartyID 
											AND L.NameChecksum = AP.NameChecksum
		WHERE EA.ContactMechanismID IS NOT NULL  
			AND L.LookupType = 'Checksum'
			AND (EXISTS (	SELECT * 
							FROM [$(SampleDB)].Meta.PartyBestPostalAddresses BPA 					-- Use the parties postal address (where it exists) to get countryID to check whether email address matching is valid
								INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = BPA.ContactMechanismID 
								INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID  
																		AND M.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address') AS INT)  -- V1.16
							WHERE BPA.PartyID = PCM.PartyID)
					OR EXISTS (	SELECT * 
								FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE				-- Use Dealer PartyID from Event Party Role to check whether email address matching is valid
									INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID 
									INNER JOIN #ValidEmailLookup_Dealers VED ON VED.DealerPartyID = EPR.PartyID
								WHERE VPRE.PartyID = PCM.PartyID))
		GROUP BY PCM.ContactMechanismID, 
			EA.EmailAddress, 
			AP.NameChecksum
	)
		UPDATE L
		SET L.PartyID = CTE.PartyID,
			L.EmailContactMechanismID = CTE.ContactMechanismID
		FROM #EmailsForLookup L
			INNER JOIN CTE_Max_PID_ContactMechanismID CTE ON CTE.EmailAddress = L.EmailAddress
														 AND CTE.NameChecksum = L.NameChecksum
	

	-- V1.14 Build list of Matched EmailContactMechanismID and PartyID for LastName only lookup
	DROP TABLE IF EXISTS #EmailsForLastNameLookup
	
	CREATE TABLE #EmailsForLastNameLookup
	(
		EmailAddress			VARCHAR(200),
		LastName				NVARCHAR(100),
		NameChecksum			INT,
		LookupType				VARCHAR(50),
		EmailContactMechanismID	INT,
		PartyID					INT
	)
	
	-- V1.14 Do LastName only + Email address lookup 
	INSERT INTO #EmailsForLastNameLookup (EmailAddress, LastName, NameChecksum, LookupType, EmailContactMechanismID, PartyID)
	SELECT L.EmailAddress, 
		L.LastName, 
		L.NameChecksum, 
		L.LookupType, 
		PCM.ContactMechanismID, 
		P.PartyID
	FROM #EmailsForLookup L
		INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses EA ON EA.EmailAddress = L.EmailAddress 
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = EA.ContactMechanismID
		INNER JOIN Lookup.vwPeople AP ON AP.PartyID = PCM.PartyID 
		INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = AP.PartyID
										AND L.LastName = P.LastName
	WHERE EA.ContactMechanismID IS NOT NULL  
		AND L.LookupType = 'LastnameOnly' 


	-- V1.14 DELETE from #EmailsForLastNameLookup where email address matching is not valid
	DELETE FROM L
	FROM #EmailsForLastNameLookup L
	WHERE L.LookupType = 'LastnameOnly'
		AND NOT EXISTS (	SELECT * 
							FROM [$(SampleDB)].Meta.PartyBestPostalAddresses BPA 	-- Use the parties postal address (where it exists) to get CountryID to check whether email address matching is valid
								INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = BPA.ContactMechanismID 
								INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID  
																		AND M.PartyMatchingMethodologyID = CAST((SELECT ID FROM [$(SampleDB)].dbo.PartyMatchingMethodologies WHERE PartyMatchingMethodology = 'Name and Email Address') AS INT)  -- V1.16
						WHERE BPA.PartyID = L.PartyID)
		AND NOT EXISTS (	SELECT * 
							FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE  -- Use DealerPartyID from Event Party Role to check whether email address matching is valid
								INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID 
								INNER JOIN #ValidEmailLookup_Dealers VED ON VED.DealerPartyID = EPR.PartyID
							WHERE VPRE.PartyID = L.PartyID)

	
	-- V1.14 UPDATE #EmailsForLookup from #EmailsForLastNameLookup
	UPDATE L
	SET L.PartyID = LNL.PartyID,
		L.EmailContactMechanismID = LNL.EmailContactMechanismID
	FROM #EmailsForLookup L
		INNER JOIN #EmailsForLastNameLookup LNL ON L.EmailAddress = LNL.EmailAddress 
												 AND L.LastName	= LNL.LastName
												 AND L.NameChecksum = LNL.NameChecksum
												 AND L.LookupType = LNL.LookupType


	-- Update the PrivEmailAddresses first  -- These have secondary priority and so any Matched +PartyIDs+ will be overwritten 
											-- in the next update of "EmailAddresses" (i.E. the main email address)
	UPDATE R
	SET R.PrivEmailContactMechanismID = E.EmailContactMechanismID,
		R.PartyID = E.PartyID
	FROM #RecordsForLookup R
		INNER JOIN #EmailsForLookup E ON E.EmailAddress = R.PrivEmailAddress 
										 AND E.LastName = R.LastName
										 AND E.NameChecksum = R.NameChecksum
										 AND E.LookupType = R.LookupType


	-- Update the EmailAddressess second - These have primary priority and so any +PartyIDs+ updated in the last step will be overwritten 
	UPDATE R
	SET R.EmailContactMechanismID = E.EmailContactMechanismID,
		R.PartyID = E.PartyID
	FROM #RecordsForLookup R
		INNER JOIN #EmailsForLookup E ON E.EmailAddress = R.EmailAddress 
										 AND E.LastName	= R.LastName
										 AND E.NameChecksum = R.NameChecksum
										 AND E.LookupType = R.LookupType


	-------------------------------------------------
	BEGIN TRAN 

		-- Set the MatchedPerson PartyID on the VWT Parent records first
		UPDATE V
		SET V.MatchedODSPersonID = R.PartyID
		FROM dbo.VWT V
			INNER JOIN #RecordsForLookup R ON R.PersonParentAuditItemID = V.PersonParentAuditItemID
		WHERE R.PartyID IS NOT NULL

		-- Now set all of the Matched EmailAddress + PrivEmailAddress ContactMechanismIDs in the VWT
		UPDATE V															-- V1.8
		SET V.MatchedODSEmailAddressID = R.EmailContactMechanismID
		FROM dbo.VWT V
			INNER JOIN #RecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
			AND R.EmailContactMechanismID IS NOT NULL

		UPDATE V															-- V1.8
		SET V.MatchedODSPrivEmailAddressID = R.PrivEmailContactMechanismID
		FROM dbo.VWT V
			INNER JOIN #RecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
			AND R.PrivEmailContactMechanismID IS NOT NULL	

	COMMIT TRAN
	-------------------------------------------------

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
	
	-- Create and populate a table of all the Telephone Lookup Methodology records with Telephone Numbers
	DROP TABLE IF EXISTS #TelRecordsForLookup
	
	CREATE TABLE #TelRecordsForLookup
	(
		AuditItemID						BIGINT, 
		PersonParentAuditItemID			BIGINT,
		MobileTel						NVARCHAR(70),
		PrivMobileTel					NVARCHAR(70),
		LastName						NVARCHAR(100),
		NameChecksum					INT,
		LookupType						VARCHAR(50),
		MobileTelContactMechanismID		INT,
		PrivMobileTelContactMechanismID	INT,	
		PartyID							INT
	)


	INSERT INTO #TelRecordsForLookup (AuditItemID, PersonParentAuditItemID, MobileTel, PrivMobileTel, LastName, NameChecksum, LookupType)
	SELECT	VP.AuditItemID, 
		VP.PersonParentAuditItemID, 
		VP.MobileTel, 
		VP.PrivMobileTel, 
		VP.LastName, 
		VP.NameChecksum,
		CASE	WHEN VP.CountryID <> (	SELECT CountryID			-- Determine whether we do a name only lookup or a LastName only lookup)		-- V1.10
										FROM [$(SampleDB)].ContactMechanism.Countries 
										WHERE Country = 'South Africa' )
								AND (VP.ODSEventTypeID IN (	SELECT EventTypeID 
															FROM [$(SampleDB)].Event.EventTypes 
															WHERE EventType IN ('I-Assistance','Roadside'))   
								AND VP.CountryID <> (	SELECT CountryID 
														FROM [$(SampleDB)].ContactMechanism.Countries 
														WHERE Country = 'United Kingdom'))
				THEN 'LastnameOnly' 
				ELSE 'Checksum'	END	AS LookupType
	FROM dbo.vwVWT_People VP
	WHERE (ISNULL(VP.MobileTel, '') <> ''  OR ISNULL(VP.PrivMobileTel, '') <> '')
		AND VP.MatchedODSPersonID = 0
		AND VP.PartyMatchingMethodologyID = @TelephoneMatchingMethodID


	-- Build list of telephone numbers and AuditIDs for lookup (split by whether Checksum or LastName only lookup)
	DROP TABLE IF EXISTS #TelNoForLookup
	
	CREATE TABLE #TelNoForLookup
	(
		TelephoneNumber					NVARCHAR(70),
		LastName						NVARCHAR(100),
		NameChecksum					INT,
		LookupType						VARCHAR(50),
		TelephoneContactMechanismID		INT,
		PartyID							INT
	)


	-- Build simplified list of names, checksums and emails for lookup
	INSERT INTO #TelNoForLookup (TelephoneNumber, LastName, NameChecksum, LookupType)
	SELECT R.MobileTel, 
		R.LastName, 
		R.NameChecksum, 
		R.LookupType
	FROM #TelRecordsForLookup R 
	WHERE ISNULL(R.MobileTel, '') <> ''
	UNION
	SELECT R.PrivMobileTel, 
		R.LastName, 
		R.NameChecksum, 
		R.LookupType
	FROM #TelRecordsForLookup R 
	WHERE ISNULL(R.PrivMobileTel, '') <> ''
		

	-- Get Dealers that are in countries in which Email Address Lookup is allowed
	; WITH CTE_DealerCountries (DealerPartyID, CountryID) AS 
	(
		SELECT DISTINCT
			DC.PartyIDFrom, 
			DC.CountryID
		FROM [$(SampleDB)].ContactMechanism.DealerCountries DC
		UNION
		SELECT CRC.PartyIDFrom, 
			CRC.CountryID				
		FROM [$(SampleDB)].Party.CRCNetworks CRC
		UNION
		SELECT RN.PartyIDFrom, 
			RN.CountryID				
		FROM [$(SampleDB)].Party.RoadsideNetworks RN
	)
	SELECT DC.DealerPartyID 
	INTO #ValidTelephoneLookup_Dealers   
	FROM CTE_DealerCountries DC
		INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = DC.CountryID
	WHERE M.PartyMatchingMethodologyID = @TelephoneMatchingMethodID
	
	
	-- Do Name Checksum + Telephone number lookups  -- CHECK PARTY MATCHING USING POSTAL ADDRESS OR DEALER -- USE MAXIMUM PARTYID V1.10
	UPDATE L
	SET L.PartyID = Q.PartyID,
		L.TelephoneContactMechanismID = Q.ContactMechanismID
	FROM #TelNoForLookup L INNER JOIN (	SELECT MAX(AP.PartyID) AS PartyID, 
											TN.ContactNumber, 
											PCM.ContactMechanismID, 
											AP.NameChecksum
										FROM [$(SampleDB)].ContactMechanism.TelephoneNumbers TN 
											INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = TN.ContactMechanismID
											INNER JOIN Lookup.vwPeople AP ON AP.PartyID = PCM.PartyID 
										WHERE TN.ContactMechanismID IS NOT NULL  
											AND (EXISTS (	SELECT *						-- Use the parties postal address (where it exists) to get countryID to check whether telephone number matching is valid
															FROM [$(SampleDB)].Meta.PartyBestPostalAddresses BPA 	
																INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = BPA.ContactMechanismID 
																INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID  
																										AND M.PartyMatchingMethodologyID = @TelephoneMatchingMethodID
															WHERE BPA.PartyID = PCM.PartyID)
												 OR EXISTS (	SELECT *					 -- Use Dealer PartyID from Event Party Role to check whether telephone number matching is valid
																FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE 
																	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID 
																	INNER JOIN #ValidTelephoneLookup_Dealers VED ON VED.DealerPartyID = EPR.PartyID
																WHERE VPRE.PartyID = PCM.PartyID))
										GROUP BY TN.ContactNumber, 
											PCM.ContactMechanismID, 
											AP.NameChecksum) Q ON L.NameChecksum = Q.NameChecksum
																AND L.TelephoneNumber = Q.ContactNumber
	WHERE L.LookupType = 'Checksum'

	
	-- Do LastName only + Telephone number lookup 
	UPDATE L
	SET L.PartyID = AP.PartyID,
		L.TelephoneContactMechanismID = PCM.ContactMechanismID
	FROM #TelNoForLookup L
		INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactNumber = L.TelephoneNumber 
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = TN.ContactMechanismID
		INNER JOIN Lookup.vwPeople AP ON AP.PartyID = PCM.PartyID 
		INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = AP.PartyID
													AND L.LastName = P.LastName
	WHERE TN.ContactMechanismID IS NOT NULL  
	AND L.LookupType = 'LastnameOnly' 
	AND (EXISTS (	SELECT *											-- Use the parties postal address (where it exists) to get countryID to check whether telephone number matching is valid
					FROM [$(SampleDB)].Meta.PartyBestPostalAddresses BPA 	
						INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = BPA.ContactMechanismID 
						INNER JOIN [$(SampleDB)].dbo.Markets M ON M.CountryID = PA.CountryID  
																AND M.PartyMatchingMethodologyID = @TelephoneMatchingMethodID
					WHERE BPA.PartyID = PCM.PartyID)
		 OR EXISTS (	SELECT *										-- Use Dealer PartyID from Event Party Role to check whether telephone number matching is valid
						FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE				
							INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID 
							INNER JOIN #ValidTelephoneLookup_Dealers VED ON VED.DealerPartyID = EPR.PartyID
						WHERE VPRE.PartyID = PCM.PartyID))



	-- Update the PrivMobileTel first  -- These have secondary priority and so any Matched +PartyIDs+ will be overwritten 
											-- in the next update of "MobileTel" (i.E. the main telephone)
	UPDATE R
	SET R.PrivMobileTelContactMechanismID = E.TelephoneContactMechanismID,
		R.PartyID = E.PartyID
	FROM #TelRecordsForLookup R
		INNER JOIN #TelNoForLookup E ON E.TelephoneNumber = R.PrivMobileTel 
									 AND E.LastName	= R.LastName
									 AND E.NameChecksum = R.NameChecksum
									 AND E.LookupType = R.LookupType


	-- Update the MobileTel second - These have primary priority and so any +PartyIDs+ updated in the last step will be overwritten 
	UPDATE R
	SET R.MobileTelContactMechanismID = E.TelephoneContactMechanismID,
		R.PartyID = E.PartyID
	FROM #TelRecordsForLookup R
		INNER JOIN #TelNoForLookup E ON E.TelephoneNumber = R.MobileTel 
									 AND E.LastName	= R.LastName
									 AND E.NameChecksum = R.NameChecksum
									 AND E.LookupType = R.LookupType


	--------------------------------------
	BEGIN TRAN 

		-- Set the MatchedPerson PartyID on the VWT Parent records first
		UPDATE V
		SET V.MatchedODSPersonID = R.PartyID
		FROM dbo.VWT V
			INNER JOIN #TelRecordsForLookup R ON R.PersonParentAuditItemID = V.PersonParentAuditItemID
		WHERE R.PartyID IS NOT NULL

		-- Now set all of the Matched EmailAddress + PrivEmailAddress ContactMechanismIDs in the VWT
		UPDATE V													-- V1.8
		SET V.MatchedODSMobileTelID	= R.MobileTelContactMechanismID
		FROM dbo.VWT V
			INNER JOIN #TelRecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
			AND R.MobileTelContactMechanismID IS NOT NULL

		UPDATE V													-- V1.8
		SET V.MatchedODSPrivMobileTelID	= R.PrivMobileTelContactMechanismID
		FROM dbo.VWT V
			INNER JOIN #TelRecordsForLookup R ON R.AuditItemID = V.AuditItemID
		WHERE R.PartyID IS NOT NULL
			AND R.PrivMobileTelContactMechanismID IS NOT NULL

	COMMIT 
	-----------------------------------------------------------------------------------

	DROP TABLE #PeopleMatches

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
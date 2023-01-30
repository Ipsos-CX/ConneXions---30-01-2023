
CREATE PROCEDURE Roadside.uspMatchPartiesUsingEmails

AS

/*
	Purpose:  Find all the Email Contact Mechanisms associated with the Supplied emails and 
			  determine if any of the associated parties have the same name.  We then populate the email  
			  addresses IDs as well as the partyIDs in the Roadside staging table for picking up by the 
			  Roadside load to VWT proc.
	
	Version			Date			Developer			Comment
	1.0				05-05-2016		Chris Ross			Original version.  BUG 12569.  
														
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


		------------------------------------------------------------------------
		-- Create Table of unmatched Names and Emails to search for... 
		------------------------------------------------------------------------
		
		CREATE TABLE #RoadsideEmailsToSearch
			(
				RoadsideID			BIGINT,
				EmailAddress		NVARCHAR(510),
				Firstname			NVARCHAR(100), 
				SurnameField1		NVARCHAR(100), 
				SurnameField2		NVARCHAR(100)
			)
		INSERT INTO #RoadsideEmailsToSearch
				(
					RoadsideID	,
					EmailAddress,
					Firstname	,
					SurnameField1,
					SurnameField2
				)
		SELECT	CONVERT(BIGINT, re.RoadsideID) AS RoadsideID, 
				re.EmailAddress1 AS EmailAddress, 
				re.Firstname, 
				re.SurnameField1, 
				re.SurnameField2
		FROM [Roadside].[RoadsideEvents] re
		WHERE CountryID IN (SELECT CountryID FROM [$(SampleDB)].dbo.Markets WHERE ISNULL(AltRoadsideEmailMatching, 0) = 1)  -- Only markets that have alternative Email matched flagged
			AND ISNULL(MatchedODSPersonID, 0) = 0   -- Only get unmatched records
			AND ISNULL(MatchedODSOrganisationID, 0) = 0   -- Only get unmatched records
			AND DateTransferredToVWT IS NULL			-- that haven't already been loaded to VWT
			AND NULLIF(EmailAddress1, '') IS NOT NULL 
			-- Screen out emails which are on the blacklist --------------------------------------------------------------------------------------------------------------------
			AND NOT EXISTS (SELECT BlacklistString FROM [$(SampleDB)].[ContactMechanism].[BlacklistStrings]	WHERE Operator = 'LIKE'		AND EmailAddress1 LIKE		BlacklistString) 	
			AND NOT EXISTS (SELECT BlacklistString FROM [$(SampleDB)].[ContactMechanism].[BlacklistStrings]	WHERE Operator = 'NOT LIKE' AND EmailAddress1 NOT LIKE	BlacklistString) 	
			AND NOT EXISTS (SELECT BlacklistString FROM [$(SampleDB)].[ContactMechanism].[BlacklistStrings]	WHERE Operator = '='		AND EmailAddress1 =			BlacklistString) 
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------
		UNION
		SELECT CONVERT(BIGINT, re.RoadsideID) AS RoadsideID, re.EmailAddress2 AS EmailAddress, re.Firstname, re.SurnameField1, re.SurnameField2
		FROM [Roadside].[RoadsideEvents] re
		WHERE CountryID = (SELECT CountryID FROM [$(SampleDB)].dbo.Markets WHERE ISNULL(AltRoadsideEmailMatching, 0) = 1) -- Only markets that have alternative Email matched flagged
			AND ISNULL(MatchedODSPersonID, 0) = 0   -- Only get unmatched records
			AND ISNULL(MatchedODSOrganisationID, 0) = 0   -- Only get unmatched records
			AND DateTransferredToVWT IS NULL			-- that haven't already been loaded to VWT
			AND NULLIF(EmailAddress2, '') IS NOT NULL
			-- Screen out emails which are on the blacklist --------------------------------------------------------------------------------------------------------------------
			AND NOT EXISTS (SELECT BlacklistString FROM [$(SampleDB)].[ContactMechanism].[BlacklistStrings]	WHERE Operator = 'LIKE'		AND EmailAddress2 LIKE		BlacklistString) 	
			AND NOT EXISTS (SELECT BlacklistString FROM [$(SampleDB)].[ContactMechanism].[BlacklistStrings]	WHERE Operator = 'NOT LIKE' AND EmailAddress2 NOT LIKE	BlacklistString) 	
			AND NOT EXISTS (SELECT BlacklistString FROM [$(SampleDB)].[ContactMechanism].[BlacklistStrings]	WHERE Operator = '='		AND EmailAddress2 =			BlacklistString) 
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------





		------------------------------------------------------------------------
		-- Find all matches 
		------------------------------------------------------------------------
		
		CREATE TABLE #EmailMatches
			(
				RowID				BIGINT,
				RoadsideID			BIGINT,
				PartyID				BIGINT,
				EmailAddress		NVARCHAR(510),
				ContactMechanismID	BIGINT
			)

		INSERT INTO #EmailMatches
				(
					RowID				,
					RoadsideID			,
					PartyID				,
					EmailAddress		,
					ContactMechanismID
				)
		SELECT  ROW_NUMBER() OVER(PARTITION BY bre.RoadsideID ORDER BY pcm.FromDate DESC) AS RowID,
				RoadsideID,
				P.PartyID,
				ea.EmailAddress,
				ea.ContactMechanismID
		FROM #RoadsideEmailsToSearch bre
		INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea ON ea.EmailAddress = bre.EmailAddress
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.ContactMechanismID = ea.ContactMechanismID
		INNER JOIN [$(SampleDB)].Party.People p ON p.PartyID = pcm.PartyID
		WHERE REPLACE(RTRIM(LTRIM(p.LastName)) + ' ' + RTRIM(LTRIM(p.SecondLastName)), '  ', ' ') = REPLACE(RTRIM(LTRIM(bre.SurnameField1)) + ' ' + RTRIM(LTRIM(bre.SurnameField2)), '  ', ' ')
		AND SUBSTRING(LTRIM(bre.FirstName), 1, 1) = SUBSTRING(LTRIM(p.FirstName), 1, 1)
		ORDER BY bre.RoadsideID, pcm.FromDate DESC



		------------------------------------------------------------------------
		-- UPDATE the Email ContactMechanism IDs and PartyIDs (for the primary 
		-- matched Email Address) in the Roadside table
		------------------------------------------------------------------------
		
		UPDATE re
		SET re.[MatchedODSEmailAddress1ID] = em.ContactMechanismID,
			re.MatchedODSPersonID = em.PartyID
		FROM #EmailMatches em
		INNER JOIN  [Roadside].[RoadsideEvents] re ON re.RoadsideID = em.RoadsideID 
												  AND re.EmailAddress1 = em.EmailAddress
		WHERE em.RowID = 1 -- Only use the primary matches

		UPDATE re
		SET re.[MatchedODSEmailAddress2ID] = em.ContactMechanismID,
			re.MatchedODSPersonID = em.PartyID
		FROM #EmailMatches em
		INNER JOIN  [Roadside].[RoadsideEvents] re ON re.RoadsideID = em.RoadsideID 
												  AND re.EmailAddress2 = em.EmailAddress
		WHERE em.RowID = 1 -- Only use the primary matches

			
			
	
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
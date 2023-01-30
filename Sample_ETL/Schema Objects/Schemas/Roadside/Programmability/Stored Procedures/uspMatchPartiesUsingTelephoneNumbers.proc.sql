
CREATE PROCEDURE Roadside.uspMatchPartiesUsingTelephoneNumbers

AS

/*
	Purpose:  Find all the Mobile Contact Mechanisms associated with the Supplied Mobile Numbers and 
			  determine if any of the associated parties have the same name.  We then populate the MobileTelephoneNumber IDs
			  as well as the partyIDs in the Roadside staging table for picking up by the Roadside load to VWT proc.
	
	Version			Date			Developer			Comment
	1.0				2018-05-05		Chris Ledger		NEW
														
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
		-- Create Table of unmatched Names and Mobile Telephone Numbers to search for... 
		------------------------------------------------------------------------
		
		CREATE TABLE #RoadsideTelephoneNumbersToSearch
			(
				RoadsideID					BIGINT,
				MobileTelephoneNumber		NVARCHAR(510),
				Firstname					NVARCHAR(100), 
				SurnameField1				NVARCHAR(100), 
				SurnameField2				NVARCHAR(100)
			)
		INSERT INTO #RoadsideTelephoneNumbersToSearch
				(
					RoadsideID	,
					MobileTelephoneNumber,
					Firstname	,
					SurnameField1,
					SurnameField2
				)
		SELECT	CONVERT(BIGINT, re.RoadsideID) AS RoadsideID, 
				re.MobileTelephoneNumber, 
				re.Firstname, 
				re.SurnameField1, 
				re.SurnameField2
		FROM Roadside.RoadsideEvents re
		WHERE CountryID IN (SELECT CountryID FROM [$(SampleDB)].dbo.Markets WHERE ISNULL(AltRoadsideTelephoneMatching, 0) = 1)  -- Only markets that have alternative Telephone matched flagged
			AND ISNULL(MatchedODSPersonID, 0) = 0			-- Only get unmatched records
			AND ISNULL(MatchedODSOrganisationID, 0) = 0		-- Only get unmatched records
			AND DateTransferredToVWT IS NULL				-- that haven't already been loaded to VWT
			AND NULLIF(MobileTelephoneNumber, '') IS NOT NULL 



		------------------------------------------------------------------------
		-- Find all matches 
		------------------------------------------------------------------------
		
		CREATE TABLE #TelephoneMatches
			(
				RowID						BIGINT,
				RoadsideID					BIGINT,
				PartyID						BIGINT,
				MobileTelephoneNumber		NVARCHAR(510),
				ContactMechanismID			BIGINT
			)

		INSERT INTO #TelephoneMatches
				(
					RowID					,
					RoadsideID				,
					PartyID					,
					MobileTelephoneNumber	,
					ContactMechanismID
				)
		SELECT  ROW_NUMBER() OVER(PARTITION BY brtn.RoadsideID ORDER BY pcm.FromDate DESC) AS RowID,
				RoadsideID,
				P.PartyID,
				tn.ContactNumber,
				tn.ContactMechanismID
		FROM #RoadsideTelephoneNumbersToSearch brtn
		INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers tn ON tn.ContactNumber = brtn.MobileTelephoneNumber
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = tn.ContactMechanismID
												AND cm.ContactMechanismTypeID = (SELECT ContactMechanismTypeID 
																			FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes 
																			WHERE ContactMechanismType = 'Phone (mobile)') 
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.ContactMechanismID = tn.ContactMechanismID
		INNER JOIN [$(SampleDB)].Party.People p ON p.PartyID = pcm.PartyID
		WHERE REPLACE(RTRIM(LTRIM(p.LastName)) + ' ' + RTRIM(LTRIM(p.SecondLastName)), '  ', ' ') = REPLACE(RTRIM(LTRIM(brtn.SurnameField1)) + ' ' + RTRIM(LTRIM(brtn.SurnameField2)), '  ', ' ')
		AND SUBSTRING(LTRIM(brtn.FirstName), 1, 1) = SUBSTRING(LTRIM(p.FirstName), 1, 1)
		ORDER BY brtn.RoadsideID, pcm.FromDate DESC



		------------------------------------------------------------------------
		-- UPDATE the Telephone Number ContactMechanism IDs and PartyIDs (for the matched Mobile Number) in the Roadside table
		------------------------------------------------------------------------
		
		UPDATE re
		SET re.MatchedODSMobileTelephoneNumberID = tm.ContactMechanismID,
			re.MatchedODSPersonID = tm.PartyID
		FROM #TelephoneMatches tm
		INNER JOIN  [Roadside].[RoadsideEvents] re ON re.RoadsideID = tm.RoadsideID 
												  AND re.MobileTelephoneNumber = tm.MobileTelephoneNumber
		WHERE tm.RowID = 1 -- Only use the primary matches

			
			
	
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
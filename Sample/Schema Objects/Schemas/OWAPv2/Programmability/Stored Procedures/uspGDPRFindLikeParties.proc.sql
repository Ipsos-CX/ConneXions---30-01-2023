
CREATE PROCEDURE OWAPv2.uspGDPRReturnLikeParties
	
	@PartyID					BIGINT, 
	@FuzzyMatchWeighting		INT,
	@Validated					BIT OUTPUT,  
	@ValidationFailureReason	VARCHAR(255) OUTPUT
AS
SET NOCOUNT ON


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


/*
	Purpose: Attempts to find any parties which may be the same individual as the supplied PartyID.  It does this 
			 by checking linked parties using Contact Mechanisms, Vehicles and Organisations and matching based on 
			 a fuzzy match weighting value.
		
	Version			Date			Developer			Comment
	1.0				28-11-2018		Chris Ross			BUG 14877 - Original version.
	1.1				21-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/



		------------------------------------------------------------------------
		-- Check params populated correctly
		------------------------------------------------------------------------

		SET @Validated = 0

			
		IF	@PartyID IS NULL
		BEGIN
			SET @ValidationFailureReason = '@PartyID parameter has not been supplied'
			RETURN 0
		END 


		IF	(SELECT PartyID FROM Party.People WHERE PartyID = @PartyID) IS NULL
		BEGIN
			SET @ValidationFailureReason = 'PartyID is not found in the Party.People table'
			RETURN 0
		END 


		IF	(SELECT PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er WHERE er.PartyID = @PartyID) IS NOT NULL
		BEGIN
			SET @ValidationFailureReason = 'This Party has already been GDPR Erased'
			RETURN 0
		END 


		IF	@FuzzyMatchWeighting IS NULL
		BEGIN
			SET @ValidationFailureReason = '@FuzzyMatchWeighting parameter has not been supplied'
			RETURN 0
		END 


		IF	@FuzzyMatchWeighting < 1 
		OR 	@FuzzyMatchWeighting > 100 
		BEGIN
			SET @ValidationFailureReason = 'FuzzyMatchWeighting must be between 1 and 100'
			RETURN 0
		END 
		
		
		SET @Validated = 1
		


		------------------------------------------------------------------------
		-- Find like parties
		------------------------------------------------------------------------
	

		;WITH CTE_ConcatRecs
		AS (
				--- find via contact mechanisms
				select DISTINCT 
							p.PartyId AS PartyID_Lookup, 
							p.FirstName AS FirstName_Lookup, 
							p.LastName AS Lastname_Lookup, 
							p2.PartyID, 
							p2.FirstName, 
							p2.LastName, 
							dbo.udfFuzzyMatchWeighted(p.LastName, p2.LastName) AS MatchRating,
							CASE WHEN pa.ContactMechanismID IS NOT NULL THEN 'Postal Address'
								 WHEN ea.ContactMechanismID IS NOT NULL THEN 'Email Address'
								 WHEN tn.ContactMechanismID IS NOT NULL THEN 'Phone Number' 
								 ELSE '[Unknown]'
								 END AS LinkedOn, 
							CASE WHEN pa.ContactMechanismID IS NOT NULL THEN RTRIM(RTRIM(RTRIM(RTRIM(RTRIM(pa.Street + ' ' + pa.SubLocality)  + ' ' + pa.Locality) + ' ' + pa.Town) + ' ' + pa.Region) + ' ' + pa.PostCode)
								 WHEN ea.ContactMechanismID IS NOT NULL THEN ea.EmailAddress
								 WHEN tn.ContactMechanismID IS NOT NULL THEN tn.ContactNumber 
								 ELSE '[Unknown]'
								 END AS LinkedValue
				from Party.People p 
				inner join ContactMechanism.PartyContactMechanisms pcm ON pcm.PartyID = p.PartyID  --- Get the contact mechanisms associated with the party
				inner join ContactMechanism.PartyContactMechanisms pcm2 ON pcm2.ContactMechanismID = pcm.ContactMechanismID -- get other parties asscoiated with the contact mechanism
																		AND pcm2.PartyID <>  pcm.PartyID
				inner join Party.People p2 ON p2.PartyID = pcm2.PartyID
										  AND p2.LastName <> '[GDPR - Erased]'
				LEFT JOIN ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = pcm.ContactMechanismID
				LEFT JOIN ContactMechanism.EmailAddresses ea ON ea.ContactMechanismID = pcm.ContactMechanismID
				LEFT JOIN ContactMechanism.TelephoneNumbers tn ON tn.ContactMechanismID = pcm.ContactMechanismID
				where p.PartyID = @PartyID
				AND dbo.udfFuzzyMatchWeighted(p.LastName, p2.LastName) >= @FuzzyMatchWeighting
				AND (		SUBSTRING(p.FirstName, 1, 1) = SUBSTRING(p2.FirstName, 1, 1)
					 OR ISNULL(p.FirstName, '') = '' OR  ISNULL(p2.FirstName, '') = ''
					)
				AND NOT EXISTS (SELECT PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er WHERE er.PartyID = p2.PArtyID)   -- Ensure we do not pick up any GDPR erased parties
				
			UNION

				--- find via VehiclePartyRoleEvents VEHICLES
				select DISTINCT
							p.PartyId AS PartyID_Lookup, 
							p.FirstName AS FirstName_Lookup, 
							p.LastName AS Lastname_Lookup, 
							p2.PartyID, 
							p2.FirstName, 
							p2.LastName, 
							dbo.udfFuzzyMatchWeighted(p.LastName, p2.LastName) AS MatchRating, 
							'VIN' AS LinkedOn, 
							v.VIN AS LinkedValue
				from Party.People p 
				inner join Vehicle.VehiclePartyRoleEvents vpre ON vpre.PartyID = p.PartyID  --- Get the VPRE recs associated with the party
				INNER JOIN Vehicle.Vehicles v ON v.VehicleID = vpre.VehicleID 
				inner join Vehicle.VehiclePartyRoleEvents vpre2 ON vpre2.VehicleID = vpre.VehicleID -- get other parties associated with the VEHICLE
																		AND vpre2.PartyID <> vpre.PartyID
				inner join Party.People p2 ON p2.PartyID = vpre2.PartyID
										  AND p2.LastName <> '[GDPR - Erased]'
				where p.PartyID = @PartyID
				AND dbo.udfFuzzyMatchWeighted(p.LastName, p2.LastName) >= @FuzzyMatchWeighting
				AND (		SUBSTRING(p.FirstName, 1, 1) = SUBSTRING(p2.FirstName, 1, 1)
					 OR ISNULL(p.FirstName, '') = '' OR  ISNULL(p2.FirstName, '') = ''
					)
				AND NOT EXISTS (SELECT PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er WHERE er.PartyID = p2.PArtyID)   -- Ensure we do not pick up any GDPR erased parties

			UNION

				--- find via VehiclePartyRoleEvents ORGANISATIONS
				select DISTINCT 
							p.PartyId AS PartyID_Lookup, 
							p.FirstName AS FirstName_Lookup, 
							p.LastName AS Lastname_Lookup, 
							p2.PartyID, 
							p2.FirstName, 
							p2.LastName,  
							dbo.udfFuzzyMatchWeighted(p.LastName, p2.LastName) AS Rating, 
							'Organisation' AS LinkedOn, 
							o.OrganisationName AS LinkedValue
				from Party.People p 
				inner join Vehicle.VehiclePartyRoleEvents vpre ON vpre.PartyID = p.PartyID  --- Get the VPRE recs associated with the party

				inner join Vehicle.VehiclePartyRoleEvents vpre2 ON vpre2.EventID = vpre.EventID  --- Get the VPRE recs associated with the Event (excluding the original Person PartyID linked on)
																AND vpre2.PartyID <> p.PartyID

				INNER JOIN Party.Organisations o ON o.PartyID = vpre2.PartyID		-- Join to the orgs

				inner join Vehicle.VehiclePartyRoleEvents vpre3 ON vpre3.PartyID = o.PartyID -- get other events associated with the Organisation
																AND vpre3.EventID <> vpre2.EventID  -- ??? ignore original eventID ...or include as may have different parties attached?? covered above?

				inner join Vehicle.VehiclePartyRoleEvents vpre4 ON vpre4.EventID = vpre3.EventID -- get other parties associated with the Organisation's events
																		AND vpre4.PartyID <> p.PartyID  -- but not original Party
																		AND vpre4.PartyID <> o.PartyID  -- and not linking organisation
				inner join Party.People p2 ON p2.PartyID = vpre4.PartyID
										  AND p2.LastName <> '[GDPR - Erased]'
				WHERE p.PartyID = @PartyID
				AND dbo.udfFuzzyMatchWeighted(p.LastName, p2.LastName) >= @FuzzyMatchWeighting
				AND (		SUBSTRING(p.FirstName, 1, 1) = SUBSTRING(p2.FirstName, 1, 1)
					 OR ISNULL(p.FirstName, '') = '' OR  ISNULL(p2.FirstName, '') = ''
					)
				AND NOT EXISTS (SELECT PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er WHERE er.PartyID = p2.PArtyID)   -- Ensure we do not pick up any GDPR erased parties
		)
		SELECT	PartyID_Lookup,
				FirstName_Lookup,
				Lastname_Lookup,
				PartyID,
				FirstName,
				LastName,
				MatchRating,
				LinkedOn,
				LinkedValue
		FROM CTE_ConcatRecs
		ORDER BY PartyID, LastName, FirstName, LinkedOn, LinkedValue




	RETURN 1


END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(Sample_Errors)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)

END CATCH


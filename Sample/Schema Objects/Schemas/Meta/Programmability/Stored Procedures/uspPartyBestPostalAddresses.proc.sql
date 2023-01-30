CREATE PROC Meta.uspPartyBestPostalAddresses

AS

/*
	Purpose:	Drops, recreates and reindexes Meta.PartyBestPostalAddresses META table which is a denormalised set of data containing the latest non solicitated postal address for a party
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_Update_META_GENERAL_PartyBestPostalAddress
	1.1				2018-05-29		Chris Ledger		BUG 14621: Change from populating using view to code to pick postal address with MAX AuditItemID
	1.2				2021-06-28		Chris Ledger		TASK 533: Tidy formatting while checking code to release 1.1 LIVE

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- DROP AND RECREATE THE TABLE
	DROP TABLE IF EXISTS Meta.PartyBestPostalAddresses
	
	CREATE TABLE Meta.PartyBestPostalAddresses
	(
		PartyID dbo.PartyID,
		ContactMechanismID dbo.ContactMechanismID
	)
	
	--INSERT INTO Meta.PartyBestPostalAddresses (PartyID, ContactMechanismID)
	--SELECT PartyID, ContactMechanismID
	--FROM Meta.vwPartyBestPostalAddresses
	
	/* V1.1 	*/
	-- LOAD PartyContactMechanisms DATA INTO TEMPORARY TABLE #PartyContactMechanisms
	DROP TABLE IF EXISTS #PartyContactMechanisms

	CREATE TABLE #PartyContactMechanisms
	(
		PartyID INT,
		ContactMechanismID INT,
		AuditItemID INT,
		ActionDate DATETIME
	)

	INSERT INTO #PartyContactMechanisms (PartyID, ContactMechanismID, AuditItemID, ActionDate)
	SELECT PCM.PartyID, 
		PCM.ContactMechanismID, 
		APCM.AuditItemID, 
		F.ActionDate
	FROM ContactMechanism.PartyContactMechanisms PCM
		INNER JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
		INNER JOIN ContactMechanism.PostalAddresses PA ON CM.ContactMechanismID = PA.ContactMechanismID
		LEFT JOIN [$(Sample_Audit)].Audit.PartyContactMechanisms APCM ON PCM.ContactMechanismID = APCM.ContactMechanismID
																	AND PCM.PartyID = APCM.PartyID
		LEFT JOIN [$(Sample_Audit)].dbo.AuditItems AI ON APCM.AuditItemID = AI.AuditItemID
		LEFT JOIN [$(Sample_Audit)].dbo.Files F ON AI.AuditID = F.AuditID
													AND F.ActionDate > '1900-01-01'
	WHERE CM.Valid = 1
		AND CASE PA.CountryID	WHEN (	SELECT CountryID 
										FROM ContactMechanism.Countries
										WHERE Country = 'Italy') THEN NULLIF(RTRIM(LTRIM(PA.Street)), '')
								ELSE ''	END IS NOT NULL
		-- Check non-solicitation doesn't exist for this ContactMechanism 
		AND NOT EXISTS (	SELECT NS.NonSolicitationID
							FROM dbo.Nonsolicitations NS 
								INNER JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID
																				AND CMNS.ContactMechanismID = PCM.ContactMechanismID
							WHERE NS.PartyID = PCM.PartyID 
								AND (NS.FromDate < GETDATE() OR FromDate IS NULL) 
								AND (NS.ThroughDate > GETDATE() OR NS.ThroughDate IS NULL))
		-- Check non-solicitation doesn't exist for this ContactMechanismType
		AND NOT EXISTS (	SELECT NS.NonSolicitationID
							FROM dbo.Nonsolicitations NS 
								INNER JOIN ContactMechanism.ContactMechanismTypeNonSolicitations CMNTS ON CMNTS.NonSolicitationID = NS.NonSolicitationID
																				AND CMNTS.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal Address')
							WHERE NS.PartyID = PCM.PartyID 
								AND (NS.FromDate < GETDATE() OR FromDate IS NULL) 
								AND (NS.ThroughDate > GETDATE() OR NS.ThroughDate IS NULL))
		-- Check non-solicitation doesn't exist for this Party
		AND NOT EXISTS (	SELECT NS.NonSolicitationID
							FROM dbo.NonSolicitations NS 
								INNER JOIN Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
							WHERE NS.PartyID = PCM.PartyID 
								AND (NS.FromDate < GETDATE() OR FromDate IS NULL) 
								AND (NS.ThroughDate > GETDATE() OR NS.ThroughDate IS NULL)) 


	INSERT INTO Meta.PartyBestPostalAddresses (PartyID, ContactMechanismID)
	SELECT A.PartyID, 
		CASE	WHEN B.PartyID IS NOT NULL THEN MAX(B.ContactMechanismID)	-- Available AuditItemID
				ELSE MAX(A.ContactMechanismID) END AS ContactMechanismID	-- No Available AuditItemID
	FROM #PartyContactMechanisms A
		LEFT JOIN (	SELECT PCM.PartyID, 
						MAX(PCM.ContactMechanismID) AS ContactMechanismID
					FROM #PartyContactMechanisms PCM 
						INNER JOIN (	SELECT PCM.PartyID,					-- Select Max AuditItemID 
											MAX(PCM.AuditItemID) AS AuditItemID
										FROM #PartyContactMechanisms PCM
										WHERE PCM.ActionDate IS NOT NULL
										GROUP BY PCM.PartyID) A	ON A.PartyID = PCM.PartyID
																	AND A.AuditItemID = PCM.AuditItemID
					GROUP BY PCM.PartyID) B ON A.PartyID = B.PartyID
	GROUP BY A.PartyID, 
		B.PartyID
	

	ALTER TABLE Meta.PartyBestPostalAddresses WITH NOCHECK
	ADD CONSTRAINT PK_META_PartyBestPostalAddresses PRIMARY KEY CLUSTERED 
	(
		PartyID,
		ContactMechanismID
	) ON [PRIMARY]

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
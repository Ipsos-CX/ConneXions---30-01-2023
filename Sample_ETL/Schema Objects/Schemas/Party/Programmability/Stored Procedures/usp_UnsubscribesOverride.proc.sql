﻿CREATE PROCEDURE [Party].[usp_UnsubscribesOverride]
@BugNumber NVARCHAR (20)
AS
SET NOCOUNT ON

/*
	Purpose:	Alter contact preferences by PID
			
	Version			Date			Developer			Comment
	1.0				06/07/2018		Ben King			Creation BUG 14486
	1.1				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
	UPDATE	UPO
	SET		UPO.EventCategoryID = EC.EventCategoryID
	FROM	Party.UnsubscribesOverride UPO	
	INNER JOIN [$(SampleDB)].Event.EventCategories EC ON EC.EventCategory = UPO.EventCategory 
	
	
	IF Exists( 
				SELECT	   cp.PartyId 
				FROM	   Party.UnsubscribesOverride upo
				LEFT JOIN [$(SampleDB)].party.contactpreferences cp ON cp.PartyID = upo.partyId
				WHERE cp.PartyID is NULL
			)			 
			
			RAISERROR(	N'Check PartyIds run are ALL set up in table Sample.Party.ContactPreferences', 
						16,
						1
					 )
					 
	IF Exists( 
				SELECT	EventCategory
				FROM	Party.UnsubscribesOverride	
				WHERE	EventCategory <> 'ALL' AND EventCategoryID IS NULL
			)			 
			
			RAISERROR(	N'Event Categories are not matching Sample.Event.EventCategories table.', 
						16,
						1
					 )
					 
	IF Exists( 
				SELECT	 cps.PartyId 
				FROM	 Party.UnsubscribesOverride upo
				LEFT JOIN [$(SampleDB)].party.ContactPreferencesBySurvey cps ON cps.PartyID = upo.partyId
																	AND	   cps.EventCategoryID = upo.EventCategoryID	 
				WHERE	 cps.PartyID is NULL
				AND		 upo.EventCategory <> 'ALL'
			)			 
			
			RAISERROR(	N'Check that all PartyId Event Category combinations are set-up in table Sample.Party.ContactPreferencesBySurvey.', 
						16,
						1
					 )
	
	
		--CREATE DUMMY FILE WHICH WE'LL ASSOCIATE UPDATES TO
		DECLARE @FileName [dbo].[FileName], 
				@FileType VARCHAR (50), 
				@FileRowCount INT, 
				@FileChecksum INT,
				@LoadSuccess INT

		SELECT  @FileName		= 'BUG' + @BugNumber + '_Unsubscribe_Removal',
				@FileType		= 'Sample Updates', 
				@FileRowCount   = 0, 
				@FileChecksum	= 1,
				@LoadSuccess	= 0

		EXEC    [Audit].[uspAddIncomingFileToAudit] @FileName, @FileType, 
		        @FileRowCount, @FileChecksum, @LoadSuccess

		-- GENERATE THE Audit
		DECLARE @MaxAuditID AS INT
				
		SELECT  @MaxAuditID  = MAX(AuditID) FROM [$(AuditDB)].dbo.Audit


		--UPDATE FILE DATE SO THE FILE IS OUT OF WINDOW FOR THE SAMPLE REPORTS 
		UPDATE	[$(AuditDB)].dbo.Files 
		SET		ActionDate = '1900-01-01'
		WHERE	AuditID = @MaxAuditID 

		--NB: SELECT SPECIFIC EVENT CATEGORIES TO RUN UPDATE ON. PRESERVER ORIGINAL VALUE OF PartyUnsubscribe
		SELECT  cpr.PartyID, cpr.MarketCountryID, cpr.EventCategoryID, cpr.BugNumber, cpr.RemoveUnsubscribe
		INTO    #ConPref
		FROM    Party.UnsubscribesOverride cpr
		WHERE   cpr.ProcessDate IS NULL AND BugNumber = @BugNumber
		

		SELECT	DISTINCT IDENTITY(INT, 1,1) AS ID, cp.*
		INTO	#ConPref2
		FROM	#ConPref CP

		-- GENERATE THE AuditItems
		DECLARE @MaxAuditItemID AS BIGINT
				
		SELECT  @MaxAuditItemID = MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems


		INSERT INTO [$(AuditDB)].dbo.audititems (auditid, AuditItemID)
		SELECT  @MaxAuditID, ID + @maxAuditItemid
		FROM    #conpref2


		 --RUN UPDATE  
		INSERT INTO [$(SampleDB)].[Party].[vwDA_ContactPreferences] (AuditItemID, PartyID, EventCategoryID,
				PartySuppression, PostalSuppression, EmailSuppression, PhoneSuppression, 
				PartyUnsubscribe, UpdateSource, MarketCountryID, OverridePreferences, RemoveUnsubscribe, 
				Comments)

		SELECT  cpr.ID + @maxAuditItemid as AuditItemID, 
				cpr.PartyID,  
				cpr.EventCategoryID,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				'usp_UnsubscribesOverride' AS UpdateSource,
				 ISNULL(cpr.MarketCountryID,0) AS MarketCountryID, 
				0 AS OverridePreferences, 
				cpr.RemoveUnsubscribe,
				'BugNo_' + cpr.BugNumber + '_Unsubscribe_Removal' AS Comments
		FROM    #ConPref2 cpr
		 
		UPDATE  Party.UnsubscribesOverride
		SET     ProcessDate = GETDATE()
		WHERE   ProcessDate IS NULL	
		AND		BugNumber = @BugNumber
			
	COMMIT

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

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage

	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH





GO


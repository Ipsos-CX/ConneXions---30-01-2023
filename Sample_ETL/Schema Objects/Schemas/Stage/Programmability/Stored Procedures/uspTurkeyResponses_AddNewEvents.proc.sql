CREATE PROCEDURE Stage.uspTurkeyResponses_AddNewEvents

AS

/*
		Purpose:	SP to load new events
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-12		Chris Ledger		Created
LIVE	1.1			2021-12-07		Chris Ledger		Task 598 - replace e_bp_uniquerecordid_txt with e_jlr_case_id_text
LIVE	1.2			2022-03-09		Chris Ledger		Task 821 - do not process events without date 
LIVE	1.3			2022-04-08		Chris Ledger		Task 850 - only create new cases if data validated
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		DECLARE	@MaxEventID BIGINT

		-- CREATE TEMP TABLE TO HOLD NEW EVENTS
		DECLARE @NewEvents TABLE
		(
			NewEventID INT IDENTITY(1, 1),
			EventID INT,
			EventDate DATETIME2,
			EventDateOrig NVARCHAR(50),
			EventTypeID INT,
			DealerID BIGINT,
			VehicleID INT,
			e_jlr_case_id_text  VARCHAR(50)			-- V1.1
		)


		-- GET DISTINCT NEW EVENTS ONLY 
		INSERT INTO @NewEvents
		(
			EventDate,
			EventDateOrig,
			EventTypeID,
			DealerID,
			VehicleID,
			e_jlr_case_id_text						-- V1.1
		)
		SELECT DISTINCT
			TR.e_jlr_event_date AS EventDate,
			TR.e_jlr_event_date AS EventDateOrig,
			TR.EventTypeID,
			TR.OutletPartyID AS DealerID,
			TR.VehicleID,
			e_jlr_case_id_text						-- V1.1
		FROM Stage.TurkeyResponses TR
		WHERE ISNULL(TR.EventID, 0) = 0
			AND TR.e_jlr_event_date_converted IS NOT NULL		-- V1.2
			AND ISNULL(TR.ValidatedData,0) = 1		-- V1.3
 

		-- GET NEXT AVAILABLE EVENT ID
		SELECT @MaxEventID = ISNULL(MAX(EventID), 0) FROM [$(SampleDB)].Event.Events


		-- ASSIGN EVENT ID TO NEW EVENTS
		UPDATE @NewEvents SET EventID = NewEventID + @MaxEventID


		-- WRITE BACK NEWLY CREATED EVENT IDS TO TURKEYRESPONSES
		UPDATE TR
		SET TR.EventID = NE.EventID
		FROM Stage.TurkeyResponses TR
			INNER JOIN @NewEvents NE ON ISNULL(TR.e_jlr_event_date, GETDATE()) = ISNULL(NE.EventDate, GETDATE())
									AND TR.EventTypeID = NE.EventTypeID
									AND TR.OutletPartyID = NE.DealerID
									AND TR.VehicleID = NE.VehicleID
									AND TR.e_jlr_case_id_text = NE.e_jlr_case_id_text				-- V1.1
	
			
		-- INSERT NEW EVENTS
		INSERT INTO [$(SampleDB)].Event.Events
		(
			EventID,
			EventDate,
			EventTypeID
		)
		SELECT 
			EventID,
			EventDate,
			EventTypeID
		FROM @NewEvents


		-- INSERT AUDIT EVENT RECORD
		INSERT INTO [$(AuditDB)].Audit.Events 
		(
			EventID, 
			EventDate, 
			EventDateOrig,
			EventTypeID, 
			AuditItemID
		)
		SELECT DISTINCT
			COALESCE(NULLIF(NE.EventID, 0), NULLIF(TR.EventID, 0)),
			TR.e_jlr_event_date AS EventDate, 
			TR.e_jlr_event_date AS EventDateOrig,
			TR.EventTypeID, 
			TR.AuditItemID
		FROM Stage.TurkeyResponses TR
			INNER JOIN @NewEvents NE ON ISNULL(TR.e_jlr_event_date, GETDATE()) = ISNULL(NE.EventDate, GETDATE())
									AND TR.EventTypeID = NE.EventTypeID
									AND TR.OutletPartyID = NE.DealerID
									AND TR.VehicleID = NE.VehicleID
									AND TR.e_jlr_case_id_text = NE.e_jlr_case_id_text				-- V1.1
			LEFT JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = TR.AuditItemID
		WHERE AE.AuditItemID IS NULL

	COMMIT TRAN

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
CREATE PROCEDURE Stage.uspAsiaPacificImporters_AddNewEvents

AS

/*
		Purpose:	SP to load new events
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-12		Chris Ledger		Created
LIVE	1.1			2022-04-08		Chris Ledger		Task 850: only create new events if data validated
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
			e_bp_uniquerecordid_txt  VARCHAR(50)
		)


		-- GET DISTINCT NEW EVENTS ONLY 
		INSERT INTO @NewEvents
		(
			EventDate,
			EventDateOrig,
			EventTypeID,
			DealerID,
			VehicleID,
			e_bp_uniquerecordid_txt
		)
		SELECT DISTINCT
			API.e_jlr_event_date AS EventDate,
			API.e_jlr_event_date AS EventDateOrig,
			API.EventTypeID,
			API.OutletPartyID AS DealerID,
			API.VehicleID,
			e_bp_uniquerecordid_txt
		FROM Stage.AsiaPacificImporters API
		WHERE ISNULL(API.EventID, 0) = 0
			AND ISNULL(API.ValidatedData,0) = 1		-- V1.3
 

		-- GET NEXT AVAILABLE EVENT ID
		SELECT @MaxEventID = ISNULL(MAX(EventID), 0) FROM [$(SampleDB)].Event.Events


		-- ASSIGN EVENT ID TO NEW EVENTS
		UPDATE @NewEvents SET EventID = NewEventID + @MaxEventID


		-- WRITE BACK NEWLY CREATED EVENT IDS TO ASIA_PACIFIC_IMPORTERS
		UPDATE API
		SET API.EventID = NE.EventID
		FROM Stage.AsiaPacificImporters API
			INNER JOIN @NewEvents NE ON ISNULL(API.e_jlr_event_date, GETDATE()) = ISNULL(NE.EventDate, GETDATE())
									AND API.EventTypeID = NE.EventTypeID
									AND API.OutletPartyID = NE.DealerID
									AND API.VehicleID = NE.VehicleID
									AND API.e_bp_uniquerecordid_txt = NE.e_bp_uniquerecordid_txt
	
			
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
			COALESCE(NULLIF(NE.EventID, 0), NULLIF(API.EventID, 0)),
			API.e_jlr_event_date AS EventDate, 
			API.e_jlr_event_date AS EventDateOrig,
			API.EventTypeID, 
			API.AuditItemID
		FROM Stage.AsiaPacificImporters API
			INNER JOIN @NewEvents NE ON ISNULL(API.e_jlr_event_date, GETDATE()) = ISNULL(NE.EventDate, GETDATE())
									AND API.EventTypeID = NE.EventTypeID
									AND API.OutletPartyID = NE.DealerID
									AND API.VehicleID = NE.VehicleID
									AND API.e_bp_uniquerecordid_txt = NE.e_bp_uniquerecordid_txt
			LEFT JOIN [$(AuditDB)].Audit.Events AE ON AE.AuditItemID = API.AuditItemID
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
CREATE PROCEDURE [Selection].[uspCreateSelectionsForEventsTooYoung]

AS

/*
		Purpose:	Identify Events that were flagged 'TooYoung', which and are now eligible.  
	
		Version		Date			Developer			Comment
LIVE	1.0			31/03/2022		Eddie Thomas		Created
LIVE	1.1			04/04/2022		Chris Ledger		Task 842 - only include active selections
LIVE	1.2			07/07/2022		Chris Ledger		Task 928 - change logic to exclude all CQI questionnaires
	
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		-- EVENTS WHICH WERE FLAGGED AS TOO YOUNG, BUT NOW ELIGIBLE FOR SELECTION
		CREATE TABLE #EventsTooYoung
		(
			EventID						INT,
			QuestionnaireRequirementID	INT
		)

		-- SELECTIONS THAT WE'LL TRY TO CREATE
		CREATE TABLE #SelectionsToCreate
		(
			ID							INT IDENTITY(1,1),
			QuestionnaireRequirementID	INT
		)
	

		----------------------------------------------------------------- POPULATE TABLES -----------------------------------------------------------------
		INSERT INTO	#EventsTooYoung
		SELECT		DISTINCT EV.EventID, 
					SL.QuestionnaireRequirementID 
		FROM		[$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL
		INNER JOIN	Event.Events											EV ON SL.MatchedODSEventID	= EV.EventID
		LEFT JOIN	[$(AuditDB)].[Audit].[EventDateTooYoung]				AY ON EV.EventID			= AY.EventID  
		WHERE		SL.EventDateTooYoung = 1  AND
					SL.Questionnaire NOT LIKE '%CQI%' AND		--< IGNORE CQI																				-- V1.2
					SL.NonLatestEvent = 0 AND					--< NON LATEST EVENTS NEVER MAKE IT INTO THE SELECTION POOL SO IGNORE
					EV.EventDate BETWEEN DATEADD(DAY, SL.EndDays, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, SL.StartDays, CAST(GETDATE() AS DATE)) AND
					ISNULL(SL.QuestionnaireRequirementID,0) > 0 AND
					AY.EventID IS NULL											--< NOT ALL EventDateTooYoung EVENTS WILL GENERATE A CASE, ONLY 
																				-- CREATE A SELECTION IF THIS IS THE FIRST TIME OF DOING A MOP UP.
																				-- THIS PREVENTS SUPERFLOUS SELECTIONS FROM BEING CREATED.
		ORDER BY	SL.QuestionnaireRequirementID ASC, 
					EV.EventID ASC


		INSERT			#SelectionsToCreate (QuestionnaireRequirementID)
		SELECT DISTINCT	QuestionnaireRequirementID
		FROM			#EventsTooYoung
		----------------------------------------------------------------- POPULATE TABLES -----------------------------------------------------------------


		-- DB UPDATES START HERE
		BEGIN TRAN

			---------------------------------------------- LOOP THROUGH REQ ID'S AND ATTEMPT TO CREATE SELECTIONS ----------------------------------------------
			DECLARE @MaxLoop int, 
					@Counter int

			SELECT	@MaxLoop = MAX(ID) FROM #SelectionsToCreate
			SET		@Counter = 1

			DECLARE @ManufacturerPartyID		INT,
					@QuestionnaireRequirementID INT,
					@SelectionName				VARCHAR(255),
					@DateStamp					DATETIME

			WHILE @Counter <= @MaxLoop
			BEGIN
					-- Set the selection creation values
					SELECT		DISTINCT	@ManufacturerPartyID		= QR.ManufacturerPartyID , 
											@QuestionnaireRequirementID = QR.RequirementID,
											@SelectionName				= CONVERT(VARCHAR(10), GETDATE(), 112) + '_' + BMQ.SelectionName ,
											@DateStamp					= CONVERT(VARCHAR(10), GETDATE(), 112)
					FROM		#SelectionsToCreate S
					INNER JOIN	dbo.vwBrandMarketQuestionnaireSampleMetadata	BMQ ON BMQ.QuestionnaireRequirementID = S.QuestionnaireRequirementID
					INNER JOIN	Requirement.QuestionnaireRequirements			QR	ON BMQ.QuestionnaireRequirementID = QR.RequirementID 
					WHERE		S.ID = @Counter AND
								BMQ.CreateSelection = 1 AND				-- V1.1
								BMQ.SampleLoadActive = 1				-- V1.1

					-- Create the selection
					EXEC Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @DateStamp, 1

					-- increment the loop counter
					SET @Counter = @Counter + 1

			END
			---------------------------------------------- LOOP THROUGH REQ ID'S AND ATTEMPT TO CREATE SELECTIONS ----------------------------------------------

	

			------------------------------------------------------------------ SAVE TO AUDIT ------------------------------------------------------------------
			DECLARE @DateNow DATETIME2(7) = CONVERT(DATETIME2(7), GETDATE())			-- LOGGING DATE

			INSERT INTO	[$(AuditDB)].[Audit].[EventDateTooYoung] (EventID, SelectionCreationDate)
			SELECT		EventID, 
						@DateNow AS SelectionCreationDate
			FROM		#EventsTooYoung	
			------------------------------------------------------------------ SAVE TO AUDIT ------------------------------------------------------------------
		
		-- COMMIT UPDATES
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


CREATE PROCEDURE [dbo].[uspRunPreSelectionCheck]

AS

/*
	Purpose:	    Update logging table flags pre-selection. All logging table records checked regardless of if they make it through to main selections.
					**ENSURE LOGIC to update logging table fields  within "dbo.uspRunPreSelectionFlags"  is identical to the LOGIC 
					in main sample selection SP - [Selection].[uspRunSelection]**

	Version			Date			Developer			Comment
	1.0				2020-01-22	    Ben King		    Replaces BarredEmail Update in [dbo].[uspCalculateSampleQuality] 
	1.1				2020-02-05		Chris Ledger		Fix hard coded database references
														
	
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------------------------------------------------------------
	-- LOAD LOGGING TABLE RECORDS TO APPLY PRE-SELECTION TEST. 
	------------------------------------------------------------------------------------------------

	--TRUNCATE PREVIOUS RUN CHECK
	TRUNCATE TABLE dbo.PoolPreSelectionCheck


	INSERT INTO dbo.PoolPreSelectionCheck
	(
		   AuditItemID,
		   QuestionnaireRequirementID,
		   MatchedODSEventID,
		   PartyID,
		   MatchedODSEmailAddressID,
		   EventCategory,
		   EventCategoryID,
		   MatchedODSVehicleID
	)
	SELECT SQ.AuditItemID,
		   SQ.QuestionnaireRequirementID,
		   SQ.MatchedODSEventID,
		   SQ.MatchedODSOrganisationID,
		   SQ.MatchedODSEmailAddressID,
		   E.EventCategory,
		   E.EventCategoryID,
		   SQ.MatchedODSVehicleID	
	FROM dbo.SampleQualityAndSelectionLogging SQ
	INNER JOIN [$(SampleDB)].Event.EventCategories E ON SQ.Questionnaire = E.EventCategory
	WHERE LoadedDate > dateadd(DD,-1,getdate()) --- CONTROL LOADED PERIOD DATE
	AND MatchedODSOrganisationID <> 0

	UNION

	SELECT SQ.AuditItemID,
		   SQ.QuestionnaireRequirementID,
		   SQ.MatchedODSEventID,
		   SQ.MatchedODSPersonID,
		   SQ.MatchedODSEmailAddressID,
		   E.EventCategory,
		   E.EventCategoryID,
		   SQ.MatchedODSVehicleID	
	FROM dbo.SampleQualityAndSelectionLogging SQ
	INNER JOIN [$(SampleDB)].Event.EventCategories E ON SQ.Questionnaire = E.EventCategory
	WHERE LoadedDate > dateadd(DD,-1,getdate()) --- CONTROL LOADED PERIOD DATE
	AND MatchedODSPersonID <> 0

	------------------------------------------------------------------------------------------------
	-- CREATE TABLE TO HOLD QUESTIONNAIRE REQUIREMENTS TO LOOP THROUGH
	------------------------------------------------------------------------------------------------
	
	CREATE TABLE #PoolPreSelectionCheck
	(
		ID INT IDENTITY(1, 1),
		QuestionnaireRequirementID INT,

	)

	INSERT INTO #PoolPreSelectionCheck
	(
		   QuestionnaireRequirementID
	)
	SELECT 
	DISTINCT QuestionnaireRequirementID
	FROM	dbo.PoolPreSelectionCheck



	-- Variables for loop
	DECLARE @Counter INT,
			@LoopMax INT

	SELECT @LoopMax = MAX(ID) FROM #PoolPreSelectionCheck
	SET @Counter = 1

	
	WHILE @Counter <= @LoopMax
	BEGIN 
			--------------------------------------------------------------------------------------------
			-- Run through the Questionnaire Requirements
			--------------------------------------------------------------------------------------------

			-- DECLARE VARIABLES
    		   DECLARE @QuestionnaireRequirementID INT
	
				-- GET THE CURRENT RequirementID
				SELECT
					@QuestionnaireRequirementID = QuestionnaireRequirementID
				FROM #PoolPreSelectionCheck WHERE ID = @Counter

				-- RUN THE PRE-SELECTION
				EXEC [dbo].[uspRunPreSelectionFlags] @QuestionnaireRequirementID

			--Increment counter
			SET @Counter += 1

	END


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

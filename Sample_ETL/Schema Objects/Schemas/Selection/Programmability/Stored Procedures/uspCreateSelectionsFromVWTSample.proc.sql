CREATE PROCEDURE [Selection].[uspCreateSelectionsFromVWTSample]
AS

/*
	Purpose:	To trigger selections from sample in the VWT (where the triggered selection RequirementID has been set)
		
	Version			Date			Developer			Comment
	1.0				19-11-2014		Chris Ross			Original version
	1.1				12-03-2015		Eddie Thomas		BUG 11105 : Netherlands - Service Event Driven Setup
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	-- Get the selections to create ------------------------------------------------
	CREATE TABLE #SelectionsToCreate
		(
			ID								int IDENTITY(1,1),
			SampleTriggeredSelectionReqID	int
		)
	
	;WITH CTE_ReqIDs
	AS (
		SELECT DISTINCT SampleTriggeredSelectionReqID
		FROM dbo.VWT
		--WHERE SampleTriggeredSelectionReqID IS NOT NULL
		WHERE SampleTriggeredSelectionReqID > 0			--1.1	Netherlands not set up for triggered selctions
														
																	
	)
	INSERT INTO #SelectionsToCreate (SampleTriggeredSelectionReqID)
	SELECT SampleTriggeredSelectionReqID
	FROM CTE_ReqIDs

	
	-- Set the loop values ------------------------------------------------------------
	DECLARE @MaxLoop int, 
			@Counter int

	SELECT @MaxLoop = MAX(ID) FROM #SelectionsToCreate
	SET @Counter = 1

	-- Loop through the requirementIds and create selections ------------------------
	DECLARE @ManufacturerPartyID INT,
			@QuestionnaireRequirementID INT,
			@SelectionName VARCHAR(255),
			@DateStamp datetime

	WHILE @Counter <= @MaxLoop
	BEGIN
			-- Set the selection creation values
			SELECT  DISTINCT @ManufacturerPartyID = qr.ManufacturerPartyID , 
					@QuestionnaireRequirementID = qr.RequirementID,
					@SelectionName = convert(varchar(10), GETDATE(), 112) + '_' + bmq.selectionname ,
					@DateStamp = convert(varchar(10), GETDATE(), 112)
			FROM #SelectionsToCreate s
			INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata bmq ON bmq.QuestionnaireRequirementID = s.SampleTriggeredSelectionReqID
			INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements  qr on bmq.QuestionnaireRequirementID = qr.RequirementID 
			WHERE s.ID = @Counter

			-- Create the selection
			EXEC [$(SampleDB)].Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @DateStamp, 1

			-- increment the loop counter
			SET @Counter = @Counter + 1

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
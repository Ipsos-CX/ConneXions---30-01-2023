CREATE PROCEDURE [Selection].[uspCreateSelectionFromSampleDownload]
(
	@SampleFileID INT
)
AS

/*
	Purpose:	As part of the sample download process we call this stored proc to generate the appropriate selections for each type of file we load
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				19-11-2014		Chris Ross			Sample Triggered Selections changes
	1.2				24-10-2017		Chris Ledger		Bug 14335: Only Create if Existing Selection Doesn't Exist RELEASED LIVE: CL 2017-10-24
	1.3				18-05-2021		Chris Ledger		Task 441: Exclude CQI questionnaires

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- GENERATE A DATE STAMP STRING
	DECLARE @DateStamp VARCHAR(8)
	DECLARE @Today DATETIME2
	DECLARE @CreateSelections BIT = 0

	SELECT @Today = GETDATE()

	SELECT @DateStamp = CAST(YEAR(@Today) AS CHAR(4))

	SELECT @DateStamp = @DateStamp + CASE	WHEN LEN(CAST(MONTH(@Today) AS VARCHAR(2))) = 1 THEN '0' + CAST(MONTH(@Today) AS CHAR(1)) 
											ELSE CAST(MONTH(@Today) AS CHAR(2)) END

	SELECT @DateStamp = @DateStamp + CASE	WHEN LEN(CAST(DAY(@Today) AS VARCHAR(2))) = 1 THEN '0' + CAST(DAY(@Today) AS CHAR(1)) 
											ELSE CAST(DAY(@Today) AS CHAR(2)) END

	-- CREATE A TABLE TO HOLD ALL THE SELECTIONS WE NEED TO GENERATE
	CREATE TABLE #Selections
	(
		ID INT IDENTITY(1,1) NOT NULL,
		ManufacturerPartyID INT,
		QuestionnaireRequirementID INT,
		SelectionName VARCHAR(255)
	)

	-- GET THE SELECTIONS WE NEED TO GENERATE
	INSERT INTO #Selections (ManufacturerPartyID, QuestionnaireRequirementID, SelectionName)
	SELECT DISTINCT ManufacturerPartyID, 
		QuestionnaireRequirementID, 
		SelectionName
	FROM dbo.vwBrandMarketQuestionnaireSampleMetadata
	WHERE SampleFileID = @SampleFileID
		AND CreateSelection = 1
		AND SampleTriggeredSelection = 0		-- V1.1 - Do create if flagged as sample created selections
		AND Questionnaire NOT LIKE '%CQI%'		-- V1.3

	-- LOOP THROUGH EACH OF THE SELECTIONS AND GENERATE IT
	DECLARE @ManufacturerPartyID INT
	DECLARE @QuestionnaireRequirementID INT
	DECLARE @SelectionName VARCHAR(255)

	DECLARE @MAXID INT
	SELECT @MAXID = MAX(ID) FROM #Selections

	DECLARE @Counter INT
	SET @Counter = 1

	WHILE @Counter <= @MAXID
	BEGIN

		-- GET THE VALUES FROM #Selections
		SELECT  @ManufacturerPartyID = ManufacturerPartyID,
			@QuestionnaireRequirementID = QuestionnaireRequirementID,
			@SelectionName = @DateStamp + '_' + SelectionName
		FROM #Selections
		WHERE ID = @Counter


		/* V1.2 SET CREATE SELECTION FLAG IF WE HAVE YET TO CREATE SELECTION FOR THIS DATE */
		SELECT @CreateSelections = CASE	WHEN COUNT(*) > 0 THEN 0
										ELSE 1 END
		FROM Requirement.QuestionnaireRequirements QR
			INNER JOIN Requirement.Requirements Q ON QR.RequirementID = Q.RequirementID
			INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQSMD ON Q.RequirementID = BMQSMD.QuestionnaireRequirementID
			INNER JOIN Requirement.RequirementRollups QS ON Q.RequirementID = QS.RequirementIDPartOf
			INNER JOIN Requirement.Requirements S ON QS.RequirementIDMadeUpOf = S.RequirementID
			INNER JOIN Requirement.SelectionRequirements SR ON S.RequirementID = SR.RequirementID
		WHERE QR.RequirementID = @QuestionnaireRequirementID
			AND SR.SelectionStatusTypeID = 1
			AND DATEADD(d, DATEDIFF(D, 0, S.RequirementCreationDate), 0) =  @Today
		
			
		IF @CreateSelections = 1

			BEGIN
				-- GENERATE THE SELECTION
				EXEC Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @DateStamp, 1
			END

		-- INCREMENT THE COUNTER
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
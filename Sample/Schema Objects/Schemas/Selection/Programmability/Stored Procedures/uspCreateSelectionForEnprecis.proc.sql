CREATE PROCEDURE [Selection].[uspCreateSelectionForEnprecis]
AS

/*
	Purpose:	Create Enprecis selections to always be executed on a monday.
		
	Version			Date			Developer			Comment
	1.0				07/01/2014		Martin Riverol		Created
	1.1				22/01/2014		Martin Riverol		Output wil run on a monday so amended the selection creation
	                                                    so if run on a monday it will create selections for the following monday
	1.2				02/02/2017		Chris Ledger		Add Enprecis Selections Quotas

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @InitialDate SMALLDATETIME
	DECLARE @RunDate SMALLDATETIME
	DECLARE @FutureDate SMALLDATETIME
	DECLARE @DateStamp VARCHAR(8)
	DECLARE @CreateSelections BIT = 0
	DECLARE @ManufacturerPartyID INT
	DECLARE @QuestionnaireRequirementID INT
	DECLARE @SelectionName VARCHAR(255)

	
	/* 
		WHEN CREATING SELECTIONS, ALWAYS MALES THEM THE FOLLOWING MONDAYS DATE REGARDLESS
		OF WHAT DAY OF THE WEEK IT IS (N.B. IF A MONDAY, CREATE SELECTIONS FOR NEXT MONDAY)
	*/
	
		SET @InitialDate = DATEADD(d, 0, DATEDIFF(D, 0, GETDATE()))
		
		SET @FutureDate = DATEADD(WK, 1, @InitialDate)
			
		IF DATEPART(WEEKDAY, @FutureDate) > 2
			SELECT @Rundate = DATEADD(d, - (DATEPART(WEEKDAY, @FutureDate) - 2), @FutureDate)
		ELSE 
			BEGIN 
				IF DATEPART(WEEKDAY, @FutureDate) = 1/* SUNDAY */
					BEGIN
						SET @FutureDate = DATEADD(d, -1, @FutureDate)
						SELECT @Rundate = DATEADD(d, - (DATEPART(WEEKDAY, @FutureDate) - 2), @FutureDate)
					END
				ELSE
					SELECT @Rundate = @FutureDate
			END		
		

	/* SET CREATE SELECTION FLAG IF WE HAVE YET TO CREATE ENPRECIS SELECTIONS FOR THIS DATE */
		
		SELECT @CreateSelections = 
			CASE 
				WHEN COUNT(*) > 0 THEN 0
				ELSE 1
			END
		FROM Sample.Requirement.QuestionnaireRequirements QR
		INNER JOIN Sample.Requirement.Requirements Q ON QR.RequirementID = Q.RequirementID
		INNER JOIN Sample.dbo.vwBrandMarketQuestionnaireSampleMetadata BMQSMD ON Q.RequirementID = BMQSMD.QuestionnaireRequirementID
		INNER JOIN Sample.Requirement.requirementrollups QS ON Q.RequirementID = QS.RequirementIDPartOf
		INNER JOIN Sample.Requirement.Requirements S ON QS.RequirementIDMadeUpOf = S.RequirementID
		INNER JOIN Sample.Requirement.SelectionRequirements SR ON S.RequirementID = SR.RequirementID
		AND Q.Requirement LIKE 'Enprecis%2014+'
		AND CreateSelection = 1
		AND DATEADD(d, DATEDIFF(D, 0, s.RequirementCreationDate), 0) =  @RunDate
	
	IF @CreateSelections = 1
	
		BEGIN
		
			/* CREATE DATESTAMP */			
			SELECT @DateStamp = CAST(YEAR(@RunDate) AS CHAR(4))
			SELECT @DateStamp = @DateStamp + CASE WHEN LEN(CAST(MONTH(@RunDate) AS VARCHAR(2))) = 1 THEN '0' + CAST(MONTH(@RunDate) AS CHAR(1)) ELSE CAST(MONTH(@RunDate) AS CHAR(2)) END
			SELECT @DateStamp = @DateStamp + CASE WHEN LEN(CAST(DAY(@RunDate) AS VARCHAR(2))) = 1 THEN '0' + CAST(DAY(@RunDate) AS CHAR(1)) ELSE CAST(DAY(@RunDate) AS CHAR(2)) END	

			/* CREATE A TABLE TO HOLD ALL THE SELECTIONS WE NEED TO CREATE */
	
			CREATE TABLE #Selections
				(
					ID INT IDENTITY(1,1) NOT NULL,
					ManufacturerPartyID INT,
					QuestionnaireRequirementID INT,
					SelectionName VARCHAR(255)
				)

			/* GET THE SELECTIONS WE NEED TO CREATE */
	
			INSERT INTO #Selections 
			
				(
					ManufacturerPartyID, 
					QuestionnaireRequirementID, 
					SelectionName
				)
	
				SELECT 
					BMQSMD.ManufacturerPartyID, 
					BMQSMD.QuestionnaireRequirementID, 
					BMQSMD.SelectionName + '_' + @DateStamp
				FROM Sample.Requirement.QuestionnaireRequirements QR
				INNER JOIN Sample.Requirement.Requirements Q ON QR.RequirementID = Q.RequirementID
				INNER JOIN Sample.dbo.vwBrandMarketQuestionnaireSampleMetadata BMQSMD ON Q.RequirementID = BMQSMD.QuestionnaireRequirementID
				AND Q.Requirement LIKE 'Enprecis%2014+'
				AND CreateSelection = 1

			/* LOOP THROUGH EACH OF THE SELECTIONS AND CREATE IT */
			
				DECLARE @MAXID INT
				SELECT @MAXID = MAX(ID) FROM #Selections

				DECLARE @Counter INT
				SET @Counter = 1

				WHILE @Counter <= @MAXID
					
					BEGIN

						-- GET THE VALUES FROM #Selections
						SELECT  @ManufacturerPartyID = ManufacturerPartyID,
								@QuestionnaireRequirementID = QuestionnaireRequirementID,
								@SelectionName = SelectionName
						FROM #Selections WHERE ID = @Counter
						
						-- GENERATE THE SELECTION
						EXEC Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @RunDate, 1, 1

						-- INCREMENT THE COUNTER
						SET @Counter += 1
					END
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
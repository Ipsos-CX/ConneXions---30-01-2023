CREATE PROCEDURE [Selection].[uspCreateSelectionForCQI]
AS

/*
		Purpose:	Create CQI selections to always be executed on a monday.
		
		Version		Date			Developer			Comment
LIVE	1.0			16/01/2017		Chris Ledger		Created from uspCreateSelectionForEnprecis
LIVE	1.1			28/04/2017		Chris Ledger		BUG 13714: Run on All Markets (i.e. exclude filter for Pilot Countries)
LIVE	1.2			21/11/2017		Chris Ledger		BUG 14347: Add MCQI
LIVE	1.3			12/05/2021		Chris Ledger		TASK 441: Set ScheduledRunDate to Tuesday
LIVE	1.4			08/06/2021		Chris Ledger		TASK 476: Include old method of identifying CQI as well
LIVE	1.5			06/12/2021		Chris Ledger		TASK 411: Set ScheduledRunDate to Wednesday for Germany
LIVE	1.6			07/09/2022		Chris Ledger		TASK 1026: Set ScheduledRunDate to Wednesday for Italy & France 24MIS
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
	DECLARE @SelectionDate SMALLDATETIME
	DECLARE @FutureDate SMALLDATETIME
	DECLARE @DateStamp VARCHAR(8)
	DECLARE @CreateSelections BIT = 0
	DECLARE @ManufacturerPartyID INT
	DECLARE @QuestionnaireRequirementID INT
	DECLARE @SelectionName VARCHAR(255)
	DECLARE @UseQuotas BIT = 0
	DECLARE @ScheduledRunDate SMALLDATETIME

	
	/* 
		WHEN CREATING SELECTIONS, ALWAYS MALES THEM THE FOLLOWING MONDAYS DATE REGARDLESS
		OF WHAT DAY OF THE WEEK IT IS (N.B. IF A MONDAY, CREATE SELECTIONS FOR NEXT MONDAY)
	*/
	SET @InitialDate = DATEADD(D, 0, DATEDIFF(D, 0, GETDATE()))
		
	SET @FutureDate = DATEADD(WK, 1, @InitialDate)
			
	IF DATEPART(WEEKDAY, @FutureDate) > 2
		SELECT @SelectionDate = DATEADD(D, - (DATEPART(WEEKDAY, @FutureDate) - 2), @FutureDate)
	ELSE 
		BEGIN 
			IF DATEPART(WEEKDAY, @FutureDate) = 1/* SUNDAY */
				BEGIN
					SET @FutureDate = DATEADD(D, -1, @FutureDate)
					SELECT @SelectionDate = DATEADD(D, - (DATEPART(WEEKDAY, @FutureDate) - 2), @FutureDate)
				END
			ELSE
				SELECT @SelectionDate = @FutureDate
		END		
		

	/* SET CREATE SELECTION FLAG IF WE HAVE YET TO CREATE ENPRECIS SELECTIONS FOR THIS DATE */
	SELECT @CreateSelections = CASE	WHEN COUNT(*) > 0 THEN 0
									ELSE 1 END
	FROM Requirement.QuestionnaireRequirements QR
		INNER JOIN Requirement.Requirements Q ON QR.RequirementID = Q.RequirementID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQSMD ON Q.RequirementID = BMQSMD.QuestionnaireRequirementID
		INNER JOIN Requirement.RequirementRollups QS ON Q.RequirementID = QS.RequirementIDPartOf
		INNER JOIN Requirement.Requirements S ON QS.RequirementIDMadeUpOf = S.RequirementID
		INNER JOIN Requirement.SelectionRequirements SR ON S.RequirementID = SR.RequirementID
	WHERE (SUBSTRING(Q.Requirement,1,3) = 'CQI' OR SUBSTRING(Q.Requirement,1,4) = 'MCQI' OR BMQSMD.Questionnaire LIKE '%CQI%')			-- V1.3 -- V1.4
		AND BMQSMD.CreateSelection = 1
		AND DATEADD(D, DATEDIFF(D, 0, S.RequirementCreationDate), 0) =  @SelectionDate
	
	IF @CreateSelections = 1
	
		BEGIN
		
			/* CREATE DATESTAMP */			
			SELECT @DateStamp = CAST(YEAR(@SelectionDate) AS CHAR(4))
			SELECT @DateStamp = @DateStamp + CASE	WHEN LEN(CAST(MONTH(@SelectionDate) AS VARCHAR(2))) = 1 THEN '0' + CAST(MONTH(@SelectionDate) AS CHAR(1)) 
													ELSE CAST(MONTH(@SelectionDate) AS CHAR(2)) END
			SELECT @DateStamp = @DateStamp + CASE	WHEN LEN(CAST(DAY(@SelectionDate) AS VARCHAR(2))) = 1 THEN '0' + CAST(DAY(@SelectionDate) AS CHAR(1)) 
													ELSE CAST(DAY(@SelectionDate) AS CHAR(2)) END	

			/* CREATE A TABLE TO HOLD ALL THE SELECTIONS WE NEED TO CREATE */
			CREATE TABLE #Selections
			(
				ID INT IDENTITY(1,1) NOT NULL,
				ManufacturerPartyID INT,
				QuestionnaireRequirementID INT,
				SelectionName VARCHAR(255),
				UseQuotas BIT
			)

			/* GET THE SELECTIONS WE NEED TO CREATE */
			INSERT INTO #Selections 
			(
				ManufacturerPartyID, 
				QuestionnaireRequirementID, 
				SelectionName,
				UseQuotas
			)
			SELECT 
				BMQSMD.ManufacturerPartyID, 
				BMQSMD.QuestionnaireRequirementID, 
				BMQSMD.SelectionName + '_' + @DateStamp AS SelectionName,
				0 AS UseQuotas								-- V1.4				
			FROM Requirement.QuestionnaireRequirements QR
				INNER JOIN Requirement.Requirements Q ON QR.RequirementID = Q.RequirementID
				INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQSMD ON Q.RequirementID = BMQSMD.QuestionnaireRequirementID
			WHERE (SUBSTRING(Q.Requirement,1,3) = 'CQI' OR SUBSTRING(Q.Requirement,1,4) = 'MCQI' OR BMQSMD.Questionnaire LIKE '%CQI%')			-- V1.3 -- V1.4
				AND CreateSelection = 1

			/* LOOP THROUGH EACH OF THE SELECTIONS AND CREATE IT */
			DECLARE @MAXID INT
			SELECT @MAXID = MAX(ID) FROM #Selections

			DECLARE @Counter INT
			SET @Counter = 1

			WHILE @Counter <= @MAXID
					
				BEGIN

					-- GET THE VALUES FROM #Selections
					SELECT @ManufacturerPartyID = ManufacturerPartyID,
						@QuestionnaireRequirementID = QuestionnaireRequirementID,
						@SelectionName = SelectionName,
						@UseQuotas = UseQuotas,
						@ScheduledRunDate = CASE	WHEN SelectionName LIKE '% GER %' THEN DATEADD(D, 2, @SelectionDate)
													WHEN SelectionName LIKE '%ITA 24MIS%' THEN DATEADD(D, 2, @SelectionDate)	-- V1.6
													WHEN SelectionName LIKE '%FRA 24MIS%' THEN DATEADD(D, 2, @SelectionDate)	-- V1.6
													ELSE DATEADD(D, 1, @SelectionDate) END										-- V1.5
					FROM #Selections 
					WHERE ID = @Counter
						
					-- GENERATE THE SELECTION
					EXEC Selection.uspCreateSelectionRequirement @ManufacturerPartyID, @QuestionnaireRequirementID, @SelectionName, @SelectionDate, 1, @UseQuotas, @ScheduledRunDate		-- V1.3

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
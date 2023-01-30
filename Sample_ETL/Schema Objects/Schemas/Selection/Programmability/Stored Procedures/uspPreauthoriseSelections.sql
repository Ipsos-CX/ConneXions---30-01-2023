CREATE PROCEDURE [Selection].[uspPreauthoriseSelections]
/*
	Purpose:	Automatically pre-authorise selections generated from the sample load job
		
	Version			Date			Developer			Comment
	1.0				2020-12-17		Eddie Thomas		Created
	1.1				2021-05-12		Eddie Thomas		Exclude CQI selection (https://dev.azure.com/ConneXions-Team/ConneXions-Restart/_workitems/edit/439)
	1.2				2021-06-30		Chris Ledger		Change DateLastRun window to include selections run in same minute as LastRunDate
*/
AS
DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)

DECLARE @JobName				VARCHAR (200)	= 'Sample Load and Selection',	--PACKAGE NAME
		@MinimumStepExecuted	VARCHAR (200)	= 'Run Scheduled Selections',	--STEP IN PACKAGE USED AS REFERENCE POINT TO
		@PackageRunTimeWindow	INT				= 300,							--ENSURE WE'RE ONLY PICK SELECTIONS THAT EXECUTED DURING THE LAST RUNNING Of THE PACKAGE
		@LastRunDate			DATETIME		



SET LANGUAGE ENGLISH
BEGIN TRY

	--IDENTIFY THE TIME WHEN THE MOSTE RECENT SAMPLE LOAD TOOK PLACE AND WHEN SELCTIONS RAN.
	SELECT		Distinct j.Name as 'JobName', md.RunDateTime
	INTO		#tmp_LastRun
	FROM		msdb.dbo.sysjobs j
	INNER JOIN	msdb.dbo.sysjobhistory h ON j.job_id = h.job_id 
	INNER JOIN 
	 (	SELECT	MAX(msdb.dbo.agent_datetime(run_date, run_time)) as 'RunDateTime', job_id
		FROM	msdb.dbo.sysjobhistory
		WHERE	step_name = @MinimumStepExecuted
		GROUP BY job_id
	)	md		ON h.job_id = md.job_id  
	WHERE		j.enabled = 1  --Only Enabled Jobs 
				AND  j.name = @JobName

	SELECT TOP 1 @LastRunDate = RunDateTime FROM #tmp_LastRun

	-- V1.1
	;WITH CQI_cte (SelectionRequirementID, Requirement)
	AS
	(
		--TRAVERSE REQUIREMENT DATA MODEL
		SELECT SR.RequirementID,  REQ.Requirement
		FROM		[$(SampleDB)].Requirement.SelectionRequirements SR
		INNER JOIN	[$(SampleDB)].Requirement.RequirementRollups RR1	ON SR.RequirementID = RR1.RequirementIDMadeUpOf
		INNER JOIN	[$(SampleDB)].Requirement.RequirementRollups RR2	ON RR1.RequirementIDPartOf = RR2.RequirementIDMadeUpOf
		INNER JOIN	[$(SampleDB)].Requirement.Requirements REQ			ON RR2.RequirementIDPartOf = REQ.RequirementID
		WHERE		REQ.Requirement like 'CQI%'
	)

	--AUTHORISE MATCHING SELECTIONS
	UPDATE		SR
	--SELECT		SR.RequirementID, @LastRunDate, DateLastRun, DATEDIFF(minute, @LastRunDate, DateLastRun) , @PackageRunTimeWindow
	SET			SelectionStatusTypeID = 4,  -- Authorised
				DateOutputAuthorised = GETDATE()
	FROM		[$(SampleDB)].Requirement.Requirements REQ
	INNER JOIN	[$(SampleDB)].Requirement.SelectionRequirements		SR	ON REQ.RequirementID = SR.RequirementID
	INNER JOIN  [$(SampleDB)].Requirement.SelectionStatusTypes		SST ON SR.SelectionStatusTypeID = SST.SelectionStatusTypeID AND SST.SelectionStatusType = 'Selected'
	LEFT JOIN	CQI_cte												CTE ON SR.RequirementID = CTE.SelectionRequirementID	-- V1.1
	
	--ONLY INTERESTED IN SELECTIONS ASSOCIATED TO THE MOST RECENT JOB RUN 
	WHERE		(DATEDIFF(MINUTE, @LastRunDate, DateLastRun) BETWEEN 0 AND @PackageRunTimeWindow) AND		-- V1.2		
				(CTE.SelectionRequirementID IS NULL)		--FILTER OUT CQI SELECTIONS		-- V1.1

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

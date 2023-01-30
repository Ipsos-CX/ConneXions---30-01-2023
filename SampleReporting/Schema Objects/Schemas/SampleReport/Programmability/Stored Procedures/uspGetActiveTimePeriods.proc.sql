CREATE PROCEDURE SampleReport.uspGetActiveTimePeriods
	
	(
		@QtrOutput BIT
		, @EchoOutput BIT
		, @DailyEcho BIT
		, @EchoFeed12mthRolling BIT
	)
AS	

/*
	Purpose: Pass in flags to denote what reports we are running and return the timeperiods required

	Version		Date			Developer			Comment
	1.0			20140606		Martin Riverol		Created
	1.1			30/05/2017		Ben King			BUG 13942 Echo Sample Reporting on a Daily Basis
	1.2			28/01/2019		Ben King			BUG 15227 - 12 month Static rolling extract report
	1.3			15/01/2020		Chris Ledger 		BUG 15372 - Fix Hard coded references to databases
*/

	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

	/* WHAT TIME PERIODS DO WE WANT TO OUTPUT REPORTS FOR */

	BEGIN TRY

		SELECT 
			TimePeriod,
			TimePeriodDescription,
			ActiveFlag
		FROM SampleReport.TimePeriods 
		WHERE ActiveFlag = 1
		AND 
			(
				(@QtrOutput = 1 AND @EchoOutput = 0 AND @DailyEcho = 0 AND TimePeriod in ('YTD','QTR','MTH'))
			OR
				(@QtrOutput = 0 AND @EchoOutput = 0 AND @DailyEcho = 0 AND TimePeriod in ('YTD', 'MTH'))
			OR 
				(@EchoOutput = 1 AND @DailyEcho = 0 AND @EchoFeed12mthRolling = 0 AND TimePeriod = 'YTD')	
				
			OR 
				(@DailyEcho = 1 AND TimePeriod = '24H') -- V1.1
				
			OR 
				(@EchoFeed12mthRolling = 1 AND TimePeriod = 'RollingYTD') -- V1.2
			)
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


CREATE PROCEDURE OWAP.uspScheduleJob_SelectionOutput  
AS

-- *********************************************************************************************
-- ** Description:	Schedules a one-off run of the Selection Output job.  Also removes any existing
-- **				one-off schedules.
-- **
-- ** Version	Author			Date		Description
-- ** -------	------			----		-----------
-- ** 1.0		Chris Ross		03/07/2012	Initial version.  Sets job to run in 30 minutes from run time.
-- **
-- *********************************************************************************************


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


	-- First remove any existing user triggered schedules.  ---------------------------------------

	DECLARE @SName_Delete varchar(100)

	DECLARE Schedules_Cursor CURSOR FOR
		select b.name from msdb..sysjobs a 
		INNER JOIN msdb..sysJobschedules c ON a.job_id = c.job_id 
		INNER JOIN msdb..SysSchedules b on b.Schedule_id=c.Schedule_id
		where a.name = 'Selection Output'
		and b.name like 'SelectionOutput_UserTriggered_%';
		
	OPEN Schedules_Cursor;
	FETCH NEXT FROM Schedules_Cursor INTO @Sname_delete;

	WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC msdb.dbo.sp_delete_schedule	
					@schedule_name = @SName_Delete,
					@force_delete = 1;
					
			FETCH NEXT FROM Schedules_Cursor INTO @Sname_delete;
		END;
		
	CLOSE Schedules_Cursor;
	DEALLOCATE Schedules_Cursor;	



	-- Now create and add new scheduled to job -------------------------------------------------------

	DECLARE @StartDate	nvarchar(8),
			@StartTime	nvarchar(6),
			@IncMinutes int,
			@SName		nvarchar(100)

	SET @IncMinutes = 30	-- Schedule for 30 minutes from now

	SELECT @StartDate = convert(varchar(8), GETDATE(),112)
	SELECT @StartTime = substring(replace(convert(varchar(12), dateadd(minute, @IncMinutes , GETDATE()),114), ':', ''), 1, 6)

	SET @SName = N'SelectionOutput_UserTriggered_' + @StartDate + @StartTime

	-- Creates the schedule 
	EXEC msdb.dbo.sp_add_schedule
		@schedule_name = @SName, 
		@freq_type = 1,			-- Run once
		@freq_interval = 1,
		@active_start_date = @StartDate,
		@active_start_time = @StartTime ;

	-- attaches the schedule to the job BackupDatabase
	EXEC msdb.dbo.sp_attach_schedule
	   @job_name = N'Selection Output',
	   @schedule_name = @SName ;

END TRY

BEGIN CATCH
	
	SELECT
	 @ErrorNumber = Error_Number()
	,@ErrorSeverity = Error_Severity()
	,@ErrorState = Error_State()
	,@ErrorLocation = Error_Procedure()
	,@ErrorLine = Error_Line()
	,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
	 @ErrorNumber
	,@ErrorSeverity
	,@ErrorState
	,@ErrorLocation
	,@ErrorLine
	,@ErrorMessage
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)

END CATCH

	   
		
		
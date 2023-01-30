CREATE PROCEDURE [OWAPv2].[uspRunEventXDealerList]
@SessionID [dbo].[SessionID]=N'', @AuditID [dbo].[AuditID]=0, @UserPartyID [dbo].[PartyID]=0, @ErrorCode INT=0 OUTPUT, @RunEventXDealerList BIT=0 OUTPUT

AS

/*
	Purpose:	OWAP Run EventX Dealer List

	Version		Date			Developer			Comment
	1.1			2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/

SET NOCOUNT, XACT_ABORT ON;

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserRoleTypeID [dbo].RoleTypeID
		DECLARE @UserPartyRoleID [dbo].PartyRoleID 
		DECLARE @RunJob BIT 
				
		SET @ActionDate = GETDATE()

		---------------------------------------------------------------------------
		-- GET THE USER DETAILS
		---------------------------------------------------------------------------
		IF (ISNULL( @UserPartyID, 0 ) = 0 )
		BEGIN
			SELECT 
				@UserPartyID = U.PartyID,
				@UserRoleTypeID = U.RoleTypeID,
				@UserPartyRoleID = U.PartyRoleID
			FROM
				OWAP.vwUsers U
			WHERE
				U.UserName = 'OWAPAdmin'
		END
		ELSE
		BEGIN
			SELECT 
				@UserRoleTypeID = U.RoleTypeID,
				@UserPartyRoleID = U.PartyRoleID
			FROM
				OWAP.vwUsers U
			WHERE
				U.PartyID = @UserPartyID
		END
		
		IF (ISNULL( @AuditID, 0 ) = 0 )
		BEGIN
			EXECUTE	[OWAP].[uspAuditSession] 'OWAP Run EventX Dealer List', @userPartyRoleID, @AuditID Output, @ErrorCode Output
		END

		---------------------------------------------------------------------------
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		---------------------------------------------------------------------------
		EXEC [OWAP].[uspAuditAction] @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT
	


		---------------------------------------------------------------------------
		-- RUN JOB TO CREATE REISSUE INVITE FILE
		---------------------------------------------------------------------------

		DECLARE @job_name NVARCHAR(MAX) = 'GENERATE AND EMAIL: EventX Dealer List'
		EXEC msdb.dbo.sp_start_job @job_name = @job_name


		-- Wait for job to finish
		DECLARE @job_history_id AS INT = NULL
		DECLARE @time_constraint AS INT = 0
		DECLARE @ok AS INT = 0
		
		WHILE @time_constraint = @ok
		BEGIN
			SELECT TOP 1 
			--activity.job_history_id
			@job_history_id = activity.job_history_id
			FROM msdb.dbo.sysjobs jobs
			INNER JOIN msdb.dbo.sysjobactivity activity ON activity.job_id = jobs.job_id
			WHERE 
			--jobs.name = 'GENERATE AND EMAIL: EventX Dealer List'
			jobs.name = @job_name
			ORDER BY activity.start_execution_date DESC

			IF @job_history_id IS NULL
			BEGIN
				WAITFOR DELAY '00:00:10'
				CONTINUE
			END
			ELSE
				BREAK
		END


		-- SET EXIT CODE
		SELECT TOP 1 @RunEventXDealerList = history.run_status
		FROM msdb.dbo.sysjobhistory history
		WHERE history.instance_id = @job_history_id		
		---------------------------------------------------------------------------
				
	
END TRY
BEGIN CATCH

	--ROLLBACK

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

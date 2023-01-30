CREATE PROCEDURE NWB.uspCreateAlerts
	
AS

/*
		Purpose:	Check for issues and create appropriate alerts for emailing out.
	
		Version		Date			Developer			Comment
LIVE	1.0			02-09-2019		Chris Ross			BUG 15430: Original version.
LIVE	1.1			10-10-2019		Chris Ledger		BUG 15636: Add Success alert for online and change alert body text
LIVE	1.2			10-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases
LIVE	1.3			15-06-2022		Chris Ledger		TASK 919: Change JOIN to NwbSampleUpload_ut_RequestLog to allow Pending/Unactioned alerts to be added
*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		------------------------------------------------------------------------------------------
		-- Create a temporary Alerts holding table 
		------------------------------------------------------------------------------------------
		CREATE TABLE #NewAlerts
		(
			NwbSampleUploadRequestKey   INT,
			AlertTypeID					INT,
			ProjectId					NVARCHAR(512),		-- V1.1
		)


		------------------------------------------------------------------------------------------
		-- Check for failed requests
		------------------------------------------------------------------------------------------
		INSERT INTO #NewAlerts (NwbSampleUploadRequestKey, AlertTypeID, ProjectId)
		SELECT R.pkNwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			R.ProjectId			-- V1.1
		FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertType = 'Failure'
		WHERE R.fkSampleUploadStatusKey = 2
			AND NOT EXISTS (	SELECT RequestAlertID 
								FROM NWB.RequestAlerts RA 
								WHERE RA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey 
									AND RA.AlertTypeID = RAT.AlertTypeID)


		------------------------------------------------------------------------------------------
		-- Check for Unactioned 2
		------------------------------------------------------------------------------------------
		INSERT INTO #NewAlerts (NwbSampleUploadRequestKey, AlertTypeID, ProjectId)
		SELECT R.pkNwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			R.ProjectId			-- V1.1
		FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertType = 'Unactioned 2'
		WHERE R.fkSampleUploadStatusKey IS NULL
			AND DATEDIFF(MINUTE, R.CreatedTimestamp, GETUTCDATE()) > RAT.AlertTimePeriodMins
			AND NOT EXISTS (	SELECT RequestAlertID 
								FROM NWB.RequestAlerts RA 
								WHERE RA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey 
									AND RA.AlertTypeID = RAT.AlertTypeID)



		------------------------------------------------------------------------------------------
		-- Check for Unactioned 1   --> Checked second in case we have just created a Pending 2 record
		--								as we do not want 2 alerts popping out if this is the first run
		--								in over the Unactioned 2 minutes value.
		------------------------------------------------------------------------------------------
		INSERT INTO #NewAlerts (NwbSampleUploadRequestKey, AlertTypeID, ProjectId)
		SELECT R.pkNwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			R.ProjectId			-- V1.1
		FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertType = 'Unactioned 1'
		WHERE R.fkSampleUploadStatusKey IS NULL
			AND DATEDIFF(MINUTE, R.CreatedTimestamp, GETUTCDATE()) > RAT.AlertTimePeriodMins
			AND NOT EXISTS (	SELECT RequestAlertID 
								FROM NWB.RequestAlerts RA 
								WHERE RA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey 
								AND RA.AlertTypeID = RAT.AlertTypeID)
			AND NOT EXISTS (	SELECT NA.NwbSampleUploadRequestKey 
								FROM #NewAlerts NA 
									INNER JOIN NWB.RequestAlertTypes RAT2 ON RAT2.AlertTypeID = NA.AlertTypeID 
																			AND RAT2.AlertType = 'Unactioned 2'
								WHERE NA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey)


		------------------------------------------------------------------------------------------
		-- Check for Pending 2
		------------------------------------------------------------------------------------------
		INSERT INTO #NewAlerts (NwbSampleUploadRequestKey, AlertTypeID, ProjectId)
		SELECT R.pkNwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			R.ProjectId			-- V1.1
		FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertType = 'Pending 2'
		WHERE R.fkSampleUploadStatusKey = 0
			AND DATEDIFF(MINUTE, R.QueuedTimestamp, GETUTCDATE()) > RAT.AlertTimePeriodMins
			AND NOT EXISTS (	SELECT RequestAlertID 
								FROM NWB.RequestAlerts RA 
								WHERE RA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey 
									AND RA.AlertTypeID = RAT.AlertTypeID)
					

		------------------------------------------------------------------------------------------
		-- Check for Pending 1  --> Checked second in case we have just created a Pending 2 record
		--                          as we do not want 2 alerts popping out if this is the first run
		--							in over the Pending 2 minutes value.
		------------------------------------------------------------------------------------------
		INSERT INTO #NewAlerts (NwbSampleUploadRequestKey, AlertTypeID, ProjectId)
		SELECT R.pkNwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			R.ProjectId			-- V1.1
		FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertType = 'Pending 1'
		WHERE R.fkSampleUploadStatusKey = 0
			AND DATEDIFF(MINUTE, R.QueuedTimestamp, GETUTCDATE()) > RAT.AlertTimePeriodMins
			AND NOT EXISTS (	SELECT RequestAlertID 
								FROM NWB.RequestAlerts RA 
								WHERE RA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey 
									AND  RA.AlertTypeID = RAT.AlertTypeID)
			AND NOT EXISTS (	SELECT NA.NwbSampleUploadRequestKey 
								FROM #NewAlerts NA 
									INNER JOIN NWB.RequestAlertTypes RAT2 ON RAT2.AlertTypeID = NA.AlertTypeID 
																			AND RAT2.AlertType = 'Pending 2'
								WHERE NA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey)


		------------------------------------------------------------------------------------------
		-- V1.1 Check for successful requests
		------------------------------------------------------------------------------------------
		INSERT INTO #NewAlerts (NwbSampleUploadRequestKey, AlertTypeID, ProjectId)
		SELECT R.pkNwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			R.ProjectId			-- V1.1
		FROM [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertType = 'Success'
		WHERE R.fkSampleUploadStatusKey = 3
			AND NOT EXISTS (	SELECT RequestAlertID 
								FROM NWB.RequestAlerts RA 
								WHERE RA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey 
									AND RA.AlertTypeID = RAT.AlertTypeID)


		------------------------------------------------------------------------------------------
		-- Create Alerts
		------------------------------------------------------------------------------------------
		INSERT INTO NWB.RequestAlerts (NwbSampleUploadRequestKey, AlertTypeID, CreatedDate, EmailSentDate, EmailRecipients, EmailCCRecipients, EmailTitleText, EmailBodyText)
		SELECT NA.NwbSampleUploadRequestKey,
			RAT.AlertTypeID,
			GETDATE() AS CreatedDate,
			NULL AS EmailSentDate,
			ER.EmailRecipients,
			ER.EmailCCRecipients,
			CASE RAT.AlertType
				WHEN 'Success' THEN
					REPLACE(
						REPLACE(
							REPLACE(RAT.EmailTitleText, 
								'<survey>', ISNULL(REPLACE(REPLACE(REPLACE(SUI.Questionnaire,'LostLeadsUS','LostLeads US'),'Russia',' Russia'),'CATI','CATI '),''))
							,'<project>', ISNULL(NA.ProjectId,''))
						,'<week>', (SELECT [$(SampleDB)].SelectionOutput.udfGetWeekNumber(GETDATE()))) 
				ELSE ETF.EmailTitlePrefix + ' - ' + RAT.EmailTitleText END AS EmailTitleText,
			REPLACE(	
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(
										REPLACE(
												ISNULL(
														REPLACE(RAT.EmailBodyText, '<filename>', CHAR(10) + CHAR(10) +
																					(	SELECT F.FileName + CHAR(10) AS [text()]
																						FROM [$(AuditDB)].dbo.Files F 
																						WHERE F.AuditID IN (	SELECT ANS.AuditID
																												FROM [$(AuditDB)].Audit.NWB_SelectionOutputsStaging ANS
																												WHERE ANS.NwbSampleUploadRequestKey = NA.NwbSampleUploadRequestKey)
																						ORDER BY F.FileName
																						FOR XML PATH ('')
																						) + CHAR(10) + CHAR(10) + CHAR(10)
														), '<< EMAIL BODY. ERROR : Audit.NWB_SelectionOutputsStaging records NOT FOUND. Contact Connexions team.>>') 
										, '<minutes>', ISNULL(RAT.AlertTimePeriodMins, 0) )
									, '<log>', CHAR(10) + CHAR(10) + ISNULL(RL.LogText,'') + CHAR(10) + CHAR(10) + CHAR(10) )					-- V1.1																						-- V1.1
								, '<project>', CHAR(10) + CHAR(10) + 'Project ID: ' + ISNULL(NA.ProjectId,'') + CHAR(10) + CHAR(10) ) 			-- V1.1
							, '<survey>', ISNULL(REPLACE(REPLACE(REPLACE(SUI.Questionnaire,'LostLeadsUS','LostLeads US'),'Russia',' Russia'),'CATI','CATI '),'') + CHAR(10) + CHAR(10) )				-- V1.1
						,'<week>', 'Status: SUCCESS' + CHAR(10) + CHAR(10) + 'Week: ' + CONVERT(VARCHAR,(SELECT [$(SampleDB)].SelectionOutput.udfGetWeekNumber(GETDATE()))) + CHAR(10) + CHAR(10) )		-- V1.1
					, '<target>', ISNULL( R.TargetServerName,'') + CHAR(10) + CHAR(10) ) 														-- V1.1
				, '<date>', CONVERT(VARCHAR, R.ModifiedTimestamp, 23)  + CHAR(10) + CHAR(10) ) 													-- V1.1
			, '<time>', SUBSTRING(CONVERT(VARCHAR, R.ModifiedTimestamp, 100), LEN(CONVERT(VARCHAR, R.ModifiedTimestamp, 100))-7,8) + CHAR(10) + CHAR(10) + CHAR(10) )  	-- V1.1
		FROM #NewAlerts NA
			INNER JOIN [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_Request R ON NA.NwbSampleUploadRequestKey = R.pkNwbSampleUploadRequestKey							-- V1.1
			LEFT JOIN [$(NwbSampleUpload)].dbo.NwbSampleUpload_ut_RequestLog RL ON NA.NwbSampleUploadRequestKey = RL.fkNwbSampleUploadRequestKey	-- V1.3					-- V1.1
			INNER JOIN NWB.SurveyUploadInfo SUI ON NA.ProjectId = SUI.ProjectId																							-- V1.1
													AND SUI.LocalServerName = @@SERVERNAME																				-- V1.1
			INNER JOIN NWB.RequestAlertTypes RAT ON RAT.AlertTypeID = NA.AlertTypeID
			INNER JOIN NWB.RequestAlertEmailRecipients ER ON ER.AlertTypeID = RAT.AlertTypeID 
															AND ER.LocalServerName = @@SERVERNAME
			INNER JOIN NWB.RequestAlertEmailTitlePrefixes ETF ON ETF.LocalServerName = @@SERVERNAME



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
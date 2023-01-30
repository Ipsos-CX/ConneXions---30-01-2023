CREATE PROCEDURE [SelectionOutput].[uspAuditTelephoneOutput]
@FileName VARCHAR (255)
AS

/*
	Purpose:	Audit the telephone output
	
	Version			Date			Developer			Comment
	1.1				19-04-2017		Chris Ledger		BUG 13378 - Add EmployeeName	
	1.2				06-07-2017		Eddie Thomas		BUG 14037 - Add fields SVOvehicle & FOBCode
	1.3				26-09-2018		Eddie Thomas		BUG 14820 - Lost Leads - Global loader change
	1.4				25-10-2019		Eddie Thomas		BUG 16667 - Add HotTopicCodes field and PHEV flags
	1.5				21-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases.
	1.6				13-03-2020		Chris Ledger		BUG 16891 - Add ServiceEventType
*/

SET NOCOUNT ON
SET DATEFORMAT DMY

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			PartyID INT NULL,
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, CaseOutputTypeID)
		SELECT DISTINCT
			CaseID, 
			PartyID,
			(SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI') AS CaseOutputTypeID
		FROM SelectionOutput.CATI
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			INSERT INTO [$(AuditDB)].Audit.SelectionOutput
			(
				[AuditID], 
				[AuditItemID], 
				[SelectionOutputTypeID], 
				[CaseID], 
				[PartyID], 
				[FullModel], 
				[CarReg], 
				[RegistrationDate], 
				[VIN], 
				[Fullname], 
				[CoName], 
				[Add1], 
				[Add2], 
				[Add3], 
				[Add4], 
				[Add5], 
				[LandPhone], 
				[WorkPhone], 
				[MobilePhone],
				[Dealer], 
				[DateOutput], 
				[manuf], 
				[etype],
				[Queue],
				[AssignedMode],
				[RequiresManualDial],
				[CallRecordingsCount],
				[TimeZone],			
				[CallOutcome],		
				[PhoneNumber],		
				[PhoneSource],		
				[Language],			
				[ExpirationTime],	
				[HomePhoneNumber],	
				[WorkPhoneNumber],	
				[MobilePhoneNumber],
				[EmployeeName],		-- V1.1
				[SVOvehicle],		-- V1.2 
				[FOBCode],			-- V1.2
				[JLREventType],		-- V1.3
				[LostLead_DateOfLeadCreation],			-- V1.3
				[LostLead_CompleteSuppressionJLR],		-- V1.3		
				[LostLead_CompleteSuppressionRetailer],	-- V1.3	
				[LostLead_PermissionToEmailJLR],		-- V1.3			
				[LostLead_PermissionToEmailRetailer],	-- V1.3	
				[LostLead_PermissionToPhoneJLR],		-- V1.3			
				[LostLead_PermissionToPhoneRetailer],	-- V1.3	
				[LostLead_PermissionToPostJLR],			-- V1.3			
				[LostLead_PermissionToPostRetailer],	-- V1.3		
				[LostLead_PermissionToSMSJLR],			-- V1.3			
				[LostLead_PermissionToSMSRetailer],		-- V1.3		
				[LostLead_PermissionToSocialMediaJLR],		-- V1.3	
				[LostLead_PermissionToSocialMediaRetailer],		-- V1.3
				[LostLead_DateOfLastContact],			-- V1.3
				[HotTopicCodes],						-- V1.4
				[ServiceEventType]						-- V1.6
			)
			SELECT DISTINCT
				O.[AuditID], 
				O.[AuditItemID], 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'CATI') AS [SelectionOutputTypeID],
				S.[CaseID], 
				S.[PartyID], 
				S.[ModelDesc] AS [FullModel], 
				S.RegNumber AS [CarReg], 
				CAST(S.RegDate AS DATETIME2) AS RegDate, 
				S.[VIN], 
				S.[LocalName], 
				S.[CoName], 
				S.[Add1], 
				S.[Add2], 
				S.[Add3], 
				S.[Add4], 
				S.[Add5], 
				S.[LandPhone], 
				S.[WorkPhone], 
				S.[MobilePhone],
				S.[DealerCode] AS [Dealer], 
				S.[DateOutput], 
				S.[JLR], 
				S.[EventTypeID],
				S.[Queue],
				S.[AssignedMode],
				S.[RequiresManualDial],
				S.[CallRecordingsCount],
				S.[TimeZone],			
				S.[CallOutcome],		
				S.[PhoneNumber],		
				S.[PhoneSource],		
				S.[Language],			
				S.[ExpirationTime],	
				S.[HomePhoneNumber],	
				S.[WorkPhoneNumber],	
				S.[MobilePhoneNumber],
				S.[EmployeeName],
				ISNULL(VEH.SVOTypeID,0) AS SVOvehicle,	-- V1.2 
				VEH.[FOBCode],							-- V1.2 
				OO.[JLREventType],					-- V1.3
				OO.[DateOfLeadCreation],			-- V1.3
				OO.[CompleteSuppressionJLR],		-- V1.3		
				OO.[CompleteSuppressionRetailer],	-- V1.3	
				OO.[PermissionToEmailJLR],			-- V1.3			
				OO.[PermissionToEmailRetailer],		-- V1.3	
				OO.[PermissionToPhoneJLR],			-- V1.3			
				OO.[PermissionToPhoneRetailer],		-- V1.3	
				OO.[PermissionToPostJLR],			-- V1.3			
				OO.[PermissionToPostRetailer],		-- V1.3		
				OO.[PermissionToSMSJLR],			-- V1.3			
				OO.[PermissionToSMSRetailer],		-- V1.3		
				OO.[PermissionToSocialMediaJLR],	-- V1.3	
				OO.[PermissionToSocialMediaRetailer],	-- V1.3
				OO.[DateOfLastContact],				-- V1.3
				OO.[HotTopicCodes],					-- V1.4
				OO.[ServiceEventType]					-- V1.6
				
			FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.CATI S ON O.CaseID = S.CaseID
								AND O.PartyID = S.PartyID
								
			INNER JOIN SelectionOutput.OnlineOutput OO	ON	S.CaseID	= OO.ID AND 
															S.PartyID	= OO.PartyID					
			INNER JOIN Vehicle.Vehicles	VEH				ON	OO.VIN		= VEH.VIN
								
			ORDER BY O.AuditItemID

		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #OutputtedSelections
		
	COMMIT TRAN
		
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
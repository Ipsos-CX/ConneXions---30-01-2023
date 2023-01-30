CREATE PROCEDURE [LostLeads].[uspPostOutputUpdate]
@FileName VARCHAR(100)
AS 
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY


/*
	Purpose:	Updates the CaseLostStatusStatuses Audit and Error tables after we have output the LostLead file
		
	Version		Date				Developer			Comment
	1.0			07/03/2018			Chris Ross			Created (See BUG 14413)
	1.3			15/01/2020			Chris Ledger 		BUG 15372 - Fix cases

*/

BEGIN TRAN 

	
		------------------------------------------------------------
		-- Set a single date for all updates
		------------------------------------------------------------
		DECLARE @Datetime DATETIME2
		SET @Datetime = GETDATE()

	
		------------------------------------------------------------
		-- Update the CaseLostStatusStatuses file
		------------------------------------------------------------
		UPDATE lls
		SET lls.OutputDate = @Datetime,
			lls.SequenceID = CONVERT(INT, ob.SequenceID)
		FROM LostLeads.OutputBase ob
		INNER JOIN LostLeads.CaseLostLeadStatuses lls ON lls.EventID = ob.EventID
		WHERE OutputDate IS NULL
	
		

		------------------------------------------------------------
		-- Write the Audit Header and File recs
		------------------------------------------------------------
		DECLARE @AuditID	BIGINT,
				@RowCount	INT
		
		SELECT @RowCount = COUNT(*) FROM LostLeads.OutputBase

		SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 FROM [$(AuditDB)].dbo.Audit
	
		INSERT INTO [$(AuditDB)].dbo.Audit
		SELECT @AuditID

		INSERT INTO [$(AuditDB)].dbo.Files
		(
			AuditID,
			FileTypeID,
			FileName,
			FileRowCount,
			ActionDate
		)
		VALUES
		(
			@AuditID, 
			(SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Lost Leads Output'),
			@FileName,
			@RowCount,
			@Datetime
		)

		INSERT INTO [$(AuditDB)].dbo.OutgoingFiles (AuditID, OutputSuccess)
		VALUES (@AuditID, 1)

		-- Create AuditItems
		DECLARE @max_AuditItemID INT
		SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) FROM [$(AuditDB)].dbo.AuditItems

		-- Insert rows into AuditItems
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditItemID, AuditID)
		SELECT ID + @max_AuditItemID, @AuditID
		FROM LostLeads.OutputBase

		-- Insert rows into FileRows
		INSERT INTO [$(AuditDB)].dbo.FileRows (AuditItemID, PhysicalRow)
		SELECT ID + @max_AuditItemID, @AuditID
		FROM LostLeads.OutputBase


		------------------------------------------------------------
		-- Write the LostLead outputs into the audit table
		------------------------------------------------------------
		;WITH CTE_AllStatuses 
		AS (SELECT 
			   ob.EventID,
			   STUFF((SELECT '; ' + CAST(lls.LeadStatusID AS VARCHAR(3))
					  FROM LostLeads.CaseLostLeadStatuses lls 
					  WHERE lls.EventID = ob.EventID
						AND lls.OutputDate = @Datetime   -- Only include statuses that were output as part of this run
					  FOR XML PATH('')), 1, 1, '') AllStatuses
			FROM  LostLeads.OutputBase ob 
			GROUP BY ob.EventID
		)
		INSERT INTO [$(AuditDB)].Audit.CaseLostLeads_Outputs (AuditItemID, EventID, CaseID, LostLeadAuditItemID, LostLeadStatusID, ValidationFailed, ValidationFailReasons, RegionCode, MarketCode, CountryCode, SourceSystemLeadID, SequenceID, Brand, Nameplate, LeadOrigin, RetailerPAGNumber, RetailerCICode, RetailerBrand, LeadStatus, LeadStartTimestamp, LeadLostTimestamp, PassedToLLAFlag, PassedToLLATimestamp, LostLeadAgency, ReasonsCode, ResurrectedFlag, LastUpdatedByLLA, BoughtElsewhereCompetitorFlag, BoughtElsewhereJLRFlag, ContactedByGfKFlag, VehicleLostBrand, VehicleLostModelRange, VehicleSaleType, OutputDate, AllLostLeadStatuses)
		SELECT  ID + @max_AuditItemID AS AuditItemID, 
				ob.EventID, 
				ob.CaseID, 
				ob.AuditItemID AS LostLeadAuditItemID, 
				ob.LostLeadStatusID, 
				ob.ValidationFailed, 
				ob.ValidationFailReasons, 
				ob.RegionCode, 
				ob.MarketCode, 
				ob.CountryCode, 
				ob.SourceSystemLeadID, 
				ob.SequenceID, 
				ob.Brand, 
				ob.Nameplate, 
				ob.LeadOrigin, 
				ob.RetailerPAGNumber, 
				ob.RetailerCICode, 
				ob.RetailerBrand, 
				ob.LeadStatus, 
				ob.LeadStartTimestamp, 
				ob.LeadLostTimestamp, 
				ob.PassedToLLAFlag, 
				ob.PassedToLLATimestamp, 
				ob.LostLeadAgency, 
				ob.ReasonsCode, 
				ob.ResurrectedFlag, 
				ob.LastUpdatedByLLA, 
				ob.BoughtElsewhereCompetitorFlag, 
				ob.BoughtElsewhereJLRFlag, 
				ob.ContactedByGfKFlag, 
				ob.VehicleLostBrand, 
				ob.VehicleLostModelRange, 
				ob.VehicleSaleType, 
				@Datetime AS OutputDate, 
				cte.AllStatuses AS AllLostLeadStatuses
		FROM LostLeads.OutputBase ob 
		LEFT JOIN CTE_AllStatuses cte ON cte.EventID = ob.EventID


		--------------------------------------------------------------
		-- Write any error records into the Error table for outputting 
		--------------------------------------------------------------
		INSERT INTO [LostLeads].[OutputErrors] (EventID, CaseID, AttemptedOutputDate, ErrorDescription)
		SELECT	EventID, 
				CaseID, 
				@Datetime AS AttemptedOutputDate ,
				ValidationFailReasons
		FROM LostLeads.OutputBase ob 
		WHERE ValidationFailed = 1	
	

COMMIT


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
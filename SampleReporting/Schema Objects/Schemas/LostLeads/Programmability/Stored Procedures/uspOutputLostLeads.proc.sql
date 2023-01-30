CREATE PROCEDURE [LostLeads].[uspOutputLostLeads]
AS
SET NOCOUNT ON;
SET FMTONLY OFF;


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)



BEGIN TRY


/*
	Purpose:	Outputs the LostLeads output base table.  For use in the LostLeads output package.
		
	Version		Date				Developer			Comment
	1.0			06/02/2018			Chris Ross			Created 

*/


	-------------------------------------------------------------------
	-- Output the data
	-------------------------------------------------------------------

	SELECT	RegionCode, 
			MarketCode, 
			CountryCode, 
			SourceSystemLeadID, 
			SequenceID, 
			Brand, 
			Nameplate, 
			LeadOrigin, 
			RetailerPAGNumber, 
			RetailerCICode, 
			RetailerBrand, 
			LeadStatus, 
			LeadStartTimestamp, 
			LeadLostTimestamp, 
			PassedToLLAFlag, 
			PassedToLLATimestamp, 
			LostLeadAgency, 
			ReasonsCode, 
			ResurrectedFlag, 
			LastUpdatedByLLA, 
			BoughtElsewhereCompetitorFlag, 
			BoughtElsewhereJLRFlag, 
			ContactedByGfKFlag, 
			VehicleLostBrand, 
			VehicleLostModelRange, 
			VehicleSaleType
	FROM LostLeads.OutputBase
	WHERE ValidationFailed = 0

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


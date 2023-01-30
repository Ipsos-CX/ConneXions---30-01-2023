CREATE PROCEDURE [Match].[uspIAssistanceNetworks]
AS

/*
	Purpose:	Match the IAssistance Centre codes in the VWT table against the Centre code held in IAssistanceNetworks
	
	Version			Date			Developer			Comment
	1.0				22-10-2018		Chris Ledger		Created from Sample_ETL.Match.uspCRCNetworks

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

			-- MATCH IASSISTANCE NETWORKS
			UPDATE V
			SET V.IAssistanceCentrePartyID = R.IAssistanceCentrePartyID
			FROM Match.vwIAssistanceNetworks R 
			INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.IAssistanceCentreCode)) = R.IAssistanceCentreCode
			WHERE R.PartyIDTo = V.IAssistanceCentreOriginatorPartyID
			AND R.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwIAssistanceNetworkRoleTypes)  -- IASSISTANCE NETWORK

		
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
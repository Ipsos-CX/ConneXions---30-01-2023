CREATE PROCEDURE [Match].[uspCRCNetworks]
AS

/*
	Purpose:	Match the CRC Centre codes in the VWT table against the Centre code held in CRCNetworks
	
	Version			Date			Developer			Comment
	1.0				30-09-2014		Chris Ross			Created from Sample_ETL.Match.uspCRCNetworks

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

			-- MATCH ROADSIDE NETWORKS
			UPDATE V
			SET V.CRCCentrePartyID = R.CRCCentrePartyID
			FROM Match.vwCRCNetworks R 
			INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.CRCCentreCode)) = R.CRCCentreCode
			WHERE R.PartyIDTo = V.CRCCentreOriginatorPartyID
			AND R.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwCRCNetworkRoleTypes)  -- ROADSIDE NETWORK
			--AND (R.CountryID = V.CountryID OR R.CountryID IS NULL)

		
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
CREATE PROCEDURE [Match].[uspRoadsideNetworks]
AS

/*
	Purpose:	Match the dealer codes in the VWT table against the dealer code held in DealerNetworks
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Chris Ross		Created from Sample_ETL.Match.uspDealers

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

print 1

			-- MATCH ROADSIDE NETWORKS
			UPDATE V
			SET V.RoadsideNetworkPartyID = R.RoadsideNetworkPartyID
			FROM Match.vwRoadsideNetworks R 
			INNER JOIN dbo.VWT V ON LTRIM(RTRIM(V.RoadsideNetworkCode)) = R.RoadsideNetworkCode
			WHERE R.PartyIDTo = V.RoadsideNetworkOriginatorPartyID
			AND R.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwRoadsideNetworkRoleTypes)  -- ROADSIDE NETWORK
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
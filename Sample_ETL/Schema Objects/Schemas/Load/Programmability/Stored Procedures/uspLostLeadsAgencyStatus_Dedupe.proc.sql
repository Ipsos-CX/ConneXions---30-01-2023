CREATE PROCEDURE [Load].[uspLostLeadsAgencyStatus_Dedupe]
/* Purpose:	dedupe records into LostLeadsAgencyStatus lookup table

	Version		Date			Developer			Comment
	1.1			2018-02-21		Chris Ledger		BUG 14555: Add Market

*/
AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE st
	SET st.ParentAuditItemID = M.ParentAuditItemID
	FROM Stage.LostLeadsAgencyStatus st
	INNER JOIN (
		SELECT
			MAX(AuditItemID) AS ParentAuditItemID,
			Market,		-- V1.1
			CICode, 
			Retailer
		FROM	Stage.LostLeadsAgencyStatus
		GROUP BY Market, CICode, Retailer	-- V1.1
	) M ON	M.Market = st.Market
			AND M.CICode = st.CICode 
			AND	M.Retailer = st.Retailer 
			
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

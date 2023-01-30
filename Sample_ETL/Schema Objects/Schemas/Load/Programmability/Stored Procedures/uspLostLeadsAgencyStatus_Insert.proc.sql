CREATE PROCEDURE [Load].[uspLostLeadsAgencyStatus_Insert]
/* Purpose:	Insert new records into LostLeadsAgencyStatus lookup table

	Version		Date			Developer			Comment
	1.1			2017-10-10		Chris Ledger		BUG 14272: Only Delete Where LostSalesProvider Exists in Staging Table
	1.2			2018-02-21		Chris Ledger		BUG 14555: Add Market

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


	BEGIN TRAN
	
		--	V1.2 DELETE ROWS WHERE Market EXISTS IN STAGING TABLE
		DELETE FROM LL
		FROM Lookup.LostLeadsAgencyStatus LL
		WHERE EXISTS
		(SELECT S.Market
		FROM Stage.LostLeadsAgencyStatus S
		WHERE S.Market = LL.Market
		)	


		-- ADD THE NEW ITEMS TO THE LOOKUP 
		INSERT INTO [Lookup].LostLeadsAgencyStatus	
		(
			Market,		-- V1.2
			CICode,
			Retailer,
			Brand,		-- V1.2
			LostSalesProvider,
			Confirmation
		)
		SELECT DISTINCT
		
				LTRIM(RTRIM(Market)),				-- V1.2
				LTRIM(RTRIM(CICode)),
				LTRIM(RTRIM(Retailer)),
				LTRIM(RTRIM(Brand)),				-- V1.2
				LTRIM(RTRIM(LostSalesProvider)),
				CASE SUBSTRING(LTRIM(RTRIM(ConfirmationYN)),1,1)	-- V1.2
					WHEN 'Y' THEN CAST(1 AS BIT)					-- V1.2
					ELSE CAST(0 AS BIT)
				END						
				
		FROM	Stage.LostLeadsAgencyStatus	 st
		WHERE	st.AuditItemID = st.ParentAuditItemID



		-- INSERT INTO [Audit].[Lookup_LostLeadsAgencyStatus] WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].[Audit].[Lookup_LostLeadsAgencyStatus]	
		(
			AuditItemID,
			Market,				-- V1.2
			CICode,
			Retailer,
			Brand,				-- V1.2
			LostSalesProvider,
			Confirmation
		)
		SELECT 
			st.AuditItemID,
			LTRIM(RTRIM(st.Market)),			-- V1.2
			LTRIM(RTRIM(st.CICode)),
			LTRIM(RTRIM(st.Retailer)),
			LTRIM(RTRIM(st.Brand)),				-- V1.2
			LTRIM(RTRIM(st.LostSalesProvider)),
			LTRIM(RTRIM(st.ConfirmationYN))			 	 
		FROM [Stage].[LostLeadsAgencyStatus] st
		LEFT JOIN [$(AuditDB)].[Audit].[Lookup_LostLeadsAgencyStatus] AUD ON	LTRIM(RTRIM(st.Market))				= AUD.Market AND				-- V1.2
																				LTRIM(RTRIM(st.CICode))				= AUD.CICode AND
																				LTRIM(RTRIM(st.Retailer))			= AUD.Retailer AND
																				LTRIM(RTRIM(st.Brand))				= AUD.Brand AND					-- V1.2
																				LTRIM(RTRIM(st.LostSalesProvider))	= AUD.LostSalesProvider AND 
																				st.AuditItemID						= AUD.AuditItemID 	
		WHERE	AUD.AuditItemID IS NULL
		
		

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

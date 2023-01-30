CREATE PROCEDURE [CustomerUpdate].[uspCRCLookup_Insert]

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
	
		-- ADD THE NEW ITEMS TO THE LOOKUP 
		INSERT INTO [Lookup].CRCAgentLookUp
		(
			Code,
			FullName,
			FirstName,
			Brand,
			MarketCode
		)
		SELECT DISTINCT
				CUL.Code,
				CUL.FullName,
				CUL.FirstName,
				CUL.Brand,
				CUL.MarketCode
		FROM CustomerUpdate.CRCAgentLookUp CUL
		LEFT JOIN [Lookup].[CRCAgentLookUp] CRC ON CUL.Code = CRC.Code AND
																CASE
																	WHEN  CUL.Brand = 'Jaguar' THEN 'J' 
																	WHEN  CUL.Brand = 'Land Rover' THEN 'L'
																	ELSE  CUL.Brand
																END   = CRC.Brand AND
																CUL.MarketCode = CRC.MarketCode 		
		WHERE	NULLIF(LTRIM(RTRIM(CRC.FullName)),'')  IS NULL
				AND CUL.AuditItemID = CUL.ParentAuditItemID



		-- INSERT INTO [Audit].[CRCAgentLookUp] WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].[Audit].[CRCAgentLookUp]
		
		(
			AuditItemID,
			Code,
			FullName,
			FirstName,
			Brand,
			MarketCode
		)
		SELECT DISTINCT
			CUL.AuditItemID,
			CUL.Code,
			CUL.FullName,
			CUL.FirstName,
			CUL.Brand,
			CUL.MarketCode
			 	 
		FROM [CustomerUpdate].[CRCAgentLookUp] CUL
		LEFT JOIN [$(AuditDB)].[Audit].[CRCAgentLookUp] AUD ON CUL.Code = AUD.Code AND
																CASE
																	WHEN  CUL.Brand = 'Jaguar' THEN 'J' 
																	WHEN  CUL.Brand = 'Land Rover' THEN 'L'
																	ELSE  CUL.Brand
																END   = AUD.Brand AND
																CUL.MarketCode = AUD.MarketCode AND 
																CUL.AuditItemID = AUD.AuditItemID 	
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


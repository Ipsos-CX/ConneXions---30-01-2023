CREATE PROCEDURE [CRM].[uspCRC_AddAuditItemIDs]

AS

/*
		Purpose:	Create/Assign AuditItemIDs to CRM event driven sales records
	
		Version		Developer			Created			Comment
LIVE	1.0			Martin Riverol		04/08/2014		Created
LIVE	1.1			Chris Ledger		24/09/2021		TASK 502: Addition of updating AuditItemID for extra CRM tables
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

			/* GET THE NEXT AUDITITEMID */		
			DECLARE @MaxAuditItemID INT
			SET @MaxAuditItemID = (SELECT MAX(AuditItemID) FROM [$(AuditDB)].dbo.AuditItems)


			/* ASSIGN THE NEXT AUDITITEMIDS IN SEQUENCE TO ANY RECORDS WITHOPUT AN AUDITITEMID */
			;WITH cteAuditItems	AS
			(
				SELECT AuditID, 
					PhysicalRowID, 
					ROW_NUMBER() OVER (ORDER BY AuditID, PhysicalRowID) + @MaxAuditItemID AS AuditItemID
				FROM CRM.CRCCall_Call
				WHERE ISNULL(AuditItemID, 0) = 0 
					AND ISNULL(AuditID, 0) > 0
			)
			UPDATE CRC
			SET CRC.AuditItemID = AI.AuditItemID
			FROM CRM.CRCCall_Call CRC
				INNER JOIN cteAuditItems AI ON CRC.AuditID = AI.AuditID 
												AND CRC.PhysicalRowID = AI.PhysicalRowID

		
			/* WRITE THE NEW AUDITITEMIDS */
			INSERT INTO [$(AuditDB)].dbo.AuditItems
			(
				AuditID,
				AuditItemID
			)
			SELECT 
				AuditID,
				AuditItemID
			FROM CRM.CRCCall_Call CRC
			WHERE NOT EXISTS (	SELECT 1 
								FROM [$(AuditDB)].dbo.AuditItems AI 
								WHERE AI.AuditItemID = CRC.AuditItemID)


			/* WRITE THE NEW FILEROWS */
			INSERT INTO [$(AuditDB)].dbo.FileRows
			(
				AuditItemID,
				PhysicalRow
			)
			SELECT 
				AuditItemID,
				PhysicalRowID
			FROM CRM.CRCCall_Call CRC
			WHERE NOT EXISTS (	SELECT 1 
								FROM [$(AuditDB)].dbo.FileRows AI 
								WHERE AI.AuditItemID = CRC.AuditItemID)


			/* V1.1 Update AuditItemID for extra CRM tables */
			UPDATE AMP
			SET AMP.AuditItemID = CRC.AuditItemID
			FROM CRM.CRCCall_Call CRC
				INNER JOIN CRM.CRC_ACCT_MKT_PERM AMP ON CRC.AuditID = AMP.AuditID
														AND CRC.item_Id = AMP.item_Id
			WHERE AMP.AuditItemID IS NULL

			UPDATE AMPI
			SET AMPI.AuditItemID = AMP.AuditItemID 
			FROM CRM.CRCCall_Call CRC
				INNER JOIN CRM.CRC_ACCT_MKT_PERM AMP ON CRC.AuditID = AMP.AuditID
															AND CRC.item_Id = AMP.item_Id
				INNER JOIN CRM.CRC_ACCT_MKT_PERM_ITEM AMPI ON AMP.AuditID = AMPI.AuditID
																AND AMP.ACCT_MKT_PERM_Id = AMPI.ACCT_MKT_PERM_Id
			WHERE AMPI.AuditItemID IS NULL

			UPDATE CMP
			SET CMP.AuditItemID = CRC.AuditItemID
			FROM CRM.CRCCall_Call CRC
				INNER JOIN CRM.CRC_CNT_MKT_PERM CMP ON CRC.AuditID = CMP.AuditID
														AND CRC.item_Id = CMP.item_Id
			WHERE CMP.AuditItemID IS NULL

			UPDATE CMPI
			SET CMPI.AuditItemID = CMP.AuditItemID 
			FROM CRM.CRCCall_Call CRC
				INNER JOIN CRM.CRC_CNT_MKT_PERM CMP ON CRC.AuditID = CMP.AuditID
															AND CRC.item_Id = CMP.item_Id
				INNER JOIN CRM.CRC_CNT_MKT_PERM_ITEM CMPI ON CMP.AuditID = CMPI.AuditID
																AND CMP.CNT_MKT_PERM_Id = CMPI.CNT_MKT_PERM_Id
			WHERE CMPI.AuditItemID IS NULL
			/* V1.1 Update AuditItemID for extra CRM tables */
			
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

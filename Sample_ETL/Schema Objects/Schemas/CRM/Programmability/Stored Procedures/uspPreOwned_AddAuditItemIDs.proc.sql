CREATE PROCEDURE [CRM].[uspPreOwned_AddAuditItemIDs]

AS

/*
		Purpose:	Create/Assign AuditItemIDs to CRM event driven PreOwned records
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ledger		2016-12-02		Created
LIVE	1.1			Chris Ledger		2021-09-24		TASK 502: Addition of updating AuditItemID for extra CRM tables
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
			;WITH cteAuditItems AS
			(
				SELECT AuditID, 
					PhysicalRowID, 
					ROW_NUMBER() OVER (ORDER BY AuditID, PhysicalRowID) + @MaxAuditItemID AS AuditItemID
				FROM CRM.PreOwned PO
				WHERE ISNULL(AuditItemID, 0) = 0 
					AND ISNULL(AuditID, 0) > 0
			)
			UPDATE PO
				SET PO.AuditItemID = AI.AuditItemID
			FROM CRM.PreOwned PO
				INNER JOIN cteAuditItems AI ON PO.AuditID = AI.AuditID 
												AND PO.PhysicalRowID = AI.PhysicalRowID;

		
			/* WRITE THE NEW AUDITITEMIDS */
			INSERT INTO [$(AuditDB)].dbo.AuditItems
			(
				AuditID,
				AuditItemID
			)
			SELECT 
				AuditID,
				AuditItemID
			FROM CRM.PreOwned PO
			WHERE NOT EXISTS (	SELECT 1 
								FROM [$(AuditDB)].dbo.AuditItems AI 
								WHERE AI.AuditItemID = PO.AuditItemID)


			/* WRITE THE NEW FILEROWS */
			INSERT INTO [$(AuditDB)].dbo.FileRows
			(
				AuditItemID,
				PhysicalRow
			)
			SELECT 
				PO.AuditItemID,
				PO.PhysicalRowID
			FROM CRM.PreOwned PO
			WHERE NOT EXISTS (	SELECT 1 
								FROM [$(AuditDB)].dbo.FileRows AI 
								WHERE AI.AuditItemID = PO.AuditItemID)


			/* V1.1 Update AuditItemID for extra CRM tables */
			UPDATE AMP
			SET AMP.AuditItemID = PO.AuditItemID
			FROM CRM.PreOwned PO
				INNER JOIN CRM.PreOwned_ACCT_MKT_PERM AMP ON PO.AuditID = AMP.AuditID
														AND PO.item_Id = AMP.item_Id
			WHERE AMP.AuditItemID IS NULL

			UPDATE AMPI
			SET AMPI.AuditItemID = AMP.AuditItemID 
			FROM CRM.PreOwned PO
				INNER JOIN CRM.PreOwned_ACCT_MKT_PERM AMP ON PO.AuditID = AMP.AuditID
															AND PO.item_Id = AMP.item_Id
				INNER JOIN CRM.PreOwned_ACCT_MKT_PERM_ITEM AMPI ON AMP.AuditID = AMPI.AuditID
																AND AMP.ACCT_MKT_PERM_Id = AMPI.ACCT_MKT_PERM_Id
			WHERE AMP.AuditItemID IS NULL

			UPDATE CMP
			SET CMP.AuditItemID = PO.AuditItemID
			FROM CRM.PreOwned PO
				INNER JOIN CRM.PreOwned_CNT_MKT_PERM CMP ON PO.AuditID = CMP.AuditID
														AND PO.item_Id = CMP.item_Id
			WHERE CMP.AuditItemID IS NULL

			UPDATE CMPI
			SET CMPI.AuditItemID = CMP.AuditItemID 
			FROM CRM.PreOwned PO
				INNER JOIN CRM.PreOwned_CNT_MKT_PERM CMP ON PO.AuditID = CMP.AuditID
															AND PO.item_Id = CMP.item_Id
				INNER JOIN CRM.PreOwned_CNT_MKT_PERM_ITEM CMPI ON CMP.AuditID = CMPI.AuditID
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

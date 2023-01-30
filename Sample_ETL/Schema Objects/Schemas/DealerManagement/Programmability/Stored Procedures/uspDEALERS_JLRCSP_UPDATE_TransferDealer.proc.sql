CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_TransferDealer]

AS
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

	-- Purpose: Update transfer outlet details in the flattened dealer hierarchy table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		14/05/2012		Created
	-- 1.1			Martin Riverol		13/07/2012		Once updated, rebuild the flattened table of dealers 
	-- 1.2			Martin Riverol		12/04/2013		Include the new GDD code as part of the dealer transfer
	-- 1.3			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases


	-- DECLARE LOCAL VARIABLES 

		DECLARE @ErrorCode INT
		DECLARE @ErrorNumber INT
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ErrorLocation NVARCHAR(500)
		DECLARE @ErrorLine INT
		DECLARE @ErrorMessage NVARCHAR(2048)


		BEGIN TRY

		-- POPULATE WORKSPACE TABLE TO HOLD AUDIT TRAIL INFO

			CREATE TABLE #AuditTrail
				(
					ID INT
					, IP_TransferDealerChangeID INT
					, ID_Hierarchy INT
					, PartyID INT
					, RoleTypeID INT
					, PartyRoleID INT
					, AuditID INT
					, AuditItemID INT
				)


			INSERT INTO #AuditTrail
			
				(
					ID
					, IP_TransferDealerChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UTD.IP_TransferDealerChangeID) ID
						, UTD.IP_TransferDealerChangeID
						, UTD.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD
					INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON UTD.IP_SystemUser = DU.UserName
					WHERE UTD.IP_ProcessedDate IS NULL
					AND UTD.IP_DataValidated = 1

		
		-- GET A DISTINCT LIST OF PARTYROLEIDS FROM WORKSPACE TABLE 

			SELECT DISTINCT
				ROW_NUMBER() OVER (ORDER BY PartyRoleID) ID
				, NEWID() AS GUID
				, PartyRoleID 
			INTO #DistinctUsers
			FROM #AuditTrail AR
			GROUP BY PartyRoleID


		-- CREATE AN AUDITID SESSION FOR EACH PARTY WHO HAS WRITTEN UPDATES

		INSERT INTO [$(AuditDB)].OWAP.vwDA_Sessions

			(
				AuditID
				, UserPartyRoleID
				, SessionID
				, SessionTimeStamp 
			)

			SELECT 
				0 AS AuditID
				, DU.PartyRoleID
				, U.UserName + ' - Dealer Transfer update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer Transfer update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


		-- NOW CREATE SOME AUDITITEMIDS AS OWAP_ACTIONS

			INSERT INTO [$(AuditDB)].owap.vwDA_Actions
			
				(
					AuditItemID
					, AuditID
					, ActionDate
					, UserPartyID
					, UserRoleTypeID
				)

					SELECT 
						AuditItemID
						, AuditID
						, GETDATE()
						, PartyID
						, RoleTypeID
					FROM #AuditTrail

				
		-- WRITE THE CREATED AUDITITEMIDS BACK TO THE WORKSPACE TABLE

			UPDATE A
			SET AuditItemID = A.ID + B.difference
			FROM #AuditTrail A
			INNER JOIN
				(
					SELECT 
						T.AuditID
						, MIN(A.AuditItemID) - MIN(T.ID) AS difference
					FROM #AuditTrail T 
					INNER JOIN [$(AuditDB)].OWAP.Sessions S ON T.AuditID = S.AuditID
					INNER JOIN [$(AuditDB)].dbo.AuditItems I ON S.AuditID = I.AuditID
					INNER JOIN [$(AuditDB)].OWAP.Actions A ON I.AuditItemID = A.AuditItemID
					GROUP BY T.AuditID
				) B
			ON A.AuditID = B.AuditID


		-- WRITE AUDITITEMIDS BACK TO DEALER TRANSFER TABLE

			UPDATE UTD
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD ON AT.IP_TransferDealerChangeID = UTD.IP_TransferDealerChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET TransferDealer = UTD.IP_TransferOutlet
			, TransferDealerCode = UTD.TransferOutletCode
			, TransferDealerCode_GDD = TD.OutletCode_GDD
			, TransferPartyID = UTD.IP_TransferOutletPartyID
			, SubNationalRegion = TD.SubNationalRegion
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD
		INNER JOIN [$(SampleDB)].DBO.DW_JLRCSPDealers D ON UTD.[id] = D.[id]
		INNER JOIN [$(SampleDB)].DBO.DW_JLRCSPDealers TD ON UTD.IP_TransferOutletPartyID = TD.OutletPartyID
													AND UTD.OutletFunction = TD.OutletFunction
		WHERE UTD.IP_ProcessedDate IS NULL
		AND UTD.IP_DataValidated = 1

	

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UTD
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD ON AT.AuditItemID = UTD.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		EXEC DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList
		
	END TRY

	BEGIN CATCH

		SET @ErrorCode = @@Error

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
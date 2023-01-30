CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_OutletDealerGroup]

AS
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

	-- Purpose: Update outlet dealer group details in the flattened dealer hierarchy table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		14/05/2012		Created
	-- 1.1			Martin Riverol		13/07/2012		Once updated, rebuild the flattened table of dealers 
	-- 1.2			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases

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
					, IP_DealerGroupChangeID INT
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
					, IP_DealerGroupChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UDG.IP_DealerGroupChangeID) ID
						, UDG.IP_DealerGroupChangeID
						, UDG.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG
					INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON UDG.IP_SystemUser = DU.UserName
					WHERE UDG.IP_ProcessedDate IS NULL
					AND UDG.IP_DataValidated = 1

		
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
				, U.UserName + ' - Dealer Group update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer Group update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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


		-- WRITE AUDITITEMIDS BACK TO DEALER APPOINTMENT TABLE

			UPDATE UDG
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG ON AT.IP_DealerGroupChangeID = UDG.IP_DealerGroupChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET CombinedDealer = UDG.NewDealerGroup
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UDG.ID = D.ID
		WHERE UDG.IP_ProcessedDate IS NULL
		AND UDG.IP_DataValidated = 1
		AND UDG.NewDealerGroup <> D.CombinedDealer
	
	-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR NAME CHANGED

		UPDATE D 
			SET CombinedDealer = UDG.NewDealerGroup
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UDG.IP_OutletPartyID = d.TransferPartyID
													AND UDG.OutletCode = D.TransferDealerCode
													AND UDG.Manufacturer = D.Manufacturer
													AND UDG.Market = D.Market
													AND UDG.OutletFunction = D.OutletFunction
		WHERE UDG.IP_ProcessedDate IS NULL
		AND UDG.IP_DataValidated = 1
		AND UDG.NewDealerGroup <> D.CombinedDealer
	

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UDG
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG ON AT.AuditItemID = UDG.IP_AuditItemID
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
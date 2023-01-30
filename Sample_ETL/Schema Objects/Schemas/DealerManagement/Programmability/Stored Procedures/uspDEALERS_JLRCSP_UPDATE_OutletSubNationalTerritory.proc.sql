CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_OutletSubNationalTerritory]

AS
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

	-- Purpose: Update outlet sub-national territory details in the flattened dealer hierarchy table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Chris Ross			12/10/2016		Created - BUG 13171. (copied from SubNational Region proc)
	-- 1.1			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases



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
					, IP_SubNationalTerritoryChangeID INT
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
					, IP_SubNationalTerritoryChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY USNR.IP_SubNationalTerritoryChangeID) ID
						, USNR.IP_SubNationalTerritoryChangeID
						, USNR.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR
					INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON USNR.IP_SystemUser = DU.UserName
					WHERE USNR.IP_ProcessedDate IS NULL
					AND USNR.IP_DataValidated = 1

		
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
				, U.UserName + ' - Dealer SNR update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer SNR update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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

			UPDATE USNR
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR ON AT.IP_SubNationalTerritoryChangeID = USNR.IP_SubNationalTerritoryChangeID


		--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET SubNationalTerritory = USNR.NewSubNationalTerritory,
				SubNationalRegion = USNR.NewSubNationalRegion
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D --ON USNR.ID = D.ID    -- v1.2 Removed specific Dealer ID to link to multi-party Outlet Codes rows (allows for inactive using same code - checks for multi-active parties already done in trigger)
												ON USNR.OutletCode = D.OutletCode
												AND USNR.Manufacturer = D.Manufacturer
												AND USNR.Market = D.Market
												AND USNR.OutletFunction = D.OutletFunction
		WHERE USNR.IP_ProcessedDate IS NULL
		AND USNR.IP_DataValidated = 1
		AND USNR.NewSubNationalTerritory <> D.SubNationalTerritory
		AND USNR.NewSubNationalRegion <> D.SubNationalRegion
	
	
		-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR NAME CHANGED

		UPDATE D 
			SET SubNationalTerritory = USNR.NewSubNationalTerritory,
				SubNationalRegion = USNR.NewSubNationalRegion
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR
		LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON USNR.OutletCode = D.TransferDealerCode
													AND USNR.Manufacturer = D.Manufacturer
													AND USNR.Market = D.Market
													AND USNR.OutletFunction = D.OutletFunction
												--	AND USNR.IP_OutletPartyID = d.TransferPartyID    --- v1.2 Removed so that the we update all associated rows even if mutiples parties on OutletCode (e.g. mutiple inactive parties with same outlet code)
		WHERE USNR.IP_ProcessedDate IS NULL
		AND USNR.IP_DataValidated = 1
		AND USNR.NewSubNationalTerritory <> D.SubNationalTerritory
		AND USNR.NewSubNationalRegion <> D.SubNationalRegion
	

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE USNR
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR ON AT.AuditItemID = USNR.IP_AuditItemID
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
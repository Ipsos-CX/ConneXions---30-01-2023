CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_SVODealer]

AS
SET NOCOUNT ON
	SET QUOTED_IDENTIFIER ON

	-- Purpose: Update SVODealer and FleetDealer flags in both the sample model and the flattened dealer hierarchy table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.1			Chris Ledger		2017-11-13		Created from uspDEALERS_JLRCSP_UPDATE_PAGCode
	-- 1.2			Chris Ledger		2020-01-10		BUG 15372 - Fix Hard coded references to databases


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
					, IP_IP_SVODealerChangeID INT
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
					, IP_IP_SVODealerChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UON.IP_SVODealerChangeID) ID
						, UON.IP_SVODealerChangeID
						, UON.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SVODealer UON
					INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON UON.IP_SystemUser = DU.UserName
					WHERE UON.IP_ProcessedDate IS NULL
					AND UON.IP_DataValidated = 1

		
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
				, U.UserName + ' - SVODealer/FleetDealer Update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - SVODealer/FleetDealer Update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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


		-- WRITE AUDITITEMIDS BACK TO DEALER SVODealer TABLE

			UPDATE UON
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_SVODealer UON ON AT.IP_IP_SVODealerChangeID = UON.IP_SVODealerChangeID

	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET SVODealer = UON.[SVODealer],
				FleetDealer = UON.[FleetDealer]
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_SVODealer UON
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UON.ID = D.ID
		WHERE UON.IP_ProcessedDate IS NULL
		AND UON.IP_DataValidated = 1
		AND (UON.SVODealer <> D.SVODealer OR UON.FleetDealer <> D.FleetDealer)
	
	

	-- PERFORM UPDATE ON SAMPLING RELATIONSHIPS (WHERE SPECIFIED). CREATE TABLE TO HOLD IMPORTER / MANUFACTURER RELATIONSHIPS AND POPULATE IT
	-- WE NEED THIS FOR CORRELATED SUBQUERY BETWEEN DEALERNETWORKS DATA ACCESS VIEW AND NAMECHANGEOVERWRITES TABLE BECAUSE...
	-- YOU CAN'T USE UPDATE..FROM WHERE TARGET IS VIEW WITH 'INSTEAD OF' TRIGGER


	
	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UON
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail D
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_SVODealer UON ON D.AuditItemID = UON.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		EXEC DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList
				
	END TRY

	BEGIN CATCH

		SET @ErrorCode = @@Error

		SELECT
			 @ErrorNumber = ERROR_NUMBER()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()
			,@ErrorLocation = ERROR_PROCEDURE()
			,@ErrorLine = ERROR_LINE()
			,@ErrorMessage = ERROR_MESSAGE()

		EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
			 @ErrorNumber
			,@ErrorSeverity
			,@ErrorState
			,@ErrorLocation
			,@ErrorLine
			,@ErrorMessage
			
		RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
			
	END CATCH




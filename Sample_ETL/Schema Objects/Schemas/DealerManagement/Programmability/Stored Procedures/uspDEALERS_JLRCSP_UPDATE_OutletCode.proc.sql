CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_OutletCode]

AS

SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

	-- 1.1			Martin Riverol		13/07/2012		Once updated, rebuild the flattened table of dealers
	-- 1.2			Martin Riverol		26/09/2013		Bug #9446: Get original outlet code so we can constrain on these rows 
    --													only when updating dealer networks (i.e. preserve old codes)										 
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
					, IP_OutletCodeChangeID INT
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
					, IP_OutletCodeChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UOC.IP_OutletCodeChangeID) ID
						, UOC.IP_OutletCodeChangeID
						, UOC.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode UOC
					INNER JOIN [$(SampleDB)].DealerManagement.vwUsers DU ON UOC.IP_SystemUser = DU.UserName
					WHERE UOC.IP_ProcessedDate IS NULL
					AND UOC.IP_DataValidated = 1

		
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
				, U.UserName + ' - Dealer name update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN [$(SampleDB)].DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer name update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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

			UPDATE UOC
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode UOC ON AT.IP_OutletCodeChangeID = UOC.IP_OutletCodeChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET OutletCode = UOC.NewOutletCode
			, TransferDealerCode = 	
								CASE
									-- ALSO UPDATE TRANSFER OUTLET COLUMNS IF THE OUTLET IS A TRANSFER DEALER
									WHEN D.TransferDealer = D.Outlet AND D.TransferPartyID = D.OutletPartyID 
									THEN UOC.NewOutletCode
									ELSE D.TransferDealer 
								END
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode UOC
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UOC.ID = D.ID
		WHERE UOC.IP_ProcessedDate IS NULL
		AND UOC.IP_DataValidated = 1
		AND UOC.NewOutletCode <> D.OutletCode
	
	-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR CODE CHANGED

		UPDATE D 
			SET D.TransferDealerCode = UOC.NewOutletCode
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode UOC
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UOC.IP_OutletPartyID = d.TransferPartyID
													AND UOC.OutletCode = D.TransferDealerCode
													AND UOC.Manufacturer = D.Manufacturer
													AND UOC.Market = D.Market
													AND UOC.OutletFunction = D.OutletFunction
		WHERE UOC.IP_ProcessedDate IS NULL
		AND UOC.IP_DataValidated = 1
		AND UOC.NewOutletCode <> D.TransferDealerCode	

	-- PERFORM UNPDATE ON SAMPLING RELATIONSHIPS (WHERE SPECIFIED). CREATE TABLE TO HOLD IMPORTER / MANUFACTURER RELATIONSHIPS AND POPULATE IT
	-- WE NEED THIS FOR CORRELATED SUBQUERY BETWEEN DEALERNETWORKS DATA ACCESS VIEW AND NAMECHANGEOVERWRITES TABLE BECAUSE...
	-- YOU CAN'T USE UPDATE..FROM WHERE TARGET IS VIEW WITH 'INSTEAD OF' TRIGGER


	-- CREATE TEMP TABLE OF IMPORTERS

		CREATE TABLE #importers

			(
				ImporterPartyID INT 
				, ManufacturerPartyID INT 
				, ManufacturerOrganisationName NVARCHAR(255) 
				, ImporterOrganisationName NVARCHAR(255)
			)
			
	-- PUT MANUFACTURERS IMPORTER ORGANISATIONS INTO A TEMP TABLE	

		INSERT INTO #importers

			(
				ImporterPartyID
				, ManufacturerPartyID
				, ManufacturerOrganisationName
				, ImporterOrganisationName
			)

				SELECT
					PR.PartyIDFrom AS ImporterPartyID 
					, PR.PartyIDTo AS ManufacturerPartyID 
					, M.OrganisationName AS ManufacturerOrganisationName 
					, I.OrganisationName AS ImporterOrganisationName
				FROM [$(SampleDB)].Party.PartyRelationships AS PR
				INNER JOIN [$(SampleDB)].Party.Organisations AS M ON PR.PartyIDTo = M.PartyID
				INNER JOIN [$(SampleDB)].Party.Organisations AS I ON PR.PartyIDFrom = I.PartyID
				WHERE PR.PartyIDTo IN (2, 3) -- JAGUAR AND LANDROVER
				AND PR.PartyRelationshipTypeID = 8 -- IMPORTER RELATIONSHIPS	 

	-- PUT CODE CHANGE UPDATES INTO A TABLE SO WE CAN LOOP THROUGH INSERTING INTO UPDATE TRIGGERS ON ORGANISATIONS AND DEALERNETWORK TABLES

		SELECT 
			IDENTITY(INT, 1, 1) AS ID 
			, X.AuditItemID 
			, X.OutletPartyID
			, X.RoleTypeIDFrom
			, X.OutletCode
			, X.NewOutletCode
		INTO #DealerCodes
		FROM 
			(
				SELECT 
					MIN(UOC.IP_AuditItemID) AS AuditItemID 
					, UOC.IP_OutletPartyID AS OutletPartyID
					, DN.RoleTypeIDFrom
					, UOC.OutletCode
					, UOC.NewOutletCode
				FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode UOC
				INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers AS D ON UOC.ID = D.ID
				INNER JOIN [$(SampleDB)].Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID 
														AND DN.RoleTypeIDFrom = D.OutletFunctionID
				INNER JOIN #importers AS I ON D.ManufacturerPartyID = I.ManufacturerPartyID
											AND DN.PartyIDTo IN (I.ManufacturerPartyID, i.ImporterPartyID)
				WHERE d.OutletPartyID = DN.PartyIDFrom
				AND d.OutletFunctionID = DN.RoleTypeIDFrom
				AND d.ManufacturerPartyID = i.ManufacturerPartyID
				AND UOC.IP_ProcessedDate IS NULL
				AND UOC.IP_DataValidated = 1
				GROUP BY 
					UOC.NewOutletCode
					, UOC.IP_OutletPartyID
					, DN.RoleTypeIDFrom
					, UOC.OutletCode
			) X


	-- LOOP THROUGH TABLE INSERTING ROWS INTO LEGALORGANISATION AND DEALERNETWORK DATA ACCESS UPDATE VIEWS

		DECLARE @Counter INT
		SET @Counter = 1
		
		DECLARE @AuditItemID BIGINT
		DECLARE @OutletPartyID INT
		DECLARE @OutletCode NVARCHAR(10)
		DECLARE @NewOutletCode NVARCHAR(10)
		DECLARE @RoleTypeIDFrom INT
		
		WHILE @Counter <= (SELECT MAX(ID) FROM #DealerCodes)

		BEGIN
			SELECT
				 @AuditItemID = AuditItemID
				, @OutletPartyID = OutletPartyID
				, @OutletCode = OutletCode
				, @NewOutletCode = NewOutletCode
				, @RoleTypeIDFrom = RoleTypeIDFrom
			FROM #DealerCodes
			WHERE ID = @Counter
			
			
			-- DEALERNETWORKS USES THE LOCAL LANGUAGE DEALER NAME AS THIS SHOULD BE WHAT GOES IN ANY OUTPUT FILES

				UPDATE [$(SampleDB)].Party.vwDA_DealerNetworks
					SET	AuditItemID = @AuditItemID 
					, DealerCode = @NewOutletCode
				WHERE PartyIDFrom = @OutletPartyID
				AND RoleTypeIDFrom = @RoleTypeIDFrom
				AND DealerCode = @OutletCode
			
			SET @Counter = @Counter + 1
		END

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UON
			SET IP_ProcessedDate = GETDATE()
		FROM #DealerCodes D
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode UON ON D.AuditItemID = UON.IP_AuditItemID
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
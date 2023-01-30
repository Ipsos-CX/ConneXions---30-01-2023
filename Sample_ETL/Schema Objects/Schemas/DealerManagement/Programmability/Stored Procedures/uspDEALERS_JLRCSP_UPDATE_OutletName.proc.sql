CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_UPDATE_OutletName]

AS
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON

	-- Purpose: Update outlet name details in both the sample model and the flattened dealer hierarchy table
	--
	--
	-- Version		Developer			Date			Comment
	-- 1.0			Martin Riverol		09/05/2012		Created
	-- 1.1			Martin Riverol		16/05/2012		Duplicate integrity issue when updating DealerNetworks therefore
	--													constrained updates based on RoleTypeIDFrom AND removed dealercode 
	--													update to ensure no duplication.
	-- 1.2			Martin Riverol		13/07/2012		Once updated, rebuild the flattened table of dealers 		
	-- 1.3			Chris Ross			16/07/2014		Modify transfer dealer update to ignore any Dealers which are not current (i.e. ThroughDate set)					 
	-- 1.4			Chris Ross			11/03/2015		BUG 11272: Ensure DealerShortName is populated correctly (as per DoAppointments)
	-- 1.5			Eddie Thomas		29/09/2017		BUG 14284: DDB Bodyshop - OWAP Dealer name updates not working.
	-- 1.6			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases


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
					, IP_OutletNameChangeID INT
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
					, IP_OutletNameChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UON.IP_OutletNameChangeID) ID
						, UON.IP_OutletNameChangeID
						, UON.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
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

			UPDATE UON
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON ON AT.IP_OutletNameChangeID = UON.IP_OutletNameChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET Outlet = UON.OutletName
			, TransferDealer = 	
								CASE
									-- ALSO UPDATE TRANSFER OUTLET COLUMNS IF THE OUTLET IS A TRANSFER DEALER
									WHEN D.TransferDealer = D.Outlet AND D.TransferPartyID = D.OutletPartyID 
									THEN UON.OutletName
									ELSE D.TransferDealer 
								END
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UON.ID = D.ID
		WHERE UON.IP_ProcessedDate IS NULL
		AND UON.IP_DataValidated = 1
		AND UON.OutletName <> D.Outlet
	
	-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR NAME CHANGED

		UPDATE D 
			SET D.TransferDealer = UON.OutletName 
		FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
		INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON UON.IP_OutletPartyID = d.TransferPartyID
													AND UON.OutletCode = D.TransferDealerCode
													AND UON.Manufacturer = D.Manufacturer
													AND UON.Market = D.Market
													AND UON.OutletFunction = D.OutletFunction
													AND GETDATE() < ISNULL(D.ThroughDate , '20991231')  -- v1.3
		WHERE UON.IP_ProcessedDate IS NULL
		AND UON.IP_DataValidated = 1
		AND UON.OutletName <> D.TransferDealer	
	

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


	-- PUT NAME CHANGE UPDATES INTO A TABLE SO WE CAN LOOP THROUGH INSERTING INTO UPDATE TRIGGERS ON ORGANISATIONS AND DEALERNETWORK TABLES

		SELECT 
			IDENTITY(INT, 1, 1) AS ID 
			, X.AuditItemID 
			, X.OutletFunction
			, X.Outlet 
			, X.OutletName_Short
			, X.LocalLanguageDealerName 
			, X.OutletPartyID
			, X.OutletCode
		INTO #Dealers
		FROM 
			(
				SELECT 
					MIN(UON.IP_AuditItemID) AS AuditItemID 
					, UON.OutletFunction
					, UON.OutletName AS Outlet
					, UON.OutletName_NativeLanguage AS LocalLanguageDealerName
					, UON.IP_OutletPartyID AS OutletPartyID
					, UON.OutletCode
					, UON.OutletName_Short
				FROM DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
				INNER JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers AS D ON UON.ID = D.ID
				INNER JOIN [$(SampleDB)].Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID 
														AND DN.RoleTypeIDFrom = D.OutletFunctionID
				INNER JOIN #importers AS I ON D.ManufacturerPartyID = I.ManufacturerPartyID
											AND DN.PartyIDTo IN (I.ManufacturerPartyID, i.ImporterPartyID)
				WHERE d.OutletPartyID = DN.PartyIDFrom
				AND d.OutletFunctionID = DN.RoleTypeIDFrom
				AND d.ManufacturerPartyID = i.ManufacturerPartyID
				AND UON.IP_ProcessedDate IS NULL
				AND UON.IP_DataValidated = 1
				GROUP BY 
					UON.OutletFunction
					, UON.OutletName
					, UON.OutletName_NativeLanguage
					, UON.IP_OutletPartyID
					, UON.OutletCode
					, UON.OutletName_Short
			) X
	

	-- LOOP THROUGH TABLE INSERTING ROWS INTO LEGALORGANISATION AND DEALERNETWORK DATA ACCESS UPDATE VIEWS


		DECLARE @Counter INT
		SET @Counter = 1
		
		DECLARE @AuditItemID BIGINT
		DECLARE @Outlet NVARCHAR(150)
		DECLARE @LocalLanguageDealerName NVARCHAR(150)
		DECLARE @OutletPartyID INT
		DECLARE @OutletCode NVARCHAR(10)
		DECLARE @OutletFunctionID INT
		DECLARE @OutletNameShort NVARCHAR(150)
		
		WHILE @Counter <= (SELECT MAX(ID) FROM #Dealers)

		BEGIN
			SELECT
				 @AuditItemID = AuditItemID
				, @Outlet = Outlet
				, @LocalLanguageDealerName = LocalLanguageDealerName
				, @OutletPartyID = OutletPartyID
				, @OutletCode = OutletCode
				, @OutletNameShort = OutletName_Short
				, @OutletFunctionID =	CASE OutletFunction 
											WHEN 'Sales' THEN 8 
											WHEN 'Aftersales' THEN 20 
											WHEN 'Bodyshop' THEN 56
											ELSE 0 
										END 
			FROM #Dealers
			WHERE ID = @Counter
			
			-- DEALERNETWORKS USES THE LOCAL LANGUAGE DEALER NAME AS THIS SHOULD BE WHAT GOES IN ANY OUTPUT FILES

				UPDATE [$(SampleDB)].Party.vwDA_DealerNetworks
					SET	AuditItemID = @AuditItemID 
					, DealerShortName = COALESCE(NULLIF(@LocalLanguageDealerName, ''), @OutletNameShort)	-- v1.4
				WHERE PartyIDFrom = @OutletPartyID
				AND RoleTypeIDFrom = @OutletFunctionID

	
			-- ORGANISATION AND LEGAL ORGANISATION USES THE STANDARD DEALER NAME

				UPDATE [$(SampleDB)].Party.vwDA_LegalOrganisations
					SET AuditItemID = @AuditItemID
					, ParentAuditItemID = @AuditItemID
					, OrganisationName = @Outlet
					, LegalName = @LocalLanguageDealerName
					, FromDate = CURRENT_TIMESTAMP
				WHERE PartyID = @OutletPartyID
					
				--UPDATE [$(SampleDB)].Party.vwDA_LegalOrganisations
				--	SET AuditItemID = 62341907 --@AuditItemID
				--	, ParentAuditItemID = 62341907 --@AuditItemID
				--	, OrganisationName = 'Allrad Grasser GmbH XXX' --@Outlet
				--	, LegalName = 'Allrad Grasser GmbH XXX' --@Outlet
				--	, FromDate = CURRENT_TIMESTAMP
				--WHERE PartyID = 555 --@OutletPartyID
						
			SET @Counter = @Counter + 1
		END

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UON
			SET IP_ProcessedDate = GETDATE()
		FROM #Dealers D
		INNER JOIN DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON ON D.AuditItemID = UON.IP_AuditItemID
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